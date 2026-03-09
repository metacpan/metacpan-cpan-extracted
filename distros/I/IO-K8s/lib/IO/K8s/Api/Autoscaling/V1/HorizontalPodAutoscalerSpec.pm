package IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerSpec;
# ABSTRACT: specification of a horizontal pod autoscaler.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s maxReplicas => Int, 'required';


k8s minReplicas => Int;


k8s scaleTargetRef => 'Autoscaling::V1::CrossVersionObjectReference', 'required';


k8s targetCPUUtilizationPercentage => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerSpec - specification of a horizontal pod autoscaler.

=head1 VERSION

version 1.008

=head2 maxReplicas

maxReplicas is the upper limit for the number of pods that can be set by the autoscaler; cannot be smaller than MinReplicas.

=head2 minReplicas

minReplicas is the lower limit for the number of replicas to which the autoscaler can scale down.  It defaults to 1 pod.  minReplicas is allowed to be 0 if the alpha feature gate HPAScaleToZero is enabled and at least one Object or External metric is configured.  Scaling is active as long as at least one metric value is available.

=head2 scaleTargetRef

reference to scaled resource; horizontal pod autoscaler will learn the current resource consumption and will set the desired number of pods by using its Scale subresource.

=head2 targetCPUUtilizationPercentage

targetCPUUtilizationPercentage is the target average CPU utilization (represented as a percentage of requested CPU) over all the pods; if not specified the default autoscaling policy will be used.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
