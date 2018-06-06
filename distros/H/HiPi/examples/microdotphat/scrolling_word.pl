#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Scrolling Text
Scrolls a single word char by char across the screen.
Usage: scrolling_word.pl "your message"
Press Ctrl+C to exit.
);

my $text = $ARGV[0] || 'Perl';

my $charwidth = 5;
my $kerning = 0;

$phat->write_string( $text, 0, 0, $kerning );
$phat->show;

$phat->sleep_milliseconds( 500 );

while (1) {
    $phat->scroll( $charwidth );
    $phat->show();
    $phat->sleep_milliseconds( 500 );
}

1;
