package Bar::Conflicts::Good;
use strict;
use warnings;

use Dist::CheckConflicts
    -dist => 'Bar',
    -conflicts => {
        'Bar' => '0.01',
    },
    -also => [
        'Bar::Conflicts::Good2',
    ];

1;
