package IO::K8s::Api::Resource::V1alpha3::ResourcePoolStatusRequestStatus;
# ABSTRACT: ResourcePoolStatusRequestStatus contains the calculated pool status information.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s poolCount => Int, 'required';


k8s pools => ['Resource::V1alpha3::PoolStatus'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ResourcePoolStatusRequestStatus - ResourcePoolStatusRequestStatus contains the calculated pool status information.

=head1 VERSION

version 1.106

=head2 conditions

Conditions provide information about the state of the request. A condition with type=Complete or type=Failed will always be set when the status is populated.

Known condition types:

- "Complete": True when the request has been processed successfully
- "Failed": True when the request could not be processed

=head2 poolCount

PoolCount is the total number of pools that matched the filter criteria, regardless of truncation. This helps users understand how many pools exist even when the response is truncated. A value of 0 means no pools matched the filter criteria.

=head2 pools

Pools contains the first C<spec.limit> matching pools, sorted by driver then pool name. If C<len(pools) < poolCount>, the list was truncated. When omitted, no pools matched the request filters.

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
