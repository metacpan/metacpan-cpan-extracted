package IO::K8s::Api::Apps::V1::StatefulSet;
# ABSTRACT: StatefulSet represents a set of pods with consistent identities.
our $VERSION = '1.008';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Apps::V1::StatefulSetSpec';


k8s status => 'Apps::V1::StatefulSetStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::StatefulSet - StatefulSet represents a set of pods with consistent identities.

=head1 VERSION

version 1.008

=head1 DESCRIPTION

StatefulSet represents a set of pods with consistent identities. Identities are defined as: Network: A single stable DNS and hostname. Storage: As many VolumeClaims as requested. The StatefulSet guarantees that a given network identity will always map to the same storage identity.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Spec defines the desired identities of pods in this set.

=head2 status

Status is the current status of Pods in this StatefulSet. This data may be out of date by some window of time.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#statefulset-v1-apps>

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
