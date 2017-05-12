use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Digest::SHA qw(hmac_sha256 hmac_sha256_hex);
use MIME::Base64::URLSafe qw(urlsafe_b64encode);
use Facebook::OpenGraph;

subtest 'success' => sub {
    my $secret  = 'secret';
    my $code    = 'XXXXXXXXXXXXXXXXXXXXXX';
    my $app_id  = 123456789;
    my $token   = '123456789XXXXXXXXXXX';
    my $expires = 5183814;

    my $stored_value = +{
        algorithm => "HMAC-SHA256",
        issued_at => 1398180151,
        code      => $code,
        user_id   => 44007581,
    };
    my $payload      = urlsafe_b64encode(encode_json($stored_value));
    my $sig          = urlsafe_b64encode(hmac_sha256($payload, $secret));
    my $cookie_value = sprintf('%s.%s', $sig, $payload);

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            
            is_deeply $args{headers}, [], 'no particular header';
            my $uri = $args{url};
            is $uri->scheme, 'https', 'scheme';
            is $uri->host, 'graph.facebook.com', 'host';
            is $uri->path, '/oauth/access_token', 'path';
            is_deeply(
                +{
                    $uri->query_form,
                },
                +{
                    client_secret => $secret,
                    client_id     => $app_id,
                    code          => $code,
                    redirect_uri  => '',
                },
                'query',
            );
            is $args{method}, 'GET', 'HTTP GET method';
            is $args{content}, '', 'content';

            return (
                1,
                200,
                'OK',
                [
                    'Content-Type'         => 'text/plain; charset=UTF-8',
                    'facebook-api-version' => 'v2.1',
                ],
                sprintf('access_token=%s&expires=%d', $token, $expires),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id => $app_id,
        secret => $secret,
    });
    my $token_ref = $fb->get_user_token_by_cookie($cookie_value);
    
    is_deeply(
        $token_ref,
        +{
            access_token => $token,
            expires      => $expires,
        },
        'token',
    );
    is $fb->access_token, undef, 'no access_token is set';
    $fb->set_access_token($token_ref->{access_token});        
    is $fb->access_token, $token, 'acess token is set';
};

subtest 'cookie value is undef or empty string' => sub {
    my $fb = Facebook::OpenGraph->new();

    throws_ok(
        sub { $fb->get_user_token_by_cookie(); },
        qr/cookie value is not given/,
    );
};

subtest 'cookie value does not contain code' => sub {
    my $secret = 'secret';

    my $stored_value = +{
        algorithm => "HMAC-SHA256",
        issued_at => 1398180151,
        user_id   => 44007581,
    };
    my $payload      = urlsafe_b64encode(encode_json($stored_value));
    my $sig          = urlsafe_b64encode(hmac_sha256($payload, $secret));
    my $cookie_value = sprintf('%s.%s', $sig, $payload);

    my $fb = Facebook::OpenGraph->new(+{
        secret => $secret,
    });
    throws_ok(
        sub { $fb->get_user_token_by_cookie($cookie_value) },
        qr/"code" is not contained in cookie value/,
    );
};

# https://developers.facebook.com/bugs/597779113651383/
subtest 'expires is not returned from FB' => sub {
    my $secret  = 'secret';
    my $code    = 'XXXXXXXXXXXXXXXXXXXXXX';
    my $app_id  = 123456789;
    my $token   = '123456789XXXXXXXXXXX';

    my $stored_value = +{
        algorithm => "HMAC-SHA256",
        issued_at => 1398180151,
        code      => $code,
        user_id   => 44007581,
    };
    my $payload      = urlsafe_b64encode(encode_json($stored_value));
    my $sig          = urlsafe_b64encode(hmac_sha256($payload, $secret));
    my $cookie_value = sprintf('%s.%s', $sig, $payload);

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            
            is_deeply $args{headers}, [], 'no particular header';
            my $uri = $args{url};
            is $uri->scheme, 'https', 'scheme';
            is $uri->host, 'graph.facebook.com', 'host';
            is $uri->path, '/oauth/access_token', 'path';
            is_deeply(
                +{
                    $uri->query_form,
                },
                +{
                    client_secret => $secret,
                    client_id     => $app_id,
                    code          => $code,
                    redirect_uri  => '',
                },
                'query',
            );
            is $args{method}, 'GET', 'HTTP GET method';
            is $args{content}, '', 'content';

            return (
                1,
                200,
                'OK',
                [
                    'Content-Type'         => 'text/plain; charset=UTF-8',
                    'facebook-api-version' => 'v2.1',
                ],
                sprintf('access_token=%s', $token),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id => $app_id,
        secret => $secret,
    });
    my $token_ref = $fb->get_user_token_by_cookie($cookie_value);
    is_deeply(
        $token_ref,
        +{
            access_token => $token,
        },
        'token w/ no expiration time',
    );
};

done_testing;
