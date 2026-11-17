#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file clone );
use JSON::MaybeXS ();


# Kubernetes hinter kubectl auf dem Linux-Simulator.
# Behauptet wird: der Status der Pods wird aus den Ressourcen abgeleitet
# (Image fehlt -> ImagePullBackOff, fehlender Secret-Schluessel bei optional
# -> CrashLoopBackOff, Readiness auf falschem Port -> 0/1, PVC ohne
# StorageClass -> Pending); Endpoints folgen Selector und Bereitschaft;
# NetworkPolicies entscheiden ueber exec curl; set image, patch (merge,
# strategic, json), apply -f und rollout restart aendern den Zustand und
# zaehlen generation; ein PVC ist nach dem Anlegen unveraenderlich.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $api = {
    replicas => 2, generation => 4, selector => { app => 'api' },
    template => { labels => { app => 'api' }, containers => [ {
        name => 'api', image => 'registry.example.com/shop/api:1.4.2', ports => [8080], listens => [8080],
        needs_env => ['DB_PASSWORD'], env => [ { name => 'DB_PASSWORD', secret => 'api-db', key => 'password', optional => $T } ],
        readiness => { port => 8080, path => '/healthz' }, logs => ['level=info msg="listening" addr=:8080'],
        crash_log => ['level=fatal msg="DB_PASSWORD not set"'] } ] },
};
my $start = {
    admin1 => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['10.30.0.5/24'], state => 'UP' } },
        files => {},
        kubernetes => {
            context => 'prod', default_namespace => 'default',
            registry => [ 'registry.example.com/shop/api:1.4.2', 'registry.example.com/shop/api:v1.4.3', 'registry.example.com/shop/web:2.0.1' ],
            nodes => { node1 => { ready => $T } },
            storageclasses => { 'local-path' => { provisioner => 'rancher.io/local-path', default => $T } },
            namespaces => {
                shop => {
                    deployments => {
                        api => $api,
                        web => { replicas => 1, generation => 2, selector => { app => 'web' }, template => { labels => { app => 'web' },
                            containers => [ { name => 'web', image => 'registry.example.com/shop/web:2.0.1', ports => [3000], listens => [3000] } ] } },
                    },
                    services => { api => { selector => { app => 'api' }, ports => [ { port => 80, target => 8080 } ] } },
                    secrets  => { 'api-db' => { password => 's3cret' } },
                    pvcs     => { data => { storage_class => 'fast', size => '10Gi' } },
                    networkpolicies => {
                        'deny-all'  => { pod_selector => {}, ingress => [] },
                        'allow-web' => { pod_selector => { app => 'api' }, ingress => [ { from => [ { app => 'web' } ], ports => [8080] } ] },
                    },
                },
            },
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub k { my ($cmd) = @_; my @r = run_command( $state, 'admin1', $cmd ); return wantarray ? @r : $r[0] }
my $K = sub { $state->{admin1}{kubernetes}{namespaces}{shop} };

subtest 'get und abgeleiteter Status' => sub {
    fresh();
    my ($o) = k('kubectl get pods -n shop');
    like( $o, qr/^NAME\s+READY\s+STATUS\s+RESTARTS\s+AGE$/m, 'Kopf' );
    like( $o, qr/^api-\w+-\w+\s+1\/1\s+Running\s+0/m, 'api laeuft' );
    is( scalar( () = $o =~ /^api-/mg ), 2, 'zwei Repliken' );
    ($o) = k('kubectl -n shop get deploy');
    like( $o, qr/^api\s+2\/2\s+2\s+2/m, 'Deployment bereit' );
    ($o) = k('kubectl get endpoints api -n shop');
    like( $o, qr/^api\s+10\.42\.\d+\.\d+:8080,10\.42/m, 'Endpoints' );
    ($o) = k('kubectl get pvc -n shop');
    like( $o, qr/^data\s+Pending\s+fast/m, 'PVC ohne StorageClass: Pending' );
    ($o) = k('kubectl get sc');
    like( $o, qr/local-path \(default\)\s+rancher\.io\/local-path/, 'StorageClasses' );
    my ( $t, $ok ) = k('kubectl get pods');
    is( $t, 'No resources found in default namespace.', 'leerer Namespace' );
};

subtest 'Fehlerbilder' => sub {
    fresh();
    $K->()->{deployments}{api}{template}{containers}[0]{image} = 'registry.example.com/shop/api:1.4.3';
    my ($o) = k('kubectl get pods -n shop -l app=api');
    like( $o, qr/0\/1\s+ImagePullBackOff/, 'falsches Tag: ImagePullBackOff' );
    ($o) = k('kubectl describe pod -n shop ' . ( $o =~ /^(api-\S+)/m )[0] );
    like( $o, qr/Failed to pull image "registry\.example\.com\/shop\/api:1\.4\.3".*not found/, 'describe zeigt den Grund' );
    k('kubectl -n shop set image deployment/api api=registry.example.com/shop/api:v1.4.3');
    ($o) = k('kubectl get pods -n shop -l app=api');
    like( $o, qr/1\/1\s+Running/, 'richtiges Tag: laeuft' );
    is( $K->()->{deployments}{api}{generation}, 5, 'set image zaehlt generation' );

    fresh();
    $K->()->{secrets}{'api-db'} = { 'db-password' => 'x' };
    ($o) = k('kubectl get pods -n shop -l app=api');
    like( $o, qr/0\/1\s+CrashLoopBackOff\s+7/, 'optionaler Schluessel fehlt: CrashLoop' );
    ($o) = k( 'kubectl logs -n shop deploy/api' );
    like( $o, qr/DB_PASSWORD not set/, 'logs' );
    my $ok;
    ( $o, $ok ) = k(q{kubectl -n shop patch deployment api --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/secretKeyRef/key","value":"db-password"}]'});
    ok( $ok, 'json patch' ) or diag $o;
    ($o) = k('kubectl get pods -n shop -l app=api');
    like( $o, qr/1\/1\s+Running/, 'Schluessel richtig: laeuft' );

    fresh();
    $K->()->{deployments}{api}{template}{containers}[0]{readiness}{port} = 80;
    ($o) = k('kubectl get endpoints -n shop api');
    like( $o, qr/^api\s+<none>/m, 'Readiness falsch: keine Endpoints' );
    ( $o, $ok ) = k(q{kubectl -n shop patch deploy api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","readinessProbe":{"httpGet":{"path":"/healthz","port":8080}}}]}}}}'});
    ok( $ok, 'strategic merge patch' ) or diag $o;
    ($o) = k('kubectl get endpoints -n shop api');
    like( $o, qr/:8080/, 'wieder Endpoints' );
};

subtest 'Service, NetworkPolicy, exec' => sub {
    fresh();
    my $web = ( k('kubectl get pods -n shop -l app=web -o name') =~ m{pod/(\S+)} )[0];
    my ( $o, $ok ) = k("kubectl exec -n shop $web -- curl -s http://api/healthz");
    ok( $ok, 'web erreicht api' ) or diag $o;
    $K->()->{networkpolicies}{'allow-web'}{ingress}[0]{from} = [ { role => 'frontend' } ];
    ( $o, $ok ) = k("kubectl exec -n shop $web -- curl -s http://api/healthz");
    like( $o, qr/Timeout was reached/, 'Policy passt nicht: gesperrt' );
    ( $o, $ok ) = k(q{kubectl -n shop patch networkpolicy allow-web --type merge -p '{"spec":{"ingress":[{"from":[{"podSelector":{"matchLabels":{"app":"web"}}}],"ports":[{"port":8080}]}]}}'});
    ok( $ok, 'merge patch der Policy' ) or diag $o;
    is_deeply( $K->()->{networkpolicies}{'allow-web'}{ingress}, [ { from => [ { app => 'web' } ], ports => [8080] } ], 'zurueck in der Form des Zustands' );
    ( $o, $ok ) = k("kubectl exec -n shop $web -- wget -qO- http://api.shop.svc.cluster.local/healthz");
    ok( $ok, 'wieder erreichbar (wget, FQDN)' );
    $K->()->{services}{api}{selector} = { app => 'shop-api' };
    ( $o, $ok ) = k("kubectl exec -n shop $web -- curl http://api");
    like( $o, qr/Couldn't connect/, 'Selector passt nicht: keine Endpoints' );
    ( $o, $ok, my $gap ) = k("kubectl exec -it -n shop $web -- sh");
    ok( $gap, 'interaktive Shell: Luecke der Simulation' );
};

subtest 'Service-Ports, Secret aendern' => sub {
    fresh();
    $K->()->{services}{api}{ports} = [ { name => 'http', port => 80, target => 8000 }, { name => 'metrics', port => 9100, target => 9100 } ];
    my ( $o, $ok ) = k(q{kubectl -n shop patch svc api -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'});
    ok( $ok, 'strategic merge auf Service-Ports' ) or diag $o;
    is_deeply( $K->()->{services}{api}{ports}, [ { name => 'http', port => 80, target => 8080 }, { name => 'metrics', port => 9100, target => 9100 } ],
        '... Schluessel port: nur dieser Port geaendert, metrics bleibt' );
    k(q{kubectl -n shop patch svc api --type merge -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'});
    is( scalar @{ $K->()->{services}{api}{ports} }, 1, 'merge patch ersetzt die ganze Liste (wie echt)' );

    ( $o, $ok ) = k(q{kubectl -n shop patch secret api-db -p '{"stringData":{"password":"neu-1"}}'});
    ok( $ok, 'patch secret mit stringData' ) or diag $o;
    is( $K->()->{secrets}{'api-db'}{password}, 'neu-1', '... stringData gewinnt gegen data' );
    ( $o, $ok ) = k(q{kubectl -n shop create secret generic api-db --from-literal=password=neu-2 --dry-run=client -o yaml});
    ok( $ok, 'create secret --dry-run=client -o yaml' ) or diag $o;
    is( $K->()->{secrets}{'api-db'}{password}, 'neu-1', '... aendert nichts' );
    like( $o, qr/kind: Secret/, '... gibt das Manifest aus' );
    ( $o, $ok ) = k(q{kubectl -n shop create secret generic api-db --from-literal=password=neu-2 --dry-run=client -o yaml | kubectl apply -f -});
    ok( $ok, '... | kubectl apply -f -' ) or diag $o;
    is( $K->()->{secrets}{'api-db'}{password}, 'neu-2', '... ersetzt den Wert' );
    write_file( $state, 'admin1', '/root/pw.txt', "neu-3\n" );
    ( $o, $ok ) = k(q{kubectl -n shop create secret generic api-db --from-file=password=/root/pw.txt --dry-run=client -o yaml | kubectl apply -f -});
    ok( $ok, '--from-file=schluessel=datei' ) or diag $o;
    is( $K->()->{secrets}{'api-db'}{password}, "neu-3\n", '... Inhalt samt Zeilenende (wie echt)' );
    ( $o, $ok ) = k(q{kubectl -n shop create secret generic x --from-file=/root/nix.txt});
    like( $o, qr/no such file/, '... fehlende Datei: Fehler' );

    my $gen = $K->()->{deployments}{api}{generation};
    ( $o, $ok ) = k(q{kubectl -n shop patch deploy api -p '{"spec":{"template":{"metadata":{"annotations":{"rotated-at":"2026-10-24"}}}}}'});
    ok( $ok, 'Annotation der Pod-Vorlage per patch' ) or diag $o;
    is( $K->()->{deployments}{api}{generation}, $gen + 1, '... rollt neu aus (generation)' );
    like( k('kubectl -n shop get deploy api -o yaml'), qr/rotated-at/, '... und steht in der Vorlage' );
};

subtest 'Flags, die echtes kubectl kennt' => sub {
    fresh();
    $state->{admin1}{kubernetes}{namespaces}{staging} = { deployments => { api => clone($api) } };
    my ($all) = k('kubectl get pods -A');
    is( scalar( () = $all =~ /^NAMESPACE/mg ), 1, 'get -A: ein Kopf fuer alle Namespaces' );
    like( $all, qr/^staging\s+api-/m, '... mit den Pods des zweiten' );
    delete $state->{admin1}{kubernetes}{namespaces}{staging};
    my ( $o, $ok, $gap ) = k('kubectl get events -n shop --sort-by=.metadata.creationTimestamp');
    ok( $ok && !$gap, '--sort-by=… wird angenommen' ) or diag $o;
    ( $o, $ok, $gap ) = k('kubectl get events -n shop --sort-by .lastTimestamp');
    ok( $ok && !$gap, '--sort-by mit getrenntem Wert' ) or diag $o;
    ( $o, $ok, $gap ) = k('kubectl get events -n shop --field-selector reason=Failed');
    ok( $gap, '--field-selector: Luecke der Simulation, kein unknown flag' );
    unlike( $o, qr/unknown flag/, '... keine falsche Fehlermeldung' );
    ( $o, $ok, $gap ) = k(q{kubectl get deploy api -n shop -o jsonpath='{.spec.template.spec.containers[0].image}'});
    ok( $ok && !$gap && $o eq 'registry.example.com/shop/api:1.4.2', '-o jsonpath: nachgebildet' ) or diag $o;
    # -o json wie kubectl (Go): "key": value, vier Leerzeichen
    ( $o, $ok ) = k('kubectl get deploy api -n shop -o json');
    ok( $ok, '-o json' ) or diag $o;
    like( $o, qr/^    "kind": "Deployment",$/m, '-o json: "key": value mit vier Leerzeichen' ) or diag $o;
    unlike( $o, qr/" :/, '... kein Leerzeichen vor dem Doppelpunkt' );
    like( k('kubectl get deploy -n shop -o json | grep -o \'"app": "[^"]*"\''), qr/"app": "api"/, '... grep auf "app": "…" trifft' );
    ( $o, $ok ) = k('kubectl get deploy -n shop -o json');
    like( $o, qr/^    "items": \[$/m, '-o json als Liste' ) or diag $o;
    is_deeply( $state, clone($start), 'nichts geaendert' );
};

subtest 'apply, PVC, delete, rollout' => sub {
    fresh();
    write_file( $state, 'admin1', '/root/pvc.yaml', <<'EOT' );
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
  namespace: shop
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
EOT
    my ( $o, $ok ) = k('kubectl apply -f /root/pvc.yaml');
    like( $o, qr/spec is immutable/, 'PVC unveraenderlich' );
    ( $o, $ok ) = k('kubectl delete pvc data -n shop && kubectl apply -f /root/pvc.yaml');
    ok( $ok, 'loeschen und neu anlegen' ) or diag $o;
    like( $o, qr{persistentvolumeclaim/data created}, 'created' );
    ($o) = k('kubectl get pvc -n shop data');
    like( $o, qr/Bound/, 'gebunden' );
    ( $o, $ok ) = k('kubectl apply -f /root/pvc.yaml');
    like( $o, qr/unchanged/, 'zweites apply: unchanged' );
    k('kubectl -n shop rollout restart deployment/web');
    is( $K->()->{deployments}{web}{generation}, 3, 'rollout restart zaehlt' );
    ( $o, $ok ) = k('kubectl delete namespace shop');
    ok( !$state->{admin1}{kubernetes}{namespaces}{shop}, 'Namespace geloescht (Regeln sehen es)' );
};

done_testing;
