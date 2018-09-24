use strict;
use warnings;

use Test::More import => ["!pass"], tests => 1;
use HTTP::API::Client;

if ( !$ENV{RUN_TCP_TEST} ) {
    ok 1;
    done_testing;
    exit;
}

use Dancer;
use Test::TCP;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $api  = HTTP::API::Client->new;
        my $res  = $api->send( GET => "http://127.0.0.1:$port/OK" );
        is $res->content, "OK";
    },
    server => sub {
        my $port = shift;
        Dancer::set(
            charset      => "utf8",
            port         => $port,
            show_errors  => 1,
            startup_info => 0,
            log          => "debug",
            logger       => "console"
        );
        Dancer::get(
            "/:status" => sub {
                my $status = param("status");
                content_type("text/plain");
                return $status;
            }
        );
        Dancer::dance();
    }
);
