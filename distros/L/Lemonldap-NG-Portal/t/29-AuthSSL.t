use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => 'SSL',
            userDB         => 'Null',
            SSLVar         => 'SSL_CLIENT_S_DN_Custom',
            sslByAjax      => 1,
            sslHost        => 'https://authssl.example.com:19876'
        }
    }
);

ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        accept => 'text/html'
    ),
    'Get Menu'
);
my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

ok(
    $res->[2]->[0] =~
m%<script type="application/init">\s*\{"sslHost":"https://authssl.example.com:19876"\}\s*</script>%s,
    ' SSL AJAX URL found'
) or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/SSL.png"%,
    'Found 5_ssl Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /ssl\.(?:min\.)?js/, 'Get sslChoice javascript' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

ok(
    $res = $client->_get(
        '/',
        cookie => $pdata,
        accept => 'text/html',
        custom => { SSL_CLIENT_S_DN_Custom => 'dwho' }
    ),
    'Auth query'
);
expectCookie($res);
expectRedirection( $res, 'http://test1.example.com/' );
$pdata = expectCookie( $res, 'lemonldappdata' );
ok( $pdata eq '', 'pdata is empty' );
count(2);

&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
$client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => 'SSL',
            userDB         => 'Null',
        }
    }
);

ok(
    $res = $client->_get( '/', custom => { SSL_CLIENT_S_DN_Email => 'dwho' } ),
    'Auth query'
);

expectOK($res);
expectCookie($res);
count(1);

clean_sessions();

done_testing( count() );
