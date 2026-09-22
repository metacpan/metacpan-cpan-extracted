package IO::K8s::ExternalSecrets::V1::WebhookCAProvider;
# ABSTRACT: The provider for the CA bundle to use to validate webhook server certificate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s key       => Str, { pattern => qr/^[-._a-zA-Z0-9]+$/ };
k8s name      => Str, { required => 'schema', pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s namespace => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ };
k8s type      => Str, { required => 'schema', enum => [qw(Secret ConfigMap)] };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::WebhookCAProvider - The provider for the CA bundle to use to validate webhook server certificate.

=head1 VERSION

version 1.108

=head2 key

The key where the CA certificate can be found in the Secret or ConfigMap.

=head2 name

The name of the object located at the provider type.

=head2 namespace

The namespace the Provider type is in.

=head2 type

The type of provider to use such as "Secret", or "ConfigMap".

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

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

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
