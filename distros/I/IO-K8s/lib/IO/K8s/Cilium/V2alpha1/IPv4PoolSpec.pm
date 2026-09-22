package IO::K8s::Cilium::V2alpha1::IPv4PoolSpec;
# ABSTRACT: IPv4 specifies the IPv4 CIDRs and mask sizes of the pool
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cidrs    => [Str], { required => 'schema' };
k8s maskSize => Int, { required => 'schema', minimum => 1, maximum => 32 };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::IPv4PoolSpec - IPv4 specifies the IPv4 CIDRs and mask sizes of the pool

=head1 VERSION

version 1.108

=head2 cidrs

CIDRs is a list of IPv4 CIDRs that are part of the pool.

=head2 maskSize

MaskSize is the mask size of the pool.

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
