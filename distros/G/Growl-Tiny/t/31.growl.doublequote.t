#!/perl
use strict;

use Test::More tests => 1;

use Growl::Tiny qw(notify);

ok( notify( { subject => 'notification subject contains "double" quotes' } ),
    "notification with double quotes"
);
