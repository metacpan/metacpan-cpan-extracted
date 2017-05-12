package Bar::Conflicts;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Bar::Local' => 0.02,
    },
    -also => [
        'Bar::Conflicts2',
    ];

1;
