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
                logLevel                  => 'error',
                yubikey2fActivation       => 1,
                yubikey2fClientID         => "myid",
                yubikey2fSecretKey        => "cG9uZXk=",
                yubikey2fSelfRegistration => 1,
                authentication            => 'Demo',
                userDB                    => 'Same',
                'demoExportedVars'        => {
                    'cn'         => 'cn',
                    'mail'       => 'mail',
                    'uid'        => 'uid',
                    '_2fDevices' => '_2fDevices',
                },
            }
        }
    );

    # Register ccccccdddwho as second factor of user dwho
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{dwho}->{_2fDevices} =
      to_json( [ {
                "_yubikey" => "ccccccdddwho",
                "epoch"    => "1548016213",
                "name"     => "MyYubikey",
                "type"     => "UBK",
            },
        ]
      );

    my $res;

    # Try to authenticate
    # -------------------
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

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/yubikey2fcheck?skin=bootstrap',
        'token', 'code' );

    # Authenticate with good OTP for wrong user
    $query =~ s/code=/code=ccccccdddwho20000000000000000000/;

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

    # Authenticate with good OTP for wrong user
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
    expectPortalError( $res, 96, "Bad OTP code" );

    # Try to authenticate again, again
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

    # Authenticate with good OTP for good user
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

