package IO::K8s::ExternalSecrets;
# ABSTRACT: external-secrets CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v2.10.0' }  # external-secrets/external-secrets

# Upstream CRD manifests for the pinned upstream_version, consumed by
# maint/crd-drift-check.pl. Data only -- no fetching happens here. `base`
# + each `files` entry is the raw manifest URL; the checker caches each
# under spec/crd/ExternalSecrets/ (path separators flattened to '_').
sub crd_sources {
    my $v = __PACKAGE__->upstream_version;
    return {
        status => 'ok',
        base   => "https://raw.githubusercontent.com/external-secrets/external-secrets/$v/deploy/crds",
        files  => [
            'bundle.yaml',
        ],
    };
}

sub resource_map {
    return {
        # external-secrets.io/v1 -- the graduated, served+storage version for
        # all four of these Kinds at the pin (v1beta1 still ships in the CRD
        # manifest but is served: false everywhere -- not modeled, see POD).
        ExternalSecret        => 'ExternalSecrets::V1::ExternalSecret',
        SecretStore           => 'ExternalSecrets::V1::SecretStore',
        ClusterSecretStore    => 'ExternalSecrets::V1::ClusterSecretStore',
        ClusterExternalSecret => 'ExternalSecrets::V1::ClusterExternalSecret',
        # external-secrets.io/v1alpha1 -- PushSecret has not graduated to v1
        # at this pin; v1alpha1 is its only served version.
        PushSecret            => 'ExternalSecrets::V1alpha1::PushSecret',
        # external-secrets.io/v1alpha1 -- ClusterPushSecret is the
        # cluster-scoped sibling of PushSecret; its spec wraps the same
        # PushSecretSpec tree (spec.pushSecretSpec) rather than re-modeling it.
        ClusterPushSecret     => 'ExternalSecrets::V1alpha1::ClusterPushSecret',
        # generators.external-secrets.io/v1alpha1 -- a separate API group
        # (upstream Go package apis/generators/v1alpha1, not
        # apis/externalsecrets/*) from the six Kinds above, despite sharing
        # both the "v1alpha1" version string and the V1alpha1 namespace with
        # PushSecret's own group -- the same one-provider/two-groups layout
        # CertManager already uses for cert-manager.io/v1 + acme.cert-manager.io/v1,
        # disambiguated by each class's own api_version rather than a path
        # segment (k113).
        ACRAccessToken => 'ExternalSecrets::V1alpha1::ACRAccessToken',
        BeyondtrustWorkloadCredentialsDynamicSecret => 'ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecret',
        CloudsmithAccessToken => 'ExternalSecrets::V1alpha1::CloudsmithAccessToken',
        # ClusterGenerator is the cluster-scoped, 17-member union kind: its
        # spec.generator.<x>Spec fields each reference the SAME *Spec class
        # the corresponding standalone Kind below uses for its own spec
        # (verified byte-identical upstream, the same way ClusterExternalSecret/
        # ClusterPushSecret reuse their sibling Kind's Spec) -- not a parallel
        # tree. It has no GeneratorState member: that Kind is controller state,
        # not a generator plugin, and is not part of the union upstream either.
        ClusterGenerator => 'ExternalSecrets::V1alpha1::ClusterGenerator',
        ECRAuthorizationToken => 'ExternalSecrets::V1alpha1::ECRAuthorizationToken',
        Fake => 'ExternalSecrets::V1alpha1::Fake',
        GCRAccessToken => 'ExternalSecrets::V1alpha1::GCRAccessToken',
        GeneratorState => 'ExternalSecrets::V1alpha1::GeneratorState',
        GithubAccessToken => 'ExternalSecrets::V1alpha1::GithubAccessToken',
        GitlabDeployToken => 'ExternalSecrets::V1alpha1::GitlabDeployToken',
        Grafana => 'ExternalSecrets::V1alpha1::Grafana',
        MFA => 'ExternalSecrets::V1alpha1::MFA',
        Password => 'ExternalSecrets::V1alpha1::Password',
        QuayAccessToken => 'ExternalSecrets::V1alpha1::QuayAccessToken',
        SSHKey => 'ExternalSecrets::V1alpha1::SSHKey',
        STSSessionToken => 'ExternalSecrets::V1alpha1::STSSessionToken',
        UUID => 'ExternalSecrets::V1alpha1::UUID',
        VaultDynamicSecret => 'ExternalSecrets::V1alpha1::VaultDynamicSecret',
        Webhook => 'ExternalSecrets::V1alpha1::Webhook',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets - external-secrets CRD resource map provider for IO::K8s

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $store = $k8s->new_object('SecretStore',
        metadata => { name => 'aws-store', namespace => 'default' },
        spec => {
            provider => {
                aws => {
                    service => 'SecretsManager',
                    region  => 'eu-west-1',
                    auth    => { jwt => { serviceAccountRef => { name => 'my-sa' } } },
                },
            },
        },
    );

    my $es = $k8s->new_object('ExternalSecret',
        metadata => { name => 'db-creds', namespace => 'default' },
        spec => {
            secretStoreRef => { name => 'aws-store', kind => 'SecretStore' },
            target         => { name => 'db-creds' },
            data           => [ { secretKey => 'password', remoteRef => { key => 'prod/db/password' } } ],
        },
    );

    print $es->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<external-secrets|https://external-secrets.io/>
Custom Resource Definitions. Registers 25 C<resource_map> entries: six
Kinds in C<external-secrets.io> and 19 Kinds in
C<generators.external-secrets.io/v1alpha1> (see
L</"Included Kinds (generators.external-secrets.io/v1alpha1)"> below),
matching upstream external-secrets v2.10.0.

C<generators.external-secrets.io> is a separate upstream API group (Go
package C<apis/generators/v1alpha1>, not C<apis/externalsecrets/*>) from
the two above, despite sharing both the C<v1alpha1> version string and,
in this distribution, the C<V1alpha1> Perl namespace with C<PushSecret>'s
own group -- the same one-provider/two-groups layout
L<IO::K8s::CertManager> already uses for C<cert-manager.io/v1> +
C<acme.cert-manager.io/v1>. Each class's own C<api_version> carries the
distinction, not a path segment.

Every Kind is modeled to full depth: C<spec> (and, where upstream declares
one, C<status>) is a typed object graph of further
C<IO::K8s::ExternalSecrets::V1::*> / C<IO::K8s::ExternalSecrets::V1alpha1::*>
classes, one per upstream Go structure, named after the upstream Go types
(C<github.com/external-secrets/external-secrets/apis/externalsecrets/v1>
and C<.../v1alpha1>). Embedded core Kubernetes types are referenced, not
re-modeled -- e.g. a condition list reuses a shipped C<Core::V1>/C<Meta::V1>
condition-shaped class rather than a per-Kind copy (D5's C<reuse_core>), and
several small cross-provider reference structs -- L<IO::K8s::ExternalSecrets::V1::SecretKeySelector>
(external-secrets' own, cross-namespace-capable variant, not
C<Core::V1::SecretKeySelector>), L<IO::K8s::ExternalSecrets::V1::ServiceAccountSelector>,
L<IO::K8s::ExternalSecrets::V1::CAProvider> -- are the literal same upstream
Go type referenced from dozens of places (every provider's own auth block,
for the first two) rather than one copy per backend.

C<SecretStore> and C<ClusterSecretStore> embed the identical upstream
C<SecretStoreSpec>/C<SecretStoreStatus> Go types (verified byte-identical
schema before writing these classes) and so share the very same
L<IO::K8s::ExternalSecrets::V1::SecretStoreSpec> class -- including its
C<provider> field, L<IO::K8s::ExternalSecrets::V1::SecretStoreProvider>,
a 43-member union of every backend the CRD's C<MinProperties=1>/
C<MaxProperties=1> validation restricts to exactly one of (AWS, Azure Key
Vault, HashiCorp Vault, GCP Secret Manager, Kubernetes, Akeyless, and so on
-- see L</"Included Kinds (external-secrets.io/v1)"> below for the full
list), each backend's own auth/reference structs modeled to full depth in
turn. C<ClusterExternalSecret> similarly embeds the literal same
C<ExternalSecretSpec> Go type C<ExternalSecret> uses for its own C<spec>
(as C<spec.externalSecretSpec>), so
L<IO::K8s::ExternalSecrets::V1::ExternalSecretSpec> and everything below it
(C<ExternalSecretData>, C<ExternalSecretTarget>,
L<IO::K8s::ExternalSecrets::V1::ExternalSecretTemplate>, ...) is one shared
tree of classes reachable from both Kinds. C<ClusterPushSecret> mirrors
that: it embeds the literal same C<PushSecretSpec> Go type C<PushSecret>
uses for its own C<spec> (as C<spec.pushSecretSpec>), so
L<IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec> and everything below
it is shared rather than re-modeled; its own wrapper fields
(C<namespaceSelectors>, C<pushSecretMetadata>, C<pushSecretName>,
C<refreshTime>) live on
L<IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretSpec>. Its
C<status.conditions> reuses the same L<IO::K8s::Api::Core::V1::NamespaceCondition>
class C<PushSecretStatus> already reuses for the identical
C<PushSecretStatusCondition> Go type.

B<Scope (D9):> C<ClusterSecretStore>, C<ClusterExternalSecret>,
C<ClusterPushSecret> and C<ClusterGenerator> are cluster-scoped upstream
(C<spec.scope: Cluster>) and do not compose L<IO::K8s::Role::Namespaced>;
C<ExternalSecret>, C<SecretStore> and C<PushSecret> are namespaced upstream
and do.

B<Served versions:> the CRD manifest at this pin still ships a deprecated
C<external-secrets.io/v1beta1> track for C<ExternalSecret>, C<SecretStore>
and C<ClusterSecretStore> (and a deprecated C<v1beta1> for
C<ClusterExternalSecret>), but every one of those entries is
C<served: false> in the manifest -- an API server at this upstream version
would reject a request naming it. Only the served version of each Kind is
modeled: C<v1> for C<ExternalSecret>, C<SecretStore>, C<ClusterSecretStore>
and C<ClusterExternalSecret>; C<v1alpha1> for C<PushSecret> and
C<ClusterPushSecret>, neither of which has graduated to C<v1> at this pin.

Not loaded by default -- opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::ExternalSecrets') >> at
runtime.

=head2 Included Kinds (external-secrets.io/v1)

ExternalSecret, SecretStore, ClusterSecretStore, ClusterExternalSecret

C<SecretStore>/C<ClusterSecretStore>'s C<spec.provider> backends: AWS,
AzureKV, Akeyless, BitwardenSecretsManager, Vault, OVHcloud, GCPSM, Oracle,
IBM, YandexCertificateManager, YandexLockbox, Github, GitLab, OnePassword,
OnePasswordSDK, Webhook, Kubernetes, CRD, Fake, Senhasegura, Scaleway,
Doppler, Previder, Onboardbase, KeeperSecurity, Conjur, Delinea,
SecretServer, Chef, Pulumi, Fortanix, PasswordDepot, Passbolt, DVLS,
Infisical, Beyondtrust, BeyondtrustWorkloadCredentials, CloudruSM,
Volcengine, Ngrok, Barbican, NebiusMysterybox, OpenBao.

=head2 Included Kinds (external-secrets.io/v1alpha1)

PushSecret, ClusterPushSecret

=head2 Included Kinds (generators.external-secrets.io/v1alpha1)

ClusterGenerator (cluster-scoped), ACRAccessToken,
BeyondtrustWorkloadCredentialsDynamicSecret,
CloudsmithAccessToken, ECRAuthorizationToken, Fake, GCRAccessToken,
GeneratorState, GithubAccessToken, GitlabDeployToken, Grafana, MFA,
Password, QuayAccessToken, SSHKey, STSSessionToken, UUID,
VaultDynamicSecret, Webhook.

Where an upstream schema was verified byte-identical to an existing
C<external-secrets.io/v1> provider structure, the generator reuses that
same class rather than a private copy: C<VaultDynamicSecret>'s C<provider>
is the literal same L<IO::K8s::ExternalSecrets::V1::VaultProvider>
C<SecretStore>'s Vault backend uses, and
C<BeyondtrustWorkloadCredentialsDynamicSecret>'s C<provider> is the
literal same L<IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider>.
C<ECRAuthorizationToken> and C<STSSessionToken> both reuse
L<IO::K8s::ExternalSecrets::V1::AWSAuth> for their C<auth> field.
C<GeneratorState> reuses L<IO::K8s::Api::Core::V1::NamespaceCondition> for
C<status.conditions>, the same way C<PushSecretStatus> does. A handful of
generator-only fields narrow the usual cross-namespace
C<SecretKeySelector> down to a same-namespace, two-field
L<IO::K8s::ExternalSecrets::V1alpha1::SecretRef> (C<Grafana>'s
C<auth.basic.password>/C<auth.token>, C<Webhook>'s C<secrets[].secretRef>).

C<ClusterGenerator> is modeled as the cluster-scoped generator union. Its
C<spec.generator> has 17 members, each reusing the corresponding standalone
Kind's C<Spec> class; C<GeneratorState> is controller state rather than a
generator plugin and is not a union member.

=head1 SEE ALSO

L<IO::K8s>

L<external-secrets documentation|https://external-secrets.io/latest/>

L<external-secrets API reference|https://external-secrets.io/latest/api/spec/>

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
