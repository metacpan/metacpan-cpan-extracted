#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *only_result = __PACKAGE__->can("onlyres");
}

use Test::More;
use Test::LMU;

my @list = (1 .. 300);
is("Hallelujah", onlyres { 150 == $_ and "Hallelujah" } @list);
is(1,            onlyres { 300 == $_ } @list);
is(undef,        onlyres { 0 == $_ } @list);
is(undef,        onlyres { 1 <= $_ } @list);
is(undef,        onlyres { !(127 & $_) } @list);

# Test aliases
is(1,            only_result { 150 == $_ } @list);
is("Hallelujah", only_result { 300 == $_ and "Hallelujah" } @list);
is(undef,        only_result { 0 == $_ } @list);
is(undef,        only_result { 1 <= $_ } @list);
is(undef,        only_result { !(127 & $_) } @list);

leak_free_ok(
    onlyres => sub {
        my $ok  = onlyres { 150 <= $_ } @list;
        my $ok2 = onlyres { 150 <= $_ } 1 .. 300;
    }
);
is_dying('onlyres without sub' => sub { &onlyres(42, 4711); });

done_testing;


