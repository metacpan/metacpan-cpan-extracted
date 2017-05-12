use Math::Clipper ':all';
use Test::More tests=>1;

my $clipper = Math::Clipper->new;

$clipper->use_full_coordinate_range(1);
pass();
