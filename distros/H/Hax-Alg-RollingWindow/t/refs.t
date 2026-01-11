use strict;
use warnings;

use Test::More;

use Scalar::Util qw(weaken);

use lib 'lib';
use Hax::Alg::RollingWindow;

# This test ensures references are released promptly when evicted or cleared.

{
    my $w = Hax::Alg::RollingWindow->new(capacity => 2);

    my $obj1 = bless({}, 'T::Obj');
    my $weak1 = $obj1;
    weaken($weak1);

    my $obj2 = bless({}, 'T::Obj');
    my $weak2 = $obj2;
    weaken($weak2);

    $w->add($obj1, $obj2);

    # Both should still be alive (held by window + our strong refs)
    ok(defined $weak1, "obj1 alive before eviction");
    ok(defined $weak2, "obj2 alive before eviction");

    # Drop our strong reference to obj1; window should be the only owner now
    undef $obj1;
    ok(defined $weak1, "obj1 still alive (held by window)");

    # Add another item; obj1 should be evicted and slot cleared -> weak should drop
    $w->add(bless({}, 'T::Obj'));
    ok(!defined $weak1, "obj1 freed after eviction (slot cleared)");

    # Now test clear() releases remaining references
    undef $obj2; # leave window holding obj2
    ok(defined $weak2, "obj2 still alive (held by window)");

    $w->clear;
    ok(!defined $weak2, "obj2 freed after clear (slots cleared)");
}

done_testing;
