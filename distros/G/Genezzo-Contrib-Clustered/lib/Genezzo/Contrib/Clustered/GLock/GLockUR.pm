#!/usr/bin/perl
#
# copyright (c) 2005, Eric Rollins, all rights reserved, worldwide
#
#
#

use strict;
use warnings;
use POSIX;

package Genezzo::Contrib::Clustered::GLock::GLockUR;

# Locking for Genezzo using UNIX fcntl record locking
use Inline (C => 'DATA',
	    DIRECTORY => '/Inline'  # Apache needs a writeable directory
	    );

require Exporter;

Inline->init;  # help for "require GLockRecord"

our @ISA = qw(Exporter);
our @EXPORT = qw(ur_lock ur_unlock ur_promote);

our $MAX_PROCS = 20;  # TODO:  initialize this from elsewhere
                      # shouldn't be huge, as we only get ~100locks/sec on OSX.

sub ur_lock()
{
    my ($name, $shared, $blocking) = @_;

    set_max_procs_impl($MAX_PROCS);

    # turn name into number
    my $offset = 0;
    my $trypid = 0;

    if($name =~ /SVR/){
	$name =~ /(\d+)/;
	$trypid = $1;
    }else{
	$offset += $MAX_PROCS+1;  # 1..MAX_PROCS reserved for PID locks
    }

    $name =~ /(\d+)/;
    my $lockid = $1 + $offset;

    my $ret = ur_lock_impl($lockid, $shared, $blocking);

    if($ret == -1){
      die "DEADLOCK";
    }

    if($ret > 0){
	if($trypid > 0){
	    if($trypid > $MAX_PROCS){
		die "Maximum procs ($MAX_PROCS) for GLockUR exceeded";
	    }

	    set_pid_impl($trypid);
	}

	return $lockid;
    }

    return 0;
}

sub ur_unlock()
{
    my ($lockid) = @_;

    return ur_unlock_impl($lockid);
}

sub ur_promote()
{
    my ($name, $lockid, $blocking) = @_;

    my $ret = ur_promote_impl($name, $lockid, $blocking);

    if($ret == -1){
      die "DEADLOCK";
    }

    return $ret;
}

sub ur_demote()
{
    my ($name, $lockid, $blocking) = @_;

    my $ret = ur_demote_impl($name, $lockid, $blocking);

    if($ret == -1){
      die "DEADLOCK";
    }

    return $ret;
}

sub ur_ast_poll()
{
    return 1;
}

sub ur_set_notify()
{
    return 1;
}

BEGIN
{
    print STDERR "Genezzo::Contrib::Clustered::GLock::GLockUR installed\n";

    # By default avoid dying.  Real handler can be registered later.
    my $sigset = POSIX::SigSet->new(POSIX::SIGUSR2);
    my $old_sigset = POSIX::SigSet->new;
    POSIX::sigprocmask(POSIX::SIG_BLOCK, $sigset, $old_sigset)
		     or die "Error blocking SIGUSR2: $!\n";
}

1;

__DATA__

=head1 NAME

Genezzo::Contrib::Clustered::GLock::GLockUR - Unix record locking implementation for Genezzo

=head1 SYNOPSIS

    my $lockid = ur_lock($name, $shared, $blocking);
    my $success = ur_promote($name, $lockid, $blocking);
    my $success = ur_unlock($lockid);

=head1 DESCRIPTION

Provides Perl wrappers to basic Unix record fcntl C functions.

=head1 FUNCTIONS

=over 4

=item ur_lock NAME, SHARED, BLOCKING

Locks lock with name NAME.  Shared if SHARED=1, otherwise
exclusive.  Blocking if BLOCKING=1, otherwise returns immediately.
Returns lockid,or 0 for failure.

=item ur_promote NAME, LOCKID, BLOCKING

Promotes lock with name NAME and lockid LOCKID to exclusive mode.
Returns 1 for success, or 0 for failure. 

=item ur_demote NAME, LOCKID, BLOCKING

Demotes lock with name NAME and lockid LOCKID to shared mode.
Returns 1 for success, or 0 for failure. 

=item ur_unlock LOCKID

Releases lock with lockid LOCKID.  Returns 1 for success, 0 for failure.

=back

=head2 EXPORT

ur_lock, ur_promote, ur_unlock

=head1 LIMITATIONS

Relies on Perl Inline::C module.
Currently terminates program when deadlock detected.

Inline code is installed in directory /Inline, so it can be used with Apache.

A file /tmp/genezzo.lock is created.  It must be writeable by the accessing
processes.  The undo file should probably be used for locking instead.

All processes must be owned by the same user; otherwise kill SIGUSR2
signals will be blocked.

=head1 AUTHOR

Eric Rollins, rollins@acm.org

Copyright (c) 2005 Eric Rollins.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to rollins@acm.org

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut

__C__

//
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

static int fdes = 0;
static int max_procs = 0;
static int pid = 0;

void set_max_procs_impl(int _max_procs){
    max_procs = _max_procs;
}

void set_pid_impl(int _pid){
    // fprintf(stderr, "set_pid_impl %d\n", _pid);

    pid = _pid;
}

static const char *fname = "/tmp/genezzo.lock";

static void init(){
    fdes = open(fname, O_CREAT|O_RDWR, S_IRWXU);

    if(fdes == -1){
	perror("open failed in Genezzo::Contrib::Clustered::GLockUR");
	fprintf(stderr, "couldn't open %s\n", fname);
	exit(EXIT_FAILURE);
    }
}

// returns lockid, 0 for failure, -1 for deadlock
static int ur_lock_impl_internal_simple(int lockid, int type, int block){
    if(!fdes) init();

    // fprintf(stderr,"ur_lock_impl_internal_simple %d %d %d\n", 
    //    lockid, type, block);

    struct flock lock;
    lock.l_type = type;
    lock.l_start = lockid;
    lock.l_whence = SEEK_SET;
    lock.l_len = 1;
    
    int cmd = F_SETLKW;

    if(!block){
	cmd = F_SETLK;
    }

    int ret;

    // retry on signals
    while(1){
	ret = fcntl(fdes, cmd, &lock);

	if((ret != -1) || (errno != EINTR)){
	    break;
	}
    }
    
    if(ret != -1){
	return lockid;
    }

    int errcopy = errno;

    if(block || ((errno != EACCES) && (errno != EAGAIN))){
	perror("lock failed in Genezzo::Contrib::Clustered::GLockUR");
    }

    if(errcopy == EDEADLK){
	return -1;
    }

    return 0;
}

static int get_blocking_os_pid(int lockid){
    struct flock lock;
    lock.l_type = F_WRLCK;
    lock.l_start = lockid;
    lock.l_whence = SEEK_SET;
    lock.l_len = 1;
    int cmd = F_GETLK;
    int ret;
    ret = fcntl(fdes, cmd, &lock);
    
    if(lock.l_type == F_UNLCK){
	return 0;
    }else{
	return lock.l_pid;
    }
}

// use base lock, buddy lock, and a lock per process to implement
// signaling (SIGUSR2) of lock holders on blocking request
static int ur_lock_impl_internal_sigblockers(int lockid, int type, 
					     int block, int demote)
{
    if(lockid <= max_procs)   // this is a PID lock
    {
	return ur_lock_impl_internal_simple(lockid, type, block);
    }

    int base_lock_id = lockid * (max_procs+2);
    int buddy_lock_id = base_lock_id+1;           // always held EX
    int first_p_lock_id =  buddy_lock_id + 1;     // per-process locks
    int my_p_lock_id = buddy_lock_id + pid;

    if(type == F_UNLCK){
	ur_lock_impl_internal_simple(my_p_lock_id, type, block);
	return ur_lock_impl_internal_simple(base_lock_id, type, block);
    }

    if(demote){
	return ur_lock_impl_internal_simple(base_lock_id, type, block);
    }

    // EX the buddy to prevent race conditions
    ur_lock_impl_internal_simple(buddy_lock_id, F_WRLCK, 1);

    if((type == F_WRLCK) &&
       block && 
       (ur_lock_impl_internal_simple(base_lock_id, type, 0) == 0))
    {
	// signal all other holders of the lock
	int i;

	for(i = 0; i < max_procs; i++){
	    int p_lock_id = first_p_lock_id + i; 

	    if(p_lock_id == my_p_lock_id){
		continue;
	    }

	    int blocking_os_pid = get_blocking_os_pid(p_lock_id);
	    
	    if(blocking_os_pid != 0){
		int kret = kill(blocking_os_pid, SIGUSR2);
		
		if(kret){
		    perror("error in kill SIGUSR2");
		}
	    }
	}
    }

    // now block on the lock
    int ret = ur_lock_impl_internal_simple(base_lock_id, type, block);

    if(ret > 0){
	// my pid lock
	ur_lock_impl_internal_simple(my_p_lock_id, F_WRLCK, 1);
    }

    // release buddy lock
    ur_lock_impl_internal_simple(buddy_lock_id, F_UNLCK, block);

    return ret;
}

#define SIGNAL_BLOCKERS  1

static int ur_lock_impl_internal(int lockid, int type, int block,
				 int demote)
{
#ifdef SIGNAL_BLOCKERS
    return ur_lock_impl_internal_sigblockers(lockid, type, block, demote);
#else
    return ur_lock_impl_internal_simple(lockid, type, block);
#endif
}

// returns lockid, 0 for failure, -1 for deadlock
int ur_lock_impl(int lockid, int shared, int block){
    int type;

    if(shared){
	type = F_RDLCK;
    }else{
	type = F_WRLCK;
    }

    return ur_lock_impl_internal(lockid, type, block, 0);
}

// returns 1 for success, or 0 for failure
int ur_unlock_impl(int lockid){
    return ur_lock_impl_internal(lockid, F_UNLCK, 1, 0);
}

// returns 1 for success, or 0 for failure
int ur_promote_impl(char *name, int lockid, int block){
    return ur_lock_impl_internal(lockid, F_WRLCK, block, 0);
}

// returns 1 for success, or 0 for failure
int ur_demote_impl(char *name, int lockid, int block){
    return ur_lock_impl_internal(lockid, F_RDLCK, block, 1);
}
