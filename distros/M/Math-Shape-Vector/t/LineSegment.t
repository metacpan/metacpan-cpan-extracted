use strict;
use warnings;
use Test::More;
use Math::Shape::Vector;

BEGIN { use_ok 'Math::Shape::LineSegment' };

# new
ok my $segment  = Math::Shape::LineSegment->new(1, 1, 5, 5);
ok my $segment2 = Math::Shape::LineSegment->new(1, 2, 4, 0);
ok my $segment3 = Math::Shape::LineSegment->new(2, 3, 5, 9);
is $segment->{start}->{x}, 1;
is $segment->{end}->{y}, 5;

# project
my $vector = Math::Shape::Vector->new(3, 3);
ok my $range = $segment->project($vector);

# collides
is $segment->collides( $segment2), 1;
is $segment->collides( $segment3), 0;
is $segment3->collides($segment2), 0;

done_testing();

