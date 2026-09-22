package IO::K8s::Cilium::V2::AzureSubnet;
# ABSTRACT: Subnet is the subnet the interface is attached to.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cidr => Str;
k8s id   => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AzureSubnet - Subnet is the subnet the interface is attached to.

=head1 VERSION

version 1.108

=head2 cidr

CIDR is the CIDR range associated with the subnet

=head2 id

ID is the resource ID of the subnet

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
