package IO::K8s::Cilium::V2::AllocationIP;
# ABSTRACT: AllocationIP is an IP which is available for allocation, or already has been allocated
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s owner    => Str;
k8s resource => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AllocationIP - AllocationIP is an IP which is available for allocation, or already has been allocated

=head1 VERSION

version 1.108

=head2 owner

Owner is the owner of the IP. This field is set if the IP has been
allocated. It will be set to the pod name or another identifier
representing the usage of the IP

The owner field is left blank for an entry in Spec.IPAM.Pool and
filled out as the IP is used and also added to Status.IPAM.Used.

=head2 resource

Resource is set for both available and allocated IPs, it represents
what resource the IP is associated with, e.g. in combination with
AWS ENI, this will refer to the ID of the ENI

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
