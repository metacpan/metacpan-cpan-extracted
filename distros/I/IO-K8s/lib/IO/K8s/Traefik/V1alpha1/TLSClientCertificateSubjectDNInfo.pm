package IO::K8s::Traefik::V1alpha1::TLSClientCertificateSubjectDNInfo;
# ABSTRACT: Subject defines the client certificate subject details to add to the X-Forwarded-Tls-Client-Cert-Info header.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s commonName         => Bool;
k8s country            => Bool;
k8s domainComponent    => Bool;
k8s locality           => Bool;
k8s organization       => Bool;
k8s organizationalUnit => Bool;
k8s province           => Bool;
k8s serialNumber       => Bool;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TLSClientCertificateSubjectDNInfo - Subject defines the client certificate subject details to add to the X-Forwarded-Tls-Client-Cert-Info header.

=head1 VERSION

version 1.108

=head2 commonName

CommonName defines whether to add the organizationalUnit information into the subject.

=head2 country

Country defines whether to add the country information into the subject.

=head2 domainComponent

DomainComponent defines whether to add the domainComponent information into the subject.

=head2 locality

Locality defines whether to add the locality information into the subject.

=head2 organization

Organization defines whether to add the organization information into the subject.

=head2 organizationalUnit

OrganizationalUnit defines whether to add the organizationalUnit information into the subject.

=head2 province

Province defines whether to add the province information into the subject.

=head2 serialNumber

SerialNumber defines whether to add the serialNumber information into the subject.

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
