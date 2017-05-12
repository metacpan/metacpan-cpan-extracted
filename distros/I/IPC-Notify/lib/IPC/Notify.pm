#!/usr/bin/perl

# Copyright 2007 Jason Long. All rights reserved.

package IPC::Notify;
use strict;
use warnings;
use Carp;
use Fcntl ":flock", ":seek";
use POSIX "mkfifo";
use File::Temp "tempdir";
our $VERSION = 0.002;

=head1 NAME

IPC::Notify

=head1 SYNOPSIS

  # Process 1- waits to be notified and then performs work
  my $notify = IPC::Notify->new("/path/to/lock");
  $notify->lock;
  for (;;) {
    $notify->wait;
    # do work
    print "I am doing some work!\n";
  }
  $notify->unlock;

  # Process 2- wakes up process 1
  my $notify = IPC::Notify->new("/path/to/lock");
  $notify->lock;
  $notify->notify;
  $notify->unlock;

=head1 CONSTRUCTOR

=head2 new() - create a new notify locking object

  my $notify = IPC::Notify->new($filename);

=cut

sub new
{
	my $class = shift;
	my ($file) = @_;
	my $self = bless { file => $file }, $class;

	# create the file if necessary
	open my $fh, ">>", $file
		or die "Error: cannot create $file: $!\n";
	close $fh;

	return $self;
}

=head1 METHODS

=cut

#returns 1 if a byte was read from the fifo
#returns undef if timeout occurred
sub _read_from_fifo
{
	my $self = shift;
	my ($fifofh, $timeout) = @_;

	#print STDERR "selecting...\n";
	use IO::Select;
	my $s = IO::Select->new;
	$s->add($fifofh);

	my @ready = $s->can_read($timeout);
	if (@ready)
	{
		#print STDERR "reading...\n";
		my $buf = "";
		read $fifofh, $buf, 1;
		return 1;
	}
	return;
}

sub _close_fifo
{
	my $self = shift;
	return unless $self->{fifofh};
	close $self->{fifofh};
	$self->{fifofh} = undef;
}

sub _create_fifo
{
	my $self = shift;
	unless ($self->{fifofile})
	{
		my $tempdir = tempdir(CLEANUP => 1);
		my $fifo_name = $self->{fifo_name} || "$$.fifo";
		my $fifofile = "$tempdir/$fifo_name";
		mkfifo($fifofile, 0777)
			or die "Error: cannot mkfifo: $!\n";
		$self->{fifofile} = $fifofile;
	}
	unless ($self->{fifofh})
	{
		my $fifofile = $self->{fifofile};
		#print STDERR "opening $fifofile...\n";
		open my $fifofh, "+<", $fifofile
			or die "Error: cannot open $fifofile: $!\n";
		$self->{fifofh} = $fifofh;
	}
	return $self->{fifofh};
}

sub _debug
{
	my $self = shift;
	print STDERR "===begin " . $self->{file} . "===\n";
	my $fh = $self->{fh};
	seek $fh, 0, SEEK_SET
		or die "Error: cannot seek: $!\n";
	while (<$fh>)
	{
		print STDERR $_;
	}
	print STDERR "===end " . $self->{file} . "===\n";
}

sub _put_hash_at
{
	my $self = shift;
	my ($pos) = @_;

	my $fh = $self->{fh};
	seek $fh, $pos, SEEK_SET
		or die "Error: cannot seek: $!\n";
	print $fh "#";
}

sub _put_line
{
	my $self = shift;
	my ($to_write) = @_;

	$to_write .= "\n";
	my $need_len = length($to_write);

	my $fh = $self->{fh};
	seek $fh, 0, SEEK_SET
		or die "Error: can't seek: $!\n";
	my $found_pos;
	my $found_len = 0;
	for (;;)
	{
		my $cur_pos = tell $fh;
		my $line = <$fh>;
		last unless defined $line;
		if ($line =~ /^#/ or $line =~ /^$/)
		{
			my $len = length($line);
			unless (defined $found_pos)
			{
				$found_pos = $cur_pos;
				$found_len = 0;
			}
			$found_len += $len;
			last if $found_len >= $need_len;
		}
		else
		{
			undef $found_pos;
		}
	}

	if (defined $found_pos)
	{
	#	print STDERR "need $need_len bytes\n";
	#	print STDERR "found " . $found_len . " bytes at pos="
	#		. $found_pos . "\n";
		seek $fh, $found_pos, SEEK_SET
			or die "Error: cannot seek: $!\n";
		$to_write .= "#" if $found_len > ($need_len + 1);
	}
	else
	{
		seek $fh, 0, SEEK_END
			or die "Error: cannot seek to end: $!\n";
		$found_pos = tell $fh;
		#print STDERR "end=$found_pos\n";
	}
	print $fh $to_write;

	return $found_pos;
}

sub _write_to_fifo
{
	my $self = shift;
	my ($fifofile) = @_;
	#print STDERR "opening $fifofile...\n";
	open my $fifofh, "+>", $fifofile
		or die "Error: cannot write to $fifofile: $!\n";
	print STDERR "writing to $fifofile...\n";
	print $fifofh ".";
	#print STDERR "closing $fifofile...\n";
	close $fifofh;
}

=head2 is_locked() - check whether object is currently "locked"

  if ($notify->is_locked) { ... }

Returns nonzero if the object is currently locked.

=cut

sub is_locked
{
	my $self = shift;
	return 0 < $self->{lock_count};
}

=head2 lock() - obtain a file lock

  $notify->lock;

A lock must be acquired before using wait() or notify() on this object.
This ensures proper synchronization. This method will block if another
(non-waiting) process has the lock.

=cut

sub lock
{
	my $self = shift;
	return if 0 < $self->{lock_count}++;

	my $file = $self->{file};
	open my $fh, "+<", $file
		or die "Error: cannot open $file: $!\n";
	flock $fh, LOCK_EX
		or die "Error: cannot lock $file: $!\n";
	$self->{fh} = $fh;
}

=head2 notify() - wake up all processes waiting on this lock

  $notify->notify;

This will wake up all processes waiting on the lock, however,
you need to call unlock() from the notifying process before
the other process(es) will be allowed to proceed.

=cut

sub notify
{
	my $self = shift;
	croak "not locked" unless $self->is_locked;

	return if $self->{notified};

	my $fh = $self->{fh};
	seek $fh, 0, SEEK_SET
		or die "Error: cannot seek: $!\n";
	while (<$fh>)
	{
		chomp;
		next if (/^\s*#/ || /^\s*$/);
		$self->_write_to_fifo($_);
	}
	$self->{notified} = 1;
}

=head2 wait() - wait for a notification on this lock

  $notify->wait($timeout_in_seconds);

This method will atomically give up the lock this process has
on the object and wait for a notification. Before returning
control, it will re-acquire the lock.

If $timeout_in_seconds is specified, wait() will return control
early if a notification is not received within
the specified time. Fractional values are acceptable.

If $timeout_in_seconds is absent, or "undef", then it
will wait forever. If $timeout_in_seconds is zero,
the call will be nonblocking. (It will simply indicate whether
a notification has been received.)

The result is nonzero if a notification was received.
Otherwise, the timeout had elapsed.

=cut

sub wait
{
	my $self = shift;
	my $timeout = shift;
	croak "not locked" unless $self->is_locked;

	# create a fifo
	my $fifofh = $self->_create_fifo;

	# write the name of this fifo to our lock file
	my $pos = $self->_put_line($self->{fifofile});

	# release the file lock
	flock $self->{fh}, LOCK_UN
		or die "Error: cannot unlock: $!\n";

#sleep 5;

	# read from fifo
	my $result = $self->_read_from_fifo($fifofh, $timeout);

#print STDERR "result=$result\n";
#sleep 5;

	#$self->_debug;

	flock $self->{fh}, LOCK_EX
		or die "Error: cannot lock: $!\n";

	# try again to read from the fifo, this time with timeout=0
	$result ||= $self->_read_from_fifo($fifofh, 0);

	# no longer need it in the lock file
	unless ($ENV{LEAVEIT}) {
	$self->_put_hash_at($pos);
	}

	$self->{notified} = undef;
	return $result;
}

=head2 unlock() - release a lock

  $notify->unlock;

Be sure to unlock() if you are going to do some other work.
As long as one process holds the lock, other processes will block
to notify().

=cut

sub unlock
{
	my $self = shift;
	return if 0 < --$self->{lock_count};

	$self->_close_fifo;

	my $fh = $self->{fh};
	flock $fh, LOCK_UN;
	close $fh;

	$self->{notified} = undef;
}

1;
