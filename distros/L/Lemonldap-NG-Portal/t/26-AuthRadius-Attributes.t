use warnings;
use Test::More;
use strict;
use IO::String;
use Authen::Radius;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                => 'error',
            authentication          => 'Radius',
            userDB                  => 'Demo',
            restSessionServer       => 1,
            radiusServer            => '127.0.0.1',
            radiusSecret            => 'test',
            radiusRequestAttributes => {
                'NAS-Identifier' => 'lemonldap',
                'X-IP-Addr'      => '$env->{REMOTE_ADDR}',
            },
            radiusExportedVars => {
                'myattr' => 'X-My-Attribute'
            },
            requireToken       => 1,
            portalDisplayOrder => 'Logout LoginHistory , Appslist'
        }
    }
);

no warnings 'redefine';
*Lemonldap::NG::Portal::Lib::Radius::_check_pwd_radius = sub {
    my ( $self, @attributes ) = @_;

    # Store attributes in a hash
    my %hattr;
    for my $a (@attributes) {
        $hattr{ $a->{Name} } = $a->{Value};
    }

    # Expect attributes
    is( $hattr{'NAS-Identifier'},
        'lemonldap', "Found NAS-Identifier attribute" );
    is( $hattr{'X-IP-Addr'}, '127.0.0.1', "Found X-Email-Address attribute" );

    # Succeed if login == password, return no attributes
    return {
        result     => ( $hattr{1} eq $hattr{2} ),
        attributes => { "X-My-Attribute" => "xxx" }
    };
};

# Test normal first access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'First request' );
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

# Try to authenticate with bad password
$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=jdoe/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html'
    ),
    'Auth query'
);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

# Try to authenticate
$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/', IO::String->new($query), length => length($query)
    ),
    'Auth query'
);
expectOK($res);
my $id = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Portal menu'
);
expectAuthenticatedAs( $res, 'dwho' );
expectSessionAttributes( $client, $id, "myattr" => "xxx" );

$client->logout($id);

clean_sessions();
done_testing();
