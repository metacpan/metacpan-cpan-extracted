use strict;
use warnings;

use Test::More import => ["!pass"];
use HTTP::API::Client;
use Dancer;
require Test::TCP;

if ( !$ENV{RUN_TCP_TEST} ) {
    ok 1;
    done_testing;
    exit;
}

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $api = HTTP::API::Client->new( content_type => "application/json" );
        my $resp = $api->post( "http://127.0.0.1:$port/json1" => { data => "OK1" } );
        is $api->json_response->{OK}, "OK1", "send hash -> json str";
        $api->post( "http://127.0.0.1:$port/json2" => q|{"data":"OK2"}| );
        is $api->json_response->{OK}, "OK2", "send json str",;
    },
    server => sub {
        my $port = shift;
        set(
            charset      => "utf8",
            port         => $port,
            show_errors  => 1,
            startup_info => 0,
            log          => "debug",
            logger       => "console"
        );
        my $param = sub {
            my $key = shift;
            my $req = request;
            my $ct  = $req->content_type;
            my $dd  = $req->body;
            if ( $ct =~ /json/ ) {
                return from_json($dd)->{$key};
            }
            elsif ( $ct =~ /xml/ ) {
                return from_xml($dd)->{$key};
            }
        };
        post "/json1" => sub {
            to_json { OK => $param->("data") };
        };
        post "/json2" => sub {
            to_json { OK => $param->("data") };
        };
        post "/xml1" => sub {
            to_xml { OK => $param->("data") };
        };
        post "/xml2" => sub {
            to_xml { OK => $param->("data") };
        };
        post "/value_pair1" => sub {
            require HTTP::Request::Common;
            HTTP::Request::Common::POST( q{},
                Content => { OK => param("data") } )->content;
        };
        post "/value_pair2" => sub {
            require HTTP::Request::Common;
            HTTP::Request::Common::POST( q{},
                Content => { OK => param("data") } )->content;
        };
        dance;
    }
);

done_testing;
