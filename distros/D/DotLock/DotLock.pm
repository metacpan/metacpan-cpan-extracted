package DotLock;
require 5.002;

# DotLock user documentation in POD format is at end of this file.  Search for =head

use strict;
use vars qw($VERSION);
use POSIX qw(uname);

$VERSION = "1.06";

sub new
{
	my($self,%args) = @_;

		# Create new object, load it with defaults.

	$self = {
		timeout		=> 60,
		path		=> "",
		errmode		=> "die",
		maxqueue	=> 0,
		retrytime	=> 1,
		domain		=> "",
	};

		# Our marker to this object

	bless $self;

		# Parse Args and load object

		# errmode must be set first to allow the data methods error escaping.

	foreach(keys %args) {
		if(/^-?errmode$/i) {
			$self->errmode($args{$_});
		} elsif (/^-?timeout$/i) {
			$self->timeout($args{$_});
		} elsif (/^-?path$/i) {
			$self->path($args{$_});
		} elsif (/^-?maxqueue$/i) {
			$self->maxqueue($args{$_});
		} elsif (/^-?retrytime$/i) {
			$self->retrytime($args{$_});
		} elsif (/^-?domain$/i) {
			$self->domain($args{$_});
		};
	};

	$self;
};

sub lock
{
	my($self) = @_;
	my(@locktarget);

		# Vars

	my $locktarget = $self->path;
	my $locktargetfname;
	my $lockfiledir;
	if(-f $locktarget) {
		my @locktarget = split("\/", $locktarget);
		$locktargetfname = pop(@locktarget);
		$lockfiledir = "\/" . join("\/", @locktarget);
		push(@locktarget, "." . $locktargetfname);
		$locktarget = "\/" . join("\/", @locktarget);		
	} elsif (!-d $locktarget) {
		$self->_error("Lock target doesn't exist");
		return undef;
	};
	my $lockfile = $locktarget . ".swp";
	my $domain = $self->domain;
	my $host = (POSIX::uname())[1];
	$host =~ s/\.$domain// if(length $domain);
	my $templockfile = $lockfile . ".$$-" . rand(1000) . ".$host";
	my $maxqueue = $self->maxqueue;
	my $timeout = $self->timeout;
	my $retrytime = $self->retrytime;

		# Open temp lockfile

	unless(open L, "> $templockfile") {
		$self->_error("Can't open lock file $templockfile: $!");
		return undef;
	};
	$self->_add_openfiles("$templockfile");

		# Make contents informative
		# what else can I add?

	print L "This lockfile was created by DotLock version $VERSION\n\n";
	print L "Host: " . $host . "\n";
	print L "Pid: $$\n"; 

		# Close and save temp lockfile

	unless(close L) {
		$self->_error("Can't write lock file $templockfile: $!");
		return undef;
	};

		# We must read the dir in, find the highest lockfile in the que, and lock one higher.

		# If by the time we have read the dir, if someone tries to obtain that same lock ... we climb the que
		# until something is free. This creates a small race condition which is only evident with fast locking.
		# There is a better way I plan to do this, however at this point it means the loss of a feature - 
		# thoughts still ticking.

	opendir(LOCKFILEDIR, $lockfiledir);
	my @lockfiledir = readdir(LOCKFILEDIR);
	closedir(LOCKFILEDIR);

		# Find the highest free lock

	my $highestlock = 0;
	my $mainlock = 0;
	foreach (@lockfiledir) {
		if(/^$locktargetfname\.lock_(\d)$/) {
			# A qued lockfile
			if($1 > $highestlock) {
				$highestlock = $1;
			};
		};
	};
	my $freelock = $highestlock + 1;

		# Handle if queing is switched off

	if(($maxqueue == 0) and ($highestlock == 0)) {
		# Hmmm, there is no-one waiting to obtain a lock, try to get the master
		if(link($templockfile, $lockfile)) {
			# We have the master
			$self->_add_openfiles($lockfile);
			unlink($templockfile) && $self->_del_openfiles($templockfile);
			return(1);
		} else {
			#No master ...
			unlink($templockfile) && $self->_del_openfiles($templockfile);
        		$self->_error("Could not obtain file lock, too many already queued: $lockfile");
			return(undef);
		};
	}; 

		# Now its time to attempt to get a place in the que

	my $currentplacing;
	for(my $order = $freelock; $order <= $maxqueue; $order++) {
		if(link($templockfile, $lockfile . "_" . $order)) {

			$self->_add_openfiles($lockfile . "_" . $order);
			$currentplacing = $order;

				# We have qued successfully, now lets move up the que

			alarm($timeout);
			for(my $downque = $currentplacing - 1; $downque >= 1; $downque--) {

					# Clear lock files if alarmed ...

				local $SIG{ALRM} = sub {
					unlink($templockfile) && $self->_del_openfiles($templockfile);
					unlink($lockfile . "_" . $currentplacing) && $self->_del_openfiles($lockfile . "_" . $currentplacing);
					$self->_error("Timed out acheiving lock: $lockfile");
					return undef;
				};
				while(!link($templockfile, $lockfile . "_" . $downque)) {
					sleep($retrytime);
				};
				$self->_add_openfiles($lockfile . "_" . $downque);

					# We have the next position, lets remove the old possy and move the marker

				unlink($lockfile . "_" . $currentplacing) && $self->_del_openfiles($lockfile . "_" . $currentplacing);
				$currentplacing = $downque;
			};

				# Now first in line ... start trying to get the main lock

				# Clear lock files if alarmed ...

			local $SIG{ALRM} = sub {
				unlink($templockfile) && $self->_del_openfiles($templockfile);
				unlink($lockfile . "_" . $currentplacing) && $self->_del_openfiles($lockfile . "_" . $currentplacing);
				$self->_error("Timed out acheiving lock: $lockfile");
				return undef;
			};
			while(!link($templockfile, $lockfile)) {
				sleep($retrytime);
			};
			$self->_add_openfiles("$lockfile");
			alarm(0);

				# Oh goodie, we have the main lock ... now clear the old temp lockfiles
				# and return a positive answer to user

			unlink($lockfile . "_" . $currentplacing) && $self->_del_openfiles($lockfile . "_" . $currentplacing);
			unlink($templockfile) && $self->_del_openfiles($templockfile);
			return(1);
		};
	};
	
		# Too many waiting to que ... abort and clear files

	unlink($templockfile) && $self->_del_openfiles($templockfile);
	$self->_error("Could not obtain file lock, too many already queued: $lockfile");
	return undef;
};

sub unlock
{
	my($self) = @_;	

	foreach(@{$self->_get_openfiles}) {
		unlink($_) && $self->_del_openfiles($_);
	};
};

sub timeout 
{
	my($self, $timeout) = @_;

	my $prev = $self->{timeout};

	if (@_ >= 2) 
	{
		if($timeout > 0) 
		{
			$self->{timeout} = $timeout;
		};
	};

	$prev;
};

sub path {
	my($self, $target) = @_;

	my $prev = $self->{path};



	if (@_ >= 2) {
		if(length $target) 
		{
			if(-d $target) {
				if($target !~ /\/$/) {
					$target = $target . "/";
				};
			} elsif(!-f $target) {
				$self->_error("Path $target does not exist");
				return undef;
			};

			$self->{path} = $target;
		}
	}

	$prev;
}

sub errmode
{
	my($self, $args) = @_;
	my($prev);

	$prev = $self->{errmode};

	if(@_ >= 2) {
		if (($args eq "die") or ($args eq "return")) {
			$self->{errmode} = $args;
		};
	};

	$prev;
}

sub maxqueue
{
	my($self, $args) = @_;
	my($prev);

	$prev = $self->{maxqueue};

	if(@_ >= 2) {
		unless($args < 0) {
			$self->{maxqueue} = $args;
		};
	};

	$prev;
};

sub retrytime
{
	my($self, $args) = @_;
	my($prev);

	$prev = $self->{retrytime};

	if(@_ >= 2) {
		unless($args < 0) {
			$self->{retrytime} = $args;
		};
	};

	$prev;
};

sub domain
{
    my($self, $args) = @_;
    my($prev);

    $prev = $self->{domain};

    if(@_ >= 2) {
		$self->{domain} = $args;
    };

    $prev;
};

sub _error 
{
	my($self, @errmsg) = @_;

	my $errmsg = join('', @errmsg);

	if($self->errmode eq "die") {
		$self->unlock;
		die($errmsg);
	} elsif ($self->errmode eq "return") {
		$self->errmsg($errmsg);
	};

	return(1);
};

sub errmsg
{
	my($self, @errmsg) = @_;
	my($prev);

	$prev = $self->{errmsg};

        my $errmsg = join('', @errmsg);

        if (@_ >= 2) {
		if(length $errmsg) 
		{
			$self->{errmsg} = $errmsg;
		};
	};

	$prev;
};

sub _add_openfiles
{
	my($self,@files) = @_;

	if(@_ >= 2) {
		foreach(@files) {
			$self->{openfiles} {$_} = 1;
		};	
	};

	1;
};

sub _get_openfiles
{
	my($self) = @_;
	my @openfiles;

	foreach(keys %{$self->{openfiles}}) {
		push(@openfiles, $_);
	};

	return(\@openfiles);
};

sub _del_openfiles
{
	my($self,@files) = @_;

	if(@_ >= 2) {
		foreach(@files) {
			delete($self->{openfiles} {$_});
		};
	};

	1;
};

sub DESTROY 
{
	my $self = shift;

	$self->unlock;
};

1;

__END__;

=head1 NAME

DotLock - Multi-host advisory queing locking system

=head1 SYNOPSIS

C<use DotLock;>

see CONSTRUCTOR & METHODS section below

=head1 DESCRIPTION

=over 4

C<DotLock> is a multipurpose queing locking system. Originally designed to take some of the pain away from locking on NFS filesystems.

This module allows script writers to develop on multiple hosts when locking between these hosts is an issue. It allows queing - scary but true. It also provides an atomic method of locking by using the "link" function between files.

The locking/queing method provided is purely on a file manipulation level. Also note that this object does not handle signals. If the program is interrupted, any open lockfiles will be left behind. 

=back

=head1 CONSTRUCTOR

=over 4

=item B<new (OPTIONS)> - create a new DotLock object

This is the constructor of the C<DotLock> object. 

OPTIONS are passed to the object in a hash-like fashion using keys and values. The keys are the same as the methods provided below, as shown:

$t = new DotLock(
        path => "/home/ken/perl/locking/", 
        errmode => "die", 
        timeout => 100, 
        maxqueue => 8,
        retrytime => 1,
        domain => 'optusnet.com.au',
);

So you can define all settings in one go. Besides the "lock" method, this is the heart and soul of the module.

=back

=head1 METHODS

=over 4

=item B<lock> - attempt to obtain a lock

This method will attempt to obtain a lock with the configuration passed to it from the constructor or from the various setup methods.

The process is basically as follows:

1. A temporary lockfile is created which is associated with the script and host.

2. The lockfile directory is listed to find the highest free lock.

3. Depending on the maxqueue setting, the highest lock is obtained.

4. If for some reason the highest lock was nabbed before the current script could get it, the current script will try the next higher up lock que until it obtains a placing.

5. Once a place in the que is obtained, lock will attempt to get the next lock. It will retry every second, or the time defined in the retrytime method.

6. Unless the process has reached the point of obtaining the main lock, the script will return to step 5 to obtain the next que placing.

7. Once the main lock is obtained, the script using this object will do its business.

=item B<unlock> - remove all lockfiles

The method removes all open lockfiles, enabling other processes to obtain any lock you have left open. This is also the method called upon object destruction.

=item B<timeout ([TIMEOUT])> - timeout for obtaining a lock

This defaults to 60 seconds.

Set this method to the amount of time you want your script to wait for a lock. The C<TIMEOUT> value is in seconds. 

If you fail to obtain the lock with the set time, the object will return an error and react based on the C<errmode> method set when creating the object.

=item B<path ([PATH])> - path of lockfiles

Set the directory for where the lockfiles will be kept. This by default is set to /var/lock/quelock. If the path does not exist, an error will occur.

For two processes to use the same lockfiles, this path must be the same in both processes.

With this method you can either set the path of the lockfiles, or return the previous path.

=item B<errmode ([MODE])> - set how to react to errors

The errmode method can be set to either "die" to die when an error is encountered or "return" to return an error message. The error message can be obtained from the errmsg method.

The default setting for errmode is "die".

=item B<maxqueue ([QUE])> - the highest allowable que placing

The maxqueue data method is used by the C<lock> method. When attempting to find a place in the que, it will look at this figure - if the figure is higher than the highest free que then DotLock will return an error.

By default, queing is turned off.

=item B<retrytime ([TIME])> - the time in seconds to retry the next lock placing

You set this data method to the amount of time in seconds you with the system to retry for the next available lock. The default is 1 second.

=item B<domain ([DOMAIN])> - set the domain of your system

Although not necessary, this allows all hosts entries to be reduced to just their hostname. This is only really usefull if you plan on running scripts with one domain and one domain only.

=item B<errmsg> - returns the last error message

This method will return the error message of the last error found. When C<errmode> is set to "return" this variable will be loaded with the error message.

=back

=head1 SEE ALSO

=over 2

Some other good modules for locking:

B<LockFile::Simple>

B<IPC::Locker>

=back

=head1 EXAMPLES

use DotLock;

$t = new DotLock(
        path => "/home/ken/perl/locking/locktest", 
        errmode => "return", 
        timeout => 100, 
        maxqueue => 8,
        retrytime => 1,
        domain => 'optusnet.com.au',
);

$t->lock || print $t->errmsg . "\n";

print "Locked\n";

$blah = <STDIN>;

$t->unlock;

=head1 AUTHOR

Ken Barber E<lt>ken@optusnet.com.auE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Ken Barber. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

