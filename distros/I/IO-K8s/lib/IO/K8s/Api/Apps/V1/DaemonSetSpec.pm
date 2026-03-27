package IO::K8s::Api::Apps::V1::DaemonSetSpec;
# ABSTRACT: DaemonSetSpec is the specification of a daemon set.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s minReadySeconds => Int;


k8s revisionHistoryLimit => Int;


k8s selector => 'Meta::V1::LabelSelector', 'required';


k8s template => 'Core::V1::PodTemplateSpec', 'required';


k8s updateStrategy => 'Apps::V1::DaemonSetUpdateStrategy';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::DaemonSetSpec - DaemonSetSpec is the specification of a daemon set.

=head1 VERSION

version 1.100

=head2 minReadySeconds

The minimum number of seconds for which a newly created DaemonSet pod should be ready without any of its container crashing, for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready).

=head2 revisionHistoryLimit

The number of old history to retain to allow rollback. This is a pointer to distinguish between explicit zero and not specified. Defaults to 10.

=head2 selector

A label query over pods that are managed by the daemon set. Must match in order to be controlled. It must match the pod template's labels. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors

=head2 template

An object that describes the pod that will be created. The DaemonSet will create exactly one copy of this pod on every node that matches the template's node selector (or on every node if no node selector is specified). The only allowed template.spec.restartPolicy value is "Always". More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#pod-template

=head2 updateStrategy

An update strategy to replace existing DaemonSet pods with new pods.

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
