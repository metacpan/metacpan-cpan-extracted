use strict;
use Test::More;
use Test::Mock::Guard;
use Test::Time;

use GitHub::Apps::Auth;
use Crypt::PK::RSA;
use JSON qw/encode_json/;
use Time::Moment;
use Furl::Response;

my $pk = Crypt::PK::RSA->new->generate_key->export_key_pem("private");

my $auth = GitHub::Apps::Auth->new(
    private_key => \$pk,
    app_id => 42,
    installation_id => 4242,
);

my $expected_base_token = 1234567890;
my $g = mock_guard "GitHub::Apps::Auth" => {
    _post_to_access_token => sub {
        my $body = encode_json({
            token => $expected_base_token++ . "",
            expires_at => Time::Moment->from_epoch(time())->plus_minutes(1)->strftime("%Y-%m-%dT%H:%M:%S%Z"),
        });

        return Furl::Response->new(1, 200, "OK", [], $body);
    },
};

my $token = $auth->issued_token;
is $token, "1234567890";
is $token, $auth->issued_token;
sleep 60;
is $token, $auth->issued_token;
sleep 1;
is "1234567891", $auth->issued_token;
sleep 1;
is "1234567891", $auth->issued_token;

done_testing;
