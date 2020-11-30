#!/usr/bin/perl

use strict;
use warnings;
use HiPi qw( :seesaw );

# call with seesaw hex address
# e.g. seesaw/neopixel.pl 0x49

my $demopin = SEESAW_PA010;
my $demopixels = 8;

package HiPi::Example::Seesaw;
use HiPi qw( :seesaw );
use parent qw( HiPi::Interface::Seesaw );

__PACKAGE__->create_accessors( qw( exit_processed demopin demopixels ) );

sub new {
    my ( $class, %params ) = @_;
    my $self = $class->SUPER::new( %params );
    HiPi->register_exit_method( $self, 'exit');
    return $self;
}

sub exit {
    my $self = shift;
    return if $self->exit_processed;
    print qq(\nExecution ending : cleaning up\n);
    $self->neopixel_clear;
    $self->software_reset;
    $self->exit_processed(1);
    return;
}

sub process {
    my $self = shift;
        
    print qq(Neopixel demo\n);
    print qq(\nPress CTRL + C to exit\n\n);
    
    $self->set_neopixel(
        pin    => $self->demopin,
        pixels => $self->demopixels,
    );
    
    my $max_brightness = 100;  # between 0 and 100
    
    # colours are always ( Red, Green, Blue, White, Brightness )
        
    my @red = ( 255, 0, 0,0,5 );
    my @green = ( 0, 255, 0,0,5 );
    my @blue = ( 0, 0, 255,0,5 );
    my @yellow = ( 255, 255, 0,0,5 );
    my @cyan = ( 0, 255, 255,0,5 );
    my @magenta = ( 255, 0, 255,0,5 );
    my @orange = ( 255, 40, 0,0,5 );
    my @white = ( 255, 255, 255,0,5 );
    my @brightwhite = ( 255, 255, 255, 255, 5 );
    
    my @pixelbuffer = (
        [ 255, 0, 0, 0, 5 ],
        [ 0, 255, 0, 0, 5 ],
        [ 0, 0, 255, 0, 5 ],
        [ 0, 0, 0, 255, 5 ],
        [ 255, 255, 0, 0, 5 ],
        [ 0, 255, 255, 0, 5 ],
        [ 255, 0, 255, 0, 5 ],
        [ 255, 255, 255, 0,5 ],
    );
    
    $self->neopixel_clear;
    
    $self->set_all_colour(\@brightwhite );
    $self->sleep_milliseconds(2500);
    
    $self->do_pixel_buffer(\@pixelbuffer);
    $self->sleep_milliseconds(2500);
    
    # cycle colours for a bit
    
    my $stop = time + 5;
    while ( $stop > time ) {
        $self->do_pixel_buffer( \@pixelbuffer);
        unshift( @pixelbuffer, pop( @pixelbuffer) );
        $self->sleep_milliseconds( 150 );    
    }
    
    # set colours and fade in / out
    
    for my $colour ( \@white, \@red, \@green, \@blue, \@yellow, \@cyan, \@magenta, \@orange ) {
        my @usecolour = @$colour;
        my $brightness = 5;
        while( $brightness < $max_brightness ) {
            
            $usecolour[-1] = $brightness;
            $self->set_all_colour(\@usecolour );
            $self->sleep_milliseconds(20);
            $brightness += 5;
        }
        
        while( $brightness >= 0 ) {
            $usecolour[-1] = $brightness;
            $self->set_all_colour(\@usecolour );
            $self->sleep_milliseconds(20);
            $brightness -= 5;
        }
    }
}

sub do_pixel_buffer {
    my ($self, $pixelbuffer) = @_;
    for( my $i = 0; $i < 8; $i++ ) {
        $self->neopixel_set_pixel($i, @{ $pixelbuffer->[$i] } );
    }
    $self->neopixel_show;
}

sub set_all_colour {
    my ($self, $colour) = @_;
    
    for( my $i = 0; $i < 8; $i++ ) {
        $self->neopixel_set_pixel($i, @$colour );
    }
    $self->neopixel_show;
}

package main;

my $seesawaddress = ( $ARGV[0] ) ?  hex($ARGV[0]) : 0x49;

my $dev = HiPi::Example::Seesaw->new(
    
    address    => $seesawaddress,
    demopin    => $demopin,
    demopixels => $demopixels,
    reset      => 1,
    
);

$dev->process;

1;

__END__
