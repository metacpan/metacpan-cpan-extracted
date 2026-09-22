package IO::K8s::Cilium::V2::IPAMPoolDemand;
# ABSTRACT: Needed indicates how many IPs out of the above Pool this node requests from the operator.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'ipv4-addrs' => Int;
k8s 'ipv6-addrs' => Int;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::IPAMPoolDemand - Needed indicates how many IPs out of the above Pool this node requests from the operator.

=head1 VERSION

version 1.108

=head2 ipv4-addrs

IPv4Addrs contains the number of requested IPv4 addresses out of a given
pool

=head2 ipv6-addrs

IPv6Addrs contains the number of requested IPv6 addresses out of a given
pool

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
