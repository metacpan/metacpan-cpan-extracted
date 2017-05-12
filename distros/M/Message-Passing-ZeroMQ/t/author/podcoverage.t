use strict;
use warnings;
use Test::More;

use Pod::Coverage::Moose;
use Test::Pod::Coverage 1.04;

my @modules = all_modules;
our @private = ( 'BUILD' );
foreach my $module (@modules) {

    pod_coverage_ok($module, {
        coverage_class => 'Pod::Coverage::Moose',
    });
}

done_testing;

