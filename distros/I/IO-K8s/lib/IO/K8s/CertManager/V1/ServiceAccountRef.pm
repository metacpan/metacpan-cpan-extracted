package IO::K8s::CertManager::V1::ServiceAccountRef;
# ABSTRACT: A reference to a service account that will be used to request a bound token (also known as "projected token").
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s audiences => [Str];
k8s name      => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ServiceAccountRef - A reference to a service account that will be used to request a bound token (also known as "projected token").

=head1 VERSION

version 1.108

=head2 audiences

TokenAudiences is an optional list of audiences to include in the
token passed to AWS. The default token consisting of the issuer's namespace
and name is always included.
If unset the audience defaults to `sts.amazonaws.com`.

=head2 name

Name of the ServiceAccount used to request a token.

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
