package Bar::Conflicts;
use strict;
use warnings;

use Dist::CheckConflicts
    ':runtime',
    -conflicts => {
        'Bar::Foo'        => 0.01,
        'Bar::Foo::Good'  => 0.01,
        'Bar::Foo::Bad'   => 0.01,
        'Bar::Bar'        => 0.01,
        'Bar::Bar::Good'  => 0.01,
        'Bar::Bar::Bad'   => 0.01,
        'Bar::Baz'        => 0.01,
        'Bar::Baz::Good'  => 0.01,
        'Bar::Baz::Bad'   => 0.01,
        'Bar::Quux'       => 0.01,
        'Bar::Quux::Good' => 0.01,
        'Bar::Quux::Bad'  => 0.01,
    };

1;
