#########################################################################################
# Package        HiPi::Device::SerialPort
# Description:   Serial Port driver
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device::SerialPort;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Device );
use Carp;
use Try::Tiny;
require Device::SerialPort if $^O =~ /^linux$/i;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( portopen baudrate parity stopbits databits serialdriver ) );

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        # standard device
        devicename      => '/dev/ttyAMA0',
        
        # serial port
        baudrate        => 9600,
        parity          => 'none',
        stopbits        => 1,
        databits        => 8,
        
        # this
        serialdriver    => undef,
        portopen        => 0,
        
    );
    
    # get user params
    foreach my $key( keys (%params) ) {
        $params{$key} = $userparams{$key} if exists($userparams{$key});
    }
    
    # warn user about unsupported params
    foreach my $key( keys (%userparams) ) {
        carp(qq(unknown parameter name ) . $key) if not exists($params{$key});
    }
    
    my $driver = Device::SerialPort->new( $params{devicename} ) or
        croak qq(unable to open device $params{devicename});
    
    try {
        $driver->baudrate($params{baudrate});
        $driver->parity($params{parity});
        $driver->stopbits($params{stopbits});
        $driver->databits($params{databits});
        $driver->handshake('none');
        $driver->write_settings;
    } catch {
        croak(qq(failed to set serial port params : $_) );
    };
    
    $params{serialdriver}   = $driver;
    $params{portopen} = 1;
    
    my $self = $class->SUPER::new( %params ) ;
    
    return $self;
}

sub write {
    my($self, $buffer) = @_;
    return unless $self->portopen;
    my $result = $self->serialdriver->write($buffer);
    $self->serialdriver->write_drain;
    return $result;
}

sub can_read {
    my $self = shift;
}

sub read {
    my($self, $timeout) = @_;
    $timeout ||= 0;
}

sub close {
    return unless $_[0]->portopen;
    $_[0]->portopen( 0 );
    $_[0]->serialdriver->close or croak q(failed to close serial port);
    $_[0]->serialdriver( undef );                  
}

1;

__END__
