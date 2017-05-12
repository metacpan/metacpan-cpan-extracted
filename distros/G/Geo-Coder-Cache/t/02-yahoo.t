# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Coder-Cache.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use Geo::Coder::Cache;

eval "use Geo::Coder::Yahoo";
plan skip_all => "Geo::Coder::Yahoo required for testing" if $@;
plan tests => 3;

my $geocoder = Geo::Coder::Cache->new(
    geocoder => Geo::Coder::Yahoo->new(appid => 'Geo::Coder::Cache'),
    cache_root => '.',
    );
my $addr = '701 1st Ave, Sunnyvale, CA 94089';
$geocoder->clear();
is(undef, $geocoder->get($addr), 'cache miss');
isnt(undef, $geocoder->geocode($addr), 'online query');
isnt(undef, $geocoder->get($addr), 'cache hit');
$geocoder->clear();
