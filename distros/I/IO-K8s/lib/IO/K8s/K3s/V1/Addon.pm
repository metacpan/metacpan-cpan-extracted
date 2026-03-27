package IO::K8s::K3s::V1::Addon;
# ABSTRACT: K3s cluster addon
our $VERSION = '1.100';
use IO::K8s::APIObject
    api_version     => 'k3s.cattle.io/v1',
    resource_plural => 'addons';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::Addon - K3s cluster addon

=head1 VERSION

version 1.100

=head1 DESCRIPTION

This class represents an Addon custom resource in the C<k3s.cattle.io/v1> API group. Addon resources represent K3s cluster addons, which are Kubernetes manifests automatically deployed during cluster startup or runtime. This is a namespace-scoped resource where the C<spec> and C<status> fields are opaque hash structures defined by the K3s API.

=head1 SEE ALSO

=over

=item * L<IO::K8s::K3s> - K3s custom resources

=item * L<https://docs.k3s.io/installation/packaged-components> - K3s Packaged Components Documentation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
