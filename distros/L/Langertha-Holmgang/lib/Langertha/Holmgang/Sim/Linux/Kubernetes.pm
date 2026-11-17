package Langertha::Holmgang::Sim::Linux::Kubernetes;
# ABSTRACT: Kubernetes cluster behind kubectl on a simulated Linux server — stored resources, derived status

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use Encode ();
use JSON::PP ();
use JSON::MaybeXS ();
use MIME::Base64 ();
use YAML::XS ();

our $VERSION = '0.001';


our @GAPS;

my $J = JSON::MaybeXS->new( canonical => 1, utf8 => 0, pretty => 1 );

# Ausgabe von -o json wie kubectl (Go encoding/json): "key": value, vier
# Leerzeichen. $J bleibt fuer Hashes und Vergleiche (Namen der Pods haengen daran).
my $OUT_JSON = JSON::PP->new->canonical->indent->indent_length(4)->space_after;

our %KIND = (
    pod => 'pods', pods => 'pods', po => 'pods',
    deployment => 'deployments', deployments => 'deployments', deploy => 'deployments',
    service => 'services', services => 'services', svc => 'services',
    secret => 'secrets', secrets => 'secrets',
    configmap => 'configmaps', configmaps => 'configmaps', cm => 'configmaps',
    persistentvolumeclaim => 'pvcs', persistentvolumeclaims => 'pvcs', pvc => 'pvcs',
    networkpolicy => 'networkpolicies', networkpolicies => 'networkpolicies', netpol => 'networkpolicies',
    endpoints => 'endpoints', ep => 'endpoints',
    storageclass => 'storageclasses', storageclasses => 'storageclasses', sc => 'storageclasses',
    namespace => 'namespaces', namespaces => 'namespaces', ns => 'namespaces',
    node => 'nodes', nodes => 'nodes', no => 'nodes',
    event => 'events', events => 'events', ev => 'events',
    replicaset => 'replicasets', replicasets => 'replicasets', rs => 'replicasets',
    ingress => 'ingresses', ingresses => 'ingresses', ing => 'ingresses',
    ingressclass => 'ingressclasses', ingressclasses => 'ingressclasses',
    serviceaccount => 'serviceaccounts', serviceaccounts => 'serviceaccounts', sa => 'serviceaccounts',
    role => 'roles', roles => 'roles', rolebinding => 'rolebindings', rolebindings => 'rolebindings',
    clusterrole => 'clusterroles', clusterroles => 'clusterroles',
    clusterrolebinding => 'clusterrolebindings', clusterrolebindings => 'clusterrolebindings',
    certificate => 'certificates', certificates => 'certificates', cert => 'certificates', certs => 'certificates',
    issuer => 'issuers', issuers => 'issuers', clusterissuer => 'clusterissuers', clusterissuers => 'clusterissuers',
    certificaterequest => 'certificaterequests', certificaterequests => 'certificaterequests', cr => 'certificaterequests', crs => 'certificaterequests',
    challenge => 'challenges', challenges => 'challenges', order => 'orders', orders => 'orders',
);

# Arten, die im Zustand in API-Form stehen (ohne apiVersion, kind, Name,
# Namespace und Status): [ apiVersion, kind, ohne Namespace, Name fuer Meldungen ]
our %GEN = (
    ingresses           => [ 'networking.k8s.io/v1', 'Ingress', 0, 'ingress.networking.k8s.io' ],
    ingressclasses      => [ 'networking.k8s.io/v1', 'IngressClass', 1, 'ingressclass.networking.k8s.io' ],
    serviceaccounts     => [ 'v1', 'ServiceAccount', 0, 'serviceaccount' ],
    roles               => [ 'rbac.authorization.k8s.io/v1', 'Role', 0, 'role.rbac.authorization.k8s.io' ],
    rolebindings        => [ 'rbac.authorization.k8s.io/v1', 'RoleBinding', 0, 'rolebinding.rbac.authorization.k8s.io' ],
    clusterroles        => [ 'rbac.authorization.k8s.io/v1', 'ClusterRole', 1, 'clusterrole.rbac.authorization.k8s.io' ],
    clusterrolebindings => [ 'rbac.authorization.k8s.io/v1', 'ClusterRoleBinding', 1, 'clusterrolebinding.rbac.authorization.k8s.io' ],
    certificates        => [ 'cert-manager.io/v1', 'Certificate', 0, 'certificate.cert-manager.io' ],
    issuers             => [ 'cert-manager.io/v1', 'Issuer', 0, 'issuer.cert-manager.io' ],
    clusterissuers      => [ 'cert-manager.io/v1', 'ClusterIssuer', 1, 'clusterissuer.cert-manager.io' ],
);
# abgeleitet, nur zum Lesen
our %DERIVED = map { $_ => 1 } qw( certificaterequests challenges orders );
our %CLUSTER = ( ( map { $_ => 1 } qw( namespaces storageclasses nodes ) ), map { $_ => 1 } grep { $GEN{$_}[2] } keys %GEN );
our %SINGULAR = ( pods => 'pod', deployments => 'deployment.apps', services => 'service', secrets => 'secret',
    configmaps => 'configmap', pvcs => 'persistentvolumeclaim', networkpolicies => 'networkpolicy.networking.k8s.io',
    storageclasses => 'storageclass.storage.k8s.io', namespaces => 'namespace', endpoints => 'endpoints', nodes => 'node',
    replicasets => 'replicaset.apps', ( map { $_ => $GEN{$_}[3] } keys %GEN ),
    certificaterequests => 'certificaterequest.cert-manager.io', challenges => 'challenge.acme.cert-manager.io', orders => 'order.acme.cert-manager.io' );
my %APIKIND = ( deployments => 'Deployment', services => 'Service', secrets => 'Secret', configmaps => 'ConfigMap',
    pvcs => 'PersistentVolumeClaim', networkpolicies => 'NetworkPolicy', storageclasses => 'StorageClass', namespaces => 'Namespace',
    map { $_ => $GEN{$_}[1] } keys %GEN );
my %FROM_APIKIND = reverse %APIKIND;

sub _hash { my ($t) = @_; my $h = Digest::SHA::sha1_hex( $J->encode($t) ); $h =~ tr/0-9a-f/bcdfghjklmnpqrst/; return substr( $h, 0, 10 ) }

sub _sel_match {
    my ( $sel, $labels ) = @_;
    for my $k ( keys %{ $sel || {} } ) { return 0 unless defined $labels->{$k} && $labels->{$k} eq $sel->{$k} }
    return 1;
}

# --- abgeleiteter Zustand ------------------------------------------------------

sub _pvc_phase {
    my ( $k, $ns, $name ) = @_;
    my $p = $k->{namespaces}{$ns}{pvcs}{$name} or return 'Missing';
    my $sc = $p->{storage_class};
    my $scs = $k->{storageclasses} || {};
    return 'Bound' if defined $sc ? $scs->{$sc} : grep { $scs->{$_}{default} } keys %$scs;
    return 'Pending';
}

# Status eines Containers bzw. Pods einer Vorlage: ( phase, ready(0/1), reason, message )
sub _pod_state {
    my ( $k, $ns, $tpl ) = @_;
    my $o = $k->{namespaces}{$ns};
    for my $c ( @{ $tpl->{containers} || [] } ) {
        for my $v ( @{ $c->{volumes} || [] } ) {
            my $ph = _pvc_phase( $k, $ns, $v->{claim} );
            return ( 'Pending', 0, 'Unschedulable', $ph eq 'Missing'
                ? qq{persistentvolumeclaim "$v->{claim}" not found}
                : '0/3 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.' )
                if $ph ne 'Bound';
        }
    }
    for my $c ( @{ $tpl->{containers} || [] } ) {
        my %reg = map { $_ => 1 } @{ $k->{registry} || [] };
        return ( 'Pending', 0, 'ImagePullBackOff', qq{Back-off pulling image "$c->{image}"}, $c ) unless $reg{ $c->{image} };
        my %env;
        for my $e ( @{ $c->{env} || [] } ) {
            if ( defined $e->{secret} ) {
                my $s = $o->{secrets}{ $e->{secret} };
                return ( 'Pending', 0, 'CreateContainerConfigError', qq{secret "$e->{secret}" not found}, $c ) if !$s && !$e->{optional};
                if ( $s && exists $s->{ $e->{key} } ) { $env{ $e->{name} } = 1 }
                elsif ( !$e->{optional} ) { return ( 'Pending', 0, 'CreateContainerConfigError', qq{couldn't find key $e->{key} in Secret $ns/$e->{secret}}, $c ) }
            }
            elsif ( defined $e->{configmap} ) {
                my $m = $o->{configmaps}{ $e->{configmap} };
                $env{ $e->{name} } = 1 if $m && exists $m->{ $e->{key} };
            }
            else { $env{ $e->{name} } = 1 }
        }
        return ( 'Running', 0, 'CrashLoopBackOff', 'back-off 5m0s restarting failed container', $c ) if grep { !$env{$_} } @{ $c->{needs_env} || [] };
        if ( my $deny = _rbac_denied( $k, $ns, $tpl, $c ) ) {
            return ( 'Running', 0, 'CrashLoopBackOff', 'back-off 5m0s restarting failed container',
                { %$c, crash_log => [ @{ $c->{rbac_log} || [] }, defined $c->{rbac_prefix} ? $c->{rbac_prefix} . $deny : 'level=fatal msg="' . ( $deny =~ s/"/\\"/gr ) . '"' ] } );
        }
    }
    for my $c ( @{ $tpl->{containers} || [] } ) {
        my $r = $c->{readiness} or next;
        return ( 'Running', 0, 'NotReady', "Readiness probe failed: Get \"http://10.42.1.17:$r->{port}" . ( $r->{path} // '/' ) . "\": dial tcp 10.42.1.17:$r->{port}: connect: connection refused", $c )
            unless grep { $_ == $r->{port} } @{ $c->{listens} || $c->{ports} || [] };
    }
    return ( 'Running', 1, '', '' );
}

# Pods aller Deployments eines Namespace
sub _pods {
    my ( $k, $ns ) = @_;
    my @p;
    my $o = $k->{namespaces}{$ns} or return ();
    for my $d ( sort keys %{ $o->{deployments} || {} } ) {
        my $dep = $o->{deployments}{$d};
        next unless _sa_exists( $k, $ns, $dep->{template}{service_account} );    # ReplicaSet kann keine Pods anlegen
        my $h = _hash( [ $dep->{template}, $dep->{restarted_at} // '' ] );
        my ( $phase, $ready, $reason, $msg, $c ) = _pod_state( $k, $ns, $dep->{template} );
        for my $i ( 1 .. ( $dep->{replicas} // 1 ) ) {
            my $suffix = substr( _hash( [ $h, $i ] ), 0, 5 );
            push @p, { name => "$d-$h-$suffix", deployment => $d, labels => { %{ $dep->{template}{labels} || {} }, 'pod-template-hash' => $h },
                phase => $phase, ready => $ready, reason => $reason, message => $msg, container => $c, template => $dep->{template},
                restarts => $reason eq 'CrashLoopBackOff' ? 7 : 0, ip => "10.42." . ( $i % 3 + 1 ) . '.' . ( 10 + ( hex( substr( Digest::SHA::sha1_hex($d), 0, 4 ) ) % 200 ) + $i ) };    # je Deployment eigene Adressen
        }
    }
    return @p;
}

sub _endpoints {
    my ( $k, $ns, $svc ) = @_;
    my $s = $k->{namespaces}{$ns}{services}{$svc} or return ();
    return grep { $_->{ready} && _sel_match( $s->{selector}, $_->{labels} ) } _pods( $k, $ns );
}

# --- Ausgabe ------------------------------------------------------------------

sub _cols {
    my (@rows) = @_;
    my @w;
    for my $r (@rows) { for ( 0 .. $#$r ) { $w[$_] = length $r->[$_] if !defined $w[$_] || length $r->[$_] > $w[$_] } }
    return join "\n", map { my $r = $_; join( '   ', map { $_ == $#$r ? $r->[$_] : sprintf( "%-$w[$_]s", $r->[$_] ) } 0 .. $#$r ) =~ s/\s+\z//r } @rows;
}

sub _age { return $_[0] // '3d' }

sub _labels_text { my ($l) = @_; return join( ',', map {"$_=$l->{$_}"} sort keys %{ $l || {} } ) || '<none>' }

# --- Kommandozeile -------------------------------------------------------------


sub kubectl {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my $k = $dev->{kubernetes} or return ( 'error: no configuration has been provided, try setting KUBERNETES_MASTER environment variable', 0 );
    my %o = ( ns => $k->{default_namespace} // 'default' );
    my @a;
    my @in = @$av;
    while (@in) {
        my $x = shift @in;
        if    ( $x eq '-n' || $x eq '--namespace' ) { $o{ns} = shift @in }
        elsif ( $x =~ /\A(?:-n|--namespace=)(.+)\z/ ) { $o{ns} = $1 }
        elsif ( $x eq '-A' || $x eq '--all-namespaces' ) { $o{all} = 1 }
        elsif ( $x eq '-o' || $x eq '--output' ) { $o{out} = shift @in }
        elsif ( $x =~ /\A(?:-o|--output=)(.+)\z/ ) { $o{out} = $1 }
        elsif ( $x eq '-l' || $x eq '--selector' ) { $o{sel} = shift @in }
        elsif ( $x =~ /\A(?:-l|--selector=)(.+)\z/ ) { $o{sel} = $1 }
        elsif ( $x eq '-f' || $x eq '--filename' ) { push @{ $o{files} }, shift @in }
        elsif ( $x =~ /\A--filename=(.+)\z/ ) { push @{ $o{files} }, $1 }
        elsif ( $x eq '-p' || $x eq '--patch' ) { $o{patch} = shift @in }
        elsif ( $x =~ /\A(?:--patch|-p)=(.+)\z/s ) { $o{patch} = $1 }
        elsif ( $x =~ /\A--type=(.+)\z/ ) { $o{type} = $1 }
        elsif ( $x eq '--type' ) { $o{type} = shift @in }
        elsif ( $x =~ /\A--replicas=(\d+)\z/ ) { $o{replicas} = $1 }
        elsif ( $x =~ /\A--from-literal=([^=]+)=(.*)\z/s ) { push @{ $o{literal} }, [ $1, $2 ] }
        elsif ( $x =~ /\A--from-file=(?:([^=]+)=)?(.+)\z/s ) { push @{ $o{from_file} }, [ $1, $2 ] }
        elsif ( $x eq '--show-labels' ) { $o{show_labels} = 1 }
        elsif ( $x eq '--previous' || $x eq '-p' && 0 ) { $o{previous} = 1 }
        elsif ( $x =~ /\A--tail(?:=(\d+))?\z/ ) { $o{tail} = $1 // shift @in }
        elsif ( $x eq '-c' || $x eq '--container' ) { $o{container} = shift @in }
        # set env: --containers, --from=secret/x, --keys, --prefix
        elsif ( $x =~ /\A(?:-c|--containers?)=(.+)\z/ ) { $o{container} = $1 }
        elsif ( $x eq '--containers' ) { $o{container} = shift @in }
        elsif ( $x =~ /\A--(from|keys|prefix)=(.*)\z/s ) { $o{"env_$1"} = $2 }
        elsif ( $x =~ /\A--(from|keys|prefix)\z/ ) { $o{"env_$1"} = shift @in }
        elsif ( $x eq '--list' ) { $o{env_list} = 1 }
        elsif ( $x eq '--' ) { $o{rest} = [@in]; last }
        # create role|rolebinding|secret tls …, auth can-i, annotate
        elsif ( $x =~ /\A--(verb|resource-name|resource|role|clusterrole|serviceaccount|user|group|cert|key|as-group|as)(?:=(.*))?\z/s ) { push @{ $o{f}{$1} }, defined $2 ? $2 : shift @in }
        elsif ( $x eq '--list' ) { $o{list} = 1 }
        # Reihenfolge der Zeilen spielt hier keine Rolle; Feldfilter sind nicht nachgebildet
        elsif ( $x =~ /\A--sort-by(?:=.+)?\z/ ) { shift @in if $x eq '--sort-by' }
        elsif ( $x =~ /\A--field-selector(?:=(.+))?\z/ ) { push @GAPS, 'kubectl --field-selector ' . ( $1 // shift(@in) // '' ) }
        elsif ( $x =~ /\A--(?:overwrite|wait|now|force|all|dry-run=\w+|record|grace-period=\d+|timeout=\S+|watch=false)\z/ ) { $o{flags}{$x} = 1 }
        elsif ( $x eq '-w' || $x eq '--watch' || $x eq '-it' || $x eq '-i' || $x eq '-t' || $x eq '--stdin' || $x eq '--tty' ) { $o{interactive} = $x }
        elsif ( $x =~ /\A-/ ) { return ( "error: unknown flag: $x\nSee 'kubectl --help' for usage.", 0 ) }
        else { push @a, $x }
    }
    if ( ( $o{out} // '' ) =~ /\A(jsonpath|custom-columns)(?:-as-json)?=(.*)\z/s && ( $a[0] // '' ) eq 'get' ) {
        my ( $how, $expr ) = ( $1, $2 );
        my $copy = JSON::MaybeXS->new( canonical => 1 )->decode( JSON::MaybeXS->new( canonical => 1 )->encode($k) );
        my ( $j, $ok ) = _v_get( $copy, [ @a[ 1 .. $#a ] ], { %o, out => 'json' } );
        return ( $j, 0 ) unless $ok;
        my $data = eval { JSON::MaybeXS->new->decode($j) };
        unless ( ref $data ) { push @GAPS, "kubectl -o $how"; return ( '', 0 ) }
        # ohne Namen ist es immer eine Liste (auch mit einem Eintrag)
        $data = { apiVersion => 'v1', kind => 'List', items => [$data] } if ( $data->{kind} // '' ) ne 'List' && !defined $a[2] && ( $a[1] // '' ) !~ m{/};
        my ( $out, $err ) = $how eq 'jsonpath' ? jsonpath( $data, $expr ) : _custom_columns( $data, $expr );
        return defined $err ? ( $err, 0 ) : ( $out, 1 );
    }
    if ( ( $o{out} // '' ) =~ /\A(jsonpath|custom-columns|go-template|template)/ ) { push @GAPS, "kubectl -o $1"; return ( '', 0 ) }
    my $verb = shift(@a) // return ( "kubectl controls the Kubernetes cluster manager.\n\nUse \"kubectl <command> --help\" for more information about a given command.", 1 );
    ( my $sub = "_v_$verb" ) =~ s/-/_/g;
    my $f = $verb =~ /\A[a-z-]+\z/ && __PACKAGE__->can($sub) or do { push @GAPS, "kubectl $verb"; return ( '', 0 ) };
    # Lesen auf einer Kopie (kein Nebeneffekt durch Zugriffe); Aendern nur in
    # einem vorhandenen Namespace (ausser Ressourcen ohne Namespace)
    my $read = $verb =~ /\A(?:get|describe|logs|exec|version|config|cluster-info|top|explain|auth|api-resources|api-versions)\z/
        || $verb eq 'rollout' && ( $a[0] // '' ) =~ /\A(?:status|history)\z/;
    if ($read) {
        my $copy = JSON::MaybeXS->new( canonical => 1 )->decode( JSON::MaybeXS->new( canonical => 1 )->encode($k) );
        return $f->( $copy, \@a, \%o, $dev, $stdin );
    }
    my ($kind) = $verb =~ /\A(?:delete|patch|label|annotate)\z/ ? _kind_name( \@a ) : ();
    return ( qq{Error from server (NotFound): namespaces "$o{ns}" not found}, 0 )
        if !$k->{namespaces}{ $o{ns} } && $verb !~ /\A(?:apply|create)\z/ && !( $kind && $CLUSTER{$kind} );
    # gescheiterte Aenderungen hinterlassen nichts (auch keine angelegten leeren Abschnitte)
    my $copy = JSON::MaybeXS->new( canonical => 1 )->decode( JSON::MaybeXS->new( canonical => 1 )->encode($k) );
    my ( $out, $ok ) = $f->( $copy, \@a, \%o, $dev, $stdin );
    $dev->{kubernetes} = $copy if $ok;
    return ( $out, $ok );
}

sub _ns_list { my ( $k, $o ) = @_; return $o->{all} ? sort keys %{ $k->{namespaces} || {} } : ( $o->{ns} ) }

sub _kind_name {
    my ( $a ) = @_;
    my ( $kind, $name ) = @$a;
    ( $kind, $name ) = split m{/}, $kind, 2 if defined $kind && $kind =~ m{/};
    ( my $base = lc( $kind // '' ) ) =~ s/\.(?:apps|networking\.k8s\.io|storage\.k8s\.io|rbac\.authorization\.k8s\.io|cert-manager\.io|acme\.cert-manager\.io)\z//;
    return ( $KIND{$base}, $name, $kind );
}

sub _v_version { return ( "Client Version: v1.30.4\nKustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3\nServer Version: v1.30.4+k3s1", 1 ) }

sub _v_config {
    my ( $k, $a ) = @_;
    return ( $k->{context} // 'default', 1 ) if ( $a->[0] // '' ) eq 'current-context';
    push @GAPS, "kubectl config @$a";
    return ( '', 0 );
}

sub _v_cluster_info { return ( "Kubernetes control plane is running at https://10.30.0.10:6443\nCoreDNS is running at https://10.30.0.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy", 1 ) }

sub _v_get {
    my ( $k, $a, $o ) = @_;
    # mehrere Arten (pods,svc): je Art ein Block, Namen mit Art davor wie kubectl
    if ( ( $a->[0] // '' ) =~ /,/ && $a->[0] !~ m{/} ) {
        my @out;
        for my $kind ( split /,/, $a->[0] ) {
            my ( $t, $ok ) = _v_get( $k, [ $kind, @$a[ 1 .. $#$a ] ], $o );
            return ( $t, 0 ) unless $ok;
            my $pre = ( $SINGULAR{ $KIND{ lc $kind } // '' } // $kind ) . '/';
            $t =~ s/^(?!NAME\b|NAMESPACE\b|No resources)(\S)/$pre$1/mg unless $o->{all};
            push @out, $t;
        }
        return ( join( "\n\n", @out ), 1 );
    }
    # mehrere Namen einer Art (get svc a b): eine Tabelle, ein Kopf
    if ( @$a > 2 && $a->[0] !~ m{/} && !grep {m{/}} @$a ) {
        my @out;
        for my $n ( @$a[ 1 .. $#$a ] ) {
            my ( $t, $ok ) = _v_get( $k, [ $a->[0], $n ], $o );
            return ( $t, 0 ) unless $ok;
            $t =~ s/\A[^\n]*\n?// if @out && $t =~ /\A(?:NAME|NAMESPACE)\b/;
            push @out, $t;
        }
        return ( join( "\n", @out ), 1 );
    }
    my ( $kind, $name, $raw ) = _kind_name($a);
    return ( qq{error: the server doesn't have a resource type "} . ( $raw // '' ) . '"', 0 ) unless $kind;
    if ( $kind eq 'namespaces' ) {
        my @n = grep { !defined $name || $_ eq $name } sort keys %{ $k->{namespaces} };
        return ( qq{Error from server (NotFound): namespaces "$name" not found}, 0 ) if defined $name && !@n;
        return ( _cols( [qw( NAME STATUS AGE )], map { [ $_, 'Active', '41d' ] } @n ), 1 );
    }
    if ( $kind eq 'nodes' ) {
        return ( _cols( [qw( NAME STATUS ROLES AGE VERSION )], map { [ $_, $k->{nodes}{$_}{ready} ? 'Ready' : 'NotReady', $k->{nodes}{$_}{roles} // '<none>', '41d', 'v1.30.4+k3s1' ] } sort keys %{ $k->{nodes} || {} } ), 1 );
    }
    if ( $kind eq 'storageclasses' ) {
        my $s = $k->{storageclasses} || {};
        my @n = grep { !defined $name || $_ eq $name } sort keys %$s;
        return ( qq{Error from server (NotFound): storageclasses.storage.k8s.io "$name" not found}, 0 ) if defined $name && !@n;
        return _structured( $o, 'storageclasses', { map { $_ => $s->{$_} } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
        return ( _cols( [qw( NAME PROVISIONER RECLAIMPOLICY VOLUMEBINDINGMODE ALLOWVOLUMEEXPANSION AGE )],
            map { [ $_ . ( $s->{$_}{default} ? ' (default)' : '' ), $s->{$_}{provisioner} // 'kubernetes.io/no-provisioner', 'Delete', 'Immediate', 'false', '41d' ] } @n ), 1 );
    }
    if ( $GEN{$kind} || $DERIVED{$kind} ) {
        my $cluster = $GEN{$kind} && $GEN{$kind}[2];
        my $multi = $o->{all} && !$cluster;
        my @rows;
        for my $ns ( $cluster ? (undef) : _ns_list( $k, $o ) ) {
            my @r;
            if ( $DERIVED{$kind} && $o->{out} && $o->{out} =~ /\A(yaml|json)/ ) {
                my $objs = _derived_objs( $k, $kind, $ns );
                my @n = grep { !defined $name || $_ eq $name } sort keys %$objs;
                return ( qq{Error from server (NotFound): $SINGULAR{$kind} "$name" not found}, 0 ) if defined $name && !@n;
                my $data = @n == 1 && defined $name ? $objs->{ $n[0] } : { apiVersion => 'v1', kind => 'List', items => [ @{$objs}{@n} ] };
                return ( $1 eq 'json' ? $OUT_JSON->encode($data) =~ s/\s+\z//r : do { local $YAML::XS::Boolean = 'JSON::PP'; YAML::XS::Dump($data) =~ s/\A---\n//r =~ s/\s+\z//r }, 1 );
            }
            if ( $DERIVED{$kind} ) {
                ( undef, @r ) = _derived_rows( $k, $kind, $ns );
                @r = grep { $_->[0] eq $name } @r if defined $name;
            }
            else {
                my ( $res, $err ) = _gen_rows( $k, $kind, $ns, $o, $name );
                if ( !$res ) { next if $multi; return ( $err, 0 ) }
                return _structured( { %$o, ns => $ns }, $kind, $res ) if ref $res eq 'HASH';
                ( undef, @r ) = @$res;
            }
            return ( join( "\n", map { "$SINGULAR{$kind}/$_->[0]" } @r ), 1 ) if ( $o->{out} // '' ) eq 'name';
            push @rows, map { [ ( $multi ? $ns : () ), @$_ ] } @r;
        }
        return ( qq{Error from server (NotFound): $SINGULAR{$kind} "$name" not found}, 0 ) if defined $name && !@rows;
        return ( $multi || $cluster ? 'No resources found' : "No resources found in $o->{ns} namespace.", 1 ) unless @rows;
        my ($head) = $DERIVED{$kind} ? _derived_rows( $k, $kind, $o->{ns} ) : @{ ( _gen_rows( $k, $kind, $o->{ns}, { %$o, out => $o->{out} && $o->{out} eq 'wide' ? 'wide' : undef }, undef ) )[0] || [ [] ] };
        return ( _cols( [ ( $multi ? 'NAMESPACE' : () ), @$head ], @rows ), 1 );
    }
    my ( @out, @all );
    my $multi = $o->{all};
    for my $ns ( _ns_list( $k, $o ) ) {
        my $obj = $k->{namespaces}{$ns} || {};
        my @rows;
        if ( $kind eq 'pods' ) {
            my @p = grep { ( !defined $name || $_->{name} eq $name ) && _label_sel( $o->{sel}, $_->{labels} ) } _pods( $k, $ns );
            return ( qq{Error from server (NotFound): pods "$name" not found}, 0 ) if defined $name && !@p;
            return ( join( "\n", map {"pod/$_->{name}"} @p ), 1 ) if ( $o->{out} // '' ) eq 'name';
            return _structured( $o, 'pods', { map { $_->{name} => _pod_obj($_) } @p } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
            push @rows, map { [ ( $multi ? $ns : () ), $_->{name}, ( $_->{ready} ? '1/1' : '0/1' ), ( $_->{reason} && $_->{reason} ne 'NotReady' && $_->{reason} ne 'Unschedulable' ? $_->{reason} : $_->{phase} ),
                $_->{restarts} . ( $_->{restarts} ? ' (2m ago)' : '' ), '12m', ( ( $o->{out} // '' ) eq 'wide' ? ( $_->{phase} eq 'Pending' && $_->{reason} eq 'Unschedulable' ? ( '<none>', '<none>' ) : ( $_->{ip}, 'node1' ) ) : () ),
                ( $o->{show_labels} ? _labels_text( $_->{labels} ) : () ) ] } @p;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME READY STATUS RESTARTS AGE ), ( ( $o->{out} // '' ) eq 'wide' ? qw( IP NODE ) : () ), ( $o->{show_labels} ? 'LABELS' : () ) ] if @rows;
        }
        elsif ( $kind eq 'deployments' ) {
            my $d = $obj->{deployments} || {};
            my @n = grep { ( !defined $name || $_ eq $name ) } sort keys %$d;
            return ( qq{Error from server (NotFound): deployments.apps "$name" not found}, 0 ) if defined $name && !@n;
            return _structured( $o, 'deployments', { map { $_ => $d->{$_} } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
            push @rows, map {
                my $n = $_;
                my @p = grep { $_->{deployment} eq $n } _pods( $k, $ns );
                my $r = grep { $_->{ready} } @p;
                [ ( $multi ? $ns : () ), $n, "$r/" . scalar(@p), scalar(@p), $r, '41d',
                    ( ( $o->{out} // '' ) eq 'wide' ? ( join( ',', map { $_->{name} } @{ $d->{$n}{template}{containers} } ), join( ',', map { $_->{image} } @{ $d->{$n}{template}{containers} } ), _labels_text( $d->{$n}{selector} ) ) : () ) ];
            } @n;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME READY UP-TO-DATE AVAILABLE AGE ), ( ( $o->{out} // '' ) eq 'wide' ? qw( CONTAINERS IMAGES SELECTOR ) : () ) ] if @rows;
        }
        elsif ( $kind eq 'services' ) {
            my $s = $obj->{services} || {};
            my @n = grep { !defined $name || $_ eq $name } sort keys %$s;
            return ( qq{Error from server (NotFound): services "$name" not found}, 0 ) if defined $name && !@n;
            return _structured( $o, 'services', { map { $_ => $s->{$_} } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
            push @rows, map { [ ( $multi ? $ns : () ), $_, $s->{$_}{type} // 'ClusterIP', $s->{$_}{cluster_ip} // '10.43.' . ( 10 + hex( substr( Digest::SHA::sha1_hex($_), 0, 2 ) ) % 200 ) . '.' . ( 10 + hex( substr( Digest::SHA::sha1_hex($_), 2, 2 ) ) % 240 ), '<none>',
                join( ',', map { "$_->{port}/TCP" } @{ $s->{$_}{ports} || [] } ), '41d', ( ( $o->{out} // '' ) eq 'wide' ? _labels_text( $s->{$_}{selector} ) : () ) ] } @n;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE ), ( ( $o->{out} // '' ) eq 'wide' ? 'SELECTOR' : () ) ] if @rows;
        }
        elsif ( $kind eq 'endpoints' ) {
            my $s = $obj->{services} || {};
            my @n = grep { !defined $name || $_ eq $name } sort keys %$s;
            return ( qq{Error from server (NotFound): endpoints "$name" not found}, 0 ) if defined $name && !@n;
            push @rows, map {
                my $svc = $s->{$_};
                my @e = _endpoints( $k, $ns, $_ );
                my @t = map { my $p = $_; map {"$_->{ip}:$p->{target}"} @e } @{ $svc->{ports} || [] };
                [ ( $multi ? $ns : () ), $_, @t ? join( ',', @t ) : '<none>', '41d' ];
            } @n;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME ENDPOINTS AGE ) ] if @rows;
        }
        elsif ( $kind eq 'pvcs' ) {
            my $p = $obj->{pvcs} || {};
            my @n = grep { !defined $name || $_ eq $name } sort keys %$p;
            return ( qq{Error from server (NotFound): persistentvolumeclaims "$name" not found}, 0 ) if defined $name && !@n;
            return _structured( $o, 'pvcs', { map { $_ => $p->{$_} } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
            push @rows, map {
                my $ph = _pvc_phase( $k, $ns, $_ );
                my $sc = $p->{$_}{storage_class} // ( grep { $k->{storageclasses}{$_}{default} } sort keys %{ $k->{storageclasses} || {} } )[0] // '';
                [ ( $multi ? $ns : () ), $_, $ph, $ph eq 'Bound' ? 'pvc-' . substr( _hash( [ $ns, $_ ] ), 0, 8 ) : '', $ph eq 'Bound' ? $p->{$_}{size} : '', $ph eq 'Bound' ? 'RWO' : '', $sc, '<unset>', '2d' ];
            } @n;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE ) ] if @rows;
            $_ = [ @$_[ 0 .. ( $multi ? 4 : 3 ) ], 'ACCESS MODES', @$_[ ( $multi ? 7 : 6 ) .. $#$_ ] ] for grep { $_->[ $multi ? 5 : 4 ] eq 'ACCESS' } @rows;
        }
        elsif ( $kind eq 'networkpolicies' ) {
            my $p = $obj->{networkpolicies} || {};
            my @n = grep { !defined $name || $_ eq $name } sort keys %$p;
            return ( qq{Error from server (NotFound): networkpolicies.networking.k8s.io "$name" not found}, 0 ) if defined $name && !@n;
            return _structured( $o, 'networkpolicies', { map { $_ => $p->{$_} } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
            push @rows, map { [ ( $multi ? $ns : () ), $_, _labels_text( $p->{$_}{pod_selector} ) =~ s/\A<none>\z/<none>/r, '41d' ] } @n;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME POD-SELECTOR AGE ) ] if @rows;
        }
        elsif ( $kind eq 'secrets' || $kind eq 'configmaps' ) {
            my $p = $kind eq 'secrets' ? _secrets_all( $k, $ns ) : $obj->{$kind} || {};
            my @n = grep { !defined $name || $_ eq $name } sort keys %$p;
            return ( qq{Error from server (NotFound): $kind "$name" not found}, 0 ) if defined $name && !@n;
            return _structured( $o, $kind, { map { $_ => $p->{$_} } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
            push @rows, map { [ ( $multi ? $ns : () ), $_, ( $kind eq 'secrets' ? _secret_type( $p->{$_} ) : () ), scalar( grep { !/\A_/ } keys %{ $p->{$_} } ), '41d' ] } @n;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), 'NAME', ( $kind eq 'secrets' ? 'TYPE' : () ), 'DATA', 'AGE' ] if @rows;
        }
        elsif ( $kind eq 'events' ) {
            my @e = map { my $p = $_; $p->{reason} ? [ '2m', $p->{reason} eq 'NotReady' || $p->{reason} eq 'CrashLoopBackOff' || $p->{reason} eq 'ImagePullBackOff' || $p->{reason} eq 'Unschedulable' ? 'Warning' : 'Normal',
                { NotReady => 'Unhealthy', CrashLoopBackOff => 'BackOff', ImagePullBackOff => 'Failed', Unschedulable => 'FailedScheduling', CreateContainerConfigError => 'Failed' }->{ $p->{reason} } // $p->{reason},
                "pod/$p->{name}", $p->{reason} eq 'ImagePullBackOff' ? qq{Failed to pull image "$p->{container}{image}": rpc error: code = NotFound desc = failed to pull and unpack image "$p->{container}{image}": failed to resolve reference "$p->{container}{image}": $p->{container}{image}: not found} : $p->{message} ] : () } _pods( $k, $ns );
            push @e, map { my $t = $obj->{deployments}{$_}{template}; _sa_exists( $k, $ns, $t->{service_account} ) ? ()
                : [ '2m', 'Warning', 'FailedCreate', "replicaset/$_-" . _hash( [ $t, $obj->{deployments}{$_}{restarted_at} // '' ] ),
                    qq{Error creating: pods "$_-} . _hash( [ $t, $obj->{deployments}{$_}{restarted_at} // '' ] ) . qq{-" is forbidden: error looking up service account $ns/$t->{service_account}: serviceaccount "$t->{service_account}" not found} ] }
                sort keys %{ $obj->{deployments} || {} };
            push @e, map { _pvc_phase( $k, $ns, $_ ) eq 'Pending' ? [ '2m', 'Warning', 'ProvisioningFailed', "persistentvolumeclaim/$_", 'storageclass.storage.k8s.io "' . ( $obj->{pvcs}{$_}{storage_class} // '' ) . '" not found' ] : () } sort keys %{ $obj->{pvcs} || {} };
            push @rows, map { [ ( $multi ? $ns : () ), @$_ ] } @e;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( LAST SEEN TYPE REASON OBJECT MESSAGE ) ] if @rows;
            $_ = [ @$_[ 0 .. ( $multi ? 0 : -1 ) ], 'LAST SEEN', @$_[ ( $multi ? 3 : 2 ) .. $#$_ ] ] for grep { $_->[ $multi ? 1 : 0 ] eq 'LAST' } @rows;
        }
        elsif ( $kind eq 'replicasets' ) {
            my @rs = _replicasets( $k, $ns );
            @rs = grep { $_->{name} eq $name } @rs if defined $name;
            return ( qq{Error from server (NotFound): replicasets.apps "$name" not found}, 0 ) if defined $name && !@rs;
            push @rows, map { [ ( $multi ? $ns : () ), $_->{name}, $_->{desired}, $_->{current}, $_->{ready}, '12m' ] } @rs;
            unshift @rows, [ ( $multi ? 'NAMESPACE' : () ), qw( NAME DESIRED CURRENT READY AGE ) ] if @rows;
        }
        if (@rows) { shift @rows if @all; push @all, @rows }    # -A: eine Tabelle, ein Kopf
    }
    push @out, _cols(@all) if @all;
    return ( @out ? join( "\n", @out ) : ( $o->{all} ? 'No resources found' : "No resources found in $o->{ns} namespace." ), 1 );
}

sub _label_sel {
    my ( $sel, $l ) = @_;
    return 1 unless defined $sel;
    for my $part ( split /,/, $sel ) {
        my ( $k, $v ) = split /=/, $part, 2;
        return 0 unless defined $l->{$k} && ( !defined $v || $l->{$k} eq $v );
    }
    return 1;
}

sub _pod_obj {
    my ($p) = @_;
    return { labels => $p->{labels}, containers => $p->{template}{containers},
        status => { phase => $p->{phase}, ready => $p->{ready} ? JSON::MaybeXS::true() : JSON::MaybeXS::false(), ( $p->{reason} ? ( reason => $p->{reason} ) : () ) } };
}

sub _structured {
    my ( $o, $kind, $objs ) = @_;
    my @items = map { _api_obj( $kind, $_, $objs->{$_}, $o->{ns} ) } sort keys %$objs;
    my $data = @items == 1 ? $items[0] : { apiVersion => 'v1', kind => 'List', items => \@items };
    return ( $o->{out} =~ /\Ajson/ ? $OUT_JSON->encode($data) =~ s/\s+\z//r : do { local $YAML::XS::Boolean = q{JSON::PP}; YAML::XS::Dump($data) } =~ s/\A---\n//r =~ s/\s+\z//r, 1 );
}

# Objekt des Zustands -> Form der API (fuer -o yaml|json); vereinfacht
sub _api_obj {
    my ( $kind, $name, $x, $ns ) = @_;
    my $meta = { name => $name, ( !$CLUSTER{$kind} ? ( namespace => $ns ) : () ) };
    if ( $GEN{$kind} ) {
        # tiefe Kopie: ein JSON-Patch aendert das Ergebnis an Ort und Stelle
        my %x = %{ JSON::MaybeXS->new( canonical => 1 )->decode( JSON::MaybeXS->new( canonical => 1 )->encode($x) ) };
        my $m = delete $x{metadata} || {};
        my $st = delete $x{_status};
        delete @x{ grep {/\A_/} keys %x };    # nur fuer die Simulation
        return { apiVersion => $GEN{$kind}[0], kind => $GEN{$kind}[1], metadata => { %$meta, %$m }, %x, ( $st ? ( status => $st ) : () ) };
    }
    if ( $kind eq 'deployments' ) {
        return { apiVersion => 'apps/v1', kind => 'Deployment', metadata => { %$meta, generation => $x->{generation} // 1 },
            spec => { replicas => $x->{replicas}, selector => { matchLabels => $x->{selector} },
                template => { metadata => { labels => $x->{template}{labels}, ( $x->{template}{annotations} ? ( annotations => $x->{template}{annotations} ) : () ) },
                    spec => { ( defined $x->{template}{service_account} ? ( serviceAccountName => $x->{template}{service_account} ) : () ), containers => [ map { _api_container($_) } @{ $x->{template}{containers} } ],
                    ( grep { @{ $_->{volumes} || [] } } @{ $x->{template}{containers} } )
                    ? ( volumes => [ map { { name => $_->{claim}, persistentVolumeClaim => { claimName => $_->{claim} } } } map { @{ $_->{volumes} || [] } } @{ $x->{template}{containers} } ] ) : () } } } };
    }
    if ( $kind eq 'services' ) {
        return { apiVersion => 'v1', kind => 'Service', metadata => $meta,
            spec => { type => $x->{type} // 'ClusterIP', selector => $x->{selector}, ports => [ map { { port => $_->{port}, targetPort => $_->{target}, protocol => 'TCP', ( $_->{name} ? ( name => $_->{name} ) : () ) } } @{ $x->{ports} || [] } ] } };
    }
    if ( $kind eq 'secrets' ) {
        return { apiVersion => 'v1', kind => 'Secret', metadata => $meta, type => _secret_type($x), data => { map { $_ => MIME::Base64::encode_base64( $x->{$_}, '' ) } grep { !/\A_/ } keys %$x } };
    }
    return { apiVersion => 'v1', kind => 'ConfigMap', metadata => $meta, data => $x } if $kind eq 'configmaps';
    if ( $kind eq 'pvcs' ) {
        return { apiVersion => 'v1', kind => 'PersistentVolumeClaim', metadata => $meta,
            spec => { accessModes => ['ReadWriteOnce'], resources => { requests => { storage => $x->{size} } }, ( defined $x->{storage_class} ? ( storageClassName => $x->{storage_class} ) : () ) } };
    }
    if ( $kind eq 'networkpolicies' ) {
        return { apiVersion => 'networking.k8s.io/v1', kind => 'NetworkPolicy', metadata => $meta,
            spec => { podSelector => { matchLabels => $x->{pod_selector} || {} }, policyTypes => ['Ingress'],
                ingress => [ map { my $r = $_; +{ ( $r->{from} ? ( from => [ map { { podSelector => { matchLabels => $_ } } } @{ $r->{from} } ] ) : () ),
                    ( $r->{ports} ? ( ports => [ map { { protocol => 'TCP', port => $_ } } @{ $r->{ports} } ] ) : () ) } } @{ $x->{ingress} || [] } ] } };
    }
    if ( $kind eq 'storageclasses' ) {
        return { apiVersion => 'storage.k8s.io/v1', kind => 'StorageClass', metadata => { %$meta, ( $x->{default} ? ( annotations => { 'storageclass.kubernetes.io/is-default-class' => 'true' } ) : () ) },
            provisioner => $x->{provisioner}, reclaimPolicy => 'Delete', volumeBindingMode => 'Immediate' };
    }
    if ( $kind eq 'pods' ) {
        return { apiVersion => 'v1', kind => 'Pod', metadata => { %$meta, labels => $x->{labels} }, spec => { containers => [ map { _api_container($_) } @{ $x->{containers} } ] }, status => $x->{status} };
    }
    return $x;
}

sub _api_container {
    my ($c) = @_;
    return {
        name  => $c->{name},
        image => $c->{image},
        ( $c->{ports} ? ( ports => [ map { { containerPort => $_, protocol => 'TCP' } } @{ $c->{ports} } ] ) : () ),
        ( $c->{env} ? ( env => [ map {
            defined $_->{secret} ? { name => $_->{name}, valueFrom => { secretKeyRef => { name => $_->{secret}, key => $_->{key}, ( $_->{optional} ? ( optional => JSON::MaybeXS::true() ) : () ) } } }
            : defined $_->{configmap} ? { name => $_->{name}, valueFrom => { configMapKeyRef => { name => $_->{configmap}, key => $_->{key} } } }
            : { name => $_->{name}, value => $_->{value} } } @{ $c->{env} } ] ) : () ),
        ( $c->{readiness} ? ( readinessProbe => { httpGet => { path => $c->{readiness}{path} // '/', port => $c->{readiness}{port} }, periodSeconds => 10 } ) : () ),
        ( $c->{volumes} ? ( volumeMounts => [ map { { name => $_->{claim}, mountPath => $_->{mount} // '/data' } } @{ $c->{volumes} } ] ) : () ),
        ( $c->{privileged} ? ( securityContext => { privileged => JSON::MaybeXS::true() } ) : () ),
    };
}

# API-Form -> Zustand (fuer apply/create/patch)
sub _from_api {
    my ( $kind, $doc, $old ) = @_;
    my $s = $doc->{spec} || {};
    if ( $GEN{$kind} ) {
        my %d = %$doc;
        delete @d{qw( apiVersion kind status )};
        my $m = delete $d{metadata} || {};
        my %m = map { $_ => { %{ $m->{$_} } } } grep { ref $m->{$_} eq 'HASH' && %{ $m->{$_} } } qw( labels annotations );
        delete $m{annotations}{'kubectl.kubernetes.io/last-applied-configuration'} if $m{annotations};
        delete $m{annotations} if $m{annotations} && !%{ $m{annotations} };
        $d{metadata} = \%m if %m;
        return \%d;
    }
    if ( $kind eq 'deployments' ) {
        my $t = $s->{template} || {};
        my %olds = map { $_->{name} => $_ } @{ ( $old || {} )->{template}{containers} || [] };
        return {
            %{ $old || {} },
            replicas => $s->{replicas} // 1,
            selector => ( $s->{selector} || {} )->{matchLabels} // {},
            template => { labels => ( $t->{metadata} || {} )->{labels} // {},
                ( %{ ( $t->{metadata} || {} )->{annotations} || {} } ? ( annotations => $t->{metadata}{annotations} ) : () ),
                ( defined( ( $t->{spec} || {} )->{serviceAccountName} ) ? ( service_account => $t->{spec}{serviceAccountName} ) : () ),
                containers => [ map { _container_from_api( $_, $olds{ $_->{name} }, $t->{spec}{volumes} ) } @{ ( $t->{spec} || {} )->{containers} || [] } ] },
        };
    }
    if ( $kind eq 'services' ) {
        return { %{ $old || {} }, selector => $s->{selector} // {}, ( $s->{type} && ( $s->{type} ne 'ClusterIP' || ( $old || {} )->{type} ) ? ( type => $s->{type} ) : () ),
            ports => [ map { { port => $_->{port}, target => $_->{targetPort} // $_->{port}, ( $_->{name} ? ( name => $_->{name} ) : () ) } } @{ $s->{ports} || [] } ] };
    }
    if ( $kind eq 'secrets' ) {
        return { ( map { $_ => MIME::Base64::decode_base64( $doc->{data}{$_} ) } keys %{ $doc->{data} || {} } ), %{ $doc->{stringData} || {} } };
    }
    return { %{ $doc->{data} || {} } } if $kind eq 'configmaps';
    if ( $kind eq 'pvcs' ) {
        return { size => ( ( $s->{resources} || {} )->{requests} || {} )->{storage}, ( defined $s->{storageClassName} ? ( storage_class => $s->{storageClassName} ) : () ) };
    }
    if ( $kind eq 'networkpolicies' ) {
        return { pod_selector => ( $s->{podSelector} || {} )->{matchLabels} // {},
            ingress => [ map { my $r = $_; +{ ( $r->{from} ? ( from => [ map { ( $_->{podSelector} || {} )->{matchLabels} // {} } @{ $r->{from} } ] ) : () ),
                ( $r->{ports} ? ( ports => [ map { $_->{port} } @{ $r->{ports} } ] ) : () ) } } @{ $s->{ingress} || [] } ] };
    }
    if ( $kind eq 'storageclasses' ) {
        my $a = ( $doc->{metadata} || {} )->{annotations} || {};
        return { provisioner => $doc->{provisioner}, ( ( $a->{'storageclass.kubernetes.io/is-default-class'} // '' ) eq 'true' ? ( default => JSON::MaybeXS::true() ) : () ) };
    }
    return {};
}

sub _container_from_api {
    my ( $c, $old, $vols ) = @_;
    $old ||= {};
    my %claim = map { $_->{name} => ( $_->{persistentVolumeClaim} || {} )->{claimName} } @{ $vols || [] };
    my $rp = ( $c->{readinessProbe} || {} )->{httpGet};
    my %n = (
        %$old,
        name  => $c->{name},
        image => $c->{image},
    );
    delete @n{qw( ports env readiness volumes privileged )};
    $n{ports} = [ map { $_->{containerPort} } @{ $c->{ports} } ] if $c->{ports};
    $n{env} = [ map {
        my $v = $_->{valueFrom} || {};
        $v->{secretKeyRef} ? { name => $_->{name}, secret => $v->{secretKeyRef}{name}, key => $v->{secretKeyRef}{key}, ( $v->{secretKeyRef}{optional} ? ( optional => JSON::MaybeXS::true() ) : () ) }
            : $v->{configMapKeyRef} ? { name => $_->{name}, configmap => $v->{configMapKeyRef}{name}, key => $v->{configMapKeyRef}{key} }
            : { name => $_->{name}, value => $_->{value} };
    } @{ $c->{env} } ] if $c->{env};
    $n{readiness} = { port => $rp->{port}, path => $rp->{path} // '/' } if $rp;
    $n{volumes} = [ map { { claim => $claim{ $_->{name} } // $_->{name}, mount => $_->{mountPath} } } @{ $c->{volumeMounts} } ] if $c->{volumeMounts};
    $n{privileged} = JSON::MaybeXS::true() if ( $c->{securityContext} || {} )->{privileged};
    return \%n;
}

sub _bump {
    my ($d) = @_;
    $d->{generation} = ( $d->{generation} // 1 ) + 1;
    return;
}

sub _store {
    my ( $k, $kind, $ns, $name, $new ) = @_;
    if ( $kind eq 'storageclasses' ) { $k->{storageclasses}{$name} = $new; return 'created' }
    if ( $kind eq 'namespaces' ) { $k->{namespaces}{$name} //= {}; return 'created' }
    die qq{error: $kind are derived by the controller and cannot be applied\n} if $DERIVED{$kind};
    my $o = $CLUSTER{$kind} ? $k : $k->{namespaces}{$ns} or die qq{Error from server (NotFound): namespaces "$ns" not found\n};
    my $old = $o->{$kind}{$name};
    if ( $kind =~ /\A(?:cluster)?rolebindings\z/ && $old && $J->encode( $old->{roleRef} // {} ) ne $J->encode( $new->{roleRef} // {} ) ) {
        die qq{The $GEN{$kind}[1] "$name" is invalid: roleRef: Invalid value: } . $J->encode( $new->{roleRef} // {} ) =~ s/\s+/ /gr . qq{: cannot change roleRef\n};
    }
    if ( $kind eq 'pvcs' && $old && $J->encode( { %$old, size => undef } ) ne $J->encode( { %$new, size => undef } ) ) {
        die qq{The PersistentVolumeClaim "$name" is invalid: spec: Forbidden: spec is immutable after creation except resources.requests and volumeAttributesClassName for bound claims\n};
    }
    if ( $kind eq 'deployments' ) {
        die qq{The Deployment "$name" is invalid: spec.selector: Invalid value: field is immutable\n}
            if $old && $J->encode( $old->{selector} ) ne $J->encode( $new->{selector} );
        die qq{The Deployment "$name" is invalid: spec.template.metadata.labels: Invalid value: map[string]string{} : `selector` does not match template `labels`\n}
            unless _sel_match( $new->{selector}, $new->{template}{labels} );
        $new->{generation} = $old->{generation} // 1 if $old;
        _bump($new) if $old && $J->encode( $old->{template} ) ne $J->encode( $new->{template} );
        $new->{generation} //= 1;
    }
    my $same = $old && $J->encode($old) eq $J->encode($new);
    $o->{$kind}{$name} = $new;
    return $same ? 'unchanged' : $old ? 'configured' : 'created';
}

sub _docs_from_file {
    my ( $dev, $file, $stdin ) = @_;
    my $text;
    if ( $file eq '-' ) { $text = $stdin // '' }
    else {
        my $f = ( $dev->{files} || {} )->{$file};
        $f = $f->{content} if ref $f eq 'HASH';
        die "error: the path \"$file\" does not exist\n" unless defined $f;
        $text = $f;
    }
    my @d = eval { YAML::XS::Load( Encode::encode( 'UTF-8', $text ) ) };
    if ( my $e = $@ ) { $e =~ s/\s+\z//; $e =~ s/\n.*//s; die "error: error parsing $file: error converting YAML to JSON: yaml: $e\n" }
    return map { ( $_->{kind} // '' ) eq 'List' ? @{ $_->{items} || [] } : $_ } grep { ref $_ eq 'HASH' } @d;
}

sub _v_apply {
    my ( $k, $a, $o, $dev, $stdin ) = @_;
    return ( 'error: must specify one of -f and -k', 0 ) unless $o->{files};
    my @out;
    for my $f ( @{ $o->{files} } ) {
        my @docs = eval { _docs_from_file( $dev, $f, $stdin ) };
        return ( $@ =~ s/\s+\z//r, 0 ) if $@;
        for my $d (@docs) {
            my $kind = $FROM_APIKIND{ $d->{kind} // '' } or return ( qq{error: resource mapping not found for name: "} . ( $d->{metadata}{name} // '' ) . qq{" namespace: "" from "$f": no matches for kind "$d->{kind}"}, 0 );
            my $name = ( $d->{metadata} || {} )->{name} or return ( 'error: error validating data: metadata.name missing', 0 );
            my $ns = $d->{metadata}{namespace} // $o->{ns};
            my $old = $CLUSTER{$kind} ? ( $k->{$kind} || {} )->{$name} : ( $k->{namespaces}{$ns} || {} )->{$kind}{$name};
            my $r = eval { _store( $k, $kind, $ns, $name, _from_api( $kind, $d, $old ) ) };
            return ( join( "\n", @out, $@ =~ s/\s+\z//r ), 0 ) if $@;
            push @out, "$SINGULAR{$kind}/$name $r";
        }
    }
    return ( join( "\n", @out ), 1 );
}

sub _v_create {
    my ( $k, $a, $o, $dev, $stdin ) = @_;
    if ( ( $a->[0] // '' ) eq 'secret' && ( $a->[1] // '' ) eq 'generic' ) {
        my $name = $a->[2] // return ( 'error: exactly one NAME is required, got 0', 0 );
        my %lit = map { $_->[0] => $_->[1] } @{ $o->{literal} || [] };
        for my $ff ( @{ $o->{from_file} || [] } ) {    # Inhalt genau wie in der Datei (mit Zeilenende, wie echt)
            my ( $key, $path ) = @$ff;
            my $f = ( $dev->{files} || {} )->{$path};
            $f = $f->{content} if ref $f eq 'HASH';
            return ( "error: error reading $path: no such file or directory", 0 ) unless defined $f;
            $lit{ $key // ( $path =~ s{.*/}{}r ) } = $f;
        }
        if ( grep {/\A--dry-run=(?:client|server)\z/} keys %{ $o->{flags} || {} } ) {
            # nur das Manifest, nichts anlegen (fuer … | kubectl apply -f -)
            return ( "secret/$name created (dry run)", 1 ) unless ( $o->{out} // '' ) =~ /\A(?:yaml|json)\z/;
            return _structured( $o, 'secrets', { $name => \%lit } );
        }
        return ( qq{error: failed to create secret secrets "$name" already exists}, 0 ) if $k->{namespaces}{ $o->{ns} }{secrets}{$name};
        $k->{namespaces}{ $o->{ns} }{secrets}{$name} = \%lit;
        return ( "secret/$name created", 1 );
    }
    if ( ( $a->[0] // '' ) =~ /\A(?:namespace|ns)\z/ ) { push @GAPS, 'kubectl create namespace'; return ( '', 0 ) }
    if ( defined $a->[0] && !$o->{files} ) { my @r = _create_more( $k, $a, $o, $dev ); return @r if @r }
    return _v_apply( $k, $a, $o, $dev, $stdin ) if $o->{files};
    push @GAPS, "kubectl create @$a";
    return ( '', 0 );
}

sub _target {
    my ( $k, $o, $kind, $name ) = @_;
    return ( $k->{$kind} ||= {} ) if $CLUSTER{$kind} && $kind ne 'namespaces';
    return ( $k->{namespaces}{ $o->{ns} }{$kind} ||= {} );
}

sub _v_delete {
    my ( $k, $a, $o, $dev ) = @_;
    my ( $kind, $name ) = _kind_name($a);
    my @names = defined $name ? ( $name, @$a[ 2 .. $#$a ] ) : ();
    return ( 'error: resource(s) were provided, but no name was specified', 0 ) unless $kind && @names;
    my @out;
    for my $n (@names) {
        if ( $kind eq 'namespaces' ) {
            delete $k->{namespaces}{$n} or return ( qq{Error from server (NotFound): namespaces "$n" not found}, 0 );
            push @out, qq{namespace "$n" deleted};
            next;
        }
        if ( $kind eq 'pods' ) {
            # Pods eines Deployments kommen neu (gleicher Status); nur die Neuerstellung zaehlt
            my ($p) = grep { $_->{name} eq $n } _pods( $k, $o->{ns} );
            return ( qq{Error from server (NotFound): pods "$n" not found}, 0 ) unless $p;
            push @out, qq{pod "$n" deleted};
            next;
        }
        if ( $kind eq 'secrets' && $n =~ /\Ash\.helm\.release\.v1\.(.+)\.v(\d+)\z/ ) {
            Langertha::Holmgang::Sim::Linux::_part('Helm');
            Langertha::Holmgang::Sim::Linux::Helm::drop_revision( $k, $o->{ns}, $1, $2 ) or return ( qq{Error from server (NotFound): secrets "$n" not found}, 0 );
            push @out, qq{secret "$n" deleted};
            next;
        }
        return ( qq{Error from server (MethodNotAllowed): the server does not allow this method on the requested resource}, 0 ) if $DERIVED{$kind};
        my $t = _target( $k, $o, $kind );
        delete $t->{$n} or return ( qq{Error from server (NotFound): } . ( $SINGULAR{$kind} =~ s/\..*//r ) . qq{s "$n" not found}, 0 );
        push @out, ( $SINGULAR{$kind} =~ s/\..*//r ) . qq{ "$n" deleted};
    }
    return ( join( "\n", @out ), 1 );
}

sub _dep {
    my ( $k, $o, $ref ) = @_;
    my ( $kind, $name ) = _kind_name( [ split( m{/}, $ref // '', 2 ) ] );
    die qq{error: the server doesn't have a resource type "$ref"\n} unless ( $kind // '' ) eq 'deployments';
    my $d = $k->{namespaces}{ $o->{ns} }{deployments}{ $name // '' } or die qq{Error from server (NotFound): deployments.apps "$name" not found\n};
    return ( $d, $name );
}

sub _v_set {
    my ( $k, $a, $o ) = @_;
    my ( $what, $ref, @assign ) = @$a;
    my ( $d, $name ) = eval { _dep( $k, $o, $ref ) };
    return ( $@ =~ s/\s+\z//r, 0 ) unless $d;
    my $before = $J->encode( $d->{template} );
    if ( ( $what // '' ) eq 'image' ) {
        for my $x (@assign) {
            my ( $c, $img ) = split /=/, $x, 2;
            my @cs = grep { $c eq '*' || $_->{name} eq $c } @{ $d->{template}{containers} };
            return ( qq{error: unable to find container named "$c"}, 0 ) unless @cs;
            $_->{image} = $img for @cs;
        }
    }
    elsif ( ( $what // '' ) eq 'env' ) {
        # -c/--containers waehlt Container (Komma-Liste, *); ohne: alle (wie kubectl)
        my $want = $o->{container} // '*';
        my %want = map { $_ => 1 } split /,/, $want;
        my @cs = grep { $want{'*'} || $want{ $_->{name} } } @{ $d->{template}{containers} };
        return ( qq{error: unable to find container named "$want"}, 0 ) unless @cs;
        if ( $o->{env_list} ) {
            return ( join( "\n", map {
                my $c = $_;
                ( "# deployments/$name, container $c->{name}",
                    map { defined $_->{secret} ? "# $_->{name} from secret $_->{secret}, key $_->{key}"
                        : defined $_->{configmap} ? "# $_->{name} from configmap $_->{configmap}, key $_->{key}"
                        : "$_->{name}=" . ( $_->{value} // '' ) } @{ $c->{env} || [] } );
            } @cs ), 1 );
        }
        my @set;
        if ( defined $o->{env_from} ) {
            my ( $kind, $sname ) = $o->{env_from} =~ m{\A(secret|configmap)/(.+)\z}
                or return ( "error: unknown resource for --from: $o->{env_from}", 0 );
            if ( $kind eq 'configmap' ) { push @GAPS, 'kubectl set env --from=configmap'; return ( '', 0 ) }
            my $sec = $k->{namespaces}{ $o->{ns} }{secrets}{$sname}
                or return ( qq{Error from server (NotFound): secrets "$sname" not found}, 0 );
            my @keys = defined $o->{env_keys} ? split( /,/, $o->{env_keys} ) : sort keys %$sec;
            for my $key (@keys) {
                return ( qq{error: key "$key" not found in secret "$sname"}, 0 ) unless exists $sec->{$key};
                ( my $n = uc( ( $o->{env_prefix} // '' ) . $key ) ) =~ s/[^A-Z0-9_]/_/g;
                push @set, [ $n, { name => $n, secret => $sname, key => $key } ];
            }
        }
        for my $x (@assign) {
            if ( $x =~ /\A([A-Za-z_][A-Za-z0-9_.-]*)-\z/ ) { push @set, [ $1, undef ]; next }
            my ( $n, $v ) = $x =~ /\A([^=]+)=(.*)\z/s or return ( "error: invalid env: $x", 0 );
            push @set, [ $n, { name => $n, value => $v } ];
        }
        for my $c (@cs) {
            for my $s (@set) {
                my ( $n, $e ) = @$s;
                my $had = grep { $_->{name} eq $n } @{ $c->{env} || [] };
                next if !$e && !$had;
                $c->{env} = [ grep { $_->{name} ne $n } @{ $c->{env} || [] } ];
                push @{ $c->{env} }, $e if $e;
            }
        }
    }
    elsif ( ( $what // '' ) =~ /\A(?:serviceaccount|sa)\z/ ) {
        return ( 'error: serviceaccount is required', 0 ) unless defined $assign[0];
        $d->{template}{service_account} = $assign[0];
        _bump($d) if $J->encode( $d->{template} ) ne $before;
        return ( "deployment.apps/$name serviceaccount updated", 1 );
    }
    else { push @GAPS, "kubectl set $what"; return ( '', 0 ) }
    return ( "deployment.apps/$name " . ( $what eq 'image' ? 'image updated' : 'env updated' ), 1 ) if 0;
    _bump($d) if $J->encode( $d->{template} ) ne $before;
    return ( "deployment.apps/$name " . ( $what eq 'image' ? 'image updated' : 'env updated' ), 1 );
}

sub _merge {
    my ( $a, $b ) = @_;
    return $b unless ref $a eq 'HASH' && ref $b eq 'HASH';
    my %r = %$a;
    for my $k ( keys %$b ) {
        if ( !defined $b->{$k} ) { delete $r{$k}; next }
        $r{$k} = _merge( $a->{$k}, $b->{$k} );
    }
    return \%r;
}

# strategic merge: Listen von Containern (name) bzw. Ports (port) werden zusammengefuehrt
sub _smerge {
    my ( $a, $b, $key ) = @_;
    if ( ref $a eq 'ARRAY' && ref $b eq 'ARRAY' && $key ) {
        # Ports eines Service fuehrt die API ueber port zusammen, die eines Containers ueber containerPort
        $key = 'port' if $key eq 'containerPort' && !grep { ref $_ eq 'HASH' && exists $_->{containerPort} } @$a, @$b;
        my @r = @$a;
        for my $x (@$b) {
            my ($i) = grep { ref $r[$_] eq 'HASH' && ref $x eq 'HASH' && defined $x->{$key} && ( $r[$_]{$key} // '' ) eq $x->{$key} } 0 .. $#r;
            if ( defined $i ) { $r[$i] = _smerge( $r[$i], $x ) } else { push @r, $x }
        }
        return \@r;
    }
    return $b unless ref $a eq 'HASH' && ref $b eq 'HASH';
    my %r = %$a;
    my %mk = ( containers => 'name', env => 'name', ports => 'containerPort', volumes => 'name', volumeMounts => 'mountPath' );
    for my $k ( keys %$b ) {
        if ( !defined $b->{$k} ) { delete $r{$k}; next }
        $r{$k} = _smerge( $a->{$k}, $b->{$k}, $mk{$k} );
    }
    return \%r;
}

sub _jsonpatch {
    my ( $doc, $ops ) = @_;
    for my $op (@$ops) {
        my @p = map { s/~1/\//gr =~ s/~0/~/gr } grep { length } split m{/}, $op->{path} // '';
        my $last = pop @p;
        my $t = $doc;
        for my $s (@p) { $t = ref $t eq 'ARRAY' ? $t->[$s] : $t->{$s}; die "error: unable to find path $op->{path}\n" unless ref $t }
        my $o = $op->{op} // '';
        if ( $o eq 'replace' || $o eq 'add' ) {
            if ( ref $t eq 'ARRAY' ) { if ( $last eq '-' ) { push @$t, $op->{value} } elsif ( $o eq 'add' ) { splice @$t, $last, 0, $op->{value} } else { $t->[$last] = $op->{value} } }
            else { die "error: replace operation does not apply: doc is missing path: $op->{path}\n" if $o eq 'replace' && !exists $t->{$last}; $t->{$last} = $op->{value} }
        }
        elsif ( $o eq 'remove' ) { if ( ref $t eq 'ARRAY' ) { splice @$t, $last, 1 } else { delete $t->{$last} } }
        else { die "error: unsupported json patch operation $o\n" }
    }
    return $doc;
}

sub _v_patch {
    my ( $k, $a, $o ) = @_;
    my ( $kind, $name ) = _kind_name($a);
    return ( 'error: you must specify the type of resource to patch', 0 ) unless $kind && defined $name;
    my $p = eval { JSON::MaybeXS->new->decode( $o->{patch} // '' ) } // eval { YAML::XS::Load( $o->{patch} // '' ) };
    return ( 'error: unable to parse "' . ( $o->{patch} // '' ) . '": yaml: did not find expected node content', 0 ) unless ref $p;
    my $t = _target( $k, $o, $kind );
    my $old = $t->{$name} or return ( qq{Error from server (NotFound): } . ( $SINGULAR{$kind} =~ s/\..*//r ) . qq{s "$name" not found}, 0 );
    my $api = _api_obj( $kind, $name, $old, $o->{ns} );
    my $type = $o->{type} // 'strategic';
    my $new = eval {
        $type eq 'json' ? _jsonpatch( $api, $p ) : $type eq 'merge' ? _merge( $api, $p ) : _smerge( $api, $p );
    };
    return ( $@ =~ s/\s+\z//r, 0 ) unless $new;
    my $r = eval { _store( $k, $kind, $o->{ns}, $name, _from_api( $kind, $new, $old ) ) };
    return ( $@ =~ s/\s+\z//r, 0 ) if $@;
    return ( "$SINGULAR{$kind}/$name " . ( $r eq 'unchanged' ? 'patched (no change)' : 'patched' ), 1 );
}

sub _v_scale {
    my ( $k, $a, $o ) = @_;
    my $ref = @$a == 2 ? "$a->[0]/$a->[1]" : $a->[0];
    my ( $d, $name ) = eval { _dep( $k, $o, $ref ) };
    return ( $@ =~ s/\s+\z//r, 0 ) unless $d;
    return ( 'error: required flag(s) "replicas" not set', 0 ) unless defined $o->{replicas};
    $d->{replicas} = 0 + $o->{replicas};
    return ( "deployment.apps/$name scaled", 1 );
}

sub _v_label { return _meta_edit( 'labels', @_ ) }
sub _v_annotate { return _meta_edit( 'annotations', @_ ) }

# kubectl label|annotate KIND NAME k=v k2- [--overwrite]: nur Arten in API-Form
sub _meta_edit {
    my ( $what, $k, $a, $o ) = @_;
    my ( $kind, $name ) = _kind_name($a);
    my $verb = $what eq 'labels' ? 'label' : 'annotate';
    unless ( $kind && $GEN{$kind} ) { push @GAPS, "kubectl $verb @$a"; return ( '', 0 ) }
    my @kv = @$a[ ( $a->[0] =~ m{/} ? 1 : 2 ) .. $#$a ];
    return ( "error: at least one $what update is required", 0 ) unless @kv;
    my $t = _target( $k, $o, $kind );
    my $x = $t->{ $name // '' } or return ( qq{Error from server (NotFound): $GEN{$kind}[3] "} . ( $name // '' ) . '" not found', 0 );
    my $m = $x->{metadata}{$what} ||= {};
    for my $e (@kv) {
        if ( $e =~ /\A([^=]+)-\z/ ) { delete $m->{$1}; next }
        my ( $kk, $v ) = $e =~ /\A([^=]+)=(.*)\z/s or return ( "error: invalid $what format: $e", 0 );
        return ( "error: --overwrite is false but found the following declared $what(s): '$kk' already has a value ($m->{$kk})", 0 )
            if defined $m->{$kk} && $m->{$kk} ne $v && !$o->{flags}{'--overwrite'};
        $m->{$kk} = $v;
    }
    delete $x->{metadata}{$what} unless %$m;
    delete $x->{metadata} unless %{ $x->{metadata} };
    return ( "$GEN{$kind}[3]/$name " . ( $what eq 'labels' ? 'labeled' : 'annotated' ), 1 );
}

sub _v_rollout {
    my ( $k, $a, $o ) = @_;
    my ( $what, @refs ) = @$a;
    @refs = ( "$refs[0]/$refs[1]" ) if @refs == 2 && $refs[0] !~ m{/};
    my @out;
    for my $ref (@refs) {
        my ( $d, $name ) = eval { _dep( $k, $o, $ref ) };
        return ( $@ =~ s/\s+\z//r, 0 ) unless $d;
        if ( $what eq 'restart' ) {
            $d->{restarted_at} = '2026-10-21T12:' . sprintf( '%02d', ( $d->{generation} // 1 ) % 60 ) . ':00Z';
            _bump($d);
            push @out, "deployment.apps/$name restarted";
        }
        elsif ( $what eq 'status' ) {
            my @p = grep { $_->{deployment} eq $name } _pods( $k, $o->{ns} );
            my $r = grep { $_->{ready} } @p;
            push @out, $r == @p ? qq{deployment "$name" successfully rolled out}
                : qq{Waiting for deployment "$name" rollout to finish: $r of } . scalar(@p) . " updated replicas are available...\nerror: timed out waiting for the condition";
            return ( join( "\n", @out ), 0 ) if $r != @p;
        }
        elsif ( $what eq 'undo' ) {
            my $prev = $d->{previous} or return ( qq{error: no rollout history found for deployment "$name"}, 0 );
            $d->{template} = $prev;
            delete $d->{previous};
            _bump($d);
            push @out, "deployment.apps/$name rolled back";
        }
        elsif ( $what eq 'history' ) {
            push @out, "deployment.apps/$name \nREVISION  CHANGE-CAUSE\n" . join( "\n", map {"$_         <none>"} 1 .. ( $d->{generation} // 1 ) );
        }
        else { push @GAPS, "kubectl rollout $what"; return ( '', 0 ) }
    }
    return ( join( "\n", @out ), 1 );
}

sub _v_logs {
    my ( $k, $a, $o ) = @_;
    my $ref = $a->[0] // return ( 'error: expected \'logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER]\'.', 0 );
    my @p = _pods( $k, $o->{ns} );
    my ($p) = $ref =~ m{\A(?:deploy(?:ment)?(?:\.apps)?)/(.+)\z} ? grep { $_->{deployment} eq $1 } @p : grep { $_->{name} eq $ref || "pod/$_->{name}" eq $ref } @p;
    return ( qq{Error from server (NotFound): pods "$ref" not found}, 0 ) unless $p;
    my ($c) = @{ $p->{template}{containers} };
    if ( $p->{reason} eq 'ImagePullBackOff' || $p->{reason} eq 'CreateContainerConfigError' || $p->{phase} eq 'Pending' ) {
        return ( qq{Error from server (BadRequest): container "$c->{name}" in pod "$p->{name}" is waiting to start: } . ( $p->{reason} eq 'ImagePullBackOff' ? 'trying and failing to pull image' : $p->{reason} eq 'CreateContainerConfigError' ? 'CreateContainerConfigError' : 'ContainerCreating' ), 0 );
    }
    my @l = $p->{reason} eq 'CrashLoopBackOff' ? @{ $p->{container}{crash_log} || ['error: missing configuration'] } : @{ $c->{logs} || [] };
    # Controller, deren Log aus dem Zustand folgt
    push @l, _ingress_log($k) if ( $c->{derive_logs} // '' ) eq 'ingress-nginx';
    push @l, _cm_log($k)      if ( $c->{derive_logs} // '' ) eq 'cert-manager';
    @l = @l[ ( @l > $o->{tail} ? @l - $o->{tail} : 0 ) .. $#l ] if defined $o->{tail} && $o->{tail} =~ /\A\d+\z/;
    return ( join( "\n", @l ), 1 );
}

sub _v_describe {
    my ( $k, $a, $o ) = @_;
    my ( $kind, $name ) = _kind_name($a);
    return ( 'error: You must specify the type of resource to describe.', 0 ) unless $kind;
    my $ns = $o->{ns};
    if ( $GEN{$kind} || $DERIVED{$kind} ) {
        return _describe_gen( $k, $kind, $ns, $name ) if defined $name || $DERIVED{$kind};
        my @n = sort keys %{ $kind eq 'certificates' ? _certs( $k, $ns ) : _gen_objs( $k, $kind, $ns ) };
        return ( "No resources found in $ns namespace.", 1 ) unless @n;
        return ( join( "\n\n\n", map { ( _describe_gen( $k, $kind, $ns, $_ ) )[0] } @n ), 1 );
    }
    if ( $kind eq 'pods' ) {
        my @p = grep { !defined $name || $_->{name} eq $name || index( $_->{name}, $name ) == 0 } _pods( $k, $ns );
        return ( qq{Error from server (NotFound): pods "$name" not found}, 0 ) unless @p;
        return ( join( "\n\n", map { _describe_pod( $k, $ns, $_ ) } @p ), 1 );
    }
    if ( $kind eq 'deployments' ) {
        my $d = $k->{namespaces}{$ns}{deployments}{ $name // '' } or return ( qq{Error from server (NotFound): deployments.apps "$name" not found}, 0 );
        my @p = grep { $_->{deployment} eq $name } _pods( $k, $ns );
        my $r = grep { $_->{ready} } @p;
        return ( join( "\n", "Name:                   $name", "Namespace:              $ns", 'Selector:               ' . _labels_text( $d->{selector} ),
            "Replicas:               $d->{replicas} desired | " . scalar(@p) . ' updated | ' . scalar(@p) . " total | $r available | " . ( @p - $r ) . ' unavailable',
            'StrategyType:           RollingUpdate', 'Pod Template:', '  Labels:  ' . _labels_text( $d->{template}{labels} ), '  Containers:',
            ( map { _describe_container( $_, '   ' ) } @{ $d->{template}{containers} } ),
            'Conditions:', '  Type           Status  Reason', '  ----           ------  ------',
            '  Available      ' . ( $r == @p ? 'True    MinimumReplicasAvailable' : 'False   MinimumReplicasUnavailable' ),
            '  Progressing    True    NewReplicaSetAvailable' ), 1 );
    }
    if ( $kind eq 'services' ) {
        my $s = $k->{namespaces}{$ns}{services}{ $name // '' } or return ( qq{Error from server (NotFound): services "$name" not found}, 0 );
        my @e = _endpoints( $k, $ns, $name );
        return ( join( "\n", "Name:              $name", "Namespace:         $ns", 'Selector:          ' . _labels_text( $s->{selector} ), 'Type:              ' . ( $s->{type} // 'ClusterIP' ),
            ( map { ( "Port:              " . ( $_->{name} // '<unset>' ) . "  $_->{port}/TCP", "TargetPort:        $_->{target}/TCP",
                'Endpoints:         ' . ( @e ? join( ',', map { my $p = $_; "$p->{ip}:" } @e ) =~ s/:(,|\z)/:$_->{target}$1/gr : '<none>' ) ) } @{ $s->{ports} || [] } ),
            'Session Affinity:  None', 'Events:            <none>' ), 1 );
    }
    if ( $kind eq 'pvcs' ) {
        my $p = $k->{namespaces}{$ns}{pvcs}{ $name // '' } or return ( qq{Error from server (NotFound): persistentvolumeclaims "$name" not found}, 0 );
        my $ph = _pvc_phase( $k, $ns, $name );
        return ( join( "\n", "Name:          $name", "Namespace:     $ns", 'StorageClass:  ' . ( $p->{storage_class} // '' ), "Status:        $ph",
            'Capacity:      ' . ( $ph eq 'Bound' ? $p->{size} : '' ), 'Access Modes:  ' . ( $ph eq 'Bound' ? 'RWO' : '' ),
            'Events:', '  Type     Reason              Age                From                         Message', '  ----     ------              ----               ----                         -------',
            ( $ph eq 'Pending' ? '  Warning  ProvisioningFailed  2m (x41 over 12m)  persistentvolume-controller  storageclass.storage.k8s.io "' . ( $p->{storage_class} // '' ) . '" not found' : () ) ), 1 );
    }
    if ( $kind eq 'networkpolicies' ) {
        my $p = $k->{namespaces}{$ns}{networkpolicies}{ $name // '' } or return ( qq{Error from server (NotFound): networkpolicies.networking.k8s.io "$name" not found}, 0 );
        my @l = ( "Name:         $name", "Namespace:    $ns", 'Spec:', '  PodSelector:     ' . ( %{ $p->{pod_selector} || {} } ? _labels_text( $p->{pod_selector} ) : '<none> (Allowing the specific traffic to all pods in this namespace)' ),
            '  Allowing ingress traffic:' );
        if ( !@{ $p->{ingress} || [] } ) { push @l, '    <none> (Selected pods are isolated for ingress connectivity)' }
        for my $r ( @{ $p->{ingress} || [] } ) {
            push @l, '    To Port: ' . ( $r->{ports} ? join( ', ', map {"$_/TCP"} @{ $r->{ports} } ) : '<any> (traffic allowed to all ports)' ), '    From:';
            push @l, $r->{from} ? map { '      PodSelector: ' . _labels_text($_) } @{ $r->{from} } : '      <any> (traffic not restricted by source)';
        }
        push @l, '  Not affecting egress traffic', '  Policy Types: Ingress';
        return ( join( "\n", @l ), 1 );
    }
    if ( $kind eq 'secrets' ) {
        my $s = _secrets_all( $k, $ns )->{ $name // '' } or return ( qq{Error from server (NotFound): secrets "$name" not found}, 0 );
        return ( join( "\n", "Name:         $name", "Namespace:    $ns", '', 'Type:  ' . _secret_type($s), '', 'Data', '====', map { "$_:  " . length( $s->{$_} ) . ' bytes' } sort grep { !/\A_/ } keys %$s ), 1 );
    }
    if ( $kind eq 'storageclasses' ) {
        my $s = ( $k->{storageclasses} || {} )->{ $name // '' } or return ( qq{Error from server (NotFound): storageclasses.storage.k8s.io "$name" not found}, 0 );
        return ( join( "\n", "Name:            $name", 'IsDefaultClass:  ' . ( $s->{default} ? 'Yes' : 'No' ), "Provisioner:     $s->{provisioner}", 'ReclaimPolicy:   Delete', 'VolumeBindingMode:  Immediate' ), 1 );
    }
    if ( $kind eq 'replicasets' ) {
        my @rs = grep { !defined $name || index( $_->{name}, $name ) == 0 } _replicasets( $k, $ns );
        return ( qq{Error from server (NotFound): replicasets.apps "$name" not found}, 0 ) unless @rs;
        return ( join( "\n\n", map {
            my $r = $_;
            join "\n", "Name:           $r->{name}", "Namespace:      $ns", "Controlled By:  Deployment/$r->{deployment}",
                "Replicas:       $r->{current} current / $r->{desired} desired", "Pods Status:    $r->{ready} Running / 0 Waiting / 0 Succeeded / 0 Failed",
                ( $r->{failed} ? ( 'Conditions:', '  Type             Status  Reason', '  ----             ------  ------', '  ReplicaFailure   True    FailedCreate',
                    'Events:', '  Type     Reason        Age                 From                   Message', '  ----     ------        ----                ----                   -------',
                    "  Warning  FailedCreate  2m (x18 over 12m)  replicaset-controller  $r->{failed}" ) : ('Events:          <none>') );
        } @rs ), 1 );
    }
    push @GAPS, "kubectl describe @$a";
    return ( '', 0 );
}

sub _describe_container {
    my ( $c, $ind ) = @_;
    return ( "$ind$c->{name}:", "$ind  Image:      $c->{image}",
        ( $c->{ports} ? "$ind  Port:       " . join( ', ', map {"$_/TCP"} @{ $c->{ports} } ) : () ),
        ( $c->{readiness} ? "$ind  Readiness:  http-get http://:$c->{readiness}{port}" . ( $c->{readiness}{path} // '/' ) . ' delay=0s timeout=1s period=10s #success=1 #failure=3' : () ),
        "$ind  Environment:", ( map { "$ind    $_->{name}:  " . ( defined $_->{secret} ? "<set to the key '$_->{key}' in secret '$_->{secret}'>" . ( $_->{optional} ? '  Optional: true' : '  Optional: false' ) : defined $_->{configmap} ? "<set to the key '$_->{key}' of config map '$_->{configmap}'>" : $_->{value} // '' ) } @{ $c->{env} || [] } ),
        ( !@{ $c->{env} || [] } ? "$ind    <none>" : () ),
        "$ind  Mounts:", ( map { "$ind    " . ( $_->{mount} // '/data' ) . " from $_->{claim} (rw)" } @{ $c->{volumes} || [] } ), ( !@{ $c->{volumes} || [] } ? "$ind    <none>" : () ),
        ( $c->{privileged} ? "$ind  Security Context: privileged" : () ) );
}

sub _describe_pod {
    my ( $k, $ns, $p ) = @_;
    my @state = $p->{reason} eq 'CrashLoopBackOff' ? ( '      State:          Waiting', '      Reason:       CrashLoopBackOff', '    Last State:     Terminated', '      Reason:       Error', '      Exit Code:    1' )
        : $p->{reason} =~ /\A(?:ImagePullBackOff|CreateContainerConfigError)\z/ ? ( '      State:          Waiting', "      Reason:       $p->{reason}" )
        : $p->{phase} eq 'Pending' ? ('      State:          Waiting', '      Reason:       ContainerCreating') : ( '      State:          Running', '      Started:      Tue, 21 Oct 2026 11:48:02 +0200' );
    my @ev;
    if ( $p->{reason} ) {
        my %r = ( NotReady => [ 'Warning', 'Unhealthy', 'kubelet' ], CrashLoopBackOff => [ 'Warning', 'BackOff', 'kubelet' ], ImagePullBackOff => [ 'Warning', 'Failed', 'kubelet' ],
            Unschedulable => [ 'Warning', 'FailedScheduling', 'default-scheduler' ], CreateContainerConfigError => [ 'Warning', 'Failed', 'kubelet' ] );
        my $r = $r{ $p->{reason} } // [ 'Normal', $p->{reason}, 'kubelet' ];
        my $msg = $p->{reason} eq 'ImagePullBackOff' ? qq{Failed to pull image "$p->{container}{image}": rpc error: code = NotFound desc = failed to pull and unpack image "$p->{container}{image}": failed to resolve reference "$p->{container}{image}": $p->{container}{image}: not found}
            : $p->{reason} eq 'CreateContainerConfigError' ? "Error: $p->{message}" : $p->{message};
        @ev = ( 'Events:', '  Type     Reason     Age                 From               Message', '  ----     ------     ----                ----               -------',
            sprintf( '  %-8s %-10s %-19s %-18s %s', @$r[ 0, 1 ], '2m (x41 over 12m)', $r->[2], $msg ) );
    }
    else { @ev = ('Events:                      <none>') }
    my ($c) = @{ $p->{template}{containers} };
    return join "\n", "Name:             $p->{name}", "Namespace:        $ns", 'Node:             ' . ( $p->{phase} eq 'Pending' && $p->{reason} eq 'Unschedulable' ? '<none>' : 'node1/10.30.0.21' ),
        'Labels:           ' . join( "\n                  ", map {"$_=$p->{labels}{$_}"} sort keys %{ $p->{labels} } ), "Status:           $p->{phase}",
        "IP:               " . ( $p->{phase} eq 'Pending' && $p->{reason} eq 'Unschedulable' ? '' : $p->{ip} ), 'Containers:', _describe_container( $c, '  ' ), @state,
        "    Ready:          " . ( $p->{ready} ? 'True' : 'False' ), "    Restart Count:  $p->{restarts}", 'Conditions:', '  Type              Status', '  Ready             ' . ( $p->{ready} ? 'True' : 'False' ), @ev;
}

# kubectl exec POD -- curl|wget URL : Erreichbarkeit von Pod zu Service
sub _v_exec {
    my ( $k, $a, $o ) = @_;
    my $ref = $a->[0] // return ( 'error: expected \'exec (POD | TYPE/NAME) [-c CONTAINER] [flags] -- COMMAND [args...]\'.', 0 );
    my @p = _pods( $k, $o->{ns} );
    my ($src) = $ref =~ m{\Adeploy(?:ment)?/(.+)\z} ? grep { $_->{deployment} eq $1 } @p : grep { $_->{name} eq $ref } @p;
    return ( qq{Error from server (NotFound): pods "$ref" not found}, 0 ) unless $src;
    my @cmd = @{ $o->{rest} || [] };
    return ( qq{error: unable to upgrade connection: container not found ("$src->{template}{containers}[0]{name}")}, 0 ) unless $src->{phase} eq 'Running' && $src->{reason} ne 'CrashLoopBackOff';
    if ( $o->{interactive} && !@cmd || ( $cmd[0] // '' ) =~ /\A(?:sh|bash|ash)\z/ && @cmd == 1 ) { push @GAPS, "kubectl exec -it"; return ( '', 0 ) }
    return pod_tool( $k, $o->{ns}, $src, \@cmd ) if ( $cmd[0] // '' ) =~ /\A(?:curl|wget)\z/ || ( $cmd[0] // '' ) eq 'openssl' && ( $cmd[1] // '' ) eq 's_client';
    # alles andere in einer Shell des Pods (curl, wget, openssl darin wieder ueber den Cluster)
    require Langertha::Holmgang::Sim::Linux;
    my $line = ( $cmd[0] // '' ) =~ /\A(?:sh|bash|ash)\z/ && ( $cmd[1] // '' ) eq '-c' ? $cmd[2] // '' : join ' ', map { /\A[\w\/.:=,@%+-]+\z/ ? $_ : "'" . s/'/'\\''/gr . "'" } @cmd;
    my ($c) = @{ $src->{template}{containers} };
    my %env = map { $_->{name} => ( defined $_->{value} ? $_->{value} : defined $_->{secret} ? ( ( ( $k->{namespaces}{ $o->{ns} }{secrets} || {} )->{ $_->{secret} } || {} )->{ $_->{key} } // '' ) : '' ) } @{ $c->{env} || [] };
    my $pd = { type => 'linux', hostname => $src->{name}, pod => { ns => $o->{ns}, name => $src->{name} }, kubernetes => $k, env => \%env,
        files => { '/etc/hosts' => "127.0.0.1\tlocalhost\n$src->{ip}\t$src->{name}\n",
            '/etc/resolv.conf' => "search $o->{ns}.svc.cluster.local svc.cluster.local cluster.local\nnameserver 10.43.0.10\noptions ndots:5\n" },
        dirs => { map { $_ => {} } qw( /bin /etc /tmp /usr /var /proc /dev /app ) } };
    my ( $out, $ok, $gap ) = Langertha::Holmgang::Sim::Linux->run( $pd, $line, { host => $src->{name}, state => {} } );
    push @GAPS, map {"kubectl exec -- $_"} split /; /, $gap if defined $gap;
    return ( $out, $ok );
}


sub pod_tool {
    my ( $k, $srcns, $src, $cmdref ) = @_;
    my @cmd = @$cmdref;
    my $o = { ns => $srcns };
    my $tool = $cmd[0] // '';
    if ( $tool eq 'openssl' && ( $cmd[1] // '' ) eq 's_client' ) {
        my ( $conn, $sni );
        for my $i ( 2 .. $#cmd ) { $conn = $cmd[ $i + 1 ] if $cmd[$i] eq '-connect'; $sni = $cmd[ $i + 1 ] if $cmd[$i] eq '-servername' }
        my ($h) = ( $conn // '' ) =~ /\A([^:]+)/;
        return ( 's_client: -connect requires an argument', 0 ) unless defined $h;
        return tls_probe( $k, $h, $sni );
    }
    if ( $tool !~ /\A(?:curl|wget)\z/ || $o->{interactive} ) { push @GAPS, "kubectl exec -- @cmd"; return ( '', 0 ) }
    my ($url) = grep {m{\Ahttps?://}} @cmd;
    ($url) = grep { !/\A-/ && $_ ne $tool } @cmd unless $url;
    return ( "$tool: no URL specified", 1 ) unless defined $url;
    my ( $host, $port, $path ) = $url =~ m{\A(?:https?://)?([^/:]+)(?::(\d+))?(/.*)?\z} or return ( "$tool: bad URL", 1 );
    # oeffentliche Namen (DNS auf den Ingress-Controller): ueber den Ingress
    my ($hh) = map { /\AHost:\s*(\S+)/i ? $1 : () } @cmd;
    if ( defined $hh || _public_host( $k, $host ) ) {
        return _client_ingress( $k, $tool, \@cmd, $url =~ m{\Ahttps://} ? 'https' : 'http', $hh // $host, $path // '/' );
    }
    ( my $svcname = $host ) =~ s/\..*//;
    my $ns = $host =~ /\A[^.]+\.([^.]+)/ && $1 ne 'svc' ? $1 : $o->{ns};
    my $svc = ( $k->{namespaces}{$ns} || {} )->{services}{$svcname};
    my $fail = sub { $tool eq 'curl' ? ( "curl: ($_[0]) $_[1]", 0 ) : ( "wget: $_[2]", 0 ) };
    return $fail->( 6, "Could not resolve host: $host", "bad address '$host'" ) unless $svc;
    my ($sp) = grep { $_->{port} == ( $port // 80 ) } @{ $svc->{ports} || [] };
    return $fail->( 28, "Failed to connect to $host port " . ( $port // 80 ) . " after 10001 ms: Timeout was reached", 'download timed out' ) unless $sp;
    my @e = _endpoints( $k, $ns, $svcname );
    return $fail->( 7, "Failed to connect to $host port " . ( $port // 80 ) . " after 2 ms: Couldn't connect to server", "can't connect to remote host: Connection refused" ) unless @e;
    my $dst = $e[0];
    # NetworkPolicies (Ingress) des Ziel-Namespace
    my @pol = grep { _sel_match( $_->{pod_selector}, $dst->{labels} ) } values %{ $k->{namespaces}{$ns}{networkpolicies} || {} };
    if (@pol) {
        my $ok = grep {
            my $r = $_;
            ( !$r->{from} || grep { $ns eq $o->{ns} && _sel_match( $_, $src->{labels} ) } @{ $r->{from} } )
                && ( !$r->{ports} || grep { $_ == $sp->{target} } @{ $r->{ports} } );
        } map { @{ $_->{ingress} || [] } } @pol;
        return $fail->( 28, "Failed to connect to $host port " . ( $port // 80 ) . " after 10001 ms: Timeout was reached", 'download timed out' ) unless $ok;
    }
    my ($dc) = @{ $dst->{template}{containers} };
    return $fail->( 7, "Failed to connect to $host port " . ( $port // 80 ) . " after 2 ms: Couldn't connect to server", "can't connect to remote host: Connection refused" )
        unless grep { $_ == $sp->{target} } @{ $dc->{listens} || $dc->{ports} || [] };
    return ( $dc->{http_body} // '{"status":"ok"}', 1 );
}

# --- openssl s_client gegen den Ingress ------------------------------------------------

sub _dn_issuer {
    my ($i) = @_;
    return 'O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate' unless defined $i;
    return "C = US, O = (STAGING) Let's Encrypt, CN = (STAGING) Counterfeit Cashew R10" if $i =~ /staging/i;
    return "C = US, O = Let's Encrypt, CN = R11" if $i =~ /letsencrypt|acme/i;
    ( my $n = $i ) =~ s{\A\w+/}{};
    return "CN = $n";
}


sub tls_probe {
    my ( $k, $host, $sni ) = @_;
    $sni //= $host;
    return ( "$host: Name or service not known\nconnect:errno=2", 0 ) unless _public_host( $k, $host ) || $host =~ /\A[\d.]+\z/ && $host eq ( ( $k->{ingress} || {} )->{address} // '' );
    my ( $ns, $sec ) = _tls_for_host( $k, $sni );
    my $s = defined $sec ? _secret( $k, $ns, $sec ) : undef;
    my $info = $s && defined $s->{'tls.crt'} ? _cert_info( $s->{'tls.crt'} ) : undef;
    my ( $subj, $iss, $pem, $verify );
    if ($info) {
        ( $subj = $info->{subject} // 'CN=' . ( $info->{san}[0] // $sni ) ) =~ s/=/ = /g; $subj =~ s/,\s*/, /g;
        $iss = _dn_issuer( $info->{issuer} );
        $pem = $s->{'tls.crt'};
        $verify = !( grep { _host_match( $_, $sni ) } @{ $info->{san} } ) ? '62 (hostname mismatch)' : $info->{trusted} ? '0 (ok)' : '20 (unable to get local issuer certificate)';
    }
    else {
        $subj = 'O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate';
        $iss = $subj;
        $pem = _pem( subject => 'O=Acme Co,CN=Kubernetes Ingress Controller Fake Certificate', san => 'ingress.local', issuer => 'fake', trusted => 0 );
        $verify = '18 (self-signed certificate)';
    }
    return ( join( "\n", 'CONNECTED(00000003)', "depth=0 $subj", ( $verify =~ /\A0 / ? 'verify return:1' : 'verify error:num=' . ( $verify =~ s/ \((.*)\)/:$1/r ) ),
        '---', 'Certificate chain', " 0 s:$subj", "   i:$iss", '---', 'Server certificate', $pem =~ s/\n\z//r, "subject=$subj", "issuer=$iss", '---',
        'SSL handshake has read 3214 bytes and written 389 bytes', 'Verification' . ( $verify =~ /\A0 / ? ': OK' : ' error: ' . ( $verify =~ s/\A\d+ \((.*)\)/$1/r ) ), '---',
        "    Verify return code: $verify", '---', 'DONE' ), 1 );
}


sub x509 {
    my ( $pem, $o ) = @_;
    my $info = _cert_info($pem) or return ( "Could not read certificate from <stdin>\nUnable to load certificate", 0 );
    ( my $subj = $info->{subject} // 'CN=' . ( $info->{san}[0] // '' ) ) =~ s/=/ = /g; $subj =~ s/,\s*/, /g;
    my $iss = _dn_issuer( $info->{issuer} );
    my @san = map {"DNS:$_"} grep {length} @{ $info->{san} };
    my %w = map { $_ => 1 } @$o;
    my @l;
    if ( $w{'-text'} ) {
        return ( join( "\n", 'Certificate:', '    Data:', '        Version: 3 (0x2)', "        Issuer: $iss", '        Validity', '            Not Before: Oct 21 07:12:44 2026 GMT',
            '            Not After : Jan 19 07:12:43 2027 GMT', "        Subject: $subj", '        X509v3 extensions:', '            X509v3 Subject Alternative Name: ', '                ' . join( ', ', @san ) ), 1 );
    }
    push @l, "subject=$subj" if $w{'-subject'};
    push @l, "issuer=$iss" if $w{'-issuer'};
    push @l, 'notBefore=Oct 21 07:12:44 2026 GMT' if $w{'-dates'} || $w{'-startdate'};
    push @l, 'notAfter=Jan 19 07:12:43 2027 GMT' if $w{'-dates'} || $w{'-enddate'};
    push @l, 'X509v3 Subject Alternative Name: ', '    ' . join( ', ', @san ) if grep {/subjectAltName/} @$o;
    push @l, $pem =~ s/\n\z//r unless $w{'-noout'} || @l;
    return ( join( "\n", @l ), 1 );
}

# --- -o jsonpath / custom-columns ---------------------------------------------------


sub _jp_segments {
    my ($p) = @_;
    my @s;
    $p =~ s/\A\s+|\s+\z//g;
    $p =~ s/\A\$//;
    while ( length $p ) {
        if    ( $p =~ s/\A\.\.((?:[^.\[\\]|\\.)+)// ) { push @s, [ 'rec', $1 =~ s/\\(.)/$1/gr ] }
        elsif ( $p =~ s/\A\.((?:[^.\[\\]|\\.)+)// ) { push @s, [ 'key', $1 =~ s/\\(.)/$1/gr ] }
        elsif ( $p =~ s/\A\[\s*['"]([^'"]*)['"]\s*\]// ) { push @s, [ 'key', $1 ] }
        elsif ( $p =~ s/\A\[\s*\*\s*\]// ) { push @s, ['all'] }
        elsif ( $p =~ s/\A\[\s*(-?\d+)\s*\]// ) { push @s, [ 'idx', $1 ] }
        elsif ( $p =~ s/\A\[\s*(-?\d*)\s*:\s*(-?\d*)\s*\]// ) { push @s, [ 'slice', $1, $2 ] }
        elsif ( $p =~ s/\A\[\s*\?\(\s*@((?:\.(?:[^.\s=!<>)\\]|\\.)+)+)\s*(==|!=)\s*(?:"([^"]*)"|'([^']*)'|(\S+?))\s*\)\s*\]// ) { push @s, [ 'filter', $1, $2, $3 // $4 // $5 ] }
        elsif ( $p =~ s/\A\[\s*\?\(\s*@((?:\.(?:[^.\s)\\]|\\.)+)+)\s*\)\s*\]// ) { push @s, [ 'has', $1 ] }
        elsif ( $p eq '.' || $p eq '@' ) { last }
        else { return undef }
    }
    return \@s;
}

sub _jp_eval {
    my ( $nodes, $segs ) = @_;
    my @cur = @$nodes;
    for my $s (@$segs) {
        my @n;
        for my $x (@cur) {
            if ( $s->[0] eq 'key' ) { push @n, $x->{ $s->[1] } if ref $x eq 'HASH' && exists $x->{ $s->[1] } }
            elsif ( $s->[0] eq 'all' ) { push @n, ref $x eq 'ARRAY' ? @$x : ref $x eq 'HASH' ? @{$x}{ sort keys %$x } : () }
            elsif ( $s->[0] eq 'idx' ) { push @n, $x->[ $s->[1] ] if ref $x eq 'ARRAY' && defined $x->[ $s->[1] ] }
            elsif ( $s->[0] eq 'slice' ) {
                next unless ref $x eq 'ARRAY';
                my ( $f, $t ) = ( length $s->[1] ? $s->[1] : 0, length $s->[2] ? $s->[2] : scalar @$x );
                $_ += @$x for grep { $_ < 0 } $f, $t;
                push @n, @$x[ $f .. ( $t > @$x ? $#$x : $t - 1 ) ] if $f < @$x;
            }
            elsif ( $s->[0] eq 'filter' || $s->[0] eq 'has' ) {
                next unless ref $x eq 'ARRAY';
                my $sub = _jp_segments( $s->[1] ) or next;
                for my $el (@$x) {
                    my ($v) = _jp_eval( [$el], $sub );
                    if ( $s->[0] eq 'has' ) { push @n, $el if defined $v; next }
                    my $vs = defined $v && !ref $v ? ( JSON::MaybeXS::is_bool($v) ? ( $v ? 'true' : 'false' ) : "$v" ) : undef;
                    my $eq = defined $vs && $vs eq $s->[3];
                    push @n, $el if $s->[2] eq '==' ? $eq : !$eq;
                }
            }
            elsif ( $s->[0] eq 'rec' ) {
                my @q = ($x);
                while (@q) {
                    my $y = shift @q;
                    if ( ref $y eq 'HASH' ) { push @n, $y->{ $s->[1] } if exists $y->{ $s->[1] }; push @q, @{$y}{ sort keys %$y } }
                    elsif ( ref $y eq 'ARRAY' ) { push @q, @$y }
                }
            }
        }
        @cur = @n;
    }
    return @cur;
}

sub _jp_text {
    my ($v) = @_;
    return '' unless defined $v;
    return $v ? 'true' : 'false' if JSON::MaybeXS::is_bool($v);
    return JSON::MaybeXS->new( canonical => 1 )->encode($v) if ref $v;
    return "$v";
}

sub jsonpath {
    my ( $data, $tpl ) = @_;
    $tpl =~ s/\A\s*'(.*)'\s*\z/$1/s;
    my @tok;
    while ( length $tpl ) {
        if ( $tpl =~ s/\A\{((?:[^{}"]|"(?:[^"\\]|\\.)*")*)\}// ) { push @tok, [ 'e', $1 ] }
        elsif ( $tpl =~ s/\A([^{]+)// ) { push @tok, [ 't', $1 ] }
        else { return ( undef, 'error: error parsing jsonpath ' . $tpl . ', unclosed action' ) }
    }
    my $err;
    my $run;
    $run = sub {
        my ( $toks, $ctx ) = @_;
        my $out = '';
        my $i = 0;
        while ( $i < @$toks ) {
            my ( $t, $v ) = @{ $toks->[$i] };
            if ( $t eq 't' ) { $out .= $v; $i++; next }
            $v =~ s/\A\s+|\s+\z//g;
            if ( $v =~ /\A"((?:[^"\\]|\\.)*)"\z/ ) { ( my $l = $1 ) =~ s/\\n/\n/g; $l =~ s/\\t/\t/g; $l =~ s/\\(.)/$1/g; $out .= $l; $i++; next }
            if ( $v =~ /\Arange\s+(.+)\z/ ) {
                my $path = $1;
                my ( $depth, $j ) = ( 1, $i + 1 );
                for ( ; $j < @$toks; $j++ ) {
                    next unless $toks->[$j][0] eq 'e';
                    $depth++ if $toks->[$j][1] =~ /\A\s*range\s/;
                    last if $toks->[$j][1] =~ /\A\s*end\s*\z/ && !--$depth;
                }
                my $segs = _jp_segments($path) or do { $err = "error: error parsing jsonpath $path"; return '' };
                my @body = @$toks[ $i + 1 .. $j - 1 ];
                $out .= $run->( \@body, $_ ) for _jp_eval( [$ctx], $segs );
                $i = $j + 1;
                next;
            }
            my $segs = _jp_segments($v) or do { $err = "error: error parsing jsonpath {$v}, unrecognized character"; return '' };
            $out .= join ' ', map { _jp_text($_) } _jp_eval( [$ctx], $segs );
            $i++;
        }
        return $out;
    };
    my $o = $run->( \@tok, $data );
    return ( undef, $err ) if defined $err;
    return ( $o =~ s/\n\z//r );
}

sub _custom_columns {
    my ( $data, $spec ) = @_;
    my @cols = map { [ split /:/, $_, 2 ] } split /,/, $spec;
    return ( undef, 'error: custom-columns format specified but no custom columns given' ) unless @cols;
    my @items = ( $data->{kind} // '' ) eq 'List' ? @{ $data->{items} || [] } : ($data);
    my @rows = ( [ map { $_->[0] } @cols ] );
    for my $it (@items) {
        push @rows, [ map { my $s = _jp_segments( ( $_->[1] // '' ) =~ s/\A\{|\}\z//gr ); my @v = $s ? _jp_eval( [$it], $s ) : (); @v ? join( ',', map { _jp_text($_) } @v ) : '<none>' } @cols ];
    }
    return ( _cols(@rows) );
}

# --- RBAC ---------------------------------------------------------------------

# API-Gruppe je Ressource (Plural der API)
our %GROUP = (
    ( map { $_ => '' } qw( pods services endpoints secrets configmaps persistentvolumeclaims persistentvolumes serviceaccounts events namespaces nodes ) ),
    ( map { $_ => 'apps' } qw( deployments replicasets statefulsets daemonsets ) ),
    ( map { $_ => 'batch' } qw( jobs cronjobs ) ),
    ( map { $_ => 'networking.k8s.io' } qw( ingresses ingressclasses networkpolicies ) ),
    ( map { $_ => 'rbac.authorization.k8s.io' } qw( roles rolebindings clusterroles clusterrolebindings ) ),
    ( map { $_ => 'cert-manager.io' } qw( certificates issuers clusterissuers certificaterequests ) ),
    ( map { $_ => 'acme.cert-manager.io' } qw( challenges orders ) ),
    storageclasses => 'storage.k8s.io', leases => 'coordination.k8s.io',
);
my %API_PLURAL = ( pvcs => 'persistentvolumeclaims' );

# Ressource aus der Kommandozeile (pods, deploy, pods/log, deployments.apps) -> ( plural, gruppe ) oder ()
sub _resource {
    my ($r) = @_;
    my ( $base, $sub ) = split m{/}, lc( $r // '' ), 2;
    my $group;
    ( $base, $group ) = ( $1, $2 ) if $base =~ /\A([a-z]+)\.(.+)\z/;
    my $plural = $KIND{$base} ? ( $API_PLURAL{ $KIND{$base} } // $KIND{$base} ) : exists $GROUP{$base} ? $base : $base eq '*' ? '*' : undef;
    return () unless defined $plural;
    $group //= $GROUP{$plural} // '*';
    return ( $plural . ( defined $sub ? "/$sub" : '' ), $group );
}

my @VIEW_RES = qw( pods pods/log services endpoints configmaps persistentvolumeclaims serviceaccounts events
    deployments replicasets statefulsets daemonsets jobs cronjobs ingresses networkpolicies );
sub _builtin_roles {
    my $rule = sub { my ( $verbs, @res ) = @_; my %g; push @{ $g{ $GROUP{ $_ =~ s{/.*}{}r } } }, $_ for @res;
        return map { { apiGroups => [$_], resources => $g{$_}, verbs => $verbs } } sort keys %g };
    my @ro = qw( get list watch );
    my @rw = ( @ro, qw( create update patch delete deletecollection ) );
    return {
        'cluster-admin' => { rules => [ { apiGroups => ['*'], resources => ['*'], verbs => ['*'] } ] },
        admin => { rules => [ $rule->( \@rw, @VIEW_RES, qw( secrets roles rolebindings pods/exec ) ) ] },
        edit  => { rules => [ $rule->( \@rw, @VIEW_RES, qw( secrets pods/exec ) ) ] },
        view  => { rules => [ $rule->( \@ro, @VIEW_RES ) ] },
    };
}

sub _clusterroles { my ($k) = @_; return { %{ _builtin_roles() }, %{ $k->{clusterroles} || {} } } }

# Wer: { user, groups }
sub _who_sa { my ( $ns, $sa ) = @_; return { user => "system:serviceaccount:$ns:$sa", groups => [ 'system:serviceaccounts', "system:serviceaccounts:$ns", 'system:authenticated' ] } }

sub _subject_match {
    my ( $s, $who, $bns ) = @_;
    my $kind = $s->{kind} // '';
    return $who->{user} eq 'system:serviceaccount:' . ( $s->{namespace} // $bns // '' ) . ':' . ( $s->{name} // '' ) if $kind eq 'ServiceAccount';
    return $who->{user} eq ( $s->{name} // '' ) if $kind eq 'User';
    return scalar grep { $_ eq ( $s->{name} // '' ) } @{ $who->{groups} || [] } if $kind eq 'Group';
    return 0;
}

sub _rule_allows {
    my ( $r, $verb, $group, $res, $name ) = @_;
    my $in = sub { my ( $l, $v ) = @_; scalar grep { $_ eq '*' || $_ eq $v } @{ ref $l eq 'ARRAY' ? $l : [] } };
    return 0 unless $in->( $r->{verbs}, $verb ) && $in->( $r->{apiGroups}, $group ) && $in->( $r->{resources}, $res );
    my @rn = @{ ref $r->{resourceNames} eq 'ARRAY' ? $r->{resourceNames} : [] };
    return 1 unless @rn;
    return defined $name && scalar grep { $_ eq $name } @rn;
}

# Bindungen, die fuer wen in einem Namespace gelten: ( [ regel, quelle ] … )
sub _rules_for {
    my ( $k, $who, $ns ) = @_;
    return ( [ { apiGroups => ['*'], resources => ['*'], verbs => ['*'] }, 'cluster-admin' ] ) if $who->{admin};
    my $crs = _clusterroles($k);
    my @r;
    for my $bn ( sort keys %{ $k->{clusterrolebindings} || {} } ) {
        my $b = $k->{clusterrolebindings}{$bn};
        next unless grep { _subject_match( $_, $who, undef ) } @{ $b->{subjects} || [] };
        my $role = $crs->{ ( $b->{roleRef} || {} )->{name} // '' } or next;
        push @r, map { [ $_, "ClusterRoleBinding/$bn" ] } @{ $role->{rules} || [] };
    }
    return @r unless defined $ns && length $ns;
    my $o = $k->{namespaces}{$ns} || {};
    for my $bn ( sort keys %{ $o->{rolebindings} || {} } ) {
        my $b = $o->{rolebindings}{$bn};
        next unless grep { _subject_match( $_, $who, $ns ) } @{ $b->{subjects} || [] };
        my $rr = $b->{roleRef} || {};
        my $role = ( $rr->{kind} // '' ) eq 'ClusterRole' ? $crs->{ $rr->{name} // '' } : ( $o->{roles} || {} )->{ $rr->{name} // '' };
        next unless $role;
        push @r, map { [ $_, "RoleBinding/$bn" ] } @{ $role->{rules} || [] };
    }
    return @r;
}

sub _allowed {
    my ( $k, $who, $verb, $group, $res, $ns, $name ) = @_;
    return scalar grep { _rule_allows( $_->[0], $verb, $group, $res, $name ) } _rules_for( $k, $who, $ns );
}

sub _forbidden {
    my ( $who, $verb, $group, $res, $ns, $name ) = @_;
    my ($base) = split m{/}, $res;
    return ( defined $name ? qq{$base "$name"} : $base ) . qq{ is forbidden: User "$who->{user}" cannot $verb resource "$res" in API group "$group" }
        . ( defined $ns && length $ns ? qq{in the namespace "$ns"} : 'at the cluster scope' );
}

# kubectl auth can-i VERB RESOURCE[/NAME] [--as …] [--as-group …] [-n ns] | --list
sub _v_auth {
    my ( $k, $a, $o ) = @_;
    my ( $sub, @r ) = @$a;
    if ( ( $sub // '' ) eq 'whoami' ) {
        my $u = ( $o->{f}{as} || [] )->[0] // 'kubernetes-admin';
        return ( "ATTRIBUTE   VALUE\nUsername    $u\nGroups      [" . ( $o->{f}{as} ? 'system:authenticated' : 'kubeadm:cluster-admins system:authenticated' ) . ']', 1 );
    }
    unless ( ( $sub // '' ) eq 'can-i' ) { push @GAPS, "kubectl auth @$a"; return ( '', 0 ) }
    my $as = ( $o->{f}{as} || [] )->[0];
    my $who = !defined $as ? { admin => 1, user => 'kubernetes-admin', groups => ['system:masters'] }
        : $as =~ /\Asystem:serviceaccount:([^:]+):(.+)\z/ ? _who_sa( $1, $2 )
        : { user => $as, groups => [ @{ $o->{f}{'as-group'} || [] }, 'system:authenticated' ] };
    my $ns = $o->{all} ? '' : $o->{ns};
    if ( $o->{list} ) {
        my @rows = ( [ 'Resources', 'Non-Resource URLs', 'Resource Names', 'Verbs' ] );
        for my $x ( _rules_for( $k, $who, $ns ) ) {
            my $r = $x->[0];
            for my $res ( @{ $r->{resources} || [] } ) {
                my @g = @{ $r->{apiGroups} || [''] };
                push @rows, map { [ ( $_ eq '' || $res eq '*' && $_ eq '*' ? $res : "$res.$_" ), '[]', '[' . join( ' ', @{ $r->{resourceNames} || [] } ) . ']', '[' . join( ' ', @{ $r->{verbs} || [] } ) . ']' ] } @g;
            }
        }
        push @rows, [ 'selfsubjectreviews.authentication.k8s.io', '[]', '[]', '[create]' ], [ 'selfsubjectaccessreviews.authorization.k8s.io', '[]', '[]', '[create]' ];
        return ( _cols(@rows), 1 );
    }
    my ( $verb, $what, $nm ) = @r;
    return ( "error: you must specify two arguments: verb resource or a single argument: nonResourceURL", 0 ) unless defined $what;
    ( $what, $nm ) = ( $1, $2 ) if !defined $nm && $what =~ m{\A([^/]+/(?:log|exec|status|scale|portforward|attach|proxy))/([^/]+)\z};
    ( $what, $nm ) = ( $1, $2 ) if !defined $nm && $what =~ m{\A([^/]+)/([^/]+)\z} && !grep { $2 eq $_ } qw( log exec status scale portforward attach proxy );
    my ( $res, $group ) = _resource($what);
    return ( qq{Warning: the server doesn't have a resource type '$what'\n\nno}, 0 ) unless defined $res;
    my $nsx = $CLUSTER{ $KIND{ ( split m{/}, $res )[0] } // '' } || ( split m{/}, $res )[0] =~ /\A(?:nodes|clusterroles|clusterrolebindings|clusterissuers|ingressclasses|storageclasses|namespaces|persistentvolumes)\z/ ? '' : $ns;
    return _allowed( $k, $who, $verb, $group eq '*' ? '' : $group, $res, $nsx, $nm ) ? ( 'yes', 1 ) : ( 'no', 0 );
}

sub _sa_exists {
    my ( $k, $ns, $sa ) = @_;
    return 1 if !defined $sa || $sa eq 'default';
    return exists( ( ( $k->{namespaces}{$ns} || {} )->{serviceaccounts} || {} )->{$sa} );
}

# erste nicht erlaubte Anforderung eines Containers (needs_rbac) -> Meldung oder undef
sub _rbac_denied {
    my ( $k, $ns, $tpl, $c ) = @_;
    my $sa = $tpl->{service_account} // 'default';
    my $who = _who_sa( $ns, $sa );
    for my $n ( @{ $c->{needs_rbac} || [] } ) {
        my $res = $n->{resource};
        my $group = $n->{group} // $GROUP{ ( split m{/}, $res )[0] } // '';
        my $nsx = exists $n->{namespace} ? $n->{namespace} // '' : $ns;
        next if _allowed( $k, $who, $n->{verb}, $group, $res, $nsx, $n->{name} );
        return _forbidden( $who, $n->{verb}, $group, $res, $nsx, $n->{name} );
    }
    return undef;
}

# --- Ingress --------------------------------------------------------------------

sub _gen_objs {
    my ( $k, $kind, $ns ) = @_;
    return $k->{$kind} || {} if $GEN{$kind}[2];
    return ( ( $k->{namespaces}{$ns} || {} )->{$kind} ) || {};
}

sub _ingress_class {
    my ( $k, $ing ) = @_;
    my $c = ( $ing->{spec} || {} )->{ingressClassName} // ( ( $ing->{metadata} || {} )->{annotations} || {} )->{'kubernetes.io/ingress.class'};
    return $c if defined $c;
    my $ics = $k->{ingressclasses} || {};
    my ($d) = grep { ( ( ( $ics->{$_}{metadata} || {} )->{annotations} || {} )->{'ingressclass.kubernetes.io/is-default-class'} // '' ) eq 'true' } sort keys %$ics;
    return $d;
}

# behandelt der Ingress-Controller des Clusters diese Klasse?
sub _handled {
    my ( $k, $cls ) = @_;
    my $ctl = ( $k->{ingress} || {} )->{controller} // return 0;
    my $ic = ( $k->{ingressclasses} || {} )->{ $cls // '' } or return 0;
    return ( ( $ic->{spec} || {} )->{controller} // '' ) eq $ctl;
}

sub _host_match {
    my ( $pat, $host ) = @_;
    return 1 unless defined $pat && length $pat;
    return lc $pat eq lc $host unless $pat =~ /\A\*\.(.+)\z/;
    my $d = $1;
    return $host =~ /\A[^.]+\.\Q$d\E\z/i ? 1 : 0;
}

sub _all_ingresses {
    my ($k) = @_;
    my @i;
    for my $ns ( sort keys %{ $k->{namespaces} || {} } ) {
        my $m = $k->{namespaces}{$ns}{ingresses} || {};
        push @i, map { [ $ns, $_, $m->{$_} ] } sort keys %$m;
    }
    return @i;
}

# Wohin fuehrt host+path? -> ( ns, ingress, backend ) oder ()
sub _ingress_route {
    my ( $k, $host, $path ) = @_;
    my @cand;
    for my $x ( _all_ingresses($k) ) {
        my ( $ns, $n, $ing ) = @$x;
        next unless _handled( $k, _ingress_class( $k, $ing ) );
        for my $r ( @{ ( $ing->{spec} || {} )->{rules} || [] } ) {
            next unless _host_match( $r->{host}, $host );
            my $exact = defined $r->{host} && $r->{host} !~ /\*/ ? 1 : 0;
            for my $p ( @{ ( $r->{http} || {} )->{paths} || [] } ) {
                my $pp = $p->{path} // '/';
                my $t  = $p->{pathType} // 'ImplementationSpecific';
                my $m  = $t eq 'Exact' ? ( $path eq $pp ? 100000 : 0 )
                    : $t eq 'Prefix' ? ( $pp eq '/' || $path eq $pp || $path =~ m{\A\Q${\( $pp =~ s{/\z}{}r )}\E/} ? 1 + length $pp : 0 )
                    : ( index( $path, $pp ) == 0 ? 1 + length $pp : 0 );
                push @cand, [ $m + 1000000 * $exact, $ns, $n, $p->{backend} ] if $m;
            }
        }
    }
    my ($best) = sort { $b->[0] <=> $a->[0] } @cand;
    return $best ? @$best[ 1 .. 3 ] : ();
}

# Zertifikat des Ingress-Controllers fuer einen Host: ( ns, secret ) oder ()
sub _tls_for_host {
    my ( $k, $host ) = @_;
    for my $x ( _all_ingresses($k) ) {
        my ( $ns, $n, $ing ) = @$x;
        next unless _handled( $k, _ingress_class( $k, $ing ) );
        for my $t ( @{ ( $ing->{spec} || {} )->{tls} || [] } ) {
            return ( $ns, $t->{secretName}, $n ) if grep { _host_match( $_, $host ) } @{ $t->{hosts} || [] };
        }
    }
    return ();
}

# Pseudo-PEM: Nutzlast "subject=…;san=a,b;issuer=…;trusted=1" in Base64
sub _pem {
    my (%c) = @_;
    return "-----BEGIN CERTIFICATE-----\n" . MIME::Base64::encode_base64( join ';', map {"$_=$c{$_}"} sort keys %c ) . "-----END CERTIFICATE-----\n";
}

sub _cert_info {
    my ($pem) = @_;
    my ($b) = ( $pem // '' ) =~ /-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END/s or return undef;
    my $t = MIME::Base64::decode_base64($b);
    return undef unless $t =~ /san=/;
    my %c = map { split /=/, $_, 2 } split /;/, $t;
    return { %c, san => [ split /,/, $c{san} // '' ] };
}

# Was ein Client von https://host sieht: ( ok, curl-code, meldung )
sub _tls_check {
    my ( $k, $host, $insecure ) = @_;
    my ( $ns, $sec ) = _tls_for_host( $k, $host );
    my $s = defined $sec ? _secret( $k, $ns, $sec ) : undef;
    my $info = $s && defined $s->{'tls.crt'} ? _cert_info( $s->{'tls.crt'} ) : undef;
    return (1) if $insecure;
    return ( 0, 60, 'SSL certificate problem: self-signed certificate' ) unless $info;
    return ( 0, 60, "SSL: no alternative certificate subject name matches target host name '$host'" ) unless grep { _host_match( $_, $host ) } @{ $info->{san} };
    return ( 0, 60, 'SSL certificate problem: unable to get local issuer certificate' ) unless $info->{trusted};
    return (1);
}

my %HTTP = ( 200 => 'OK', 308 => 'Permanent Redirect', 404 => 'Not Found', 502 => 'Bad Gateway', 503 => 'Service Temporarily Unavailable' );
sub _nginx_page { my ($c) = @_; return "<html>\n<head><title>$c $HTTP{$c}</title></head>\n<body>\n<center><h1>$c $HTTP{$c}</h1></center>\n<hr><center>nginx</center>\n</body>\n</html>" }

# Antwort des Ingress-Controllers: ( http-code, rumpf )
sub _ingress_http {
    my ( $k, $scheme, $host, $path ) = @_;
    my ( $ns, $ing, $be ) = _ingress_route( $k, $host, $path );
    return ( 404, _nginx_page(404) ) unless $ns;
    return ( 308, _nginx_page(308) ) if $scheme eq 'http' && _tls_for_host( $k, $host );
    my $sb  = ( $be || {} )->{service} || {};
    my $svc = ( $k->{namespaces}{$ns}{services} || {} )->{ $sb->{name} // '' } or return ( 503, _nginx_page(503) );
    my $want = $sb->{port} || {};
    my ($sp) = grep { defined $want->{number} ? $_->{port} == $want->{number} : ( $_->{name} // '' ) eq ( $want->{name} // '' ) } @{ $svc->{ports} || [] };
    return ( 503, _nginx_page(503) ) unless $sp;
    my @e = _endpoints( $k, $ns, $sb->{name} ) or return ( 503, _nginx_page(503) );
    my ($dc) = @{ $e[0]{template}{containers} };
    return ( 502, _nginx_page(502) ) unless grep { $_ == $sp->{target} } @{ $dc->{listens} || $dc->{ports} || [] };
    return ( 200, $dc->{http_body} // '{"status":"ok"}' );
}

sub _public_host {
    my ( $k, $host ) = @_;
    return 0 unless $k->{ingress};
    return 1 if $host eq ( $k->{ingress}{address} // '' ) || exists( ( $k->{dns} || {} )->{$host} );
    return scalar grep { my $i = $_->[2]; grep { defined $_->{host} && _host_match( $_->{host}, $host ) } @{ ( $i->{spec} || {} )->{rules} || [] } } _all_ingresses($k);
}

# curl|wget gegen den Ingress-Controller
sub _client_ingress {
    my ( $k, $tool, $cmd, $scheme, $host, $path ) = @_;
    my ( %f, $w );
    my @c = @$cmd[ 1 .. $#$cmd ];
    while (@c) {
        my $x = shift @c;
        if ( $tool eq 'curl' && $x =~ /\A-([a-zA-Z]+)\z/ ) {
            my $fl = $1;
            $f{$_} = 1 for split //, $fl;
            if ( $fl =~ /[owHmXdA]\z/ ) { my $v = shift @c; $w = $v if $fl =~ /w\z/ }
        }
        elsif ( $x eq '--insecure' || $x eq '--no-check-certificate' ) { $f{k} = 1 }
        elsif ( $x eq '--fail' ) { $f{f} = 1 }
        elsif ( $x eq '--location' ) { $f{L} = 1 }
        elsif ( $x eq '--head' ) { $f{I} = 1 }
        elsif ( $x =~ /\A--(?:write-out|output|header|max-time|connect-timeout|resolve|user-agent)\z/ ) { my $v = shift @c; $w = $v if $x eq '--write-out' }
        elsif ( $x =~ /\A--write-out=(.*)\z/s ) { $w = $1 }
        elsif ( $tool eq 'wget' && $x =~ /\A-[qOST]+\z/ && $x =~ /[OT]\z/ ) { shift @c }
    }
    for my $hop ( 1 .. 3 ) {
        if ( $scheme eq 'https' ) {
            my ( $ok, $code, $msg ) = _tls_check( $k, $host, $f{k} );
            unless ($ok) {
                return ( "curl: ($code) $msg\nMore details here: https://curl.se/docs/sslcerts.html", 0 ) if $tool eq 'curl';
                return ( "Connecting to $host (" . ( ( $k->{ingress} || {} )->{address} // '' ) . ":443)\nssl_client: $host: certificate verification failed: " . ( $msg =~ s/\ASSL(?: certificate problem)?:\s*//r ) . "\nwget: error getting response: Connection reset by peer", 0 );
            }
        }
        my ( $st, $body ) = _ingress_http( $k, $scheme, $host, $path );
        if ( $st == 308 && ( $f{L} || $tool eq 'wget' ) ) { $scheme = 'https'; next }
        return ( $st == 200 ? ( $body, 1 ) : ( "wget: server returned error: HTTP/1.1 $st $HTTP{$st}", 0 ) ) if $tool eq 'wget';
        return ( "curl: (22) The requested URL returned error: $st", 0 ) if $f{f} && $st >= 400;
        my $out = $f{I} ? "HTTP/1.1 $st $HTTP{$st}\nContent-Type: text/html\n" . ( $st == 308 ? "Location: https://$host$path\n" : '' ) : $body;
        $out = '' if $f{o};
        if ( defined $w ) { ( my $ww = $w ) =~ s/%\{http_code\}/$st/g; $ww =~ s/\\n/\n/g; $out .= $ww }
        return ( $out =~ s/\n\z//r, 1 );
    }
    return ( 'curl: (47) Maximum (3) redirects followed', 0 );
}

# Hinweise des Ingress-Controllers (wie im Log von ingress-nginx)
sub _ingress_log {
    my ($k) = @_;
    my @l;
    my $i = 0;
    my $ts = sub { sprintf 'W1024 08:%02d:%02d.%06d       7', 10 + $i, ( 7 * ++$i ) % 60, 118223 + 977 * $i };
    for my $x ( _all_ingresses($k) ) {
        my ( $ns, $n, $ing ) = @$x;
        my $cls = _ingress_class( $k, $ing );
        unless ( _handled( $k, $cls ) ) {
            push @l, $ts->() =~ s/\AW/I/r . qq{ store.go:440] "Ignoring ingress because of error while validating ingress class" ingress="$ns/$n" error="}
                . ( defined $cls ? qq{no object matching key \\"$cls\\" in local store} : 'ingress does not contain a valid IngressClass' ) . '"';
            next;
        }
        for my $r ( @{ ( $ing->{spec} || {} )->{rules} || [] } ) {
            for my $p ( @{ ( $r->{http} || {} )->{paths} || [] } ) {
                my $sb = ( $p->{backend} || {} )->{service} || {};
                my $sn = $sb->{name} // '';
                my $svc = ( $k->{namespaces}{$ns}{services} || {} )->{$sn};
                if ( !$svc ) { push @l, $ts->() . qq{ controller.go:1214] Error obtaining Endpoints for Service "$ns/$sn": no object matching key "$ns/$sn" in local store}; next }
                my $want = $sb->{port} || {};
                my ($sp) = grep { defined $want->{number} ? $_->{port} == $want->{number} : ( $_->{name} // '' ) eq ( $want->{name} // '' ) } @{ $svc->{ports} || [] };
                if ( !$sp ) { push @l, $ts->() . qq{ controller.go:1196] Service "$ns/$sn" does not have any port matching } . ( $want->{number} // $want->{name} // '' ); next }
                push @l, $ts->() . qq{ controller.go:1214] Service "$ns/$sn" does not have any active Endpoint.} unless _endpoints( $k, $ns, $sn );
            }
        }
        for my $t ( @{ ( $ing->{spec} || {} )->{tls} || [] } ) {
            my $sec = $t->{secretName} // '';
            my $s = _secret( $k, $ns, $sec );
            if ( !$s || !defined $s->{'tls.crt'} ) {
                push @l, $ts->() . qq{ backend_ssl.go:47] Error obtaining X.509 certificate: no object matching key "$ns/$sec" in local store},
                    $ts->() . qq{ controller.go:1418] Error getting SSL certificate "$ns/$sec": local SSL certificate $ns/$sec was not found. Using default certificate};
                next;
            }
            my $info = _cert_info( $s->{'tls.crt'} ) or next;
            for my $h ( @{ $t->{hosts} || [] } ) {
                push @l, $ts->() . qq{ controller.go:1442] Unexpected error validating SSL certificate "$ns/$sec" for server "$h": x509: certificate is valid for }
                    . join( ', ', @{ $info->{san} } ) . ", not $h" unless grep { _host_match( $_, $h ) } @{ $info->{san} };
            }
        }
    }
    return @l;
}

# --- cert-manager ---------------------------------------------------------------

sub _cm_ns { my ($k) = @_; return ( $k->{cert_manager} || {} )->{namespace} // 'cert-manager' }

our @ACME = ( 'https://acme-v02.api.letsencrypt.org/directory', 'https://acme-staging-v02.api.letsencrypt.org/directory' );

# Certificates eines Namespace: gespeicherte und die aus Ingress-Annotationen (ingress-shim)
sub _certs {
    my ( $k, $ns ) = @_;
    my %c = %{ ( ( $k->{namespaces}{$ns} || {} )->{certificates} ) || {} };
    for my $x ( grep { $_->[0] eq $ns } _all_ingresses($k) ) {
        my ( undef, $n, $ing ) = @$x;
        my $an = ( $ing->{metadata} || {} )->{annotations} || {};
        my ( $kind, $iss ) = defined $an->{'cert-manager.io/cluster-issuer'} ? ( 'ClusterIssuer', $an->{'cert-manager.io/cluster-issuer'} )
            : defined $an->{'cert-manager.io/issuer'} ? ( 'Issuer', $an->{'cert-manager.io/issuer'} ) : next;
        for my $t ( @{ ( $ing->{spec} || {} )->{tls} || [] } ) {
            next unless defined $t->{secretName};
            $c{ $t->{secretName} } //= { metadata => { ownerReferences => [ { apiVersion => "networking.k8s.io/v1", kind => "Ingress", name => $n, controller => JSON::MaybeXS::true(), blockOwnerDeletion => JSON::MaybeXS::true() } ] },
                spec => { secretName => $t->{secretName}, dnsNames => [ @{ $t->{hosts} || [] } ], issuerRef => { kind => $kind, name => $iss, group => 'cert-manager.io' } } };
        }
    }
    return \%c;
}

# ( issuer, art, namespace-der-geheimnisse ) oder ()
sub _issuer_of {
    my ( $k, $ns, $ref ) = @_;
    my $kind = $ref->{kind} // 'Issuer';
    return () if ( $ref->{group} // 'cert-manager.io' ) ne 'cert-manager.io';
    if ( $kind eq 'ClusterIssuer' ) { my $i = ( $k->{clusterissuers} || {} )->{ $ref->{name} // '' } or return (); return ( $i, $kind, _cm_ns($k) ) }
    my $i = ( ( $k->{namespaces}{$ns} || {} )->{issuers} || {} )->{ $ref->{name} // '' } or return ();
    return ( $i, 'Issuer', $ns );
}

# ( bereit, grund, meldung )
sub _issuer_state {
    my ( $k, $i, $sns ) = @_;
    my $s = $i->{spec} || {};
    if ( $s->{ca} ) {
        my $sn = $s->{ca}{secretName} // '';
        my $sec = _secret( $k, $sns, $sn ) or return ( 0, 'ErrGetKeyPair', qq{Error getting keypair for CA issuer: secrets "$sn" not found} );
        return ( 0, 'ErrInvalidKeyPair', 'Error getting keypair for CA issuer: certificate data is empty' ) unless defined $sec->{'tls.crt'} && defined $sec->{'tls.key'};
        return ( 1, 'KeyPairVerified', 'Signing CA verified' );
    }
    if ( $s->{acme} ) {
        my $srv = $s->{acme}{server} // '';
        my @known = ( @ACME, @{ ( $k->{cert_manager} || {} )->{acme_servers} || [] } );
        unless ( grep { $_ eq $srv } @known ) {
            my ($h) = $srv =~ m{\Ahttps?://([^/:]+)};
            return ( 0, 'ErrRegisterACMEAccount', qq{Failed to register ACME account: Get "$srv": dial tcp: lookup } . ( $h // $srv ) . ' on 10.43.0.10:53: no such host' );
        }
        return ( 1, 'ACMEAccountRegistered', 'The ACME account was registered with the ACME server' );
    }
    return ( 1, 'IsReady', '' ) if $s->{selfSigned};
    return ( 0, 'InvalidConfig', 'no issuer type specified for Issuer' );
}

# Zustand eines Certificate: { ready, reason, message, cr => [bereit, grund, meldung], challenges => [ … ], issuer => … }
sub _cert_state {
    my ( $k, $ns, $name, $c ) = @_;
    my $s = $c->{spec} || {};
    my $ref = $s->{issuerRef} || {};
    my %r = ( name => $name, secret => $s->{secretName}, dns => [ @{ $s->{dnsNames} || [] } ], challenges => [] );
    my $not = sub { my ( $cr_reason, $cr_msg ) = @_; return { %r, ready => 0, reason => 'DoesNotExist', message => 'Issuing certificate as Secret does not exist', cr => [ 0, $cr_reason, $cr_msg ] } };
    my ( $i, $ikind, $sns ) = _issuer_of( $k, $ns, $ref );
    my $ik = $ref->{kind} // 'Issuer';
    return $not->( 'Pending', qq{Referenced "$ik" not found: } . lc($ik) . qq{.cert-manager.io "} . ( $ref->{name} // '' ) . '" not found' ) unless $i;
    my ($iready) = _issuer_state( $k, $i, $sns );
    return $not->( 'Pending', 'Referenced issuer does not have a Ready status condition' ) unless $iready;
    return $not->( 'Pending', 'spec.dnsNames: at least one DNS name is required' ) unless @{ $r{dns} } || defined $s->{commonName};
    my $is = $i->{spec};
    my $trusted = 1;
    if ( $is->{acme} ) {
        $trusted = ( $is->{acme}{server} // '' ) !~ /staging/ ? 1 : 0;
        my $pending = 0;
        for my $d ( @{ $r{dns} } ) {
            my ( $state, $reason ) = ( 'valid', 'Successfully authorized domain' );
            my ($sol) = grep { my $sel = ( $_->{selector} || {} )->{dnsNames}; !$sel || grep { $_ eq $d } @$sel } @{ $is->{acme}{solvers} || [] };
            if ( !$sol || ( $d =~ /\A\*/ && !$sol->{dns01} ) ) {
                ( $state, $reason ) = ( 'errored', 'Failed to determine a valid solver configuration for the set of domains on the Order: no configured challenge solvers can be used for this challenge' );
            }
            elsif ( my $h = $sol->{http01} ) {
                my $ingc = ( $h->{ingress} || {} );
                my $cls = $ingc->{ingressClassName} // $ingc->{class};
                my %dns = %{ $k->{dns} || {} };
                if ( %dns && !exists $dns{$d} ) {
                    ( $state, $reason ) = ( 'pending', qq{Waiting for HTTP-01 challenge propagation: failed to perform self check GET request 'http://$d/.well-known/acme-challenge/tP3dBxM0Ugs3Fv2sHzv5Kp0yZq1rWc8eJn4aLo6iYuQ': Get "http://$d/.well-known/acme-challenge/tP3dBxM0Ugs3Fv2sHzv5Kp0yZq1rWc8eJn4aLo6iYuQ": dial tcp: lookup $d on 10.43.0.10:53: no such host} );
                }
                elsif ( !_handled( $k, $cls ) ) {
                    ( $state, $reason ) = ( 'pending', q{Waiting for HTTP-01 challenge propagation: wrong status code '404', expected '200'} );
                }
            }
            elsif ( my $dn = $sol->{dns01} ) {
                my ($prov) = grep { ref $dn->{$_} eq 'HASH' } sort keys %$dn;
                my $ref2 = $prov ? ( $dn->{$prov}{apiTokenSecretRef} || $dn->{$prov}{tsigSecretSecretRef} || $dn->{$prov}{secretAccessKeySecretRef} ) : undef;
                if ($ref2) {
                    my $sec = _secret( $k, $sns, $ref2->{name} // '' );
                    ( $state, $reason ) = ( 'errored', "error getting $prov secret: " . ( $sec ? qq{key "$ref2->{key}" not found in secret} : qq{secrets "} . ( $ref2->{name} // '' ) . '" not found' ) )
                        unless $sec && defined $sec->{ $ref2->{key} // '' };
                }
            }
            push @{ $r{challenges} }, { domain => $d, state => $state, reason => $reason, type => $sol && $sol->{dns01} ? 'DNS-01' : 'HTTP-01' };
            $pending = 1 if $state ne 'valid';
        }
        if ($pending) {
            my ($bad) = grep { $_->{state} ne 'valid' } @{ $r{challenges} };
            return { %{ $not->( 'Pending', qq{Waiting on certificate issuance from order $ns/$name-1-2873461: "} . ( $bad->{state} eq 'errored' ? 'errored' : 'pending' ) . '"' ) }, order => $bad->{state} };
        }
    }
    $trusted = 0 if $is->{selfSigned};
    $trusted = ( $is->{ca}{trusted} // 1 ) ? 1 : 0 if $is->{ca};
    return { %r, ready => 1, reason => 'Ready', message => 'Certificate is up to date and has not expired', cr => [ 1, 'Issued', 'Certificate fetched from issuer successfully' ],
        order => 'valid', trusted => $trusted, issuer => "$ikind/" . ( $ref->{name} // '' ) };
}

# Secret aus dem Zustand, sonst eines, das cert-manager ausgestellt hat
sub _secret {
    my ( $k, $ns, $name ) = @_;
    my $s = ( ( $k->{namespaces}{$ns} || {} )->{secrets} || {} )->{ $name // '' };
    return $s if $s;
    my $certs = _certs( $k, $ns );
    for my $cn ( sort keys %$certs ) {
        my $c = $certs->{$cn};
        next unless ( ( $c->{spec} || {} )->{secretName} // '' ) eq ( $name // '' );
        my $st = _cert_state( $k, $ns, $cn, $c );
        next unless $st->{ready};
        my @dns = @{ $st->{dns} };
        return { 'tls.crt' => _pem( subject => 'CN=' . ( $dns[0] // $cn ), san => join( ',', @dns ), issuer => $st->{issuer}, trusted => $st->{trusted} ),
            'tls.key' => "-----BEGIN PRIVATE KEY-----\nMC4CAQAwBQYDK2VwBCIEIOx0Zl8i\n-----END PRIVATE KEY-----\n", _issued => 1 };
    }
    return undef;
}

# alle Secrets eines Namespace mit den ausgestellten
sub _secrets_all {
    my ( $k, $ns ) = @_;
    my %s = %{ ( ( $k->{namespaces}{$ns} || {} )->{secrets} ) || {} };
    if ( $k->{helm} ) { Langertha::Holmgang::Sim::Linux::_part('Helm'); %s = ( Langertha::Holmgang::Sim::Linux::Helm::release_secrets( $k, $ns ), %s ) }
    for my $c ( values %{ _certs( $k, $ns ) } ) {
        my $sn = ( $c->{spec} || {} )->{secretName} // next;
        next if $s{$sn};
        my $x = _secret( $k, $ns, $sn ) or next;
        $s{$sn} = $x;
    }
    return \%s;
}

sub _secret_type {
    my ($s) = @_;
    return 'helm.sh/release.v1' if $s->{_helm};
    return defined $s->{'tls.crt'} && defined $s->{'tls.key'} ? 'kubernetes.io/tls' : 'Opaque';
}

sub _cm_log {
    my ($k) = @_;
    my @l;
    my $i = 0;
    for my $ns ( sort keys %{ $k->{namespaces} || {} } ) {
        my $certs = _certs( $k, $ns );
        for my $cn ( sort keys %$certs ) {
            my $st = _cert_state( $k, $ns, $cn, $certs->{$cn} );
            next if $st->{ready};
            $i++;
            my ($ch) = grep { $_->{state} ne 'valid' } @{ $st->{challenges} };
            push @l, sprintf( 'E1024 08:%02d:%02d.%06d       1 controller.go:157] "re-queuing item due to error processing" err="%s" logger="cert-manager.controller" key="%s/%s-1"',
                20 + $i, ( 13 * $i ) % 60, 418310 + 711 * $i, ( $ch ? $ch->{reason} : $st->{cr}[2] ) =~ s/"/\\"/gr, $ns, $cn );
        }
    }
    for my $ci ( sort keys %{ $k->{clusterissuers} || {} } ) {
        my ( $ok, $reason, $msg ) = _issuer_state( $k, $k->{clusterissuers}{$ci}, _cm_ns($k) );
        push @l, sprintf( 'E1024 08:31:%02d.%06d       1 setup.go:%d] "%s" err="%s" logger="cert-manager.controller" resource_name="%s" resource_kind="ClusterIssuer"', ++$i % 60, 207110 + $i, 100 + $i, $reason, $msg =~ s/"/\\"/gr, $ci ) unless $ok;
    }
    return @l;
}

# --- Tabellen und Beschreibungen der Arten in API-Form ---------------------------------

sub _cond_text { my ($b) = @_; return $b ? 'True' : 'False' }

# Status fuer -o yaml|json
sub _gen_status {
    my ( $k, $kind, $ns, $name, $x ) = @_;
    if ( $kind eq 'certificates' ) {
        my $st = _cert_state( $k, $ns, $name, $x );
        return { conditions => [ { type => 'Ready', status => _cond_text( $st->{ready} ), reason => $st->{reason}, message => $st->{message} } ] };
    }
    if ( $kind eq 'issuers' || $kind eq 'clusterissuers' ) {
        my ( $ok, $reason, $msg ) = _issuer_state( $k, $x, $kind eq 'issuers' ? $ns : _cm_ns($k) );
        return { conditions => [ { type => 'Ready', status => _cond_text($ok), reason => $reason, message => $msg } ] };
    }
    if ( $kind eq 'ingresses' && _handled( $k, _ingress_class( $k, $x ) ) ) {
        return { loadBalancer => { ingress => [ { ip => ( $k->{ingress} || {} )->{address} // '' } ] } };
    }
    return undef;
}

sub _gen_rows {
    my ( $k, $kind, $ns, $o, $name ) = @_;
    my $objs = $kind eq 'certificates' ? _certs( $k, $ns ) : _gen_objs( $k, $kind, $ns );
    $objs = { %{ _builtin_roles() }, %$objs } if $kind eq 'clusterroles';
    $objs = { default => {}, %$objs } if $kind eq 'serviceaccounts' && $k->{namespaces}{$ns};
    my @n = grep { !defined $name || $_ eq $name } sort keys %$objs;
    return ( undef, qq{Error from server (NotFound): $GEN{$kind}[3] "$name" not found} ) if defined $name && !@n;
    return ( { map { $_ => { %{ $objs->{$_} }, ( _gen_status( $k, $kind, $ns, $_, $objs->{$_} ) ? ( _status => _gen_status( $k, $kind, $ns, $_, $objs->{$_} ) ) : () ) } } @n } ) if $o->{out} && $o->{out} =~ /\A(?:yaml|json)/;
    my $wide = ( $o->{out} // '' ) eq 'wide';
    my @rows;
    if ( $kind eq 'ingresses' ) {
        @rows = ( [qw( NAME CLASS HOSTS ADDRESS PORTS AGE )], map {
            my $i = $objs->{$_};
            my $s = $i->{spec} || {};
            [ $_, $s->{ingressClassName} // '<none>', join( ',', map { $_->{host} // '*' } @{ $s->{rules} || [] } ) || '*',
                _handled( $k, _ingress_class( $k, $i ) ) ? ( $k->{ingress} || {} )->{address} // '' : '', @{ $s->{tls} || [] } ? '80, 443' : '80', '41d' ];
        } @n );
    }
    elsif ( $kind eq 'ingressclasses' ) {
        @rows = ( [qw( NAME CONTROLLER PARAMETERS AGE )], map { [ $_, ( $objs->{$_}{spec} || {} )->{controller} // '', '<none>', '41d' ] } @n );
    }
    elsif ( $kind eq 'serviceaccounts' ) {
        @rows = ( [qw( NAME SECRETS AGE )], map { [ $_, 0, '41d' ] } @n );
    }
    elsif ( $kind eq 'roles' || $kind eq 'clusterroles' ) {
        @rows = ( [ 'NAME', 'CREATED AT' ], map { [ $_, '2026-09-13T08:14:51Z' ] } @n );
    }
    elsif ( $kind eq 'rolebindings' || $kind eq 'clusterrolebindings' ) {
        @rows = ( [ qw( NAME ROLE AGE ), ( $wide ? qw( USERS GROUPS SERVICEACCOUNTS ) : () ) ], map {
            my $b = $objs->{$_};
            my @s = @{ $b->{subjects} || [] };
            my $sj = sub { my ($t) = @_; join ',', map { $t eq 'ServiceAccount' ? ( $_->{namespace} // $ns ) . ":$_->{name}" : $_->{name} } grep { ( $_->{kind} // '' ) eq $t } @s };
            [ $_, ( ( $b->{roleRef} || {} )->{kind} // '' ) . '/' . ( ( $b->{roleRef} || {} )->{name} // '' ), '41d', ( $wide ? ( $sj->('User'), $sj->('Group'), $sj->('ServiceAccount') ) : () ) ];
        } @n );
    }
    elsif ( $kind eq 'certificates' ) {
        @rows = ( [qw( NAME READY SECRET AGE )], map { my $st = _cert_state( $k, $ns, $_, $objs->{$_} ); [ $_, _cond_text( $st->{ready} ), $st->{secret} // '', '3d' ] } @n );
    }
    elsif ( $kind eq 'issuers' || $kind eq 'clusterissuers' ) {
        @rows = ( [qw( NAME READY AGE )], map { my ($ok) = _issuer_state( $k, $objs->{$_}, $kind eq 'issuers' ? $ns : _cm_ns($k) ); [ $_, _cond_text($ok), '41d' ] } @n );
    }
    return ( \@rows );
}

sub _derived_rows {
    my ( $k, $kind, $ns ) = @_;
    my $certs = _certs( $k, $ns );
    my @st = map { _cert_state( $k, $ns, $_, $certs->{$_} ) } sort keys %$certs;
    if ( $kind eq 'certificaterequests' ) {
        return ( [qw( NAME APPROVED DENIED READY ISSUER REQUESTOR AGE )],
            map { [ "$_->{name}-1", 'True', '', _cond_text( $_->{cr}[0] ), ( ( $certs->{ $_->{name} }{spec} || {} )->{issuerRef} || {} )->{name} // '', 'system:serviceaccount:cert-manager:cert-manager', '12m' ] } @st );
    }
    my @acme = grep { defined $_->{order} } @st;
    if ( $kind eq 'orders' ) { return ( [qw( NAME STATE AGE )], map { [ "$_->{name}-1-2873461", $_->{order}, '12m' ] } @acme ) }
    my $i = 0;
    return ( [qw( NAME STATE DOMAIN AGE )], map { my $c = $_; map { [ "$c->{name}-1-2873461-" . ( 1902000000 + 7919 * ++$i ), $_->{state}, $_->{domain}, '12m' ] } @{ $c->{challenges} } } @acme );
}

# abgeleitete Objekte in API-Form (fuer -o yaml|json|jsonpath)
sub _derived_objs {
    my ( $k, $kind, $ns ) = @_;
    my $certs = _certs( $k, $ns );
    my %o;
    my $i = 0;
    for my $cn ( sort keys %$certs ) {
        my $st = _cert_state( $k, $ns, $cn, $certs->{$cn} );
        my $ref = ( $certs->{$cn}{spec} || {} )->{issuerRef} || {};
        my $meta = sub { { name => $_[0], namespace => $ns, ownerReferences => [ { apiVersion => 'cert-manager.io/v1', kind => $_[1], name => $_[2], controller => JSON::MaybeXS::true() } ] } };
        if ( $kind eq 'certificaterequests' ) {
            $o{"$cn-1"} = { apiVersion => 'cert-manager.io/v1', kind => 'CertificateRequest', metadata => $meta->( "$cn-1", 'Certificate', $cn ),
                spec => { issuerRef => $ref, username => 'system:serviceaccount:cert-manager:cert-manager' },
                status => { conditions => [ { type => 'Approved', status => 'True', reason => 'cert-manager.io', message => 'Certificate request has been approved by cert-manager.io' },
                    { type => 'Ready', status => _cond_text( $st->{cr}[0] ), reason => $st->{cr}[1], message => $st->{cr}[2] } ] } };
            next;
        }
        next unless defined $st->{order};
        my $on = "$cn-1-2873461";
        if ( $kind eq 'orders' ) {
            my ($bad) = grep { $_->{state} ne 'valid' } @{ $st->{challenges} };
            $o{$on} = { apiVersion => 'acme.cert-manager.io/v1', kind => 'Order', metadata => $meta->( $on, 'CertificateRequest', "$cn-1" ),
                spec => { dnsNames => $st->{dns}, issuerRef => $ref }, status => { state => $st->{order}, ( $bad ? ( reason => $bad->{reason} ) : () ) } };
            next;
        }
        for my $c ( @{ $st->{challenges} } ) {
            my $chn = "$on-" . ( 1902000000 + 7919 * ++$i );
            $o{$chn} = { apiVersion => 'acme.cert-manager.io/v1', kind => 'Challenge', metadata => $meta->( $chn, 'Order', $on ),
                spec => { dnsName => $c->{domain}, type => $c->{type}, issuerRef => $ref },
                status => { state => $c->{state}, reason => $c->{reason}, presented => $c->{state} eq 'errored' ? JSON::MaybeXS::false() : JSON::MaybeXS::true(),
                    processing => $c->{state} eq 'valid' ? JSON::MaybeXS::false() : JSON::MaybeXS::true() } };
        }
    }
    return \%o;
}

sub _describe_gen {
    my ( $k, $kind, $ns, $name ) = @_;
    if ( $DERIVED{$kind} ) {
        my $certs = _certs( $k, $ns );
        for my $cn ( sort keys %$certs ) {
            my $st = _cert_state( $k, $ns, $cn, $certs->{$cn} );
            next unless index( $name // '', $cn ) == 0 || !defined $name;
            if ( $kind eq 'certificaterequests' ) {
                return ( join( "\n", "Name:         $cn-1", "Namespace:    $ns", 'API Version:  cert-manager.io/v1', 'Kind:         CertificateRequest', 'Status:', '  Conditions:',
                    '    Type:     Approved', '    Status:   True', '    Type:     Ready', '    Status:   ' . _cond_text( $st->{cr}[0] ), "    Reason:   $st->{cr}[1]", "    Message:  $st->{cr}[2]",
                    'Events:  <none>' ), 1 );
            }
            my @ch = @{ $st->{challenges} } or next;
            my ($c) = grep { $_->{state} ne 'valid' } @ch;
            $c //= $ch[0];
            return ( join( "\n", "Name:         " . ( $name // "$cn-1-2873461" ), "Namespace:    $ns", 'API Version:  acme.cert-manager.io/v1', 'Kind:         ' . ( $kind eq 'orders' ? 'Order' : 'Challenge' ),
                'Spec:', "  Dns Name:  $c->{domain}", "  Type:      $c->{type}", 'Status:', "  Presented:   " . ( $c->{state} eq 'errored' ? 'false' : 'true' ), "  Processing:  " . ( $c->{state} eq 'valid' ? 'false' : 'true' ),
                "  Reason:      $c->{reason}", "  State:       $c->{state}", 'Events:  <none>' ), 1 );
        }
        return ( qq{Error from server (NotFound): $SINGULAR{$kind} "} . ( $name // '' ) . '" not found', 0 );
    }
    my $objs = $kind eq 'certificates' ? _certs( $k, $ns ) : _gen_objs( $k, $kind, $ns );
    $objs = { %{ _builtin_roles() }, %$objs } if $kind eq 'clusterroles';
    $objs = { default => {}, %$objs } if $kind eq 'serviceaccounts';
    my $x = $objs->{ $name // '' } or return ( qq{Error from server (NotFound): $GEN{$kind}[3] "} . ( $name // '' ) . '" not found', 0 );
    my $s = $x->{spec} || {};
    my $m = $x->{metadata} || {};
    my $kv = sub { my ($h) = @_; my @k = sort keys %{ $h || {} }; @k ? join( "\n              ", map {"$_: $h->{$_}"} @k ) : '<none>' };
    my @l = ( "Name:         $name", ( $GEN{$kind}[2] ? () : "Namespace:    $ns" ), 'Labels:       ' . $kv->( $m->{labels} ), 'Annotations:  ' . $kv->( $m->{annotations} ) );
    if ( $kind eq 'ingresses' ) {
        my $cls = _ingress_class( $k, $x );
        push @l, 'Address:          ' . ( _handled( $k, $cls ) ? ( $k->{ingress} || {} )->{address} // '' : '' ), 'Ingress Class:    ' . ( $s->{ingressClassName} // '<none>' ), 'Default backend:  <default>';
        push @l, 'TLS:', map { '  ' . ( $_->{secretName} // 'SNI routes' ) . ' terminates ' . join( ',', @{ $_->{hosts} || [] } ) } @{ $s->{tls} || [] } if @{ $s->{tls} || [] };
        push @l, 'Rules:', '  Host              Path  Backends', '  ----              ----  --------';
        for my $r ( @{ $s->{rules} || [] } ) {
            push @l, '  ' . ( $r->{host} // '*' );
            for my $p ( @{ ( $r->{http} || {} )->{paths} || [] } ) {
                my $sb = ( $p->{backend} || {} )->{service} || {};
                my $port = ( $sb->{port} || {} )->{number} // ( $sb->{port} || {} )->{name} // '';
                my $svc = ( $k->{namespaces}{$ns}{services} || {} )->{ $sb->{name} // '' };
                my $ep = !$svc ? qq{<error: services "} . ( $sb->{name} // '' ) . '" not found>'
                    : do { my @e = _endpoints( $k, $ns, $sb->{name} ); my ($sp) = grep { $port =~ /\A\d+\z/ ? $_->{port} == $port : ( $_->{name} // '' ) eq $port } @{ $svc->{ports} || [] };
                        !$sp ? '<error: service port not found>' : @e ? join( ',', map {"$_->{ip}:$sp->{target}"} @e ) : '' };
                push @l, sprintf( '                    %-5s %s:%s (%s)', $p->{path} // '/', $sb->{name} // '', $port, $ep );
            }
        }
        push @l, 'Events:       <none>';
    }
    elsif ( $kind eq 'roles' || $kind eq 'clusterroles' ) {
        my @rows = ( [ 'Resources', 'Non-Resource URLs', 'Resource Names', 'Verbs' ], [ '---------', '-----------------', '--------------', '-----' ] );
        for my $r ( @{ $x->{rules} || [] } ) {
            for my $res ( @{ $r->{resources} || [] } ) {
                push @rows, map { [ ( $_ eq '' ? $res : "$res.$_" ), '[]', '[' . join( ' ', @{ $r->{resourceNames} || [] } ) . ']', '[' . join( ' ', @{ $r->{verbs} || [] } ) . ']' ] } @{ $r->{apiGroups} || [''] };
            }
        }
        push @l, 'PolicyRule:', map {"  $_"} split /\n/, _cols(@rows);
    }
    elsif ( $kind eq 'rolebindings' || $kind eq 'clusterrolebindings' ) {
        my $rr = $x->{roleRef} || {};
        push @l, 'Role:', '  Kind:  ' . ( $rr->{kind} // '' ), '  Name:  ' . ( $rr->{name} // '' ), 'Subjects:',
            map {"  $_"} split /\n/, _cols( [qw( Kind Name Namespace )], [qw( ---- ---- --------- )], map { [ $_->{kind} // '', $_->{name} // '', $_->{namespace} // '' ] } @{ $x->{subjects} || [] } );
    }
    elsif ( $kind eq 'serviceaccounts' ) {
        push @l, 'Image pull secrets:  <none>', 'Mountable secrets:   <none>', 'Tokens:              <none>', 'Events:              <none>';
    }
    elsif ( $kind eq 'certificates' ) {
        my $st = _cert_state( $k, $ns, $name, $x );
        my $ir = $s->{issuerRef} || {};
        push @l, 'API Version:  cert-manager.io/v1', 'Kind:         Certificate', 'Spec:', '  Dns Names:', ( map {"    $_"} @{ $s->{dnsNames} || [] } ),
            '  Issuer Ref:', '    Group:  ' . ( $ir->{group} // 'cert-manager.io' ), '    Kind:   ' . ( $ir->{kind} // 'Issuer' ), '    Name:   ' . ( $ir->{name} // '' ),
            '  Secret Name:  ' . ( $s->{secretName} // '' ), 'Status:', '  Conditions:', '    Type:     Ready', '    Status:   ' . _cond_text( $st->{ready} ), "    Reason:   $st->{reason}", "    Message:  $st->{message}",
            ( $st->{ready} ? ( 'Events:', '  Type    Reason     Age   From                                       Message', '  ----    ------     ----  ----                                       -------',
                    "  Normal  Issuing    3d    cert-manager-certificates-issuing          The certificate has been successfully issued" )
                : ( 'Events:', '  Type    Reason     Age   From                                       Message', '  ----    ------     ----  ----                                       -------',
                    "  Normal  Requested  12m   cert-manager-certificates-request-manager  Created new CertificateRequest resource \"$name-1\"" ) );
    }
    elsif ( $kind eq 'issuers' || $kind eq 'clusterissuers' ) {
        my ( $ok, $reason, $msg ) = _issuer_state( $k, $x, $kind eq 'issuers' ? $ns : _cm_ns($k) );
        my $spec = do { local $YAML::XS::Boolean = q{JSON::PP}; YAML::XS::Dump($s) } =~ s/\A---\n//r;
        push @l, "API Version:  cert-manager.io/v1", "Kind:         $GEN{$kind}[1]", 'Spec:', ( map {"  $_"} split /\n/, $spec ),
            'Status:', '  Conditions:', '    Type:     Ready', '    Status:   ' . _cond_text($ok), "    Reason:   $reason", "    Message:  $msg", 'Events:  <none>';
    }
    elsif ( $kind eq 'ingressclasses' ) {
        push @l, 'Controller:   ' . ( $s->{controller} // '' ), 'Events:       <none>';
    }
    return ( join( "\n", @l ), 1 );
}

# --- kubectl create fuer RBAC und TLS ---------------------------------------------

sub _create_more {
    my ( $k, $a, $o, $dev ) = @_;
    my ( $what, $name ) = @$a;
    my $f = $o->{f} || {};
    my $ns = $o->{ns};
    my $split = sub { map { split /,/ } @{ $f->{ $_[0] } || [] } };
    if ( $what =~ /\A(?:serviceaccount|sa)\z/ ) {
        return ( 'error: exactly one NAME is required, got 0', 0 ) unless defined $name;
        return ( qq{error: failed to create serviceaccount: serviceaccounts "$name" already exists}, 0 ) if $name eq 'default' || $k->{namespaces}{$ns}{serviceaccounts}{$name};
        $k->{namespaces}{$ns}{serviceaccounts}{$name} = {};
        return ( "serviceaccount/$name created", 1 );
    }
    if ( $what eq 'role' || $what eq 'clusterrole' ) {
        my $kind = $what eq 'role' ? 'roles' : 'clusterroles';
        return ( 'error: exactly one NAME is required, got 0', 0 ) unless defined $name;
        my @verbs = $split->('verb');
        return ( 'error: at least one verb must be specified', 0 ) unless @verbs;
        my @res = $split->('resource');
        return ( 'error: at least one resource must be specified', 0 ) unless @res;
        my %g;
        my @order;
        for my $r (@res) {
            my ( $p, $grp ) = _resource($r);
            return ( qq{error: the server doesn't have a resource type "$r"}, 0 ) unless defined $p;
            push @order, $grp unless $g{$grp};
            push @{ $g{$grp} }, $p;
        }
        my @rn = $split->('resource-name');
        my $t = _target( $k, $o, $kind );
        return ( qq{error: failed to create $what: $kind "$name" already exists}, 0 ) if $t->{$name};
        $t->{$name} = { rules => [ map { { apiGroups => [$_], resources => $g{$_}, verbs => [@verbs], ( @rn ? ( resourceNames => [@rn] ) : () ) } } @order ] };
        return ( "$GEN{$kind}[3]/$name created", 1 );
    }
    if ( $what eq 'rolebinding' || $what eq 'clusterrolebinding' ) {
        my $kind = "${what}s";
        return ( 'error: exactly one NAME is required, got 0', 0 ) unless defined $name;
        my ($role) = @{ $f->{role} || [] };
        my ($cr) = @{ $f->{clusterrole} || [] };
        return ( 'error: exactly one of clusterrole or role must be specified', 0 ) unless defined $role xor defined $cr;
        return ( 'error: unknown flag: --role', 0 ) if $what eq 'clusterrolebinding' && defined $role;
        my @subj;
        for my $s ( @{ $f->{serviceaccount} || [] } ) {
            my ( $sns, $sn ) = split /:/, $s, 2;
            return ( "error: serviceaccount must be <namespace>:<name>", 0 ) unless defined $sn && length $sns && length $sn;
            push @subj, { kind => 'ServiceAccount', name => $sn, namespace => $sns };
        }
        push @subj, map { { kind => 'User', apiGroup => 'rbac.authorization.k8s.io', name => $_ } } @{ $f->{user} || [] };
        push @subj, map { { kind => 'Group', apiGroup => 'rbac.authorization.k8s.io', name => $_ } } @{ $f->{group} || [] };
        my $t = _target( $k, $o, $kind );
        return ( qq{error: failed to create $what: $kind "$name" already exists}, 0 ) if $t->{$name};
        $t->{$name} = { roleRef => { apiGroup => 'rbac.authorization.k8s.io', kind => defined $role ? 'Role' : 'ClusterRole', name => $role // $cr }, ( @subj ? ( subjects => \@subj ) : () ) };
        return ( "$GEN{$kind}[3]/$name created", 1 );
    }
    if ( $what eq 'secret' && ( $name // '' ) eq 'tls' ) {
        my $sn = $a->[2] // return ( 'error: exactly one NAME is required, got 0', 0 );
        my ($cert) = @{ $f->{cert} || [] };
        my ($key)  = @{ $f->{key} || [] };
        return ( 'error: load key pair: open : no such file or directory', 0 ) unless defined $cert && defined $key;
        my %t;
        for ( [ 'tls.crt', $cert ], [ 'tls.key', $key ] ) {
            my $fe = ( $dev->{files} || {} )->{ $_->[1] };
            $fe = $fe->{content} if ref $fe eq 'HASH';
            return ( "error: open $_->[1]: no such file or directory", 0 ) unless defined $fe;
            $t{ $_->[0] } = $fe;
        }
        return ( qq{error: failed to create secret secrets "$sn" already exists}, 0 ) if $k->{namespaces}{$ns}{secrets}{$sn};
        $k->{namespaces}{$ns}{secrets}{$sn} = \%t;
        return ( "secret/$sn created", 1 );
    }
    return;
}
sub _v_edit    { push @GAPS, 'kubectl edit'; return ( 'error: Edit cancelled, no valid changes were saved.', 0 ) }
sub _v_explain { push @GAPS, 'kubectl explain'; return ( '', 0 ) }
sub _v_top     { return ( 'error: Metrics API not available', 0 ) }

# ReplicaSets der Deployments (das aktuelle je Deployment)
sub _replicasets {
    my ( $k, $ns ) = @_;
    my $o = $k->{namespaces}{$ns} or return ();
    my @p = _pods( $k, $ns );
    my @r;
    for my $d ( sort keys %{ $o->{deployments} || {} } ) {
        my $dep = $o->{deployments}{$d};
        my $h = _hash( [ $dep->{template}, $dep->{restarted_at} // '' ] );
        my @dp = grep { $_->{deployment} eq $d } @p;
        my $sa = $dep->{template}{service_account};
        push @r, { name => "$d-$h", deployment => $d, desired => $dep->{replicas} // 1, current => scalar @dp, ready => scalar( grep { $_->{ready} } @dp ),
            ( _sa_exists( $k, $ns, $sa ) ? () : ( failed => qq{Error creating: pods "$d-$h-" is forbidden: error looking up service account $ns/$sa: serviceaccount "$sa" not found} ) ) };
    }
    return @r;
}

sub _v_api_versions {
    return ( join( "\n", qw( acme.cert-manager.io/v1 admissionregistration.k8s.io/v1 apiextensions.k8s.io/v1 apps/v1 authorization.k8s.io/v1 autoscaling/v2 batch/v1
        cert-manager.io/v1 coordination.k8s.io/v1 discovery.k8s.io/v1 events.k8s.io/v1 networking.k8s.io/v1 node.k8s.io/v1 policy/v1 rbac.authorization.k8s.io/v1
        scheduling.k8s.io/v1 storage.k8s.io/v1 v1 ) ), 1 );
}

sub _v_api_resources {
    my @r = ( [qw( NAME SHORTNAMES APIVERSION NAMESPACED KIND )] );
    my %short = ( pods => 'po', services => 'svc', deployments => 'deploy', ingresses => 'ing', serviceaccounts => 'sa', certificates => 'cert,certs', persistentvolumeclaims => 'pvc',
        networkpolicies => 'netpol', replicasets => 'rs', configmaps => 'cm', namespaces => 'ns', nodes => 'no', storageclasses => 'sc', certificaterequests => 'cr,crs', events => 'ev' );
    my %kind = ( %APIKIND, pods => 'Pod', replicasets => 'ReplicaSet', endpoints => 'Endpoints', nodes => 'Node', events => 'Event', certificaterequests => 'CertificateRequest', orders => 'Order', challenges => 'Challenge' );
    for my $int ( sort keys %kind ) {
        my $p = $API_PLURAL{$int} // $int;
        my $g = $GROUP{$p} // '';
        push @r, [ $p, $short{$p} // '', ( $g eq '' ? 'v1' : "$g/v1" ), ( $CLUSTER{$int} ? 'false' : 'true' ), $kind{$int} ];
    }
    return ( _cols(@r), 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Kubernetes - Kubernetes cluster behind kubectl on a simulated Linux server — stored resources, derived status

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator: kubectl on a device with kubernetes state
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Kubernetes::kubectl( $dev, \@argv, $ctx, $stdin );

=head1 DESCRIPTION

A Kubernetes cluster (v1.30) as state of a Linux device (the device is the
admin host with C<kubectl>, cai-platform F<docs/entwurf-evals.md> §3.3.1). The
state is under C<kubernetes>:

  kubernetes:
    context: prod
    registry: [ registry.example.com/shop/api:1.4.2, … ]   # images available
    nodes: { node1: { ready: true } }
    storageclasses: { local-path: { provisioner: rancher.io/local-path, default: true } }
    namespaces:
      shop:
        deployments:
          api:
            replicas: 2
            generation: 3                 # counts every change of the template (rollout)
            selector: { app: api }
            template:
              labels: { app: api }
              containers:
                - name: api
                  image: registry.example.com/shop/api:1.4.2
                  ports: [8080]
                  listens: [8080]          # where the process really listens (simulation only)
                  needs_env: [DB_PASSWORD] # without these variables it crashes (simulation only)
                  env: [ { name: DB_PASSWORD, secret: api-db, key: password, optional: true } ]
                  readiness: { port: 8080, path: /healthz }
                  volumes: [ { claim: data } ]
                  privileged: false
                  logs: [ "…" ]            # what the process writes when it starts
                  crash_log: [ "…" ]       # what it writes when its environment is missing
        services: { api: { selector: { app: api }, ports: [ { port: 80, target: 8080 } ] } }
        secrets: { api-db: { password: "…" } }       # key -> value
        configmaps: { … }
        pvcs: { data: { storage_class: fast, size: 10Gi } }
        networkpolicies:
          deny-all: { pod_selector: {}, ingress: [] }
          allow-web: { pod_selector: { app: api }, ingress: [ { from: [ { app: web } ], ports: [8080] } ] }

B<Derived, not stored>: pods (name from the deployment and a hash of the
template), their status (C<ImagePullBackOff> when the image is not in
C<registry>; C<CreateContainerConfigError> when a non-optional secret key is
missing; C<CrashLoopBackOff> when a C<needs_env> variable is missing;
C<Pending> when a PVC is not bound; C<Running> 0/1 when the readiness probe
targets a port nothing listens on), PVC status (C<Bound> when the
StorageClass exists, or, without one given, a default class is there),
endpoints of a service (ready pods whose labels match) and reachability
(C<kubectl exec POD -- curl|wget URL> checks service, endpoints, target port
and NetworkPolicies). Only what C<kubectl> changes is B<stored> — the rules
check the cause in the state.

B<Commands>: C<get> (kinds and short names, C<-n>, C<-A>, C<-l>, C<-o
wide|yaml|json|name>, C<--show-labels>), C<describe>, C<logs [--previous]>,
C<get events>, C<apply -f file> (YAML, several documents), C<create -f>,
C<create secret generic … --from-literal>, C<create storageclass> by file,
C<set image>, C<set env> (C<-c|--containers NAME[,…]>, without: all containers;
C<--from=secret/NAME [--keys=a,b] [--prefix=P]> as C<secretKeyRef>, name upper case
with C<_>; C<NAME-> removes; C<--list> only reads), C<patch … -p JSON [--type merge|strategic|json]>,
C<scale>, C<label>, C<rollout restart|status|undo>, C<delete>, C<exec … --
curl|wget>, C<config current-context>, C<cluster-info>, C<version>. Anything
interactive (C<edit>, C<exec -it … sh>, C<port-forward>) and anything else is
a B<gap of the simulation>. A deployment's C<generation> counts every change
of the template; C<kubectl rollout restart> counts as well.

B<Further kinds in API form> (stored without apiVersion, kind, name,
namespace and status; rules check the API's fields): C<ingresses>,
C<ingressclasses>, C<serviceaccounts>, C<roles>, C<rolebindings>,
C<clusterroles>, C<clusterrolebindings>, C<certificates>, C<issuers>,
C<clusterissuers>; derived and read only: C<certificaterequests>,
C<orders>, C<challenges>. Also in the state: C<ingress: { controller, address }>
(the cluster's controller), C<dns: { host: ip }> (public names),
C<cert_manager: { namespace, acme_servers }>.

B<Ingress>: the controller serves only ingresses of an IngressClass with its
C<spec.controller> (class from C<ingressClassName>, the deprecated annotation
or the default class); paths C<Exact>, C<Prefix> (element-wise),
C<ImplementationSpecific> (character prefix); backend through the service port
as number or name; TLS from the host's secret, otherwise a fake certificate;
http with TLS redirects (308). C<kubectl exec … -- curl|wget> to a public name
goes through the ingress (C<-k>, C<-L>, C<-I>, C<-f>, C<-w>, C<-H Host:>).
Containers with C<derive_logs: ingress-nginx|cert-manager> have the
controller's log from the state.

B<cert-manager>: a Certificate is ready when its issuer is there and ready
(CA secret in the issuer's namespace, or for a ClusterIssuer in
C<cert_manager.namespace>, a known ACME server, HTTP-01 through a served
class and a name from C<dns>, DNS-01 with an existing secret); then its
secret exists (pseudo-PEM with names and issuer). Ingress annotations
C<cert-manager.io/cluster-issuer|issuer> create Certificates (ingress-shim).

B<RBAC>: C<kubectl auth can-i> (C<--as>, C<--as-group>, C<--list>) over
Roles, ClusterRoles (built in: cluster-admin, admin, edit, view) and
bindings (ServiceAccount with namespace, without: the binding's; groups;
C<resourceNames>; subresources such as C<pods/log>); C<kubectl create
serviceaccount|role|clusterrole|rolebinding|clusterrolebinding|secret tls>;
C<roleRef> is immutable. A container with C<needs_rbac> crashes when its
ServiceAccount lacks a permission; when the ServiceAccount is missing, there
are no pods (event FailedCreate).

Pure functions on the state, neutral.

=head2 kubectl

  my ( $out, $ok ) = kubectl( $dev, \@argv, $ctx, $stdin );

=head2 pod_tool

  my ( $out, $ok ) = pod_tool( $k, $ns, $pod, [ 'curl', '-s', 'http://api' ] );

curl, wget or openssl s_client from a pod: service, endpoints, NetworkPolicies,
ingress controller (for public names).

=head2 tls_probe

  my ( $text, $ok ) = tls_probe( $k, $host, $servername );

What C<openssl s_client -connect host:443 -servername …> sees from the
cluster's ingress controller: certificate (pseudo-PEM), subject, issuer, verification result.

=head2 x509

  my ( $text, $ok ) = x509( $pem, \@options );

C<openssl x509 -noout -subject|-issuer|-dates|-enddate|-ext subjectAltName|-text>
on a pseudo-PEM of the simulation.

=head2 jsonpath

  my ( $text, $err ) = jsonpath( $data, '{range .items[*]}{.metadata.name}{"\n"}{end}' );

Subset of kubectl JSONPath: text and C<{expression}>; expressions C<.a.b>,
C<.data.tls\.crt>, C<['a.b']>, C<[n]>, C<[*]>, C<[?(@.f=="v")]> (also C<!=>),
C<..name> (recursive), literals C<{"\n"}>, C<{range …}…{end}>. Several
matches are joined with spaces; lists and objects as JSON.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
