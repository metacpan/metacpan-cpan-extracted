use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing';
    }
    require Lemonldap::NG::Common::TOTP;

    sub registerTotp {
        my ( $client, $id ) = @_;
        ok(
            my $res = $client->_get(
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
            $res = $client->_post(
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
        ok( $key = $res->{secret}, 'Found secret' )
          or print STDERR Dumper($res);
        ok( $token = $res->{token}, 'Found token' )
          or print STDERR Dumper($res);
        ok( $res->{user} eq 'dwho', 'Found user' )
          or print STDERR Dumper($res);
        $key = Convert::Base32::decode_base32($key);

        # Post code
        ok(
            my $code =
              Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
            'Code'
        );
        ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
        my $s = "code=$code&token=$token&TOTPName=my-T OTP";
        ok(
            $res = $client->_post(
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
        ok( $res->{result} == 1, 'TOTP is registered' );
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
            }
        }
    );
    my $res;

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    my $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    expectRedirection( $res, qr#/2fregisters/totp$# );
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );

    registerTotp( $client, $id );

    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    like( $res->[2]->[0], qr,device='TOTP',, "Found newly registered device" );
    like( $res->[2]->[0],
        qr,href="/2fregisters/totp",, "Found button to register a new device" );

    registerTotp( $client, $id );

    my $pdata   = getPSession("dwho");
    my $devices = from_json( $pdata->{data}->{_2fDevices} );

    is( scalar( grep { $_->{type} eq "TOTP" } @$devices ),
        2, "Found 2 registered TOTP" );
}

clean_sessions();

done_testing();

