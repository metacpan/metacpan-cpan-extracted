package IO::K8s::ExternalSecrets::V1::ConfigMapReference;
# ABSTRACT: credConfig holds the configmap reference containing the GCP external account credential configuration in JSON format and the key name containing the json data.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s key       => Str, { required => 'schema', pattern => qr/^[-._a-zA-Z0-9]+$/ };
k8s name      => Str, { required => 'schema', pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s namespace => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ConfigMapReference - credConfig holds the configmap reference containing the GCP external account credential configuration in JSON format and the key name containing the json data.

=head1 VERSION

version 1.108

=head2 key

key name holding the external account credential config.

=head2 name

name of the configmap.

=head2 namespace

namespace in which the configmap exists. If empty, configmap will looked up in local namespace.

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
