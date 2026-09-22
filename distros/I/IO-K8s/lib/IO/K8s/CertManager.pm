package IO::K8s::CertManager;
# ABSTRACT: cert-manager CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v1.21.1' }  # cert-manager/cert-manager

# Upstream CRD manifests for the pinned upstream_version, consumed by
# maint/crd-drift-check.pl. Data only -- no fetching here. cert-manager
# ships one released multi-document CRD bundle as a GitHub release asset;
# `base` + the single `files` entry is that asset URL, cached under
# spec/crd/CertManager/.
sub crd_sources {
    my $v = __PACKAGE__->upstream_version;
    return {
        status => 'ok',
        base   => "https://github.com/cert-manager/cert-manager/releases/download/$v",
        files  => [
            'cert-manager.crds.yaml',
        ],
    };
}

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

version 1.108

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
and C<acme.cert-manager.io/v1>, modeled to full depth: C<spec> (and, where
upstream declares one, C<status>) is a typed object graph of 71 further
C<IO::K8s::CertManager::V1::*> classes, one per upstream Go structure, named
after the upstream Go types
(L<IO::K8s::CertManager::V1::Certificate|IO::K8s::CertManager::V1::Certificate>'s
C<issuerRef> is an
L<IO::K8s::CertManager::V1::IssuerReference|IO::K8s::CertManager::V1::IssuerReference>,
and so on down) rather than an opaque hashref. Embedded core and Gateway API
types are referenced, not re-modeled. A Go type used by more than one Kind
(C<SecretKeySelector>, C<IssuerReference>, C<LocalObjectReference>,
C<ServiceAccountRef>, the whole C<ACMEChallengeSolver> family) is one shared
class, not a copy per Kind -- most notably C<IssuerSpec>/C<IssuerStatus>
themselves, the literal same Go types embedded by both C<Issuer> and
C<ClusterIssuer>, so those two Kinds share their entire spec/status tree.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::CertManager') >> at runtime.

=head2 Included CRDs (cert-manager.io/v1)

=over 4

=item * C<Certificate> (namespaced) -- a human-readable request that an up to date,
signed X.509 certificate be kept stored in the Kubernetes Secret named in
C<spec.secretName>.

=item * C<CertificateRequest> (namespaced) -- the single-shot request cert-manager
generates from a C<Certificate> to actually obtain one signed certificate from the
referenced issuer; disposable, and re-created on each renewal.

=item * C<Issuer> (namespaced) -- a certificate-issuing authority (ACME, CA, Vault,
self-signed, ...), usable only by C<Certificate>s in its own namespace.

=item * C<ClusterIssuer> (cluster-scoped) -- the same issuer abstraction as C<Issuer>,
but referenceable from C<Certificate>s in any namespace. C<Issuer> and C<ClusterIssuer>
embed the identical upstream C<IssuerSpec>/C<IssuerStatus> Go types, which is why this
distribution models them as one shared spec/status class tree (see above).

=back

=head2 Included CRDs (acme.cert-manager.io/v1)

=over 4

=item * C<Order> (namespaced) -- represents a single ACME certificate order, created
automatically once a C<CertificateRequest> referencing an ACME issuer exists.

=item * C<Challenge> (namespaced) -- represents one ACME challenge (HTTP-01, DNS-01,
...) that must be completed to authorize a single DNS name/identifier within an
C<Order>.

=back

=head1 SEE ALSO

L<IO::K8s>

L<cert-manager documentation|https://cert-manager.io/docs/>

L<cert-manager API reference|https://cert-manager.io/docs/reference/api-docs/>

L<ACME issuer|https://cert-manager.io/docs/configuration/acme/>

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
