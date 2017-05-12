use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Mock::Furl;
use JSON 2 qw/encode_json/;
use Facebook::OpenGraph;

subtest 'w/o use_post_method setting' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            is $args{method}, 'GET', 'HTTP method';
            is $args{content}, '', 'content';
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    dummy => 'data',
                }),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new;
    $fb->get('go.hagiwara');

};

subtest 'use_post_method setting w/ GET' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            
            is_deeply(
                \%args,
                +{
                    method => 'POST',
                    url    => 'https://graph.facebook.com/me',
                    headers => [
                        Authorization => 'OAuth qwerty',
                    ],
                    content => +{
                        method => 'GET',
                    },
                },
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    dummy => 'data',
                }),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        access_token    => 'qwerty',
        use_post_method => 1,
    });
    $fb->get('/me');

};

subtest 'use_post_method setting w/ DELETE' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
        
            is_deeply(
                \%args,
                +{
                    method => 'POST',
                    url    => 'https://graph.facebook.com/123456',
                    headers => [
                        Authorization => 'OAuth qwerty',
                    ],
                    content => +{
                        method => 'DELETE',
                    },
                },
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{dummy => 'data'}),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        access_token    => 'qwerty',
        use_post_method => 1,
    });
    $fb->delete(123456);

};

done_testing;
