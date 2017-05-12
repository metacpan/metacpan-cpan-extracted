package Device::ParallelPort::Printer;
use strict;
use Carp;
use Device::ParallelPort;
use IO::File;

# XXX 1.0 - Make this work and test with simple printer.

=head1 NAME

Device::ParallelPort::Printer - Emulate a normal old style printer using Device::ParallelPort

=head1 SYNOPSIS

	use Device::ParallelPort::Printer;
	my $printer = Device::ParallelPort::Printer->new('parport:0');
	$printer->sendfile('demo.ps');

=head1 DESCRIPTION

This is a demonstration only and does not have any real practical application.
It has been written as a demonstration on how to write drivers for
Device::ParallelPort.

Device::ParallelPort provides a raw interface to the parallel port. Printers
actually expect a certain way of getting data. That is the Centronix Parallel
Port Protocol. 

Basically you set a byte you want to send to the printer on the first byte of
the parallel device. You then raise and lower a pin on the control byte (3rd I
think ???) which tells the printer to retrieve the data you put on the first
byte.

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

sub new {
	my ($class, $parport) = @_;
	my $this = bless {}, ref($class) || $class;
	$this->{PP} = Device::ParallelPort->new($parport)
		or croak("Unable to create device - $parport");
	return $this;
}

sub sendfile {
}

sub _data {
	my ($this, $data) = @_;
	$this->_pp->set_data($data);
}

# XXX Does there need to be any delay here ?
sub _flash {
	my ($this) = @_;
	$this->_pp->set_bit(8 * 2, 1);
	$this->_pp->set_bit(8 * 2, 0);
}

sub _pp { return $_[0]->{PP}; }

1;
