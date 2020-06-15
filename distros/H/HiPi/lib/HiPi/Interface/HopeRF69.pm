#########################################################################################
# Package        HiPi::Interface::HopeRF69
# Description  : Control Hope RF69 Transceivers
# Copyright    : Copyright (c) 2013-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::HopeRF69;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi qw( :rpi :spi :hrf69 );

__PACKAGE__->create_accessors( qw( devicename reset_gpio update_default_on_reset
                                   fsk_config ook_config ook_repeat
                                   high_power_module max_power_on ) );

our $VERSION ='0.82';

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
        speed        => 9600000,  # 9.6 mhz
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        reset_gpio   => undef,
        update_default_on_reset => 1,
        ook_repeat   => 15,
        fsk_config => [
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
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        
        require HiPi::Device::SPI;
        $params{device} = HiPi::Device::SPI->new(
            speed        => $params{speed},
            bitsperword  => $params{bitsperword},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
    }
    
    my $self = $class->SUPER::new(%params);
    
    # setup defaults
    $self->reset();
    
    $self->configure($self->fsk_config);
    
    return $self;
}

sub configure {
    my( $self, $config ) = @_;
    for my $msgref ( @$config ) {
        $self->write_register(@$msgref);
    }
    
    if( $self->high_power_module ) {
        $self->write_register( RF69_REG_OCP, RF69_VAL_OCP_OFF );
        $self->write_register( RF69_REG_PALEVEL, ( $self->read_register(RF69_REG_PALEVEL) & 0x1F) | RF69_PALEVEL_PA1_ON | RF69_PALEVEL_PA2_ON );
    }
    
    $self->wait_for(RF69_REG_IRQFLAGS1, RF69_MASK_MODEREADY, RF69_TRUE);
}

sub change_mode {
    my($self, $mode, $waitmask) = @_;
    $waitmask //= RF69_MASK_MODEREADY;
    $self->write_register(RF69_REG_OPMODE, $mode);
    if( $self->high_power_module && $self->max_power_on ) {
        if( $mode == RF69_MASK_OPMODE_RX ) {
            $self->write_register( RF69_REG_TESTPA1, 0x55 );
            $self->write_register( RF69_REG_TESTPA2, 0x70 );
        } elsif( $mode == RF69_MASK_OPMODE_TX ) {
            $self->write_register( RF69_REG_TESTPA1, 0x5D );
            $self->write_register( RF69_REG_TESTPA2, 0x7C );
        }
    }
    $self->wait_for(RF69_REG_IRQFLAGS1, $waitmask, RF69_TRUE);
}

sub set_mode_receiver {
    my $self = shift;
    $self->change_mode(RF69_MASK_OPMODE_RX, RF69_MASK_MODEREADY );
}

sub set_mode_transmitter {
    my $self = shift;
    $self->change_mode(RF69_MASK_OPMODE_TX, RF69_MASK_MODEREADY | RF69_MASK_TXREADY );
}

sub write_register {
    my( $self, @data ) = @_;
    # address is first byte
    $data[0] |= RF69_MASK_REG_WRITE;
    $self->device->transfer_byte_array( @data );
}

sub read_register {
    my( $self, $addr, $numbytes ) = @_;
    $numbytes ||= 1;
    my @data = ( 0 ) x ( $numbytes + 1 );
    $data[0] = $addr;
    my ($retaddr, @rvals ) = $self->device->transfer_byte_array( @data );
    return ( wantarray ) ? @rvals : $rvals[0];
}

sub write_fifo { shift->write_register( 0x0, @_ ); }

sub read_fifo {
    my $self = shift;
    my( $rval ) = $self->read_register( 0x0, 1 );
    return $rval;
}

sub clear_fifo {
    my $self = shift;
    
    my $state = $self->read_register( RF69_REG_IRQFLAGS2 );
    
	while ($state & RF69_MASK_FIFONOTEMPTY)	{
        my $discard = $self->read_fifo;
		$state = $self->read_register(RF69_REG_IRQFLAGS2);
	}
    
	return;
}

sub reset {
    my $self = shift;
    my $pin = $self->reset_gpio;
    return unless defined($pin);
    require HiPi::GPIO;
    my $gpio = HiPi::GPIO->new;
    $gpio->set_pin_mode( $pin, RPI_MODE_OUTPUT ) if( $gpio->get_pin_mode($pin) != RPI_MODE_OUTPUT );
    $gpio->pin_write($pin, RPI_HIGH);
    $self->delay( 100 ); # 0.1 secs
    $gpio->pin_write($pin, RPI_LOW);
        
    if ($self->update_default_on_reset) {
       $self->configure($reset_defaults);
    }
    return;
}

sub wait_for {
    my( $self, $addr, $mask, $true) = @_;
    my $counter  = 0;
    my $maxcount = 4000000;
    while ( $counter < $maxcount ) {
        my $ret = $self->read_register( $addr );
        last if( ( $ret & $mask ) == ( $true ? $mask : 0 ) );
        $counter ++;
    }
    if ( $counter >= $maxcount ) {
        croak qq(timeout inside wait loop with addr $addr);
    }
    return;
}


sub assert_register_value {
    my($self, $addr, $mask, $true, $desc) = @_;
    my $val = $self->read_register( $addr );
	if ($true){
		if (($val & $mask) != $mask) {
			croak sprintf("ASSERTION FAILED: addr:%02x, expVal:%02x(mask:%02x) != val:%02x, desc: %s", $addr, $true, $mask, $val, $desc);
        }
    } else {
		if (($val & $mask) != 0) {
			croak sprintf("ASSERTION FAILED: addr:%02x, expVal:%02x(mask:%02x) != val:%02x, desc: %s", $addr, $true, $mask, $val, $desc);
        }
    }
    return;
}

sub send_message {
    my($self, $bytes) = @_;

    return unless(scalar( @$bytes ));

    $self->set_mode_transmitter;
    # write to fifo
    $self->write_fifo( @$bytes );
	# wait for Packet sent
	$self->wait_for (RF69_REG_IRQFLAGS2, RF69_MASK_PACKETSENT, RF69_TRUE);
	# assert that all bytes sent
    $self->assert_register_value(RF69_REG_IRQFLAGS2, RF69_MASK_FIFONOTEMPTY | RF69_MASK_FIFOOVERRUN, RF69_FALSE, q(are all bytes sent?));
    # set back to receive mode
    $self->set_mode_receiver;
    
	return;
}

sub send_ook_message {
    my($self, $bytes, $repeat ) = @_;
    
    return unless scalar @$bytes;
    
    $repeat ||= $self->ook_repeat;
    $repeat = 100 if $repeat > 100;
    $repeat = 8 if $repeat < 8;
        
    # switch to OOK mode
    $self->configure($self->ook_config);
    $self->set_mode_transmitter();
    
    # wait for mode ready for transmit after config
	$self->wait_for(RF69_REG_IRQFLAGS1, RF69_MASK_MODEREADY | RF69_MASK_TXREADY, RF69_TRUE);
    
    # send first without preamble
    $self->write_fifo( @$bytes[4..15] );
    
	# repeated resend with sync bytes
    for (my $i = 0; $i < $repeat; $i++) {
        # wait while bytes in FIFO exceed FifoThreshold, 
		$self->wait_for(RF69_REG_IRQFLAGS2, RF69_MASK_FIFOLEVEL, RF69_FALSE);
		$self->write_fifo( @$bytes );					
	}
    
    # wait for Packet sent
	$self->wait_for (RF69_REG_IRQFLAGS2, RF69_MASK_PACKETSENT, RF69_TRUE);
    
    # assert that FIFO is empty and there were no overruns
	$self->assert_register_value(RF69_REG_IRQFLAGS2, RF69_MASK_FIFONOTEMPTY | RF69_MASK_FIFOOVERRUN, RF69_FALSE, q(are all bytes sent?));
    
    # return to default mode
    $self->configure($self->fsk_config);
    $self->set_mode_receiver();
    
    return;
}

sub receive_message {
    my ( $self ) = @_;
	
    my $fifostate = $self->read_register( RF69_REG_IRQFLAGS2 );
    
    if ( ( $fifostate & RF69_MASK_PAYLOADRDY ) ==  RF69_MASK_PAYLOADRDY ) {
        my @databuffer = ();
        while ( $fifostate & RF69_MASK_FIFONOTEMPTY )	{
            push @databuffer, $self->read_fifo;
            $fifostate = $self->read_register(RF69_REG_IRQFLAGS2);
        }
        
        return \@databuffer;
    }
    
    return undef;
}


1;

__END__
