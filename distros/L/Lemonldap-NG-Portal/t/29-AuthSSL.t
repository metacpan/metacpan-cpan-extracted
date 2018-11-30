use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => 'SSL',
            userDB         => 'Null',
            SSLVar         => 'SSL_CLIENT_S_DN_Custom',
        }
    }
);

ok(
    $res = $client->_get(
        '/', custom => { SSL_CLIENT_S_DN_Custom => 'dwho' }
    ),
    'Auth query'
);
expectOK($res);
expectCookie($res);
count(1);

&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
$client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => 'SSL',
            userDB         => 'Null',
        }
    }
);

ok(
    $res = $client->_get(
        '/', custom => { SSL_CLIENT_S_DN_Email => 'dwho' }
    ),
    'Auth query'
);
expectOK($res);
expectCookie($res);
count(1);

clean_sessions();

done_testing( count() );
