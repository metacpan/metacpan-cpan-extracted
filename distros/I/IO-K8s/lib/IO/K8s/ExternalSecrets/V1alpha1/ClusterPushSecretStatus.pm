package IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus;
# ABSTRACT: ClusterPushSecretStatus contains the status information for the ClusterPushSecret resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions            => ['+IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition'];
k8s failedNamespaces      => ['+IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretNamespaceFailure'];
k8s provisionedNamespaces => [Str];
k8s pushSecretName        => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus - ClusterPushSecretStatus contains the status information for the ClusterPushSecret resource.

=head1 VERSION

version 1.108

=head2 conditions

No description in the upstream schema.

=head2 failedNamespaces

Failed namespaces are the namespaces that failed to apply an PushSecret

=head2 provisionedNamespaces

ProvisionedNamespaces are the namespaces where the ClusterPushSecret has secrets

=head2 pushSecretName

No description in the upstream schema.

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
