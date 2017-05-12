#!/perl
use strict;

use Test::More tests => 1;

use Growl::Tiny qw(notify);

ok( notify( { subject => 'notification subject; contains a semicolon' } ),
    "notification with semicolon"
);
