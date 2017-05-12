# $Id: SNMP.pm,v 1.20 2009/09/18 09:38:00 dk Exp $
package IO::Lambda::SNMP;
use vars qw(
	$DEBUG
	@ISA @EXPORT_OK %EXPORT_TAGS 
	$MASTER %ACTIVE_FDS %PASSIVE_FDS 
	@TIMER $TIMER_ACTIVE
);
@ISA = qw(Exporter);
my @methods = qw(get fget getnext fgetnext set bulkwalk);
@EXPORT_OK = map { "snmp$_" } @methods;
%EXPORT_TAGS = ( all => \@EXPORT_OK);
$DEBUG = $IO::Lambda::DEBUG{snmp} || 0;

use strict;
use warnings;
use SNMP;
use IO::Handle;
use Exporter;
use Time::HiRes qw(time);
use IO::Lambda qw(:all :dev);

# $DEBUG = 1;

#
# Part I: Lower-level event loop interactions
# 
# Create a singleton object that will receive yield notification
# and that will be passed as WATCH_OBJ for all lower-level events
# to not involve upper-level IO::Lambda event mechanisms. In this
# part, we talk to the loop directly because SNMP has its own
# event loop.
#
# Also note that this implementation allows for use of SNMP with native
# callbacks together with lambdas.
$MASTER = bless {}, __PACKAGE__;

# register yield handler
IO::Lambda::add_loop($MASTER);
END { IO::Lambda::remove_loop($MASTER) };

sub remove {}

sub empty { 0 == keys %ACTIVE_FDS and 0 == keys %PASSIVE_FDS }

sub yield
{
	warn "snmp.yield\n" if $DEBUG;
	SNMP::MainLoop(1e-6);
	reshuffle_fds();
}
# Use the same $MASTER for the lambda emulator and do not call anything in the handler,
# but do that in yield()
sub io_handler
{
	my ( undef, $rec) = @_;
	my $fileno = fileno($rec->[WATCH_IO_HANDLE]);
	warn "snmp.io_handler[$fileno]\n" if $DEBUG;
	$PASSIVE_FDS{$fileno} = delete $ACTIVE_FDS{$fileno};
}

# There'll also be a single timer as SNMP loop needs timeouts
$TIMER[WATCH_OBJ] = bless {}, "IO::Lambda::Loop::SNMP::Timer";
sub IO::Lambda::Loop::SNMP::Timer::io_handler { $TIMER_ACTIVE = 0 }

# Get all fds monitored by SNMP, and monitor these by ourselves.
# Return number of events passed (and therefore resubmitted)
sub reshuffle_fds
{
	my $resubmitted = 0;

	my ( $timeout, @fds) = SNMP::select_info;
	@fds = grep { defined } @fds;
	if ( @fds) {
		$timeout = 1e-6 if defined($timeout) && $timeout == 0;
	} else {
		undef $timeout;
	}

	# kill old handles
	my %all = map { $_ => 1 } @fds;
	for my $old ( grep { not exists $all{$_} } keys %ACTIVE_FDS) {
		$IO::Lambda::LOOP-> remove_event( delete $ACTIVE_FDS{$old});
		warn "snmp.remove: $old\n" if $DEBUG;
	}

	# resubmit handles that were fired off
	for my $passive ( grep { exists $all{$_} } keys %PASSIVE_FDS) {
		$resubmitted++;
		$IO::Lambda::LOOP-> watch( $ACTIVE_FDS{$passive} = $PASSIVE_FDS{$passive} );
		warn "snmp.resubmit: $passive\n" if $DEBUG;
	}
	%PASSIVE_FDS = ();

	# register new handles
	for my $new ( grep { not exists $ACTIVE_FDS{$_} } @fds) {
	
		warn "snmp.listen: $new\n" if $DEBUG;
		
		my $fh = IO::Handle-> new;
		unless ( open( $fh, "<&=$new")) {
			warn "cannot dup($new):$!\n";
			next;
		}

		# construct a fake IO::Lambda event record
		my @rec;
		$rec[WATCH_OBJ]       = $MASTER;
		$rec[WATCH_IO_HANDLE] = $fh;
		$rec[WATCH_IO_FLAGS]  = IO_READ;

		$IO::Lambda::LOOP-> watch( $ACTIVE_FDS{$new} = \@rec);
	}

	# timer
	if ( $timeout) {
		my $deadline = time + $timeout;
		if ( $TIMER_ACTIVE) {
			if ( abs( $deadline - $TIMER[WATCH_DEADLINE]) > 0.001) {
				# restart the active timer
				warn "snmp.timer restart $timeout $deadline/$TIMER[WATCH_DEADLINE]\n"
					if $DEBUG;
				$IO::Lambda::LOOP-> remove_event( \@TIMER);
				$TIMER[WATCH_DEADLINE] = $deadline;
				$IO::Lambda::LOOP-> after( \@TIMER);
			}
			# else, same timeout, on already active timer - do nothing
		} else {
			# resubmit
			warn "snmp.timer resubmit $timeout\n" if $DEBUG;
			$TIMER[WATCH_DEADLINE] = $deadline;
			$IO::Lambda::LOOP-> after( \@TIMER);
			$TIMER_ACTIVE = 1;
			$resubmitted++;
		}
	} elsif ( $TIMER_ACTIVE) {
		warn "snmp.timer stop\n" if $DEBUG;
		# stop timer
		$IO::Lambda::LOOP-> remove_event( \@TIMER);
		$TIMER_ACTIVE = 0;
	}

	return $resubmitted;
}

# Part II - building on SNMP callback mechanism, provide lambda interface

sub snmpcallback
{
	my ($q, $c) = (shift, shift);

	warn "snmp.cb: $q\n" if $DEBUG;
	$q-> resolve($c);
	$q-> terminate(@_);
	undef $c;
	undef $q;
}


sub wrapper 
{
	my ( $cb, $method, $caller) = @_;

	return this-> override_handler( $method, $caller, $cb)
		if this-> {override}->{$method};

	my ( $session, @param ) = context;
	_subname( $method, $cb, 1) if $cb;

	# the caller will listen to a new lambda
	my $q = IO::Lambda-> new;
	my $c = $q-> bind;
	this-> add_tail( $cb, $caller, $q, context);

	# fire an snmp request
	my $ok = $session-> $method(
		@param, 
		[ \&snmpcallback, $q, $c ]
	);

	return $q-> resolve($c) unless $ok;

	reshuffle_fds();

	# don't set up timers and fd listeners yet, yield() will do that
	warn "snmp.call: $method($q)\n" if $DEBUG;
}

for ( @methods) {
	eval "sub snmp$_(&) { wrapper( shift, '$_', \\&snmp$_ ) }";
	die $@ if $@;
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::SNMP - snmp requests lambda style

=head1 DESCRIPTION

The module exports a set of conditions: snmpget, snmpfget, snmpgetnext,
snmpfgetnext, snmpset, and snmpbulkwalk, that behave like the corresponding
SNMP:: non-blocking counterpart functions. See L<SNMP> for descriptions of
their parameters and results.

=head1 SYNOPSIS

   use strict;
   use SNMP;
   use IO::Lambda::SNMP qw(:all);
   use IO::Lambda qw(:all);
   
   my $sess = SNMP::Session-> new(
      DestHost => 'localhost',
      Community => 'public',
      Version   => '2c',
   );
   
   this lambda {
      context $sess, new SNMP::Varbind;
      snmpgetnext {
         my $vb = shift;
         print @{$vb->[0]}, "\n" ; 
         context $sess, $vb;
         again unless $sess-> {ErrorNum};
      }
   };
   this-> wait;

=head1 SEE ALSO

L<IO::Lambda>, L<SNMP>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
