package IO::K8s::Api::Apps::V1::DeploymentSpec;
# ABSTRACT: DeploymentSpec is the specification of the desired behavior of the Deployment.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s minReadySeconds => Int;


k8s paused => Bool;


k8s progressDeadlineSeconds => Int;


k8s replicas => Int;


k8s revisionHistoryLimit => Int;


k8s selector => 'Meta::V1::LabelSelector', 'required';


k8s strategy => 'Apps::V1::DeploymentStrategy';


k8s template => 'Core::V1::PodTemplateSpec', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::DeploymentSpec - DeploymentSpec is the specification of the desired behavior of the Deployment.

=head1 VERSION

version 1.100

=head2 minReadySeconds

Minimum number of seconds for which a newly created pod should be ready without any of its container crashing, for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready)

=head2 paused

Indicates that the deployment is paused.

=head2 progressDeadlineSeconds

The maximum time in seconds for a deployment to make progress before it is considered to be failed. The deployment controller will continue to process failed deployments and a condition with a ProgressDeadlineExceeded reason will be surfaced in the deployment status. Note that progress will not be estimated during the time a deployment is paused. Defaults to 600s.

=head2 replicas

Number of desired pods. This is a pointer to distinguish between explicit zero and not specified. Defaults to 1.

=head2 revisionHistoryLimit

The number of old ReplicaSets to retain to allow rollback. This is a pointer to distinguish between explicit zero and not specified. Defaults to 10.

=head2 selector

Label selector for pods. Existing ReplicaSets whose pods are selected by this will be the ones affected by this deployment. It must match the pod template's labels.

=head2 strategy

The deployment strategy to use to replace existing pods with new ones.

=head2 template

Template describes the pods that will be created. The only allowed template.spec.restartPolicy value is "Always".

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
