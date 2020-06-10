#########################################################################################
# Package        HiPi::Energenie::ENER314
# Description  : Control Energenie ENER314 board
# Copyright    : Copyright (c) 2016-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Energenie::ENER314;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use Carp;
use HiPi qw( :rpi :energenie );
use HiPi::GPIO;
use Time::HiRes;

__PACKAGE__->create_accessors( qw( device signal_d0_pin signal_d1_pin signal_d2_pin signal_d3_pin
                                   mode_select_pin mode_enable_pin ) );

our $VERSION ='0.81';

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        signal_d0_pin   => RPI_PIN_11,
        signal_d1_pin   => RPI_PIN_15,
        signal_d2_pin   => RPI_PIN_16,
        signal_d3_pin   => RPI_PIN_13,
        mode_select_pin => RPI_PIN_18,
        mode_enable_pin => RPI_PIN_22,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        $params{device} = HiPi::GPIO->new;
    }
    
    my $self = $class->SUPER::new(%params);
    
    # setup defaults
    $self->_init();
    
    return $self;
}

sub _init {
    my $self = shift;
    
    $self->device->set_pin_mode( $self->mode_enable_pin, RPI_MODE_OUTPUT  );
    $self->device->set_pin_level( $self->mode_enable_pin, RPI_LOW  );
    
    $self->device->set_pin_mode( $self->mode_select_pin, RPI_MODE_OUTPUT  );
    $self->device->set_pin_level( $self->mode_select_pin, RPI_LOW  );
    
    $self->device->set_pin_mode( $self->signal_d0_pin, RPI_MODE_OUTPUT  );
    $self->device->set_pin_level( $self->signal_d0_pin, RPI_LOW  );
    
    $self->device->set_pin_mode( $self->signal_d1_pin, RPI_MODE_OUTPUT  );
    $self->device->set_pin_level( $self->signal_d1_pin, RPI_LOW  );
    
    $self->device->set_pin_mode( $self->signal_d2_pin, RPI_MODE_OUTPUT  );
    $self->device->set_pin_level( $self->signal_d2_pin, RPI_LOW  );
    
    $self->device->set_pin_mode( $self->signal_d3_pin, RPI_MODE_OUTPUT  );
    $self->device->set_pin_level( $self->signal_d3_pin, RPI_LOW  );

}

sub send_gpio_message {
    my($self, $data ) = @_;
    $self->device->set_pin_level( $self->mode_enable_pin, RPI_LOW  );
    
    $self->device->set_pin_level( $self->signal_d0_pin, ( $data & 8 ) ? 1 : 0  );
    $self->device->set_pin_level( $self->signal_d1_pin, ( $data & 4 ) ? 1 : 0  );
    $self->device->set_pin_level( $self->signal_d2_pin, ( $data & 2 ) ? 1 : 0  );
    $self->device->set_pin_level( $self->signal_d3_pin, ( $data & 1 ) ? 1 : 0  );
    
    Time::HiRes::sleep( 0.1 );
    $self->device->set_pin_level( $self->mode_enable_pin, RPI_HIGH  );
    Time::HiRes::sleep( 1.0 );
    $self->device->set_pin_level( $self->mode_enable_pin, RPI_LOW  );
    return;
}

#-------------------------------------------------------
# Common OOK switch handler
#-------------------------------------------------------

sub switch_ook_socket {
    my($self, $groupid, $data, $repeat) = @_;
    # $groupid is ignored as this board has a single hard coded id
    $self->send_gpio_message( $data );
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
    $self->device( undef );
} 

1;

__END__