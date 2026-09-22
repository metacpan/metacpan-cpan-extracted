package IO::K8s::CertManager::V1::NameConstraints;
# ABSTRACT: x.509 certificate NameConstraint extension which MUST NOT be used in a non-CA certificate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s critical  => Bool;
k8s excluded  => '+IO::K8s::CertManager::V1::NameConstraintItem';
k8s permitted => '+IO::K8s::CertManager::V1::NameConstraintItem';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::NameConstraints - x.509 certificate NameConstraint extension which MUST NOT be used in a non-CA certificate.

=head1 VERSION

version 1.108

=head2 critical

if true then the name constraints are marked critical.

=head2 excluded

Excluded contains the constraints which must be disallowed. Any name matching a
restriction in the excluded field is invalid regardless
of information appearing in the permitted

=head2 permitted

Permitted contains the constraints in which the names must be located.

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
