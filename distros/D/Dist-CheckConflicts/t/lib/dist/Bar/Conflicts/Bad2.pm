package Bar::Conflicts::Bad2;
use strict;
use warnings;

use Dist::CheckConflicts
    -dist => 'Bar',
    -conflicts => {
        'Bar::Two' => '0.02',
    },
    -also => [
        'Bar::Conflicts::Bad3',
    ];

1;
