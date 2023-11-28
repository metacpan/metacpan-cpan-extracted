#! perl

# Test return of lines in array.

use strict;
use warnings;
use Test::More tests => 3;
use utf8;

use File::LoadLines;

-d "t" && chdir "t";

# Testing a missing final line terminator.
my $data = "first\r\nsecond\r\nthird";
my @lines = loadlines( \$data, { chomp => 0 } );
is( scalar(@lines), 3, "three lines CRLF" );
$data = "first\rsecond\rthird";
@lines = loadlines( \$data, { chomp => 0 } );
is( scalar(@lines), 3, "three lines CR" );
$data = "first\nsecond\nthird";
@lines = loadlines( \$data, { chomp => 0 } );
is( scalar(@lines), 3, "three lines NL" );
