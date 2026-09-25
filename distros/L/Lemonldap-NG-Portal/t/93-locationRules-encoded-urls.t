use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            authentication    => 'Demo',
            userDB            => 'Same',
            restSessionServer => 1,
            locationRules     => {
                'auth.example.com' => {
                    '^/mysession' => 'deny',
                    default       => 'accept',
                },
            },
        }
    }
);

my $id = $client->login('dwho');

# The URL is percent-decoded and normalized by the web server before the
# request is routed to the application: with Nginx (FastCGI), REQUEST_URI
# contains for example /my%73ession while PATH_INFO (used to route the
# request inside the portal) is /mysession. Rules must be tested against the
# same value, else they can be bypassed with an encoded URL.
foreach my $uri (
    '/mysession',            # no encoding
    '/my%73ession',          # "s" encoded
    '/mysess%69on',          # "i" encoded
    '/%6Dysession',          # "m" encoded
    '/./mysession',          # dot segment
    '/foo/../mysession',     # dot segment
    '/foo//../mysession',    # duplicate slash
    '//mysession',           # duplicate slash
    '/%2Fmysession',         # encoded slash
  )
{
    ok(
        $res = $client->_get(
            '/mysession',
            cookie => "lemonldap=$id",
            accept => 'application/json',
            query  => 'whoami=1',
            custom => { REQUEST_URI => "$uri?whoami=1" },
        ),
        "Auth query to $uri"
    );
    count(1);
    expectForbidden($res);
}

# Negative control: this URL is decoded as /mysessCon, the rule must not be
# applied (the router answers 400 because such route doesn't exist, the
# important point is that it is not a 403 from the rule)
ok(
    $res = $client->_get(
        '/mysessCon',
        cookie => "lemonldap=$id",
        accept => 'application/json',
        custom => { REQUEST_URI => '/mysess%43on' },
    ),
    'Auth query to /mysess%43on'
);
count(1);
ok( $res->[0] != 403, ' Rule is not applied on /mysessCon' )
  or explain( $res->[0], 'not 403' );
count(1);

clean_sessions();
done_testing( count() );
