BEGIN
{
    $INC{'List/MoreUtils.pm'} or *only_index = __PACKAGE__->can("onlyidx");
}

use Test::More;
use Test::LMU;

my @list = (1 .. 300);
is(0,   onlyidx { 1 == $_ } @list);
is(149, onlyidx { 150 == $_ } @list);
is(299, onlyidx { 300 == $_ } @list);
is(-1,  onlyidx { 0 == $_ } @list);
is(-1,  onlyidx { 1 <= $_ } @list);
is(-1,  onlyidx { !(127 & $_) } @list);

# Test aliases
is(0,   only_index { 1 == $_ } @list);
is(149, only_index { 150 == $_ } @list);
is(299, only_index { 300 == $_ } @list);
is(-1,  only_index { 0 == $_ } @list);
is(-1,  only_index { 1 <= $_ } @list);
is(-1,  only_index { !(127 & $_) } @list);

leak_free_ok(
    onlyidx => sub {
        my $ok  = onlyidx { 150 <= $_ } @list;
        my $ok2 = onlyidx { 150 <= $_ } 1 .. 300;
    }
);
is_dying('onlyidx without sub' => sub { &onlyidx(42, 4711); });

done_testing;
