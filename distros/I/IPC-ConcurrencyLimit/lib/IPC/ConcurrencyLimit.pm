package IPC::ConcurrencyLimit;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.17';

use Carp qw(croak);

sub new {
  my $class = shift;
  my %params = @_;
  my $type = delete $params{type};
  $type = 'Flock' if not defined $type;

  my $lock_class = $class . "::Lock::$type";
  if (not eval "require $lock_class; 1;") {
    my $err = $@ || 'Zombie error';
    croak("Invalid lock type '$type'. Could not load lock class '$lock_class': $err");
  }

  my $self = bless {
    opt => {
      max_procs => 1,
      %params,
    },
    lock_class => $lock_class,
    lock_obj => undef,
  } => $class;

  return $self;
}

sub get_lock {
  my $self = shift;
  return $self->{lock_obj}->id() if $self->{lock_obj};
  
  my $class = $self->{lock_class};
  $self->{lock_obj} = $class->new($self->{opt});

  return $self->{lock_obj} ? $self->{lock_obj}->id() : undef;
}

sub is_locked {
  my $self = shift;
  return $self->{lock_obj} ? 1 : 0;
}

sub release_lock {
  my $self = shift;
  return undef if not $self->{lock_obj};
  $self->{lock_obj} = undef;
  return 1;
}

sub lock_id {
  my $self = shift;
  return undef if not $self->{lock_obj};
  return $self->{lock_obj}->id;
}

sub heartbeat {
  my $self = shift;
  my $lock = $self->{lock_obj};
  return if not $lock;
  if (not $lock->heartbeat) {
    $self->release_lock;
    return();
  }
  return 1;
}

1;

__END__


=head1 NAME

IPC::ConcurrencyLimit - Lock-based limits on cooperative multi-processing

=head1 SYNOPSIS

  use IPC::ConcurrencyLimit;
  
  sub run {
    my $limit = IPC::ConcurrencyLimit->new(
      type      => 'Flock', # that's also the default
      max_procs => 10,
      path      => '/var/run/myapp', # an option to the locking strategy
    );
    
    # NOTE: when $limit goes out of scope, the lock is released
    my $id = $limit->get_lock;
    if (not $id) {
      warn "Got none of the worker locks. Exiting.";
      exit(0);
    }
    else {
      # Got one of the worker locks (ie. number $id)
      do_work();
    }
    
    # lock released with $limit going out of scope here
  }
  
  run();
  exit();

=head1 DESCRIPTION

This module implements a mechanism to limit the number of concurrent
processes in a cooperative multiprocessing environment. This is an alternative
to, for example, running several daemons.

Roughly speaking,
a typical setup would be the following:

=over 2

=item *

Cron starts a new process every minute.

=item *

The process attempts to get a lock as shown in synopsis.

=item *

If it obtains a lock, it starts working and exits when the
work is done.

=item *

If not, C<max_procs> processes are already working, so it exits.

=back

This has several distinct advantages over daemons.

=over 2

=item *

Processes do not run as long. Small memory leaks are less likely to
become a problem.

=item *

Rolling out new code is trivial. No need to do any daemon restarting
and worrying about interrupting a unit of work.

=item *

No complicated master/slave setups and process/thread pooling.

=back

The implementation uses some form of locking to limit concurrency:
There's simply a limited number of locks to go around. The detailed
locking implementation is chosen using the C<type> parameter to the
constructor. The base distributions ships with one locking strategy only:
L<IPC::ConcurrencyLimit::Lock::Flock> for a file-locking based
concurrency limit.

Among the other potential strategies that are not part of
this distribution are NFS-based locking using L<File::SharedNFSLock>
or using MySQL's C<GET_LOCK>. Both of these schemes would
allow limiting concurrency across multiple hosts without a
special-purpose daemon.

=head1 METHODS

=head2 new

Creates a new concurrency limit. Creating the object
does B<not> lock anything. This requires a followup
call to the C<get_lock()> method!

After calling C<get_lock()>, the lock will be held
by the C<IPC::ConcurrencyLimit> object and released
when either C<release_lock()> is called or the
C<IPC::ConcurrencyLimit> object is freed.

Takes named parameters, one of which is the C<type>
parameter, which specifies the type of lock to use
and defaults to C<Flock>.

The C<max_procs> option indicates the maximum
number of locks that can be held at the same time
and thus usually the maximum no. of running processes.
It defaults to 1.

All concurrency limits that refer to the same resource/limit
B<must> use the same setting for C<max_procs>. If not, the
behaviour is undefined.

All other named parameters will be passed as options
to the lock implementation. See L<IPC::ConcurrencyLimit::Lock::Flock>
or other implementations.

=head2 get_lock

Creates the actual lock and if successful, returns its id
(starting from 1, not 0).

Returns undef if locking was unsuccessful.
Multiple calls do not stack. They will simply return
the same lock id as long as a lock is held.

B<WARNING!> make sure the variable holding the lock remains in scope at all
times, otherwise the lock will be released and locking will become apparently
ineffective. This is the most common reason for having several concurrent
processes running when only one is expected to be alive.

=head2 release_lock

Releases the lock. Returns 1 if a lock has been
released or undef if there had been no lock to be
released.

=head2 is_locked

Returns whether we have a lock.

=head2 lock_id

Returns the id of the lock or undef if there is none.

=head2 heartbeat

Check whether the lock is still valid. If so,
returns true. Otherwise, it releases (destroys) the lock
and returns false.

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

Yves Orton

David Morel

Matt Koscica, C<mattk@cpan.org>

Ivan Kruglov

=head1 ACKNOWLEDGMENT

This module was originally developed for Booking.com.
With approval from Booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2011-2015 Steffen Mueller. All rights reserved.
 
 This code is available under the same license as Perl version
 5.8.1 or higher.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

