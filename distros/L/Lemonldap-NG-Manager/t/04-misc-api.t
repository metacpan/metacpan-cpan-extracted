# Test Providers API

use warnings;
use Test::More;
use strict;
use JSON;
use IO::String;
require 't/test-lib.pm';

sub LLNG::Manager::Test::getStatus {
    my ( $client, $test, $expectCode ) = @_;
    my $res;
    ok( $res = $client->_get( "/api/v1/status", '' ),
        "$test: Request succeed" );
    is( $res->[0], $expectCode || 200, "$test: correct status code" );
    count(1);
    return from_json( $res->[2]->[0] );
}

my $client = LLNG::Manager::Test->new;

# "break" config file
rename "$main::tmpdir/conf/lmConf-1.json", "$main::tmpdir/conf/lmConf-1.json.broken";
my $brokenconfig = $client->getStatus( "Broken config backend", 503 );
is( $brokenconfig->{status},        'ko', 'Got expected global status' );
is( $brokenconfig->{status_config}, 'ko', 'Got expected config status' );
rename "$main::tmpdir/conf/lmConf-1.json.broken", "$main::tmpdir/conf/lmConf-1.json";

my $allfine = $client->getStatus("Back to normal");
is( $allfine->{status},           'ok',      'Got expected global status' );
is( $allfine->{status_config},    'ok',      'Got expected config status' );
is( $allfine->{status_sessions},  'unknown', 'Not implemented yet' );
is( $allfine->{status_psessions}, 'unknown', 'Not implemented yet' );

# Clean up generated files, except for "lmConf-1.json"
unlink grep { $_ ne "$main::tmpdir/conf/lmConf-1.json" }
  glob "$main::tmpdir/conf/lmConf-*.json";

done_testing();
