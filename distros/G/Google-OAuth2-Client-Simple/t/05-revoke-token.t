use Test::Most;

use Test::Mock::Furl;
use Furl::Response;

use Google::OAuth2::Client::Simple;

$Mock_furl->mock(
    request => sub {
        return Furl::Response->new(1, 200, 'OK');
    }
);

ok my $google = Google::OAuth2::Client::Simple->new(
    client_id => 'foo',
    client_secret => 'bar',
    redirect_uri => 'baz',
    scopes => ['https://www.googleapis.com/auth/drive.readonly', 'https://www.googleapis.com/auth/adexchange.buyer'],
), 'created client successfully';

ok $google->revoke_token('access_token'), 'revoked token';

done_testing;
