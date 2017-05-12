#!perl
#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Jedi;
use JSON;
use FindBin qw/$Bin/;
use Jedi::Request;

my $jedi = Jedi->new();
$jedi->road( '/', 't::lib::request' );

test_psgi $jedi->start, sub {
    my ($cb) = @_;
    {
        my $res = $cb->( GET '/' );
        is $res->code,    200,  'status is correct';
        is $res->content, '{}', 'status is empty, no params';
    }

    {
        my $res = $cb->( GET '/?a=1&a=2&b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => 1 },
            '... and params is correct';
    }

    {
        my $res = $cb->( POST '/?a=1&a=2&b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), {},
            '... and params is empty (not a post)';
    }

    {
        my $res = $cb->( POST '/', [ a => 1, a => 2, b => 1 ] );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => 1 },
            '... and params is correct';
    }

    {
        my $res = $cb->( PUT '/?a=1&a=2&b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), {},
            '... and params is empty (not a post)';
    }

    {
        my $req = POST '/', [ a => 1, a => 2, b => 1 ];
        $req->method('PUT');

        my $res = $cb->($req);
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => 1 },
            '... and params is correct';
    }

    {
        # do a POST request, with GET (post file into the content)
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ];
        $req->method('GET');

        my $res = $cb->($req);
        is $res->code, 200, 'status is correct';
        is $res->content, '';
    }

    {
        # post the file, and get it back through content
        my $res = $cb->(
            POST '/file',
            Content_Type => 'form-data',
            Content =>
                [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ]
        );
        is $res->code,    200,             'status is correct';
        is $res->content, 'Hello World !', '... and tiny content is correct';
    }

    {
        # post the file, and get it back through content
        my $res = $cb->(
            POST '/file',
            Content_Type => 'form-data',
            Content =>
                [ myTestFile => [ $Bin . "/../data/hello_world_big.txt" ], ]
        );
        is $res->code, 200, 'status is correct';
        is $res->content,
            join( "\n", map {"Hello World !"} ( 1 .. 650 ) ) . "\n",
            '... and big content is correct';
    }

    {
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ];
        $req->method('PUT');

        # post the file, and get it back through content
        my $res = $cb->( $req );
        is $res->code,    200,             'status is correct';
        is $res->content, 'Hello World !', '... and tiny content is correct';
    }

    {
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world_big.txt" ], ];
        $req->method('PUT');

        # post the file, and get it back through content
        my $res = $cb->($req);
        is $res->code, 200, 'status is correct';
        is $res->content,
            join( "\n", map {"Hello World !"} ( 1 .. 650 ) ) . "\n",
            '... and big content is correct';
    }

    {
        # simulate empty file
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ];
        $req->content_length(0);
        my $res = $cb->($req);
        is $res->code,    200, 'status is correct';
        is $res->content, '',  '... and tiny content is correct';
    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie' );
        is $res->code,    200,  'status is correct';
        is $res->content, '{}', '... and content is correct';

    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie', 'Cookie' => 'a=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [1] },
            '... and content is correct';

    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie', 'Cookie' => 'a=1&2; b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => [1] },
            '... and content is correct';

    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie', 'Cookie' => ' ' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), {},
            '... and content is correct';

    }

};

{
    # test scheme/port/env
    test_psgi $jedi->start, sub {
        my ($cb) = @_;
        {
            my $req = GET 'http://sck.to/scheme';
            my $res = $cb->($req);
            is $res->code,           200,    'status is correct';
            is_deeply $res->content, 'http', '... and content is correct';
        }
        {
            my $req = GET 'http://sck.to/port';
            my $res = $cb->($req);
            is $res->code,           200,  'status is correct';
            is_deeply $res->content, '80', '... and content is correct';
        }
        {
            my $req = GET 'http://sck.to/host';
            my $res = $cb->($req);
            is $res->code,           200,      'status is correct';
            is_deeply $res->content, 'sck.to', '... and content is correct';
        }
        }
}

{
    # test IP
    test_psgi $jedi->start, sub {
        my ($cb) = @_;
        {
            my $req = HTTP::Request->new( 'GET', '/ip',
                HTTP::Headers->new( 'CLIENT_IP' => '11.2.3.4' ) );
            my $expected = Net::IP::XS->new("11.2.3.4");
            my $res      = $cb->($req);
            is $res->code, 200, 'status ok';
            is_deeply decode_json( $res->content ),
                [ $expected->intip()->bstr(), $expected->ip() ], 'ip ok';
        }
        {
            my $req = HTTP::Request->new(
                'GET', '/ip',
                HTTP::Headers->new(
                    'X_FORWARDED_FOR' => '10.0.0.1, 127.0.0.1, 11.2.3.4'
                )
            );
            my $expected = Net::IP::XS->new("11.2.3.4");
            my $res      = $cb->($req);
            is $res->code, 200, 'status ok';
            is_deeply decode_json( $res->content ),
                [ $expected->intip()->bstr(), $expected->ip() ], 'ip ok';
        }
        {
            my $req      = HTTP::Request->new( 'GET', '/ip', );
            my $expected = Net::IP::XS->new("127.0.0.1");
            my $res      = $cb->($req);
            is $res->code, 200, 'status ok';
            is_deeply decode_json( $res->content ),
                [ $expected->intip()->bstr(), $expected->ip() ], 'ip ok';
        }
        {
            my $req = HTTP::Request->new( 'GET', '/ip',
                HTTP::Headers->new( 'X_FORWARDED_FOR' => '2.3.4.5' ) );
            my $expected = Net::IP::XS->new("2.3.4.5");
            my $res      = $cb->($req);
            is $res->code, 200, 'status ok';
            is_deeply decode_json( $res->content ),
                [ $expected->intip()->bstr(), $expected->ip() ], 'ip ok';
        }
        {
            my $req = HTTP::Request->new(
                'GET', '/ip',
                HTTP::Headers->new(
                    'X_FORWARDED_FOR' => '::1,fe00::0,2001:41d0:8:bd54::1'
                )
            );
            my $expected = Net::IP::XS->new("2001:41d0:8:bd54::1");
            my $res      = $cb->($req);
            is $res->code, 200, 'status ok';
            is_deeply decode_json( $res->content ),
                [ $expected->intip()->bstr(), $expected->ip() ], 'ip ok';
        }
        }
}

{
    # Test URL
    my @tests = (
        [   {   'PSGI.URL_SCHEME' => 'http',
                'HTTP_HOST'       => 'test.com',
                'PATH_INFO'       => '/test/ok',
            },
            'test.com',
            80,
            'http://test.com',
            'http://test.com/test/ok'
        ],
        [   {   'PSGI.URL_SCHEME' => 'http',
                'HTTP_HOST'       => 'test.com:123',
                'PATH_INFO'       => '/test/ok',
            },
            'test.com',
            123,
            'http://test.com:123',
            'http://test.com:123/test/ok'
        ],
        [   {   'PSGI.URL_SCHEME' => 'https',
                'HTTP_HOST'       => 'test.com',
                'PATH_INFO'       => '/test/ok',
            },
            'test.com',
            443,
            'https://test.com',
            'https://test.com/test/ok'
        ],
        [   {   'PSGI.URL_SCHEME' => 'https',
                'HTTP_HOST'       => 'test.com:123',
                'PATH_INFO'       => '/test/ok',
            },
            'test.com',
            123,
            'https://test.com:123',
            'https://test.com:123/test/ok'
        ],
        [   {   'PSGI.URL_SCHEME' => 'ftp',
                'HTTP_HOST'       => 'test.com',
                'PATH_INFO'       => '/test/ok',
            },
            'test.com',
            '',
            'ftp://test.com',
            'ftp://test.com/test/ok'
        ],
    );
    for my $test (@tests) {
        my ( $env, $host, $port, $base_url, $url ) = @$test;
        my $req = Jedi::Request->new( env => $env, path => '/' );
        is $req->host,     $host,     'Host: ' . $host . ' ok ';
        is $req->port,     $port,     'Port: ' . $port . ' ok ';
        is $req->base_url, $base_url, 'Base: ' . $base_url . ' ok';
        is $req->url,      $url,      'Url: ' . $url . ' ok';
    }
}

done_testing;
