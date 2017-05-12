use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'post photo' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            ok delete $args{content}, 'content'; # too huge to compare, so just check if it's given
            is_deeply(
                \%args,
                +{
                    method  => 'POST',
                    url     => 'https://graph.facebook.com/me/photos',
                    headers => [
                        'Authorization'  => 'OAuth 12345qwerty',
                        'Content-Length' =>  69332,
                        'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                    ],
                }
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    post_id => 100004886761157_100537230119169, # user_id + post id combo
                    id      => '100550186784540',
                }),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 12345678,
        access_token => '12345qwerty',
    });
    my $response = $fb->publish('/me/photos',+{ source => './t/resource/sample.png', message => 'upload photo'});
    is $response->{id}, '100550186784540', 'id';
    is $response->{post_id}, 100004886761157_100537230119169, 'post_id';

};


done_testing;
