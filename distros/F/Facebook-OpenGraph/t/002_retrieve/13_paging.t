use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use Facebook::OpenGraph;
use JSON 2 qw(encode_json);

subtest 'paging' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is $args{method}, 'GET', 'HTTP method';
            my $uri = $args{url};
            is $uri->scheme, 'https', 'scheme';
            is $uri->host, 'graph.facebook.com', 'host';
            is $uri->path, '/me/albums', 'path';
            is_deeply +{$uri->query_form}, +{
                limit => 25,
                after => 'MTAxNTExOTQ1MjAwNzI5NDE=',
            }, 'query parameters';
            
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{dummy => 'BOO!'}),
            );
        },
    );

    my $prev_response = +{
        data   => [], # dummy
        paging => +{
            previous => "https://graph.facebook.com/me/albums?limit=25&before=NDMyNzQyODI3OTQw",
            next     => "https://graph.facebook.com/me/albums?limit=25&after=MTAxNTExOTQ1MjAwNzI5NDE=",
            cursors  => +{
                after  => "MTAxNTExOTQ1MjAwNzI5NDE=",
                before => "NDMyNzQyODI3OTQw",
            },
        },
    };
    
    my $fb = Facebook::OpenGraph->new;
    $fb->fetch($prev_response->{paging}->{next});

};



done_testing;
