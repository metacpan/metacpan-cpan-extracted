package Langertha::Raider::Session::Journal;
# ABSTRACT: Internal read-only view of one session journal
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use JSON::MaybeXS ();
use Path::Tiny;


has id           => ( is => 'ro', isa => 'Str' );
has path         => ( is => 'ro' );
has events       => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has damaged      => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has unterminated => ( is => 'ro', isa => 'Bool', default => 0 );


sub load {
  my ( $self, $file, %args ) = @_;
  $file = path($file);
  my $raw = -e $file ? $file->slurp_raw : '';
  my $json = JSON::MaybeXS->new(utf8 => 1);
  my ( @events, @damaged );
  my $n = 0;
  for my $line (split /\n/, $raw) {
    $n++;
    next unless $line =~ /\S/;
    my $event = eval { $json->decode($line) };
    if (ref $event eq 'HASH' && defined $event->{type}) { push @events, $event }
    else                                                { push @damaged, $n }
  }
  return $self->new(
    %args,
    path         => $file,
    events       => \@events,
    damaged      => \@damaged,
    unterminated => length $raw && substr($raw, -1) ne "\n" ? 1 : 0,
  );
}


sub created {
  my ( $self ) = @_;
  my $first = $self->events->[0];
  return $first && $first->{type} eq 'session.created' ? $first : undef;
}


sub last_seq {
  my ( $self ) = @_;
  my $max = 0;
  for my $e (@{ $self->events }) {
    $max = $e->{seq} if ($e->{seq} // 0) =~ /\A\d+\z/ && $e->{seq} > $max;
  }
  return $max;
}


sub last_run_number {
  my ( $self ) = @_;
  my $max = 0;
  for my $e (@{ $self->events }) {
    my ( $n ) = ($e->{run} // '') =~ /\Ar(\d+)\z/ or next;
    $max = $n if $n > $max;
  }
  return $max;
}


sub runs {
  my ( $self ) = @_;
  my ( @runs, %run );
  for my $e (@{ $self->events }) {
    my $id = $e->{run} // next;
    my $r = $run{$id} //= do { push @runs, { run => $id }; $runs[-1] };
    if    ($e->{type} eq 'run.started')  { $r->{started}  = $e }
    elsif ($e->{type} eq 'run.finished') { $r->{finished} = $e }
    elsif ($e->{type} eq 'message') {
      $r->{prompt}   //= $e->{content} if ($e->{role} // '') eq 'user';
      $r->{response}   = $e->{content} if ($e->{role} // '') eq 'assistant';
    }
  }
  $_->{status} = $_->{finished} ? ($_->{finished}{status} // 'unknown') : 'interrupted' for @runs;
  return \@runs;
}


sub unknown_calls {
  my ( $self ) = @_;
  my $key = sub { ($_[0]{run} // '').' '.($_[0]{call} // '') };
  my %done = map { $key->($_) => 1 } grep { $_->{type} eq 'tool.result' } @{ $self->events };
  return [ grep { $_->{type} eq 'tool.call' && !$done{ $key->($_) } } @{ $self->events } ];
}


sub history_messages {
  my ( $self ) = @_;
  my %answered = map { $_->{run} => 1 } grep { defined $_->{response} } @{ $self->runs };
  my @messages;
  for my $e (@{ $self->events }) {
    if ($e->{type} eq 'history.cleared') { @messages = () }
    elsif ($e->{type} eq 'message' && (!defined $e->{run} || $answered{ $e->{run} })) {
      push @messages, { role => $e->{role}, content => $e->{content} };
    }
  }
  return \@messages;
}


sub session_history_messages {
  my ( $self ) = @_;
  my %unknown = map { ($_->{run} // '').' '.($_->{call} // '') => 1 } @{ $self->unknown_calls };
  my @entries;
  for my $e (@{ $self->events }) {
    if ($e->{type} eq 'message') {
      push @entries, { role => $e->{role}, content => $e->{content} };
    }
    elsif ($e->{type} eq 'tool.call') {
      push @entries, { role => 'assistant', content => [ {
        type => 'tool_use', id => $e->{call}, name => $e->{name}, input => $e->{arguments},
      } ] };
      push @entries, { role => 'tool', name => $e->{name},
        content => 'unknown: no result was recorded, the call is not run again' }
        if $unknown{ ($e->{run} // '').' '.($e->{call} // '') };
    }
    elsif ($e->{type} eq 'tool.result') {
      push @entries, { role => 'tool', name => $e->{name}, content => $e->{content} };
    }
  }
  return \@entries;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Session::Journal - Internal read-only view of one session journal

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $journal = Langertha::Raider::Session::Journal->load($file, id => $id);

    for my $run (@{ $journal->runs }) {
      say $run->{run}, ' ', $run->{status};         # 'interrupted' without run.finished
    }
    my @unknown = @{ $journal->unknown_calls };      # tool.call without tool.result
    my @history = @{ $journal->history_messages };   # { role, content } to replay
    warn 'damaged lines: '.join(', ', @{ $journal->damaged }) if @{ $journal->damaged };

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

A session journal as read from disk (ADR 0015), with the crash rules
applied: a line that is not a complete JSON object is skipped and its
number listed in L</damaged>; a run without C<run.finished> counts as
C<interrupted>; a C<tool.call> without its C<tool.result> is C<unknown>.
Unknown event types and fields are kept but not interpreted. Beside the
event types of ADR 0015 it knows C<history.cleared> (no fields, no run):
the REPL's C</clear> emptied the working history there.

=head2 id

The session id.

=head2 path

The journal file.

=head2 events

The events in file order, each a hash reference.

=head2 damaged

The line numbers (1-based) that could not be read.

=head2 unterminated

True when the file does not end with a newline -- the last write was cut
off.

=head2 load

    my $journal = Langertha::Raider::Session::Journal->load($file, id => $id);

Reads the file. A missing file reads as an empty journal.

=head2 created

The C<session.created> event (line 1), or C<undef>.

=head2 last_seq

The highest C<seq> in the journal, C<0> for none.

=head2 last_run_number

The highest run number (C<r3> is 3) in the journal, C<0> for none.

=head2 runs

The runs in order, each a hash reference: C<run>, C<status> (from
C<run.finished>, or C<interrupted> without one), C<started> and
C<finished> (the events, C<finished> may be C<undef>), C<prompt> (the
user message) and C<response> (the assistant message, when there is one).

=head2 unknown_calls

The C<tool.call> events that have no C<tool.result> with the same C<run>
and C<call>: their outcome is unknown, and they are never run again.

=head2 history_messages

The working history to rebuild on resume, as C<< { role, content } >>
hashes: the user input and final assistant text of every run that has a
final assistant text. A run that failed or was interrupted before its
answer adds nothing, as a live raid adds nothing to C<history> then. A
C<history.cleared> event (C</clear> in the REPL) empties it: only the
messages after the last one count. A C<message> outside any run (the
history a fork took over) counts as it is.

=head2 session_history_messages

The full history to rebuild on resume, from all events, in the shapes
L<Langertha::Raider/session_history> renders: a C<message> as
C<< { role, content } >>, a C<tool.call> as an assistant C<tool_use>
block, a C<tool.result> as C<< { role => 'tool', name, content } >>, and
for a call without result an entry saying its outcome is unknown.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SessionStore>

=item * L<Langertha::Raider::Session>

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
