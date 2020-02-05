#! perl

use strict;

use Test::More tests => 1;

my $log;
if ( open( my $fd, '<', "config.log" ) ) {
    undef $/;
    $log = <$fd>;
}
else {
    $log = "config.log: $!\n";
};

diag($log);
pass();
