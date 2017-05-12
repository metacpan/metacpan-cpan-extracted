use Test::Most;

use Test::Mock::Furl;
use Furl::Response;

use Cpanel::JSON::XS;

use Google::OAuth2::Client::Simple;

my $content = {
    access_token => "ya29.kwJllB_kVrUpGDUwNoqXo0-G3p3IJE8dcBPXkYC52RlwyHuhKocNLCGk3OonSU7RuQ",
    token_type => "Bearer",
    expires_in => 3600,
    refresh_token => "1/4ls2RYVNBvmAmzv6dgNEYhnhB7MIyX4xIqxMTJeYxQc"
};

$Mock_furl->mock(
    request => sub {
        return Furl::Response->new(1, 200, 'OK', {'content-type' => 'application/json'}, encode_json($content));
    }
);

$Mock_furl_res->mock(
    decoded_content => sub { return encode_json($content); }
);

ok my $google = Google::OAuth2::Client::Simple->new(
    client_id => 'foo',
    client_secret => 'bar',
    redirect_uri => 'baz',
    scopes => ['https://www.googleapis.com/auth/drive.readonly'],
), 'created client successfully';

ok my $token_ref = $google->exchange_code_for_token('blabla_is_mocked'), 'received hash of json data returned from Google';

ok $token_ref->{access_token}, 'ref contains access token';
ok $token_ref->{expires_in}, 'ref contains expiry time';
ok $token_ref->{refresh_token}, 'ref contains a refresh token';

done_testing;
