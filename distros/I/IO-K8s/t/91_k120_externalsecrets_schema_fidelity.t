#!/usr/bin/env perl
# k120: five generators.external-secrets.io classes from k113 disagreed with
# the upstream CRD. Verified against
# external-secrets v2.10.0's deploy/crds/bundle.yaml -- every literal below
# is quoted from that manifest, so this test needs no network and no
# spec/crd/ cache (which is gitignored and absent from a clean checkout).
#
# The five split into TWO impact classes, and this file tests each in the way
# that can actually fail:
#
#   1. SecretRef's missing key/name patterns were a CONSTRUCTION-TIME loss.
#      `pattern` is enforced as a Type::Tiny constraint (see the k8s option
#      docs in IO::K8s::Resource), so while it was missing an invalid value
#      was accepted client-side and only rejected by the API server. Tested
#      by constructing: a bad value must die, a good one must live.
#
#   2. The other four were SCHEMA-FIDELITY losses -- `required => 'schema'`
#      and `default` are registry-only, never applied at construction or
#      serialization, so no accessor test can see them. They are visible
#      exactly where they are consumed: the CRD that Class->to_crd builds.
#      Tested through TO_JSON, i.e. the structure that would be applied to a
#      cluster, not the object's internal slots.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;
use IO::K8s::ExternalSecrets;
use IO::K8s::ExternalSecrets::V1alpha1::SecretRef;

my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

# The CRD node reached by Class->to_crd, as plain wire data.
sub spec_schema {
    my ($kind) = @_;
    my $class = $k8s->expand_class($kind);
    return $class->to_crd->TO_JSON
        ->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{spec};
}

# --- 1. SecretRef: a construction-time constraint, not a schema note ------
#
# bundle.yaml declares the SAME two patterns at all three places this class
# models -- grafanas .spec.auth.token, grafanas .spec.auth.basic.password
# and webhooks .spec.secrets[].secretRef:
#   key:  pattern: ^[-._a-zA-Z0-9]+$
#   name: pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$
subtest 'SecretRef enforces the CRD key/name patterns at construction' => sub {
    my $class = 'IO::K8s::ExternalSecrets::V1alpha1::SecretRef';

    lives_ok {
        my $ref = $class->new(key => 'my-token.key_1', name => 'grafana-admin');
        is($ref->key,  'my-token.key_1', 'a legal key survives the constraint');
        is($ref->name, 'grafana-admin',  'a legal name survives the constraint');
    } 'values the CRD pattern allows still construct';

    # A Secret data key may hold [-._a-zA-Z0-9] and nothing else.
    throws_ok { $class->new(key => 'has space') } qr/pattern/,
        'a key with a space is rejected (was silently accepted before k120)';
    throws_ok { $class->new(key => 'has/slash') } qr/pattern/,
        'a key with a slash is rejected';

    # name is a DNS subdomain: lowercase alphanumerics, - and . only.
    throws_ok { $class->new(name => 'UPPERCASE') } qr/pattern/,
        'an uppercase name is rejected';
    throws_ok { $class->new(name => 'under_score') } qr/pattern/,
        'an underscore in a name is rejected';
    throws_ok { $class->new(name => '-leading-dash') } qr/pattern/,
        'a leading dash in a name is rejected';
};

# The constraint has to survive nested inflation, which is how a consumer
# actually reaches SecretRef -- never by calling ->new on it directly.
subtest 'the SecretRef patterns hold through nested inflation' => sub {
    lives_ok {
        $k8s->new_object('Webhook',
            metadata => { name => 'wh' },
            spec     => {
                url     => 'https://example.invalid/hook',
                secrets => [ { name => 's', secretRef => { key => 'good.key_1', name => 'my-secret' } } ],
            },
        );
    } 'a Webhook with a legal secretRef inflates';

    throws_ok {
        $k8s->new_object('Webhook',
            metadata => { name => 'wh' },
            spec     => {
                url     => 'https://example.invalid/hook',
                secrets => [ { name => 's', secretRef => { key => 'bad key!', name => 'my-secret' } } ],
            },
        );
    } qr/pattern/, 'an illegal secretRef key fails while inflating the Webhook';
};

# --- 2. the four schema-only corrections, seen through to_crd -------------

subtest 'Grafana: to_crd marks spec.auth required, as the CRD does' => sub {
    # bundle.yaml, grafanas.generators.external-secrets.io:
    #   .spec.versions[0].schema.openAPIV3Schema.properties.spec.required:
    #     [auth, serviceAccount, url]
    my $spec = spec_schema('Grafana');
    is_deeply([ sort @{ $spec->{required} || [] } ], [qw( auth serviceAccount url )],
        'all three of the CRD required fields reach the generated schema');
};

subtest 'Github/Gitlab: to_crd emits no default the CRD does not declare' => sub {
    # Both manifests describe the fallback in PROSE only --
    #   githubaccesstokens ... .spec.properties.url:
    #     description: URL configures the GitHub instance URL. Defaults to https://github.com/.
    #     type: string
    #   gitlabdeploytokens ... .spec.properties.url:
    #     description: URL configures the GitLab instance URL. Defaults to https://gitlab.com.
    #     type: string
    # -- with no `default:` key at either. k113 turned the sentence into one.
    for my $case (['GithubAccessToken', 'https://github.com/'], ['GitlabDeployToken', 'https://gitlab.com']) {
        my ($kind, $was) = @$case;
        my $url = spec_schema($kind)->{properties}{url};
        ok(!exists $url->{default},
            "$kind .spec.url carries no default (was: '$was', read out of the description)");
        is($url->{type}, 'string', "$kind .spec.url is still a plain string field");
    }
};

subtest 'ACRAccessToken: to_crd leaves workloadIdentity without a required list' => sub {
    # bundle.yaml, acraccesstokens.generators.external-secrets.io:
    #   .spec.auth.workloadIdentity carries description/properties/type only --
    #   no `required:` key at all, so serviceAccountRef is optional there.
    my $wi = spec_schema('ACRAccessToken')->{properties}{auth}{properties}{workloadIdentity};
    ok(!exists $wi->{required},
        'workloadIdentity has no required list (serviceAccountRef was wrongly marked)');
    ok(exists $wi->{properties}{serviceAccountRef},
        'the field itself is still modeled, only its required-ness was wrong');
};

# A guard for the whole family, since an invented default is the failure
# k113 actually made and a future hand-modelled round can make again. The
# claim is NOT "no defaults" -- eleven are genuine -- but "exactly these,
# and no others", each quoted from bundle.yaml below. A default read out of
# a description adds a line here; a genuine one silently dropped removes
# one. maint/crd-schema-audit.pl is the general form of this check, run
# against the real manifest rather than a pinned list.
my @CRD_DEFAULTS = (
    'ACRAccessToken.spec.environmentType=PublicCloud',   # acraccesstokens ... default: PublicCloud
    'Password.spec.allowRepeat=false',                   # passwords ... default: false
    'Password.spec.encoding=raw',                        # passwords ... default: raw
    'Password.spec.length=24',                           # passwords ... default: 24
    'Password.spec.noUpper=false',                       # passwords ... default: false
    'PushSecret.spec.deletionPolicy=None',               # pushsecrets ... default: None
    'PushSecret.spec.refreshInterval=1h0m0s',            # pushsecrets ... default: 1h0m0s
    'PushSecret.spec.updatePolicy=Replace',              # pushsecrets ... default: Replace
    'SSHKey.spec.keyType=rsa',                           # sshkeys ... default: rsa
    'VaultDynamicSecret.spec.allowEmptyResponse=false',  # vaultdynamicsecrets ... default: false
    'VaultDynamicSecret.spec.resultType=Data',           # vaultdynamicsecrets ... default: Data
);

subtest 'every V1alpha1 spec default is one the upstream CRD declares' => sub {
    my $map = IO::K8s::ExternalSecrets->resource_map;
    my @found;
    for my $kind (sort keys %$map) {
        my $class = $k8s->expand_class($kind);
        next unless $class =~ /::V1alpha1::/ && $class->can('resource_plural');
        my $spec  = eval { spec_schema($kind) } or next;
        my $props = $spec->{properties} || {};
        for my $field (sort keys %$props) {
            next unless exists $props->{$field}{default};
            my $value = $props->{$field}{default};
            # Render a boolean default by name. This deliberately reads the
            # VALUE, not its encoding: a Bool field's default currently
            # reaches the generated schema as a plain 0/1 rather than a JSON
            # false/true (so `default: 0` under `type: boolean`), which is a
            # to_crd question of its own and not what this subtest is about.
            $value = ($value ? 'true' : 'false')
                if ($props->{$field}{type} // '') eq 'boolean';
            push @found, "$kind.spec.$field=$value";
        }
    }
    is_deeply(\@found, [ sort @CRD_DEFAULTS ],
        'the V1alpha1 spec defaults are exactly the ones bundle.yaml declares');
};

done_testing;
