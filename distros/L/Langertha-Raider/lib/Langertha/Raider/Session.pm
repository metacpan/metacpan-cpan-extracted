package Langertha::Raider::Session;
# ABSTRACT: Internal writer of one session journal, holding its lock
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Fcntl qw( :flock );
use IO::Handle;
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
use Langertha::Raider::Session::Journal;


has id => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has path => (
  is       => 'ro',
  required => 1,
);

has clock => (
  is      => 'ro',
  isa     => 'CodeRef',
  default => sub { \&Time::HiRes::time },
);


has journal => (
  is       => 'ro',
  init_arg => undef,
  writer   => '_set_journal',
);

has _lock_fh => ( is => 'rw', init_arg => undef );
has _fh      => ( is => 'rw', init_arg => undef );
has _seq     => ( is => 'rw', init_arg => undef, default => 0 );
has _runs    => ( is => 'rw', init_arg => undef, default => 0 );
has _torn    => ( is => 'rw', init_arg => undef, default => 0 );

has _json => (
  is      => 'ro',
  lazy    => 1,
  default => sub { JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1, allow_blessed => 1) },
);

sub journal_class { 'Langertha::Raider::Session::Journal' }

sub BUILD {
  my ( $self ) = @_;
  my $path = path($self->path);
  open my $lock, '>>', $self->lock_path or croak 'cannot open '.$self->lock_path.': '.$!;
  croak 'session '.$self->id.' is in use' unless flock $lock, LOCK_EX | LOCK_NB;
  $self->_lock_fh($lock);

  my $journal = $self->journal_class->load($path, id => $self->id);
  $self->_set_journal($journal);
  $self->_seq($journal->last_seq);
  $self->_runs($journal->last_run_number);

  open my $fh, '>>:raw', $path or croak 'cannot append to '.$path.': '.$!;
  $fh->autoflush(1);
  print {$fh} "\n" if $journal->unterminated;
  $self->_fh($fh);
  return;
}

sub DEMOLISH { $_[0]->release }


sub lock_path {
  my ( $self ) = @_;
  return path($self->path)->sibling($self->id.'.lock')->stringify;
}


sub is_open { $_[0]->_fh ? 1 : 0 }


sub next_run {
  my ( $self ) = @_;
  $self->_runs($self->_runs + 1);
  return 'r'.$self->_runs;
}


sub append {
  my ( $self, $type, %fields ) = @_;
  my $fh = $self->_fh or croak 'session '.$self->id.' is closed';
  $self->_seq($self->_seq + 1);
  my $event = { %fields, v => 1, seq => $self->_seq, time => $self->clock->(), type => $type };
  # After a failed write part of that line may be in the file: start anew.
  my $line = ($self->_torn ? "\n" : '').$self->_json->encode($event)."\n";
  unless (print {$fh} $line) {
    $self->_torn(1);
    croak 'cannot write '.$self->path.': '.$!;
  }
  $self->_torn(0);
  return $event;
}


sub release {
  my ( $self ) = @_;
  if (my $fh = $self->_fh) { close $fh; $self->_fh(undef) }
  if (my $lock = $self->_lock_fh) { close $lock; $self->_lock_fh(undef) }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Session - Internal writer of one session journal, holding its lock

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    # Made by Langertha::Raider::SessionStore->create / ->open.
    my $run = $session->next_run;                       # 'r3' after two runs
    $session->append('message', run => $run, role => 'user', content => 'hi');
    say $session->id, ' ', $session->path;
    $session->release;                                  # or let it go out of scope

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The one writer of a session journal (ADR 0015). Constructing it takes an
exclusive, non-blocking C<flock> on F<< <id>.lock >> next to the journal
and fails at once with C<session ID is in use> when another writer --
in this process or another -- holds it. The lock is held until
L</release> or until the object is destroyed.

On opening, the journal is read once (L</journal>): numbering continues
after its last C<seq> and its last run, and when the last line was cut off
(a crash mid-write) the next append starts on a fresh line.

=head2 id

The session id. Required.

=head2 path

The journal file, a L<Path::Tiny>. Required; it must exist.

=head2 clock

Code reference returning epoch seconds for the C<time> of an event.
Defaults to L<Time::HiRes/time>.

=head2 journal

The L<Langertha::Raider::Session::Journal> as it was when the session was
opened (read under the lock) -- what a resume replays.

=head2 lock_path

F<< <id>.lock >> next to the journal.

=head2 is_open

True until L</release>.

=head2 next_run

    my $run = $session->next_run;   # 'r1', 'r2', ...

The id of the next run of this session, counting on from the runs already
in the journal.

=head2 append

    my $event = $session->append('tool.call', run => 'r1', call => 'c1', name => 'bash', ...);

Writes one event as one line and flushes it: the fields plus C<v> (1),
C<seq>, C<time> and C<type>. Returns the event. Croaks C<cannot write
FILE: ...> when the line cannot be written; the next event then starts on
a fresh line, so a partly written one damages only itself.

=head2 release

Closes the journal and gives up the lock. Appending afterwards croaks.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SessionStore>

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
