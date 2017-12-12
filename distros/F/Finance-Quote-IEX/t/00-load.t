use strict;
use warnings;
use Test::More;

BEGIN {
    my @modules = qw(
        Finance::Quote::IEX
    );

    for my $module (@modules) {
        use_ok($module) or BAIL_OUT("Failed to load $module");
    }
}

diag(
    sprintf(
        'Testing Finance::Quote::IEX %f, Perl %f, %s', $Finance::Quote::IEX::VERSION, $], $^X
    )
);

done_testing();
