use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all =>
        'set RELEASE_TESTING=1 to run release-only Kwalitee checks'
        unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok();
done_testing();
