#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp;
use JSON::MaybeXS;

use IO::K8s::Cilium::V2::CiliumNetworkPolicy;
use IO::K8s::Cilium::V2::CiliumClusterwideNetworkPolicy;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
use IO::K8s::Api::Networking::V1::NetworkPolicy;

# --- Cilium NetworkPolicy ---
# spec is a typed IO::K8s::Cilium::V2::Rule object as of task B-Cilium (D5)
# -- never passed as a raw hashref to ->new (k100: a direct ->new(spec =>
# {...}) does not coerce) and never read back via ->spec->{key} (fragile
# hash-key access on a blessed object). Every method under test writes
# through spec_set/spec_push (IO::K8s::Role::SpecBuilder, which the role's
# own method bodies already use and which auto-vivifies a typed spec, k90);
# assertions below read the typed accessors or TO_JSON.

subtest 'cilium: select_pods' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->select_pods(app => 'web', tier => 'frontend');
    isa_ok($cnp->spec, 'IO::K8s::Cilium::V2::Rule');
    isa_ok($cnp->spec->endpointSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is_deeply($cnp->spec->endpointSelector->matchLabels, { app => 'web', tier => 'frontend' }, 'select_pods sets endpointSelector');
};

subtest 'cilium: allow_ingress_from_pods' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->allow_ingress_from_pods({ app => 'nginx' }, ports => [{ port => 8080, protocol => 'TCP' }]);
    my $ingress = $cnp->spec->ingress;
    is(scalar @$ingress, 1, 'one ingress rule');
    isa_ok($ingress->[0], 'IO::K8s::Cilium::V2::IngressRule');
    is_deeply($ingress->[0]->TO_JSON->{fromEndpoints}, [{ matchLabels => { app => 'nginx' } }], 'from endpoints');
    is($ingress->[0]->TO_JSON->{toPorts}[0]{ports}[0]{port}, 8080, 'port');
};

subtest 'cilium: allow_ingress_from_cidrs' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->allow_ingress_from_cidrs(['192.168.0.0/16', '10.0.0.0/8']);
    my $ingress = $cnp->spec->ingress;
    is_deeply($ingress->[0]->TO_JSON->{fromCIDR}, ['192.168.0.0/16', '10.0.0.0/8'], 'fromCIDR');
};

subtest 'cilium: allow_ingress_from_namespace' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->allow_ingress_from_namespace('monitoring', ports => [{ port => 9090 }]);
    my $ingress = $cnp->spec->ingress;
    ok($ingress->[0]->TO_JSON->{fromEndpoints}[0]{matchLabels}{'k8s:io.kubernetes.pod.namespace'}, 'namespace set');
};

subtest 'cilium: allow_egress_to_pods' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->allow_egress_to_pods({ app => 'db' }, ports => [{ port => 5432 }]);
    my $egress = $cnp->spec->egress;
    is_deeply($egress->[0]->TO_JSON->{toEndpoints}, [{ matchLabels => { app => 'db' } }], 'to endpoints');
};

subtest 'cilium: allow_egress_to_cidrs' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->allow_egress_to_cidrs(['10.0.0.0/8']);
    is_deeply($cnp->spec->egress->[0]->TO_JSON->{toCIDR}, ['10.0.0.0/8'], 'toCIDR');
};

subtest 'cilium: allow_egress_to_dns' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->allow_egress_to_dns;

    # The full rule, not just the port count: since k117 both formats build
    # this from one %DNS_TARGET constant in the role, so this is the half
    # that pins the shared facts (kube-system, k8s-app=kube-dns) on the
    # Cilium side. The core side asserts the same two facts in
    # networking.k8s.io's spelling.
    is_deeply($cnp->spec->egress->[0]->TO_JSON, {
        toEndpoints => [ { matchLabels => {
            'k8s:io.kubernetes.pod.namespace' => 'kube-system',
            'k8s:k8s-app'                     => 'kube-dns',
        } } ],
        toPorts     => [ { ports => [ { port => 53, protocol => 'UDP' },
                                      { port => 53, protocol => 'TCP' } ] } ],
    }, 'DNS egress reaches the CoreDNS endpoints on UDP and TCP 53');
};

subtest 'cilium: deny_all_ingress' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->deny_all_ingress;
    is_deeply($cnp->spec->ingress, [], 'empty ingress');
    ok($cnp->spec->ingressDeny, 'ingressDeny set');
};

subtest 'cilium: deny_all_egress' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    $cnp->deny_all_egress;
    is_deeply($cnp->spec->egress, [], 'empty egress');
    ok($cnp->spec->egressDeny, 'egressDeny set');
};

subtest 'cilium: CIDR validation' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    dies_ok { $cnp->allow_ingress_from_cidrs(['not-a-cidr']) } 'rejects bad CIDR';
    dies_ok { $cnp->allow_egress_to_cidrs(['garbage']) } 'rejects bad egress CIDR';
};

subtest 'cilium: chaining' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy', namespace => 'default',
        ),
    );

    my $result = $cnp->select_pods(app => 'web')
                     ->allow_ingress_from_pods({ app => 'nginx' })
                     ->allow_egress_to_dns;

    is($result, $cnp, 'chaining returns self');
    ok($cnp->spec->endpointSelector, 'endpointSelector set via chain');
    ok($cnp->spec->ingress, 'ingress set via chain');
    ok($cnp->spec->egress, 'egress set via chain');
};

# --- CiliumClusterwideNetworkPolicy ---

subtest 'clusterwide network policy' => sub {
    my $ccnp = IO::K8s::Cilium::V2::CiliumClusterwideNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'global-deny',
        ),
    );

    $ccnp->select_pods(app => 'web')->deny_all_ingress;
    isa_ok($ccnp->spec, 'IO::K8s::Cilium::V2::Rule');
    ok($ccnp->spec->endpointSelector, 'clusterwide endpoint selector');
    ok($ccnp->spec->ingressDeny, 'clusterwide deny');
};

# --- core NetworkPolicy (_netpol_format 'core') ------------------------------
#
# The other half of the role, and untested until k117. It builds typed
# NetworkPolicySpec / NetworkPolicyPeer / NetworkPolicyPort / LabelSelector
# objects by name without loading any of them, so it worked only in a
# process that had loaded them for some other reason -- which every test
# above happens to be. The standalone probe at the end is what actually
# pins that; these two subtests pin the shape.

sub core_np {
    IO::K8s::Api::Networking::V1::NetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => $_[0], namespace => 'prod',
        ),
    );
}

subtest 'core: selector, ingress and egress rules' => sub {
    my $np = core_np('web');
    is($np->_netpol_format, 'core', 'the core branch is under test');

    $np->select_pods(app => 'web')
       ->allow_ingress_from_pods({ app => 'gateway' }, ports => [ { port => 8080 } ])
       ->allow_ingress_from_namespace('monitoring')
       ->allow_ingress_from_cidrs(['192.168.0.0/16'])
       ->allow_egress_to_pods({ app => 'redis' }, ports => [ { port => 6379 } ])
       ->allow_egress_to_cidrs(['10.0.0.0/8']);

    isa_ok($np->spec, 'IO::K8s::Api::Networking::V1::NetworkPolicySpec');
    isa_ok($np->spec->podSelector,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($np->spec->ingress->[0],
        'IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule');
    isa_ok($np->spec->egress->[0],
        'IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule');

    is_deeply($np->TO_JSON->{spec}, {
        podSelector => { matchLabels => { app => 'web' } },
        policyTypes => [ 'Ingress', 'Egress' ],
        ingress     => [
            { from  => [ { podSelector => { matchLabels => { app => 'gateway' } } } ],
              ports => [ { port => 8080, protocol => 'TCP' } ] },
            { from  => [ { namespaceSelector => { matchLabels =>
                            { 'kubernetes.io/metadata.name' => 'monitoring' } } } ] },
            { from  => [ { ipBlock => { cidr => '192.168.0.0/16' } } ] },
        ],
        egress      => [
            { to    => [ { podSelector => { matchLabels => { app => 'redis' } } } ],
              ports => [ { port => 6379, protocol => 'TCP' } ] },
            { to    => [ { ipBlock => { cidr => '10.0.0.0/8' } } ] },
        ],
    }, 'the core branch emits the canonical NetworkPolicy shape');

    throws_ok { core_np('bad')->allow_egress_to_cidrs(['10.0.0.0']) }
        qr/is not valid CIDR notation/, 'CIDR validation still applies';
};

subtest 'core: deny-all and DNS' => sub {
    # This subtest previously asserted that the core branch emits the DNS
    # ports with no `to` peer at all. That claim was true and is now
    # deliberately replaced, not repaired: a rule without `to` allows port
    # 53 to every destination, which is looser than the method's own
    # documentation ("to the cluster's CoreDNS pods") and looser than what
    # the cilium branch has always written. The claim below is the
    # documented one.
    my $np = core_np('locked');
    $np->select_pods(app => 'locked')->deny_all_ingress->allow_egress_to_dns;

    is_deeply($np->TO_JSON->{spec}, {
        podSelector => { matchLabels => { app => 'locked' } },
        policyTypes => [ 'Ingress', 'Egress' ],
        ingress     => [],
        egress      => [ {
            to    => [ {
                namespaceSelector => { matchLabels =>
                    { 'kubernetes.io/metadata.name' => 'kube-system' } },
                podSelector       => { matchLabels => { 'k8s-app' => 'kube-dns' } },
            } ],
            ports => [ { port => 53, protocol => 'UDP' },
                       { port => 53, protocol => 'TCP' } ],
        } ],
    }, 'empty ingress list plus DNS egress narrowed to the CoreDNS pods');

    # Kubernetes intersects namespaceSelector and podSelector *within* one
    # `to` element and unions them across elements, so the single peer is
    # the whole point: two peers would reach every pod in kube-system plus
    # every k8s-app=kube-dns pod in any namespace.
    is(scalar @{ $np->spec->egress->[0]->to }, 1,
        'one peer carrying both selectors, so they intersect');
    isa_ok($np->spec->egress->[0]->to->[0]->namespaceSelector,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($np->spec->egress->[0]->to->[0]->podSelector,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
};

subtest 'core: the branch works in a process that loads only the Kind' => sub {
    # Same reasoning as t/17: the bug is only visible in a bare process,
    # and every subtest above has already pulled the classes into %INC.
    my $probe = <<'PROBE';
use strict;
use warnings;
use IO::K8s::Api::Networking::V1::NetworkPolicy;   # and deliberately nothing else
my $np = IO::K8s::Api::Networking::V1::NetworkPolicy->new;
$np->select_pods(app => 'web')
   ->allow_ingress_from_pods({ app => 'gateway' }, ports => [ { port => 8080 } ])
   ->allow_ingress_from_namespace('monitoring')
   ->allow_ingress_from_cidrs(['192.168.0.0/16'])
   ->allow_egress_to_pods({ app => 'redis' })
   ->allow_egress_to_cidrs(['10.0.0.0/8'])
   ->allow_egress_to_dns;
print $np->to_json;
PROBE
    my $fh = File::Temp->new(SUFFIX => '.pl');
    print $fh $probe;
    close $fh;
    my $out = qx{"$^X" -Ilib "$fh" 2>&1};
    is($?, 0, 'the probe exits clean') or diag($out);

    my $spec = eval { JSON::MaybeXS->new->decode($out)->{spec} };
    is(scalar @{ $spec->{ingress} || [] }, 3, 'three ingress rules, nothing preloaded')
        or diag($out);
    is(scalar @{ $spec->{egress}  || [] }, 3, 'three egress rules, nothing preloaded')
        or diag($out);
    is_deeply($spec->{egress}[2]{to}, [ {
        namespaceSelector => { matchLabels =>
            { 'kubernetes.io/metadata.name' => 'kube-system' } },
        podSelector       => { matchLabels => { 'k8s-app' => 'kube-dns' } },
    } ], 'and the DNS rule got its CoreDNS peer with nothing preloaded')
        or diag($out);
    is_deeply($spec->{podSelector}, { matchLabels => { app => 'web' } },
        'and the typed podSelector was built')
        or diag($out);
};

done_testing;
