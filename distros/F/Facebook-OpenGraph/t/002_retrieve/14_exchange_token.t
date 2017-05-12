use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Mock::Furl;
use Facebook::OpenGraph;

subtest 'success' => sub {
    my $app_id            = 123456789;
    my $short_lived_token = '123456789XXXXXXXXXXX';
    my $long_lived_token  = 'longLivedToken12345',
    my $expires           = 5183814;

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
                    client_secret     => 'secret',
                    client_id         => $app_id,
                    grant_type        => 'fb_exchange_token',
                    fb_exchange_token => $short_lived_token,
                },
                'query',
            );
            is $args{method}, 'GET', 'HTTP GET method';
            is $args{content}, '', 'content';

            # returns long-lived access token
            return (
                1,
                200,
                'OK',
                [
                    'Content-Type'         => 'text/plain; charset=UTF-8',
                    'facebook-api-version' => 'v2.1',
                ],
                sprintf(
                    'access_token=%s&expires=%d',
                    $long_lived_token,
                    $expires
                ),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id => $app_id,
        secret => 'secret',
    });
    my $token_ref = $fb->exchange_token($short_lived_token);
    
    is_deeply(
        $token_ref,
        +{
            access_token => $long_lived_token,
            expires      => $expires,
        },
        'token',
    );
    is $fb->access_token, undef, 'no access_token is set';
    $fb->set_access_token($token_ref->{access_token});        
    is $fb->access_token, $long_lived_token, 'acess token is set';
};

subtest 'w/o secret key' => sub {
        
    my $fb = Facebook::OpenGraph->new(+{
        app_id => 123456789,
    });

    throws_ok(
        sub {
            my $token_ref = $fb->exchange_token('token');
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
            my $token = $fb->exchange_token('token');
        },
        qr/app_id and secret must be set /,
        'app_id is not set',
    );

};

done_testing;
