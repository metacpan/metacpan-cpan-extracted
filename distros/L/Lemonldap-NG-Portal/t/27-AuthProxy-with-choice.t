use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;

my $res;
require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                      => 'error',
            useSafeJail                   => 1,
            cookieName                    => 'external',
            authentication                => 'Proxy',
            userDB                        => 'Same',
            proxyAuthService              => 'http://auth.example.com',
            proxyAuthServiceChoiceParam   => 'lmAuth',
            proxyAuthServiceChoiceValue   => '2_Password',
            proxyCookieName               => 'lemonldap',
            proxyAuthServiceImpersonation => 1
        }
    }
);
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get menu' );
ok( $res->[2]->[0] =~ m#<input name="spoofId" type="text"#,
    'spoofId input found' )
  or explain( $res->[2]->[0], 'spoofId' );
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&spoofId=rtyler'),
        length => 38
    ),
    'Auth query'
);
expectOK($res);
my $id = expectCookie( $res, 'external' );
count(7);

$client->logout( $id, 'external' );
clean_sessions();

done_testing( count() );

# Redefine LWP methods for tests
no warnings 'redefine';

sub LWP::UserAgent::request {
    my ( $self, $req ) = @_;

    unless ( $req->uri->as_string =~
        m%http://auth.example.com(?:/session/my/global|\?logout=1)% )
    {
        ok( $req->content() =~ m%user=dwho%, 'User found' )
          or print STDERR Dumper( $req->content() );
        ok( $req->content() =~ m%password=dwho%, 'Password found' )
          or print STDERR Dumper( $req->content() );
        ok( $req->content() =~ m%lmAuth=2_Password%, 'ChoiceParam found' )
          or print STDERR Dumper( $req->content() );
        ok( $req->content() =~ m%spoofId=rtyler%, 'SpoofId found' )
          or print STDERR Dumper( $req->content() );
    }

    my $httpResp;
    my $s =
'{"error":"0","id":"6e30af4ffa5689b3e49a104d1b160d316db2b2161a0f45776994eed19dbdc101","result":1}';
    $httpResp = HTTP::Response->new( 200, 'OK' );
    $httpResp->header( 'Content-Type',   'application/json' );
    $httpResp->header( 'Content-Length', length($s) );
    $httpResp->header( 'Set-Cookie',
'lemonldap=6e30af4ffa5689b3e49a104d1b160d316db2b2161a0f45776994eed19dbdc101'
    );
    $httpResp->content($s);
    return $httpResp;
}
