package IO::K8s::Api::Core::V1::NodeAllocatableMappedResources;
# ABSTRACT: NodeAllocatableMappedResources describes mapped node allocatable resource allocations.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s quantity => Quantity, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::NodeAllocatableMappedResources - NodeAllocatableMappedResources describes mapped node allocatable resource allocations.

=head1 VERSION

version 1.108

=head2 name

Name is the name of the resource (e.g., cpu, memory).

=head2 quantity

Quantity is the total node allocatable resource capacity allocated for the claim. This claim's allocated devices is shared by all the containers referencing the claim. Kubelet adds this value to both requests and limits at the pod-level cgroup, and to limits at the container-level cgroup for each container referencing the claim.

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
