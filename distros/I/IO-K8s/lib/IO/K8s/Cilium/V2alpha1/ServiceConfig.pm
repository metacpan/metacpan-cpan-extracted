package IO::K8s::Cilium::V2alpha1::ServiceConfig;
# ABSTRACT: Service specifies the configuration for the generated Service.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allocateLoadBalancerNodePorts  => Bool;
k8s externalTrafficPolicy          => Str, { default => 'Cluster' };
k8s ipFamilies                     => [Str];
k8s ipFamilyPolicy                 => Str;
k8s loadBalancerClass              => Str;
k8s loadBalancerSourceRanges       => [Str];
k8s loadBalancerSourceRangesPolicy => Str, { enum => [qw(Allow Deny)], default => 'Allow' };
k8s trafficDistribution            => Str;
k8s type                           => Str, { enum => [qw(LoadBalancer NodePort)], default => 'LoadBalancer' };










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::ServiceConfig - Service specifies the configuration for the generated Service.

=head1 VERSION

version 1.108

=head2 allocateLoadBalancerNodePorts

Sets the Service.Spec.AllocateLoadBalancerNodePorts in generated Service objects to the given value.

=head2 externalTrafficPolicy

Sets the Service.Spec.ExternalTrafficPolicy in generated Service objects to the given value.

=head2 ipFamilies

Sets the Service.Spec.IPFamilies in generated Service objects to the given value.

=head2 ipFamilyPolicy

Sets the Service.Spec.IPFamilyPolicy in generated Service objects to the given value.

=head2 loadBalancerClass

Sets the Service.Spec.LoadBalancerClass in generated Service objects to the given value.

=head2 loadBalancerSourceRanges

Sets the Service.Spec.LoadBalancerSourceRanges in generated Service objects to the given value.

=head2 loadBalancerSourceRangesPolicy

LoadBalancerSourceRangesPolicy defines the policy for the LoadBalancerSourceRanges if the incoming traffic
is allowed or denied.

=head2 trafficDistribution

Sets the Service.Spec.TrafficDistribution in generated Service objects to the given value.

=head2 type

Sets the Service.Spec.Type in generated Service objects to the given value.
Only LoadBalancer and NodePort are supported.

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
