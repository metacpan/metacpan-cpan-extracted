package File::Flock::Subprocess;

@ISA = qw(Exporter);
@EXPORT = qw(lock unlock lock_rename forget_lock);

# use Smart::Comments;
use strict;
use warnings;
require Exporter;
require POSIX;
use Socket;
use IO::Handle;
use Time::HiRes qw(sleep time);
use Carp;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Data::Structure::Util qw(unbless);

# shared
my $dir;
my $socket;
my $av0;
my $debug;

BEGIN { $debug = 0; }

# proxy server
my $connections;
my $parent_pid;
my $timer;
my $ioe_parent;
my $counter = '0001';
my %locks;

# client side
my $child;
my %lock_pids;		# filename -> pid
my %lock_proxies;	# pid -> proxy
my %lock_count;		# pid -> count
my $last_pid;

sub new
{
	my ($pkg, $file, $shared, $nonblocking) = @_;
	&lock($file, $shared, $nonblocking) or return undef;
	return bless [$file], __PACKAGE__;
}

sub DESTROY
{
	my ($this) = @_;
	unlock($this->[0]);
}

sub encode
{
	local($_);
	for $_ (@_) {
		### assert: defined $_
		s/\\/\\\\/g;
		s/\n/\\n/g;
		s/\t/\\t/g;
	}
}

sub decode
{
	local($_);
	for $_ (@_) {
		### assert: defined $_
		s/\\t/\t/g;
		s/\\n/\n/g;
		s/\\\\/\\/g;
	}
}

sub update_proxy_connections
{
use Carp qw(longmess);
	print STDERR longmess("last_pid undefined") unless defined $last_pid;
	return if $last_pid == $$;
	### UPDATING PROXY CONNECTIONS: "$$ IS NOT $last_pid"
	$last_pid = $$;
	for my $pid (keys %lock_proxies) {
		my $proxy = IO::Socket::UNIX->new(
			Peer	=> "$socket.$pid",
			Type	=> SOCK_STREAM,
		) or carp "Could not open connection to lockserver $socket.$pid: $!";

		### CLOSING OLD $$
		$lock_proxies{$pid}->close();
		$lock_proxies{$pid} = $proxy;
	}
	### DONE UPDATING: $$
}

sub request
{
	my ($request, $file) = @_;
	my $av0 = $0;
	local($0) = $av0;
	$0 = "$av0 - lock proxy request $request";
	my $ts_before = time;
	### REQUEST: "$$ $request"

	my $proxy = $lock_proxies{$lock_pids{$file}} or die;

	$proxy->print("$$ $request\n")
		or croak "print to lock proxy: $!";
	for(;;) {
		my $ok = $proxy->getline();
		chomp($ok);
		### RESPONSE: $ok
		if ($ts_before) {
			my $diff = time - $ts_before;
		}
		if ($ok =~ /^ERROR:(.*)/) {
			my $error = $1;
			decode($error);
			### ................. $error
			$error =~ s/\n.*//s;
			### ..... $error
			croak $error;
		} elsif ($ok =~ /^RESULT=(\d+)/) {
			### RESULT: $$.$1
			return $1;
		} else {
			die "unexpected response from lock proxy: $ok";
		}
	}
}

sub lock
{
	my ($file, $shared, $nonblocking) = @_;

	update_proxy_connections();

	if (!$lock_pids{$file}) {
		$lock_pids{$file} = $$;
		$lock_count{$$}++;
	}
	if (!$lock_proxies{$$}) {
		$lock_proxies{$$} = IO::Socket::UNIX->new(
			Peer	=> $socket,
			Type	=> SOCK_STREAM,
		) or carp "Could not open connection to lockserver $socket: $!";

		request("LISTEN", $file);
	}

	$shared = $shared ? "1" : "0";
	$nonblocking = $nonblocking ? "1" : "0";
	my $orig_file = $file;
	encode($file);
	my $r = request("LOCK $shared$nonblocking $file", $file);
	$locks{$orig_file} = $$ if $r;
	return $r;
}

sub unlock
{
	my ($file) = @_;

	if (ref $file eq __PACKAGE__) {
		unbless $file; # avoid destructor later
		$file = $file->[0];
	}

	update_proxy_connections();

	if (ref $file eq 'File::Flock') {
		bless $file, 'UNIVERSAL'; # avoid destructor later
		$file = $$file;
	}
	croak "File $file not locked" unless $lock_pids{$file};
	my $orig_file = $file;
	encode($file);
	my $r = request("UNLOCK $file", $file);
	my $lock_pid = delete $lock_pids{$orig_file};
	if ($lock_count{$lock_pid} <= 0) {
		delete $lock_proxies{$lock_pid};
	}
	delete $locks{$orig_file};
	return $r;
}

sub lock_rename
{
	croak "arguments to lock_rename" unless @_ == 2;
	my ($oldfile, $newfile) = @_;

	if (ref $oldfile eq 'File::Flock::Subprocess') {
		my $obj = $oldfile;
		$oldfile = $obj->[0];
		$obj->[0] = $newfile;
	}

	update_proxy_connections();

	carp "File $oldfile not locked" unless $lock_pids{$oldfile};
	carp "File $newfile already locked" if $lock_pids{$newfile};
	my ($orig_oldfile, $orig_newfile) = ($oldfile, $newfile);
	encode($oldfile, $newfile);
	my $r = request("LOCK_RENAME $oldfile\t$newfile", $oldfile);
	$lock_pids{$orig_newfile} = delete $lock_pids{$orig_oldfile};
	$locks{$orig_newfile} = delete $locks{$orig_oldfile} if exists $locks{$orig_oldfile};
	return $r;
}

sub forget_locks
{
	%locks = ();
}

sub final_cleanup
{
	for (keys %locks) {
		unlock($_) if $locks{$_} == $$;
	}
	$child->close() if defined $child;
	undef $child;
	undef %lock_proxies;
}

END {
	final_cleanup();
}

sub run_lockserver
{
	my ($parent) = @_;
	require IO::Event;
	import IO::Event 'AnyEvent';

	my $ioe_listener = IO::Event::Socket::UNIX->new(
		Type	=> SOCK_STREAM,
		Local	=> $socket,
		Listen	=> 255,
		Handler	=> 'File::Flock::Subprocess::Master',
		Description => "listen($socket)",
	);
	carp "could not listen on unix socket: $!" unless $ioe_listener;

	# we don't add a connection for the listener

	$parent->print("ready\n");

	$ioe_parent = IO::Event->new($parent, __PACKAGE__,
		{ description => 'socketpair', read_only => 1});

	$connections->add($ioe_parent);

	if ($debug) {
		$timer = IO::Event->timer(
			interval => 2,
			cb	=> sub { $connections->display() },
		);
	}

	IO::Event::loop();

	File::Flock::final_cleanup_flock();
}

{
	package File::Flock::Subprocess::Master;
	use strict;
	use warnings;

	# lock proxy master accepting connection to start new child
	sub ie_connection
	{
		my ($pkg, $ioe) = @_;
		my $client = $ioe->accept('File::Flock::Subprocess') or die;
		### CONNECT IN MASTER: "$$ - @{[$ioe->ie_desc()]}"
		my $new_child;
		for(;;) {
			$new_child = fork();
			### FORKED IN ACCEPT
			### PID: $$ 
			### CHILD: $new_child
			last if defined $new_child;
			warn "Could not fork: $!";
			sleep(1);
		}
		if ($new_child) {
			# now is as good a time as any to clean up zombies
			my $kid;
			do {
				$kid = waitpid(-1, &POSIX::WNOHANG);
				### CHILD PROXY ZOMBIE REAPED: $kid
			} while $kid > 0;
			$client->close();
		} else {
			$ioe->close();
			$connections->remove($ioe_parent);
			$ioe_parent->close();
			undef $ioe_parent;
			### NEW CHILD PROXY SERVER $$
			$av0 = "Locking proxy slave for $parent_pid using $socket";
			$connections->add($client, "connection($socket)");
		}
	}
	sub ie_input {
		die;
	}
	sub ie_eof {
		die;
	}
}

# lock proxy children accepting replacement connections
sub ie_connection
{
	my ($pkg, $ioe) = @_;
	my $replacement = $ioe->accept();
	$connections->add($replacement, "slave(@{[$ioe->ie_desc().$counter++]})");
}

# could be lock server master losing socketpair or lock server
# proxy child losing a client
sub ie_eof
{
	### EOF IN CHILD
	my ($handler, $ioe, $input_buffer_reference) = @_;
	$ioe->close();
	unless ($connections->remove($ioe)) {
		### "PROXY SERVER $$ ALL DONE"
		IO::Event::unloop_all();
	}
}

sub ie_input
{
	### INPUT IN CHILD
	my ($handler, $ioe, $input_buffer_reference) = @_;
	$0 = "$av0: processing request";
	while (my $request = $ioe->getline()) {
		$0 = "$av0: handling $request";

		my $pid;
		$request =~ s/^(\d+) //
			or die "bad request to lock proxy: $request";
		$pid = $1;
		$0 = "$av0: handling $request from $pid: $request";

		my $r;
		### PROCESSING REQUEST FROM $pid : $request
		eval {
			if ($request =~ m{^LOCK (.)(.) (.*)\n}s) {
				my ($shared, $nonblocking, $file) = ($1, $2, $3);
				decode($file);
				$r = File::Flock::lock_flock($file, $shared, $nonblocking);
			} elsif ($request =~ m{^UNLOCK (.*)\n}s) {
				my $file = $1;
				decode($file);
				$r = File::Flock::unlock_flock($file);
			} elsif ($request =~ m{^LOCK_RENAME (.*?)\t(.*)\n}) {
				my ($oldfile, $newfile) = ($1, $2);
				decode($oldfile, $newfile);
				$r = File::Flock::lock_rename_flock($oldfile, $newfile);
			} elsif ($request =~ m{^LISTEN\n}) {
				IO::Event::Socket::UNIX->new(
					Type	=> SOCK_STREAM,
					Local	=> "$socket.$pid",
					Listen	=> 255,
					Description => "slave($socket.$pid)",
				) or die "Listen $socket.$pid: $!";
				$r = 1;
			} elsif ($request =~ m{^QUIT\n}) {
				$r = 1;
			} else {
				die "Unknown remote lock request: $request";
			}
		};
		if ($@) {
			my $error = $@;
			encode($error);
			$ioe->print("ERROR:$error\n");
		} else {
			$r = 0 + $r;
			$ioe->print("RESULT=$r\n");
		}
		$0 = "$av0: idle";
	}
}

{
	package File::Flock::Subprocess::Connections;

	use strict;
	use warnings;

	sub new {
		return bless {};
	}
	sub add {
		my ($self, $ioe, $label) = @_;
		$ioe->ie_desc($label) if $label;
		die "duplicate @{[$ioe->ie_desc()]}" if ++$self->{$ioe->ie_desc()} > 1;
		print STDERR "PROXY $$: " . join(' ', 'ADD', $ioe->ie_desc(), ':', sort keys %$self) . "\n" if $debug;
	}
	sub remove
	{	
		my ($self, $ioe) = @_;
		die $ioe unless $self->{$ioe->ie_desc()};
		delete $self->{$ioe->ie_desc()};;
		print STDERR "PROXY $$: " . join(' ', 'REMOVE', $ioe->ie_desc(), ':', sort keys %$self) . "\n" if $debug;
		return scalar(keys %$self);
	}
	sub display {
		my ($self) = @_;
		print STDERR "PROXY $$: " . join(' ', sort keys %$self) . "\n" if $debug;
	}
}


BEGIN {
	# Let File::Flock know we're live with Subprocess
	$File::Flock::Forking::SubprocessEnabled = 1;
	require File::Flock;

	$dir = tempdir(CLEANUP => 0);
	$socket = "$dir/lock";

	my $parent = new IO::Handle;
	$child = new IO::Handle;
	socketpair($parent, $child, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
		or die "cannot create socketpair: $!";

	$parent_pid = $$;
	my $child_pid;
	### FORKING: $$
	for(;;) {
		$child_pid = fork();
		### CHILD: $child_pid
		last if defined $child_pid;
		warn "Could not fork: $!";
		sleep(1);
	}
	if ($child_pid) {
		$parent->close();
		my $ready = <$child>;
		die unless $ready && $ready eq "ready\n";
		$last_pid = $$;

		# We need File::Flock->new() to work.  This is a bit gross:
		*File::Flock::new = \&File::Flock::Subprocess::new
			unless defined &File::Flock::new;

		if ($debug) {
			$SIG{ALRM} = sub {
				print STDERR "$$ Alive with " . ($child ? "child defined" : "child undefined") . "\n";
				alarm(2);
			};
			alarm(2);
		}
	} else {
		require IO::Event;
		$av0 = "Locking proxy master for $parent_pid, using $socket";
		$0 = $av0;
		$child->close();
		undef $child;

		$connections = File::Flock::Subprocess::Connections->new();

		run_lockserver($parent);

		POSIX::_exit(0);
		die;

	}
}

1;

__END__

Implementation notes.

We're trying to mimic the bahavior of locking on systems that
preserve locks across fork().

We create connections to the proxy server as needed.  When we make
such connections, we record (with the connection) our current process
PID.

Whenever we have a new lock()/unlock()/lock_rename() request, we check
to see if we're still the same process we used to be.  If not, we
re-open connections to the lock proxies.  This way connections aren't
shared with child processes.



=head1 NAME

 File::Flock::Subprocess - file locking with flock in a subprocess

=head1 SYNOPSIS

 use File::Flock::Subprocess;

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

This is a wrapper around L<File::Flock> that starts a subprocess and
does the locking in the subprocess with L<File::Flock>.  The purpose of
this is to handle operating systems (eg: Solaris) that do not retain
locks across a call to fork().

The sub-process for this is created with fork() when
File::Flock::Subprocess is compiled.  I've tried to minimize the
side-effects calling fork() by doing calling it early and by using
POSIX::_exit() to quit but it is still worth being aware of.  I suggest
loading File::Flock::Subprocess early.

Use L<File::Flock::Forking> to automatically detect when this is needed.

Read the docs for L<File::Flock> for details of the API.

=head1 ERRATA

Any errors reported by the locking proxy File::Flock::Subprocess starts
will be reported as "Compilation Failed" errors because the proxy is
started in a BEGIN{} block.

=head1 LICENSE

Copyright (C) 2013 Google, Inc.
This module may be used/copied/etc on the same terms as Perl itself.

