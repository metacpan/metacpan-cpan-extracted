package Foo::Conflicts;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Foo::One'   => 0.01,
        'Foo::Two'   => 0.03,
        'Foo::Three' => 0.02,
    },
    -also => [
        'Foo::Conflicts2',
    ];

1;
