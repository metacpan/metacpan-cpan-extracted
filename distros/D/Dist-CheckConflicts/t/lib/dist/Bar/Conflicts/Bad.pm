package Bar::Conflicts::Bad;
use strict;
use warnings;

use Dist::CheckConflicts
    -dist => 'Bar',
    -conflicts => {
        'Bar' => '0.03',
    },
    -also => [
        'Bar::Conflicts::Bad2',
    ];

1;
