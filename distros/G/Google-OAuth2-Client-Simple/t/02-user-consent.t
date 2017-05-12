use Test::Most;

use Test::Mock::Furl;
use Furl::Response;

use Google::OAuth2::Client::Simple;

$Mock_furl->mock(
    request => sub {
        return Furl::Response->new(1, 200, 'OK', {'content-type' => 'text/html'}, 'sign in with your google account');
    }
);

$Mock_furl_res->mock(
    decoded_content => sub { return 'sign in with your google account'; }
);

ok my $google = Google::OAuth2::Client::Simple->new(
    client_id => 'foo',
    client_secret => 'bar',
    redirect_uri => 'baz',
    scopes => ['https://www.googleapis.com/auth/drive.readonly'],
), 'created client successfully';

ok my $response = $google->request_user_consent(), 'directed user to googles user consent form';

is $response->code, 200, 'user consent code is 200';
like $response->decoded_content, qr|sign in with your google account|i, 'response content shows the google sign in form';

done_testing;
