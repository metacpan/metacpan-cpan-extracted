package Langertha::Holmgang::Sim::Linux::Postgres;
# ABSTRACT: PostgreSQL on a simulated Linux server — psql, an SQL subset, pg_hba, settings, slots

use strict;
use warnings;
use utf8;

use Digest::MD5 ();
use JSON::MaybeXS ();
use Langertha::Holmgang::Sim::Linux::Calendar ();
use Time::Local ();

our $VERSION = '0.002';


my $JSON = JSON::MaybeXS->new( canonical => 1 );

# Simulationszeit (UTC-Sekunden) fuer now(); Zeitstempel als Text wie psql sie zeigt
our $NOW = 1792828800;    # 2026-10-24 08:00:00 UTC
sub _ts { my @t = gmtime( $_[0] ); return sprintf '%04d-%02d-%02d %02d:%02d:%02d+00', $t[5] + 1900, $t[4] + 1, @t[ 3, 2, 1, 0 ] }
sub _epoch {
    my ($v) = @_;
    return undef unless defined $v;
    if ( $v =~ /\A(\d{4})-(\d\d)-(\d\d)[ T](\d\d):(\d\d):(\d\d)(?:\.\d+)?(?:([+-])(\d\d))?/ ) {
        my $e = Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 );
        $e -= ( $7 eq '+' ? 1 : -1 ) * $8 * 3600 if defined $7;
        return $e;
    }
    return undef;
}

our @GAPS;

# Kontext der Einstellungen: postmaster (Neustart) / sighup (reload) / user.
our %CONTEXT = (
    max_connections => 'postmaster', shared_buffers => 'postmaster', listen_addresses => 'postmaster',
    superuser_reserved_connections => 'postmaster', max_wal_senders => 'postmaster', max_replication_slots => 'postmaster',
    port => 'postmaster', wal_level => 'postmaster', fsync => 'sighup', autovacuum => 'sighup',
    max_slot_wal_keep_size => 'sighup', wal_keep_size => 'sighup', max_wal_size => 'sighup',
    autovacuum_vacuum_scale_factor => 'sighup', autovacuum_naptime => 'sighup', log_min_duration_statement => 'superuser',
    idle_in_transaction_session_timeout => 'user', work_mem => 'user', statement_timeout => 'user',
    synchronous_commit => 'user', full_page_writes => 'sighup', password_encryption => 'user',
);

# Spalten der echten Katalog-Sichten (PostgreSQL 15); fehlt eine davon in der Nachbildung, ist das eine Luecke.
our %REAL_COLS = map { my ( $v, @c ) = split ' '; ( $v => { map { $_ => 1 } @c } ) } split /\n/, <<'EOT';
pg_stat_activity datid datname pid leader_pid usesysid usename application_name client_addr client_hostname client_port backend_start xact_start query_start state_change wait_event_type wait_event state backend_xid backend_xmin query_id query backend_type
pg_stat_user_tables relid schemaname relname seq_scan seq_tup_read idx_scan idx_tup_fetch n_tup_ins n_tup_upd n_tup_del n_tup_hot_upd n_live_tup n_dead_tup n_mod_since_analyze n_ins_since_vacuum last_vacuum last_autovacuum last_analyze last_autoanalyze vacuum_count autovacuum_count analyze_count autoanalyze_count
pg_settings name setting unit category short_desc extra_desc context vartype source min_val max_val enumvals boot_val reset_val sourcefile sourceline pending_restart
pg_replication_slots slot_name plugin slot_type datoid database temporary active active_pid xmin catalog_xmin restart_lsn confirmed_flush_lsn wal_status safe_wal_size two_phase
pg_stat_replication pid usesysid usename application_name client_addr client_hostname client_port backend_start backend_xmin state sent_lsn write_lsn flush_lsn replay_lsn write_lag flush_lag replay_lag sync_priority sync_state reply_time
pg_roles rolname rolsuper rolinherit rolcreaterole rolcreatedb rolcanlogin rolreplication rolconnlimit rolpassword rolvaliduntil rolbypassrls rolconfig oid
pg_file_settings sourcefile sourceline seqno name setting applied error
pg_authid oid rolname rolsuper rolinherit rolcreaterole rolcreatedb rolcanlogin rolreplication rolbypassrls rolconnlimit rolpassword rolvaliduntil
pg_database oid datname datdba encoding datlocprovider datistemplate datallowconn datconnlimit datfrozenxid datminmxid dattablespace datcollate datctype daticulocale datcollversion datacl
pg_tables schemaname tablename tableowner tablespace hasindexes hasrules hastriggers rowsecurity
pg_hba_file_rules line_number type database user_name address netmask auth_method options error
pg_class oid relname relnamespace reltype reloftype relowner relam relfilenode reltablespace relpages reltuples relallvisible reltoastrelid relhasindex relisshared relpersistence relkind relnatts relchecks relhasrules relhastriggers relhassubclass relrowsecurity relforcerowsecurity relispopulated relreplident relispartition relrewrite relfrozenxid relminmxid relacl reloptions relpartbound
EOT

sub _bytes {
    my ($v) = @_;
    return 0 unless defined $v;
    return $v if $v =~ /\A\d+\z/;
    my %u = ( K => 1024, M => 1024**2, G => 1024**3, T => 1024**4 );
    return $v =~ /\A(\d+(?:\.\d+)?)\s*([KMGT])B?\z/i ? int( $1 * $u{ uc $2 } ) : 0;
}

sub _pretty {
    my ($b) = @_;
    return "$b bytes" if $b < 10240;
    for my $u ( [ TB => 1024**4 ], [ GB => 1024**3 ], [ MB => 1024**2 ], [ kB => 1024 ] ) {
        return int( $b / $u->[1] + 0.5 ) . " $u->[0]" if $b >= 10 * $u->[1] || $u->[0] eq 'kB';
    }
    return "$b bytes";
}

# --- Konfiguration ------------------------------------------------------------

# Einstellungen von PostgreSQL 15: Typ, Einheit, Vorgabe (in der Einheit), Kategorie.
# pg_settings zeigt diese mit source default, wenn der Zustand sie nicht fuehrt.
our %GUC = map { my ( $n, $t, $u, $b, @c ) = split /\|/; ( $n => { vartype => $t, unit => $u, boot => $b, category => join( '|', @c ) } ) } split /\n/, <<'EOT';
listen_addresses|string||localhost|Connections and Authentication / Connection Settings
port|integer||5432|Connections and Authentication / Connection Settings
max_connections|integer||100|Connections and Authentication / Connection Settings
superuser_reserved_connections|integer||3|Connections and Authentication / Connection Settings
password_encryption|enum||scram-sha-256|Connections and Authentication / Authentication
shared_buffers|integer|8kB|16384|Resource Usage / Memory
work_mem|integer|kB|4096|Resource Usage / Memory
maintenance_work_mem|integer|kB|65536|Resource Usage / Memory
effective_cache_size|integer|8kB|524288|Query Tuning / Planner Cost Constants
random_page_cost|real||4|Query Tuning / Planner Cost Constants
wal_level|enum||replica|Write-Ahead Log / Settings
fsync|bool||on|Write-Ahead Log / Settings
synchronous_commit|enum||on|Write-Ahead Log / Settings
full_page_writes|bool||on|Write-Ahead Log / Settings
checkpoint_timeout|integer|s|300|Write-Ahead Log / Checkpoints
max_wal_size|integer|MB|1024|Write-Ahead Log / Checkpoints
max_wal_senders|integer||10|Replication / Sending Servers
max_replication_slots|integer||10|Replication / Sending Servers
wal_keep_size|integer|MB|0|Replication / Sending Servers
max_slot_wal_keep_size|integer|MB|-1|Replication / Sending Servers
autovacuum|bool||on|Autovacuum
autovacuum_naptime|integer|s|60|Autovacuum
autovacuum_vacuum_scale_factor|real||0.2|Autovacuum
log_min_duration_statement|integer|ms|-1|Reporting and Logging / When to Log
log_min_messages|enum||warning|Reporting and Logging / When to Log
log_statement|enum||none|Reporting and Logging / What to Log
log_lock_waits|bool||off|Reporting and Logging / What to Log
log_line_prefix|string||%m [%p] %q%u@%d |Reporting and Logging / What to Log
statement_timeout|integer|ms|0|Client Connection Defaults / Statement Behavior
lock_timeout|integer|ms|0|Client Connection Defaults / Statement Behavior
idle_in_transaction_session_timeout|integer|ms|0|Client Connection Defaults / Statement Behavior
deadlock_timeout|integer|ms|1000|Lock Management
EOT

# Wert in der Grundeinheit der Einstellung, wie pg_settings.setting ("16MB" -> 16384 bei kB)
sub _guc_base {
    my ( $name, $v ) = @_;
    my $u = ( $GUC{$name} || {} )->{unit} // '';
    return $v unless length $u && defined $v && $v =~ /\A\s*(-?\d+(?:\.\d+)?)\s*([a-zA-Z]+)\s*\z/;
    my ( $n, $vu ) = ( $1, $2 );
    my %mem = ( B => 1 / 1024, kB => 1, MB => 1024, GB => 1024**2, TB => 1024**3 );
    my %time = ( us => 0.001, ms => 1, s => 1000, min => 60000, h => 3600000, d => 86400000 );
    if ( $u =~ /\A(\d*)(kB|MB)\z/ ) {
        my $base = ( length $1 ? $1 : 1 ) * $mem{$2};
        return defined $mem{$vu} ? int( $n * $mem{$vu} / $base ) : $v;
    }
    my $base = $time{$u} // return $v;
    return defined $time{$vu} ? int( $n * $time{$vu} / $base ) : $v;
}

# Millisekunden eines Zeitwerts (log_min_duration_statement: "250", "250ms", "1s")
sub _ms { my ($v) = @_; return undef unless defined $v; return $v =~ /\A\s*-?\d+\s*\z/ ? 0 + $v : _guc_base( 'deadlock_timeout', $v ) }

sub _file {
    my ( $dev, $path ) = @_;
    my $f = ( $dev->{files} || {} )->{ $path // '' };
    return ref $f eq 'HASH' ? $f->{content} // '' : $f;
}

sub _set_file {
    my ( $dev, $path, $text ) = @_;
    my $f = $dev->{files}{$path};
    if ( ref $f eq 'HASH' ) { $f->{content} = $text } else { $dev->{files}{$path} = $text }
}

sub _conf_values {
    my ($text) = @_;
    my %v;
    for my $l ( split /\n/, $text // '' ) {
        $l =~ s/#.*//;
        next unless $l =~ /\A\s*([a-z_]+)\s*=?\s*(?:'([^']*)'|(\S+))/;
        $v{$1} = defined $2 ? $2 : $3;
    }
    return \%v;
}

sub _file_settings {
    my ( $pg, $dev ) = @_;
    return { %{ _conf_values( _file( $dev, $pg->{conf} ) ) }, %{ _conf_values( _file( $dev, $pg->{auto_conf} ) ) } };
}

sub _norm_val { my ($v) = @_; $v = lc $v; return { true => 'on', yes => 'on', 1 => 'on', false => 'off', no => 'off', 0 => 'off' }->{$v} // $v }

# reload: sighup-Einstellungen und pg_hba neu; postmaster-Einstellungen nur bei $restart.
sub _apply_config {
    my ( $dev, $restart ) = @_;
    my $pg = $dev->{postgres};
    my $want = _file_settings( $pg, $dev );
    my $s = $pg->{settings} //= {};
    my %pending;
    for my $k ( sort keys %$want ) {
        next unless exists $s->{$k} || exists $CONTEXT{$k};    # z. B. data_directory: nicht gefuehrt
        my $ctx = $CONTEXT{$k} // 'sighup';
        my $v = $want->{$k};
        $v = _norm_val($v) if defined $s->{$k} && $s->{$k} =~ /\A(?:on|off)\z/;
        next if defined $s->{$k} && "$s->{$k}" eq "$v";
        if ( $ctx eq 'postmaster' && !$restart ) { $pending{$k} = 1; next }
        $s->{$k} = $v =~ /\A\d+\z/ ? 0 + $v : $v;
    }
    if ( %pending ) { $pg->{pending_restart} = [ sort keys %pending ] }
    else            { delete $pg->{pending_restart} }
    my $hba = _file( $dev, $pg->{hba} );
    $pg->{hba_loaded} = [ grep { length } map { s/#.*//r =~ s/\A\s+|\s+\z//gr =~ s/\s+/ /gr } split /\n/, $hba ] if defined $hba;
    return;
}


sub service_event {
    my ( $dev, $name, $verb, $state, $host ) = @_;
    my $pg = $dev->{postgres};
    if ( $pg && ( $pg->{service} // '' ) eq $name ) {
        if ( $verb eq 'reload' ) { _apply_config( $dev, 0 ) }
        # Herunterfahren: Checkpoint, alle Verbindungen enden
        elsif ( $verb eq 'stop' ) { _checkpoint( $pg, $dev ); $pg->{activity} = [] if @{ $pg->{activity} || [] } }
        else { _checkpoint( $pg, $dev ); _apply_config( $dev, 1 ); $pg->{activity} = [] if @{ $pg->{activity} || [] } }
    }
    # Clients: ein Dienst mit pg_connect verbindet sich nach (Neu-)Start neu
    my $svc = ( $dev->{services} || {} )->{$name} or return;
    my $c = $svc->{pg_connect} or return;
    my $srv = $state->{ $c->{server} // '' };
    return unless ref $srv eq 'HASH' && $srv->{postgres};
    my $act = $srv->{postgres}{activity} //= [];
    my @keep = grep { !( ( $_->{host} // '' ) eq ( $host // '' ) && ( $_->{service} // '' ) eq $name ) } @$act;
    @$act = @keep if @keep != @$act;
    return if $verb eq 'stop';
    my $text = _file( $dev, $c->{file} ) // '';
    my ($port) = $c->{port_regex} && $text =~ /$c->{port_regex}/ ? ($1) : ( $c->{port} // 5432 );
    my $n = ( $c->{per_port} || {} )->{$port} // 0;
    push @$act, { pid => $c->{pid} // 5001, ( $n > 1 ? ( count => $n ) : () ), usename => $c->{user}, datname => $c->{db},
        client_addr => $c->{addr}, application_name => $c->{application_name} // $name, state => 'idle', host => $host, service => $name } if $n;
    return;
}

# Verbindungen: Eintraege mit count stehen fuer so viele gleiche ab pid.
sub _activity_rows {
    my ($pg) = @_;
    return map { my $a = $_; map { { %$a, pid => $a->{pid} + $_ } } 0 .. ( $a->{count} // 1 ) - 1 } @{ $pg->{activity} || [] };
}

sub _activity_n { my ($pg) = @_; my $n = 0; $n += $_->{count} // 1 for @{ $pg->{activity} || [] }; return $n }

# --- Rollen und Rechte --------------------------------------------------------

sub _role { my ( $pg, $r ) = @_; return $pg->{roles}{$r} }

sub _is_super { my ( $pg, $r ) = @_; my $x = _role( $pg, $r ); return $x && $x->{superuser} ? 1 : 0 }

sub _memberships {
    my ( $pg, $r ) = @_;
    my %seen = ( $r => 1 );
    my @todo = ($r);
    while ( defined( my $x = shift @todo ) ) {
        for my $g ( sort keys %{ $pg->{members} || {} } ) {
            next unless grep { $_ eq $x } @{ $pg->{members}{$g} };
            push @todo, $g unless $seen{$g}++;
        }
    }
    return keys %seen;
}

sub _has_priv {
    my ( $pg, $user, $obj, $priv ) = @_;
    return 1 if _is_super( $pg, $user );
    my $owner = $obj =~ /\Atable:(.+)\z/ ? ( $pg->{tables}{$1} || {} )->{owner}
        : $obj =~ /\Aschema:(.+)\z/   ? ( $pg->{schemas}{$1} || {} )->{owner}
        : $obj =~ /\Adatabase:(.+)\z/ ? ( $pg->{databases}{$1} || {} )->{owner} : undef;
    my @who = ( _memberships( $pg, $user ), 'PUBLIC' );
    return 1 if defined $owner && grep { $_ eq $owner } @who;
    my $g = ( $pg->{grants} || {} )->{$obj} || {};
    return scalar grep { my $w = $_; grep { $_ eq $priv || $_ eq 'ALL' } @{ $g->{$w} || [] } } @who;
}

# --- Verbindung ---------------------------------------------------------------

sub _ip_of {
    my ($dev) = @_;
    for my $i ( sort keys %{ $dev->{interfaces} || {} } ) {
        next if $i eq 'lo';
        my ($a) = @{ $dev->{interfaces}{$i}{addr} || [] };
        return $1 if defined $a && $a =~ m{\A([\d.]+)/};
    }
    return '127.0.0.1';
}

sub _in_cidr {
    my ( $ip, $cidr ) = @_;
    my ( $net, $len ) = split m{/}, $cidr;
    $len //= 32;
    my $n = sub { my $x = 0; $x = $x * 256 + $_ for split /\./, $_[0]; $x };
    return 0 unless $ip =~ /\A[\d.]+\z/ && $net =~ /\A[\d.]+\z/;
    my $mask = $len ? ( 0xffffffff << ( 32 - $len ) ) & 0xffffffff : 0;
    return ( $n->($ip) & $mask ) == ( $n->($net) & $mask );
}

# erste passende pg_hba-Zeile: ( methode, zeilennummer ) oder ()
sub _hba_match {
    my ( $pg, $kind, $db, $user, $ip ) = @_;
    my $i = 0;
    for my $l ( @{ $pg->{hba_loaded} || [] } ) {
        $i++;
        my @f = split / /, $l;
        my $type = shift @f;
        next unless $kind eq 'local' ? $type eq 'local' : $type =~ /\Ahost(?:ssl)?\z/;
        my ( $dbs, $users ) = ( shift @f, shift @f );
        my $addr = $type eq 'local' ? undef : shift @f;
        $addr .= '/' . _masklen( shift @f ) if defined $addr && $addr !~ m{/|\A(?:all|samehost|samenet)\z} && @f && $f[0] =~ /\A\d+\.\d+\.\d+\.\d+\z/;
        my $method = shift(@f) // 'reject';
        next unless grep { $_ eq 'all' || $_ eq $db || ( $_ eq 'sameuser' && $db eq $user ) } split /,/, $dbs;
        next unless grep { $_ eq 'all' || $_ eq $user || ( /\A\+(.+)\z/ && grep { $_ eq $1 } _memberships( $pg, $user ) ) } split /,/, $users;
        if ( defined $addr ) {
            next unless $addr eq 'all' || $addr eq 'samehost' && $ip eq '127.0.0.1' || $addr =~ m{/} && _in_cidr( $ip, $addr );
        }
        return ( $method, $i );
    }
    return ();
}

sub _masklen { my ($m) = @_; my $n = 0; $n += unpack( '%32b*', pack( 'C', $_ ) ) for split /\./, $m; return $n }

# Verbindung aufbauen: ( undef, $sitzung ) oder ( fehlertext )
sub _connect {
    my ( $srv, $o ) = @_;
    my $pg  = $srv->{postgres};
    my $svc = ( $srv->{services} || {} )->{ $pg->{service} // '' };
    my $where = $o->{remote}
        ? qq{connection to server at "$o->{hostname}" ($o->{server_ip}), port $o->{port} failed}
        : qq{connection to server on socket "/var/run/postgresql/.s.PGSQL.$o->{port}" failed};
    return "psql: error: $where: Connection refused\n\tIs the server running on that host and accepting TCP/IP connections?"
        if $o->{remote} && !( $svc && $svc->{active} );
    return "psql: error: $where: No such file or directory\n\tIs the server running locally and accepting connections on that socket?"
        unless $svc && $svc->{active};
    my ( $user, $db ) = ( $o->{user}, $o->{db} );
    my $enc = $o->{remote} ? 'SSL encryption' : 'no encryption';
    my ( $method ) = _hba_match( $pg, $o->{remote} ? 'host' : 'local', $db, $user, $o->{client_ip} );
    my $who = $o->{remote} ? qq{host "$o->{client_ip}", } : '';
    return qq{psql: error: $where: FATAL:  no pg_hba.conf entry for ${who}user "$user", database "$db", $enc} unless $method;
    return qq{psql: error: $where: FATAL:  pg_hba.conf rejects connection for ${who}user "$user", database "$db", $enc}
        if $method eq 'reject';
    my $role = _role( $pg, $user );
    if ( $method eq 'peer' ) {
        return qq{psql: error: $where: FATAL:  role "$user" does not exist} unless $role;
        return qq{psql: error: $where: FATAL:  Peer authentication failed for user "$user"} if ( $o->{os_user} // 'root' ) ne $user;
    }
    elsif ( $method =~ /\A(?:md5|scram-sha-256|password)\z/ ) {
        return qq{psql: error: $where: FATAL:  password authentication failed for user "$user"} unless $role && $role->{password};
    }
    return qq{psql: error: $where: FATAL:  role "$user" does not exist} unless $role;
    return qq{psql: error: $where: FATAL:  role "$user" is not permitted to log in} unless $role->{login} || $role->{superuser};
    return qq{psql: error: $where: FATAL:  database "$db" does not exist} unless ( $pg->{databases} || {} )->{$db} || $db eq 'postgres';
    my $n = _activity_n($pg);
    my $max = $pg->{settings}{max_connections} // 100;
    my $res = $pg->{settings}{superuser_reserved_connections} // 3;
    return "psql: error: $where: FATAL:  sorry, too many clients already" if $n >= $max;
    return "psql: error: $where: FATAL:  remaining connection slots are reserved for non-replication superuser connections"
        if $n >= $max - $res && !$role->{superuser};
    return qq{psql: error: $where: FATAL:  permission denied for database "$db"\nDETAIL:  User does not have CONNECT privilege.}
        if $db ne 'postgres' && !_has_priv( $pg, $user, "database:$db", 'CONNECT' );
    return ( undef, { user => $user, db => $db } );
}


sub psql {
    my ( $dev, $av, $ctx, $os_user ) = @_;
    $os_user //= 'root';
    my %o = ( user => $os_user, port => 5432 );
    my ( @cmds, $list, %fmt, $db );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-c' || $x eq '--command' ) { push @cmds, shift(@a) // '' }
        elsif ( $x =~ /\A--command=(.*)\z/s )      { push @cmds, $1 }
        elsif ( $x =~ /\A-c(.+)\z/s )              { push @cmds, $1 }
        elsif ( $x eq '-U' || $x eq '--username' ) { $o{user} = shift @a }
        elsif ( $x =~ /\A-U(.+)\z/ || $x =~ /\A--username=(.+)\z/ ) { $o{user} = $1 }
        elsif ( $x eq '-d' || $x eq '--dbname' )   { $db = shift @a }
        elsif ( $x =~ /\A-d(.+)\z/ || $x =~ /\A--dbname=(.+)\z/ ) { $db = $1 }
        elsif ( $x eq '-h' || $x eq '--host' )     { $o{host} = shift @a }
        elsif ( $x =~ /\A-h(.+)\z/ || $x =~ /\A--host=(.+)\z/ ) { $o{host} = $1 }
        elsif ( $x eq '-p' || $x eq '--port' )     { $o{port} = shift @a }
        elsif ( $x =~ /\A-p(\d+)\z/ || $x =~ /\A--port=(\d+)\z/ ) { $o{port} = $1 }
        elsif ( $x eq '-l' || $x eq '--list' )     { $list = 1 }
        elsif ( $x eq '-f' || $x eq '--file' )     { push @GAPS, 'psql -f'; return ( '', 0 ) }
        elsif ( $x =~ /\A-([tAxXqwW]+)c\z/ )       { $fmt{$_} = 1 for split //, $1; push @cmds, shift(@a) // q{} }    # -Atc 'sql'
        elsif ( $x =~ /\A-([tAxXqwW]+)\z/ )        { $fmt{$_} = 1 for split //, $1 }
        elsif ( $x =~ /\A--(?:tuples-only|no-align|expanded|no-psqlrc|quiet)\z/ ) { $fmt{ { 'tuples-only' => 't', 'no-align' => 'A', expanded => 'x' }->{ substr $x, 2 } // 'X' } = 1 }
        elsif ( $x =~ /\A-v\z|\A--set\z/ )         { shift @a }
        elsif ( $x =~ /\Apostgres(?:ql)?:\/\/(?:([^:@\/]+)(?::[^@\/]*)?@)?([^:\/?]+)?(?::(\d+))?(?:\/([^?]+))?/ ) {
            $o{user} = $1 if defined $1;
            $o{host} = $2 if defined $2;
            $o{port} = $3 if defined $3;
            $db = $4 if defined $4;
        }
        elsif ( $x =~ /\A\s*\w+\s*=/ && $x !~ /\A-/ ) {    # libpq: "host=db1 dbname=appdb user=report"
            my %kv = $x =~ /(\w+)\s*=\s*('(?:[^'\\]|\\.)*'|\S*)/g;
            s/\A'|'\z//g for values %kv;
            $o{host} = $kv{host} // $kv{hostaddr} if defined( $kv{host} // $kv{hostaddr} );
            $o{port} = $kv{port} if defined $kv{port};
            $o{user} = $kv{user} if defined $kv{user};
            $db = $kv{dbname} if defined $kv{dbname};
        }
        elsif ( $x !~ /\A-/ )                      { if ( !defined $db ) { $db = $x } else { $o{user} = $x } }
        else  { return ( "psql: error: unrecognized option '$x'\nTry \"psql --help\" for more information.", 0 ) }
    }
    if ( !@cmds && !$list ) { push @GAPS, 'psql (interaktiv)'; return ( '', 0 ) }
    $o{db} = $db // $o{user};
    $o{db} = 'postgres' if $list && !defined $db;
    $o{os_user} = $os_user;

    # Ziel: eigener Server (Socket oder eigene Adresse) oder ein anderes Geraet
    my $srv = $dev;
    if ( defined $o{host} && $o{host} !~ m{\A/} ) {
        my $h = $o{host};
        my $self = $h eq 'localhost' || $h eq '127.0.0.1' || $h eq ( $ctx->{host} // '' ) || $h eq _ip_of($dev);
        if ( !$self ) {
            my ($name) = grep { $_ eq $h || _ip_of( $ctx->{state}{$_} ) eq $h } grep { ref $ctx->{state}{$_} eq 'HASH' && ( $ctx->{state}{$_}{type} // '' ) eq 'linux' } sort keys %{ $ctx->{state} || {} };
            return ( qq{psql: error: could not translate host name "$h" to address: Name or service not known}, 0 ) unless defined $name;
            $srv = $ctx->{state}{$name};
            @o{qw( remote hostname server_ip client_ip )} = ( 1, $h, _ip_of($srv), _ip_of($dev) );
        }
        else { @o{qw( remote hostname server_ip client_ip )} = ( 1, $h, '127.0.0.1', '127.0.0.1' ) }
    }
    my $pg = $srv->{postgres};
    if ( !$pg || ( $pg->{port} // 5432 ) != $o{port} ) {
        if ( $pg && $o{port} == ( $pg->{pooler_port} // 0 ) ) { push @GAPS, 'psql über pgbouncer'; return ( '', 0 ) }
        my $where = $o{remote} ? qq{connection to server at "$o{hostname}" ($o{server_ip}), port $o{port} failed} : qq{connection to server on socket "/var/run/postgresql/.s.PGSQL.$o{port}" failed};
        return ( "psql: error: $where: " . ( $o{remote} ? "Connection refused\n\tIs the server running on that host and accepting TCP/IP connections?" : "No such file or directory\n\tIs the server running locally and accepting connections on that socket?" ), 0 );
    }
    my ( $err, $sess ) = _connect( $srv, \%o );
    return ( $err, 0 ) if $err;
    $sess->{fmt} = \%fmt;
    $sess->{srv} = $srv;
    return _out( _list_dbs( $pg, $sess ) ) if $list;
    my ( @out, $ok );
    $ok = 1;
    for my $c (@cmds) {
        for my $st ( _split_sql($c) ) {
            my ( $t, $k ) = _statement( $pg, $sess, $st );
            push @out, $t if defined $t && length $t;
            if ( !$k ) { $ok = 0; last }
        }
        last unless $ok;
    }
    return ( join( "\n", @out ), $ok );
}

sub _out { return ( $_[0], 1 ) }

sub _split_sql {
    my ($s) = @_;
    my ( @out, $cur, $q ) = ( (), '', '' );
    for my $ch ( split //, $s ) {
        if ($q) { $cur .= $ch; $q = '' if $ch eq $q; next }
        if ( $ch eq "'" || $ch eq '"' ) { $q = $ch; $cur .= $ch; next }
        if ( $ch eq ';' ) { push @out, $cur; $cur = ''; next }
        if ( $ch eq "\n" && $cur =~ /\A\s*\\/ ) { push @out, $cur; $cur = ''; next }
        $cur .= $ch;
    }
    push @out, $cur;
    return grep {/\S/} map { s/\A\s+|\s+\z//gr } @out;
}

# --- Ausgabe wie psql --------------------------------------------------------

sub _table {
    my ( $sess, $cols, $rows, %o ) = @_;
    my $f = $sess->{fmt} || {};
    my @r = map { [ map { defined $_ ? "$_" : '' } @$_ ] } @$rows;
    if ( $f->{x} ) {
        my $w = 0;
        for (@$cols) { $w = length if length > $w }
        my @l;
        my $i = 0;
        for my $row (@r) {
            $i++;
            push @l, "-[ RECORD $i ]" . ( '-' x ( $w + 2 ) ) unless $f->{t};
            push @l, sprintf( "%-${w}s | %s", $cols->[$_], $row->[$_] ) for 0 .. $#$cols;
        }
        return join "\n", @l ? @l : $f->{t} ? () : '(0 rows)';
    }
    if ( $f->{A} ) {
        return join "\n", ( $f->{t} ? () : join( '|', @$cols ) ), ( map { join '|', @$_ } @r ),
            ( $f->{t} ? () : '(' . @r . ' row' . ( @r == 1 ? '' : 's' ) . ')' );
    }
    # wie psql: Kopf zentriert, Zahlen rechtsbuendig, letzte Spalte ohne Fuellung rechts
    my @w = map { length $cols->[$_] } 0 .. $#$cols;
    for my $row (@r) { for ( 0 .. $#$cols ) { $w[$_] = length $row->[$_] if length $row->[$_] > $w[$_] } }
    my @num = $o{text} ? () : map { my $i = $_; @r && !grep { $_->[$i] !~ /\A-?\d+(?:\.\d+)?\z/ } @r } 0 .. $#$cols;
    my $line = sub {
        my ($v) = @_;
        my $t = join '|', map {
            my $x = $num[$_] ? sprintf( "%$w[$_]s", $v->[$_] ) : $_ == $#$cols ? $v->[$_] : sprintf( "%-$w[$_]s", $v->[$_] );
            ' ' . $x . ( $_ == $#$cols ? '' : ' ' );
        } 0 .. $#$cols;
        return $t;
    };
    my @l;
    if ( !$f->{t} ) {
        push @l, join '|', map { my $p = $w[$_] - length $cols->[$_]; ' ' . ( ' ' x int( $p / 2 ) ) . $cols->[$_] . ( ' ' x ( $p - int( $p / 2 ) ) ) . ' ' } 0 .. $#$cols;
        push @l, join '+', map { '-' x ( $_ + 2 ) } @w;
    }
    push @l, map { $line->($_) } @r;
    push @l, '(' . @r . ' row' . ( @r == 1 ? '' : 's' ) . ')' unless $f->{t};
    return join "\n", @l;
}

sub _list_dbs {
    my ( $pg, $sess ) = @_;
    my @db = ( 'postgres', sort keys %{ $pg->{databases} || {} } );
    my %seen;
    return _table( $sess, [qw( Name Owner Encoding Collate Ctype )],
        [ map { [ $_, ( $pg->{databases}{$_} || {} )->{owner} // 'postgres', 'UTF8', 'C.UTF-8', 'C.UTF-8' ] } grep { !$seen{$_}++ } @db ] );
}

# --- Sichten -----------------------------------------------------------------

sub _wal_needed {
    my ($pg) = @_;
    my $keep = 0;
    for my $s ( values %{ $pg->{slots} || {} } ) {
        my $r = _bytes( $s->{retained} );
        $keep = $r if $r > $keep && !$s->{invalidated};
    }
    return _bytes( $pg->{wal_base} // '1G' ) + $keep;
}

sub _view {
    my ( $pg, $sess, $name ) = @_;
    my $db = $sess->{db};
    if ( $name eq 'pg_stat_activity' ) {
        return [ map { my $a = $_; +{ ( map { $_ => $a->{$_} } qw( pid usename datname client_addr application_name state ) ),
                    backend_start => $a->{backend_start} // _ts( $NOW - 86400 ), state_change => $a->{state_change} // _ts( $NOW - 180 ),
                    query_start => $a->{query_start} // $a->{state_change} // _ts( $NOW - 180 ),
                    xact_start => ( $a->{state} // '' ) =~ /\A(?:active|idle in transaction)/ ? $a->{xact_start} // $a->{state_change} // _ts( $NOW - 180 ) : undef,
                    wait_event_type => ( $a->{state} // '' ) =~ /\Aidle/ ? 'Client' : undef, wait_event => ( $a->{state} // '' ) =~ /\Aidle/ ? 'ClientRead' : undef,
                    query => $a->{query} // '', backend_type => 'client backend', client_port => 50000 + ( $a->{pid} % 10000 ) } }
            _activity_rows($pg), { pid => 9999, usename => $sess->{user}, datname => $db, application_name => 'psql', state => 'active' } ];
    }
    if ( $name eq 'pg_replication_slots' ) {
        return [ map { my $s = $pg->{slots}{$_};
            { slot_name => $_, slot_type => $s->{type} // 'physical', active => $s->{active} ? 't' : 'f',
              active_pid => $s->{active} ? $s->{active_pid} // 3121 : undef, temporary => 'f', safe_wal_size => undef,
              # ein physischer Slot hat kein Plugin, keine Datenbank und kein confirmed_flush_lsn (NULL)
              ( ( $s->{type} // q{physical} ) eq q{physical}
                ? ( plugin => undef, datoid => undef, database => undef, confirmed_flush_lsn => undef )
                : ( ( map { exists $s->{$_} ? ( $_ => $s->{$_} ) : () } qw( plugin database ) ), confirmed_flush_lsn => $s->{confirmed_flush_lsn} // $s->{restart_lsn} // q{0/3000000} ) ),
              xmin => undef, catalog_xmin => undef, two_phase => q{f},
              restart_lsn => $s->{restart_lsn} // '0/3000000', wal_status => $s->{invalidated} ? 'lost' : _bytes( $s->{retained} ) > 10 * 1024**3 ? 'extended' : 'reserved',
              _retained => _bytes( $s->{retained} ) } } sort keys %{ $pg->{slots} || {} } ];
    }
    if ( $name eq q{pg_stat_replication} ) {    # ohne aktiven Slot haengt kein Replikat an: keine Zeile; sonst nicht nachgebildet
        die "gap\n" if grep { ref eq q{HASH} && $_->{active} } values %{ $pg->{slots} || {} };
        return [];
    }
    if ( $name eq 'pg_stat_user_tables' || $name eq 'pg_tables' ) {
        my @t;
        for my $k ( sort keys %{ $pg->{tables} || {} } ) {
            my ( $d, $s, $t ) = split /\./, $k, 3;
            next unless $d eq $db;
            my $x = $pg->{tables}{$k};
            push @t, $name eq 'pg_tables'
                ? { schemaname => $s, tablename => $t, tableowner => $x->{owner} }
                : { relid => "$s.$t", schemaname => $s, relname => $t, n_live_tup => $x->{n_live_tup} // 0, n_dead_tup => $x->{n_dead_tup} // 0,
                    last_vacuum => $x->{last_vacuum}, last_autovacuum => $x->{last_autovacuum}, last_analyze => $x->{last_analyze},
                    last_autoanalyze => $x->{last_autoanalyze}, autovacuum_count => $x->{autovacuum_count} // 0, _size => _bytes( $x->{size} ),
                    _reloptions => $x->{reloptions} || [] };
        }
        return \@t;
    }
    if ( $name eq 'pg_settings' ) {
        my %p = map { $_ => 1 } @{ $pg->{pending_restart} || [] };
        # Herkunft: die Datei, deren Zeile den laufenden Wert traegt (auto.conf vor postgresql.conf)
        my @src = map {
            my $f = $_;
            my $n = 0;
            my %line = map { $n++; /\A\s*([a-z_]+)\s*=/ ? ( $1 => $n ) : () } split /\n/, _file( $sess->{srv}, $f ) // '';
            [ $f, _conf_values( _file( $sess->{srv}, $f ) ), \%line ];
        } grep {defined} @{$pg}{qw( auto_conf conf )};
        my %all = ( %GUC, %{ $pg->{settings} || {} } );
        return [ map {
            my $k = $_;
            my $g = $GUC{$k} || {};
            my $val = exists( ( $pg->{settings} || {} )->{$k} ) ? $pg->{settings}{$k} : $g->{boot};
            my ($s) = exists( ( $pg->{settings} || {} )->{$k} ) ? grep { defined $_->[1]{$k} && _guc_base( $k, $_->[1]{$k} ) eq _guc_base( $k, $val ) } @src : ();
            { name => $k, setting => _guc_base( $k, $val ), unit => length( $g->{unit} // '' ) ? $g->{unit} : undef, context => $CONTEXT{$k} // 'sighup',
                vartype => $g->{vartype} // 'string', category => $g->{category}, short_desc => undef, extra_desc => undef,
                boot_val => $g->{boot}, reset_val => _guc_base( $k, $val ), min_val => undef, max_val => undef, enumvals => undef,
                source => $s ? 'configuration file' : 'default', sourcefile => $s ? $s->[0] : undef, sourceline => $s ? $s->[2]{$k} : undef,
                pending_restart => $p{$k} ? 't' : 'f' }
        } sort keys %all ];
    }
    if ( $name eq 'pg_file_settings' ) {    # jede Zeile der Dateien; wirksam ist die letzte je Name
        die "permission denied for view pg_file_settings\n" unless _is_super( $pg, $sess->{user} );
        my @r;
        my $seq = 0;
        for my $f ( grep {defined} @{$pg}{qw( conf auto_conf )} ) {
            my $n = 0;
            for my $l ( split /\n/, _file( $sess->{srv}, $f ) // '' ) {
                $n++;
                ( my $x = $l ) =~ s/#.*//;
                next unless $x =~ /\A\s*([a-z_]+)\s*=?\s*(?:'([^']*)'|(\S+))/;
                push @r, { sourcefile => $f, sourceline => $n, seqno => ++$seq, name => $1, setting => $2 // $3, applied => 'f', error => undef };
            }
        }
        my %last;
        $last{ $_->{name} } = $_ for @r;
        for my $x ( values %last ) {
            if ( ( $CONTEXT{ $x->{name} } // '' ) eq 'postmaster' && grep { $_ eq $x->{name} } @{ $pg->{pending_restart} || [] } ) {
                $x->{error} = 'setting could not be applied';
            }
            else { $x->{applied} = 't' }
        }
        return \@r;
    }
    if ( $name eq 'pg_authid' ) {
        die "permission denied for table pg_authid\n" unless _is_super( $pg, $sess->{user} );
        return [ map { my $r = $pg->{roles}{$_};
            { oid => $_, rolname => $_, rolsuper => $r->{superuser} ? 't' : 'f', rolcanlogin => ( $r->{login} || $r->{superuser} ) ? 't' : 'f',
              rolcreaterole => $r->{createrole} ? 't' : 'f', rolcreatedb => $r->{createdb} ? 't' : 'f', rolinherit => 't',
              rolreplication => $r->{replication} ? 't' : 'f', rolbypassrls => $r->{bypassrls} ? 't' : 'f', rolconnlimit => -1, rolvaliduntil => undef,
              rolpassword => $r->{password} ? 'SCRAM-SHA-256$4096:' . substr( Digest::MD5::md5_base64("salz:$_"), 0, 22 ) . '==$'
                  . Digest::MD5::md5_base64("stored:$_") . '=:' . Digest::MD5::md5_base64("server:$_") . '=' : undef } } sort keys %{ $pg->{roles} || {} } ];
    }
    if ( $name eq 'pg_roles' ) {
        return [ map { my $r = $pg->{roles}{$_};
            { oid => $_, rolname => $_, rolsuper => $r->{superuser} ? 't' : 'f', rolcanlogin => ( $r->{login} || $r->{superuser} ) ? 't' : 'f',
              rolcreaterole => $r->{createrole} ? 't' : 'f', rolcreatedb => $r->{createdb} ? 't' : 'f',
              rolreplication => $r->{replication} ? 't' : 'f', rolbypassrls => $r->{bypassrls} ? 't' : 'f', rolinherit => 't',
              rolconnlimit => -1, rolvaliduntil => undef, rolpassword => '********', rolconfig => undef } } sort keys %{ $pg->{roles} || {} } ];
    }
    if ( $name eq 'pg_auth_members' ) {
        my $m = $pg->{members} || {};
        return [ map { my $g = $_; map { +{ roleid => $g, member => $_, grantor => 'postgres', admin_option => 'f' } } @{ $m->{$g} || [] } } sort keys %$m ];
    }
    if ( $name eq 'pg_default_acl' ) {
        my %k = ( tables => 'r', sequences => 'S', functions => 'f', types => 'T', schemas => 'n' );
        return [ map { +{ defaclrole => $_->{role}, defaclnamespace => $_->{schema} // 0, defaclobjtype => $k{ lc( $_->{on} // 'tables' ) } // 'r',
            defaclacl => '{' . ( $_->{grantee} eq 'PUBLIC' ? '' : $_->{grantee} ) . '=' . _acl_letters( $_->{privs} ) . "/$_->{role}}" } }
            grep { ( $_->{db} // $db ) eq $db } @{ $pg->{default_acl} || [] } ];
    }
    if ( $name eq 'pg_hba_file_rules' ) {
        my $i = 0;
        my @r;
        for my $l ( split /\n/, _file( $sess->{srv}, $pg->{hba} ) // '' ) {
            $i++;
            ( my $x = $l ) =~ s/#.*//;
            $x =~ s/\A\s+|\s+\z//g;
            next unless length $x;
            my @f = split /\s+/, $x;
            my $type = shift @f;
            my ( $d, $u ) = ( shift @f, shift @f );
            my $addr = $type eq 'local' ? undef : shift @f;
            push @r, { line_number => $i, type => $type, database => "{$d}", user_name => "{$u}", address => $addr, auth_method => shift(@f) };
        }
        return \@r;
    }
    if ( $name eq 'pg_class' ) {
        return [ map {
            my ( $d, $sch, $t ) = split /\./, $_, 3;
            my $x = $pg->{tables}{$_};
            $d eq $db ? +{ oid => "$sch.$t", relname => $t, relnamespace => $sch, relowner => $x->{owner} // 'postgres', relkind => 'r',
                reltuples => $x->{n_live_tup} // 0, relpages => int( _bytes( $x->{size} ) / 8192 ), relhasindex => @{ $x->{indexes} || [] } ? 't' : 'f',
                relacl => _acl_text( $pg, "table:$_", $x->{owner} // 'postgres' ),
                reloptions => @{ $x->{reloptions} || [] } ? '{' . join( ',', @{ $x->{reloptions} } ) . '}' : undef,
                _size => _bytes( $x->{size} ) } : ();
        } sort keys %{ $pg->{tables} || {} } ];
    }
    if ( $name eq 'pg_database' ) {
        return [ map { { oid => $_, datname => $_, datdba => ( $pg->{databases}{$_} || {} )->{owner} // 'postgres',
            datallowconn => ( ( $pg->{databases}{$_} || {} )->{allowconn} // 1 ) ? 't' : 'f', datistemplate => 'f', datconnlimit => -1,
            encoding => 6, datcollate => 'C.UTF-8', datctype => 'C.UTF-8', datlocprovider => 'c',
            datacl => _acl_text( $pg, "database:$_", ( $pg->{databases}{$_} || {} )->{owner} // 'postgres' ) } }
            'postgres', grep { $_ ne 'postgres' } sort keys %{ $pg->{databases} || {} } ];
    }
    if ( $name eq 'pg_namespace' ) {
        return [ map { my ( $d, $n ) = split /\./, $_, 2; $d eq $db ? +{ oid => $n, nspname => $n, nspowner => $pg->{schemas}{$_}{owner} // 'postgres',
            nspacl => _acl_text( $pg, "schema:$_", $pg->{schemas}{$_}{owner} // 'postgres' ) } : () } sort keys %{ $pg->{schemas} || {} } ];
    }
    return undef;
}

# --- Ausdruecke ----------------------------------------------------------------

sub _tokens {
    my ($s) = @_;
    my @t;
    pos($s) = 0;
    while ( pos($s) < length $s ) {
        if    ( $s =~ /\G\s+/gc ) { next }
        elsif ( $s =~ /\G'((?:[^']|'')*)'/gc ) { push @t, [ str => $1 =~ s/''/'/gr ] }
        elsif ( $s =~ /\G"([^"]*)"/gc ) { push @t, [ id => $1 ] }
        elsif ( $s =~ /\G(\d+(?:\.\d+)?)/gc ) { push @t, [ num => $1 ] }
        elsif ( $s =~ /\G(::|\|\||<>|!=|<=|>=|[(),*=<>.+-])/gc ) { push @t, [ op => $1 ] }
        elsif ( $s =~ /\G([A-Za-z_][A-Za-z0-9_\$]*)/gc ) { push @t, [ id => lc $1 ] }
        else { die "syntax\n" }
    }
    return \@t;
}

# rekursiver Abstieg: or > and > not > cmp > primary
sub _parse_expr {
    my ($t) = @_;
    my $l = _p_and($t);
    while ( @$t && $t->[0][0] eq 'id' && $t->[0][1] eq 'or' ) { shift @$t; $l = [ or => $l, _p_and($t) ] }
    return $l;
}

sub _p_and {
    my ($t) = @_;
    my $l = _p_not($t);
    while ( @$t && $t->[0][0] eq 'id' && $t->[0][1] eq 'and' ) { shift @$t; $l = [ and => $l, _p_not($t) ] }
    return $l;
}

sub _p_not {
    my ($t) = @_;
    if ( @$t && $t->[0][0] eq 'id' && $t->[0][1] eq 'not' ) { shift @$t; return [ not => _p_not($t) ] }
    return _p_cmp($t);
}

sub _p_arith {
    my ($t) = @_;
    my $l = _p_prim($t);
    while ( @$t && $t->[0][0] eq 'op' && $t->[0][1] =~ /\A(?:\|\||\+|-)\z/ ) { my $op = ( shift @$t )->[1]; $l = [ arith => $op, $l, _p_prim($t) ] }
    return $l;
}

sub _p_cmp {
    my ($t) = @_;
    my $l = _p_arith($t);
    return $l unless @$t;
    my $x = $t->[0];
    if ( $x->[0] eq 'op' && $x->[1] =~ /\A(?:=|<>|!=|<|>|<=|>=)\z/ ) { shift @$t; return [ cmp => $x->[1], $l, _p_arith($t) ] }
    if ( $x->[0] eq 'id' && $x->[1] =~ /\A(?:like|ilike)\z/ ) { shift @$t; return [ $x->[1] => $l, _p_prim($t) ] }
    if ( $x->[0] eq 'id' && $x->[1] eq 'is' ) {
        shift @$t;
        my $neg = @$t && $t->[0][1] eq 'not' ? shift(@$t) && 1 : 0;
        my $v = shift @$t;
        die "syntax\n" unless $v && $v->[1] =~ /\A(?:null|true|false)\z/;
        return [ is => $neg, $l, $v->[1] ];
    }
    if ( $x->[0] eq 'id' && ( $x->[1] eq 'in' || $x->[1] eq 'not' && @$t > 1 && $t->[1][1] eq 'in' ) ) {
        my $neg = $x->[1] eq 'not' ? 1 : 0;
        shift @$t; shift @$t if $neg;
        die "syntax\n" unless @$t && $t->[0][1] eq '(';
        shift @$t;
        my @v;
        while ( @$t && $t->[0][1] ne ')' ) { push @v, _p_prim($t); shift @$t if @$t && $t->[0][1] eq ',' }
        shift @$t;
        return [ in => $neg, $l, \@v ];
    }
    return $l;
}

sub _p_prim {
    my ($t) = @_;
    my $x = shift @$t // die "syntax\n";
    my $e;
    if ( $x->[0] eq 'str' || $x->[0] eq 'num' ) { $e = [ lit => $x->[1] ] }
    elsif ( $x->[1] eq '(' ) { $e = _parse_expr($t); die "syntax\n" unless @$t && shift(@$t)->[1] eq ')' }
    elsif ( $x->[1] eq '*' ) { $e = ['star'] }
    elsif ( $x->[0] eq 'id' && $x->[1] =~ /\A(?:true|false|null)\z/ ) { $e = [ lit => $x->[1] eq 'null' ? undef : $x->[1] eq 'true' ? 't' : 'f' ] }
    elsif ( $x->[0] eq 'id' ) {
        my $name = $x->[1];
        my $qual;
        if ( @$t && $t->[0][1] eq '.' ) { shift @$t; ( $qual, $name ) = ( $name, ( shift @$t )->[1] ) }    # tabelle.spalte
        if ( $name eq 'extract' && @$t > 2 && $t->[0][1] eq '(' && $t->[2][1] eq 'from' ) {
            shift @$t;
            my $field = ( shift @$t )->[1];
            shift @$t;
            my $arg = _parse_expr($t);
            die "syntax\n" unless @$t && shift(@$t)->[1] eq ')';
            $e = [ fn => 'extract', [ [ lit => $field ], $arg ] ];
        }
        elsif ( $name =~ /\A(?:current_timestamp|localtimestamp)\z/ ) { $e = [ fn => 'now', [] ] }
        elsif ( @$t && $t->[0][1] eq '(' ) {
            shift @$t;
            my @args;
            while ( @$t && $t->[0][1] ne ')' ) { push @args, _parse_expr($t); shift @$t if @$t && $t->[0][1] eq ',' }
            die "syntax\n" unless @$t;
            shift @$t;
            $e = [ fn => $name, \@args ];
        }
        else { $e = [ col => $name, $qual ] }
    }
    else { die "syntax\n" }
    while ( @$t && $t->[0][1] eq '::' ) { shift @$t; shift @$t }    # Typumwandlung: ohne Wirkung
    return $e;
}

sub _truth { my ($v) = @_; return defined $v && $v ne 'f' && $v ne '0' && $v ne '' }

sub _cmpv {
    my ( $a, $b ) = @_;
    return ( $a <=> $b ) if defined $a && defined $b && "$a" =~ /\A-?\d+(?:\.\d+)?\z/ && "$b" =~ /\A-?\d+(?:\.\d+)?\z/;
    return ( ( $a // '' ) cmp( $b // '' ) );
}

sub _ev {
    my ( $e, $row, $env ) = @_;
    my $k = $e->[0];
    return $e->[1] if $k eq 'lit';
    if ( $k eq 'col' ) {
        return $row->{"$e->[2].$e->[1]"} if defined $e->[2] && exists $row->{"$e->[2].$e->[1]"};
        # echte Spalte einer Katalog-Sicht, die hier nicht nachgebildet ist: Luecke, kein erfundener Fehler
        die "gap\n" if !exists $row->{ $e->[1] } && $env->{view} && $REAL_COLS{ $env->{view} } && $REAL_COLS{ $env->{view} }{ lc $e->[1] };
        die "column \"$e->[1]\" does not exist\n" unless exists $row->{ $e->[1] };
        return $row->{ $e->[1] };
    }
    return ( _truth( _ev( $e->[1], $row, $env ) ) || _truth( _ev( $e->[2], $row, $env ) ) ) ? 't' : 'f' if $k eq 'or';
    return ( _truth( _ev( $e->[1], $row, $env ) ) && _truth( _ev( $e->[2], $row, $env ) ) ) ? 't' : 'f' if $k eq 'and';
    return _truth( _ev( $e->[1], $row, $env ) ) ? 'f' : 't' if $k eq 'not';
    if ( $k eq 'cmp' ) {
        my ( $a, $b ) = ( _ev( $e->[2], $row, $env ), _ev( $e->[3], $row, $env ) );
        return undef unless defined $a && defined $b;
        my $c = _cmpv( $a, $b );
        my %r = ( '=' => $c == 0, '<>' => $c != 0, '!=' => $c != 0, '<' => $c < 0, '>' => $c > 0, '<=' => $c <= 0, '>=' => $c >= 0 );
        return $r{ $e->[1] } ? 't' : 'f';
    }
    if ( $k eq 'like' || $k eq 'ilike' ) {
        my ( $a, $p ) = ( _ev( $e->[1], $row, $env ), _ev( $e->[2], $row, $env ) );
        return undef unless defined $a;
        my $re = join '', map { $_ eq '%' ? '.*' : $_ eq '_' ? '.' : quotemeta } split //, $p;
        return ( $k eq 'ilike' ? $a =~ /\A$re\z/is : $a =~ /\A$re\z/s ) ? 't' : 'f';
    }
    if ( $k eq 'is' ) {
        my $v = _ev( $e->[2], $row, $env );
        my $r = $e->[3] eq 'null' ? !defined $v : $e->[3] eq 'true' ? _truth($v) : defined $v && !_truth($v);
        return ( $e->[1] ? !$r : $r ) ? 't' : 'f';
    }
    if ( $k eq 'in' ) {
        my $v = _ev( $e->[2], $row, $env );
        my $hit = grep { _cmpv( $v, _ev( $_, $row, $env ) ) == 0 } @{ $e->[3] };
        return ( $e->[1] ? !$hit : $hit ) ? 't' : 'f';
    }
    if ( $k eq 'fn' ) { return _fn( $e->[1], $e->[2], $row, $env ) }
    if ( $k eq 'arith' ) {
        my ( $a, $b ) = ( _ev( $e->[2], $row, $env ), _ev( $e->[3], $row, $env ) );
        return undef unless defined $a && defined $b;
        return "$a$b" if $e->[1] eq '||';
        my ( $ea, $eb ) = ( _epoch($a), _epoch($b) );
        if ( defined $ea && defined $eb && $e->[1] eq '-' ) {    # Zeitstempel - Zeitstempel = Intervall
            my $d = $ea - $eb;
            return sprintf( '%s%02d:%02d:%02d', $d < 0 ? '-' : '', abs($d) / 3600, abs($d) % 3600 / 60, abs($d) % 60 );
        }
        die "gap\n" unless "$a" =~ /\A-?\d+(?:\.\d+)?\z/ && "$b" =~ /\A-?\d+(?:\.\d+)?\z/;
        return $e->[1] eq '+' ? $a + $b : $a - $b;
    }
    die "syntax\n";
}

# pg_sleep(x): die Anweisung dauerte x s; ab log_min_duration_statement (>= 0) steht sie
# mit ihrer Dauer im Log des Clusters (Laufzeitspur _append am Geraet, wie Linux sie liest)
sub _slept {
    my ( $pg, $sess, $secs, $stmt ) = @_;
    my $min = _ms( ( $pg->{settings} || {} )->{log_min_duration_statement} );
    return unless defined $min && $min >= 0 && defined $secs && $secs =~ /\A\d+(?:\.\d+)?\z/;
    my $ms = $secs * 1000 + 0.412;
    return if $ms < $min;
    my $dev = $sess->{srv} or return;
    my $path = $pg->{log} // '/var/log/postgresql/postgresql-' . ( ( $pg->{cluster} // '15/main' ) =~ s{/}{-}r ) . '.log';
    my $e = ( $dev->{files} || {} )->{$path};
    my $raw = ref $e eq 'HASH' ? $e->{content} // '' : $e;
    return unless defined $raw;
    my $t = Langertha::Holmgang::Sim::Linux::Calendar::format_local($NOW);    # "Sat 2026-10-24 10:00:00 CEST"
    my ( $d, $zone ) = $t =~ /\A\w+ (\S+ \S+) (\S+)\z/;
    ( my $st = $stmt // 'SELECT pg_sleep(' . $secs . ')' ) =~ s/\s*;?\s*\z//;
    my $old = ( $dev->{_append} || {} )->{$path};
    my @keep = $old && $old->{base} eq $raw ? @{ $old->{lines} } : ();
    $dev->{_append}{$path} = { base => $raw, lines => [ @keep, sprintf( '%s.%03d %s [9999] %s@%s LOG:  duration: %.3f ms  statement: %s', $d, 0, $zone, $sess->{user}, $sess->{db}, $ms, $st ) ] };
    return;
}

sub _fn {
    my ( $name, $args, $row, $env ) = @_;
    my @v = map { _ev( $_, $row, $env ) } grep { $_->[0] ne 'star' } @$args;
    my ( $pg, $sess ) = @{$env}{qw( pg sess )};
    return defined $v[0] ? _pretty( $v[0] ) : undef if $name eq q{pg_size_pretty};    # NULL bleibt NULL
    if ( $name eq q{pg_wal_lsn_diff} ) { return undef if @v >= 2 && grep { !defined } @v[ 0, 1 ]; return $row->{_retained} // 0 }
    return '0/9A000000' if $name eq 'pg_current_wal_lsn';
    return 'PostgreSQL 15.8 (Debian 15.8-0+deb12u1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit' if $name eq 'version';
    return $sess->{user} if $name eq 'current_user' || $name eq 'session_user';
    return _ts($NOW) if $name eq 'now' || $name eq 'clock_timestamp' || $name eq 'statement_timestamp';
    if ( $name eq 'extract' || $name eq 'date_part' ) {
        my ( $f, $v ) = @v;
        die "gap\n" unless lc( $f // '' ) eq 'epoch' && defined $v;
        return $1 * 3600 + $2 * 60 + $3 if $v =~ /\A(\d+):(\d\d):(\d\d)\z/;
        return $v =~ /\A-(\d+):(\d\d):(\d\d)\z/ ? -( $1 * 3600 + $2 * 60 + $3 ) : _epoch($v) // die "gap\n";
    }
    return $sess->{db} if $name eq 'current_database';
    if ( $name eq 'pg_sleep' ) { _slept( $pg, $sess, $v[0], $env->{stmt} ); return '' }
    if ( $name eq 'current_setting' ) {
        my $s = $pg->{settings}{ $v[0] // '' };
        die qq{unrecognized configuration parameter "$v[0]"\n} unless defined $s;
        return $s;
    }
    if ( $name =~ /\Apg_(?:total_)?relation_size\z|\Apg_table_size\z|\Apg_indexes_size\z/ ) {
        # Argument: Spalte (relid/oid einer Zeile) oder Name 'schema.tabelle'
        my $k = defined $v[0] ? _resolve( $pg, $sess, $v[0] ) : undef;
        return defined $k ? _bytes( $pg->{tables}{$k}{size} ) : $row->{_size} // 0;
    }
    if ( $name =~ /\Ahas_(database|schema|table)_privilege\z/ ) {
        my $kind = $1;
        my ( $who, $obj, $priv ) = @v == 3 ? @v : ( $sess->{user}, @v );
        die "gap\n" unless defined $obj && defined $priv;
        my $key = $kind eq 'database' ? "database:$obj" : $kind eq 'schema' ? "schema:$sess->{db}.$obj" : ( 'table:' . ( _resolve( $pg, $sess, $obj ) // die qq{relation "$obj" does not exist\n} ) );
        die qq{role "$who" does not exist\n} unless $pg->{roles}{$who};
        my @p = map { uc s/\A\s+|\s+\z//gr } split /,/, $priv;
        return ( grep { _has_priv( $pg, $who, $key, $_ ) } @p ) ? 't' : 'f';
    }
    if ( $name eq 'pg_has_role' ) {
        my ( $who, $role ) = @v == 3 ? @v[ 0, 1 ] : ( $sess->{user}, $v[0] );
        die qq{role "$role" does not exist\n} unless defined $role && $pg->{roles}{$role};
        return 't' if _is_super( $pg, $who );
        return ( grep { $_ eq $role } _memberships( $pg, $who ) ) ? 't' : 'f';
    }
    if ( $name eq 'pg_database_size' ) { return 0 }
    die "must be superuser\n" if $name =~ /\Apg_(?:reload_conf|drop_replication_slot|terminate_backend|cancel_backend)\z/ && !_is_super( $pg, $sess->{user} );
    if ( $name eq 'pg_reload_conf' ) { _apply_config( $sess->{srv}, 0 ); return 't' }
    if ( $name eq 'pg_drop_replication_slot' ) {
        my $s = $pg->{slots}{ $v[0] // '' } or die qq{replication slot "$v[0]" does not exist\n};
        die qq{replication slot "$v[0]" is active for PID 3121\n} if $s->{active};
        delete $pg->{slots}{ $v[0] };
        $env->{mutated} = 1;
        return '';
    }
    if ( $name eq 'pg_terminate_backend' || $name eq 'pg_cancel_backend' ) {
        my $pid = $v[0] // 0;
        my @rows = _activity_rows($pg);
        my @keep = grep { $_->{pid} != $pid } @rows;
        return 'f' if @keep == @rows;
        if ( $name eq 'pg_terminate_backend' ) {
            # der getroffene Eintrag zerfaellt in Einzelzeilen, die uebrigen bleiben
            my @new;
            for my $a ( @{ $pg->{activity} } ) {
                my $c = $a->{count} // 1;
                if ( $pid >= $a->{pid} && $pid < $a->{pid} + $c ) {
                    push @new, map { my %x = ( %$a, pid => $a->{pid} + $_ ); delete $x{count}; \%x } grep { $a->{pid} + $_ != $pid } 0 .. $c - 1;
                }
                else { push @new, $a }
            }
            $pg->{activity} = \@new;
        }
        return 't';
    }
    die "function $name() does not exist\n";
}

# --- Anweisungen -------------------------------------------------------------

sub _err { my ($m) = @_; return ( "ERROR:  $m", 0 ) }

sub _statement {
    my ( $pg, $sess, $st ) = @_;
    my $super = _is_super( $pg, $sess->{user} );
    return _meta( $pg, $sess, $st ) if $st =~ /\A\\/;
    ( my $u = $st ) =~ s/\s+/ /g;

    return ( '', 1 ) if $u =~ /\A(?:BEGIN|COMMIT|ROLLBACK|END|START TRANSACTION)\b/i;
    if ( $u =~ /\ASHOW (\w+)\z/i ) {
        my $k = lc $1;
        return _err(qq{unrecognized configuration parameter "$k"}) unless defined $pg->{settings}{$k};
        return ( _table( $sess, [$k], [ [ $pg->{settings}{$k} ] ], text => 1 ), 1 );
    }
    if ( $u =~ /\AALTER SYSTEM (SET|RESET) (\w+)(?: ?(?:=|TO) ?(?:'([^']*)'|(\S+)))?\z/i ) {
        return _err('must be superuser to execute ALTER SYSTEM command') unless $super;
        my ( $op, $k, $v ) = ( uc $1, lc $2, $3 // $4 );
        my $path = $pg->{auto_conf};
        my $dev = $sess->{srv};
        my @l = grep { !/\A\s*\Q$k\E\s*=/ } split /\n/, _file( $dev, $path ) // '';
        @l = ( '# Do not edit this file manually!', '# It will be overwritten by the ALTER SYSTEM command.' ) unless @l;
        push @l, "$k = '$v'" if $op eq 'SET';
        _set_file( $dev, $path, join( "\n", @l ) . "\n" );
        return ( 'ALTER SYSTEM', 1 );
    }
    if ( $u =~ /\ACHECKPOINT\z/i ) {
        return _err('must be superuser to do CHECKPOINT') unless $super;
        _checkpoint( $pg, $sess->{srv} );
        return ( 'CHECKPOINT', 1 );
    }
    if ( $u =~ /\A(VACUUM|ANALYZE)\b ?(.*)\z/i ) {
        my ( $what, $rest ) = ( uc $1, $2 );
        my %opt;
        $opt{ uc $_ } = 1 for $rest =~ /\A\(([^)]*)\)/ ? split( /\s*,\s*/, $1 ) : ();
        $rest =~ s/\A\([^)]*\)\s*//;
        while ( $rest =~ s/\A(FULL|FREEZE|VERBOSE|ANALYZE)\b\s*//i ) { $opt{ uc $1 } = 1 }
        $opt{ uc $_ } = 1 for map { s/\s+(?:true|on)\z//ir } keys %opt;
        my @t = length $rest ? map { _resolve( $pg, $sess, $_ ) // return _err(qq{relation "$_" does not exist}) } split /\s*,\s*/, $rest
            : grep { ( split /\./ )[0] eq $sess->{db} } sort keys %{ $pg->{tables} || {} };
        for my $k (@t) {
            my $x = $pg->{tables}{$k};
            next unless $super || ( $x->{owner} // '' ) eq $sess->{user};
            if ( $what eq 'VACUUM' ) {
                $x->{n_dead_tup} = 0 if $x->{n_dead_tup};
                $x->{last_vacuum} = '2026-10-20 12:00:00+02';
                if ( $opt{FULL} ) {
                    $x->{rewrites} = ( $x->{rewrites} // 0 ) + 1;
                    $x->{size} = $x->{size_live} if defined $x->{size_live};
                }
            }
            $x->{last_analyze} = '2026-10-20 12:00:00+02' if $what eq 'ANALYZE' || $opt{ANALYZE};
        }
        return ( $what, 1 );
    }
    if ( $u =~ /\AALTER TABLE (?:IF EXISTS )?(?:ONLY )?(\S+) (SET|RESET) ?\((.*)\)\z/i ) {
        my ( $name, $op, $list ) = ( $1, uc $2, $3 );
        my $k = _resolve( $pg, $sess, $name ) // return _err(qq{relation "$name" does not exist});
        my $x = $pg->{tables}{$k};
        return _err("must be owner of table $name") unless $super || ( $x->{owner} // '' ) eq $sess->{user};
        my @o = @{ $x->{reloptions} || [] };
        for my $item ( split /\s*,\s*/, $list ) {
            my ( $key, $val ) = $item =~ /\A\s*([\w.]+)\s*(?:=\s*'?([^']*?)'?)?\s*\z/ or return _err('syntax error');
            $key = lc $key;
            @o = grep { !/\A\Q$key\E=/ } @o;
            push @o, "$key=" . _norm_val( $val // 'true' ) =~ s/\Aon\z/true/r =~ s/\Aoff\z/false/r if $op eq 'SET';
        }
        $x->{reloptions} = \@o;
        return ( 'ALTER TABLE', 1 );
    }
    if ( $u =~ /\A(CREATE|ALTER) (ROLE|USER) (\S+)(?: (?:WITH )?(.*))?\z/i ) {
        my ( $verb, $kind, $name, $opts ) = ( uc $1, uc $2, $3, $4 // '' );
        $name =~ s/\A"|"\z//g;
        return _err('permission denied to create role') unless $super || ( _role( $pg, $sess->{user} ) || {} )->{createrole};
        my $r = $pg->{roles}{$name};
        return _err(qq{role "$name" already exists}) if $verb eq 'CREATE' && $r;
        return _err(qq{role "$name" does not exist}) if $verb eq 'ALTER' && !$r;
        $r = $pg->{roles}{$name} //= {};
        $r->{login} = JSON::MaybeXS::true() if $verb eq 'CREATE' && $kind eq 'USER';
        my $err = _role_opts( $pg, $r, $name, $opts );
        return _err($err) if $err;
        return ( "$verb ROLE", 1 );
    }
    # DROP REPLICATION SLOT ist ein Befehl des Replikationsprotokolls, kein SQL
    return _err(qq{syntax error at or near "REPLICATION"\nLINE 1: $st\n             ^}) if $u =~ /\ADROP\s+REPLICATION\b/i;
    if ( $u =~ /\ADROP (?:ROLE|USER) (IF EXISTS )?(\S+)\z/i ) {
        return _err('permission denied to drop role') unless $super;
        delete $pg->{roles}{$2} or ( $1 ? return ( 'DROP ROLE', 1 ) : return _err(qq{role "$2" does not exist}) );
        return ( 'DROP ROLE', 1 );
    }
    return _grant( $pg, $sess, $u ) if $u =~ /\A(?:GRANT|REVOKE) /i;
    return _default_privs( $pg, $sess, $u ) if $u =~ /\AALTER DEFAULT PRIVILEGES /i;
    if ( $u =~ /\A(DROP TABLE|TRUNCATE(?: TABLE)?|DELETE FROM) (?:IF EXISTS )?(\S+)/i ) {
        my ( $what, $name ) = ( uc $1, $2 );
        my $k = _resolve( $pg, $sess, $name ) // return _err(qq{relation "$name" does not exist});
        my $x = $pg->{tables}{$k};
        # DROP nur Eigentuemer (auch ueber Mitgliedschaft); DELETE/TRUNCATE auch mit dem Recht
        my $own  = $super || grep { $_ eq ( $x->{owner} // '' ) } $sess->{user}, _memberships( $pg, $sess->{user} );
        my $need = $what eq 'DROP TABLE' ? undef : $what =~ /\ATRUNCATE/ ? 'TRUNCATE' : 'DELETE';
        return _err("permission denied for table $name") unless $own || defined $need && _has_priv( $pg, $sess->{user}, "table:$k", $need );
        if ( $what eq 'DROP TABLE' ) { delete $pg->{tables}{$k}; return ( 'DROP TABLE', 1 ) }
        my $n = $x->{n_live_tup} // 0;
        $x->{n_live_tup} = 0;
        return ( $what =~ /\ATRUNCATE/ ? 'TRUNCATE TABLE' : "DELETE $n", 1 );
    }
    if ( $u =~ /\ACREATE (UNIQUE )?INDEX (CONCURRENTLY )?(?:IF NOT EXISTS )?(?:(\w+) )?ON (?:ONLY )?(\S+?) ?(?:USING (\w+) ?)?\(([^()]+)\)\s*\z/i ) {
        my ( $uniq, $name, $table, $method, $cols ) = ( $1, $3, $4, lc( $5 // 'btree' ), $6 );
        my $k = _resolve( $pg, $sess, $table ) // return _err(qq{relation "$table" does not exist});
        my $x = $pg->{tables}{$k};
        return _err("must be owner of table $table") unless $super || ( $x->{owner} // '' ) eq $sess->{user};
        my @c = map { s/\A\s+|\s+\z//gr =~ s/"//gr } split /,/, lc $cols;
        my ( undef, undef, $t ) = split /\./, $k;
        $name //= join( '_', $t, @c, $uniq ? 'key' : 'idx' ) =~ s/\W+/_/gr;
        return _err(qq{relation "$name" already exists}) if grep { $_->{name} eq $name } @{ $x->{indexes} || [] };
        push @{ $x->{indexes} }, { name => lc $name, columns => \@c, method => $method, ( $uniq ? ( unique => JSON::MaybeXS::true() ) : () ) };
        return ( 'CREATE INDEX', 1 );
    }
    if ( $u =~ /\ADROP INDEX (?:CONCURRENTLY )?(IF EXISTS )?(\S+?)\s*\z/i ) {
        my ( $ifex, $name ) = ( $1, lc $2 );
        $name =~ s/\A.*\.//;
        for my $x ( values %{ $pg->{tables} || {} } ) {
            my @keep = grep { $_->{name} ne $name } @{ $x->{indexes} || [] };
            next if @keep == @{ $x->{indexes} || [] };
            return _err("must be owner of index $name") unless $super;
            $x->{indexes} = \@keep;
            return ( 'DROP INDEX', 1 );
        }
        return $ifex ? ( 'DROP INDEX', 1 ) : _err(qq{index "$name" does not exist});
    }
    if ( $u =~ /\ADROP (DATABASE|SCHEMA) (?:IF EXISTS )?(\S+)/i ) {
        return _err('must be owner') unless $super;
        my ( $kind, $name ) = ( uc $1, $2 );
        if ( $kind eq 'DATABASE' ) {
            delete $pg->{databases}{$name} or return _err(qq{database "$name" does not exist});
            delete $pg->{tables}{$_} for grep {/\A\Q$name\E\./} keys %{ $pg->{tables} || {} };
        }
        else {
            delete $pg->{schemas}{"$sess->{db}.$name"} or return _err(qq{schema "$name" does not exist});
        }
        return ( "DROP $kind", 1 );
    }
    if ( $u =~ /\ASELECT\b/i ) {
        my $r = eval { _select( $pg, $sess, $st ) };
        if ( my $e = $@ ) {
            return _gap($st) if $e eq "gap\n";
            $e =~ s/\s+\z//;
            return $e eq 'syntax' ? _gap($st) : _err($e);
        }
        return ( $r, 1 );
    }
    return _gap($st);
}

sub _gap { my ($st) = @_; push @GAPS, "psql: $st"; return ( '', 0 ) }

sub _checkpoint {
    my ( $pg, $dev ) = @_;
    # max_slot_wal_keep_size: ein Slot, der mehr zurueckhaelt, wird ungueltig
    my $lim = $pg->{settings}{max_slot_wal_keep_size} // -1;
    if ( "$lim" ne '-1' ) {
        my $b = _bytes( $lim =~ s/B\z//ir =~ s/\A(\d+)\z/${1}M/r );
        for my $s ( values %{ $pg->{slots} || {} } ) {
            next if $s->{invalidated} || _bytes( $s->{retained} ) <= $b;
            $s->{invalidated} = JSON::MaybeXS::true();
            $s->{retained}    = '0';
            $s->{active}      = JSON::MaybeXS::false() if $s->{active};
        }
    }
    my $path = $pg->{wal} or return;
    my $f = $dev->{files}{$path};
    return unless ref $f eq 'HASH';
    my $need = _wal_needed($pg);
    $f->{size} = _pretty_size($need) if _bytes( $f->{size} ) > $need;
    return;
}

sub _pretty_size {
    my ($b) = @_;
    for my $u ( [ G => 1024**3 ], [ M => 1024**2 ], [ K => 1024 ] ) { return ( $b / $u->[1] ) . $u->[0] if $b % $u->[1] == 0 }
    return $b;
}

sub _resolve {
    my ( $pg, $sess, $name ) = @_;
    $name =~ s/"//g;
    $name = lc $name;
    my @p = split /\./, $name;
    my @hit = @p == 2 ? grep { $_ eq "$sess->{db}.$name" } keys %{ $pg->{tables} || {} }
        : grep { /\A\Q$sess->{db}\E\.[^.]+\.\Q$name\E\z/ } keys %{ $pg->{tables} || {} };
    @hit = grep {/\.public\./} @hit if @hit > 1;
    return @hit == 1 ? $hit[0] : undef;
}

sub _role_opts {
    my ( $pg, $r, $name, $opts ) = @_;
    my @w = $opts =~ /('(?:[^']|'')*'|\S+)/g;
    while (@w) {
        my $o = uc shift @w;
        # Attribute stehen nur, wenn sie gesetzt sind (wie rolsuper = true)
        if    ( $o =~ /\A(NO)?(SUPERUSER|LOGIN|CREATEDB|CREATEROLE|REPLICATION|BYPASSRLS)\z/ ) {
            my $k = lc $2;
            if ($1) { delete $r->{$k} } else { $r->{$k} = JSON::MaybeXS::true() }
        }
        elsif ( $o eq 'INHERIT' )   { delete $r->{noinherit} }
        elsif ( $o eq 'NOINHERIT' ) { $r->{noinherit} = JSON::MaybeXS::true() }
        elsif ( $o eq 'PASSWORD' ) {
            my $p = shift @w;
            if ( uc( $p // '' ) eq 'NULL' ) { delete $r->{password} } else { $r->{password} = JSON::MaybeXS::true() }
        }
        elsif ( $o eq 'ENCRYPTED' ) { next }
        elsif ( $o eq 'CONNECTION' ) { shift @w; $r->{connection_limit} = 0 + ( shift(@w) // -1 ) }
        elsif ( $o eq 'IN' ) {
            shift @w;
            for my $g ( split /,/, join '', @w ) { push @{ $pg->{members}{$g} }, $name }
            @w = ();
        }
        elsif ( $o eq 'VALID' ) { shift @w; shift @w }
        else { return qq{syntax error at or near "$o"} }
    }
    return undef;
}

my %ALL_PRIVS = ( table => [qw( SELECT INSERT UPDATE DELETE TRUNCATE REFERENCES TRIGGER )], schema => [qw( USAGE CREATE )],
    database => [qw( CONNECT CREATE TEMPORARY )] );

sub _privs {
    my ( $list, $kind ) = @_;
    my @p = map { s/\A\s+|\s+\z//gr } split /,/, uc $list;
    return [ @{ $ALL_PRIVS{$kind} } ] if grep { $_ eq 'ALL' || $_ eq 'ALL PRIVILEGES' } @p;
    @p = map { $_ eq 'TEMP' ? 'TEMPORARY' : $_ } @p;
    for my $x (@p) { die qq{invalid privilege type $x for } . lc($kind) . "\n" unless grep { $_ eq $x } @{ $ALL_PRIVS{$kind} } }
    return \@p;
}

sub _grant {
    my ( $pg, $sess, $u ) = @_;
    my $super = _is_super( $pg, $sess->{user} );
    my ( $verb, $privs, $on, $to ) = $u =~ /\A(GRANT|REVOKE) (.+?) ON (.+?) (?:TO|FROM) (.+?)(?: WITH GRANT OPTION)?(?: CASCADE| RESTRICT)?\z/i;
    if ( !$verb ) {    # GRANT rolle TO rolle
        my ( $v, $roles, $who ) = $u =~ /\A(GRANT|REVOKE) (\S+(?:\s*,\s*\S+)*) (?:TO|FROM) (.+)\z/i or return _gap($u);
        for my $g ( split /\s*,\s*/, $roles ) {
            return _err(qq{role "$g" does not exist}) unless $pg->{roles}{$g};
            for my $w ( split /\s*,\s*/, $who ) {
                return _err(qq{role "$w" does not exist}) unless $pg->{roles}{$w};
                my $m = $pg->{members}{$g} //= [];
                @$m = grep { $_ ne $w } @$m;
                push @$m, $w if uc $v eq 'GRANT';
            }
        }
        return ( uc($v) eq 'GRANT' ? 'GRANT ROLE' : 'REVOKE ROLE', 1 );
    }
    $verb = uc $verb;
    my @grantees = map { s/\A"|"\z//gr } split /\s*,\s*/, $to;
    for my $g (@grantees) { return _err(qq{role "$g" does not exist}) unless uc $g eq 'PUBLIC' || $pg->{roles}{$g} }
    @grantees = map { uc $_ eq 'PUBLIC' ? 'PUBLIC' : $_ } @grantees;
    my ( $kind, @objs );
    if ( $on =~ /\AALL TABLES IN SCHEMA (.+)\z/i ) {
        $kind = 'table';
        for my $s ( split /\s*,\s*/, lc $1 ) {
            return _err(qq{schema "$s" does not exist}) unless $pg->{schemas}{"$sess->{db}.$s"};
            push @objs, map {"table:$_"} sort grep {/\A\Q$sess->{db}.$s.\E[^.]+\z/} keys %{ $pg->{tables} || {} };
        }
    }
    elsif ( $on =~ /\ASCHEMA (.+)\z/i ) {
        $kind = 'schema';
        for my $s ( split /\s*,\s*/, lc $1 ) {
            return _err(qq{schema "$s" does not exist}) unless $pg->{schemas}{"$sess->{db}.$s"};
            push @objs, "schema:$sess->{db}.$s";
        }
    }
    elsif ( $on =~ /\ADATABASE (.+)\z/i ) {
        $kind = 'database';
        for my $d ( split /\s*,\s*/, $1 ) {
            return _err(qq{database "$d" does not exist}) unless $pg->{databases}{$d};
            push @objs, "database:$d";
        }
    }
    elsif ( $on =~ /\A(?:TABLE )?(.+)\z/i && $on !~ /\A(?:SEQUENCE|FUNCTION|ALL SEQUENCES|ALL FUNCTIONS|LARGE OBJECT|TABLESPACE|FOREIGN|TYPE|DOMAIN|LANGUAGE)/i ) {
        $kind = 'table';
        for my $t ( split /\s*,\s*/, $1 ) {
            my $k = _resolve( $pg, $sess, $t ) // return _err(qq{relation "$t" does not exist});
            push @objs, "table:$k";
        }
    }
    else { return _gap($u) }
    my $p = eval { _privs( $privs, $kind ) } or return _err( $@ =~ s/\s+\z//r );
    for my $o (@objs) {
        my $owner = $o =~ /\Atable:(.+)\z/ ? $pg->{tables}{$1}{owner} : $o =~ /\Aschema:(.+)\z/ ? $pg->{schemas}{$1}{owner} : $pg->{databases}{ $o =~ s/\Adatabase://r }{owner};
        return _err( 'permission denied for ' . ( split /:/, $o )[0] ) unless $super || grep { $_ eq ( $owner // '' ) } _memberships( $pg, $sess->{user} );
        for my $g (@grantees) {
            my $cur = $pg->{grants}{$o}{$g} //= [];
            my %h = map { $_ => 1 } @$cur;
            if ( $verb eq 'GRANT' ) { $h{$_} = 1 for @$p } else { delete $h{$_} for @$p }
            if (%h) { @$cur = sort keys %h }
            else {
                delete $pg->{grants}{$o}{$g};
                delete $pg->{grants}{$o} unless %{ $pg->{grants}{$o} };
            }
        }
    }
    return ( $verb, 1 );
}

sub _default_privs {
    my ( $pg, $sess, $u ) = @_;
    my ( $for, $schema, $verb, $privs, $on, $who ) = $u =~ /\AALTER DEFAULT PRIVILEGES(?: FOR (?:ROLE|USER) (\S+))?(?: IN SCHEMA (\S+))? (GRANT|REVOKE) (.+?) ON (TABLES|SEQUENCES|FUNCTIONS|ROUTINES|TYPES|SCHEMAS) (?:TO|FROM) (.+?)(?: WITH GRANT OPTION)?\z/i
        or return _err('syntax error');
    return _gap($u) unless uc $on eq 'TABLES';
    $for //= $sess->{user};
    return _err(qq{role "$for" does not exist}) unless $pg->{roles}{$for};
    return _err('permission denied to change default privileges') unless _is_super( $pg, $sess->{user} ) || grep { $_ eq $for } _memberships( $pg, $sess->{user} );
    $schema = lc $schema if defined $schema;
    return _err(qq{schema "$schema" does not exist}) if defined $schema && !$pg->{schemas}{"$sess->{db}.$schema"};
    my $p = eval { _privs( $privs, 'table' ) } or return _err( $@ =~ s/\s+\z//r );
    my $acl = $pg->{default_acl} //= [];
    for my $g ( split /\s*,\s*/, $who ) {
        return _err(qq{role "$g" does not exist}) unless $pg->{roles}{$g} || uc $g eq 'PUBLIC';
        my ($e) = grep { $_->{role} eq $for && ( $_->{schema} // '' ) eq ( $schema // '' ) && $_->{db} eq $sess->{db} && $_->{grantee} eq $g } @$acl;
        if ( !$e ) { $e = { role => $for, db => $sess->{db}, ( defined $schema ? ( schema => $schema ) : () ), on => 'tables', grantee => $g, privs => [] }; push @$acl, $e }
        my %h = map { $_ => 1 } @{ $e->{privs} };
        if ( uc $verb eq 'GRANT' ) { $h{$_} = 1 for @$p } else { delete $h{$_} for @$p }
        $e->{privs} = [ sort keys %h ];
        @$acl = grep { @{ $_->{privs} } } @$acl;
    }
    return ( 'ALTER DEFAULT PRIVILEGES', 1 );
}

sub _select {
    my ( $pg, $sess, $st ) = @_;
    my ( $body ) = $st =~ /\A\s*SELECT\s+(.*?)\s*;?\s*\z/is or die "syntax\n";
    # FROM auf oberster Ebene (nicht in extract(… FROM …) oder in '…')
    my ( $list, $rest ) = ( $body, undef );
    {
        my ( $d, $q ) = ( 0, 0 );
        for my $i ( 0 .. length($body) - 1 ) {
            my $c = substr( $body, $i, 1 );
            if    ( $c eq "'" ) { $q = !$q }
            elsif ( $q )        { next }
            elsif ( $c eq '(' ) { $d++ }
            elsif ( $c eq ')' ) { $d-- }
            elsif ( !$d && substr( $body, $i ) =~ /\A\s+FROM\s+/i ) {
                ( $list, $rest ) = ( substr( $body, 0, $i ), substr( $body, $i ) =~ s/\A\s+FROM\s+//ir );
                last;
            }
        }
    }
    my ( $from, $where, $group, $order, $limit, $join );
    if ( defined $rest ) {
        ( $from, my $tail ) = $rest =~ /\A(\S+)\s*(.*)\z/s;
        if ( $from =~ /\A(?:pg_catalog\.)?pg_sleep\(\s*([\d.]+)\s*\)\z/i ) {    # FROM pg_sleep(x): eine Zeile, die Anweisung dauert x s
            _slept( $pg, $sess, $1, $st );
            $from = undef;
            $tail =~ s/\A\s*(?:AS\s+)?[a-z_]\w*\s*//i unless $tail =~ /\A\s*(?:WHERE|GROUP|ORDER|LIMIT)\b/i;
            die "gap\n" if $tail =~ /\S/;
        }
        die "syntax\n" if defined $from && $from =~ /\(/;
        $tail //= '';
        # a [AS] x [INNER|LEFT [OUTER]] JOIN b [AS] y ON …  (zwei Quellen; mehr ist eine Luecke)
        my $kw = qr/(?:WHERE|GROUP|ORDER|LIMIT|JOIN|INNER|LEFT|RIGHT|FULL|CROSS|ON)\b/i;
        if ( $tail =~ /\A(?:AS\s+)?(?!$kw)([a-z_]\w*)?\s*(?:(INNER|LEFT(?:\s+OUTER)?)\s+)?JOIN\s+(\S+)\s+(?:AS\s+)?(?!$kw)([a-z_]\w*)?\s*ON\s+(.+?)(?=\s+(?:WHERE|GROUP\s+BY|ORDER\s+BY|LIMIT)\b|\s*\z)(.*)\z/is ) {
            my ( $a1, $type, $from2, $a2, $on, $after ) = ( $1 // $from, $2 // '', $3, $4 // $3, $5, $6 );
            die "gap\n" if $after =~ /\bJOIN\b/i;
            $join = { a1 => lc( $a1 =~ s/\A.*\.//r ), from2 => $from2, a2 => lc( $a2 =~ s/\A.*\.//r ), on => $on, left => ( $type =~ /\ALEFT/i ? 1 : 0 ) };
            $tail = $after;
        }
        $limit = $1 if $tail =~ s/\s*\bLIMIT\s+(\d+)\s*\z//i;
        $order = $1 if $tail =~ s/\s*\bORDER\s+BY\s+(.+?)\s*\z//is;
        $group = $1 if $tail =~ s/\s*\bGROUP\s+BY\s+(.+?)\s*\z//is;
        $where = $1 if $tail =~ s/\A\s*WHERE\s+(.+?)\s*\z//is;
        $tail =~ s/\A\s*(?:AS\s+)?[a-z_]\w*\s*\z//i;    # Alias der Tabelle
        die "syntax\n" if $tail =~ /\S/;
    }
    my $env = { pg => $pg, sess => $sess, stmt => $st };
    my $rows = [ {} ];
    if ( defined $from ) {
        my $v = lc( $from =~ s/\Apg_catalog\.//ir );
        $rows = _view( $pg, $sess, $v );
        $env->{view} = $v if $rows;
        # echter Katalog ohne Nachbildung (nicht: Sichten von Erweiterungen, die hier nicht installiert sind)
        die "gap\n" if !$rows && $v =~ /\A(?:pg_[a-z_]+|information_schema\.[a-z_]+)\z/ && $v !~ /\Apg_(?:stat_statements|buffercache|stat_kcache|qualstats)/;
        if ( !$rows ) {
            my $k = _resolve( $pg, $sess, $from ) // die qq{relation "$from" does not exist\n};
            my ( undef, $s ) = split /\./, $k;
            die "permission denied for schema $s\n" unless _has_priv( $pg, $sess->{user}, "schema:" . join( '.', ( split /\./, $k )[ 0, 1 ] ), 'USAGE' );
            die "permission denied for table " . ( split /\./, $k )[2] . "\n" unless _has_priv( $pg, $sess->{user}, "table:$k", 'SELECT' );
            die "gap\n" unless $list =~ /\A\s*count\s*\(\s*\*\s*\)\s*\z/i;
            return _table( $sess, ['count'], [ [ $pg->{tables}{$k}{n_live_tup} // 0 ] ] );
        }
        die "permission denied for view $v\n" if $v eq 'pg_hba_file_rules' && !_is_super( $pg, $sess->{user} );
        if ($join) {
            my $v2 = lc( $join->{from2} =~ s/\Apg_catalog\.//ir );
            my $rows2 = _view( $pg, $sess, $v2 );
            die "gap\n" if !$rows2 && $v2 =~ /\A(?:pg_[a-z_]+|information_schema\.[a-z_]+)\z/;
            die qq{relation "$join->{from2}" does not exist\n} unless $rows2;
            my $on = _parse_expr( _tokens( $join->{on} ) );
            my @j;
            for my $ra (@$rows) {
                my $hit = 0;
                for my $rb (@$rows2) {
                    my %m = ( %$ra, %$rb, ( map { ( "$join->{a1}.$_" => $ra->{$_} ) } keys %$ra ), ( map { ( "$join->{a2}.$_" => $rb->{$_} ) } keys %$rb ) );
                    next unless _truth( _ev( $on, \%m, $env ) );
                    push @j, \%m;
                    $hit = 1;
                }
                push @j, { %$ra, ( map { ( "$join->{a1}.$_" => $ra->{$_} ) } keys %$ra ), ( map { ( "$join->{a2}.$_" => undef ) } keys %{ $rows2->[0] || {} } ) }
                    if !$hit && $join->{left};
            }
            $rows = \@j;
            $env->{view} = undef;    # Spaltenpruefung: in einem JOIN mehrere Sichten
        }
    }
    # Auswahlliste
    my @items;
    my $t = _tokens($list);
    while (@$t) {
        my $start = scalar @$t;
        my $e = _parse_expr($t);
        my $alias;
        if ( @$t && $t->[0][1] eq 'as' ) { shift @$t; $alias = ( shift @$t )->[1] }
        elsif ( @$t && $t->[0][0] eq 'id' && $t->[0][1] ne ',' ) { $alias = ( shift @$t )->[1] }
        push @items, [ $e, $alias ];
        last unless @$t;
        die "syntax\n" unless $t->[0][1] eq ',';
        shift @$t;
    }
    my @rows = @$rows;
    if ( defined $where ) {
        my $w = _parse_expr( _tokens($where) );
        @rows = grep { _truth( _ev( $w, $_, $env ) ) } @rows;
    }
    my $is_count = sub { my ($e) = @_; return $e->[0] eq 'fn' && $e->[1] eq 'count' };
    my ( @cols, @out );
    @cols = map { $_->[1] // ( $_->[0][0] eq 'col' ? $_->[0][1] : $_->[0][0] eq 'fn' ? $_->[0][1] : $_->[0][0] eq 'star' ? '*' : '?column?' ) } @items;
    if ( @items == 1 && $items[0][0][0] eq 'star' ) {
        @cols = grep { !/\A_/ } sort keys %{ $rows[0] // {} };
        @cols = grep { !/\A_/ } sort keys %{ ( _view( $pg, $sess, lc $from ) || [ {} ] )->[0] // {} } unless @cols;
        @out = map { my $r = $_; [ map { $r->{$_} } @cols ] } @rows;
    }
    elsif ( defined $group || grep { $is_count->( $_->[0] ) } @items ) {
        my @g = defined $group ? map { lc s/\A\s+|\s+\z//gr } split /,/, $group : ();
        my ( %bucket, @keys );
        for my $r (@rows) {
            my $k = join "\0", map { $r->{$_} // '' } @g;
            push @keys, $k unless $bucket{$k};
            push @{ $bucket{$k} }, $r;
        }
        @keys = ('') if !@keys && !@g;
        for my $k (@keys) {
            my $b = $bucket{$k} || [];
            push @out, [ map { $is_count->( $_->[0] ) ? scalar @$b : _ev( $_->[0], $b->[0] // {}, $env ) } @items ];
        }
    }
    else {
        @out = map { my $r = $_; [ map { _ev( $_->[0], $r, $env ) } @items ] } @rows;
    }
    if ( defined $order ) {
        my @ob = map { my ( $c, $d ) = /\A\s*(\S+)(?:\s+(ASC|DESC))?\s*\z/i; [ lc $c, uc( $d // 'ASC' ) ] } split /,/, $order;
        my %ix = map { ( $cols[$_] => $_, ( $_ + 1 ) => $_ ) } 0 .. $#cols;
        @out = sort {
            my $c = 0;
            for my $o (@ob) {
                my $i = $ix{ $o->[0] } // next;
                $c = _cmpv( $a->[$i], $b->[$i] );
                $c = -$c if $o->[1] eq 'DESC';
                last if $c;
            }
            $c;
        } @out;
    }
    splice @out, $limit if defined $limit && @out > $limit;
    return _table( $sess, \@cols, \@out );
}

sub _meta {
    my ( $pg, $sess, $st ) = @_;
    my ( $cmd, $arg ) = $st =~ /\A\\(\S+)\s*(.*)\z/;
    $cmd //= '';
    if ( $cmd =~ /\Adu\+?\z|\Adg\+?\z/ ) {
        my @r;
        for my $n ( sort keys %{ $pg->{roles} || {} } ) {
            my $r = $pg->{roles}{$n};
            my @a;
            push @a, 'Superuser' if $r->{superuser};
            push @a, 'Create role' if $r->{createrole};
            push @a, 'Create DB' if $r->{createdb};
            push @a, 'Cannot login' unless $r->{login} || $r->{superuser};
            push @a, 'Replication' if $r->{replication};
            push @r, [ $n, join( ', ', @a ) ];
        }
        return ( "                                   List of roles\n" . _table( $sess, [ 'Role name', 'Attributes' ], \@r ) =~ s/\n\(\d+ rows?\)\z//r, 1 );
    }
    if ( $cmd eq 'l' || $cmd eq 'l+' ) { return ( _list_dbs( $pg, $sess ), 1 ) }
    if ( $cmd eq 'dn' || $cmd eq 'dn+' ) {
        return ( _table( $sess, [qw( Name Owner )], [ map { [ ( split /\./ )[1], $pg->{schemas}{$_}{owner} ] } sort grep {/\A\Q$sess->{db}\E\./} keys %{ $pg->{schemas} || {} } ] ), 1 );
    }
    if ( ( $cmd eq 'd' || $cmd eq 'd+' ) && length $arg ) {
        my $k = _resolve( $pg, $sess, $arg ) // return ( qq{Did not find any relation named "$arg".}, 0 );
        my ( undef, $sch, $n ) = split /\./, $k;
        my $x = $pg->{tables}{$k};
        my @cols = map { [ split /\s+/, $_, 2 ] } @{ $x->{columns} || [] };
        my $t = _table( { fmt => { %{ $sess->{fmt} } } }, [qw( Column Type Collation Nullable Default )],
            [ map { [ $_->[0], $_->[1] // 'text', '', '', '' ] } @cols ] ) =~ s/\n\(\d+ rows?\)\z//r;
        my @o = @{ $x->{reloptions} || [] };
        return ( join( "\n", "                 Table \"$sch.$n\"", $t,
            ( @{ $x->{indexes} || [] } ? ( 'Indexes:', map { qq{    "$_->{name}"} . ( $_->{unique} ? ' UNIQUE,' : '' ) . " $_->{method} (" . join( ', ', @{ $_->{columns} } ) . ')' } @{ $x->{indexes} } ) : () ),
            ( $cmd eq 'd+' ? 'Access method: heap' : () ), ( @o ? 'Options: ' . join( ', ', @o ) : () ) ), 1 );
    }
    if ( $cmd eq 'dt' || $cmd eq 'dt+' ) {
        my @t = map { my ( undef, $s, $n ) = split /\./; [ $s, $n, 'table', $pg->{tables}{$_}{owner} ] } sort grep {/\A\Q$sess->{db}\E\./} keys %{ $pg->{tables} || {} };
        @t = grep { my $x = "$_->[0].$_->[1]"; my $re = $arg =~ s/\./\\./gr =~ s/\*/.*/gr; $x =~ /\A$re\z/ || $_->[1] =~ /\A$re\z/ } @t if length $arg;
        return ( _table( $sess, [qw( Schema Name Type Owner )], \@t ), 1 );
    }
    if ( $cmd eq 'dp' || $cmd eq 'z' ) {
        my @t;
        for my $k ( sort grep {/\A\Q$sess->{db}\E\./} keys %{ $pg->{tables} || {} } ) {
            my ( undef, $s, $n ) = split /\./, $k;
            next if length $arg && "$s.$n" !~ /\A\Q$arg\E\z/ && $n ne $arg && $arg !~ /\A\Q$s\E\.\*\z/;
            my $g = $pg->{grants}{"table:$k"} || {};
            my $own = $pg->{tables}{$k}{owner};
            my $acl = join "\n", map { my $w = $_; ( $w eq 'PUBLIC' ? '' : $w ) . '=' . _acl_letters( $g->{$w} ) . "/$own" } sort keys %$g;
            $acl = "$own=arwdDxt/$own" . ( length $acl ? "\n$acl" : '' ) if %$g;
            push @t, [ $s, $n, 'table', $acl, '', '' ];
        }
        return ( "                            Access privileges\n" . _table( $sess, [ 'Schema', 'Name', 'Type', 'Access privileges', 'Column privileges', 'Policies' ], \@t ), 1 );
    }
    if ( $cmd eq 'ddp' ) {
        my @t = map { [ $_->{role}, $_->{schema} // '', 'table', ( $_->{grantee} eq 'PUBLIC' ? '' : $_->{grantee} ) . '=' . _acl_letters( $_->{privs} ) . "/$_->{role}" ] }
            grep { $_->{db} eq $sess->{db} } @{ $pg->{default_acl} || [] };
        return ( "            Default access privileges\n" . _table( $sess, [ 'Owner', 'Schema', 'Type', 'Access privileges' ], \@t ), 1 );
    }
    if ( $cmd eq 'conninfo' ) {
        return ( qq{You are connected to database "$sess->{db}" as user "$sess->{user}" via socket in "/var/run/postgresql" at port "} . ( $pg->{port} // 5432 ) . '".', 1 );
    }
    if ( $cmd eq 'c' || $cmd eq 'connect' ) {
        my ($db) = split /\s+/, $arg;
        return ( qq{connection to server failed: FATAL:  database "$db" does not exist}, 0 ) unless $pg->{databases}{$db} || $db eq 'postgres';
        $sess->{db} = $db;
        return ( qq{You are now connected to database "$db" as user "$sess->{user}".}, 1 );
    }
    return ( '', 1 ) if $cmd eq 'q' || $cmd eq 'x' || $cmd eq 'timing';
    return _gap($st);
}

# ACL wie im Katalog: {rolle=rechte/eigentuemer,…}; ohne Eintraege NULL
sub _acl_text {
    my ( $pg, $key, $owner ) = @_;
    my $g = ( $pg->{grants} || {} )->{$key} or return undef;
    my @e = map { ( $_ eq 'PUBLIC' ? '' : $_ ) . '=' . _acl_letters( $g->{$_} ) . "/$owner" } grep { @{ $g->{$_} || [] } } sort keys %$g;
    return @e ? '{' . join( ',', @e ) . '}' : undef;
}

sub _acl_letters {
    my ($p) = @_;
    my %l = ( SELECT => 'r', INSERT => 'a', UPDATE => 'w', DELETE => 'd', TRUNCATE => 'D', REFERENCES => 'x', TRIGGER => 't', USAGE => 'U', CREATE => 'C', CONNECT => 'c', TEMPORARY => 'T' );
    my $order = 'arwdDxtUCcT';
    my %have = map { ( $l{$_} // '' ) => 1 } @{ $p || [] };
    return join '', grep { $have{$_} } split //, $order;
}


sub pg_lsclusters {
    my ( $dev, $av, $ctx ) = @_;
    my $pg = $dev->{postgres} or return ( '', 1 );
    my ( $ver, $name ) = split m{/}, $pg->{cluster} // '15/main';
    my $svc = ( $dev->{services} || {} )->{ $pg->{service} // '' } || {};
    return ( join( "\n", 'Ver Cluster Port Status Owner    Data directory              Log file',
        sprintf( '%-3s %-7s %-4s %-6s postgres /var/lib/postgresql/%s/%s /var/log/postgresql/postgresql-%s-%s.log',
            $ver, $name, $pg->{port} // 5432, $svc->{active} ? 'online' : 'down', $ver, $name, $ver, $name ) ), 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Postgres - PostgreSQL on a simulated Linux server — psql, an SQL subset, pg_hba, settings, slots

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator: psql, pg_lsclusters, pg_ctlcluster
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Postgres::psql( $dev, \@argv, $ctx, $as_user );

=head1 DESCRIPTION

A PostgreSQL cluster (Debian 12, version 15) on a device of type
C<linux> (cai-platform F<docs/entwurf-evals.md> §3.3.1): the state lives under
C<postgres> of the device, configuration files under C<files>, the service under
C<services> (name in C<postgres.service>).

  postgres:
    service:   postgresql@15-main
    cluster:   15/main
    port:      5432
    conf:      /etc/postgresql/15/main/postgresql.conf
    auto_conf: /var/lib/postgresql/15/main/postgresql.auto.conf
    hba:       /etc/postgresql/15/main/pg_hba.conf
    wal:       /var/lib/postgresql/15/main/pg_wal      # file with size (takes up space)
    wal_base:  1G                                      # what remains without slots
    settings:  { max_connections: 100, fsync: "on", … }  # running values
    hba_loaded: [ "local all postgres peer", … ]       # loaded lines
    roles:     { postgres: { superuser: true, login: true }, app: { login: true, password: true } }
    members:   { app_rw: [ alice ] }
    databases: { appdb: { owner: app_owner } }
    schemas:   { appdb.app: { owner: app_owner } }
    tables:    { appdb.app.orders: { owner: app_owner, n_live_tup: 1200, n_dead_tup: 0, size: 80M, reloptions: [] } }
    grants:    { "table:appdb.app.orders": { report: [SELECT] }, "schema:appdb.app": {…}, "database:appdb": {…} }
    default_acl: [ { role: app_owner, schema: app, db: appdb, on: tables, grantee: report, privs: [SELECT] } ]
    slots:     { replica_a: { type: physical, active: true, retained: 64M } }
    activity:  [ { pid: 4001, count: 96, usename: api, datname: appdb, client_addr: 10.20.0.11, application_name: api,
                   state: idle, host: app1, service: api } ]     # count: this many identical connections from pid on

B<Commands>: C<psql> (C<-U>, C<-d>, C<-h>, C<-p>, C<-c> repeatable, C<-t>,
C<-A>, C<-x>, C<-X>, C<-q>, C<-l>; user from C<sudo -u>/C<su>), within it SQL
and C<\du>, C<\dp>, C<\ddp>, C<\l>, C<\dn>, C<\dt>, C<\d[+] table> (columns from
C<columns>, options), C<\c>, C<\conninfo>;
C<pg_lsclusters>, C<pg_ctlcluster VER NAME start|stop|restart|reload|status>.

B<SQL subset>: C<SELECT> over the views C<pg_stat_activity>,
C<pg_replication_slots>, C<pg_stat_user_tables>, C<pg_settings>,
C<pg_roles>, C<pg_hba_file_rules>, C<pg_database> (C<datallowconn>, C<datacl>), C<pg_tables>, C<pg_class>,
C<pg_file_settings> (every line of the files, C<applied>), C<pg_authid> (superuser only) and real
tables (row count), with C<WHERE>, C<GROUP BY>, C<ORDER BY>, C<LIMIT> and the
functions C<count(*)>, C<pg_size_pretty>, C<pg_wal_lsn_diff>,
C<pg_current_wal_lsn>, C<pg_terminate_backend>, C<pg_cancel_backend>,
C<pg_drop_replication_slot>, C<pg_reload_conf>, C<current_setting>,
C<version>, C<pg_sleep(x)> (also C<FROM pg_sleep(x)>: from C<log_min_duration_statement> on, a
line C<LOG:  duration: … ms  statement: …> in the cluster's log, a runtime trace); C<pg_settings>
shows C<unit>, C<vartype>, C<boot_val>, values in the base unit and the common
settings with their default (C<source> default); C<SHOW>, C<ALTER SYSTEM SET|RESET>, C<CHECKPOINT>, C<VACUUM
[FULL] [ANALYZE]>, C<ANALYZE>, C<ALTER TABLE … SET|RESET (…)>, C<CREATE|ALTER|DROP
ROLE/USER>, C<GRANT>/C<REVOKE> (tables, all tables of a schema,
schema, database, roles), C<ALTER DEFAULT PRIVILEGES [FOR ROLE r] [IN SCHEMA
s] GRANT|REVOKE … ON TABLES>, C<DROP TABLE|DATABASE|SCHEMA>, C<TRUNCATE>,
C<DELETE FROM> (change the state — the rules see it), C<CREATE [UNIQUE] INDEX
[CONCURRENTLY] [name] ON table [USING method] (columns)> and C<DROP INDEX> (list
C<indexes> of the table: C<name>, C<columns>, C<method>, C<unique>). Anything
beyond that is a B<simulation gap> (neutral answer).

B<Effect>: C<reload> (C<systemctl reload>, C<pg_ctlcluster … reload>,
C<SELECT pg_reload_conf()>) rereads C<postgresql.conf>, C<postgresql.auto.conf>
and C<pg_hba.conf>; settings with context C<postmaster>
(C<max_connections>, C<shared_buffers>, C<listen_addresses> …) take effect only
after a restart (C<pending_restart>). A restart ends all
connections. Connections check the service, the role, C<pg_hba> (loaded lines,
first match wins) and the number of connections against
C<max_connections>. A dropped slot frees its WAL at the next
C<CHECKPOINT>.

Pure functions on the state, neutral.

=head2 service_event

  service_event( $dev, $service, $verb );   # from the Linux simulator

Effect of C<start>/C<restart>/C<reload>/C<stop> of a service on
PostgreSQL: its own service reads the configuration, a restart ends the
connections; another service with C<pg_connect> reconnects.

=head2 psql

  my ( $out, $ok ) = psql( $dev, \@argv, $ctx, $os_user );

=head2 pg_lsclusters

  my ( $out, $ok ) = pg_lsclusters( $dev, \@argv, $ctx );

Output of C<pg_lsclusters>: header line and one line for the device's cluster
with version, name, port and C<online>/C<down> per the service; empty
without PostgreSQL on the device.

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
