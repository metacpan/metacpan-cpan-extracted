######################################################################
# LockFile::NetLock
#
# Use ftp and directory creation to create mutual exclusion/locking
# available cross platform and on a network.  Based on an article
# by Sean M. Burke in the Summer 2002 Perl Journal.  
#
# Basic idea is based on mutually exclusive property of creating
# directories via FTP.  The first process that asks to create the
# directory succeeds and later attempts are notified of failure
# because directory already exists.  FTP session is maintained
# by separate program called 'netlock' that automatically removes
# the directory if the creating program dies or requests removal.
# Communication between this module and netlock program is via an
# interprocess pipe.  On win32 systems some communication is also
# done via a mutex because pipes block too quickly and problems
# were encountered when trying other solutions.
#
# Implemented by Ronald Schmidt.
######################################################################

package LockFile::NetLock;

use strict;
use warnings;
require 5.006; # goes back a ways but does not seem to like 5.005
use Exporter;
use Config;
use Carp;
use FileHandle;
use POSIX qw(sys_wait_h signal_h);

our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw(lock unlock);

our $VERSION = '0.32';

our $errstr;

my %named_lock;
my $mx_id = 0;
my $is_win32;

BEGIN {
        $is_win32 = ($^O =~ /win32/i);
        require Win32::Mutex if ($is_win32);
}

######################################################################
# new - Constructor method.
#
# Not much going on here - just setup of parameters that will be
# used by lock process.  Caller is allowed to pass up to four initial
# un-named parameters that are interpreted as ftp host, lock directory
# ftp user and password respectively.
######################################################################
sub new {
        my $self = shift;
        my $class = ref($self) || $self;

        use constant KNOWN_OPT => {
                map( ($_ => 1) , qw(
                        -dir -disconnect -ftp_heartbeat -heartbeat -host -idle
                        -password -sleep -timeout -user
                ))
        };

        my %ivar = (
                -host   =>      'localhost',
                -dir    =>      'lockdir'
        );

        # allow host, directory user and password to be passed unlabeled
        foreach (qw (-host -dir -user -password)) {
                last if ($_[0] && ($_[0] =~ /^\-/));
                $ivar{$_} = shift;
        }
        %ivar = (%ivar, @_);

        # empty parameters may cause trouble with ./netlock program
        grep(   $_ ne '-disconnect' && (! $ivar{$_}) && delete($ivar{$_}),
                (keys %ivar));

        foreach my $opt (keys %ivar) {
                carp("Unknown option: $opt") unless (KNOWN_OPT->{$opt});
        }
        
        return bless \%ivar, $class;    
}

######################################################################
######################################################################
sub set_error {
        my $self = shift;
        $errstr = $self->{error} = shift;
}

######################################################################
# lock
#
# Call netlock program to use FTP to create a directory on a
# mutually exclusive basis if one has not been created.  Can
# be called using an existing LockFile::NetLock object reference
# or the parameters needed to create a new object can be passed
# to this method.
######################################################################
sub lock {
        my $self = ref($_[0]) && shift;
        my $lock_key;

        unless ($self) {
                $self = LockFile::NetLock->new(@_);
                $lock_key = "$self->{-host},$self->{-dir}";
                if ($named_lock{$lock_key}) {
                        $errstr = "Already locking $lock_key";
                        return;
                }
                $named_lock{$lock_key} = $self;             
        }

        my ($cmd) = grep    { -r  && ! -d }
                            (   './netlock', "$Config{bin}/netlock",
                                "$Config{installsitescript}/netlock"
                            );
        my $cmd_line = $Config{perlpath};
        $cmd_line =~ s!/!\\!g if ($is_win32);
	$cmd_line .= " $cmd";

        $cmd_line .= ' -d' if $self->{-disconnect};

        # first character after - in package option is Getopt::Std prog option
        foreach my $opt (grep($_ !~ /^(-d|-host|-reader)/, keys %$self)) {
                $cmd_line .= ' ' . substr($opt, 0, 2) . $self->{$opt};
        }

        if ($is_win32) {
                $self->{mutex_name} = "netlock:$$:" . $mx_id++;
                unless ($self->{mutex} = 
                                Win32::Mutex->new(1, $self->{mutex_name})) {
                        $self->set_error("Could not create mutex: $^E");
                        return;
                }
                $cmd_line .= " -m $self->{mutex_name}";
        }

        $cmd_line .= " $self->{-host} $self->{-dir}";
        my $fh = new FileHandle "$cmd_line |";

        unless ($fh) {
                $self->set_error("Could not start netlock process: $!");
                delete $named_lock{$lock_key} if ($lock_key);
                return;
        }

        $self->{filehandle} = $fh;
        my $from_netlock = <$fh>;
        if ($from_netlock !~ /^\.*OK/) {
                $self->set_error("Failed to acquire net lock: $from_netlock");
                return;
        }
        $self->{is_locked} = 1;

        return $self;
}


######################################################################
# unlock
#
# Close the handle to the running netlock process holding the lock
# uniquely identified by the host and directory or object containing
# those unique identifiers.  If we are not currently the locker, or
# an error happens on close, or we get a child exist code of -1
# indicating a netlock lock removal error we return an error code.
######################################################################
sub unlock {
        my $self = ref($_[0]) && shift;
        my $lock_key;

        unless ($self) {
                # bit of a hack - just want a standard way to get host and dir
                $self = LockFile::NetLock->new(@_);
                $lock_key = "$self->{-host},$self->{-dir}";
                $self = $named_lock{$lock_key};

                # once you try to unlock you can always try to lock again
                delete $named_lock{$lock_key};
        }

        unless ($self && $self->{filehandle}) {
                $errstr = "Cannot unlock: not currently locking";
                if ($lock_key) {
                        $errstr .= " $lock_key";
                }
                else {
                        $errstr .= ' object';
                }
                $self->{error} = $errstr if ($self);
                return;
        }

        if ($is_win32) {
                unless ($self->{mutex}->release) {
                        $self->set_error("Could not release mutex: $^E");
                }
        }

        my $close_rc;
        unless ($close_rc = close($self->{filehandle})) {
                $self->set_error("Failed to close lock process: $!");
        }

        if ($?) {
                my $reaped_rc = $? >> 8;
                if ($reaped_rc & 255 == 255) {
                        $self->set_error("Failed to remove lock directory.");
                }
                else {
                        $self->set_error("Unlock failure code: $reaped_rc");
                }                        
        }
        return unless($close_rc);
        $self->{is_locked} = 0;

        return 1;
}

######################################################################
# Return most recent error on object if passed an object reference
# otherwise most recent error against module.
######################################################################
sub errstr {
        my $self = shift;

        return ($self && ref($self) && $self->{error}) || $errstr;
}

######################################################################
# Needed for win32.  Without this exiting scope could
# attempt to close the process handle without releasing the mutex
# leading to deadlock.
######################################################################
sub DESTROY {
        my $self = shift;

        $self->{mutex}->release if (
                $is_win32 && $self->{is_locked}
        );
}

1;
__END__

=head1 NAME

LockFile::NetLock - FTP based locking using the FTP mkdir command.

=head1 SYNOPSIS

  use LockFile::NetLock;

  my $locker = new LockFile::NetLock(
      'ftp.myhost.com', 'lockdir.lck', 'ftpuser', 'ftppassword'
  );
  if ($locker->lock()) {
      # do work requiring lock
      $locker->unlock() ||
          print STDERR $locker->errstr;
  }
  else {
      print STDERR $locker->errstr;
  }            

  -- OR --

  use LockFile::NetLock qw(lock unlock);

  if (lock qw(ftp.myhost.com lockdir.lck ftpuser ftppassword)) {
      # do work requiring lock
      unlock(qw(ftp.myhost.com lockdir.lck)) ||
          print STDERR $LockFile::NetLock::errstr;
  }
  else {
      print STDERR $LockFile::NetLock::errstr;
  }

  -- OR even with a .netrc file --

  use LockFile::NetLock qw(lock unlock);

  if (lock qw(ftp.myhost.com lockdir.lck )) {
      # do work requiring lock
      unlock(qw(ftp.myhost.com lockdir.lck)) ||
          print STDERR $LockFile::NetLock::errstr;
  }
  else {
      print STDERR $LockFile::NetLock::errstr;
  }

=head1 DESCRIPTION

Provide locking/mutex mechanism under (at least) UNIX and
Win32 that will function correctly even in networked/NFS
environments.  It is based on the concept that if two 
processes each connect to the same host via ftp and try
to create the same directory that does not yet exist then
one will create the directory and the other will be notified
that it cannot create the directory because it already exists.
The basic ideas are explained in more detail in an article
in the summer 2002 Perl journal by Sean M. Burke.

As demonstrated in the SYNOPSIS the module has two interfaces:
an object oriented interface and a more traditional subroutine
interface.  The four most critical parameters, the host name,
directory, ftp user and password may be passed unnamed as a list
or named with the respective labels -host, -dir, -user, 
-password.  There are also several optional parameters that
control the timing of lock events including a total timeout
parameter, a sleep time between attempts to create the
directory, and a heartbeat option controlling the frequency
of verifying the running or dead status of the process that
requested the lock.  The options and parameters are
discussed in an itemized format in the parameters 
sections below.

It is strongly recommended that users of this module upgrade their Net::FTP
module to at least version 2.64.  Earlier versions may make errors in
removing a lock undetectable.

=head1 Methods 

=over 4

=item constructor C<< $lock = LockFile::NetLock->new( I<< option1 => val1, ... >> ) >>

Create a new LockFile::NetLock object.  See 'Named Parameters to new' 
and 'Ordered Parameters' for initialization options.  Currently
just constructs a blessed hash and has no cause for failure.  

=item method C<< $lock->lock() >> or C<< lock(... intialization parameters ...) >>

Attempt to acquire the lock by opening an FTP session to an FTP host  
and creating a directory.  Needs no parameters if called using a
properly constructed LockFile::NetLock object reference but may
be called with all parameters that would otherwise be passed
to new for a more traditional subroutine interface.  In the
case of the subroutine interface lock will return a reference
to the newly created lock object but unlock may be called
with either the object reference or the host and directory name
that will be used internally to uniquely identify the lock
object.  Returns object reference on success and undef on failure 
in which case both $LockFile::NetLock::errstr and the object's 
error field are set.

=item method C<< $lock->unlock() >> or C<< unlock($host, $dir) >>

Release lock by removing directory at FTP host that was created
to do locking.  Needs no parameters if called using a properly
constructed LockFile::NetLock object but can also be called
with the FTP host and directory if the lock was created using
the "sub" interface to lock described above.  Returns 1 on
success and undef if there was an error releasing the
lock (and this is possible).

=item method C<< $lock->errstr() >>

Return string describing last error on LockFile::NetLock object or class.

=back

=head1 Named Parameters (to new, lock and in some cases unlock).

=over 4

=item option C<< -dir => I<dirname>, >>

Path of directory that will be created at FTP host.  Once the
directory is created other processes attempting to create the
same directory at the same host will be informed that they
cannot do so because the directory already exists.  This
provides a mutual exclusion effect.  Defaults to 'lockdir'.
The FTP host and lock directory uniquely identify a lock
not otherwise identifiable through an object reference.

=item option C<< -disconnect => 1, >>

The module calls a program to create the lock directory and by 
default the program maintains an FTP connection to the host as long
as the lock is held.  This option instructs the program to disconnect
from the FTP host after creating the lock directory and re-connect
later when the lock is released and the directory needs to be
removed.  This option is included for cases where locks need
to be held for a long time and the number of available FTP sessions
is limited.

=item option C<< -ftp_heartbeat  => I<seconds>, >>

Frequency with which action on FTP connection will be taken to
prevent FTP idle timeout.  Should rarely need to be changed from default
of 15 seconds.

=item option C<< -heartbeat  => I<seconds>, >>

The module calls a program to create the lock directory.  If the
program that called this module dies or calls unlock then the
lock directory must be removed.  The heartbeat option sets the
frequency in seconds with which the lock program checks the 
calling program to see if it needs to release the lock.  Set to
small number for briefly held frequent locks.  For long held locks
a conservative setting would be 1 second for every 7 minutes the
lock is held.  Defaults to 2 seconds.

=item option C<< -host  => I<hostname>, >>

The FTP host on which the lock directory will be created.
The FTP host and lock directory uniquely identify a lock
not otherwise identifiable through an object reference.

=item option C<< -password  => I<password>, >>

The password allowing the FTP user to connect to the FTP host.
May be inferred from .netrc if not passed as parameter.

=item option C<< -sleep  => I<seconds>, >>

The amount of time in seconds that the locking process will sleep
after a failed attempt to create the lock directory and before
trying to create the directory again.  Defaults to 4 seconds.

=item option C<< -timeout  => I<seconds>, >>

The total amount of time in seconds the locking process can
spend trying to create the lock directory.  If the directory
cannot be created before the timeout elapses an error is returned
indicating a timeout.  Defaults to 40 seconds.  Use infinite or
forever if you never want to time out.

=item option C<< -user  => I<username>, >>

FTP login user for the FTP host at which the module will try to
create the lock directory.  May be inferred from .netrc if not 
passed as parameter.

=back

=head1 Ordered parameters

Until a named parameter is detected by new, lock or unlock, the
first four parameters to these functions will be interpreted as
-host, -dir, -login and -password respectively.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Sean M. Burke C<sburke@cpan.org> - designer and architect of this concept.

Ronald Schmidt C<RonaldWS@software-path.com> - implementor.

=cut
