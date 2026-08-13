package IO::K8s::Api::Core::V1::PodCondition;
# ABSTRACT: PodCondition contains details for the current condition of this pod.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s lastProbeTime => Time;


k8s lastTransitionTime => Time;


k8s message => Str;


k8s observedGeneration => Int;


k8s reason => Str;


k8s status => Str, 'required';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodCondition - PodCondition contains details for the current condition of this pod.

=head1 VERSION

version 1.106

=head2 lastProbeTime

Last time we probed the condition.

=head2 lastTransitionTime

Last time the condition transitioned from one status to another.

=head2 message

Human-readable message indicating details about last transition.

=head2 observedGeneration

If set, this represents the .metadata.generation that the pod condition was set based upon.

=head2 reason

Unique, one-word, CamelCase reason for the condition's last transition.

=head2 status

Status is the status of the condition. Can be True, False, Unknown. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions

=head2 type

Type is the type of the condition. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions

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
