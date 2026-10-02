package Langertha::Raider::CLI::Sessions;
# ABSTRACT: Internal session subcommands of the raider CLI: list, show, resume, fork, rm
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use JSON::MaybeXS ();


has app => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Application',
  required => 1,
);


sub store { $_[0]->app->session_store }

has output => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI::Output',
  required => 1,
);

has _json => (
  is      => 'ro',
  lazy    => 1,
  default => sub { JSON::MaybeXS->new(canonical => 1, allow_nonref => 1, allow_blessed => 1, convert_blessed => 1) },
);


sub summary {
  my ( $self, $id ) = @_;
  my $journal = $self->store->read($id);
  my $runs = $journal->runs;
  my ( $first ) = grep { defined $_->{prompt} } @$runs;
  my ( $date, $time ) = $id =~ /\A(\d{8})-(\d{6})/;
  return {
    id      => $id,
    path    => ''.$journal->path,
    created => join('-', unpack 'A4 A2 A2', $date).'T'.join(':', unpack 'A2 A2 A2', $time).'Z',
    runs    => scalar @$runs,
    status  => @$runs ? $runs->[-1]{status} : 'empty',
    prompt  => $first ? $first->{prompt} : undef,
    damaged => scalar @{ $journal->damaged },
  };
}


sub list {
  my ( $self, $machine ) = @_;
  my @summaries = map { $self->summary($_) } $self->store->ids;
  return $machine->write({ version => $machine->version, sessions => \@summaries }) if $machine;
  my $out = $self->output;
  unless (@summaries) {
    $out->say_meta('no sessions in '.$self->store->dir);
    return;
  }
  for my $s (@summaries) {
    $out->emit($out->c(title => $s->{id}), '  ',
      sprintf('%3d run%s  %-11s', $s->{runs}, $s->{runs} == 1 ? ' ' : 's', $s->{status}), '  ',
      $out->c(meta => $self->_short($s->{prompt} // '', 60)),
      $s->{damaged} ? $out->c(warn => '  ('.$s->{damaged}.' damaged)') : '', "\n");
  }
  return;
}


sub show {
  my ( $self, $id, $machine ) = @_;
  my $journal = $self->store->read($id);
  if ($machine) {
    return $machine->write({
      version => $machine->version,
      id      => $id,
      path    => ''.$journal->path,
      events  => $journal->events,
      damaged => $journal->damaged,
      runs    => [ map { { run => $_->{run}, status => $_->{status} } } @{ $journal->runs } ],
      unknown => [ map { { run => $_->{run}, call => $_->{call}, name => $_->{name} } } @{ $journal->unknown_calls } ],
    });
  }
  my $out = $self->output;
  my $line = sub { $out->emit($out->c(meta => sprintf('%-11s ', $_[0])), @_[ 1 .. $#_ ], "\n") };
  $line->('session', $out->c(title => $id));
  $line->('file', $journal->path);
  if (my $c = $journal->created) {
    $line->('created', join ' ', grep { defined }
      $self->summary($id)->{created}, 'by', $c->{principal} // '?', 'in', $c->{root} // '?',
      '(raider '.($c->{raider} // '?').')');
    $line->('forked from', $c->{forked_from}) if defined $c->{forked_from};
  }
  for my $e (@{ $journal->events }) {
    my $run = defined $e->{run} ? $e->{run}.' ' : '';
    my $type = $e->{type};
    if ($type eq 'run.started') {
      $line->($run.'started', join ' ', grep { defined } $e->{engine}, $e->{model});
    }
    elsif ($type eq 'message') {
      $line->($run.($e->{role} // '?'), $out->c(($e->{role} // '') eq 'assistant' ? 'agent' : 'title',
        $self->_indent($e->{content} // '')));
    }
    elsif ($type eq 'tool.call') {
      $line->($run.'tool', ($e->{call} // '?').' ', $out->c(title => $e->{name} // '?'), ' ',
        $self->_short($self->_json->encode($e->{arguments} // {}), 200));
    }
    elsif ($type eq 'tool.result') {
      my $content = $e->{content} // '';
      $line->($run.'result', ($e->{call} // '?').' '.($e->{status} // '?').', '.length($content).' chars: ',
        $out->c(meta => $self->_short($content, 100)));
    }
    elsif ($type eq 'run.finished') {
      $line->($run.'finished', join ', ', grep { defined } $e->{status},
        defined $e->{elapsed} ? $e->{elapsed}.'s' : undef,
        defined $e->{signal} ? 'SIG'.$e->{signal} : undef,
        defined $e->{error} ? 'error: '.$self->_short($e->{error}, 200) : undef);
    }
  }
  $out->emit($out->c(warn => 'note: '.$_), "\n") for $self->notes($journal);
  return;
}


sub notes {
  my ( $self, $journal ) = @_;
  my @notes;
  push @notes, 'line '.$_.' of the journal is damaged and was skipped' for @{ $journal->damaged };
  push @notes, 'run '.$_->{run}.' has no end: interrupted'
    for grep { !$_->{finished} } @{ $journal->runs };
  push @notes, 'tool call '.($_->{name} // '?').' ('.($_->{run} // '?').' '.($_->{call} // '?')
    .') has no result: its outcome is unknown, it is not run again'
    for @{ $journal->unknown_calls };
  return @notes;
}


sub restore {
  my ( $self, $session ) = @_;
  my $journal = $self->app->replay_session($session);
  my $history = $journal->history_messages;
  my $runs = scalar @{ $journal->runs };
  return ( 'resumed session '.$session->id.': '.$runs.' run'.($runs == 1 ? '' : 's').', '
    .scalar(@$history).' messages in the history', $self->notes($journal) );
}


sub fork_session {
  my ( $self, $id, $machine ) = @_;
  my %doc = %{ $self->app->fork_session($id) };
  if ($machine) {
    $machine->write({ version => $machine->version, %doc });
  }
  else {
    $self->output->emit('forked session '.$id.' as '.$doc{id}.' ('.$doc{path}.'): '.$doc{messages}
      .' message'.($doc{messages} == 1 ? '' : 's')."\n");
  }
  return $doc{id};
}


sub remove {
  my ( $self, $id, $machine ) = @_;
  my $path = $self->app->remove_session($id);
  return $machine->write({ version => $machine->version, id => $id, path => $path, removed => JSON::MaybeXS->true })
    if $machine;
  $self->output->emit('removed session '.$id."\n");
  return;
}

sub _short {
  my ( $self, $text, $max ) = @_;
  $text =~ s/\s+/ /g;
  $text =~ s/\A | \z//g;
  return length $text > $max ? substr($text, 0, $max - 3).'...' : $text;
}

sub _indent {
  my ( $self, $text ) = @_;
  $text =~ s/\n/\n            /g;
  return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Sessions - Internal session subcommands of the raider CLI: list, show, resume, fork, rm

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $sessions = Langertha::Raider::CLI::Sessions->new(app => $app, output => $out);
    $sessions->list;                        # raider session list
    $sessions->show($id);                   # raider session show ID
    $sessions->show($id, $machine);         # raider session show ID --json
    my @notes = $sessions->restore($session);                 # --session ID, --continue
    my $new = $sessions->fork_session($id);                   # raider session fork ID
    $sessions->remove($id);                                   # raider session rm ID

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

What F<raider> does with the session journals of a project
(L<Langertha::Raider::SessionStore>, ADR 0015) beyond writing them: listing
them, showing one, replaying one into a raider to resume it, forking one
and removing one -- the changes through the
L<Langertha::Raider::Application>, this class presents them.

=head2 app

The L<Langertha::Raider::Application> of the project. Required.

=head2 output

The L<Langertha::Raider::CLI::Output> to print to. Required.

=head2 store

The L<Langertha::Raider::Application/session_store> of L</app>.

=head2 summary

    my $s = $sessions->summary($id);

One session in short: C<id>, C<path>, C<created> (ISO 8601, UTC, from the
id), C<runs> (how many), C<status> (of the last run, C<empty> without
one), C<prompt> (the first user input, or C<undef>) and C<damaged> (how
many lines could not be read).

=head2 list

    $sessions->list;            # human
    $sessions->list($machine);  # { version => 1, sessions => [ summary, ... ] }

The sessions of the project, newest first, one L</summary> each.

=head2 show

    $sessions->show($id);            # human
    $sessions->show($id, $machine);  # the journal as one document

Prints one session: every event in order, then the L</notes> of its
journal. With a machine, one document: C<version>, C<id>, C<path>,
C<events> (as in the file), C<damaged> (line numbers), C<runs> (C<run>
and C<status> each) and C<unknown> (the calls without result: C<run>,
C<call>, C<name>).

=head2 notes

    my @notes = $sessions->notes($journal);

What the crash rules of ADR 0015 found in a journal, one line each: the
lines that could not be read, the runs without C<run.finished> (they count
as C<interrupted>) and the tool calls without result (C<unknown>, never run
again).

=head2 restore

    my @notes = $sessions->restore($session);

Replays the journal the L<Langertha::Raider::Session> was opened with into
the raider of L</app> (L<Langertha::Raider::Application/replay_session>).
Returns a line saying what was resumed, then the L</notes>.

=head2 fork_session

    $sessions->fork_session($id);            # human
    $sessions->fork_session($id, $machine);  # { version, id, path, forked_from, messages }

C<raider session fork ID>: a new session of the same project that takes
over the working history of the original
(L<Langertha::Raider::Application/fork_session>). From there it has a
journal of its own; the original is never changed, and the workspace
stays the same. Returns the new id.

=head2 remove

    $sessions->remove($id);            # human
    $sessions->remove($id, $machine);  # { version, id, path, removed }

C<raider session rm ID>: deletes the session's journal and lock file
through L<Langertha::Raider::Application/remove_session>, which croaks
C<session ID is in use> while another raider has it open.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SessionStore>

=item * L<Langertha::Raider::CLI::Main>

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
