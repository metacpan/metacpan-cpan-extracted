
use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 10000);
is_true(any  { $_ == 5000 } @list);
is_true(any  { $_ == 5000 } 1 .. 10000);
is_true(any  { defined } @list);
is_false(any { not defined } @list);
is_true(any  { not defined } undef);
is_false(any {});

leak_free_ok(
    any => sub {
        my $ok  = any { $_ == 5000 } @list;
        my $ok2 = any { $_ == 5000 } 1 .. 10000;
    }
);
leak_free_ok(
    'any with a coderef that dies' => sub {
        # This test is from Kevin Ryde; see RT#48669
        eval {
            my $ok = any { die } 1;
        };
    }
);
is_dying('any without sub' => sub { &any(42, 4711); });

done_testing;
