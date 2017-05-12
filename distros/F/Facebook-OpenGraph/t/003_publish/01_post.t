use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'create test user' => sub {

    my $datum_ref = +{
        id           => 123456789,
        access_token => '5678uiop',
        login_url    => 'https://www.facebook.com/platform/test_account_login?user_id=123456789&n=asdfghh',
        email        => 'saffasdffad@tfbnw.net',
        password     => 67890,
    };

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            is_deeply(
                delete $args{content},
                +{
                    permissions => 'read_stream',
                    installed   => 'true',
                },
                'content'
            );
            is_deeply(
                \%args,
                +{
                    headers => ['Authorization' => 'OAuth 12345qwerty'],
                    url     => 'https://graph.facebook.com/1234556/accounts/test-users',
                    method  => 'POST',
                },
                'args'
            );

            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json($datum_ref),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id => 1234556,
        secret => 'secret',
        access_token => '12345qwerty',
    });

    my $response = $fb->publish(
        $fb->app_id.'/accounts/test-users',
        +{
            installed   => 'true',
            permissions => 'read_stream',
        },
    );

    is_deeply $response, $datum_ref, 'datum';

};

done_testing;
