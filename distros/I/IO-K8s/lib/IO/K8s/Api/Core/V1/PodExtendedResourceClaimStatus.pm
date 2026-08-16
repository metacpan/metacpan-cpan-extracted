package IO::K8s::Api::Core::V1::PodExtendedResourceClaimStatus;
# ABSTRACT: PodExtendedResourceClaimStatus is stored in the PodStatus for the extended resources backed by DRA. It stores the generated name for the corresponding special ResourceClaim created by the scheduler.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s requestMappings => ['Core::V1::ContainerExtendedResourceRequest'], 'required';


k8s resourceClaimName => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodExtendedResourceClaimStatus - PodExtendedResourceClaimStatus is stored in the PodStatus for the extended resources backed by DRA. It stores the generated name for the corresponding special ResourceClaim created by the scheduler.

=head1 VERSION

version 1.107

=head2 requestMappings

RequestMappings identifies the mapping of extended resource requests in each container to their corresponding requests within the special ResourceClaim.

=head2 resourceClaimName

ResourceClaimName is the name of the ResourceClaim that was generated for the Pod in the namespace of the Pod.

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
