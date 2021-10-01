#!perl

use strict;
use warnings;

# This test pretty much exists only to remind the author to make sure djare
# versions are updated

use Test::Most;
use JSON::DJARE::Writer;

for ( '0.0.1', '0.0.3', '0.1.0' ) {
    throws_ok {
        JSON::DJARE::Writer->new(
            djare_version => $_,
            meta_version  => '99.99.99',
        )
    }
    qr/Only supported `djare_version` is 0.0.2/,
      "[$_] is not an acceptable version";
}

lives_ok {
    JSON::DJARE::Writer->new(
        djare_version => '0.0.2',
        meta_version  => '99.99.99',
    )
}
"0.0.2 is an acceptable version";

done_testing();