use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'publish_action' => sub {

    my $datum_ref = +{
        id => 1234567890,
    };

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            is_deeply(
                \%args,
                +{
                    headers => [
                        'Authorization',
                        'OAuth AAAAAAAAAAA'
                    ],
                    url     => 'https://graph.facebook.com/me/foo-bar:give',
                    method  => 'POST',
                    content => +{
                        crap => 'http://samples.ogp.me/428404590566358',
                    },
                },
                'args',
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
        namespace    => 'foo-bar',
        access_token => 'AAAAAAAAAAA',
    });
    my $response = $fb->publish_action('give', +{crap => 'http://samples.ogp.me/428404590566358'});

    is_deeply $response, $datum_ref, 'response';

};

done_testing;
