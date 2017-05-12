use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'post like to a feed story' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            is_deeply(
                \%args,
                +{
                    headers => ['Authorization' => 'OAuth qwerty'],
                    url     => 'https://graph.facebook.com/1234_5678/likes',
                    method  => 'POST',
                    content => +{},
                },
                'args',
            );

            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                'true',
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        access_token => 'qwerty',
    });

    my $res = $fb->post('/1234_5678/likes');
    is_deeply $res, +{success => 'true'}, 'result';

};

done_testing;
