use strict;
use Test::More tests => 3;
use HTML::HiLiter;

my $file = 't/docs/test.html';

my @q = (
    'foo = "quick brown" and bar=(fox* or run)',
    'runner',
    '"over the too lazy dog"',
    '"c++ filter"',
    '"-h option"',
    'laz',
    'fakefox',
    '"jumped over"',
);

ok( my $hiliter = HTML::HiLiter->new(
        Links => 1,
        query => join( ' ', @q ),

        #debug => 1,
        #tty   => 1,
    ),
    "new HiLiter"
);

ok( my $hilited = $hiliter->run( \Search::Tools->slurp($file) ) );

ok( $hilited->isa("HTML::Parser"), "hiliter matches" );
