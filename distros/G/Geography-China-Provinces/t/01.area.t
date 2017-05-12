use strict;
use warnings;
use Test::More;
use Test::Pretty;

use Geography::China::Provinces;

subtest 'areas' => sub {
    plan tests => 18 + 1;
    my %areas = Geography::China::Provinces->areas;
    is(scalar(keys %areas), 6, 'area count ok');
    for my $id (keys %areas) {
        ok($id >= 1 && $id <= 6, 'area_id ok');
        ok(exists $areas{$id}->{en}, 'has en');
        ok(exists $areas{$id}->{zh}, 'has zh');
    }
};

done_testing;
