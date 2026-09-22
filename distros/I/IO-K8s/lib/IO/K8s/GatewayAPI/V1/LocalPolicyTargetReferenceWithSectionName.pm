package IO::K8s::GatewayAPI::V1::LocalPolicyTargetReferenceWithSectionName;
# ABSTRACT: LocalPolicyTargetReferenceWithSectionName identifies an API object to apply a direct policy to.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s group       => Str, { required => 'schema', pattern => qr/^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s kind        => Str, { required => 'schema', pattern => qr/^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$/ };
k8s name        => Str, { required => 'schema' };
k8s sectionName => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::LocalPolicyTargetReferenceWithSectionName - LocalPolicyTargetReferenceWithSectionName identifies an API object to apply a direct policy to.

=head1 VERSION

version 1.108

=head2 group

Group is the group of the target resource.

=head2 kind

Kind is kind of the target resource.

=head2 name

Name is the name of the target resource.

=head2 sectionName

SectionName is the name of a section within the target resource. When
unspecified, this targetRef targets the entire resource. In the following
resources, SectionName is interpreted as the following:

* Gateway: Listener name
* HTTPRoute: HTTPRouteRule name
* Service: Port name

If a SectionName is specified, but does not exist on the targeted object,
the Policy must fail to attach, and the policy implementation should record
a `ResolvedRefs` or similar Condition in the Policy's status.

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
