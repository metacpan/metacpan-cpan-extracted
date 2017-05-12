package IPC::ConcurrencyLimit::Lock::NFS;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use File::Path qw();
use File::Spec;
use Fcntl qw(:DEFAULT :flock);
use File::SharedNFSLock;

use IPC::ConcurrencyLimit::Lock;
our @ISA = qw(IPC::ConcurrencyLimit::Lock);

sub new {
  my $class = shift;
  my $opt = shift;

  my $max_procs = $opt->{max_procs}
    or croak("Need a 'max_procs' parameter");
  my $path = $opt->{path}
    or croak("Need a 'path' parameter");

  my $h = {};
  my $self = bless {
    max_procs => $max_procs,
    path      => $path,
    the_lock  => undef,
    lock_file => undef,
    id        => undef,
    unique    => "$h",
    unique_s  => $h,
  } => $class;
  $self->{unique} =~ s/[^A-Za-z0-9.-_]+//g;
  $self->{unique} =~ s/HASH//;

  $self->_get_lock() or return undef;

  return $self;
}

sub _get_lock {
  my $self = shift;

  File::Path::mkpath($self->{path});

  for my $worker (1 .. $self->{max_procs}) {
    my $lock_file = File::Spec->catfile($self->{path}, $worker);

    my $lock = File::SharedNFSLock->new(
      file => $lock_file,
      timeout_acquire => 0,
      timeout_stale => 0,
      unique_token => $self->{unique},
    );

    if ($lock->lock()) {
      $self->{the_lock} = $lock;
      $self->{id} = $worker;
      $self->{lock_file} = $lock_file;
      last;
    }
  }

  return undef if not $self->{id};
  return 1;
}

sub lock_file { $_[0]->{lock_file} }
sub path { $_[0]->{path} }

# Normally needs implementing to release the lock,
# but in this case, we just hold on to the file handle that's flocked.
# Thus, it will be released as soon as this object is freed.
#sub DESTROY {}

1;

__END__


=head1 NAME

IPC::ConcurrencyLimit::Lock::NFS - Locking via NFS

=head1 SYNOPSIS

  use IPC::ConcurrencyLimit;

=head1 DESCRIPTION

This locking strategy uses L<File::SharedNFSLock> to implement
locking on NFS shares across multiple hosts.
The locking technique employed by C<File::SharedNFSLock>
should work on other, local file systems as well. If in doubt,
do your own testing.

B<Beware:> If processes are killed harshly without being able
to clean up, stale lock files may remain that are not recoverable.
In principle, C<File::SharedNFSLock> can reclaim them after
a timeout, but that feature does not seem to make a lot of
sense in this context. All C<File::SharedNFSLock> gotchas apply.

=head1 METHODS

=head2 new

Given a hash ref with options, attempts to obtain a lock in
the pool. On success, returns the lock object, otherwise undef.

Required options:

=over 2

=item C<path>

The directory that will hold the lock files.
Created if it does not exist.
It is suggested not to use a directory that may hold other data.

=item C<max_procs>

The maximum no. of locks (and thus usually processes)
to allow at one time.

=back

=head2 lock_file

Returns the full path and name of the lock file.

=head2 path

Returns the directory in which the lock files resides.

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

 (C) 2011 Steffen Mueller. All rights reserved.
 
 This code is available under the same license as Perl version
 5.8.1 or higher.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

