package Foo::Conflicts::Broken;
use strict;
use warnings;

use Dist::CheckConflicts
    -conflicts => {
        'Broken' => '0.03',
        'NotInstalled' => '0.01',
    };

1;
