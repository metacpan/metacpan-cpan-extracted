package IO::K8s::Api::Resource::V1beta2::DeviceCounterConsumption;
# ABSTRACT: DeviceCounterConsumption defines a set of counters that a device will consume from a CounterSet.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s compatibilityGroups => [Str];


k8s counterSet => Str, 'required';


k8s counters => { 'Resource::V1beta2::Counter' => 1 }, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::DeviceCounterConsumption - DeviceCounterConsumption defines a set of counters that a device will consume from a CounterSet.

=head1 VERSION

version 1.108

=head2 compatibilityGroups

CompatibilityGroups is a list of opaque group names for this counter set consumption.

Devices that consume counters from the same counter set may only be allocated at the same time ("co-allocated") if they all share at least one common group: the intersection of the CompatibilityGroups of all co-allocated devices on that counter set must be non-empty. Devices that consume from different counter sets are never compared via this field.

An unset field, an explicit nil, and an empty list are equivalent and mean "no groups": such a device is only co-allocatable with sibling devices on the same counter set that also have no groups, and is never co-allocatable with a device that declares one or more groups.

Group names are opaque and meaningful only within the publishing driver's pool.

The maximum number of groups is 2, and the names must be unique.

=head2 counterSet

CounterSet is the name of the set from which the counters defined will be consumed.

=head2 counters

Counters defines the counters that will be consumed by the device.  The maximum number of counters is 32.

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
