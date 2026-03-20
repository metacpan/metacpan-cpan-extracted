package IO::K8s::Api::Batch::V1::PodFailurePolicyRule;
# ABSTRACT: PodFailurePolicyRule describes how a pod failure is handled when the requirements are met. One of onExitCodes and onPodConditions, but not both, can be used in each rule.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s action => Str, 'required';


k8s onExitCodes => 'Batch::V1::PodFailurePolicyOnExitCodesRequirement';


k8s onPodConditions => ['Batch::V1::PodFailurePolicyOnPodConditionsPattern'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Batch::V1::PodFailurePolicyRule - PodFailurePolicyRule describes how a pod failure is handled when the requirements are met. One of onExitCodes and onPodConditions, but not both, can be used in each rule.

=head1 VERSION

version 1.009

=head2 action

Specifies the action taken on a pod failure when the requirements are satisfied. Possible values are:

- FailJob: indicates that the pod's job is marked as Failed and all running pods are terminated.
- FailIndex: indicates that the pod's index is marked as Failed and will not be restarted. This value is beta-level. It can be used when the `JobBackoffLimitPerIndex` feature gate is enabled (enabled by default).
- Ignore: indicates that the counter towards the .backoffLimit is not incremented and a replacement pod is created.
- Count: indicates that the pod is handled in the default way - the counter towards the .backoffLimit is incremented.

Additional values are considered to be added in the future. Clients should react to an unknown action by skipping the rule.

=head2 onExitCodes

Represents the requirement on the container exit codes.

=head2 onPodConditions

Represents the requirement on the pod conditions. The requirement is represented as a list of pod condition patterns. The requirement is satisfied if at least one pattern matches an actual pod condition. At most 20 elements are allowed.

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
