package IO::K8s::Api::Resource::V1::DeviceTaint;
# ABSTRACT: The device this taint is attached to has the effect on any claim which does not tolerate the taint and, through the claim, to pods using the claim.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s effect => Str, 'required';


k8s key => Str, 'required';


k8s timeAdded => Time;


k8s value => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::DeviceTaint - The device this taint is attached to has the effect on any claim which does not tolerate the taint and, through the claim, to pods using the claim.

=head1 VERSION

version 1.106

=head2 effect

The effect of the taint on claims that do not tolerate the taint and through such claims on the pods using them. Valid effects are None, NoSchedule and NoExecute. PreferNoSchedule as used for nodes is not valid here. More effects may get added in the future. Consumers must treat unknown effects like None.

Possible enum values:

=over 4

=item * C<"NoExecute"> Evict any already-running pods that do not tolerate the device taint.

=item * C<"NoSchedule"> Do not allow new pods to schedule which use a tainted device unless they tolerate the taint, but allow all pods submitted to Kubelet without going through the scheduler to start, and allow all already-running pods to continue running.

=item * C<"None"> No effect, the taint is purely informational.

=back

=head2 key

The taint key to be applied to a device. Must be a label name.

=head2 timeAdded

TimeAdded represents the time at which the taint was added or (only in a DeviceTaintRule) the effect was modified. Added automatically during create or update if not set.

In addition, in a DeviceTaintRule a value provided during an update gets replaced with the current time if the provided value is the same as the old one and the new effect is different. Changing the key and/or value while keeping the effect unchanged is possible and does not update the time stamp because the eviction which uses it is either already started (NoExecute) or not started yet (NoEffect, NoSchedule).

=head2 value

The taint value corresponding to the taint key. Must be a label value.

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
