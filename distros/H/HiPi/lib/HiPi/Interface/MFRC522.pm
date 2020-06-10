#########################################################################################
# Package        HiPi::Interface::MFRC522
# Description  : Interface to MFRC522 Contactless reader IC
# Copyright    : Perl implementation Copyright (c) 2019 Mark Dootson
#                This is a port of the Arduino MFRC522 library from
#                https://github.com/miguelbalboa/rfid
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MFRC522;

#########################################################################################
# DOCS
#
# https://www.nxp.com/docs/en/data-sheet/MF1S70YYX_V1.pdf     Mifare Classic 1K/4K/Mini
# https://www.nxp.com/docs/en/application-note/AN10787.pdf    Mifare Application Directory

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :mfrc522 :spi :rpi );
use HiPi::Device::SPI;
use HiPi::GPIO;
use Carp;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( reset_pin gpio scanwait scaniter _allow_write_st _allow_write_block0 debug ) );

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_2,
        delay        => 0,
        reset_pin    => undef,
        scanwait     => 10000,
        scaniter     => 2000,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless(defined($params{device})) {
        $params{device} = HiPi::Device::SPI->new(
            speed        => $params{speed},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
    }
    
    $params{gpio} = HiPi::GPIO->new;
    
    my $self = $class->SUPER::new(%params);
    
    $self->_check_reset_pin_status;
    
    return $self;
}

sub _check_reset_pin_status {
    my $self = shift;
    return unless $self->reset_pin;
    my $mode = $self->gpio->get_pin_mode( $self->reset_pin );
    $self->gpio->set_pin_pud( $self->reset_pin, RPI_PUD_OFF );
    if( $mode == RPI_MODE_OUTPUT ) {
        my $level = $self->gpio->get_pin_level( $self->reset_pin );
        $self->gpio->set_pin_level( $self->reset_pin, RPI_HIGH ) if $level == RPI_LOW;
    } else {
        $self->gpio->set_pin_mode( $self->reset_pin, RPI_MODE_OUTPUT );
        $self->gpio->set_pin_level( $self->reset_pin, RPI_HIGH )
    }
    return 1;
}

sub soft_reset {
    my $self = shift;
    $self->write_register( MFRC522_REG_CommandReg, MFRC522_SOFTRESET );
    
    # wait
    my $loops = 0;
    while( ( $self->read_register( MFRC522_REG_CommandReg ) ) & (1 << 4) && $loops < 5 )  {
        $loops ++;
        $self->sleep_milliseconds(50);
    }
}

sub hard_reset {
    my $self = shift;
    return 0 unless $self->reset_pin;
    $self->gpio->set_pin_level( $self->reset_pin, RPI_LOW );
    $self->sleep_microseconds( 10 );
    $self->gpio->set_pin_level( $self->reset_pin, RPI_HIGH );
    $self->sleep_milliseconds( 50 );
    return 1;
}

sub write_register {
    my($self, $register, @bytes ) = @_;
    my $address = ($register << 1) & 0x7E;
    $self->device->transfer_byte_array( $address, @bytes );
    return;
}

sub read_register {
    my($self, $register ) = @_;
    my $address = (($register << 1) & 0x7E) | 0x80;
    my @result = $self->device->transfer_byte_array( $address , 0x00 );
    return $result[1];
}

sub read_fifo {
    my($self, $numbytes ) = @_;
    $numbytes ||= 1;
    my $address = ((MFRC522_REG_FIFODataReg << 1) & 0x7E) | 0x80;
    my @addressbytes = ( $address ) x $numbytes;
    my @result = $self->device->transfer_byte_array( @addressbytes , 0x00 );
    shift @result;
    return @result;
}

sub get_firmware_version  {
    my $self = shift;
    my $version = $self->read_register( MFRC522_REG_VersionReg );
    return $version;
}

sub get_firmware_version_string {
    my ($self, $version) = @_;
    $version //= $self->get_firmware_version;
    my $vstring = 'unknown module';
    if( $version == 0x88 ) {
        $vstring = 'Fudan Semiconductor FM17522 Clone';
    } elsif( $version == 0x90 ) {
        $vstring = 'RC522 Version 0';
    } elsif( $version == 0x91 ) {
        $vstring = 'MFRC522 Version 1';
    } elsif( $version == 0x92 ) {
        $vstring = 'MFRC522 Version 2';
    }    
    return $vstring;
}

sub init {
    my $self = shift;
    
    $self->hard_reset || $self->soft_reset();
    
    ## // Reset baud rates
	$self->write_register(MFRC522_REG_TxModeReg, 0x00);
	$self->write_register(MFRC522_REG_RxModeReg, 0x00);
	## // Reset ModWidthReg
	$self->write_register(MFRC522_REG_ModWidthReg, 0x26);
    
    $self->write_register(MFRC522_REG_TModeReg, 0x80);			#// TAuto=1; timer starts automatically at the end of the transmission in all communication modes at all speeds
	$self->write_register(MFRC522_REG_TPrescalerReg, 0xA9);		#// TPreScaler = TModeReg[3..0]:TPrescalerReg, ie 0x0A9 = 169 => f_timer=40kHz, ie a timer period of 25?s.
	$self->write_register(MFRC522_REG_TReloadRegH, 0x03);		#// Reload timer with 0x3E8 = 1000, ie 25ms before timeout.
	$self->write_register(MFRC522_REG_TReloadRegL, 0xE8);
	
	$self->write_register(MFRC522_REG_TxAutoReg, 0x40);		    #// Default 0x00. Force a 100 % ASK modulation independent of the ModGsPReg register setting
	$self->write_register(MFRC522_REG_ModeReg, 0x3D);		    #// Default 0x3F. Set the preset value for the CRC coprocessor for the CalcCRC command to 0x6363 (ISO 14443-3 part 6.2.4)
	
    $self->pcd_antenna_on();    						        #// Enable the antenna driver pins TX1 and TX2 (they were disabled by the reset)
}

sub init_alt {
    my $self = shift;
    
    ## // Reset baud rates
	$self->write_register(MFRC522_REG_TxModeReg, 0x00);
	$self->write_register(MFRC522_REG_RxModeReg, 0x00);
    
    ## // Reset ModWidthReg
	$self->write_register(MFRC522_REG_ModWidthReg, 0x26);
    
    $self->write_register(MFRC522_REG_TModeReg, 0x8D);
    $self->write_register(MFRC522_REG_TPrescalerReg, 0x3E);
    $self->write_register(MFRC522_REG_TReloadRegL, 0x1E);
    $self->write_register(MFRC522_REG_TReloadRegH, 0x00);
    
    $self->write_register(MFRC522_REG_TxAutoReg, 0x40);
    $self->write_register(MFRC522_REG_ModeReg, 0x3D);
    
    $self->pcd_antenna_on();
}

sub pcd_antenna_on {
    my $self = shift;
    $self->set_bit_mask(MFRC522_REG_TxControlReg, 0x03);    # // Turn antenna on.
}

sub pcd_antenna_off {
    my $self = shift;
    $self->clear_bit_mask(MFRC522_REG_TxControlReg, 0x03);    # // Turn antenna off.
}

sub pcd_get_antenna_gain {
    my $self = shift;
    return $self->read_register(MFRC522_REG_RFCfgReg) & (0x07<<4);
}

sub pcd_set_antenna_gain {
    my ($self, $gain ) = @_;
    my $current = $self->pcd_get_antenna_gain;
    if( $current != $gain ) {
        $self->pcd_antenna_off;
        $self->clear_bit_mask(MFRC522_REG_RFCfgReg, (0x07<<4) );
        $self->set_bit_mask(MFRC522_REG_RFCfgReg, $gain & (0x07<<4) );
        $self->pcd_antenna_on;
    }
    return $gain;
}

sub set_bit_mask {
    my ($self, $resister, $mask) = @_;
    my $current = $self->read_register( $resister );
    $self->write_register( $resister, $current | $mask );
}

sub clear_bit_mask {
    my ($self, $resister, $mask) = @_;
    my $current = $self->read_register( $resister );
    $self->write_register( $resister, $current &~$mask );
}

sub self_test_ok {
    my $self = shift;
    
    my @valV0 = (0x00, 0x87, 0x98, 0x0f, 0x49, 0xFF, 0x07, 0x19,
                0xBF, 0x22, 0x30, 0x49, 0x59, 0x63, 0xAD, 0xCA,
                0x7F, 0xE3, 0x4E, 0x03, 0x5C, 0x4E, 0x49, 0x50,
                0x47, 0x9A, 0x37, 0x61, 0xE7, 0xE2, 0xC6, 0x2E,
                0x75, 0x5A, 0xED, 0x04, 0x3D, 0x02, 0x4B, 0x78,
                0x32, 0xFF, 0x58, 0x3B, 0x7C, 0xE9, 0x00, 0x94,
                0xB4, 0x4A, 0x59, 0x5B, 0xFD, 0xC9, 0x29, 0xDF,
                0x35, 0x96, 0x98, 0x9E, 0x4F, 0x30, 0x32, 0x8D);
    
    my @valV1 = (0x00, 0xC6, 0x37, 0xD5, 0x32, 0xB7, 0x57, 0x5C,
                0xC2, 0xD8, 0x7C, 0x4D, 0xD9, 0x70, 0xC7, 0x73,
                0x10, 0xE6, 0xD2, 0xAA, 0x5E, 0xA1, 0x3E, 0x5A,
                0x14, 0xAF, 0x30, 0x61, 0xC9, 0x70, 0xDB, 0x2E,
                0x64, 0x22, 0x72, 0xB5, 0xBD, 0x65, 0xF4, 0xEC,
                0x22, 0xBC, 0xD3, 0x72, 0x35, 0xCD, 0xAA, 0x41,
                0x1F, 0xA7, 0xF3, 0x53, 0x14, 0xDE, 0x7E, 0x02,
                0xD9, 0x0F, 0xB5, 0x5E, 0x25, 0x1D, 0x29, 0x79 );
 
    my @valV2 = (0x00, 0xEB, 0x66, 0xBA, 0x57, 0xBF, 0x23, 0x95,
                0xD0, 0xE3, 0x0D, 0x3D, 0x27, 0x89, 0x5C, 0xDE,
                0x9D, 0x3B, 0xA7, 0x00, 0x21, 0x5B, 0x89, 0x82,
                0x51, 0x3A, 0xEB, 0x02, 0x0C, 0xA5, 0x00, 0x49,
                0x7C, 0x84, 0x4D, 0xB3, 0xCC, 0xD2, 0x1B, 0x81,
                0x5D, 0x48, 0x76, 0xD5, 0x71, 0x61, 0x21, 0xA9,
                0x86, 0x96, 0x83, 0x38, 0xCF, 0x9D, 0x5B, 0x6D,
                0xDC, 0x15, 0xBA, 0x3E, 0x7D, 0x95, 0x3B, 0x2F );
    
    my @valVclone = (0x00, 0xD6, 0x78, 0x8C, 0xE2, 0xAA, 0x0C, 0x18,
                0x2A, 0xB8, 0x7A, 0x7F, 0xD3, 0x6A, 0xCF, 0x0B,
                0xB1, 0x37, 0x63, 0x4B, 0x69, 0xAE, 0x91, 0xC7,
                0xC3, 0x97, 0xAE, 0x77, 0xF4, 0x37, 0xD7, 0x9B,
                0x7C, 0xF5, 0x3C, 0x11, 0x8F, 0x15, 0xC3, 0xD7,
                0xC1, 0x5B, 0x00, 0x2A, 0xD0, 0x75, 0xDE, 0x9E,
                0x51, 0x64, 0xAB, 0x3E, 0xE9, 0x15, 0xB5, 0xAB,
                0x56, 0x9A, 0x98, 0x82, 0x26, 0xEA, 0x2A, 0x62);
    
    my $version = $self->get_firmware_version;
    
    my $checkvals;
    
    if( $version == 0x88 ) {
        $checkvals = \@valVclone;
    } elsif( $version == 0x90 ) {
        $checkvals = \@valV0;
    } elsif( $version == 0x91 ) {
        $checkvals = \@valV1;
    } elsif( $version == 0x92 ) {
        $checkvals = \@valV2;
    } else {
        return 0;
    }
    
    $self->soft_reset();
    $self->write_register(MFRC522_REG_FIFOLevelReg, 0x80);
    $self->write_register(MFRC522_REG_FIFODataReg, 0x00);
    $self->write_register(MFRC522_REG_CommandReg, MFRC522_MEM);
    $self->write_register(MFRC522_REG_AutoTestReg, 0x09);
    $self->write_register(MFRC522_REG_FIFODataReg, 0x00);
    $self->write_register(MFRC522_REG_CommandReg, MFRC522_CALCCRC);
    
    my $i = 0;
        
    while ( $i < 64 ) {
        $self->sleep_microseconds(100);
        my $regval = $self->read_register( MFRC522_REG_DivIrqReg );
        last if ($regval & 0x04);
        $i ++;
    }
    
    my @valdata = $self->read_fifo(64);
    
    for ( $i = 0; $i < 64; $i++) {
        if ($valdata[$i] != $checkvals->[$i]) {
            return 0;
        }
    }
    
    return 1;
}

sub scan {
    my($self, $coderef, $timeoutref, $timeoutsecs ) = @_;
    
    $timeoutref  //= sub { return 1; };
    $timeoutsecs //= 60;
    
    $self->init;
        
    my $continue = 1;
    
    my $timeout = time() + $timeoutsecs;
    
    while ($continue)  {
        
        $self->sleep_microseconds( 10 * $self->scanwait );
        if( $self->picc_is_new_tag_present ) {
            my ( $status, $uid, $serialstring ) = $self->picc_read_tag_serial;
            if( $status == MFRC522_STATUS_OK ) {
                $timeout = time() + $timeoutsecs;
                $continue = $coderef->($uid, $serialstring);
                $self->picc_end_session unless $continue;
            } else {
                carp $self->get_status_code_name( $status );
            }
        }
        
        if( $timeout < time() ) {
            $continue = $timeoutref->();
            $timeout = time() + $timeoutsecs;
        }
    }
}

sub mifare_set_access_bits {
    my($self, $g0, $g1, $g2, $g3) = @_;
    
    #g0,		        ///< Access bits C1 C2 C3 for block 0 (for sectors 0-31) or blocks 0-4 (for sectors 32-39)
    #g1,				///< Access bits C1 C2 C3 for block 1 (for sectors 0-31) or blocks 5-9 (for sectors 32-39)
    #g2,				///< Access bits C1 C2 C3 for block 2 (for sectors 0-31) or blocks 10-14 (for sectors 32-39)
    #g3					///< Access bits C1 C2 C3 for the sector trailer, block 3 (for sectors 0-31) or block 15 (for sectors 32-39)

	my $c1 = (($g3 & 4) << 1) | (($g2 & 4) << 0) | (($g1 & 4) >> 1) | (($g0 & 4) >> 2);
	my $c2 = (($g3 & 2) << 2) | (($g2 & 2) << 1) | (($g1 & 2) << 0) | (($g0 & 2) >> 1);
	my $c3 = (($g3 & 1) << 3) | (($g2 & 1) << 2) | (($g1 & 1) << 1) | (($g0 & 1) << 0);
    
    my @bitbuffer;
	
	$bitbuffer[0] = (~$c2 & 0xF) << 4 | (~$c1 & 0xF);
	$bitbuffer[1] =          $c1 << 4 | (~$c3 & 0xF);
	$bitbuffer[2] =          $c3 << 4 | $c2;
    
    return \@bitbuffer
}

sub pcd_communicate_with_picc {
    my($self, $command, $waitirq, $sendref, $getlen, $validbits, $rxalign, $checkcrc ) = @_;    

    $rxalign  ||= 0;
    $checkcrc ||= 0;
        
    #byte command,		///< The command to execute. One of the PCD_Command enums.
    #byte waitIRq,		///< The bits in the ComIrqReg register that signals successful completion of the command.
    #byte *sendData,		///< Pointer to the data to transfer to the FIFO.
    #byte sendLen,		///< Number of bytes to transfer to the FIFO.
    #byte *backData,		///< nullptr or pointer to buffer if data should be read back after executing the command.
    #byte *backLen,		///< In: Max number of bytes to write to *backData. Out: The number of bytes returned.
    #byte *validBits,	///< In/Out: The number of valid bits in the last byte. 0 for 8 valid bits.
    #byte rxAlign,		///< In: Defines the bit position in backData[0] for the first bit received. Default 0.
    #bool checkCRC		///< In: True => The last two bytes of the response is assumed to be a CRC_A that must be validated.
									
	# // Prepare values for BitFramingReg
    
	my $txLastBits = $validbits || 0;
	my $bitFraming = ($rxalign << 4) + $txLastBits;		# // RxAlign = BitFramingReg[6..4]. TxLastBits = BitFramingReg[2..0]
	    
	$self->write_register(MFRC522_REG_CommandReg, MFRC522_IDLE);		# // Stop any active command.
	$self->write_register(MFRC522_REG_CommIrqReg, 0x7F);				# // Clear all seven interrupt request bits
	$self->write_register(MFRC522_REG_FIFOLevelReg, 0x80);				# // FlushBuffer = 1, FIFO initialization
    	
    $self->write_register(MFRC522_REG_FIFODataReg, @$sendref);	        #// Write sendData to the FIFO
	$self->write_register(MFRC522_REG_BitFramingReg, $bitFraming);		#// Bit adjustments
	$self->write_register(MFRC522_REG_CommandReg, $command);    		#// Execute the command
	
    if ($command == MFRC522_TRANSCEIVE) {
		$self->set_bit_mask(MFRC522_REG_BitFramingReg, 0x80);	        #// StartSend=1, transmission of data starts
	}
	
	#// Wait for the command to complete.
	#// In PCD_Init() we set the TAuto flag in TModeReg. This means the timer automatically starts when the PCD stops transmitting.
	#// Each iteration of the do-while-loop takes 17.86?s.
	#// TODO check/modify for other architectures than Arduino Uno 16bit
    	
    my $i;
    
    my $scanwait = $self->scanwait;
    
	for ($i = $self->scaniter; $i > 0; $i--) {
		my $val = $self->read_register(MFRC522_REG_CommIrqReg);	# CommIrqReg[7..0] bits are: Set1 TxIRq RxIRq IdleIRq HiAlertIRq LoAlertIRq ErrIRq TimerIRq
		if ($val & $waitirq) {					                #// One of the interrupts that signal success has been set.
			
            last;
		}
		if ($val & 0x01) {						                #// Timer interrupt - nothing received in 25ms
			
            return ( MFRC522_STATUS_TIMEOUT, [] );
		}
        $self->sleep_microseconds( $scanwait );
	}
	
	if ($i == 0) {        
		return ( MFRC522_STATUS_TIMEOUT, [] );
	}
	
	# Stop now if any errors except collisions were detected.
	my $errorRegValue = $self->read_register(MFRC522_REG_ErrorReg); # // ErrorReg[7..0] bits are: WrErr TempErr reserved BufferOvfl CollErr CRCErr ParityErr ProtocolErr
	if ($errorRegValue & 0x13) {	 #// BufferOvfl ParityErr ProtocolErr
		return ( MFRC522_STATUS_ERROR, [] );
	}
  
	my $check_validBits = 0;
	
    my @rdata = ();
    
    # warn qq(something's out there .....);
    
	# If the caller wants data back, get it from the MFRC522.
	if ($getlen) {
        
        # warn qq(let's read what it says .....);
		my $haslen = $self->read_register(MFRC522_REG_FIFOLevelReg);	#// Number of bytes in the FIFO
		
        @rdata = $self->read_fifo($haslen);
        
        $getlen = $haslen;
        
        if ($rxalign) {		#// Only update bit positions rxAlign..7 in values[0]
            #// Create bit mask for bit positions rxAlign..7
            my $mask = (0xFF << $rxalign) & 0xFF;
            
            # // Apply mask to both current value of values[0] and the new data in value.
            $rdata[0] = ( $rdata[0] & ~$mask) | ( $rdata[0] & $mask );
        }
        
        $check_validBits = $self->read_register(MFRC522_REG_ControlReg) & 0x07;		#// RxLastBits[2:0] indicates the number of valid bits in the last received byte. If this value is 000b, the whole byte is valid.
        $validbits = $check_validBits if $validbits;
	}
    
	# // Tell about collisions
	if ($errorRegValue & 0x08) {		#  CollErr
		return ( MFRC522_STATUS_COLLISION, \@rdata, $validbits );
	}
	
	# // Perform CRC_A validation if requested.
	if ( @rdata && $checkcrc) {
        
		# // In this case a MIFARE Classic NAK is not OK.
		if ( $getlen == 1 && $check_validBits == 4) {
			return ( MFRC522_STATUS_MIFARE_NACK , \@rdata, $validbits);
		}
		#// We need at least the CRC_A value and all 8 bits of the last byte must be received.
		
        if ( $getlen < 2 || $check_validBits != 0) {
			return ( MFRC522_STATUS_CRC_WRONG, \@rdata, $validbits );
		}
		
        #// Verify CRC_A - do our own calculation and store the control in controlBuffer.
		         
        my @crcdata = @rdata;
        pop @crcdata; pop @crcdata;
        
        my ( $crcstatus, $cbuffer1, $cbuffer2 ) = $self->pcd_calculate_crc( \@crcdata );
        
		if ($crcstatus != MFRC522_STATUS_OK) {
			return ($crcstatus, \@rdata, $check_validBits) ;
		}
		if (($rdata[-2] != $cbuffer1 ) || ($rdata[-1] != $cbuffer2)) {
			return (MFRC522_STATUS_CRC_WRONG, \@rdata, $check_validBits) ;
		}
	}
	
	return ( MFRC522_STATUS_OK, \@rdata, $check_validBits );
}

sub pcd_calculate_crc {
    my($self, $dataref) = @_;
    
    $self->write_register(MFRC522_REG_CommandReg, MFRC522_IDLE);	#// Stop any active command.
	$self->write_register(MFRC522_REG_DivIrqReg, 0x04);             #// Clear the CRCIRq interrupt request bit
	$self->write_register(MFRC522_REG_FIFOLevelReg, 0x80);			#// FlushBuffer = 1, FIFO initialization
	$self->write_register(MFRC522_REG_FIFODataReg, @$dataref);	    #// Write data to the FIFO
	$self->write_register(MFRC522_REG_CommandReg, MFRC522_CALCCRC);	#// Start the calculation
	
	#// Wait for the CRC calculation to complete. Each iteration of the while-loop takes 17.73?s.
	#// TODO check/modify for other architectures than Arduino Uno 16bit

	#// Wait for the CRC calculation to complete. Each iteration of the while-loop takes 17.73us.
	for (my $i = 5000; $i > 0; $i--) {
		#// DivIrqReg[7..0] bits are: Set2 reserved reserved MfinActIRq reserved CRCIRq reserved reserved
		my $checkirq = $self->read_register(MFRC522_REG_DivIrqReg);
		if ($checkirq & 0x04) {									            # // CRCIRq bit set - calculation done
			$self->write_register(MFRC522_REG_CommandReg, MFRC522_IDLE);	# // Stop calculating CRC for new content in the FIFO.
			# // Transfer the result from the registers to the result buffer
			my $r1 = $self->read_register(MFRC522_REG_CRCResultRegL);
			my $r2 = $self->read_register(MFRC522_REG_CRCResultRegH);
			return ( MFRC522_STATUS_OK, $r1, $r2 );
		}
        $self->sleep_microseconds( $self->scanwait );
	}
	
	return ( MFRC522_STATUS_TIMEOUT, undef, undef );
}

sub picc_is_new_tag_present  {
    my $self = shift;
	
	#// Reset baud rates
	$self->write_register(MFRC522_REG_TxModeReg, 0x00);
	$self->write_register(MFRC522_REG_RxModeReg, 0x00);
	#// Reset ModWidthReg
	$self->write_register(MFRC522_REG_ModWidthReg, 0x26);
	    
    my( $status, $data, $validbits ) = $self->picc_request_active();
    
    my $result = ( $status == MFRC522_STATUS_OK || $status == MFRC522_STATUS_COLLISION );
    return $result;
}

sub picc_request_active {
    my($self) = @_;
    my( $status, $data, $validbits ) = $self->picc_request_idl_or_wup( MIFARE_REQIDL, 2 );
    return ( $status, $data, $validbits );
}

sub picc_request_wakeup {
    my($self) = @_;
    my( $status, $data, $validbits ) = $self->picc_request_idl_or_wup( MIFARE_REQALL, 2 );
    return ( $status, $data, $validbits );
}

sub picc_request_idl_or_wup {
    my($self, $command, $getlen) = @_;
    
    # command is MIFARE_REQIDL or MIFARE_REQALL
    
	$self->clear_bit_mask(MFRC522_REG_CollReg, 0x80);	#// ValuesAfterColl=1 => Bits received after collision are cleared.
	
    my $validbits = 7;									#// For REQA and WUPA we need the short frame format - transmit only 7 bits of the last (and only) byte. TxLastBits = BitFramingReg[2..0]
    my($status, $data);
    ( $status, $data, $validbits ) = $self->pcd_transceive_data( $command , $validbits, $getlen );
	
    if ($status != MFRC522_STATUS_OK) {
		return ( $status, undef, undef );
	}
    
	if (scalar @$data != 2 || $validbits != 0) {		#// ATQA must be exactly 16 bits.
		return ( MFRC522_STATUS_ERROR, undef, undef );
	}
    
	return ( $status, $data, $validbits );
}

sub pcd_transceive_data {
    my($self, $senddata, $validbitsin, $getlen, $rxalign, $checkcrc ) = @_;
    
    my $sendref = ( ref($senddata) eq 'ARRAY') ? $senddata : [ $senddata ];
    
    my $waitirq = 0x30;
    
    # // we sometimes pass in null bytes
    for (my $i = 0; $i < @$sendref; $i ++ ) {
        $sendref->[$i] //= 0;
    }
    
    my ($status, $data, $validbits) = $self->pcd_communicate_with_picc(
        MFRC522_TRANSCEIVE, $waitirq, $sendref, $getlen, $validbitsin, $rxalign, $checkcrc 
    );
    
    return ($status, $data, $validbits);
}

sub pcd_mifare_transceive {
    my($self, $data, $accepttimeout) = @_;
    
    $accepttimeout = ( $accepttimeout ) ? 1 : 0;
    
	#// Copy sendData[] to cmdBuffer[] and add CRC_A
	    
    my ( $crcstatus, $cbuffer1, $cbuffer2 ) = $self->pcd_calculate_crc( $data );
    
	if ($crcstatus != MFRC522_STATUS_OK) { 
		return ( $crcstatus, undef );
	}
	    
    my @sendbuffer = @$data;
    push( @sendbuffer, $cbuffer1, $cbuffer2 );
	
	#// Transceive the data, store the reply in cmdBuffer[]
	my $waitIRq = 0x30;		#// RxIRq and IdleIRq
	my $validBits = 0;
    my $getlen = 16;
    my ($status, $piccdata, $validbitsout) = $self->pcd_communicate_with_picc(
        MFRC522_TRANSCEIVE, $waitIRq, \@sendbuffer, $getlen, $validBits 
    );
    
	if ($accepttimeout && $status == MFRC522_STATUS_TIMEOUT) {
		return (MFRC522_STATUS_OK, [] );
	}
	if ($status != MFRC522_STATUS_OK) {
		return ( $status, undef );
	}
	#// The PICC must reply with a 4 bit ACK
    
    my $returnbuffersize = scalar @$piccdata;
    
	if ($returnbuffersize != 1 || $validbitsout != 4) {
        
		return ( MFRC522_STATUS_ERROR, undef );
	}
	if ($piccdata->[0] != MIFARE_MF_ACK) {
		return ( MFRC522_STATUS_MIFARE_NACK, undef );
	}
    
	return ($status, $piccdata, $validbitsout);
    
}

sub picc_read_tag_serial {
    my $self = shift;
    my( $status, $uid ) = $self->picc_select;
    
    my $serialstring = '';
    if( $status == MFRC522_STATUS_OK ) {
        for (my $i = 0; $i < $uid->{'size'}; $i ++ ) {
            $serialstring .= '-' if $serialstring;
            $serialstring .= sprintf('%02X', $uid->{'data'}->[$i]);
        }
    }
    
    return ( $status, $uid, $serialstring );
}

sub picc_select {
    my ($self, $uid, $validbits ) = @_;
    
    $uid //= {
        size => 0,
        data => [],
        sak  => 0,
    };
    
    $validbits ||= 0;
    
#   bool uidComplete;
#	bool selectDone;
#	bool useCascadeTag;
#	byte cascadeLevel = 1;
#	MFRC522::StatusCode result;
#	byte count;
#	byte checkBit;
#	byte index;
#	byte uidIndex;					// The first index in uid->uidByte[] that is used in the current Cascade Level.
#	int8_t currentLevelKnownBits;		// The number of known UID bits in the current Cascade Level.
#	byte buffer[9];					// The SELECT/ANTICOLLISION commands uses a 7 byte standard frame + 2 bytes CRC_A
#	byte bufferUsed;				// The number of bytes used in the buffer, ie the number of bytes to transfer to the FIFO.
#	byte rxAlign;					// Used in BitFramingReg. Defines the bit position for the first bit received.
#	byte txLastBits;				// Used in BitFramingReg. The number of valid bits in the last transmitted byte. 
#	byte *responseBuffer;
#	byte responseLength;
#	
#	// Description of buffer structure:
#	//		Byte 0: SEL 				Indicates the Cascade Level: PICC_CMD_SEL_CL1, PICC_CMD_SEL_CL2 or PICC_CMD_SEL_CL3
#	//		Byte 1: NVB					Number of Valid Bits (in complete command, not just the UID): High nibble: complete bytes, Low nibble: Extra bits. 
#	//		Byte 2: UID-data or CT		See explanation below. CT means Cascade Tag.
#	//		Byte 3: UID-data
#	//		Byte 4: UID-data
#	//		Byte 5: UID-data
#	//		Byte 6: BCC					Block Check Character - XOR of bytes 2-5
#	//		Byte 7: CRC_A
#	//		Byte 8: CRC_A
#	// The BCC and CRC_A are only transmitted if we know all the UID bits of the current Cascade Level.
#	//
#	// Description of bytes 2-5: (Section 6.5.4 of the ISO/IEC 14443-3 draft: UID contents and cascade levels)
#	//		UID size	Cascade level	Byte2	Byte3	Byte4	Byte5
#	//		========	=============	=====	=====	=====	=====
#	//		 4 bytes		1			uid0	uid1	uid2	uid3
#	//		 7 bytes		1			CT		uid0	uid1	uid2
#	//						2			uid3	uid4	uid5	uid6
#	//		10 bytes		1			CT		uid0	uid1	uid2
#	//						2			CT		uid3	uid4	uid5
#	//						3			uid6	uid7	uid8	uid9
	
	# // Sanity checks
	if ($validbits > 80) {
		return ( MFRC522_STATUS_INVALID );
	}
	
	# // Prepare MFRC522
	$self->clear_bit_mask(MFRC522_REG_CollReg, 0x80);		#// ValuesAfterColl=1 => Bits received after collision are cleared.
	
	#// Repeat Cascade Level loop until we have a complete UID.
	my $uidComplete = 0;
    my $cascadeLevel = 1;
    
    my( $uidIndex, $useCascadeTag, $currentLevelKnownBits, $index, $selectDone, $txLastBits, $bufferUsed, $rxAlign );
    
    my ($respstatus, $respdata, $respvalidbits);
    my ( $crcstatus, $cbuffer1, $cbuffer2 );
    
    my ( $responseIndex, $responseLength );
    
    my @buffer = ();
    
	while (!$uidComplete) {
		#// Set the Cascade Level in the SEL byte, find out if we need to use the Cascade Tag in byte 2.
        
        $selectDone = 0;
        
        if( $cascadeLevel == 1 ) {
            
            $buffer[0] = MIFARE_SELECT_CL1;
            $uidIndex = 0,
            $useCascadeTag = ( $validbits && $uid->{'size'} > 4 ) ? 1 : 0;
        } elsif( $cascadeLevel == 2 ) {
			            
            $buffer[0] = MIFARE_SELECT_CL2;
            $uidIndex = 3,
            $useCascadeTag = ( $validbits && $uid->{'size'} > 7 ) ? 1 : 0;
		
        } elsif( $cascadeLevel == 3 ) {
			            
            $buffer[0] = MIFARE_SELECT_CL3;
            $uidIndex = 6,
            $useCascadeTag = 0
			
		} else {
            # should not get here
            # warn qq( cascade level $cascadeLevel);
            return ( MFRC522_STATUS_INTERNAL_ERROR );
        }
		
		# // How many UID bits are known in this Cascade Level?
		$currentLevelKnownBits = $validbits - (8 * $uidIndex);
        
		if ($currentLevelKnownBits < 0) {
			$currentLevelKnownBits = 0;
		}
                
		# // Copy the known bits from uid->uidByte[] to buffer[]
		$index = 2; #// destination index in buffer[]
		if ($useCascadeTag) {
			$buffer[$index++] = MIFARE_CASCADE;
		}
        
		my $bytesToCopy = int($currentLevelKnownBits / 8) + ($currentLevelKnownBits % 8 ? 1 : 0); # // The number of bytes needed to represent the known bits for this level.
		
        if ($bytesToCopy) {
			my $maxBytes = $useCascadeTag ? 3 : 4; #// Max 4 bytes in each Cascade Level. Only 3 left if we use the Cascade Tag
			if ($bytesToCopy > $maxBytes) {
				$bytesToCopy = $maxBytes;
			}
			for (my $count = 0; $count < $bytesToCopy; $count++) {
				$buffer[$index++] = $uid->{'data'}->[$uidIndex + $count] || 0;
			}
		}
		# // Now that the data has been copied we need to include the 8 bits in CT in currentLevelKnownBits
		if ($useCascadeTag) {
			$currentLevelKnownBits += 8;
		}
		
		# // Repeat anti collision loop until we can transmit all UID bits + BCC and receive a SAK - max 32 iterations.
		
		while (!$selectDone) {
			# // Find out how many bits and bytes to send and receive.
			if ($currentLevelKnownBits >= 32) { # // All UID bits in this Cascade Level are known. This is a SELECT.
				
				$buffer[1] = 0x70; #// NVB - Number of Valid Bits: Seven whole bytes
				#// Calculate BCC - Block Check Character
                
                for( 2,3,4,5) {
                    $buffer[$_] //= 0;
                }
                
				$buffer[6] = $buffer[2] ^ $buffer[3] ^ $buffer[4] ^ $buffer[5];
				# // Calculate CRC_A
                
                my @crcdata = @buffer[0..6];
                
                ( $crcstatus, $cbuffer1, $cbuffer2 ) = $self->pcd_calculate_crc( \@crcdata );
                
				if ($crcstatus != MFRC522_STATUS_OK) {
					return ( $crcstatus, undef, undef );
				}
                
                # set the crc result
                $buffer[7] = $cbuffer1;
                $buffer[8] = $cbuffer2;
                
				$txLastBits		= 0; #// 0 => All 8 bits are valid.
				$bufferUsed		= 9; 
				$responseLength	= 3;
                $responseIndex  = 6;
                
			} else { #// This is an ANTICOLLISION.
				
				$txLastBits		= $currentLevelKnownBits % 8;
				my $count		= int($currentLevelKnownBits / 8);	#// Number of whole bytes in the UID part.
				$index			= 2 + $count;					#// Number of whole bytes: SEL + NVB + UIDs
				$buffer[1]		= ($index << 4) + $txLastBits;	#// NVB - Number of Valid Bits
				$bufferUsed		= $index + ($txLastBits ? 1 : 0);
				$responseLength = 9 - $index;
                $responseIndex = $index;
			}
			
			#// Set bit adjustments
			$rxAlign = $txLastBits || 0;											#// Having a separate variable is overkill. But it makes the next line easier to read.
			$self->write_register(MFRC522_REG_BitFramingReg, ($rxAlign << 4) + $txLastBits);	#// RxAlign = BitFramingReg[6..4]. TxLastBits = BitFramingReg[2..0]
			
			#// Transmit the buffer and receive the response.
            
            my $getlen = $responseLength;
            
            my $sendlen = $bufferUsed -1;
           
            my @sendbuffer = @buffer[0..$sendlen];
                        
            ($respstatus, $respdata, $respvalidbits) = $self->pcd_transceive_data(\@sendbuffer, $txLastBits, $getlen, $rxAlign );
            
			$txLastBits = $respvalidbits;
            
            if($respdata && ref($respdata)) {
                
                for (my $i = 0; $i < @$respdata; $i ++) {
                    last if $i > $responseLength;
                    $buffer[ $i + $responseIndex ] = $respdata->[$i];
                }
            }
            
            if ($respstatus == MFRC522_STATUS_COLLISION) { #// More than one PICC in the field => collision.
				my $valueOfCollReg = $self->read_register(MFRC522_REG_CollReg); #// CollReg[7..0] bits are: ValuesAfterColl reserved CollPosNotValid CollPos[4:0]
				if ($valueOfCollReg & 0x20) { #// CollPosNotValid
					return ( MFRC522_STATUS_COLLISION, undef, undef ); # // Without a valid collision position we cannot continue
				}
				my $collisionPos = $valueOfCollReg & 0x1F; # // Values 0-31, 0 means bit 32.
				if ($collisionPos == 0) {
					$collisionPos = 32;
				}
				if ($collisionPos <= $currentLevelKnownBits) { #// No progress - should not happen
					return ( MFRC522_STATUS_INTERNAL_ERROR, undef, undef );
				}
				#// Choose the PICC with the bit set.
				$currentLevelKnownBits	= $collisionPos;
				my $count			= $currentLevelKnownBits % 8; #// The bit to modify
				my $checkBit		= ($currentLevelKnownBits - 1) % 8;
				$index			= 1 + int($currentLevelKnownBits / 8) + ($count ? 1 : 0); # // First byte is index 0.
				$buffer[$index]	|= (1 << $checkBit);
			} elsif ($respstatus != MFRC522_STATUS_OK) {
				return ( $respstatus, undef, undef );
			} else { # // MFRC522_STATUS_OK
                
				if ($currentLevelKnownBits >= 32) { #// This was a SELECT.
					$selectDone = 1; #// No more anticollision 
					#// We continue below outside the while.
				} else { #// This was an ANTICOLLISION.
					#/ We now have all 32 bits of the UID in this Cascade Level
					$currentLevelKnownBits = 32;
					#// Run loop again to do the SELECT.
				}
			}
		} 
		
		#// We do not check the CBB - it was constructed by us above.
		
		#// Copy the found UID bytes from buffer[] to uid->uidByte[]
		$index			= ($buffer[2] == MIFARE_CASCADE) ? 3 : 2; #// source index in buffer[]
		$bytesToCopy	= ($buffer[2] == MIFARE_CASCADE) ? 3 : 4;
		for (my $count = 0; $count < $bytesToCopy; $count++) {
            $uid->{'data'}->[$uidIndex + $count] = $buffer[$index++];
		}
		
		#// Check response SAK (Select Acknowledge)
        
        my $resplen = scalar @$respdata;
        
		if ($resplen != 3 || $respvalidbits != 0) { # // SAK must be exactly 24 bits (1 byte + CRC_A).
			return ( MFRC522_STATUS_ERROR, undef, undef );
		}
		#// Verify CRC_A - do our own calculation and store the control in buffer[2..3] - those bytes are not needed anymore.
         
        my @crcdata = @$respdata;
        pop @crcdata; pop @crcdata;
        
        ( $crcstatus, $cbuffer1, $cbuffer2 ) = $self->pcd_calculate_crc( \@crcdata );
        
		if ($crcstatus != MFRC522_STATUS_OK) {
			return ( $crcstatus, undef, undef );
		}
		if (($cbuffer1 != $respdata->[-2]) || ($cbuffer2 != $respdata->[-1])) {
			return ( MFRC522_STATUS_CRC_WRONG, undef, undef );
		}
        
		if ($respdata->[0] & 0x04) { #// Cascade bit set - UID not complete yes
			$cascadeLevel++;
		} else {
			$uidComplete = 1;
			$uid->{'sak'} = $respdata->[0];
		}
	} 
	
	#// Set correct uid->size
	$uid->{'size'} = 3 * $cascadeLevel + 1;

	return ( MFRC522_STATUS_OK, $uid, $respvalidbits );
}

sub get_status_code_name {
    my($self, $code) = @_;
    $code //= 0xEE;
    if($code == MFRC522_STATUS_OK ) {
        return 'Success.';
    } elsif($code == MFRC522_STATUS_ERROR ) {
        return 'Error in communication.';
    } elsif($code == MFRC522_STATUS_COLLISION ) {
        return 'Collision detected.';
    } elsif($code == MFRC522_STATUS_TIMEOUT ) {
        return 'Timeout in communication.';
    } elsif($code == MFRC522_STATUS_NO_ROOM ) {
        return 'A buffer is not big enough.';
    } elsif($code == MFRC522_STATUS_INTERNAL_ERROR ) {
        return 'Internal error in the code. Should not happen.';
    } elsif($code == MFRC522_STATUS_INVALID ) {
        return 'Invalid argument.';
    } elsif($code == MFRC522_STATUS_CRC_WRONG ) {
        return 'The CRC_A does not match.';
    } elsif($code == MFRC522_STATUS_MIFARE_NACK ) {
        return 'A MIFARE PICC responded with NAK.';
    } elsif($code == MFRC522_STATUS_UNSUPPORTED_TYPE ) {
        return 'Unsupported command for this PICC type.';
    } elsif($code == MFRC522_STATUS_BLOCK_NOT_ALLOWED ) {
        return 'Command not allowed for this block.';
    } elsif($code == MFRC522_STATUS_BAD_PARAM ) {
        return 'Bad parameter.';
    } else {
        return 'Unknown Error.';
    }
}

sub get_default_key {
    my $self = shift;
    my @key = (0xFF) x 6;
    return \@key;
}

sub picc_type_is_classic {
    my($self, $picctype, $sak) = @_;
    
    if(!defined($picctype) && defined($sak)) {
        $picctype = $self->picc_get_type( $sak );
    }
    
    if( $picctype && ( $picctype == MFRC522_PICC_TYPE_MIFARE_MINI
        || $picctype == MFRC522_PICC_TYPE_MIFARE_1K
        || $picctype == MFRC522_PICC_TYPE_MIFARE_4K ) ) {
        return 1;
    } else {
        return 0;
    }
}

sub picc_type_is_ultralight {
    my($self, $picctype) = @_;
    
    if( $picctype && ( $picctype == MFRC522_PICC_TYPE_MIFARE_UL ) ) {
        return 1;
    } else {
        return 0;
    }
}

sub picc_dump_tag_info {
    my($self, $uid, $key) = @_;
    
    unless($uid && ref($uid) eq 'HASH' && $uid->{'size'} && $uid->{'sak'} ) {
        return 'invalid tag uid';
    }
    
    my $output = $self->picc_dump_details($uid);
    
    my $picctype = $self->picc_get_type( $uid->{'sak'});
    if( $self->picc_type_is_classic( $picctype ) ) {
        $key = $self->get_default_key unless(defined($key));
        $output .= $self->picc_dump_classic_memory( $uid, $picctype, $key );
    } elsif( $self->picc_type_is_ultralight( $picctype ) ) {
        $key = $self->get_default_key unless(defined($key));
        $output .= $self->picc_dump_ultralight_memory( $uid, $picctype, $key );
    } else {
        my $piccname = $self->picc_get_type_name( $picctype );
        $output = qq(Dumping memory contents not implemented for $piccname\n);
    }
    
    return $output . qq(\n);
}

sub picc_dump_ultralight_memory {
    my($self, $uid, $picctype, $key) = @_;
    my $piccname = $self->picc_get_type_name( $picctype );
    my $output = qq(Dumping memory contents not implemented for $piccname\n);
    return $output;
}

sub picc_dump_classic_memory {
    my($self, $uid, $picctype, $key) = @_;
    
    my $output = '';
    my $no_of_sectors = 0;
    if( $picctype == MFRC522_PICC_TYPE_MIFARE_MINI ) {
        $no_of_sectors = 5;
    } elsif( $picctype == MFRC522_PICC_TYPE_MIFARE_1K ) {
        $no_of_sectors = 16;
    } elsif( $picctype == MFRC522_PICC_TYPE_MIFARE_4K ) {
        $no_of_sectors = 40;
    }
    
	#// Dump sectors, highest address first.
	if ($no_of_sectors) {
        $output .= qq(Sector Block   0  1  2  3   4  5  6  7   8  9 10 11  12 13 14 15  AccessBits\n);
        for (my $i = $no_of_sectors -1; $i >= 0; $i-- ) {
            $output .= $self->picc_dump_classic_sector( $uid, $key, $i );
		}
	}
    
    my $haltstatus = $self->picc_halt_active;
    unless($haltstatus == MFRC522_STATUS_OK) {
        $output .= $self->get_status_code_name( $haltstatus ) . qq(\n);
    }
    $self->pcd_stop_crypto1;
    return $output;
}

sub pcd_authenticate {
    my($self, $command, $blockAddr, $key, $uid ) = @_;
    
    my $waitIRq = 0x10;
	    
    my @sendData = ( $command, $blockAddr );
    
	for (my $i = 0; $i < 6; $i++) {	# // 6 key bytes
		$sendData[2 + $i] = $key->[$i];
	}
	#// Use the last uid bytes as specified in http://cache.nxp.com/documents/application_note/AN10927.pdf
	#// section 3.2.5 "MIFARE Classic Authentication".
	#// The only missed case is the MF1Sxxxx shortcut activation,
	#// but it requires cascade tag (CT) byte, that is not part of uid.
    
	for (my $i = 0; $i < 4; $i++) {				#// The last 4 bytes of the UID
		$sendData[8 + $i] = $uid->{'data'}->[$i + $uid->{'size'} -4];
	}
	
    my ($piccstatus, $piccdata, $piccvalidbits) = $self->pcd_communicate_with_picc( MFRC522_AUTHENT, $waitIRq, \@sendData  );
	return $piccstatus;
}

sub picc_dump_classic_sector {
    my($self, $uid, $key, $sector) = @_;
    
    my $output = '';
    
    my ( $status, $firstBlock, $no_of_blocks, $isSectorTrailer );
	#byte firstBlock;		// Address of lowest address to dump actually last block dumped)
	#byte no_of_blocks;		// Number of blocks in sector
	#bool isSectorTrailer;	// Set to true while handling the "last" (ie highest address) in the sector.
	
	#// The access bits are stored in a peculiar fashion.
	#// There are four groups:
	#//		g[3]	Access bits for the sector trailer, block 3 (for sectors 0-31) or block 15 (for sectors 32-39)
	#//		g[2]	Access bits for block 2 (for sectors 0-31) or blocks 10-14 (for sectors 32-39)
	#//		g[1]	Access bits for block 1 (for sectors 0-31) or blocks 5-9 (for sectors 32-39)
	#//		g[0]	Access bits for block 0 (for sectors 0-31) or blocks 0-4 (for sectors 32-39)
	#// Each group has access bits [C1 C2 C3]. In this code C1 is MSB and C3 is LSB.
	#// The four CX bits are stored together in a nible cx and an inverted nible cx_.
	#byte c1, c2, c3;		// Nibbles
	#byte c1_, c2_, c3_;		// Inverted nibbles
    
    my ( $c1, $c2, $c3, $c1x, $c2x, $c3x );
    
	#bool invertedError;		// True if one of the inverted nibbles did not match
	#byte g[4];				// Access bits for each of the four groups.
	#byte group;				// 0-3 - active group for access bits
	#bool firstInGroup;		// True for the first block dumped in the group
    
    my( $invertedError, $group, $firstInGroup );
    my @g = (0,0,0,0);
	
	#// Determine position and size of sector.
	if ($sector < 32) { #// Sectors 0..31 has 4 blocks each
		$no_of_blocks = 4;
		$firstBlock = $sector * $no_of_blocks;
	} elsif ($sector < 40) { #// Sectors 32-39 has 16 blocks each
		$no_of_blocks = 16;
		$firstBlock = 128 + ($sector - 32) * $no_of_blocks;
	}  else { #// Illegal input, no MIFARE Classic PICC has more than 40 sectors.
		return qq(Illegal input, no MIFARE Classic PICC has more than 40 sectors\n);
	}
		
	#// Dump blocks, highest address first.
	my $byteCount;
	my @buffer = ( 0 ) x 18;
	my $blockAddr;
	$isSectorTrailer = 1;
	$invertedError = 0;	# // Avoid "unused variable" warning.
	for (my $blockOffset = $no_of_blocks - 1; $blockOffset >= 0; $blockOffset-- ) {
		$blockAddr = $firstBlock + $blockOffset;
		#// Sector number - only on first line
		if ($isSectorTrailer) {
			if($sector < 10) {
				$output .= '   '; #// Pad with spaces
            } else {
				$output .= '  '; #// Pad with spaces
            }
			$output .= $sector;
			$output .= '   ';
		} else {
			$output .= '       ';
		}
		# // Block number
		if($blockAddr < 10) {
			$output .= '   '; #// Pad with spaces
        } else {
			if($blockAddr < 100) {
				$output .= '  '; # // Pad with spaces
            } else {
				$output .= ' '; # // Pad with spaces
            }
		}
		$output .= $blockAddr;
		$output .= '  ';
		#// Establish encrypted communications before reading the first block
		if ($isSectorTrailer) {
			# status = PCD_Authenticate(PICC_CMD_MF_AUTH_KEY_A, firstBlock, key, uid);
            
            $status = $self->pcd_authenticate( MIFARE_AUTHENT1A , $firstBlock, $key, $uid );
            
			if ($status != MFRC522_STATUS_OK) {
				$output .= 'authentication failed: ';
				$output .= $self->get_status_code_name($status);
                $output .= qq(\n);
				return $output;
			}
		}
		#// Read block
		# byteCount = sizeof(buffer);
        
        my ( $mstatus, $mdata, $mvalidbits ) = $self->mifare_read( $blockAddr );
        
		#if (status != STATUS_OK) {
        if ($mstatus != MFRC522_STATUS_OK) {
            $output .= 'mifare_read() failed: ';
            $output .= $self->get_status_code_name($mstatus);
            $output .= qq(\n);
            next;
		}
		
		# // Dump data
		for (my $index = 0; $index < 16; $index++) {
            $output .= sprintf(' %02X', $mdata->[$index]);
            
			if (($index % 4) == 3) {
                $output .= ' ';
			}
		}
		#// Parse sector trailer data
		if ($isSectorTrailer) {
			$c1  = $mdata->[7] >> 4;
			$c2  = $mdata->[8] & 0xF;
			$c3  = $mdata->[8] >> 4;
			$c1x = $mdata->[6] & 0xF;
			$c2x = $mdata->[6] >> 4;
			$c3x = $mdata->[7] & 0xF;
			$invertedError = ($c1 != (~$c1x & 0xF)) || ($c2 != (~$c2x & 0xF)) || ($c3 != (~$c3x & 0xF));
			$g[0] = (($c1 & 1) << 2) | (($c2 & 1) << 1) | (($c3 & 1) << 0);
			$g[1] = (($c1 & 2) << 1) | (($c2 & 2) << 0) | (($c3 & 2) >> 1);
			$g[2] = (($c1 & 4) << 0) | (($c2 & 4) >> 1) | (($c3 & 4) >> 2);
			$g[3] = (($c1 & 8) >> 1) | (($c2 & 8) >> 2) | (($c3 & 8) >> 3);
			$isSectorTrailer = 0;
		}
		
		#// Which access group is this block in?
		if ($no_of_blocks == 4) {
			$group = $blockOffset;
			$firstInGroup = 1;
		} else {
			$group = int($blockOffset / 5);
			$firstInGroup = ($group == 3) || ($group != int(($blockOffset + 1) / 5));
		}
		
		if ($firstInGroup) {
			# // Print access bits
            $output .= ' [ ';
            $output .= sprintf(' %s %s %s ] ', ($g[$group] >> 2) & 1, ($g[$group] >> 1) & 1, $g[$group] & 1 ); 
            
			if ($invertedError) {
                $output .= 'Inverted access bits did not match! ';
			}
		}
		
		if ($group != 3 && ($g[$group] == 1 || $g[$group] == 6)) { # // Not a sector trailer, a value block
			          
            for my $dex ( 0, 1, 2, 3 ) {
                $mdata->[$dex] //= 0;
            }
            my $value = ( $mdata->[3] << 24) | ( $mdata->[2] << 16 ) | ( $mdata->[1] << 8 ) | $mdata->[0];
            $output .= sprintf(' Value=0x%02X', $value );
			
            $output .= sprintf(' Adr=0x', $mdata->[12] );
		}
		 $output .= qq(\n);
	}
    
    return $output;
}

sub pcd_stop_crypto1 {
    my $self = shift;
    $self->clear_bit_mask(MFRC522_REG_Status2Reg, 0x08);
}

sub picc_halt_active {
    my($self) = @_;
        
    my @buffer = ( MIFARE_HALT , 0);
    
	#// Calculate CRC_A
    
    my ( $crcstatus, $cbuffer1, $cbuffer2 ) = $self->pcd_calculate_crc( \@buffer );
	
	if ($crcstatus != MFRC522_STATUS_OK) {
		return $crcstatus;
	}
    $buffer[2] = $cbuffer1;
    $buffer[3] = $cbuffer2;
	
	#// Send the command.
	#// The standard says:
	#//		If the PICC responds with any modulation during a period of 1 ms after the end of the frame containing the
	#//		HLTA command, this response shall be interpreted as 'not acknowledge'.
	#// We interpret that this way: Only STATUS_TIMEOUT is a success.
	
     #my($self, $senddata, $validbitsin, $getlen, $rxalign, $checkcrc ) = @_;
    
    # result = PCD_TransceiveData(buffer, sizeof(buffer), nullptr, 0);
    
    my ( $tstatus, $tdata, $tvalidbits ) = $self->pcd_transceive_data( \@buffer );
    
	if ($tstatus == MFRC522_STATUS_TIMEOUT) {
		return MFRC522_STATUS_OK;
	}
	if ($tstatus == MFRC522_STATUS_OK) {  #// NOT ok in this case ;-)
		return MFRC522_STATUS_ERROR;
	}
    
	return $tstatus;
}

sub picc_dump_details {
    my($self, $uid) = @_;
    unless($uid && ref($uid) eq 'HASH' && $uid->{'size'} && $uid->{'sak'} ) {
        return 'Invalid tag uid' . qq(\n);
    }
    
    my $output = 'Tag UID  :';
    
    for (my $i = 0; $i < $uid->{'size'}; $i++) {
        $output .= sprintf(' %02X', $uid->{'data'}->[$i] );
	}
    $output .= qq(\n);
    
    $output .= 'Tag SAK  :';
    $output .= sprintf(' %02X', $uid->{'sak'} );
    $output .= qq(\n);
    
    my $picctype = $self->picc_get_type( $uid->{'sak'});
    $output .= 'Tag Type : ';
    $output .= $self->picc_get_type_name( $picctype );
    $output .= qq(\n);
    
    return $output;
}

sub picc_get_type {
    my ( $self, $sak ) = @_;
    $sak &= 0x7F;
    if( $sak == 0x04 ) {
        return MFRC522_PICC_TYPE_NOT_COMPLETE;
    } elsif( $sak == 0x09 ) {
        return MFRC522_PICC_TYPE_MIFARE_MINI;
    } elsif( $sak == 0x08 ) {
        return MFRC522_PICC_TYPE_MIFARE_1K;
    } elsif( $sak == 0x18 ) {
        return MFRC522_PICC_TYPE_MIFARE_4K;
    } elsif( $sak == 0x00 ) {
        return MFRC522_PICC_TYPE_MIFARE_UL;
    } elsif( $sak == 0x10 || $sak == 0x11 ) {
        return MFRC522_PICC_TYPE_MIFARE_PLUS;
    } elsif( $sak == 0x01 ) {
        return MFRC522_PICC_TYPE_TNP3XXX;
    } elsif( $sak == 0x20 ) {
        return MFRC522_PICC_TYPE_ISO_14443_4;
    } elsif( $sak == 0x40 ) {
        return MFRC522_PICC_TYPE_ISO_18092;
    } else {
        return MFRC522_PICC_TYPE_UNKNOWN;
    }
}

sub picc_get_type_name {
    my($self, $type) = @_;
    return 'Unknown type' unless(defined($type) && $type =~ /^[0-9]+$/);
    if( $type == MFRC522_PICC_TYPE_ISO_14443_4 ) {
        return 'PICC compliant with ISO/IEC 14443-4';
    } elsif($type == MFRC522_PICC_TYPE_ISO_18092 ) {
        return 'PICC compliant with ISO/IEC 18092 (NFC)';
    } elsif($type == MFRC522_PICC_TYPE_MIFARE_MINI ) {
        return 'MIFARE Classic Mini, 320 bytes';
    } elsif($type == MFRC522_PICC_TYPE_MIFARE_1K ) {
        return 'MIFARE Classic 1KB';
    } elsif($type == MFRC522_PICC_TYPE_MIFARE_4K ) {
        return 'MIFARE Classic 4KB';
    } elsif($type == MFRC522_PICC_TYPE_MIFARE_UL ) {
        return 'MIFARE Ultralight or Ultralight C';
    } elsif($type == MFRC522_PICC_TYPE_MIFARE_PLUS ) {
        return 'MIFARE Plus';
    } elsif($type == MFRC522_PICC_TYPE_MIFARE_DESFIRE ) {
        return 'MIFARE DESFire';
    } elsif($type == MFRC522_PICC_TYPE_TNP3XXX ) {
        return 'MIFARE TNP3XXX';
    } elsif($type == MFRC522_PICC_TYPE_NOT_COMPLETE ) {
        return 'SAK indicates UID is not complete.';
    } else {
        return 'Unknown type';
    }
   
}

sub mifare_read {
    my( $self, $blockAddr) = @_;
    
    my @buffer = ( MIFARE_READ , $blockAddr );
    
	#// Calculate CRC_A
    
    my ( $crcstatus, $cbuffer1, $cbuffer2 ) = $self->pcd_calculate_crc( \@buffer );
	
	if ($crcstatus != MFRC522_STATUS_OK) {
		return ( $crcstatus, undef, undef );
	}
    $buffer[2] = $cbuffer1;
    $buffer[3] = $cbuffer2;
	
	# // Transmit the buffer and receive the response, validate CRC_A.
    
    my $getlen = 16;
    my ( $status, $data, $validbits ) = $self->pcd_transceive_data( \@buffer, 0, $getlen, 0, 1  );
    return ( $status, $data, $validbits );
}

sub mifare_write {
    my( $self, $blockAddr, $buffer) = @_;
    
    unless( $buffer && ref($buffer) eq 'ARRAY' && scalar(@$buffer) == 16 ) {
        return MFRC522_STATUS_INVALID;
    }
    
    my @commandbuffer = ( MIFARE_WRITE , $blockAddr );
        
    my ( $status, $outdata, $validbits ) = $self->pcd_mifare_transceive( \@commandbuffer );
    
	if ($status != MFRC522_STATUS_OK) {
        
		return $status;
	}
	    
    ( $status, $outdata, $validbits ) = $self->pcd_mifare_transceive( $buffer );
	
	return $status;
}

sub write_sector_trailer {
    my($self, $blockaddr, $key, $uid, $newA, $newB, $accessbitsin, $gpb ) = @_;
    
    for ( $blockaddr, $key, $newA, $newB ) {
        if(!defined($_)) {
            carp 'missing block or keys param';
            return MFRC522_STATUS_BAD_PARAM;
        }
    }
    
    unless( $self->picc_type_is_classic( undef, $uid->{'sak'} ) ) {
        return MFRC522_STATUS_UNSUPPORTED_TYPE;
    };
    
    unless( $self->picc_block_is_sector_trailer( $blockaddr ) ){
        carp 'block address is not a sector trailer';
        return MFRC522_STATUS_BAD_PARAM;
    }
    
    if(defined($accessbitsin)) {
        unless( ref($accessbitsin) eq 'ARRAY' && scalar @$accessbitsin == 4 )  {
            carp 'Access bits provided does not contain 4 bytes';
            return MFRC522_STATUS_BAD_PARAM;
        }
    }
    
    # get Existing data
    
    my ( $mstatus, $existing, $mvalidbits ) = $self->read_block_data( $blockaddr, $uid, $key );
    
    if( $mstatus != MFRC522_STATUS_OK ) {
        return $mstatus;
    }
    
    my @databuffer = ();
    
    my $keylen = MIFARE_MF_KEY_SIZE;
    my $index  = $keylen;  # The first byte of the access bits
    
    # KEY A
    for (my $i = 0; $i < $keylen; $i++) {
        $databuffer[$i] = $newA->[$i];
    }   
    
    # ACCESS BITS
    if(defined($accessbitsin)) {
        my $accessbits = $self->mifare_set_access_bits( @$accessbitsin );
        for (my $i = 0; $i < 3; $i++) {
            $databuffer[$i + $index] = $accessbits->[$i];
        }
    } else {
        for (my $i = 0; $i < 3; $i++) {
            $databuffer[$i + $index] = $existing->[$i + $index];
        }
    }
    
    $index += 3; # we added 3 bytes
    
    # GENERAL PURPOSE BYTE
    if(defined($gpb)) {
        $databuffer[$index] = $gpb;
    } else {
        $databuffer[$index] = $existing->[$index];
    }
    
    $index ++; # we added a byte
    
    # KEY B
    for (my $i = 0; $i < $keylen; $i++) {
        $databuffer[$i + $index] = $newB->[$i];
    }
    
    # flag switch before call
    $self->_allow_write_st(1);
        
    return $self->write_block_data( $blockaddr, $uid, \@databuffer, $key );
}

sub picc_block_is_sector_trailer {
    my($self, $block) = @_;
    
    unless(defined($block) && $block =~ /^[0-9]+$/ ) {
        carp 'block param must be a valid block number';
        return 0;
    }
    if( $block < 128 ) {
        if( ($block % 4) == 3 ) {
            return 1;
        } else {
            return 0;
        }
    } else {
        if( ( $block % 16 ) == 15 ) {
            return 1;
        } else {
            return 0;
        }
    }
}

sub get_sector_trailer_blocks {
    my($self, $picctype) = @_;
    
    my $sts = {};
    
    if( $picctype == MFRC522_PICC_TYPE_MIFARE_MINI ) {
        for( my $i = 3; $i < 20; $i += 4 ) {
            $sts->{$i} = 4;
        }
    } elsif( $picctype == MFRC522_PICC_TYPE_MIFARE_1K ) {
        for( my $i = 3; $i < 64; $i += 4 ) {
            $sts->{$i} = 4;
        }
    } elsif( $picctype == MFRC522_PICC_TYPE_MIFARE_4K ) {
        for( my $i = 3; $i < 126; $i += 4 ) {
            $sts->{$i} = 4;
        }
        for( my $i = 143; $i < 256; $i += 16 ) {
            $sts->{$i} = 16;
        }
    }
    return $sts;
}

sub write_uid_block {
    my( $self, $uid, $data, $key ) = @_;
    my $block = 0;
    $self->_allow_write_block0(1);
    return $self->write_block_data( $block, $uid, $data, $key );
}

sub write_block_data {
    my( $self, $block, $uid, $data, $key ) = @_;
    $key = $self->get_default_key unless(defined($key));
    
    unless( $uid && ref($uid) eq 'HASH' && defined( $uid->{'sak'} )
            && $data && ref($data) eq 'ARRAY'
            && defined( $block ) ) {
        carp 'bad uid or data or block';
        return MFRC522_STATUS_BAD_PARAM;
    }
    
    unless( $self->picc_type_is_classic( undef, $uid->{'sak'} ) ) {
        return MFRC522_STATUS_UNSUPPORTED_TYPE;
    };
    
    # dont allow on block 0 or sector trailer block unless overridden
    if( $self->_allow_write_st ) {
        # allow writes to sector trailer
        if( !$block || $block !~ /^[0-9]+$/ ) {
            return MFRC522_STATUS_BLOCK_NOT_ALLOWED;
        }
        
    } else {
        if( ( !$block && !$self->_allow_write_block0 ) || $block !~ /^[0-9]+$/ || $self->picc_block_is_sector_trailer($block) ) {
            return MFRC522_STATUS_BLOCK_NOT_ALLOWED
        }
    }
    
    # set flags off
    $self->_allow_write_st(0);
    $self->_allow_write_block0(0);
    
    # fix up $data
    my @fixeddata = ();
    for (my $i = 0; $i < 16; $i++  ) {
        my $val = $data->[$i];
        if(!defined($val)) {
            $val = 0;
        }
        $val &= 0xFF;
        $fixeddata[$i] = $val;
    }
    
    my $authstatus = $self->pcd_authenticate( MIFARE_AUTHENT1A , $block, $key, $uid );
            
	if ( $authstatus != MFRC522_STATUS_OK ) {
        return $authstatus;
    }
    
    my $restorescanwait = $self->scanwait;
    $self->scanwait(10);
    my $writestatus = $self->mifare_write( $block, \@fixeddata );
    $self->scanwait($restorescanwait);
    return $writestatus;   
}

sub read_block_data {
    my( $self, $block, $uid, $key ) = @_;
    $key = $self->get_default_key unless(defined($key));
    
    unless( $uid && ref($uid) eq 'HASH' && defined( $uid->{'sak'}) ) {
        return ( MFRC522_STATUS_BAD_PARAM, undef  );
    }
    
    unless( $self->picc_type_is_classic( undef, $uid->{'sak'} ) ) {
        return MFRC522_STATUS_UNSUPPORTED_TYPE;
    };
    
    my $authstatus = $self->pcd_authenticate( MIFARE_AUTHENT1A , $block, $key, $uid );
            
	if ( $authstatus != MFRC522_STATUS_OK ) {
        return ( $authstatus, undef );
    }
    
    my ( $mstatus, $mdata, $mvalidbits ) = $self->mifare_read( $block );
    
    if( $mstatus == MFRC522_STATUS_OK ) {
        # data will have CRC
        pop @$mdata; pop @$mdata;
    }
    
    return ( $mstatus, $mdata, $mvalidbits );
}

sub picc_end_session {
    my $self = shift;
    $self->picc_halt_active;
    $self->pcd_stop_crypto1;   
}

sub mifare_set_uid {
    my($self, $uid, $newuid, $key) = @_;
        
    my $uidsize = ( $newuid && ref($newuid) eq 'ARRAY' ) ? scalar @$newuid : 0;
	
	#/ UID + BCC byte can not be larger than 16 together
	if (!$newuid || !$uidsize || $uidsize > 15) {
		carp 'New UID buffer empty, size 0, or size > 15 given';
		return 0;
	}
	
	#// Authenticate for reading
	    
    $key //= $self->get_default_key;
    
    my $status = $self->pcd_authenticate( MIFARE_AUTHENT1A , 1, $key, $uid );
    
	if ($status != MFRC522_STATUS_OK) {
        carp 'Authentication failed : ' . $self->get_status_code_name( $status );
        return 0;
	}
	
	#// Read block 0
    
    my ( $bdstatus, $blockdata ) = $self->read_block_data( 0, $uid, $key );
    
	if ($bdstatus != MFRC522_STATUS_OK) {
		carp 'Reading block 0 failed : ' . $self->get_status_code_name( $bdstatus );
		return 0;
	}
    
    my $bcc = 0;
	
    for (my $i = 0; $i < $uidsize; $i++ ) {
        $blockdata->[$i] = $newuid->[$i];
        $bcc ^= $newuid->[$i];
    }
    
    $blockdata->[$uidsize] = $bcc;
	
	#// Stop encrypted traffic so we can send raw bytes
	$self->pcd_stop_crypto1();
	
	#// Try to Activate UID backdoor
    unless( $self->mifare_open_uid_backdoor ) {
        return 0;
    }
    
	#// Write modified block 0 back to card
    
	$status = $self->mifare_write( 0, $blockdata );
	if ($status != MFRC522_STATUS_OK) {
		carp 'Writing block 0 failed : ' . $self->get_status_code_name( $status );
		return 0;
	}
	
	#// Wake the card up again
	
	$self->picc_request_wakeup;
	
	return 1;
}

sub mifare_open_uid_backdoor {
    my ( $self ) = @_;

#    // Magic sequence:
#	// > 50 00 57 CD (HALT + CRC)
#	// > 40 (7 bits only)
#	// < A (4 bits only)
#	// > 43
#	// < A (4 bits only)
#	// Then you can write to sector 0 without authenticating
	
	    
    $self->picc_halt_active;
	    
    my $command = 0x40;
    my $getlen = 1;
    my $validbitssend = 7;
    
    my ( $status, $data, $validbits ) = $self->pcd_transceive_data( $command, $validbitssend, $getlen );
        
	if($status != MFRC522_STATUS_OK) {
		carp 'Card did not respond to 0x40 after HALT command. Are you sure it is a UID changeable one? : ' . $self->get_status_code_name( $status );
		return 0;
	}
    
    # good response
    unless( $data && ref($data) eq 'ARRAY' && scalar( @$data ) && $data->[0] == 0x0A ) {
        carp sprintf('Got bad response on backdoor 0x40 command : %02X : validbits %s', $data->[0], $validbits);
        return 0;
    }
    
	$command = 0x43;
	$validbitssend = 8;
    ( $status, $data, $validbits ) = $self->pcd_transceive_data( $command, $validbitssend, $getlen );
		
    if($status != MFRC522_STATUS_OK) {
        carp 'Error in communication at command 0x43, after successfully executing 0x40 : ' . $self->get_status_code_name( $status );
		return 0;
	}
    
    unless( $data && ref($data) eq 'ARRAY' && scalar( @$data ) && $data->[0] == 0x0A ) {
        carp sprintf('Got bad response on backdoor 0x43 command : %02X : validbits %s', $data->[0], $validbits);
        return 0;
    }
    
	# // You can now write to sector 0 without authenticating!
	return 1;
}


1;

__END__