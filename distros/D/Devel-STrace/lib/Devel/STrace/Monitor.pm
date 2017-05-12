#/**
# Provides a minimal strace/truss-like utility for
# Perl scripts. Using <a href='http://search.cpan.org/perldoc?Devel::RingBuffer'>
# Devel::RingBuffer</a>, each new subroutine call is logged to an mmap'ed shared memory
# region (as provided by <a href='http://search.cpan.org/perldoc?IPC::Mmap'>IPC::Mmap</a>).
# As each statement is executed, the line number and Time::HiRes:;time() timestamp
# are written to the current ringbuffer slot. An external application can
# then monitor a running application by inspecting the mmap'ed area.
# <p>
# Permission is granted to use this software under the same terms as Perl itself.
# Refer to the <a href='http://perldoc.perl.org/perlartistic.html'>Perl Artistic License</a>
# for details.
#
# @author D. Arnold
# @since 2006-05-01
# @see <a href='http://search.cpan.org/perldoc?Devel::RingBuffer'>Devel::RingBuffer</a>
# @see <a href='http://search.cpan.org/perldoc?IPC::Mmap'>IPC::Mmap</a>
# @see <a href='http://search.cpan.org/perldoc?Devel::STrace'>Devel::STrace</a>
# @see <a href='http://perldoc.perl.org/perldebguts.html'>perdebguts</a>
# @self	$self
#*/
package Devel::STrace::Monitor;

require 5.008;
use Devel::RingBuffer;

our $VERSION = '0.30';

use strict;
use warnings;

#/**
# Constructor. Opens the specified filename, or,
# if no filename is specified, the filename specified by
# the DEVEL_RINGBUF_FILE environment variable, using
# <a href='http://search.cpan.org/perldoc?Devel::RingBuffer'>Devel::RingBuffer</a>.
# Performs an initial scan of the file to create a PID/TID buffer map.
#
# @static
# @param	$file	name of the mmap()'d file (or namespace on Win32)
# @return 	on success, a new Devel::STrace::Monitor object;
#			undef on failure.
#*/
sub open {
	my ($class, $file) = @_;

	$file = $ENV{DEVEL_RINGBUF_FILE}
		unless $file;

#print $file, "\n";
	my $ringbuffer = Devel::RingBuffer->monitor($file)
		or return undef;

	my $self = bless {
		_ring => $ringbuffer,
		_filename => $file,
		_map => {},
		_slots => $ringbuffer->getSlots()
	}, $class;
#
#	load the map
#
#	my @headers = $ringbuffer->getHeader();
#	print "header is
#	single: $headers[0]
#	msgarea_sz: $headers[1]
#	max_buffers: $headers[2]
#	slots: $headers[3]
#	slot_sz: $headers[4]
#	stop_on_create: $headers[5]
#	trace_on_create: $headers[6]
#	global_sz: $headers[7]
#	globmsg_total: $headers[8]
#	globmsg_sz: $headers[9]
#	";

	return $self->refresh();
}

#/**
# Refresh the PID/TID buffer map.
# Scans the mmap'ed file to refresh the PID/TID buffer map.
# (in order to collect buffers for new threads/processes, or to discard
# old buffers for threads/processes which have terminated)
#
# @return 	the Devel::STrace::Monitor object
#*/
sub refresh {
	my $self = shift;

	my @bufmap = $self->{_ring}->getMap();
	my $map = $self->{_map} = {};
#
#	optimization: only inspect buffers that are alloc'd
#
	my ($pid, $tid, $current, $depth);
	foreach (0..$#bufmap) {
		next
			if $bufmap[$_];

		my $ring = $self->{_ring}->getRing($_);
		($pid, $tid, $current, $depth) = $ring->getHeader();
		$map->{"$pid:$tid"} = $ring;
	}
	return $self;
}

#/**
# Dump the mmap'ed ringbuffer file contents.
# Scans the mmap'ed file to refresh the PID/TID buffer map.
# (in order to collect buffers for new threads/processes, or to discard
# old buffers for threads/processes which have terminated)
#
# @param $trace_cb	callback to which ringbuffer contents are posted
# @param @pid_tid_list  optional list of PID's, or "PID:TID" keys
#						for which ringbuffer contents are to be returned;
#						if none are specified, all PID/TID keys are used;
#						if only a PID is specified, all threads for the process
#						are used.
#
# @return 	the Devel::STrace::Monitor object
#*/
sub trace {
	my $self = shift;
	my $trace_cb = shift;
#
#	if pids or pid:tid's provided, return them
#
	my @keys = sort keys %{$self->{_map}};
	if (scalar @_) {
		foreach my $pid (@_) {
#
#	if full key, get it
#
			$self->_get_trace($pid, $trace_cb),
			next
				if exists $self->{_map}{$pid};
#
#	else scan for all matching pids
#
			foreach (@keys) {
				$self->_get_trace($_, $trace_cb)
					if /^$pid:/;
			}
		}
		return $self;
	}
#
#	else dump everything
#
	$self->_get_trace($_, $trace_cb)
		foreach (@keys);

	return $self;
}

sub _get_trace {
	my ($self, $key, $cb) = @_;

	my $ring = $self->{_map}{$key};
	return undef unless $ring;

	my ($pid, $tid, $current, $depth) = $ring->getHeader();

	my $slot;
	my $slots = $self->{_slots};
	my ($trace, $line, $time);

	$slots = $depth if ($depth < $slots);
	foreach (1..$slots) {
		($line, $time, $trace) = $ring->getSlot($current);
		&$cb($key, $current, $depth, $line, $time, $trace);
		$current--;
		$current = $slots - 1 if ($current < 0);
	}

	return $self;
}

#/**
# Set the current ringbuffer global single
# control variable value. Setting this to a non-zero
# value causes Devel::STrace to trace data for all threads
# of all processes; setting it to zero <i>may</i> disable
# tracing, <i>but only</i> if the per-thread trace and signal
# control variables are also set to zero.
#
# @param $value		new value to assign to single
#
# @return 	the prior value of the Devel::RingBuffer global single value
#*/
sub setSingle {
	my $single = $_[0]->{_ring}->getSingle();
	$_[0]->{_ring}->setSingle($_[1]);
	return $single;
}

#/**
# Get the current ringbuffer global single
# control variable value.
#
# @return 	the current Devel::RingBuffer global single value
#*/
sub getSingle {
	return $_[0]->{_ring}->getSingle();
}
#/**
# Set the ringbuffer per-thread signal
# control variable value for the specified PID or PID:TID.
# Setting this to a non-zero
# value causes Devel::STrace to trace data for the specified threads
# of the specified processes; setting it to zero <i>may</i> disable
# tracing, <i>but only</i> if the global single variable, and the
# per-thread trace control variables are also set to zero.
#
# @param @pid_tid_list	optional list of PIDs, or "PID:TID", keys to set signal on;
#					if no keys are specified, all keys are used
# @param $value		new value to assign to signal
#
# @return 	a hash of the prior values of the Devel::RingBuffer signal values, keyed
#			by the "PID:TID"
#*/
sub setSignal {
	my $self = shift;
	my $value = pop;
	my %pidtids = ();
	if (scalar @_) {
		foreach my $pidtid (keys %{$self->{_map}}) {
			foreach (@_) {
				$pidtids{$_} = $self->{_map}{$_}->getSignal(),
				$self->{_map}{$_}->setSignal($value)
					if ($_ eq $pidtid) ||
						(substr($_, 0, length($pidtid) + 1) eq "$pidtid:");
			}
		}
	}
	else {
		$pidtids{$_} = $self->{_map}{$_}->getSignal(),
		$self->{_map}{$_}->setSignal($value)
			foreach (keys %{$self->{_map}});
	}
	return %pidtids;
}

#/**
# Get the ringbuffer per-thread signal
# control variable value for the specified PIDs or PID:TIDs.
#
# @param @pid_tid_list	optional list of PIDs, or "PID:TID", keys to get signal for;
#					if no keys are specified, all keys are used
#
# @return 	a hash of the Devel::RingBuffer signal values, keyed
#			by the "PID:TID"
#*/
sub getSignal {
	my $self = shift;
	my %pidtids = ();
	if (scalar @_) {
		foreach my $pidtid (keys %{$self->{_map}}) {
			foreach (@_) {
				$pidtids{$_} = $self->{_map}{$_}->getSignal()
					if ($_ eq $pidtid) ||
						(substr($_, 0, length($pidtid) + 1) eq "$pidtid:");
			}
		}
	}
	else {
		$pidtids{$_} = $self->{_map}{$_}->getSignal()
			foreach (keys %{$self->{_map}});
	}
	return %pidtids;
}

#/**
# Set the ringbuffer per-thread trace
# control variable value for the specified PID or PID:TID.
# Setting this to a non-zero
# value causes Devel::STrace to trace data for the specified threads
# of the specified processes; setting it to zero <i>may</i> disable
# tracing, <i>but only</i> if the global single variable, and the
# per-thread signal control variables are also set to zero.
#
# @param @pid_tid_list	optional list of PIDs, or "PID:TID", keys to set trace on;
#					if no keys are specified, all keys are used
# @param $value		new value to assign to trace
#
# @return 	a hash of the prior values of the Devel::RingBuffer trace values, keyed
#			by the "PID:TID"
#*/
sub setTrace {
	my $self = shift;
	my $value = pop;
	my %pidtids = ();
	if (scalar @_) {
		foreach my $pidtid (keys %{$self->{_map}}) {
			foreach (@_) {
				$pidtids{$_} = $self->{_map}{$_}->getTrace(),
				$self->{_map}{$_}->setTrace($value)
					if ($_ eq $pidtid) ||
						(substr($_, 0, length($pidtid) + 1) eq "$pidtid:");
			}
		}
	}
	else {
		$pidtids{$_} = $self->{_map}{$_}->getTrace(),
		$self->{_map}{$_}->setTrace($value)
			foreach (keys %{$self->{_map}});
	}
	return %pidtids;
}

#/**
# Get the ringbuffer per-thread trace
# control variable value for the specified PIDs or PID:TIDs.
#
# @param @pid_tid_list	optional list of PIDs, or "PID:TID", keys to get trace for;
#					if no keys are specified, all keys are used
#
# @return 	a hash of the Devel::RingBuffer trace values, keyed
#			by the "PID:TID"
#*/
sub getTrace {
	my $self = shift;
	my %pidtids = ();
	if (scalar @_) {
		foreach my $pidtid (keys %{$self->{_map}}) {
			foreach (@_) {
				$pidtids{$_} = $self->{_map}{$_}->getTrace()
					if ($_ eq $pidtid) ||
						(substr($_, 0, length($pidtid) + 1) eq "$pidtid:");
			}
		}
	}
	else {
		$pidtids{$_} = $self->{_map}{$_}->getTrace()
			foreach (keys %{$self->{_map}});
	}
	return %pidtids;
}


#/**
# Get the current list of PID:TID keys.
#
# @return 	a list of currently active PID:TID keys from the Devel::RingBuffer
#*/
sub getPIDTIDs {
	my $self = shift;
	return sort keys %{$self->{_map}};
}

1;