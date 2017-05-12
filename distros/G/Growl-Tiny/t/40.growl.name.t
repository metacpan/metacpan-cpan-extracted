#!/perl
use strict;

use Test::More tests => 1;

use Growl::Tiny qw(notify);

ok( notify( { subject => 'image',
              title   => 'image growl',
              name    => 'Growl::Tiny::TestCase',
          }),
    "notify() called with 'name' set to GROW::Tiny::TestCase"
);
