package IPC::Lock::WithTTL;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;
use Smart::Args;
use Class::Accessor::Lite (
    rw => [qw(ttl)],
    ro => [qw(file kill_old_proc)],
   );
use Fcntl qw(:DEFAULT :flock :seek);

sub new {
    args(my $class,
         my $file          => { isa => 'Str' },
         my $ttl           => { isa => 'Int',  default => 0 },
         my $kill_old_proc => { isa => 'Bool', default => 0 },
        );

    my $self = bless {
        file          => $file,
        ttl           => $ttl,
        kill_old_proc => $kill_old_proc,
        #
        _fh           => undef,
    }, $class;

    return $self;
}

sub _fh {
    args(my $self);

    unless ($self->{_fh}) {
        open $self->{_fh}, '+>>', $self->file or croak $!;
    }

    return $self->{_fh};
}

sub acquire {
    args(my $self,
         my $ttl => { isa => 'Int', optional => 1 },
        );
    $self->ttl($ttl) if $ttl;

    my $fh = $self->_fh;
    flock $fh, LOCK_EX or return;

    seek $fh, 0, SEEK_SET;
    my($heartbeat) = <$fh>;
    $heartbeat ||= "0 0";
    my($pid, $expiration) = split /\s+/, $heartbeat;
    $pid += 0; $expiration += 0;

    my $now = time();
    my $new_expiration;
    my $acquired = 0;
    if ($pid == 0) {
        # Previous task finished successfully
        if ($now >= $expiration) {
            # expired
            $new_expiration = $self->update_heartbeat;
            $acquired = 1;
        } else {
            # not expired
            $acquired = 0;
        }
    } elsif ($pid != $$) {
        # Other task is in process?
        if ($now >= $expiration) {
            # expired (Last task may have terminated abnormally)
            $new_expiration = $self->update_heartbeat;

            if ($self->kill_old_proc && $pid > 0) {
                kill 'KILL', $pid;
            }
            $acquired = 1;
        } else {
            # not expired (Still running)
            $acquired = 0;
        }
    } else {
        # Previous task done by this process
        if ($now >= $expiration) {
            # expired (Last task may have terminated abnormally)
            $new_expiration = $self->update_heartbeat;
            $acquired = 1;
        } else {
            # not expired (Last task may have terminated abnormally)
            $new_expiration = $self->update_heartbeat;
            $acquired = 1;
        }
    }

    flock $fh, LOCK_UN;
    if ($acquired) {
        return wantarray ? (1, { pid => $$,   expiration => $new_expiration })
                         : 1;
    } else {
        return wantarray ? (0, { pid => $pid, expiration => $expiration })
                         : 0;
    }
}

sub release {
    args(my $self);

    $self->update_heartbeat(pid => 0);
    undef $self->{_fh};

    return 1;
}

sub update_heartbeat {
    args(my $self,
         my $pid => { isa => 'Int', default => $$ },
       );

    my $fh = $self->_fh;

    my $expiration = time() + $self->ttl;

    seek $fh, 0, SEEK_SET;
    truncate $fh, 0;
    print {$fh} join(' ', $pid, $expiration)."\n";

    return $expiration;
}

1;

__END__

=encoding utf-8

=begin html

<a href="https://travis-ci.org/hirose31/IPC-Lock-WithTTL"><img src="https://travis-ci.org/hirose31/IPC-Lock-WithTTL.png?branch=master" alt="Build Status" /></a>
<a href="https://coveralls.io/r/hirose31/IPC-Lock-WithTTL?branch=master"><img src="https://coveralls.io/repos/hirose31/IPC-Lock-WithTTL/badge.png?branch=master" alt="Coverage Status" /></a>

=end html

=head1 NAME

IPC::Lock::WithTTL - run only one process up to given timeout

=head1 SYNOPSIS

    use IPC::Lock::WithTTL;
    
    my $lock = IPC::Lock::WithTTL->new(
        file          => '/tmp/lockme',
        ttl           => 5,
        kill_old_proc => 0,
       );
    
    my($r, $hb) = $lock->acquire;
    
    if ($r) {
        infof("Got lock! yay!!");
    } else {
        critf("Cannot get lock. Try after at %d", $hb->{expiration});
        exit 1;
    }
    
    $lock->release;

=head1 DESCRIPTION

IPC::Lock::WithTTL provides inter process locking feature.
This locking has timeout feature, so we can use following cases:

    * Once send an alert email, don't send same kind of alert email within 10 minutes.
    * We want to prevent the situation that script for failover some system is invoked more than one processes at same time and invoked many times in short time.

=head1 DETAIL

=head2 SEQUENCE

    1. flock a heartbeat file (specified by file param in new) with LOCK_EX
       return if failed to flock.
    2. read a heartbeat file and examine PID and expiration (describe later)
       return if I should not go ahead.
    3. update a heartbeat file with my PID and new expiration.
    4. ACQUIRED LOCK
    5. unlock a lock file.
    6. process main logic.
    7. RELEASE LOCK with calling $lock->release method.
       In that method update a heartbeat file with PID=0 and new expiration.

=head2 DETAIL OF EXAMINATION OF PID AND EXPIRATION

Format of a heartbeat file (lock file) is:

    PID EXPIRATION

Next action table by PID and expiration

    PID       expired?  Next action      Description
    =========================================================================
    not mine  yes       acquired lock*1  Another process is running or
    - - - - - - - - - - - - - - - - - -  exited abnormally (without leseasing
    not mine  no        return           lock).
    -------------------------------------------------------------------------
    mine      yes       acquired lock    Previously myself acquired lock but
    - - - - - - - - - - - - - - - - - -  does not release lock.
    mine      no        acquired lock
    -------------------------------------------------------------------------
    0         yes       acquired lock    Previously someone acquired and
    - - - - - - - - - - - - - - - - - -  released lock successfully.
    0         no        return
    -------------------------------------------------------------------------
    
    *1 try to kill another process if you enable kill_old_proc option in new().

=head1 METHODS

=over 4

=item B<new>($args:Hash)

    file => Str (required)
      File path of heartbeat file. IPC::Lock::WithTTL also flock this file.
    
    ttl  => Int (default is 0)
      TTL to exipire. expiration time set to now + TTL.
    
    kill_old_proc => Boolean (default is 0)
      Try to kill old process which might exit abnormally.

=item B<acquire>(ttl => $TTL:Int)

Try to acquire lock. ttl option set TTL to expire (override ttl in new())

This method returns scalar or list by context.

    Scalar context
    =========================================================================
      Acquired lock successfully
        1
      -----------------------------------------------------------------------
      Failed to acquire lock
        0
    
    List context
    =========================================================================
      Acquired lock successfully
        (1, { pid => PID, expiration => time_to_expire })
        PID is mine. expiration is setted by me.
      -----------------------------------------------------------------------
      Failed to acquire lock
        (0, { pid => PID, expiration => time_to_expire })
        PID is another process. expiration is setted by another process.

=item B<release>()

Update a heartbeat file (PID=0 and new expiration) and release lock.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/IPC-Lock-WithTTL>

  git clone git://github.com/hirose31/IPC-Lock-WithTTL.git

patches and collaborators are welcome.

=head1 SEE ALSO

L<IPC::Lock|IPC::Lock>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 :
