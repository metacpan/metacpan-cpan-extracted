#!perl

# test basic usage, no callbacks, in playback mode

BEGIN {
    $ENV{ LWP_UA_MOCK } = 'playback';
}

use strict;
use warnings;

use LWP;
use Test::More;

eval {
    require LWP::UserAgent::Mockable;
};
ok( defined $@, "script dies if in playback mode and no playback file specified" );

done_testing();
