#########################################################################################
# Package        HiPi::Interface::HopeRF69::Dummy
# Description  : Dummy implementation of HiPi::Interface::HopeRF69
# Copyright    : Copyright (c) 2013-2023 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::HopeRF69::Dummy;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi qw( :rpi :spi :hrf69 );

__PACKAGE__->create_accessors( qw(
    devicename
    reset_gpio
    update_default_on_reset
    fsk_config
    ook_config
    ook_repeat
    high_power_module
    _dummy_buffer ) );

our $VERSION ='0.89';

# Hope recommended updated reset defaults
my $reset_defaults = [
    [ RF69_REG_LNA,           0x88 ],
    [ RF69_REG_RXBW,          0x55 ],
    [ RF69_REG_AFCBW,         0x8B ],
    [ RF69_REG_DIOMAPPING2,   0x07 ],
    [ RF69_REG_RSSITHRESH,    0xE4 ],
    [ RF69_REG_SYNCVALUE1,    0x01 ],
    [ RF69_REG_FIFOTHRESH,    0x8F ],
    [ RF69_REG_TESTDAGC,      0x30 ],
];

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.1',
        speed        => 8000000,  # 8 mhz
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        reset_gpio   => undef,
        update_default_on_reset => 1,
        ook_repeat   => 15,
        fsk_config   => [],
        
        ook_config   => [],
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    my $self = $class->SUPER::new(%params);
    
    # setup defaults
    $self->reset();
    
    $self->configure($self->fsk_config);
    
    return $self;
}

sub configure {
    my( $self, $config ) = @_;
    
    return;
}

sub change_mode {
    my($self, $mode, $waitmask) = @_;
    
    return;
}

sub set_mode_receiver {
    my $self = shift;
    
    return;
}

sub set_mode_transmitter {
    my $self = shift;
    
    return;
}

sub write_register {
    my( $self, @data ) = @_;
    
    return;
}

sub read_register {
    my( $self, $addr, $numbytes ) = @_;
    $numbytes ||= 1;
    my @data = ( 0 ) x $numbytes;
    
    return ( wantarray ) ? @data : $data[0];
}

sub write_fifo {
    shift->write_register( 0x0, @_ );
}

sub read_fifo {
    my $self = shift;
    return 0;
}

sub clear_fifo {
    my $self = shift;
	return;
}

sub reset {
    my $self = shift;
    return;
}

sub wait_for {
    my( $self, $addr, $mask, $true) = @_;
    return;
}


sub assert_register_value {
    my($self, $addr, $mask, $true, $desc) = @_;
    return;
}

sub send_message {
    my($self, $bytes) = @_;
    return unless(scalar( @$bytes ));
    $self->_dummy_buffer( [ @$bytes  ] );   
	return;
}

sub send_ook_message {
    my($self, $bytes, $repeat ) = @_;  
    return;
}

sub receive_message {
    my ( $self ) = @_;
    if ( $self->_dummy_buffer && ref( $self->_dummy_buffer ) eq 'ARRAY' ) {
        my $buffer = $self->_dummy_buffer;
        $self->_dummy_buffer( undef );
        return $buffer;
    } else {
        return undef;
    }
}

sub send_hipi_message {
    my ($self, $msg) =  @_;
    $msg->encode_buffer unless $msg->is_encoded;
    $self->send_message( $msg->databuffer );
}

sub receive_hipi_message {
    my ($self, $messageclass, $messageparams ) = @_;
        
    if( my $buffer = $self->receive_message ) {
        $messageparams->{databuffer} = $buffer;
        my $msg = $messageclass->new(
            %$messageparams
        );
        $msg->inspect_buffer;
        return $msg;
    }
    return undef;
}


1;

__END__
