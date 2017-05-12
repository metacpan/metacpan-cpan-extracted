use strict;
use warnings;
use Geo::Distance::XS;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $geo = Geo::Distance->new;
    $geo->distance(mile => -118.243103, 34.159545, -73.987427, 40.853293);
};

$try->();

is(leaked_count($try), 0, 'leaks');
