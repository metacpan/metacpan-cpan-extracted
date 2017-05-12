package Foo::Conflicts;
use strict;
use warnings;

use Dist::CheckConflicts
    ':runtime',
    -conflicts => {
        'Foo::Foo'  => 0.01,
        'Foo::Bar'  => 0.01,
        'Foo::Baz'  => 0.01,
        'Foo::Quux' => 0.01,
    };

1;
