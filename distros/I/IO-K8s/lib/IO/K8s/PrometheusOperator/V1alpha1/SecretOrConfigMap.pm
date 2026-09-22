package IO::K8s::PrometheusOperator::V1alpha1::SecretOrConfigMap;
# ABSTRACT: cert defines the Client certificate to present when doing client-authentication.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s configMap => 'Core::V1::ConfigMapKeySelector';
k8s secret    => 'Core::V1::ConfigMapKeySelector';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::SecretOrConfigMap - cert defines the Client certificate to present when doing client-authentication.

=head1 VERSION

version 1.108

=head2 configMap

configMap defines the ConfigMap containing data to use for the targets.

=head2 secret

secret defines the Secret containing data to use for the targets.

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
