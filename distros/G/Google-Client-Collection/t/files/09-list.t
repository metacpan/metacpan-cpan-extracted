use Test::Most;
use Test::Mock::Furl;
use Furl::Response;
use CHI;
use Google::Client::Collection;

my $content = '
{
  "kind": "drive#fileList",
  "nextPageToken": "string",
  "files": [
    {"kind":"drive#file","name":"Example file resource 1","mimeType":"application/vnd.google-apps.spreadsheet","id":"1eXMjOsoBwfWwxa18bw4xh_ej2viYD3K2QDkE6Z3U0As"},
    {"kind":"drive#file","name":"Example file resource 2","mimeType":"application/vnd.google-apps.spreadsheet","id":"2eXMjOsoBwfWwxa18bw4xh_ej2viYD3K2QDkE6Z3U0Ba"}
  ]
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

    ok my $json = $client->files->list({}), 'can request to list all files for user';
    ok $json->{files}, 'can read json files';
}
done_testing;
