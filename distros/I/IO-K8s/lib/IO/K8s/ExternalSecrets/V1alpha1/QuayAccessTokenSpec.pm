package IO::K8s::ExternalSecrets::V1alpha1::QuayAccessTokenSpec;
# ABSTRACT: QuayAccessTokenSpec defines the desired state to generate a Quay access token.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s robotAccount      => Str, { required => 'schema' };
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector', { required => 'schema' };
k8s url               => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::QuayAccessTokenSpec - QuayAccessTokenSpec defines the desired state to generate a Quay access token.

=head1 VERSION

version 1.108

=head2 robotAccount

Name of the robot account you are federating with

=head2 serviceAccountRef

Name of the service account you are federating with

=head2 url

URL configures the Quay instance URL. Defaults to quay.io.

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
