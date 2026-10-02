package Langertha::Raider::Plugin::Trace;
our $VERSION = '0.503';
# ABSTRACT: Live ANSI-colored progress output for a running Langertha::Raider raid

use Moose;
use namespace::autoclean;
use Future::AsyncAwait;
use Term::ANSIColor qw( colored );
use JSON::MaybeXS ();
use IO::Async::Timer::Periodic;
use Langertha::Usage;

extends 'Langertha::Plugin';

my @SPINNER_FRAMES = ('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏');


has color => (
  is      => 'ro',
  isa     => 'Bool',
  default => sub { -t STDOUT ? 1 : 0 },
);


has out => (
  is      => 'ro',
  default => sub { \*STDOUT },
);


has max_value_length => (
  is      => 'ro',
  isa     => 'Int',
  default => 80,
);


has token_stats => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub { { prompt => 0, completion => 0, total => 0, calls => 0 } },
);


has loop => (
  is        => 'ro',
  predicate => 'has_loop',
);

has _spinner_timer => ( is => 'rw', clearer => '_clear_spinner_timer' );
has _spinner_idx   => ( is => 'rw', isa => 'Int', default => 0 );
has _spinner_active=> ( is => 'rw', isa => 'Bool', default => 0 );

sub _spinner_enabled {
  my ($self) = @_;
  return 0 unless $self->has_loop;
  return 0 unless $self->color;
  return 0 if $ENV{ANSI_COLORS_DISABLED};
  return 0 unless -t $self->out;
  return 1;
}

sub _start_spinner {
  my ($self) = @_;
  return unless $self->_spinner_enabled;
  return if $self->_spinner_active;
  $self->_spinner_active(1);
  $self->_spinner_idx(0);

  my $tick = sub {
    my $idx   = $self->_spinner_idx;
    my $frame = $SPINNER_FRAMES[$idx % @SPINNER_FRAMES];
    $self->_spinner_idx($idx + 1);
    local $| = 1;
    print { $self->out } "\r", $self->_c(accent => $frame), ' ', $self->_c(iter => 'thinking…'), "\033[K";
  };
  $tick->();

  my $timer = IO::Async::Timer::Periodic->new(
    interval       => 0.1,
    first_interval => 0.1,
    on_tick        => $tick,
  );
  $self->loop->add($timer);
  $timer->start;
  $self->_spinner_timer($timer);
}

sub _stop_spinner {
  my ($self) = @_;
  return unless $self->_spinner_active;
  $self->_spinner_active(0);
  if (my $timer = $self->_spinner_timer) {
    $timer->stop;
    eval { $self->loop->remove($timer) };
    $self->_clear_spinner_timer;
  }
  local $| = 1;
  print { $self->out } "\r\033[K";
}

my %C = (
  iter   => 'bright_black',
  tool   => 'blue',
  args   => 'bright_black',
  ok     => 'bright_black',
  err    => 'red',
  text   => 'bright_black',
  accent => 'yellow',
);

sub _c {
  my ($self, $key, @text) = @_;
  my $text = join '', @text;
  return $text unless $self->color && !$ENV{ANSI_COLORS_DISABLED};
  return colored([$C{$key}], $text);
}

sub _truncate {
  my ($self, $s) = @_;
  return '' unless defined $s;
  $s =~ s/\s+/ /g;
  my $lim = $self->max_value_length;
  return length($s) > $lim ? substr($s, 0, $lim - 1) . '…' : $s;
}

sub _summarize_args {
  my ($self, $input) = @_;
  return '' unless ref $input eq 'HASH';
  my @parts;
  for my $k (sort keys %$input) {
    my $v = $input->{$k};
    if (ref $v) {
      $v = eval { JSON::MaybeXS->new(utf8 => 0, canonical => 1)->encode($v) } // '?';
    }
    push @parts, "$k=" . $self->_truncate($v);
  }
  return join(' ', @parts);
}

async sub plugin_before_llm_call {
  my ($self, $conversation, $iteration) = @_;
  $self->_start_spinner;
  return $conversation;
}

async sub plugin_after_llm_response {
  my ($self, $data, $iteration) = @_;
  $self->_stop_spinner;

  my $usage = Langertha::Usage->from_raw($data);
  if ($usage) {
    my $s = $self->token_stats;
    $s->{prompt}     += $usage->input_tokens;
    $s->{completion} += $usage->output_tokens;
    $s->{total}      += $usage->total_tokens;
    $s->{calls}++;
  }

  return $data;
}

async sub plugin_before_tool_call {
  my ($self, $name, $input) = @_;
  $self->_stop_spinner;
  my $args = $self->_summarize_args($input);
  print { $self->out }
    $self->_c(tool => "> $name"),
    (length $args ? ' ' . $self->_c(args => $args) : ''),
    "\n";
  return ($name, $input);
}

async sub plugin_after_tool_call {
  my ($self, $name, $input, $result) = @_;

  my $is_err = 0;
  my $text   = '';
  if (ref $result eq 'HASH') {
    $is_err = $result->{isError} ? 1 : 0;
    if (ref $result->{content} eq 'ARRAY' && ref $result->{content}[0] eq 'HASH') {
      $text = $result->{content}[0]{text} // '';
    }
  }
  elsif (!ref $result) {
    $text = $result // '';
  }

  my $bytes = length $text;
  my $first = (split /\n/, $text, 2)[0] // '';
  $first =~ s/\s+$//;

  my $key  = $is_err ? 'err' : 'ok';
  my $lead = $is_err ? '! '  : '. ';
  print { $self->out }
    $self->_c($key => $lead . "${bytes}b"),
    (length $first ? ' ' . $self->_c(text => $self->_truncate($first)) : ''),
    "\n";

  return $result;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Plugin::Trace - Live ANSI-colored progress output for a running Langertha::Raider raid

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => ['+Langertha::Raider::Plugin::Trace'],
    );

=head1 DESCRIPTION

Streaming trace plugin used by L<Langertha::Raider::CLI> to show live progress during a
raid: per-iteration markers, each tool call with a short argument summary, and
the tool result (ok / error / length). Palette is blue-dominant with yellow
accents to match the rest of the CLI.

Set C<ANSI_COLORS_DISABLED=1> or construct with C<color =E<gt> 0> to render
without ANSI sequences.

A "thinking..." spinner runs while a model request is in flight when a
L</loop> is given, colors are on and L</out> is a terminal.

=head2 color

Whether to emit ANSI colors. Defaults to true when STDOUT is a terminal.

=head2 out

Filehandle the trace is printed to. Defaults to C<STDOUT>; the raider CLI
passes C<STDERR> when stdout carries machine output.

=head2 max_value_length

Maximum characters shown per argument value in tool-call summaries. Longer
strings are truncated with an ellipsis. Defaults to 80.

=head2 token_stats

Running cumulative hashref: C<{ prompt, completion, total, calls }>.
Updated after every LLM response; read via the C<token_stats> accessor or
through L<Langertha::Raider::CLI/token_stats>.

=head2 loop

Optional L<IO::Async::Loop> used to drive a small "thinking…" spinner while
the LLM HTTP call is in flight. When absent, no spinner is shown.

=head1 ENVIRONMENT

=head2 ANSI_COLORS_DISABLED

Set, the trace has no colors and no spinner, whatever L</color> says.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI>

=item * L<Langertha::Plugin>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
