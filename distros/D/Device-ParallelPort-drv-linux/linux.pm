package Device::ParallelPort::drv::linux;

use strict;
use warnings;
use Errno;
use Carp;

our $VERSION = '1.00';

require DynaLoader;
use Device::ParallelPort::drv;
our @ISA = qw(DynaLoader Device::ParallelPort::drv);

# bootstrap Device::ParallelPort::drv::linux $VERSION;
bootstrap Device::ParallelPort::drv::linux;

=head1 NAME

Device::ParallelPort::drv::linux - Standard linux hardware io access

=head1 DESCRIPTION

This is a basic driver that access the parallel port directly via standard io.
This of course means that this script must be run as root (or setuid and all
that involves).

=head1 CAPABILITIES

=head2 Operating System

Linux

=head2 Special Requirements

You must be root to run this code. 

=head1 HOW IT WORKS

This code uses a c portion that compiles in a assembler macro to read and write
(via the kernel) to the address directly.

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

sub INFO {
	return {
		'os' => 'linux',
		'ver' => 'any',
		'type' => 'byte',
	};
}

sub init {
	my ($this, $str, @params) = @_;
	$this->{DATA}{BASE} = linux_opendev($this->{DATA}{DEVICE});
	unless ($this->{DATA}{BASE} > 1) {
		croak "Failed to load partport driver for " . $this->{DATA}{DEVICE};
	}
}

sub set_byte {
	my ($this, $byte, $val) = @_;
	_testbyte($byte);
	linux_write($this->{DATA}{BASE}, $byte, $val);
}

sub get_byte {
	my ($this, $byte, $val) = @_;
	_testbyte($byte);
	return linux_read($this->{DATA}{BASE}, $byte);
}

sub _testbyte {
	my ($byte) = @_;
	if ($byte < 0 || $byte > 2) {
		croak "drv:linux supports only byte 0,1 and 2";
	}
}

1;

