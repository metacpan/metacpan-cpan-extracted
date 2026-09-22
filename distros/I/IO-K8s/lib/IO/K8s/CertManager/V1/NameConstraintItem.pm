package IO::K8s::CertManager::V1::NameConstraintItem;
# ABSTRACT: Permitted contains the constraints in which the names must be located.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s dnsDomains     => [Str];
k8s emailAddresses => [Str];
k8s ipRanges       => [Str];
k8s uriDomains     => [Str];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::NameConstraintItem - Permitted contains the constraints in which the names must be located.

=head1 VERSION

version 1.108

=head2 dnsDomains

DNSDomains is a list of DNS domains that are permitted or excluded.

=head2 emailAddresses

EmailAddresses is a list of Email Addresses that are permitted or excluded.

=head2 ipRanges

IPRanges is a list of IP Ranges that are permitted or excluded.
This should be a valid CIDR notation.

=head2 uriDomains

URIDomains is a list of URI domains that are permitted or excluded.

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
