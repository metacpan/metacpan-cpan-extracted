=pod

=begin classdoc


Provides a configurable I/O selector that permits
distinguishing between read, write, and exception
selectors. Used within the HTTP::Daemon::Threaded::Socket object
to simplify the process of managing events on I/O handles.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2005-12-01
@self	$_[0]



=end classdoc

=cut
package HTTP::Daemon::Threaded::IOSelector;

use IO::Select;
use Time::HiRes qw(time);

use strict;
use warnings;

our $VERSION = '0.91';

use constant HTTPD_SELECT_RD => 1;
use constant HTTPD_SELECT_WR => 2;
use constant HTTPD_SELECT_EX => 4;

=pod

=begin classdoc

Constructor. Creates separate read, write, and exception
IO::Select objects.

@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub new {
	my ($class, $interval) = @_;
#
#	create 3 selectors: read, write, and exception,
#	and accepts a static timeout to use for all
#	select() ops
#
	my $readsel = IO::Select->new();
	my $writesel = IO::Select->new();
	my $exceptsel = IO::Select->new();
	return bless [ $readsel, $writesel, $exceptsel, $interval ], $class;
}

=pod

=begin classdoc

Add a HTTP::Daemon::Threaded::Socket object to the read selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub addRead {
	$_[0]->[0]->add($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Add a HTTP::Daemon::Threaded::Socket object to the write selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub addWrite {
	$_[0]->[1]->add($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Add a HTTP::Daemon::Threaded::Socket object to the exception selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub addExcept {
	$_[0]->[2]->add($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Add a HTTP::Daemon::Threaded::Socket object to the read and exception selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub addNoWrite {
	$_[0]->[0]->add($_[1]);
	$_[0]->[2]->add($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Add a HTTP::Daemon::Threaded::Socket object to the all selectors.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub addAll {
	$_[0]->[0]->add($_[1]);
	$_[0]->[1]->add($_[1]);
	$_[0]->[2]->add($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Remove a HTTP::Daemon::Threaded::Socket object from the read selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub removeRead {
	$_[0]->[0]->remove($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Remove a HTTP::Daemon::Threaded::Socket object from the write selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub removeWrite {
	$_[0]->[1]->remove($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Remove a HTTP::Daemon::Threaded::Socket object from the exception selector.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub removeExcept {
	$_[0]->[2]->remove($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Remove a HTTP::Daemon::Threaded::Socket object from the read and exception selectors.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub removeNoWrite {
	$_[0]->[0]->remove($_[1]);
	$_[0]->[2]->remove($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Remove a HTTP::Daemon::Threaded::Socket object from all the selectors.

@param $fd	a HTTP::Daemon::Threaded::Socket
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub removeAll {

#	my @frame = caller(1);

#	print STDERR 'IOSelector removing for ',
#		join('', $frame[3], ':', $frame[2]), "\n";

	$_[0]->[0]->remove($_[1]);
	$_[0]->[1]->remove($_[1]);
	$_[0]->[2]->remove($_[1]);
	return $_[0];
}

=pod

=begin classdoc

Return the read selector.

@return		IO::Select object


=end classdoc

=cut
sub getRead { return $_[0]->[0]; }

=pod

=begin classdoc

Return the write selector.

@return		IO::Select object


=end classdoc

=cut
sub getWrite { return $_[0]->[1]; }

=pod

=begin classdoc

Return the exception selector.

@return		IO::Select object


=end classdoc

=cut
sub getExcept { return $_[0]->[2]; }

=pod

=begin classdoc

Return all selectors.

@returnlist		read, write, exception IO::Select objects


=end classdoc

=cut
sub getAll { return ( @{$_[0]} ); }

=pod

=begin classdoc

Set the select() timeout

@param $timeout	number of seconds to select()
@return		HTTP::Daemon::Threaded::IOSelector object


=end classdoc

=cut
sub setTimeout { $_[0]->[3] = $_[1]; return $_[0]; }

=pod

=begin classdoc

Return the current select() timeout value

@return		timeout value


=end classdoc

=cut
sub getTimeout { return $_[0]->[3] = $_[1]; }

=pod

=begin classdoc

Wait up to the configured timeout for an event on any of
the HTTP::Daemon::Threaded::Socket objects installed in any of the read, write,
or exception IO::Select objects. When events are detected,
the handleSocketEvent() method on the HTTP::Daemon::Threaded::Socket object
is called, with a bit mask indicating which of the events was
detected.

@return		elapsed time in the function, in seconds


=end classdoc

=cut
sub select {
	my $obj = shift;

	my $start = time();
	$! = undef;
	my ($read, $write, $except) = IO::Select->select(
		$obj->[0],
		$obj->[1],
		$obj->[2],
		$obj->[3] );

	if ($! ne '') {
		print STDERR "select() failure: $!\n";
		print STDERR join("\n",
			$obj->[0]->as_string(),
			$obj->[1]->as_string(),
			$obj->[2]->as_string()), "\n";
	}
#
#	returns undef if no events
#
	return time() - $start
		unless $read;

#	print STDERR "IO::Select failed after ", time() - $start, " secs:\n",
#		join("\n", $obj->[0]->as_string(), $obj->[1]->as_string(), $obj->[2]->as_string()),
#		"\n";
#
#	consolidate selected objects, with a flag indicating which
#	events they have
#
	my %ready = ();
	my %ready_flags = ();

	$ready_flags{$_} = HTTPD_SELECT_RD,
	$ready{$_} = $_
		foreach (@$read);

	$ready_flags{$_} |= HTTPD_SELECT_WR,
	$ready{$_} = $_
		foreach (@$write);

	$ready_flags{$_} |= HTTPD_SELECT_EX,
	$ready{$_} = $_
		foreach (@$except);

	$ready{$_}->handleSocketEvent($ready_flags{$_}) foreach (keys %ready);
#
#	returns the time spent here..
#
	return time() - $start;
}
