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

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
ok(
    $res->[2]->[0] =~
m%<script type="application/init">\{"sslHost":"https://authssl.example.com:19876"\}</script>%,
    ' SSL AJAX URL found'
) or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/SSL.png"%,
    'Found 5_ssl Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /ssl\.(?:min\.)?js/, 'Get sslChoice javascript' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

ok(
    $res = $client->_get( '/', custom => { SSL_CLIENT_S_DN_Custom => 'dwho' } ),
    'Auth query'
);
expectOK($res);
expectCookie($res);
count(1);

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
