package TestServer::Reflect;
use strict;
use warnings;

use TestServer ();
our @ISA = qw(TestServer);

use HTTP::Response;

sub dispatch {
    my $self = shift;
    my ($c, $method, $uri, $request) = @_;

    if ($uri eq '/content-length') {
        my $res = HTTP::Response->new(200);
        $res->content(length $request->content);
        $c->send_response($res);
    }
    elsif ($uri eq '/echo') {
        my $res = HTTP::Response->new(200);
        $res->content($request->content);
        $c->send_response($res);
    }
    else {
        $c->send_error(404);
    }

    $c->force_last_request;    # we're just not mature enough
    $c->close;
}

1;
