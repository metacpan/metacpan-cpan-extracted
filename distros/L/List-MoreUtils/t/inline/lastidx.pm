BEGIN
{
    $INC{'List/MoreUtils.pm'} or *last_index = __PACKAGE__->can("lastidx");
}

use Test::More;
use Test::LMU;

my @list = (1 .. 10000);
is(9999, lastidx { $_ >= 5000 } @list);
is(-1,   lastidx { not defined } @list);
is(9999, lastidx { defined } @list);
is(-1, lastidx {});

# Test aliases
is(9999, last_index { $_ >= 5000 } @list);
is(-1,   last_index { not defined } @list);
is(9999, last_index { defined } @list);
is(-1, last_index {});

leak_free_ok(
    lastidx => sub {
        my $i  = lastidx { $_ >= 5000 } @list;
        my $i2 = lastidx { $_ >= 5000 } 1 .. 10000;
    }
);
is_dying('lastidx without sub' => sub { &lastidx(42, 4711); });

done_testing;
