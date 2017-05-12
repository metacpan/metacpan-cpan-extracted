#########################################################################################
# Package        HiPi::Device::GPIO::Pin
# Description:   Pin
# Created        Wed Feb 20 04:37:38 2013
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device::GPIO::Pin;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Pin );
use Carp;
use Fcntl;
use HiPi qw( :rpi );

our $VERSION ='0.65';

my $sysroot = '/sys/class/gpio';

__PACKAGE__->create_accessors( qw( pinroot valfh ) );

sub _open {
    my ($class, %params) = @_;
    defined($params{pinid}) or croak q(pinid not defined in parameters);
    
    my $pinroot = qq(${sysroot}/gpio$params{pinid});
    croak qq(pin $params{pinid} is not exported) if !-d $pinroot;
    
    my $valfile = qq($pinroot/value);

    $params{valfh} = _open_file( $valfile );
    $params{pinroot} = $pinroot;
    
    my $self = $class->SUPER::_open(%params);
    return $self;
}

sub _open_file {
    my $filepath = shift;
    my $fh;
    sysopen($fh, $filepath, O_RDWR|O_NONBLOCK) or croak qq(failed to open $filepath : $!);
    return $fh;
}

sub _read_fh_bytes {
    my($fh, $bytes) = @_;
    my $value;
    sysseek($fh,0,0);
    defined( sysread($fh, $value, $bytes) ) or croak(qq(Failed to read from filehandle : $!));
    chomp $value;
    return $value;
}

sub _write_fh {
    my($fh, $val) = @_;
    defined( syswrite($fh, $val) ) or croak(qq(Failed to write to filehandle : $!));
}

sub _do_getvalue {
    _read_fh_bytes( $_[0]->valfh, 1);
}

sub _do_setvalue {
    my( $self, $newval) = @_;
    _write_fh($self->valfh, $newval );
    return $newval;
}

sub _do_getmode {
    my $self = shift;
    my $fh = _open_file( $self->pinroot . '/direction' );
    my $result = _read_fh_bytes( $fh, 16);
    close($fh);
    return ( $result eq 'out' ) ? RPI_MODE_OUTPUT : RPI_MODE_INPUT;
}

sub _do_setmode {
    my ($self, $newmode) = @_;
    my $fh = _open_file( $self->pinroot . '/direction' );
    if( ($newmode == RPI_MODE_OUTPUT) || ($newmode eq 'out') )  {
        _write_fh($fh, 'out');
        close($fh);
        return RPI_MODE_OUTPUT;
    } else {
        _write_fh($fh, 'in');
        close($fh);
        return RPI_MODE_INPUT;
    }
}

sub _do_getinterrupt {
    my $self = shift;
    my $fh = _open_file( $self->pinroot . '/edge' );
    my $result = _read_fh_bytes( $fh, 16);
    close($fh);
    
    if($result eq 'rising') {
        return RPI_INT_RISE;
    } elsif($result eq 'falling') {
        return RPI_INT_FALL;
    } elsif($result eq 'both') {
        return RPI_INT_BOTH;
    } else {
        return RPI_INT_NONE;
    }
}

sub _do_setinterrupt {
    my ($self, $newedge) = @_;
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
    }
    my $fh = _open_file( $self->pinroot . '/edge' );
    _write_fh( $fh, $stredge);
    close($fh);
    return $newedge;
}

sub _do_clear_interrupt {
    # clear edge detection status ? already cleared
    return;
}

sub _do_setpud {
    my($self, $pudval) = @_;
    my $pudchars = 'error';
    
    if ( $pudval == RPI_PUD_OFF ) {
        $pudchars = 'pn';
    } elsif ($pudval == RPI_PUD_UP ) {
        $pudchars = 'pu';
    } elsif ($pudval == RPI_PUD_DOWN ) {
        $pudchars = 'pd';
    } else {
        croak(qq(Incorrect PUD setting $pudval));
    }
    
    require HiPi::GPIO;
    HiPi::GPIO->set_pin_pud($self->pinid, $pudval);
}


sub _do_activelow {
    my($self, $newval) = @_;
    
    my $fh = _open_file( $self->pinroot . '/active_low' );
    my $result;
    if(defined($newval)) {
        _write_fh( $fh, $newval);
        $result = $newval;
    } else {
        $result = _read_fh_bytes( $fh, 1);
    }
    close($fh);
    return $result;
} 

sub DESTROY {
    my $self = shift;
    close($self->valfh) if $self->valfh;
}

1;
