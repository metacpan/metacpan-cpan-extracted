#########################################################################################
# Package        HiPi::Device::SPI
# Description:   Wrapper for SPI communucation
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device::SPI;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Device );
use IO::File;
use Fcntl;
use XSLoader;
use Carp;
use HiPi qw( :rpi :spi );

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw ( fh fno delay speed bitsperword ) );

XSLoader::load('HiPi::Device::SPI', $VERSION) if HiPi::is_raspberry_pi();

sub get_required_module_options {
    my $moduleoptions = [
        [ qw( spi_bcm2708 spidev ) ],  # older spi modules
        [ qw( spi_bcm2385 ) ],         # recent spi modules
    ];
    return $moduleoptions;
}

sub get_device_list {
    # get the devicelist
    opendir my $dh, '/dev' or croak qq(Failed to open dev : $!);
    my @spidevs = grep { $_ =~ /^spidev\d+\.\d+$/ } readdir $dh;
    closedir($dh);
    for (my $i = 0; $i < @spidevs; $i++) {
        $spidevs[$i] = '/dev/' . $spidevs[$i];
    }
    return @spidevs;
}

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1(),
        bitsperword  => 8,
        delay        => 0,
    );
    
    foreach my $key( sort keys( %params ) ) {
        $params{$key} = $userparams{$key} if exists($userparams{$key});
    }
    
    my $fh = IO::File->new(
        $params{devicename}, O_RDWR, 0
    ) or croak qq(open error on $params{devicename}: $!\n);
    
    
    $params{fh}  = $fh;
    $params{fno} = $fh->fileno(),
     
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub transfer {
    my($self, $buffer) = @_;
   
    my $rval = HiPi::Device::SPI::_transfer_data(
        $self->fno, $buffer, $self->delay, $self->speed, $self->bitsperword
    );
    
    if( !defined( $rval ) ) {
        croak('SPI transfer failed');
    }
    
    return $rval;
}

sub transfer_byte_array {
    my( $self, @bytes) = @_;
    my $packcount = scalar( @bytes );
    my $packfmt = 'C' . $packcount;
    my @resultarray = unpack($packfmt, $self->transfer( pack($packfmt, @bytes) ) );
    return @resultarray;
}

sub bus_transfer {
    my $self = shift;
    return $self->transfer( @_ ); 
}

sub set_bus_mode {
    my($self, $mode) = @_;
    return HiPi::Device::SPI::_set_spi_mode($self->fno, $mode);
}

sub get_bus_mode {
    my($self) = @_;
    return HiPi::Device::SPI::_get_spi_mode($self->fno);
}

sub set_bus_maxspeed {
    my($self, $speed) = @_;
    return HiPi::Device::SPI::_set_spi_max_speed($self->fno, $speed);
}

sub get_bus_maxspeed {
    my($self, $speed) = @_;
    return HiPi::Device::SPI::_get_spi_max_speed($self->fno);
}

sub set_transfer_bitsperword { shift->bitsperword( @_ ); }
sub get_transfer_bitsperword { shift->bitsperword(); }

sub set_transfer_speed { shift->speed( @_ ); }
sub get_transfer_speed { shift->speed(); }

sub set_transfer_delay { shift->delay( @_ ); }
sub get_transfer_delay { shift->delay(); }

sub close {
    my $self = shift;
    if( $self->fh ) {
        $self->fh->flush;
        $self->fh->close;
        $self->fh( undef );
        $self->fno( undef );
        $self->devicename( undef );
    }
}

1;

__END__
