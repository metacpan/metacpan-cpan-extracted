use Test::More;
use File::Copy;
use File::Temp 'tempdir';
use JSON;
use MIME::Base64;
use URI::Escape;

BEGIN {
    require 't/test-psgi-lib.pm';
}

my $confDir = tempdir( CLEANUP => 1 );
my $res;

init( 'Lemonldap::NG::Handler::PSGI',
    { configStorage => { type => 'File', dirName => $confDir } } );

ok( $res = $client->_get('/'), 'Request without configuration' );
ok( $res->[0] == 500, 'Get a 500 code' );

copy 't/lmConf-1.json', "$confDir/lmConf-1.json";
ok( $res = $client->_get('/'), 'Request with configuration' );
ok( $res->[0] < 400, 'No more error' ) or explain ($res->[0], '302');

done_testing();
