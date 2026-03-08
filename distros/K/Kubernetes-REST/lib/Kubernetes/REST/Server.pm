package Kubernetes::REST::Server;
our $VERSION = '1.100';
# ABSTRACT: Kubernetes API server connection configuration
use Moo;
use Types::Standard qw/Str Bool/;


has endpoint => (is => 'ro', isa => Str, required => 1);


has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);


has ssl_cert_file => (is => 'ro');


has ssl_cert_pem => (is => 'ro');


has ssl_key_file => (is => 'ro');


has ssl_key_pem => (is => 'ro');


has ssl_ca_file => (is => 'ro');


has ssl_ca_pem => (is => 'ro');


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Server - Kubernetes API server connection configuration

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Kubernetes::REST::Server;

    my $server = Kubernetes::REST::Server->new(
        endpoint => 'https://kubernetes.local:6443',
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

=head1 DESCRIPTION

Configuration object for Kubernetes API server connection details.

=head2 endpoint

Required. The Kubernetes API server endpoint URL (e.g., C<https://kubernetes.local:6443>).

=head2 ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to C<1> (true).

Set to C<0> for development clusters with self-signed certificates.

=head2 ssl_cert_file

Optional. Path to client certificate file for mTLS authentication.

=head2 ssl_cert_pem

Optional. PEM string of client certificate for mTLS authentication.
Takes precedence over C<ssl_cert_file>.

=head2 ssl_key_file

Optional. Path to client key file for mTLS authentication.

=head2 ssl_key_pem

Optional. PEM string of client key for mTLS authentication.
Takes precedence over C<ssl_key_file>.

=head2 ssl_ca_file

Optional. Path to CA certificate file for verifying the server certificate.

=head2 ssl_ca_pem

Optional. PEM string of CA certificate for server verification.
Takes precedence over C<ssl_ca_file>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Kubeconfig> - Load settings from kubeconfig

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
