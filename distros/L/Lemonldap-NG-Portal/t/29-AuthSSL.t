use Test::More;
use IO::String;
use URI;
use strict;

require 't/test-lib.pm';

my $res;

sub testUserTokenSSLAuth {
    my %params = @_;
    my $choice = $params{'choice'};

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel    => 'error',
                useSafeJail => 1,
                (
                    $choice
                    ? (
                        authentication    => 'Choice',
                        userDB            => 'Same',
                        authChoiceParam   => 'test',
                        authChoiceModules => {
                            '1_demo' => 'Demo;Demo;Null',
                            '2_ssl'  => 'SSL;Demo;Null',
                        },
                      )
                    : (
                        authentication => 'SSL',
                        userDB         => 'Demo',
                    )
                ),

                SSLVar            => 'SSL_CLIENT_S_DN_Custom',
                SSLIssuerVar      => 'SSL_CLIENT_I_DN_Custom',
                sslByAjax         => 1,
                sslHost           => 'https://authssl.example.com/authssl',
                restSessionServer => 1,
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
m%<script type="application/init">\s*\{"sslHost":"https://authssl.example.com/authssl"\}\s*</script>%s,
        ' SSL AJAX URL found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/SSL.png"%,
        'Found 5_ssl Logo' )
      or print STDERR Dumper( $res->[2]->[0] );
    my $scriptname = "ssl" . ( $choice ? "Choice" : "" ) . "(?:min)?\.js";
    ok( $res->[2]->[0] =~ /$scriptname/, 'Get ssl javascript' )
      or print STDERR Dumper( $res->[2]->[0] );

    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'nossl', 'ajax_auth_token' );

    # AJAX request
    ok(
        $res = $client->_get(
            '/authssl',
            accept => 'application/json',
            custom => {
                SSL_CLIENT_S_DN_Custom   => 'dwho',
                'SSL_CLIENT_I_DN_Custom' => 'cn=MyIssuer'
            }
        ),
        'Auth query'
    );
    my $json = expectJSON($res);
    ok( $json->{ajax_auth_token}, "User token was returned" );
    my $ajax_auth_token = $json->{ajax_auth_token};

    $query .= "&ajax_auth_token=$ajax_auth_token";

    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post form'
    );
    my $id = expectCookie($res);
    expectRedirection( $res, 'http://test1.example.com/' );
    expectSessionAttributes(
        $client, $id,
        authenticationLevel => 5,
        _auth               => 'SSL',
        _Issuer             => 'cn=MyIssuer',
        _user               => 'dwho',
        uid                 => 'dwho'
    );
}

sub testLegacyAjaxSSL {
    my %params = @_;
    my $choice = $params{'choice'};
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel    => 'error',
                useSafeJail => 1,
                (
                    $choice
                    ? (
                        authentication    => 'Choice',
                        userDB            => 'Same',
                        authChoiceParam   => 'test',
                        authChoiceModules => {
                            '1_demo' => 'Demo;Demo;Null',
                            '2_ssl'  => 'SSL;Demo;Null',
                        },
                        sslHost =>
                          'https://authssl.example.com:19876/?test=2_ssl'
                      )
                    : (
                        authentication => 'SSL',
                        userDB         => 'Demo',
                        sslHost        => 'https://authssl.example.com:19876/'
                    )
                ),
                SSLVar    => 'SSL_CLIENT_S_DN_Custom',
                sslByAjax => 1,
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
m%<script type="application/init">\s*\{"sslHost":"([^"]*)"\}\s*</script>%s,
        ' SSL AJAX URL found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    my $sslHost = URI->new($1);
    is( $sslHost->authority, "authssl.example.com:19876", "Correct hostname" );
    is( $sslHost->path,      "/",                         "Correct path" );
    is( $sslHost->query, ( $choice ? "test=2_ssl" : undef ), "Correct query" );

    ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/SSL.png"%,
        'Found 5_ssl Logo' )
      or print STDERR Dumper( $res->[2]->[0] );
    my $scriptname = "ssl" . ( $choice ? "Choice" : "" ) . "(?:min)?\.js";
    ok( $res->[2]->[0] =~ /$scriptname/, 'Get ssl javascript' )
      or print STDERR Dumper( $res->[2]->[0] );

    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'nossl' );

    # AJAX request
    ok(
        $res = $client->_get(
            $sslHost->path,
            query  => $sslHost->query,
            accept => 'application/json',
            custom => { SSL_CLIENT_S_DN_Custom => 'dwho' }
        ),
        'Auth query'
    );
    my $json = expectJSON($res);
    is( $json->{result}, 1, "Correct result" );
    is( $json->{error},  0, "No error" );

    my $id = expectCookie($res);

    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Post form'
    );
    expectRedirection( $res, 'http://test1.example.com/' );
}

subtest 'Usertoken SSL Auth' => \&testUserTokenSSLAuth, choice => 0;
subtest
  'Usertoken SSL Auth (with choice)' => \&testUserTokenSSLAuth,
  choice                             => 1;

subtest 'Legacy AJAX SSL Auth' => \&testLegacyAjaxSSL, choice => 0;
subtest
  'Legacy AJAX SSL Auth (with Choice)' => \&testLegacyAjaxSSL,
  choice                               => 1;

subtest 'Regular SSL Auth' => sub {
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                useSafeJail    => 1,
                authentication => 'SSL',
                userDB         => 'Null',
            }
        }
    );

    my $res;
    ok(
        $res =
          $client->_get( '/', custom => { SSL_CLIENT_S_DN_Email => 'dwho' } ),
        'Auth query'
    );

    expectOK($res);
    expectCookie($res);
};

sub testSSLVarIf {
    my ( $client, $headers, $expected ) = @_;
    my $res;
    ok( $res = $client->_get( '/', custom => $headers ), 'Auth query' );

    expectOK($res);
    my $id = expectCookie($res);

    # Test authentication
    ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ) );
    expectOK($res);
    expectAuthenticatedAs( $res, $expected );
}

subtest 'SSLVarIf mechanism' => sub {
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                useSafeJail    => 1,
                authentication => 'SSL',
                userDB         => 'Null',
                SSLVar         => 'SSL_CLIENT_S_DN_Email',
                SSLIssuerVar   => 'SSL_CLIENT_I_DN_CN',
                SSLVarIf       => {
                    'CA1' => "SSL_CLIENT_S_DN_UID",
                    'CA2' => "SSL_CLIENT_S_DN_CN",
                },
            }
        }
    );

    my $subjectInfo = {
        'SSL_CLIENT_S_DN_Email' => 'dwho@example.com',
        'SSL_CLIENT_S_DN_UID'   => 'dwho',
        'SSL_CLIENT_S_DN_CN'    => 'Doctor Who',
    };

    subtest "Testing SSLVarIf with CA1", sub {
        testSSLVarIf( $client,
            { %$subjectInfo, 'SSL_CLIENT_I_DN_CN' => 'CA1' }, 'dwho' );
    };
    subtest "Testing SSLVarIf with CA2", sub {
        testSSLVarIf( $client, { %$subjectInfo, 'SSL_CLIENT_I_DN_CN' => 'CA2' },
            'Doctor Who' );
    };
    subtest "Testing SSLVarIf with unknown CA", sub {
        testSSLVarIf( $client, { %$subjectInfo, 'SSL_CLIENT_I_DN_CN' => 'CA3' },
            'dwho@example.com' );
    };
    subtest "Testing SSLVarIf with no CA", sub {
        testSSLVarIf( $client, $subjectInfo, 'dwho@example.com' );
    };

};

done_testing();
