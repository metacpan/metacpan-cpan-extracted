use strict;
use IO::String;
use Test::More;
use lib 'inc';
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use JSON qw(to_json from_json);

BEGIN {
    require 't/test-lib.pm';
}

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#^http://ws/(auth|user|confirm|modify)#,
            ' ' . ucfirst($1) . ' REST request' )
          or explain( $req->uri, 'http://ws/(auth|user)' );
        my $type = $1;
        count(1);
        my $res = from_json( $req->content );
        ok( $res->{user} eq 'dwho', ' User is dwho' );
        count(1);

        if ( $type eq 'auth' ) {
            ok( $res->{password} eq 'dwho', ' Password is dwho' )
              or explain( $res, 'password: dwho' );
            count(1);
            return [
                200,
                [ 'Content-Type' => 'application/json' ],
                ['{"result":true,"info":{"uid":"dwho"}}']
            ];
        }
        elsif ( $type eq 'modify' ) {
            ok( $res->{password} eq 'test', ' Password is test' );
            count(1);
            return [
                200, [ 'Content-Type' => 'application/json' ],
                ['{"result":true}']
            ];
        }
        elsif ( $type eq 'confirm' ) {
            ok( $res->{password} eq 'dwho', ' Password is dwho' );
            count(1);
            return [
                200, [ 'Content-Type' => 'application/json' ],
                ['{"result":true}']
            ];
        }
        elsif ( $type eq 'user' ) {
            return [
                200,
                [ 'Content-Type' => 'application/json' ],
                ['{"result":true,"info":{"cn":"dwho"}}']
            ];
        }
        else {
            fail('Unknwon URL');
            count(1);
        }
        return [ 500, [], [] ];
    }
);

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            useSafeJail       => 1,
            authentication    => 'REST',
            userDB            => 'Same',
            passwordDB        => 'REST',
            restAuthUrl       => 'http://ws/auth',
            restUserDBUrl     => 'http://ws/user',
            restPwdConfirmUrl => 'http://ws/confirm',
            restPwdModifyUrl  => 'http://ws/modify',
        }
    }
);

ok(
    $res = $client->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
expectRedirection( $res, 'http://auth.example.com/' );
my $id = expectCookie($res);
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=test&confirmpassword=test'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 54
    ),
    'Change password'
);
count(1);
expectOK($res);
$client->logout($id);

clean_sessions();

done_testing( count() );

