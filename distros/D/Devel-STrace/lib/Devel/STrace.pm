#/**
# Provides a minimal strace/truss-like utility for
# Perl scripts. Using <a href='http://search.cpan.org/perldoc?Devel::RingBuffer'>
# Devel::RingBuffer</a>, each new subroutine call is logged to an mmap'ed shared memory
# region (as provided by <a href='http://search.cpan.org/perldoc?IPC::Mmap'>IPC::Mmap</a>).
# As each statement is executed, the line number and Time::HiRes:;time() timestamp
# are written to the current ringbuffer slot. An external application can
# then monitor a running application by inspecting the mmap'ed area (see
# <a href='http://search.cpan.org/perldoc?Devel::STrace::Monitor'>Devel::STrace::Monitor</a>
# and the associated plstrace.pl application for an example).
# <p>
# Permission is granted to use this software under the same terms as Perl itself.
# Refer to the <a href='http://perldoc.perl.org/perlartistic.html'>Perl Artistic License</a>
# for details.
#
# @author D. Arnold
# @since 2006-05-01
# @see <a href='http://search.cpan.org/perldoc?Devel::RingBuffer'>Devel::RingBuffer</a>
# @see <a href='http://search.cpan.org/perldoc?IPC::Mmap'>IPC::Mmap</a>
# @see <a href='http://search.cpan.org/perldoc?Devel::STrace::Monitor'>Devel::STrace::Monitor</a>
# @see <a href='http://perldoc.perl.org/perldebguts.html'>perdebguts</a>
# @self	$self
#*/
package Devel::STrace;

require 5.008;

package DB;

#use threads;
use Config;
use Time::HiRes qw(time);
use Devel::RingBuffer;
use Devel::RingBuffer qw(:ringbuffer_consts);

$Devel::STrace::VERSION = '0.31';

# disable DB single-stepping
BEGIN {
	if ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
		require Devel::RingBuffer::ThreadFacade;
		$hasThreads = 1;
	}
	else {
		$hasThreads = undef;
	}
	$single = 0;
	$subtrace = 1;
	$tid = -1;
	$pid = -1;
	$ringbuffer = undef;
	$myring = undef;
	$depth = 0;
	$single = 1;
	$inited = 0;
#
#	DESTROY occasionally attempts to retie
#	after we've lost the objects we get our fixed
#	addresses from, so use local vars for them
#
	$ringaddr = undef;
	local ($pkg, $filename, $line);
}

#/**
# Threads clone method. Allocates a new ring, and
# and populates the existing cloned ring object with
# the newly allocate ring information.
#
# @static
#*/
sub CLONE {
#	print STDERR " ++++ In CLONE for ", Devel::RingBuffer::ThreadFacade->tid(), "\n";
	my ($oldtrace, $oldsingle) = ($subtrace, $single);
	$pid = $$;
	$tid = $hasThreads ? Devel::RingBuffer::ThreadFacade::tid() : 0;
	$subtrace = 0;
	$single = 0;
	if (defined($myring)) {
		$myring->clone();
		$ringaddr = $myring->getAddress();
#		print STDERR "\n$tid Allocd ring ", $myring->getIndex(), "\n";
	}
	else {
		$ringaddr = undef;
	}
	($single, $subtrace) = (1, $oldtrace);
#	print STDERR " ++++ Exit CLONE for ",
#		Devel::RingBuffer::ThreadFacade->tid(), " with $ringaddr\n";
}
#/**
# Debug a single statement. Creates a ringbuffer if none exists.
# Allocates a new ring if executed in a new process. Updates
# the ring's current slot with the current line number and timestamp.
#
# @static
#*/
sub DB {
#
#	if subtracing is disabled OR
#		we're tracing one of our debugger modules OR
#		we've init'd but theres no ringbuffer
#		(meaning we're in global DESTROY),
#	then skip out of this
#
	return if (! $subtrace) || ($inited && (! $ringbuffer)) ||
		($sub && (substr($sub, 0, 19) eq 'Devel::RingBuffer::'));

	$subtrace = 0;
	$single = 0;	# no effect if tied

#print STDERR "In DB::DB\n";

	unless (defined($ringbuffer)) {

#print STDERR "DB::DB initing the ringbuffer\n";

		$ringbuffer =  Devel::RingBuffer->new(TraceOnCreate => 1);
#
#	alloc the root's ringbuffer so we can tie to it
#
		$pid = $$;
		$tid = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);
		$myring = $ringbuffer->allocate();
		die "Can't get a ring!!!!\n"
			unless $myring;

		$depth = 0;
		$ringaddr = $myring->getAddress();

		print STDERR "\n*** Ringbuffer file is ", $ringbuffer->getName(), "\n";

#		print STDERR "\n$tid Allocd ring ", $myring->getIndex(), "\n";
		$inited = 1;
	}
#
#	check our pid; CLONE will handle threads for us
#
	if ($pid != $$) {
#
#	we keep the existing realdepth, since we may pop out
#	of the fork level
#
		$pid = $$;
		$tid = ($hasThreads ? Devel::RingBuffer::ThreadFacade->tid() : 0);
		$myring = $myring->clone();
		$depth = 0;
#
#	if we can't get a ring buffer, exit
#
		$single = 0,
		print STDERR "Can't get a ring!!!!\n" and
		return
			unless $myring;
		$ringaddr = $myring->getAddress();
	}
#
#	update the current slot's line number and timestamp;
#	note the update is suppressed in updateSlot if trace flag off
#	(tho it doesn't contribute much optimization)
#
    ($pkg, $filename, $line) = caller;
	Devel::RingBuffer::Ring::updateSlot($ringaddr, $line);

    $single = 1;
    $subtrace = 1;
}

#/**
# Debug a subroutine call. If trace is enabled
# in the ring, the next slot is allocated and the called
# subroutine (from $DB::sub) is written to it. The subroutine
# is then called with the caller's return context, and then
# the slot is freed before returning. Note that this method
# requires additional control to handle re-entrancy when
# DB::DB() or DB::sub() make calls to the various support
# functions.
#
# @static
# @return		The subroutine's return value(s), if the
#				caller is not in void context.
#*/
sub sub {
#
#	alloc next slot
#	fill with info
#	call &$sub
#	clear slot
#	free it up
#
#	!!!TODO: return the current slot contents prior to writing over
#	it; that way we can restore it after we return!!!
#
#	!!!NOTE NOTE NOTE!!!
#	we need to untie when realdepth goes to zero, and tie when it goes
#	to one
#
	my @ret;
	my $ret;

	my $wassingle = defined($myring) ? Devel::RingBuffer::Ring::getFlags($ringaddr) : $single;

	unless ($subtrace && ($wassingle & 3) && defined($myring) &&
		(substr($sub, 0, 19) ne 'Devel::RingBuffer::')) {
		if (wantarray) {
			@ret = &$sub;
		}
		elsif (defined(wantarray)) {
			$ret = &$sub;
		}
		else {
			&$sub;
		}

		return (wantarray) ? @ret : defined(wantarray) ? $ret : undef;
	}

	$subtrace = 0;

#	print STDERR "In $$:$tid DB::sub for $sub $depth\n";

	my $tsub ="$sub";
	$tsub = 'main' unless $tsub;
#
# If $sub ends with '::AUTOLOAD', note we've traced into AUTOLOAD
#
    $tsub .= " for $$tsub"
    	if (( length($tsub) > 10) && (substr( $tsub, -10, 10 ) eq '::AUTOLOAD' ));
#
#	now log the info in the slot; note that we rely on
#	DB::DB to set the lineno
#	!!!NOTE: we need to extract startlines of subs
#
	$depth = Devel::RingBuffer::Ring::nextSlot($ringaddr, $tsub);
#    print STDERR "In $$:$tid got depth of $depth\n"
#    	if $depth && (($depth < 0) && ($depth > 20));

	$subtrace = 1;
#
#	call it in proper context, then unwind
#
	if (wantarray) {
		@ret = &$sub;
	}
	elsif (defined wantarray) {
		$ret = &$sub;
	}
	else {
		&$sub;
	}

	if (defined($depth) && ($depth >= 0)) {
		$subtrace = 0;
		$depth = Devel::RingBuffer::Ring::freeSlot($ringaddr);
		$subtrace = 1;
#		print STDERR "*** $$:$tid return from $sub $depth\n";
		_traceback() if ($depth < 0);
	}

	return (wantarray) ? @ret : defined(wantarray) ? $ret : undef;
}

sub _traceback {
	my $i = 2;
	while (1) {
		my @t = caller($i++);
		last unless $t[2] || $t[3];
		print STDERR "\t*** called from $t[3]:$t[2]\n";
	}
}

1;
