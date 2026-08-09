package IO::K8s::Api::Core::V1::NodeAllocatableResourceClaimStatus;
# ABSTRACT: NodeAllocatableResourceClaimStatus tracks the status of node-allocatable resources allocated to a ResourceClaim for a Pod.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s containers => [Str], 'required';


k8s resourceClaimName => Str, 'required';


k8s resources => { Str => 1 };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::NodeAllocatableResourceClaimStatus - NodeAllocatableResourceClaimStatus tracks the status of node-allocatable resources allocated to a ResourceClaim for a Pod.

=head1 VERSION

version 1.105

=head2 containers

Containers lists the names of the containers in the Pod that use this ResourceClaim to consume node-allocatable resources.

=head2 resourceClaimName

ResourceClaimName is the name of the ResourceClaim that was generated for the Pod to track allocation of node-allocatable resources.

=head2 resources

Resources lists the node-allocatable resources that were allocated to this ResourceClaim, keyed by resource name.

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
