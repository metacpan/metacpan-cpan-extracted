package IO::K8s::Api::Resource::V1alpha3::PartitionTypeStatus;
# ABSTRACT: PartitionTypeStatus reports allocatability for a single partition type, identified by the value of a grouping attribute.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allocatable => Int, 'required';


k8s attribute => Str, 'required';


k8s total => Int, 'required';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::PartitionTypeStatus - PartitionTypeStatus reports allocatability for a single partition type, identified by the value of a grouping attribute.

=head1 VERSION

version 1.108

=head2 allocatable

Allocatable is the number of additional devices of this partition type that could still be allocated given current shared-counter consumption.

=head2 attribute

Attribute is the fully qualified name of the device attribute whose value groups this entry. It is the PartitionTypeAttribute declared by the devices' own slice, or the default named in the request when their slice declares none.

=head2 total

Total is the number of devices of this partition type in the pool.

=head2 type

Type is the partition type value (e.g. "Full" or "Half").

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
