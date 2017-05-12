use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'post movie' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            ok delete $args{content}, 'content'; # too huge to compare, so just check if it's given
            is_deeply(
                \%args,
                +{
                    url     => 'https://graph-video.facebook.com/me/videos',
                    method  => 'POST',
                    headers => [
                        'Authorization'  => 'OAuth 12345qwerty',
                        'Content-Length' => 289105,
                        'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                    ],
                },
                'args'
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    id => 111111111,
                }),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 12345678,
        access_token => '12345qwerty',
    });
    my $response = $fb->publish(
        '/me/videos',
        +{
            source      => './t/resource/IMG_6753.MOV',
            title       => 'domo-kun',
            description => 'found it @ walmart'
        }
    );

    is_deeply $response, +{ id => 111111111 }, 'response';

};

done_testing;
