use warnings;
use strict;
use File::Temp 'tempdir';
use IO::String;
use JSON;
use MIME::Base64;
use Test::More;

no warnings 'once';

our $debug     = 'error';
our $maintests = 51;
my ( $p, $res, $spId );
$| = 1;

$LLNG::TMPDIR = tempdir( 'tmpSessionXXXXX', DIR => 't/sessions', CLEANUP => 1 );

require 't/separate-handler.pm';

require "t/test-lib.pm";

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    ok( $p = issuer(), 'Issuer portal' );

    # BEGIN TESTS
    ok( $res = handler( req => [ GET => 'http://test2.example.com/' ] ),
        'Simple request to handler' );
    ok(
        getHeader( $res, 'WWW-Authenticate' ) eq 'Basic realm="LemonLDAP::NG"',
        'Get WWW-Authenticate header'
    );

    my $subtest = 0;
    foreach my $user (qw(dwho)) {
        ok( $res = $p->_get( '/', accept => 'text/html' ), 'Get Menu', );
        my ( $host, $url, $query ) =
          expectForm( $res, '#', undef, 'user', 'password' );

        $query =~ s/user=/user=dwho/;
        $query =~ s/password=/password=dwho/;
        ok(
            $res = $p->_post(
                '/',
                IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Auth query'
        );
        my $id = expectCookie($res);
        expectRedirection( $res, 'http://auth.idp.com/' );

        # TOTP form
        ok(
            $res = $p->_get(
                '/2fregisters',
                cookie => "lemonldap=$id",
                accept => 'text/html',
            ),
            'Form registration'
        );
        expectRedirection( $res, qr#/2fregisters/totp$# );
        ok(
            $res = $p->_get(
                '/2fregisters/totp',
                cookie => "lemonldap=$id",
                accept => 'text/html',
            ),
            'Form registration'
        );
        ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/,
            'Found TOTP js' );

        # JS query
        ok(
            $res = $p->_post(
                '/2fregisters/totp/getkey',
                IO::String->new(''),
                cookie => "lemonldap=$id",
                length => 0,
                custom => {
                    HTTP_X_CSRF_CHECK => 1,
                },
            ),
            'Get new key'
        );
        eval { $res = JSON::from_json( $res->[2]->[0] ) };
        ok( not($@), 'Content is JSON' )
          or explain( $res->[2]->[0], 'JSON content' );
        my ( $key, $token );
        ok( $key   = $res->{secret}, 'Found secret' );
        ok( $token = $res->{token},  'Found token' );
        $key = Convert::Base32::decode_base32($key);

        # Post code
        my $code;
        ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
            'Code' );
        ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );

        my $s = "code=$code&token=$token";
        ok(
            $res = $p->_post(
                '/2fregisters/totp/verify',
                IO::String->new($s),
                length => length($s),
                cookie => "lemonldap=$id",
                custom => {
                    HTTP_X_CSRF_CHECK => 1,
                },
            ),
            'Post code'
        );
        eval { $res = JSON::from_json( $res->[2]->[0] ) };
        ok( not($@), 'Content is JSON' )
          or explain( $res->[2]->[0], 'JSON content' );
        ok( $res->{result} == 1, 'Key is registered' );
        ok( $res = $p->_get( '/', accept => 'text/html' ), 'Get Menu', );
        ( $host, $url, $query ) =
          expectForm( $res, '#', undef, 'user', 'password' );

        $query =~ s/user=/user=dwho/;
        $query =~ s/password=/password=dwho/;
        ok(
            $res = $p->_post(
                '/',
                IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Auth query'
        );
        ( $host, $url, $query ) = expectForm( $res, undef, '/totp2fcheck' );

        ok(
            $res = handler(
                req => [
                    GET => 'http://test2.example.com/',
                    [
                        'Authorization' => 'Basic '
                          . encode_base64( "$user:$user", '' )
                    ]
                ],
                sub => sub {
                    my ($res) = @_;
                    $subtest++;
                    subtest 'REST request to Portal' => sub {
                        plan tests => 2;
                        ok( $res->[0] eq 'POST', 'Get POST request' );
                        my ( $url, $query ) = split /\?/, $res->[1];
                        ok(
                            $res = $p->_post(
                                $url, IO::String->new( $res->[3] ),
                                length => length( $res->[3] ),
                                query  => $query,
                            ),
                            'Push request to portal'
                        );
                        return $res;
                    };
                    return $res;
                },
            ),
            'AuthBasic request'
        );
        ok( $res->[0] == 401, "Authentication rejected" );
    }
    ok( $subtest == 1, 'REST requests were done by handler' );

    $subtest = 0;
    foreach my $user (qw(dwho)) {
        ok(
            $res = handler(
                req => [
                    GET => 'http://test2.example.com/',
                    [
                        'Authorization' => 'Basic '
                          . encode_base64( "$user:$user", '' )
                    ]
                ],
                sub => sub {
                    my ($res) = @_;
                    $subtest++;
                    subtest 'REST request to Portal' => sub {
                        plan tests => 2;
                        ok( $res->[0] eq 'POST', 'Get POST request' );
                        my ( $url, $query ) = split /\?/, $res->[1];
                        ok(
                            $res = $p->_post(
                                $url, IO::String->new( $res->[3] ),
                                length => length( $res->[3] ),
                                query  => $query,
                            ),
                            'Push request to portal'
                        );
                        return $res;
                    };
                    return $res;
                },
            ),
            'New AuthBasic request'
        );
        ok( $subtest == 1,    'Handler used its local cache' );
        ok( $res->[0] == 401, 'Authentication rejected a second time' );
    }

    foreach my $user (qw(rtyler)) {
        ok(
            $res = handler(
                req => [
                    GET => 'http://test2.example.com/',
                    [
                        'Authorization' => 'Basic '
                          . encode_base64( "$user:$user", '' )
                    ]
                ],
                sub => sub {
                    my ($res) = @_;
                    $subtest++;
                    subtest 'REST request to Portal' => sub {
                        plan tests => 2;
                        ok( $res->[0] eq 'POST', 'Get POST request' );
                        my ( $url, $query ) = split /\?/, $res->[1];
                        ok(
                            $res = $p->_post(
                                $url, IO::String->new( $res->[3] ),
                                length => length( $res->[3] ),
                                query  => $query,
                            ),
                            'Push request to portal'
                        );
                        return $res;
                    };
                    return $res;
                },
            ),
            'New AuthBasic request'
        );
        ok( $subtest == 2, 'Portal was called a second time' );
        is( $res->[0], 200,
            '2FA did not trigger for rtyler because of ENV rule' );
    }

    end_handler();
    clean_sessions();
}
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'idp.com',
                portal            => 'http://auth.idp.com/',
                authentication    => 'Demo',
                userDB            => 'Same',
                restSessionServer => 1,
                totp2fActivation  =>
                  'has2f("TOTP") and ($uid eq "dwho" or not $ENV{AuthBasic})',
                totp2fSelfRegistration => 1,
                totp2fRange            => 2,
                totp2fAuthnLevel       => 5,
            }
        }
    );
}
