package File::Flock;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(lock unlock lock_rename forget_locks);

use Carp;
use POSIX qw(EAGAIN EACCES EWOULDBLOCK ENOENT EEXIST O_EXCL O_CREAT O_RDWR); 
use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB LOCK_UN);
use IO::File;
use Data::Structure::Util qw(unbless);

use vars qw($VERSION $debug $av0debug);

BEGIN	{
	$VERSION = 2014.01;
	$debug = 0;
	$av0debug = 0;
}

use strict;
no strict qw(refs);

my %locks;		# did we create the file?
my %lockHandle;
my %shared;
my %pid;
my %rm;

sub new_flock {
	my ($pkg, $file, $shared, $nonblocking) = @_;
	lock_flock($file, $shared, $nonblocking) or return undef;
	return bless [$file], $pkg;
}

sub DESTROY
{
	my ($this) = @_;
	unlock_flock($this->[0]);
}

sub lock_flock
{
	my ($file, $shared, $nonblocking) = @_;

	my $f = new IO::File;

	my $created = 0;
	my $previous = exists $locks{$file};

	# the file may be springing in and out of existence...
	OPEN:
	for(;;) {
		if (-e $file) {
			unless (sysopen($f, $file, O_RDWR)) {
				redo OPEN if $! == ENOENT;
				croak "open $file: $!";
			}
		} else {
			unless (sysopen($f, $file, O_CREAT|O_EXCL|O_RDWR)) {
				redo OPEN if $! == EEXIST;
				croak "open >$file: $!";
			}
			print STDERR " {$$ " if $debug; # }
			$created = 1;
		}
		last;
	}
	$locks{$file} = $created || $locks{$file} || 0;
	$shared{$file} = $shared;
	$pid{$file} = $$;
	
	$lockHandle{$file} = $f;

	my $flags;

	$flags = $shared ? LOCK_SH : LOCK_EX;
	$flags |= LOCK_NB
		if $nonblocking;
	
	local($0) = "$0 - locking $file" if $av0debug && ! $nonblocking;
	my $r = flock($f, $flags);

	print STDERR " ($$ " if $debug and $r;

	if ($r) {
		# let's check to make sure the file wasn't
		# removed on us!

		my $ifile = (stat($file))[1];
		my $ihandle;
		eval { $ihandle = (stat($f))[1] };
		croak $@ if $@;

		return 1 if defined $ifile 
			and defined $ihandle 
			and $ifile == $ihandle;

		# oh well, try again
		flock($f, LOCK_UN);
		close($f);
		return lock_flock($file);
	}

	return 1 if $r;
	if ($nonblocking and 
		(($! == EAGAIN) 
		or ($! == EACCES)
		or ($! == EWOULDBLOCK))) 
	{
		if (! $previous) {
			delete $locks{$file};
			delete $lockHandle{$file};
			delete $shared{$file};
			delete $pid{$file};
		}
		if ($created) {
			# oops, a bad thing just happened.  
			# We don't want to block, but we made the file.
			&background_remove($f, $file);
		}
		close($f);
		return 0;
	}
	croak "flock $f $flags: $!";
}

#
# get a lock on a file and remove it if it's empty.  This is to
# remove files that were created just so that they could be locked.
#
# To do this without blocking, defer any files that are locked to the
# the END block.
#
sub background_remove
{
	my ($f, $file) = @_;

	if (flock($f, LOCK_EX|LOCK_NB)) {
		unlink($file)
			if -s $file == 0;
		flock($f, LOCK_UN);
		return 1;
	} else {
		$rm{$file} = 1
			unless exists $rm{$file};
		return 0;
	}
}

sub unlock_flock
{
	my ($file) = @_;

	if (ref $file eq 'File::Flock') {
		unbless $file; # avoid destructor later
		$file = $file->[0];
	}

	croak "no lock on $file" unless exists $locks{$file};
	my $created = $locks{$file};
	my $unlocked = 0;


	my $size = -s $file;
	if ($created && defined($size) && $size == 0) {
		if ($shared{$file}) {
			$unlocked = 
				&background_remove($lockHandle{$file}, $file);
		} else { 
			# {
			print STDERR " $$} " if $debug;
			unlink($file) 
				or croak "unlink $file: $!";
		}
	}
	delete $locks{$file};
	delete $pid{$file};

	my $f = $lockHandle{$file};

	delete $lockHandle{$file};

	return 0 unless defined $f;

	print STDERR " $$) " if $debug;
	$unlocked or flock($f, LOCK_UN)
		or croak "flock $file UN: $!";

	close($f);
	return 1;
}

sub lock_rename_flock
{
	croak "arguments to lock_rename" unless @_ == 2;
	my ($oldfile, $newfile) = @_;

	if (ref $oldfile eq 'File::Flock') {
		my $obj = $oldfile;
		$oldfile = $obj->[0];
		$obj->[0] = $newfile;
	}
	if (exists $locks{$newfile}) {
		unlock_flock($newfile);
	}
	delete $locks{$newfile};
	delete $shared{$newfile};
	delete $pid{$newfile};
	delete $lockHandle{$newfile};
	delete $rm{$newfile};

	$locks{$newfile}	= $locks{$oldfile}	if exists $locks{$oldfile};
	$shared{$newfile}	= $shared{$oldfile}	if exists $shared{$oldfile};
	$pid{$newfile}		= $pid{$oldfile}	if exists $pid{$oldfile};
	$lockHandle{$newfile}	= $lockHandle{$oldfile} if exists $lockHandle{$oldfile};
	$rm{$newfile}		= $rm{$oldfile}		if exists $rm{$oldfile};

	delete $locks{$oldfile};
	delete $shared{$oldfile};
	delete $pid{$oldfile};
	delete $lockHandle{$oldfile};
	delete $rm{$oldfile};

	return 1;
}

sub forget_locks_flock
{
	%locks = ();
	%shared = ();
	%pid = ();
	%lockHandle = ();
	%rm = ();
}

#
# Unlock any files that are still locked and remove any files
# that were created just so that they could be locked.
#

sub final_cleanup_flock
{
	my $f;
	for $f (keys %locks) {
		unlock_flock($f)
			if $pid{$f} == $$;
	}

	my %bgrm;
	for my $file (keys %rm) {
		my $f = new IO::File;
		if (sysopen($f, $file, O_RDWR)) {
			if (flock($f, LOCK_EX|LOCK_NB)) {
				unlink($file)
					if -s $file == 0;
				flock($f, LOCK_UN);
			} else {
				$bgrm{$file} = 1;
			}
			close($f);
		}
	}
	if (%bgrm) {
		my $ppid = fork;
		croak "cannot fork" unless defined $ppid;
		my $pppid = $$;
		my $b0 = $0;
		$0 = "$b0: waiting for child ($ppid) to fork()";
		unless ($ppid) {
			my $pid = fork;
			croak "cannot fork" unless defined $pid;
			unless ($pid) {
				for my $file (keys %bgrm) {
					my $f = new IO::File;
					if (sysopen($f, $file, O_RDWR)) {
						if (flock($f, LOCK_EX)) {
							unlink($file)
								if -s $file == 0;
							flock($f, LOCK_UN);
						}
						close($f);
					}
				}
				print STDERR " $pppid] $pppid)" if $debug;
			}
			kill(9, $$); # exit w/o END or anything else
		}
		waitpid($ppid, 0);
		kill(9, $$); # exit w/o END or anything else
	}

	%locks = ();
	%lockHandle = ();
	%shared = ();
	%pid = ();
	%rm = ();
	%bgrm = ();
}

END {
	final_cleanup();
}

BEGIN {
	if ($File::Flock::Forking::SubprocessEnabled) {
		require File::Flock::Subprocess;
		*new	        = *File::Flock::Subprocess::new;
		*final_cleanup	= *File::Flock::Subprocess::final_cleanup;
		*lock		= *File::Flock::Subprocess::lock;
		*unlock		= *File::Flock::Subprocess::unlock;
		*lock_rename	= *File::Flock::Subprocess::lock_rename;
		*forget_locks	= *File::Flock::Subprocess::forget_locks;
	} else {
		*new	        = *new_flock;
		*final_cleanup	= *final_cleanup_flock;
		*lock		= *lock_flock;
		*unlock		= *unlock_flock;
		*lock_rename	= *lock_rename_flock;
		*forget_locks	= *forget_locks_flock;
	}
}

1;

__END__

=head1 NAME

 File::Flock - file locking with flock

=head1 SYNOPSIS

 use File::Flock;

 lock($filename);

 lock($filename, 'shared');

 lock($filename, undef, 'nonblocking');

 lock($filename, 'shared', 'nonblocking');

 unlock($filename);

 lock_rename($oldfilename, $newfilename)

 my $lock = new File::Flock '/somefile';

 $lock->unlock();

 $lock->lock_rename('/new/file');

 forget_locks();

=head1 DESCRIPTION

Lock files using the flock() call.  If the file to be locked does not
exist, then the file is created.  If the file was created then it will
be removed when it is unlocked assuming it's still an empty file.

Locks can be created by new'ing a B<File::Flock> object.  Such locks
are automatically removed when the object goes out of scope.  The
B<unlock()> method may also be used.

B<lock_rename()> is used to tell File::Flock when a file has been
renamed (and thus the internal locking data that is stored based
on the filename should be moved to a new name).  B<unlock()> the
new name rather than the original name.

Locks are released on process exit when the process that created the
lock exits.  Subprocesses that exit do not remove locks.
Use forget_locks() or POSIX::_exit() to prevent unlocking on process exit.

=head1 SEE ALSO

See L<File::Flock::Subprocess> for a variant that uses a subprocess to hold
the locks so that the locks survive when the parent process forks.
See L<File::Flock::Forking> for a way to automatically choose between
File::Flock and L<File::Flock::Subprocess>.

=head1 LICENSE

Copyright (C) 1996-2012 David Muir Sharnoff <cpan@dave.sharnoff.org>
Copyright (C) 2013 Google, Inc.
This module may be used/copied/etc on the same terms as Perl itself.

=head1 PACKAGERS

File::Flock is packaged for Fedora by Emmanuel Seyman <emmanuel.seyman@club-internet.fr>.

