#! perl

use Test::Lib;
use Test2::V0;

use aliased 'MyTest::Tests::May::Iter';

my @depends = map Iter->new, 1 .. 3;

my $iter = Iter->new( \@depends );

ok( $iter->may( 'rewind' ), "may rewind" );

try_ok { $iter->rewind } "rewinds";


done_testing;
