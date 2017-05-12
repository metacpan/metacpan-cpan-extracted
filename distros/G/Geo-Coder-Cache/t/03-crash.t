# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Coder-Cache.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use Geo::Coder::Cache;

eval "use Geo::Coder::Google";
plan skip_all => "Geo::Coder::Google required for testing" if $@;
plan tests => 3;

my $geocoder;
for (1..1000) {
    $geocoder = Geo::Coder::Cache->new(
        geocoder => Geo::Coder::Google->new(apikey => 'Geo::Coder::Cache', apiver => 3),
        cache_root => '.',
        );
}
my $addr = '1600 Amphitheatre Pkwy, Mountain View, CA 94043';
$geocoder->clear();
is(undef, $geocoder->get($addr), 'cache miss');
isnt(undef, $geocoder->geocode($addr), 'online query');
isnt(undef, $geocoder->get($addr), 'cache hit');
$geocoder->clear();
