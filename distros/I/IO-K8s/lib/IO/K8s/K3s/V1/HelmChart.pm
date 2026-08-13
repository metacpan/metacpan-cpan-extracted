package IO::K8s::K3s::V1::HelmChart;
# ABSTRACT: K3s Helm chart deployment
our $VERSION = '1.106';
use IO::K8s::APIObject
    api_version     => 'helm.cattle.io/v1',
    resource_plural => 'helmcharts';
with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::HelmManaged';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::HelmChart - K3s Helm chart deployment

=head1 VERSION

version 1.106

=head1 DESCRIPTION

This class represents a HelmChart custom resource in the C<helm.cattle.io/v1> API group. HelmChart resources declare Helm charts to be deployed by the K3s Helm controller, which automatically manages the chart lifecycle. This is a namespace-scoped resource where the C<spec> and C<status> fields are opaque hash structures defined by the K3s API.

As of the C<helm-controller> version shipped with K3s v1.36.3+k3s1, C<spec> accepts several fields beyond the historical C<chart>/C<version>/C<set>/C<valuesContent>: C<values> (structured YAML/JSON values, taking precedence over C<valuesContent>), C<serverSide> (C<"true">|C<"false">|C<"auto">, controls Helm server-side-apply), C<forceConflicts> (bool, force managed-field ownership on server-side-apply conflicts), and C<driver> (C<"secret">|C<"configmap">, selects the Helm release-metadata storage backend; immutable after creation). C<failurePolicy> now also accepts C<retry> in addition to the existing C<abort>|C<reinstall>. All of these pass through transparently via the opaque C<spec> hash above.

=head1 SEE ALSO

=over

=item * L<IO::K8s::K3s> - K3s custom resources

=item * L<https://docs.k3s.io/helm> - K3s Helm Controller Documentation

=back

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
