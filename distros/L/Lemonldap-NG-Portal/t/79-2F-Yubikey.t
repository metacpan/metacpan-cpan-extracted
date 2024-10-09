use warnings;
use Test::More;
use strict;
use IO::String;
use Plack::Request;
use JSON qw/from_json to_json/;
use URI;
use URI::QueryParam;

require 't/test-lib.pm';
require 't/test-yubikey.pm';

no warnings 'once';

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
                    'cn'   => 'cn',
                    'mail' => 'mail',
                    'uid'  => 'uid',
                },
            }
        }
    );

    my $res;

    # Login
    my $id = $client->login("dwho");

    # Display Yubikey register page
    ok(
        $res = $client->_get(
            '/2fregisters/yubikey',
            accept => 'application/json',
            cookie => "lemonldap=$id",
        ),
        'Auth query'
    );
    count(1);

    expectXpath(
        $res,
        '//span[@trspan="clickOnYubikey"]',
        "Found prompt message"
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/2fregisters/yubikey/register',
        'UBKName', 'otp' );

    my $form = URI->new;
    $form->query($query);
    $form->query_param( "otp", "invalid" );

    ok(
        $res = $client->_post(
            '/2fregisters/yubikey/register',
            $form->query,
            accept => "text/html",
            cookie => "lemonldap=$id",
        ),
        'Invalid otp'
    );
    count(1);
    expectXpath( $res, '//span[@trspan="PE2"]', "Found error message" );

    $form->query_param( "otp",     "ccccccdddwho20000000000000000000" );
    $form->query_param( "UBKName", "aaaaaaaaaaaaaaaaaaaaaaaaé" );
    ok(
        $res = $client->_post(
            '/2fregisters/yubikey/register',
            $form->query,
            accept => "text/html",
            cookie => "lemonldap=$id",
        ),
        'Invalid UBKname'
    );
    count(1);
    expectXpath( $res, '//span[@trspan="badName"]', "Found error message" );

    $form->query_param( "UBKName", "MyUBK" );
    ok(
        $res = $client->_post(
            '/2fregisters/yubikey/register',
            $form->query,
            accept => "text/html",
            cookie => "lemonldap=$id",
        ),
        'Correct registration attempt'
    );
    count(1);
    expectRedirection( $res, "http://auth.example.com/2fregisters?continue=1" );

    my $psession = $client->p->getPersistentSession("dwho")->data;
    my $devices  = from_json( $psession->{_2fDevices} );
    is( $devices->[0]->{type},     "UBK",          "Found registered yubikey" );
    is( $devices->[0]->{_yubikey}, "ccccccdddwho", "Correct device ID" );
    ok( my $epoch = $devices->[0]->{epoch}, "Epoch is defined" );
    count(3);

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

    ( $host, $url, $query ) =
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
    $id = expectCookie($res);

    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => "test/html",
    );

    {
        my $delete_query = buildForm( { epoch => $epoch } );
        $res = $client->_post(
            "/2fregisters/yubikey/delete",
            $delete_query,
            length => length($delete_query),
            cookie => "lemonldap=$id",
        );
        my $json = expectBadRequest($res);
        ok( $res->[2]->[0] =~ 'csrfToken',
            "Deletion expects valid CSRF token" );
    	count(1);
    }

    {
        my $delete_query =
          buildForm( { epoch => $epoch, csrf_token => "1234566" } );
        $res = $client->_post(
            "/2fregisters/yubikey/delete",
            $delete_query,
            length => length($delete_query),
            cookie => "lemonldap=$id",
        );
        my $json = expectBadRequest($res);
        ok( $res->[2]->[0] =~ 'csrfToken',
            "Deletion expects valid CSRF token" );
    	count(1);
    }

    # Deletion
    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );
    my $delete_query = buildForm( { epoch => $epoch, csrf_token => getJsVars($res)->{csrf_token} } );
    ok(
        $res = $client->_post(
            "/2fregisters/yubikey/delete",
			$delete_query,
			length => length($delete_query),
            cookie => "lemonldap=$id",
        ),
        'Post deletion'
    );
    $res = expectJSON($res);
    is( $res->{result}, 1 );
    $psession = $client->p->getPersistentSession("dwho")->data;
    $devices  = from_json( $psession->{_2fDevices} );
    is( scalar @$devices, 0, "No device found anymore" );
    count(3);

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

