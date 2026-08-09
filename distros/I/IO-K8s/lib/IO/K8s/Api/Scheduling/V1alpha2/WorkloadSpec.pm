package IO::K8s::Api::Scheduling::V1alpha2::WorkloadSpec;
# ABSTRACT: WorkloadSpec defines the desired state of a Workload.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s controllerRef => 'Core::V1::TypedLocalObjectReference';


k8s podGroupTemplates => ['Scheduling::V1alpha2::PodGroupTemplate'], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha2::WorkloadSpec - WorkloadSpec defines the desired state of a Workload.

=head1 VERSION

version 1.105

=head2 controllerRef

ControllerRef is an optional reference to the controlling object, such as a Deployment or Job. This field is intended for use by tools like CLIs to provide a link back to the original workload definition.

This field is immutable.

=head2 podGroupTemplates

PodGroupTemplates is the list of templates that make up the Workload. The maximum number of templates is 8. This field is immutable.

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
