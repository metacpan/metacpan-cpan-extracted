package IO::K8s::CertManager;
# ABSTRACT: cert-manager CRD resource map provider for IO::K8s
our $VERSION = '1.008';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub resource_map {
    return {
        # cert-manager.io/v1
        Certificate        => 'CertManager::V1::Certificate',
        CertificateRequest => 'CertManager::V1::CertificateRequest',
        Issuer             => 'CertManager::V1::Issuer',
        ClusterIssuer      => 'CertManager::V1::ClusterIssuer',
        # acme.cert-manager.io/v1
        Order              => 'CertManager::V1::Order',
        Challenge          => 'CertManager::V1::Challenge',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager - cert-manager CRD resource map provider for IO::K8s

=head1 VERSION

version 1.008

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

    my $cert = $k8s->new_object('Certificate',
        metadata => { name => 'my-cert', namespace => 'default' },
        spec => {
            secretName => 'my-cert-tls',
            issuerRef  => { name => 'letsencrypt', kind => 'ClusterIssuer' },
            dnsNames   => ['example.com'],
        },
    );

    print $cert->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<cert-manager|https://cert-manager.io/> Custom
Resource Definitions. Registers 6 CRD classes covering C<cert-manager.io/v1>
and C<acme.cert-manager.io/v1>.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::CertManager') >> at runtime.

=head2 Included CRDs (cert-manager.io/v1)

Certificate (namespaced), CertificateRequest (namespaced), Issuer (namespaced),
ClusterIssuer (cluster-scoped)

=head2 Included CRDs (acme.cert-manager.io/v1)

Order (namespaced), Challenge (namespaced)

=head1 SEE ALSO

L<IO::K8s>

L<cert-manager documentation|https://cert-manager.io/docs/>

L<cert-manager API reference|https://cert-manager.io/docs/reference/api-docs/>

L<ACME issuer|https://cert-manager.io/docs/configuration/acme/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
