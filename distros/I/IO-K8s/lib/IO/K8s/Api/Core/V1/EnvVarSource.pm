package IO::K8s::Api::Core::V1::EnvVarSource;
# ABSTRACT: EnvVarSource represents a source for the value of an EnvVar.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s configMapKeyRef => 'Core::V1::ConfigMapKeySelector';


k8s fieldRef => 'Core::V1::ObjectFieldSelector';


k8s resourceFieldRef => 'Core::V1::ResourceFieldSelector';


k8s secretKeyRef => 'Core::V1::SecretKeySelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::EnvVarSource - EnvVarSource represents a source for the value of an EnvVar.

=head1 VERSION

version 1.006

=head2 configMapKeyRef

Selects a key of a ConfigMap.

=head2 fieldRef

Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`, spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.

=head2 resourceFieldRef

Selects a resource of the container: only resources limits and requests (limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.

=head2 secretKeyRef

Selects a key of a secret in the pod's namespace

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
