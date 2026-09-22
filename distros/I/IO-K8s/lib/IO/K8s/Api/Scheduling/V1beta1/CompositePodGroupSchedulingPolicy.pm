package IO::K8s::Api::Scheduling::V1beta1::CompositePodGroupSchedulingPolicy;
# ABSTRACT: CompositePodGroupSchedulingPolicy defines the scheduling configuration for a CompositePodGroup. Exactly one policy must be set.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s basic => 'Scheduling::V1beta1::CompositeBasicSchedulingPolicy';


k8s gang => 'Scheduling::V1beta1::CompositeGangSchedulingPolicy';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1beta1::CompositePodGroupSchedulingPolicy - CompositePodGroupSchedulingPolicy defines the scheduling configuration for a CompositePodGroup. Exactly one policy must be set.

=head1 VERSION

version 1.108

=head2 basic

basic specifies that the groups of this composite group should be scheduled independently. This field is immutable.

=head2 gang

gang specifies that the groups of this composite group should be scheduled using all-or-nothing semantics.

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
