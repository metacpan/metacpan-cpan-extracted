# See copyright, etc in below POD section.
######################################################################

=head1 NAME

IPC::Locker::Server - Distributed lock handler server

=head1 SYNOPSIS

  use IPC::Locker::Server;

  IPC::Locker::Server->new(port=>1234)->start_server;

  # Or more typically via the command line
  lockerd

=head1 DESCRIPTION

L<IPC::Locker::Server> provides the server for the IPC::Locker package.

=over 4

=item new ([parameter=>value ...]);

Creates a server object.

=item start_server ([parameter=>value ...]);

Starts the server.  Does not return.

=back

=head1 PARAMETERS

=over 4

=item family

The family of transport to use, either INET or UNIX.  Defaults to INET.

=item port

The port number (INET) or name (UNIX) of the lock server.  Defaults to
'lockerd' looked up via /etc/services, else 1751.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<https://www.veripool.org/ipc-locker>.

Copyright 1999-2019 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<IPC::Locker>, L<lockerd>

=cut

######################################################################

package IPC::Locker::Server;
require 5.006;
require Exporter;
@ISA = qw(Exporter);

use IPC::Locker;
use Socket;
use IO::Socket;
use IO::Poll qw(POLLIN POLLOUT POLLERR POLLHUP POLLNVAL);
use Time::HiRes;

use IPC::PidStat;
use strict;
use vars qw($VERSION $Debug %Locks %Clients $Poll $Interrupts $Hostname $Exister);
use Carp;

######################################################################
#### Configuration Section

# Other configurable settings.
$Debug = 0;

$VERSION = '1.500';
$Hostname = IPC::Locker::hostfqdn();

######################################################################
#### Globals

# All held locks
%Locks = ();
our $_Client_Num = 0;  # Debug use only
our $StartTime = time();

our $RecheckLockDelta = 1;		# Loop all locks every N seconds
our $PollDelta = 1;			# Poll every N seconds for activity
our $AutoUnlockCheckDelta = 2;		# Check every N seconds for pid existance
our $AutoUnlockCheckPerSec = 100;	# Check at most N existances per second

######################################################################
#### Creator

sub new {
    # Establish the server
    @_ >= 1 or croak 'usage: IPC::Locker::Server->new ({options})';
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {
	#Documented
	port=>$IPC::Locker::Default_Port,
	family=>$IPC::Locker::Default_Family,
	host=>'localhost',
	@_,};
    bless $self, $class;
    my $param = {@_};
    if (defined $param->{family} && $param->{family} eq 'UNIX'
	&& !exists($param->{port})) {
	$self->{port} = $IPC::Locker::Default_UNIX_port;
    }
    return $self;
}

sub start_server {
    my $self = shift;

    # Open the socket
    _timelog("Listening on $self->{port}\n") if $Debug;
    my $server;
    if ($self->{family} eq 'INET') {
	$server = IO::Socket::INET->new( Proto     => 'tcp',
					 LocalAddr => $self->{host},
					 LocalPort => $self->{port},
					 Listen    => SOMAXCONN,
					 Reuse     => 1)
	    or die "$0: Error, socket: $!";
    } elsif ($self->{family} eq 'UNIX') {
	$server = IO::Socket::UNIX->new(Local => $self->{port},
					Listen    => SOMAXCONN,
					Reuse     => 1)
	    or die "$0: Error, socket: $!\n port=$self->{port}=";
	$self->{unix_socket_created}=1;
    } else {
	die "IPC::Locker::Server:  What transport do you want to use?";
    }
    $Poll = IO::Poll->new();
    $Poll->mask($server => (POLLIN | POLLERR | POLLHUP | POLLNVAL));

    $Exister = IPC::PidStat->new();
    my $exister_fh = $Exister->fh;  # Avoid method calls, to accelerate things
    $Poll->mask($exister_fh => (POLLIN | POLLERR | POLLHUP | POLLNVAL));

    %Clients = ();
    #$SIG{ALRM} = \&sig_alarm;
    $SIG{INT}= \&sig_INT;
    $SIG{HUP}= \&sig_INT;

    $! = 0;
    while (!$Interrupts) {
	_timelog("Pre-poll $!\n") if $Debug;
	#use Data::Dumper; Carp::cluck(Dumper(\%Clients, \%Locks));
	$! = 0;
	my (@r, @w, @e);

	my $timeout = ((scalar keys %Locks) ? $PollDelta : 2000);
	my $npolled = $Poll->poll($timeout);
	if ($npolled>0) {
	    @r = $Poll->handles(POLLIN);
	    @e = $Poll->handles(POLLERR | POLLHUP | POLLNVAL);
	    #@w = $Poll->handles(POLLOUT);
	}
	_timelog("Poll $npolled Locks=",(scalar keys %Locks),": $#r $#w $#e $!\n") if $Debug;
        foreach my $fh (@r) {
            if ($fh == $server) {
		# Create a new socket
		my $clientfh = $server->accept;
		$Poll->mask($clientfh => (POLLIN | POLLERR | POLLHUP | POLLNVAL));
		#
		my $clientvar = {socket=>$clientfh,
				 input=>'',
				 inputlines=>[],
			     };
		$clientvar->{client_num} = $_Client_Num++ if $Debug;
		$Clients{$clientfh}=$clientvar;
		client_send($clientvar,"HELLO\n") if $Debug;
	    } elsif ($fh == $exister_fh) {
		exist_traffic();
	    } else {
		my $data = '';
		# For debug, change the 1000 to 1 below
		my $rc = recv($fh, $data, 1000, 0);
		if ($data eq '') {
		    # we have finished with the socket
		    delete $Clients{$fh};
		    $Poll->remove($fh);
		    $fh->close;
		} else {
		    my $line = $Clients{$fh}->{input}.$data;
		    my @lines = split /\n/, $line;
		    if ($line =~ /\n$/) {
			$Clients{$fh}->{input}='';
			_timelog("Nothing Left\n") if $Debug;
		    } else {
			$Clients{$fh}->{input}=pop @lines;
			_timelog("Left: ".$Clients{$fh}->{input}."\n") if $Debug;
		    }
		    client_service($Clients{$fh}, \@lines);
		}
	    }
	}
	foreach my $fh (@e) {
	    # we have finished with the socket
	    delete $Clients{$fh};
	    $Poll->remove($fh);
	    $fh->close;
        }
	$self->recheck_locks();
    }
    _timelog("Loop end\n") if $Debug;
}

######################################################################
######################################################################
#### Client servicing

sub client_service {
    my $clientvar = shift || die;
    my $linesref = shift;
    # Loop getting commands from a specific client
    _timelog("c$clientvar->{client_num}: REQS $clientvar->{socket}\n") if $Debug;

    if (defined $clientvar->{inputlines}[0]) {
	_timelog("c$clientvar->{client_num}: handling pre-saved lines\n") if $Debug;
	$linesref = [@{$clientvar->{inputlines}}, @{$linesref}];
	$clientvar->{inputlines} = [];  # Zap, in case we get called recursively
    }

    # We may return before processing all lines, thus the lines are
    # stored in the client variables
    while (defined (my $line = shift @{$linesref})) {
	_timelog("c$clientvar->{client_num}: REQ $line\n") if $Debug;
	my ($cmd,@param) = split /\s+/, $line;  # We rely on the newline to terminate the split
	if ($cmd) {
	    # Variables
	    if ($cmd eq 'user') {		$clientvar->{user} = $param[0]; }
	    elsif ($cmd eq 'locks') {		$clientvar->{locks} = [@param]; }
	    elsif ($cmd eq 'block') {		$clientvar->{block} = $param[0]; }
	    elsif ($cmd eq 'timeout') {		$clientvar->{timeout} = $param[0]; }
	    elsif ($cmd eq 'autounlock') {	$clientvar->{autounlock} = $param[0]; }
	    elsif ($cmd eq 'hostname') {	$clientvar->{hostname} = $param[0]; }
	    elsif ($cmd eq 'pid') {		$clientvar->{pid} = $param[0]; }

	    # Frequent Commands
	    elsif ($cmd eq 'UNLOCK') {
		client_unlock ($clientvar);
	    }
	    elsif ($cmd eq 'LOCK') {
		my $wait = client_lock ($clientvar);
		_timelog("c$clientvar->{client_num}: Wait= $wait\n") if $Debug;
		last if $wait;
	    }
	    elsif ($cmd eq 'EOF') {
		client_close ($clientvar);
		undef $clientvar;
		last;
	    }

	    # Infrequent commands
	    elsif ($cmd eq 'STATUS') {
		client_status ($clientvar);
	    }
	    elsif ($cmd eq 'BREAK_LOCK') {
		client_break  ($clientvar);
	    }
	    elsif ($cmd eq 'DEAD_PID') {
		dead_pid($param[0],$param[1]);
	    }
	    elsif ($cmd eq 'LOCK_LIST') {
		client_lock_list ($clientvar);
	    }
	    elsif ($cmd eq 'VERSION') {
		client_send ($clientvar, "version $VERSION $StartTime\n\n");
	    }
	    elsif ($cmd eq 'RESTART') {
		die "restart";
	    }
	}
	# Commands
    }

    # Save any non-processed lines (from 'last') for next time
    $clientvar->{inputlines} = $linesref;
}

sub client_close {
    my $clientvar = shift || die;
    if ($clientvar->{socket}) {
	delete $Clients{$clientvar->{socket}};
	$Poll->remove($clientvar->{socket});
	$clientvar->{socket}->close();
    }
    $clientvar->{socket} = undef;
}

sub client_status {
    # Send status of lock back to client
    # Return 1 if success (client didn't hangup)
    my $clientvar = shift || die;
    $clientvar->{locked} = 0;
    $clientvar->{owner} = "";
    my $send = "";
    foreach my $lockname (@{$clientvar->{locks}}) {
	if (my $locki = locki_find ($lockname)) {
	    if ($locki->{owner} eq $clientvar->{user}) {  # (Re) got lock
		$clientvar->{locked} = 1;
		$clientvar->{locks} = [$locki->{lock}];
		$clientvar->{owner} = $locki->{owner};  # == Ourself
		if ($clientvar->{told_locked}) {
		    $clientvar->{told_locked} = 0;
		    $send .= "print_obtained\n";
		}
		last;
	    } else {
		# Indicate first owner, for client "waiting" message 
		$clientvar->{owner} = $locki->{owner} if !$clientvar->{owner};
	    }
	}
    }

    $send .= "owner $clientvar->{owner}\n";
    $send .= "locked $clientvar->{locked}\n";
    $send .= "lockname $clientvar->{locks}[0]\n" if $clientvar->{locked};
    $send .= "error $clientvar->{error}\n" if $clientvar->{error};
    $send .= "\n\n";  # End of group.  Some day we may not always send EOF immediately
    return client_send ($clientvar, $send);
}

sub client_lock_list {
    my $clientvar = shift || die;
    _timelog("c$clientvar->{client_num}: Locklist!\n") if $Debug;
    while (my ($lockname, $lock) = each %Locks) {
	if (!$lock->{locked}) {
	    _timelog("c$clientvar->{client_num}: Note unlocked lock $lockname\n") if $Debug;
	    next;
	}
	client_send ($clientvar, "lock $lockname $lock->{owner}\n");
    }
    return client_send ($clientvar, "\n\n");
}

sub client_lock {
    # Client wants this lock, return true if delayed transaction
    my $clientvar = shift || die;

    # Fast case, see if there are any non-allocated locks
    foreach my $lockname (@{$clientvar->{locks}}) {
	_timelog("c$clientvar->{client_num}: check $lockname\n") if $Debug;
	my $locki = locki_find ($lockname);
	if ($locki && $locki->{owner} ne $clientvar->{user}) {
	    # See if the user's machine can clear it
	    if ($locki->{autounlock} && $clientvar->{autounlock}) {
		# The 2 is for supports DEAD_PID added in version 1.480
		# Older clients will ignore it.
		client_send ($clientvar, "autounlock_check $locki->{lock} $locki->{hostname} $locki->{pid} 2\n");
	    }
	    # Try to have timer/exister clear up existing lock
	    locki_recheck($locki,undef); # locki maybe deleted
	} else {
	    if (!$clientvar->{locked}) {  # Unlikely - some async path established the lock
		# Know there's a free lock; for speed, munge request to point to only it
		$clientvar->{locks} = [$lockname];
		last;
	    }
	}
    }

    # Create lock requests
    my $first_locki = undef;
    foreach my $lockname (@{$clientvar->{locks}}) {
	_timelog("c$clientvar->{client_num}: new $lockname\n") if $Debug;
	# Create new request.  If it can be serviced, this will
	# establish the lock and send status back.
	my $locki = locki_new_request($lockname, $clientvar);
	$first_locki ||= $locki;
	# Done if found free lock
	last if $clientvar->{locked};
    }

    # All locks busy?
    if ($clientvar->{locked}) {
	# Done, and we already sent client_status when the lock was made
	return 0;
    } elsif (!$clientvar->{block}) {
	# All busy, and user wants non-blocking, just send status
	client_status($clientvar);
	return 0;
    } else {
	# All busy, we need to block the user's request and tell the user
	if (!$clientvar->{told_locked} && $first_locki) {
	    $clientvar->{told_locked} = 1;
	    client_send ($clientvar, "print_waiting $first_locki->{owner}\n");
	}
	# Either need to wait for timeout, or someone else to return key
	return 1;	# Exit loop and check if can lock later
    }
}

sub client_break {
    my $clientvar = shift || die;
    # The locki may be deleted by this call
    foreach my $lockname (@{$clientvar->{locks}}) {
	if (my $locki = locki_find ($lockname)) {
	    if ($locki->{locked}) {
		_timelog("c$clientvar->{client_num}: broke lock   $locki->{locks} User $clientvar->{user}\n") if $Debug;
		client_send ($clientvar, "print_broke $locki->{owner}\n");
		locki_unlock ($locki);  # locki may be deleted
	    }
	}
    }
    client_status ($clientvar);
}

sub client_unlock {
    my $clientvar = shift || die;
    # Client request to unlock the given lock
    # The locki may be deleted by this call
    $clientvar->{locked} = 0;
    foreach my $lockname (@{$clientvar->{locks}}) {
	if (my $locki = locki_find ($lockname)) {
	    if ($locki->{owner} eq $clientvar->{user}) {
		_timelog("c$clientvar->{client_num}: Unlocked   $locki->{lock} User $clientvar->{user}\n") if $Debug;
		locki_unlock ($locki); # locki may be deleted
	    } else {
		# Doesn't hold lock but might be waiting for it.
		_timelog("c$clientvar->{client_num}: Waiter count: ".$#{$locki->{waiters}}."\n") if $Debug;
		for (my $n=0; $n <= $#{$locki->{waiters}}; $n++) {
		    if ($locki->{waiters}[$n]{user} eq $clientvar->{user}) {
			_timelog("c$clientvar->{client_num}: Dewait     $locki->{lock} User $clientvar->{user}\n") if $Debug;
			splice @{$locki->{waiters}}, $n, 1;
		    }
		}
	    }
	}
    }
    client_status ($clientvar);
}

sub client_send {
    # Send a string to the client, return 1 if success
    my $clientvar = shift || die;
    my $msg = shift;

    my $clientfh = $clientvar->{socket};
    return 0 if (!$clientfh);
    _timelog_split("c$clientvar->{client_num}: RESP $clientfh",
		   (' 'x24)."c$clientvar->{client_num}: RES  ", $msg) if $Debug;

    $SIG{PIPE} = 'IGNORE';
    my $status = eval { local $^W=0; send $clientfh,$msg,0; };  # Disable warnings
    if (!$status) {
	warn "client_send hangup $? $! ".($status||"")." $clientfh " if $Debug;
	client_close ($clientvar);
	return 0;
    }
    return 1;
}

######################################################################
######################################################################
#### Alarm handler

sub sig_INT {
    $Interrupts++;
    #$SIG{INT}= \&sig_INT;
    0;
}

sub alarm_time {
    # Compute alarm interval and set
    die "Dead code\n";
    my $time = fractime();
    my $timelimit = undef;
    foreach my $locki (values %Locks) {
	if ($locki->{locked} && $locki->{timelimit}) {
	    $timelimit = $locki->{timelimit} if
		(!defined $timelimit
		 || $locki->{timelimit} <= $timelimit);
	}
    }
    return $timelimit ? ($timelimit - $time + 1) : 0;
}

sub fractime {
    my ($time, $time_usec) = Time::HiRes::gettimeofday();
    return $time + $time_usec * 1e-6;
}

######################################################################
######################################################################
#### Exist traffic

sub exist_traffic {
    # Handle UDP responses from our $Exister->pid_request calls.
    _timelog("UDP PidStat in...\n") if $Debug;
    my ($pid,$exists,$onhost) = $Exister->recv_stat();
    if (defined $pid && defined $exists && !$exists) {
	# We only care about known-missing processes
	_timelog("   UDP PidStat PID $pid no longer with us.  RIP.\n") if $Debug;
	dead_pid($onhost,$pid);
    }
}

sub dead_pid {
    my $host = shift;
    my $pid = shift;
    # We don't maintain a table sorted by pid, as these messages
    # are rare, and there can be many locks per pid.
    foreach my $locki (values %Locks) {
	if ($locki->{locked} && $locki->{autounlock}
	    && $locki->{hostname} eq $host
	    && $locki->{pid} == $pid) {
	    _timelog("\tUDP RIP Unlock\n") if $Debug;
	    locki_unlock($locki); # break the lock, locki may be deleted
	}
    }
    _timelog("   UDP RIP done\n\n") if $Debug;
}

######################################################################
######################################################################
#### Internals

sub locki_action {
    # Give lock to next requestor that accepts it
    my $locki = shift || die;

    _timelog("$locki->{lock}: Locki_action:Waiter count: ".$#{$locki->{waiters}}."\n") if $Debug;
    if (!$locki->{locked} && defined $locki->{waiters}[0]) {
	my $clientvar = shift @{$locki->{waiters}};
	# Give it to a client.  If it fails, it will call locki_unlock then locki_action again
	# so we just return after this.
	locki_lock_to_client($locki,$clientvar);
	return;
    }
    elsif (!$locki->{locked} && !defined $locki->{waiters}[0]) {
	locki_delete ($locki);  # locki invalid
    }
}

sub locki_lock_to_client {
    my $locki = shift;
    my $clientvar = shift;

    _timelog("$locki->{lock}: Issuing to $clientvar->{user}\n") if $Debug;
    $locki->{locked} = 1;
    $locki->{owner} = $clientvar->{user};
    if ($clientvar->{timeout}) {
	$locki->{timelimit} = $clientvar->{timeout} + fractime();
    } else {
	$locki->{timelimit} = 0;
    }
    $locki->{autounlock} = $clientvar->{autounlock};
    $locki->{hostname} = $clientvar->{hostname};
    $locki->{pid} = $clientvar->{pid};

    if ($clientvar->{locked} && $clientvar->{locks}[0] ne $locki->{lock}) {
	# Client gave a choice of locks, and another one got to
	# satisify it first
	_timelog("$locki->{lock}: Already has different lock\n") if $Debug;
	return locki_unlock ($locki); # locki_unlock may recurse to call locki_lock
    }
    else {
	# This is the only call to a client_ routine not in the direct
	# client call stack.  Thus we may need to process more commands
	# after this call
	if (client_status ($clientvar)) {   # sets clientvar->{locked}
	    # Worked ok
	    client_service($clientvar, []);  # If any queued, handle more commands/ EOF
	    return; # Don't look for another lock waiter
	}
	# Else hung up, didn't get the lock, give to next guy
	_timelog("$locki->{lock}: Owner hangup $locki->{owner}\n") if $Debug;
	return locki_unlock ($locki); # locki_unlock may recurse to call locki_lock
    }
    die "%Error: Can't get here - instead we recurse thru unlock\n";
}

sub locki_unlock {
    my $locki = shift || die;
    # Unlock this lock
    # The locki may be deleted by this call
    $locki->{locked} = 0;
    $locki->{owner} = "unlocked";
    $locki->{autounlock} = 0;
    $locki->{hostname} = "";
    $locki->{pid} = 0;
    # Give it to someone else?
    # Note the new lock request client may not still be around, if so we
    # recurse back to this function with waiters one element shorter.
    locki_action ($locki);
}

sub locki_delete {
    my $locki = shift;
    # The locki may be deleted by this call
    _timelog("$locki->{lock}: locki_delete\n") if $Debug;
    delete $Locks{$locki->{lock}};
}

sub recheck_locks {
    my $self = shift;
    # Main loop to see if any locks have changed state
    my $time = fractime();
    if (($self->{_recheck_locks_time}||0) < $time) {
	$self->{_recheck_locks_time} = $time + $RecheckLockDelta;
	foreach my $locki (values %Locks) {
	    locki_recheck($locki,$time); # locki may be deleted
	}
    }
}

sub locki_recheck {
    my $locki = shift;
    my $time = shift || fractime();
    # See if any locks need to change state due to pid disappearance or timeout
    # The locki may be deleted by this call
    if ($locki->{locked}) {
	if ($locki->{timelimit} && ($locki->{timelimit} <= $time)) {
	    _timelog("$locki->{lock}: Timeout of $locki->{owner}\n") if $Debug;
	    locki_unlock ($locki); # locki may be deleted
	}
	elsif ($locki->{autounlock}) {   # locker said it was OK to break lock if he dies
	    if (($locki->{autounlock_check_time}||0) < $time) {
		# If there's 1000 locks, we don't want to check them all
		# in one second, so scale back appropriately.
		my $chkdelta = ($AutoUnlockCheckDelta
				+ ((scalar keys %Locks)/$AutoUnlockCheckPerSec));
		$locki->{autounlock_check_time} = $time + $chkdelta;
		# Only check every 2 secs or so, else we can spend more time
		# doing the OS calls than it's worth
		my $dead = undef;
		if ($locki->{hostname} eq $Hostname) {	# lock owner is running on same host
		    $dead = IPC::PidStat::local_pid_doesnt_exist($locki->{pid});
		    if ($dead) {
			_timelog("$locki->{lock}: Autounlock of $locki->{owner}\n") if $Debug;
			locki_unlock($locki); # break the lock, locki may be deleted
		    }
		}
		if (!defined $dead) {
		    # Ask the other host if the PID is gone
		    # Or, we had a permission problem so ask root.
		    _timelog("$locki->{lock}: UDP pid_request $locki->{hostname} $locki->{pid}\n") if $Debug;
		    $Exister->pid_request(host=>$locki->{hostname}, pid=>$locki->{pid},
					  return_exist=>0, return_doesnt=>1, return_unknown=>1);
		    # This may (or may not) return a UDP message with the status in it.
		    # If so, they will call exist_traffic.
		}
	    }
	}
    }
}

sub locki_new_request {
    my $lockname = shift || "lock";
    my $clientvar = shift;
    my $locki;
    if ($locki=locki_find($lockname)) {
	# Same existing owner wants to grab it under a new connection
	if ($locki->{locked} && ($locki->{owner} eq $clientvar->{user})) {
	    _timelog("c$clientvar->{client_num}: Renewing connection\n") if $Debug;
	    locki_lock_to_client($locki,$clientvar);
	} else {
	    # Search waiters to see if already on list
	    my $found;
	    for (my $n=0; $n <= $#{$locki->{waiters}}; $n++) {
		# Note the old client value != new client value, although the user is the same
		if ($locki->{waiters}[$n]{user} eq $clientvar->{user}) {
		    _timelog("c$clientvar->{client_num}: Renewing wait list\n") if $Debug;
		    $locki->{waiters}[$n] = $clientvar;
		    $found = 1;
		    last;
		}
	    }
	    if (!$found) {
		_timelog("c$clientvar->{client_num}: New waiter\n") if $Debug;
		push @{$locki->{waiters}}, $clientvar;
	    }
	    # Either way, we don't have the lock, so just hang out
	}
    } else { # new
	$locki = {
	    lock=>$lockname,
	    locked=>0,
	    owner=>"unlocked",
	    waiters=>[$clientvar],
	};
	$Locks{$lockname} = $locki;
	_timelog("$locki->{lock}: New\n") if $Debug;
	# Process it, which will establish the lock for this client
	locki_action($locki);
    }
    return $locki;
}

sub locki_find {
    return $Locks{$_[0] || "lock"};
}

sub DESTROY {
    my $self = shift;
    _timelog("DESTROY\n") if $Debug;
    if (($self->{family} eq 'UNIX') && $self->{unix_socket_created}){
	unlink $self->{port};
    }
}

######################################################################
#### Logging

sub _timelog {
    IPC::Locker::_timelog(@_);
}
sub _timelog_split {
    IPC::Locker::_timelog_split(@_);
}

######################################################################
#### Package return
1;
