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
use HiPi::Device::GPIO::Pin;
use Time::HiRes;

our $VERSION ='0.65';

my $sysroot = '/sys/class/gpio';

use constant {
    DEV_GPIO_PIN_STATUS_NONE         => 0x00,
    DEV_GPIO_PIN_STATUS_EXPORTED     => 0x01,
};

our @EXPORT_OK = qw(
    DEV_GPIO_PIN_STATUS_NONE 
    DEV_GPIO_PIN_STATUS_EXPORTED
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, pinstatus => \@EXPORT_OK );

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

sub get_pin {
    my( $self, $pinid ) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinid});
    if( !-d $pinroot ) {
        return $self->export_pin( $pinid );
    } else {
        return HiPi::Device::GPIO::Pin->_open( pinid => $pinid );
    }
}

sub export_pin {
    my( $self, $pinno ) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinno});
    # export the pin
    
    if( !-d $pinroot ) {
        system(qq(/bin/echo $pinno > ${sysroot}/export)) and croak qq(failed to export pin $pinno : $!);
    }
    
    {
        # We have to wait for the system to export the pin correctly.
        # Max 10 seconds
        my $checkpath = qq($pinroot/value);
        my $counter = 100;
        while( $counter ){
            last if( -e $checkpath && -w $checkpath );
            Time::HiRes::sleep( 0.1 );
            $counter --;
        }
        
        unless( $counter ) {
            croak qq(failed to export pin $checkpath);
        }
    }
    
    return HiPi::Device::GPIO::Pin->_open( pinid => $pinno );
}

sub unexport_pin {
    my( $self, $pinno ) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinno});
    return if !-d $pinroot;
    # unexport the pin
    system( qq(/bin/echo $pinno > ${sysroot}/unexport) ) and croak qq(failed to unexport pin $pinno : $!);
}

sub pin_status {
    my($self, $pinno) = @_;
    my $pinroot = qq(${sysroot}/gpio${pinno});
    return (-d $pinroot ) ? DEV_GPIO_PIN_STATUS_EXPORTED : DEV_GPIO_PIN_STATUS_NONE;    
}

1;

__END__
