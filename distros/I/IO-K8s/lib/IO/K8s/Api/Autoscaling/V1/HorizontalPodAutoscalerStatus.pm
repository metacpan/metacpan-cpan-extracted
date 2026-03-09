package IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerStatus;
# ABSTRACT: current status of a horizontal pod autoscaler
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s currentCPUUtilizationPercentage => Int;


k8s currentReplicas => Int, 'required';


k8s desiredReplicas => Int, 'required';


k8s lastScaleTime => Time;


k8s observedGeneration => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerStatus - current status of a horizontal pod autoscaler

=head1 VERSION

version 1.008

=head2 currentCPUUtilizationPercentage

currentCPUUtilizationPercentage is the current average CPU utilization over all pods, represented as a percentage of requested CPU, e.g. 70 means that an average pod is using now 70% of its requested CPU.

=head2 currentReplicas

currentReplicas is the current number of replicas of pods managed by this autoscaler.

=head2 desiredReplicas

desiredReplicas is the  desired number of replicas of pods managed by this autoscaler.

=head2 lastScaleTime

lastScaleTime is the last time the HorizontalPodAutoscaler scaled the number of pods; used by the autoscaler to control how often the number of pods is changed.

=head2 observedGeneration

observedGeneration is the most recent generation observed by this autoscaler.

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
