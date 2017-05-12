#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new( name    => 'foo',
                                      version => '0.0.1' );

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

$mon += 1; # starts counting from zero
$year += 1900;

my $y = sprintf '%02d', $year % 100;
my $d = sprintf '%02d', $mday;
my $m = sprintf '%02d', $mon;

my $date_string = "$d/$m/$y";

like( $spec->date, qr/^\Q$date_string\E /, 'Date format is correct' );

$spec->update_date();

like( $spec->date, qr/^\Q$date_string\E /, 'Date format is correct' );
