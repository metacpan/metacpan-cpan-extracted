package Bar::Conflicts::Bad;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Bar' => '0.03',
    },
    -also => [
        'Bar::Conflicts::Bad2',
    ];

1;
