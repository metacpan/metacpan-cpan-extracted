package Langertha::Holmgang::Sim::Linux::Redis;
# ABSTRACT: Redis on a simulated Linux server — redis-cli, CONFIG GET/SET/REWRITE, INFO, BGSAVE

use strict;
use warnings;
use utf8;

use JSON::MaybeXS ();
use Langertha::Holmgang::Shell ();
use Langertha::Holmgang::Sim::Linux ();

our $VERSION = '0.001';


our @GAPS;
our %REAL_CMD;    # echte Redis-Befehle ohne Nachbildung (unten)

# Vorgaben von Redis 7.0 (Debian 12); Werte wie CONFIG GET sie zeigt
our %DEFAULT = (
    bind                          => '127.0.0.1 -::1',
    port                          => '6379',
    'protected-mode'              => 'yes',
    requirepass                   => '',
    masterauth                    => '',
    masteruser                    => '',
    maxmemory                     => '0',
    'maxmemory-policy'            => 'noeviction',
    'maxmemory-samples'           => '5',
    maxclients                    => '10000',
    save                          => '3600 1 300 100 60 10000',
    appendonly                    => 'no',
    appendfsync                   => 'everysec',
    dir                           => '/var/lib/redis',
    dbfilename                    => 'dump.rdb',
    timeout                       => '0',
    'tcp-keepalive'               => '300',
    'tcp-backlog'                 => '511',
    databases                     => '16',
    loglevel                      => 'notice',
    logfile                       => '/var/log/redis/redis-server.log',
    daemonize                     => 'yes',
    supervised                    => 'auto',
    pidfile                       => '/run/redis/redis-server.pid',
    'stop-writes-on-bgsave-error' => 'yes',
    'rdbcompression'              => 'yes',
    'replica-read-only'           => 'yes',
    'replica-serve-stale-data'    => 'yes',
    'lazyfree-lazy-eviction'      => 'no',
    'slowlog-log-slower-than'     => '10000',
    'slowlog-max-len'             => '128',
    'notify-keyspace-events'      => '',
);

our %IMMUTABLE = map { $_ => 1 } qw( daemonize supervised databases pidfile );
our %BYTES     = map { $_ => 1 } qw( maxmemory );
our %BOOL      = map { $_ => 1 } qw( protected-mode appendonly daemonize stop-writes-on-bgsave-error rdbcompression
    replica-read-only replica-serve-stale-data lazyfree-lazy-eviction );
our %ENUM = (
    'maxmemory-policy' => [qw( volatile-lru allkeys-lru volatile-lfu allkeys-lfu volatile-random allkeys-random volatile-ttl noeviction )],
    appendfsync        => [qw( always everysec no )],
    loglevel           => [qw( debug verbose notice warning nothing )],
    supervised         => [qw( upstart systemd auto no )],
);
our %ALIAS = ( slaveof => 'replicaof', 'slave-read-only' => 'replica-read-only', 'slave-serve-stale-data' => 'replica-serve-stale-data' );

sub _bytes {
    my ($v) = @_;
    return undef unless defined $v && $v =~ /\A\s*(\d+)\s*(b|k|kb|m|mb|g|gb)?\s*\z/i;
    my %f = ( '' => 1, b => 1, k => 1000, kb => 1024, m => 1000_000, mb => 1024**2, g => 1000_000_000, gb => 1024**3 );
    return $1 * $f{ lc( $2 // '' ) };
}

sub _human_bytes {
    my ($n) = @_;
    for ( [ 1024**3, 'gb' ], [ 1024**2, 'mb' ], [ 1024, 'kb' ] ) {
        return ( $n / $_->[0] ) . $_->[1] if $n && $n % $_->[0] == 0;
    }
    return "$n";
}

sub _info_human {
    my ($n) = @_;
    for ( [ 1024**3, 'G' ], [ 1024**2, 'M' ], [ 1024, 'K' ] ) { return sprintf( '%.2f%s', $n / $_->[0], $_->[1] ) if $n >= $_->[0] }
    return "${n}B";
}

sub _file_text {
    my ( $dev, $p ) = @_;
    my $e = ( $dev->{files} || {} )->{$p};
    return undef unless defined $e;
    return ref $e eq 'HASH' ? $e->{content} // '' : $e;
}

sub _set_file {
    my ( $dev, $p, $t ) = @_;
    my $e = $dev->{files}{$p};
    if ( ref $e eq 'HASH' ) { my %n = %$e; delete @n{qw( size link )}; $n{content} = $t; $dev->{files}{$p} = \%n }
    else { $dev->{files}{$p} = $t }
    return;
}

# Wert pruefen und normalisieren: ( wert ) oder ( undef, fehlertext )
sub _check_value {
    my ( $k, $v ) = @_;
    $v //= '';
    if ( $BYTES{$k} ) {
        my $b = _bytes($v) // return ( undef, "argument must be a memory value" );
        return ("$b");
    }
    if ( $BOOL{$k} ) {
        my $x = lc $v;
        return ( undef, "argument must be 'yes' or 'no'" ) unless $x eq 'yes' || $x eq 'no';
        return ($x);
    }
    if ( my $l = $ENUM{$k} ) {
        my $x = lc $v;
        return ( undef, 'argument(s) must be one of the following: ' . join( ', ', @$l ) ) unless grep { $_ eq $x } @$l;
        return ($x);
    }
    if ( $k =~ /\A(?:port|maxclients|databases|timeout|tcp-keepalive|tcp-backlog|maxmemory-samples|slowlog-log-slower-than|slowlog-max-len)\z/ ) {
        return ( undef, 'argument couldn\'t be parsed into an integer' ) unless $v =~ /\A-?\d+\z/;
        return ("$v");
    }
    return ($v);
}


sub parse_conf {
    my ($text) = @_;
    my %v = %DEFAULT;
    my $n = 0;
    for my $line ( split /\n/, $text // '' ) {
        $n++;
        next if $line =~ /\A\s*(?:#|\z)/;
        my ( $k, $rest ) = $line =~ /\A\s*(\S+)\s*(.*?)\s*\z/;
        $k = lc $k;
        $k = $ALIAS{$k} // $k;
        next if $k eq 'include' || $k eq 'rename-command' || $k eq 'unixsocket' || $k eq 'unixsocketperm';
        ( my $val = $rest ) =~ s/\A"(.*)"\z/$1/;
        if ( $k eq 'replicaof' ) { $v{replicaof} = $val; next }
        if ( $k eq 'save' ) { $v{save} = $v{_save_seen}++ ? "$v{save} $val" : $val; $v{save} = '' if $val eq '""' || $val eq ''; next }
        return ( undef, $n, $line, 'Bad directive or wrong number of arguments' ) unless exists $DEFAULT{$k};
        my ( $x, $err ) = _check_value( $k, $k eq 'bind' ? $rest : $val );
        return ( undef, $n, $line, $err ) unless defined $x;
        $v{$k} = $x;
    }
    delete $v{_save_seen};
    return ( \%v );
}

sub _running {
    my ($dev) = @_;
    my $r = $dev->{redis};
    if ( !$r->{running} ) {
        my ($v) = parse_conf( _file_text( $dev, $r->{conf} // '/etc/redis/redis.conf' ) );
        $r->{running} = $v // {%DEFAULT};
    }
    return $r->{running};
}


sub conf_error {
    my ($dev) = @_;
    my $r = $dev->{redis} or return undef;
    my ( $v, $n, $line, $why ) = parse_conf( _file_text( $dev, $r->{conf} // '/etc/redis/redis.conf' ) );
    return undef if $v;
    return [ '*** FATAL CONFIG FILE ERROR (Redis 7.0.15) ***', "Reading the configuration file, at line $n", ">>> '$line'", $why ];
}


sub service_event {
    my ( $dev, $verb, $state ) = @_;
    my $r = $dev->{redis} or return;
    # beim Herunterfahren sichert Redis, wenn Sicherungspunkte gesetzt sind (scheitert es, ist der Rest weg)
    _bgsave($dev) if ( $verb eq 'restart' || $verb eq 'stop' ) && ( _running($dev)->{save} // '' ) ne '';
    if ( $verb eq 'start' || $verb eq 'restart' ) {
        my ($v) = parse_conf( _file_text( $dev, $r->{conf} // '/etc/redis/redis.conf' ) );
        $r->{running} = $v if $v;
        # was seit der letzten Sicherung dazukam, ist weg (RDB wird geladen); lost zaehlt es
        if ( $r->{saved} && JSON::MaybeXS->new( canonical => 1 )->encode( $r->{saved} ) ne JSON::MaybeXS->new( canonical => 1 )->encode( $r->{keys} || {} ) ) {
            my $diff = _keys_total($r) - do { my $n = 0; $n += $_ for values %{ $r->{saved} }; $n };
            $r->{lost} = ( $r->{lost} // 0 ) + ( $diff > 0 ? $diff : 1 ) if $verb eq 'restart' || $diff;
            $r->{keys} = { %{ $r->{saved} } };
            delete $r->{data};    # ungesicherte Einzelwerte sind ebenso weg
        }
        $r->{rdb_changes} = 0 if $r->{rdb_changes};
        $r->{rdb_ok} = JSON::MaybeXS::true() unless $r->{rdb_ok};
    }
    return;
}

sub _active {
    my ($dev) = @_;
    my $svc = ( $dev->{services} || {} )->{ $dev->{redis}{service} // 'redis-server' };
    return $svc && $svc->{active} ? 1 : 0;
}

sub _bound_to {
    my ( $dev, $host ) = @_;
    my $b = _running($dev)->{bind} // '';
    my @a = map { s/\A-//r } split /\s+/, $b;
    return 1 if grep { $_ eq '0.0.0.0' || $_ eq '*' } @a;
    $host = '127.0.0.1' if $host eq 'localhost';
    return scalar grep { $_ eq $host } @a;
}

sub _need_failing {
    my ( $dev, $needs ) = @_;
    return Langertha::Holmgang::Sim::Linux::_failing_need( $dev, { needs => $needs || [] } );
}

sub _bgsave {
    my ($dev) = @_;
    my $r = $dev->{redis};
    my $bad = _need_failing( $dev, $r->{fork_needs} ) || _need_failing( $dev, $r->{bgsave_needs} );
    if ($bad) {
        $r->{rdb_ok} = JSON::MaybeXS::false() if $r->{rdb_ok} // 1;
        return 0;
    }
    $r->{rdb_ok} = JSON::MaybeXS::true() unless $r->{rdb_ok};
    $r->{saved}  = { %{ $r->{keys} || {} } };
    # die Sicherung schreibt dir/dbfilename neu (temp-Datei, dann umbenannt: redis:redis 0660, neue Zeit)
    my $run = _running($dev);
    ( my $dir = $run->{dir} // '/var/lib/redis' ) =~ s{/+\z}{};
    my $p   = "$dir/" . ( $run->{dbfilename} // 'dump.rdb' );
    my $old = ref $dev->{files}{$p} eq 'HASH' ? $dev->{files}{$p} : {};
    $dev->{files}{$p} = { content => '', size => $old->{size} // '1M', owner => 'redis', group => 'redis', mode => '0660',
        mtime => Langertha::Holmgang::Sim::Linux::_clock($dev) };
    $r->{rdb_changes} = 0 if $r->{rdb_changes};
    $r->{lastsave} = ( $r->{lastsave} // 1792821600 ) + 60;
    return 1;
}

sub _keys_total { my ($r) = @_; my $n = 0; $n += $_ for values %{ $r->{keys} || {} }; return $n }

sub _info {
    my ( $dev, $sec ) = @_;
    my $r   = $dev->{redis};
    my $run = _running($dev);
    my $used = $r->{used_memory} // 1048576;
    my $max  = $run->{maxmemory} // 0;
    my %s;
    $s{server} = [ 'redis_version:7.0.15', 'redis_mode:standalone', 'os:Linux 6.1.0-26-amd64 x86_64', 'process_id:' . ( $r->{pid} // 811 ),
        "tcp_port:$run->{port}", 'uptime_in_seconds:' . ( $r->{uptime} // 1728000 ), 'uptime_in_days:' . int( ( $r->{uptime} // 1728000 ) / 86400 ),
        'executable:/usr/bin/redis-server', 'config_file:' . ( $r->{conf} // '/etc/redis/redis.conf' ) ];
    $s{clients} = [ 'connected_clients:' . ( $r->{clients} // 3 ), 'maxclients:' . ( $r->{effective_maxclients} // $run->{maxclients} ),
        'blocked_clients:0' ];
    $s{memory} = [ "used_memory:$used", 'used_memory_human:' . _info_human($used), 'used_memory_rss:' . int( $used * 1.08 ),
        'used_memory_peak:' . ( $r->{used_memory_peak} // $used ), "maxmemory:$max", 'maxmemory_human:' . _info_human($max),
        "maxmemory_policy:$run->{'maxmemory-policy'}", 'mem_fragmentation_ratio:1.08', 'mem_allocator:jemalloc-5.3.0' ];
    $s{persistence} = [ 'loading:0', 'rdb_changes_since_last_save:' . ( $r->{rdb_changes} // 0 ), 'rdb_bgsave_in_progress:0',
        'rdb_last_save_time:' . ( $r->{lastsave} // 1792821600 ), 'rdb_last_bgsave_status:' . ( ( $r->{rdb_ok} // 1 ) ? 'ok' : 'err' ),
        'rdb_last_bgsave_time_sec:' . ( ( $r->{rdb_ok} // 1 ) ? 2 : -1 ), 'aof_enabled:' . ( $run->{appendonly} eq 'yes' ? 1 : 0 ),
        'aof_last_write_status:ok' ];
    my $st = $r->{stats} || {};
    $s{stats} = [ 'total_connections_received:' . ( $st->{total_connections_received} // 912233 ), 'rejected_connections:' . ( $st->{rejected_connections} // 0 ),
        'expired_keys:' . ( $st->{expired_keys} // 0 ), 'evicted_keys:' . ( $st->{evicted_keys} // 0 ), 'keyspace_hits:' . ( $st->{keyspace_hits} // 1200443 ),
        'keyspace_misses:' . ( $st->{keyspace_misses} // 80211 ) ];
    if ( my $p = _replica_of( $dev ) ) {
        my $up = _link_up( $dev, $p );
        $s{replication} = [ 'role:slave', "master_host:$p->{host}", "master_port:$p->{port}", 'master_link_status:' . ( $up ? 'up' : 'down' ),
            'master_last_io_seconds_ago:' . ( $up ? 1 : -1 ), 'master_sync_in_progress:0', 'slave_read_only:1', 'connected_slaves:0' ];
    }
    else { $s{replication} = [ 'role:master', 'connected_slaves:' . ( $r->{connected_slaves} // 0 ), 'master_repl_offset:' . ( $r->{repl_offset} // 0 ) ] }
    $s{cpu} = [ 'used_cpu_sys:812.441201', 'used_cpu_user:1503.120044' ];
    $s{keyspace} = [ map { "$_:keys=$r->{keys}{$_},expires=0,avg_ttl=0" } grep { $r->{keys}{$_} } sort keys %{ $r->{keys} || {} } ];
    my @order = qw( server clients memory persistence stats replication cpu keyspace );
    my @want = !defined $sec || $sec eq '' || $sec =~ /\A(?:all|everything|default)\z/i ? @order : grep { $_ eq lc $sec } @order;
    return join "\n", map { ( '# ' . ucfirst($_), @{ $s{$_} }, '' ) } @want;
}

# Replikat: { host, port, primary } aus dem laufenden replicaof
sub _replica_of {
    my ($dev) = @_;
    my $ro = _running($dev)->{replicaof} // '';
    return undef unless $ro =~ /\A(\S+)\s+(\d+)\z/ && lc $1 ne 'no';
    my ( $host, $port ) = ( $1, $2 );
    # Primaer: das Geraet mit dieser Adresse (auch nach einer Umschaltung), sonst replica.primary
    my $state = $Langertha::Holmgang::Sim::Linux::CTX ? $Langertha::Holmgang::Sim::Linux::CTX->{state} : {};
    my ($by_addr) = grep { ref $state->{$_} eq 'HASH' && $state->{$_}{redis} && grep { $_ eq $host } _addrs( $state->{$_} ) } sort keys %$state;
    return { host => $host, port => $port, primary => $by_addr // ( $dev->{redis}{replica} || {} )->{primary} };
}

sub _addrs {
    my ($dev) = @_;
    return map { s{/\d+\z}{}r } map { @{ $_->{addr} || [] } } grep { ref eq 'HASH' } values %{ $dev->{interfaces} || {} };
}

# Verbindung zum Primaer steht, wenn es ihn gibt, er laeuft und masterauth zu seinem requirepass passt
sub _link_up {
    my ( $dev, $p ) = @_;
    my $state = $Langertha::Holmgang::Sim::Linux::CTX ? $Langertha::Holmgang::Sim::Linux::CTX->{state} : undef;
    my $pd = $state && defined $p->{primary} ? $state->{ $p->{primary} } : undef;
    return 0 unless $pd && $pd->{redis} && _active($pd);
    my $prun = _running($pd);
    return 0 unless _bound_to( $pd, $p->{host} ) && $prun->{port} eq $p->{port};
    return ( $prun->{requirepass} // '' ) eq '' || ( _running($dev)->{masterauth} // '' ) eq $prun->{requirepass} ? 1 : 0;
}

sub _glob_re { my ($g) = @_; ( my $re = quotemeta $g ) =~ s/\\\*/.*/g; $re =~ s/\\\?/./g; return qr/\A$re\z/i }

sub _fmt_bulk_list {
    my ( $raw, @v ) = @_;
    return '(empty array)' if !@v && !$raw;
    return join "\n", @v if $raw;
    my $i = 0;
    return join "\n", map { $i++; sprintf( '%d) "%s"', $i, $_ ) } @v;
}

sub _rewrite {
    my ($dev) = @_;
    my $r    = $dev->{redis};
    my $conf = $r->{conf} // '/etc/redis/redis.conf';
    my $text = _file_text( $dev, $conf );
    return 0 unless defined $text;
    my $run = _running($dev);
    my %seen;
    my $fmt = sub {
        my ($k) = @_;
        my $v = $run->{$k} // '';
        $v = _human_bytes($v) if $BYTES{$k};
        return $k eq 'save' && $v eq '' ? qq{save ""} : $v eq '' ? qq{$k ""} : "$k $v";
    };
    my @out;
    for my $line ( split /\n/, $text ) {
        my ($k) = $line =~ /\A\s*([A-Za-z][\w-]*)\s/;
        $k = $ALIAS{ lc( $k // '' ) } // lc( $k // '' );
        if ( length $k && ( exists $DEFAULT{$k} || $k eq 'replicaof' ) && $line !~ /\A\s*#/ ) {
            next if $seen{$k}++;    # doppelte Zeilen (save) fasst REWRITE zusammen
            push @out, $k eq 'replicaof' && !( $run->{replicaof} // '' ) ? () : $fmt->($k);
            next;
        }
        push @out, $line;
    }
    my @new = grep { !$seen{$_} && ( $run->{$_} // '' ) ne ( $DEFAULT{$_} // '' ) } sort keys %DEFAULT;
    push @new, 'replicaof' if !$seen{replicaof} && ( $run->{replicaof} // '' ) ne '';
    if (@new) {
        push @out, '# Generated by CONFIG REWRITE' unless grep { $_ eq '# Generated by CONFIG REWRITE' } @out;
        push @out, map { $fmt->($_) } @new;
    }
    _set_file( $dev, $conf, join( "\n", @out ) . "\n" );
    return 1;
}

sub _err { my ($m) = @_; return ( "(error) $m", 1 ) }

# Ein Befehl (Woerter) -> ( ausgabe, ok )
sub _command {
    my ( $dev, $w, $o ) = @_;
    my $r   = $dev->{redis};
    my $run = _running($dev);
    my @w   = @$w;
    my $cmd = uc( shift(@w) // '' );
    my $raw = $o->{raw};
    if ( $cmd eq 'AUTH' ) {
        my $pw = pop @w // '';
        return _err('ERR AUTH <password> called without any password configured for the default user. Are you sure your configuration is correct?')
            if ( $run->{requirepass} // '' ) eq '';
        return _err('WRONGPASS invalid username-password pair or user is disabled.') unless $pw eq $run->{requirepass};
        $o->{authed} = 1;
        return ( 'OK', 1 );
    }
    return _err('NOAUTH Authentication required.') if ( $run->{requirepass} // '' ) ne '' && !$o->{authed};
    return ( 'PONG', 1 ) if $cmd eq 'PING' && !@w;
    return ( $w[0], 1 ) if $cmd eq 'PING';
    if ( $cmd eq 'INFO' ) { return ( _info( $dev, $w[0] ), 1 ) }
    if ( $cmd eq 'DBSIZE' ) { my $db = $o->{db} // 0; return ( ( $raw ? '' : '(integer) ' ) . ( $r->{keys}{"db$db"} // 0 ), 1 ) }
    if ( $cmd eq 'LASTSAVE' ) { return ( ( $raw ? '' : '(integer) ' ) . ( $r->{lastsave} // 1792821600 ), 1 ) }
    if ( $cmd eq 'BGSAVE' || $cmd eq 'SAVE' ) {
        # fork scheitert: sofort ERR; Schreiben scheitert (Rechte, Platz): erst im Kind
        my $fork_bad = _need_failing( $dev, $r->{fork_needs} );
        my $ok = _bgsave($dev);
        return _err('ERR') if $fork_bad || ( $cmd eq 'SAVE' && !$ok );
        return ( $cmd eq 'SAVE' ? 'OK' : 'Background saving started', 1 );
    }
    if ( $cmd eq 'ROLE' ) {
        my $p = _replica_of($dev);
        return ( _fmt_bulk_list( $raw, 'slave', $p->{host}, $p->{port}, _link_up( $dev, $p ) ? 'connected' : 'connect' ), 1 ) if $p;
        return ( _fmt_bulk_list( $raw, 'master', $r->{repl_offset} // 0 ), 1 );
    }
    if ( $cmd eq 'REPLICAOF' || $cmd eq 'SLAVEOF' ) {
        return _err("ERR wrong number of arguments for '" . lc($cmd) . "' command") unless @w == 2;
        if ( uc $w[0] eq 'NO' && uc $w[1] eq 'ONE' ) { $run->{replicaof} = ''; return ( 'OK', 1 ) }
        return _err('ERR value is out of range, must be positive') unless $w[1] =~ /\A\d+\z/;
        $run->{replicaof} = "$w[0] $w[1]";
        return ( 'OK', 1 );
    }
    if ( $cmd eq 'ACL' && uc( $w[0] // '' ) eq 'WHOAMI' ) { return ( $raw ? 'default' : '"default"', 1 ) }
    if ( $cmd eq 'CLIENT' && uc( $w[0] // '' ) eq 'LIST' ) {
        my $n = $r->{clients} // 3;
        my @l = map { "id=$_ addr=" . ( $r->{client_addr} // '10.20.0.21' ) . ':' . ( 40000 + $_ ) . " laddr=127.0.0.1:6379 fd=" . ( 8 + $_ ) . " name= age=812 idle=0 flags=N db=0 cmd=get user=default" } 1 .. ( $n > 5 ? 5 : $n );
        return ( join( "\n", @l ), 1 );
    }
    if ( $cmd eq 'FLUSHALL' ) { $r->{flushed} = ( $r->{flushed} // 0 ) + _keys_total($r); $r->{keys} = {}; return ( 'OK', 1 ) }
    if ( $cmd eq 'FLUSHDB' ) { $r->{flushed} = ( $r->{flushed} // 0 ) + ( $r->{keys}{ 'db' . ( $o->{db} // 0 ) } // 0 ); delete $r->{keys}{ 'db' . ( $o->{db} // 0 ) }; return ( 'OK', 1 ) }
    # Daten: SET/GET/DEL/EXISTS/INCR/EXPIRE/TTL an einem kleinen Bestand (data); Schreiben ist bei
    # gescheiterter Sicherung gesperrt (MISCONF), bei voller Grenze ohne Verdraengung (OOM)
    if ( $cmd =~ /\A(?:SET|SETEX|DEL|INCR|EXPIRE|HSET|LPUSH|RPUSH)\z/ ) {
        return _err("ERR wrong number of arguments for '" . lc($cmd) . "' command") unless @w;
        return _err("READONLY You can't write against a read only replica.")
            if _replica_of($dev) && ( $run->{'replica-read-only'} // 'yes' ) eq 'yes';
        if ( !( $r->{rdb_ok} // 1 ) && ( $run->{'stop-writes-on-bgsave-error'} // 'yes' ) eq 'yes' && ( $run->{save} // '' ) ne '' ) {
            return _err('MISCONF Redis is configured to save RDB snapshots, but it\'s currently unable to persist to disk. Commands that may modify the data set are disabled, because this instance is configured to report errors during writes if RDB snapshotting fails (stop-writes-on-bgsave-error option). Please check the Redis logs for details about the RDB error.');
        }
        if ( ( $run->{maxmemory} // 0 ) > 0 && ( $r->{used_memory} // 0 ) >= $run->{maxmemory} && $run->{'maxmemory-policy'} eq 'noeviction' && $cmd ne 'DEL' && $cmd ne 'EXPIRE' ) {
            return _err("OOM command not allowed when used memory > 'maxmemory'.");
        }
        my $db = 'db' . ( $o->{db} // 0 );
        my $d = $r->{data} //= {};
        if ( $cmd eq 'DEL' ) {
            my $n = grep { delete $d->{$_} } @w;
            $r->{keys}{$db}-- , $r->{deleted}++ for 1 .. $n;
            return ( ( $raw ? '' : '(integer) ' ) . $n, 1 );
        }
        if ( $cmd eq 'EXPIRE' ) { return ( ( $raw ? '' : '(integer) ' ) . ( exists $d->{ $w[0] } ? 1 : 0 ), 1 ) }
        my $new = !exists $d->{ $w[0] };
        $d->{ $w[0] } = $cmd eq 'INCR' ? ( $d->{ $w[0] } // 0 ) + 1 : $cmd eq 'SETEX' ? $w[2] // '' : $w[1] // '';
        $r->{keys}{$db}++ if $new;
        $r->{rdb_changes} = ( $r->{rdb_changes} // 0 ) + 1;
        return ( $cmd eq 'INCR' ? ( $raw ? '' : '(integer) ' ) . $d->{ $w[0] } : $cmd =~ /PUSH|HSET/ ? ( $raw ? '' : '(integer) ' ) . 1 : 'OK', 1 );
    }
    if ( $cmd =~ /\A(?:GET|EXISTS|TTL|TYPE)\z/ ) {
        my $v = ( $r->{data} || {} )->{ $w[0] // '' };
        return ( ( $raw ? '' : '(integer) ' ) . ( defined $v ? 1 : 0 ), 1 ) if $cmd eq 'EXISTS';
        return ( ( $raw ? '' : '(integer) ' ) . ( defined $v ? -1 : -2 ), 1 ) if $cmd eq 'TTL';
        return ( defined $v ? 'string' : 'none', 1 ) if $cmd eq 'TYPE';
        return ( defined $v ? ( $raw ? $v : qq{"$v"} ) : $raw ? '' : '(nil)', 1 );
    }
    if ( $cmd eq 'SHUTDOWN' ) {
        my $svc = $dev->{services}{ $r->{service} // 'redis-server' };
        if ( $svc && $svc->{active} ) {
            my $nosave = grep { uc $_ eq 'NOSAVE' } @w;
            _bgsave($dev) unless $nosave;
            $svc->{active} = JSON::MaybeXS::false();
            $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1;
        }
        return ( '', 1 );
    }
    # DEBUG SLEEP s: der Befehl dauert s Sekunden; ab slowlog-log-slower-than (µs, >= 0)
    # ein Eintrag im Slowlog (Laufzeitspur _slowlog, hoechstens slowlog-max-len)
    if ( $cmd eq 'DEBUG' && uc( $w[0] // '' ) eq 'SLEEP' ) {
        my $s = $w[1] // '';
        return _err("ERR value is not a valid float") unless $s =~ /\A\d+(?:\.\d+)?\z/;
        my $us = int( $s * 1e6 ) + 12;
        my $lim = $run->{'slowlog-log-slower-than'} // 10000;
        if ( $lim =~ /\A\d+\z/ && $us >= $lim ) {
            my $now = defined $dev->{clock} ? do { Langertha::Holmgang::Sim::Linux::_part('Monitoring'); Langertha::Holmgang::Sim::Linux::Monitoring::now_epoch($dev) } : 1792821600;
            my $id = $r->{_slowlog_next} // 0;
            unshift @{ $r->{_slowlog} }, { id => $id, ts => $now, us => $us, args => [ 'DEBUG', 'SLEEP', $s ], client => '127.0.0.1:' . ( 43210 + $id ) };
            $r->{_slowlog_next} = $id + 1;
            my $max = $run->{'slowlog-max-len'} // 128;
            splice @{ $r->{_slowlog} }, $max if $max =~ /\A\d+\z/ && @{ $r->{_slowlog} } > $max;
        }
        return ( 'OK', 1 );
    }
    if ( $cmd eq 'SLOWLOG' ) {
        my $sub = uc( $w[0] // '' );
        my @e = @{ $r->{_slowlog} || [] };
        return ( ( $raw ? '' : '(integer) ' ) . scalar(@e), 1 ) if $sub eq 'LEN';
        if ( $sub eq 'RESET' ) { $r->{_slowlog} = []; return ( 'OK', 1 ) }
        return _err("ERR unknown subcommand '" . lc( $w[0] // '' ) . "'. Try SLOWLOG HELP.") unless $sub eq 'GET';
        my $n = $w[1] // 10;
        @e = @e[ 0 .. $n - 1 ] if $n =~ /\A\d+\z/ && @e > $n;
        return ( $raw ? '' : '(empty array)', 1 ) unless @e;
        if ($raw) { return ( join( "\n", map { ( $_->{id}, $_->{ts}, $_->{us}, @{ $_->{args} }, $_->{client}, '' ) } @e ), 1 ) }
        my @l;
        my $i = 0;
        for my $x (@e) {
            $i++;
            my $p = "$i) ";
            my $ind = ' ' x length $p;
            my $j = 0;
            my @args = map { $j++; ( $j == 1 ? '' : "$ind   " ) . "$j) \"$_\"" } @{ $x->{args} };
            push @l, "${p}1) (integer) $x->{id}", "${ind}2) (integer) $x->{ts}", "${ind}3) (integer) $x->{us}",
                "${ind}4) $args[0]", @args[ 1 .. $#args ], "${ind}5) \"$x->{client}\"", "${ind}6) \"\"";
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $cmd eq 'CONFIG' ) {
        my $sub = uc( shift(@w) // '' );
        if ( $sub eq 'GET' ) {
            return _err("ERR wrong number of arguments for 'config|get' command") unless @w;
            my @out;
            for my $pat (@w) {
                my $re = _glob_re( $ALIAS{ lc $pat } // $pat );
                for my $k ( sort keys %$run ) {
                    next unless $k =~ $re;
                    push @out, $k, $run->{$k} // '';
                }
            }
            return ( _fmt_bulk_list( $raw, @out ), 1 );
        }
        if ( $sub eq 'SET' ) {
            return _err("ERR wrong number of arguments for 'config|set' command") unless @w && @w % 2 == 0;
            my %new;
            while (@w) {
                my ( $k, $v ) = ( lc shift @w, shift @w );
                $k = $ALIAS{$k} // $k;
                return _err("ERR Unknown option or number of arguments for CONFIG SET - '$k'") unless exists $DEFAULT{$k} || $k eq 'replicaof';
                return _err("ERR CONFIG SET failed (possibly related to argument '$k') - can't set immutable config") if $IMMUTABLE{$k};
                return _err("ERR Unknown option or number of arguments for CONFIG SET - '$k'") if $k eq 'replicaof';
                my ( $x, $e ) = _check_value( $k, $v );
                return _err("ERR CONFIG SET failed (possibly related to argument '$k') - $e") unless defined $x;
                if ( $k eq 'bind' ) {    # jede Adresse muss gueltig und eine des Servers sein
                    my %own = map { s{/\d+\z}{}r => 1 } map { @{ $_->{addr} || [] } } values %{ $dev->{interfaces} || {} };
                    $own{'127.0.0.1'} = $own{'::1'} = 1;
                    for my $a ( split /\s+/, $x ) {
                        ( my $b = $a ) =~ s/\A-//;
                        next if $b eq '*' || $b eq '0.0.0.0' || $b eq '::' || $own{$b};
                        return _err("ERR CONFIG SET failed (possibly related to argument 'bind') - Failed to bind to specified addresses.");
                    }
                }
                $new{$k} = $x;
            }
            $run->{$_} = $new{$_} for keys %new;
            return ( 'OK', 1 );
        }
        if ( $sub eq 'REWRITE' ) {
            return _rewrite($dev) ? ( 'OK', 1 ) : _err("ERR Rewriting config file: No such file or directory");
        }
        if ( $sub eq 'RESETSTAT' ) { $r->{stats} = {}; return ( 'OK', 1 ) }
        return _err("ERR unknown subcommand '" . lc($sub) . "'. Try CONFIG HELP.");
    }
    # echter Redis-Befehl ohne Nachbildung: Luecke; sonst wie Redis: unbekannter Befehl
    if ( !$REAL_CMD{$cmd} ) {
        my $args = join ' ', map {"'$_'"} @w[ 0 .. ( $#w < 2 ? $#w : 2 ) ];
        return _err( "ERR unknown command '" . lc($cmd) . "', with args beginning with: " . ( length $args ? "$args " : '' ) );
    }
    push @GAPS, 'redis-cli ' . join( ' ', $cmd, @w );
    return ( '', 0 );
}

%REAL_CMD = map { $_ => 1 } qw( APPEND BITCOUNT BLPOP BRPOP COPY DECR DECRBY DUMP ECHO EVAL EVALSHA EXPIREAT GETDEL GETEX GETRANGE GETSET HDEL HEXISTS HGET
    HGETALL HINCRBY HKEYS HLEN HMGET HMSET HSCAN HVALS INCRBY INFO KEYS LINDEX LLEN LPOP LRANGE LREM MEMORY MGET MONITOR MOVE MSET OBJECT PERSIST PEXPIRE PTTL
    PUBLISH RANDOMKEY RENAME RPOP SADD SCAN SCARD SCRIPT SELECT SETNX SISMEMBER SLOWLOG SMEMBERS SREM STRLEN SUBSCRIBE SWAPDB TIME TOUCH UNLINK WAIT XADD XLEN
    XRANGE ZADD ZCARD ZRANGE ZREM ZSCORE LATENCY MODULE COMMAND DEBUG FAILOVER PSYNC SYNC LASTSAVE CLUSTER READONLY READWRITE RESET HELLO QUIT
    MULTI EXEC DISCARD WATCH UNWATCH PFADD PFCOUNT GEOADD );


sub redis_cli {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my %o = ( host => '127.0.0.1', port => undef );
    my @cmd;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-h' ) { $o{host} = shift @a }
        elsif ( $x eq '-p' ) { $o{port} = shift @a }
        elsif ( $x eq '-a' || $x eq '--pass' ) { $o{pass} = shift @a }
        elsif ( $x =~ /\A-a(.+)\z/ ) { $o{pass} = $1 }
        elsif ( $x eq '--user' ) { shift @a }
        elsif ( $x eq '-n' ) { $o{db} = shift @a }
        elsif ( $x eq '--raw' ) { $o{raw} = 1 }
        elsif ( $x eq '--no-auth-warning' || $x eq '--no-raw' || $x eq '-e' ) { }
        elsif ( $x eq '-u' ) {
            my $u = shift @a // '';
            if ( $u =~ m{\Aredis://(?:[^:@]*:([^@]*)@)?([^:/]+)(?::(\d+))?(?:/(\d+))?} ) { $o{pass} = $1; $o{host} = $2; $o{port} = $3; $o{db} = $4 }
        }
        elsif ( $x =~ /\A--(?:stat|bigkeys|memkeys|latency|scan|pipe|rdb|eval|cluster|ldb)/ || $x eq '-i' || $x eq '-r' || $x eq '-x' ) {
            push @GAPS, join( ' ', 'redis-cli', @$av );
            return ( '', 0 );
        }
        else { @cmd = ( $x, @a ); last }
    }
    my $r = $dev->{redis};
    return ( 'Could not connect to Redis at ' . $o{host} . ':' . ( $o{port} // 6379 ) . ': Connection refused', 1 ) unless $r && _active($dev);
    my $run = _running($dev);
    $o{port} //= $run->{port};
    return ( "Could not connect to Redis at $o{host}:$o{port}: Connection refused", 1 )
        unless $o{port} eq $run->{port} && ( _bound_to( $dev, $o{host} ) || ( $ctx->{host} // '' ) eq $o{host} && _bound_to( $dev, '127.0.0.1' ) );
    my $quiet = grep { $_ eq '--no-auth-warning' } @$av;
    my @warn = defined $o{pass} && !$quiet
        ? ('Warning: Using a password with \'-a\' or \'-u\' option on the command line interface may not be safe.') : ();
    if ( defined $o{pass} ) {
        my $rp = $run->{requirepass} // '';
        if ( $rp ne '' && $o{pass} eq $rp ) { $o{authed} = 1 }
        elsif ( $rp ne '' ) { return ( join( "\n", @warn, 'AUTH failed: WRONGPASS invalid username-password pair or user is disabled.' ), 1 ) }
    }
    # nach einer gescheiterten Sicherung versucht Redis es selbst alle paar Sekunden neu
    _bgsave($dev) if !( $r->{rdb_ok} // 1 ) && ( $run->{save} // '' ) ne '' && !_need_failing( $dev, $r->{bgsave_needs} ) && !_need_failing( $dev, $r->{fork_needs} );
    my @lines = @cmd ? ( [@cmd] ) : map { [ grep { !ref } Langertha::Holmgang::Shell::shell_words($_) ] } grep {/\S/} split /\n/, $stdin // '';
    if ( !@lines ) { push @GAPS, 'redis-cli (interaktiv)'; return ( '', 0 ) }
    my @out = @warn;
    for my $l (@lines) {
        my ( $t, $k ) = _command( $dev, $l, \%o );
        push @out, $t if defined $t && length $t;
        return ( join( "\n", @out ), 0 ) unless $k;
    }
    return ( join( "\n", @out ), 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Redis - Redis on a simulated Linux server — redis-cli, CONFIG GET/SET/REWRITE, INFO, BGSAVE

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator: redis-cli, effect of a service start/restart
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Redis::redis_cli( $dev, \@argv, $ctx, $stdin );
  Langertha::Holmgang::Sim::Linux::Redis::service_event( $dev, 'restart', $state );

=head1 DESCRIPTION

A Redis server (Debian 12, Redis 7.0) on a device of type C<linux>
(cai-platform F<docs/entwurf-evals.md> §3.3.1). The state lives under C<redis> of the device,
the configuration file under C<files>, the service under C<services> (name in
C<redis.service>):

  redis:
    service:  redis-server
    conf:     /etc/redis/redis.conf
    running:  { maxmemory: "2147483648", maxmemory-policy: noeviction, … }  # running values (bytes)
    keys:     { db0: 182344 }          # keys in memory
    saved:    { db0: 182344 }          # as of the last successful save (RDB)
    used_memory: 2147480000            # in use (bytes)
    clients:  41
    rdb_ok:   true                     # last save succeeded
    rdb_changes: 0                     # changes since the last save
    bgsave_needs: [ { state: …, regex: … }, { can: { user: redis, write: /var/lib/redis } } ]
    fork_needs:   [ … ]                # like a service's needs; without them BGSAVE succeeds
    replica:  { host: 10.20.0.31, port: 6379, primary: db-a }   # replica of (device primary)
    stats:    { evicted_keys: 0, rejected_connections: 0 }

Without C<running>, the file applies (with the defaults of Redis 7.0). A start
or restart of the service rereads the file. On shutdown
Redis saves (if C<save> is set); if that fails (C<bgsave_needs>), the
restart discards what was added since the last save (C<keys> = C<saved>). After
a failed save Redis retries on its own (here: on the
next call of C<redis-cli>, once the conditions hold). If the file is broken
(unknown directive, wrong value), the service does not start.

B<redis-cli> (C<-h>, C<-p>, C<-a>, C<--pass>, C<--user>, C<--no-auth-warning>,
C<-n>, C<--raw>, command as arguments or line by line on stdin): C<PING>,
C<AUTH>, C<INFO [section]>, C<CONFIG GET pattern>, C<CONFIG SET k v [k v …]>
(checked like Redis: unknown, immutable, list of values), C<CONFIG REWRITE>
(writes the running values to the file), C<CONFIG RESETSTAT>, C<DBSIZE>,
C<BGSAVE>, C<SAVE>, C<LASTSAVE>, C<SLOWLOG GET [n]|LEN|RESET>, C<DEBUG SLEEP s> (from
C<slowlog-log-slower-than> on, an entry in the slowlog, at most C<slowlog-max-len>), C<ROLE>, C<REPLICAOF|SLAVEOF host port|NO
ONE>, C<CLIENT LIST>, C<ACL WHOAMI>, C<SHUTDOWN> (stops the service),
C<FLUSHALL>/C<FLUSHDB> (empties, counts C<flushed>), C<SET>/C<GET>/C<DEL>/C<INCR>/C<EXISTS>
on a small store C<data> (writes refused with C<MISCONF> or C<OOM> like
Redis). A restart that discards unsaved data increments C<lost> — rules
check data loss on it instead of on the key count. Without a running service or on an address
Redis is not bound to: "Connection refused"; with C<requirepass> and no
password: C<NOAUTH>. Anything else is a B<simulation gap>.

Pure functions on the state, neutral.

=head2 parse_conf

  my ( $values, $lineno, $line, $reason ) = parse_conf( $text );

Reads a F<redis.conf> over the defaults of Redis 7.0: the values (as
C<CONFIG GET> shows them) or C<undef> with line and reason of the first error.

=head2 conf_error

  my $lines = conf_error( $dev );   # undef or [ journal lines ]

Error in the configuration file, as Redis reports it on start.

=head2 service_event

  service_event( $dev, 'start'|'restart'|'stop', $state );

Effect on Redis when its service starts, restarts or stops.

=head2 redis_cli

  my ( $out, $ok ) = redis_cli( $dev, \@argv, $ctx, $stdin );

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
