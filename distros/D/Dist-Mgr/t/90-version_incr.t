use warnings;
use strict;

use Test::More;

use Data::Dumper;
use Hook::Output::Tiny;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

# bad params
{
    # no version
    is eval {
        version_incr();
        1
    }, undef, "version_incr() croaks if no param";
    like $@, qr/needs a version number/, "...and error is sane";

    # invalid version
    is eval {
        version_incr('1.07asdf');
        1
    }, undef, "invalid version croaks ok";
    like $@, qr/The version number/, "...and error is sane";
}

# version
{
    my $orig = '0.01';
    my $v = '0.01';

    for (0..500) {
        $v = version_incr($v);

        my $incr = ('0.01' * $_) + '0.01';
        is $v, sprintf("%.2f", $orig + $incr), "version incremented to $v at round $_ ok";
    }
}

done_testing();

