#!perl

use strict;
use warnings;
use Test::More tests => 2;
use POSIX ();

use Log::Tiny;

# %D{...} formats the current time with the brace pattern via strftime.
my $buf = '';
open( my $fh, '>>', \$buf ) or die $!;
my $log = Log::Tiny->new( $fh, '%D{%Y}|%m%n' ) or die Log::Tiny->errstr;
$log->LOG("x");
my $year = POSIX::strftime( '%Y', localtime );
is( $buf, "$year|x\n", "%D{%Y} expands via strftime" );

# %D with no brace uses the ISO-ish default pattern.
my $buf2 = '';
open( my $fh2, '>>', \$buf2 ) or die $!;
my $log2 = Log::Tiny->new( $fh2, '%D|%m%n' ) or die Log::Tiny->errstr;
$log2->LOG("y");
like( $buf2, qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\|y\n$/,
    "%D with no brace uses the default ISO-ish timestamp" );
