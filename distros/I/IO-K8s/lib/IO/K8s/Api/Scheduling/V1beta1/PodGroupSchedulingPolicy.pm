package IO::K8s::Api::Scheduling::V1beta1::PodGroupSchedulingPolicy;
# ABSTRACT: PodGroupSchedulingPolicy defines the scheduling configuration for a PodGroup. Exactly one policy must be set. The policy is chosen at creation time by setting either the Basic or Gang field. The PodGroup may not change policy after creation. Fields within chosen policy may be updated after creation when their individual fields allow it.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s basic => 'Scheduling::V1beta1::BasicSchedulingPolicy';


k8s gang => 'Scheduling::V1beta1::GangSchedulingPolicy';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1beta1::PodGroupSchedulingPolicy - PodGroupSchedulingPolicy defines the scheduling configuration for a PodGroup. Exactly one policy must be set. The policy is chosen at creation time by setting either the Basic or Gang field. The PodGroup may not change policy after creation. Fields within chosen policy may be updated after creation when their individual fields allow it.

=head1 VERSION

version 1.108

=head2 basic

basic specifies that the pods in this group should be scheduled using standard Kubernetes scheduling behavior. Setting this field at group creation time opts this group to basic scheduling; this field cannot be changed afterward.

=head2 gang

gang specifies that the pods in this group should be scheduled using all-or-nothing semantics. Setting this field at group creation time opts this group to gang scheduling; this field cannot be set or unset afterward. The minCount field within Gang scheduling policy remains mutable after group creation.

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
