use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;
use URI::Escape;

require 't/test-psgi-lib.pm';

init(
    'Lemonldap::NG::Handler::PSGI',
    {
        vhostOptions => {
            'test1.example.com' => {
                vhostHttps => 1,
                vhostPort  => 443,
                vhostAuthnLevel => 1,
            },
            'test2.example.com' => {
                vhostHttps => 1,
                vhostPort  => 443,
            },
            'test3.example.com' => {
                vhostHttps => 1,
                vhostPort  => 443,
                vhostAuthnLevel => 3,
            },
        },
        locationRules   => {
            'test1.example.com' => {
                default => "accept"
            },
            'test2.example.com' => {
                default => "accept"
            },
            'test3.example.com' => {
                default => "accept"
            },
        },
        exportedHeaders => {},
        defaultAuthnLevel => 2,
        https           => undef,
        port            => undef,
        maintenance     => undef,
    }
);

my $res;

ok( $res = $client->_get('/','','test1.example.com', "lemonldap=$sessionId"), 'Access' );
is($res->[0], 200, "Request successful");

ok( $res = $client->_get('/','','test2.example.com', "lemonldap=$sessionId"), 'Access' );
is($res->[0], 200, "Request successful. Default AuthnLevel used");

ok( $res = $client->_get('/','','test3.example.com', "lemonldap=$sessionId"), 'Access' );
is($res->[0], 302, "Redirection");
my %h = @{ $res->[1] };
is(
    $h{Location},'http://auth.example.com//upgradesession?url='
      . uri_escape( encode_base64( 'https://test3.example.com/', '' ) ),
    'Redirection points to portal'
  );

count(7);
done_testing( count() );
clean();

sub Lemonldap::NG::Handler::PSGI::handler { # W: Module does not end with "1;"
    my ( $self, $req ) = @_;
    return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
}

