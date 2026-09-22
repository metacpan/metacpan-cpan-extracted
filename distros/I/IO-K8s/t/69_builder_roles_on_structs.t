#!/usr/bin/env perl
# D2: every builder role works on a modeled (inline-struct / object) spec.
# The hash-spec behaviour of the same roles is covered by t/16-t/19.
use strict;
use warnings;
use Test::More;

use IO::K8s;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

sub meta { IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => $_[0], namespace => 'd') }

# --- classes -------------------------------------------------------------

{
    package TestBR::Cert;
    use IO::K8s::APIObject api_version => 'cert-manager.io/v1', resource_plural => 'certificates';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::CertManaged';
    k8s spec => {
        dnsNames    => [Str],
        ipAddresses => [Str],
        secretName  => Str,
        renewBefore => Str,
        issuerRef   => { name => Str, kind => Str, group => Str },
    };
}

{
    package TestBR::Solver;
    use IO::K8s::Resource;
    k8s http01 => { Str => 1 };
    k8s dns01  => { Str => 1 };
}

{
    package TestBR::Issuer;
    use IO::K8s::APIObject api_version => 'cert-manager.io/v1', resource_plural => 'issuers';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::CertManaged';
    k8s spec => {
        acme       => { email => Str, server => Str, privateKeySecretRef => { name => Str }, solvers => ['+TestBR::Solver'] },
        selfSigned => { Str => 1 },
        ca         => { secretName => Str },
    };
}

{
    package TestBR::Chart;
    use IO::K8s::APIObject api_version => 'helm.cattle.io/v1', resource_plural => 'helmcharts';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::HelmManaged';
    k8s spec => {
        repo          => Str,
        chart         => Str,
        version       => Str,
        set           => { Str => 1 },
        valuesContent => Str,
    };
}

{
    package TestBR::Middleware;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'middlewares';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::MiddlewareBuilder';
    k8s spec => {
        rateLimit      => { average => Int, burst => Int, period => Str },
        basicAuth      => { secret => Str, realm => Str },
        stripPrefix    => { prefixes => [Str] },
        redirectScheme => { scheme => Str, permanent => Bool },
        headers        => { customRequestHeaders => { Str => 1 }, customResponseHeaders => { Str => 1 } },
    };
}

{
    package TestBR::MiddlewareTCP;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'middlewaretcps';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::MiddlewareTCPBuilder';
    k8s spec => {
        inFlightConn => { amount => Int },
        ipAllowList  => { sourceRange => [Str] },
        ipWhiteList  => { sourceRange => [Str] },
    };
}

{
    package TestBR::WSvc;
    use IO::K8s::Resource;
    k8s name   => Str;
    k8s weight => Int;
}

{
    package TestBR::Mirror;
    use IO::K8s::Resource;
    k8s name    => Str;
    k8s percent => Int;
}

{
    package TestBR::TraefikService;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'traefikservices';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Loadbalanced';
    k8s spec => {
        weighted  => { services => ['+TestBR::WSvc'] },
        mirroring => { mirrors => ['+TestBR::Mirror'] },
    };
}

{
    package TestBR::BackendRef;
    use IO::K8s::Resource;
    k8s name   => Str;
    k8s port   => Int;
    k8s weight => Int;
}

{
    package TestBR::HeaderMatch;
    use IO::K8s::Resource;
    k8s name  => Str;
    k8s value => Str;
}

{
    package TestBR::Match;
    use IO::K8s::Resource;
    k8s path    => { type => Str, value => Str };
    k8s headers => ['+TestBR::HeaderMatch'];
}

{
    package TestBR::Rule;
    use IO::K8s::Resource;
    k8s backendRefs => ['+TestBR::BackendRef'];
    k8s matches     => ['+TestBR::Match'];
}

{
    package TestBR::HTTPRoute;
    use IO::K8s::APIObject api_version => 'gateway.networking.k8s.io/v1', resource_plural => 'httproutes';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Routable';
    sub _route_format { 'gateway' }
    k8s spec => {
        hostnames => [Str],
        rules     => ['+TestBR::Rule'],
    };
}

{
    package TestBR::TRoute;
    use IO::K8s::Resource;
    k8s match    => Str;
    k8s kind     => Str;
    k8s services => [ {} ];
}

{
    package TestBR::IngressRoute;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'ingressroutes';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Routable';
    sub _route_format { 'traefik' }
    k8s spec => {
        routes => ['+TestBR::TRoute'],
    };
}

{
    package TestBR::CNPRule;
    use IO::K8s::Resource;
    k8s fromEndpoints => [ {} ];
    k8s toEndpoints   => [ {} ];
    k8s fromCIDR      => [Str];
    k8s toCIDR        => [Str];
    k8s toPorts       => [ {} ];
}

{
    package TestBR::CNP;
    use IO::K8s::APIObject api_version => 'cilium.io/v2', resource_plural => 'ciliumnetworkpolicies';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::NetworkPolicy';
    sub _netpol_format { 'cilium' }
    k8s spec => {
        endpointSelector => { matchLabels => { Str => 1 } },
        ingress          => ['+TestBR::CNPRule'],
        egress           => ['+TestBR::CNPRule'],
        ingressDeny      => [ {} ],
        egressDeny       => [ {} ],
    };
}

# --- tests ---------------------------------------------------------------

subtest 'CertManaged on a modeled Certificate' => sub {
    my $c = TestBR::Cert->new(metadata => meta('c'));
    $c->for_domains('a.example', 'b.example')
      ->with_issuer('le', kind => 'ClusterIssuer')
      ->store_in_secret('tls')
      ->add_ip_san('10.0.0.1')
      ->renew_before(days => 2);
    my $spec = $c->TO_JSON->{spec};
    is_deeply($spec->{dnsNames}, [ 'a.example', 'b.example' ], 'dnsNames');
    is_deeply($spec->{issuerRef}, { name => 'le', kind => 'ClusterIssuer', group => 'cert-manager.io' }, 'issuerRef');
    is($c->spec->issuerRef->kind, 'ClusterIssuer', 'issuerRef is the struct');
    is($spec->{secretName}, 'tls', 'secretName');
    is_deeply($spec->{ipAddresses}, [ '10.0.0.1' ], 'ipAddresses');
    is($spec->{renewBefore}, '48h0m0s', 'renewBefore');
    $c->for_domains('c.example');
    is(scalar @{ $spec = $c->TO_JSON->{spec}; $spec->{dnsNames} }, 3, 'for_domains appends');
};

subtest 'CertManaged on a modeled Issuer' => sub {
    my $i = TestBR::Issuer->new(metadata => meta('i'));
    $i->letsencrypt(email => 'me@example', production => 1)
      ->add_http01_solver(class => 'traefik')
      ->add_dns01_solver(provider => 'cloudflare', secret => 'cf');
    my $acme = $i->TO_JSON->{spec}{acme};
    is($acme->{server}, 'https://acme-v02.api.letsencrypt.org/directory', 'production server');
    is($acme->{privateKeySecretRef}{name}, 'letsencrypt-account-key', 'default account key');
    is(scalar @{ $acme->{solvers} }, 2, 'two solvers');
    isa_ok($i->spec->acme->solvers->[0], 'TestBR::Solver', 'solver inflated to its class');
    is($acme->{solvers}[0]{http01}{ingress}{class}, 'traefik', 'http01 solver');
    is($acme->{solvers}[1]{dns01}{cloudflare}{apiTokenSecretRef}{name}, 'cf', 'dns01 solver');
    my $s = TestBR::Issuer->new(metadata => meta('s'))->self_signed;
    is_deeply($s->TO_JSON->{spec}{selfSigned}, {}, 'self_signed');
    my $ca = TestBR::Issuer->new(metadata => meta('ca'))->ca(secret => 'root');
    is($ca->TO_JSON->{spec}{ca}{secretName}, 'root', 'ca');
};

subtest 'HelmManaged on a modeled HelmChart' => sub {
    my $h = TestBR::Chart->new(metadata => meta('h'));
    $h->from_repo('https://charts.example', 'app')->set_version('1.2.3')
      ->set_values('image.tag' => 'v1', replicas => 3)
      ->set_values_yaml("a: 1\n");
    my $spec = $h->TO_JSON->{spec};
    is($spec->{repo}, 'https://charts.example', 'repo');
    is($spec->{chart}, 'app', 'chart');
    is($spec->{version}, '1.2.3', 'version');
    is_deeply($spec->{set}, { 'image.tag' => 'v1', replicas => 3 }, 'set keeps dotted keys intact');
    $h->set_values(replicas => 4);
    is($h->TO_JSON->{spec}{set}{replicas}, 4, 'set_values merges');
    is($spec->{valuesContent}, "a: 1\n", 'valuesContent');
};

subtest 'MiddlewareBuilder on a modeled Middleware' => sub {
    my $m = TestBR::Middleware->new(metadata => meta('m'));
    $m->rate_limit(average => 100, burst => 200)
      ->basic_auth(secret => 'users', realm => 'r')
      ->strip_prefix('/api', '/v1')
      ->redirect_https
      ->add_request_header('X-A' => '1')
      ->add_request_header('X-B' => '2')
      ->add_response_header('X-C' => '3');
    my $spec = $m->TO_JSON->{spec};
    is_deeply($spec->{rateLimit}, { average => 100, burst => 200 }, 'rateLimit');
    is($m->spec->rateLimit->average, 100, 'rateLimit is the struct');
    is_deeply($spec->{basicAuth}, { secret => 'users', realm => 'r' }, 'basicAuth');
    is_deeply($spec->{stripPrefix}{prefixes}, [ '/api', '/v1' ], 'stripPrefix');
    is($spec->{redirectScheme}{scheme}, 'https', 'redirectScheme');
    ok($spec->{redirectScheme}{permanent}, 'permanent is true');
    is_deeply($spec->{headers}{customRequestHeaders}, { 'X-A' => '1', 'X-B' => '2' }, 'request headers accumulate');
    is_deeply($spec->{headers}{customResponseHeaders}, { 'X-C' => '3' }, 'response headers');
};

subtest 'MiddlewareTCPBuilder on a modeled MiddlewareTCP' => sub {
    my $m = TestBR::MiddlewareTCP->new(metadata => meta('mtcp'));
    $m->in_flight_conn(10)
      ->ip_allow_list('10.0.0.0/8', '192.168.1.7')
      ->ip_white_list('172.16.0.0/12');
    my $spec = $m->TO_JSON->{spec};
    is_deeply($spec->{inFlightConn}, { amount => 10 }, 'inFlightConn');
    is($m->spec->inFlightConn->amount, 10, 'inFlightConn is the struct');
    is_deeply($spec->{ipAllowList}{sourceRange}, [ '10.0.0.0/8', '192.168.1.7' ], 'ipAllowList');
    is_deeply($spec->{ipWhiteList}{sourceRange}, [ '172.16.0.0/12' ], 'ipWhiteList');

    # k106: the HTTP builders are a separate role and are not composed here.
    ok(!TestBR::MiddlewareTCP->can('rate_limit'), 'no HTTP rate_limit on a TCP middleware');
};

subtest 'Loadbalanced on a modeled TraefikService' => sub {
    my $t = TestBR::TraefikService->new(metadata => meta('t'));
    $t->set_weighted('a', 10)->set_weighted('b', 20)->set_weighted('a', 30)->mirror_to('m', percent => 5);
    my $spec = $t->TO_JSON->{spec};
    is_deeply($spec->{weighted}{services}, [ { name => 'a', weight => 30 }, { name => 'b', weight => 20 } ], 'update-or-add');
    isa_ok($t->spec->weighted->services->[0], 'TestBR::WSvc', 'service inflated');
    is_deeply($spec->{mirroring}{mirrors}, [ { name => 'm', percent => 5 } ], 'mirror_to');
};

subtest 'Routable (gateway) on a modeled HTTPRoute' => sub {
    my $r = TestBR::HTTPRoute->new(metadata => meta('r'));
    $r->add_hostname('example.com')
      ->add_path_match('/api', type => 'PathPrefix')
      ->add_header_match('X-Env' => 'prod')
      ->add_backend('api-v1', port => 8080, weight => 90);
    my $spec = $r->TO_JSON->{spec};
    is_deeply($spec->{hostnames}, [ 'example.com' ], 'hostnames');
    is(scalar @{ $spec->{rules} }, 1, 'one rule vivified by -1');
    isa_ok($r->spec->rules->[0], 'TestBR::Rule', 'rule inflated');
    is_deeply($spec->{rules}[0]{matches}, [ { path => { type => 'PathPrefix', value => '/api' }, headers => [ { name => 'X-Env', value => 'prod' } ] } ], 'matches with header on the last match');
    is_deeply($spec->{rules}[0]{backendRefs}, [ { name => 'api-v1', port => 8080, weight => 90 } ], 'backendRefs');
};

subtest 'Routable (traefik) on a modeled IngressRoute' => sub {
    my $r = TestBR::IngressRoute->new(metadata => meta('r'));
    $r->add_hostname('example.com')->add_path_match('/api')->add_header_match('X-A' => 'b')->add_backend('svc', port => 80);
    my $routes = $r->TO_JSON->{spec}{routes};
    is(scalar @$routes, 1, 'one route');
    is($routes->[0]{match}, 'PathPrefix(`/api`) && Header(`X-A`, `b`)', 'match rule rewritten then extended');
    is_deeply($routes->[0]{services}, [ { name => 'svc', port => 80 } ], 'services');
};

subtest 'NetworkPolicy (cilium) on a modeled CiliumNetworkPolicy' => sub {
    my $p = TestBR::CNP->new(metadata => meta('p'));
    $p->select_pods(app => 'web')
      ->allow_ingress_from_pods({ app => 'nginx' }, ports => [ { port => '8080', protocol => 'TCP' } ])
      ->allow_ingress_from_cidrs([ '10.0.0.0/8' ])
      ->allow_ingress_from_namespace('other')
      ->allow_egress_to_pods({ app => 'db' })
      ->allow_egress_to_cidrs([ '0.0.0.0/0' ])
      ->allow_egress_to_dns;
    my $spec = $p->TO_JSON->{spec};
    is_deeply($spec->{endpointSelector}, { matchLabels => { app => 'web' } }, 'endpointSelector');
    is(scalar @{ $spec->{ingress} }, 3, 'three ingress rules');
    isa_ok($p->spec->ingress->[0], 'TestBR::CNPRule', 'rule inflated');
    is_deeply($spec->{ingress}[0]{fromEndpoints}, [ { matchLabels => { app => 'nginx' } } ], 'from pods');
    is_deeply($spec->{ingress}[0]{toPorts}, [ { ports => [ { port => '8080', protocol => 'TCP' } ] } ], 'ports');
    is_deeply($spec->{ingress}[1]{fromCIDR}, [ '10.0.0.0/8' ], 'from cidrs');
    is_deeply($spec->{ingress}[2]{fromEndpoints}[0]{matchLabels}, { 'k8s:io.kubernetes.pod.namespace' => 'other' }, 'from namespace');
    is(scalar @{ $spec->{egress} }, 3, 'three egress rules');
    is_deeply($spec->{egress}[1]{toCIDR}, [ '0.0.0.0/0' ], 'to cidrs');
    ok($spec->{egress}[2]{toPorts}, 'dns rule has ports');

    my $d = TestBR::CNP->new(metadata => meta('d'))->deny_all_ingress->deny_all_egress;
    my $dspec = $d->TO_JSON->{spec};
    is_deeply([ $dspec->{ingress}, $dspec->{ingressDeny} ], [ [], [ {} ] ], 'deny_all_ingress');
    is_deeply([ $dspec->{egress}, $dspec->{egressDeny} ], [ [], [ {} ] ], 'deny_all_egress');
};

done_testing;
