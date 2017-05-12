package Device::ParallelPort::drv;
use Carp;

=head1 NAME

Device::ParallelPort::drv - Standard pacakge to be imported by all drivers

=head1 SYNOPSIS

(Not Applicable) - do not use this directly, use another driver

	* Device::ParallelPort::drv::auto
	* Device::ParallelPort::drv::linux
	* Device::ParallelPort::drv::parport
	* Device::ParallelPort::drv::win32

=head1 DESCRIPTION

This driver is the base class recommended for all Parallel Port Drivers.
It is not useful in itself. Although against proper OO
design, this particular module does not work by itself.

=head1 METHODS

=head2 new

=head2 get_bit

=head2 get_byte

=head2 set_bit

=head2 set_byte

=head1 NOTES

=head2 Device Names

A special system of device names has been deviced.
Basically we are trying to be compatible with most systems, and not force
people to learn something new.

You can enter parallel port device in a number of ways

	- N	Unix style, where 0 is the first port
	- lptN	Windows style, where 1 is the first port
	- 0xNNN	Direct hardware location

This is totally dependent on the driver being used.  
For example the script driver would not use these but the auto driver does.

Now these are not necessarily supported in all operating systems. By default
this base driver converts lpt notation into lp notation, it then optionally
converts all lp notation into a hardware location. However what would not work
for parport control, which is generally done as parport device, mapping the
same number as the lp above (check that?), in that case passing the direct
hardware location is pointless.

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

# Some constants that are useful 
sub BASE_0 { 0x378; }		# Intel x86 Base Port
sub OFFSET_DATA { 0; }
sub OFFSET_STATUS { 1; }
sub OFFSET_CONTROL { 2; }

sub new {
	my ($class, $str, @params) = @_;
	my $this = bless {}, ref($class) || $class;
	$this->init($str, @params) if ($this->can('init'));
	return $this;
}

# ------------------------------------------------------------------------------
# BIT -> BYTE and BYTE -> BIT Autoamtic Support
# ------------------------------------------------------------------------------
# This seciton basically provides
sub get_bit {
	my ($this, $bit) = @_;
	unless ($this->INFO->{type} eq "byte") { croak "Unsupported in this driver"; }
	# Find the byte
	my $byte = int($bit / 8);
	$bit = $bit - ($byte * 8);
	return _bit_from_byte($this->get_byte($byte), $bit);
}

sub _bit_from_byte {
	my ($byte, $bit) = @_;
	return ((ord($byte) & (1 << $bit)) == (1 << $bit)) ? 1 : 0;
}

sub get_byte {
	my ($this, $byte) = @_;
	unless ($this->INFO->{type} eq "bit") { croak "Unsupported in this driver"; }
	my $ret = 0;
	my $first_bit = ($byte * 8);
	for (my $bit = $first_bit; $bit < ($first_bit + 8); $bit++) {
		if ($this->get_bit($bit)) {
			$ret = $ret + (1 << ($bit - ($byte * 8)));
		}
	}
	return chr($ret);
}

sub get_byte_uninvert {
	my ($this, $byte) = @_;
	return $this->uninvert($byte, $this->get_byte($byte));
}

sub set_byte_uninvert {
	my ($this, $byte, $val) = @_;
	return $this->set_byte($byte, $this->uninvert($byte, $val));
}

sub set_bit {
	my ($this, $bit, $val) = @_;
	unless ($this->INFO->{type} eq "byte") { croak "Unsupported in this driver"; }
	my $byte = int($bit / 8);
	$bit = $bit - ($byte * 8);
	my $current = $this->get_byte($byte);
	if (defined($current)) {
		$current = ord($current);
	} else {
		$current = 0;
	}
	if ($val) {
		$current = $current | (1 << $bit);
	} else {
		$current = $current & (~ (1 << $bit));
	}
	$this->set_byte($byte, chr($current));
}

sub set_byte {
	my ($this, $byte, $val) = @_;
	unless ($this->INFO->{type} eq "bit") { croak "Unsupported in this driver"; }
	for(my $i = 0; $i < 8; $i++) {
		$this->set_bit(
			$i + ($byte * 8),
			_bit_from_byte($val, $i),
		);
	}
}

# Shortcuts for those who want data, control and status for standard parallel
# ports seprarately.

sub get_data {
	my ($this) = @_;
	return $this->get_byte($this->OFFSET_DATA);
}

sub get_control {
	my ($this) = @_;
	return $this->get_byte($this->OFFSET_CONTROL);
}

sub get_status {
	my ($this) = @_;
	return $this->get_byte($this->OFFSET_STATUS);
}

sub set_data {
	my ($this, $val) = @_;
	return $this->set_byte($this->OFFSET_DATA, $val);
}

sub set_control {
	my ($this, $val) = @_;
	return $this->set_byte($this->OFFSET_CONTROL, $val);
}

sub set_status {
	my ($this, $val) = @_;
	return $this->set_byte($this->OFFSET_STATUS, $val);
}

# HELPER METHODS

# TODO - Real byte converter - CHAR from Number
# Convert an integer to a real byte - just in case someone has passed in a
# number instead of a byte.
#sub real_byte {
#	my ($this, $val) = @_;
#	return $val;
#}

# TODO - Invert / Uninverter - Just swaps bits
# Convert all inverted bits back to normal
#sub uninvert {
#	my ($this, $byte, $val, $bits) = @_;
#	if ($byte == 0) {	# BYTE
#		$bits ||= [];
#	} elsif ($byte == 1) {	# STATUS
#		$bits ||= [qw/7/];
#	} elsif ($byte == 2) {	# STATUS
#		$bits ||= [qw/0 1 3/];
#	}
#	my $ret = $val;
#	foreach my $bit (@$bits) {
#		# XXX XOR Bit here
#	}
#}

# ADDRESS METHODS

sub address_to_num {
	my ($this, $address) = @_;
	if (($address * 1) == $address) {
		return $address;
	} elsif ($address =~/^lpt(\d)$/) {
		return $1 - 1;
	} else {
		croak "Unable to convert $address to something meaninful to Device::ParallelPort - try 0..9 or lpt1..lpt9";
	}
}

sub num_to_hardware {
	my ($this, $num) = @_;
	if ($num == 0) {
		return 0x378;
	} elsif ($num == 1) {
		return 0x278;
	} else {
		croak "No known lookup for hardware address $num to Device::ParallelPort - Try 0..1";
	}
}

1;
