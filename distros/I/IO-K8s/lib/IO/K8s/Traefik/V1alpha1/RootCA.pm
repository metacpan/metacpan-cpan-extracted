package IO::K8s::Traefik::V1alpha1::RootCA;
# ABSTRACT: RootCA defines a reference to a Secret or a ConfigMap that holds a CA certificate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s configMap => Str;
k8s secret    => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::RootCA - RootCA defines a reference to a Secret or a ConfigMap that holds a CA certificate.

=head1 VERSION

version 1.108

=head2 configMap

ConfigMap defines the name of a ConfigMap that holds a CA certificate.
The referenced ConfigMap must contain a certificate under either a tls.ca or a ca.crt key.

=head2 secret

Secret defines the name of a Secret that holds a CA certificate.
The referenced Secret must contain a certificate under either a tls.ca or a ca.crt key.

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
