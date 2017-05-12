package Bar::Conflicts3;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Bar::Also::Also' => 0.12,
    };

1;
