package Bar::Conflicts;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Bar::Local' => 0.02,
    },
    -also => [
        'Foo',
    ];

1;
