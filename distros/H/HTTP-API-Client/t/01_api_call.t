=head1 NAME

01_api_call.t - a subclass overriding send() can fake a response, and get()
returns it unchanged

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

{

    package Foo;
    use Moo;
    extends 'HTTP::API::Client';

    sub send {
        my $r = HTTP::Response->new;
        $r->content('OK');
        return $r;
    }
}

my $api = Foo->new;
my $res = $api->get("http://127.0.0.1/OK");

is $res->content, "OK";

done_testing;
