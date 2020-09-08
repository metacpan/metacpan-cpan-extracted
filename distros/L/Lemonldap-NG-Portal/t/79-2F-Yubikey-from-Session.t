use lib 'inc';
use Test::More;
use strict;
use IO::String;
use Plack::Request;
use JSON qw/from_json to_json/;

require 't/test-lib.pm';
require 't/test-yubikey.pm';

SKIP: {
    eval "use Auth::Yubikey_WebClient";
    if ($@) {
        skip 'Auth::Yubikey_WebClient not found', 0;
    }
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                      => 'error',
                yubikey2fActivation           => 1,
                yubikey2fClientID             => "myid",
                yubikey2fSecretKey            => "cG9uZXk=",
                yubikey2fFromSessionAttribute => "yubikey",
                yubikey2fSelfRegistration     => 1,
                authentication                => 'Demo',
                userDB                        => 'Same',
                'demoExportedVars'            => {
                    'cn'         => 'cn',
                    'mail'       => 'mail',
                    'uid'        => 'uid',
                    '_2fDevices' => '_2fDevices',
                    'yubikey'    => 'yubikey',
                },
            }
        }
    );

    # dwho has an userdb-provisionned yubikey and a registered one
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{dwho}->{yubikey} =
      "ccccccdddwho";
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{dwho}->{_2fDevices} =
      to_json( [ {
                "_yubikey" => "zzzzzzzzdwho",
                "epoch"    => "1548016213",
                "name"     => "MyYubikey",
                "type"     => "UBK",
            },
        ]
      );

    # rtyler only has a registered yubikey
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{rtyler}->{_2fDevices} =
      to_json( [ {
                "_yubikey" => "ccccccrtyler",
                "epoch"    => "1548016213",
                "name"     => "MyYubikey",
                "type"     => "UBK",
            },
        ]
      );

    my $res;

    # Try to authenticate
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'application/json',
        ),
        'Authenticate as dwho'
    );
    count(1);

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/yubikey2fcheck?skin=bootstrap',
        'token', 'code' );

# Authenticate with registered OTP should fail because dwho is externally provisionned
    $query =~ s/code=/code=zzzzzzzzdwho10000000000000000000/;

    ok(
        $res = $client->_post(
            '/yubikey2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    count(1);

    expectPortalError( $res, 96, "Bad OTP code" );

    # Try to authenticate again
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'application/json',
        ),
        'Auth query'
    );
    count(1);

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/yubikey2fcheck?skin=bootstrap',
        'token', 'code' );

    # Authenticate with good OTP
    $query =~ s/code=/code=ccccccdddwho10000000000000000000/;

    ok(
        $res = $client->_post(
            '/yubikey2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    count(1);
    my $id = expectCookie($res);

    # Authenticate as a user that only has a self registered OTP
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=rtyler&password=rtyler'),
            length => 27,
            accept => 'application/json',
        ),
        'Auth query'
    );
    count(1);

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/yubikey2fcheck?skin=bootstrap',
        'token', 'code' );

    # Authenticate with good OTP for rtyler
    $query =~ s/code=/code=ccccccrtyler10000000000000000000/;

    ok(
        $res = $client->_post(
            '/yubikey2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    count(1);
    $id = expectCookie($res);

    # This user has no UBK, the activation rule should not trigger
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=msmith&password=msmith'),
            length => 27,
            accept => 'application/json',
        ),
        'Auth query'
    );
    count(1);
    $id = expectCookie($res);

}

clean_sessions();

done_testing( count() );

