
# CMD-Class for Revolt USB Dongle PX-1674-675

package Device::USB::PX1674;

$VERSION = '1.04';

use strict;
use warnings;
use Device::USB;
use Carp;

sub new{
    my $class = shift;
    my %cfg = (
        vid  => 0xFFFF,   # Vendor ID
        pid  => 0x1122,   # Product ID
        ept  => 0x02,     # Endpoint Out
        addr => 0x1A1A,   # Hauscode
        intf => 0,        # Interface 
        cfg  => 1,        # Configuration
        verb => 0,        # Verbose 
    @_);
    my $self = bless{
        CMD   => {
            1     => { On => 0xF0, Off => 0xE0 },
            2     => { On => 0xD0, Off => 0xC0 },
            3     => { On => 0xB0, Off => 0xA0 },
            4     => { On => 0x90, Off => 0x80 },
            5     => { On => 0x70, Off => 0x60 },
            6     => { On => 0x50, Off => 0x40 },
            group => { On => 0x20, Off => 0x10 },
        },
        CFG => \%cfg,
    }, $class;

    eval{
        my $vid = sprintf "%04X", $cfg{vid};
        my $pid = sprintf "%04X", $cfg{pid};
        my $usb = Device::USB->new;
        
        my $dev = undef;
        foreach my $d( $usb->list_devices ){
            if( $d->idVendor == $cfg{vid} && $d->idProduct == $cfg{pid} ){
                $dev = $d;
                last;
            }
        }
        die "Device Vendor '$vid', Product '$pid' not found\n"
            unless $dev;
        $dev->open || die "Error open device!\n";
        
        if( $dev->set_configuration($cfg{cfg}) != 0 ){
            die "Can not set configuration!\n";
        }
        if( $dev->claim_interface($cfg{intf}) != 0 ){
            die "Can not claim interface\n";
        }
        
        $self->{usb_dev} = $dev;
        $self;
    };
}
# On|Off|switch
# Übergeben wird die Gerätenummer
# Ansonsten wird die Gruppe geschaltet
# __ANON__
my $OnOff = sub{
    my $self = shift;
    my $dest = shift;    
    my $devnr = shift || 'group';
    my $payload = $self->_payload($devnr, $dest);

    print join(" ", map{sprintf("%02X", $_)}unpack "C*", $payload) if $self->{CFG}{verb};
    return $self->{usb_dev}->bulk_write( $self->{CFG}{ept}, $payload, 8, 5000);
};
############################ Private ######################################
sub _payload{
    my $self  = shift;
    my $devnr = shift;
    my $dest  = shift;
    
    my $cmd = $self->{CMD}{$devnr}{$dest} || croak "CMD '$dest' for device '$devnr' not found!";
    my ($b1, $b2) = unpack "CC", pack "n", $self->{CFG}{addr};
    my $chk = 255 - ($b1 + $b2 + $cmd) % 256;
    return pack "C8", $b1,$b2,$cmd,$chk,0x20,0x0A,0x00,0x18;
}

# On || Off || switch über eine anonyme Funktion
sub AUTOLOAD{
    my $self = shift;
    my $name = our $AUTOLOAD =~ /::(\w+)$/ ? $1 : '';
    if( $name eq 'On' || $name eq 'Off' ){
        $self->$OnOff($name, @_);
    }
    elsif( $name eq 'switch'){
        $self->$OnOff(@_);
    }
    else{ die "Unbekannte Funktion: '$name'!\n" }
}
sub DESTROY{}
1;#########################################################################

#my $px = Device::USB::PX1674->new() or die $@;
#$px->Off;

__END__

=head1 NAME

Device::USB::PX1674 - Perl CMD-Class for Revolt USB Dongle PX-1674-675


=head1 SYNOPSIS

  use Device::USB::PX1674;
  my $usb = Device::USB->new;
  
  my $px = Device::USB::PX1674->new(
    addr    => 0x1A85, # inhouse code
    verb    => 1,      # verbose output, shown as hex-dump
  ) || die $@;

  # Set Device 1 to state on
  $px->On(1);  

  # Switch off entire group
  $px->switch('Off');
  
=head1 DESCRIPTION

The instance of this class sends commands to USB-Dongle for switching on/off a certain RF power socket. The USB-device using this API must be configured for using libusb. This dongle has the vendor-id 0xFFFF and product-id 0x1122 by factory.

For a certain inhouse code it is possible to switch up to 6 RF power sockets in one group.

The Perl-Library Device::USB must be installed and the Revolt USB-dongle PX-1674-675 must be configured for using libusb.

=head2 CONSTRUCTOR

Available options are:

  addr => 0x1A1A,   # Hauscode
  verb => 0,        # Verbose 

=head2 METHODS

  On();
    If argument omitted, On() is switching entire group of devices.
      
  Off();
    Similar to On(); 
  
  switch('On',3);
    Same as On, Off but now 'On' or 'Off' are arguments. Group-switching similar to methods above.

=head2 PPM Packages for Win32

  ppm install http://rolfrost.de/Device-USB.ppd
  ppm install http://rolfrost.de/Device-USB-PX1674.ppd

=head1 SEE ALSO

  Device::USB
  LibUSB
  LibUSB-Win32

=head1 AUTHOR

Rolf Rost, E<lt> pilgrim@rolfrost.de E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rolf Rost

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
