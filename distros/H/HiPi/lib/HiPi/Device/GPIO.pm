#########################################################################################
# Package        HiPi::Device::GPIO
# Description:   Wrapper for GPIO
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device::GPIO;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Device );
use Carp;
use HiPi qw( :rpi );
use HiPi::Device::GPIO::Pin;
use Fcntl;

our $VERSION ='0.81';

my $sysroot = '/sys/class/gpio';


sub new {
    my ($class, %userparams) = @_;
    
    my %params = ();
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}

# Methods are class methods

sub export_pin {
    my( $class, $pinno ) = @_;
    my $pinroot = $class->_do_export( $pinno );
    return HiPi::Device::GPIO::Pin->_open( pinid => $pinno );
}

sub unexport_pin {
    my( $class, $pinno ) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinno});
    return if !-d $pinroot;
    # unexport the pin
    system( qq(/bin/echo $pinno > ${sysroot}/unexport) ) and croak qq(failed to unexport pin $pinno : $!);
}

sub unexport_all {
    
    opendir(my $dir, $sysroot) or die qq(failed to open sysfs root : $!);
    my @gpios = grep { /gpio\d+$/ } readdir( $dir );
    closedir($dir);
    
    for my $gpio ( @gpios ) {
        $gpio =~ s/^gpio//;
        system( qq(/bin/echo $gpio > ${sysroot}/unexport) );
    }
    
    return scalar @gpios;
}

sub pin_status {
    my($class, $pinno) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinno});
    return (-d $pinroot ) ? DEV_GPIO_PIN_STATUS_EXPORTED : DEV_GPIO_PIN_STATUS_NONE;    
}

sub pin_write {
    my($class, $gpio, $level) = @_;
    my $wval = ( $level ) ? 1 : 0;
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'value' ) );
    _write_fh( $fh, $wval);
    close( $fh );
    return $wval;
}

sub pin_read {
    my($class, $gpio) = @_;
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'value' ) );
    my $rval = _read_fh( $fh, 1);
    close( $fh );
    return $rval;
}

sub set_pin_mode {
    my($class, $gpio, $mode, $init ) = @_;
    
    my $inst;
    if( $mode == RPI_MODE_OUTPUT ) {
        if( $init ) {
            $inst = 'high';
        } else {
            $inst = 'low';
        }
    } elsif( $mode == RPI_MODE_INPUT ) {
        $inst = 'in';
    } else {
        croak qq(Invalid value for mode : $mode);
    }
    
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'direction' ) );
    _write_fh( $fh, $inst);
    close( $fh );
    return $mode;
}

sub get_pin_mode {
    my($class, $gpio ) = @_;
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'direction' ) );
    my $result = _read_fh( $fh, 16);
    close($fh);
    return ( $result eq 'out' ) ? RPI_MODE_OUTPUT : RPI_MODE_INPUT;
}

sub get_pin_function {
    my($class, $gpio) = @_;
    require HiPi::GPIO;
    return HiPi::GPIO->get_pin_function( $gpio );
}

sub set_pin_pud {
    my($class, $gpio , $pud ) = @_;
    
    require HiPi::GPIO;
    
    # we want to force pin export
    _get_pin_filepath( $gpio, 'value' );
    
    return HiPi::GPIO->set_pin_pud( $gpio, $pud );
}

sub get_pin_pud {
    my($class, $gpio ) = @_;
    
    require HiPi::GPIO;
    
    # we want to force pin export
    _get_pin_filepath( $gpio, 'value' );
    
    return HiPi::GPIO->get_pin_pud( $gpio );
}

sub set_pin_activelow {
    my($class, $gpio, $alow ) = @_;
    $alow = ( $alow ) ? 1 : 0;    
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'active_low' ) );
    _write_fh( $fh, $alow);
    close( $fh );
    return $alow;
}

sub get_pin_activelow {
    my($class, $gpio ) = @_;
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'active_low' ) );
    my $result = _read_fh( $fh, 1);
    close($fh);
    return ( $result ) ? 1 : 0;
}

sub get_pin_interrupt_filepath {
    my($class, $gpio ) = @_;
    my $fpath = _get_pin_filepath( $gpio, 'value' );
    return $fpath;
}

sub set_pin_interrupt {
    my($class, $gpio, $newedge ) = @_;
     
    $newedge ||= RPI_INT_NONE;
    my $stredge = 'none';
    if ( $newedge == RPI_INT_AFALL || $newedge == RPI_INT_FALL || $newedge == RPI_INT_LOW  ) {
        $stredge = 'falling';
    } elsif( $newedge == RPI_INT_ARISE || $newedge == RPI_INT_RISE || $newedge == RPI_INT_HIGH  ) {
        $stredge = 'rising';
    } elsif( $newedge == RPI_INT_BOTH ) {
        $stredge = 'both';
    } else {
        $stredge = 'none';
        $newedge = RPI_INT_NONE;
    }
    
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'edge' ) );
    _write_fh( $fh, $stredge );
    close( $fh );
    return $newedge;
}

sub get_pin_interrupt {
    my($class, $gpio ) = @_;
    my $fh = _open_fh( _get_pin_filepath( $gpio, 'edge' ) );
    my $result = _read_fh( $fh, 16);
    close($fh);
    
    my $edge = RPI_INT_NONE;
    
    if($result eq 'rising') {
        $edge =  RPI_INT_RISE;
    } elsif($result eq 'falling') {
        $edge =  RPI_INT_FALL;
    } elsif($result eq 'both') {
        $edge =  RPI_INT_BOTH;
    }
    
    return $edge;
}

sub _do_export {
    my ($class, $pinno ) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinno});
    return $pinroot if -d $pinroot;
    system(qq(/bin/echo $pinno > ${sysroot}/export)) and croak qq(failed to export pin $pinno : $!);
        
    # We have to wait for the system to export the pin correctly.
    # Max 10 seconds
    my $checkpath = qq($pinroot/value);
    my $counter = 100;
    while( $counter ){
        last if( -e $checkpath && -w $checkpath );
        $class->delay( 100 );
        $counter --;
    }
    
    unless( $counter ) {
        croak qq(failed to export pin $checkpath);
    }
    
    return $pinroot;
}

sub _get_pin_filepath {
    my( $pinno, $type ) = @_;
    my $pinroot = __PACKAGE__->_do_export( $pinno );
        
    my $filepath = qq($pinroot/$type);
    
    if( -e $filepath ) {
        return $filepath;
    } else {
        croak qq(could not find $type file for pin $pinno);
    }
}

sub _open_fh {
    my $filepath = shift;
    my $fh;
    sysopen($fh, $filepath, O_RDWR|O_NONBLOCK) or croak qq(failed to open $filepath : $!);
    return $fh;
}

sub _read_fh {
    my($fh, $bytes) = @_;
    my $value;
    sysseek($fh,0,0);
    defined( sysread($fh, $value, $bytes) ) or croak(qq(Failed to read from filehandle : $!));
    chomp $value;
    return $value;
}

sub _write_fh {
    my($fh, $val) = @_;
    sysseek($fh,0,0);
    defined( syswrite($fh, $val) ) or croak(qq(Failed to write to filehandle : $!));
}


# Aliases

*HiPi::Device::GPIO::get_pin = \&export_pin;
*HiPi::Device::GPIO::get_pin_level = \&pin_read;
*HiPi::Device::GPIO::set_pin_level = \&pin_write;


1;

__END__
