#!/perl
use strict;

use Test::More tests => 4;

use Growl::Tiny;

ok( Growl::Tiny::_set_growl_command( "/usr/bin/false" ),
    "Setting growl command to /usr/bin/false for automated testing"
);

ok( ! Growl::Tiny::notify( { subject => 'test subject with failing growl notify command' } ),
    "GROWL: notify with growl command set to /usr/bin/false"
);

ok( Growl::Tiny::_set_growl_command( "/bin/abcxyzpdq" ),
    "Setting growl command to /bin/false for automated testing"
);

ok( ! Growl::Tiny::notify( { subject => 'test subject with failing growl notify command' } ),
    "GROWL: notify with growl command set to non-existent path"
);
