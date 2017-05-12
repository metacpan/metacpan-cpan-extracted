package Bar::Conflicts::Bad3;
use strict;
use warnings;

use Dist::CheckConflicts
    -dist => 'Bar',
    -conflicts => {
        'Bar::Three' => '0.01',
    };

1;
