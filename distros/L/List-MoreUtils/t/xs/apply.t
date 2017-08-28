#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

# Test the null case
my $null_scalar = apply {};
is($null_scalar, undef, 'apply(null) returns undef');

my @null_list = apply {};
is_deeply(\@null_list, [], 'apply(null) returns null list');

# Normal cases
my @list = (0 .. 9);
my @list1 = apply { $_++ } @list;
is_deeply(\@list,  [0 .. 9],  "original numbers untouched");
is_deeply(\@list1, [1 .. 10], "returned numbers increased");
@list = (" foo ", " bar ", "     ", "foobar");
@list1 = apply { s/^\s+|\s+$//g } @list;
is_deeply(\@list,  [" foo ", " bar ", "     ", "foobar"], "original strings untouched");
is_deeply(\@list1, ["foo",   "bar",   "",      "foobar"], "returned strings stripped");
my $item = apply { s/^\s+|\s+$//g } @list;
is($item, "foobar");

# RT 96596
SKIP:
{
    $INC{'List/MoreUtils/XS.pm'} or skip "PurePerl will not fail here ...", 1;
    eval { my @a = \&apply(1, 2); };
    my $err = $@;
    like($err, qr/\QList::MoreUtils::XS::apply(code, ...)\E/, "apply must be reasonable invoked");
}

# RT 38630
SCOPE:
{
    # wrong results from apply() [XS]
    @list = (1 .. 4);
    @list1 = apply { grow_stack(); $_ = 5; } @list;
    is_deeply(\@list,  [1 .. 4]);
    is_deeply(\@list1, [(5) x 4]);
}

leak_free_ok(
    apply => sub {
        @list  = (1 .. 4);
        @list1 = apply
        {
            grow_stack();
            $_ = 5;
        }
        @list;
    }
);

SCOPE:
{
    leak_free_ok(
        'dying callback during apply' => sub {
            my @l = (1 .. 4);
            eval {
                my @l1 = apply { $_ % 2 or die "Even!"; $_ %= 2; } @l;
            };
        }
    );
}

is_dying('apply without sub' => sub { &apply(42, 4711); });

done_testing;


