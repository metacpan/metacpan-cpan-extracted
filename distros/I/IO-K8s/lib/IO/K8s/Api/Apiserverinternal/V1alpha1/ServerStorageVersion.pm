package IO::K8s::Api::Apiserverinternal::V1alpha1::ServerStorageVersion;
# ABSTRACT: An API server instance reports the version it can decode and the version it encodes objects to when persisting objects in the backend.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s apiServerID => Str;


k8s decodableVersions => [Str];


k8s encodingVersion => Str;


k8s servedVersions => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apiserverinternal::V1alpha1::ServerStorageVersion - An API server instance reports the version it can decode and the version it encodes objects to when persisting objects in the backend.

=head1 VERSION

version 1.008

=head2 apiServerID

The ID of the reporting API server.

=head2 decodableVersions

The API server can decode objects encoded in these versions. The encodingVersion must be included in the decodableVersions.

=head2 encodingVersion

The API server encodes the object to this version when persisting it in the backend (e.g., etcd).

=head2 servedVersions

The API server can serve these versions. DecodableVersions must include all ServedVersions.

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
