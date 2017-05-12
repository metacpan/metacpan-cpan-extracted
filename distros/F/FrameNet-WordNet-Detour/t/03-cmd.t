#!perl

use Test::More tests => 5;

my $t1 = "perl -I blib/arch/auto/ blib/script/detour";


like(`$t1 --help`, qr/^Usage/,
     "Checking if the usage information is display correctly");

like(`$t1 get#v#1`, qr/Getting;/,
     "Checking without parameters");

like(`$t1 --weights get#v#1`, qr/^Getting \d\.\d+;/,
     "Checking --weights");


like(`$t1 --weights --fees get#v#1`, 
     qr/^Getting \d\.\d+ \([\w_]+\#[nva]\#\d(,[\w_]+\#[nva]\#\d)+\);/,
     "Checking --fees");

like(`$t1 --weights --sims get#v#1`,
     qr/^Getting \d\.\d+ \([\w_]+\#[nva]\#\d\[[\d\.]+\](,[\w_]+\#[nva]\#\d\[[\d\.]+\])+\);/,
     "Checking --sims");
