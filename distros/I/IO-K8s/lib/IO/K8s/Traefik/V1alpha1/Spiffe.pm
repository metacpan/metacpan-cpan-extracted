package IO::K8s::Traefik::V1alpha1::Spiffe;
# ABSTRACT: Spiffe defines the SPIFFE configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ids         => [Str];
k8s trustDomain => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Spiffe - Spiffe defines the SPIFFE configuration.

=head1 VERSION

version 1.108

=head2 ids

IDs defines the allowed SPIFFE IDs (takes precedence over the SPIFFE TrustDomain).

=head2 trustDomain

TrustDomain defines the allowed SPIFFE trust domain.

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
