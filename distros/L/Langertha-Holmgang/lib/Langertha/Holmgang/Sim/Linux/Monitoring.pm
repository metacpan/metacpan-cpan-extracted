package Langertha::Holmgang::Sim::Linux::Monitoring;
# ABSTRACT: Monitoring on a simulated Linux server — checks Prometheus/Alertmanager, promtool, amtool

use strict;
use warnings;
use utf8;

use Encode ();
use JSON::MaybeXS ();
use Text::ParseWords ();
use YAML::XS ();

our $VERSION = '0.001';


our @GAPS;

sub _file_text {
    my ( $dev, $p ) = @_;
    require Langertha::Holmgang::Sim::Linux;
    return Langertha::Holmgang::Sim::Linux::_file_text( $dev, $p );
}

sub _glob_files {
    my ( $dev, $pat ) = @_;
    ( my $re = quotemeta $pat ) =~ s/\\\*/[^\/]*/g;
    $re =~ s/\\\?/[^\/]/g;
    return sort grep { /\A$re\z/ && defined _file_text( $dev, $_ ) } keys %{ $dev->{files} || {} };
}

# YAML laden: ( daten ) oder ( undef, "yaml: line N: …" )
sub _yaml {
    my ($text) = @_;
    my $d = eval { YAML::XS::Load( utf8::is_utf8($text) ? Encode::encode( q{UTF-8}, $text ) : $text ) };
    return ($d) unless $@;
    my $e = "$@";
    my ($line) = $e =~ /line:\s*(\d+)/;
    my ($what) = $e =~ /YAML::XS::Load Error: The problem:\s*\n?\s*(.+?)(?:\n|$)/;
    $what //= 'did not find expected key';
    $what =~ s/\s+\z//;
    return ( undef, 'yaml: line ' . ( $line // 1 ) . ": $what" );
}

# Prometheus-Dauer ("90s", "1m30s", "2h") in Sekunden, undef wenn ungueltig
sub _dur {
    my ($s) = @_;
    return undef unless defined $s && $s =~ /\A(?:\d+(?:ms|s|m|h|d|w|y))+\z/;
    my %f = ( ms => 0.001, s => 1, m => 60, h => 3600, d => 86400, w => 604800, y => 31536000 );
    my $t = 0;
    $t += $1 * $f{$2} while $s =~ /(\d+)(ms|s|m|h|d|w|y)/g;
    return $t;
}

our %RULE_KEYS =map { $_ => 1 } qw( alert record expr for labels annotations keep_firing_for );

# Regeldatei pruefen: ( zahl der regeln ) oder ( undef, [ fehler ] )
sub _check_rules {
    my ( $path, $text ) = @_;
    my ( $d, $ye ) = _yaml($text);
    return ( undef, ["$path: $ye"] ) if $ye;
    return ( undef, ["$path: yaml: unmarshal errors: groups missing"] ) unless ref $d eq 'HASH' && ref $d->{groups} eq 'ARRAY';
    my ( $n, @e, %gn ) = (0);
    for my $g ( @{ $d->{groups} } ) {
        push @e, "$path: group name must not be empty" unless ref $g eq 'HASH' && defined $g->{name} && length $g->{name};
        next unless ref $g eq 'HASH';
        push @e, "$path: $g->{name}: repeated in the same file" if defined $g->{name} && $gn{ $g->{name} }++;
        for my $r ( @{ $g->{rules} || [] } ) {
            if ( ref $r ne 'HASH' ) { push @e, "$path: rule is not a map"; next }
            for my $k ( sort keys %$r ) { push @e, "$path: field $k not found in type rulefmt.RuleNode" unless $RULE_KEYS{$k} }
            push @e, "$path: group \"$g->{name}\", rule $n: one of 'record' or 'alert' must be set" unless defined $r->{alert} || defined $r->{record};
            push @e, "$path: group \"$g->{name}\", rule $n: field 'expr' must be set in rule" unless defined $r->{expr} && length $r->{expr};
            if ( defined $r->{expr} ) {
                my $x = $r->{expr};
                my $open = () = $x =~ /\(/g;
                my $close = () = $x =~ /\)/g;
                push @e, "$path: group \"$g->{name}\", rule $n, \"" . ( $r->{alert} // $r->{record} // '' ) . "\": could not parse expression: 1:1: parse error: unclosed left parenthesis"
                    if $open != $close;
            }
            if ( defined $r->{for} && $r->{for} !~ /\A\d+(?:ms|s|m|h|d|w|y)\z/ ) {
                push @e, "$path: group \"$g->{name}\", rule $n: not a valid duration string: \"$r->{for}\"";
            }
            $n++;
        }
    }
    return ( undef, \@e ) if @e;
    return ($n);
}


sub check_prometheus {
    my ( $dev, $path ) = @_;
    my $text = _file_text( $dev, $path );
    return ( ["open $path: no such file or directory"], {} ) unless defined $text;
    my ( $d, $ye ) = _yaml($text);
    return ( ["parsing YAML file $path: $ye"], {} ) if $ye;
    return ( ["parsing YAML file $path: yaml: unmarshal errors: config is not a map"], {} ) unless ref $d eq 'HASH';
    my @e;
    my %known = map { $_ => 1 } qw( global scrape_configs rule_files alerting remote_write remote_read storage tracing scrape_config_files );
    push @e, "parsing YAML file $path: yaml: unmarshal errors: field $_ not found in type config.plain" for grep { !$known{$_} } sort keys %$d;
    my %jobs;
    my $g = ref $d->{global} eq 'HASH' ? $d->{global} : {};
    my $gi = _dur( $g->{scrape_interval} // '1m' );
    my $gt = _dur( $g->{scrape_timeout} // '10s' );
    for my $sc ( @{ $d->{scrape_configs} || [] } ) {
        my $j = ref $sc eq 'HASH' ? $sc->{job_name} : undef;
        if ( !defined $j || !length $j ) { push @e, "parsing YAML file $path: job_name is empty"; next }
        push @e, "parsing YAML file $path: found multiple scrape configs with job name \"$j\"" if $jobs{$j}++;
        my $iv = defined $sc->{scrape_interval} ? _dur( $sc->{scrape_interval} ) : $gi;
        my $to = defined $sc->{scrape_timeout} ? _dur( $sc->{scrape_timeout} ) : ( $gt > $iv ? $iv : $gt );
        for my $k (qw( scrape_interval scrape_timeout )) {
            push @e, "parsing YAML file $path: not a valid duration string: \"$sc->{$k}\"" if defined $sc->{$k} && !defined _dur( $sc->{$k} );
        }
        push @e, "parsing YAML file $path: scrape timeout greater than scrape interval for scrape config with job name \"$j\""
            if defined $iv && defined $to && $to > $iv;
        for my $s ( @{ $sc->{static_configs} || [] } ) {
            for my $t ( @{ ( ref $s eq 'HASH' ? $s->{targets} : undef ) || [] } ) {
                push @e, "parsing YAML file $path: \"$t\" is not a valid hostname" unless defined $t && $t =~ /\A[\w.\-\[\]:]+:\d+\z/;
            }
        }
    }
    my ( %rules, $nr );
    for my $pat ( @{ $d->{rule_files} || [] } ) {
        ( my $p = $pat ) =~ s{\A(?!/)}{ ( $path =~ m{\A(.*)/} )[0] . '/' }e;
        for my $f ( _glob_files( $dev, $p ) ) {
            my $t = _file_text( $dev, $f );
            my ( $n, $re ) = _check_rules( $f, $t );
            if ($re) { push @e, map {"loading groups failed: $_"} @$re; next }
            $rules{$f} = $t;
            $nr += $n;
        }
    }
    return ( \@e, \%rules, $nr // 0 );
}


sub check_alertmanager {
    my ( $dev, $path ) = @_;
    my $text = _file_text( $dev, $path );
    return ["open $path: no such file or directory"] unless defined $text;
    return _am_check_text($text);
}

sub _am_check_text {
    my ($text) = @_;
    my ( $d, $ye ) = _yaml($text);
    return [$ye] if $ye;
    return ['no route provided in config'] unless ref $d eq 'HASH' && ref $d->{route} eq 'HASH';
    my %recv = map { ( ref $_ eq 'HASH' ? $_->{name} // '' : '' ) => 1 } @{ $d->{receivers} || [] };
    my @e;
    my $walk;
    $walk = sub {
        my ( $r, $top ) = @_;
        if ( defined $r->{receiver} ) { push @e, "undefined receiver \"$r->{receiver}\" used in route" unless $recv{ $r->{receiver} } }
        elsif ($top) { push @e, 'root route must specify a default receiver' }
        $walk->( $_, 0 ) for grep { ref $_ eq 'HASH' } @{ $r->{routes} || [] };
    };
    $walk->( $d->{route}, 1 );
    return \@e;
}


sub service_check {
    my ( $dev, $svc, $kind ) = @_;
    my $main = $svc->{config_main} // ( ref $svc->{config} ? $svc->{config}[0] : $svc->{config} );
    my $ts   = 'ts=2026-10-24T09:12:03.000Z';
    if ( $kind eq 'prometheus' ) {
        my ( $e, $rules ) = check_prometheus( $dev, $main );
        return ( [ map {qq{$ts caller=main.go:1150 level=error msg="Error reloading config" err="couldn't load configuration (--config.file=\\"$main\\"): $_"}} @$e ], {} ) if @$e;
        return ( [], $rules );
    }
    if ( $kind eq 'alertmanager' ) {
        my $e = check_alertmanager( $dev, $main );
        return ( [ map {qq{$ts caller=coordinator.go:118 level=error component=configuration msg="Loading configuration file failed" file=$main err="$_"}} @$e ], {} ) if @$e;
        $svc->{_routes} = _am_routes( _file_text( $dev, $main ) );
        return ( [], {} );
    }
    return ( [], {} );
}


sub http {
    my ( $dev, $method, $port, $path, $run ) = @_;
    my $kind = $port == 9090 ? 'prometheus' : $port == 9093 ? 'alertmanager' : return;
    my ( $name, $svc ) = map { ( $_, $dev->{services}{$_} ) }
        grep { ( $dev->{services}{$_}{config_check} // '' ) eq $kind } sort keys %{ $dev->{services} || {} };
    return ( '', 0 ) unless $svc && $svc->{active};
    my $run_cfg = ref $svc->{running} eq 'HASH' ? $svc->{running} : {};
    my $main    = $svc->{config_main} // ( ref $svc->{config} ? $svc->{config}[0] : $svc->{config} );
    $path =~ s/\?.*//;
    my $js = sub { JSON::MaybeXS->new( canonical => 1 )->encode( { status => 'success', data => $_[0] } ) };
    if ( $kind eq 'prometheus' ) {
        return ( 'Prometheus Server is Healthy.', 200 ) if $path eq '/-/healthy';
        return ( 'Prometheus Server is Ready.',   200 ) if $path eq '/-/ready';
        if ( $path eq '/-/reload' ) {
            return ( 'Only POST or PUT requests allowed', 405 ) if $method ne 'POST';
            my $args = join ' ', map { $run_cfg->{$_} // '' } grep { m{\A/etc/default/} } keys %$run_cfg;
            return ( 'Lifecycle API is not enabled.', 403 ) unless $args =~ /--web\.enable-lifecycle/;
            my ( $o, $ok ) = $run->("systemctl reload $name");
            return ( $ok ? '' : "failed to reload config: $o", $ok ? 200 : 500 );
        }
        return ( $js->( { yaml => $run_cfg->{$main} // '' } ), 200 ) if $path eq '/api/v1/status/config';
        return ( $js->( _prom_flags($run_cfg) ), 200 ) if $path eq '/api/v1/status/flags';
        return ( $js->( { alerts => [] } ), 200 ) if $path eq '/api/v1/alerts';    # Regeln stehen auf inactive
        if ( $path eq '/api/v1/rules' ) {
            my @groups;
            for my $f ( sort grep { $_ ne $main && !m{\A/etc/default/} } keys %$run_cfg ) {
                my ($d) = _yaml( $run_cfg->{$f} );
                for my $g ( @{ ( ref $d eq 'HASH' ? $d->{groups} : undef ) || [] } ) {
                    my @r;
                    for my $x ( grep { ref $_ eq 'HASH' } @{ $g->{rules} || [] } ) {
                        my %r = ( name => $x->{alert} // $x->{record}, query => $x->{expr}, health => 'ok',
                            type => defined $x->{alert} ? 'alerting' : 'recording' );
                        %r = ( %r, duration => _dur( $x->{for} // '0s' ) // 0, labels => $x->{labels} // {},
                            annotations => $x->{annotations} // {}, state => 'inactive', alerts => [] ) if defined $x->{alert};
                        push @r, \%r;
                    }
                    push @groups, { name => $g->{name}, file => $f, interval => 15, rules => \@r };
                }
            }
            return ( $js->( { groups => \@groups } ), 200 );
        }
        return;
    }
    return ( 'OK', 200 ) if $path eq '/-/healthy' || $path eq '/-/ready';
    if ( $path eq '/-/reload' ) {    # bei Alertmanager immer offen
        return ( 'Only POST requests allowed', 405 ) if $method ne 'POST';
        my ( $o, $ok ) = $run->("systemctl reload $name");
        return ( $ok ? '' : "failed to reload config: $o", $ok ? 200 : 500 );
    }
    if ( $path eq '/api/v2/status' ) {
        return ( JSON::MaybeXS->new( canonical => 1 )->encode( { config => { original => $run_cfg->{$main} // '' }, cluster => { status => 'disabled' } } ), 200 );
    }
    return;
}

# Startoptionen, mit denen Prometheus laeuft (ARGS aus /etc/default/*), ueber den
# Standardwerten von Prometheus 2.x (Debian-Pfade). Werte sind Strings wie in der API.
my %PROM_FLAG_DEFAULT = (
    'config.file'                 => '/etc/prometheus/prometheus.yml',
    'storage.tsdb.path'           => '/var/lib/prometheus/metrics2/',
    'storage.tsdb.retention.time' => '0s',
    'storage.tsdb.retention.size' => '0B',
    'web.listen-address'          => '0.0.0.0:9090',
    'web.external-url'            => '',
    'web.enable-lifecycle'        => 'false',
    'web.enable-admin-api'        => 'false',
    'log.level'                   => 'info',
);

sub _prom_flags {
    my ($run_cfg) = @_;
    my %f = %PROM_FLAG_DEFAULT;
    for my $file ( sort grep { m{\A/etc/default/} } keys %$run_cfg ) {
        for my $line ( split /\n/, $run_cfg->{$file} // '' ) {
            next unless $line =~ /\A\s*ARGS=(.*)\z/;
            my $args = $1;    # Kopie: shellwords bekaeme $1 als Alias
            # die Shell entquotet ARGS="…", systemd teilt $ARGS an Leerraum
            my @w = split q{ }, join q{ }, Text::ParseWords::shellwords($args);
            while ( defined( my $w = shift @w ) ) {
                next unless $w =~ /\A--?(?:no-)?([\w.\-]+)(?:=(.*))?\z/s;
                my ( $k, $v ) = ( $1, $2 );
                if ( $w =~ /\A--?no-/ ) { $f{$k} = 'false'; next }
                $v //= @w && $w[0] !~ /\A-/ && ( $f{$k} // '' ) !~ /\A(?:true|false)\z/ ? shift @w : 'true';
                $f{$k} = $v;
            }
        }
    }
    return \%f;
}


sub promtool {
    my ( $dev, $av ) = @_;
    my @a = grep { !/\A--/ } @$av;
    my ( $cmd, $what, @files ) = @a;
    if ( ( $cmd // '' ) ne 'check' || ( $what // '' ) !~ /\A(?:config|rules)\z/ ) { push @GAPS, join( ' ', 'promtool', @$av ); return ( '', 0 ) }
    my ( @out, $ok );
    $ok = 1;
    for my $f (@files) {
        push @out, "Checking $f";
        if ( $what eq 'config' ) {
            my ( $e, $rules, $n ) = check_prometheus( $dev, $f );
            if (@$e) { push @out, map {"  FAILED: $_"} @$e; $ok = 0; push @out, ''; next }
            push @out, '  SUCCESS: ' . scalar( keys %$rules ) . ' rule files found', " SUCCESS: $f is valid prometheus config file syntax", '';
            for my $r ( sort keys %$rules ) { push @out, "Checking $r", "  SUCCESS: " . ( _check_rules( $r, $rules->{$r} ) )[0] . ' rules found', '' }
        }
        else {
            my $t = _file_text( $dev, $f );
            if ( !defined $t ) { push @out, "  FAILED:", "open $f: no such file or directory", ''; $ok = 0; next }
            my ( $n, $e ) = _check_rules( $f, $t );
            if ($e) { push @out, '  FAILED:', @$e, ''; $ok = 0; next }
            push @out, "  SUCCESS: $n rules found", '';
        }
    }
    pop @out while @out && $out[-1] eq '';
    return ( join( "\n", @out ), $ok );
}


# Wirksame Einstellungen je Empfaenger: { empfaenger => { repeat_interval, group_wait,
# group_interval, group_by } } — Unterrouten erben, was sie nicht selbst setzen (erste Route je Empfaenger)
our %AM_ROUTE_DEFAULT = ( group_wait => '30s', group_interval => '5m', repeat_interval => '4h' );

sub _am_routes {
    my ($text) = @_;
    my ($d) = _yaml($text);
    my %out;
    my $walk;
    $walk = sub {
        my ( $r, $parent ) = @_;
        return unless ref $r eq 'HASH';
        my %eff = %$parent;
        for my $k (qw( receiver repeat_interval group_wait group_interval )) { $eff{$k} = $r->{$k} if defined $r->{$k} }
        $eff{group_by} = join( ',', @{ $r->{group_by} } ) if ref $r->{group_by} eq 'ARRAY';
        my %copy = %eff;
        $out{ $eff{receiver} } //= \%copy if defined $eff{receiver};
        $walk->( $_, \%eff ) for @{ $r->{routes} || [] };
    };
    $walk->( ref $d eq 'HASH' ? $d->{route} : undef, {%AM_ROUTE_DEFAULT} );
    return \%out;
}

# Zeit: Uhr des Geraets (clock "Oct 24 09:12", Jahr 2026, Zone tz, Vorgabe +02:00) als Epoche
our %MON = ( Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5, Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11 );


sub now_epoch {
    my ($dev) = @_;
    require Time::Local;
    my ( $mon, $day, $h, $mi ) = ( $dev->{clock} // 'Oct 20 09:12' ) =~ /\A(\w{3})\s+(\d+)\s+(\d+):(\d+)/;
    return Time::Local::timegm( 0, $mi, $h, $day, $MON{$mon} // 9, 2026 ) - _tz_secs($dev);
}

sub _tz_secs {
    my ($dev) = @_;
    my ( $sg, $h, $m ) = ( $dev->{tz} // '+02:00' ) =~ /\A([+-])(\d\d):?(\d\d)\z/ or return 0;
    return ( $sg eq '-' ? -1 : 1 ) * ( $h * 3600 + $m * 60 );
}

# RFC 3339 -> Epoche; undef wenn nicht lesbar
sub _rfc3339 {
    my ($t) = @_;
    require Time::Local;
    my ( $Y, $M, $D, $h, $m, $s, $z ) = ( $t // '' ) =~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?(Z|[+-]\d\d:\d\d)\z/ or return undef;
    my $e = Time::Local::timegm( $s, $m, $h, $D, $M - 1, $Y );
    if ( $z ne 'Z' ) { my ( $sg, $zh, $zm ) = $z =~ /([+-])(\d\d):(\d\d)/; $e -= ( $sg eq '-' ? -1 : 1 ) * ( $zh * 3600 + $zm * 60 ) }
    return $e;
}

sub _iso { my @t = gmtime $_[0]; return sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ', $t[5] + 1900, $t[4] + 1, @t[ 3, 2, 1, 0 ] }

# Go-Dauer: 2h, 90m, 1h30m, 45s
sub _godur {
    my ($d) = @_;
    return undef unless defined $d && $d =~ /\A(?:\d+(?:\.\d+)?(?:h|m|s|ms))+\z/;
    my $t = 0;
    while ( $d =~ /(\d+(?:\.\d+)?)(ms|h|m|s)/g ) { $t += $1 * { h => 3600, m => 60, s => 1, ms => 0.001 }->{$2} }
    return int $t;
}

# Matcher: name=wert, name!=wert, name=~re, name!~re (Wert ggf. in Anfuehrungszeichen)
sub _am_matcher {
    my ($x) = @_;
    my ( $n, $op, $v ) = $x =~ /\A\s*([A-Za-z_]\w*)\s*(=~|!~|!=|=)\s*(.*?)\s*\z/ or return undef;
    $v =~ s/\A"(.*)"\z/$1/s;
    $v =~ s/\A'(.*)'\z/$1/s;
    return { name => $n, op => $op, value => $v };
}

sub _am_matches {
    my ( $ms, $labels ) = @_;
    for my $m (@$ms) {
        my $have = $labels->{ $m->{name} } // '';
        my $hit = $m->{op} =~ /~/ ? ( eval { $have =~ /\A(?:$m->{value})\z/ } // 0 ) : $have eq $m->{value};
        $hit = !$hit if $m->{op} =~ /\A!/;
        return 0 unless $hit;
    }
    return 1;
}

# Silence mit abgeleiteten Feldern: starts/ends (UTC), state, covers (Namen aus alert_targets)
sub _am_silence_view {
    my ( $svc, $sil, $now ) = @_;
    my $t = $svc->{alert_targets} || {};
    $sil->{starts} = _iso( $sil->{_start} );
    $sil->{ends}   = _iso( $sil->{_end} );
    $sil->{state}  = $sil->{_expired} || $sil->{_end} <= $now ? 'expired' : $sil->{_start} > $now ? 'pending' : 'active';
    $sil->{covers} = [ sort grep { _am_matches( $sil->{_matchers}, $t->{$_} ) } keys %$t ];
    return $sil;
}

sub _am_svc {
    my ($dev) = @_;
    my ($n) = grep { ( $dev->{services}{$_}{config_check} // '' ) eq 'alertmanager' } sort keys %{ $dev->{services} || {} };
    return defined $n ? $dev->{services}{$n} : undef;
}

sub _amtool_silence {
    my ( $dev, $sub, $av ) = @_;
    my ( %opt, @pos );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A--([\w.-]+)=(.*)\z/s ) { $opt{$1} = $2 }
        elsif ( $x =~ /\A--([\w.-]+)\z/ && $1 !~ /\A(?:quiet|expired|extended)\z/ ) { $opt{$1} = shift @a }
        elsif ( $x =~ /\A-([acdq])\z/ ) { $opt{ { a => 'author', c => 'comment', d => 'duration', q => 'quiet' }->{$1} } = $1 eq 'q' ? 1 : shift @a }
        elsif ( $x =~ /\A--(quiet|expired|extended)\z/ ) { $opt{$1} = 1 }
        else  { push @pos, $x }
    }
    my $url = $opt{'alertmanager.url'};
    if ( !defined $url ) {
        my $cf = _file_text( $dev, '/etc/amtool/config.yml' ) // _file_text( $dev, '/root/.config/amtool/config.yml' ) // '';
        ($url) = $cf =~ /^\s*alertmanager\.url:\s*"?([^"\s]+)/m;
    }
    return ( 'amtool: error: required flag --alertmanager.url not provided', 0 ) unless defined $url;
    my $svc = _am_svc($dev);
    return ( qq{Post "$url/api/v2/silences": dial tcp: connect: connection refused}, 0 )
        unless $svc && $svc->{active} && $url =~ m{\Ahttps?://(?:localhost|127\.0\.0\.1|\[::1\])?(?::9093)?/?\z};
    my $now = now_epoch($dev);
    my $sil = $svc->{silences} //= [];
    $_ = _am_silence_view( $svc, $_, $now ) for @$sil;
    if ( $sub eq 'add' ) {
        my @m;
        for my $p (@pos) {
            my $m = _am_matcher($p) // ( $p =~ /\A[\w:.-]+\z/ ? { name => 'alertname', op => '=', value => $p } : undef );
            return ( qq{amtool: error: bad matcher format: $p}, 0 ) unless $m;
            push @m, $m;
        }
        return ( 'amtool: error: no matchers specified', 0 ) unless @m;
        return ( 'amtool: error: comment required by config', 0 ) unless defined $opt{comment} && length $opt{comment};
        my $start = defined $opt{start} ? _rfc3339( $opt{start} ) : $now;
        return ( qq{amtool: error: parsing time "$opt{start}" as "2006-01-02T15:04:05Z07:00": cannot parse}, 0 ) unless defined $start;
        my $end;
        if ( defined $opt{end} ) {
            $end = _rfc3339( $opt{end} ) // return ( qq{amtool: error: parsing time "$opt{end}" as "2006-01-02T15:04:05Z07:00": cannot parse}, 0 );
        }
        else {
            my $d = _godur( $opt{duration} // '1h' ) // return ( qq{amtool: error: time: invalid duration "$opt{duration}"}, 0 );
            $end = $start + $d;
        }
        return ( 'amtool: error: silence cannot end before it starts', 0 ) if $end <= $start;
        return ( 'amtool: error: silence cannot end in the past', 0 ) if $end <= $now;
        my $id = sprintf '%08x-%04x-4%03x-a%03x-%012x', 0x5e1e0000 + @$sil, 0x2026, scalar @$sil, 0x124, $start;
        push @$sil, _am_silence_view( $svc, { id => $id, matchers => [ map {"$_->{name}$_->{op}$_->{value}"} @m ], comment => $opt{comment},
            author => $opt{author} // 'root', _matchers => \@m, _start => $start, _end => $end }, $now );
        return ( $id, 1 );
    }
    if ( $sub eq 'query' || $sub eq '' ) {
        my @l = grep { $opt{expired} ? $_->{state} eq 'expired' : $_->{state} ne 'expired' } @$sil;
        return ( join( "\n", map { $_->{id} } @l ), 1 ) if $opt{quiet};
        my $f = '%-37s %-40s %-24s %-10s %s';
        return ( join( "\n", sprintf( $f, 'ID', 'Matchers', 'Ends At', 'Created By', 'Comment' ),
            map { sprintf( $f, $_->{id}, join( ' ', @{ $_->{matchers} } ), $_->{ends} =~ s/T/ /r =~ s/Z\z/ UTC/r, $_->{author}, $_->{comment} ) } @l ), 1 );
    }
    if ( $sub eq 'expire' ) {
        return ( 'amtool: error: no silence IDs specified', 0 ) unless @pos;
        for my $id (@pos) {
            my ($s) = grep { $_->{id} eq $id } @$sil or return ( qq{silence $id not found}, 0 );
            $s->{_expired} = 1;
            _am_silence_view( $svc, $s, $now );
        }
        return ( '', 1 );
    }
    push @GAPS, join( ' ', 'amtool silence', $sub, @$av );
    return ( '', 0 );
}

# amtool config routes [show] | config routes test [--verify.receivers=LISTE] LABEL…: Baum bzw.
# Empfaenger aus --config.file oder der laufenden Konfiguration (--alertmanager.url); Matcher je
# Route sortiert, ein Zweig nach dem ersten Treffer nur mit continue. () = Luecke
sub _amtool_routes {
    my ( $dev, $av ) = @_;
    my ( $file, $verify, @pos );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A--config\.file=(.*)\z/ ) { $file = $1 }
        elsif ( $x eq '--config.file' ) { $file = shift(@a) // return }
        elsif ( $x =~ /\A--verify\.receivers=(.*)\z/ ) { $verify = $1 }
        elsif ( $x eq '--verify.receivers' ) { $verify = shift(@a) // return }
        elsif ( $x =~ /\A--alertmanager\.url=/ ) { }
        elsif ( $x eq '--alertmanager.url' ) { shift @a }
        elsif ( $x =~ /\A-/ ) { return }
        else  { push @pos, $x }
    }
    my $sub = @pos && $pos[0] =~ /\A(?:show|test)\z/ ? shift @pos : 'show';
    return if $sub eq 'show' && @pos;
    my $text;
    if ( defined $file ) {
        $text = _file_text( $dev, $file );
        return ( "amtool: error: open $file: no such file or directory", 0 ) unless defined $text;
    }
    else {
        my $svc = _am_svc($dev) or return ( 'amtool: error: required flag --alertmanager.url not provided', 0 );
        return unless $svc->{active};
        my $main = $svc->{config_main} // ( ref $svc->{config} ? $svc->{config}[0] : $svc->{config} ) // return;
        $text = ( ref $svc->{running} eq 'HASH' ? $svc->{running}{$main} : undef ) // _file_text( $dev, $main ) // return;
    }
    my $e = _am_check_text($text);
    return ( "amtool: error: $e->[0]", 0 ) if @$e;
    my ($d) = _yaml($text);
    my $q = sub { my $v = shift; $v =~ s/(["\\])/\\$1/g; qq{"$v"} };
    my $route;
    $route = sub {
        my ( $r, $parent ) = @_;
        my @m;
        for my $s ( @{ ref $r->{matchers} eq 'ARRAY' ? $r->{matchers} : [] } ) { push @m, _am_matcher($s) // return }
        push @m, map { { name => $_, op => '=',  value => $r->{match}{$_} } } sort keys %{ ref $r->{match} eq 'HASH' ? $r->{match} : {} };
        push @m, map { { name => $_, op => '=~', value => $r->{match_re}{$_} } } sort keys %{ ref $r->{match_re} eq 'HASH' ? $r->{match_re} : {} };
        @m = sort { $a->{name} cmp $b->{name} || $a->{value} cmp $b->{value} || $a->{op} cmp $b->{op} } @m;
        my $node = { m => \@m, receiver => $r->{receiver} // $parent->{receiver}, continue => $r->{continue} && "$r->{continue}" =~ /\A(?:1|true)\z/ };
        for my $c ( grep { ref $_ eq 'HASH' } @{ $r->{routes} || [] } ) { push @{ $node->{kids} }, $route->( $c, $node ) // return }
        return $node;
    };
    my $root = $route->( $d->{route}, {} ) or return;
    if ( $sub eq 'show' ) {
        my @l = ( 'Routing tree:', '.' );
        my $tree;
        $tree = sub {
            my ( $n, $pre, $last ) = @_;
            my $slug = @{ $n->{m} } ? '{' . join( ',', map { $_->{name} . $_->{op} . $q->( $_->{value} ) } @{ $n->{m} } ) . '}' : 'default-route';
            $slug .= ', continue: true' if $n->{continue};
            push @l, $pre . ( $last ? '└── ' : '├── ' ) . "$slug  receiver: " . ( $n->{receiver} // '' );
            my @k = @{ $n->{kids} || [] };
            $tree->( $k[$_], $pre . ( $last ? '    ' : '│   ' ), $_ == $#k ) for 0 .. $#k;
        };
        $tree->( $root, '', 1 );
        return ( join( "\n", @l ), 1 );
    }
    my %lab;
    for (@pos) { my $m = _am_matcher($_) or return ( "amtool: error: bad matcher format: $_", 0 ); $lab{ $m->{name} } = $m->{value} }
    my $match;
    $match = sub {
        my ($n) = @_;
        return () unless _am_matches( $n->{m}, \%lab );
        my @all;
        for my $c ( @{ $n->{kids} || [] } ) {
            my @hit = $match->($c);
            push @all, @hit;
            last if @hit && !$c->{continue};
        }
        return @all ? @all : ($n);
    };
    my $slug = join ',', map { $_->{receiver} // '' } $match->($root);
    return ( "$slug\nWARNING: Expected receivers did not match resolved receivers.", 0 ) if defined $verify && length $verify && $verify ne $slug;
    return ( $slug, 1 );
}

sub amtool {
    my ( $dev, $av ) = @_;
    my @all = @$av;
    if ( ( $all[0] // '' ) eq 'config' && ( $all[1] // '' ) eq 'routes' ) {
        my @r = _amtool_routes( $dev, [ @all[ 2 .. $#all ] ] );
        return @r if @r;
        push @GAPS, join( ' ', 'amtool', @$av );
        return ( '', 0 );
    }
    if ( ( $all[0] // '' ) eq 'silence' ) {
        my $sub = defined $all[1] && $all[1] !~ /\A-/ ? $all[1] : '';
        return _amtool_silence( $dev, $sub, [ @all[ ( $sub eq '' ? 1 : 2 ) .. $#all ] ] );
    }
    if ( ( $all[0] // '' ) eq 'alert' && ( ( $all[1] // 'query' ) eq 'query' || $all[1] =~ /\A-/ ) ) {
        my $svc = _am_svc($dev) or return ( 'amtool: error: required flag --alertmanager.url not provided', 0 );
        my $now = now_epoch($dev);
        my $sil = $svc->{silences} || [];
        $_ = _am_silence_view( $svc, $_, $now ) for @$sil;
        my $t = $svc->{alert_targets} || {};
        my @rows;
        for my $a ( @{ $svc->{alerts} || [] } ) {
            my $lab = { %{ $t->{ $a->{target} // '' } || {} }, alertname => $a->{alertname} };
            next if grep { $_->{state} eq 'active' && _am_matches( $_->{_matchers}, $lab ) } @$sil;
            push @rows, sprintf( '%-22s %-26s %s', $a->{alertname}, $a->{since} // '2026-10-24 06:58:12 UTC', $a->{summary} // '' );
        }
        return ( join( "\n", sprintf( '%-22s %-26s %s', 'Alertname', 'Starts At', 'Summary' ), @rows ), 1 );
    }
    my @a = grep { !/\A--/ } @$av;
    my ( $cmd, @files ) = @a;
    if ( ( $cmd // '' ) ne 'check-config' ) { push @GAPS, join( ' ', 'amtool', @$av ); return ( '', 0 ) }
    my ( @out, $ok );
    $ok = 1;
    for my $f (@files) {
        push @out, "Checking '$f'";
        my $e = check_alertmanager( $dev, $f );
        if (@$e) { push @out, "  FAILED: $_" for @$e; $ok = 0; next }
        my ($d) = _yaml( _file_text( $dev, $f ) );
        push @out, '  SUCCESS', 'Found:', ' - global config', ' - route', ' - ' . scalar( @{ $d->{inhibit_rules} || [] } ) . ' inhibit rules',
            ' - ' . scalar( @{ $d->{receivers} || [] } ) . ' receivers', ' - 0 templates', '';
    }
    pop @out while @out && $out[-1] eq '';
    return ( join( "\n", @out ), $ok );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Monitoring - Monitoring on a simulated Linux server — checks Prometheus/Alertmanager, promtool, amtool

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator
  my ( $error, $reloaded ) = Langertha::Holmgang::Sim::Linux::Monitoring::service_check( $dev, $svc, 'prometheus' );
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Monitoring::promtool( $dev, \@argv );
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Monitoring::amtool( $dev, \@argv );
  my ( $body, $status ) = Langertha::Holmgang::Sim::Linux::Monitoring::http( $dev, 'GET', 9090, '/api/v1/rules', $run );

=head1 DESCRIPTION

Prometheus and Alertmanager on a device of type C<linux>
(cai-platform F<docs/entwurf-evals.md> §3.3.1). The services live under C<services> with
several files in C<config> (C<running> is then C<{ path => text }>) and
C<config_check: prometheus|alertmanager>; C<config_main> names the main file.

B<Prometheus>: The main file must be valid YAML; C<scrape_configs> with
C<job_name> (unique) and C<static_configs.targets> (C<host:port>);
C<rule_files> (patterns) load rule files: C<groups> with C<name> and C<rules>,
each rule C<alert> or C<record>, C<expr>, otherwise only C<for>, C<labels>,
C<annotations>, C<keep_firing_for>. An error prevents the start; on
C<reload> the old configuration stays and the journal shows
C<Error reloading config>. Loaded rule files are part of C<running>.

B<Alertmanager>: C<route> with C<receiver>; every receiver named in C<route> (also in
C<routes>) must be listed under C<receivers>.

B<promtool> C<check config|rules FILE…>, B<amtool> C<check-config FILE> —
output like the real tools. What Alertmanager has loaded is kept per
receiver under the service's C<_routes> (effective C<repeat_interval>,
C<group_wait>, C<group_interval>, C<group_by>; subroutes inherit).
B<amtool config routes> [C<show>] prints the routing tree and C<amtool config
routes test [--verify.receivers=LIST] LABEL…> the receivers an alert reaches,
from C<--config.file> or else the running configuration; a config that does
not load is an C<amtool: error>.
B<amtool silence add|query|expire> and C<amtool alert query> (with
C<--alertmanager.url> or F</etc/amtool/config.yml>; comment required; times
RFC 3339, C<--duration> as a Go duration, device clock in C<tz>, default
C<+02:00>): silences live under the service's C<silences>, each entry with
C<starts>/C<ends> (UTC), C<state> (pending|active|expired) and C<covers> — which
of the named label sets from C<alert_targets> they match; C<alerts> names the
firing alerts (C<alertname>, C<target>).

logrotate is modelled by L<Langertha::Holmgang::Sim::Linux::Logrotate>.

Pure functions on the state, neutral.

=head2 check_prometheus

  my ( $error, $rule_files, $rule_count ) = check_prometheus( $dev, $path );

=head2 check_alertmanager

  my $error = check_alertmanager( $dev, $path );

=head2 service_check

  my ( $journal_lines, $reloaded ) = service_check( $dev, $svc, 'prometheus'|'alertmanager' );

=head2 http

  my ( $body, $status ) = http( $dev, 'GET'|'POST', $port, $path, $run );

The HTTP interface of Prometheus (9090) and Alertmanager (9093) on the
device, from the running configuration: C</-/healthy>, C</-/ready>,
C</api/v1/status/config>, C</api/v1/status/flags> (from the running start
options), C</api/v1/rules>, C</api/v1/alerts> (empty: no rule fires), C<POST /-/reload> (only with
C<--web.enable-lifecycle>, otherwise 403), Alertmanager C</api/v2/status> and
C<POST /-/reload>. Without a
running service C<$status> is 0 (connection refused); anything else is a gap
(C<undef>).

=head2 promtool

  my ( $out, $ok ) = promtool( $dev, \@argv );

=head2 amtool

  my ( $out, $ok ) = amtool( $dev, \@argv );

=head2 now_epoch

  my $t = now_epoch($dev);

The device's clock (C<clock>, year 2026, zone C<tz>) as Unix time.

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
