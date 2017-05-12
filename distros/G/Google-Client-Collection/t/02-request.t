use Test::Most;

# This test uses one of the client classes (::Files) to test
# the request method that talks to the user agent. It's pretty
# important to do that :)

use Test::Mock::Furl;
use Furl::Response;

use CHI;

use Google::Client::Collection;

my $chi = CHI->new(driver => 'Memory', global => 0);

$Mock_furl->mock(
    request => sub {
        return Furl::Response->new(1, 200, 'OK', {'content-type' => 'application/json'}, '{}');
    }
);

$Mock_furl_res->mock(
    content_type => sub { return 'application/json'; }
);

$Mock_furl_res->mock(
    decoded_content => sub { return '{}'; }
);

ok my $client = Google::Client::Collection->new(
    cache => $chi,
    cache_key => 'test-key'
), 'created client ok';

throws_ok { $client->files->_request(
  method => 'GET',
  url => 'http://www.googleapis.com/some/test/path'
) } qr|access token not found or may have expired|, 'dies when no access token';

$chi->set('test-key', 'test_access_token', 5);

lives_ok { $client->files->_request(
    method => 'GET',
    url => 'http://www.googleapis.com/some/test/path',
) } 'lives when given access token and response is good';

done_testing;
