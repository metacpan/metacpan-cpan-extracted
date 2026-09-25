use Test::More;
use Lemonldap::NG::Handler::ApacheMP2::Request;

require 't/test-psgi-lib.pm';

init('Lemonldap::NG::Handler::PSGI');

my $res;

# Encoded URLs (#3723)
# --------------------
# mod_perl: rules are tested against $r->uri, decoded and normalized by httpd,
# while PATH_INFO is rebuilt from the raw unparsed URI, where dot segments
# survive. Values measured on Apache 2.4.68 + mod_perl 2.0.13 for GET /./deny.
my $req =
  Lemonldap::NG::Handler::ApacheMP2::Request->new( ApacheMP2FakeRequest->new );
is( $req->path,               '/./deny', 'PATH_INFO keeps dot segments' );
is( $req->access_control_uri, '/deny',   'Access control URI is $r->uri' );
count(2);

# Same environment through the handler
ok(
    $res = $client->app->(
        { %{ $req->env }, HTTP_COOKIE => "lemonldap=$sessionId" }
    ),
    'Query /./deny'
);
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res->[0], 403 );
count(2);

done_testing( count() );

clean();

sub Lemonldap::NG::Handler::PSGI::handler {
    return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
}

# Minimal fake Apache request for GET /./deny: httpd decodes and normalizes
# $r->uri, but $r->unparsed_uri keeps what the client sent
package ApacheMP2FakeRequest;

sub new             { return bless {}, shift }
sub uri             { return '/deny' }
sub args            { return '' }
sub hostname        { return 'test1.example.com' }
sub useragent_ip    { return '127.0.0.1' }
sub get_server_port { return 80 }
sub method          { return 'GET' }
sub subprocess_env  { return undef }
sub unparsed_uri    { return '/./deny' }
sub headers_in      { return bless {}, 'ApacheMP2FakeRequest::Headers' }

package ApacheMP2FakeRequest::Headers;

sub do { return 1 }
