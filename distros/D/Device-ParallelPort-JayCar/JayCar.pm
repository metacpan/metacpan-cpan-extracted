package Device::ParallelPort::JayCar;
use strict;
use Carp;
use Device::ParallelPort;
our $VERSION = "0.04";


# XXX NOTE - Temporary version with DUMB mappings...
#
# 
# Card =
#       8 - $card

# C3    C2      C1      C0      Card ID         Number
#
# 1     0       1               1               10
# 1     0       0               2               8
# 1     1       1               3               14
# 1     1       0               4               12
# 0     0       1               5               2
# 0     0       0               6               0
# 0     1       1               7               6
# 0     1       0               8               4
#
# Logic =
#       Card shift left

my %cardmap = (
	0 => 10,
	1 => 8,
	2 => 14,
	3 => 12,
	4 => 2,
	5 => 0,
	6 => 6,
	7 => 4,
);

=head1 NAME

Device::ParallelPort::JayCarXXX - Jaycar controlling device.

XXX This is all wrong - need to update...

=head1 SYNOPSIS

This is an example driver for a fairly common (in Australia anyway) parallel
port controller card. It can be used for real, but has been written in an easy
to read manner to allow it to be a base class for future drivers.

=head1 DESCRIPTION

To come.

=head1 NOTE ON NAMING

A note on class locations. If you are writting a general controller, eg: for a
high speed neon sign controller. Then you would always write that in its own
class (see CPAN for the best base class to put that in). Thats because more
than likely the sign supports multiple protocols such as Parallel, RS485, USB
and more. Then the propert place would be:

	SomeBaseClass::MySign::drv::ParallelPort

or simular. When you write a network class that talks TCPIP only for that sign,
you do not put it in the Net:: location, same for parallel port.

=head1 NOTE ON INHERITENCE

Should examples such

=head1 QUESTIONS

How to handle errors, when writting to the port?

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

# How many relays (allows you to sub class and add more)
# (max Jaycar ID = 8, max relays = 8)
sub RELAYS { 8 * 8 };

# Need: Parallel Port and Board ID
# Return: Object
sub new {
	my ($class, $parport, $boards) = @_;
	my $this = bless {}, ref($class) || $class;
	$boards = [1, 2];
	$this->init($parport, $boards);
	return $this;
}

sub init {
	my ($this, $parport, $boards) = @_;
	if (ref($parport)) {
		$this->{PARPORT} = $parport;
	} elsif (defined($parport)) {
		$this->{PARPORT} = Device::ParallelPort->new($parport)
			or croak("Unable to create ParPort Device");
	} else {
		croak "Invalid parport provided";
	}

	# Store array of boards activated (ie: only update those boards)
	$this->{BOARDS} = ref($boards) eq "ARRAY" ? $boards : [$boards];

	$this->{RELAYS} = [];
	for (my $i = 0; $i < $this->RELAYS(); $i++) {
		$this->{RELAYS}[$i] = 0;
	}
}

sub _parport {
	my ($this) = @_;
	return $this->{PARPORT};
}

# Need: Relay Number (0-7)
# Return: True/False
# How: Must remember, can not get it from the board.
sub get {
	my ($this, $id) = @_;
	$this->_checkid($id);
	return $this->{RELAYS}[$id];
}

sub _checkid {
	my ($this, $id) = @_;
	if ($id < 0 || $id >= $this->RELAYS) {
		croak "Invalid relay id specified - $id";
	}
}

# Need: Ralay Number (0-7) (optionally delay update)
# Return: NA
# How: Update memory map bit, set whole byte, flash with Board ID
sub on {
	my ($this, $id, $delay) = @_;
	$this->_checkid($id);
	$this->{RELAY}[$id] = 1;
	$this->update unless ($delay);
}

# See relay_on
sub off {
	my ($this, $id, $delay) = @_;
	$this->_checkid($id);
	$this->{RELAY}[$id] = 0;
	$this->update unless ($delay);
}

# Update the device.
# Need: NA
# Return: NA
# How: Use parport to update byte and then flash it.
sub update {
	my ($this) = @_;

	foreach my $board (@{$this->{BOARDS}}) {
		$this->_parport->set_byte(2, chr($cardmap{$board}));		# Prepare
		$this->_parport->set_byte(0, chr($this->_byte_calc($board)));	# Set data
		$this->_parport->set_byte(2, chr($cardmap{$board} + 1));	# Flash bit 1 (strobe)
		$this->_parport->set_byte(2, chr($cardmap{$board}));		# Undo flash/strobe
	}
}

# Add bits together and return as integer.
# Need: NA (uses stored data)
# Return: Integer representing byte
# How: Add bits together as a byte (only those turned on)
sub _byte_calc {
        my ($this, $board) = @_;
        my $ret = 0;
        for (my $i = 0; $i < 8; $i++) {
		if ($this->{RELAY}[$i + ($board * 8)]) {
			$ret = $ret + (1 << $i);
		}
        }
        return $ret;
}

1;
