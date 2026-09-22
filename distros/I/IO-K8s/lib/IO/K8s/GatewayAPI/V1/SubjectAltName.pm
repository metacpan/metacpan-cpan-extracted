package IO::K8s::GatewayAPI::V1::SubjectAltName;
# ABSTRACT: SubjectAltName represents Subject Alternative Name.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s hostname => Str, { pattern => qr/^(\*\.)?[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s type     => Str, { required => 'schema', enum => [qw(Hostname URI)] };
k8s uri      => Str, { pattern => qr/^(([^:\/?#]+):)(\/\/([^\/?#]*))([^?#]*)(\?([^#]*))?(#(.*))?/ };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::SubjectAltName - SubjectAltName represents Subject Alternative Name.

=head1 VERSION

version 1.108

=head2 hostname

Hostname contains Subject Alternative Name specified in DNS name format.
Required when Type is set to Hostname, ignored otherwise.

Support: Core

=head2 type

Type determines the format of the Subject Alternative Name. Always required.

Support: Core

=head2 uri

URI contains Subject Alternative Name specified in a full URI format.
It MUST include both a scheme (e.g., "http" or "ftp") and a scheme-specific-part.
Common values include SPIFFE IDs like "spiffe://mycluster.example.com/ns/myns/sa/svc1sa".
Required when Type is set to URI, ignored otherwise.

Support: Core

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
