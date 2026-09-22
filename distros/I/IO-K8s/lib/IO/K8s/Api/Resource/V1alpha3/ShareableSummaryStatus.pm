package IO::K8s::Api::Resource::V1alpha3::ShareableSummaryStatus;
# ABSTRACT: ShareableSummaryStatus reports aggregate capacity for a pool that contains devices with AllowMultipleAllocations.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s capacity => ['Resource::V1alpha3::ShareableCapacityStatus'];


k8s fullyAvailableDevices => Int, 'required';


k8s partiallyAvailableDevices => Int, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ShareableSummaryStatus - ShareableSummaryStatus reports aggregate capacity for a pool that contains devices with AllowMultipleAllocations.

=head1 VERSION

version 1.108

=head2 capacity

Capacity reports aggregate total, consumed, and available amounts per shareable capacity key across the pool.

=head2 fullyAvailableDevices

FullyAvailableDevices is the number of shareable devices with no capacity consumed.

=head2 partiallyAvailableDevices

PartiallyAvailableDevices is the number of shareable devices with some but not all capacity consumed.

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
