#!perl -T
use strict;
use warnings;
use Test::More;

BEGIN {
    my @modules = qw(
        Math::Fractal::Julia
    );

    for my $module (@modules) {
        use_ok($module) or BAIL_OUT("Failed to load $module");
    }
}

diag(
    sprintf(
        'Testing Math::Fractal::Julia %f, Perl %f, %s',
        $Math::Fractal::Julia::VERSION,
        $], $^X
    )
);

done_testing();

