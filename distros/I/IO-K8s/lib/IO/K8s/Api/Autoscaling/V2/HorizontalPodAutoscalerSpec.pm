package IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerSpec;
# ABSTRACT: HorizontalPodAutoscalerSpec describes the desired functionality of the HorizontalPodAutoscaler.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s behavior => 'Autoscaling::V2::HorizontalPodAutoscalerBehavior';


k8s maxReplicas => Int, 'required';


k8s metrics => ['Autoscaling::V2::MetricSpec'];


k8s minReplicas => Int;


k8s scaleTargetRef => 'Autoscaling::V2::CrossVersionObjectReference', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerSpec - HorizontalPodAutoscalerSpec describes the desired functionality of the HorizontalPodAutoscaler.

=head1 VERSION

version 1.006

=head2 behavior

behavior configures the scaling behavior of the target in both Up and Down directions (scaleUp and scaleDown fields respectively). If not set, the default HPAScalingRules for scale up and scale down are used.

=head2 maxReplicas

maxReplicas is the upper limit for the number of replicas to which the autoscaler can scale up. It cannot be less that minReplicas.

=head2 metrics

metrics contains the specifications for which to use to calculate the desired replica count (the maximum replica count across all metrics will be used).  The desired replica count is calculated multiplying the ratio between the target value and the current value by the current number of pods.  Ergo, metrics used must decrease as the pod count is increased, and vice-versa.  See the individual metric source types for more information about how each type of metric must respond. If not set, the default metric will be set to 80% average CPU utilization.

=head2 minReplicas

minReplicas is the lower limit for the number of replicas to which the autoscaler can scale down.  It defaults to 1 pod.  minReplicas is allowed to be 0 if the alpha feature gate HPAScaleToZero is enabled and at least one Object or External metric is configured.  Scaling is active as long as at least one metric value is available.

=head2 scaleTargetRef

scaleTargetRef points to the target resource to scale, and is used to the pods for which metrics should be collected, as well as to actually change the replica count.

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
