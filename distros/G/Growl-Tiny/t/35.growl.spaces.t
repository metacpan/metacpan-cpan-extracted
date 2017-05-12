#!/perl
use strict;

use Test::More tests => 1;

use Growl::Tiny qw(notify);

ok( notify( { priority => 0, stick => undef, title => "multiword title", subject => "multiword subject" } ),
    "notification with spaces in title"
);
