#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *only_value = __PACKAGE__->can("onlyval");
}

use Test::More;
use Test::LMU;

my @list = (1 .. 300);
is(1,     onlyval { 1 == $_ } @list);
is(150,   onlyval { 150 == $_ } @list);
is(300,   onlyval { 300 == $_ } @list);
is(undef, onlyval { 0 == $_ } @list);
is(undef, onlyval { 1 <= $_ } @list);
is(undef, onlyval { !(127 & $_) } @list);

# Test aliases
is(1,     only_value { 1 == $_ } @list);
is(150,   only_value { 150 == $_ } @list);
is(300,   only_value { 300 == $_ } @list);
is(undef, only_value { 0 == $_ } @list);
is(undef, only_value { 1 <= $_ } @list);
is(undef, only_value { !(127 & $_) } @list);

leak_free_ok(
    onlyval => sub {
        my $ok  = onlyval { 150 <= $_ } @list;
        my $ok2 = onlyval { 150 <= $_ } 1 .. 300;
    }
);
is_dying('onlyval without sub' => sub { &onlyval(42, 4711); });

done_testing;


