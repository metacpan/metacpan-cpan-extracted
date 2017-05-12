#!/usr/bin/perl

use lib qw(blib/lib blib/arch);
use MP3::Cut::Gapless;
use Time::HiRes qw(sleep);

my $file = shift;
my $n = 0;

for ( 1..50000 ) {
    my $cut = MP3::Cut::Gapless->new(
        file     => $file,
        start_ms => 1000,
        end_ms   => 2000,
    );

    while ( $cut->read( my $buf, 4096 ) ) { }
    
    sleep 0.001;
}
