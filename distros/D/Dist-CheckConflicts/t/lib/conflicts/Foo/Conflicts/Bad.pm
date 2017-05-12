package Foo::Conflicts::Bad;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Foo'        => 0.03,
        'Foo::Two'   => 0.02,
        'Foo::Three' => 0.01,
    };

1;
