package IO::K8s::Cilium::V2::CiliumNetworkPolicyNodeStatus;
# ABSTRACT: CiliumNetworkPolicyNodeStatus is the status of a Cilium policy rule for a specific node.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s annotations         => { Str => 1 };
k8s enforcing           => Bool;
k8s error               => Str;
k8s lastUpdated         => Time;
k8s localPolicyRevision => Int;
k8s ok                  => Bool;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumNetworkPolicyNodeStatus - CiliumNetworkPolicyNodeStatus is the status of a Cilium policy rule for a specific node.

=head1 VERSION

version 1.108

=head2 annotations

Annotations corresponds to the Annotations in the ObjectMeta of the CNP
that have been realized on the node for CNP. That is, if a CNP has been
imported and has been assigned annotation X=Y by the user,
Annotations in CiliumNetworkPolicyNodeStatus will be X=Y once the
CNP that was imported corresponding to Annotation X=Y has been realized on
the node.

=head2 enforcing

Enforcing is set to true once all endpoints present at the time the
policy has been imported are enforcing this policy.

=head2 error

Error describes any error that occurred when parsing or importing the
policy, or realizing the policy for the endpoints to which it applies
on the node.

=head2 lastUpdated

LastUpdated contains the last time this status was updated

=head2 localPolicyRevision

Revision is the policy revision of the repository which first implemented
this policy.

=head2 ok

OK is true when the policy has been parsed and imported successfully
into the in-memory policy repository on the node.

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
