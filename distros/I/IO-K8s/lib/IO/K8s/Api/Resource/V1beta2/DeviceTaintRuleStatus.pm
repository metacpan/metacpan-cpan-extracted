package IO::K8s::Api::Resource::V1beta2::DeviceTaintRuleStatus;
# ABSTRACT: DeviceTaintRuleStatus provides information about an on-going pod eviction.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::DeviceTaintRuleStatus - DeviceTaintRuleStatus provides information about an on-going pod eviction.

=head1 VERSION

version 1.106

=head2 conditions

Conditions provide information about the state of the DeviceTaintRule and the cluster at some point in time, in a machine-readable and human-readable format. The following condition is currently defined as part of this API, more may get added:

- Type: EvictionInProgress
- Status: True if there are currently pods which need to be evicted, False otherwise (includes the effects which don't cause eviction).
- Reason: not specified, may change
- Message: includes information about number of pending pods and already evicted pods in a human-readable format, updated periodically, may change

For C<effect: None>, the condition above gets set once for each change to the spec, with the message containing information about what would happen if the effect was C<NoExecute>. This feedback can be used to decide whether changing the effect to C<NoExecute> will work as intended. It only gets set once to avoid having to constantly update the status.

Must have 8 or fewer entries.

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
