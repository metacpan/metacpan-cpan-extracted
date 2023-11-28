#! perl

# Test soft failure.

use strict;
use warnings;
use Test::More tests => 2;
use utf8;

use File::LoadLines;

-d "t" && chdir "t";

# Testing soft errors.
my $opt = { fail => "soft" };
my @lines = loadlines( "a hopefully not existing file", $opt );
is( scalar(@lines), 0, "no lines" );
ok( $opt->{error}, "error ok" );
diag("Error message: $opt->{error}");
