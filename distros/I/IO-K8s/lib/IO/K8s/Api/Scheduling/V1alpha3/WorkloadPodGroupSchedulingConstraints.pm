package IO::K8s::Api::Scheduling::V1alpha3::WorkloadPodGroupSchedulingConstraints;
# ABSTRACT: WorkloadPodGroupSchedulingConstraints defines leaf-level scheduling constraints, such as topology.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s topology => ['Scheduling::V1alpha3::TopologyConstraint'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha3::WorkloadPodGroupSchedulingConstraints - WorkloadPodGroupSchedulingConstraints defines leaf-level scheduling constraints, such as topology.

=head1 VERSION

version 1.108

=head2 topology

topology specifies desired topological placements for all pods within the pod group. If unset, no topology placement is requested.

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
