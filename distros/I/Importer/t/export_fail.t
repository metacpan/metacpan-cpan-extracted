use strict;
use warnings;

use Test::More;

my @got;
BEGIN {
    $INC{'FAIL.pm'} = 1;
    package FAIL;

    our @EXPORT = qw/foo $bar/;
    our @EXPORT_FAIL = qw/foo $bar/;

    sub export_fail {
        @got = @_;
        return();
    }
}

use Importer FAIL => qw/&foo $bar/;

is_deeply(
    \@got,
    [qw/FAIL foo $bar/],
    "'&' stripped from sub export"
);

done_testing;
