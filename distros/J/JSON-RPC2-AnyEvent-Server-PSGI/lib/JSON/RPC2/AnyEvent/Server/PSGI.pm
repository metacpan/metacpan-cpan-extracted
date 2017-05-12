package JSON::RPC2::AnyEvent::Server::PSGI;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent;
use JSON;
use Plack::Request;
use Try::Tiny;

use JSON::RPC2::AnyEvent::Constants qw(ERR_PARSE_ERROR);
use JSON::RPC2::AnyEvent::Server;


sub JSON::RPC2::AnyEvent::Server::to_psgi_app {
    my ($self) = @_;
    sub{
        my $req = Plack::Request->new(shift);
        if ( $req->method eq 'GET' or  $req->method eq 'HEAD' ) {
            return _dispatch_url_query($self, $req);
        } elsif ( $req->method eq 'POST' ) {
            return $req->content_type =~ m|^application/x-www-form-urlencoded$|i
                ? _dispatch_url_query($self, $req)
                : _dispatch_json($self, $req);
        } else {
            return [405, ['Content-type' => 'text/plain'], ['Method Not Allowed']]
        }
    }
}

my $json = JSON->new->utf8;

sub _dispatch_url_query {
    my ($self, $req) = @_;
    _dispatch_aux($self, {
        jsonrpc => '2.0',
        id      => undef,
        method  => substr($req->path_info, 1),
        params  => $req->parameters->mixed,
    });
}

sub _dispatch_json {
    my ($self, $req) = @_;
    try{
        my $hash = $json->decode($req->content);
        _dispatch_aux($self, $hash);
    } catch {
        [200, ['Content-Type', 'application/json'], [$json->encode({
            jsonrpc => '2.0',
            id      => undef,
            error   => {code => ERR_PARSE_ERROR, message => 'Parse error', data => shift}
        })]]
    };
}

sub _dispatch_aux {
    my ($self, $hash) = @_;
    my $cv = $self->dispatch($hash);
    return [200, [], []]  unless $cv;  # notification
    sub{
        my $writer = shift->([200, ['Content-Type', 'application/json']]);
        $cv->cb(sub{
            my $res = shift->recv;
            $writer->write($json->encode($res));
            $writer->close;
        });
    };
}


1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent::Server::PSGI - PSGI adapter for JSON::RPC2::AnyEvent::Server

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Server::PSGI;
    
    my $srv = JSON::RPC2::AnyEvent::Server->new(
        method => '[arg1, arg2]' => sub{
            my ($cv, $args) = @_;
            do_some_async_task(sub{ $cv->($result) });
        }
    );
    
    $srv->to_psgi_app;  # psgi app


=head1 DESCRIPTION

JSON::RPC2::AnyEvent::Server::PSGI is a PSGI adapter for JSON::RPC2::AnyEvent::Server.
It converts JSON::RPC2::AnyEvent::Server object to a PSGI app.


=head1 USAGE

Just call C<to_psgi_app> method on JSON::RPC2::AnyEvent::Server object:

    my $srv = JSON::RPC2::AnyEvent::Server->new(...);
    my $psgi_app = $srv->to_psgi_app;

That's it!


=head1 URL-QUERY MAPPING

While you can send requests as JSON of course, you can also send requests as
application/x-www-form-urlencoded format for your convinience. The mapping rule
between URL-query to JSON is similar to but slightly different from the rule of
L<JSON-RPC 1.1 Draft|http://tonyg.github.io/erlang-rfc4627/doc/JSON-RPC-1-1-WD-20060807.html>.

For example:

    POST /jsonrpc/do_it HTTP/1.1
    Host: example.com
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 11
    
    foo=1&bar=2

This request is equivalent to the below: 

    POST /jsonrpc HTTP/1.1
    Host: example.com
    Content-Type: application/json
    Content-Length: 75
    
    {"jsonrpc":"2.0", "id":null, "method":"do_it", "params":{"foo":1, "bar":2}}

Key-value pairs of URL-encoded query is translated into a JSON object (hash) and method to be
called is determined by the path-info (extra-path) part in the requested URI.

This module makes special treatment for requests with Content-Type header set to
"application/x-www-form-urlencoded".

You can even call RPC by HTTP GET request. The above request is also equivalent to
the following:

    GET /jsonrpc/do_it?foo=1&bar=2 HTTP/1.1
    Host: example.com
    

If a key is used multiple times, it is treated as a arrayref. For instance:

    GET /jsonrpc/do_it?foo=1&bar=2&foo=3 HTTP/1.1
    Host: example.com
    

is equivalent to:

    POST /jsonrpc HTTP/1.1
    Host: example.com
    Content-Type: application/json
    Content-Length: 81
    
    {"jsonrpc":"2.0", "id":null, "method":"do_it", "params":{"foo":[1, 3], "bar":2}}


=head1 NOTIFICATION

Since L<JSON-RPC 2.0 spec|http://www.jsonrpc.org/specification> defines "The Server MUST NOT
reply to a Notification, this module does not reply any responses for notification requests,
but just returns empty HTTP response (zero-length content body) with status code 200.

Actually, the server returns response as soon as it turns out the response is notification,
even when the corresponding server method has not completed the process. It can be an advantege
to normal method call requests, because it blocks clients only for short time.


=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

