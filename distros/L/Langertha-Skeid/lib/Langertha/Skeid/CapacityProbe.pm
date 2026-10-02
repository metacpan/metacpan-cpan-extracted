package Langertha::Skeid::CapacityProbe;
our $VERSION = '0.003';
# ABSTRACT: Background probes that report what a node's real capacity is
use Moo;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);
use namespace::clean;



has skeid => (
  is       => 'ro',
  required => 1,
);


has node_id => (
  is       => 'ro',
  required => 1,
);


has interval_ms => (
  is      => 'rw',
  default => sub { 2000 },
);


has config => (
  is      => 'ro',
  default => sub { {} },
);

has _timer => (
  is      => 'rw',
  clearer => '_clear_timer',
);


has is_stopped => (
  is      => 'rwp',
  default => sub { 0 },
);


sub source { return }

# Forget what this probe reported, and nothing another source said.
sub _forget_own {
  my ($self) = @_;
  my $source = $self->source;
  return $self->skeid->forget_capacity($self->node_id, (defined $source ? (source => $source) : ()));
}


sub poll {
  my ($self) = @_;
  croak ref($self) . " must implement poll()";
}


sub poll_interval_seconds {
  my ($self) = @_;
  my $workers = 0 + ($self->skeid->worker_count // 1);
  $workers = 1 if $workers < 1;

  my $every = (($self->interval_ms || 2000) * $workers) / 1000;
  return $every < 0.1 ? 0.1 : $every;
}


sub start {
  my ($self) = @_;
  return $self->_timer if $self->_timer;
  require Mojo::IOLoop;
  $self->_set_is_stopped(0);

  my $every = $self->poll_interval_seconds;

  # A reading older than capacity_max_age_ms is dropped. A probe that polls less often than
  # that leaves gaps in which inflight decides, and the operator should hear about it once.
  my $max_age_ms = 0 + ($self->skeid->capacity_max_age_ms // 0);
  if ($max_age_ms > 0 && $every * 1000 >= $max_age_ms) {
    warn "capacity probe for '" . $self->node_id . "' polls every " . ($every * 1000)
      . "ms (interval_ms x workers); it must be below capacity_max_age_ms ($max_age_ms), or its "
      . "reading expires between polls and inflight decides in the gaps\n";
  }

  # Weak, or the timer's closure keeps the probe (and the whole control plane) alive forever.
  my $weak = $self;
  weaken($weak);

  my $id = Mojo::IOLoop->recurring($every => sub {
    my $probe = $weak or return;
    # A probe that dies takes the timer's reactor with it otherwise, and one unreachable
    # metrics endpoint should not stop the proxy.
    eval { $probe->poll; 1 } or do {
      my $err = $@ || 'unknown error';
      $err =~ s/\s+\z//;
      warn "capacity probe for '" . $probe->node_id . "' failed: $err";
      $probe->_forget_own;
    };
  });
  $self->_timer($id);

  eval { $self->poll; 1 } or do { $self->_forget_own };
  return $id;
}


sub stop {
  my ($self) = @_;
  $self->_set_is_stopped(1);
  if (my $id = $self->_timer) {
    require Mojo::IOLoop;
    eval { Mojo::IOLoop->remove($id) };
    $self->_clear_timer;
  }
  $self->_forget_own;
  return 1;
}


sub for_node {
  my ($class, $skeid, $node) = @_;
  return unless ref($node) eq 'HASH';
  my $cfg = $node->{capacity};
  return unless ref($cfg) eq 'HASH';

  my $kind = lc($cfg->{probe} // $cfg->{type} // 'inflight');
  return if $kind eq 'inflight' || $kind eq 'none' || $kind eq 'ratelimit';

  my %args = (
    skeid   => $skeid,
    node_id => $node->{id},
    config  => $cfg,
    (defined $cfg->{interval_ms} ? (interval_ms => 0 + $cfg->{interval_ms}) : ()),
  );

  if ($kind eq 'prometheus') {
    require Langertha::Skeid::CapacityProbe::Prometheus;
    return Langertha::Skeid::CapacityProbe::Prometheus->new(%args);
  }

  if ($kind eq 'registry') {
    require Langertha::Skeid::CapacityProbe::Registry;
    return Langertha::Skeid::CapacityProbe::Registry->new(%args);
  }

  if ($kind eq 'custom') {
    if (ref($cfg->{code}) eq 'CODE') {
      require Langertha::Skeid::CapacityProbe::Custom;
      return Langertha::Skeid::CapacityProbe::Custom->new(%args, code => $cfg->{code});
    }
    my $custom_class = $cfg->{class} or croak "capacity probe 'custom' needs a code or class";
    # A class name out of a config file is loaded by name, so keep it looking like one.
    croak "invalid capacity probe class '$custom_class'"
      unless $custom_class =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;
    my $path = $custom_class . '.pm';
    $path =~ s{::}{/}g;
    require $path;
    return $custom_class->new(%args);
  }

  croak "unknown capacity probe '$kind'";
}


sub start_for_skeid {
  my ($class, $skeid) = @_;
  my %probes;
  for my $node (@{$skeid->nodes}) {
    my $probe = eval { $class->for_node($skeid, $node) };
    if ($@) {
      my $err = $@; $err =~ s/\s+\z//;
      warn "capacity probe for '" . ($node->{id} // '?') . "' not started: $err";
      next;
    }
    next unless $probe;
    $probe->start;
    $probes{$node->{id}} = $probe;
  }
  return \%probes;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::CapacityProbe - Background probes that report what a node's real capacity is

=head1 VERSION

version 0.003

=head1 DESCRIPTION

C<inflight> counts what B<this> process sent to a node. That is exact for one Skeid in front of
one node, and wrong the moment anything else sends work there — a second frontend, a prefork
worker, a batch job, an engineer with C<curl>. Each counter then sees only its own share, every
instance believes the node is emptier than it is, and together they over-admit.

A probe reports what the node itself says instead. See ADR 0009 for why this rather than a
shared counter in Redis.

=head2 Writing one

Subclass this, implement L</poll>, and report through L<Langertha::Skeid/set_capacity_reading>.
Two rules that are not negotiable:

=over 4

=item * B<Never on the request path.> Polling is a timer. A probe that resolves during a
request has moved a network round-trip into the latency of a request that did not ask for it.

=item * B<Report nothing rather than something old.> If the source cannot be reached, call
C<forget_capacity>. Admission falls back to C<inflight>, which is merely imprecise; a stale
reading is confidently wrong.

=back

=head2 skeid

The control plane to report to.

=head2 node_id

Which node this probe describes.

=head2 interval_ms

How often to poll (default 2000). The right value is a trade between staleness and load on the
node's metrics endpoint, and ADR 0009 leaves it open pending measurement — 2s is a starting
point, not a finding.

=head2 config

The node's C<capacity> block, verbatim.

=head2 is_stopped

True once L</stop> has run. A poll whose answer arrives after that (an HTTP request still in
flight at a restart) must not report: the node may be gone, or a new probe may already describe
it. A subclass that reports asynchronously checks this before it writes.

=head2 source

The C<source> this probe writes its readings under (C<prometheus>, C<registry>), or undef when
it does not have a fixed one -- a C<custom> callback picks its own. When the probe fails or
stops it forgets only a reading under this source, so a C<429> backoff the passive rate-limit
probe recorded outlives a probe that went blind (ADR 0017). Undef forgets whatever is there.

=head2 poll

  $probe->poll;

What a subclass implements: read the source, then either C<set_capacity_reading> or
C<forget_capacity> on L</skeid>. Must not block.

=head2 poll_interval_seconds

How often this process actually polls: L</interval_ms> multiplied by the worker count.

Every worker runs its own copy of the timer, so without the multiplier four workers on a 2s
interval would hit the node's metrics endpoint every 500ms — the probe becoming the load it
was meant to measure. What the operator configured is the rate the *node* sees from the
process group (ADR 0010).

=head2 start

  $probe->start;

Begins polling on a timer, and polls once immediately so the first request does not have to
wait an interval for a reading. Safe to call twice.

=head2 stop

Stops polling and drops the node's reading, so admission goes back to C<inflight> rather than
acting on whatever this probe last said.

=head2 for_node

  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $node);

Builds the probe a node's C<capacity> block asks for, or nothing when it asks for none.

  capacity:
    probe: prometheus              # or: inflight, custom, registry
    url: http://gpu-1:8000/metrics
    interval_ms: 2000

C<probe> may also be spelled C<type>. C<inflight> (the default; also C<none>, and an absent
block) means no probe object at all — that is the default admission path, not a probe that
reports the same thing. C<ratelimit> is likewise not built here: it is
passive, read off responses the proxy already has, and needs nothing running.

C<registry> is for a node that is itself a Skeid: it pulls that Skeid's signed registry
snapshot (L<Langertha::Skeid::CapacityProbe::Registry>, ADR 0017).

C<custom> takes either a C<code> callback (given the probe, reports through the same methods)
or a C<class> to load, because Skeid is generic and the built-ins only cover the engines we
happen to know. The class must look like a Perl package name, is loaded by name and built
with C<skeid>, C<node_id>, C<config> and C<interval_ms>.

C<interval_ms> in the block becomes L</interval_ms>. Croaks on an unknown probe, and on a
C<custom> block with neither C<code> nor a valid C<class>.

=head2 start_for_skeid

  my $probes = Langertha::Skeid::CapacityProbe->start_for_skeid($skeid);

Builds and starts a probe for every node that asks for one, and returns them by node id. The
caller holds them: a probe that goes out of scope stops polling. A node whose block does not
build is skipped with a warning, so one bad block does not stop the others.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid::CapacityProbe::Prometheus>, L<Langertha::Skeid::CapacityProbe::Registry>,
L<Langertha::Skeid::CapacityProbe::Custom>

=item * L<Langertha::Skeid/set_capacity_reading>, L<Langertha::Skeid/observe_response_headers> --
the reading every probe reports, and the passive one

=back

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
