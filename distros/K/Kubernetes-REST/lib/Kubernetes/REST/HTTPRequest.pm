package Kubernetes::REST::HTTPRequest;
our $VERSION = '1.107';
# ABSTRACT: HTTP request object
use Moo;
use Types::Standard qw/Str HashRef/;


has server => (is => 'ro');


has credentials => (is => 'ro');


sub authenticate {
    my $self = shift;
    my $auth = $self->credentials;
    if (defined $auth) {
      $self->headers->{ Authorization } = 'Bearer ' . $auth->token;
    }
}


has uri => (is => 'rw', isa => Str);


has method => (is => 'rw', isa => Str);


has url => (is => 'rw', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    return $self->server->endpoint . $self->uri if $self->server;
    return '';
});


has headers => (is => 'rw', isa => HashRef, default => sub { {} });


has parameters => (is => 'rw', isa => HashRef);


has content => (is => 'rw', isa => Str);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::HTTPRequest - HTTP request object

=head1 VERSION

version 1.107

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPRequest;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'https://kubernetes.local:6443/api/v1/pods',
        headers => { 'Authorization' => 'Bearer token' },
    );

=head1 DESCRIPTION

Internal HTTP request object used by L<Kubernetes::REST>.

=head2 server

Optional. L<Kubernetes::REST::Server> instance for building the full URL.

=head2 credentials

Optional. Credentials for authentication: a L<Kubernetes::REST::AuthToken>, a
L<Kubernetes::REST::AuthTokenFile>, or any other object with a C<token()>
method.

=head2 authenticate

Add authentication header from the C<credentials> attribute.

=head2 uri

The URI path (e.g., C</api/v1/pods>).

=head2 method

The HTTP method (GET, POST, PUT, DELETE, PATCH, etc.).

=head2 url

The complete URL. If not provided, constructed from C<server> and C<uri>.

=head2 headers

Hashref of HTTP headers.

=head2 parameters

Hashref of query parameters.

=head2 content

The request body content (typically JSON). L<Kubernetes::REST> sets this as
already UTF-8-encoded bytes; treat it as opaque and send it on the wire
unchanged. See L<Kubernetes::REST::Role::IO/Encoding contract>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::HTTPResponse> - Response object

=item * L<Kubernetes::REST::Role::IO> - IO interface

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
