package Bar::Conflicts::Good2;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Bar::Two' => '0.01',
    },
    -also => [
        'Bar::Conflicts::Good3',
    ];

1;
