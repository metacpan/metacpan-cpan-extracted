#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command need_parts );
use JSON::MaybeXS ();


# Kubernetes fuer Fortgeschrittene.
# Behauptet wird:
# - Ingress: der Controller behandelt nur Ingresse seiner IngressClass; Host
#   und Pfad (Prefix elementweise, Exact genau) fuehren zum Service-Port (Zahl
#   oder Name); fehlende Backends sind 503, unbekannte Hosts 404; https mit
#   Zertifikat des Secrets, sonst das Ersatzzertifikat; http leitet um, wenn TLS
#   gesetzt ist; das Log des Controllers nennt fehlende Services und Secrets.
# - cert-manager: ein Certificate ist bereit, wenn sein Issuer da und bereit ist
#   (CA-Secret eines ClusterIssuer im Namespace cert-manager, bekannter
#   ACME-Server, HTTP-01 ueber eine behandelte Klasse); dann gibt es sein Secret.
#   Ingress-Annotationen erzeugen Certificates (ingress-shim).
# - RBAC: auth can-i folgt Role/ClusterRole und Bindungen (ServiceAccount mit
#   Namespace, Gruppen, resourceNames, Unterressourcen); ein Container mit
#   needs_rbac stuerzt mit der Meldung des API-Servers ab; ein fehlender
#   ServiceAccount verhindert Pods; roleRef ist unveraenderlich.
# - Helm: upgrade ohne --reuse-values verwirft alte Werte, ohne neue Werte bleiben
#   sie; ohne --version kommt die neueste Chart-Version; list verbirgt
#   pending-upgrade; upgrade auf pending scheitert, rollback und das Loeschen des
#   Release-Secrets loesen es; gerenderte Ressourcen landen im Cluster.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $J = JSON::MaybeXS->new( canonical => 1 );
sub clone { $J->decode( $J->encode( $_[0] ) ) }

sub dep {
    my ( $name, $port, %x ) = @_;
    return { replicas => 1, generation => 1, selector => { app => $name },
        template => { labels => { app => $name }, ( $x{sa} ? ( service_account => $x{sa} ) : () ),
            containers => [ { name => $name, image => "registry.example.com/$name:1", ports => [$port], listens => [$port], http_body => "hallo von $name",
                ( $x{rbac} ? ( needs_rbac => $x{rbac}, rbac_log => ['starting'] ) : () ), ( $x{logs} ? ( derive_logs => $x{logs}, logs => ['started'] ) : () ) } ] } };
}

my $start = {
    admin1 => {
        type => 'linux',
        files => { '/root/ca.crt' => "CA\n", '/root/ca.key' => "KEY\n", '/root/values-prod.yaml' => "replicaCount: 3\n" },
        kubernetes => {
            context => 'prod', default_namespace => 'default',
            registry => [ map {"registry.example.com/$_:1"} qw( web api ctl cm op shop ) ],
            ingress => { controller => 'k8s.io/ingress-nginx', address => '203.0.113.10' },
            dns => { 'shop.example.com' => '203.0.113.10', 'www.shop.example.com' => '203.0.113.10' },
            ingressclasses => { nginx => { spec => { controller => 'k8s.io/ingress-nginx' } }, traefik => { spec => { controller => 'traefik.io/ingress-controller' } } },
            clusterissuers => {
                'internal-ca' => { spec => { ca => { secretName => 'root-ca' } } },
                letsencrypt   => { spec => { acme => { server => 'https://acme-v02.api.letsencrypt.org/directory', privateKeySecretRef => { name => 'le-key' },
                    solvers => [ { http01 => { ingress => { ingressClassName => 'nginx' } } } ] } } },
            },
            namespaces => {
                'cert-manager' => {},
                'ingress-nginx' => { deployments => { ctl => dep( 'ctl', 80, logs => 'ingress-nginx' ), cm => dep( 'cm', 9402, logs => 'cert-manager' ) } },
                shop => {
                    deployments => { web => dep( 'web', 3000 ), api => dep( 'api', 8080 ), op => dep( 'op', 9000, sa => 'op', rbac => [ { verb => 'list', resource => 'pods' } ] ) },
                    services => {
                        web => { selector => { app => 'web' }, ports => [ { name => 'http', port => 80, target => 3000 } ] },
                        api => { selector => { app => 'api' }, ports => [ { name => 'http', port => 80, target => 8080 } ] },
                    },
                    secrets => { 'root-ca' => { 'tls.crt' => 'x', 'tls.key' => 'y' } },
                    serviceaccounts => { op => {} },
                    ingresses => {
                        web => { metadata => { annotations => { 'cert-manager.io/cluster-issuer' => 'letsencrypt' } },
                            spec => { ingressClassName => 'nginx', tls => [ { hosts => ['shop.example.com'], secretName => 'shop-tls' } ],
                                rules => [ { host => 'shop.example.com', http => { paths => [
                                    { path => '/api', pathType => 'Prefix', backend => { service => { name => 'api', port => { number => 80 } } } },
                                    { path => '/', pathType => 'Prefix', backend => { service => { name => 'web', port => { name => 'http' } } } } ] } } ] } },
                    },
                    certificates => {
                        internal => { spec => { secretName => 'internal-tls', dnsNames => ['api.shop.svc'], issuerRef => { kind => 'ClusterIssuer', name => 'internal-ca' } } },
                    },
                },
            },
            helm => {
                repos => { example => 'https://charts.example.com' },
                charts => { 'example/shop' => { versions => {
                    '1.0.0' => { app_version => '1', values => { replicaCount => 1, image => { tag => '1' }, debug => JSON::MaybeXS::false() },
                        resources => [ { kind => 'deployments', name => '{{ .Release.Name }}', obj => {
                            replicas => '{{ .Values.replicaCount }}', selector => { app => 'shop' },
                            template => { labels => { app => 'shop' }, containers => [ { name => 'shop', image => 'registry.example.com/shop:{{ .Values.image.tag }}', ports => [80], listens => [80],
                                env => [ { _if => 'debug', name => 'DEBUG', value => '1' } ] } ] } } } ] },
                    '2.0.0' => { app_version => '2', values => { replicaCount => 1, image => { tag => '2' } }, resources => [] },
                } } },
                releases => { shop => {
                    shop => { chart => 'example/shop', version => '1.0.0', revision => 2, status => 'deployed', values => { replicaCount => 3, debug => $T },
                        updated => '2026-10-23 14:02:11', description => 'Upgrade complete', manifest => ['deployments/shop'],
                        history => [ { revision => 1, version => '1.0.0', values => {}, status => 'superseded', updated => '2026-10-20 10:00:00', description => 'Install complete' } ] },
                } },
            },
        },
    },
};
# Deployment des Releases wie gerendert
$start->{admin1}{kubernetes}{namespaces}{shop}{deployments}{shop} = { replicas => 3, generation => 2, selector => { app => 'shop' },
    template => { labels => { app => 'shop' }, containers => [ { name => 'shop', image => 'registry.example.com/shop:1', ports => [80], listens => [80], env => [ { name => 'DEBUG', value => '1' } ] } ] } };

sub run {
    my ( $s, $cmd ) = @_;
    my ( $o, $ok, $gap ) = run_command( $s, 'admin1', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
my $K = sub { $_[0]{admin1}{kubernetes} };

subtest 'Ingress: Klasse, Routen, Backends' => sub {
    my $s = clone($start);
    is( run( $s, 'kubectl exec -n shop deploy/web -- curl -sk https://shop.example.com/api/orders' ), 'hallo von api', 'Prefix /api fuehrt zu api' );
    is( run( $s, 'kubectl exec -n shop deploy/web -- curl -sk https://shop.example.com/apix' ), 'hallo von web', '/apix ist nicht /api (elementweise)' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- curl -s http://shop.example.com/' ), qr/308 Permanent Redirect/, 'http mit TLS leitet um' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- curl -sk -H "Host: other.example.com" https://203.0.113.10/' ), qr/404 Not Found/, 'fremder Host: 404' );
    like( run( $s, 'kubectl get ingress -n shop' ), qr/web\s+nginx\s+shop\.example\.com\s+203\.0\.113\.10\s+80, 443/, 'get ingress' );
    run( $s, q{kubectl -n shop patch ingress web --type json -p '[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"apii"}]'} );
    like( run( $s, 'kubectl exec -n shop deploy/web -- curl -sk https://shop.example.com/api' ), qr/503/, 'fehlender Service: 503' );
    like( run( $s, 'kubectl logs -n ingress-nginx deploy/ctl' ), qr{Error obtaining Endpoints for Service "shop/apii"}, 'Log des Controllers nennt ihn' );
    like( run( $s, 'kubectl describe ingress web -n shop' ), qr{apii:80 \(<error: services "apii" not found>\)}, 'describe zeigt den Fehler' );
    run( $s, q{kubectl -n shop patch ingress web --type merge -p '{"spec":{"ingressClassName":"traefik"}}'} );
    like( run( $s, 'kubectl logs -n ingress-nginx deploy/ctl' ), qr{Ignoring ingress.*shop/web}, 'fremde Klasse: ignoriert' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- curl -sk https://shop.example.com/' ), qr/404/, 'und nicht erreichbar' );
};

subtest 'cert-manager: Issuer, Certificate, Secret, TLS' => sub {
    # the start state carries a Helm release: its secrets come from the Helm part
    my $why = need_parts('Helm');
    plan skip_all => $why if $why;
    my $s = clone($start);
    like( run( $s, 'kubectl get certificate -n shop' ), qr/internal\s+False\s+internal-tls.*\n.*shop-tls\s+True\s+shop-tls/s, 'CA-Secret fehlt in cert-manager; shim-Zertifikat bereit' );
    like( run( $s, 'kubectl describe clusterissuer internal-ca' ), qr/Error getting keypair for CA issuer: secrets "root-ca" not found/, 'Grund am Issuer' );
    is( run( $s, 'kubectl exec -n shop deploy/web -- curl -s https://shop.example.com/' ), 'hallo von web', 'TLS mit ausgestelltem Zertifikat gueltig' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- curl -s https://www.shop.example.com/' ), qr/curl: \(60\)/, 'www nicht im Zertifikat (kein Ingress-Host -> Ersatzzertifikat)' );
    my ( $o, $ok ) = run( $s, 'kubectl create secret tls root-ca -n cert-manager --cert=/root/ca.crt --key=/root/ca.key' );
    ok( $ok, 'create secret tls' ) or diag $o;
    like( run( $s, 'kubectl get cert internal -n shop' ), qr/internal\s+True/, 'jetzt bereit' );
    like( run( $s, 'kubectl get secret internal-tls -n shop' ), qr{internal-tls\s+kubernetes\.io/tls\s+2}, 'Secret ausgestellt' );
    run( $s, q{kubectl -n shop annotate ingress web cert-manager.io/cluster-issuer=staging --overwrite} );
    like( run( $s, 'kubectl get certificaterequests -n shop' ), qr/shop-tls-1\s+True\s+False/, 'unbekannter Issuer: Request nicht bereit' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- curl -s https://shop.example.com/' ), qr/self-signed/, 'Ersatzzertifikat' );
    my $s2 = clone($start);
    $s2->{admin1}{kubernetes}{clusterissuers}{letsencrypt}{spec}{acme}{solvers}[0]{http01}{ingress}{ingressClassName} = 'traefik';
    like( run( $s2, 'kubectl get challenges -n shop' ), qr/pending\s+shop\.example\.com/, 'HTTP-01 ueber eine fremde Klasse haengt' );
    like( run( $s2, 'kubectl describe challenge -n shop' ), qr/wrong status code '404'/, 'mit Grund' );
    like( run( $s2, q{kubectl get challenges -n shop -o jsonpath='{.items[0].status.state}'} ), qr/\Apending\z/, 'Challenge als JSON' );
    my $y = run( $s2, 'kubectl get certificate shop-tls -n shop -o yaml' );
    unlike( $y, qr/\A_|\n_/, 'keine Felder der Simulation' );
    like( $y, qr/ownerReferences:\n\s+- apiVersion: networking\.k8s\.io\/v1/, 'Besitzer wie echt' );
};

subtest 'RBAC' => sub {
    my $s = clone($start);
    like( run( $s, 'kubectl get pods -n shop' ), qr/op-\S+\s+0\/1\s+CrashLoopBackOff/, 'ohne Recht: CrashLoop' );
    like( run( $s, 'kubectl logs -n shop deploy/op' ), qr{pods is forbidden: User \\"system:serviceaccount:shop:op\\" cannot list resource \\"pods\\" in API group \\"\\" in the namespace \\"shop\\"}, 'Meldung im Log' );
    my ( $o, $ok ) = run( $s, 'kubectl auth can-i list pods -n shop --as=system:serviceaccount:shop:op' );
    is_deeply( [ $o, $ok ], [ 'no', 0 ], 'can-i: no, Exit 1' );
    ok( ( run( $s, 'kubectl create role pod-reader -n shop --verb=get,list,watch --resource=pods' ) )[1], 'create role' );
    ok( ( run( $s, 'kubectl create rolebinding op-read -n shop --role=pod-reader --serviceaccount=shop:op' ) )[1], 'create rolebinding' );
    is( run( $s, 'kubectl auth can-i list pods -n shop --as=system:serviceaccount:shop:op' ), 'yes', 'jetzt erlaubt' );
    is( run( $s, 'kubectl auth can-i get pods/log -n shop --as=system:serviceaccount:shop:op' ), 'no', 'Unterressource nicht' );
    is( run( $s, 'kubectl auth can-i list pods -n default --as=system:serviceaccount:shop:op' ), 'no', 'anderer Namespace nicht' );
    like( run( $s, 'kubectl get pods -n shop' ), qr/op-\S+\s+1\/1\s+Running/, 'Pod laeuft' );
    is_deeply( $K->($s)->{namespaces}{shop}{roles}{'pod-reader'}, { rules => [ { apiGroups => [''], resources => ['pods'], verbs => [qw( get list watch )] } ] }, 'Role im Zustand' );
    ( $o, $ok ) = run( $s, q{kubectl -n shop patch rolebinding op-read --type merge -p '{"roleRef":{"kind":"ClusterRole","name":"view"}}'} );
    ok( !$ok && $o =~ /cannot change roleRef/, 'roleRef unveraenderlich' ) or diag $o;
    ( $o, $ok ) = run( $s, q{kubectl -n shop patch rolebinding op-read --type json -p '[{"op":"replace","path":"/roleRef/name","value":"view"}]'} );
    ok( !$ok && $o =~ /cannot change roleRef/, 'auch per JSON-Patch' ) or diag $o;
    ( $o, $ok ) = run( $s, q{kubectl -n shop patch rolebinding op-read --type json -p '[{"op":"add","path":"/subjects/-","value":{"kind":"User","name":"eve"}}]'} );
    like( $o, qr/op-read patched\z/, 'JSON-Patch meldet die Aenderung (nicht "no change")' );
    run( $s, 'kubectl create rolebinding dev-view -n shop --clusterrole=view --group=team-shop' );
    is( run( $s, 'kubectl auth can-i list deployments.apps -n shop --as=jane --as-group=team-shop' ), 'yes', 'Gruppe mit view' );
    is( run( $s, 'kubectl auth can-i get secrets -n shop --as=jane --as-group=team-shop' ), 'no', 'view liest keine Secrets' );
    run( $s, 'kubectl create role one-secret -n shop --verb=get --resource=secrets --resource-name=root-ca' );
    run( $s, 'kubectl create rolebinding one-secret -n shop --role=one-secret --user=bob' );
    is( run( $s, 'kubectl auth can-i get secrets/root-ca -n shop --as=bob' ), 'yes', 'resourceNames: der eine' );
    is( run( $s, 'kubectl auth can-i get secrets/other -n shop --as=bob' ), 'no', 'resourceNames: kein anderer' );
    my $s2 = clone($start);
    delete $K->($s2)->{namespaces}{shop}{serviceaccounts}{op};
    unlike( run( $s2, 'kubectl get pods -n shop' ), qr/\bop-/, 'ohne ServiceAccount keine Pods' );
    like( run( $s2, 'kubectl get events -n shop' ), qr/FailedCreate.*serviceaccount "op" not found/, 'Ereignis nennt ihn' );
    like( run( $s2, 'kubectl get rs -n shop' ), qr/op-\S+\s+1\s+0\s+0/, 'ReplicaSet ohne Pods' );
    like( run( $s2, 'kubectl describe rs -n shop op' ), qr/ReplicaFailure\s+True\s+FailedCreate.*serviceaccount "op" not found/s, 'describe rs nennt den Grund' );
    like( run( $s2, 'kubectl api-versions' ), qr{^cert-manager\.io/v1$}m, 'api-versions' );
    is( run( $s2, 'which kubectl helm' ), "/usr/local/bin/kubectl\n/usr/local/bin/helm", 'which' );
    is( run( $s2, 'which python3' ), '/usr/bin/python3', 'python3: vorhanden, nicht nachgebildet (wie in main)' );
    ok( ( run( $s2, 'kubectl create sa op -n shop' ) )[1], 'create sa' );
    like( run( $s2, 'kubectl get pods -n shop' ), qr/\bop-/, 'dann Pods' );
};

subtest 'jsonpath, custom-columns, base64, openssl' => sub {
    # the start state carries a Helm release: its secrets come from the Helm part
    my $why = need_parts('Helm');
    plan skip_all => $why if $why;
    my $s = clone($start);
    is( run( $s, q{kubectl get deploy -n shop -o jsonpath='{range .items[*]}{.metadata.name}={.spec.template.spec.containers[0].image}{"\n"}{end}'} ),
        "api=registry.example.com/api:1\nop=registry.example.com/op:1\nshop=registry.example.com/shop:1\nweb=registry.example.com/web:1", 'range mit Literal' );
    is( run( $s, q{kubectl get deploy web -n shop -o jsonpath={.spec.replicas}} ), '1', 'ein Objekt' );
    like( run( $s, q{POD=$(kubectl get pods -n shop -l app=web -o name | head -1); kubectl logs -n shop $POD; echo "${POD}"} ), qr{\Apod/web-\S+\z}, 'Shell-Variablen' );
    is( run( $s, q{printf hallo | wc -c} ), '5', 'wc -c aus der Pipe' );
    like( run( $s, q{kubectl exec -n shop deploy/web -- sh -c 'echo | timeout 5 openssl s_client -connect 203.0.113.10:443 -servername shop.example.com > /tmp/out.txt 2>&1; grep subject= /tmp/out.txt'} ),
        qr/\Asubject=CN = shop\.example\.com\z/, 'Shell im Pod: Umleitung in eine Datei des Pods, openssl ueber den Cluster' );
    is( run( $s, q{kubectl exec -n shop deploy/web -- sh -c 'curl -s http://api/ && echo'} ), 'hallo von api', 'curl in der Pod-Shell' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- cat /etc/resolv.conf' ), qr/search shop\.svc\.cluster\.local/, 'Dateien des Pods' );
    ok( !$K->($s)->{namespaces}{shop}{pods}, 'Pod-Shell aendert den Cluster nicht' );
    is( run( $s, q{kubectl get pods -n shop -o name | awk '{print $NF}' | wc -l} ), run( $s, 'kubectl get pods -n shop -o name | wc -l' ), 'awk-Felder bleiben unberuehrt' );
    is( run( $s, q{kubectl get ingress -n shop -o jsonpath='{.items[0].spec.rules[0].http.paths[?(@.path=="/api")].backend.service.name}'} ), 'api', 'Filter' );
    is( run( $s, q{kubectl get secret root-ca -n shop -o jsonpath='{.data.tls\.crt}' | base64 -d} ), 'x', 'Punkt im Schluessel, base64 -d' );
    like( run( $s, 'kubectl get svc -n shop -o custom-columns=NAME:.metadata.name,PORT:.spec.ports[0].port' ), qr/\ANAME\s+PORT\napi\s+80\nweb\s+80\z/, 'custom-columns' );
    like( run( $s, 'kubectl exec -n shop deploy/web -- openssl s_client -connect shop.example.com:443 -servername shop.example.com' ), qr/subject=CN = shop\.example\.com\nissuer=C = US, O = Let's Encrypt.*Verify return code: 0 \(ok\)/s, 's_client: gueltig' );
    like( run( $s, 'openssl s_client -connect 203.0.113.10:443 -servername www.shop.example.com | openssl x509 -noout -subject' ), qr/\Asubject=O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate\z/, 'Ersatzzertifikat, x509 aus der Pipe' );
    like( run( $s, q{kubectl get secret shop-tls -n shop -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -ext subjectAltName} ), qr/DNS:shop\.example\.com/, 'SAN des ausgestellten Zertifikats' );
};

subtest 'Helm' => sub {
    # the start state carries a Helm release: its secrets come from the Helm part
    my $why = need_parts('Helm');
    plan skip_all => $why if $why;
    my $s = clone($start);
    like( run( $s, 'helm list -n shop' ), qr/shop\s+shop\s+2\s+.*deployed\s+shop-1\.0\.0\s+1/, 'list' );
    like( run( $s, 'helm get values shop -n shop' ), qr/USER-SUPPLIED VALUES:\ndebug: true\nreplicaCount: 3/, 'get values' );
    is( run( $s, 'helm get values shop -n shop -o json' ), '{"debug":true,"replicaCount":3}', 'get values -o json kompakt wie Helm' );
    like( run( $s, 'helm get manifest shop -n shop' ), qr/replicas: 3/, 'manifest der aktuellen Revision' );
    like( run( $s, 'helm get manifest shop -n shop --revision 1' ), qr/replicas: 1\b/, 'manifest einer alten Revision: aus deren Werten' );
    # Release-Secret wie Helm 3: base64 (kubectl) ueber base64 ueber gzip ueber JSON
    my $rel = run( $s, q{kubectl get secret sh.helm.release.v1.shop.v1 -n shop -o jsonpath='{.data.release}' | base64 -d | base64 -d | gzip -d} );
    like( $rel, qr/"config":\{\}.*"manifest":"---\\n# Source: shop.*replicas: 1\b.*"name":"shop".*"version":1/s, 'Release-Secret entpackt: Revision 1' );
    like( run( $s, q{kubectl get secret sh.helm.release.v1.shop.v2 -n shop -o jsonpath='{.data.release}' | base64 -d | base64 -d | zcat} ), qr/"config":\{"debug":true,"replicaCount":3\}/, 'zcat, Werte von Revision 2' );
    like( run( $s, 'helm get all shop -n shop' ), qr/STATUS: deployed\nREVISION: 2.*USER-SUPPLIED VALUES:.*MANIFEST:\n---/s, 'helm get all' );
    like( run( $s, 'helm get metadata shop -n shop' ), qr/CHART: shop\nVERSION: 1\.0\.0/, 'helm get metadata' );
    like( run( $s, 'helm env' ), qr/HELM_DRIVER="secret"/, 'helm env' );
    my $before = $J->encode( $K->($s) );
    like( run( $s, 'helm template shop example/shop --version 1.0.0 --set replicaCount=5' ), qr/replicas: 5/, 'helm template rendert' );
    is( $J->encode( $K->($s) ), $before, '... und aendert nichts' );
    my ( $o, $ok ) = run( $s, 'helm upgrade shop example/shop -n shop --version 1.0.0 --set image.tag=1' );
    ok( $ok, 'upgrade ohne --reuse-values' ) or diag $o;
    is_deeply( $K->($s)->{helm}{releases}{shop}{shop}{values}, { image => { tag => 1 } }, 'alte Werte fallen weg' );
    is( $K->($s)->{namespaces}{shop}{deployments}{shop}{replicas}, 1, 'replicaCount wieder Vorgabe' );
    ok( !$K->($s)->{namespaces}{shop}{deployments}{shop}{template}{containers}[0]{env} || !@{ $K->($s)->{namespaces}{shop}{deployments}{shop}{template}{containers}[0]{env} }, 'DEBUG weg' );
    is( $K->($s)->{namespaces}{shop}{deployments}{shop}{generation}, 3, 'Vorlage geaendert: generation +1' );
    run( $s, 'helm rollback shop 2 -n shop' );
    is_deeply( $K->($s)->{helm}{releases}{shop}{shop}{values}, { replicaCount => 3, debug => $T }, 'rollback: Werte von Revision 2' );
    is( $K->($s)->{helm}{releases}{shop}{shop}{revision}, 4, 'als Revision 4' );
    ( $o, $ok ) = run( $s, 'helm upgrade shop example/shop -n shop --version 1.0.0 --reuse-values --set image.tag=1' );
    is_deeply( $K->($s)->{helm}{releases}{shop}{shop}{values}, { replicaCount => 3, debug => $T, image => { tag => 1 } }, '--reuse-values legt auf die alten' );
    run( $s, 'helm upgrade shop example/shop -n shop --version 1.0.0' );
    is_deeply( $K->($s)->{helm}{releases}{shop}{shop}{values}, { replicaCount => 3, debug => $T, image => { tag => 1 } }, 'ohne neue Werte bleiben die alten' );
    run( $s, 'helm upgrade shop example/shop -n shop -f /root/values-prod.yaml --reuse-values' );
    is( $K->($s)->{helm}{releases}{shop}{shop}{version}, '2.0.0', 'ohne --version: neueste Chart-Version' );
    ok( !$K->($s)->{namespaces}{shop}{deployments}{shop}, '2.0.0 rendert kein Deployment: entfernt' );
    my $s2 = clone($start);
    $K->($s2)->{helm}{releases}{shop}{shop}{status} = 'pending-upgrade';
    is( run( $s2, 'helm list -n shop' ), 'NAME   NAMESPACE   REVISION   UPDATED   STATUS   CHART   APP VERSION', 'list verbirgt pending' );
    like( run( $s2, 'helm list -n shop -a' ), qr/pending-upgrade/, '-a zeigt es' );
    ( $o, $ok ) = run( $s2, 'helm upgrade shop example/shop -n shop --version 1.0.0 --reuse-values' );
    ok( !$ok && $o =~ /another operation/, 'upgrade auf pending scheitert' );
    like( run( $s2, 'kubectl get secrets -n shop' ), qr{sh\.helm\.release\.v1\.shop\.v2\s+helm\.sh/release\.v1}, 'Release-Secrets' );
    my $s3 = clone($s2);
    ok( ( run( $s2, 'helm rollback shop -n shop' ) )[1], 'rollback ohne Revision' );
    is( $K->($s2)->{helm}{releases}{shop}{shop}{status}, 'deployed', 'danach deployed' );
    is_deeply( $K->($s2)->{helm}{releases}{shop}{shop}{values}, {}, 'mit den Werten von Revision 1' );
    ok( ( run( $s3, 'kubectl delete secret sh.helm.release.v1.shop.v2 -n shop' ) )[1], 'Secret der haengenden Revision geloescht' );
    is( $K->($s3)->{helm}{releases}{shop}{shop}{revision}, 1, 'Revision 1 ist wieder die aktuelle' );
    ok( ( run( $s3, 'helm upgrade shop example/shop -n shop --version 1.0.0 --reuse-values' ) )[1], 'upgrade geht wieder' );
    like( run( $s, 'helm search repo shop --versions' ), qr/example\/shop\s+2\.0\.0.*\n.*example\/shop\s+1\.0\.0/, 'search: neueste Version zuerst' );
    ( $o, $ok ) = run( $s, 'helm diff upgrade shop example/shop' );
    ok( !$ok && $o =~ /unknown command "diff"/, 'kein diff-Plugin' );
};

done_testing;
