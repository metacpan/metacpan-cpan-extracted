#!/perl
use strict;

use Test::More tests => 3;

use Growl::Tiny qw(notify);

ok( notify( { subject => 'growl identifier message 1',
              title   => 'first growl',
              identifier => 'foo',
          }),
    "notify() called with growl identifier"
);

sleep 1;

ok( notify( { subject => 'growl identifier message 2',
              title   => 'second growl',
              identifier => 'foo',
          }),
    "notify() called with growl identifier"
);

sleep 1;

ok( notify( { subject => 'growl identifier message 3',
              title   => 'third growl',
              identifier => 'foo',
          }),
    "notify() called with growl identifier"
);
