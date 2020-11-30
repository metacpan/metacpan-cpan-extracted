#########################################################################################
# Package        HiPi::Device::I2C
# Description:   Wrapper for I2C communucation
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device::I2C;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Device );
use HiPi qw( :i2c :rpi );
use HiPi::RaspberryPi;
use IO::File;
use XSLoader;
use Carp;
use Try::Tiny;

use constant {
    I2C_BCM2708 => 1,
    I2C_BCM2835 => 2,
};

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw ( fh fno address busmode readmode ) );

XSLoader::load('HiPi::Device::I2C', $VERSION) if HiPi::is_raspberry_pi();

my $modvers = ( -e '/sys/module/i2c_bcm2708' ) ? I2C_BCM2708 : I2C_BCM2835;

my $combined_param_path = '/sys/module/i2c_bcm2708/parameters/combined';
my $baudrate_param_path = '/sys/module/i2c_bcm2708/parameters/baudrate';

sub get_required_module_options {
    my $moduleoptions = [
        [ qw( i2c_bcm2708 i2c_dev ) ], # older i2c modules
        [ qw( i2c_bcm2385 i2c_dev ) ], # recent i2c modules
    ];
    return $moduleoptions;
}

sub get_device_list {
    # get the devicelist
    opendir my $dh, '/dev' or croak qq(Failed to open dev : $!);
    my @i2cdevs = grep { $_ =~ /^i2c-\d+$/ } readdir $dh;
    closedir($dh);
    for (my $i = 0; $i < @i2cdevs; $i++) {
        $i2cdevs[$i] = '/dev/' . $i2cdevs[$i];
    }
    return @i2cdevs;
}

sub _get_i2c_node_name {
    my $self = shift;
    my $devname = $self->devicename || '/dev/i2c-1';
    my ( $i2cnodename ) = ( $devname =~ /^\/dev\/(i2c-[0-9]{1,2})/ );
    return $i2cnodename;
}

sub get_baudrate {
    my ($class) = @_;
    
    if ( $modvers == I2C_BCM2835 ) {
        my $sysfile = '/sys/class/i2c-adapter/i2c-1/of_node/clock-frequency';
        my $sysfile0 = '/sys/class/i2c-adapter/i2c-0/of_node/clock-frequency';
        
        if ( $class && $class->isa('HiPi::Device::I2C') ) {
            my $nodename = $class->_get_i2c_node_name();
            $sysfile0 = $sysfile = qq(/sys/class/i2c-adapter/$nodename/of_node/clock-frequency);
        }

        if( -e $sysfile0 && !-e $sysfile ) {
            $sysfile = $sysfile0;
        }
        
        if( -e $sysfile ) {
            my $baudrate = qx(xxd -ps $sysfile);
            chomp $baudrate;
            return hex($baudrate);
        } else {
            return 0;
        }
    } else {
        my $baudrate = qx(/bin/cat $baudrate_param_path);
        if($?) {
            carp q(Unable to determine baudrate);
            return 0;
        }
        chomp($baudrate);
        return $baudrate;
    }
}

sub get_driver {
    return ( $modvers == I2C_BCM2835 ) ? 'i2c_bcm2835' : 'i2c_bcm2708';
}

sub get_combined {
    my ($class) = @_;
    return 'Y' if $modvers == I2C_BCM2835;
    my $combined = qx(/bin/cat $combined_param_path);
    if($?) {
        carp q(Unable to determine combined setting);
        return 'N';
    }
    chomp($combined);
    return $combined;
}

sub set_combined {
    my ($class, $newval) = @_;
    $newval //= 'N';
    $newval = uc($newval);
    croak('Usage HiPi::Device::I2C->set_combined( "Y|N" )') unless ( $newval =~ /^Y|N$/ );
    return 'Y' if $modvers == I2C_BCM2835;
    qx(/bin/echo $newval > $combined_param_path);
    return $newval;
}

sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address      => 0,
        fh           => undef,
        fno          => undef,
        busmode      => 'smbus',
        readmode     => I2C_READMODE_SYSTEM,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
        
    my $fh = IO::File->new( $params{devicename}, O_RDWR, 0 ) or croak qq(open error on $params{devicename}: $!\n);
    
    $params{fh}  = $fh;
    $params{fno} = $fh->fileno(),
    
    my $self = $class->SUPER::new(%params);
    
    # select address if id provided
    $self->select_address( $self->address ) if $self->address;

    return $self;
}

sub close {
    my $self = shift;
    if( $self->fh ) {
        $self->fh->flush;
        $self->fh->close;
        $self->fh( undef );
        $self->fno( undef );
        $self->address( undef );
    }
}

sub select_address {
    my ($self, $address) = @_;
    $self->address( $address );
    return $self->reset_ioctl;
}

sub reset_ioctl {
    my $self = shift;
    my $result = -1;
    if( $self->address ) {
        $result = $self->ioctl( I2C_SLAVE, $self->address + 0 );
    }
    return $result;
}

sub send_software_reset {
    my $self = shift;
    my $devicename = $self->devicename;
    my $result = -1;
    try {
        my $fh = IO::File->new( $devicename, O_RDWR, 0 ) or croak qq(open error on $devicename $!\n);
        $fh->ioctl( I2C_SLAVE, 0 );
        my $buffer = pack('C*', 0x06, 0);
        $result = _i2c_write( $fh->fileno, 0, $buffer, 1 );
        $fh->close;
    } catch {
        warn $_;
    };
    
    return $result;
}

sub ioctl {
    my ($self, $ioctlconst, $data) = @_;
    $self->fh->ioctl( $ioctlconst, $data );
}

sub scan_bus {
    my( $self, $mode, $start, $end) = @_;   
    $mode //= I2C_SCANMODE_AUTO;
    $start //= 0x03;
    $end //= 0x77;
    $start = 0x03 if $start < 0x03;
    $end = 0x77 if $end > 0x77;
    $end = $start if $end < $start;
    my @results = i2c_scan_bus($self->fno, $mode, $start, $end);
    
    # need to reset the ioctl address 
    $self->reset_ioctl;
    
    return @results;
}

sub check_address {
    my($self, $checkaddress) = @_;
    $checkaddress //= $self->address;
    return 0 unless $checkaddress;
    my @result = $self->scan_bus(I2C_SCANMODE_AUTO, $checkaddress, $checkaddress );
    return 0 unless @result;
    return (  $result[0] == $checkaddress ) ? 1 : 0;
}

#-------------------------------------------
# Methods that honour busmode (smbus or i2c)
#-------------------------------------------

sub bus_write {
    my ( $self, @bytes ) = @_;
    if( $self->busmode eq 'smbus' ) {
        return $self->smbus_write( @bytes );
    } else {
        return $self->i2c_write( @bytes );
    }
}

sub bus_write_error {
    my ( $self, @bytes ) = @_;
    if( $self->busmode eq 'smbus' ) {
        return $self->smbus_write_error( @bytes );
    } else {
        return $self->i2c_write_error( @bytes );
    }
}

sub bus_read {
    my ($self, $cmdval, $numbytes) = @_;

    # check if we need to change read mode
    my $resetcombined = undef;
    
    if( $modvers == I2C_BCM2708 ) {
        if ($self->readmode == I2C_READMODE_START_STOP  ) {
            my $combined = $self->get_combined;
            if ( $combined ne 'N') {
                $resetcombined = $combined;
                $self->set_combined('N');
            }
        } elsif($self->readmode == I2C_READMODE_REPEATED_START  ) {
            my $combined = $self->get_combined;
            if ( $combined ne 'Y') {
                $resetcombined = $combined;
                $self->set_combined('Y');
            }
        }
    }
    
    my @arrayreturn  = ();
        
    if( $self->busmode eq 'smbus' ) {       
        @arrayreturn = $self->smbus_read( $cmdval, $numbytes );
    
    # i2c modes
    } elsif( defined($cmdval) ) {
        @arrayreturn = $self->i2c_read_register($cmdval, $numbytes );
    } else {
        # read without write
        @arrayreturn = $self->i2c_read( $numbytes );
    }
    
    $self->set_combined($resetcombined) if $resetcombined;
    
    return @arrayreturn;
}

sub bus_read_bits {
    my($self, $regaddr, $numbytes) = @_;
    $numbytes ||= 1;
    my @bytes = $self->bus_read($regaddr, $numbytes);
    my @bits;
    while( defined(my $byte = shift @bytes )) {
        my $checkbits = 0b00000001;
        for( my $i = 0; $i < 8; $i++ ) {
            my $val = ( $byte & $checkbits ) ? 1 : 0;
            push( @bits, $val );
            $checkbits *= 2;
        }
    }
    return @bits;
}

sub bus_write_bits {
    my($self, $register, @bits) = @_;
    my $bitcount  = @bits;
    my $bytecount = $bitcount / 8;
    if( $bitcount % 8 ) { croak(qq(The number of bits $bitcount cannot be ordered into bytes)); }
    my @bytes;
    while( $bytecount ) {
        my $byte = 0;
        for(my $i = 0; $i < 8; $i++ ) {
            my $bit = shift @bits;
            $byte += ( $bit << $i ); 
        }
        push(@bytes, $byte);
        $bytecount --;
    }
    $self->bus_write($register, @bytes);
}

#-------------------------------------------
# I2C interface
#-------------------------------------------
    
sub i2c_write {
    my( $self, @bytes ) = @_;
    my $buffer = pack('C*', @bytes, '0');
    my $len = @bytes;
    my $result = _i2c_write($self->fno, $self->address, $buffer, $len );
    croak qq(i2c_write failed with return value $result) if $result;
}

sub i2c_write_error {
    my( $self, @bytes ) = @_;
    my $buffer = pack('C*', @bytes, '0');
    my $len = @bytes;
    _i2c_write($self->fno, $self->address, $buffer, $len );
}

sub i2c_read {
    my($self, $numbytes) = @_;
    $numbytes ||= 1;
    my $buffer = '0' x ( $numbytes + 1 );
    my $result = _i2c_read($self->fno, $self->address, $buffer, $numbytes );
    croak qq(i2c_read failed with return value $result) if $result;
    my $template = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @vals = unpack($template, $buffer );
    return @vals;
}

sub i2c_read_register {
    my($self, $register, $numbytes) = @_;
    $numbytes ||= 1;
    my $rbuffer = '0' x ( $numbytes + 1 );
    my $wbuffer = pack('C', $register);
    my $result = _i2c_read_register($self->fno, $self->address, $wbuffer, $rbuffer, $numbytes );
    croak qq(i2c_read_register failed with return value $result) if $result;
    my $template = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @vals = unpack($template, $rbuffer );
    return @vals;
}

#-------------------------------------------
# SMBus interface
#-------------------------------------------

sub smbus_write {
    my ($self, @bytes) = @_;
    if( @bytes == 1) {
        $self->smbus_write_byte($bytes[0]);
    } elsif( @bytes == 2) {
        $self->smbus_write_byte_data( @bytes );
    } else {
        my $command = shift @bytes;
        $self->smbus_write_i2c_block_data($command, \@bytes );
    }
}

sub smbus_write_error {
    my ($self, @bytes) = @_;
    # we allow errors - so catch auto generated error
    try {
        if( @bytes == 1) {
            $self->smbus_write_byte($bytes[0]);
        } elsif( @bytes == 2) {
            $self->smbus_write_byte_data( @bytes );
        } else {
            my $command = shift @bytes;
            $self->smbus_write_i2c_block_data($command, \@bytes );
        }
    };
}

sub smbus_read {
    my ($self, $cmdval, $numbytes) = @_;
    if(!defined($cmdval)) {
        return $self->smbus_read_byte;
    } elsif(!$numbytes || $numbytes <= 1 ) {
        return $self->smbus_read_byte_data( $cmdval );
    } else {
        return $self->smbus_read_i2c_block_data($cmdval, $numbytes );
    }
}

sub smbus_write_quick {
    my($self, $command ) = @_;
    my $result = i2c_smbus_write_quick($self->fno, $command);
    croak qq(smbus_write_quick failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_byte {
    my( $self ) = @_;
    my $result = i2c_smbus_read_byte( $self->fno );
    croak qq(smbus_read_byte failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_byte {
    my($self, $command) = @_;
    my $result = i2c_smbus_write_byte($self->fno, $command);
    croak qq(smbus_write_byte failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_byte_data {
    my($self, $command) = @_;
    my $result = i2c_smbus_read_byte_data($self->fno, $command);
    croak qq(smbus_read_byte_data failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_byte_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_byte_data($self->fno,  $command, $data);
    croak qq(smbus_write_byte_data failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_word_data {
    my($self, $command) = @_;
    my $result = i2c_smbus_read_word_data($self->fno, $command);
    croak qq(smbus_read_word_data failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_word_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_word_data($self->fno, $command, $data);
    croak qq(smbus_write_word_data failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_word_swapped {
    my($self, $command) = @_;
    my $result = i2c_smbus_read_word_swapped($self->fno, $command);
    croak qq(smbus_read_word_swapped failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_word_swapped {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_word_swapped($self->fno, $command, $data);
    croak qq(smbus_write_word_swapped failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_process_call {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_process_call($self->fno, $command, $data);
    croak qq(smbus_process_call failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_block_data {
    my($self, $command) = @_;
    my @result = i2c_smbus_read_block_data($self->fno, $command);
    croak qq(smbus_read_block_data failed ) unless @result;
    return @result;
}

sub smbus_read_i2c_block_data {
    my($self, $command, $numbytes) = @_;
    my @result = i2c_smbus_read_i2c_block_data($self->fno, $command, $numbytes);
    croak qq(smbus_read_i2c_block_data failed ) unless @result;
    return @result;
}

sub smbus_write_block_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_block_data($self->fno, $command, $data);
    croak qq(smbus_write_block_data failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_write_i2c_block_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_i2c_block_data($self->fno, $command, $data);
    croak qq(smbus_write_i2c_block_data failed with return value $result) if $result < 0;
    return $result;
}

1;

__END__
