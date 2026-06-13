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

# version (two decimal places)
{
    my $orig = '0.01';
    my $v = '0.01';

    for (0..500) {
        $v = version_incr($v);

        my $incr = ('0.01' * $_) + '0.01';
        is $v, sprintf("%.2f", $orig + $incr), "version incremented to $v at round $_ ok";
    }
}

# version (four decimal places - precision must be preserved)
{
    is version_incr('3.1802'), '3.1803', "3.1802 increments to 3.1803, not 3.19";
    is version_incr('3.1899'), '3.1900', "four-decimal carry preserves precision";

    my $orig = '0.0001';
    my $v = '0.0001';

    for (0..500) {
        $v = version_incr($v);

        my $incr = ('0.0001' * $_) + '0.0001';
        is $v, sprintf("%.4f", $orig + $incr), "four-decimal version incremented to $v at round $_ ok";
    }
}

done_testing();

