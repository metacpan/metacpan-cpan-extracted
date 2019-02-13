use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Plack::Request;

require 't/test-lib.pm';
my $maintests = 6;

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        if ( $req->path_info eq '/init' ) {
            ok( $req->content eq '{"name":"dwho"}', ' Init req gives dwho' )
              or explain( $req->content, '{"name":"dwho"}' );
        }
        elsif ( $req->path_info eq '/vrfy' ) {
            ok( $req->content eq '{"code":"1234"}', ' Code is 1234' )
              or explain( $req->content, '{"code":"1234"}' );
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

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            rest2fActivation    => 1,
            rest2fInitUrl       => 'http://auth.example.com/init',
            rest2fInitArgs      => { name => 'uid' },
            rest2fVerifyUrl     => 'http://auth.example.com/vrfy',
            rest2fVerifyArgs    => { code => 'code' },
            loginHistoryEnabled => 1,
            authentication      => 'Demo',
            userDB              => 'Same',
            portalMainLogo      => 'common/logos/logo_llng_old.png',
        }
    }
);
my $res;

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&checkLogins=1'),
        length => 37,
        accept => 'text/html',
    ),
    'Auth query'
);
ok( $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
    'Found custom Main Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/rest2fcheck', 'token', 'code', 'checkLogins' );
$query =~ s/code=/code=1234/;

ok(
    $res = $client->_post(
        '/rest2fcheck',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post code'
);
my $id = expectCookie($res);

ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or print STDERR Dumper( $res->[2]->[0] );
my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
ok( @c == 1, 'One entry found' );

$client->logout($id);

#print STDERR Dumper($res);

count($maintests);

clean_sessions();

done_testing( count() );

