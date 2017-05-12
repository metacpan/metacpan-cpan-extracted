#!/usr/bin/perl -w
use strict;
use DateTime;
my $year = shift || DateTime->now->year;

my $dt = DateTime->new( year => $year, month => 1, day => 1);

while ($dt->year == $year) {
    if ($dt->dow <= 5) {
        print $dt->ymd.$/;
    }
    $dt->add( days => 1);
}
