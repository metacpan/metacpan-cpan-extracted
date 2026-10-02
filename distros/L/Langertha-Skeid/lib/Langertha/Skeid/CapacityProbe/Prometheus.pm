package Langertha::Skeid::CapacityProbe::Prometheus;
our $VERSION = '0.003';
# ABSTRACT: Capacity probe reading vLLM/SGLang/TGI Prometheus metrics
use Moo;
use Mojo::UserAgent;
use namespace::clean;

extends 'Langertha::Skeid::CapacityProbe';


my @DEFAULT_RUNNING = qw(
  vllm:num_requests_running
  sglang:num_running_reqs
  tgi_batch_current_size
);

my @DEFAULT_WAITING = qw(
  vllm:num_requests_waiting
  sglang:num_queue_reqs
  tgi_queue_size
);

has _ua => (
  is      => 'lazy',
  builder => sub {
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(2);
    # Deliberately shorter than the poll interval: a probe request still outstanding when the
    # next tick fires is a probe that has started queueing on itself.
    $ua->request_timeout(3);
    return $ua;
  },
);

has _inflight_poll => (
  is      => 'rw',
  default => sub { 0 },
);


sub url {
  my ($self) = @_;
  my $cfg = $self->config;
  return $cfg->{url} if defined($cfg->{url}) && length($cfg->{url});

  my ($node) = grep { ($_->{id} // '') eq $self->node_id } @{$self->skeid->nodes};
  my $base = $node ? ($node->{url} // '') : '';
  $base =~ s{/v\d+/?$}{};
  $base =~ s{/+$}{};
  my $path = $cfg->{path} // '/metrics';
  $path = "/$path" unless $path =~ m{^/};
  return $base . $path;
}


sub source { 'prometheus' }


sub poll {
  my ($self) = @_;

  # One poll at a time. A slow metrics endpoint would otherwise accumulate requests on every
  # tick, and the probe becomes the load it is supposed to measure.
  return if $self->_inflight_poll;
  $self->_inflight_poll(1);

  my $url = $self->url;
  $self->_ua->get($url => sub {
    my (undef, $tx) = @_;
    $self->_inflight_poll(0);
    # Stopped while the request was out -- a restart or a removed node. Whatever it says now
    # belongs to no running probe, and writing it would overwrite or resurrect a reading.
    return if $self->is_stopped;

    my $status = $tx->res->code // 0;
    unless ($status >= 200 && $status < 300) {
      # Unreachable means unknown, and unknown means inflight decides. Never keep the last
      # reading: it describes a node we can no longer see.
      $self->_forget_own;
      return;
    }

    my $metrics = $self->parse_metrics($tx->res->body);
    my $running = $self->_sum($metrics, ($self->config->{running} || $self->config->{used}), \@DEFAULT_RUNNING);
    my $waiting = $self->_sum($metrics, $self->config->{waiting}, \@DEFAULT_WAITING);

    if (!defined $running && !defined $waiting) {
      # The endpoint answered but said nothing we understand -- most likely the wrong metric
      # names for this engine. Same rule: report nothing.
      $self->_forget_own;
      return;
    }

    $self->skeid->set_capacity_reading(
      $self->node_id,
      source      => $self->source,
      used        => (($running // 0) + ($waiting // 0)),
      limit       => $self->_limit,
      interval_ms => $self->poll_interval_seconds * 1000,
    );
  });
  return;
}

sub _limit {
  my ($self) = @_;
  my $cfg_limit = $self->config->{limit};
  return 0 + $cfg_limit if defined($cfg_limit) && $cfg_limit > 0;

  # Falling back to max_conns keeps one number in one place for the common case where the
  # operator already wrote down what the node can take.
  my ($node) = grep { ($_->{id} // '') eq $self->node_id } @{$self->skeid->nodes};
  my $max = $node ? 0 + ($node->{max_conns} // 0) : 0;
  return $max > 0 ? $max : undef;
}

sub _sum {
  my ($self, $metrics, $configured, $defaults) = @_;
  my @names = $configured
    ? (ref($configured) eq 'ARRAY' ? @$configured : ($configured))
    : @$defaults;

  my $total;
  for my $name (@names) {
    next unless defined $metrics->{$name};
    $total = ($total // 0) + $metrics->{$name};
  }
  return $total;
}


sub parse_metrics {
  my ($self, $body) = @_;
  my %values;
  return \%values unless defined $body && length $body;

  for my $line (split /\n/, $body) {
    next if $line =~ /^\s*(?:#|$)/;
    my ($name, $value) = $line =~ /^\s*([A-Za-z_:][A-Za-z0-9_:]*)(?:\{[^}]*\})?\s+([-+0-9.eE]+|NaN)\s*$/
      or next;
    next if $value eq 'NaN';
    $values{$name} = ($values{$name} // 0) + $value;
  }
  return \%values;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::CapacityProbe::Prometheus - Capacity probe reading vLLM/SGLang/TGI Prometheus metrics

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  nodes:
    - id: gpu-1
      url: http://gpu-1:8000/v1
      model: qwen3-32b
      max_conns: 32
      capacity:
        probe: prometheus
        url: http://gpu-1:8000/metrics
        interval_ms: 2000
        limit: 32                       # optional; falls back to max_conns

=head1 DESCRIPTION

vLLM, SGLang and TGI already publish how many requests they are running and how many are
queued. That is the number C<inflight> is trying to reconstruct by counting — except this one
includes traffic this Skeid never sent, which is the entire problem with counting (ADR 0009).

Used is C<running + waiting>: a queued request is occupying the node as surely as a running
one, and admitting more because they are "only waiting" is how a queue becomes a timeout.

=head2 Metric names

Defaults cover the common engines: C<vllm:num_requests_running>, C<sglang:num_running_reqs> and
C<tgi_batch_current_size> for running, C<vllm:num_requests_waiting>, C<sglang:num_queue_reqs> and
C<tgi_queue_size> for waiting. C<running> (or C<used>) and C<waiting> in the C<capacity> block
override them, each a name or a list of names. Names are matched ignoring labels, and several
series with the same name are summed — a per-model breakdown still adds up to what the node is
doing.

=head2 The capacity block

C<url> (the metrics endpoint) or C<path> (default C</metrics>, see L</url>), C<interval_ms>
(default 2000), C<running>/C<used>, C<waiting>, and C<limit> (the ceiling; default the node's
C<max_conns>, and with neither the reading does not narrow admission).

=head2 url

The metrics endpoint. Taken from the C<capacity> block; if it only gives a path, it is resolved
against the node's own URL, so C<path: /metrics> is enough for the usual case where the engine
serves metrics beside its API.

=head2 source

C<prometheus>.

=head2 poll

Fetches L</url> without blocking, one request at a time (a poll still out when the next tick
fires is skipped), and reports C<used> = running + waiting against the limit. A non-2xx answer,
an unreachable endpoint, or a body without any of the metric names forgets the reading instead.
An answer that arrives after L<Langertha::Skeid::CapacityProbe/stop> is dropped.

=head2 parse_metrics

  my $values = $probe->parse_metrics($body);   # { 'vllm:num_requests_running' => 3, ... }

Prometheus text format, reduced to what a probe needs: metric name to summed value, labels
ignored, C<#> lines skipped. Not a general-purpose parser and not trying to be — histograms and
label selection are not what admission asks about.

=head1 SEE ALSO

L<Langertha::Skeid::CapacityProbe>, and ADR 0009 in the distribution repository.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
