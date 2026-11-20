package Langertha::Holmgang::Sim::Linux::Helm;
# ABSTRACT: helm on the admin host of a simulated cluster — releases, values, revisions, rendering

use strict;
use warnings;
use utf8;

use Encode ();
use IO::Compress::Gzip ();
use JSON::MaybeXS ();
use MIME::Base64 ();
use YAML::XS ();

our $VERSION = '0.002';


our @GAPS;

my $K = 'Langertha::Holmgang::Sim::Linux::Kubernetes';
my $J = JSON::MaybeXS->new( canonical => 1 );
my $T = JSON::MaybeXS::true();
my $F = JSON::MaybeXS::false();

sub _clone { return $J->decode( $J->encode( $_[0] ) ) }

sub _dump {
    my ($d) = @_;
    my $y = Encode::decode( 'UTF-8', do { local $YAML::XS::Boolean = q{JSON::PP}; YAML::XS::Dump($d) } );
    $y =~ s/\A---\s*//;
    return $y =~ s/\s+\z//r;
}

# --- Werte -----------------------------------------------------------------------------

sub _merge {
    my ( $a, $b ) = @_;
    return _clone($b) unless ref $a eq 'HASH' && ref $b eq 'HASH';
    my %r = %{ _clone($a) };
    for my $k ( keys %$b ) {
        if ( !defined $b->{$k} ) { delete $r{$k}; next }
        $r{$k} = ref $b->{$k} eq 'HASH' && ref $r{$k} eq 'HASH' ? _merge( $r{$k}, $b->{$k} ) : _clone( [ $b->{$k} ] )->[0];
    }
    return \%r;
}

sub _typed {
    my ( $v, $string ) = @_;
    return $v if $string;
    return undef if $v eq 'null';
    return $T if $v eq 'true';
    return $F if $v eq 'false';
    return 0 + $v if $v =~ /\A-?(?:0|[1-9]\d*)\z/;
    return $v;
}

# --set a.b=c,d[0]=e -> Hash
sub _parse_set {
    my ( $spec, $string, $into ) = @_;
    $into ||= {};
    my @parts;
    my $cur = '';
    while ( $spec =~ /\G(\\.|[^,\\]+|,)/gcs ) { my $t = $1; if ( $t eq ',' ) { push @parts, $cur; $cur = '' } else { $cur .= $t =~ /\A\\(.)\z/s ? $1 : $t } }
    push @parts, $cur;
    for my $p ( grep { length } @parts ) {
        my ( $key, $val ) = $p =~ /\A([^=]+)=(.*)\z/s or die "failed parsing --set data: key \"$p\" has no value\n";
        my @seg = map { /\A(.+?)\[(\d+)\]\z/ ? ( $1, [$2] ) : ($_) } split /\./, $key;
        my $t = $into;
        while ( @seg > 1 ) {
            my $s = shift @seg;
            my $next_is_idx = ref $seg[0];
            if ( ref $s ) { $t->[ $s->[0] ] //= $next_is_idx ? [] : {}; $t = $t->[ $s->[0] ] }
            else { $t->{$s} = ( $next_is_idx ? [] : {} ) unless ref $t->{$s}; $t = $t->{$s} }
        }
        my $last = $seg[0];
        if ( ref $last ) { $t->[ $last->[0] ] = _typed( $val, $string ) }
        else { $t->{$last} = _typed( $val, $string ) }
    }
    return $into;
}

sub _val_at {
    my ( $v, $path ) = @_;
    for my $s ( grep { length } split /\./, $path ) {
        return undef unless ref $v eq 'HASH';
        $v = $v->{$s};
    }
    return $v;
}

sub _true { my ($v) = @_; return 0 unless defined $v; return 0 if ref $v eq 'HASH' && !%$v; return 0 if ref $v eq 'ARRAY' && !@$v; return $v && $v ne 'false' ? 1 : 0 }

# --- Rendern ---------------------------------------------------------------------------

sub _expr {
    my ( $e, $ctx ) = @_;
    $e =~ s/\A\s+|\s+\z//g;
    my ( $main, @pipes ) = split /\s*\|\s*/, $e;
    my $v = _atom( $main, $ctx );
    for my $p (@pipes) {
        if ( $p =~ /\Adefault\s+(.+)\z/ ) { $v = _atom( $1, $ctx ) unless _true($v) || ( defined $v && !ref $v && length $v && $v ne '0' ) }
        elsif ( $p eq 'quote' ) { $v = defined $v ? "$v" : '' }
    }
    return $v;
}

sub _atom {
    my ( $a, $ctx ) = @_;
    return $1 if $a =~ /\A"(.*)"\z/s;
    return 0 + $a if $a =~ /\A-?\d+\z/;
    return _val_at( $ctx->{values}, $1 ) if $a =~ /\A\.Values((?:\.[A-Za-z0-9_-]+)*)\z/;
    return $ctx->{release} if $a eq '.Release.Name';
    return $ctx->{ns}      if $a eq '.Release.Namespace';
    return $ctx->{version} if $a eq '.Chart.Version';
    return $ctx->{app}     if $a eq '.Chart.AppVersion';
    return undef;
}

sub _render {
    my ( $t, $ctx ) = @_;
    if ( ref $t eq 'HASH' ) {
        my %r;
        for my $k ( keys %$t ) {
            next if $k eq '_if';
            my $v = _render( $t->{$k}, $ctx );
            $r{$k} = $v if defined $v;
        }
        return \%r;
    }
    if ( ref $t eq 'ARRAY' ) {
        return [ map { _render( $_, $ctx ) } grep { !( ref $_ eq 'HASH' && defined $_->{_if} && !_true( _val_at( $ctx->{values}, $_->{_if} ) ) ) } @$t ];
    }
    return $t unless defined $t && !ref $t;
    return _expr( $1, $ctx ) if $t =~ /\A\{\{((?:(?!\}\}).)*)\}\}\z/s;
    ( my $s = $t ) =~ s/\{\{(.*?)\}\}/my $v = _expr( $1, $ctx ); defined $v && !ref $v ? $v : ''/ges;
    return $s;
}

# Ressourcen eines Charts fuer Werte: ( [ kind, name, obj ] … )
sub _resources {
    my ( $chart, $ver, $vals, $rel, $ns ) = @_;
    my $ctx = { values => $vals, release => $rel, ns => $ns, version => $ver, app => $chart->{app_version} };
    my @r;
    for my $t ( @{ $chart->{resources} || [] } ) {
        next if defined $t->{if} && !_true( _val_at( $vals, $t->{if} ) );
        push @r, [ $t->{kind}, _render( $t->{name}, $ctx ), _render( $t->{obj} // {}, $ctx ) ];
    }
    return @r;
}

# Rendert in den Cluster; stirbt mit der Meldung von Helm
sub _apply_release {
    my ( $k, $ns, $rel, $chartref, $ver, $user, $old_manifest ) = @_;
    my $chart = _chart_version( $k, $chartref, $ver ) or die qq{chart "$chartref" version "$ver" not found\n};
    my $vals = _merge( $chart->{values} || {}, $user || {} );
    my @res = _resources( $chart, $ver, $vals, $rel, $ns );
    my %now;
    for my $r (@res) {
        my ( $kind, $name, $obj ) = @$r;
        $now{"$kind/$name"} = 1;
        eval { $K->can('_store')->( $k, $kind, $ns, $name, $obj ); 1 }
            or die 'cannot patch "' . $name . '" with kind ' . ( $Langertha::Holmgang::Sim::Linux::Kubernetes::SINGULAR{$kind} // $kind ) . ': ' . ( $@ =~ s/\s+\z//r ) . "\n";
    }
    for my $m ( @{ $old_manifest || [] } ) {
        next if $now{$m};
        my ( $kind, $name ) = split m{/}, $m, 2;
        my $t = $Langertha::Holmgang::Sim::Linux::Kubernetes::CLUSTER{$kind} ? $k->{$kind} : ( $k->{namespaces}{$ns} || {} )->{$kind};
        delete $t->{$name} if $t;
    }
    return ( [ map {"$_->[0]/$_->[1]"} @res ], $chart, [ map { $_->[1] } grep { $_->[0] eq 'deployments' } @res ] );
}

sub _all_ready {
    my ( $k, $ns, $deps ) = @_;
    my @p = $K->can('_pods')->( $k, $ns );
    for my $d (@$deps) {
        my @dp = grep { $_->{deployment} eq $d } @p;
        return 0 if !@dp || grep { !$_->{ready} } @dp;
    }
    return 1;
}

# --- Charts --------------------------------------------------------------------------

sub _vcmp {
    my ( $x, $y ) = @_;
    my @a = split /[.-]/, $x;
    my @b = split /[.-]/, $y;
    for ( 0 .. ( @a > @b ? $#a : $#b ) ) {
        my ( $p, $q ) = ( $a[$_] // 0, $b[$_] // 0 );
        my $c = $p =~ /\A\d+\z/ && $q =~ /\A\d+\z/ ? $p <=> $q : $p cmp $q;
        return $c if $c;
    }
    return 0;
}

# neueste Version zuerst (eigene Funktion: in den Befehlen ist $a das Argument-Array)
sub _desc { return sort { _vcmp( $b, $a ) } @_ }

sub _chart { my ( $k, $ref ) = @_; return ( ( $k->{helm} || {} )->{charts} || {} )->{ $ref // '' } }

sub _chart_version {
    my ( $k, $ref, $ver ) = @_;
    my $c = _chart( $k, $ref ) or return undef;
    return ( $c->{versions} || {} )->{$ver};
}

sub _latest {
    my ( $k, $ref ) = @_;
    my $c = _chart( $k, $ref ) or return undef;
    my ($v) = _desc( keys %{ $c->{versions} || {} } );
    return $v;
}

sub _short { my ($ref) = @_; return $ref =~ s{.*/}{}r }

# --- Releases ----------------------------------------------------------------------------

sub _rel { my ( $k, $ns, $n ) = @_; return ( ( ( $k->{helm} || {} )->{releases} || {} )->{$ns} || {} )->{ $n // '' } }

my @MON = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
sub _now { my ($k) = @_; my $n = ++$k->{helm}{_clock}; return sprintf '2026-10-24 09:%02d:%02d', 10 + int( $n / 60 ), $n % 60 }
sub _long { my ($u) = @_; my ( $y, $m, $d, $t ) = ( $u // '2026-10-23 14:02:11' ) =~ /\A(\d+)-(\d+)-(\d+) (\S+)/; return sprintf '%s %s %2d %s %s', 'Sat', $MON[ $m - 1 ], $d, $t, $y }

sub _app { my ( $k, $r ) = @_; my $c = _chart_version( $k, $r->{chart}, $r->{version} ) || {}; return $c->{app_version} // '' }

sub _status_text {
    my ( $k, $ns, $n, $r ) = @_;
    return join "\n", "NAME: $n", 'LAST DEPLOYED: ' . _long( $r->{updated} ), "NAMESPACE: $ns", "STATUS: $r->{status}", "REVISION: $r->{revision}", 'TEST SUITE: None';
}

# neue Revision: die alte wandert in die Historie
sub _push_revision {
    my ( $k, $ns, $n, $new ) = @_;
    my $old = _rel( $k, $ns, $n );
    my @hist;
    if ($old) {
        @hist = @{ delete $old->{history} || [] };
        my $manifest = delete $old->{manifest};
        my $chart = delete $old->{chart};
        $old->{status} = 'superseded' if $old->{status} eq 'deployed';
        push @hist, $old;
        $new->{chart} //= $chart;
    }
    $new->{history} = \@hist;
    $k->{helm}{releases}{$ns}{$n} = $new;
    return $new;
}


sub drop_revision {
    my ( $k, $ns, $n, $rev ) = @_;
    my $r = _rel( $k, $ns, $n ) or return 0;
    if ( $r->{revision} == $rev ) {
        my @hist = @{ $r->{history} || [] };
        my $prev = pop @hist;
        if ( !$prev ) { delete $k->{helm}{releases}{$ns}{$n}; return 1 }
        $k->{helm}{releases}{$ns}{$n} = { %$prev, chart => $r->{chart}, manifest => $r->{manifest}, history => \@hist };
        return 1;
    }
    my @h = grep { $_->{revision} != $rev } @{ $r->{history} || [] };
    return 0 if @h == @{ $r->{history} || [] };
    $r->{history} = \@h;
    return 1;
}


sub release_secrets {
    my ( $k, $ns ) = @_;
    my %s;
    my $rs = ( ( $k->{helm} || {} )->{releases} || {} )->{$ns} || {};
    for my $n ( keys %$rs ) {
        for my $r ( @{ $rs->{$n}{history} || [] }, $rs->{$n} ) {
            $s{"sh.helm.release.v1.$n.v$r->{revision}"} = { release => _payload( $k, $n, $ns, $rs->{$n}, $r ), _helm => 1, _status => $r->{status} };
        }
    }
    return %s;
}

# Inhalt des Release-Secrets wie Helm 3: JSON der Revision, gzip, base64 (kubectl zeigt es nochmals base64)
sub _payload {
    my ( $k, $n, $ns, $cur, $rev ) = @_;
    my $chart = _chart_version( $k, $cur->{chart}, $rev->{version} ) || {};
    my $rel = {
        name      => $n,
        namespace => $ns,
        version   => 0 + $rev->{revision},
        info      => { status => $rev->{status}, description => $rev->{description} // '', last_deployed => _long( $rev->{updated} ) },
        chart     => { metadata => { name => _short( $cur->{chart} ), version => $rev->{version}, appVersion => $chart->{app_version} // '' }, values => $chart->{values} || {} },
        config    => $rev->{values} || {},
        manifest  => _manifest( $k, $n, $ns, $cur, $rev ),
    };
    my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 )->encode($rel);
    IO::Compress::Gzip::gzip( \$json => \my $gz, Time => 0, Minimal => 1 );
    return MIME::Base64::encode_base64( $gz, '' );
}

# Manifest einer Revision: aus Chart und Werten dieser Revision gerendert
sub _manifest {
    my ( $k, $n, $ns, $r, $rev ) = @_;
    my $chart = _chart_version( $k, $r->{chart}, $rev->{version} ) or return '';
    my @out;
    for my $x ( _resources( $chart, $rev->{version}, _merge( $chart->{values} || {}, $rev->{values} || {} ), $n, $ns ) ) {
        my ( $kind, $name, $obj ) = @$x;
        ( my $file = $Langertha::Holmgang::Sim::Linux::Kubernetes::SINGULAR{$kind} // $kind ) =~ s/\..*//;
        my $api = $K->can('_api_obj')->( $kind, $name, $obj, $ns );
        delete $api->{metadata}{generation};
        push @out, "---\n# Source: " . _short( $r->{chart} ) . "/templates/$file.yaml\n" . _dump($api);
    }
    return join "\n", @out;
}

# --- Kommandozeile -------------------------------------------------------------------------


sub helm {
    my ( $dev, $av, $ctx ) = @_;
    my $k = $dev->{kubernetes} or return ( 'Error: Kubernetes cluster unreachable: Get "http://localhost:8080/version": dial tcp [::1]:8080: connect: connection refused', 0 );
    Langertha::Holmgang::Sim::Linux::_part(q{Kubernetes});    # helm drives the cluster part
    my %o = ( ns => $k->{default_namespace} // 'default', f => [], set => [] );
    my @a;
    my @in = @$av;
    my %val = map { $_ => 1 } qw( version revision max timeout description output o );
    while (@in) {
        my $x = shift @in;
        if    ( $x eq '-n' || $x eq '--namespace' ) { $o{ns} = shift @in }
        elsif ( $x =~ /\A(?:-n|--namespace=)(.+)\z/ ) { $o{ns} = $1 }
        elsif ( $x eq '-A' || $x eq '--all-namespaces' ) { $o{all_ns} = 1 }
        elsif ( $x eq '-a' || $x eq '--all' ) { $o{all} = 1 }
        elsif ( $x eq '-f' || $x eq '--values' ) { push @{ $o{f} }, shift @in }
        elsif ( $x =~ /\A--values=(.+)\z/ ) { push @{ $o{f} }, $1 }
        elsif ( $x eq '--set' || $x eq '--set-string' ) { push @{ $o{set} }, [ shift(@in) // '', $x eq '--set-string' ] }
        elsif ( $x =~ /\A--set(-string)?=(.*)\z/s ) { push @{ $o{set} }, [ $2, $1 ? 1 : 0 ] }
        elsif ( $x =~ /\A--(version|revision|max|timeout|description|output)=(.*)\z/ ) { $o{$1} = $2 }
        elsif ( $x =~ /\A--(version|revision|max|timeout|description|output)\z/ ) { $o{$1} = shift @in }
        elsif ( $x eq '-o' ) { $o{output} = shift @in }
        elsif ( $x =~ /\A--(install|reuse-values|reset-values|reset-then-reuse-values|atomic|wait|dry-run|create-namespace|force|keep-history|pending|failed|deployed|debug|cleanup-on-fail|wait-for-jobs|versions|no-hooks|short)\z/ ) { $o{$1} = 1 }
        elsif ( $x eq '-i' ) { $o{install} = 1 }
        elsif ( $x eq '-q' ) { $o{short} = 1 }
        elsif ( $x eq '-l' ) { $o{versions} = 1 }
        elsif ( $x =~ /\A--kube-context(?:=.*)?\z/ ) { shift @in if $x eq '--kube-context' }
        elsif ( $x =~ /\A-/ ) { return ( qq{Error: unknown flag: $x}, 0 ) }
        else { push @a, $x }
    }
    my $verb = shift(@a) // return ( "The Kubernetes package manager\n\nUsage:\n  helm [command]", 1 );
    $verb = { ls => 'list', hist => 'history', un => 'uninstall', delete => 'uninstall', del => 'uninstall' }->{$verb} // $verb;
    return ( qq{Error: unknown command "$verb" for "helm"\nRun 'helm --help' for usage.}, 0 ) if $verb =~ /\A(?:diff|secrets|unittest|mapkubeapis)\z/;
    ( my $sub = "_h_$verb" ) =~ s/-/_/g;
    my $f = $verb =~ /\A[a-z]+\z/ && __PACKAGE__->can($sub) or do {
        return ( qq{Error: unknown command "$verb" for "helm"\nRun 'helm --help' for usage.}, 0 ) unless $verb =~ /\A(?:template|lint|pull|push|package|dependency|plugin|test|env|registry|create|verify|completion|get)\z/;
        push @GAPS, "helm $verb";
        return ( '', 0 );
    };
    my $copy = _clone($k);
    my ( $out, $ok, $keep ) = $f->( $copy, \@a, \%o, $dev );
    $dev->{kubernetes} = $copy if $ok || $keep;
    return ( $out, $ok );
}

sub _h_env {
    return ( join( "\n", 'HELM_BIN="helm"', 'HELM_CACHE_HOME="/root/.cache/helm"', 'HELM_CONFIG_HOME="/root/.config/helm"', 'HELM_DATA_HOME="/root/.local/share/helm"',
        'HELM_DRIVER="secret"', 'HELM_KUBECONTEXT=""', 'HELM_MAX_HISTORY="10"', 'HELM_NAMESPACE="default"', 'HELM_REGISTRY_CONFIG="/root/.config/helm/registry/config.json"',
        'HELM_REPOSITORY_CACHE="/root/.cache/helm/repository"', 'HELM_REPOSITORY_CONFIG="/root/.config/helm/repositories.yaml"' ), 1 );
}

sub _h_version { return ( 'version.BuildInfo{Version:"v3.15.4", GitCommit:"fa9efb07d9d8debbb4306d72af76a383895aa8c4", GitTreeState:"clean", GoVersion:"go1.22.6"}', 1 ) }

sub _h_list {
    my ( $k, $a, $o ) = @_;
    my $rs = ( $k->{helm} || {} )->{releases} || {};
    my @rows;
    for my $ns ( $o->{all_ns} ? sort keys %$rs : ( $o->{ns} ) ) {
        for my $n ( sort keys %{ $rs->{$ns} || {} } ) {
            my $r = $rs->{$ns}{$n};
            my $st = $r->{status};
            my $show = $o->{all} ? 1
                : ( $o->{pending} || $o->{failed} || $o->{deployed} ) ? ( $o->{pending} && $st =~ /\Apending/ || $o->{failed} && $st eq 'failed' || $o->{deployed} && $st eq 'deployed' )
                : $st eq 'deployed' || $st eq 'failed';
            next unless $show;
            push @rows, [ $n, $ns, $r->{revision}, "$r->{updated}.482913 +0200 CEST", $st, _short( $r->{chart} ) . "-$r->{version}", _app( $k, $r ) ];
        }
    }
    return ( join( "\n", map { $_->[0] } @rows ), 1 ) if $o->{short};
    return ( Langertha::Holmgang::Sim::Linux::Kubernetes::_cols( [qw( NAME NAMESPACE REVISION UPDATED STATUS CHART ), 'APP VERSION'], @rows ), 1 );
}

sub _need_rel {
    my ( $k, $a, $o ) = @_;
    my $n = $a->[0] // die "Error: \"helm\" requires 1 argument\n";
    my $r = _rel( $k, $o->{ns}, $n ) or die "Error: release: not found\n";
    return ( $n, $r );
}

sub _h_status {
    my ( $k, $a, $o ) = @_;
    my ( $n, $r ) = eval { _need_rel( $k, $a, $o ) } or return ( $@ =~ s/\s+\z//r, 0 );
    return ( _status_text( $k, $o->{ns}, $n, $r ), 1 );
}

sub _h_history {
    my ( $k, $a, $o ) = @_;
    my ( $n, $r ) = eval { _need_rel( $k, $a, $o ) } or return ( $@ =~ s/\s+\z//r, 0 );
    my @all = ( @{ $r->{history} || [] }, $r );
    @all = @all[ -$o->{max} .. -1 ] if $o->{max} && $o->{max} =~ /\A\d+\z/ && $o->{max} < @all;
    return ( Langertha::Holmgang::Sim::Linux::Kubernetes::_cols( [qw( REVISION UPDATED STATUS CHART ), 'APP VERSION', 'DESCRIPTION'],
        map { [ $_->{revision}, _long( $_->{updated} ), $_->{status}, _short( $r->{chart} ) . "-$_->{version}", ( _chart_version( $k, $r->{chart}, $_->{version} ) || {} )->{app_version} // '', $_->{description} // '' ] } @all ), 1 );
}

sub _h_get {
    my ( $k, $a, $o ) = @_;
    my $what = shift @$a // return ( "Error: \"helm get\" requires a subcommand", 0 );
    my ( $n, $r ) = eval { _need_rel( $k, $a, $o ) } or return ( $@ =~ s/\s+\z//r, 0 );
    my $rev = $r;
    if ( defined $o->{revision} ) {
        ($rev) = grep { $_->{revision} == $o->{revision} } @{ $r->{history} || [] }, $r;
        return ( 'Error: release: not found', 0 ) unless $rev;
    }
    if ( $what eq 'values' ) {
        my $v = $o->{all} ? _merge( ( _chart_version( $k, $r->{chart}, $rev->{version} ) || {} )->{values} || {}, $rev->{values} || {} ) : $rev->{values} || {};
        return ( $J->encode($v), 1 ) if ( $o->{output} // '' ) eq 'json';    # Helm schreibt kompakt
        return ( _dump($v) || 'null', 1 ) if ( $o->{output} // '' ) eq 'yaml';
        return ( ( $o->{all} ? 'COMPUTED VALUES:' : 'USER-SUPPLIED VALUES:' ) . "\n" . ( %$v ? _dump($v) : 'null' ), 1 );
    }
    return ( _manifest( $k, $n, $o->{ns}, $r, $rev ), 1 ) if $what eq 'manifest';
    if ( $what eq 'notes' ) { return ( 'NOTES:', 1 ) }
    my $chart = _chart_version( $k, $r->{chart}, $rev->{version} ) || {};
    my @meta = ( "NAME: $n", 'LAST DEPLOYED: ' . _long( $rev->{updated} ), "NAMESPACE: $o->{ns}", "STATUS: $rev->{status}", "REVISION: $rev->{revision}",
        'CHART: ' . _short( $r->{chart} ), "VERSION: $rev->{version}", 'APP_VERSION: ' . ( $chart->{app_version} // '' ) );
    return ( join( "\n", @meta ), 1 ) if $what eq 'metadata';
    if ( $what eq 'all' ) {
        my $v = $rev->{values} || {};
        return ( join( "\n", @meta[ 0 .. 4 ], 'TEST SUITE: None', 'USER-SUPPLIED VALUES:', ( %$v ? _dump($v) : 'null' ), '', 'COMPUTED VALUES:',
            _dump( _merge( $chart->{values} || {}, $v ) ), '', 'HOOKS:', 'MANIFEST:', _manifest( $k, $n, $o->{ns}, $r, $rev ) ), 1 );
    }
    push @GAPS, "helm get $what";
    return ( '', 0 );
}

sub _new_values {
    my ( $dev, $o ) = @_;
    my $v = {};
    for my $f ( @{ $o->{f} } ) {
        my $t = ( $dev->{files} || {} )->{$f};
        $t = $t->{content} if ref $t eq 'HASH';
        die "Error: open $f: no such file or directory\n" unless defined $t;
        my $d = eval { YAML::XS::Load( Encode::encode( 'UTF-8', $t ) ) };
        die "Error: failed to parse $f: error converting YAML to JSON: yaml: " . ( ( $@ // '' ) =~ s/\n.*//sr ) . "\n" if $@;
        $v = _merge( $v, $d ) if ref $d eq 'HASH';
    }
    for my $s ( @{ $o->{set} } ) {
        my $add = eval { _parse_set( $s->[0], $s->[1] ) } or die 'Error: ' . $@;
        $v = _merge( $v, $add );
    }
    return $v;
}

sub _resolve_chart {
    my ( $k, $ref, $o ) = @_;
    my $c = _chart( $k, $ref ) or do {
        my ($repo) = $ref =~ m{\A([^/]+)/};
        die defined $repo && !( ( $k->{helm} || {} )->{repos} || {} )->{$repo}
            ? qq{Error: repo $repo not found\n} : qq{Error: path "$ref" not found\n};
    };
    my $ver = $o->{version} // _latest( $k, $ref );
    unless ( ( $c->{versions} || {} )->{$ver} ) {
        my ( $repo, $name ) = $ref =~ m{\A([^/]+)/(.+)\z};
        die qq{Error: chart "$name" matching $ver not found in $repo index. (try 'helm repo update'): no chart version found for $name-$ver\n};
    }
    return $ver;
}

sub _h_install {
    my ( $k, $a, $o, $dev ) = @_;
    my ( $n, $ref ) = @$a;
    return ( 'Error: INSTALLATION FAILED: must either provide a name or specify --generate-name', 0 ) unless defined $ref;
    return ( 'Error: INSTALLATION FAILED: cannot re-use a name that is still in use', 0 ) if _rel( $k, $o->{ns}, $n );
    return ( qq{Error: INSTALLATION FAILED: create: failed to create: namespaces "$o->{ns}" not found}, 0 ) unless $k->{namespaces}{ $o->{ns} } || $o->{'create-namespace'};
    $k->{namespaces}{ $o->{ns} } //= {};
    my $ver = eval { _resolve_chart( $k, $ref, $o ) } // return ( 'Error: INSTALLATION FAILED: ' . ( $@ =~ s/\AError: //r =~ s/\s+\z//r ), 0 );
    my $vals = eval { _new_values( $dev, $o ) } // return ( $@ =~ s/\s+\z//r, 0 );
    return _deploy( $k, $o, $n, $ref, $ver, $vals, [], 'Install complete', 'INSTALLATION FAILED' );
}

sub _deploy {
    my ( $k, $o, $n, $ref, $ver, $vals, $old_manifest, $desc, $failword, $prev ) = @_;
    my $ns = $o->{ns};
    if ( $o->{'dry-run'} ) {
        # auf einer Kopie: Fehler zeigen, nichts aendern
        my ( $m, $err ) = ( eval { [ _apply_release( _clone($k), $ns, $n, $ref, $ver, $vals, $old_manifest ) ] }, $@ );
        return ( "Error: $failword: " . ( $err =~ s/\s+\z//r ), 0 ) unless $m;
        my $vals_text = %$vals ? _dump($vals) : '{}';
        return ( "NAME: $n\nLAST DEPLOYED: Sat Oct 24 09:10:00 2026\nNAMESPACE: $ns\nSTATUS: pending-" . ( $failword =~ /INSTALL/ ? 'install' : 'upgrade' )
            . "\nREVISION: " . ( ( _rel( $k, $ns, $n ) || { revision => 0 } )->{revision} + 1 ) . "\nTEST SUITE: None\nUSER-SUPPLIED VALUES:\n$vals_text\n\nHOOKS:\nMANIFEST:\n"
            . join( "\n", map {"# Source: $_"} @{ $m->[0] } ), 1 );
    }
    my $rev = ( ( _rel( $k, $ns, $n ) || { revision => 0 } )->{revision} ) + 1;
    my $now = _now($k);
    my ( $res, $err ) = ( eval { [ _apply_release( $k, $ns, $n, $ref, $ver, $vals, $old_manifest ) ] }, $@ );
    if ( !$res ) {
        _push_revision( $k, $ns, $n, { chart => $ref, version => $ver, values => $vals, revision => $rev, status => 'failed', updated => $now,
            description => ( $failword =~ /INSTALL/ ? 'Release' : 'Upgrade' ) . qq{ "$n" failed: } . ( $err =~ s/\s+\z//r ), manifest => $old_manifest } );
        return ( "Error: $failword: " . ( $err =~ s/\s+\z//r ), 0, 1 );
    }
    my ( $manifest, undef, $deps ) = @$res;
    my $ready = _all_ready( $k, $ns, $deps );
    if ( ( $o->{wait} || $o->{atomic} ) && !$ready ) {
        _push_revision( $k, $ns, $n, { chart => $ref, version => $ver, values => $vals, revision => $rev, status => 'failed', updated => $now,
            description => qq{Upgrade "$n" failed: context deadline exceeded}, manifest => $manifest } );
        if ( $o->{atomic} && $prev ) {
            my $now2 = _now($k);
            _apply_release( $k, $ns, $n, $ref, $prev->{version}, $prev->{values}, $manifest );
            _push_revision( $k, $ns, $n, { chart => $ref, version => $prev->{version}, values => _clone( $prev->{values} || {} ), revision => $rev + 1, status => 'deployed',
                updated => $now2, description => "Rollback to $prev->{revision}", manifest => $manifest } );
            return ( "Error: $failword: release $n failed, and has been rolled back due to atomic being set: context deadline exceeded", 0, 1 );
        }
        return ( "Error: $failword: context deadline exceeded", 0, 1 );
    }
    _push_revision( $k, $ns, $n, { chart => $ref, version => $ver, values => $vals, revision => $rev, status => 'deployed', updated => $now,
        description => $o->{description} // $desc, manifest => $manifest } );
    my $r = _rel( $k, $ns, $n );
    return ( ( $failword =~ /INSTALL/ ? '' : qq{Release "$n" has been upgraded. Happy Helming!\n} ) . _status_text( $k, $ns, $n, $r ), 1 );
}

sub _h_upgrade {
    my ( $k, $a, $o, $dev ) = @_;
    my ( $n, $ref ) = @$a;
    return ( qq{Error: "helm upgrade" requires 2 arguments\n\nUsage:  helm upgrade [RELEASE] [CHART] [flags]}, 0 ) unless defined $ref;
    my $cur = _rel( $k, $o->{ns}, $n );
    if ( !$cur ) {
        return _h_install( $k, $a, $o, $dev ) if $o->{install};
        return ( qq{Error: UPGRADE FAILED: "$n" has no deployed releases}, 0 );
    }
    return ( 'Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress', 0 ) if $cur->{status} =~ /\Apending/;
    my $ver = eval { _resolve_chart( $k, $ref, $o ) } // return ( 'Error: UPGRADE FAILED: ' . ( $@ =~ s/\AError: //r =~ s/\s+\z//r ), 0 );
    my $new = eval { _new_values( $dev, $o ) } // return ( $@ =~ s/\s+\z//r, 0 );
    my $old = $cur->{values} || {};
    # wie pkg/action/upgrade.go reuseValues
    my $vals = $o->{'reset-values'} ? $new
        : $o->{'reuse-values'} || $o->{'reset-then-reuse-values'} ? _merge( $old, $new )
        : !%$new && %$old ? _clone($old)
        : $new;
    my ($last_ok) = grep { $_->{status} =~ /\A(?:deployed|superseded)\z/ } reverse( @{ $cur->{history} || [] } ), $cur;
    return _deploy( $k, $o, $n, $ref, $ver, $vals, $cur->{manifest} || [], 'Upgrade complete', 'UPGRADE FAILED', $cur->{status} eq 'deployed' ? $cur : $last_ok );
}

sub _h_rollback {
    my ( $k, $a, $o ) = @_;
    my ( $n, $to ) = @$a;
    my $cur = _rel( $k, $o->{ns}, $n // '' ) or return ( 'Error: release: not found', 0 );
    $to = $cur->{revision} - 1 if !defined $to || $to eq '0';
    return ( "Error: invalid revision number: $to", 0 ) unless $to =~ /\A\d+\z/;
    my ($t) = grep { $_->{revision} == $to } @{ $cur->{history} || [] };
    return ( "Error: release has no $to version", 0 ) unless $t;
    my $ref = $cur->{chart};
    my $now = _now($k);
    my ( $res, $err ) = ( eval { [ _apply_release( $k, $o->{ns}, $n, $ref, $t->{version}, $t->{values} || {}, $cur->{manifest} || [] ) ] }, $@ );
    return ( 'Error: ' . ( $err =~ s/\s+\z//r ), 0 ) unless $res;
    my $rev = $cur->{revision} + 1;
    $cur->{status} = 'superseded' if $cur->{status} =~ /\A(?:deployed|pending-.*)\z/;
    _push_revision( $k, $o->{ns}, $n, { chart => $ref, version => $t->{version}, values => _clone( $t->{values} || {} ), revision => $rev, status => 'deployed',
        updated => $now, description => "Rollback to $to", manifest => $res->[0] } );
    return ( 'Rollback was a success! Happy Helming!', 1 );
}

sub _h_uninstall {
    my ( $k, $a, $o ) = @_;
    my $out = '';
    for my $n (@$a) {
        my $cur = _rel( $k, $o->{ns}, $n ) or return ( "Error: uninstall: Release not loaded: $n: release: not found", 0 );
        for my $m ( @{ $cur->{manifest} || [] } ) {
            my ( $kind, $name ) = split m{/}, $m, 2;
            my $t = $Langertha::Holmgang::Sim::Linux::Kubernetes::CLUSTER{$kind} ? $k->{$kind} : ( $k->{namespaces}{ $o->{ns} } || {} )->{$kind};
            delete $t->{$name} if $t;
        }
        delete $k->{helm}{releases}{ $o->{ns} }{$n};
        $out .= qq{release "$n" uninstalled\n};
    }
    return ( $out =~ s/\n\z//r, 1 );
}

sub _h_repo {
    my ( $k, $a ) = @_;
    my $what = $a->[0] // '';
    my $r = ( $k->{helm} || {} )->{repos} || {};
    if ( $what eq 'list' || $what eq 'ls' ) {
        return ( 'Error: no repositories to show', 0 ) unless %$r;
        return ( Langertha::Holmgang::Sim::Linux::Kubernetes::_cols( [qw( NAME URL )], map { [ $_, $r->{$_} ] } sort keys %$r ), 1 );
    }
    if ( $what eq 'update' || $what eq 'up' ) {
        return ( join( "\n", 'Hang tight while we grab the latest from your chart repositories...',
            ( map {qq{...Successfully got an update from the "$_" chart repository}} sort keys %$r ), 'Update Complete. ⎈Happy Helming!⎈' ), 1 );
    }
    push @GAPS, "helm repo $what";
    return ( '', 0 );
}

sub _h_search {
    my ( $k, $a, $o ) = @_;
    my ( $where, $kw ) = @$a;
    return ( qq{Error: unknown command "$where" for "helm search"}, 0 ) unless ( $where // '' ) eq 'repo';
    my $cs = ( $k->{helm} || {} )->{charts} || {};
    my @rows;
    for my $ref ( sort keys %$cs ) {
        next if defined $kw && index( $ref, $kw ) < 0;
        my @v = _desc( keys %{ $cs->{$ref}{versions} || {} } );
        @v = ( $v[0] ) unless $o->{versions};
        push @rows, map { [ $ref, $_, $cs->{$ref}{versions}{$_}{app_version} // '', $cs->{$ref}{description} // '' ] } @v;
    }
    return ( 'No results found', 1 ) unless @rows;
    return ( Langertha::Holmgang::Sim::Linux::Kubernetes::_cols( [ 'NAME', 'CHART VERSION', 'APP VERSION', 'DESCRIPTION' ], @rows ), 1 );
}

# helm template NAME CHART [--version] [-f] [--set]: rendert lokal, aendert nichts
sub _h_template {
    my ( $k, $a, $o, $dev ) = @_;
    my ( $n, $ref ) = @$a;
    ( $n, $ref ) = ( 'release-name', $n ) unless defined $ref;
    return ( 'Error: "helm template" requires at least 1 argument', 0 ) unless defined $ref;
    my $ver = eval { _resolve_chart( $k, $ref, $o ) } // return ( $@ =~ s/\s+\z//r, 0 );
    my $vals = eval { _new_values( $dev, $o ) } // return ( $@ =~ s/\s+\z//r, 0 );
    my $chart = _chart_version( $k, $ref, $ver );
    my @out;
    for my $x ( _resources( $chart, $ver, _merge( $chart->{values} || {}, $vals ), $n, $o->{ns} ) ) {
        my ( $kind, $name, $obj ) = @$x;
        ( my $file = $Langertha::Holmgang::Sim::Linux::Kubernetes::SINGULAR{$kind} // $kind ) =~ s/\..*//;
        my $api = $K->can('_api_obj')->( $kind, $name, _clone($obj), $o->{ns} );
        delete $api->{metadata}{generation};
        push @out, "---\n# Source: " . _short($ref) . "/templates/$file.yaml\n" . _dump($api);
    }
    return ( join( "\n", @out ), 1 );
}

sub _h_show {
    my ( $k, $a, $o ) = @_;
    my ( $what, $ref ) = @$a;
    my $ver = eval { _resolve_chart( $k, $ref // '', $o ) } // return ( $@ =~ s/\s+\z//r, 0 );
    my $c = _chart_version( $k, $ref, $ver );
    return ( _dump( $c->{values} || {} ), 1 ) if ( $what // '' ) eq 'values';
    return ( join( "\n", 'apiVersion: v2', 'appVersion: ' . ( $c->{app_version} // '' ), 'name: ' . _short($ref), 'type: application', "version: $ver" ), 1 ) if ( $what // '' ) eq 'chart';
    push @GAPS, 'helm show ' . ( $what // '' );
    return ( '', 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Helm - helm on the admin host of a simulated cluster — releases, values, revisions, rendering

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator: helm on a device with kubernetes.helm
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Helm::helm( $dev, \@argv, $ctx );

=head1 DESCRIPTION

Helm 3 (v3.15) against the cluster under C<kubernetes> of a Linux device
(cai-platform F<docs/entwurf-evals.md> §3.3.1). The state is under C<kubernetes.helm>:

  helm:
    repos: { example: https://charts.example.com }
    charts:
      example/shop-api:
        versions:
          "1.4.0":
            app_version: 1.4.2
            values: { replicaCount: 2, image: { tag: "" } }      # the chart's defaults
            resources:                                           # templates (state shape)
              - kind: deployments
                name: "{{ .Release.Name }}"
                if: enabled                                      # only when the value is true
                obj: { replicas: "{{ .Values.replicaCount }}", … }
    releases:
      shop:                                                      # namespace
        shop-api:
          chart: example/shop-api
          version: 1.4.0
          revision: 4
          status: deployed            # deployed | failed | pending-upgrade | …
          values: { … }               # values set by the user (helm get values)
          updated: "2026-10-23 14:02:11"
          description: Upgrade complete
          history: [ { revision, version, values, status, updated, description }, … ]
          manifest: [ deployments/shop-api, … ]                  # what the release owns

Templates: a text that is exactly C<{{ EXPRESSION }}> becomes the value itself
(number, list …); otherwise it is substituted. Expressions: C<.Values.a.b>,
C<.Release.Name>, C<.Release.Namespace>, C<.Chart.Version>,
C<.Chart.AppVersion>, plus C<| default EXPRESSION|"text">. A hash with
C<_if: path> in a list counts only when the value is true.

B<Values like Helm 3>: C<upgrade> without C<--reuse-values> puts only the newly
passed values (C<-f>, C<--set>) on top of the chart's defaults — the old ones
are dropped; without new values the old ones stay. C<--reuse-values> puts the
new ones on top of the old. Without C<--version>, C<upgrade> takes the newest
chart version of the repo. C<helm list> shows only C<deployed> and C<failed>
(C<-a> all). A release in C<pending-*> refuses C<upgrade> ("another
operation … is in progress"); C<rollback> and deleting the secret of the
pending revision (C<sh.helm.release.v1.NAME.vN>) resolve it as for real.
C<--wait>/C<--atomic> check the readiness of the rendered deployments.

B<Commands>: C<list|ls>, C<status>, C<history|hist>, C<get values|manifest>,
C<upgrade [--install]>, C<install>, C<rollback>, C<uninstall>, C<repo
list|update>, C<search repo>, C<show values|chart>, C<version>. Anything else
(C<template>, C<lint>, C<pull> …) is a gap of the simulation; plugins
(C<diff>) are not installed.

Pure functions on the state, neutral.

=head2 drop_revision

  drop_revision( $k, $ns, $release, $revision );

The secret C<sh.helm.release.v1.NAME.vN> was deleted: the revision
disappears; if it was the newest, the previous one becomes current again.

=head2 release_secrets

  my %s = release_secrets( $k, $ns );   # name -> Secret (type helm.sh/release.v1)

=head2 helm

  my ( $out, $ok ) = helm( $dev, \@argv, $ctx );

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
