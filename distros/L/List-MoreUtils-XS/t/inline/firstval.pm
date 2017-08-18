BEGIN
{
    $INC{'List/MoreUtils.pm'} or *first_value = __PACKAGE__->can("firstval");
}

use Test::More;
use Test::LMU;

my $x = firstval { $_ > 5 } 4 .. 9;
is($x, 6);
$x = firstval { $_ > 5 } 1 .. 4;
is($x, undef);
is_undef(firstval { $_ > 5 });

# Test aliases
$x = first_value { $_ > 5 } 4 .. 9;
is($x, 6);
$x = first_value { $_ > 5 } 1 .. 4;
is($x, undef);

leak_free_ok(
    firstval => sub {
        $x = firstval { $_ > 5 } 4 .. 9;
    }
);
is_dying('firstval without sub' => sub { &firstval(42, 4711); });

done_testing;
