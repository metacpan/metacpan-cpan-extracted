#!perl

package File::Lock::Multi::Fuser;

use strict;
use warnings (FATAL => 'all');

use File::Lock::Multi;
use base q(File::Lock::Multi);

use Linux::Fuser 1.5;
use Carp q(croak);

__PACKAGE__->mk_accessors(qw(_fuser _fh));

return 1;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->_fuser(Linux::Fuser->new());
  return $self;
}

sub locked {
  my $self = shift;
  return $self->_fh ? 1 : 0;
}

sub lockers {
  my $self = shift;
  my @procs = $self->_fuser->fuser($self->file);
  my @ids;
  foreach my $proc (@procs) {
    my $id = $proc->pid;
    my $fd = $proc->filedes->fd;
    push(@ids, "$id:$fd");
  }
  return @ids;
}

sub _release {
  my $self = shift;
  $self->_fh->close;
  $self->_fh(undef);
  return 1;
}

sub _lock {
  my $self = shift;
  if(open(my $fh, '>>', $self->file)) {
    my $fn = fileno($fh);
    my $id = "$$:$fn";
    $self->_fh($fh);
    return $id;
  } else {
    croak "open ", $self->file, " for write: $!";
  }
}

__END__

=pod

=head1 NAME

File::Lock::Multi::Fuser - Lock files based on how many times they are open

=head1 DESCRIPTION

This module provides a linux-specific concurrent locking mechanism. It
uses the /proc filesystem to determine how many times a lockfile is open,
and counts each open filehandle as a "lock". Locks are obtained by opening
the given lockfile in append mode, which means that if the file does not
exist when you attempt to gain (or check for) a lock, it will be created.

=head1 CAVEATS

C<File::Lock::Multi::Fuser> makes use of L<Linux::Fuser> to obtain the
list of processes that have opened the file -- it then looks in /proc
to see how many times each process has the file opened. There is a ticket
opened with the Linux::Fuser manpage
(L<http://rt.cpan.org/Public/Bug/Display.html?id=43979>) requesting
that the latter functionality be added there.

C<File::Lock::Multi::Fuser> considers B<any> filehandle that is opened
on your lockfile (read or write, flock'ed or not) to be a "lock". There
is a /proc extension ("fdinfo") that can give more detailed information
about what processes are doing with your files, so options may be added
to refine this in the future.

Since the "fd" directories in the /proc filesystem are protected, you
can only "see" locks if you are root, or the locks have been taken out
by processes that match your userid.

=head1 LICENSE

Copyright 2009 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

L<File::Lock::Multi>, L<Linux::Fuser>

=cut

