package IO::K8s::Api::Apps::V1::Deployment;
# ABSTRACT: Deployment enables declarative updates for Pods and ReplicaSets.
our $VERSION = '1.100';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Apps::V1::DeploymentSpec';


k8s status => 'Apps::V1::DeploymentStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::Deployment - Deployment enables declarative updates for Pods and ReplicaSets.

=head1 VERSION

version 1.100

=head1 DESCRIPTION

Deployment enables declarative updates for Pods and ReplicaSets.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Specification of the desired behavior of the Deployment.

=head2 status

Most recently observed status of the Deployment.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#deployment-v1-apps>

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
