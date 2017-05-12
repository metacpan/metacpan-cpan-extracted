use Test::Most;
use Test::Mock::Furl;
use Furl::Response;
use CHI;
use Google::Client::Collection;

my $content = '
{
  "kind": "api#channel",
  "id": "string",
  "resourceId": "string",
  "resourceUri": "string",
  "token": "string",
  "expiration": "long",
  "type": "string",
  "address": "string",
  "payload": 1,
  "params": {
    "key": "string"
  }
}
';

my $chi = CHI->new(driver => 'Memory', global => 0);
$chi->set('file-client', 'test-access-token', 5);
ok my $client = Google::Client::Collection->new(
    cache => $chi,
), 'ok built client';
$client->set_cache_key('file-client');

{
    $Mock_furl->mock(
        request => sub {
            return Furl::Response->new(1, 200, 'OK', {'content-type' => 'application/json'}, $content);
        }
    );

    $Mock_furl_res->mock(
        content_type => sub { return 'application/json'; }
    );

    $Mock_furl_res->mock(
        decoded_content => sub { return $content; }
    );

    ok my $json = $client->files->watch('1eXMjOsoBwfWwxa18bw4xh_ej2viYD3K2QDkE6Z3U0As', {}, { example => 'params' }), 'can request to watch a file';
    ok $json->{resourceId}, "can read as json";
}
done_testing;
