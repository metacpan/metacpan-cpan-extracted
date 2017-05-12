package Device::USB::PanicButton;

use 5.008008;
use strict;
use warnings;
use Device::USB;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.04';

my $VENDOR_ID = 0x1130;
my $PRODUCT_ID = 0x0202;
my $CONFIG_NO = 1;
my $INTERFACE_NO = 0;
my $INTERFACES_NUM = 2;

my $REQTYPE = 0xA1;
my $REQ = 0x1;
my $VAL = 0x300;
my $GET_SIZE = 8;
my $TIMEOUT = 500;

sub new {
	my $class = shift;
	my $self = {};

	$self->{'error'} = undef;
	$self->{'dev'} = undef;

	bless($self, $class);

	my $usb = Device::USB->new();

	my $dev = $usb->find_device( $VENDOR_ID, $PRODUCT_ID );
	if(!$dev) {
		$self->_set_error("USB Panic Button not found. Connected?");
		return $self;
	}

	if($< != 0) {
		$self->_set_error("You have to be root to connect to USB Panic Button.");
		return $self;
	}

	for(my $interface = 0; $interface < $INTERFACES_NUM; $interface++) {
		my $kdrv = $dev->get_driver_np($interface);
		if($kdrv) {
                	if($dev->detach_kernel_driver_np($interface) < 0) {
                        	$self->_set_error("Cannot detach kernel driver '$kdrv'.");
				return $self;	
               		}
        	}
 	}

	if(!$dev->open()) {
		$self->_set_error("Error opening USB device: $!");
		return $self;
	}	

	if($dev->set_configuration($CONFIG_NO) < 0) {
		$self->_set_error("Error setting configuration no. $CONFIG_NO: $!.");
		return $self;	
	}
	if($dev->claim_interface($INTERFACE_NO) < 0) {
		$self->_set_error("Error claiming interface no. $INTERFACE_NO: $!.");
		return $self;	
	}

	$self->{dev} = $dev;
	return $self;
}

sub error {
	my $self = shift;
	return $self->{'error'};
}

sub pressed {
	my $self = shift;
	my $data = 0;

	if(!$self->{'dev'}) {
		$self->_set_error("USB device object not initialisied.");
		return -1;
	}
	$self->_reset_error();

	my $count = $self->{'dev'}->control_msg($REQTYPE, $REQ, $VAL, 0, $data, $GET_SIZE, $TIMEOUT);

	if($count < 0) {
		$self->_set_error("Error reading device: $!.");
		return -1;
	} elsif ($count != 8) {
		$self->_set_error("Error reading device: unknown answer!");
		return -1;
	} else {
       		if(ord(substr($data, 0, 1)) == 0x1) {
			return 1;
		}
        }

	return 0;
}

sub _set_error {
	my $self = shift;
	$self->{'error'} = shift;
}

sub _reset_error {
	my $self = shift;
	$self->{'error'} = undef;
}

sub DESTROY {
	my $self = shift;

	if($self->{'dev'}) {
		$self->{'dev'}->release_interface($INTERFACE_NO);
		#$self->{'dev'}->close();
	}
}

1;

=head1 NAME

Device::USB::PanicButton - interface to USB Panic Button

=head1 SYNOPSIS

    use Device::USB::PanicButton;

    my $pbutton = Device::USB::PanicButton->new();

    if(!$pbutton || $pbutton->error()) {
        printf(STDERR "FATAL: ". $pbutton->error() ."\n");
        exit(-1);
    }

    while(1) {
        my $result = $pbutton->pressed();

        if($result == 1) {
            printf("PANIC ;)\n");
        } elsif($result < 0) {
            printf(STDERR "WARN: ". $pbutton->error() ."\n");
        }	

	sleep(1);
    }

=head1 DESCRIPTION

This implements a basic interface to the toy USB Panic Button by reading out the button status.

http://www.firebox.com/product/1742/USB-Panic-Button

It has three methods - new(), error() and pressed(). 

new() returns always an object - you have to check for errors with error().

error() returns a scalar with an error message, if something hit an error.

pressed() returns:

   -1, if something went wrong during reading the device.
    0, if the button was not pressed.
    1, if the button was pressed since last read process.

=head1 REQUIREMENTS

   libusb -> http://libusb.sourceforge.net
   Device::USB -> http://search.cpan.org/search?query=Device-USB

=head1 MORE DOCUMENTATION

see README for complete install instruction for Debian Etch.

=head1 AUTHOR

Benjamin Kendinibilir <cpan at kendinibilir.de>

=head1 COPYRIGHT

Copyright (C) 2008 by Benjamin Kendinibilir. All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

Device::USB

=cut

