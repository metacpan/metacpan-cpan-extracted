package Kubernetes::REST::Role::IO;
our $VERSION = '1.107';
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

version 1.107

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

=head2 call

    my $response = $io->call($req);

Required. Execute an HTTP request. Receives a L<Kubernetes::REST::HTTPRequest> with C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<Kubernetes::REST::HTTPResponse> with C<status> and C<content>, the latter as bytes - see L</Encoding contract>.

=head2 call_streaming

    my $response = $io->call_streaming($req, $data_callback);

Required. Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives: C<< $data_callback->($chunk) >>. Chunks are bytes - see L</Encoding contract>.

Must return a L<Kubernetes::REST::HTTPResponse> when the stream ends.

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
