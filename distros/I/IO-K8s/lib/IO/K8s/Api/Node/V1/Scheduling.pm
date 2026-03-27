package IO::K8s::Api::Node::V1::Scheduling;
# ABSTRACT: Scheduling specifies the scheduling constraints for nodes supporting a RuntimeClass.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s nodeSelector => { Str => 1 };


k8s tolerations => ['Core::V1::Toleration'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Node::V1::Scheduling - Scheduling specifies the scheduling constraints for nodes supporting a RuntimeClass.

=head1 VERSION

version 1.100

=head2 nodeSelector

nodeSelector lists labels that must be present on nodes that support this RuntimeClass. Pods using this RuntimeClass can only be scheduled to a node matched by this selector. The RuntimeClass nodeSelector is merged with a pod's existing nodeSelector. Any conflicts will cause the pod to be rejected in admission.

=head2 tolerations

tolerations are appended (excluding duplicates) to pods running with this RuntimeClass during admission, effectively unioning the set of nodes tolerated by the pod and the RuntimeClass.

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
