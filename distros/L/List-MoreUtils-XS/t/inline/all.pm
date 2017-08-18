
use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 10000);
is_true(all  { defined } @list);
is_true(all  { $_ > 0 } @list);
is_false(all { $_ < 5000 } @list);
is_true(all {});

leak_free_ok(
    all => sub {
        my $ok  = all { $_ == 5000 } @list;
        my $ok2 = all { $_ == 5000 } 1 .. 10000;
    }
);
is_dying('all without sub' => sub { &all(42, 4711); });

done_testing;
