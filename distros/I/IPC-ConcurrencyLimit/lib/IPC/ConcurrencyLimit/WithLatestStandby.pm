package IPC::ConcurrencyLimit::WithLatestStandby;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.17';

use Carp qw(croak);
use Time::HiRes qw(sleep time);
use IPC::ConcurrencyLimit;

sub new {
    my $class  = shift;
    my %params = @_;
    my $type   = delete $params{type};
    $type = 'Flock' if not defined $type;
    croak( __PACKAGE__ . " only supports 'Flock' for now")
        if $type ne 'Flock';

    if (defined $params{max_procs} and $params{max_procs}!=1) {
        croak( __PACKAGE__ . " does not support max_procs!=1, use multiple objects instead.");
    }

    my $process_name_change= $params{process_name_change} || 0;
    my $path=        $params{path}          || die __PACKAGE__ . '->new: missing mandatory parameter `path`';
    my $file_prefix= $params{file_prefix}   || "";
    my $poll_time=   $params{poll_time}     || $params{interval} || 1; # seconds to poll (may be fraction)
    my $retries=     $params{retries}       || undef;
    my $timeout=     $params{timeout}       || undef;
    my $debug=       $params{debug}         || 0; # show debug?
    my $debug_sub=   $params{debug_sub}     || undef;

    my $retry_sub= (ref $retries)     ? $retries :
                   (defined $retries &&
                    defined $timeout) ? sub { $_[0] <= $retries && $_[2] <= $timeout } :
                   (defined $retries) ? sub { $_[0] <= $retries } :
                   (defined $timeout) ? sub { $_[2] <= $timeout } :
                                        sub { 1 };

    # primary is replace by standby1, is replaced by
    # standby2, is replaced by standby3. However, standby1
    # will exit when standby2's lock is held by another process.
    my @names= map { ($file_prefix ? "$file_prefix.$_" : $_) }
                     qw(primary standby1 standby2 standby3);
    my @lockers= map {
        IPC::ConcurrencyLimit->new(
            type => $type,
            max_procs => 1,
            # future proofing
            $type eq "Flock" ? (
                file_prefix => $_,
                path => $path,
            ) : (),
        )
    } @names;

    return bless {
        poll_time   => $poll_time,
        timeout     => $timeout,    # FYI
        retries     => $retries,    # FYI
        lock_name   => \@names,
        locker      => \@lockers,
        debug       => $debug,
        debug_sub   => $debug_sub || sub { warn @_,"\n" },
        retry_sub   => $retry_sub,
        process_name_change => $process_name_change,
    }, $class;
}

sub _diag {
    my ($self, $fmt, @args)= @_;
    if (!@args) {
        $self->{debug_sub}->($fmt);
    } else {
        $self->{debug_sub}->(sprintf $fmt, @args);
    }
}


sub get_lock {
    my ($self) = @_;

    my $locker= $self->{locker};
    my $names= $self->{lock_name};

    my $old_oh= $0;

    $0 = "$old_oh - acquire"
        if $self->{process_name_change};

    # try to get the rightmost lock (standby3) if we don't get it
    # then we exit out. this shouldn't really happen if other things
    # are sane, for instance when $poll_time is much smaller than
    # the rate we allocate new workers.
    my $locker_id= $#$locker;
    if ( $locker->[$locker_id]->get_lock() ) {
        $self->_diag( "Got a $names->[$locker_id] lock")
            if $self->{debug};
    } else {
        $self->_diag( "Failed to get a $names->[$locker_id] lock, entry lock is held by another process" )
            if $self->{debug};
        $0 = "$old_oh - no-lock-acquired"
            if $self->{process_name_change};
        return;
    }

    # Each worker tries to acquire the lock to its left. If it does
    # then it abandons its old lock. If that means the worker ends up
    # on locker_id 0 then they are done, and can do work.
    # The first standby worker also looks to its right to see if there
    # is a replacement process for it, if there is it exits, leaving
    # a gap and letting the replacements shuffle left.
    my $tries= 0;
    my $lock_tries= 0;
    my $standby_start= time();
    my $lock_start= time();
    my $poll_time= $self->{poll_time};

    while ( $locker_id > 0 ) {
        $0 = "$old_oh - $names->[$locker_id]"
            if $self->{process_name_change};

        # can we shuffle our lock left?
        if ( $locker->[$locker_id - 1]->get_lock() ) {
            $self->_diag( "Got a $names->[$locker_id -1] lock, dropping old $names->[$locker_id] lock")
                if $self->{debug};
            # yep, we got the lock to the left, so drop our old lock,
            # and move the pointer left at the same time.
            $locker->[ $locker_id-- ]->release_lock();
            $lock_tries= 0;
            $lock_start= time();
            next;
        }

        unless ($self->{retry_sub}->(++$tries, ++$lock_tries, time - $standby_start, time - $lock_start)) {
            $0 = "$old_oh - no-lock-timeout"
                if $self->{process_name_change};
            return;
        }

        # check if we are the first standby worker.
        if ( $locker_id == 1 ) {
            # yep - we are the first standby worker,
            # so check if the lock to our right is being held:
            if ( $locker->[$locker_id + 1]->get_lock() ) {
                # we got the lock, which means nothing else
                # holds it. so we release the lock and move on.
                $locker->[$locker_id + 1]->release_lock();
            } else {
                $self->_diag(
                    "A newer worker is holding the $names->[$locker_id+1] lock, will exit to let it take over"
                ) if $self->{debug};
                # we failed to get the lock, which means there is a newer
                # process that can replace us so return/exit - this frees up
                # our lock and lets the newer process to move into our position.
                $0 = "$old_oh - no-lock-retired"
                    if $self->{process_name_change};
                return;
            }
        }

        # nope - the lock to our left is being held so sleep a while before
        # we try again. We use the rand and the formula so that items to the
        # right poll faster than items to the left, and to reduce the chance
        # that lock holder 1 and lock holder 3 poll lock 2 at the same time
        # forever. The formula guarantees that items to the left poll faster,
        # and the rand ensures there is jitter.
        sleep rand(($poll_time / $locker_id)*2);
    }

    # assert that $locker_id is 0 at this point.
    die "panic: We should not reach this point with \$locker_id larger than 0, got $locker_id"
        if $locker_id;

    $self->_diag("Got $names->[$locker_id] lock, we are allowed to do work.")
        if $self->{debug};

    # at this point we should be $locker_id == 0 and we can do work.
    if ($self->{process_name_change}) {
        if ($self->{process_name_change} > 1) {
            $0 = $old_oh;
        } else {
            $0 = "$old_oh - $names->[$locker_id]"
        }
    }
    return 1;
}


sub is_locked {
    my $self = shift;
    return $self->{locker}[0]->is_locked(@_);
}

sub release_lock {
    my $self = shift;
    return $self->{locker}[0]->release_lock(@_);
}

sub lock_id {
    my $self = shift;
    return $self->{locker}[0]->lock_id(@_);
}

sub heartbeat {
    my $self = shift;
    return $self->{locker}[0]->heartbeat;
}


1;

__END__


=head1 NAME

IPC::ConcurrencyLimit::WithLatestStandby - IPC::ConcurrencyLimit with latest started working as standby

=head1 SYNOPSIS

  use IPC::ConcurrencyLimit::WithLatestStandby;

  sub run {
    my $limit = IPC::ConcurrencyLimit::WithLatestStandby->new(
      type              => 'Flock', # default, and currently only supported type
      path              => '/var/run/myapp',
    );

    if ($limit->get_lock) {
        # Got one of the worker locks (ie. number $id)
        do_work();
    } else {
        print "Failed to get a lock, replaced by a newer standby worker.\n";
    }
    # lock released with $limit going out of scope here
  }

  run();
  exit();

=head1 DESCRIPTION

This module behaves much the same as L<IPC::ConcurrencyLimit> when configured
for a single lock, with the exception of what happens when the lock is already
held by another process. Instead of simply returning false, the lock will block
and the worker will go into a "standby queue" waiting to acquire the master lock.
If the master lock is released then the next worker in the queue takes over,
and additionally workers in standby mode are managed such that older standby
workers "bow out" when they detect a newer standby worker is available to take
over waiting.  When configured and used properly you are guaranteed to get the
most recent worker "taking over" processing every time.

When using this module at any one time there may be up to four workers alive.
One master process, one primary standby, one secondary standby, and one new
standby, each one corresponding to one of four locks, numbered 0 to 3. Each
new worker starts by acquiring the rightmost lock, #3, and then tries to
"move left" by also acquiring the preceding lock, which when successful leads
to it dropping its old lock. When the worker ends up holding the master lock #0
it can do work. At the same time the holder of the primary standby lock #1
also polls to see if the secondary standby lock #2 is held. If it is then the holder
of the lock #1 exits, allowing the secondary standby lock to "move left" and
take over standby responsibility.

So long as the polling time is sufficiently faster than the frequency with which
new processes are started you will generally see the most recently started worker
take over from the master. IOW, if you use the default poll time of 1 second
and you start new workers minutely you can be confident that the new worker will
be reasonably "fresh".

=head2 Options

C<IPC::ConcurrencyLimit::WithLatestStandby> does not accept all the regular
C<IPC::ConcurrencyLimit> options. Currently it is restricted to using
Flock internally, and max_procs may only be set to 1. There are also additional
parameters which may be supplied.

=over 4

=item poll_time

=item interval

This is the base amount of time that we should wait between checking if a lock
is still held by another process. It is not the actual time that we may wait,
which may be anything from 0 to 2 times the stated value, chosen randomly each
time we sleep. Fractional seconds may be specified.

Note that new standby workers, and secondary standby workers poll at a faster
rate than this value. The actual time is determined by $poll_time/$lock_id,
meaning that a secondary standby worker polls twice as often as a primary standby
worker. (For the lock algorithm to work properly we need to ensure that the
poll times associated with each lock differ, and are not synchronized).

=item retries

Specify the maximum number of times we will attempt to get a lock. Note that
due to the random sleep in our wait-and-retry loop this cannot be cleanly
mapped to time. For that you can use the C<timeout> setting, with or instead
of the retries logic.

Addtionally one can provide a code reference to control the retry logic.
The sub will be called with four arguments:

    my $should_retry= $retry_sub->($tries, $lock_tries, $elapsed, $lock_elapsed);

$tries is an integer which is incremented every time we try to acquire a lock
internally, $lock_tries is similar but every time we successfully acquire a
lock and "move left" it is reset to 0. $elapsed is the amount of time in secs
(with fractional part) that has elapsed since we acquired the initial "new
standby worker" lock, and $lock_elapsed is the amount of time since we last
acquried a lock, with the timer being reset when we "move left". If the retry
sub returns true then we retry, if it returns false then we exit out of the
lock-wait loop.

Note that providing a reference for C<retries> means that the C<timeout> option
is ignored.

=item timeout

Specify the maximum amount of time to wait for acquiring the master lock
before exiting. This option may be combined with a non-reference C<retries> value.
See also C<retries> for more details about finer grained control of the
lock wait loop.

=item path

Specify the directory for Flock.

=item file_prefix

Specify a file prefix so that the files for this lock object can share
a directory with other lock objects.

=item debug

Emit diagnostics when running. See debug_sub.

=item debug_sub

A sub to use for emitting diagnostics. Will be called with a single argument
containing text to output.

=item process_name_change

Use this to tell the difference between active and standby workers in a process
list. When this option is not disabled the C<$0> for the running process is
updated to include the lock name that is currently held. This way you can see
what state the worker is in by inspecting the process list using a tool like
C<top> or C<ps auwx>.

When this option is enabled C<IPC::ConcurrencyLimit::WithLatestStandby>
will modify the running processes name via modification of C<$0> to show the
state of the lock process and which lock is held if any.
This is only supported on newer Perls and might not work on all
operating systems. On my testing Linux, a process that showed as
C<perl foo.pl> in the process table before using this feature was
shown as C<foo.pl - standby1> while in standby mode and as
C<foo.pl - primary> after getting the main worker lock.

Note this mode is slightly different from the same option in
C<IPC::ConcurrencyLimite::WithStandby> as it will NOT normally restore the
previous value of $0 after exiting C<get_lock()>. If you want that
behavior set C<process_name_change> to a value larger than 1.

Due to an oversight this parameter defaults to on or "enabled" in
v0.15, and in later versions defaults to off or "disabled", you should
explicitly set it if you wish to be sure of what will happen.

=back

=head1 SEE ALSO

See also C<IPC::ConcurrencyLimit::WithStandby> for a similar module but
with different simpler semantics than this one.

=head1 AUTHOR

Yves Orton, C<yves@cpan.org>

=head1 ACKNOWLEDGMENT

This module was originally developed for booking.com.
With approval from booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2015 Yves Orton. All rights reserved.

 This code is available under the same license as Perl version
 5.8.1 or higher.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

