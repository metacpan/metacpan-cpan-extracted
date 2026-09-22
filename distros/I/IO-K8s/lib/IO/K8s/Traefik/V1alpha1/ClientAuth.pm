package IO::K8s::Traefik::V1alpha1::ClientAuth;
# ABSTRACT: ClientAuth defines the server's policy for TLS Client Authentication.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientAuthType => Str, { enum => [qw(NoClientCert RequestClientCert RequireAnyClientCert VerifyClientCertIfGiven RequireAndVerifyClientCert)] };
k8s secretNames    => [Str];



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ClientAuth - ClientAuth defines the server's policy for TLS Client Authentication.

=head1 VERSION

version 1.108

=head2 clientAuthType

ClientAuthType defines the client authentication type to apply.

=head2 secretNames

SecretNames defines the names of the referenced Kubernetes Secret storing certificate details.

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
