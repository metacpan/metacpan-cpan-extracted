use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_uncaught_exception );

eval { die "trapped" };
do_die();
sub do_die {
    die "untrapped"; # 11
}

sub __tests__ {
    plan tests => 1;

    ok_uncaught_exception
        filename => __FILE__,
        line => 11,
        package => 'main',
        subroutine => 'main::do_die',
        exception => 'untrapped at '.__FILE__." line 11.\n";
}

