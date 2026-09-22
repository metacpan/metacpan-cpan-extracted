package IO::K8s::Cilium::V2::AwsVPC;
# ABSTRACT: VPC is the VPC information to which the ENI is attached to
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cidrs          => [Str];
k8s id             => Str;
k8s 'primary-cidr' => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AwsVPC - VPC is the VPC information to which the ENI is attached to

=head1 VERSION

version 1.108

=head2 cidrs

CIDRs is the list of CIDR ranges associated with the VPC

=head2 id

/ ID is the ID of a VPC

=head2 primary-cidr

PrimaryCIDR is the primary CIDR of the VPC

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
