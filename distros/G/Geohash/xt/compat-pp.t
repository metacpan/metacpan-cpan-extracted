use strict;
use Test::More;
use Test::Requires 'Geo::Hash';

$ENV{PERL_GEOHASH_BACKEND} = 'Geo::Hash';
while (<t/0*.t>) {
    subtest $_ => sub { do $_ };
}

done_testing();
