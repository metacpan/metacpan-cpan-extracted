

package HTTP::DAVServer::Respond;

our $VERSION=0.1;

use strict;
use warnings;

=head1 NAME

HTTP::DAVServer::Respond - Produces all response codes, headers and sends output to client

=cut

# 0 flags does not have content
# 1 flags must have content
# -1 flags may have content

my $methods = {
    'OPTIONS' => 0,
    'GET' => 0,
    'HEAD' => 0,
    'POST' => 1,
    'DELETE' => 0,
    'PROPFIND' => 1,
    'PROPPATCH' => 1,
    'COPY' => 0,
    'MOVE' => 0,
    'PUT' => 1,
    'MKCOL' => 0,
};

sub handles {

    if ($_[1]) {
        return exists $methods->{$_[1]};
    }
    return $methods;

}

sub hasContent {

    exists $methods->{$_[1]} && return $methods->{$_[1]};
    warn "hasContent called with no valid method name ($_[1])\n" if $HTTP::DAVServer::WARN;
    return 0;

}

sub ok {

    my ($self, $r) = @_;
    warn "OK @_\n" if $HTTP::DAVServer::TRACE;

    print $r->header(
        -status => "200 OK",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub created {

    my ($self, $r) = @_;
    warn "CREATED @_\n" if $HTTP::DAVServer::TRACE;

    print $r->header(
        -status => "201 Created",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub multiStatus {

    warn "MULTISTATUS @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r, $xml) = @_;

	my $message = qq(<?xml version="1.0" encoding="utf-8" ?>\n<multistatus xmlns="DAV:">\n$xml\n</multistatus>);
    warn "RESPOND XML:\n$message\n" if $HTTP::DAVServer::TRACE;

    print $r->header(
        -status => "207 Multi-Status",
        $self->headers,
        -Content_Length => length $message,
        -Content_Type => "text/xml; charset=UTF-8",
    );

	print $message;

    exit 0;

}

sub badRequest {

    warn "BADREQUEST @_\n" if $HTTP::DAVServer::TRACE;

    my ($self, $r, $flag, $detail) = @_;

	my $message = "<h1>400 Bad Request</h1>\n$flag $detail\n";

    print $r->header(
        -status => "400 Bad Request",
        $self->headers,
        -Content_Length => length $message,
        -Content_Type => "text/html; charset=UTF-8",
    );

	print $message;

    exit 0;

}

sub challenge {

    warn "CHALLENGE @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "401 Unauthorized",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
        -WWW_Authenticate => qq(Digest realm="mymac", stale=false, nonce="c847ab2bf1b3661a9bf2a6bef87a9ef1", qop="auth", algorithm="MD5"),
    );

    exit 0;
}

sub forbidden {

    warn "FORBIDDEN @_\n" if $HTTP::DAVServer::TRACE;

    my ($self, $r) = @_;

    print $r->header(
        -status => "403 Forbidden",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub notFound {

    warn "NOTFOUND @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "404 Not Found",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub notAllowed {

    warn "NOTALLOWED @_\n" if $HTTP::DAVServer::TRACE;

    my ($self, $r) = @_;

    print $r->header(
        -status => "405 Method Not Allowed",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub conflict {

    warn "CONFLICT @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "409 Conflict",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub unsupported {

    warn "UNSUPPORTED @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "415 Unsupported Media Type",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub serverError {

    warn "SERVERERROR @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "500 Server Error",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub notImplemented {

    warn "SERVERERROR @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "501 Not Implemented",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub diskFull {

    warn "DISKFULL @_\n" if $HTTP::DAVServer::TRACE;
    my ($self, $r) = @_;

    print $r->header(
        -status => "507 Insufficient Storage",
        $self->headers,
        -Content_Length => 0,
        -Content_Type => "text/html; charset=UTF-8",
    );

    exit 0;

}

sub Server {
    return "Jay's DAV server";
}

sub DAV {
    return "1";
}

sub headers {
    my $self=shift;
    return (
        -nph    => 1,
        -Server => $self->Server,
        -DAV    => $self->DAV,
    )
}


=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "HTTP::DAVServer" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

Thank you to the authors of my prequisite modules. With out your help this code
would be much more difficult to write!

 XML::Simple - Grant McLean
 XML::SAX    - Matt Sergeant
 DateTime    - Dave Rolsky

Also the authors of litmus, a very helpful tool indeed!

=head1 SEE ALSO

HTTP::DAV, HTTP::Webdav, http://www.webdav.org/, RFC 2518

=cut

1;

