package Kubernetes::REST::Role::IO;
our $VERSION = '1.110';
# ABSTRACT: Interface role for HTTP backends
use Moo::Role;


requires 'call';


requires 'call_streaming';


sub supports_duplex {
    my ($self) = @_;
    return $self->can('call_duplex') ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Role::IO - Interface role for HTTP backends

=head1 VERSION

version 1.110

=head1 SYNOPSIS

    package My::AsyncIO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    sub call {
        my ($self, $req) = @_;
        # Execute HTTP request, return Kubernetes::REST::HTTPResponse
        ...
    }

    sub call_streaming {
        my ($self, $req, $data_callback) = @_;
        # Execute HTTP request with streaming callback
        ...
    }

    # Optional: full-duplex transport (WebSocket/SPDY)
    sub call_duplex {
        my ($self, $req, %callbacks) = @_;
        ...
    }

=head1 DESCRIPTION

This role defines the interface that HTTP backends must implement. L<Kubernetes::REST> delegates all HTTP communication through this interface, making it possible to swap out the transport layer.

The default backend is L<Kubernetes::REST::LWPIO> (using L<LWP::UserAgent>). An alternative L<Kubernetes::REST::HTTPTinyIO> (using L<HTTP::Tiny>) is provided. To use an async event loop, implement this role with e.g. L<Net::Async::HTTP>.

This is not how L<Net::Async::Kubernetes>, this distribution's own async client, integrates: it does not consume this role or call C<call>/C<call_streaming> at all. Instead it drives L<Kubernetes::REST>'s request pipeline directly, through the published C<build_path>, C<prepare_request>, C<check_response>, C<inflate_object>, C<inflate_list>, C<process_watch_chunk> and C<process_log_chunk> methods, running its own HTTP transport underneath them. Two more published methods, C<prepare_discovery_requests> and C<absorb_discovery>, let such a client read the cluster's discovery through its own transport too, instead of the synchronous L</call> that name resolution otherwise uses for it (see L<Kubernetes::REST/BUILDING BLOCKS FOR ASYNC WRAPPERS>).

Both shipped backends are synchronous, request/response-only transports: neither
implements C<call_duplex> (see L</supports_duplex> below), so L<Kubernetes::REST>
methods that need full-duplex transport (C<port_forward>, C<exec>, C<attach>)
croak against them by design. A backend that wants to support those needs to
implement C<call_duplex($req, %callbacks)> itself, as sketched in the L</SYNOPSIS>.

=head2 Encoding contract

Request and response bodies are B<bytes>, never character strings - this holds
for C<call> and C<call_streaming> alike, whatever kind of request they carry.

A backend receives C<< $req->content >> already UTF-8 encoded (the core client's
JSON encoder runs with C<utf8 =E<gt> 1>) and must put it on the wire unchanged.
It must hand back C<< $res->content >> - and every streaming chunk - as the
bytes it received, undoing C<Content-Encoding> (gzip) but B<not> the charset.

Two different callers rely on this, for two different reasons:

=over

=item *

For C<get>/C<list>/C<watch>, L<Kubernetes::REST> decodes UTF-8 itself once the
JSON is parsed, together with L<IO::K8s>. A backend that decodes the charset
first causes silent double decoding (mojibake) on any non-ASCII value.

=item *

For C<log> (streamed via C<call_streaming> just like C<watch>), the bytes are
handed straight back to the caller undecoded, on purpose: container output is
not guaranteed to be UTF-8, or even text, so there is no safe charset for the
backend to assume. See L<Kubernetes::REST/log>.

=back

With L<LWP::UserAgent> that means C<< $res->decoded_content(charset => 'none') >>
rather than C<< $res->decoded_content >>. See also L<Kubernetes::REST/ENCODING>
for the full picture from the caller's side of this module.

=head2 Error contract

C<call> and C<call_streaming> tell three kinds of failure apart, and a backend
must keep them apart. A status code is the only thing L<Kubernetes::REST>
reads to do so.

=over

=item *

B<A transport failure is a response with status 599.> When no answer from the
API server exists, the backend returns a L<Kubernetes::REST::HTTPResponse> with
C<status> C<599> and the error message as C<content>; it does not die. That
covers a refused or failed connect, a TLS error, a timeout, an unsupported URL
scheme, a missing protocol module (C<LWP::Protocol::https not installed>) and a
transfer that breaks off in the middle of the body, in C<call> and
C<call_streaming> alike. A backend whose library reports such a failure as an
ordinary-looking response, or as a truncated 200, must map it to 599 itself.

=item *

B<Every other status is the API server's answer> and is returned unchanged,
C<500> and C<502> included. The backend does not retry it, rewrite it or
turn it into an exception. Only the status values from the HTTP library's own
internal failure reporting are the backend's to translate.

=item *

B<An exception thrown by the streaming callback is not a transport failure.>
If C<$data_callback> dies, C<call_streaming> aborts the transfer and dies with
that same exception, a string or an object, untouched. It returns no
response, and in particular no 599. A library that catches the exception and
reports it as an error status (L<HTTP::Tiny> turns it into a 599) must have it
captured first and rethrown. The callback is not called again after it has
thrown. This is how an exception from the C<on_event> or C<on_line> handler of
L<Kubernetes::REST/watch> and L<Kubernetes::REST/log> reaches the caller of
those methods.

=back

L<Kubernetes::REST> treats the 599 like any other status of 400 and up: its
response check dies with a L<Kubernetes::REST::APIError> whose C<code> is
C<599> and whose C<body> is the message the backend put in C<content>. A
caller tells a transport failure from an answer of the server by that code.

=head2 call

    my $response = $io->call($req);

Required. Execute an HTTP request. Receives a L<Kubernetes::REST::HTTPRequest> with C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<Kubernetes::REST::HTTPResponse> with C<status> and C<content>, the latter as bytes - see L</Encoding contract>. A transport failure (no answer from the API server) is returned as status C<599> with the error message as C<content>, never thrown; every other status is the server's and stays as it is - see L</Error contract>.

=head2 call_streaming

    my $response = $io->call_streaming($req, $data_callback);

Required. Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives: C<< $data_callback->($chunk) >>. Chunks are bytes - see L</Encoding contract>.

Must return a L<Kubernetes::REST::HTTPResponse> when the stream ends. A transport failure, including a break in the middle of the body, is returned as status C<599> with the error message as C<content>, as in C<call>.

If C<$data_callback> dies, the backend aborts the transfer and dies with the same exception, unchanged and without a response; that is not a 599. See L</Error contract>.

=head2 supports_duplex

    if ($io->supports_duplex) {
        ...
    }

Optional capability probe for full-duplex protocols used by Kubernetes
subresources such as pod port-forward and exec/attach streams.

Returns true if the backend implements C<call_duplex>, false otherwise.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::LWPIO> - LWP::UserAgent backend (default)

=item * L<Kubernetes::REST::HTTPTinyIO> - HTTP::Tiny backend

=item * L<Kubernetes::REST::HTTPRequest> - Request object

=item * L<Kubernetes::REST::HTTPResponse> - Response object

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
