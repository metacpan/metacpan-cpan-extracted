package Foo::Conflicts::Good;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Foo'        => 0.01,
        'Foo::Two'   => 0.01,
        'Foo::Three' => 0.01,
        'NotInstalled' => '0.01',
    };

1;
