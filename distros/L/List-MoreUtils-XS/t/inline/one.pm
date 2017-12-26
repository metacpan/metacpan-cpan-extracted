
use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 300);
is_true(one  { 1 == $_ } @list);
is_true(one  { 150 == $_ } @list);
is_true(one  { 300 == $_ } @list);
is_false(one { 0 == $_ } @list);
is_false(one { 1 <= $_ } @list);
is_false(one { !(127 & $_) } @list);
is_false(one { 0 } ());

leak_free_ok(
    one => sub {
        my $ok  = one { 150 <= $_ } @list;
        my $ok2 = one { 150 <= $_ } 1 .. 300;
    }
);
is_dying('one without sub' => sub { &one(42, 4711); });

done_testing;
