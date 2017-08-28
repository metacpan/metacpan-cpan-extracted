
use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 10000);
is_true(none  { not defined } @list);
is_true(none  { $_ > 10000 } @list);
is_false(none { defined } @list);
is_true(none {});

leak_free_ok(
    none => sub {
        my $ok  = none { $_ == 5000 } @list;
        my $ok2 = none { $_ == 5000 } 1 .. 10000;
    }
);
is_dying('none without sub' => sub { &none(42, 4711); });

done_testing;
