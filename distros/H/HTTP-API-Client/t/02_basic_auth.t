use strict;
use warnings;
use Test::More import => ["!pass"];    # last test to print
use HTTP::API::Client;
use Dancer;
use Test::TCP;
use Dancer::Plugin::Auth::Basic;

if ( !$ENV{RUN_TCP_TEST} ) {
    ok 1;
    done_testing;
    exit;
}

test_tcp(
    client => sub {
        my $port = shift;
        my $api  = HTTP::API::Client->new(
            username => "tester",
            password => "wrong password"
        );
        {
            my $res = $api->send( GET => "http://127.0.0.1:$port/OK" );
            ## Should be fail
            is $res->content, "Authorization required";
        }
        {
            $api->password("testing01");
            my $res = $api->send( GET => "http://127.0.0.1:$port/OK" );
            ## Should be OK
            is $res->content, "OK";
        }
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
        hook "before" => sub {
            my $self = shift;
            auth_basic
              realm => "Restricted zone",
              users => { tester => "testing01" };
        };
        get "/:status" => sub {
            my $status = param("status");
            content_type("text/plain");
            return $status;
        };
        dance;
    }
);

done_testing;
