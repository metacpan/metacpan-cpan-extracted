package IO::K8s::Cilium::V2::CiliumNetworkPolicyStatus;
# ABSTRACT: Status is the status of the Cilium policy rule
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions         => ['+IO::K8s::Cilium::V2::NetworkPolicyCondition'];
k8s derivativePolicies => { '+IO::K8s::Cilium::V2::CiliumNetworkPolicyNodeStatus' => 1 };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumNetworkPolicyStatus - Status is the status of the Cilium policy rule

=head1 VERSION

version 1.108

=head2 conditions

No description in the upstream schema.

=head2 derivativePolicies

DerivativePolicies is the status of all policies derived from the Cilium
policy

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
