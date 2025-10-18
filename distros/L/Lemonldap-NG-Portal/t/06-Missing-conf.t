use Test::More;
use File::Copy;
use File::Temp 'tempdir';
use JSON;
use MIME::Base64;
use URI::Escape;

BEGIN {
    require 't/test-lib.pm';
}

# Initialization
my $confDir = tempdir( CLEANUP => 1 );
my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            configStorage =>
              { type => 'File', dirName => $confDir, confFile => '/dev/null' }
        },
        confFailure => 1,
    }
);

# Complete init since "confFailure" was used
ok( $client->{p}->init( $client->{ini} ) == 0, 'Init' );
ok( $client->{app} = $client->{p}->run(),      'Portal app' );

# Test
ok( $res = $client->_get( '/', accept => 'text/html' ),
    'Request without configuration' );
ok( $res->[0] == 500, 'Get a 500 code' );

copy 't/lmConf-1.json', "$confDir/lmConf-1.json";
ok( $res = $client->_get( '/', accept => 'text/html' ),
    'Request with configuration' );
ok( $res->[0] < 400, 'No more error' ) or explain( $res->[0], '200' );

done_testing();
