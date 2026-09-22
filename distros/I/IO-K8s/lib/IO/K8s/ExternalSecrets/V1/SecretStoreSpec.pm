package IO::K8s::ExternalSecrets::V1::SecretStoreSpec;
# ABSTRACT: SecretStoreSpec defines the desired state of SecretStore.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions      => ['+IO::K8s::ExternalSecrets::V1::ClusterSecretStoreCondition'];
k8s controller      => Str;
k8s provider        => '+IO::K8s::ExternalSecrets::V1::SecretStoreProvider', { required => 'schema' };
k8s refreshInterval => IntOrStr;
k8s retrySettings   => '+IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::SecretStoreSpec - SecretStoreSpec defines the desired state of SecretStore.

=head1 VERSION

version 1.108

=head2 conditions

Used to constrain a ClusterSecretStore to specific namespaces. Relevant only to ClusterSecretStore.

=head2 controller

Used to select the correct ESO controller (think: ingress.ingressClassName)
The ESO controller is instantiated with a specific controller name and filters ES based on this property

=head2 provider

Used to configure the provider. Only one provider may be set

=head2 refreshInterval

Used to configure store refresh interval. Accepts either an integer number
of seconds (legacy) or a Go duration string such as "1h" or "5m". Empty or
0 will default to the controller config.

=head2 retrySettings

Used to configure HTTP retries on failures.

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
