use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Mock::Furl;
use Facebook::OpenGraph;

subtest 'get' => sub {

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
                    grant_type    => 'client_credentials',
                    client_secret => 'secret',
                    client_id     => 123456789,
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
                    'facebook-api-version' => 'v2.0'
                ],
                'access_token=123456789|SSSeFWB-0EQ0qyipMdmNpJJJJjk',
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id => 123456789,
        secret => 'secret',
    });
    my $token = $fb->get_app_token->{access_token};
    is $token, '123456789|SSSeFWB-0EQ0qyipMdmNpJJJJjk', 'token';

};

subtest 'w/o secret key' => sub {

    my $fb = Facebook::OpenGraph->new(+{
        app_id => 123456789,
    });

    throws_ok(
        sub {
            my $token = $fb->get_app_token->{access_token};
        },
        qr/app_id and secret must be set /,
        'secret key is not set',
    );

};

subtest 'w/o app_id' => sub {

    my $fb = Facebook::OpenGraph->new(+{
        secret => 'secret',
    });

    throws_ok(
        sub {
            my $token = $fb->get_app_token->{access_token};
        },
        qr/app_id and secret must be set /,
        'app_id is not set',
    );

};

done_testing;
