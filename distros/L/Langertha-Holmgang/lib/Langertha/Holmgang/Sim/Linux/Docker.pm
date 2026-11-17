package Langertha::Holmgang::Sim::Linux::Docker;
# ABSTRACT: Docker Engine with Compose v2 on a simulated Linux server — projects, containers, derived state

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use Encode ();
use JSON::MaybeXS ();
use JSON::PP ();

# Ausgabe von inspect wie Docker (Go json.MarshalIndent): "Key": value, vier Leerzeichen
my $OUT_JSON = JSON::PP->new->canonical->indent->indent_length(4)->space_after;
use YAML::XS ();

our $VERSION = '0.001';


my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

sub _L { require Langertha::Holmgang::Sim::Linux; return 'Langertha::Holmgang::Sim::Linux' }
sub _text  { my ( $dev, $p ) = @_; return _L()->can('_file_text')->( $dev, $p ) }
sub _gap   { push @Langertha::Holmgang::Sim::Linux::GAPS, $_[0]; return ( '', 0 ) }
sub _true  { JSON::MaybeXS::true() }
sub _false { JSON::MaybeXS::false() }

my @COMPOSE_FILES = qw( compose.yaml compose.yml docker-compose.yml docker-compose.yaml );

my %SERVICE_KEYS = map { $_ => 1 } qw( image build container_name environment env_file ports expose volumes
    networks depends_on healthcheck restart user command entrypoint profiles labels extra_hosts working_dir logging
    deploy cap_add cap_drop read_only tmpfs ulimits stop_grace_period stop_signal hostname domainname dns init
    privileged security_opt sysctls shm_size platform pull_policy stdin_open tty devices mem_limit memswap_limit
    cpus cpu_shares network_mode secrets configs links ipc pid group_add oom_score_adj userns_mode scale
    mac_address runtime external_links annotations attach );
my %TOP_KEYS = map { $_ => 1 } qw( version name services networks volumes secrets configs include );

# --- Zustand ----------------------------------------------------------------------


sub ensure {
    my ( $dev, $host, $state ) = @_;
    my $d = $dev->{docker};
    if ( ref $d->{containers} eq 'HASH' ) {
        _settle($dev);    # Neustart-Regel: inzwischen erneut versucht (Docker mit Backoff)
        return;
    }
    $d->{containers} = {};
    $d->{seq} //= 0;
    for my $p ( sort keys %{ $d->{projects} || {} } ) {
        my $pr = $d->{projects}{$p};
        next if $pr->{stopped};
        my %over = %{ $pr->{running_files} || {} };
        local $Langertha::Holmgang::Sim::Linux::Docker::OVERRIDE = \%over;
        my $m = model( $dev, dir => $pr->{dir}, project => $p );
        next if $m->{error};
        local $Langertha::Holmgang::Sim::Linux::Docker::QUIET = 1;
        up( $dev, $m, {}, $state, $host );
    }
    for ( values %{ $d->{containers} } ) { $_->{restarts} = 0; $_->{initial} = _true() }
    return;
}

our ( $OVERRIDE, $QUIET );

sub _file {
    my ( $dev, $p ) = @_;
    return $OVERRIDE->{$p} if $OVERRIDE && exists $OVERRIDE->{$p};
    return _text( $dev, $p );
}

# --- Interpolation und .env -------------------------------------------------------


# dotenv: KEY=VAL, export KEY=VAL, 'woertlich', "mit \n und ${X}", # Kommentar
sub parse_env {
    my ( $text, $vars, $missing ) = @_;
    my %e;
    $missing //= [];
    for my $l ( split /\n/, $text // '' ) {
        next if $l =~ /\A\s*(?:#|\z)/;
        my ( $k, $v ) = $l =~ /\A\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_.-]*)\s*=\s*(.*?)\s*\z/ or next;
        if    ( $v =~ /\A'(.*)'\z/ ) { $v = $1 }
        elsif ( $v =~ /\A"(.*)"\z/ ) {
            $v = $1;
            $v =~ s/\\n/\n/g;
            $v =~ s/\\(["\\])/$1/g;
            my $r = interpolate( $v, { %{ $vars || {} }, %e } );
            push @$missing, @{ $r->{missing} };
            $v = $r->{value};
        }
        else {
            $v =~ s/\s+#.*\z//;
            my $r = interpolate( $v, { %{ $vars || {} }, %e } );
            push @$missing, @{ $r->{missing} };
            $v = $r->{value};
        }
        $e{$k} = $v;
    }
    return \%e;
}


# ${VAR}, $VAR, ${VAR:-d}, ${VAR-d}, ${VAR:?e}, ${VAR?e}, ${VAR:+x}, $$ -> $
sub interpolate {
    my ( $s, $vars ) = @_;
    my ( @missing, $err );
    my $re;
    my $sub = sub {
        my ( $name, $op, $arg ) = @_;
        my $set = exists $vars->{$name};
        my $v = $vars->{$name};
        if ( defined $op ) {
            $arg = interpolate( $arg, $vars )->{value} if defined $arg && $arg =~ /\$/;
            if ( $op eq ':-' ) { return defined $v && length $v ? $v : $arg }
            if ( $op eq '-' )  { return $set ? $v // '' : $arg }
            if ( $op eq ':+' ) { return defined $v && length $v ? $arg : '' }
            if ( $op eq '+' )  { return $set ? $arg : '' }
            if ( $op eq ':?' || $op eq '?' ) {
                return $v if $op eq '?' ? $set : defined $v && length $v;
                $err //= "required variable $name is missing a value: " . ( $arg // '' );
                return '';
            }
        }
        push @missing, $name unless $set;
        return $v // '';
    };
    my $out = '';
    pos($s) = 0;
    while ( pos($s) < length $s ) {
        if    ( $s =~ /\G\$\$/gc ) { $out .= '$' }
        elsif ( $s =~ /\G\$\{((?:peer:)?[A-Za-z_][A-Za-z0-9_]*)(?:(:?[-?+])((?:[^{}]|\{[^{}]*\})*))?\}/gc ) { $out .= $sub->( $1, $2, $3 ) }
        elsif ( $s =~ /\G\$([A-Za-z_][A-Za-z0-9_]*)/gc ) { $out .= $sub->( $1, undef, undef ) }
        elsif ( $s =~ /\G\$\{([^}]*)\}/gc ) { $err //= "invalid interpolation format for \${$1}"; }
        elsif ( $s =~ /\G([^\$]+|\$)/gc ) { $out .= $1 }
    }
    return { value => $out, missing => \@missing, error => $err };
}

# Interpolation ueber eine ganze Datenstruktur (nur Werte, wie Compose)
sub _interp_tree {
    my ( $x, $vars, $acc ) = @_;
    if ( ref $x eq 'HASH' ) { return { map { $_ => _interp_tree( $x->{$_}, $vars, $acc ) } keys %$x } }
    if ( ref $x eq 'ARRAY' ) { return [ map { _interp_tree( $_, $vars, $acc ) } @$x ] }
    return $x if !defined $x || ref $x;
    my $r = interpolate( $x, $vars );
    push @{ $acc->{missing} }, @{ $r->{missing} };
    $acc->{error} //= $r->{error};
    return $r->{value};
}

# --- Modell eines Projekts ----------------------------------------------------------


sub model {
    my ( $dev, %o ) = @_;
    my $dir = $o{dir};
    my @files = @{ $o{files} || [] };
    if ( !@files ) {
        my ($f) = grep { defined _file( $dev, "$dir/$_" ) } @COMPOSE_FILES;
        return { error => 'no configuration file provided: not found', dir => $dir } unless defined $f;
        @files = ("$dir/$f");
        # ohne -f liest Compose auch die Override-Datei daneben
        ( my $ov = $f ) =~ s/\.(ya?ml)\z/.override.$1/;
        my ($o) = grep { defined _file( $dev, "$dir/$_" ) } $ov, map { s/\.(ya?ml)\z/.override.$1/r } @COMPOSE_FILES;
        push @files, "$dir/$o" if defined $o;
    }
    $dir //= ( $files[0] =~ m{\A(.*)/[^/]+\z} )[0];
    my %m = ( dir => $dir, file => $files[0], warnings => [] );
    my $envf = $o{env_file} // "$dir/.env";
    my @env_missing;
    my $vars = defined _file( $dev, $envf ) ? parse_env( _file( $dev, $envf ), {}, \@env_missing ) : {};
    my %shell = Langertha::Holmgang::Sim::Linux::shell_env();
    $vars = { %$vars, %shell };
    $m{shell_env} = {%shell} if %shell;
    if ( defined $o{env_file} && !defined _file( $dev, $envf ) ) {
        return { %m, error => "couldn't find env file: $envf" };
    }
    my $data = {};
    for my $f (@files) {
        my $t = _file( $dev, $f );
        return { %m, error => "open $f: no such file or directory" } unless defined $t;
        my $bytes = Encode::encode( 'UTF-8', $t );
        my $y = eval { YAML::XS::Load($bytes) };
        if ( my $e = $@ ) {
            my ($problem) = $e =~ /The problem:\s*\n\s*\n\s*(.+?)\s*\n/s;
            my ($line)    = $e =~ /line:\s*(\d+)/;
            $problem //= 'did not find expected key';
            return { %m, error => "yaml: line " . ( $line // 1 ) . ": $problem" };
        }
        return { %m, error => "validating $f: (root) must be a mapping" } unless ref $y eq 'HASH' || !defined $y;
        _merge( $data, $y || {}, '' );
    }
    my $acc = { missing => [] };    # Ersetzungen in .env selbst bleiben still (wie dotenv)
    $data = _interp_tree( $data, $vars, $acc );
    return { %m, error => $acc->{error} } if $acc->{error};
    my %seen;
    push @{ $m{warnings} }, map {"The \"$_\" variable is not set. Defaulting to a blank string."} grep { !$seen{$_}++ } @{ $acc->{missing} };
    push @{ $m{warnings} }, "$files[0]: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion"
        if exists $data->{version};
    for my $k ( sort keys %$data ) {
        next if $TOP_KEYS{$k} || $k =~ /\Ax-/;
        return { %m, error => "validating $files[0]: (root) additional properties '$k' not allowed" };
    }
    my $name = $o{project} // $data->{name} // ( $dir =~ m{([^/]+)\z} )[0] // 'default';
    $name = lc $name;
    $name =~ s/[^a-z0-9_-]//g;
    $m{name} = $name;
    my $svcs = $data->{services};
    return { %m, error => 'no service selected' } unless ref $svcs eq 'HASH' && %$svcs;
    my %nets = %{ ref $data->{networks} eq 'HASH' ? $data->{networks} : {} };
    my %vols = %{ ref $data->{volumes} eq 'HASH' ? $data->{volumes} : {} };
    $m{networks} = { map { $_ => _net_name( $name, $_, $nets{$_} ) } keys %nets };
    $m{internal} = { map { ( _net_name( $name, $_, $nets{$_} ) => 1 ) } grep { ref $nets{$_} eq 'HASH' && $nets{$_}{internal} } keys %nets };
    $m{volumes}  = { map { $_ => _vol_name( $name, $_, $vols{$_} ) } keys %vols };
    $m{external_volumes} = { map { ( _vol_name( $name, $_, $vols{$_} ) => 1 ) } grep { ref $vols{$_} eq 'HASH' && $vols{$_}{external} } keys %vols };
    my %active_profiles = map { $_ => 1 } @{ $o{profiles} || [] }, grep {length} split /,/, $vars->{COMPOSE_PROFILES} // '';
    for my $s ( sort keys %$svcs ) {
        my $c = $svcs->{$s};
        return { %m, error => "services.$s must be a mapping" } unless ref $c eq 'HASH';
        for my $k ( sort keys %$c ) {
            next if $SERVICE_KEYS{$k} || $k =~ /\Ax-/;
            return { %m, error => "validating $files[0]: services.$s additional properties '$k' not allowed" };
        }
        my $n = eval { _service( $dev, \%m, $s, $c, \%nets, \%vols ) };
        if ( my $e = $@ ) { $e =~ s/\s+\z//; return { %m, error => $e } }
        $n->{disabled} = 1 if @{ $n->{profiles} } && !grep { $active_profiles{$_} } @{ $n->{profiles} };
        $m{services}{$s} = $n;
    }
    for my $s ( sort keys %{ $m{services} } ) {
        for my $dep ( sort keys %{ $m{services}{$s}{depends_on} } ) {
            return { %m, error => "service \"$s\" depends on undefined service \"$dep\": invalid compose project" }
                unless $m{services}{$dep};
        }
    }
    return \%m;
}

# Mehrere Dateien wie Compose: Maps werden gemischt, ports/expose/dns angehaengt,
# volumes nach Ziel, environment nach Name; sonst ersetzt die spaetere Datei.
sub _merge {
    my ( $a, $b, $path ) = @_;
    for my $k ( keys %$b ) {
        my $p = length $path ? "$path.$k" : $k;
        if ( $p =~ /\Aservices\.[^.]+\.environment\z/ && defined $a->{$k} ) {
            $a->{$k} = { %{ _env_map( $a->{$k} ) }, %{ _env_map( $b->{$k} ) } };
        }
        elsif ( $p =~ /\Aservices\.[^.]+\.(?:ports|expose|dns|dns_search|tmpfs|external_links)\z/ && ref $a->{$k} eq 'ARRAY' && ref $b->{$k} eq 'ARRAY' ) {
            my %seen = map { ( ref $_ ? $JSON->encode($_) : "$_" ) => 1 } @{ $a->{$k} };
            push @{ $a->{$k} }, grep { !$seen{ ref $_ ? $JSON->encode($_) : "$_" } } @{ $b->{$k} };
        }
        elsif ( $p =~ /\Aservices\.[^.]+\.volumes\z/ && ref $a->{$k} eq 'ARRAY' && ref $b->{$k} eq 'ARRAY' ) {
            my $tgt = sub { my ($v) = @_; ref $v eq 'HASH' ? $v->{target} // '' : ( split /:/, "$v" )[ ( split /:/, "$v" ) > 1 ? 1 : 0 ] };
            my %new = map { $tgt->($_) => 1 } @{ $b->{$k} };
            $a->{$k} = [ ( grep { !$new{ $tgt->($_) } } @{ $a->{$k} } ), @{ $b->{$k} } ];
        }
        elsif ( ref $a->{$k} eq 'HASH' && ref $b->{$k} eq 'HASH' ) { _merge( $a->{$k}, $b->{$k}, $p ) }
        else { $a->{$k} = $b->{$k} }
    }
    return $a;
}

sub _env_map {
    my ($e) = @_;
    return {%$e} if ref $e eq 'HASH';
    return { map { /\A([^=]+)(?:=(.*))?\z/s ? ( $1 => $2 ) : () } @$e } if ref $e eq 'ARRAY';
    return {};
}

sub _net_name {
    my ( $p, $n, $c ) = @_;
    $c = {} unless ref $c eq 'HASH';
    return $c->{name} // $n if $c->{external};
    return $c->{name} // "${p}_$n";
}

sub _vol_name {
    my ( $p, $n, $c ) = @_;
    $c = {} unless ref $c eq 'HASH';
    return $c->{name} // $n if $c->{external};
    return $c->{name} // "${p}_$n";
}

sub _service {
    my ( $dev, $m, $s, $c, $nets, $vols ) = @_;
    my $dir = $m->{dir};
    my %n = ( name => $s );
    die "service \"$s\" has neither an image nor a build context specified: invalid compose project\n"
        unless defined $c->{image} || defined $c->{build};
    $n{image} = $c->{image};
    die "invalid reference format\n" if defined $n{image} && ( $n{image} =~ /:\z/ || $n{image} =~ /\s/ || $n{image} eq '' );
    $n{image} .= ':latest' if defined $n{image} && $n{image} !~ m{:[^/]+\z} && $n{image} !~ /@/;
    $n{build} = 1 if defined $c->{build};
    $n{container_name} = $c->{container_name} if defined $c->{container_name};
    # Umgebung: env_file (der Reihe nach), dann environment
    my %env;
    for my $ef ( ref $c->{env_file} eq 'ARRAY' ? @{ $c->{env_file} } : grep {defined} $c->{env_file} ) {
        my ( $p, $req ) = ref $ef eq 'HASH' ? ( $ef->{path}, $ef->{required} // 1 ) : ( $ef, 1 );
        my $abs = $p =~ m{\A/} ? $p : "$dir/" . ( $p =~ s{\A\./}{}r );
        my $t = _file( $dev, $abs );
        if ( !defined $t ) {
            next unless $req;
            die "env file $abs not found: stat $abs: no such file or directory\n";
        }
        %env = ( %env, %{ _literal_env($t) } );
    }
    my $e = $c->{environment};
    if ( ref $e eq 'HASH' ) { $env{$_} = defined $e->{$_} ? "$e->{$_}" : '' for keys %$e }
    elsif ( ref $e eq 'ARRAY' ) {
        for (@$e) { my ( $k, $v ) = /\A([^=]+)(?:=(.*))?\z/s or next; $env{$k} = $v // '' }
    }
    elsif ( defined $e ) { die "services.$s.environment must be a mapping\n" }
    $n{environment} = \%env;
    # Ports
    my @ports;
    for my $p ( @{ ref $c->{ports} eq 'ARRAY' ? $c->{ports} : [] } ) {
        if ( ref $p eq 'HASH' ) {
            push @ports, { host_ip => $p->{host_ip} // '0.0.0.0', published => defined $p->{published} ? "$p->{published}" : '',
                target => "$p->{target}", protocol => $p->{protocol} // 'tcp' };
            next;
        }
        my ( $spec, $proto ) = split m{/}, "$p", 2;
        my @parts = split /:/, $spec;
        die "services.$s.ports contains an invalid port specification: $p\n" if @parts > 3 || grep { !/\A[\d.\-]*\z/ } @parts;
        my ( $ip, $pub, $tgt ) = @parts == 3 ? @parts : @parts == 2 ? ( '0.0.0.0', @parts ) : ( '0.0.0.0', '', @parts );
        $ip = '0.0.0.0' if $ip eq '';
        push @ports, { host_ip => $ip, published => $pub, target => $tgt, protocol => $proto // 'tcp' };
    }
    $n{ports} = \@ports;
    # Volumes
    my @mounts;
    for my $v ( @{ ref $c->{volumes} eq 'ARRAY' ? $c->{volumes} : [] } ) {
        my ( $src, $tgt, $ro, $type );
        if ( ref $v eq 'HASH' ) {
            ( $src, $tgt, $ro, $type ) = ( $v->{source}, $v->{target}, $v->{read_only}, $v->{type} );
        }
        else {
            my @p = split /:/, "$v";
            ( $src, $tgt ) = @p == 1 ? ( undef, $p[0] ) : @p[ 0, 1 ];
            $ro = 1 if ( $p[2] // '' ) =~ /\bro\b/;
        }
        die "services.$s.volumes: invalid mount config\n" unless defined $tgt && $tgt =~ m{\A/};
        if ( !defined $src || $src eq '' ) { push @mounts, { type => 'volume', source => '', target => $tgt, anonymous => 1 }; next }
        $type //= $src =~ m{\A(?:/|\./|\.\./|~)} ? 'bind' : 'volume';
        if ( $type eq 'bind' ) {
            my $abs = $src =~ m{\A/} ? $src : "$dir/" . ( $src =~ s{\A\./}{}r );
            1 while $abs =~ s{/[^/]+/\.\./}{/};
            $abs =~ s{/+\z}{};
            push @mounts, { type => 'bind', source => $abs, target => $tgt, ( $ro ? ( read_only => 1 ) : () ) };
        }
        else {
            die "service \"$s\" refers to undefined volume $src: invalid compose project\n" unless exists $vols->{$src};
            push @mounts, { type => 'volume', source => _vol_name( $m->{name} // 'x', $src, $vols->{$src} ), target => $tgt,
                ( $ro ? ( read_only => 1 ) : () ) };
        }
    }
    $n{volumes} = \@mounts;
    # Netze
    my @nw;
    if ( ref $c->{networks} eq 'ARRAY' ) { @nw = @{ $c->{networks} } }
    elsif ( ref $c->{networks} eq 'HASH' ) { @nw = sort keys %{ $c->{networks} } }
    for (@nw) { die "service \"$s\" refers to undefined network $_: invalid compose project\n" unless exists $nets->{$_} || $_ eq 'default' }
    @nw = ('default') unless @nw;
    $n{networks} = [ sort @nw ];
    $n{network_mode} = $c->{network_mode} if defined $c->{network_mode};
    # depends_on
    my %dep;
    if ( ref $c->{depends_on} eq 'ARRAY' ) { $dep{$_} = { condition => 'service_started' } for @{ $c->{depends_on} } }
    elsif ( ref $c->{depends_on} eq 'HASH' ) {
        for my $d ( keys %{ $c->{depends_on} } ) {
            my $v = $c->{depends_on}{$d};
            my $cond = ref $v eq 'HASH' ? $v->{condition} // 'service_started' : 'service_started';
            die "services.$s.depends_on.$d.condition must be one of the following: \"service_started\", \"service_healthy\", \"service_completed_successfully\"\n"
                unless $cond =~ /\Aservice_(?:started|healthy|completed_successfully)\z/;
            $dep{$d} = { condition => $cond };
        }
    }
    $n{depends_on} = \%dep;
    # healthcheck
    if ( ref $c->{healthcheck} eq 'HASH' ) {
        my $h = $c->{healthcheck};
        if ( $h->{disable} ) { $n{healthcheck} = { disable => 1 } }
        else {
            my $t = $h->{test};
            $t = [ 'CMD-SHELL', $t ] if defined $t && !ref $t;
            $n{healthcheck} = { test => $t, map { defined $h->{$_} ? ( $_ => "$h->{$_}" ) : () } qw( interval timeout retries start_period ) };
        }
    }
    $n{restart} = $c->{restart} // 'no';
    die "services.$s.restart must be one of no, always, on-failure, unless-stopped\n"
        unless $n{restart} =~ /\A(?:no|always|unless-stopped|on-failure(?::\d+)?)\z/;
    $n{mem_limit} = "$c->{mem_limit}" if defined $c->{mem_limit};
    $n{deploy} = $c->{deploy} if ref $c->{deploy} eq 'HASH';
    for my $k (qw( user command entrypoint working_dir hostname read_only )) {
        $n{$k} = ref $c->{$k} ? $c->{$k} : "$c->{$k}" if defined $c->{$k};
    }
    $n{extra_hosts} = $c->{extra_hosts} if defined $c->{extra_hosts};
    $n{labels} = $c->{labels} if defined $c->{labels};
    $n{profiles} = [ @{ ref $c->{profiles} eq 'ARRAY' ? $c->{profiles} : [] } ];
    return \%n;
}

sub _literal_env {
    my ($t) = @_;
    my %e;
    for my $l ( split /\n/, $t ) {
        next if $l =~ /\A\s*(?:#|\z)/;
        my ( $k, $v ) = $l =~ /\A\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_.-]*)\s*=\s*(.*?)\s*\z/ or next;
        if ( $v =~ /\A'(.*)'\z/ || $v =~ /\A"(.*)"\z/ ) { $v = $1 }
        else { $v =~ s/\s+#.*\z// }
        $e{$k} = $v;
    }
    return \%e;
}

# Hash der wirksamen Konfiguration (wann ein Container neu erzeugt wird)
sub _config_hash {
    my ($svc) = @_;
    my %c = %$svc;
    delete @c{qw( depends_on profiles disabled name )};
    return substr( Digest::SHA::sha256_hex( Encode::encode( 'UTF-8', $JSON->encode( \%c ) ) ), 0, 16 );
}

# --- Images -----------------------------------------------------------------------

sub _image {
    my ( $d, $ref ) = @_;
    return $d->{images}{$ref} if $d->{images} && exists $d->{images}{$ref};
    return undef;
}

sub _pull {
    my ( $d, $ref ) = @_;
    my $r = ( $d->{registry} || {} )->{$ref};
    if ( !defined $r ) {
        my ($repo) = $ref =~ /\A(.+):[^:\/]+\z/;
        return ( 0, "Error response from daemon: pull access denied for $repo, repository does not exist or may require 'docker login': denied: requested access to the resource is denied" )
            unless grep { /\A\Q$repo\E:/ } keys %{ $d->{registry} || {} }, keys %{ $d->{images} || {} };
        return ( 0, "Error response from daemon: manifest for $ref not found: manifest unknown: manifest unknown" );
    }
    $d->{images}{$ref} = $r;
    return (1);
}

# --- Container -----------------------------------------------------------------------

sub _cname {
    my ( $m, $s ) = @_;
    my $svc = $m->{services}{$s};
    return $svc->{container_name} // "$m->{name}-$s-1";
}

sub _project_containers {
    my ( $d, $p ) = @_;
    return grep { ( $d->{containers}{$_}{project} // '' ) eq $p } sort keys %{ $d->{containers} };
}

# Reihenfolge nach depends_on (Abhaengigkeiten zuerst)
sub _order {
    my ( $m, @want ) = @_;
    my ( @out, %seen );
    my $visit;
    $visit = sub {
        my ($s) = @_;
        return if $seen{$s}++;
        $visit->($_) for sort keys %{ $m->{services}{$s}{depends_on} || {} };
        push @out, $s;
    };
    $visit->($_) for @want;
    return @out;
}


sub up {
    my ( $dev, $m, $o, $state, $host ) = @_;
    my $d = $dev->{docker};
    my @want = @{ $o->{services} || [] };
    for (@want) { return ( [], 0, "no such service: $_" ) unless $m->{services}{$_} }
    @want = grep { !$m->{services}{$_}{disabled} } sort keys %{ $m->{services} } unless @want;
    my @order = $o->{no_deps} ? @want : _order( $m, @want );
    # --force-recreate gilt fuer die gewaehlten Dienste; Abhaengigkeiten nur bei
    # geaenderter Konfiguration (oder --always-recreate-deps), wie Compose v2
    my %forced = map { $_ => 1 } $o->{force_recreate} ? @want : (), $o->{recreate_deps} ? @order : ();
    my ( @l, %fresh );
    my $ok = 1;
    my $err;
    # Netze
    for my $s (@order) {
        for my $n ( @{ $m->{services}{$s}{networks} } ) {
            my $full = $n eq 'default' ? "$m->{name}_default" : $m->{networks}{$n};
            next if $d->{networks}{$full};
            $d->{networks}{$full} = { project => $m->{name} };
            push @l, " Network $full  Creating", " Network $full  Created";
        }
        for my $v ( grep { $_->{type} eq 'volume' && !$_->{anonymous} } @{ $m->{services}{$s}{volumes} } ) {
            next if $d->{volumes}{ $v->{source} };
            $d->{volumes}{ $v->{source} } = { project => $m->{name} };
            push @l, " Volume \"$v->{source}\"  Creating", " Volume \"$v->{source}\"  Created";
        }
    }
    # Waisen
    my %svc_names = map { _cname( $m, $_ ) => 1 } keys %{ $m->{services} };
    my @orph = grep { !$svc_names{$_} } _project_containers( $d, $m->{name} );
    if (@orph) {
        if ( $o->{remove_orphans} ) {
            for my $c (@orph) { push @l, " Container $c  Stopping", " Container $c  Stopped", " Container $c  Removing", " Container $c  Removed"; delete $d->{containers}{$c} }
        }
        else {
            unshift @l, "WARN[0000] Found orphan containers ([" . join( ' ', @orph ) . "]) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.";
        }
    }
    SERVICE: for my $s (@order) {
        my $svc  = $m->{services}{$s};
        my $name = _cname( $m, $s );
        if ( $svc->{build} && !defined $svc->{image} ) { _gap("docker compose build ($s)"); return ( \@l, 0, "build is not supported here" ) }
        my $img = _image( $d, $svc->{image} );
        if ( !$img ) {
            push @l, " $s Pulling";
            my ( $pok, $perr ) = _pull( $d, $svc->{image} );
            if ( !$pok ) { push @l, " $s Error " . ( $perr =~ s/\AError response from daemon: //r ); return ( \@l, 0, $perr ) }
            push @l, " $s Pulled";
            $img = _image( $d, $svc->{image} );
        }
        my $hash = _config_hash($svc);
        my $c = $d->{containers}{$name};
        if ( $c && ( $c->{project} // '' ) ne $m->{name} ) {
            return ( \@l, 0, "Error response from daemon: Conflict. The container name \"/$name\" is already in use by container \"" . _id( $name, $c->{seq} ) . "\". You have to remove (or rename) that container to be able to reuse that name." );
        }
        # Warten auf Abhaengigkeiten
        for my $dep ( sort keys %{ $svc->{depends_on} } ) {
            my $cond = $svc->{depends_on}{$dep}{condition};
            my $dc = $d->{containers}{ _cname( $m, $dep ) };
            if ( $cond eq 'service_healthy' ) {
                push @l, " Container " . _cname( $m, $dep ) . "  Waiting";
                if ( $dc && !_has_hc( $dc->{config}, _image( $d, $dc->{image} ) || {} ) ) {
                    push @l, " Container " . _cname( $m, $dep ) . "  Error";
                    $err = "dependency failed to start: container " . _cname( $m, $dep ) . " has no healthcheck configured";
                    $ok = 0;
                    _create( $d, $m, $s, $name, $svc, $hash, \@l ) unless $c && $c->{hash} eq $hash;
                    next SERVICE;
                }
                if ( !$dc || ( $dc->{health} // '' ) ne 'healthy' ) {
                    push @l, " Container " . _cname( $m, $dep ) . "  Error";
                    $err = "dependency failed to start: container " . _cname( $m, $dep ) . ( $dc && $dc->{status} eq 'running' ? ' is unhealthy' : ' exited (1)' );
                    $ok = 0;
                    _create( $d, $m, $s, $name, $svc, $hash, \@l ) unless $c && $c->{hash} eq $hash;
                    next SERVICE;
                }
                push @l, " Container " . _cname( $m, $dep ) . "  Healthy";
            }
        }
        $c->{config}{depends_on} = $svc->{depends_on} if $c;    # Abhaengigkeiten gehoeren dem Projekt, nicht dem Container
        if ( $c && $c->{hash} eq $hash && $c->{image_id} eq _img_id( $svc->{image}, $img ) && !$forced{$s} ) {
            if ( $c->{status} eq 'running' || $c->{status} eq 'restarting' ) { push @l, " Container $name  Running"; next }
            push @l, " Container $name  Starting";
        }
        elsif ($c) {
            push @l, " Container $name  Recreate";
            $c->{restarts}++ if $c->{status} eq 'running' || $c->{status} eq 'restarting';
            _create( $d, $m, $s, $name, $svc, $hash, \@l, $c->{restarts} );
            push @l, " Container $name  Recreated", " Container $name  Starting";
        }
        else {
            push @l, " Container $name  Creating";
            _create( $d, $m, $s, $name, $svc, $hash, \@l );
            push @l, " Container $name  Created", " Container $name  Starting";
        }
        $c = $d->{containers}{$name};
        my $e = _start( $dev, $d, $name, $c, \%fresh, $state, $host );
        $c->{start_error} = $e if defined $e;
        if ($e) { push @l, " Container $name  Error"; $err //= $e; $ok = 0; next }
        $fresh{$name} = 1;
        push @l, " Container $name  Started";
    }
    _settle($dev);
    return ( \@l, $ok, $err );
}

sub _img_id { my ( $ref, $img ) = @_; return substr( Digest::SHA::sha256_hex( $ref . $JSON->encode( $img || {} ) ), 0, 12 ) }
sub _id { my ( $name, $seq ) = @_; return substr( Digest::SHA::sha256_hex( "$name/" . ( $seq // 0 ) ), 0, 12 ) }

sub _create {
    my ( $d, $m, $s, $name, $svc, $hash, $l, $restarts ) = @_;
    my $img = _image( $d, $svc->{image} ) || {};
    $d->{seq}++;
    $d->{containers}{$name} = {
        project => $m->{name}, service => $s, image => $svc->{image}, image_id => _img_id( $svc->{image}, $img ),
        hash => $hash, seq => $d->{seq}, status => 'created', restarts => $restarts // 0,
        ( defined _mem_limit($svc) ? ( mem_limit_bytes => _mem_limit($svc) ) : () ),
        config => { %$svc, networks => [ map { $_ eq 'default' ? "$m->{name}_default" : $m->{networks}{$_} } @{ $svc->{networks} } ],
            ( %{ $m->{internal} || {} } ? ( internal_nets => { %{ $m->{internal} } } ) : () ) },
    };
    return;
}

# Container starten: Ports, Einhaengungen, Bedingungen des Images. Fehlertext oder undef.
sub _start {
    my ( $dev, $d, $name, $c, $fresh, $state, $host ) = @_;
    my $cfg = $c->{config};
    my $img = _image( $d, $c->{image} ) || {};
    # Ports
    for my $p ( @{ $cfg->{ports} } ) {
        next unless length $p->{published};
        my $k = "$p->{host_ip}:$p->{published}";
        my ($host_proc) = grep { _port_clash( $_, $p->{host_ip}, $p->{published} ) } sort keys %{ $d->{host_ports} || {} };
        my $id = _id( $name, $c->{seq} );
        if ( defined $host_proc ) {
            $c->{status} = 'created';
            return "Error response from daemon: driver failed programming external connectivity on endpoint $name ($id): failed to bind port $k/tcp: Error starting userland proxy: listen tcp4 $k: bind: address already in use";
        }
        for my $o ( sort keys %{ $d->{containers} } ) {
            next if $o eq $name;
            my $oc = $d->{containers}{$o};
            next unless $oc->{status} eq 'running' || $oc->{status} eq 'restarting';
            if ( grep { length $_->{published} && _port_clash( "$_->{host_ip}:$_->{published}", $p->{host_ip}, $p->{published} ) } @{ $oc->{config}{ports} } ) {
                $c->{status} = 'created';
                return "Error response from daemon: driver failed programming external connectivity on endpoint $name ($id): Bind for $k failed: port is already allocated";
            }
        }
    }
    # Bind-Mounts: fehlende Verzeichnisse legt Docker als root an
    for my $mt ( grep { $_->{type} eq 'bind' } @{ $cfg->{volumes} } ) {
        next if _L()->can('_file_entry')->( $dev, $mt->{source} ) || _L()->can('_is_dir')->( $dev, $mt->{source} );
        $dev->{dirs}{ $mt->{source} } = { owner => 'root', group => 'root', mode => '0755' };
    }
    delete @$c{qw( error early_error )};
    my $bad = _failing_need( $dev, $d, $name, $c, $img, $fresh );
    if ( $bad && $bad->{transient} && $cfg->{restart} ne 'no' ) {
        # Wettlauf beim Start: mit Neustart-Regel laeuft er beim naechsten Versuch
        $c->{restart_count} = ( $c->{restart_count} // 0 ) + 1;
        $c->{early_error} = $bad->{log};
        $bad = _failing_need( $dev, $d, $name, $c, $img, {} );
    }
    if ($bad) {
        $c->{error} = $bad->{log} || [];
        $c->{exit_code} = $bad->{exit} // 1;
        if ( $bad->{oom} ) { $c->{oom} = _true() } else { delete $c->{oom} }
        delete $c->{data};
        if ( $cfg->{restart} ne 'no' ) {
            $c->{status} = 'restarting';
            $c->{restart_count} = ( $c->{restart_count} // 0 ) + 3;
            if ( _has_hc( $cfg, $img ) ) { $c->{health} = 'unhealthy' } else { delete $c->{health} }
        }
        else {
            $c->{status} = 'exited';
            delete $c->{health};
        }
        return undef;
    }
    $c->{status} = 'running';
    delete $c->{oom};
    delete $c->{initial};    # nur was schon vor dem ersten Befehl lief, laeuft „seit 2 Stunden“
    delete $c->{exit_code};
    $c->{data} = _data_of( $dev, $d, $c, $img );
    $c->{health} = _health( $dev, $d, $name, $c, $img ) if _has_hc( $cfg, $img );
    delete $c->{health} unless _has_hc( $cfg, $img );
    return undef;
}

sub _port_clash {
    my ( $key, $ip, $port ) = @_;
    my ( $kip, $kp ) = $key =~ /\A(?:(.*):)?(\d+)\z/ or return 0;
    return 0 unless $kp == $port;
    $kip //= '0.0.0.0';
    return 1 if $kip eq '0.0.0.0' || $ip eq '0.0.0.0' || $kip eq $ip;
    return 0;
}

# Neu rechnen, was von anderen abhaengt (Gesundheit, Daten)
sub _settle {
    my ($dev) = @_;
    my $d = $dev->{docker};
    # Container mit Neustart-Regel kommen hoch, sobald ihre Bedingungen halten
    for my $round ( 1 .. 5 ) {
        my $changed = 0;
        for my $n ( sort keys %{ $d->{containers} } ) {
            my $c = $d->{containers}{$n};
            next unless $c->{status} eq 'restarting';
            next if _failing_need( $dev, $d, $n, $c, _image( $d, $c->{image} ) || {}, {} );
            _start( $dev, $d, $n, $c, {}, undef, undef );
            $changed = 1;
        }
        last unless $changed;
    }
    for my $n ( sort keys %{ $d->{containers} } ) {
        my $c = $d->{containers}{$n};
        my $img = _image( $d, $c->{image} ) || {};
        next unless $c->{status} eq 'running';
        $c->{health} = _health( $dev, $d, $n, $c, $img ) if _has_hc( $c->{config}, $img );
    }
    return;
}

sub _env_of {
    my ( $c, $img ) = @_;
    return { %{ $img->{env} || {} }, %{ $c->{config}{environment} || {} } };
}

sub _vars {
    my ( $c, $img, $peer ) = @_;
    my $env = _env_of( $c, $img );
    my %v = %$env;
    if ($peer) { my $pe = _env_of( $peer->[1], $peer->[2] ); $v{"peer:$_"} = $pe->{$_} for keys %$pe }
    return \%v;
}

sub _expand { my ( $t, $v ) = @_; return interpolate( $t, $v )->{value} }


# Container zu einem Namen aus Sicht eines Containers (gemeinsames Netz)
sub lookup {
    my ( $d, $from, $hostname ) = @_;
    my $fc = $d->{containers}{$from} or return;
    my %fnet = map { $_ => 1 } @{ $fc->{config}{networks} || [] };
    for my $n ( sort keys %{ $d->{containers} } ) {
        my $c = $d->{containers}{$n};
        my $same = ( $c->{project} // '' ) eq ( $fc->{project} // '' );
        next unless $n eq $hostname || ( $c->{config}{hostname} // '' ) eq $hostname
            || ( $same && ( $c->{service} // '' ) eq $hostname );
        next unless grep { $fnet{$_} } @{ $c->{config}{networks} || [] };
        return ( $n, $c );
    }
    return;
}

# Erste verletzte Bedingung des Images: { log, transient } oder undef
sub _failing_need {
    my ( $dev, $d, $name, $c, $img, $fresh ) = @_;
    my $peer;
    for my $n ( @{ $img->{needs} || [] } ) {
        next if defined $n->{when_env} && !length( _env_of( $c, $img )->{ $n->{when_env} } // '' );
        my $v = _vars( $c, $img, $peer );
        my $log = [ map { _expand( $_, $v ) } @{ $n->{log} || [] } ];
        if ( defined $n->{env} ) {
            my $x = _env_of( $c, $img )->{ $n->{env} };
            return { log => $log } unless defined $x && length $x;
        }
        elsif ( defined $n->{connect} ) {
            my ( $h, $p ) = _expand( $n->{connect}, $v ) =~ /\A(.*):(\d*)\z/ or return { log => $log };
            return { log => $log } unless length $h && length $p;
            if ( $h eq 'localhost' || $h eq '127.0.0.1' ) { return { log => $log } unless grep { $_ == $p } @{ $img->{listens} || [] }; next }
            my $hip = _extra_host( $c, $h ) // ( $h =~ /\A\d+\.\d+\.\d+\.\d+\z/ ? $h : undef );    # extra_hosts, host-gateway, IP
            if ( defined $hip ) {
                if ( $hip =~ /\A127\./ ) {    # im Container ist das der Container selbst
                    return { log => $log } unless grep { $_ == $p } @{ $img->{listens} || [] };
                }
                else { return { log => $log } unless _host_listens( $dev, $d, $hip, $p ) }
                next;
            }
            my ( $pn, $pc ) = lookup( $d, $name, $h );
            return { log => $log } unless $pc;
            my $pimg = _image( $d, $pc->{image} ) || {};
            return { log => $log } unless $pc->{status} eq 'running' && grep { $_ == $p } @{ $pimg->{listens} || [] };
            # gerade erst gestartet, ohne auf die Gesundheit zu warten
            if ( $pimg->{warmup} && $fresh->{$pn} ) {
                my $cond = ( $c->{config}{depends_on}{ $pc->{service} } || {} )->{condition} // '';
                return { log => $log, transient => 1 } unless $cond eq 'service_healthy';
            }
            $peer = [ $pn, $pc, $pimg ];
        }
        elsif ( ref $n->{equals} eq 'ARRAY' ) {
            my ( $a, $b ) = map { _expand( $_, $v ) } @{ $n->{equals} };
            return { log => $log } unless defined $a && defined $b && $a eq $b;
        }
        elsif ( defined $n->{writable} ) {
            return { log => $log } unless _writable( $dev, $d, $c, $img, $n->{writable} );
        }
        elsif ( defined $n->{egress} ) {    # Ziel ausserhalb des Hosts: nur ueber ein Netz, das nicht internal ist
            my @nw = @{ $c->{config}{networks} || [] };
            my $int = $c->{config}{internal_nets} || {};
            return { log => $log } if ( $c->{config}{network_mode} // '' ) eq 'none' || !grep { !$int->{$_} } @nw;
        }
        elsif ( defined $n->{memory} ) {    # braucht so viel Speicher, sonst OOM-Kill (Exit 137)
            my $lim = _mem_limit( $c->{config} );
            return { log => $log, exit => 137, oom => 1 } if defined $lim && $lim < _bytes( $n->{memory} );
        }
        elsif ( defined $n->{mount} ) {
            my ($mt) = _mount_at( $c, $n->{mount} );
            return { log => $log } unless $mt && $mt->{type} eq 'bind' && defined _text( $dev, $mt->{source} . substr( $n->{mount}, length $mt->{target} ) );
        }
    }
    return undef;
}

# extra_hosts eines Containers: Name -> Adresse (host-gateway = Bruecke docker0)
sub _extra_host {
    my ( $c, $h ) = @_;
    my $x = $c->{config}{extra_hosts} or return undef;
    my %m = ref $x eq 'HASH' ? %$x : map { /\A([^:=]+)[:=](.+)\z/ ? ( $1 => $2 ) : () } @$x;
    my $ip = $m{$h} // return undef;
    return $ip eq 'host-gateway' ? '172.17.0.1' : $ip;
}

# Lauscht auf dem Host ein Dienst auf ip:port (docker.host_listen: { "172.17.0.1:25": postfix })?
sub _host_listens {
    my ( $dev, $d, $ip, $p ) = @_;
    for my $k ( sort keys %{ $d->{host_listen} || {} } ) {
        my ( $kip, $kp ) = $k =~ /\A(?:(.*):)?(\d+)\z/ or next;
        next unless $kp == $p && ( !defined $kip || $kip eq '0.0.0.0' || $kip eq $ip );
        my $svc = ( $dev->{services} || {} )->{ $d->{host_listen}{$k} };
        return 1 if !$svc || $svc->{active};
    }
    return 0;
}

# Speichergrenze eines Dienstes: mem_limit oder deploy.resources.limits.memory (Bytes)
sub _mem_limit {
    my ($cfg) = @_;
    my $l = $cfg->{mem_limit} // ( ( ( $cfg->{deploy} || {} )->{resources} || {} )->{limits} || {} )->{memory};
    return defined $l ? _bytes($l) : undef;
}

sub _bytes {
    my ($v) = @_;
    my ( $n, $u ) = "$v" =~ /\A\s*([\d.]+)\s*([kmgt]?)i?b?\s*\z/i or return 0;
    return int( $n * ( { '' => 1, k => 1024, m => 1024**2, g => 1024**3, t => 1024**4 }->{ lc $u } ) );
}

# Laengste Einhaengung, die den Pfad im Container enthaelt
sub _mount_at {
    my ( $c, $path ) = @_;
    my ($mt) = sort { length $b->{target} <=> length $a->{target} }
        grep { $path eq $_->{target} || index( $path, "$_->{target}/" ) == 0 } @{ $c->{config}{volumes} || [] };
    return $mt;
}

sub _uid_of {
    my ( $c, $img ) = @_;
    my $u = $c->{config}{user} // $img->{user} // '0';
    my ( $uid, $gid ) = split /:/, "$u";
    return ( $uid // 0, $gid // $uid // 0 );
}

sub _writable {
    my ( $dev, $d, $c, $img, $path ) = @_;
    my $mt = _mount_at( $c, $path ) or return 0;
    return 0 if $mt->{read_only};
    return 1 if $mt->{type} eq 'volume';
    my ( $uid, $gid ) = _uid_of( $c, $img );
    return 1 if $uid =~ /\A0\z|\Aroot\z/;
    my $e = ( $dev->{dirs} || {} )->{ $mt->{source} } // _L()->can('_file_entry')->( $dev, $mt->{source} ) // {};
    my $mode = oct( $e->{mode} // '0755' );
    my $L = _L();
    my $ouid = $L->can('_uid')->( $dev, $e->{owner} // 'root' );
    my $ogid = $L->can('_gid')->( $dev, $e->{group} // 'root' );
    return ( $mode >> 6 ) & 2 ? 1 : 0 if $ouid == $uid;
    return ( $mode >> 3 ) & 2 ? 1 : 0 if $ogid == $gid;
    return $mode & 2 ? 1 : 0;
}

sub _data_of {
    my ( $dev, $d, $c, $img ) = @_;
    return undef unless defined $img->{data_path};
    my $mt = _mount_at( $c, $img->{data_path} );
    if ( !$mt || $mt->{anonymous} ) { return $img->{init_data} // 'leer' }
    if ( $mt->{type} eq 'volume' ) {
        my $v = $d->{volumes}{ $mt->{source} } //= {};
        $v->{data} //= $img->{init_data} // 'leer';
        return $v->{data};
    }
    my $e = $dev->{dirs}{ $mt->{source} } //= { owner => 'root', group => 'root', mode => '0755' };
    $e->{data} //= $img->{init_data} // 'leer';
    return $e->{data};
}

sub _has_hc {
    my ( $cfg, $img ) = @_;
    return 0 if $cfg->{healthcheck} && $cfg->{healthcheck}{disable};
    return $cfg->{healthcheck} || $img->{healthcheck} ? 1 : 0;
}

# Gesundheit aus dem Test des Healthchecks: healthy | unhealthy
sub _health {
    my ( $dev, $d, $name, $c, $img ) = @_;
    my $hc = $c->{config}{healthcheck} || { test => $img->{healthcheck} };
    my $t = $hc->{test};
    $t = [ 'CMD-SHELL', $t ] if defined $t && !ref $t;
    return 'unhealthy' unless ref $t eq 'ARRAY' && @$t >= 2;
    my ( $kind, @rest ) = @$t;
    return 'unhealthy' if $kind eq 'NONE';
    my $line = $kind eq 'CMD-SHELL' ? $rest[0] : join ' ', map { /\s/ ? "'$_'" : $_ } @rest;
    $line = _expand( $line, _env_of( $c, $img ) ) if $kind eq 'CMD-SHELL';
    my ( $out, $ok ) = exec_line( $dev, $d, $name, $c, $line );
    $c->{health_log} = $out if defined $out && length $out;
    delete $c->{health_log} if $ok;
    return $ok ? 'healthy' : 'unhealthy';
}

# --- exec im Container ---------------------------------------------------------------


sub exec_line {
    my ( $dev, $d, $name, $c, $line ) = @_;
    my @w = eval { Langertha::Holmgang::Shell::shell_words($line) };
    return ( "sh: syntax error", 0 ) if $@;
    my @seq = ( [] );
    for my $t (@w) {
        if ( ref $t && $t->{op} =~ /\A(;|&&|\|\|)\z/ ) { push @seq, $t->{op}, [] }
        elsif ( ref $t && $t->{op} eq '|' ) { push @{ $seq[-1] }, '|' }
        elsif ( ref $t ) { }
        else { push @{ $seq[-1] }, $t }
    }
    my ( @out, $ok ) = ();
    $ok = 1;
    my $op = ';';
    while (@seq) {
        my $cmd = shift @seq;
        if ( @$cmd && !( $op eq '&&' && !$ok ) && !( $op eq '||' && $ok ) ) {
            my @argv = @$cmd;
            my $cut = 0;
            for my $i ( 0 .. $#argv ) { if ( $argv[$i] eq '|' ) { $cut = $i; last } }
            @argv = @argv[ 0 .. $cut - 1 ] if $cut;
            my ( $o, $k ) = _exec( $dev, $d, $name, $c, \@argv );
            push @out, $o if defined $o && length $o;
            $ok = $k;
        }
        $op = shift @seq // ';';
    }
    return ( join( "\n", @out ), $ok ? 1 : 0 );
}

sub _exec {
    my ( $dev, $d, $name, $c, $argv ) = @_;
    my $img = _image( $d, $c->{image} ) || {};
    my @a = @$argv;
    my $cmd = shift @a // return ( '', 1 );
    if ( $cmd eq 'sh' || $cmd eq 'bash' || $cmd eq '/bin/sh' ) {
        my ($i) = grep { $a[$_] eq '-c' } 0 .. $#a;
        return exec_line( $dev, $d, $name, $c, _expand( $a[ $i + 1 ] // '', _env_of( $c, $img ) ) ) if defined $i;    # die Shell im Container ersetzt $VAR
        _gap("docker exec $cmd (interaktiv)");
        return ( '', 0 );
    }
    return ( '', 1 ) if $cmd eq 'true';
    return ( '', 0 ) if $cmd eq 'false';
    return ( '', ( $a[0] // 0 ) == 0 ? 1 : 0 ) if $cmd eq 'exit';
    my %tools = map { $_ => 1 } @{ $img->{tools} || [] }, qw( env printenv cat id echo ls ),
        ( grep { $_ == 5432 } @{ $img->{listens} || [] } ) ? 'psql' : ();
    ( my $base = $cmd ) =~ s{.*/}{};
    return ( "OCI runtime exec failed: exec failed: unable to start container process: exec: \"$cmd\": executable file not found in \$PATH: unknown", 0 )
        unless $tools{$base};
    my $env = _env_of( $c, $img );
    if ( $base eq 'env' || $base eq 'printenv' ) {
        return ( $env->{ $a[0] } // '', defined $env->{ $a[0] } ? 1 : 0 ) if $base eq 'printenv' && @a;
        return ( join( "\n", map {"$_=$env->{$_}"} sort keys %$env ), 1 );
    }
    if ( $base eq 'echo' ) { return ( join( ' ', @a ), 1 ) }
    if ( $base eq 'id' ) { my ( $u, $g ) = _uid_of( $c, $img ); return ( "uid=$u gid=$g", 1 ) }
    if ( $base eq 'cat' || $base eq 'ls' ) {
        my ($p) = grep { !/\A-/ } @a;
        return ( '', 1 ) unless defined $p;
        my $mt = _mount_at( $c, $p );
        if ( $mt && $mt->{type} eq 'bind' ) {
            my $hp = $mt->{source} . substr( $p, length $mt->{target} );
            my $t = _text( $dev, $hp );
            return ( "$base: $p: Permission denied", 0 ) if defined $t && $base eq 'cat' && !_readable( $dev, $c, $img, $hp );
            return ( $base eq 'cat' ? ( $t =~ s/\n\z//r ) : ( $p =~ s{.*/}{}r ), 1 ) if defined $t;
            return ( '', 1 ) if $base eq 'ls' && _L()->can('_is_dir')->( $dev, $hp );
            return ( "$base: $p: No such file or directory", 0 );
        }
        my ( $kind, $v ) = _container_fs( $dev, $d, $name, $c, $img, $p );
        if ( defined $kind ) {
            return ( $kind eq 'dir' ? join( "\n", @$v ) : $p =~ s{.*/}{}r, 1 ) if $base eq 'ls';
            return ( "cat: $p: Is a directory", 0 ) if $kind eq 'dir';
            return ( $v =~ s/\n\z//r, 1 );
        }
        if ( $p =~ m{\A/proc/} ) { _gap("docker exec $name $base $p"); return ( '', 0 ) }
        return ( "$base: " . ( $base eq 'ls' ? "cannot access '$p'" : $p ) . ': No such file or directory', 0 );
    }
    if ( $base eq 'psql' ) { return _psql( $d, $name, $c, $img, \@a ) }
    if ( $base eq 'pg_isready' ) {
        my %o;
        for ( my $i = 0; $i < @a; $i++ ) { $o{ $a[$i] } = $a[ $i + 1 ] if $a[$i] =~ /\A-[hpUd]\z/ }
        my $h = $o{-h} // 'localhost';
        my $p = $o{-p} // 5432;
        my $ok = _reach( $d, $name, $c, $img, $h, $p );
        return ( "$h:$p - " . ( $ok ? 'accepting connections' : 'no response' ), $ok ? 1 : 0 );
    }
    if ( $base eq 'curl' || $base eq 'wget' ) {
        Langertha::Holmgang::Sim::Linux::_part(q{Http});
        my ($url) = grep { m{\Ahttps?://} } @a;
        return ( $base eq 'curl' ? 'curl: no URL specified!' : 'wget: missing URL', 0 ) unless defined $url;
        my $u = Langertha::Holmgang::Sim::Linux::Http::parse_url($url) // return ( "$base: bad url", 0 );
        my $res = container_request( $dev, $d, $name, $c, $u );
        my $fail = $base eq 'curl'
            ? ( grep {/\A-\w*f/} @a ) : 1;
        if ( !$res ) {
            return $base eq 'curl' ? ( "curl: (7) Failed to connect to $u->{host} port $u->{port} after 0 ms: Couldn't connect to server", 0 )
                : ( "wget: can't connect to remote host: Connection refused", 0 );
        }
        if ( $res->{unresolved} ) {
            return $base eq 'curl' ? ( "curl: (6) Could not resolve host: $u->{host}", 0 ) : ( "wget: bad address '$u->{host}'", 0 );
        }
        my $st = $res->{status} // 200;
        if ( $st >= 400 && $fail ) {
            return $base eq 'curl' ? ( "curl: (22) The requested URL returned error: $st", 0 ) : ( "wget: server returned error: HTTP/1.1 $st", 0 );
        }
        my $spider = grep { $_ eq '--spider' } @a;
        my $quiet = grep { /\A-\w*q/ || $_ eq '--quiet' || /\A-\w*s/ } @a;
        return ( $spider ? ( $quiet ? '' : 'remote file exists' ) : ( $res->{body} // '' ) =~ s/\n\z//r, 1 );
    }
    if ( $base eq 'redis-cli' ) { return _reach( $d, $name, $c, $img, 'localhost', 6379 ) ? ( 'PONG', 1 ) : ( 'Could not connect to Redis at 127.0.0.1:6379: Connection refused', 0 ) }
    if ( $base eq 'nc' ) {
        my @x = grep { !/\A-/ } @a;
        return _reach( $d, $name, $c, $img, $x[0] // 'localhost', $x[1] // 0 ) ? ( '', 1 ) : ( '', 0 );
    }
    _gap("docker exec $name $base");
    return ( '', 0 );
}

sub _readable {
    my ( $dev, $c, $img, $hp ) = @_;
    my ( $uid, $gid ) = _uid_of( $c, $img );
    return 1 if $uid =~ /\A0\z|\Aroot\z/;
    my $e = _L()->can('_file_entry')->( $dev, $hp ) or return 0;
    my $mode = oct( $e->{mode} // '0644' );
    my $L = _L();
    return ( $mode >> 6 ) & 4 ? 1 : 0 if $L->can('_uid')->( $dev, $e->{owner} // 'root' ) == $uid;
    return ( $mode >> 3 ) & 4 ? 1 : 0 if $L->can('_gid')->( $dev, $e->{group} // 'root' ) == $gid;
    return $mode & 4 ? 1 : 0;
}

my @ROOT = qw( bin boot dev etc home lib media mnt opt proc root run sbin srv sys tmp usr var );
my @BIN  = qw( cat chmod chown cp date echo grep hostname id ln ls mkdir mv ps pwd rm sed sh sleep tail tar touch uname );
my @PG   = qw( PG_VERSION base global pg_commit_ts pg_dynshmem pg_hba.conf pg_ident.conf pg_logical pg_multixact pg_notify
    pg_replslot pg_serial pg_snapshots pg_stat pg_stat_tmp pg_subtrans pg_tblspc pg_twophase pg_wal pg_xact postgresql.auto.conf
    postgresql.conf postmaster.opts postmaster.pid );

# Dateien im Container, die nicht vom Host eingehaengt sind: ( 'file', text ) | ( 'dir', [namen] ) | ()
sub _container_fs {
    my ( $dev, $d, $name, $c, $img, $p ) = @_;
    $p =~ s{/+\z}{} if length $p > 1;
    my $ip = '172.18.0.' . ( 1 + ( $c->{seq} // 1 ) );
    if ( $p eq '/etc/hosts' ) {
        my $x = $c->{config}{extra_hosts};
        my @eh = ref $x eq 'HASH' ? map {"$x->{$_}\t$_"} sort keys %$x : map { /\A([^:=]+)[:=](.+)\z/ ? "$2\t$1" : () } @{ $x || [] };
        s/\Ahost-gateway\t/172.17.0.1\t/ for @eh;
        return ( file => join( "\n", "127.0.0.1\tlocalhost", "::1\tlocalhost ip6-localhost ip6-loopback", @eh, "$ip\t" . _id( $name, $c->{seq} ) ) . "\n" );
    }
    return ( file => "# Generated by Docker Engine.\n# This file can be edited; Docker Engine will not make further changes once it\n# has been modified.\n\nnameserver 127.0.0.11\noptions ndots:0\n" )
        if $p eq '/etc/resolv.conf';
    if ( $p eq '/etc/os-release' ) {
        return ( file => ( $img->{os} // '' ) =~ /alpine/i
            ? qq{NAME="Alpine Linux"\nID=alpine\nVERSION_ID=3.20.3\nPRETTY_NAME="Alpine Linux v3.20"\n}
            : qq{PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"\nNAME="Debian GNU/Linux"\nVERSION_ID="12"\nID=debian\n} );
    }
    return ( dir => [@ROOT] ) if $p eq '/';
    return ( dir => [ sort { $a cmp $b } keys %{ { map { $_ => 1 } @BIN, @{ $img->{tools} || [] } } } ] ) if $p =~ m{\A/(?:usr/)?(?:local/)?s?bin\z};
    # Datenverzeichnis einer Datenbank: an der Stelle des Images oder in einem eingehaengten Volume mit Daten
    if ( defined $img->{data_path} ) {
        my ($base) = grep { $p eq $_ || index( $p, "$_/" ) == 0 } $img->{data_path}, map { $_->{target} } grep { $_->{type} eq 'volume' } @{ $c->{config}{volumes} || [] };
        if ( defined $base ) {
            my $mt = _mount_at( $c, $base );
            my $data = $mt && $mt->{type} eq 'volume' && !$mt->{anonymous} ? ( $d->{volumes}{ $mt->{source} } || {} )->{data} : undef;
            $data //= $base eq $img->{data_path} ? $c->{data} : undef;
            return () unless defined $data;
            my $rest = substr( $p, length $base );
            return ( dir => [@PG] ) if $rest eq '';
            return ( file => ( ( $img->{version} // '16' ) =~ /\A(\d+)/ )[0] . "\n" ) if $rest eq '/PG_VERSION';
            return ( dir => [qw( 1 4 5 16384 )] ) if $rest eq '/base';
        }
    }
    return ();
}

# psql im Container: Tabellen und Zaehlungen aus psql des Images, leere Datenbank ohne Daten
sub _psql {
    my ( $d, $name, $c, $img, $av ) = @_;
    my @a = @$av;
    my ( @sql, $list );
    for ( my $i = 0; $i < @a; $i++ ) {
        if    ( $a[$i] eq '-c' || $a[$i] eq '--command' ) { push @sql, $a[ ++$i ] }
        elsif ( $a[$i] =~ /\A-[Udh]\z/ ) { $i++ }
        elsif ( $a[$i] eq '-l' || $a[$i] eq '--list' ) { $list = 1 }
    }
    return ( 'psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory', 0 )
        unless $c->{status} eq 'running' && grep { $_ == 5432 } @{ $img->{listens} || [] };
    my $spec = $img->{psql} || {};
    my $leer = !defined $c->{data} || $c->{data} eq ( $img->{init_data} // 'leer' );
    my @t = $leer ? () : @{ $spec->{tables} || [] };
    my $db = $spec->{database} // 'postgres';
    my @out;
    if ($list) { push @out, '                                  List of databases', ' Name      | Owner    | Encoding', '-----------+----------+----------',
        map {" $_ | postgres | UTF8"} 'postgres', ( $leer ? () : $db ), 'template0', 'template1' }
    for my $q (@sql) {
        if ( $q =~ /\A\s*\\l\s*\z/ ) { push @out, map {" $_ | postgres | UTF8"} 'postgres', ( $leer ? () : $db ), 'template0', 'template1'; next }
        if ( $q =~ /\A\s*\\dt\b/ ) {
            push @out, @t ? ( '        List of relations', ' Schema |   Name    | Type  | Owner', map {" public | $_ | table | postgres"} @t ) : 'Did not find any relations.';
            next;
        }
        if ( $q =~ /\A\s*select\s+count\(\*\)\s+from\s+(?:public\.)?"?(\w+)"?\s*;?\s*\z/i ) {
            my $tb = $1;
            return ( join( "\n", @out, "ERROR:  relation \"$tb\" does not exist", "LINE 1: select count(*) from $tb" ), 0 ) unless grep { $_ eq $tb } @t;
            push @out, ' count ', '-------', sprintf( ' %5d', ( $spec->{counts} || {} )->{$tb} // 0 ), '(1 row)';
            next;
        }
        if ( $q =~ /\A\s*select\s+1\s*;?\s*\z/i ) { push @out, ' ?column? ', '----------', '        1', '(1 row)'; next }
        if ( $q =~ /\A\s*select\s+current_user\s*;?\s*\z/i ) { push @out, ' current_user ', '--------------', ' ' . ( $spec->{user} // 'postgres' ), '(1 row)'; next }
        if ( $q =~ /\A\s*select\s+version\(\)/i ) { push @out, ' PostgreSQL ' . ( $img->{version} // '16.4' ) . ' on x86_64-pc-linux-gnu'; next }
        _gap("docker exec $name psql -c $q");
        return ( join( "\n", @out ), 0 );
    }
    return ( join( "\n", @out ), 1 );
}

# Lauscht h:p aus Sicht des Containers?
sub _reach {
    my ( $d, $name, $c, $img, $h, $p ) = @_;
    if ( $h eq 'localhost' || $h eq '127.0.0.1' ) { return $c->{status} eq 'running' && grep { $_ == $p } @{ $img->{listens} || [] } }
    my ( $pn, $pc ) = lookup( $d, $name, $h ) or return 0;
    my $pimg = _image( $d, $pc->{image} ) || {};
    return $pc->{status} eq 'running' && grep { $_ == $p } @{ $pimg->{listens} || [] };
}


# HTTP aus einem Container an einen Dienst (oder sich selbst)
sub container_request {
    my ( $dev, $d, $name, $c, $u ) = @_;
    my ( $tn, $tc );
    if ( $u->{host} eq 'localhost' || $u->{host} eq '127.0.0.1' ) { ( $tn, $tc ) = ( $name, $c ) }
    else {
        ( $tn, $tc ) = lookup( $d, $name, $u->{host} );
        return { unresolved => 1 } unless $tc;
    }
    my $img = _image( $d, $tc->{image} ) || {};
    return undef unless $tc->{status} eq 'running' && grep { $_ == $u->{port} } @{ $img->{listens} || [] };
    Langertha::Holmgang::Sim::Linux::_part(q{Http});
    return Langertha::Holmgang::Sim::Linux::Http::respond( $img->{http} || {}, { method => 'GET', path => $u->{path},
        headers => { host => $u->{host} . ":$u->{port}" } }, $tn );
}

# --- HTTP von aussen (veroeffentlichte Ports) ---------------------------------------


sub serve {
    my ( $state, $to, $req, $from, $depth ) = @_;
    my $dev = $state->{$to};
    my $d = $dev->{docker};
    ensure( $dev, $to, $state );
    my $local = defined $from && $from eq $to;
    for my $n ( sort keys %{ $d->{containers} || {} } ) {
        my $c = $d->{containers}{$n};
        next unless $c->{status} eq 'running';
        for my $p ( @{ $c->{config}{ports} || [] } ) {
            next unless length $p->{published} && $p->{published} == $req->{port};
            next if $p->{host_ip} =~ /\A127\./ && !$local;
            next unless $p->{host_ip} eq '0.0.0.0' || $p->{host_ip} eq $req->{ip} || ( $local && $p->{host_ip} =~ /\A127\./ && $req->{ip} =~ /\A127\./ );
            my $img = _image( $d, $c->{image} ) || {};
            return { error => '(56) Recv failure: Connection reset by peer', code => 56 }
                unless grep { $_ == $p->{target} } @{ $img->{listens} || [] };
            Langertha::Holmgang::Sim::Linux::_part(q{Http});
            return Langertha::Holmgang::Sim::Linux::Http::respond( $img->{http} || {}, $req, "$to $n" );
        }
    }
    return undef;
}


sub ss_lines {
    my ($dev) = @_;
    my $d = $dev->{docker};
    my ( @l, $pid );
    $pid = 4100;
    for my $n ( sort keys %{ $d->{containers} || {} } ) {
        my $c = $d->{containers}{$n};
        next unless $c->{status} eq 'running';
        for my $p ( grep { length $_->{published} } @{ $c->{config}{ports} || [] } ) {
            push @l, sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', 'tcp', 'LISTEN', 0, 4096, "$p->{host_ip}:$p->{published}", '0.0.0.0:*',
                'users:(("docker-proxy",pid=' . $pid++ . ',fd=4))' );
        }
    }
    return @l;
}

# --- Kommandozeile ---------------------------------------------------------------------


sub docker {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my $d = $dev->{docker};
    ensure( $dev, $ctx->{host}, $ctx->{state} );
    my @a = @$av;
    my $sub = shift @a // return ( "Usage:  docker [OPTIONS] COMMAND\n\nA self-sufficient runtime for containers", 0 );
    return _compose( $dev, \@a, $ctx ) if $sub eq 'compose';
    if ( $sub eq 'version' || $sub eq '--version' || $sub eq '-v' ) { return ( 'Docker version 26.1.5, build a72d7cd', 1 ) }
    if ( $sub eq 'container' ) { $sub = shift(@a) // ''; $sub = 'ps' if $sub eq 'ls' }
    if ( $sub eq 'ps' ) { return _docker_ps( $d, \@a ) }
    if ( $sub eq 'logs' ) { return _docker_logs( $d, \@a, 0 ) }
    if ( $sub eq 'inspect' ) { return _inspect( $d, \@a ) }
    if ( $sub =~ /\A(?:restart|stop|start|rm|kill)\z/ ) { return _docker_lifecycle( $dev, $d, $sub, \@a, $ctx ) }
    if ( $sub eq 'exec' ) {
        my @x = @a;
        while ( @x && $x[0] =~ /\A-/ ) { my $o = shift @x; shift @x if $o =~ /\A-(?:u|e|w|-user|-env|-workdir)\z/ }
        my $n = shift @x // return ( '"docker exec" requires at least 2 arguments.', 0 );
        my $c = $d->{containers}{$n} // ( map { $d->{containers}{$_} } grep { _id( $_, $d->{containers}{$_}{seq} ) =~ /\A\Q$n\E/ } keys %{ $d->{containers} } )[0];
        return ( "Error response from daemon: No such container: $n", 0 ) unless $c;
        return ( "Error response from daemon: container " . _id( $n, $c->{seq} ) . " is not running", 0 ) unless $c->{status} eq 'running';
        return _exec( $dev, $d, $n, $c, \@x );
    }
    if ( $sub eq 'volume' ) {
        my $v = shift @a // 'ls';
        if ( $v eq 'ls' ) {
            return ( join( "\n", sprintf( '%-10s%s', 'DRIVER', 'VOLUME NAME' ), map { sprintf( '%-10s%s', 'local', $_ ) } sort keys %{ $d->{volumes} || {} } ), 1 );
        }
        if ( $v eq 'inspect' ) {
            my @o;
            for my $n ( grep { !/\A-/ } @a ) {
                return ( "Error response from daemon: get $n: no such volume", 0 ) unless $d->{volumes}{$n};
                push @o, { Name => $n, Driver => 'local', Mountpoint => "/var/lib/docker/volumes/$n/_data", Scope => 'local',
                    Labels => { ( $d->{volumes}{$n}{project} ? ( 'com.docker.compose.project' => $d->{volumes}{$n}{project} ) : () ) } };
            }
            return ( $OUT_JSON->encode( \@o ) =~ s/\n\z//r, 1 );
        }
        if ( $v eq 'rm' ) {
            for my $n ( grep { !/\A-/ } @a ) {
                return ( "Error response from daemon: get $n: no such volume", 0 ) unless $d->{volumes}{$n};
                my ($user) = grep { grep { $_->{type} eq 'volume' && $_->{source} eq $n } @{ $d->{containers}{$_}{config}{volumes} || [] } } sort keys %{ $d->{containers} };
                return ( "Error response from daemon: remove $n: volume is in use - [" . _id( $user, $d->{containers}{$user}{seq} ) . "]", 0 ) if defined $user;
                delete $d->{volumes}{$n};
            }
            return ( join( "\n", grep { !/\A-/ } @a ), 1 );
        }
        return _gap("docker volume $v");
    }
    if ( $sub eq 'network' && ( $a[0] // 'ls' ) eq 'ls' ) {
        return ( join( "\n", sprintf( '%-14s %-24s %-8s %s', 'NETWORK ID', 'NAME', 'DRIVER', 'SCOPE' ),
            map { sprintf( '%-14s %-24s %-8s %s', substr( Digest::SHA::sha1_hex($_), 0, 12 ), $_, 'bridge', 'local' ) } 'bridge', 'host', sort keys %{ $d->{networks} || {} } ), 1 );
    }
    if ( $sub eq 'images' || ( $sub eq 'image' && ( $a[0] // '' ) eq 'ls' ) ) {
        return ( join( "\n", sprintf( '%-44s %-12s %-14s', 'REPOSITORY', 'TAG', 'IMAGE ID' ),
            map { my ( $r, $t ) = /\A(.+):([^:]+)\z/; sprintf( '%-44s %-12s %-14s', $r, $t, _img_id( $_, $d->{images}{$_} ) ) } sort keys %{ $d->{images} || {} } ), 1 );
    }
    if ( $sub eq 'pull' ) {
        my ($ref) = grep { !/\A-/ } @a;
        return ( '"docker pull" requires exactly 1 argument.', 0 ) unless defined $ref;
        $ref .= ':latest' unless $ref =~ m{:[^/]+\z};
        my $reg = ( $d->{registry} || {} )->{$ref};
        return ( "Status: Image is up to date for $ref", 1 )
            if _image( $d, $ref ) && ( !$reg || $JSON->encode($reg) eq $JSON->encode( _image( $d, $ref ) ) );
        my ( $ok, $e ) = _pull( $d, $ref );
        return ( $e, 0 ) unless $ok;
        return ( "Status: Downloaded newer image for $ref", 1 );
    }
    if ( $sub eq 'stats' ) {
        my @n = grep { $d->{containers}{$_}{status} eq 'running' } sort keys %{ $d->{containers} };
        return ( join( "\n", sprintf( '%-14s %-24s %-8s %-22s %-7s', 'CONTAINER ID', 'NAME', 'CPU %', 'MEM USAGE / LIMIT', 'MEM %' ),
            map { my $c = $d->{containers}{$_}; my $lim = $c->{mem_limit_bytes};
                sprintf( '%-14s %-24s %-8s %-22s %-7s', _id( $_, $c->{seq} ), $_, '0.42%', '96.3MiB / ' . ( $lim ? sprintf( '%.0fMiB', $lim / 1048576 ) : '3.84GiB' ),
                    $lim ? sprintf( '%.2f%%', 96.3 * 1048576 / $lim * 100 ) : '2.45%' ) } @n ), 1 );
    }
    if ( $sub eq 'info' ) {
        my @c = values %{ $d->{containers} || {} };
        return ( join( "\n", 'Client: Docker Engine - Community', ' Version:    26.1.5', '', 'Server:',
            ' Containers: ' . scalar(@c), '  Running: ' . scalar( grep { $_->{status} eq 'running' } @c ),
            '  Stopped: ' . scalar( grep { $_->{status} ne 'running' } @c ), ' Images: ' . scalar( keys %{ $d->{images} || {} } ),
            ' Server Version: 26.1.5', ' Storage Driver: overlay2', ' Logging Driver: json-file', ' Cgroup Driver: systemd',
            ' Kernel Version: 6.1.0-26-amd64', ' Operating System: Debian GNU/Linux 12 (bookworm)', ' Docker Root Dir: /var/lib/docker' ), 1 );
    }
    return _gap("docker $sub") if $sub =~ /\A(?:run|build|cp|top|events|attach|system|login|tag|push|commit|save|load|update)\z/;
    return ( "docker: '$sub' is not a docker command.\nSee 'docker --help'", 0 );
}

sub _status_text {
    my ($c) = @_;
    return 'Up 2 hours' . ( defined $c->{health} ? " ($c->{health})" : '' ) if $c->{status} eq 'running' && $c->{initial};
    return 'Up 3 seconds' . ( defined $c->{health} ? " ($c->{health})" : '' ) if $c->{status} eq 'running';
    return "Restarting (" . ( $c->{exit_code} // 1 ) . ") 4 seconds ago" if $c->{status} eq 'restarting';
    return "Exited ($c->{exit_code}) 5 seconds ago" if $c->{status} eq 'exited';
    return 'Created';
}

sub _ports_text {
    my ( $c, $img ) = @_;
    my @p;
    my %pub;
    for my $p ( @{ $c->{config}{ports} || [] } ) {
        next unless length $p->{published};
        $pub{ $p->{target} } = 1;
        push @p, ( $p->{host_ip} eq '0.0.0.0' ? '0.0.0.0' : $p->{host_ip} ) . ":$p->{published}->$p->{target}/tcp" if $c->{status} eq 'running';
    }
    push @p, map {"$_/tcp"} grep { !$pub{$_} } @{ $img->{listens} || [] } if $c->{status} eq 'running';
    return join ', ', @p;
}

# Zeile eines Containers fuer ps --format (Felder wie docker/compose)
sub _ps_row {
    my ( $d, $n ) = @_;
    my $c = $d->{containers}{$n};
    return {
        ID => _id( $n, $c->{seq} ), Names => $n, Name => $n, Image => $c->{image}, Command => '"docker-entrypoint.s…"',
        Service => $c->{service}, Project => $c->{project}, Status => _status_text($c), State => $c->{status},
        Health => $c->{health} // '', Ports => _ports_text( $c, _image( $d, $c->{image} ) || {} ),
        CreatedAt => '2026-10-24 06:00:00 +0200 CEST', RunningFor => 'About an hour ago', ExitCode => $c->{exit_code} // 0,
        Labels => "com.docker.compose.project=$c->{project},com.docker.compose.service=$c->{service}",
    };
}


sub gofmt {
    my ( $fmt, $rows ) = @_;
    my $table = $fmt =~ s/\Atable\s+//;
    $fmt =~ s/\\t/\t/g;
    $fmt =~ s/\\n/\n/g;
    my $tree = eval { _tpl_parse($fmt) };
    if ( !$tree ) { push @Langertha::Holmgang::Sim::Linux::GAPS, "--format $fmt"; return '' }
    my @out = map { _tpl_run( $tree, $_, {} ) } @$rows;
    if ($table) {
        ( my $h = $fmt ) =~ s{\{\{\s*(?:json\s+)?\.((?:\w+\.)*(\w+))\s*\}\}}{uc $2}ge;
        unshift @out, $h;
    }
    return join "\n", @out;
}

# Go-Vorlagen (Teilmenge): Text, {{.A.B}}, {{json X}}, {{X}} mit $k/$v/., {{range [$k, $v :=] X}}…{{end}},
# {{if X}}…{{else}}…{{end}}, {{println …}}, {{index X "k"}}
sub _tpl_parse {
    my ($s) = @_;
    my @stack = ( [] );
    while ( length $s ) {
        if ( $s =~ s/\A\{\{-?\s*(.*?)\s*-?\}\}//s ) {
            my $a = $1;
            if ( $a =~ /\Arange\s+(?:\$(\w+)\s*,\s*\$(\w+)\s*:=\s*|\$(\w+)\s*:=\s*)?(.+)\z/ ) {
                my $n = { op => 'range', k => $1, v => $2 // $3, x => $4, body => [] };
                push @{ $stack[-1] }, $n;
                push @stack, $n->{body};
            }
            elsif ( $a =~ /\Aif\s+(.+)\z/ ) {
                my $n = { op => 'if', x => $1, body => [], else => [] };
                push @{ $stack[-1] }, $n;
                push @stack, $n->{body};
                $n->{_if} = 1;
            }
            elsif ( $a eq 'else' ) {
                pop @stack;
                my ($n) = grep { ref $_ eq 'HASH' && $_->{op} eq 'if' } reverse @{ $stack[-1] };
                die "else ohne if\n" unless $n;
                push @stack, $n->{else};
            }
            elsif ( $a eq 'end' ) { die "end zu viel\n" if @stack == 1; pop @stack }
            else { push @{ $stack[-1] }, { op => 'expr', x => $a } }
        }
        elsif ( $s =~ s/\A((?:(?!\{\{).)+)//s ) { push @{ $stack[-1] }, $1 }
        else { die "kaputt\n" }
    }
    die "end fehlt\n" if @stack > 1;
    return $stack[0];
}

sub _tpl_val {
    my ( $x, $dot, $vars ) = @_;
    $x =~ s/\A\s+|\s+\z//g;
    return $1 if $x =~ /\A"(.*)"\z/;
    my ( $root, $path );
    if    ( $x =~ /\A\$(\w+)((?:\.\w+)*)\z/ ) { ( $root, $path ) = ( $vars->{$1}, $2 ) }
    elsif ( $x =~ /\A\.((?:\w+\.?)*)\z/ )    { ( $root, $path ) = ( $dot, ".$1" ) }
    else { die "unbekannt: $x\n" }
    my $v = $root;
    for my $k ( grep { length } split /\./, $path // '' ) { $v = ref $v eq 'HASH' ? $v->{$k} : undef }
    return $v;
}

sub _tpl_text {
    my ($v) = @_;
    return '<no value>' unless defined $v;
    return $v ? 'true' : 'false' if JSON::MaybeXS::is_bool($v);
    return $v unless ref $v;
    return '[' . join( ' ', map { _tpl_text($_) } @$v ) . ']' if ref $v eq 'ARRAY';
    return 'map[' . join( ' ', map { "$_:" . _tpl_text( $v->{$_} ) } sort keys %$v ) . ']';
}

sub _tpl_expr {
    my ( $x, $dot, $vars ) = @_;
    return $JSON->encode( _tpl_val( $1, $dot, $vars ) // undef ) if $x =~ /\Ajson\s+(.+)\z/;
    if ( $x =~ /\Aprintln(?:\s+(.*))?\z/ ) { my @a = defined $1 ? split( ' ', $1 ) : (); return join( ' ', map { _tpl_text( _tpl_val( $_, $dot, $vars ) ) } @a ) . "\n" }
    if ( $x =~ /\Aindex\s+(\S+)\s+"([^"]*)"\z/ ) { my $m = _tpl_val( $1, $dot, $vars ); return _tpl_text( ref $m eq 'HASH' ? $m->{$2} : undef ) }
    return _tpl_text( _tpl_val( $x, $dot, $vars ) );
}

sub _tpl_run {
    my ( $tree, $dot, $vars ) = @_;
    my $out = '';
    for my $n (@$tree) {
        if ( !ref $n ) { $out .= $n; next }
        if ( $n->{op} eq 'expr' ) { $out .= _tpl_expr( $n->{x}, $dot, $vars ); next }
        if ( $n->{op} eq 'if' ) {
            my $v = _tpl_val( $n->{x}, $dot, $vars );
            my $t = ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? %$v : $v;
            $out .= _tpl_run( $t ? $n->{body} : $n->{else}, $dot, $vars );
            next;
        }
        my $v = _tpl_val( $n->{x}, $dot, $vars );
        my @it = ref $v eq 'HASH' ? map { [ $_, $v->{$_} ] } sort keys %$v : ref $v eq 'ARRAY' ? map { [ $_, $v->[$_] ] } 0 .. $#$v : ();
        for my $i (@it) {
            my %v2 = %$vars;
            if ( defined $n->{k} ) { $v2{ $n->{k} } = $i->[0]; $v2{ $n->{v} } = $i->[1] }
            elsif ( defined $n->{v} ) { $v2{ $n->{v} } = $i->[1] }
            $out .= _tpl_run( $n->{body}, $i->[1], \%v2 );
        }
    }
    return $out;
}

sub _ps_filter {
    my ( $d, $n, $filters ) = @_;
    my $c = $d->{containers}{$n};
    for my $f (@$filters) {
        my ( $k, $v ) = split /=/, $f, 2;
        $v //= '';
        if    ( $k eq 'name' )   { return 0 unless $n =~ /$v/ }
        elsif ( $k eq 'status' ) { return 0 unless $c->{status} eq $v || ( $v eq 'running' && 0 ) }
        elsif ( $k eq 'health' ) { return 0 unless ( $c->{health} // 'none' ) eq $v }
        elsif ( $k eq 'label' )  {
            my ( $lk, $lv ) = split /=/, $v, 2;
            my %l = ( 'com.docker.compose.project' => $c->{project}, 'com.docker.compose.service' => $c->{service} );
            return 0 unless exists $l{$lk} && ( !defined $lv || $l{$lk} eq $lv );
        }
        elsif ( $k eq 'ancestor' ) { return 0 unless index( $c->{image}, $v ) == 0 }
        else { push @Langertha::Holmgang::Sim::Linux::GAPS, "docker ps --filter $f" }
    }
    return 1;
}

sub _docker_ps {
    my ( $d, $a ) = @_;
    my ( $all, $quiet, $fmt, @filters );
    my @x = @$a;
    while (@x) {
        my $v = shift @x;
        if    ( $v eq '-a' || $v eq '--all' ) { $all = 1 }
        elsif ( $v eq '-q' || $v eq '--quiet' ) { $quiet = 1 }
        elsif ( $v eq '-aq' || $v eq '-qa' ) { $all = $quiet = 1 }
        elsif ( $v eq '--format' ) { $fmt = shift @x }
        elsif ( $v =~ /\A--format=(.*)\z/s ) { $fmt = $1 }
        elsif ( $v eq '-f' || $v eq '--filter' ) { push @filters, shift(@x) // '' }
        elsif ( $v =~ /\A--filter=(.*)\z/ ) { push @filters, $1 }
        elsif ( $v eq '--no-trunc' || $v eq '-s' || $v eq '--size' ) { }
        else { return ( "unknown flag: $v\nSee 'docker ps --help'.", 0 ) }
    }
    my @n = grep { ( $all || $d->{containers}{$_}{status} =~ /\A(?:running|restarting)\z/ ) && _ps_filter( $d, $_, \@filters ) }
        sort keys %{ $d->{containers} };
    return ( join( "\n", map { _id( $_, $d->{containers}{$_}{seq} ) } @n ), 1 ) if $quiet;
    return ( gofmt( $fmt, [ map { _ps_row( $d, $_ ) } @n ] ), 1 ) if defined $fmt;
    my @l = ( sprintf( '%-14s %-44s %-24s %-16s %-28s %-36s %s', 'CONTAINER ID', 'IMAGE', 'COMMAND', 'CREATED', 'STATUS', 'PORTS', 'NAMES' ) );
    for (@n) {
        my $c = $d->{containers}{$_};
        push @l, sprintf( '%-14s %-44s %-24s %-16s %-28s %-36s %s', _id( $_, $c->{seq} ), $c->{image}, '"docker-entrypoint.s…"',
            'About an hour ago', _status_text($c), _ports_text( $c, _image( $d, $c->{image} ) || {} ), $_ );
    }
    return ( join( "\n", @l ), 1 );
}

sub _logs_of {
    my ( $d, $n ) = @_;
    my $c = $d->{containers}{$n};
    my $img = _image( $d, $c->{image} ) || {};
    my @l;
    push @l, @{ $c->{early_error} || [] };
    if ( $c->{status} eq 'running' ) { push @l, map { _expand( $_, _env_of( $c, $img ) ) } @{ $img->{logs} || [] } }
    elsif ( $c->{error} ) { push @l, ( @{ $c->{error} } ) x ( $c->{status} eq 'restarting' ? 3 : 1 ) }
    return @l;
}

sub _docker_logs {
    my ( $d, $a ) = @_;
    my @x = @$a;
    my ( $tail, $n );
    while (@x) {
        my $v = shift @x;
        if    ( $v eq '--tail' || $v eq '-n' ) { $tail = shift @x }
        elsif ( $v =~ /\A--tail=(\d+)\z/ ) { $tail = $1 }
        elsif ( $v eq '-f' || $v eq '--follow' ) { _gap('docker logs -f'); return ( '', 0 ) }
        elsif ( $v =~ /\A-/ ) { }
        else { $n = $v }
    }
    return ( '"docker logs" requires exactly 1 argument.', 0 ) unless defined $n;
    return ( "Error response from daemon: No such container: $n", 0 ) unless $d->{containers}{$n};
    my @l = _logs_of( $d, $n );
    @l = @l[ ( @l > $tail ? @l - $tail : 0 ) .. $#l ] if defined $tail && $tail =~ /\A\d+\z/;
    return ( join( "\n", @l ), 1 );
}

sub _inspect_data {
    my ( $d, $n ) = @_;
    my $c = $d->{containers}{$n};
    my $img = _image( $d, $c->{image} ) || {};
    my $env = _env_of( $c, $img );
    return {
        Id => _id( $n, $c->{seq} ) . ( '0' x 52 ), Name => "/$n",
        State => { Status => $c->{status}, Running => $c->{status} eq 'running' ? _true() : _false(), Restarting => $c->{status} eq 'restarting' ? _true() : _false(),
            ExitCode => $c->{exit_code} // 0, Paused => _false(), OOMKilled => $c->{oom} ? _true() : _false(), Dead => _false(),
            Error => $c->{status} eq 'created' && $c->{start_error} ? $c->{start_error} : '',
            ( defined $c->{health} ? ( Health => { Status => $c->{health}, FailingStreak => $c->{health} eq 'healthy' ? 0 : 3,
                Log => [ { ExitCode => $c->{health} eq 'healthy' ? 0 : 1, Output => $c->{health_log} // '' } ] } ) : () ) },
        RestartCount => $c->{restart_count} // 0,
        Config => { Image => $c->{image}, Env => [ map {"$_=$env->{$_}"} sort keys %$env ], User => $c->{config}{user} // $img->{user} // '',
            Labels => { 'com.docker.compose.project' => $c->{project}, 'com.docker.compose.service' => $c->{service} },
            ( $c->{config}{healthcheck} ? ( Healthcheck => { Test => $c->{config}{healthcheck}{test} } ) : () ) },
        HostConfig => { RestartPolicy => { Name => $c->{config}{restart} }, PortBindings => { map { ( "$_->{target}/tcp" => [ { HostIp => $_->{host_ip} eq '0.0.0.0' ? '' : $_->{host_ip}, HostPort => $_->{published} } ] ) } grep { length $_->{published} } @{ $c->{config}{ports} } } },
        Mounts => [ map { { Type => $_->{type}, Source => $_->{type} eq 'bind' ? $_->{source} : "/var/lib/docker/volumes/$_->{source}/_data", Destination => $_->{target},
            ( $_->{type} eq 'volume' ? ( Name => $_->{source} ) : () ), RW => $_->{read_only} ? _false() : _true() } } @{ $c->{config}{volumes} } ],
        NetworkSettings => { Networks => { map { $_ => { Aliases => [ $n, $c->{service} ] } } @{ $c->{config}{networks} } },
            Ports => $c->{status} eq 'running'
                ? { map { ( "$_->{target}/tcp" => [ { HostIp => $_->{host_ip}, HostPort => $_->{published} } ] ) } grep { length $_->{published} } @{ $c->{config}{ports} } }
                : {} },
    };
}

sub _inspect {
    my ( $d, $a ) = @_;
    my @x = @$a;
    my ( $fmt, @names );
    while (@x) {
        my $v = shift @x;
        if    ( $v eq '-f' || $v eq '--format' ) { $fmt = shift @x }
        elsif ( $v =~ /\A--format=(.*)\z/s ) { $fmt = $1 }
        elsif ( $v =~ /\A-/ ) { }
        else { push @names, $v }
    }
    return ( '"docker inspect" requires at least 1 argument.', 0 ) unless @names;
    my @data;
    for my $n (@names) {
        if ( !$d->{containers}{$n} ) {
            if ( $d->{volumes}{$n} ) { push @data, { Name => $n, Driver => 'local', Mountpoint => "/var/lib/docker/volumes/$n/_data" }; next }
            return ( "Error: No such object: $n", 0 );
        }
        push @data, _inspect_data( $d, $n );
    }
    return ( $OUT_JSON->encode( \@data ) =~ s/\n\z//r, 1 ) unless defined $fmt;
    return ( gofmt( $fmt, \@data ), 1 );
}

sub _docker_lifecycle {
    my ( $dev, $d, $verb, $a, $ctx ) = @_;
    my @n = grep { !/\A-/ } @$a;
    my $force = grep { /\A-\w*f/ || $_ eq '--force' } @$a;
    return ( "\"docker $verb\" requires at least 1 argument.", 0 ) unless @n;
    my @out;
    for my $n (@n) {
        my $c = $d->{containers}{$n} or return ( "Error response from daemon: No such container: $n", 0 );
        if ( $verb eq 'rm' ) {
            return ( "Error response from daemon: cannot remove container \"/$n\": container is running: stop the container before removing or force remove", 0 )
                if $c->{status} eq 'running' && !$force;
            delete $d->{containers}{$n};
        }
        elsif ( defined( my $e = _lifecycle( $dev, $d, $n, $c, $verb, $ctx ) ) ) {
            _settle($dev);
            return ( join( "\n", @out, $e, "Error: failed to start containers: $n" ), 0 );
        }
        push @out, $n;
    }
    _settle($dev);
    return ( join( "\n", @out ), 1 );
}

sub _lifecycle {
    my ( $dev, $d, $n, $c, $verb, $ctx ) = @_;
    my $running = $c->{status} eq 'running' || $c->{status} eq 'restarting';
    if ( $verb eq 'stop' || $verb eq 'kill' ) {
        $c->{restarts}++ if $running;
        $c->{status} = 'exited';
        $c->{exit_code} = $verb eq 'kill' ? 137 : 0;
        delete $c->{health};
        return;
    }
    return undef if $verb eq 'start' && $running;
    $c->{restarts}++ if $running;
    my $e = _start( $dev, $d, $n, $c, {}, $ctx->{state}, $ctx->{host} );
    $c->{start_error} = $e if defined $e;
    delete $c->{start_error} unless defined $e;
    return $e;
}

# --- docker compose ---------------------------------------------------------------------

sub _compose {
    my ( $dev, $av, $ctx ) = @_;
    my $d = $dev->{docker};
    my @a = @$av;
    my ( @files, $proj, $pdir, $envf, @profiles );
    while ( @a && $a[0] =~ /\A-/ ) {
        my $x = shift @a;
        if    ( $x eq '-f' || $x eq '--file' ) { push @files, shift @a }
        elsif ( $x =~ /\A--file=(.+)\z/ ) { push @files, $1 }
        elsif ( $x eq '-p' || $x eq '--project-name' ) { $proj = shift @a }
        elsif ( $x eq '--project-directory' ) { $pdir = shift @a }
        elsif ( $x eq '--env-file' ) { $envf = shift @a }
        elsif ( $x eq '--profile' ) { push @profiles, shift @a }
        elsif ( $x eq '--ansi' || $x eq '--progress' ) { shift @a }
        elsif ( $x eq '-v' || $x eq '--version' ) { return ( 'Docker Compose version v2.29.7', 1 ) }
        else { return ( "unknown shorthand flag: '" . ( $x =~ s/\A-+//r ) . "' in $x", 0 ) }
    }
    my $verb = shift @a // return ( "Usage:  docker compose [OPTIONS] COMMAND", 0 );
    return ( 'Docker Compose version v2.29.7', 1 ) if $verb eq 'version';
    if ( $verb eq 'ls' ) {
        my %p;
        $p{ $_->{project} }{ $_->{status} eq 'running' ? 'running' : 'exited' }++ for values %{ $d->{containers} };
        return ( join( "\n", sprintf( '%-16s %-20s %s', 'NAME', 'STATUS', 'CONFIG FILES' ),
            map { my $pn = $_; my $pr = $d->{projects}{$pn} || {};
                sprintf( '%-16s %-20s %s', $pn, join( ', ', map {"$_($p{$pn}{$_})"} sort keys %{ $p{$pn} } ), ( $pr->{dir} // '' ) . '/compose.yaml' ) } sort keys %p ), 1 );
    }
    my $L = _L();
    @files = map { $L->can('cwd_path')->($_) } @files;
    $pdir = $L->can('cwd_path')->($pdir) if defined $pdir;
    $envf = $L->can('cwd_path')->($envf) if defined $envf;
    my $cwd = do { no warnings "once"; $Langertha::Holmgang::Sim::Linux::CWD_DIR } // "/root";
    my $dir = $pdir // ( @files ? ( $files[0] =~ m{\A(.*)/[^/]+\z} )[0] : $cwd );
    my $m = model( $dev, dir => $dir, files => \@files, project => $proj, env_file => $envf, profiles => \@profiles );
    # ohne Datei: Befehle, die mit dem Projektnamen auskommen (Labels)
    if ( $m->{error} && $m->{error} =~ /no configuration file/ ) {
        my $pn = $proj // ( $dir =~ m{([^/]+)\z} )[0] // '';
        if ( $verb =~ /\A(?:ps|logs|down|stop|start|restart|exec|top)\z/ && grep { $_->{project} eq $pn } values %{ $d->{containers} } ) {
            $m = { name => $pn, services => { map { $_->{service} => $_->{config} } grep { $_->{project} eq $pn } values %{ $d->{containers} } },
                warnings => [], nofile => 1 };
        }
    }
    my @warn = map {"WARN[0000] $_"} @{ $m->{warnings} || [] };
    return ( join( "\n", @warn, $m->{error} ), 0 ) if $m->{error};
    my $out = sub { my ( $lines, $ok ) = @_; return ( join( "\n", @warn, @$lines ), $ok ) };
    my ( %f, @svc );
    for my $x (@a) {
        if ( $x =~ /\A--?([\w-]+)(?:=(.*))?\z/ ) { $f{$1} = $2 // 1 }
        else { push @svc, $x }
    }
    for ( my $i = 0; $i < @a; $i++ ) {
        if ( $a[$i] =~ /\A(?:--tail|-n|--timeout|-t|--format|--scale|--pull|-e|--env|-u|--user|-w|--workdir|--index|--status|--filter)\z/ ) {
            ( my $k = $a[$i] ) =~ s/\A-+//;
            $f{$k} = $a[ $i + 1 ];
            @svc = grep { $_ ne ( $a[ $i + 1 ] // '' ) } @svc;
        }
    }
    if ( $verb eq 'config' ) {
        return $out->( [], 1 ) if $f{q} || $f{quiet};
        return $out->( [ sort keys %{ $m->{services} } ], 1 ) if $f{services};
        return $out->( [ sort keys %{ $m->{volumes} || {} } ], 1 ) if $f{volumes};
        return $out->( [ _config_yaml($m) ], 1 );
    }
    if ( $verb eq 'up' ) {
        if ( !( $f{d} || $f{detach} || $f{'wait'} ) ) { _gap('docker compose up (ohne -d, haengt im Vordergrund)'); return ( '', 0 ) }
        return $out->( [ 'no such service: ' . ( grep { !$m->{services}{$_} } @svc )[0] ], 0 ) if grep { !$m->{services}{$_} } @svc;
        if ( ( $f{pull} // '' ) eq 'always' ) {    # --pull always: erst ziehen, was die Registry neuer hat
            for my $s ( @svc ? @svc : sort keys %{ $m->{services} } ) {
                my $ref = $m->{services}{$s}{image} // next;
                _pull( $d, $ref ) if ( $d->{registry} || {} )->{$ref};
            }
        }
        my ( $l, $ok, $err ) = up( $dev, $m, { services => \@svc, force_recreate => $f{'force-recreate'}, no_deps => $f{'no-deps'},
            recreate_deps => $f{'always-recreate-deps'},
            remove_orphans => $f{'remove-orphans'} }, $ctx->{state}, $ctx->{host} );
        push @$l, $err if defined $err;
        $d->{projects}{ $m->{name} } //= { dir => $m->{dir} } unless $m->{nofile};
        return $out->( $l, $ok );
    }
    if ( $verb eq 'pull' ) {
        my @l;
        for my $s ( @svc ? @svc : sort keys %{ $m->{services} } ) {
            my $ref = $m->{services}{$s}{image} // next;
            push @l, " $s Pulling";
            if ( _image( $d, $ref ) && !( $d->{registry} || {} )->{$ref} ) { push @l, " $s Pulled"; next }
            my ( $ok, $e ) = _pull( $d, $ref );
            if ( !$ok ) { push @l, " $s Error " . ( $e =~ s/\AError response from daemon: //r ), $e; return $out->( \@l, 0 ) }
            push @l, " $s Pulled";
        }
        return $out->( \@l, 1 );
    }
    my @mine = _project_containers( $d, $m->{name} );
    my %by_svc = map { $d->{containers}{$_}{service} => $_ } @mine;
    for (@svc) { return $out->( ["no such service: $_"], 0 ) if $verb ne 'exec' && $verb ne 'logs' && !$by_svc{$_} && !$m->{services}{$_} }
    if ( $verb eq 'ps' ) {
        return $out->( [ sort map { $d->{containers}{$_}{service} } grep { $f{a} || $f{all} || $d->{containers}{$_}{status} ne 'exited' } @mine ], 1 ) if $f{services};
        my @rows = grep {
            my $c = $d->{containers}{$_};
            ( $f{a} || $f{all} || defined $f{status} || $c->{status} ne 'exited' && $c->{status} ne 'created' )
                && ( !@svc || grep { $_ eq $c->{service} } @svc ) && ( !defined $f{status} || $c->{status} eq $f{status} )
        } @mine;
        return $out->( [ map { _id( $_, $d->{containers}{$_}{seq} ) } @rows ], 1 ) if $f{q} || $f{quiet};
        if ( defined $f{format} && $f{format} ne 'table' ) {
            my $fm = $f{format} eq 'json' ? '{{json .}}' : $f{format};
            return $out->( [ gofmt( $fm, [ map { _ps_row( $d, $_ ) } @rows ] ) ], 1 );
        }
        my @l = ( sprintf( '%-22s %-44s %-24s %-10s %-18s %-28s %s', qw( NAME IMAGE COMMAND SERVICE CREATED STATUS PORTS ) ) );
        for my $n (@rows) {
            my $c = $d->{containers}{$n};
            push @l, sprintf( '%-22s %-44s %-24s %-10s %-18s %-28s %s', $n, $c->{image}, '"docker-entrypoint.s…"', $c->{service},
                'About an hour ago', _status_text($c), _ports_text( $c, _image( $d, $c->{image} ) || {} ) );
        }
        return $out->( \@l, 1 );
    }
    if ( $verb eq 'logs' ) {
        return ( '', _gap('docker compose logs -f') ) if $f{f} || $f{follow};
        my @l;
        for my $n (@mine) {
            my $c = $d->{containers}{$n};
            next if @svc && !grep { $_ eq $c->{service} } @svc;
            my @x = _logs_of( $d, $n );
            @x = @x[ ( @x > $f{tail} ? @x - $f{tail} : 0 ) .. $#x ] if defined $f{tail} && $f{tail} =~ /\A\d+\z/;
            push @l, map { sprintf( '%-12s| %s', $n, $_ ) } @x;
        }
        return $out->( \@l, 1 );
    }
    if ( $verb =~ /\A(?:restart|stop|start|kill)\z/ ) {
        my @l;
        for my $n (@mine) {
            my $c = $d->{containers}{$n};
            next if @svc && !grep { $_ eq $c->{service} } @svc;
            push @l, " Container $n  " . { restart => 'Restarting', stop => 'Stopping', start => 'Starting', kill => 'Killing' }->{$verb};
            if ( defined( my $e = _lifecycle( $dev, $d, $n, $c, $verb, $ctx ) ) ) {
                _settle($dev);
                return $out->( [ @l, " Container $n  Error", $e ], 0 );
            }
            push @l, " Container $n  " . { restart => 'Started', stop => 'Stopped', start => 'Started', kill => 'Killed' }->{$verb};
        }
        _settle($dev);
        return $out->( \@l, 1 );
    }
    if ( $verb eq 'down' ) {
        my @l;
        my %svc_c = map { _cname( $m, $_ ) => 1 } keys %{ $m->{services} };
        my @orph = grep { !$svc_c{$_} } @mine;
        for my $n ( reverse @mine ) {
            next if !$svc_c{$n} && !( $f{'remove-orphans'} || $m->{nofile} );
            my $c = $d->{containers}{$n};
            push @l, " Container $n  Stopping", " Container $n  Stopped", " Container $n  Removing", " Container $n  Removed";
            delete $d->{containers}{$n};
        }
        unshift @l, "WARN[0000] Found orphan containers ([" . join( ' ', @orph ) . "]) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up."
            if @orph && !$f{'remove-orphans'} && !$m->{nofile};
        for my $nw ( sort grep { ( $d->{networks}{$_}{project} // '' ) eq $m->{name} } keys %{ $d->{networks} || {} } ) {
            push @l, " Network $nw  Removing", " Network $nw  Removed";
            delete $d->{networks}{$nw};
        }
        if ( $f{v} || $f{volumes} ) {
            my %mine = map { $_ => 1 } grep { !( $m->{external_volumes} || {} )->{$_} } values %{ $m->{volumes} || {} };
            for my $v ( sort grep { $mine{$_} || ( $d->{volumes}{$_}{project} // '' ) eq $m->{name} } keys %{ $d->{volumes} || {} } ) {
                push @l, " Volume $v  Removing", " Volume $v  Removed";
                delete $d->{volumes}{$v};
            }
        }
        return $out->( \@l, 1 );
    }
    if ( $verb eq 'exec' ) {
        my @x = @a;
        my $s;
        while (@x) {
            my $v = shift @x;
            if ( $v =~ /\A-(?:e|u|w|-env|-user|-workdir|-index)\z/ ) { shift @x; next }
            next if $v =~ /\A-/;
            $s = $v;
            last;
        }
        return $out->( ['"docker compose exec" requires at least 2 arguments.'], 0 ) unless defined $s && @x;
        my $n = $by_svc{$s};
        return $out->( ["service \"$s\" is not running"], 0 ) unless defined $n && $d->{containers}{$n}{status} eq 'running';
        my ( $o, $ok ) = _exec( $dev, $d, $n, $d->{containers}{$n}, \@x );
        return $out->( [ grep { length } $o ], $ok );
    }
    if ( $verb eq 'images' ) {
        return $out->( [ sprintf( '%-22s %-44s %-12s %s', 'CONTAINER', 'REPOSITORY', 'TAG', 'IMAGE ID' ),
            map { my $c = $d->{containers}{$_}; my ( $r, $t ) = $c->{image} =~ /\A(.+):([^:]+)\z/; sprintf( '%-22s %-44s %-12s %s', $_, $r, $t, $c->{image_id} ) } @mine ], 1 );
    }
    if ( $verb eq 'rm' ) {    # gestoppte Container entfernen (-f ohne Rueckfrage, -s stoppt vorher)
        my @l;
        for my $n (@mine) {
            my $c = $d->{containers}{$n};
            next if @svc && !grep { $_ eq $c->{service} } @svc;
            if ( $c->{status} eq 'running' || $c->{status} eq 'restarting' ) {
                next unless $f{s} || $f{stop};
                _lifecycle( $dev, $d, $n, $c, 'stop', $ctx );
            }
            push @l, " Container $n  Removing", " Container $n  Removed";
            delete $d->{containers}{$n};
        }
        return $out->( @l ? \@l : ['No stopped containers'], 1 );
    }
    return _gap("docker compose $verb") if $verb =~ /\A(?:build|run|cp|top|events|port|attach|watch|create|wait|scale|pause|unpause|stats)\z/;
    return ( "unknown docker command: \"compose $verb\"", 0 );
}

sub _config_yaml {
    my ($m) = @_;
    my %y = ( name => $m->{name}, services => {} );
    for my $s ( sort keys %{ $m->{services} } ) {
        my $c = $m->{services}{$s};
        my %o = map { defined $c->{$_} ? ( $_ => $c->{$_} ) : () } qw( image container_name user command restart healthcheck profiles );
        delete $o{profiles} unless @{ $c->{profiles} || [] };
        $o{environment} = $c->{environment} if %{ $c->{environment} || {} };
        $o{ports} = [ map { { mode => 'ingress', target => 0 + $_->{target}, ( length $_->{published} ? ( published => "$_->{published}" ) : () ),
            ( $_->{host_ip} ne '0.0.0.0' ? ( host_ip => $_->{host_ip} ) : () ), protocol => $_->{protocol} } } @{ $c->{ports} } ] if @{ $c->{ports} };
        $o{volumes} = [ map { { type => $_->{type}, ( length $_->{source} ? ( source => $_->{source} ) : () ), target => $_->{target},
            ( $_->{read_only} ? ( read_only => '__TRUE__' ) : () ) } } @{ $c->{volumes} } ] if @{ $c->{volumes} };
        $o{networks} = { map { $_ => undef } @{ $c->{networks} } };
        $o{depends_on} = { map { $_ => { condition => $c->{depends_on}{$_}{condition}, required => '__TRUE__' } } keys %{ $c->{depends_on} } } if %{ $c->{depends_on} };
        $y{services}{$s} = \%o;
    }
    $y{networks} = { ( map { $_ => { name => $m->{networks}{$_} } } keys %{ $m->{networks} || {} } ), default => { name => "$m->{name}_default" } };
    $y{volumes} = { map { $_ => { name => $m->{volumes}{$_} } } keys %{ $m->{volumes} } } if %{ $m->{volumes} || {} };
    my $t = Encode::decode( 'UTF-8', YAML::XS::Dump( \%y ) );
    $t =~ s/\A---\n//;
    $t =~ s/: ~$/: null/mg;
    $t =~ s/'?__TRUE__'?/true/g;
    $t =~ s/\n\z//;
    return $t;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Docker - Docker Engine with Compose v2 on a simulated Linux server — projects, containers, derived state

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator: docker on a device with docker state
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Docker::docker( $dev, \@argv, $ctx, $stdin );

=head1 DESCRIPTION

Docker Engine 26 with the Compose plugin v2 as state of a Linux device
(cai-platform F<docs/entwurf-evals.md> §3.3). The Compose files are ordinary files
of the device (C<files>); what runs is under C<docker>:

  docker:
    projects:
      shop: { dir: /srv/shop }        # compose.yaml|compose.yml|docker-compose.y(a)ml and .env there
      # running_files: { /srv/shop/compose.yaml: "…" }  # what the running state was started with
      # stopped: true                 # project is not running
    images:                           # images present locally and their behaviour (simulation only)
      "postgres:16.4":
        listens: [5432]
        user: "999"                   # uid of the process (write access to bind mounts)
        data_path: /var/lib/postgresql/data   # where data lives (data of the mount there)
        warmup: true                  # accepts connections only after starting up
        tools: [pg_isready, sh]       # for healthchecks and exec
        needs:                        # start conditions; the first one violated exits with 1
          - env: POSTGRES_PASSWORD
            log: [ "Error: Database is uninitialized and superuser password is not specified." ]
          - connect: "${DB_HOST}:${DB_PORT:-5432}"     # service name on the same network, running, listening
            log: [ "…" ]
          - equals: [ "${DB_PASSWORD}", "${peer:POSTGRES_PASSWORD}" ]   # peer = target of the last connect
            log: [ "…" ]
          - writable: /data           # mount there writable for user
          - mount: /etc/app/app.yml   # file present through a bind mount
        logs: [ "…" ]                 # when it runs
        http: { routes: [ … ] }       # like Sim::Http (application on the first listens port)
    registry: { "registry.example.com/shop/api:2.5.0": { … } }   # pullable (behaviour like images)
    host_ports: { "0.0.0.0:80": apache2 }                       # taken by the host
    volumes: { shop_pgdata: { data: kunden-2026 } }              # named volumes, content
    # by the simulator (derived from the files on the first command, then carried on):
    containers:
      shop-db-1: { project, service, image, status: running|exited|restarting|created,
                   exit_code, health: healthy|unhealthy|starting, seq, restarts,
                   config (effective service configuration), data, error }

Bind mounts with content describe directories of the device (C<dirs: {
/srv/shop/pgdata: { data: …, owner, group, mode } }>). Docker creates a missing
directory as root on start (as for real).

B<Effective configuration>: interpolation like Compose (C<${VAR}>, C<$VAR>,
C<${VAR:-d}>, C<${VAR-d}>, C<${VAR:?e}>, C<$$>) from the project's F<.env>
(quotes like dotenv: single literal, double with substitution),
C<env_file> (values literal into the container's environment), C<environment>
(list or map), C<ports> (short and long), C<volumes> (short and long,
project volumes with prefix), C<networks>, C<depends_on> (list or map with
C<condition>), C<healthcheck>, C<restart>, C<user>, C<profiles>,
C<container_name>. Errors like Compose: YAML errors with line, unknown
keys (C<additional properties … not allowed>), unknown services,
networks, volumes.

B<up>: order by C<depends_on>; each service recreated when its effective
configuration or the image has changed (otherwise "Running"); a missing image
is pulled from C<registry> (otherwise C<manifest unknown>); port conflicts with
the host or other containers; C<service_healthy> waits for a healthy
healthcheck; a service that does not meet its conditions on start ends
(C<exited>), or with a restart policy C<restarting>; when it reaches a service
with C<warmup> that was started in the same round, without waiting for its
health, its first start fails (with a restart policy it runs afterwards).
C<restart> restarts containers without taking over changes to the file;
C<down -v> deletes the project's volumes with their content.

B<Commands>: C<docker compose> (C<-f>, C<-p>, C<--project-directory>,
C<--env-file>, C<--profile>) C<up -d [--force-recreate] [--no-deps]
[--remove-orphans] [service…]>, C<down [-v] [--remove-orphans]>, C<ps [-a]
[--services]>, C<logs [--tail N] [service…]>, C<config [-q] [--services]
[--volumes]>, C<restart|stop|start [service…]>, C<pull [service…]>, C<exec [-T]
service command>, C<images>, C<ls>, C<version>; C<docker ps [-a]>, C<logs>,
C<inspect [--format]>, C<restart|stop|start>, C<exec>, C<volume ls|inspect>,
C<network ls>, C<images>, C<pull>, C<version>. In C<exec>: C<env>,
C<printenv>, C<cat> (mounted files), C<id>, C<curl>/C<wget> to other
services, C<pg_isready>. C<up> without C<-d>, C<docker run>, C<build> and
anything interactive are B<gaps of the simulation>.

=head2 ensure

  ensure( $dev, $host, $state );

On the first command, derives the running containers from the files (or from
C<running_files>), as if every project had been started with C<up -d>.

=head2 parse_env

  my $vars = parse_env( $text, \%before, \@missing );

An F<.env> like Compose (dotenv): C<KEY=VAL>, C<export>, single quotes
literal, double and unquoted with substitution.

=head2 interpolate

  my $r = interpolate( '${DB_HOST:-db}:5432', \%vars );   # { value, missing, error }

Substitution like Compose: C<${VAR}>, C<$VAR>, C<${VAR:-d}>, C<${VAR-d}>,
C<${VAR:?e}>, C<${VAR:+x}>, C<$$>; C<${peer:X}> for the environment of the
container reached last (only in conditions of the images).

=head2 model

  my $m = model( $dev, dir => '/srv/shop', files => [ … ], project => 'shop', env_file => …, profiles => [ … ] );

The effective configuration of a project: C<name>, C<dir>, C<file>,
C<services> (normalised per service), C<networks>, C<volumes>, C<warnings>,
C<error> (text like Compose).

=head2 up

  my ( $lines, $ok, $err ) = up( $dev, $model, \%opt, $state, $host );

C<docker compose up -d>: C<services> (list, otherwise all without a profile),
C<force_recreate> (only the chosen services), C<recreate_deps> (their
dependencies too), C<no_deps>, C<remove_orphans>.

=head2 lookup

  my ( $name, $c ) = lookup( $docker, $from, 'db' );

The container behind a name as seen from a container: service name in the
same project, container name or C<hostname>, only over a shared network.

=head2 exec_line

  my ( $out, $ok ) = exec_line( $dev, $docker, $container, $c, 'wget -qO- http://api:8080/health' );

A command line in the container (healthchecks, C<docker exec>): chains with
C<||>, C<&&>, C<;>; C<curl>, C<wget>, C<pg_isready>, C<env>, C<printenv>,
C<cat>, C<id>, C<true>/C<false>/C<exit N>. A program the image does not
have (C<tools>) is missing as for real.

=head2 container_request

  my $res = container_request( $dev, $docker, $name, $c, $url );

HTTP from a container to a service (or itself), response like
L<Langertha::Holmgang::Sim::Linux::Http/respond>; C<undef> when nobody listens there.

=head2 serve

Response of a container that publishes the port on the device, or
C<undef> (contract of L<Langertha::Holmgang::Sim::Linux::Http/request>).

=head2 ss_lines

Lines for C<ss -tlnp>: the published ports of running containers (docker-proxy).

=head2 docker

C<docker …> on the device (see DESCRIPTION).

=head2 gofmt

  my $text = gofmt( 'table {{.Names}}\t{{.Status}}', \@rows );

Go templates like docker's C<--format>: C<{{.Field}}>, C<{{.A.B}}>, C<{{json .X}}>,
C<{{json .}}>, prefix C<table> (header line from the field names), C<\t>. Unknown
fields: C<< <no value> >>.

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
