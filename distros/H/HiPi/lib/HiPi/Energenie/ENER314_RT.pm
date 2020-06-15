#########################################################################################
# Package        HiPi::Energenie::ENER314_RT
# Description :  Control Energenie ENER314-RT board
# Copyright    : Copyright (c) 2016-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Energenie::ENER314_RT;

#########################################################################################

use strict;
use warnings;
use HiPi qw( :rpi :hrf69 :openthings :energenie );
use parent qw( HiPi::Class );
use Carp;
use Time::HiRes qw( usleep );
use HiPi::Interface::HopeRF69;
use HiPi::GPIO;
use HiPi::RF::OpenThings::Message;

__PACKAGE__->create_accessors( qw( device devicename led_green led_red 
                              led_on _green_pin _red_pin ook_repeat
                              backend default_config ook_config gpiodev rf_high_power ) );

our $VERSION ='0.82';

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        devicename     => '/dev/spidev0.1',
        backend        => 'spi',
        speed          => 9600000,  # 9.6 mhz
        bitsperword    => 8,
        delay          => 0,
        device         => undef,
        led_green      => RPI_PIN_13,
        led_red        => RPI_PIN_15,
        led_on         => 1,
        reset_gpio     => RPI_PIN_22,
        oo_repeat     => ENERGENIE_TXOOK_REPEAT_RATE,
        gpiodev        => HiPi::GPIO->new,
        default_config => [
            [ RF69_REG_REGDATAMODUL,  0x00 ],   # modulation scheme FSK
            [ RF69_REG_FDEVMSB, 	  0x01 ],   # frequency deviation 5kHz 0x0052 -> 30kHz 0x01EC
            [ RF69_REG_FDEVLSB, 	  0xEC ],   # frequency deviation 5kHz 0x0052 -> 30kHz 0x01EC
            [ RF69_REG_FRMSB, 		  0x6C ],   # carrier freq -> 434.3MHz 0x6C9333
            [ RF69_REG_FRMID, 		  0x93 ],   # carrier freq -> 434.3MHz 0x6C9333
            [ RF69_REG_FRLSB, 		  0x33 ],   # carrier freq -> 434.3MHz 0x6C9333
            [ RF69_REG_AFCCTRL,       0x00 ],   # standard AFC routine
            [ RF69_REG_PREAMBLEMSB,   0x00 ],   # 3 byte preamble
            [ RF69_REG_PREAMBLELSB,   0x03 ],   # 3 byte preamble
            [ RF69_REG_LNA, 		  0x08 ],	# 200ohms, gain by AGC loop -> 50ohms
            [ RF69_REG_RXBW, 		  0x43 ],	# channel filter bandwidth 10kHz -> 60kHz  page:26
            [ RF69_REG_BITRATEMSB, 	  0x1A ],	# 4800b/s
            [ RF69_REG_BITRATELSB, 	  0x0B ],	# 4800b/s
            [ RF69_REG_SYNCCONFIG, 	  0x88 ],	# Size of the Synch word = 2 (SyncSize + 1)
            [ RF69_REG_SYNCVALUE1, 	  0x2D ],	# 1st byte of Sync word
            [ RF69_REG_SYNCVALUE2, 	  0xD4 ],	# 2nd byte of Sync word
            [ RF69_REG_PACKETCONFIG1, 0xA0 ],   # Variable length, Manchester coding
            [ RF69_REG_PAYLOADLEN, 	  0x42 ],	# max Length in RX, not used in Tx
            [ RF69_REG_NODEADDRESS,   0x06 ],	# Node address used in address filtering ( not used in this config )
            [ RF69_REG_FIFOTHRESH, 	  0x81 ],	# Condition to start packet transmission: at least one byte in FIFO
            [ RF69_REG_OPMODE, 		  RF69_MASK_OPMODE_RX ], # Operating mode to Receive    
        ],
        
        ook_config     => [
            [ RF69_REG_REGDATAMODUL, 0x08 ],   # modulation scheme OOK
            [ RF69_REG_FDEVMSB, 	 0 ], 	   # frequency deviation -> 0kHz 
            [ RF69_REG_FDEVLSB, 	 0 ],      # frequency deviation -> 0kHz
            [ RF69_REG_FRMSB, 		 0x6C ],   # carrier freq -> 433.92MHz 0x6C7AE1
            [ RF69_REG_FRMID, 		 0x7A ],   # carrier freq -> 433.92MHz 0x6C7AE1
            [ RF69_REG_FRLSB, 		 0xE1 ],   # carrier freq -> 433.92MHz 0x6C7AE1
            [ RF69_REG_RXBW, 		 0x41 ],   # channel filter bandwidth 120kHz
            [ RF69_REG_BITRATEMSB, 	 0x40 ],   # 1938b/s
            [ RF69_REG_BITRATELSB,   0x80 ],   # 1938b/s
            [ RF69_REG_PREAMBLEMSB,  0 ],      # no preamble
            [ RF69_REG_PREAMBLELSB,  0 ],      # no preamble
            [ RF69_REG_SYNCCONFIG, 	 0x98 ],   # Size of the Synch word = 4 (SyncSize + 1)
            [ RF69_REG_SYNCVALUE1, 	 0x80 ],   # sync value 1
            [ RF69_REG_SYNCVALUE2, 	 0 ],      # sync value 2
            [ RF69_REG_SYNCVALUE3, 	 0 ],      # sync value 3
            [ RF69_REG_SYNCVALUE4, 	 0 ],      # sync value 4
            [ RF69_REG_PACKETCONFIG1, 0 ],	   # Fixed length, no Manchester coding, OOK
            [ RF69_REG_PAYLOADLEN, 	13 + 8 * 17 ],	# Fixed OOK Payload Length
            [ RF69_REG_FIFOTHRESH, 	 0x1E ],   # Condition to start packet transmission: wait for 30 bytes in FIFO
            [ RF69_REG_OPMODE, 		 RF69_MASK_OPMODE_TX ],	# Transmitter mode
        ],
        
        rf_high_power => 0,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        $params{device} = HiPi::Interface::HopeRF69->new(
            speed        => $params{speed},
            bitsperword  => $params{bitsperword},
            delay        => $params{delay},
            devicename   => $params{devicename},
            reset_gpio   => $params{reset_gpio},
            ook_repeat   => $params{ook_repeat},
            backend      => $params{backend},
            fsk_config   => $params{default_config},
            ook_config   => $params{ook_config},
            high_power_module  => $params{rf_high_power},
            max_power_on => ( $params{rf_high_power} ) ? 1 : 0,
        );
    }
    
    my $self = $class->SUPER::new(%params);
    $self->init_pins;
    
    # setup defaults
    $self->set_red_led( 0 );
    $self->set_green_led( 0 );
    
    return $self;
}

sub make_ook_message {
    my($self, $groupid, $data) = @_;
    
    # energenie preamble
    my @msgbytes = ( 0x80, 0x00, 0x00, 0x00 );
    
    # encode the group id
    push @msgbytes, ( $self->encode_data( ( $groupid & 0x0f0000 ) >> 16, 4 ) );
    push @msgbytes, ( $self->encode_data( ( $groupid & 0x00ff00 ) >> 8, 8 ) );
    push @msgbytes, ( $self->encode_data( ( $groupid & 0x0000ff ), 8 ) );
    
    # encode the databits
    push @msgbytes, ( $self->encode_data( ( $data & 0x00000f ), 4 ) );
    
    return @msgbytes;
}

sub send_message {
    my($self, $bytes) = @_;

    return unless(scalar( @$bytes ));

    $self->set_red_led( 1 );
    $self->device->send_message( $bytes );
    $self->set_red_led( 0 );
    
	return;
}

sub send_ook_message {
    my($self, $groupid, $data, $repeat ) = @_;
    
    $repeat ||= $self->ook_repeat;
        
    $self->set_red_led( 1 );
    
    # $groupid = 20 bit controller id for your energenie ENER314-RT - you can vary this
    # as you wish so you can control multiple groups of 4 devices each.
    # $address is therefore any number between 0x1 and 0xFFFFF
    # $data = the 4 bits you want to send as defined in Energenie docs for your switch
    # order here is d0,d1,d2,d3 as defined in docs for your device
    # therefore data is a number between 0 and 15
    
    my @sendbytes = $self->make_ook_message( $groupid, $data );
    
    $self->device->send_ook_message(\@sendbytes, $repeat );
    
    $self->set_red_led( 0 );
}

# mask for bit encoding
my @_encoding_mask = ( 0x88, 0x8E, 0xE8, 0xEE );

sub encode_data {
    my($self, $data, $number ) = @_;
    my @encoded = ();
    my $shift = $number - 2;
    while ( $shift >= 0 ) {
        my $encindex = ($data >> $shift) & 0x03;
        push @encoded, $_encoding_mask[$encindex];
        $shift -= 2;
    }
    return @encoded;
}

sub init_pins {
    my $self = shift;
    return unless $self->led_on;
    if( my $redpin = $self->led_red ) {
        $self->gpiodev->set_pin_mode( $redpin, RPI_MODE_OUTPUT  );
        $self->gpiodev->set_pin_level( $redpin, RPI_LOW  );
    }
    if( my $greenpin = $self->led_green ) {
        $self->gpiodev->set_pin_mode( $greenpin, RPI_MODE_OUTPUT  );
        $self->gpiodev->set_pin_level( $greenpin, RPI_LOW  );
    }
}

sub set_red_led {
    my ($self, $value) = @_;
    return unless $self->led_on;
    if( my $redpin = $self->led_red ) {
        $self->gpiodev->set_pin_level( $redpin, $value  );
    }
    return;
}

sub set_green_led {
    my ($self, $value) = @_;
    return unless $self->led_on;
    if( my $greenpin = $self->led_green ) {
        $self->gpiodev->set_pin_level( $greenpin, $value  );
    }
    return;
}

sub reset {
    my $self = shift;
    $self->device->reset;
}

sub receive_fsk_message {
    my ($self, $encryptionid) = @_;
    if( my $buffer = $self->device->receive_message ) {
        my $msg = HiPi::RF::OpenThings::Message->new(
            databuffer => $buffer,
            cryptseed  => $encryptionid,
        );
        $msg->inspect_buffer;
        return $msg;
    }
    return undef;
}

sub send_fsk_message {
    my ($self, $msg) =  @_;
    $msg->encode_buffer unless $msg->is_encoded;
    $self->send_message( $msg->databuffer );
}

#-------------------------------------------------------
# Common OOK switch handler
#-------------------------------------------------------

sub switch_ook_socket {
    my($self, $groupid, $data, $repeat) = @_;
    $self->send_ook_message( $groupid, $data, $repeat );
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
    $self->device( undef );
} 

1;

__END__
