use Test::Most;
use Test::Mock::Furl;
use Furl::Response;
use CHI;
use Google::Client::Collection;

my $chi = CHI->new(driver => 'Memory', global => 0);
$chi->set('file-client', 'test-access-token', 5);
ok my $client = Google::Client::Collection->new(
    cache => $chi,
), 'ok built client';
$client->set_cache_key('file-client');

{
    my $content = 'text,csv,stuff';
    $Mock_furl->mock(
        request => sub {
            return Furl::Response->new(1, 200, 'OK', {'content-type' => 'text/csv'}, $content);
        }
    );

    $Mock_furl_res->mock(
        content_type => sub { return 'text/csv'; }
    );

    $Mock_furl_res->mock(
        decoded_content => sub { return $content; }
    );

    ok my $data = $client->files->export(6, {mimeType => 'text/csv'}), 'can request to export files';
    is $data, $content, 'got back csv data';
}
done_testing;
