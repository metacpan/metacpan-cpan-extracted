package IO::K8s::Api::Resource::V1alpha3::ResourceClaimConsumerReference;
# ABSTRACT: ResourceClaimConsumerReference contains enough information to let you locate the consumer of a ResourceClaim. The user must be a resource in the same namespace as the ResourceClaim.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s apiGroup => Str;


k8s name => Str, 'required';


k8s resource => Str, 'required';


k8s uid => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ResourceClaimConsumerReference - ResourceClaimConsumerReference contains enough information to let you locate the consumer of a ResourceClaim. The user must be a resource in the same namespace as the ResourceClaim.

=head1 VERSION

version 1.100

=head2 apiGroup

APIGroup is the group for the resource being referenced. It is empty for the core API. This matches the group in the APIVersion that is used when creating the resources.

=head2 name

Name is the name of resource being referenced.

=head2 resource

Resource is the type of resource being referenced, for example "pods".

=head2 uid

UID identifies exactly one incarnation of the resource.

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
