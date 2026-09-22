package IO::K8s::Api::Scheduling::V1beta1::WorkloadReference;
# ABSTRACT: WorkloadReference references the Workload object together with the template that was used to create a particular PodGroup.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s templateName => Str, 'required';


k8s workloadName => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1beta1::WorkloadReference - WorkloadReference references the Workload object together with the template that was used to create a particular PodGroup.

=head1 VERSION

version 1.108

=head2 templateName

templateName is the name of a template within the Workload object that was used to create a pod group. It must be a DNS label. This field is required.

=head2 workloadName

workloadName is the name of the Workload object that contains a template that was used when creating a pod group. It must be a DNS name. This field is required.

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
