package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIVersions;
# ABSTRACT: APIVersions lists the versions that are available, to allow clients to discover the API at /api, which is the root path of the legacy v1 API.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s apiVersion => Str;


k8s kind => Str;


k8s serverAddressByClientCIDRs => ['Meta::V1::ServerAddressByClientCIDR'], 'required';


k8s versions => [Str], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIVersions - APIVersions lists the versions that are available, to allow clients to discover the API at /api, which is the root path of the legacy v1 API.

=head1 VERSION

version 1.006

=head2 apiVersion

APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

=head2 kind

Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

=head2 serverAddressByClientCIDRs

a map of client CIDR to server address that is serving this group. This is used to help clients reach servers in the most network-efficient way possible. Clients can use the appropriate server address as per the CIDR that they match. In case of multiple matches, clients should use the longest matching CIDR. The server returns only those CIDRs that it thinks that the client can match. For example: the master will return an internal IP CIDR only, if the client reaches the server using an internal IP. Server looks at X-Forwarded-For header or X-Real-Ip header or request.RemoteAddr (in that order) to get the client IP.

=head2 versions

versions are the api versions that are available.

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
