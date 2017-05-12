#/**
# A single shared memory ring buffer for diagnosis/debug of Perl scripts.
# Uses IPC::Mmap to create/access/manage a memory mapped file (or namespace
# on Win32) as a ring buffer structure that can be used by "applications
# under test" that use an appropriate debug module (e.g., Devel::STrace)
# along with an external monitoring application
# (e.g., Devel::STrace::Monitor).
# <p>
# Note that significant functionality is written in XS/C in order to minimize
# tracing/debugging overhead.
# <p>
# Permission is granted to use this software under the same terms as Perl itself.
# Refer to the <a href='http://perldoc.perl.org/perlartistic.html'>Perl Artistic License</a>
# for details.
#
# @author D. Arnold
# @since 2006-05-01
# @self $self
#*/
package	Devel::RingBuffer::Ring;

#use threads;
use Time::HiRes qw(time);
use Exporter;

BEGIN {
our @ISA = qw(Exporter);
#
#	consts for member indexes
#
use constant RINGBUF_RING_BUFFER => 0;
use constant RINGBUF_RING_SLOTS => 1;
#
# !!!+++!+!+!+!+!+!+!+!+!+!+!+
#	!!!DON'T CHANGE THIS INDEX UNLESS YOU CHANGE THE XS CODE TOO!!!!
# !!!+++!+!+!+!+!+!+!+!+!+!+!+
#
use constant RINGBUF_RING_ADDR => 2;

use constant RINGBUF_RING_PID => 3;
use constant RINGBUF_RING_TID => 4;
use constant RINGBUF_RING_SLOT => 5;
use constant RINGBUF_RING_DEPTH => 6;
use constant RINGBUF_RING_INDEX => 7;
use constant RINGBUF_RING_MSGSZ => 8;
use constant RINGBUF_RING_HDRSZ => 9;
use constant RINGBUF_BASE_ADDR => 10;

use constant RINGBUF_RING_WAIT => 0.3;

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = (
	ring_members => [
	qw/RINGBUF_RING_BUFFER RINGBUF_RING_SLOTS RINGBUF_RING_ADDR
		RINGBUF_RING_PID RINGBUF_RING_TID RINGBUF_RING_SLOT RINGBUF_RING_DEPTH
		RINGBUF_RING_INDEX RINGBUF_RING_MSGSZ RINGBUF_RING_HDRSZ
		RINGBUF_BASE_ADDR/
	],
);

Exporter::export_tags(keys %EXPORT_TAGS);

};

use Config;
use Devel::RingBuffer;	# to bootstrap
use Devel::RingBuffer qw(:ringbuffer_consts);

our $hasThreads;

BEGIN {
	if ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
		require Devel::RingBuffer::ThreadFacade;
		$hasThreads = 1;
	}
}

use strict;
use warnings;

our $VERSION = '0.31';
#/**
# Constructor. Allocates a ring buffer, and initializes its header
# and control variables.
#
# @param $ringbuffer	the Devel::RingBuffer object
# @param $ringaddr		the base address of this ring
# @param $baseaddr		base address of the complete ring buffer structure
# @param $ringnum		the number (i.e., positional index) of this ring
# @param $slots			number of slots per ring
# @param $msgareasz		size of the per-thread message area
#
# @return Devel::RingBuffer::Ring object on success; undef on failure
#*/
sub new {
	my ($class, $ringbuffer, $ringaddr, $baseaddr, $ringnum, $slots, $msgareasz) = @_;

	my $tid = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);
	_init_ring($ringaddr, $$, $tid, $baseaddr);

	return bless [
		$ringbuffer,
		$slots,
		$ringaddr,
		$$,
		$tid,
		-1,
		0,
		$ringnum,
		$msgareasz,
		RINGBUF_BUFHDR_SZ + $msgareasz,
		$baseaddr
	], $class;
}
#/**
# Constructor. Allocates a ring buffer, and initializes its header
# and control variables. Called when the AUT object (e.g., DB)
# is CLONE'd, so that a new ring can be assigned to the new thread
#
# @return	the Devel::RingBuffer::Ring object
#*/
sub clone {
	my $self = shift;

	my $tid = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);
	my ($ringnum, $ringaddr) = $self->[RINGBUF_RING_BUFFER]->reallocate();
	return undef unless defined($ringnum);
	$self->[RINGBUF_RING_ADDR] = $ringaddr;
	$self->[RINGBUF_RING_INDEX] = $ringnum;
	_init_ring($ringaddr, $$, $tid, $self->[RINGBUF_BASE_ADDR]);
	return $self;
}
#/**
# Constructor. Opens an existing ring buffer for read-only access.
#
# @param $ringbuffer	the Devel::RingBuffer object
# @param $ringaddr		the base address of this ring
# @param $baseaddr		base address of the complete ring buffer structure
# @param $ringnum		the number (i.e., positional index) of this ring
# @param $slots			number of slots per ring
# @param $msgareasz		size of the per-thread message area
#
# @return Devel::RingBuffer::Ring object on success; undef on failure
#*/
sub open {
	my ($class, $ringbuffer, $ringaddr, $baseaddr, $ringnum, $slots, $msgareasz) = @_;

	my ($pid, $tid, $slot, $depth) = _get_header($ringaddr);

	return bless [
		$ringbuffer,
		$slots,
		$ringaddr,
		$pid,
		$tid,
		$slot,
		$depth,
		$ringnum,
		$msgareasz,
		RINGBUF_BUFHDR_SZ + $msgareasz,
		$baseaddr
	], $class;
}
#/**
# Update the current slot. Only updates linenumber and timestamp.
# May be called as either object or class method; in the latter case,
# caller must supply the ring's base address <i>(used within DB::DB()
# to optimize access speed)</i>
#
# @param $address		<b><i>class method calls only</i></b>: base address of the ring
# @param $linenumber	linenumber of current statement
#
# @return the Devel::RingBuffer::Ring object
#*/
# @xs updateSlot

#/**
# @xs nextSlot
# Allocate and initialize the next slot. If the stack depth is
# greater than the configured number of slots, the oldest
# in-use slot is used, overwriting its current contents.
# May be called as either object or class method; in the latter case,
# caller must supply the ring's base address <i>(used within DB::sub()
# to optimize access speed)</i>
# <p>
# <i>Note: In future, this should return prior contents so we can restore
#	on de-wrapping.</i>
#
# @param $address		<b><i>class method calls only</i></b>: base address of the ring
# @param $entry		subroutine name (from $DB::sub)
#
# @return the stack depth after the slot is allocated.
#*/
# @xs nextSlot

#/**
# @xs freeSlot
# Free the current slot and invalidates its contents.
# May be called as either object or class method; in the latter case,
# caller must supply the ring's base address <i>(used within DB::sub()
# to optimize access speed)</i>
#
# @param $address		<b><i>class method calls only</i></b>: base address of the ring
#
# @return the stack depth after the slot is freed.
#*/
# @xs freeSlot

#/**
# Get the ring header values. Header fields returned are
# <p>
# <ol>
# <li>pid - PID of the ring owner
# <li>tid - TID of the ring owner
# <li>currSlot - current top slot
# <li>depth - current stack depth
# </ol>
#
# @return list of header values
#*/
sub getHeader {
	return _get_header($_[0]->[RINGBUF_RING_ADDR]);
}

#/**
# Get the ring number (i.e., positional index)
#
# @return the ring number
#*/
sub getIndex { return $_[0]->[RINGBUF_RING_INDEX]; }

#/**
# Get the ring base address
#
# @return the ring base address
#*/
sub getAddress { return $_[0]->[RINGBUF_RING_ADDR]; }

#/**
# Get the contents of the specified slot.
#
# @param $slot the number of the slot to return
#
# @return the line number, timestamp, and subroutine name from the slot
#*/
sub getSlot {
	my ($self, $slot) = @_;

	return (-1, 0, '(Invalid slot; ring has been wrapped)')
		if ($slot < 0) || ($slot > $self->[RINGBUF_RING_SLOTS]);

	return _get_slot($self->[RINGBUF_RING_ADDR], $slot);
}
#/**
# Get the ring's trace flag
#
# @return the ring's trace flag
#*/
sub getTrace {
	return _get_trace($_[0]->[RINGBUF_RING_ADDR]);
}

#/**
# Set the ring's trace flag
#
# @param $trace the value to set
#
# @return the prior value of the ring's trace flag
#*/
sub setTrace {
	return _set_trace($_[0]->[RINGBUF_RING_ADDR], $_[1]);
}

#/**
# Get the ring's signal flag
#
# @return the ring's signal flag
#*/
sub getSignal {
	return _get_single($_[0]->[RINGBUF_RING_ADDR]);
}

#/**
# Set the ring's signal flag
#
# @param $signal the value to set
#
# @return the prior value of the ring's signal flag
#*/
sub setSignal {
	return _set_signal($_[0]->[RINGBUF_RING_ADDR], $_[1]);
}

#/**
# Post a command to the ring's command/message area
#
# @param $command the command value to set; must be no more than 3 bytes
# @param $msg	an optional message associated with the command; max length
#				is determined by configuration settings
#
# @return the ring object
#*/
sub postCommand { return postCmdEvent(@_, 1); }

#/**
# Post a response to the ring's command/message area
#
# @param $response the response value to set; must be no more than 3 bytes
# @param $msg	an optional message associated with the response; max length
#				is determined by configuration settings
#
# @return the ring object
#*/
sub postResponse { return postCmdEvent(@_, 0); }

sub postCmdEvent {
	my ($self, $cmd, $msg, $state) = @_;
	_post_cmd_msg($self->[RINGBUF_RING_ADDR], $cmd, $msg, $state);

	return $self;
}

#/**
# Wait indefinitely for a command to be posted to the ring's command/message area.
#
# @return the posted command and message
#*/
sub waitForCommand {
	return waitForCmdEvent(@_, 1);
}

#/**
# Wait indefinitely for a response to be posted to the ring's command/message area.
#
# @return the posted response and message
#*/
sub waitForResponse {
	return waitForCmdEvent(@_, 0);
}

sub waitForCmdEvent {
	my ($cmd, $msg);
	while (1) {
		($cmd, $msg) = _check_for_cmd_msg($_[0]->[RINGBUF_RING_ADDR], $_[1]);
		last if defined($cmd);
		sleep RINGBUF_RING_WAIT;
	}
	return ($cmd, $msg);
}

#/**
# Test if a command is available in the ring's command/message area.
#
# @return if available, the posted command and message; otherwise an empty list
#*/
sub checkCommand {
	return checkCmdEvent(@_, 1);
}

#/**
# Test if a response is available in the ring's command/message area.
#
# @return if available, the posted response and message; otherwise an empty list
#*/
sub checkResponse {
	return checkCmdEvent(@_, 0);
}

sub checkCmdEvent {
	return _check_for_cmd_msg($_[0]->[RINGBUF_RING_ADDR], $_[1]);
}
#/**
# Allocate and initialize a watchlist entry. Sets the watch expression.
#
# @param $expr	expression to set
#
# @return allocated watchlist entry number on success; undef on failure
#*/
sub addWatch {
	return _add_watch_expr($_[0]->[RINGBUF_RING_ADDR], $_[1]);
}

#/**
# Free a watchlist entry.
#
# @param $watch	the watchlist entry number to free
#
#*/
sub freeWatch {
	return _free_watch_expr($_[0]->[RINGBUF_RING_ADDR], $_[1]);
}

#/**
# Get a watchlist expression entry.
#
# @param $watch	the watchlist entry number to get
#
# @return the expression in the watchlist entry, if any; undef otherwise
#*/
sub getWatchExpr {
	return $_[0]->[RINGBUF_RING_BUFFER] ?
		_get_watch_expr($_[0]->[RINGBUF_RING_ADDR], $_[1]) :
		undef;
}

#/**
# Set a watchlist result entry.
#
# @param $watch	the watchlist entry number to set
# @param $result the result of the expression evaluation
# @param $error error string if expression evaluation fails
#*/
sub setWatchResult {
	my ($self, $watch, $result, $error) = @_;

	return $self->[RINGBUF_RING_BUFFER] ?
		_set_watch_result($self->[RINGBUF_RING_ADDR], $watch, $result, $error) :
		undef;
}
#/**
# Get a watchlist expression entry. If the length of the result exceeds
# the configured message size, the result is truncated. If the result is
# undef, the length will zero, and both the result and error will be undef.
# If the evaluation caused a failure, the length indicates the length of
# the error string, and result will be undef.
#
# @param $watch	the watchlist entry number to get
#
# @return the complete length of the result, the (possibly truncated) result value,
#			and the (possibly truncated) error message (if the evaluation failed).
#*/
sub getWatchResult {
	return $_[0]->[RINGBUF_RING_BUFFER] ?
		_get_watch_result($_[0]->[RINGBUF_RING_ADDR], $_[1]) :
		(undef, undef, undef);
}
#/**
#	Destructor. Updates the Devel::RingBuffer container object's free ring map,
#	<i>but only if executed in the same process/thread that it was allocated'd in.</i>
# (Note that due to threads CLONE, a ring object may be cloned with PID/TID
# of another thread, and thus DESTROY() could cause an invalid destruction)
# <p>
#	A future enhancement will add a flag to indicate to preserve
#	the ring on exit for post-mortem analysis
#*/
sub DESTROY {
#
#	for some reason we're getting leakage of ring objects into
#	the root thread, so only destroy in the thread its created
#
#	return unless defined($_[0]->[RINGBUF_RING_BUFFER]) &&
#		($_[0]->[RINGBUF_RING_PID] == $$) &&
#		($_[0]->[RINGBUF_RING_TID] == threads->self()->tid());
	return unless defined($_[0]->[RINGBUF_RING_BUFFER]);
	my @hdr = _get_header($_[0]->[RINGBUF_RING_ADDR]);
	my $tid = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);

	return
		unless ($hdr[0] == $$) && ($hdr[1] == $tid);
	$_[0]->[RINGBUF_RING_BUFFER]->free($_[0]->[RINGBUF_RING_INDEX]);
}

1;
