#
#  Copyright (c) 2004 catpipe Systems ApS
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.
#

# $Id: Events.pm,v 1.32 2007/03/28 08:01:59 dk Exp $
use strict;

package IO::Events;
use vars qw($VERSION $FORK_MODE @loops);
$VERSION=0.6;

# Master loop object
package IO::Events::Loop;
use vars qw(@ISA);

use IO::Handle;
use Errno qw(EAGAIN);
use POSIX qw(sys_wait_h exit);
use Time::HiRes qw(time);

sub new
{
	my $class = shift;
	my $obj = bless {
		# options
		debug     => 0,
		timeout   => 50, # seconds
		waitpid   => 1,
		@_,

		# private fields
		read      => '',
		write     => '',
		exc       => '',
		processes => {},
		filenos   => {},
		ids       => {},
		timers    => [],
	}, $class;
	push @IO::Events::loops, $obj;
	return $obj;
}

sub yield
{
	my ( $self, %profile) = @_;

	my ( $ir, $iw, $ie) = ( 
		$self->{read}, 
		$profile{block_write} ? '' : $self-> {write}, 
		$profile{block_exc} ? '' : $self-> {exc}
	);

	my $timeout = exists $profile{timeout} ? $profile{timeout} : $self->{timeout};
	if ( @{$self->{timers}}) {
		my $time = time;
		for my $timer (@{$self->{timers}}) {
			next unless $timer->{active};
			my $sleep = $timer->{alert} - $time;
			$timeout = $sleep if $timeout > $sleep;
		}
		$timeout = 0 if $timeout < 0;
	}
	my $n = select( $ir, $iw, $ie, $timeout);

	if ( @{$self->{timers}}) {
		my $time = time;
		for my $timer (@{$self->{timers}}) {
			next if not $timer->{active} or $time < $timer->{alert};
			$timer-> notify;
		}
	}
	
	unless ( $n > 0) {
		if ( $self->{debug}) {
			print STDERR "IO::Events: empty select";
			if ( $n < 0) {
				print STDERR " error:$!";
			}
			print STDERR "\n";
		}
		goto WAITPID;
	}

	my $i;
	my $lnx = (sort { $a <=> $b } map { length } ( $ir, $iw, $ie))[-1] * 8;
	for ( $i = 0; $i < $lnx; $i++) {
		my ( $r, $w, $e) = ( vec( $ir, $i, 1), vec( $iw, $i, 1), vec( $ie, $i, 1));
		next unless $r || $w || $e;
		my $task;
		if ( exists $self-> {filenos}-> {$i} && 
			exists $self->{ids}->{$self-> {filenos}-> {$i}}) {
			$task = $self->{ids}->{$self-> {filenos}-> {$i}};
		} else {
			print STDERR "IO::Events: runaway handle $i/$self->{filenos}->{$i}\n" 
				if $self->{debug};
			$self-> error( undef, 'select');
			next;
		}
		if ( $task-> {callback} and not $task-> {dead} ) {
			$task-> {callback}-> ( $task, $r, $w, $e);
		}

		if ( $r and not $task-> {dead}) {
			my $nbytes;
			if ( $task-> {read} > -1) {
				$nbytes = sysread( $task->{handle}, $task->{read_buffer}, 
					$profile{block_read} ? 0 : 65536, length ($task->{read_buffer}));
			}
			if ( $task->{read} > 0) {
				print STDERR "IO::Events: # $i read $nbytes bytes\n" 
					if $self->{debug};
				unless ( defined $nbytes) {
					$self-> error( $task, 'read') unless $! == EAGAIN;
					next;
				}
			} else {
				$nbytes = 1 unless defined $nbytes; # simulate read
				print STDERR "IO::Events: # $i simulated read $nbytes\n" 
					if $self->{debug};
			}
			next if $profile{block_read};
			if ( $nbytes > 0) {
				$task-> notify('on_read');
				next;
			}
			$task-> destroy unless $task-> {pid};
		} 

		if ( $w and not $task-> {dead}) {
			unless ( length $task->{write_buffer}) {
				vec( $self->{write}, $task-> {fileno}, 1) = 0;
				$task-> notify('on_write');
				next;
			}
			my $nbytes = syswrite( $task->{handle}, $task->{write_buffer});
			print STDERR "IO::Events: # $i wrote $nbytes bytes\n" 
				if $self->{debug};
			unless ( defined $nbytes) {
				$self-> error( $task, 'write') unless $! == EAGAIN;
				next;
			}
			if ( $nbytes > 0) {
				substr( $task->{write_buffer}, 0, $nbytes) = '';
				unless ( length $task->{write_buffer}) {
					vec( $self->{write}, $task-> {fileno}, 1) = 0;
					$task-> notify('on_write');
				}
				next;
			}
		}
		
		if ( $e and not $task-> {dead}) {
			print STDERR "IO::Events: exception $i\n" if $self->{debug};
			$task-> notify('on_exception');
		} 
	}

	# close processes
WAITPID:   
	if ( $self-> {waitpid}) {
		while (($_ = waitpid(-1,WNOHANG)) > 0) {
			next unless $self->{processes}->{$_};
			my @tasks = map { $self-> {ids}-> {$_}} @{$self->{processes}-> {$_}};
			# read leftovers
			for my $task ( @tasks) {
				if ( $task-> can_read && $task-> {read} > 0) {
					my $notify;
					while ( 1) {
						my $nbytes = sysread( $task->{handle}, 
							$task->{read_buffer}, 65536, 
							length ($task->{read_buffer}));
						unless ( defined $nbytes) {
							$self-> error( $task, 'read') 
								unless $! == EAGAIN;
							last;
						}
						$notify += $nbytes;
						last unless $nbytes;
					}
					$task-> notify('on_read') if $notify;
				}
				# XXX if $task-> can_exception ... read URG bytes?
				$task->{exitcode} = $?;
				$task->{finished} = 1;
			}
			for my $task ( @tasks) {
				$task-> destroy;
			}
		}
	}

	return $n;
}

sub handles
{
	return scalar(keys %{$_[0]->{ids}});
}

sub flush
{
	shift-> yield( block_read => 1, block_exc => 1, timeout => 0);
}

sub error 
{ 
	my ( $self, $task, $condition) = @_;
	$task-> notify('on_error', $condition, $!) if $task;
}

sub on_fork
{
	$IO::Events::FORK_MODE = 1;
	shift-> DESTROY;
	$IO::Events::FORK_MODE = undef;
}

sub DESTROY
{
	my $self = $_[0];
	return if $self->{dead};
	for ( values %{$self->{ids}}) {
		next unless $_;
		$_->{dead} = 1 if $IO::Events::FORK_MODE;
		$_-> destroy;
	}
	for ( @{$self->{timers}}) {
		next unless $_;
		$_->{dead} = 1;
	}
	@IO::Events::loops = grep { $self != $_ } @IO::Event::IPC::loops;
	$self-> {dead} = 1;
}

END
{
	for ( @IO::Events::loops) {
		eval { $_->DESTROY };
		warn "$@" if $@;
	}
	@IO::Events::loops = ();
}

# Single task
package IO::Events::Handle;
use vars qw(@ISA %events);

use Errno qw(EAGAIN);

use constant SINGLE   => 1;
use constant MULTIPLE => 2;

%events = (
	on_read      => SINGLE,
	on_write     => SINGLE,
	on_exception => SINGLE,
	on_close     => MULTIPLE,
	on_create    => MULTIPLE,
	on_error     => MULTIPLE,
);

use Fcntl;

sub new
{
	my $class = shift;
	my $self = bless {
		auto_close   => 1,
		finished     => 0,
		exitcode     => 0,
		read_buffer  => '',
		write_buffer => '',
		write        => 0,
		read         => 0,
		exception    => 0,
		pid          => undef,
		@_,
	}, $class;
	$self->{handle} = IO::Handle-> new() unless defined $self->{handle};
	for ( qw(owner)) {
		die "No `$_' field" unless defined $self-> {$_};
	}
	$self-> {id} = "$self" unless defined $self-> {id};
	my $owner = $self->{owner};
	die "Id `$self->{id}` already present" if exists $owner->{ids}->{$self->{id}};
	my $fno = fileno( $self->{handle});
	die "Cannot read fileno() from handle" unless defined $fno;
	$self-> {fileno} = $fno;
	unless ( $self-> {nonblock}) {
		my $fl;
		$fl = fcntl( $self->{handle}, F_GETFL, 0);
		die "$!" unless defined $fl;
		fcntl( $self->{handle}, F_SETFL, $fl|O_NONBLOCK) or die "$!";
	}
	if ($self-> {write}) {
		vec( $owner-> {write}, $fno, 1) = 1;
		#print "write\n";
	}
	if ($self-> {read}) {
		vec( $owner-> {read}, $fno, 1) = 1;
		#print "read\n";
	}
	if ($self-> {exception}) {
		vec( $owner-> {exc}, $fno, 1) = 1;
	}
	$owner-> {filenos}-> {$fno} = $self-> {id};
	push @{$owner-> {processes}-> {$self->{pid}}}, $self-> {id} if defined $self->{pid};
	$owner-> {ids}-> {$self->{id}} = $self;
	$self-> notify('on_create');
	return $self;
}

sub can_read
{
	return vec( $_[0]->{owner}->{read}, $_[0]-> {fileno}, 1) unless $#_;
	vec( $_[0]->{owner}->{read}, $_[0]-> {fileno}, 1) = $_[1];
	$_[0]-> {read} = $_[1];
}

sub can_write
{
	return vec( $_[0]->{owner}->{write}, $_[0]-> {fileno}, 1) unless $#_;
	vec( $_[0]->{owner}->{write}, $_[0]-> {fileno}, 1) = $_[1];
	$_[0]-> {write} = $_[1];
}

sub can_exception
{
	return vec( $_[0]->{owner}->{exc}, $_[0]-> {fileno}, 1) unless $#_;
	vec( $_[0]->{owner}->{exc}, $_[0]-> {fileno}, 1) = $_[1];
	$_[0]-> {exception} = $_[1];
}

sub DESTROY
{
	my $self = $_[0];
	return if $self->{dead};
	$self->{dead} = 1;
	$self-> flush;
	$self-> notify('on_close');
	$self-> {handle}-> close
		if defined $self->{handle} && $self->{auto_close};
	if ( defined $self->{owner}) {
		if ( defined $self->{fileno}) {
			vec( $self-> {owner}-> {exc},   $self->{fileno}, 1) = 0;
			vec( $self-> {owner}-> {write}, $self->{fileno}, 1) = 0;
			vec( $self-> {owner}-> {read}, $self->{fileno}, 1) = 0;
			delete $self-> {owner}-> {filenos}-> {$self->{fileno}};
		}
		if (defined $self->{pid}) {
			my $p = $self-> {owner}-> {processes}-> {$self->{pid}};
			@$p = grep { $_ ne $self->{id}} @$p;
			delete $self-> {owner}-> {processes}-> {$self->{pid}} unless @$p;
		}
		delete $self-> {owner}-> {ids}-> {$self->{id}};
	}
	delete $self->{fileno};
	delete $self->{id};
}

sub readline
{
	return $1 if $_[0]-> {read_buffer} =~ s/^([^\n]*\n)//;
	return undef;
}

sub read
{
	my $c = $_[0]-> {read_buffer};
	substr( $_[0]-> {read_buffer}, 0) = '';
	return $c;
}

sub write
{
	my ( $self, $data) = @_;
	$self-> {write_buffer} .= $data;
	vec( $self->{owner}->{write}, $self-> {fileno}, 1) = 1 if $self->{owner} and defined $self->{fileno};

	my $nbytes = syswrite( $self->{handle}, $self->{write_buffer});
	unless ( defined $nbytes) {
		$self-> {owner}-> error( $self, 'write') if $self->{owner} && $! != EAGAIN;
		$nbytes = 0 if $! == EAGAIN;
	} elsif ( $nbytes > 0) {
		substr( $self->{write_buffer}, 0, $nbytes) = '';
	}
	$nbytes;
}

sub flush
{
	my ( $self, $discard) = @_;
	if ( $discard) {
		$self-> {write_buffer} = '';
	} else {
		while ( length $self-> {write_buffer}) {
			return undef unless defined $self-> write('');
		}	 
	}
	return 1;
}

sub destroy { shift-> DESTROY }

sub notify
{
	my ( $self, $event, @params) = @_;
	die( "Unexistent event `$event'") unless $events{$event};
	
	$self-> {event_flag} = 0;
	if ( exists $self->{$event}) {
		$self->{$event}->($self,@params);
		return if $events{$event} == SINGLE || $self->{event_flag};
	}
	$self-> $event(@params) if $self-> can($event);
}

sub on_error
{
	my ( $self, $condition, $errno) = @_;
	if ( $self) {
		$condition .= ' '.ref($self);
		$condition .= ",#$self->{fileno}" if defined $self->{fileno};
		$condition .= " pid $self->{pid}" if defined $self->{pid};
		$condition .= " ($self->{process})" if defined $self->{process};
	}
	warn "Error on $condition: $errno\n";
	$_[0]-> destroy;
}


# external writer process
package IO::Events::Process::Write;
use vars qw(@ISA);
@ISA = qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	die "No `process'" unless defined $profile{process};
	my $handle = IO::Handle-> new();
	$handle-> autoflush(1);
	my $pid = open( $handle, "|$profile{process}");
	die("Cannot fork:$!") unless defined $pid;

	$self = $self-> SUPER::new( 
		write => 1, 
		%profile, 
		handle => $handle,
		pid    => $pid,
	);
	return $self;
}

# external reader process
package IO::Events::Process::Read;
use vars qw(@ISA);
@ISA = qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	die "No `process'" unless defined $profile{process};
	my $handle = IO::Handle-> new();
	$handle-> autoflush(1);
	my $pid = open( $handle, "$profile{process}|");
	die("Cannot fork:$!") unless defined $pid;

	$self = $self-> SUPER::new( 
		read => 1, 
		%profile, 
		handle => $handle,
		pid    => $pid,
	);
	return $self;
}

# internal reader process
package IO::Events::Fork::Read;
use vars qw(@ISA);
@ISA = qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	my $handle = IO::Handle-> new();
	$handle-> autoflush(1);
	my $pid = open( $handle, "-|");
	die("Cannot fork:$!") unless defined $pid;
	unless ( $pid) {
		# $profile{owner}->on_fork();
		$|=1;
		my $on_fork = $profile{on_fork} || $self->can('on_fork');
		$on_fork->(\%profile) if $on_fork;
		POSIX::_exit(0);
	}

	$self = $self-> SUPER::new( 
		read => 1, 
		%profile, 
		handle => $handle,
		pid    => $pid,
	);
	return $self;
}

# internal writer process
package IO::Events::Fork::Write;
use vars qw(@ISA);
@ISA = qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	my $handle = IO::Handle-> new();
	$handle-> autoflush(1);
	my $pid = open( $handle, "|-");
	die("Cannot fork:$!") unless defined $pid;
	unless ( $pid) {
		# $profile{owner}->on_fork();
		my $on_fork = $profile{on_fork} || $self->can('on_fork');
		$on_fork->(\%profile) if $on_fork;
		POSIX::_exit(0);
	}

	$self = $self-> SUPER::new( 
		write => 1, 
		%profile, 
		handle => $handle,
		pid    => $pid,
	);
	return $self;
}

package IO::Events::internal::Shadow;
use vars qw(@ISA);
@ISA = qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	$profile{shadow_task} = $profile{owner}->{ids}->{$profile{id}};
	$profile{id} = "shadow:$profile{id}";
	my $ret = $self-> SUPER::new(%profile);
	return $ret;
}

sub on_close
{
	undef $_[0]->{shadow_task}-> {shadow};
}

sub on_error
{
	my ( $self, $condition, $errno) = @_;
	$self-> {shadow_task}-> notify('on_error', $condition, $errno);
}


# internal bidirectional process
package IO::Events::Fork::ReadWrite;
use vars qw(@ISA);
@ISA = qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;

	# reader
	my $handle1 = IO::Handle-> new();
	$handle1-> autoflush(1);
		
	# writer
	my $handle2 = IO::Handle-> new();
	$handle2-> autoflush(1);

	# fork & pipes
	pipe(READER, $handle2);
	pipe($handle1, WRITER);
	WRITER->autoflush(1);
		
	my $pid = fork();
	die("Cannot fork:$!") unless defined $pid;
	
	unless ( $pid) {
		close $handle1;
		close $handle2;
		open STDOUT, ">&WRITER";
		open STDIN,  "<&READER";

		# $profile{owner}->on_fork();
		$|=1;
		my $on_fork = $profile{on_fork} || $self->can('on_fork');
		$on_fork->(\%profile) if $on_fork;
		POSIX::_exit(0);
	} 

	close WRITER;   
	close READER;   

	# create objects
	$self = $self-> SUPER::new( 
		read => 1, 
		%profile, 
		handle => $handle1,
		pid    => $pid,
	);

	$self-> {shadow} = IO::Events::internal::Shadow-> new( 
		write => 1, 
		%profile, 
		id     => $self-> {id},
		handle => $handle2,
		pid    => $pid,
		on_write => \&shadow_write,
		on_close => \&shadow_close,
	);

	return $self;
}

sub shadow_write
{
	shift-> {shadow_task}-> notify('on_write');
}

sub shadow_close
{
	my $shadow = shift;
	$shadow-> {shadow_task}->{finished} = $shadow-> {finished};
	$shadow-> {shadow_task}->{exitcode} = $shadow-> {exitcode};
	$shadow-> {shadow_task}-> notify('on_close', 1);
}

sub shutdown
{
	my ( $self, @cmd) = @_;
	for ( @cmd) {
		if ( $_ eq 'read') {
			$self-> SUPER::DESTROY;
		} elsif ( $_ eq 'write') {
			$self-> {shadow}-> DESTROY if $self-> {shadow};
		}
	}
}

sub DESTROY
{
	return if $_[0]->{dead};
	$_[0]->{shadow}->DESTROY if $_[0]->{shadow};
	$_[0]->SUPER::DESTROY;
	$_[0]->{dead} = 1;
}

sub write { 
	my $self = shift;
	return unless $self->{shadow};
	$self-> {shadow}-> write( @_) 
}

# external bidirectional process
package IO::Events::Process::ReadWrite;
use vars qw(@ISA);
@ISA = qw(IO::Events::Fork::ReadWrite);

sub on_fork
{
	exec( $_[0]->{process}) or POSIX::_exit(127);
}

package IO::Events::stdin;
use vars qw(@ISA);
@ISA=qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	$profile{id}     = "stdin";
	$profile{handle} = \*STDIN;
	$profile{read}   = 1;
	$profile{auto_close} = 0;
	return $self-> SUPER::new(%profile);
}

package IO::Events::stdout;
use vars qw(@ISA);
@ISA=qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	$profile{id}     = "stdout";
	$profile{handle} = \*STDOUT;
	$profile{write}  = 1;
	$profile{auto_close} = 0;
	return $self-> SUPER::new(%profile);
}

package IO::Events::stderr;
use vars qw(@ISA);
@ISA=qw(IO::Events::Handle);

sub new
{
	my ( $self, %profile) = @_;
	$profile{id}     = "stderr";
	$profile{handle} = \*STDERR;
	$profile{write}  = 1;
	$profile{auto_close} = 0;
	return $self-> SUPER::new(%profile);
}

package IO::Events::Socket;
use vars qw(@ISA);
@ISA=qw(IO::Events::Handle);

use Socket;

sub accept
{
	my ( $self, %profile) = @_;
	my $handle = IO::Handle-> new;
	accept( $handle, $self-> {handle}) or die "accept() error:$!";
	return IO::Events::Handle-> new(
		owner  => $self-> {owner},
		handle => $handle,
		%profile,
	);
}

sub connect
{
	$_[0]-> {callback} = \&socket_connect_error_checker;
}

sub socket_connect_error_checker
{
	my ( $self, $r, $w, $e) = @_;
	delete $self-> {callback};

	local $! = unpack('i', getsockopt($self-> {handle}, SOL_SOCKET, SO_ERROR)); 
	if ( $!) {
		$self-> {owner}-> error( $self, 'connect') if $self->{owner};
	}
}

package IO::Events::Socket::TCP;
use vars qw(@ISA);
@ISA=qw(IO::Events::Socket);

use strict;
use Socket;
use Fcntl;
use Errno qw(EWOULDBLOCK EINPROGRESS);

sub new
{
	my ( $self, %profile) = @_;

	$profile{handle} = IO::Handle-> new unless $profile{handle};
	die "Cannot create socket: $!" unless 
		socket( $profile{handle}, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

	unless ( $profile{nonblock}) {
		my $fl;
		$fl = fcntl( $profile{handle}, F_GETFL, 0);
		die "$!" unless defined $fl;
		fcntl( $profile{handle}, F_SETFL, $fl|O_NONBLOCK) or die "$!";
	}

	if ( defined $profile{connect}) {
		my $iaddr;
		die "Cannot resolve host '$profile{connect}'" unless
			$iaddr = inet_aton( $profile{connect});
		my $ok = connect( $profile{handle}, sockaddr_in( $profile{port}, $iaddr));
		$ok = 1 if !$ok and ( $! == EWOULDBLOCK || $! == EINPROGRESS);
		die "Connect error: $!" unless $ok;
	} elsif ( exists $profile{listen}) {
		setsockopt( $profile{handle}, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or 
			die "Error in setsockopt(SOL_SOCKET,SO_REUSEADDR,1):$!";
		my $addr = $profile{addr} || '0.0.0.0';
		my $inet = inet_aton( $addr);
		die "Cannot resolve host '$addr'" unless defined $inet;
		bind( $profile{handle}, sockaddr_in( $profile{port}, $inet)) or
			die "Error in bind($profile{port}, $addr):$!";
		listen( $profile{handle}, SOMAXCONN);
		$profile{read} = -1;
	}

	my $this = $self-> SUPER::new(%profile);
	$this-> SUPER::connect() if $profile{connect};
	return $this;
}

sub accept
{
	my ( $self, %profile) = @_;
	my $client = $self-> SUPER::accept( %profile);
	my ($port, $ipaddr) = unpack_sockaddr_in( getpeername( $client->{handle}));
	$client-> {remote_addr} = inet_ntoa($ipaddr);
	$client-> {remote_port} = $port;
	return $client;
}

package IO::Events::Socket::UDP;
use vars qw(@ISA);
@ISA=qw(IO::Events::Socket);

use strict;
use Socket;
use Fcntl;

sub new
{
	my ( $self, %profile) = @_;

	$profile{handle} = IO::Handle-> new unless $profile{handle};
	die "Cannot create socket: $!" unless 
		socket( $profile{handle}, PF_INET, SOCK_DGRAM, getprotobyname('udp'));

	unless ( $profile{nonblock}) {
		my $fl;
		$fl = fcntl( $profile{handle}, F_GETFL, 0);
		die "$!" unless defined $fl;
		fcntl( $profile{handle}, F_SETFL, $fl|O_NONBLOCK) or die "$!";
	}
		
	my $addr = $profile{addr} || '0.0.0.0';
	my $inet = inet_aton( $addr);
	die "Cannot resolve host '$addr'" unless defined $inet;
		
	if ( $profile{broadcast}) {
		setsockopt( $profile{handle}, SOL_SOCKET, SO_BROADCAST, pack("l", 1)) or 
			die "Error in setsockopt(SOL_SOCKET,SO_BROADCAST,1):$!";
	}
	$profile{read} = -2;
	
	bind( $profile{handle}, sockaddr_in( $profile{port} || 0, $inet)) or
		die "Error in bind($profile{port}, $addr):$!";

	return $self-> SUPER::new(%profile);
}

sub recv
{
	my ( $self, %profile) = @_;

	$profile{maxlen} = 32768 unless defined $profile{maxlen};

	my $flags = MSG_DONTWAIT;
	$flags |= MSG_OOB if $profile{oob};
	$flags |= MSG_PEEK if $profile{peek};
	$flags |= MSG_WAITALL if $profile{waitall};
	$flags &= ~MSG_DONTWAIT if defined($profile{nonblock}) and $profile{nonblock} == 0;
	
	my ( $port, $host);
	my $data = '';
	$host = recv( $self-> {handle}, $data, $profile{maxlen}, $flags);
	unless ( defined $host) {
		$self-> error( 'recv');
		return undef;
	}
	( $port, $host) = sockaddr_in( $host);
	$self-> {remote_port} = $port;
	$self-> {remote_host} = gethostbyaddr( $host, AF_INET);

	return $data;
}

sub send
{
	my ( $self, $addr, $port, $data, %profile) = @_;

	my $flags = 0;
	$flags |= MSG_OOB if $profile{oob};
	$flags |= MSG_DONTROUTE if $profile{dontroute};
	$flags |= MSG_EOR if $profile{eor};
	$flags |= MSG_EOF if $profile{eof};
	
	my $inet = inet_aton($addr) || die "unknown host '$addr'\n";
	$inet = sockaddr_in( $port, $inet);

	my $ret = send( $self-> {handle}, $data, $flags, $inet);
	unless ( defined $ret) {
		$self-> error( 'recv');
		return undef;
	}
	return $ret;
}

package IO::Events::Socket::UNIX;
use vars qw(@ISA);
@ISA=qw(IO::Events::Socket);

use Socket;
use Fcntl;

sub new
{
	my ( $self, %profile) = @_;

	$profile{handle} = IO::Handle-> new unless $profile{handle};
	die "Cannot create socket: $!" unless 
		socket( $profile{handle}, PF_UNIX, SOCK_STREAM, 0);

	unless ( $profile{nonblock}) {
		my $fl;
		$fl = fcntl( $profile{handle}, F_GETFL, 0);
		die "$!" unless defined $fl;
		fcntl( $profile{handle}, F_SETFL, $fl|O_NONBLOCK) or die "$!";
	}

	if ( defined $profile{connect}) {
		connect( $profile{handle}, pack_sockaddr_un($profile{connect})) or
			die "connect($profile{connect}) error: $!";
	} elsif ( exists $profile{listen}) {
		bind( $profile{handle}, pack_sockaddr_un($profile{listen})) or 
			die "Error in bind($profile{listen}):$!";
		listen( $profile{handle}, SOMAXCONN);
		$profile{read} = -1;
	}

	my $this = $self-> SUPER::new(%profile);
	$this-> SUPER::connect() if $profile{connect};
	return $this;
}

package IO::Events::Timer;
use Time::HiRes qw(time);

sub new
{
	my $class = shift;

	my $self = bless {
		timeout		=> 10000,
		repetitive	=> 0,
		active		=> 0,
		@_,
	}, $class;
	
	for ( qw(owner)) {
		die "No `$_' field" unless defined $self-> {$_};
	}

	push @{$self-> {owner}-> {timers}}, $self;

	$self-> start if $self-> {active};

	return $self;
}

sub DESTROY
{
	my $self = $_[0];
	return if $self-> {dead};
	@{$self-> {owner}-> {timers}} = grep { $_ != $self } @{$self-> {owner}-> {timers}};
}

sub start
{
	my $self = $_[0];
	$self-> {alert} = time + $self-> {timeout};
	$self-> {active} = 1;
}

sub stop { $_[0]-> {active} = 0 }

sub active 
{
	my ( $self, $active) = @_;
	return if $active == $self-> {active}; # to avoid restarts
	$active ? $self-> start : $self-> stop;
}

sub notify
{
	my $self = $_[0];

	if ( $self-> {repetitive}) {
		my $time = time;
		# eat up late events
		$self-> {alert} += $self-> {timeout} while $self-> {alert} < $time;
	} else {
		$self-> {active} = 0;
	}
	
	$self-> {event_flag} = 0;
	if ( defined $self->{on_tick}) {
		$self->{on_tick}->($self);
		return if $self->{event_flag};
	}
	$self-> on_tick() if $self-> can('on_tick');
}


1;

__DATA__

=pod

=head1 NAME

IO::Events - Non-blocking IO using events 

=head1 SYNOPSIS

Example 1, run 'bc' as a co-process:

	use IO::Events;

	my $loop = IO::Events::Loop-> new();

	my $stdin_alive = 1;
	my $calculator = IO::Events::Process::ReadWrite-> new(
		owner    => $loop,
		process  => 'bc -l', 
		on_read  => sub {
			while ( my $line = $_[0]-> readline) {
				print "bc says: $line";
			}
		},
		on_close => sub {
			exit 1 if $stdin_alive; # fork/exec error
		}
	);

	my $stdin = IO::Events::stdin-> new(
		owner => $loop,
		on_read => sub { 
		$calculator-> write( $_[0]-> read );
		},
		on_close => sub {
			$stdin_alive = 0;
			exit;
		},
	);

	$loop-> yield while 1;


Example 2, connect to/listen on a TCP port within a single process:

	use IO::Events;
	
	my $loop = IO::Events::Loop-> new();
	IO::Events::Socket::TCP-> new(
		owner    => $loop,
		listen   => 1,
		port     => 10000,
		on_read => sub {
			my $new = shift-> accept( 
				read   => 1,
				on_read => sub {
					while ( my $line = $_[0]-> readline) {
						print "client says: $line\n";
						exit;
					}
				}
			);
	                print "connect from $new->{remote_addr}:$new->{remote_port}\n";
		},
	);
	
	IO::Events::Socket::TCP-> new(
		owner   => $loop,
		connect => 'localhost',
		port 	=> 10000,
	)-> write("hello, tcp socket!\n");
	
	$loop->yield while 1;

Example 3, connect to/listen on a UDP port within a single process:

	use Socket;
	use IO::Events;
	
	my $loop = IO::Events::Loop-> new();
	IO::Events::Socket::UDP-> new(
		owner    => $loop,
		port     => 10000,
		on_read => sub {
			my $self = $_[0];
			my $data = $self-> recv;
			print "$self->{remote_host}:$self->{remote_port} says: $data";
			exit;
		},
	);
	
	IO::Events::Socket::UDP-> new(
		owner   => $loop,
	)-> send( 'localhost', 10000, "hello, udp socket!\n");
	
	$loop->yield while 1;

=head1 DESCRIPTION

The module implements object-oriented approach to select-driven events and
contains set of convenience objects for inter-process communication.

The main part of the module is the 'loop' instance of C<IO::Events::Loop> class,
which knows about all IO handles subject to select(). The handles are inherited
from C<IO::Events::Handle> class, which property C<handle> holds reference to a
IO handle object, - a file scalar or C<IO::Handle> instance.
C<IO::Events::Handle> object propagates select-based events - C<on_read>,
C<on_write>, C<on_exception>, as well as generic C<on_create>, C<on_close> and
C<on_error>. It is a requirement that handles are non-blocking.

All instances are created by calling C<new> with arbitrary number of named parameters.
The unrecognized parameters are stored in the object and cause no conflict:

	my $a = IO::Events::Handle-> new( my_var => 1 );
	die $a->{my_var};

The module is not meant to serve as replacement of C<IO::Select> and
C<IPC::Open>, and can perfectly live together with the first and counteract
with the handles managed by the second. The example in L<"SYNOPSIS"> section
displays how to harness the non-blocking IO between stdin and a co-process.

=head2 Advices

=over

=item *
Set C<$SIG{PIPE} = 'IGNORE'>, usually a sound idea.

=item *
Set C<$|=1> first in your script if you use ::Fork or ::Process
classes.

=item * 
If you use C<on_fork>, never terminate a child process by C<die> or C<exit>, because
otherwise everything Perl allocated in parent process will be de-allocated
twice, both in the parent and in the child process. If you must, use
C<POSIX::exit> instead.

=back

=head1 IO::Events::Loop

=head2 C<new()> parameters

=over

=item timeout INTEGER

Number of seconds passed to select() as the fourth parameter.

Default value: 50

=item waitpid BOOLEAN

In addition to C<select()>, C<IO::Events::Loop> also waits for
finished processes, automatically getting rid of handles associated with
them, if set to 1. 

Default value: 1

=back

=head2 Methods

=over

=item handles

Returns number of handles owner by loop object. When a program
automatically disposes of handles, not needed anymore, it may choose
to stop when there are no more handles to serve.

=item yield %HASH

Enters C<select()> loop and dispatches pending IO if data are available to read
or write. Hash values of C<'block_read'>, C<'block_write'>, and C<'block_exc'>
can be set to 1 if read, write, or exception events are not to be used.
Practically,

	$loop-> yield( block_read => 1, block_exc => 1, timeout => 0 )

call effectively ( but still in the non-blocking fashion ) flushes write buffers.

Returns result of select() call, the number of streams handled.

=item flush

Flushes write sockets, if possible.

=back

=head2 Fields

=over

=item %id

All handles are assigned an unique id, and are stored in
internal C<{id}> hash. This hash is read-only, and can be used
to look-up a handle object by its id string.

=item %filenos

Hash of file numbers, read-only.

=item %processes

Hash of PIDs associated with handles, read-only.
Used for IPC and C<waitpid> results processing.

=back

=head1 IO::Events::Handle

Root of IO handle object hierarchy, dispatches IO events and auto-destructs when 
handle is closed or an IO error occurs. The explicit destruction is invoked by 
calling C<destroy>, which is reentrant-safe.

=head2 Parameters to C<new()>

=over

=item auto_close BOOLEAN

If set to 1, IO handle is explicitly closed as the object instance is destroyed.
Doesn't affect anything otherwise.

Default value: 1

=item flush [ DISCARD = 0]

Flushes not yet written data. If DISCARD is 1, does not
return until all data are written or error is signalled. 
If 0, discards all data.

=item handle IOHANDLE

C<IO::Handle> object or a file scalar. If not specified,
a new C<IO::Handle> instance is created automatically.

The C<handle> is set to non-blocking mode. If this is already
done, C<nonblock> optional boolean parameter can be set to 1
to prevent extra C<fcntl> calls.

=item read BOOLEAN

Set to 1 if C<handle> is to be read from.

Default value: 0

=item shutdown @WHO

Defined in C<IO::Events::Fork::ReadWrite> and C<IO::Event::IPC::Process::ReadWrite>
namespaces. @WHO can contain string C<'read'> and C<'write'>, to tell what
part of bidirectional IPC is to be closed.

=item write BOOLEAN

Set to 1 if C<handle> is to be written from.

Default value: 0

=item pid INTEGER

If a handle is associated with a process, C<IO::Events::Loop> uses
this field to C<waitpid()> and auto-destruct the handle.

Default value: undef

=back

=head2 Methods

=over

=item can_read BOOLEAN

Selects whether the handle is readable.

=item can_write BOOLEAN

Selects whether the handle is writable.

=item can_exception BOOLEAN

Selects whether the handle accepts exception events.

=item readline

Returns newline-ended read data, if available.

=item read

Return contents of the read buffer.

=item write DATA

Appends DATA to the write buffer

=item destroy 

Destructs handle instance

=item notify $EVENT, @PARAMETERS

Dispatches EVENT, passing PARAMETERS to each callback.

=back

=head2 Events

A single event can cause several callback routines to be called. This is useful
when a class declares its own, for example, cleanup code in C<on_close> sub,
whereas the class instance user can add another listener to the same C<on_close>
notification:

	package MyHandle;
	...
	sub on_close { ... }
	...

	MyHandle-> new( on_close => sub { ... });

The class declares static ( per-class ) instance of hash C<%events>, which 
contains declaration of events and their execution flow. C<SINGLE>-declared
events call only single callback, be it static or dynamic. C<MULTIPLE>-declared
events call all callbacks, but execution flow can be stopped by setting
C<{event_flag}> to 1. This is useful, for example, to dynamically override
default behavior of C<IO::Events::Handle::on_error> which emits a warning message
to stderr and destroys the handle.

=over

=item on_close

Called before object instance is destroyed. 

In a special case for ReadWrite objects, C<on_close> is called twice,
when read and write handles are closed. To distinuish between the cases,
the second parameter is set to 1 when C<on_close> is called due to 
the writer handle destruction.

Declared as MULTIPLE.

=item on_create

Called after object instance is created.

Declared as MULTIPLE.

=item on_error

Called when read or write calls encounter error.

Declared as MULTIPLE.

=item on_exception

Called when exception is arrived. Consult your system C<select> manpage
to see what events and on what socket types can be expected.

=item on_fork

Special event, called by C<IO::Events::Fork> objects when 
a new process is instantiated. Although the syntax for specifying 
C<on_fork> is the same as for the other events, C<on_fork> does
not interact with these, and is not called from within C<yield>.

When C<on_fork> returned, process is terminated. If you wish to
terminate process yourself, do not call perl's C<exit> but rather
C<POSIX::_exit>, since otherwise perl stuctures created before fork
will be destroyed twice.

=item on_read

Called after data is read.

=item on_write

Called when handle is writable and the write buffer is empty. If the event
doesn't fill the write buffer, the handle C<write> flag is cleared and further
C<on_write> notifications are suppressed until the write buffer is filled.

=back

=head1 IO::Events::Process::Read

Runs a process with its stdout tied to a newly created handle.
The process name is passed to C<process> parameter to the C<new()> contructor.

=head1 IO::Events::Process::Write

Runs a process with its stdin tied to a newly created handle.
The process name is passed to C<process> parameter to the C<new()> contructor.

=head1 IO::Events::Process::ReadWrite

Runs a process with its stdin and stdout tied to two newly created handles.
The both handles are transparently mapped to a single handle object.

Note: check L<IPC::Open2> and L<IPC::Open3> also.

=head1 IO::Events::Fork::Read

Forks a child with its stdout tied to a newly created handle.

=head1 IO::Events::Fork::Write

Forks a child with its stdin tied to a newly created handle.

=head1 IO::Events::Fork::ReadWrite

Forks a child with its stdin and stdout tied to two newly created handles.
The both handles are transparently mapped to a single handle object.

=head1 IO::Events::stdin

Shortcut class for STDIN handle.

=head1 IO::Events::stdout

Shortcut class for STDOUT handle.

=head1 IO::Events::stderr

Shortcut class for STDERR handle.

=head1 IO::Events::Socket::TCP

Shortcut class for TCP socket. Parameters accepted:

=over

=item connect HOSTNAME

If set, C<connect()> call is issued on the socket to
HOSTNAME and port set in C<port>
parameter.

=item listen

If set, socket listens on C<port>.

=item port INTEGER

Number of a port to bind to.

=item addr STRING

If set, socket listens on C<addr> IP address, otherwise INADDR_ANY.

=item accept %PROFILE

Creates a new IO handle and accepts a connection into it.
Returns the newly created C<IO::Events::Handle> object 
with C<%PROFILE> fields.

=back

=head1 IO::Events::Socket::UDP

Shortcut class for UDP socket. Parameters accepted:

=over

=item port INTEGER

Number of a port to bind to.

=item addr STRING

If set, socket listens on C<addr> IP address, otherwise INADDR_ANY.

=item send HOSTNAME, PORT, DATA, %OPTIONS

Issues send(2) call, returns number of bytes sent or an error.
See L<perldoc/send> for more details.

Options accepted: C<oob>, C<dontroute>, C<eor>, C<eof>.

=item recv %OPTIONS

Issues recv(2) call, returns data block or under if error. 
See L<perldoc/recv> for more details.

Options accepted: C<oob>, C<peek>, C<waitall>, C<nonblock>, C<maxlen>.

=back

=head1 IO::Events::Socket::UNIX

A handle class, used to connect to and listen on UNIX sockets.

=over

=item accept %PROFILE

Creates a new IO handle and accepts a connection into it.
Returns the newly created C<IO::Events::Handle> object 
with C<%PROFILE> fields.

=item connect PATHNAME

Connects to a socket over a given PATHNAME

=item listen PATHNAME

Listens on a socket over a given PATHNAME

=back

=head1 IO::Events::Timer

A tiny hackish hask to add time-based events. The class is not inherited
from C<IO::Event::Handle>, and the only property it shared with the other
handle classes is C<owner>. 

=over

=item timeout SECONDS

Invokes C<on_tick> callback in SECONDS, which can be float.

=item active BOOLEAN

If on, timer is started immediately, otherwise is stopped.

=item repetitive BOOLEAN

If on, timer fires off event each SECONDS interval, otherwise goes off
after the first C<on_tick>.

=item start

Starts the timer

=item stop

Stops the timer

=item on_tick

Callback invoked each time SECONDS interval is expired.

=back

=head1 SEE ALSO

L<perlipc>, L<POE>, L<IO::Handle>, L<IO::Select>, L<IPC::Open2>.

=head1 COPYRIGHT

Copyright (c) 2004 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dmitry@karasik.eu.org>

=cut
