# PP only
use strict;
use warnings;

use Test::More 0.96;

BEGIN { $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'PP' }
use List::SomeUtils;

is(
    Module::Implementation::implementation_for('List::SomeUtils'),
    'PP',
    'List::SomeUtils is using PP implementation'
);

done_testing();
