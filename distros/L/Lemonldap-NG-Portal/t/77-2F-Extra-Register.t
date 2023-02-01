use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

our $receivedCode;
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        if ( $req->path_info eq '/init' ) {
            my $json = from_json( $req->content );
            is( $json->{user}, "dwho", ' Init req gives dwho' );
            is( $json->{uid},  "dwho", ' Found uid attribute' );
            is( $json->{destination}, "dwho-destination",
                ' Found destination attribute' );
            my $code = $json->{code};
            ok( $code, "Received code from LLNG" );
            $receivedCode = $code;
        }
        elsif ( $req->path_info eq '/vrfy' ) {
            die "Not supposed to happen";
        }
        else {
            fail( ' Bad REST call ' . $req->path_info );
        }
        return [
            200,
            [ 'Content-Type' => 'application/json', 'Content-Length' => 12 ],
            ['{"result":1}']
        ];
    }
);

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel              => 'error',
            localSessionStorage   => "Cache::NullCache",
            tokenUseGlobalStorage => 1,
            authentication        => 'Demo',
            userDB                => 'Same',
            restSessionServer     => 1,
            'sfExtra'             => {
                'work' => {
                    'over' => {
                        rest2fCodeActivation => '\d{6}',
                        rest2fInitUrl        => 'http://auth.example.com/init',
                        rest2fInitArgs       =>
                          { uid => 'uid', "destination", "destination" },
                    },
                    'logo'     => 'work.jpg',
                    'label'    => "Work Label",
                    'type'     => 'REST',
                    'register' => 1,
                    'level'    => 5,
                },
                'work2' => {
                    'over' => {
                        mail2fCodeRegex => '\w{4}',
                    },
                    'logo'     => 'work.jpg',
                    'label'    => "Work Label",
                    'type'     => 'Mail2F',
                    'register' => 1,
                    'level'    => 5,
                },
                'home' => {
                    'over' => {
                        mail2fCodeRegex => '\w{4}',
                    },
                    'logo'     => 'home.jpg',
                    'label'    => "Home Label",
                    'rule'     => '$uid eq "dwho"',
                    'type'     => 'Mail2F',
                    'register' => 1,
                    'level'    => 5,
                },
            },
        }
    }
);

subtest "Register and use mail based custom SF as dwho" => sub {

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );
    ok( getHtmlElement( $res, '//a[@href="/2fregisters/home"]' ),
        "Found link to home register" );
    ok( getHtmlElement( $res, '//img[@src="/static/bootstrap/home.jpg"]' ),
        "Found image for home" );
    ok( getHtmlElement( $res, '//a[@href="/2fregisters/work"]' ),
        "Found link to work register" );
    ok( getHtmlElement( $res, '//img[@src="/static/bootstrap/work.jpg"]' ),
        "Found image for work" );

    $res = $client->_get(
        '/2fregisters/home',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );

    # Ajax send mail
    my $query = buildForm( { generic => 'test@test.com' } );
    $res = $client->_post(
        '/2fregisters/home/sendcode',
        IO::String->new($query),
        length => length $query,
        cookie => "lemonldap=$id",
        accept => 'application/json',
    );

    $res = expectJSON($res);
    is( $res->{result}, 1 );
    ok( $res->{token} );
    my $token = $res->{token};

    like( mail(), qr%Doctor Who%,     'Found session attribute in mail' );
    like( mail(), qr%<b>(\w{4})</b>%, 'Found 2F code in mail' );

    mail() =~ qr%<b>(\w{4})</b>%;
    is( envelope()->{to}->[0], 'test@test.com',
        'Sent to self registered mail' );

    my $code = $1;

    $query = buildForm(
        { generic => 'test@test.com', genericcode => $code, token => $token } );
    $res = $client->_post(
        '/2fregisters/home/verify',
        IO::String->new($query),
        length => length $query,
        cookie => "lemonldap=$id",
        accept => 'application/json',
    );

    $res = expectJSON($res);
    is( $res->{result}, 1 );

    # Login with dwho, with 2FA
    # -----------------
    clear_mail();
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/home2fcheck?skin=bootstrap', 'token', 'code' );

    like( mail(), qr%Doctor Who%,     'Found session attribute in mail' );
    like( mail(), qr%<b>(\w{4})</b>%, 'Found 2F code in mail' );

    mail() =~ qr%<b>(\w{4})</b>%;
    $code = $1;

    is( envelope()->{to}->[0], 'test@test.com',
        'Sent to self registered mail' );

    $query =~ s/code=/code=${code}/;
    ok(
        $res = $client->_post(
            '/home2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );

    my $id = expectCookie($res);
    expectSessionAttributes(
        $client, $id,
        _2f                 => "home",
        authenticationLevel => 5
    );
};

subtest "Fail to register mail based custom SF as dwho" => sub {
    getPSession('dwho')->remove;

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    $res = $client->_get(
        '/2fregisters/home',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );

    # Ajax send mail
    my $query = buildForm( { generic => 'test@test.com' } );
    $res = $client->_post(
        '/2fregisters/home/sendcode',
        IO::String->new($query),
        length => length $query,
        cookie => "lemonldap=$id",
        accept => 'application/json',
    );

    $res = expectJSON($res);
    is( $res->{result}, 1 );
    ok( $res->{token} );
    my $token = $res->{token};

    like( mail(), qr%Doctor Who%,     'Found session attribute in mail' );
    like( mail(), qr%<b>(\w{4})</b>%, 'Found 2F code in mail' );

    mail() =~ qr%<b>(\w{4})</b>%;
    is( envelope()->{to}->[0], 'test@test.com',
        'Sent to self registered mail' );

    my $code = $1;
    $code = $code + 1;

    $query = buildForm(
        { generic => 'test@test.com', genericcode => $code, token => $token } );
    $res = $client->_post(
        '/2fregisters/home/verify',
        IO::String->new($query),
        length => length $query,
        cookie => "lemonldap=$id",
        accept => 'application/json',
    );
    expectReject( $res, 400, 'PE96' );
    ok( !getPSession('dwho')->data->{_2fDevices},
        "No 2fDevice was registered" );
};

subtest "Register and use rest based custom SF as dwho" => sub {
    getPSession('dwho')->remove;

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    $res = $client->_get(
        '/2fregisters/work',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );

    # Ajax send mail
    my $query = buildForm( { generic => 'dwho-destination' } );
    $res = $client->_post(
        '/2fregisters/work/sendcode',
        IO::String->new($query),
        length => length $query,
        cookie => "lemonldap=$id",
        accept => 'application/json',
    );

    $res = expectJSON($res);
    is( $res->{result}, 1 );
    ok( $res->{token} );
    my $token = $res->{token};

    my $code = $receivedCode;

    $query = buildForm( {
            generic     => 'dwho-destination',
            genericcode => $code,
            token       => $token
        }
    );
    $res = $client->_post(
        '/2fregisters/work/verify',
        IO::String->new($query),
        length => length $query,
        cookie => "lemonldap=$id",
        accept => 'application/json',
    );

    $res = expectJSON($res);
    is( $res->{result}, 1 );

    # Login with dwho, with 2FA
    # -----------------
    clear_mail();
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/work2fcheck?skin=bootstrap', 'token', 'code' );

    $code = $receivedCode;

    $query =~ s/code=/code=${code}/;
    ok(
        $res = $client->_post(
            '/work2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );

    my $id = expectCookie($res);
    expectSessionAttributes(
        $client, $id,
        _2f                 => "work",
        authenticationLevel => 5
    );

    # Display registered 2FA
    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );
    my $unregister = getHtmlElement( $res,
            '//span[@prefix="work" and @device="work"]'
          . '/span[@trspan="unregister"]/..' )->get_node(1);

    ok( $unregister, "Found unregister button" );

    my $epoch  = $unregister->getAttribute("epoch");
    my $prefix = $unregister->getAttribute("prefix");
    ok( $epoch,  "Found epoch on delete button" );
    ok( $prefix, "Found prefix on delete button" );

    $query = buildForm( { epoch => $epoch, } );
    ok(
        $res = $client->_post(
            "/2fregisters/$prefix/delete",
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
        ),
        'Post deletion'
    );
    $res = expectJSON($res);
    is( $res->{result}, 1 );

    my $_2fDevices = from_json( getPSession('dwho')->data->{'_2fDevices'} );
    ok( !@$_2fDevices, "Device was unregistered" );
};

subtest "Login and display available registrations for rtyler" => sub {

    my $query = "user=rtyler&password=rtyler";
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );
    ok(
        !getHtmlElement( $res, '//a[@href="/2fregisters/home"]' ),
        "Home is not offered because rule doesn't match"
    );
    ok( getHtmlElement( $res, '//a[@href="/2fregisters/work"]' ),
        "Found link to work register" );
    ok( getHtmlElement( $res, '//img[@src="/static/bootstrap/work.jpg"]' ),
        "Found image for work" );
};

clean_sessions();

done_testing();

