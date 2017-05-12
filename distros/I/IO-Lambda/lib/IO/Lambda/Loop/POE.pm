# $Id: POE.pm,v 1.6 2010/03/26 20:35:03 dk Exp $

package IO::Lambda::Loop::POE;
use strict;
use warnings;
use POE;
use IO::Lambda qw(:constants :dev);
use Time::HiRes qw(time);

use vars qw(
	@timers $deadline $alarm_id
	$kr_active_session $kr_last_session 
	$session $alarm_id 
	%filenos $event $DEBUG @mask @modes $global_destruction
);

END { $global_destruction = 1 } 

$DEBUG = $IO::Lambda::DEBUG{poe} || 0;

$mask[IO_READ]      = 'select_read';
$mask[IO_WRITE]     = 'select_write';
$mask[IO_EXCEPTION] = 'select_expedite';
$modes[POE::Kernel::MODE_RD()] = IO_READ;
$modes[POE::Kernel::MODE_WR()] = IO_WRITE;
$modes[POE::Kernel::MODE_EX()] = IO_EXCEPTION;

IO::Lambda::Loop::default('POE');
$kr_active_session = $poe_kernel-> [POE::Kernel::KR_ACTIVE_SESSION()];

# this shuts up warnings - we don't rely on run() anyway
${$poe_kernel-> [POE::Kernel::KR_RUN()]} |= POE::Kernel::KR_RUN_CALLED();

sub new   { bless {} , shift }
sub empty { ( @timers + scalar keys %filenos) ? 0 : 1 }

# creates new session when needed (or when about to be needed), and shuts one down as well
sub reset_session
{
	my $expect_to_have_a_new_session = shift;

	if ( not @timers and not keys %filenos and not $expect_to_have_a_new_session ) {
		if ( $session ) {
			warn "session "._o($session)." abandoned\n" if $DEBUG;
			undef $session;
		}
	} elsif ( not defined $session) {

		return if $global_destruction;
		
		$session = POE::Session-> create(
			inline_states => {
				_start  => sub {},
				timeout => \&on_tick,
				io      => \&on_io,
				_stop    => sub {
					warn "session "._o($_[SESSION])." stopped\n" if $DEBUG;
					if (not $session and (@timers or keys %filenos)) {
						require Data::Dumper;
						die "session stopped, but we have some unhandled data:\n",
						       Data::Dumper->Dump(\@timers, \%filenos)
					}
				},
			}
		);
		warn "session "._o($session). " started\n" if $DEBUG;
	}
}

# returns new deadline - we queue timeouts internally, without bothering POE 
sub deadline
{
	return undef unless @timers;
	my $new_deadline = $timers[0]-> [WATCH_DEADLINE];

	for ( map { $_-> [WATCH_DEADLINE] } @timers) {
		next if $_ >= $new_deadline;
		$new_deadline = $_;
	}
	return $new_deadline;
}


# we use a single session, single alarm here for all IO::Lambda timeouts
sub reset_timer
{
	my $old = $deadline;

	if ( $global_destruction) {
		undef $alarm_id;
		return;
	}

	$deadline = deadline();
	unless ( defined $deadline) {
		if (defined $alarm_id) {
			warn "stop timer[$alarm_id]\n" if $DEBUG;
			$poe_kernel-> alarm_remove($alarm_id);
			undef $alarm_id;
		}
		return;
	}

	return if defined $old and $old == $deadline;

	if ( defined $old and defined $alarm_id) {
		my $ok = $poe_kernel-> alarm_adjust($alarm_id, $deadline - $old);
		warn "alarm_adjust($alarm_id, ", $deadline-$old, "):$!" unless $ok;
		warn "reset timer[$alarm_id] $old -> $deadline\n" if $DEBUG;
	} else {
		warn "something wrong, existing alarm ID with no old timeout" if defined $alarm_id;
		$alarm_id = $poe_kernel-> alarm_set(timeout => $deadline);
		warn "alarm_set($deadline):$!" unless defined $alarm_id;
		warn "start timer[$alarm_id] $deadline\n" if $DEBUG;
	}
}

sub reset_mask
{
	return if $global_destruction;

	my $f = shift;

	my $mask = 0;
	for my $flags ( map { $_-> [WATCH_IO_FLAGS]} @{ $f-> {rec}} ) {
		$mask |= $_ for grep { $flags & $_ } IO_READ, IO_WRITE, IO_EXCEPTION;
	}
	return if $mask == $f-> {mask};

	for ( IO_READ, IO_WRITE, IO_EXCEPTION) {
		my $meth = $mask[$_];
		if ( $mask & $_ ) {
			next if $f-> {mask} & $_;
			$poe_kernel-> $meth( $f-> {handle}, 'io', $f);
			warn "$meth charged for ", fileno($f-> {handle}), "\n" if $DEBUG;
		} elsif ( $f-> {mask} & $_) {
			$poe_kernel-> $meth( $f-> {handle} );
			warn "$meth cleared for ", fileno($f-> {handle}), "\n" if $DEBUG;
		}
	}
	$f-> {mask} = $mask;
}

sub purge_filenos(&)
{
	my $sub = shift;
	my @kill;
	while ( my ( $fileno, $r) = each %filenos) {
		my @xr = grep &$sub, @{$r->{rec}};
		next if @xr == @{$r->{rec}};
		$r-> {rec} = \@xr;
		push @kill, $fileno unless @xr;
		reset_mask( $r);
	}
	warn "delete objects for @kill\n" if $DEBUG and @kill;
	delete @filenos{@kill};
}


sub on_io
{
	$event++;

	my ($handle, $mode, $obj) = @_[ARG0,ARG1,ARG2];
	my $mask = $modes[$mode];
	my $fileno = fileno($handle);
	warn "event $fileno/$mode=$mask\n" if $DEBUG;

	unless ( $obj-> {mask} & $mask) {
		warn "handled already, don't propagate\n" if $DEBUG;
		return;
	}

	my (@ev, @rx);
	# remove records that were listening for that event 
	for ( @{ $obj-> {rec} } ) {
		if ( $_-> [WATCH_IO_FLAGS] & $mask) {
			push @ev, $_;
		} else {
			push @rx, $_;
		}
	}
	$obj-> {rec} = \@rx;

	# next see if there are records waiting for more than one mode, -
	# build a vector and check them using select()
	if ( $obj-> {mask} & ~$mask) {
		my @vec = ('', '', '');
		vec( $vec[0], $fileno, 1) = 1 if $obj-> {mask} & IO_READ;
		vec( $vec[1], $fileno, 1) = 1 if $obj-> {mask} & IO_WRITE;
		vec( $vec[2], $fileno, 1) = 1 if $obj-> {mask} & IO_EXCEPTION;
		select( $vec[0], $vec[1], $vec[2], 0 );
		$mask |= IO_READ      if vec($vec[0], $fileno, 1);
		$mask |= IO_WRITE     if vec($vec[1], $fileno, 1);
		$mask |= IO_EXCEPTION if vec($vec[2], $fileno, 1);
	}
	reset_mask($obj);
	unless ($obj-> {mask}) {
		delete $filenos{$fileno};
		warn "object deleted for $fileno\n" if $DEBUG;
	}

	# kill associated timers
	my %timer = (map { $_ => undef } grep { defined $_-> [WATCH_DEADLINE] } @ev);
	if ( scalar keys %timer) {
		my $n = @timers;
		@timers = grep { not exists $timer{"$_"}} @timers;
		reset_timer if @timers != $n;
		warn "some timers killed too\n" if $DEBUG;
	}

	# prepare and call the handlers
	if ( $DEBUG) {
		warn "io dispatch ", join(' ', map { defined($_) ? $_ : 'undef' } @$_), "\n"
			for @ev;
	}
	for ( @ev) {
		$$_[WATCH_IO_FLAGS] &= $mask;
		$$_[WATCH_OBJ]-> io_handler( $_);
	}
	reset_session;
}

# timeout handler
sub on_tick
{
	warn "event timer[$alarm_id]\n" if $DEBUG;
	$event++;

	my @ev;

	# timers
	my $t  = time;
	push @ev, grep { $_-> [WATCH_DEADLINE] <= $t } @timers;
	@timers = grep { $_-> [WATCH_DEADLINE]  > $t } @timers;

	$alarm_id = undef;
	reset_timer;
	purge_filenos { 
		return not defined($_-> [WATCH_DEADLINE]) or 
		($_-> [WATCH_DEADLINE] > $t) 
	};

	$$_[WATCH_IO_FLAGS] = 0 for @ev;
	if ( $DEBUG) {
		warn "timer dispatch ", join(' ', map { defined($_) ? $_ : 'undef' } @$_), "\n"
			for @ev
	}
	$$_[WATCH_OBJ]-> io_handler( $_) for @ev;

	reset_session;
}

sub watch
{
	reset_session(1);
	$kr_last_session = $$kr_active_session;
	$$kr_active_session = $session;

	my ( $self, $rec) = @_;
	my $fileno = fileno $rec->[WATCH_IO_HANDLE];
	die "Invalid filehandle" unless defined $fileno;

	my $flags = $rec->[WATCH_IO_FLAGS];

	unless ( $filenos{$fileno}) {
		$filenos{$fileno} = {
			mask     => 0,
			rec      => [],
			handle   => $rec->[WATCH_IO_HANDLE],
		};
		warn "object created for $fileno\n" if $DEBUG;
	}

	my $f = $filenos{$fileno};
	push @{$f-> {rec}}, $rec;
	reset_mask($f);

	$self-> after( $rec) if $rec-> [WATCH_DEADLINE];

	$$kr_active_session = $kr_last_session;
}


sub after
{
	reset_session(1);
	$kr_last_session = $$kr_active_session;
	$$kr_active_session = $session;

	my ( $self, $rec) = @_;
	push @timers, $rec;
	reset_timer;
	
	$$kr_active_session = $kr_last_session;
}

sub remove
{
	$kr_last_session = $$kr_active_session;
	$$kr_active_session = $session;

	my ($self, $obj) = @_;

	my $t = @timers;
	@timers = grep { defined($_-> [WATCH_OBJ]) and $_-> [WATCH_OBJ] != $obj } @timers;
	reset_timer if $t != @timers;

	purge_filenos { defined($_-> [WATCH_OBJ]) and $_-> [WATCH_OBJ] != $obj };
	reset_session(0);

	$$kr_active_session = $kr_last_session;
}

sub remove_event
{
	$kr_last_session = $$kr_active_session;
	$$kr_active_session = $session;

	my ($self, $rec) = @_;

	my $t = @timers;
	@timers = grep { $_ != $rec } @timers;
	reset_timer if $t != @timers;
	purge_filenos { $_ != $rec };
	reset_session(0);

	$$kr_active_session = $kr_last_session;
}

sub yield
{
	warn "yield\n" if $DEBUG;
	my ( $self, $nonblocking ) = @_;
	local $event = 0;
	$poe_kernel-> run_one_timeslice;
	# that ssession should be the kernel itself
	$poe_kernel-> run if $poe_kernel-> _data_ses_count == 1;
	
	return if $nonblocking;
	$poe_kernel-> run_one_timeslice while $event == 0;
	$poe_kernel-> run if $poe_kernel-> _data_ses_count == 1;
}

sub signal { $event++ }

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Loop::POE - POE event loop for IO::Lambda

=head1 DESCRIPTION

This is the implementation of event loop for C<IO::Lambda> based on C<POE> event
loop. The module is not intended for direct use.

=head1 LIMITATIONS

Note that L<POE> is also a proxy event loop itself, and depending on the
actual event loop module it uses, functionality of C<IO::Lambda> might be
limited. 

=head1 SYNOPSIS

  use POE;
  use IO::Lambda::Loop::POE; # explicitly select the event loop module
  use IO::Lambda;

or

  setenv IO_LAMBDA_DEBUG=loop=POE

=head1 BUGS

Threads and forks seem to be not playing nicely together with POE.

=head1 SEE ALSO

L<POE>
