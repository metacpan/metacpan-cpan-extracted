package IPC::ConcurrencyLimit::Lock::MySQL;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw(croak);
use Class::XSAccessor {
  accessors => [qw(dbh id timeout)],
  getters => [qw(make_new_dbh_callback lock_name)],
};

use IPC::ConcurrencyLimit::Lock;
our @ISA = qw(IPC::ConcurrencyLimit::Lock);

sub new {
  my $class = shift;
  my $opt = shift;

  my $max_procs = $opt->{max_procs}
    or croak("Need a 'max_procs' parameter");

  my $dbh_callback = $opt->{make_new_dbh};
  $dbh_callback && ref($dbh_callback) eq 'CODE'
    or croak("Need a 'make_new_dbh' callback as parameter");

  my $lock_name = $opt->{lock_name};
  defined $lock_name
    or croak("Need a 'lock_name' parameter for the lock");

  my $self = bless {
    lock_name => $lock_name,
    max_procs => $max_procs,
    make_new_dbh_callback => $dbh_callback,
    timeout => $opt->{timeout}||0,
    dbh => undef,
    id => undef,
  } => $class;

  $self->_get_lock() or return undef;

  return $self;
}

sub _get_dbh {
  my $self = shift;
  my $dbh = $self->dbh;

  if (not defined $dbh) {
    $dbh = $self->make_new_dbh_callback->($self);
    die "Could not get a DB handle for getting a lock"
      if not defined $dbh;
    $self->dbh($dbh);
  }

  return $dbh;
}

sub _get_lock {
  my $self = shift;

  my $dbh = $self->_get_dbh;
  my $lock_name_base = $self->lock_name;
  my $timeout = $self->timeout;
  for my $worker (1 .. $self->{max_procs}) {
    my $lock_name = $lock_name_base . "_" . $worker;
    my $query = "SELECT GET_LOCK(?, ?)";
    my $res = $dbh->selectcol_arrayref($query, undef, $lock_name, $timeout);
    if (not defined $res or not ref($res) eq 'ARRAY') {
      die "Failed to execute query '$query': " . $dbh->errstr;
    }
    if (@$res && $res->[0]) {
      $self->id($worker);
      last;
    }
  }

  return undef if not $self->{id};
  return 1;
}

sub _release_lock {
  my $self = shift;
  my $dbh = $self->dbh;
  return if not $dbh;
  my $id = $self->id;
  return if not $id;
  my $query = "SELECT RELEASE_LOCK(?)";
  $dbh->do($query, undef, $self->lock_name . "_" . $id);
}

sub DESTROY {
  my $self = shift;
  $self->_release_lock();
}

1;

__END__


=head1 NAME

IPC::ConcurrencyLimit::Lock::MySQL - Locking via MySQL GET_LOCK

=head1 SYNOPSIS

  use IPC::ConcurrencyLimit;

=head1 DESCRIPTION

This locking strategy uses MySQL's C<GET_LOCK> to implement
locking across multiple hosts.

=head1 METHODS

=head2 new

Given a hash ref with options, attempts to obtain a lock in
the pool. On success, returns the lock object, otherwise undef.

Required parameters:

=over 2

=item C<lock_name>

The name prefix for the named C<GET_LOCK> locks to use.
Make sure this doesn't collide with any other locks.

=item C<make_new_dbh>

A code reference that, when called, will return a B<NEW>
database handle for use in locking. If it returns a handle
that is used for other purposes as well, there can be
strange action at a distance since MySQL allow exactly one
lock at a time per connection. If a second C<GET_LOCK>
is issued for the same connection, the old lock will
be silently released!

=item C<max_procs>

The maximum no. of locks (and thus usually processes)
to allow at one time.

=back

Options:

=over 2

=item C<timeout>

The time-out in seconds when trying to obtain a lock. Defaults to
0, non-blocking.

=back

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

=head1 ACKNOWLEDGMENT

This module was originally developed for booking.com.
With approval from booking.com, this module was generalized
and put on CPAN, for which the author would like to express
his gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2011, 2013 Steffen Mueller. All rights reserved.
 
 This code is available under the same license as Perl version
 5.8.1 or higher.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

