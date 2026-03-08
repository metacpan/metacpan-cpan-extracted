package IO::K8s::Api::Rbac::V1::ClusterRoleBinding;
# ABSTRACT: ClusterRoleBinding references a ClusterRole, but not contain it.  It can reference a ClusterRole in the global namespace, and adds who information via Subject.
our $VERSION = '1.006';
use IO::K8s::APIObject;


k8s roleRef => 'Rbac::V1::RoleRef', 'required';


k8s subjects => ['Rbac::V1::Subject'];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Rbac::V1::ClusterRoleBinding - ClusterRoleBinding references a ClusterRole, but not contain it.  It can reference a ClusterRole in the global namespace, and adds who information via Subject.

=head1 VERSION

version 1.006

=head1 DESCRIPTION

ClusterRoleBinding references a ClusterRole, but not contain it.  It can reference a ClusterRole in the global namespace, and adds who information via Subject.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 roleRef

RoleRef can only reference a ClusterRole in the global namespace. If the RoleRef cannot be resolved, the Authorizer must return an error. This field is immutable.

=head2 subjects

Subjects holds references to the objects the role applies to.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#clusterrolebinding-v1-rbac.authorization.k8s.io>

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
