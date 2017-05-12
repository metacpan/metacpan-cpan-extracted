#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;


BEGIN {
    use_ok('HTTP::Soup');
}

my $CONTENT = "It works\n";
my $X_TEST  = "random data";

sub main {
    test_server();
    return 0;
}


sub test_server {
    my $server = HTTP::Soup::Server->new(
#        port => 9999,
    );
    isa_ok($server, 'HTTP::Soup::Server');

    my $port = $server->get_port();
    diag("Server at port: $port");

    # Safe guard to make sure that the test doesn't run forever
    Glib::Timeout->add(5_000, sub {
        diag("Test is running for too long, timeout");
        $server->quit();
    }) if 1;


    # Custom client used to fetch a response from our own server
    my $session = HTTP::Soup::SessionAsync->new();
    isa_ok($session, 'HTTP::Soup::Session');
    isa_ok($session, 'HTTP::Soup::SessionAsync');


    Glib::Timeout->add(500, sub {
        my $message = HTTP::Soup::Message->new(GET => "http://localhost:$port/a");
        $session->queue_message($message, sub {
            my ($session, $message) = @_;

            is($message->status_code, 203, "status_code");
            is($message->reason_phrase, "Non-Authoritative Information", "reason_phrase");

            my $body = $message->response_body;
            is($body->data, $CONTENT, "body->data");
            is($body->length, length $CONTENT, "body->length");

            my $headers = $message->response_headers;
            is($headers->get('X-Test'), $X_TEST, 'got test header');

            # We can finish with the server we got all the data that we wanted
            $server->quit();
        });
    });

    # A custom server
    $server->add_handler("/", sub {
        my ($server, $message, $path, $query, $context) = @_;
        $message->set_status(203);

        my $body = $message->response_body;
        isa_ok($body, 'HTTP::Soup::MessageBody');
        $message->response_body->append($CONTENT);

        my $headers = $message->response_headers;
        isa_ok($headers, 'HTTP::Soup::MessageHeaders');
        $headers->append('X-Test', $X_TEST);
    });

    $server->run();
}


exit main() unless caller;
