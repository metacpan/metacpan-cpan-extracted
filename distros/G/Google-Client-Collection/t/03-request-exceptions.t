use Test::Most;

# This test uses one of the client classes (::Files) to test
# the request method that talks to the user agent. It's pretty
# important to do that :)

use Test::Mock::Furl;
use Furl::Response;

use Google::Client::Collection;

use CHI;

my $chi = CHI->new(driver => 'Memory', global => 0);

$chi->set('test-req', 'foobar', 5);

ok my $client = Google::Client::Collection->new(
    cache => $chi,
    cache_key => 'test-req'
), 'created client ok';

{
    $Mock_furl->mock(
        request => sub {
            return Furl::Response->new(1, '403', 'Forbidden', {'content-type' => 'application/json'}, '{"error": "bad token"}');
        }
    );

    $Mock_furl_res->mock(decoded_content => sub { return '{"error": "bad token"}'; });
    $Mock_furl_res->mock(is_success => sub { return 0; });
    $Mock_furl_res->mock(as_string => sub { return "403 Forbidden"; });

    throws_ok { $client->files->_request(
      method => 'GET',
      url => 'http://www.googleapis.com/some/test/path'
    ) } qr|google api request failed|i, 'dies if response is not successful';
}

done_testing;
