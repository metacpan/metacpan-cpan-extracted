# $Id: Signal.pm,v 1.24 2010/03/25 12:52:36 dk Exp $
package IO::Lambda::Signal;
use vars qw(@ISA %SIGDATA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(signal pid spawn new_signal new_pid new_process);
%EXPORT_TAGS = ( all => \@EXPORT_OK);

our $DEBUG = $IO::Lambda::DEBUG{signal} || 0;

use strict;
use Carp;
use IO::Handle;
use POSIX ":sys_wait_h";
use IO::Lambda qw(:all :dev);

my $MASTER = bless {}, __PACKAGE__;

# register yield handler
IO::Lambda::add_loop($MASTER);
END { IO::Lambda::remove_loop($MASTER) };

sub empty { 0 == keys %SIGDATA }

sub remove
{
	my $lambda = $_[1];
	my %rec;
	keys %SIGDATA;
	while ( my ($id, $v) = each %SIGDATA) {
		for my $r (@{$v-> {lambdas}}) {
			push @{$rec{$id}}, $r-> [0];
		}
	}
	while ( my ($id, $v) = each %rec) {
		unwatch_signal( $id, $_ ) for @$v;
	}
}

sub yield
{
	my %v = %SIGDATA;
	for my $id ( keys %v) {
		my $v = $v{$id};
		# use mutex in case signal happens right here during handling
		$v-> {mutex} = 0;
		warn "  yield sig $id\n" if $DEBUG > 1;
	AGAIN:  
		next unless $v-> {signal};

		my @r = @{$v-> {lambdas}};
		warn "  calling ", scalar(@r), " sig handlers\n" if $DEBUG > 1;
		for my $r ( @r) {
			my ( $lambda, $callback, @param) = @$r;
			$callback-> ( $lambda, @param);
		}

		my $sigs = $v-> {mutex};
		if ( $sigs) {
			warn "  caught $sigs signals during yield\n" if $DEBUG > 1;
			$v-> {signal} = $sigs;
			$v-> {mutex}  -= $sigs;
			goto AGAIN;
		}
	}
}

sub signal_handler
{
	my $id = shift;
	warn "SIG{$id}\n" if $DEBUG;
	return unless exists $SIGDATA{$id};
	$SIGDATA{$id}-> {signal}++;
	$SIGDATA{$id}-> {mutex}++;
	$IO::Lambda::LOOP-> signal($id) if $IO::Lambda::LOOP-> can('signal');
}

sub watch_signal
{
	my ($id, $lambda, $callback, @param) = @_;

	my $entry = [ $lambda, $callback, @param ];
	unless ( exists $SIGDATA{$id}) {
		$SIGDATA{$id} = {
			mutex   => 0,
			signal  => 0,
			save    => $SIG{$id},
			lambdas => [$entry],
		};
		$SIG{$id} = sub { signal_handler($id) };
		warn "install signal handler for $id ", _o($lambda), "\n" if $DEBUG > 1;
	} else {
		push @{ $SIGDATA{$id}-> {lambdas} }, $entry;
		warn "push signal handler for $id ", _o($lambda), "\n" if $DEBUG > 2;
	}
}

sub unwatch_signal
{
	my ( $id, $lambda) = @_;

	return unless exists $SIGDATA{$id};
		
	warn "remove signal handler for $id ", _o($lambda), "\n" if $DEBUG > 2;

	@{ $SIGDATA{$id}-> {lambdas} } = 
		grep { $$_[0] != $lambda } 
		@{ $SIGDATA{$id}-> {lambdas} };
	
	return if @{ $SIGDATA{$id}-> {lambdas} };
	
	warn "uninstall signal handler for $id\n" if $DEBUG > 1;

	if (defined($SIGDATA{$id}-> {save})) {
		$SIG{$id} = $SIGDATA{$id}-> {save};
	} else {
		delete $SIG{$id};
	}
	delete $SIGDATA{$id};
}

# create a lambda that either returns undef on timeout,
# or some custom value based on passed callback
sub signal_or_timeout_lambda
{
	my ( $id, $deadline, $condition) = @_;

	my $t;
	my $q = IO::Lambda-> new;

	# wait for signal
	my $c = $q-> bind;
	watch_signal( $id, $q, sub {
		my @ret = $condition-> ();
		return unless @ret;

		unwatch_signal( $id, $q);
		$q-> cancel_event($t) if $t;
		$q-> resolve($c);
		$q-> terminate(@ret); # result
		undef $c;
		undef $q;
	});

	# or wait for timeout
	$t = $q-> watch_timer( $deadline, sub {
		unwatch_signal( $id, $q);
		$q-> resolve($c);
		undef $c;
		undef $q;
		return undef; #result
	}) if $deadline;

	return $q;
}

sub new_process;
# condition
sub signal (&) { new_signal (context)-> condition(shift, \&signal, 'signal') }
sub pid    (&) { new_pid    (context)-> condition(shift, \&pid,    'pid') }
sub spawn  (&) { new_process-> call(context)-> condition(shift, \&spawn,  'spawn') }

sub new_signal
{
	my ( $id, $deadline) = @_;
	signal_or_timeout_lambda( $id, $deadline, 
		sub { 1 });
}

sub new_pid
{
	my ( $pid, $deadline) = @_;

	croak 'bad pid' unless $pid =~ /^\-?\d+$/;
	warn "new_pid($pid) ", _t($deadline), "\n" if $DEBUG;
	
	# avoid race conditions
	my ( $savesig, $early_sigchld);
	unless ( defined $SIGDATA{CHLD}) {
		warn "new_pid: install early SIGCHLD detector\n" if $DEBUG > 1;
		$savesig       = $SIG{CHLD};
		$early_sigchld = 0;
		$SIG{CHLD} = sub {
			warn "new_pid: early SIGCHLD caught\n" if $DEBUG > 1;
			$early_sigchld++
		};
	}

	# finished already
	if ( waitpid( $pid, WNOHANG) != 0) {
		if ( defined $early_sigchld) {
			if ( defined( $savesig)) {
				$SIG{CHLD} = $savesig;
			} else {
				delete $SIG{CHLD};
			}
		}
		warn "new_pid($pid): finished already with $?\n" if $DEBUG > 1;
		return IO::Lambda-> new-> call($?) 
	}

	# wait
	my $p = signal_or_timeout_lambda( 'CHLD', $deadline, sub {
		my $wp = waitpid($pid, WNOHANG);
		warn "waitpid($pid) = $wp\n" if $DEBUG > 1;
		return if $wp == 0;
		return $?;
	});

	warn "new_pid: new lambda(", _o($p), ")\n" if $DEBUG > 1;

	# don't let unwatch_signal() to restore it back to us
	$SIGDATA{CHLD}-> {save} = $savesig if defined $early_sigchld;

	# possibly have a race? gracefully remove the lambda
	if ( $early_sigchld) {

		# Got a signal, but that wasn't our pid. And neither it was
		# pid that we're watching.
		return $p if waitpid( $pid, WNOHANG) == 0;

		# Our pid is finished. Unwatch the signal.
		unwatch_signal( 'CHLD', $p);
		# Lambda will also never get executed - cancel it
		$p-> terminate;
		
		warn "new_pid($pid): finished with race: $?, ", _o($p), " killed\n" if $DEBUG > 1;
	
		return IO::Lambda-> new-> call($?); 
	}

	return $p;
}

sub new_process_posix
{
lambda {
	my $h   = IO::Handle-> new;
	my $pid = open( $h, '-|', @_);

	return undef, undef, $! unless $pid;

	this-> {pid} = $pid;
	$h-> blocking(0);

	my $buf;
	context readbuf, $h, \$buf, undef; # wait for EOF
tail {
	my ($res, $error) = @_;
	if ( defined $error) {
		close $h;
		return ($buf, $?, $error);
	}

	# finished already
	if (waitpid($pid, WNOHANG) != 0) {
		my ( $exitcode, $error) = ( $?, $! );
		close $h;
		return ($buf, $exitcode, $error);
	}
	# wait for it
	context $pid;
pid {
	close $h;
	return ($buf, shift);
}}}}

sub new_process_win32
{
	lambda {
		my @cmd = @_;
		context IO::Lambda::Thread::threaded( sub {
			my $k = `@cmd`;
			return $? ? ( undef, $?, $! ) : ( $k, 0, undef );
		});
		&tail();
	}
}


if ( $^O !~ /win32/i) {
	*new_process = \&new_process_posix;
} else {
	require IO::Lambda::Thread;
	unless ( $IO::Lambda::Thread::DISABLED) {
		*new_process = \&new_process_win32;
	} else {
		*new_process = sub { lambda { undef, undef, $IO::Lambda::Thread::DISABLED } };
	}
}


1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Signal - wait for pids and signals

=head1 DESCRIPTION

The module provides access to the signal-based callbacks: generic signal listener
C<signal>, process ID listener C<pid>, and the asynchronous version of I<system>
call, C<spawn>.

=head1 SYNOPSIS

   use strict;
   use IO::Lambda qw(:all);
   use IO::Lambda::Signal qw(pid spawn);

   # pid
   my $pid = fork;
   exec "/bin/ls" unless $pid;
   lambda {
       context $pid, 5;
       pid {
          my $ret = shift;
	  print defined($ret) ? ("exitcode(", $ret>>8, ")\n") : "timeout\n";
       }
   }-> wait;

   # spawn
   this lambda {
      context "perl -v";
      spawn {
      	  my ( $buf, $exitcode, $error) = @_;
   	  print "buf=[$buf], exitcode=$exitcode, error=$error\n";
      }
   }-> wait;

=head2 USAGE

=over

=item pid ($PID, $TIMEOUT) -> $?|undef

Accepts PID and an optional deadline/timeout, returns either the process' exit status,
or undef on timeout.  The corresponding lambda is C<new_pid> :

   new_pid ($PID, $TIMEOUT) :: () -> $?|undef

=item signal ($SIG, $TIMEOUT) -> boolean

Accepts signal name and optional deadline/timeout, returns 1 if the signal was caught,
or C<undef> on timeout.  The corresponding lambda is C<new_signal> :

   new_signal ($SIG, $TIMEOUT) :: () -> boolean

=item spawn (@LIST) -> ( output, $?, $!)

Calls pipe open on C<@LIST>, reads all data printed by the child process,
and awaits for the process to finish. Returns three scalars - collected output,
process exitcode C<$?>, and an error string (usually C<$!>). The corresponding
lambda is C<new_process> :

   new_process (@LIST) :: () -> ( output, $?, $!)

Lambda objects created by C<new_process> have an additional field C<'pid'> 
initialized with the process pid value.

=back

=head1 LIMITATION

C<pid> and C<new_pid> don't work on win32 because win32 doesn't use
SIGCHLD/waitpid.  Native implementation of C<spawn> and C<new_process> doesn't
work for the same reason on win32 as well, therefore those were reimplemented
using threads, and require a threaded perl.

=head1 SEE ALSO

L<IO::Lambda>, L<perlipc>, L<IPC::Open2>, L<IPC::Run>

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
