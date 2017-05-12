#!/usr/bin/perl -w
#
# Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.
#
# For a description of this module, please refer to the POD documentation
# embedded at the bottom of the file (e.g. perldoc EMDIS::ECS::LockedHash).

package EMDIS::ECS::LockedHash;

use Data::Dumper;
use EMDIS::ECS qw($VERSION);
use Fcntl qw(:DEFAULT :flock);
#use File::lockf;   # potential alternate locking method
use SDBM_File;
use strict;
use vars qw($VERSION);

# ----------------------------------------------------------------------
# Constructor.  Requires name of the database file and name of lock file
# as parameters.  Also accepts optional lock timeout parameter.
sub new {
    my $class = shift;
    my $dbfile = shift;
    my $lockfile = shift;
    my $lock_timeout = shift;

    # validate aaarghs
    if(!defined $dbfile) {
        warn "EMDIS::ECS::LockedHash::new() failed: missing database file name.";
        return undef;
    }
    if(!defined $lockfile) {
        warn "EMDIS::ECS::LockedHash::new() failed: missing lock file name.";
        return undef;
    }
    $lock_timeout = 10 unless defined $lock_timeout;

    # define this object
    my $this = {};
    bless $this, $class;
    $this->{dbfile} = $dbfile;
    $this->{lockfile} = $lockfile;
    $this->{lock_timeout} = $lock_timeout;
    $this->{ERROR} = '';
    $this->{LOCK} = 0;
    $this->{TIED} = '';

    # open lock file and retain file handle
    if(!sysopen($this->{FH_LOCK}, $this->{lockfile}, O_RDWR|O_CREAT)) {
        warn "EMDIS::ECS::LockedHash::new() failed: unable to access lock file " .
            "'$this->{lockfile}': $!";
        return undef;
    }

    # tie/untie db file, to test whether it's accessible
    if(!$this->_tie()) {
        warn "EMDIS::ECS::LockedHash::new() failed: " . $this->ERROR;
        return undef;
    }
    $this->_untie;

    return $this;
}

# ----------------------------------------------------------------------
# set/get error description
sub ERROR {
    my $this = shift;
    my $err = shift;
    if(defined $err) {
        $this->{ERROR} = $err;
    }
    return $this->{ERROR};
}

# ----------------------------------------------------------------------
# set/get locked status indicator
sub LOCK {
    my $this = shift;
    my $status = shift;
    if(defined $status) {
        $this->{LOCK} = $status;
    }
    return $this->{LOCK};
}

# ----------------------------------------------------------------------
# set/get tied status indicator
sub TIED {
    my $this = shift;
    my $status = shift;
    if(defined $status) {
        $this->{TIED} = $status;
    }
    return $this->{TIED};
}

# ----------------------------------------------------------------------
# Read one key-value from the database under a shared lock
sub read {
    my $this = shift;
    my $key = shift;
    my $value = undef;

    $this->ERROR('');  # reset error status
    # check lock status
    if($this->LOCK != LOCK_SH and $this->LOCK != LOCK_EX) {
        $this->ERROR(
            "EMDIS::ECS::LockedHash::read() requires shared or exclusive lock.");
        return undef;
    }
    # read value from hash
    $value = undef;
    $value = $this->{hash}->{$key} if exists $this->{hash}->{$key};
    if(defined($value) and ($value =~ /^\$\w+\s*=\s*\{.*\}\s*\;\s*$/s)) {
        # convert Dumper() string to hash ref
        $value =~ s/^\$\w+/\$value/;  # convert "$VAR1 = ..." to "$value = ..."
        eval($value);                 # eval "$value = ..." string
    }
    return $value;
}

# ----------------------------------------------------------------------
# Write one key-value to the database under an exclusive lock
sub write {
    my $this = shift;
    my $key = shift;
    my $value = shift;

    $this->ERROR('');  # reset error status
    # check lock status
    if($this->LOCK != LOCK_EX) {
        $this->ERROR("EMDIS::ECS::LockedHash::write() requires exclusive lock.");
        return '';
    }
    # write value to hash
    if(ref $value) {
        local $Data::Dumper::Indent = 0;
        $value = Dumper($value);   # convert ref to Dumper() string
    }
    $this->{hash}->{$key} = $value;
    return 1;  # successful
}

# ----------------------------------------------------------------------
# Delete a key-value under an exclusive lock
sub delete {
    my $this = shift;
    my $key = shift;
    my $value = undef;

    $this->ERROR('');  # reset error status
    # check lock status
    if($this->LOCK != LOCK_EX) {
        $this->ERROR("EMDIS::ECS::LockedHash::delete() requires exclusive lock.");
        return '';
    }
    # delete value from hash
    $value = delete $this->{hash}->{$key};
    return 1;  # successful
}

# ----------------------------------------------------------------------
# Return a list of key values under a shared lock
sub keys {
    my $this = shift;
    my @ks = ();

    $this->ERROR('');  # reset error status
    # check lock status
    if($this->LOCK != LOCK_SH and $this->LOCK != LOCK_EX) {
        $this->ERROR(
            "EMDIS::ECS::LockedHash::keys() requires shared or exclusive lock.");
        return '';
    }
    # get keys from hash
    @ks = keys %{$this->{hash}};
    return @ks;
}

# ----------------------------------------------------------------------
# Obtain (advisory) lock and tie internal hash to db file.
sub lock {
    my $this = shift;
    my $lock_type = shift;
    my $oldlock = $this->LOCK;
    $lock_type = LOCK_EX unless $lock_type;   # default = LOCK_EX
    $this->ERROR('');   # reset error status
    return 1 if $oldlock == $lock_type;       # already locked
    my $locked = 0;
    my $attempt = 0;
    while(!$locked and $attempt++ < 5) {
        sleep 2 if $attempt > 1;
        $this->ERROR('');   # reset error status
        $locked = $this->_lock($lock_type);
    }
    if(!$locked) {
        $this->ERROR("EMDIS::ECS::LockedHash::lock() failed: " . $this->ERROR);
        return '';
    }
    if(!$this->TIED and !$this->_tie()) {
        $this->ERROR("EMDIS::ECS::LockedHash::lock() failed: " . $this->ERROR);
        return '';
    }
    return 1;  # successful
}

# ----------------------------------------------------------------------
# Release (advisory) lock and untie internal hash.
sub unlock {
    my $this = shift;
    $this->_untie();
    $this->_unlock();
}

# ----------------------------------------------------------------------
# Quickly delete all key-values under an exclusive lock
sub undef {
    my $this = shift;

    $this->ERROR('');  # reset error status
    # check lock status
    if($this->LOCK != LOCK_EX) {
        $this->ERROR("EMDIS::ECS::LockedHash::undef() requires exclusive lock.");
        return '';
    }
    # delete everything from hash
    undef %{$this->{hash}};
    return 1;  # successful
}


# ----------------------------------------------------------------------
# untie hash and close lock file when perl object passes out of scope
sub DESTROY {
    my $this = shift;
    $this->_untie();
    close($this->{FH_LOCK})
        if defined $this->{FH_LOCK};
}

# ----------------------------------------------------------------------
# Select UNIX or Win32 version of _lock
sub _lock
{
    $^O =~ /MSWin32/ ? _lock_win32(@_) : _lock_unix(@_);
}

# ----------------------------------------------------------------------
# Internal subroutine:  obtain (advisory) lock, using time limit to
# avoid indefinite blocking.  Returns true if able to obtain lock within
# time limit;  otherwise returns false.
sub _lock_unix {
    my $this = shift;
    my $lock_type = shift;
    $lock_type = LOCK_EX unless defined $lock_type;
    my $result = 1;

    # set up "local" SIG_ALRM handler
    # (Note:  not using "local $SIG{PIPE}" because it ignores die())
    my $oldsigalrm = $SIG{ALRM};
    $SIG{ALRM} = sub {
        die "timeout - $this->{lock_timeout} second time limit exceeded\n";
    };

    # attempt to obtain lock, with time limit
    eval {
        alarm($this->{lock_timeout});   # set alarm
        die "flock() failed: $!\n"
            unless flock($this->{FH_LOCK}, $lock_type);
# File::lockf -- potential alternate locking method:
#        my $status = File::lockf::lock($this->{FH_LOCK}, 0);
#        die "lockf failed: $status\n"
#            if $status != 0;
        alarm(0);  # turn off alarm
    };
    if($@) {
        alarm(0);  # turn off alarm
        $this->ERROR("EMDIS::ECS::LockedHash::_lock_unix() failed: $@");
        $this->LOCK(0);  # reset status indicator
        $result = '';
    }
    # restore previous SIG_ALRM handler
    if(defined $oldsigalrm) { $SIG{ALRM} = $oldsigalrm; }
    else                    { delete $SIG{ALRM}; }
    $this->LOCK($lock_type)   # set status indicator
        if $result;
    return $result;  # successful
}

# ----------------------------------------------------------------------
# Internal subroutine:  obtain (advisory) lock, using time limit to
# avoid indefinite blocking.  Returns true if able to obtain lock within
# time limit;  otherwise returns false.
sub _lock_win32 {
    my $this = shift;
    my $lock_type = shift;
    $lock_type = LOCK_EX unless defined $lock_type;
    my $result = 1;

    # attempt to obtain lock, with time limit
    # (uses polling method to obtain lock -- somewhat more crude than
    # the unix method, which uses blocking with SIGALRM to enforce timeout)
    my $timeoutCount = 0;
    my $locked;
    while (!($locked = flock($this->{FH_LOCK}, $lock_type | LOCK_NB)) and 
        ($timeoutCount++ <= $this->{lock_timeout})) {
	sleep 1;
    }

    if(!$locked) {
        $this->ERROR("EMDIS::ECS::LockedHash::_lock_win32() failed: $@");
        $this->LOCK(0);  # reset status indicator
        $result = '';
    }
    $this->LOCK($lock_type)   # set status indicator
        if $result;
    return $result;  # successful
}

# ----------------------------------------------------------------------
# Internal subroutine:  tie hash to db file
sub _tie {
    my $this = shift;
    $this->{db_obj} = tie(%{$this->{hash}}, 'SDBM_File', $this->{dbfile},
        O_CREAT|O_RDWR, (defined $EMDIS::ECS::FILEMODE ? $EMDIS::ECS::FILEMODE : 0664))
        or $this->ERROR(
            "EMDIS::ECS::LockedHash::_tie() failed ($this->{dbfile}): $!");
    if($this->{db_obj}) {
        $this->TIED(1);     # set status indicator
    } else {
        $this->TIED('');    # reset status indicator
    }
    return $this->TIED;
}

# ----------------------------------------------------------------------
# Internal subroutine:  release (advisory) lock
sub _unlock {
    my $this = shift;
    flock($this->{FH_LOCK}, LOCK_UN);
# File::lockf -- potential alternate locking method:
#    my $status = File::lockf::ulock($this->{FH_LOCK}, 0);
    $this->LOCK(0);      # reset status indicator
}

# ----------------------------------------------------------------------
# Internal subroutine:  untie hash from db file
# (mainly, insure that output is flushed to disk)
sub _untie {
    my $this = shift;
    untie $this->{hash}
        if exists $this->{hash};
    delete $this->{hash};
    delete $this->{db_obj};
    $this->TIED('');        # reset status indicator
}

1;

__DATA__

# embedded POD documentation
# for more info:  man perlpod

=head1 NAME

EMDIS::ECS::LockedHash - tied hash (SDBM) with simple locking protocol

=head1 SYNOPSIS

 use EMDIS::ECS::LockedHash;
 $node_tbl =
     new EMDIS::ECS::LockedHash("node_tbl.dat", "node_tbl.lock", 10);
 $node_tbl->lock or die "unable to lock node_tbl: " .
     $node_tbl->ERROR . "\n";
 $node = $node_tbl->read("UX");
 $node_tbl->write('AA', { node => 'AA' });
 $node_tbl->delete('AA');
 @keys = $node_tbl->keys;
 $node_tbl->unlock;

=head1 DESCRIPTION

Tied hash (SDBM) with simple locking protocol.

=head1 BUGS

Possibly.

=head1 SEE ALSO

EMDIS::ECS, EMDIS::ECS::Config, EMDIS::ECS::FileBackedMessage,
EMDIS::ECS::Message

=head1 AUTHOR

Neil Smeby <nsmeby@nmdp.org>

Joel Schneider <jschneid@nmdp.org> - modifications.

=head1 COPYRIGHT AND LICENSE

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.

See LICENSE file for license details.

=head1 HISTORY

ECS, the EMDIS Communication System, was originally designed and
implemented by the ZKRD (http://www.zkrd.de/).  This Perl implementation
of ECS was developed by the National Marrow Donor Program
(http://www.marrow.org/).

2004-03-12	
Canadian Blood Services - Tony Wai
Added MS Windows support for Windows 2000 and Windows XP
Added "DIRECTORY" inBox Protocol. This can interface with any mail
system that can output the new messages to text files.
