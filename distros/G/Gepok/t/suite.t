#!perl

# run Plack test suite for testing PSGI server implementation

use strict;
use warnings;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all =>
                             'these tests are for release candidate testing');
    }
}

use Plack::Test::Suite;
use Test::More;

Plack::Test::Suite->run_server_tests('Gepok');

done_testing();
