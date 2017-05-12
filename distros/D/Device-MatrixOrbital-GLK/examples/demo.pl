#!/usr/bin/perl
#

use strict;
use warnings;
use Time::HiRes qw( sleep );
use Device::MatrixOrbital::GLK;

my $lcd = new Device::MatrixOrbital::GLK();

print "LCD type: ".$lcd->get_lcd_type()."\n";
#print "LCD version: ".$lcd->get_lcd_type()."\n";

$lcd->clear_screen();

#$lcd->print("hello world\n");
$lcd->draw_rect( 1, 0, 0, 239, 63 );
$lcd->draw_rect( 1, 1, 1, 238, 62 );

$lcd->draw_solid_rect( 1, 10, 10, 20, 20 );
$lcd->draw_solid_rect( 1, 25, 25, 35, 35 );
$lcd->draw_solid_rect( 1, 40, 40, 50, 50 );

$lcd->draw_line( 120, 1,  120, 62 );


$lcd->draw_bitmap( 1, 150, 5 );

#while(1) {
#	$lcd->draw_rect( int(rand(240)), int(rand(64)), int(rand(240)), int(rand(64)) );
#	sleep(0.1);
#}

#while(1) {
#	$lcd->draw_pixel( int(rand(240)), int(rand(64)),  );
#	sleep(0.1);
#}

#foreach my $n (0...100) {
#	$lcd->print("Hello World $n\n");
#	sleep 1;
#}

foreach my $c (0...254) {
	$lcd->set_contrast($c);
	sleep 0.01;
}


$lcd->set_contrast(127);

