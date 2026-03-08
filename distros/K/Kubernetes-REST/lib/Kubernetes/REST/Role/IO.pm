package Kubernetes::REST::Role::IO;
our $VERSION = '1.100';
# ABSTRACT: Interface role for HTTP backends
use Moo::Role;


requires 'call';


requires 'call_streaming';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Role::IO - Interface role for HTTP backends

=head1 VERSION

version 1.100

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

=head1 DESCRIPTION

This role defines the interface that HTTP backends must implement. L<Kubernetes::REST> delegates all HTTP communication through this interface, making it possible to swap out the transport layer.

The default backend is L<Kubernetes::REST::LWPIO> (using L<LWP::UserAgent>). An alternative L<Kubernetes::REST::HTTPTinyIO> (using L<HTTP::Tiny>) is provided. To use an async event loop, implement this role with e.g. L<Net::Async::HTTP>.

=head2 call

    my $response = $io->call($req);

Required. Execute an HTTP request. Receives a L<Kubernetes::REST::HTTPRequest> with C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<Kubernetes::REST::HTTPResponse> with C<status> and C<content>.

=head2 call_streaming

    my $response = $io->call_streaming($req, $data_callback);

Required. Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives: C<< $data_callback->($chunk) >>.

Must return a L<Kubernetes::REST::HTTPResponse> when the stream ends.

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

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org> (JLMARTIN, original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
