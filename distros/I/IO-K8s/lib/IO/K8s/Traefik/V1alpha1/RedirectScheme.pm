package IO::K8s::Traefik::V1alpha1::RedirectScheme;
# ABSTRACT: RedirectScheme holds the redirect scheme middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s permanent => Bool;
k8s port      => Str;
k8s scheme    => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::RedirectScheme - RedirectScheme holds the redirect scheme middleware configuration.

=head1 VERSION

version 1.108

=head2 permanent

Permanent defines whether the redirection is permanent.
For HTTP GET requests a 301 is returned, otherwise a 308 is returned.

=head2 port

Port defines the port of the new URL.

=head2 scheme

Scheme defines the scheme of the new URL.

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
