use warnings;
use Test::More;
use strict;
use IO::String;
use URI::Escape;
use Plack::Response;

require 't/test-lib.pm';

my $res;
my $tmp;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            useRedirectOnError => 0,
            vhostOptions       => {
                'auth.example.com' => {
                    vhostMaintenance => 1,
                },
            },
        }
    }
);

# Two simple access to see if pdata is set and restored
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Simple access' );
ok( $res->[0] == 503, 'Portal is in maintainance mode' )
  or explain( $res->[0], '503' );

ok( $res = $client->_get( '/lmerror/503', accept => 'text/html' ),
    'Attempt to access to /lmerror/503' );
ok( $res->[0] == 200, 'Maintainance page is displayed' );

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            useRedirectOnError => 1,
            vhostOptions       => {
                'auth.example.com' => {
                    vhostMaintenance => 1,
                },
            },
        }
    }
);

# Two simple access to see if pdata is set and restored
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Simple access' );
expectRedirection( $res,
    'http://auth.example.com//lmerror/503?url=aHR0cDovL2F1dGguZXhhbXBsZS5jb20v'
);

ok( $res = $client->_get( '/lmerror/503', accept => 'text/html' ),
    'Attempt to access to /lmerror/503' );
ok( $res->[0] == 200, 'Maintainance page is displayed' );

clean_sessions();

done_testing();
