#########################################################################################
# Package        HiPi::Interface::ZeroSeg
# Description  : Interface to Pi Hut ZeroSeg pHAT
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::ZeroSeg;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :max7219 );
use HiPi::Interface::MAX7219;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( buffer writeflags flipped _decimals _shutdown_on_exit segmentfont ) );

my $defaultsegmentfont = {
    ' ' => 0x00,
    '-' => 0x01,
	'_' => 0x08,
    '>' => 0b00000111,
    '<' => 0b00110001,
    '=' => 0b00001001,
    '0' => 0x7e,
    '1' => 0x30,
    '2' => 0x6d,
    '3' => 0x79,
    '4' => 0x33,
    '5' => 0x5b,
    '6' => 0x5f,
    '7' => 0x70,
    '8' => 0x7f,
    '9' => 0x7b,
	'a' => 0x7d,
    'b' => 0x1f,
	'c' => 0x0d,
    'd' => 0x3d,
	'e' => 0x6f,
	'f' => 0x47,
	'g' => 0x7b,
	'h' => 0x17,
	'i' => 0x10,
	'j' => 0x18,
	'k' => 0b00000111,
	'l' => 0x06,
	'm' => 0b01000001,
	'n' => 0x15,
	'o' => 0x1d,
	'p' => 0x67,
	'q' => 0x73,
	'r' => 0x05,
	's' => 0x5b,
	't' => 0x0f,
	'u' => 0x1c,
	'v' => 0x1c,
	'w' => 0b00010100,
	'x' => 0b00100101,
	'y' => 0x3b,
	'z' => 0x6d,
	'A' => 0x77,
	'B' => 0x7f,
	'C' => 0x4e,
	'D' => 0x7e,
	'E' => 0x4f,
	'F' => 0x47,
	'G' => 0x5e,
	'H' => 0x37,
	'I' => 0x30,
	'J' => 0x38,
	'K' => 0b00110001,
	'L' => 0x0e,
	'M' => 0b01001001,
	'N' => 0x76,
	'O' => 0b01100011,
	'P' => 0x67,
	'Q' => 0x73,
	'R' => 0x46,
	'S' => 0x5b,
	'T' => 0x0f,
	'U' => 0x3e,
	'V' => 0x3e,
	'W' => 0b00110110,
	'X' => 0b00010011,
	'Y' => 0x3b,
	'Z' => 0x6d,
	',' => 0x80,
	'.' => 0x80,
};

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => 9600000,  # 9.6 mhz
        delay        => 0,
        _shutdown_on_exit => 1,
        segmentfont  => $defaultsegmentfont,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    $params{buffer} = [];
    $params{_decimals} = [0,0,0,0,0,0,0,0];
        
    unless(defined($params{device})) {
        $params{device} = HiPi::Interface::MAX7219->new(
            speed        => $params{speed},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
    }
    
    my $self = $class->SUPER::new(%params);
    HiPi->register_exit_method( $self, '_on_exit');
    $self->device->set_decode_mode( 0 );
    $self->device->set_scan_limit( 7 );
    $self->device->set_intensity( 2 );
    $self->device->wake_up;
    $self->device->set_display_test(0);
    
    return $self;
}

sub set_shutdown_on_exit {
    my ($self, $state) = @_;
    $state = ( $state ) ? 1 : 0;
    $self->_shutdown_on_exit( $state );
}

sub _on_exit {
    my $self = shift;
    if(  $self->_shutdown_on_exit ) {
        $self->device->shutdown;
    }
}

sub set_buffer_text {
    my( $self, $text ) = @_;
    
    # padleft
    $text = sprintf('%8s', $text);
    
    my @chars = split(//, $text);
    
    $self->buffer(\@chars );
    $self->_decimals( [0,0,0,0,0,0,0,0] );
    return $text;
}

sub write_decimal_number {
    my ($self, $value) = @_;
    $value =~ s/\s+//g;
    
    my $dp = index($value, '.');
    
    $value =~ s/\.//g;
    $self->_decimals( [0,0,0,0,0,0,0,0] );
    
    if($dp > -1 ) {
        if( length( $value ) < 8 ) {
            $dp += ( 8 - length( $value ) );
        }
        $self->_decimals->[$dp - 1] = 1 if $dp > 0;
    }
    
    my @chars = split(//, sprintf('%8s', $value) );
    $self->buffer(\@chars );
    $self->write_buffer;
    return $value;
}

sub write_degrees {
    my ($self, $value, $scale) = @_;
    $value =~ s/\s+//g;
    $scale //='';
    if($scale) {
        $scale =~ s/[^fc]//ig;
    }
    
    $value .= 'O' . uc($scale);
    
    my $dp = index($value, '.');
    
    $value =~ s/\.//g;
    $self->_decimals( [0,0,0,0,0,0,0,0] );
    
    if($dp > -1 ) {
        if( length( $value ) < 8 ) {
            $dp += ( 8 - length( $value ) );
        }
        $self->_decimals->[$dp - 1] = 1 if $dp > 0;
    }
    
    my @chars = split(//, sprintf('%8s', $value) );
    $self->buffer(\@chars );
    $self->write_buffer;
    return $value;
}

sub write_time {
    my ( $self, $hour, $minute, $second ) = @_;
    $hour ||= 0;
    $minute ||= 0;
    
    for ( $hour, $minute, $second) {
        $_ = sprintf("%02d", $_) if defined( $_ );
    }
    my $timestring = $hour . $minute;
    if(defined($second)) {
        $timestring .= $second;
        $self->_decimals( [0,0,0,1,0,1,0,0] );
    } else {
        $self->_decimals( [0,0,0,0,0,1,0,0] );
    }
    my @chars = split(//, sprintf('%8s', $timestring) );
    $self->buffer(\@chars );
    $self->write_buffer;
    return $timestring;
}

sub write_localtime {
    my ( $self, $skipseconds ) = @_;
    my ($second, $minute, $hour ) = localtime(time);
    $second = ( $skipseconds ) ? undef : $second;
    my $rval =  $self->write_time( $hour, $minute, $second);
    return $rval;
}

sub write_gmtime {
    my ( $self, $skipseconds ) = @_;
    my ($second, $minute, $hour ) = gmtime(time);
    $second = ( $skipseconds ) ? undef : $second;
    my $rval = $self->write_time( $hour, $minute, $second);
    return $rval;
}

sub write_buffer {
    my $self = shift;
    for (my $i = 0; $i < 8; $i ++) {
        my $flags = 0;
        $flags |= MAX7219_FLAG_DECIMAL if $self->_decimals->[$i];
        $self->_write_segment_char( 7 - $i , $self->buffer->[$i], $flags );
    }
    return;
}

sub write_text {
    my( $self, $text ) = @_;
    $self->set_buffer_text($text);
    $self->write_buffer;
}

sub write_raw_bytes {
    my( $self, @bytes ) = @_;
    while( scalar(@bytes) < 8 ) {
        unshift( @bytes, 0x00 );
    }
    
    for (my $i = 0; $i < 8; $i ++) {
        $self->device->send_segment_matrix( 7 - $i, $bytes[$i] );
        $self->sleep_milliseconds(10);
    }
    
    return;
}

sub scroll_buffer_left {
    my $self = shift;
    if( scalar @{ $self->buffer } ) {
        push @{ $self->buffer }, shift @{ $self->buffer };
    }
    return;
}

sub scroll_buffer_right {
    my $self = shift;
    if( scalar @{ $self->buffer } ) {
        unshift @{ $self->buffer }, pop @{ $self->buffer };
    }
    return;
}

sub clear_display {
    my $self = shift;
    my $text = ' ' x 8;
    $self->write_text($text);
    return;
}

sub shut_down { $_[0]->device->shutdown; }

sub wake_up { $_[0]->device->wake_up; }

sub set_intensity{ $_[0]->device->set_intensity( $_[1] ); }

sub _write_segment_char {
    my($self, $matrix, $char, $flags ) = @_;
    $flags //= 0x00;
    $char  //= '_';
    my $byte = ( exists($self->segmentfont->{$char}) ) ? $self->segmentfont->{$char} : 0x08;
    
    if( $flags & MAX7219_FLAG_FLIPPED ) {
        $byte = (($byte & 0xE) << 3) | (($byte & 0x70) >> 3) | ( $byte & 0x80 ) | ( $byte & 0x01 );
    }
    
    if( $flags & MAX7219_FLAG_DECIMAL ) {
        $byte |= 0x80;
    }
    
    if( $flags & MAX7219_FLAG_MIRROR ) {
        # swap bits 5 and 1
        # swap bits 4 and 2
        for my $swap ( [ 5, 1], [ 4, 2 ] ) {
            my $val0 =  ( $byte >> $swap->[0] ) & 1;
            my $val1 =  ( $byte >> $swap->[1] ) & 1;
            
            if( $val0 ) {
                $byte |= ( 1 << $swap->[1] ); 
            } else {
                $byte &= ~( 1 << $swap->[1] );
            }
            
            if( $val1 ) {
                $byte |= ( 1 << $swap->[0] ); 
            } else {
                $byte &= ~( 1 << $swap->[0] );
            }
        } 
    }
        
    $self->device->send_segment_matrix( $matrix, $byte );
    $self->sleep_milliseconds(10);
}


1;

__END__