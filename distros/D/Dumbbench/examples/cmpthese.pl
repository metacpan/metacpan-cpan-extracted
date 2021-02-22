#!perl

use lib qw(lib);
use Benchmark::Dumb qw(cmpthese);

cmpthese( 500.01, { a => "++\$i", b => "\$i *= 2" } ) ;

