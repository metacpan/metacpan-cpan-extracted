#/**
# Shared memory ring buffers for diagnosis/debug of Perl scripts.
# Uses IPC::Mmap to create/access/manage a memory mapped file (or namespace
# on Win32) as a ring buffer structure that can be used by "applications
# under test" that use an appropriate debug module (e.g., Devel::STrace)
# along with an external monitoring application (e.g., Devel::STrace::Monitor).
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
package Devel::RingBuffer;

use Carp qw(cluck carp confess);
#use threads;
#use threads::shared;
use Config;
use IPC::Mmap;
use DynaLoader;
use Exporter;

BEGIN {
our @ISA = qw(Exporter DynaLoader);

#
#	offset of global fields
#
use constant RINGBUF_SINGLE => 0;
use constant RINGBUF_MSGAREA_SZ => 4;
use constant RINGBUF_BUFFERS => 8;
use constant RINGBUF_SLOTS => 12;
use constant RINGBUF_SLOT_SZ => 16;
use constant RINGBUF_CREATE_STOP => 20;
use constant RINGBUF_CREATE_TRACE => 24;
use constant RINGBUF_GLOBAL_SZ => 28;
use constant RINGBUF_TOTALMSG_SZ => 32;
use constant RINGBUF_GLOBMSG_SZ => 36;
use constant RINGBUF_GLOBAL_MSG => 40;
use constant RINGBUF_RINGHDR_SZ => 40;
#
#	offsets of watchlist members
#
use constant RINGBUF_WATCH_INUSE => 0;
use constant RINGBUF_WATCH_EXPRLEN => 4;
use constant RINGBUF_WATCH_EXPR => 8;
use constant RINGBUF_WATCH_READY => 264;
use constant RINGBUF_WATCH_RESLEN => 268;
use constant RINGBUF_WATCH_RESULT => 272;
use constant RINGBUF_WATCH_SZ => 784;
use constant RINGBUF_WATCH_CNT => 4;
use constant RINGBUF_WATCH_EXPRSZ => 256;
use constant RINGBUF_WATCH_RESSZ => 512;
#
#	offsets of ring buffer members
#
use constant RINGBUF_PID => 0;
use constant RINGBUF_TID => 4;
use constant RINGBUF_CURRSLOT => 8;
use constant RINGBUF_DEPTH => 12;
use constant RINGBUF_TRACE => 16;
use constant RINGBUF_SIGNAL => 20;
use constant RINGBUF_BASEADDR => 24;
use constant RINGBUF_WATCH_OFFSET => 28;
use constant RINGBUF_BUFHDR_SZ => 28;

use constant RINGBUF_DFLT_SLOTSZ => 214;
use constant RINGBUF_ENTRY_SZ => 200;
use constant RINGBUF_SLOT_PACKSTR => 'l d S/a*';
#
#	consts for member indexes
#
use constant RINGBUF_FILENAME => 0;
use constant RINGBUF_SIZE => 1;
use constant RINGBUF_COUNT => 2;
use constant RINGBUF_BUFSIZE => 3;
use constant RINGBUF_SLOT_CNT => 4;
use constant RINGBUF_FLD_TID => 5;
use constant RINGBUF_FLD_PID => 6;
use constant RINGBUF_RING => 7;
use constant RINGBUF_FH => 8;
use constant RINGBUF_FLD_MSGAREA_SZ => 9;
use constant RINGBUF_FLD_GLOBAL_SZ => 10;
use constant RINGBUF_MAP_OFFSET => 11;
use constant RINGBUF_RINGS_OFFSET => 12;
use constant RINGBUF_MAP_ADDR => 13;
use constant RINGBUF_RINGS_ADDR => 14;
use constant RINGBUF_ADDRESS => 15;
use constant RINGBUF_SLOT_SIZE => 16;
use constant RINGBUF_NEXT_IDX => 17;

use constant RINGBUF_RING_WAIT => 0.3;

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = (
	ringbuffer_consts => [
 	qw/RINGBUF_SINGLE RINGBUF_MSGAREA_SZ RINGBUF_BUFFERS RINGBUF_SLOTS
 		RINGBUF_SLOT_SZ RINGBUF_CREATE_STOP RINGBUF_CREATE_TRACE RINGBUF_GLOBAL_SZ
 		RINGBUF_TOTALMSG_SZ RINGBUF_GLOBMSG_SZ
 		RINGBUF_GLOBAL_MSG RINGBUF_RINGHDR_SZ RINGBUF_WATCH_INUSE
 		RINGBUF_WATCH_EXPRLEN RINGBUF_WATCH_EXPR RINGBUF_WATCH_READY
 		RINGBUF_WATCH_RESLEN RINGBUF_WATCH_RESULT RINGBUF_WATCH_SZ
 		RINGBUF_WATCH_CNT RINGBUF_PID RINGBUF_TID RINGBUF_CURRSLOT
 		RINGBUF_DEPTH RINGBUF_TRACE RINGBUF_SIGNAL RINGBUF_WATCH_OFFSET
 		RINGBUF_BUFHDR_SZ RINGBUF_DFLT_SLOTSZ RINGBUF_ENTRY_SZ RINGBUF_SLOT_PACKSTR/
	],

	ringbuffer_members => [
	qw/RINGBUF_FILENAME RINGBUF_SIZE RINGBUF_COUNT RINGBUF_BUFSIZE RINGBUF_SLOT_CNT
		RINGBUF_FLD_TID RINGBUF_FLD_PID RINGBUF_RING RINGBUF_FH
		RINGBUF_FLD_MSGAREA_SZ RINGBUF_FLD_GLOBAL_SZ RINGBUF_MAP_OFFSET
		RINGBUF_RINGS_OFFSET RINGBUF_MAP_ADDR RINGBUF_RINGS_ADDR RINGBUF_ADDRESS
		RINGBUF_SLOT_SIZE RINGBUF_NEXT_IDX/
	],
);

Exporter::export_tags(keys %EXPORT_TAGS);

};

our $VERSION = '0.31';
our $hasThreads;

BEGIN {
	if ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
		require Devel::RingBuffer::ThreadFacade;
		$hasThreads = 1;
	}
}

use threads::shared;

use strict;
use warnings;

bootstrap Devel::RingBuffer $VERSION;

use Devel::RingBuffer::Ring;

our $thrdlock = undef;

#/**
# Constructor. Using a combination of the optional C<%args> and
# various environment variables, creates and initializes a
# mmap'ed file in read/write mode with the ring buffer structures.
#
# @param File	name of the file to be created for memory mapping.
# @param GlobalSize size of global monitor <=> AUT message buffer.
# @param MessageSize size of per-thread monitor <=> AUT message buffer.
# @param Rings Number of rings to create in the ring buffer.
# @param Slots Number of slots per ring.
# @param SlotSize Slot size in bytes.
# @param StopOnCreate Initial value for stop_on_create flag.
# @param TraceOnCreate Initial value for trace_on_create flag.
#
# @return Devel::RingBuffer object on success; undef on failure
#*/
sub new {
	my $class = shift;

	my %args = @_;

	my $file = $args{File} || $ENV{DEVEL_RINGBUF_FILE};
	my $anon;
	unless (defined($file)) {
		my @paths = split(/[\/\\]/, $0);
		$file = pop @paths;
		if ($^O eq 'MSWin32') {
			$anon = 1;
		}
		else {
			$file =  defined($ENV{TEMP}) ? "$ENV{TEMP}/$file" : "/tmp/$file";
		}
		$file=~s/^(.+)\..+/$1/;
#
#	use timestamp sans weekday and year
#
		my @pieces = split(/\s+/, scalar localtime);
		pop @pieces;	# get rid of year
		$pieces[0] = $$;	# replace weekday w/ PID
		$pieces[-1]=~tr/:/_/; # Win32 can't handle colons in filenames
		$file .= '.' . join('_', @pieces);
	}

#print STDERR "RingBuffer new: args:", join(', ', keys %args), "\n";

	my $ringslots = $args{Slots} || $ENV{DEVEL_RINGBUF_SLOTS} || 10;
	my $slotsz = $args{SlotSize} || $ENV{DEVEL_RINGBUF_SLOTSZ} || 200;
	my $ringcount = $args{Rings} || $ENV{DEVEL_RINGBUF_BUFFERS} || 20;
	my $ringmsgsz = $args{MessageSize} || $ENV{DEVEL_RINGBUF_MSGSZ} || 256;
	my $globmsgsz = $args{GlobalSize} || $ENV{DEVEL_RINGBUF_GLOBALSZ} || (16 * 1024);
	my $create_stop = $args{StopOnCreate} || $ENV{DEVEL_RINGBUF_SOC} || 0;
	my $create_trace = $args{TraceOnCreate} || $ENV{DEVEL_RINGBUF_TOC} || 0;
#
#	in order to avoid issues with word alignment, we'll always
#	force slotsz, msg size, and global size to be word aligned
#	(who knows, we may need to be 8 byte aligned on some platforms)
#
	$slotsz += (4 - ($slotsz & 3)) if ($slotsz & 3);
	$ringmsgsz += (4 - ($ringmsgsz & 3)) if ($ringmsgsz & 3);
	$globmsgsz += (4 - ($globmsgsz & 3)) if ($globmsgsz & 3);

	my $freemap_offs = RINGBUF_RINGHDR_SZ + $globmsgsz;

	my $ringbufsz = _get_ring_size($ringslots, $slotsz, $ringmsgsz);

	my $ringsize = _get_total_size($ringcount, $ringslots, $slotsz, $ringmsgsz, $globmsgsz) +
		1024;		# Win32 needs some extra room

	my $self = bless [
		$file,
		$ringsize,
		$ringcount,
		$ringbufsz,
		$ringslots,
		($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0),
		$$,
		undef,
		undef,
		$ringmsgsz,
		$globmsgsz,
		$freemap_offs,
		_get_rings_addr(0, $ringcount, $globmsgsz),
		$freemap_offs,
		_get_rings_addr(0, $ringcount, $globmsgsz),
		0,
		$slotsz
	], $class;
#
#	create the mmap'ed ring
#
#cluck "file is $file\n";
	if ($anon) {
#
#	on Win32 only...anonymous mmap is useless to us on POSIX
#
		$self->[RINGBUF_RING] = IPC::Mmap->new($file, $ringsize,
			PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON)
			or die "Can't open mmap file $file: $!";
	}
	else {
		open(FH, ">$file") ||
			confess "Can't open mmap file $file: $!";
		print FH "\0" x $ringsize;
		close FH;

		$self->[RINGBUF_RING] = IPC::Mmap->new($file, $ringsize,
			PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FILE)
			or die "Can't open mmap file $file: $!";
	}
#
#	share the thrdlock
#
	if ($hasThreads) {
#		print STDERR "we're shared\n";
		share($thrdlock);
	}
#
#	clear the ringbuffer (Win32 needs this)
#
	my $ringbuffer = $self->[RINGBUF_RING] ;
	my $var = "\0" x ($ringsize - 1024);
	$ringbuffer->write($var, 0, $ringsize - 1024);
	my $ringslotsz = $ringslots * $slotsz;
#
#	then init it
#
	return undef
		unless $ringbuffer->pack(0, 'l l l l l l l l l',
			0, $ringmsgsz, $ringcount, $ringslots, $slotsz, $create_stop, $create_trace, $globmsgsz, 0);

	my $addr = $self->[RINGBUF_ADDRESS] = $self->[RINGBUF_RING]->getAddress();

	$self->[RINGBUF_MAP_ADDR] += $addr;
	$self->[RINGBUF_RINGS_ADDR] += $addr;

	my $mapaddr = $self->[RINGBUF_MAP_ADDR];
	my $ringsaddr = $self->[RINGBUF_RINGS_ADDR];
#
#	let XS do init
#
	_free_ring($mapaddr, $ringsaddr, $ringbufsz, $_)
		foreach (0..$ringcount-1);
#
#	for unknown reasons, the first map doesn't take ... so remap
#
#	$self->remmap();

	return $self;
}

#/**
# Get the name of the mmap'ed file.
#
# @return the name of the mmap'ed file
#*/
sub getName { return $_[0]->[RINGBUF_FILENAME]; }

#/**
# Get base address of the mmap'ed file.
#
# @return the address of the mmap'ed file
#*/
sub getAddress { return $_[0]->[RINGBUF_ADDRESS]; }

#/**
# Allocate a ring buffer. Should only be used on ringbuffers created with new().
#
# @return a Devel::RingBuffer::Ring object on success.
#			If no rings are available, returns undef.
#*/
sub allocate {
	my $self = shift;
#
#	allocate a ring buffer and init it
#
#	unless (($self->[RINGBUF_FLD_TID] == threads->self()->tid()) ||
#		($self->[RINGBUF_FLD_PID] == $$)) {
#	On Win32, the fork() emulation means we shouldn't remap!!!
#
	if (0) {
	unless ($self->[RINGBUF_FLD_PID] == $$) {
#
#	this probably isn't needed anymore for threads, but may be for
#	processes...
#
		my $file = $self->[RINGBUF_FILENAME];
		my $ringsize = $self->[RINGBUF_SIZE];
		$self->[RINGBUF_RING] = IPC::Mmap->new($file, $ringsize,
			PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FILE) ||
			die "Can't mmap file $file: $!";
		$self->[RINGBUF_FLD_TID] = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);
		$self->[RINGBUF_FLD_PID] = $$;
	}
	}

	my $ring = 0;
	my $ringbuffer = $self->[RINGBUF_RING];
	$ringbuffer->lock();
	{
		lock($thrdlock);
#
#	use XS to find free ring (for performance reasons)
#
		$ring = _alloc_ring($self->[RINGBUF_MAP_ADDR], $self->[RINGBUF_COUNT]);
	}
	$ringbuffer->unlock();

	my $ringsaddr = $self->[RINGBUF_RINGS_ADDR];

	return defined($ring) ?
		Devel::RingBuffer::Ring->new(
			$self,
			_get_ring_addr($self->[RINGBUF_RINGS_ADDR],
				$ring,
				$self->[RINGBUF_SLOT_CNT],
				$self->[RINGBUF_SLOT_SIZE],
				$self->[RINGBUF_FLD_MSGAREA_SZ]),
			$self->[RINGBUF_ADDRESS],
			$ring,
			$self->[RINGBUF_SLOT_CNT],
			$self->[RINGBUF_FLD_MSGAREA_SZ],
			) :
		undef;
}

#/**
# Re-allocates a ring buffer. Required to handle threads' CLONE()
# of the existing ring buffer object when a new thread is created.
# C<reallocate()> simply allocates a ring buffer and returns its
# ring number, and its base address; the caller than updates
# an existing ring object with the returned values.
#
# @return the allocated ring index and address
#*/
sub reallocate {
	my $self = shift;

	my $newring = 0;
	my $ringbuffer = $self->[RINGBUF_RING];
	$ringbuffer->lock();
	{
		lock($thrdlock);
#
#	use XS to find free ring (for performance reasons)
#
		$newring = _alloc_ring($self->[RINGBUF_MAP_ADDR], $self->[RINGBUF_COUNT]);
	}
	$ringbuffer->unlock();

	return defined($newring) ?
		($newring,
		_get_ring_addr(
			$self->[RINGBUF_RINGS_ADDR],
			$newring,
			$self->[RINGBUF_SLOT_CNT],
			$self->[RINGBUF_SLOT_SIZE],
			$self->[RINGBUF_FLD_MSGAREA_SZ])) :
		();
}

#/**
# Constructor. Opens an existing mmap'd file for read/write
# access (for interactive debuggers)
#
# @param	$file	optional name of mmap'ed file (or namespace for Win32)
#
# @return  Devel::RingBuffer object on success; undef on failure
#*/
sub open {
	return _lcl_open(@_, PROT_READ|PROT_WRITE);
}

#/**
# Constructor. Opens an existing mmap'd file for read-only
# access (for simple monitor applications)
#
# @param	$file	optional name of mmap'ed file (or namespace for Win32)
#
# @return  Devel::RingBuffer object on success; undef on failure
#*/
sub monitor {
	return _lcl_open(@_, PROT_READ);
}

sub _lcl_open {
	my ($class, $file, $mode) = @_;
#
#	open twice: first to get config params, then
#	to map the whole file
#
#	use anonymous open for Win32
#
	my $flags = ($^O eq 'MSWin32') ?
		MAP_SHARED | MAP_ANON :
		MAP_SHARED | MAP_FILE;

	my $ringbuffer =
		IPC::Mmap->new($file, RINGBUF_RINGHDR_SZ, PROT_READ, $flags) or
			die "Can't mmap file $file: $!";

	my ($msgareasz, $count, $slots, $slotsz, $stop, $trace, $globmsgsz) =
		$ringbuffer->unpack(4, 28, 'l7');

	my $freemap_offs = RINGBUF_RINGHDR_SZ + $globmsgsz;

	my $ringbufsz = _get_ring_size($slots, $slotsz, $msgareasz);

	my $ringsize = _get_total_size($count, $slots, $slotsz, $msgareasz, $globmsgsz) +
		1024;		# Win32 needs some extra room

	$ringbuffer->close();

	$ringbuffer = IPC::Mmap->new($file, $ringsize, $mode, $flags)
		or die "Can't mmap file $file: $!";

	return bless [
		$file,
		$ringsize,
		$count,
		$ringbufsz,
		$slots,
		($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0),
		$$,
		$ringbuffer,
		undef,
		$msgareasz,
		$globmsgsz,
		$freemap_offs,
		_get_rings_addr(0, $count, $globmsgsz),
		$ringbuffer->getAddress() + $freemap_offs,
		_get_rings_addr($ringbuffer->getAddress(), $count, $globmsgsz),
		$ringbuffer->getAddress(),
		$slotsz
	], $class;
}

#/**
# Get the free buffer map
#
# @return list of bytes, one per ring; if and element is 'true', the associated
#			ring is free; otherwise the ring is in use.
#*/
sub getMap {
	return $_[0]->[RINGBUF_RING]->unpack(
		$_[0]->[RINGBUF_MAP_OFFSET],
		$_[0]->[RINGBUF_COUNT],
		'C' . $_[0]->[RINGBUF_COUNT] );
}

#/**
#	Get the RingBuffer global header fields. The fields
#	returned include:
#	<p>
#	<ol>
#	<li>single	- global control variable
#	<li>msgarea_sz - size of per-thread message area
#	<li>max_buffer - number of configured rings
#	<li>slots - number of slots per ring
#	<li>slot_sz - size of each slot (excluding linenumber and timestamp header)
#	<li>stop_on_create - 1 => new threads created with signal = 1
#	<li>trace_on_create - 1 => new threads created with trace = 1
#	<li>global_sz - size of global message buffer
#	<li>globmsg_total - size of complete global message contents
#	<li>globmsg_sz - size of current global message fragment
#	</ol>
#
#	@return	list of the specified header values
#*/
sub getHeader {
	return $_[0]->[RINGBUF_RING]->unpack(0, 40, 'l10');
}
#/**
# Open and return a Devel::RingBuffer::Ring object
# for the specified ring number.
#
# @param $ringnum	number of ring to be opened
#
# @return Devel::RingBuffer::Ring object
#*/
sub getRing {
	my ($self, $ringnum) = @_;
	return Devel::RingBuffer::Ring->open(
		$self,
		_get_ring_addr(
			$self->[RINGBUF_RINGS_ADDR],
			$ringnum,
			$self->[RINGBUF_SLOT_CNT],
			$self->[RINGBUF_SLOT_SIZE],
			$self->[RINGBUF_FLD_MSGAREA_SZ]),
		$self->[RINGBUF_ADDRESS],
		$ringnum,
		$self->[RINGBUF_SLOT_CNT],
		$self->[RINGBUF_FLD_MSGAREA_SZ]
	);
}

#/**
# Get the configured number of slots per ring.
#
# @return the number of slots configured for the ring buffer.
#*/
sub getSlots { return $_[0]->[RINGBUF_SLOT_CNT]; }
#/**
# Get the configured size of slots.
#
# @return the slot size
#*/
sub getSlotSize { return $_[0]->[RINGBUF_SLOT_SIZE]; }
#/**
# Get the number of configured rings.
#
# @return the count of rings
#*/
sub getCount { return $_[0]->[RINGBUF_COUNT]; }
#/**
# Close the ring buffer.
#
# @deprecated
#*/
sub close {
	my $self = shift;
	my $ring = delete $self->[RINGBUF_RING];
	return 1;
}
#/**
# Free a ring. Returns a ring to the free list
#
# @param $ring	the ring object to be freed
#*/
sub free {
	my ($self, $ring) = @_;
#print STDERR "freeing ring $ring\n";
	return 1 unless $self->[RINGBUF_RING];

	my $ringbuffer = $self->[RINGBUF_RING];
	$ringbuffer->lock();
	{
		lock($thrdlock);
#
#	XS handles everything but the locks
#
		_free_ring($self->[RINGBUF_MAP_ADDR],
			$self->[RINGBUF_RINGS_ADDR],
			$self->[RINGBUF_BUFSIZE],
			$ring);
	}

	$ringbuffer->unlock();
}
#/**
# Get the IPC::Mmap object used to store the ringbuffer.
#
# @return the IPC::Mmap object
#*/
sub getMmap { return $_[0]->[RINGBUF_RING]; }
#
#	just check for the current thread/process's ring instance;
#	note this can be a lengthy process, since we must
#	scan the mmap'd ring buffer headers for matching PID/TID,
#	and then free it
#
#	!!!DPERECATED!!! We can't permit DESTROY if cloned versions
#	might destroy things; just let process run down deal with
#	closing the file
#
sub OLDDESTROY {
	my $self = shift;
	my $tid = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);

	return unless $self->[RINGBUF_RING];

	print STDERR "RingBuffer DESTROYING in thread $tid\n";

	my $ringbuffer = $self->[RINGBUF_RING];
	$ringbuffer->lock();
	{
		lock($thrdlock);
#
#	XS handles everything but the locks
#
		my $ring = _find_ring($self->[RINGBUF_RINGS_ADDR],
			$self->[RINGBUF_BUFSIZE], $self->[RINGBUF_COUNT], $$, $tid);
		_free_ring($self->[RINGBUF_MAP_ADDR],
			$self->[RINGBUF_RINGS_ADDR],
			$self->[RINGBUF_BUFSIZE],
			$ring)
			if defined($ring);
	}
	$ringbuffer->unlock();
}

#/**
# Sets the value of the global single field.
#
# @param value to set
#
# @return the prior value of the field.
#*/
sub setSingle {
	return $_[0]->[RINGBUF_RING]->pack(0, 'l', $_[1]);
}

#/**
# Gets the value of the global single field.
#
# @return the value of the field.
#*/
sub getSingle {
	return $_[0]->[RINGBUF_RING]->unpack(0, 4, 'l');
}

#/**
# Sets the value of the stop_on_create field.
#
# @return the prior value of the field.
#*/
sub setStopOnCreate {
	return $_[0]->[RINGBUF_RING]->pack(RINGBUF_CREATE_STOP, 'l', $_[1]);
}

#/**
# Get the value of the stop_on_create field.
#
# @return the current value of the field.
#*/
sub getStopOnCreate {
	return $_[0]->[RINGBUF_RING]->unpack(RINGBUF_CREATE_STOP, 4, 'l');
}

#/**
# Sets the value of the trace_on_create field.
#
# @param $trace_on_create	value to set
# @return the prior value of the field
#*/
sub setTraceOnCreate {
	return $_[0]->[RINGBUF_RING]->pack(RINGBUF_CREATE_TRACE, 'l', $_[1]);
}

#/**
# Get the value of the trace_on_create field.
#
# @return the value of the field
#*/
sub getTraceOnCreate {
	return $_[0]->[RINGBUF_RING]->unpack(RINGBUF_CREATE_TRACE, 4, 'l');
}

#/**
# Sets a message into the global message area. Note that
# this operation requires locking the entire ring buffer
# header until the message is completely transfered.
# Messages larger than the configured global message size
# will be transfered in chunks; each chunk must back ACK'd by
# the message receiver.
#
# @param $msg	the message to send
#
# @return	the RingBuffer object
#*/
sub setGlobalMsg {
	my $self = shift;
	my $ringbuffer = $self->[RINGBUF_RING];
	my $globsz = $self->[RINGBUF_FLD_GLOBAL_SZ];
	my $first = 1;
	$ringbuffer->lock();
	{
		lock($thrdlock);
		my ($t, $frag) = (0,0);
		my $len = length($_[0]);
		while ($len) {
#
#	may need to fragment
#
			$t = ($len > $globsz) ? $globsz : $len;
			$ringbuffer->write(substr($_[0], $frag, $t), RINGBUF_GLOBAL_MSG, $t);
			$ringbuffer->pack(RINGBUF_GLOBMSG_SZ, 'l', $t);
#
#	set this last so reader doesn't read to soon
#
			$ringbuffer->pack(RINGBUF_TOTALMSG_SZ, 'l', $len),
			$first = undef
				if $first;

			$len -= $t;
			$frag += $t;
#
#	wait for ACK that its been read
#
			sleep RINGBUF_RING_WAIT,
			$t = $ringbuffer->unpack(RINGBUF_GLOBMSG_SZ, 4, 'l')
				while $t;
		}
		$ringbuffer->pack(RINGBUF_TOTALMSG_SZ, 'l', 0);
	}
	$ringbuffer->unlock();
	return $self;
}

#/**
# Gets a message from the global message area. Note that
# this operation B<does not> lock the entire ring buffer
# header, but instead relies on signalling of the message
# chunk lengths.
# Messages larger than the configured global message size
# will be received in chunks; each chunk must back ACK'd by
# the message receiver.
#
# @return	the re-assembled global message buffer contents
#
#*/
sub getGlobalMsg {
	my $self = shift;
	my $ringbuffer = $self->[RINGBUF_RING];
	my $globsz = $self->[RINGBUF_FLD_GLOBAL_SZ];
	my $result = '';
	my $frag;
	my $t;
#
#	wait for indication that msg is available
#
	my $len = $ringbuffer->unpack(RINGBUF_TOTALMSG_SZ, 4, 'l');

	sleep RINGBUF_RING_WAIT,
	$len = $ringbuffer->unpack(RINGBUF_TOTALMSG_SZ, 4, 'l')
		until $len;

	while ($len) {
#
#	may be fragmented
#	wait for length field
#
		sleep RINGBUF_RING_WAIT,
		$t = $ringbuffer->unpack(RINGBUF_GLOBMSG_SZ, 4, 'l')
			until $t;

		$ringbuffer->read($frag, RINGBUF_GLOBAL_MSG, $t);
		$len -= $t;
		$result .= $frag;
#
#	ACK it
#
		$ringbuffer->pack(RINGBUF_GLOBMSG_SZ, 'l', 0);
	}
	return $result;
}

1;
