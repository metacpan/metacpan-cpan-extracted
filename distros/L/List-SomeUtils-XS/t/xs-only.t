use strict;
use warnings;

use Test::More 0.96;
use Test::Warnings 0.006;

BEGIN {
    eval 'use List::SomeUtils 0.56';
    if ($@) {
        plan skip_all => 'These tests require that List::SomeUtils 0.56 already be installed';
    }
}

BEGIN {
    $^W++;
    $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'XS';
}
use List::SomeUtils;

is(
    Module::Implementation::implementation_for('List::SomeUtils'),
    'XS',
    'List::SomeUtils is using XS implementation'
);

done_testing();
