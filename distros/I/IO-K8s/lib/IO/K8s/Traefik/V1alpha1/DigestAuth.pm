package IO::K8s::Traefik::V1alpha1::DigestAuth;
# ABSTRACT: DigestAuth holds the digest auth middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s headerField  => Str;
k8s realm        => Str;
k8s removeHeader => Bool;
k8s secret       => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::DigestAuth - DigestAuth holds the digest auth middleware configuration.

=head1 VERSION

version 1.108

=head2 headerField

HeaderField defines a header field to store the authenticated user.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/digestauth/#headerfield

=head2 realm

Realm allows the protected resources on a server to be partitioned into a set of protection spaces, each with its own authentication scheme.
Default: traefik.

=head2 removeHeader

RemoveHeader defines whether to remove the authorization header before forwarding the request to the backend.

=head2 secret

Secret is the name of the referenced Kubernetes Secret containing user credentials.

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
