package File::Lock::ParentLock;

use strict;
use warnings;

use Cwd;
use Carp;
use Fcntl;
use File::Spec;
use Proc::ProcessTable;
use File::Path qw(make_path remove_tree);

our $VERSION=0.06;

my $default_lock_name = '.lock';

use constant _PERMITTED_LOCKED_BIT => 4;
use constant _FORBIDDEN_BIT => 8;
use constant PERMITTED_NOT_LOCKED_NO_LOCK_FILE => 0;
use constant PERMITTED_NOT_LOCKED_INVALID_LOCK_FILE => 1;
use constant PERMITTED_NOT_LOCKED_STALE_LOCK_FILE => 2;
use constant PERMITTED_LOCKED_BY_US => _PERMITTED_LOCKED_BIT | 0;
use constant PERMITTED_LOCKED_BY_PARENT => _PERMITTED_LOCKED_BIT | 1;
use constant FORBIDDEN_LOCKED_BY_OTHERS => _FORBIDDEN_BIT | 0;
use constant FORBIDDEN_LOCKED_ACCESS_ERROR => _FORBIDDEN_BIT | 1;
use constant FORBIDDEN_NOT_LOCKED_DIR_AT_LOCK_FILE_PATH => _FORBIDDEN_BIT | 2;

my @msg;
$msg[PERMITTED_NOT_LOCKED_NO_LOCK_FILE] = 'No lock file';
$msg[PERMITTED_NOT_LOCKED_INVALID_LOCK_FILE] = 'Invalid lock file';
$msg[PERMITTED_NOT_LOCKED_STALE_LOCK_FILE] = 'Stale lock file (pid is dead)';
$msg[PERMITTED_LOCKED_BY_US] = 'Locked by given pid.';
$msg[PERMITTED_LOCKED_BY_PARENT] = 'Locked by the parent of the given pid';
$msg[FORBIDDEN_LOCKED_BY_OTHERS] = 'Locked by another group of processes';
$msg[FORBIDDEN_LOCKED_ACCESS_ERROR] = 'Access error. Assume locked.';
$msg[FORBIDDEN_NOT_LOCKED_DIR_AT_LOCK_FILE_PATH] = 'Access error. Dir found at lock file path.';

#--------------------------------------------

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my $self = {
	-pid => $$,
	-lockfile => $default_lock_name,
	@_,
    };
    my $lockfile=$self->{-lockfile};
    unless (File::Spec->file_name_is_absolute($lockfile)) {
	$self->{-lockfile}=File::Spec->catfile(cwd(), $lockfile);
    }
    bless($self,$class);
    return $self;
}

sub lockfile {
    my ($self, $val)=@_;
    $self->{-lockfile}=$val if defined $val;
    return $self->{-lockfile};
}    

sub pid {
    my ($self, $val)=@_;
    $self->{-pid}=$val if defined $val;
    return $self->{-pid};
}    

sub lock {
    my ($self)=@_;
    return &parentlock_lock($self->{-lockfile},$self->{-pid});
}    

sub unlock {
    my ($self)=@_;
    return &parentlock_unlock($self->{-lockfile},$self->{-pid});
}    

sub can_lock {
    my ($self)=@_;
    return &parentlock_can_lock($self->{-lockfile},$self->{-pid});
}

# deprecated; will be removed in 0.07
sub is_locked {
    my ($self)=@_;
    return &parentlock_is_locked($self->{-lockfile},$self->{-pid});
}

sub is_locked_by_us {
    my ($self)=@_;
    return &parentlock_is_locked_by_us($self->{-lockfile},$self->{-pid});
}

sub is_locked_by_others {
    my ($self)=@_;
    return &parentlock_is_locked_by_others($self->{-lockfile},$self->{-pid});
}

sub status_string {
    my ($self)=@_;
    return &parentlock_status_string($self->{-lockfile},$self->{-pid});
}

###################### procedural interface #########################

sub parentlock_lock {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    my $SUCCESS=1;
    my $FAILURE=0;
    my $status=&_lock_status($lockfile,$pid);

    if (
	$status==PERMITTED_LOCKED_BY_PARENT ||
	$status==PERMITTED_LOCKED_BY_US) {
	return $SUCCESS;
    } elsif (
	$status==PERMITTED_NOT_LOCKED_NO_LOCK_FILE ||
	$status==PERMITTED_NOT_LOCKED_INVALID_LOCK_FILE ||
	$status==PERMITTED_NOT_LOCKED_STALE_LOCK_FILE
	) {
	&_write_lock($lockfile, $pid);
	return $SUCCESS;
    } elsif (
	$status==FORBIDDEN_LOCKED_ACCESS_ERROR ||
	$status==FORBIDDEN_LOCKED_BY_OTHERS ||
	$status==FORBIDDEN_NOT_LOCKED_DIR_AT_LOCK_FILE_PATH
	) {
	return $FAILURE;
    } else {
	warn "internal error: _lock_status returned unsupported status $status";
	return $FAILURE;
    }
}

sub parentlock_unlock {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    my $SUCCESS=1;
    my $FAILURE=0;
    my $status=&_lock_status($lockfile,$pid);

    if (
	$status==PERMITTED_NOT_LOCKED_NO_LOCK_FILE or
	$status==PERMITTED_LOCKED_BY_PARENT
	) {
	return $SUCCESS;
    } elsif (
	$status==PERMITTED_LOCKED_BY_US or
	$status==PERMITTED_NOT_LOCKED_INVALID_LOCK_FILE or
	$status==PERMITTED_NOT_LOCKED_STALE_LOCK_FILE
	) {
	if (unlink $lockfile) {
	    return $SUCCESS;
	} else {
	    return $FAILURE;
	}
    } elsif (
	$status==FORBIDDEN_LOCKED_ACCESS_ERROR or
	$status==FORBIDDEN_LOCKED_BY_OTHERS or
	$status==FORBIDDEN_NOT_LOCKED_DIR_AT_LOCK_FILE_PATH
	) {
	return $FAILURE;
    } else {
	warn "internal error: _lock_status returned unsupported status $status";
	return $FAILURE;
    }
}

sub parentlock_status_string {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    my $status=&_lock_status($lockfile,$pid);
    my $msg=$msg[$status];
    $msg||="FATAL: Unknown status (status=$status)";
    return $msg;
}

sub parentlock_can_lock {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    return not (&_lock_status($lockfile,$pid) & _FORBIDDEN_BIT);
}

sub parentlock_is_locked {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    carp "parentlock_is_locked and is_locked method are deprecated! Use (parentlock_)is_locked_by_us!";
    return &_lock_status($lockfile,$pid) & _PERMITTED_LOCKED_BIT;
}

sub parentlock_is_locked_by_us {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    return &_lock_status($lockfile,$pid) & _PERMITTED_LOCKED_BIT;
}

sub parentlock_is_locked_by_others {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    return &_lock_status($lockfile,$pid) == FORBIDDEN_LOCKED_BY_OTHERS;
}

sub _lock_status {
    my ($lockfile,$pid) = @_;
    $pid||=$$;
    my %parentmap;
    my %pidmap;
    my $t = new Proc::ProcessTable( 'enable_ttys' => 0 );

    foreach my $p (@{$t->table}) {
	my $pid=$p->{'pid'};
	$parentmap{$pid}=$p->{'ppid'};
	$pidmap{$pid}=1;
    }

    return PERMITTED_NOT_LOCKED_NO_LOCK_FILE if (! -e $lockfile);
    return FORBIDDEN_NOT_LOCKED_DIR_AT_LOCK_FILE_PATH if ( -d $lockfile);

    my $fh;
    if (!open($fh, '<', $lockfile)) {
	# lock file can't be opened.
	warn "can't open lock file $lockfile: $!\n";
	return FORBIDDEN_LOCKED_ACCESS_ERROR;
    } else {
	my $oldpid=<$fh>;
	close ($fh) or warn "can't close lock file $lockfile: $!";
	unless ($oldpid) {
	    warn "$lockfile does not have a pid";
	    return PERMITTED_NOT_LOCKED_INVALID_LOCK_FILE;
	}
	chomp $oldpid;
	if ($oldpid<=0) {
	    warn "$lockfile: invalid pid value $oldpid";
	    return PERMITTED_NOT_LOCKED_INVALID_LOCK_FILE;
	}

	return PERMITTED_LOCKED_BY_US if ($oldpid==$pid);

	if ($pidmap{$oldpid}) {
	    # old pid still alive;
	    my $intermedpid=$pid;
	    my $counter=0;
	    my $counter_threshhold=70000;
	    while ($intermedpid and $counter++ <$counter_threshhold) {
		if ($intermedpid==$oldpid) {
		    return PERMITTED_LOCKED_BY_PARENT;
		}
		$intermedpid=$parentmap{$intermedpid};
	    }
	    die "threshhold reached for $oldpid" if $counter >=$counter_threshhold;
	    # lock is valid but we are not born from parent
	    return FORBIDDEN_LOCKED_BY_OTHERS;
	}
	# lock file's pid is dead.
	return PERMITTED_NOT_LOCKED_STALE_LOCK_FILE;
    }
}

sub _write_lock {
    my ($lockfile, $pid)=@_;
    # try to remove it if it exists.
    unlink $lockfile;

    sysopen(FH, $lockfile, O_WRONLY|O_CREAT|O_EXCL, 0644)
	or die "can't open lock file $lockfile: $!";
    syswrite(FH, "$pid");
    close (FH) or die "can't close lock file $lockfile: $!";
}


__END__



=head1	NAME

File::Lock::ParentLock - share lock among child processes of given pid.

=head1	SYNOPSIS

my $locker= File::Lock::ParentLock->new(
	-lockfile=>$lockfile,
	-pid=>$pid,
    );

die $locker->status_string() if !$locker->lock();
...
die $locker->status_string() if !$locker->unlock();


=head1	DESCRIPTION

File::Lock::ParentLock is useful for shell scripting where there are 
lots of nested script calls and we want to share a lock through the
parent - child relationship.

=head1	METHODS

=over

=item	B<new>

Create a File::Lock::ParentLock. Options:

=over

=item	B<-lockfile>

Lockfile name to be created. A relative path will be converted
to the absolute path at the moment script called.
Default is I<.lock>.

=item  B<-pid>

PID to store in lock / to access a lock. Default is current PID.

=back

=item	B<lock>

Accuire Lock.

If supplied PID is a child of PID stored in the lock file then access 
is granted (the lock is accuired). If the lock file does not exist 
or is invalid, the lock file will be created and the supplied PID 
will be stored in the lock file, If supplied PID is not a child of 
the PID stored in the lock file, then access is denied.

Returns true if the lock is successfully accuired.

=item	B<unlock>

Release lock.

Lock is successfully released if supplied PID is a child of the stored
PID. Also, if supplied PID is the same as PID stored in the lock file
then the lock file will be removed.

Returns true if lock is successfully released.
Returns false if supplied PID is not a child of the stored PID
or some other error happen.

=item	B<can_lock>

Test whether lock can be accuired.
Returns true if lock can be accuired.

=item	B<is_locked_by_us>

Test whether lock is accuired by us or by our parent process.

=item	B<is_locked_by_others>

Test whether lock is accuired by a live process that is not us or our parent process.

=item	B<is_locked>

Test whether lock is accuired by us or by our parent process. Deprecated. 
Use B<is_locked_by_us> instead.


=item	B<status_string>

Returns the human readable string regarding the status of locking.

=item	B<lockfile>

Accessor method. Returns the object's lockfile.

=item	B<pid>

Accessor method. Returns the object's pid.

=item	B<parentlock_lock>, B<parentlock_unlock>, B<parentlock_is_locked>, B<parentlock_is_locked_by_us>, B<parentlock_is_locked_by_others>, B<parentlock_can_lock>, B<parentlock_status_string>

Procedural interface. Same as B<lock>, B<unlock>, B<is_locked>, B<is_locked_by_us>, B<is_locked_by_others>, B<can_lock>, B<status_string>
But require a pair ($lockfile,$pid) instead of the object.

=back

=head1	AUTHOR

Written by Igor Vlasenko <viy@altlinux.org>.

=head1	ACKNOWLEGEMENTS

To Alexey Torbin <at@altlinux.org>, whose qa-robot package
had a strong influence on repocop. 

=head1	COPYRIGHT AND LICENSE

Copyright (c) 2008-2018 Igor Vlasenko, ALT Linux Team.

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available
or under the terms of the GNU General Public License as published 
by the Free Software Foundation; either version 2 of the License, 
or (at your option) any later version.

=cut
