use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            useSafeJail    => 1,
            authentication => 'Choice',
            userDB         => 'Same',

            authChoiceParam   => 'test',
            authChoiceModules => {
                '1_demo' => 'Demo;Demo;Null;;',
            },
            ext2fActivation     => 1,
            ext2fCodeActivation => 'A1b2C0',
            ext2FSendCommand    => '/bin/true',
        }
    }
);

subtest "Login, then cancel" => sub {
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
    ok( $res->[2]->[0] =~ /1_demo/, '1_demo displayed' );

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
                test     => "1_demo",
            },
        ),
        'Auth query'
    );
    expectOK($res);

    my $pdata = expectCookie( $res, "lemonldappdata" );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

    ok(
        $res = $client->_get(
            '/',
            query  => { cancel => 1 },
            accept => 'text/html',
            cookie => "lemonldappdata=$pdata",
        ),
        'Post code'
    );
    count(1);
    $pdata = expectCookie( $res, "lemonldappdata" );
    ok( !$pdata, "pdata was removed" );
    expectRedirection( $res, qr'^http://auth.example.com/$' );
};

subtest "Login, then logout" => sub {
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
    ok( $res->[2]->[0] =~ /1_demo/, '1_demo displayed' );

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
                test     => "1_demo",
            },
        ),
        'Auth query'
    );
    expectOK($res);
    my $pdata = expectCookie( $res, "lemonldappdata" );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

    ok(
        $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
        'Found EXTCODE input'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(1);

    $query =~ s/code=/code=A1b2C0/;
    ok(
        $res = $client->_post(
            '/ext2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldappdata=$pdata",
        ),
        'Post code'
    );
    count(1);
    my $id = expectCookie($res);

    $client->logout($id);
};

clean_sessions();
done_testing();
