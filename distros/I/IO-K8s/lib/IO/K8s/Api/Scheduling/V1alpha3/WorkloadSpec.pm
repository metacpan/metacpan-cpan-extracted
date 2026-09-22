package IO::K8s::Api::Scheduling::V1alpha3::WorkloadSpec;
# ABSTRACT: WorkloadSpec defines the desired state of a Workload.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s compositePodGroupTemplates => ['Scheduling::V1alpha3::CompositePodGroupTemplate'];


k8s controllerRef => 'Scheduling::V1alpha3::TypedLocalObjectReference';


k8s podGroupTemplates => ['Scheduling::V1alpha3::PodGroupTemplate'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha3::WorkloadSpec - WorkloadSpec defines the desired state of a Workload.

=head1 VERSION

version 1.108

=head2 compositePodGroupTemplates

compositePodGroupTemplates is the list of CompositePodGroup templates that make up the Workload. The maximum number of templates is 8. This field is immutable. Exactly one of CompositePodGroupTemplates and PodGroupTemplates must be set.

This field is used only when the CompositePodGroup feature gate is enabled.

=head2 controllerRef

controllerRef is an optional reference to the controlling object, such as a Deployment or Job. This field is intended for use by tools like CLIs to provide a link back to the original workload definition. This field is immutable.

=head2 podGroupTemplates

podGroupTemplates is the list of templates that make up the Workload. The maximum number of templates is 8. Templates cannot be added or removed after the workload is created. Existing templates may still be updated where their individual fields allow it. Exactly one of CompositePodGroupTemplates and PodGroupTemplates must be set.

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
