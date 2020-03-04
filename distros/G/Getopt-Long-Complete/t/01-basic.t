#!perl

use strict;
use warnings;
use Test::More 0.98;

use Getopt::Long::Complete;

is($REQUIRE_ORDER, 0);

subtest GetOptions => sub {
    local @ARGV = ("--foo", "--bar", "baz");
    my %opts;
    GetOptions(
        'foo' => \$opts{foo},
        'bar=s' => sub { $opts{bar} = $_[1] },
    );
    ok($opts{foo});
    is($opts{bar}, "baz");
};

DONE_TESTING:
done_testing;
