package IO::K8s::Api::Discovery::V1::Endpoint;
# ABSTRACT: Endpoint represents a single logical "backend" implementing a service.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s addresses => [Str], 'required';


k8s conditions => 'Discovery::V1::EndpointConditions';


k8s deprecatedTopology => { Str => 1 };


k8s hints => 'Discovery::V1::EndpointHints';


k8s hostname => Str;


k8s nodeName => Str;


k8s targetRef => 'Core::V1::ObjectReference';


k8s zone => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Discovery::V1::Endpoint - Endpoint represents a single logical "backend" implementing a service.

=head1 VERSION

version 1.009

=head2 addresses

addresses of this endpoint. The contents of this field are interpreted according to the corresponding EndpointSlice addressType field. Consumers must handle different types of addresses in the context of their own capabilities. This must contain at least one address but no more than 100. These are all assumed to be fungible and clients may choose to only use the first element. Refer to: https://issue.k8s.io/106267

=head2 conditions

conditions contains information about the current status of the endpoint.

=head2 deprecatedTopology

deprecatedTopology contains topology information part of the v1beta1 API. This field is deprecated, and will be removed when the v1beta1 API is removed (no sooner than kubernetes v1.24).  While this field can hold values, it is not writable through the v1 API, and any attempts to write to it will be silently ignored. Topology information can be found in the zone and nodeName fields instead.

=head2 hints

hints contains information associated with how an endpoint should be consumed.

=head2 hostname

hostname of this endpoint. This field may be used by consumers of endpoints to distinguish endpoints from each other (e.g. in DNS names). Multiple endpoints which use the same hostname should be considered fungible (e.g. multiple A values in DNS). Must be lowercase and pass DNS Label (RFC 1123) validation.

=head2 nodeName

nodeName represents the name of the Node hosting this endpoint. This can be used to determine endpoints local to a Node.

=head2 targetRef

targetRef is a reference to a Kubernetes object that represents this endpoint.

=head2 zone

zone is the name of the Zone this endpoint exists in.

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
