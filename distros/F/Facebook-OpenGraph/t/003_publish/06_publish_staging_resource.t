use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'publish_staging_resource' => sub {

    my $datum_ref = +{
        uri => 'fbstaging://graph.facebook.com/staging_resources/MDExMzc3MDU0MDg1ODQ3OTY2OjE5MDU4NTM1MzQ=',
    };

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            
            ok delete $args{content}, 'content'; # too huge to compare, so just check if it's given

            is_deeply(
                \%args,
                +{
                    headers => [
                        'Authorization'  => 'OAuth 12345qwerty',
                        'Content-Length' =>  69257,
                        'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                    ],
                    url => 'https://graph.facebook.com/me/staging_resources',
                    method => 'POST',
                },
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
        app_id       => 12345678,
        access_token => '12345qwerty',
    });
    my $response = $fb->publish_staging_resource('./t/resource/sample.png');
    is_deeply($response, $datum_ref);
};

done_testing;
