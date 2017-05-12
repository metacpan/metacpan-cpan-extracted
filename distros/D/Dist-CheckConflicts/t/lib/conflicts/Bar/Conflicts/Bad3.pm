package Bar::Conflicts::Bad3;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Bar::Three' => '0.01',
    };

1;
