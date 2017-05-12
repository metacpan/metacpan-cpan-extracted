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
    $Mock_furl->mock(
        request => sub {
            return Furl::Response->new(1, 200, 'OK', {'content-type' => 'application/json'}, '');
        }
    );

    $Mock_furl_res->mock(
        content_type => sub { return 'application/json'; }
    );

    $Mock_furl_res->mock(
        decoded_content => sub { return ''; }
    );

    ok $client->files->empty_trash(), 'can request to empty users trash';
}
done_testing;
