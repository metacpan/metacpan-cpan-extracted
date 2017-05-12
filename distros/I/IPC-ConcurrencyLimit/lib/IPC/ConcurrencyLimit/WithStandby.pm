package IPC::ConcurrencyLimit::WithStandby;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.17';
use Carp qw(croak);
use Time::HiRes qw(sleep);
use IPC::ConcurrencyLimit;

sub new {
  my $class = shift;
  my %params = @_;
  my $type = delete $params{type};
  $type = 'Flock' if not defined $type;

  my $standby_type = delete($params{standby_type}) || $type;

  foreach my $t ($type, $standby_type) {
    my $lock_class = "IPC::ConcurrencyLimit::Lock::$t";
    if (not eval "require $lock_class; 1;") {
      my $err = $@ || 'Zombie error';
      croak("Invalid lock type '$t'. Could not load lock class '$lock_class': $err");
    }
  }

  my %standby;
  foreach my $key (grep /^standby_/, keys %params) {
    my $munged = $key;
    $munged =~ s/^standby_//;
    $standby{$munged} = delete $params{$key};
  }
  $standby{$_} = $params{$_} for grep !exists($standby{$_}), keys %params;

  my $main_lock = IPC::ConcurrencyLimit->new(%params, type => $type);
  my $standby_lock = IPC::ConcurrencyLimit->new(%standby, type => $standby_type);

  my $self = bless({
    main_lock => $main_lock,
    standby_lock => $standby_lock,
    retries => defined($params{retries}) ? $params{retries} : 10,
    interval => defined($params{interval}) ? $params{interval} : 1,
    process_name_change => $params{process_name_change},
  } => $class);

  return $self;
}

sub get_lock {
  my $self = shift;
  my $main_lock = $self->{main_lock};

  # Convert retries to a sub if it's not one already
  if ( ref $self->{retries} ne "CODE" ) {
      my $max_retries = $self->{retries};
      $self->{retries} = sub { return $_[0] <= $max_retries };
  }

  my $id = $main_lock->get_lock;
  return $id if defined $id;

  my $st_lock = $self->{standby_lock};
  my $st_id = $st_lock->get_lock;
  return undef if not defined $st_id;

  # got standby lock, go into wait-retry loop
  my $old_proc_name;
  if ($self->{process_name_change}) {
    $old_proc_name = $0;
    $0 = "$0 - standby";
  }
  my $interval = $self->{interval};
  eval {
    my $tries = 0;
    while (1) {
      $id = $main_lock->get_lock;
      if (defined $id) {
        $st_lock->release_lock;
        last;
      }

      last unless $self->{retries}->(++$tries);
      sleep($interval) if $interval;
    }
    1;
  }
  or do {
    my $err = $@ || 'Zombie error';
    $0 = $old_proc_name if defined $old_proc_name;
    $st_lock->release_lock;
    die $err;
  };

  $0 = $old_proc_name if defined $old_proc_name;
  return $id;
}

sub is_locked {
  my $self = shift;
  return $self->{main_lock}->is_locked(@_);
}

sub release_lock {
  my $self = shift;
  return $self->{main_lock}->release_lock(@_);
}

sub lock_id {
  my $self = shift;
  return $self->{main_lock}->lock_id(@_);
}

sub heartbeat {
  my $self = shift;
  return $self->{main_lock}->heartbeat;
}

1;

__END__


=head1 NAME

IPC::ConcurrencyLimit::WithStandby - IPC::ConcurrencyLimit with an additional standby lock

=head1 SYNOPSIS

  use IPC::ConcurrencyLimit::WithStandby;
  
  sub run {
    my $limit = IPC::ConcurrencyLimit::WithStandby->new(
      type              => 'Flock', # that's also the default
      max_procs         => 10,
      path              => '/var/run/myapp',
      standby_path      => '/var/run/myapp/standby',
      standby_max_procs => 3,
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

This module provides the same interface as the regular L<IPC::ConcurrencyLimit>
module. It differs in what happens if C<get_lock> fails to get a slot for the
main limit:

If it fails to get a (or the) lock on the main limit, it will repeatedly attempt
to get the main lock until a slot for the main limit is attained or the number
of retries is exhausted. Most importantly, this supports limiting the number of
instances that continuously attempt to get the main lock (typically, this would
be limited to 1). This is implemented with a wait-retry-loop and two separate
C<IPC::ConcurrencyLimit> objects.

The options for the main limit are passed
in to the constructor as usual. The standby limit are inherited from the main
one, but all parameters prefixed with C<standby_> will override the respective
inherited parameters. For example, C<standby_type =E<gt> "MySQL"> will
enforce the use of the MySQL lock for the standby lock.

In addition to the regular C<IPC::ConcurrencyLimit> options, the constructor
accepts C<retries> as the number of retries a standby instance should do
to get the main lock. There will always be only one attempt to become
a standby process. Additionally, C<interval> can indicate a number of seconds
to wait between retries (also supports fractional seconds down to what
C<Time::HiRes::sleep> supports).

C<retries> can also be passed a code reference that will be called on every
retry, with the current attempt number as its first argument (starting at 1).
Returning false from this routine will break the loop and give up any further
attempts to acquire the lock. One example of a configuration which would
continue to attempt to acquire a lock forever would be as follows:

  my $limit = IPC::ConcurrencyLimit::WithStandby->new(
    retries           => sub { $_[0] },
    interval          => 0.01,
    maxproc           => 1,
    standby_max_procs => 1,
    ...
  );

The form above would be used to have a single process running, with a standby
process ready to take over 1/100th of a second after the active process exits,
at the expense of attempting to acquire a C<flock()> 100 times per second.

Finally, as a way to tell blocked worker processes apart from standby
processes, the module supports the C<process_name_change> option. If set to
true, then the module will modify the process name of standby processes via
modification of <$0>. It appends the string " - standby" to $0 and resets it
to the old value after timing out or getting a worker lock. This is only
supported on newer Perls and might not work on all operating systems.
On my testing Linux, a process that showed as C<perl foo.pl> in the process
table before using this feature was shown as C<foo.pl - standby> while
in standby mode and as C<foo.pl> after getting a main worker lock.
Note the curiously stripped C<perl> prefix.

=head1 WARNING!

Make sure the variable holding the lock remains in scope at all times,
otherwise the lock will be released, resulting in process churn and potential
double work. This is the most common reason for having several concurrent
processes running when only one is expected to be alive.

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

David Morel, C<david.morel@amakuru.net>

=head1 ACKNOWLEDGMENT

This module was originally developed for booking.com.
With approval from booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2012 Steffen Mueller. All rights reserved.

 This code is available under the same license as Perl version
 5.8.1 or higher.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

