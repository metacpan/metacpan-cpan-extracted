package IO::K8s::Api::Networking::V1::NetworkPolicyPeer;
# ABSTRACT: NetworkPolicyPeer describes a peer to allow traffic to/from. Only certain combinations of fields are allowed
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s ipBlock => 'Networking::V1::IPBlock';


k8s namespaceSelector => 'Meta::V1::LabelSelector';


k8s podSelector => 'Meta::V1::LabelSelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Networking::V1::NetworkPolicyPeer - NetworkPolicyPeer describes a peer to allow traffic to/from. Only certain combinations of fields are allowed

=head1 VERSION

version 1.006

=head2 ipBlock

ipBlock defines policy on a particular IPBlock. If this field is set then neither of the other fields can be.

=head2 namespaceSelector

namespaceSelector selects namespaces using cluster-scoped labels. This field follows standard label selector semantics; if present but empty, it selects all namespaces. If podSelector is also set, then the NetworkPolicyPeer as a whole selects the pods matching podSelector in the namespaces selected by namespaceSelector. Otherwise it selects all pods in the namespaces selected by namespaceSelector.

=head2 podSelector

podSelector is a label selector which selects pods. This field follows standard label selector semantics; if present but empty, it selects all pods. If namespaceSelector is also set, then the NetworkPolicyPeer as a whole selects the pods matching podSelector in the Namespaces selected by NamespaceSelector. Otherwise it selects the pods matching podSelector in the policy's own namespace.

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
