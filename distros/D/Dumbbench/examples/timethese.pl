#!perl
use v5.10;

use lib qw(lib);
use Benchmark::Dumb qw(cmpthese timethese);
use Data::Dumper;

my $results = timethese( 100.01, { a => "++\$i", b => "\$i *= 2" } );
say Dumper( $results );

my $rc = cmpthese( $results );
say Dumper( $rc );
