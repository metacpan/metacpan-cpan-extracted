package IO::K8s::Api::Resource::V1::CapacityRequestPolicyRange;
# ABSTRACT: CapacityRequestPolicyRange defines a valid range for consumable capacity values.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s max => Quantity;


k8s min => Quantity, 'required';


k8s step => Quantity;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::CapacityRequestPolicyRange - CapacityRequestPolicyRange defines a valid range for consumable capacity values.

=head1 VERSION

version 1.106

=head2 max

Max defines the upper limit for capacity that can be requested. Max must be less than or equal to the capacity value. Min and requestPolicy.default must be less than or equal to the maximum.

=head2 min

Min specifies the minimum capacity allowed for a consumption request. Min must be greater than or equal to zero, and less than or equal to the capacity value. requestPolicy.default must be more than or equal to the minimum.

=head2 step

Step defines the step size between valid capacity amounts within the range. Max (if set) and requestPolicy.default must be a multiple of Step. Min + Step must be less than or equal to the capacity value.

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
