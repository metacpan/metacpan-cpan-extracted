package IO::K8s::Api::Resource::V1beta1::CapacityRequestPolicy;
# ABSTRACT: CapacityRequestPolicy defines how requests consume device capacity.  Must not set more than one ValidRequestValues.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s default => Quantity;


k8s validRange => 'Resource::V1beta1::CapacityRequestPolicyRange';


k8s validValues => [Quantity];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta1::CapacityRequestPolicy - CapacityRequestPolicy defines how requests consume device capacity.  Must not set more than one ValidRequestValues.

=head1 VERSION

version 1.107

=head2 default

Default specifies how much of this capacity is consumed by a request that does not contain an entry for it in DeviceRequest's Capacity.

=head2 validRange

ValidRange defines an acceptable quantity value range in consuming requests.  If this field is set, Default must be defined and it must fall within the defined ValidRange.  If the requested amount does not fall within the defined range, the request violates the policy, and this device cannot be allocated.  If the request doesn't contain this capacity entry, Default value is used.

=head2 validValues

ValidValues defines a set of acceptable quantity values in consuming requests.  Must not contain more than 10 entries. Must be sorted in ascending order.  If this field is set, Default must be defined and it must be included in ValidValues list.  If the requested amount does not match any valid value but smaller than some valid values, the scheduler calculates the smallest valid value that is greater than or equal to the request. That is: min(ceil(requestedValue) ∈ validValues), where requestedValue ≤ max(validValues).  If the requested amount exceeds all valid values, the request violates the policy, and this device cannot be allocated.

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
