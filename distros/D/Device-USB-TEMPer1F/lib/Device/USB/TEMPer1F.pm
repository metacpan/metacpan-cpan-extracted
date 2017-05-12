
# USB Dongle TEMPer1F
# The Dongle has Vendor ID 0x0C45 and Product ID 0x7401

package Device::USB::TEMPer1F;

our $VERSION = '0.04';

use 5.008008;
use strict;
use warnings;
use Device::USB;

sub new{
    my $class = shift;

    # Basic Configuration 
    my %cfg = (
        vid => 0x0C45, # Vendor ID
        pid => 0x7401, # Product ID
        tim => 500,    # Timeout
        epi => 0x82,   # Endoint in
    );

    my $self = bless{ 
        cfg => \%cfg,
        buffer => 0
    }, $class;
    
    # There are two devices!
    # Need the device for: 
    # bInterfaceProtocol = 2
    #       and
    # bInterfaceNumber = 1
    return eval{
        my $usb = Device::USB->new;
        my $device = undef;
        foreach my $d( $usb->list_devices ){
            next if $d->idVendor  != $cfg{vid};
            next if $d->idProduct != $cfg{pid};

            foreach my $cfg( $d->config ){
                foreach my $ifs( $cfg->interfaces ){
                    foreach my $if( @$ifs ){
                        if( $if->bInterfaceNumber == 1 ){
                            $device = $d;
                            last;
                        }
                    }
                }
            }        
        }

        die "Device TEMPer1F not found!\n" unless $device;
        $device->open() or die "Can not open the device TEMPer1F!\n";
        0 == $device->set_configuration(1) ||
            die "Cannot set configuration for device TEMPer1F!\n";
        0 == $device->claim_interface(1) ||
            die "Cannot claim interface 1 for device TEMPer1F!\n";

        $self->{device} = $device;
        $self;
    }
}

# fetch temperature in °C #################################################
sub fetch{
    my $self = shift;
    if(! ref $self ){
        $self = __PACKAGE__->new or die $@;
    }
    
    $self->_control();
    8 == $self->{device}->interrupt_read(
        $self->{cfg}{epi},
        $self->{buffer},
        8,
        $self->{cfg}{tim}
    ) || die "Cannot read the the temperature!\n";

    my $r = [unpack "C8", $self->{buffer}];
    return sprintf "%0.2f", $r->[4] + $r->[5]/256;
}

############################ private methods ##############################
# set up a control message
sub _control{
    my $self = shift;
    my $buffer = pack("C8", 0x1,0x80,0x33,0x1,0x0,0x0,0x0,0x0);
    my $check = $self->{device}->control_msg(
        0x21,
        0x09,
        0x0200,
        0x01,
        $buffer,
        8,
        $self->{cfg}{tim}
    );
    die "Cannot setup a control_message!\n" if $check != 8;
}

1;#########################################################################


# my $temper = Device::USB::TEMPer1F->new or die $@;
# print $temper->fetch;


__END__

=head1 NAME

Device::USB::TEMPer1F - Perl extension for USB PCSensor TEMPer1F

=head1 SYNOPSIS

  use Device::USB::TEMPer1F;

  Either
  my $temper = Device::USB::TEMPer1F->new or die $@;
  print $temper->fetch; # 23.50

  Or
  print Device::USB::TEMPer1F->fetch;
  

=head1 DESCRIPTION

    This device must be configured for using libusb.

=head2 METHODS

    The API is very easy and has two methods only, as you can see below.
    
=head3 CONSTRUCTOR

  my $temper = Device::USB::TEMPer1F->new 
   or die $@;

  If the device was not found or other errors occurred, new() throws an exception and $@ contains the corresponding message.
  
=head3 FETCH

  The fetch() method returns the temperature in degrees celsius.

=head1 SEE ALSO

  libusb  
  Device::USB
  ppm install http://rolfrost.de/Device-USB.ppd
  ppm install http://rolfrost.de/Device-USB-PX1674.ppd
  ppm install http://rolfrost.de/Device-USB-TEMPer1F.ppd

=head1 AUTHOR

Rolf Rost, E<lt>pilgrim@rolfrost.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rolf Rost

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
