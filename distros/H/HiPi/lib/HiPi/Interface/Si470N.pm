#########################################################################################
# Package        HiPi::Interface::Si470N
# Description  : Control Si4701/2/3 via I2C
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::Si470N;

#########################################################################################


# DOES NOT WORK WITH CURRENT I2C DRIVER

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi qw( :i2c :si470n :rpi );
use HiPi::GPIO;
use HiPi::Device::I2C;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw(
    devicename address
    _mapped_registers _register_names
    _register_name_order _datamap
    sdapin resetpin
    gpiodev
) );

use constant {
    DEVICEID    => 0x00,
    CHIPID      => 0x01,
    POWERCFG    => 0x02,
    CHANNEL     => 0x03,
    SYSCONFIG1  => 0x04,
    SYSCONFIG2  => 0x05,
    SYSCONFIG3  => 0x06,
    TEST1       => 0x07,
    TEST2       => 0x08,
    BOOTCONFIG  => 0x09,
    STATUSRSSI  => 0x0A,
    READCHAN    => 0x0B,
    RDSA        => 0x0C,
    RDSB        => 0x0D,
    RDSC        => 0x0E,
    RDSD        => 0x0F,
};

sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename  => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x10,
        device      => undef,
        sdapin      => I2C_SDA,
    );
    
    # get user params
    
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{resetpin}) ) {
        croak qq(you must connect a reset pin to the device and pass the GPIO number to the constructor as param 'resetpin');
    }
    
    $params{gpiodev} = HiPi::GPIO->new;
    $params{device} ||= HiPi::Device::I2C->new(
        devicename  => $params{devicename},
        busmode     => 'i2c',
    );
    
    my $self = $class->SUPER::new(%params);
        
    $self->_init();
    
    unless( $self->device->check_address( $self->address ) ) {
        $self->reset;
    } else {
        $self->device->select_address( $self->address );
        $self->read_registers;
    }
    
    return $self;
}

sub _init {
    my $self = shift;
    
    # set up register names
    
    my $regnames = {
        DEVICEID    => 0x00,
        CHIPID      => 0x01,
        POWERCFG    => 0x02,
        CHANNEL     => 0x03,
        SYSCONFIG1  => 0x04,
        SYSCONFIG2  => 0x05,
        SYSCONFIG3  => 0x06,
        TEST1       => 0x07,
        TEST2       => 0x08,
        BOOTCONFIG  => 0x09,
        STATUSRSSI  => 0x0A,
        READCHAN    => 0x0B,
        RDSA        => 0x0C,
        RDSB        => 0x0D,
        RDSC        => 0x0E,
        RDSD        => 0x0F,
    };
    
    $self->_register_names( $regnames );
    
    # and name order
    
    my @nameorder = qw(
        DEVICEID
        CHIPID
        POWERCFG
        CHANNEL
        SYSCONFIG1
        SYSCONFIG2
        SYSCONFIG3
        TEST1
        TEST2
        BOOTCONFIG
        STATUSRSSI
        READCHAN
        RDSA
        RDSB
        RDSC
        RDSD
    );
    
    $self->_register_name_order( \@nameorder );
    
    # configure the data items
    
    my $datamap = {
    # DEVICEID
        PN          => { word => DEVICEID   , shiftbits => [  0, 12,  4 ] },
        MFGID       => { word => DEVICEID   , shiftbits => [  4,  0, 12 ] },
        
    # CHIPID
        REV         => { word => CHIPID     , shiftbits => [  0, 10,  6 ] },
        DEV         => { word => CHIPID     , shiftbits => [  6,  6,  4 ] },
        FIRMWARE    => { word => CHIPID     , shiftbits => [ 10,  0,  6 ] },
        
    # POWERCFG
        DSMUTE      => { word => POWERCFG   , shiftbits => [  0, 15,  1 ] },
        DMUTE       => { word => POWERCFG   , shiftbits => [  1, 14,  1 ] },
        MONO        => { word => POWERCFG   , shiftbits => [  2, 13,  1 ] },
        # RESERVED  => { word => POWERCFG   , shiftbits => [  3, 12,  1 ] },
        RDSM        => { word => POWERCFG   , shiftbits => [  4, 11,  1 ] },
        SKMODE      => { word => POWERCFG   , shiftbits => [  5, 10,  1 ] },
        SEEKUP      => { word => POWERCFG   , shiftbits => [  6,  9,  1 ] },
        SEEK        => { word => POWERCFG   , shiftbits => [  7,  8,  1 ] },
        # RESERVED  => { word => POWERCFG   , shiftbits => [  8,  7,  1 ] },
        DISABLE     => { word => POWERCFG   , shiftbits => [  9,  6,  1 ] },
        # RESERVED  => { word => POWERCFG   , shiftbits => [ 10,  1,  5 ] },
        ENABLE      => { word => POWERCFG   , shiftbits => [ 15,  0,  1 ] },
    
    # CHANNEL
        TUNE        => { word => CHANNEL    , shiftbits => [  0, 15,  1 ] },
        # RESERVED  => { word => CHANNEL    , shiftbits => [  1, 10,  5 ] },
        CHAN        => { word => CHANNEL    , shiftbits => [  6,  0, 10 ] },
        
    # SYSCONFIG1
        RDSIEN      => { word => SYSCONFIG1 , shiftbits => [  0, 15,  1 ] },
        STCIEN      => { word => SYSCONFIG1 , shiftbits => [  1, 14,  1 ] },
        # RESERVED  => { word => SYSCONFIG1 , shiftbits => [  2, 13,  1 ] },
        RDS         => { word => SYSCONFIG1 , shiftbits => [  3, 12,  1 ] },
        DE          => { word => SYSCONFIG1 , shiftbits => [  4, 11,  1 ] },
        AGCD        => { word => SYSCONFIG1 , shiftbits => [  5, 10,  1 ] },
        # RESERVED  => { word => SYSCONFIG1 , shiftbits => [  6,  8,  2 ] },
        BLNDADJ     => { word => SYSCONFIG1 , shiftbits => [  8,  6,  2 ] },
        GPIO3       => { word => SYSCONFIG1 , shiftbits => [ 10,  4,  2 ] },
        GPIO2       => { word => SYSCONFIG1 , shiftbits => [ 12,  2,  2 ] },
        GPIO1       => { word => SYSCONFIG1 , shiftbits => [ 14 , 0,  2 ] },
        
    # SYSCONFIG2
        SEEKTH      => { word => SYSCONFIG2 , shiftbits => [  0,  8,  8 ] },
        BAND        => { word => SYSCONFIG2 , shiftbits => [  8,  6,  2 ] },
        SPACE       => { word => SYSCONFIG2 , shiftbits => [ 10,  4,  2 ] },
        VOLUME      => { word => SYSCONFIG2 , shiftbits => [ 12,  0,  4 ] },
        
    # SYSCONFIG3
        SMUTER      => { word => SYSCONFIG3 , shiftbits => [  0, 14,  2 ] },
        SMUTEA      => { word => SYSCONFIG3 , shiftbits => [  2, 12,  2 ] },
        # RESERVED  => { word => SYSCONFIG3 , shiftbits => [  4,  9,  3 ] },
        VOLEXT      => { word => SYSCONFIG3 , shiftbits => [  7,  8,  1 ] },
        SKSNR       => { word => SYSCONFIG3 , shiftbits => [  8,  4,  4 ] },
        SKCNT       => { word => SYSCONFIG3 , shiftbits => [ 12,  0,  4 ] },
        
    # TEST1
        XOSCEN      => { word => TEST1      , shiftbits => [  0, 15,  1 ] },
        AHIZEN      => { word => TEST1      , shiftbits => [  1, 14,  1 ] },
        # RESERVED  => { word => TEST1      , shiftbits => [  2,  0, 14 ] },
        
    # STATUSRSSI
        RDSR        => { word => STATUSRSSI , shiftbits => [  0, 15,  1 ] },
        STC         => { word => STATUSRSSI , shiftbits => [  1, 14,  1 ] },
        SFBL        => { word => STATUSRSSI , shiftbits => [  2, 13,  1 ] },
        AFCRL       => { word => STATUSRSSI , shiftbits => [  3, 12,  1 ] },
        RDSS        => { word => STATUSRSSI , shiftbits => [  4, 11,  1 ] },
        BLERA       => { word => STATUSRSSI , shiftbits => [  5,  9,  2 ] },
        ST          => { word => STATUSRSSI , shiftbits => [  7,  8,  1 ] },
        RSSI        => { word => STATUSRSSI , shiftbits => [  8,  0,  8 ] },
    
    # READCHAN
        BLERB       => { word => READCHAN   , shiftbits => [  0, 14,  2 ] },
        BLERC       => { word => READCHAN   , shiftbits => [  2, 12,  2 ] },
        BLERD       => { word => READCHAN   , shiftbits => [  4, 10,  2 ] },
        READCHAN    => { word => READCHAN   , shiftbits => [  6,  0, 10 ] },
    
    };
    
    $self->_datamap( $datamap );
    
    return;
}

sub reset {
    my $self = shift;
    
    # disconnect from i2c device
    $self->device->close;
    $self->device( undef );
    
    my $rstpin = $self->resetpin;
    my $sdapin = $self->sdapin;  

    # set reset pin and sda pin as output
    $self->gpiodev->set_pin_mode( $rstpin, RPI_MODE_OUTPUT );
    $self->gpiodev->set_pin_mode( $sdapin, RPI_MODE_OUTPUT );
         
    # set reset and sda pins low
   
    $self->gpiodev->set_pin_level( $sdapin, RPI_LOW );
    
    # delay
    $self->sleep_seconds( 0.1 );
    
    $self->gpiodev->set_pin_level( $rstpin, RPI_LOW );
    
    # delay
    $self->sleep_seconds( 0.1 );
    
    # set reset high
    $self->gpiodev->set_pin_level( $rstpin, RPI_HIGH );

    # delay
    $self->sleep_seconds( 0.1 );

    # restore I2C operation
    $self->gpiodev->set_pin_mode( $sdapin, RPI_MODE_ALT0 );
    
    # delay
    $self->sleep_seconds( 0.1 );
    
    $self->device(HiPi::Device::I2C->new( address => $self->address, busmode => 'i2c' ) );
    
    $self->read_registers;
    $self->set_register(TEST1, 0x8100);
    $self->update_registers( 0.5 );
    
    # setup mode
    $self->set_register(POWERCFG, 1);
    
    # set for europe
    $self->configure_europe(1);
    
    # seek settings
    $self->set_config_value('SEEKTH', 0x19);
    $self->set_config_value('SKSNR', 0x4);
    $self->set_config_value('SKCNT', 0x8);
    
    $self->update_registers( 0.1 );
    $self->read_registers();
    
    return;
}

sub power_off {
    my $self = shift;
    $self->set_config_value('ENABLE', 1);
    $self->set_config_value('DISABLE', 1);
    $self->set_config_value('RDS', 0);
    
    $self->update_registers( 0.1 );
}

sub power_on {
    my $self = shift;
    $self->set_config_value('ENABLE', 1);
    $self->update_registers( 0.1 );
}

sub name_to_register {
    my($self, $rname) = @_;
    $rname //= 'UNKNOWN';
    if( exists($self->_register_names->{$rname}) ) {
        return $self->_register_names->{$rname};
    } else {
        carp qq(register name $rname is unknown);
        return undef;
    }
}

sub register_to_name {
    my( $self, $register ) = @_;
    $register //= -1;
    return 'UNKNOWN' if(( $register < 0 ) || ($register > 15));
    return $self->_register_name_order->[$register];
}

sub read_registers {
    my($self) = @_;
    
    my @bytes = $self->device->bus_read( undef, 32 );
    
    # change 32 bytes into 16 16 bit words
    my @words = ();
    for ( my $i = 0; $i < @bytes; $i += 2  ) {
        push @words, ( $bytes[$i] << 8 ) + $bytes[$i + 1];
    }
    
    # map to correct write order
    
    my @mappedwords = ();
    for ( my $i = 6; $i < 16; $i ++ ) {
        $mappedwords[$i - 6] = $words[$i];
    }
    for ( my $i = 0; $i < 6; $i ++ ) {
        $mappedwords[$i + 10] = $words[$i];
    }
    
    $self->_mapped_registers( \@mappedwords );
    
    return ( wantarray ) ? @{$self->_mapped_registers } : 1;
}

sub write_registers {
    my($self) = @_;
    my $regvals = $self->_mapped_registers;
    return unless( $regvals && ref( $regvals ) eq 'ARRAY');
    
    my @bytes = (); 
    
    # write words 2 to 7
    for ( my $i = 2; $i < 8; $i ++) {
        my $high = $regvals->[$i] >> 8;
        my $low  = $regvals->[$i] & 0xFF;
        push @bytes, ( $high, $low );
    }
    
    my $rval = $self->device->bus_write( @bytes );
    return $rval;
}

sub update_registers {
    my($self, $delay) = @_;
    $delay ||= 0.1;
    $self->write_registers();
    $self->sleep_seconds( $delay );
    $self->read_registers;
    return 1;
}

sub set_config_value {
    my( $self, $valuename, $newvalue ) = @_;
    $valuename //= 'UNKNOWN';
    $newvalue ||= 0;
    my $config = $self->_datamap->{$valuename};
    unless( $config ) {
        carp qq(unknownvalue $valuename);
        return undef;
    }
    my $register = $config->{word};
    my $wordname = $self->register_to_name( $register );
    my $currentword = $self->get_register($register);

    my( $bitsbefore, $bitsafter, $bitlen ) = @{ $config->{shiftbits} };
    
    my $mask = ( (2 ** $bitlen) -1 ) << $bitsafter;
    
    my $currentvalue = ($currentword & $mask) >> $bitsafter;
    
    return $currentvalue if $newvalue == $currentvalue;
    
    my $newbits = $newvalue << $bitsafter;
    my $newword = ($currentword & ~$mask) | ($newbits & $mask);
    
    $self->set_register($register, $newword);
    return $newvalue;
}

sub get_word_value {
    my($self, $wordname) = @_;
    my $register = $self->name_to_register( $wordname );
    my $word = $self->get_register($register);
    return $word;
}

sub get_config_value {
    my($self, $valuename) = @_;
    $valuename //= 'UNKNOWN';
    my $config = $self->_datamap->{$valuename};
    unless( $config ) {
        carp qq(unknownvalue $valuename);
        return undef;
    }
    my $currentword = $self->get_register($config->{word});
    my( $bitsbefore, $bitsafter, $bitlen ) = @{ $config->{shiftbits} };
    
    my $mask = ( (2 ** $bitlen) -1 ) << $bitsafter;
    my $currentvalue = ($currentword & $mask) >> $bitsafter;
    return $currentvalue;
}

sub configure_europe {
    my($self, $skipwrite) = @_;
    $self->set_config_value('DE', 1);
    $self->set_config_value('BAND', 0);
    $self->set_config_value('SPACE', 1);
    $self->update_registers( 0.1 ) unless $skipwrite;
}

sub configure_japan {
    my($self, $skipwrite) = @_;
    $self->set_config_value('DE', 1);
    $self->set_config_value('BAND', 2);
    $self->set_config_value('SPACE', 1);
    $self->update_registers( 0.1 ) unless $skipwrite;
}

sub configure_japan_wide {
    my($self, $skipwrite) = @_;
    $self->set_config_value('DE', 1);
    $self->set_config_value('BAND', 1);
    $self->set_config_value('SPACE', 1);
    $self->update_registers( 0.1 ) unless $skipwrite;
}

sub configure_usa {
    my($self, $skipwrite) = @_;
    $self->set_config_value('DE', 0);
    $self->set_config_value('BAND', 0);
    $self->set_config_value('SPACE', 0);
    $self->update_registers( 0.1 ) unless $skipwrite;
}

sub configure_australia {
    my($self, $skipwrite) = @_;
    $self->set_config_value('DE', 1);
    $self->set_config_value('BAND', 0);
    $self->set_config_value('SPACE', 0);
    $self->update_registers( 0.1 ) unless $skipwrite;
}

sub set_frequency {
    my($self, $frequency) = @_;
    
    my $spacebits = $self->get_config_value('SPACE');
    my $bandbits  = $self->get_config_value('BAND');
    
    my $baseline = ( $bandbits ) ? 7600 : 8750;
    my $spacing;
    if( $spacebits == 1) {
        $spacing = 10;
    } elsif( $spacebits == 2 ) {
        $spacing = 5;
    } else {
        $spacing = 20;
    }
    
    my $channel = ( ($frequency * 100 ) - $baseline ) / $spacing;
    
    $self->set_channel($channel);
}

sub set_channel {
    my($self, $channel) = @_;
    
    $self->set_config_value('CHAN', $channel);
    $self->set_config_value('TUNE', 1);
    $self->update_registers(0.01);
    $self->wait_for_stc;
}

sub get_channel {
    my $self = shift;
    my $channel = $self->get_config_value('READCHAN');
    return $channel;
}

sub get_frequency {
    my $self = shift;
    
    my $spacebits = $self->get_config_value('SPACE');
    my $bandbits  = $self->get_config_value('BAND');
    
    my $baseline = ( $bandbits ) ? 7600 : 8750;
    my $spacing;
    if( $spacebits == 1) {
        $spacing = 10;
    } elsif( $spacebits == 2 ) {
        $spacing = 5;
    } else {
        $spacing = 20;
    }
    my $channel = $self->get_config_value('READCHAN');
    
    my $frequency = ( $channel ) ? (( $spacing * $channel ) + $baseline) / 100 : 0;
    return $frequency;
}

sub set_volume {
    my($self, $volume) = @_;
    # volume 0 to 30
    $volume ||= 0;
    $volume = 0 if $volume < 0;
    $volume = 30 if $volume > 30;
    
    my $volext = 1;
    if( $volume >= 16 ) {
        $volume -= 15;
        $volext = 0;
    }
    
    $self->disable_mute if $volume;
        
    $self->set_config_value('VOLUME', $volume);
    $self->set_config_value('VOLEXT', $volext);
    
    $self->update_registers( 0.01 );
}

sub get_volume {
    my $self = shift;
    my $volume =  $self->get_config_value('VOLUME');
    my $volext =  $self->get_config_value('VOLEXT');
    
    $volume += 15 unless $volext;
    return $volume;
}

sub seek_up {
    my($self) = @_;
    $self->set_config_value('SEEKUP', 1);
    $self->set_config_value('SEEK', 1);
    $self->update_registers(0.01);
    $self->wait_for_stc;
}

sub seek_down {
    my($self) = @_;
    $self->set_config_value('SEEKUP', 0);
    $self->set_config_value('SEEK', 1);
    $self->update_registers(0.01);
    $self->wait_for_stc;
}

sub wait_for_stc {
    my $self = shift;
        
    my $count = 500; # 5 second max seek time
    
    while(!$self->get_config_value('STC') && $count > 0) {
        $self->read_registers;
        $self->sleep_seconds(0.01);
        $count --;
    }
    
    $self->set_config_value('SEEK', 0);
    $self->set_config_value('TUNE', 0);    
    
    $self->update_registers(0.01);
    
    $count = 500;
    
    while($self->get_config_value('STC') && $count > 0) {
        $self->read_registers;
        $self->sleep_seconds(0.01);
    }
}

sub sleep_seconds {
    my($self, $seconds) = @_;
    $self->delay( $seconds * 1000 );
}

# whole register access

sub set_register {
    my($self, $register, $newword) = @_;
    return unless($self->_mapped_registers);
    $self->_mapped_registers->[$register] = $newword;
    return;
}

sub get_register {
    my($self, $register) = @_;
    return ( $self->_mapped_registers ) ? $self->_mapped_registers->[$register] : 0;
}

# enable / disable

sub enable_seek_wrap {
    my $self = shift;
    $self->set_config_value('SKMODE', 0);
    $self->update_registers( 0.01 );
}

sub disable_seek_wrap {
    my $self = shift;
    $self->set_config_value('SKMODE', 1);
    $self->update_registers( 0.01 );
}

sub enable_mute {
    my $self = shift;
    $self->set_config_value('DMUTE', 0);
    $self->update_registers( 0.01 );
}

sub disable_mute {
    my $self = shift;
    $self->set_config_value('DMUTE', 1);
    $self->update_registers( 0.01 );
}

sub enable_soft_mute {
    my $self = shift;
    $self->set_config_value('DSMUTE', 0);
    $self->update_registers( 0.01 );
}

sub disable_soft_mute {
    my $self = shift;
    $self->set_config_value('DSMUTE', 1);
    $self->update_registers( 0.01 );
}

1;

__END__
