use strict;
use warnings;

use Test::More tests => 1;

# Test set 1 -- can we load the library?
use Lirc::Client;

SKIP: {

    skip "/dev/lircd isn't readable. lirc must installed and run.", 1
      unless -r '/dev/lircd';

    # Test the connection to /dev/lircd
    my $lirc = Lirc::Client->new(
        'lclient_test',
        {
            rcfile => 'samples/lircrc',
            debug  => 1,
            fake   => 0,
        } );
    ok $lirc, "Created new Lirc::Client with named args";
}
