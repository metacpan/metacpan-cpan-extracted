package Foo::Conflicts2;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Foo::One'  => 0.03,
        'Foo::Two'  => 0.01,
        'Foo::Four' => 0.02,
    };

1;
