#!perl -T
use strict;
use warnings;
use Test::More;

# guts of Test::More::UTF8
binmode Test::More->builder->$_, ':utf8'
    for qw(failure_output todo_output output);

use LWP::Simple;
#use Data::Dump qw(dump);
use Encode qw(encode);

use_ok( 'Geo::Coder::Yahoo' );

ok(my $g = Geo::Coder::Yahoo->new(appid => 'perl-geocoder-test'), 'new geocoder');
isa_ok($g, 'Geo::Coder::Yahoo', 'isa');

SKIP: {
   skip 'Requires a network connection allowing HTTP', 5 unless get('http://www.yahoo.com/');

   my $p;

   ok($p = $g->geocode(location => 'Berlin, Dudenstr. 24' ), 'geocode a street in Berlin, Germany');
   ok @$p;
   my $expect = "Dudenstra\N{U+DF}e 24";
   my $got = $p->[0]->{address};
   # this test fails with perl < 5.12/5.10 ... 
   # ok Encode::is_utf8($expect, 1), 'expected is_utf8';
   ok Encode::is_utf8($got, 1), 'got is_utf8';
   is($got, $expect);

}

done_testing();
