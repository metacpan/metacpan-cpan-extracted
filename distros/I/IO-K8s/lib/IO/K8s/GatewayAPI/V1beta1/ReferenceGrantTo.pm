package IO::K8s::GatewayAPI::V1beta1::ReferenceGrantTo;
# ABSTRACT: ReferenceGrantTo describes what Kinds are allowed as targets of the references.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s group => Str, { required => 'schema', pattern => qr/^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s kind  => Str, { required => 'schema', pattern => qr/^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$/ };
k8s name  => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::ReferenceGrantTo - ReferenceGrantTo describes what Kinds are allowed as targets of the references.

=head1 VERSION

version 1.108

=head2 group

Group is the group of the referent.
When empty, the Kubernetes core API group is inferred.

Support: Core

=head2 kind

Kind is the kind of the referent. Although implementations may support
additional resources, the following types are part of the "Core"
support level for this field:

* Secret when used to permit a SecretObjectReference
* Service when used to permit a BackendObjectReference

=head2 name

Name is the name of the referent. When unspecified, this policy
refers to all resources of the specified Group and Kind in the local
namespace.

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
