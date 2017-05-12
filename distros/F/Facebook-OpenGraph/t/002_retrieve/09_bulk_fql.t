use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(decode_json encode_json);
use Facebook::OpenGraph;

subtest 'multi query w/out dependencies' => sub {

    my $val = [
        +{
            fql_result_set => [
                +{
                    uid2 => '100004652133279',
                },
                +{
                    uid2 => '100004657083353'
                },
                +{
                    uid2 => '100004682741165'
                },
                +{
                    uid2 => '100004691462769'
                },
                +{
                    uid2 => '100004737602210'
                },
            ],
            name => 'all friends',
        },
        +{
            fql_result_set => [
                +{
                    name => 'Linda Amdgjheicghf Laustein',
                },
            ],
            name => 'my name',
        },
    ];

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is_deeply $args{headers}, [], 'no particular header';
            is $args{content}, '', 'content';
            is $args{method}, 'GET', 'HTTP GET method';
    
            my $uri = $args{url};
            is $uri->scheme, 'https', 'scheme';
            is $uri->path, '/fql', 'path';
            my $query_form = +{$uri->query_form};
            is_deeply(
                decode_json($query_form->{q}), 
                +{
                    'my name'     => 'SELECT name FROM user WHERE uid=me()',
                    'all friends' => 'SELECT uid2 FROM friend WHERE uid1=me()',
                },
                'query parameter',
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    data => $val,
                }),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new;
    my $data_ref = $fb->bulk_fql(+{
        "all friends" => "SELECT uid2 FROM friend WHERE uid1=me()",
        "my name"     => "SELECT name FROM user WHERE uid=me()",
    })->{data};

    is_deeply $data_ref, $val, 'content';

};

done_testing;
