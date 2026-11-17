package Langertha::Holmgang::Sim::Linux::MariaDB;
# ABSTRACT: MariaDB on a simulated Linux server — mysql/mariadb client, variables, users, binlogs, replica

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use JSON::MaybeXS ();
use Langertha::Holmgang::Sim::Linux ();

our $VERSION = '0.001';


our @GAPS;

# Variablen: Vorgabe, dynamisch?, Art (int|size|bool|str|enum)
our %VAR = (
    max_connections                => [ '151',                        1, 'int' ],
    max_user_connections           => [ '0',                          1, 'int' ],
    bind_address                   => [ '127.0.0.1',                  0, 'str' ],
    port                           => [ '3306',                       0, 'int' ],
    socket                         => [ '/run/mysqld/mysqld.sock',    0, 'str' ],
    datadir                        => [ '/var/lib/mysql/',            0, 'str' ],
    tmpdir                         => [ '/tmp',                       0, 'str' ],
    log_error                      => [ '',                           0, 'str' ],
    log_bin                        => [ 'OFF',                        0, 'bool' ],
    log_bin_basename               => [ '',                           0, 'str' ],
    server_id                      => [ '1',                          1, 'int' ],
    expire_logs_days               => [ '0.000000',                   1, 'days' ],
    binlog_expire_logs_seconds     => [ '0',                          1, 'int' ],
    max_binlog_size                => [ '1073741824',                 1, 'size' ],
    binlog_format                  => [ 'MIXED',                      1, 'str' ],
    innodb_buffer_pool_size        => [ '134217728',                  1, 'size' ],
    innodb_log_file_size           => [ '100663296',                  0, 'size' ],
    innodb_flush_log_at_trx_commit => [ '1',                          1, 'int' ],
    innodb_file_per_table          => [ 'ON',                         0, 'bool' ],
    max_allowed_packet             => [ '16777216',                   1, 'size' ],
    wait_timeout                   => [ '28800',                      1, 'int' ],
    interactive_timeout            => [ '28800',                      1, 'int' ],
    slow_query_log                 => [ 'OFF',                        1, 'bool' ],
    slow_query_log_file            => [ 'mariadb-slow.log',           1, 'str' ],
    long_query_time                => [ '10.000000',                  1, 'float' ],
    general_log                    => [ 'OFF',                        1, 'bool' ],
    character_set_server           => [ 'utf8mb4',                    1, 'str' ],
    collation_server               => [ 'utf8mb4_general_ci',         1, 'str' ],
    sql_mode                       => [ 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION', 1, 'str' ],
    read_only                      => [ 'OFF',                        1, 'bool' ],
    skip_name_resolve              => [ 'OFF',                        0, 'bool' ],
    table_open_cache               => [ '2000',                       1, 'int' ],
    thread_cache_size              => [ '151',                        1, 'int' ],
    tmp_table_size                 => [ '16777216',                   1, 'size' ],
    max_heap_table_size            => [ '16777216',                   1, 'size' ],
    open_files_limit               => [ '32768',                      0, 'int' ],
    query_cache_size               => [ '1048576',                    1, 'size' ],
    query_cache_type               => [ 'OFF',                        1, 'str' ],
    relay_log                      => [ '',                           0, 'str' ],
    sql_slave_skip_counter         => [ '0',                          1, 'int' ],
    slave_skip_errors              => [ 'OFF',                        0, 'str' ],
    slave_parallel_threads         => [ '0',                          1, 'int' ],
    slave_parallel_mode            => [ 'optimistic',                 1, 'str' ],
    slave_parallel_max_queued      => [ '131072',                     1, 'int' ],
    max_connect_errors             => [ '100',                        1, 'int' ],
    version                        => [ '10.11.6-MariaDB-0+deb12u1-log', 0, 'ro' ],
);

# Neue Namen (replica_*) sind in 10.11 Aliase der alten
our %VAR_ALIAS = ( replica_parallel_threads => 'slave_parallel_threads', replica_parallel_mode => 'slave_parallel_mode',
    replica_parallel_max_queued => 'slave_parallel_max_queued' );

sub _norm_name { my ($n) = @_; $n = lc $n; $n =~ s/-/_/g; return $VAR_ALIAS{$n} // $n }

sub _size {
    my ($v) = @_;
    return undef unless defined $v && $v =~ /\A\s*(\d+)\s*([kmgt])?\s*\z/i;
    return $1 * { '' => 1, k => 1024, m => 1024**2, g => 1024**3, t => 1024**4 }->{ lc( $2 // '' ) };
}

# Wert einer Variablen pruefen: ( normalisiert ) oder ( undef, fehler )
sub _value {
    my ( $n, $v ) = @_;
    my $kind = $VAR{$n}[2];
    $v = '' unless defined $v;
    $v =~ s/\A(['"])(.*)\1\z/$2/;
    if ( $kind eq 'size' ) { my $b = _size($v); return defined $b ? ("$b") : ( undef, "Incorrect argument type to variable '$n'" ) }
    if ( $kind eq 'int' )  { return $v =~ /\A\d+\z/ ? ("$v") : ( undef, "Incorrect argument type to variable '$n'" ) }
    if ( $kind eq 'float' ) { return $v =~ /\A\d+(?:\.\d+)?\z/ ? ( sprintf '%.6f', $v ) : ( undef, "Incorrect argument type to variable '$n'" ) }
    if ( $kind eq 'days' ) { return $v =~ /\A\d+(?:\.\d+)?\z/ ? ( sprintf '%.6f', $v ) : ( undef, "Incorrect argument type to variable '$n'" ) }
    if ( $kind eq 'bool' ) {
        my $x = uc $v;
        return ('ON')  if $x eq '' || $x eq 'ON' || $x eq '1' || $x eq 'TRUE';
        return ('OFF') if $x eq 'OFF' || $x eq '0' || $x eq 'FALSE';
        return ( 'ON' ) if $n eq 'log_bin';    # log_bin = name
        return ( undef, "Variable '$n' can't be set to the value of '$v'" );
    }
    return ($v);
}

sub _file_text {
    my ( $dev, $p ) = @_;
    my $e = ( $dev->{files} || {} )->{$p};
    return undef unless defined $e;
    return ref $e eq 'HASH' ? $e->{content} // '' : $e;
}

sub _conf_files { my ($dev) = @_; my $c = $dev->{mariadb}{conf} // ['/etc/mysql/mariadb.conf.d/50-server.cnf']; return ref $c ? @$c : ($c) }


sub parse_conf {
    my ($dev) = @_;
    my %v = map { $_ => $VAR{$_}[0] } keys %VAR;
    for my $f ( _conf_files($dev) ) {
        my $t = _file_text( $dev, $f ) // next;
        my $sec = '';
        for my $line ( split /\n/, $t ) {
            next if $line =~ /\A\s*(?:[#;]|\z)/;
            if ( $line =~ /\A\s*\[([^\]]+)\]/ ) { $sec = lc $1; next }
            next unless $sec =~ /\A(?:mysqld|mariadb|server|mariadbd|mariadb-10\.11)\z/;
            my ( $k, $val ) = $line =~ /\A\s*([\w-]+)\s*(?:=\s*(.*?))?\s*\z/ or return ( undef, $f, $line, 'syntax' );
            $k = _norm_name($k);
            $k = 'log_bin' if $k eq 'log_bin';
            if ( $k eq 'log_bin' ) { $v{log_bin} = 'ON'; $v{log_bin_basename} = '/var/lib/mysql/' . ( $val // 'mysqld-bin' ) =~ s{.*/}{}r =~ s/\.\w+\z//r; next }
            next if $k =~ /\A(?:user|pid_file|basedir|lc_messages_dir|lc_messages|expire_logs|skip_external_locking|log_slave_updates|log_replica_updates|innodb_buffer_pool_instances|key_buffer_size|myisam_recover_options)\z/;
            return ( undef, $f, $line, "unknown variable '" . ( $line =~ s/\A\s+|\s+\z//gr =~ s/\s*=\s*/=/r ) . "'" ) unless exists $VAR{$k} && $VAR{$k}[2] ne 'ro';
            my ( $x, $e ) = _value( $k, $val );
            return ( undef, $f, $line, "Error while setting value '" . ( $val // '' ) . "' to '$k'" ) unless defined $x;
            $v{$k} = $x;
        }
    }
    { my ( $s, $d ) = ( "$v{binlog_expire_logs_seconds}", "$v{expire_logs_days}" ); $v{expire_logs_days} = sprintf "%.6f", $s / 86400 if $s && $d == 0 }    # Kopien: Zahlenkontext aendert die JSON-Form nicht
    return ( \%v );
}


sub conf_error {
    my ($dev) = @_;
    return undef unless $dev->{mariadb};
    my ( $v, $f, $line, $why ) = parse_conf($dev);
    if ($v) {
        # tmpdir muss fuer mysql schreibbar sein (Verzeichnis im Zustand: Eigentuemer, Gruppe, Rechte)
        ( my $t = $v->{tmpdir} // '/tmp' ) =~ s{(?<=.)/+\z}{};
        my $d = ( $dev->{dirs} || {} )->{$t} or return undef;
        my $m = oct( $d->{mode} // '0755' );
        my $u = ( $d->{owner} // 'root' ) eq 'mysql' ? $m & 0200 : ( $d->{group} // 'root' ) eq 'mysql' ? $m & 020 : $m & 002;
        return undef if $u;
        return [ "[ERROR] mariadbd: Can't create/write to file '$t/ibXXXXXX' (Errcode: 13 \"Permission denied\")",
            '[ERROR] InnoDB: Unable to create temporary file; errno: 13', '[ERROR] Aborting' ];
    }
    return [ "[ERROR] /usr/sbin/mariadbd: $why", '[ERROR] Aborting' ] if $why =~ /\Aunknown variable/;
    return [ "[ERROR] mariadbd: $why ($f)", '[ERROR] Aborting' ];
}

sub _vars {
    my ($dev) = @_;
    my $m = $dev->{mariadb};
    if ( !$m->{variables} ) { my ($v) = parse_conf($dev); $m->{variables} = $v // { map { $_ => $VAR{$_}[0] } keys %VAR } }
    return $m->{variables};
}


sub service_event {
    my ( $dev, $verb ) = @_;
    my $m = $dev->{mariadb} or return;
    if ( $verb eq 'start' || $verb eq 'restart' ) {
        my ($v) = parse_conf($dev);
        $m->{variables} = $v if $v;
        # Verbindungen sind weg; die Anwendungen verbinden sich neu (einmal je Eintrag)
        if ( $m->{processlist} ) {
            my @p = map { +{ %$_, count => 1, time => 0 } } grep { ( $_->{user} // '' ) ne 'system user' } @{ $m->{processlist} };
            $m->{processlist} = \@p;
            my $n = 0;
            $n += $_->{count} // 1 for @p;
            $m->{status}{Threads_connected} = $n if $m->{status};
        }
        if ( my $r = $m->{replica} ) { $r->{io} = 'Yes'; $r->{sql} = $r->{last_errno} ? 'No' : 'Yes' }
    }
    return;
}

sub _active {
    my ($dev) = @_;
    my $svc = ( $dev->{services} || {} )->{ $dev->{mariadb}{service} // 'mariadb' };
    return $svc && $svc->{active} ? 1 : 0;
}

# --- Ausgabe ---------------------------------------------------------------------

sub _render {
    my ( $o, $cols, $rows ) = @_;
    if ( $o->{vertical} ) {
        my $w = 0;
        $w = length > $w ? length : $w for @$cols;
        my @l;
        my $i = 0;
        for my $r (@$rows) {
            $i++;
            push @l, ( '*' x 27 ) . " $i. row " . ( '*' x 27 );
            push @l, sprintf( "%*s: %s", $w, $cols->[$_], $r->[$_] // 'NULL' ) for 0 .. $#$cols;
        }
        return join "\n", @l;
    }
    if ( $o->{table} ) {
        my @w = map { length $_ } @$cols;
        for my $r (@$rows) { for my $i ( 0 .. $#$cols ) { my $l = length( $r->[$i] // 'NULL' ); $w[$i] = $l if $l > $w[$i] } }
        my $sep = '+' . join( '+', map { '-' x ( $_ + 2 ) } @w ) . '+';
        my $fmt = sub { my @v = @_; '| ' . join( ' | ', map { sprintf '%-*s', $w[$_], $v[$_] // 'NULL' } 0 .. $#w ) . ' |' };
        return join "\n", $sep, $fmt->(@$cols), $sep, ( map { $fmt->(@$_) } @$rows ), $sep;
    }
    my @l;
    push @l, join "\t", @$cols unless $o->{skip_names};
    push @l, join "\t", map { $_ // 'NULL' } @$_ for @$rows;
    return join "\n", @l;
}

sub _like {
    my ($pat) = @_;
    return undef unless defined $pat;
    $pat =~ s/\A['"]|['"]\z//g;
    my $re = join '', map { $_ eq '%' ? '.*' : $_ eq '_' ? '.' : quotemeta $_ } split //, $pat;
    return qr/\A$re\z/i;
}

# --- Benutzer und Rechte -------------------------------------------------------------

sub _account {
    my ($s) = @_;    # 'u'@'h' | u@h | `u`@`h` | 'u'
    $s =~ s/\s+//g;
    my ( $u, $h ) = $s =~ /\A['"`]?([^'"`@]*)['"`]?(?:@['"`]?([^'"`]*)['"`]?)?\z/ or return;
    return ( $u, $h // '%' );
}

sub _host_match {
    my ( $pat, $host ) = @_;
    return 1 if $pat eq '%';
    return 1 if $pat eq $host;
    return 1 if $pat eq 'localhost' && ( $host eq 'localhost' || $host eq '127.0.0.1' );
    my $re = join '', map { $_ eq '%' ? '.*' : $_ eq '_' ? '.' : quotemeta $_ } split //, $pat;
    return $host =~ /\A$re\z/ ? 1 : 0;
}

# bestes Konto fuer user@host (genauester Host zuerst)
sub _find_account {
    my ( $m, $user, $host ) = @_;
    my @c = grep { my ( $u, $h ) = split /@/, $_, 2; $u eq $user && _host_match( $h, $host ) } keys %{ $m->{users} || {} };
    my ($best) = sort { ( ( split /@/, $a, 2 )[1] =~ tr/%_// ) <=> ( ( split /@/, $b, 2 )[1] =~ tr/%_// ) || length( $b ) <=> length( $a ) } @c;
    return $best;
}

# mysql_native_password: '*' . SHA1(SHA1(passwort)) in Grossbuchstaben
sub _pwhash { my ($pw) = @_; return '*' . uc Digest::SHA::sha1_hex( Digest::SHA::sha1( $pw // '' ) ) }

# Klartext zu einem Hash aus den bekannten Konten (IDENTIFIED BY PASSWORD '*…'), sonst undef
sub _pw_from_hash {
    my ( $m, $hash ) = @_;
    return undef unless defined $hash && $hash =~ /\A\*[0-9A-Fa-f]{40}\z/;
    for my $a ( values %{ $m->{users} || {} } ) {
        return $a->{password} if defined $a->{password} && _pwhash( $a->{password} ) eq uc $hash;
    }
    return undef;
}

sub _norm_obj {
    my ($o) = @_;
    $o =~ s/\s+//g;
    $o =~ s/[`'"]//g;
    my ( $db, $t ) = split /\./, $o, 2;
    $t //= '*';
    return ( $db eq '*' ? '*' : "`$db`" ) . '.' . ( $t eq '*' ? '*' : "`$t`" );
}

our @PRIV_ORDER = ( 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'DROP', 'RELOAD', 'SHUTDOWN', 'PROCESS', 'FILE', 'REFERENCES', 'INDEX', 'ALTER',
    'SHOW DATABASES', 'SUPER', 'CREATE TEMPORARY TABLES', 'LOCK TABLES', 'EXECUTE', 'REPLICATION SLAVE', 'BINLOG MONITOR', 'CREATE VIEW', 'SHOW VIEW',
    'CREATE ROUTINE', 'ALTER ROUTINE', 'CREATE USER', 'EVENT', 'TRIGGER', 'REPLICATION CLIENT', 'SLAVE MONITOR' );

# Spalten von mysql.db
our @DB_PRIVS = ( 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'DROP', 'REFERENCES', 'INDEX', 'ALTER', 'CREATE TEMPORARY TABLES',
    'LOCK TABLES', 'CREATE VIEW', 'SHOW VIEW', 'CREATE ROUTINE', 'ALTER ROUTINE', 'EXECUTE', 'EVENT', 'TRIGGER' );
our %DB_PRIV = ( map { my $x = lc $_; $x =~ s/ /_/g; $_ => ucfirst($x) . '_priv' } @DB_PRIVS );
$DB_PRIV{'CREATE TEMPORARY TABLES'} = 'Create_tmp_table_priv';

sub _priv_list {
    my ($s) = @_;
    my @p = map { my $x = uc $_; $x =~ s/\s+/ /g; $x =~ s/\A\s|\s\z//g; $x } split /,/, $s;
    return ('ALL PRIVILEGES') if grep { $_ eq 'ALL' || $_ eq 'ALL PRIVILEGES' } @p;
    my %rank = map { $PRIV_ORDER[$_] => $_ } 0 .. $#PRIV_ORDER;
    return sort { ( $rank{$a} // 99 ) <=> ( $rank{$b} // 99 ) || $a cmp $b } @p;
}

# grants: [ "SELECT, INSERT ON `shop`.*", … ] <-> { obj => [privs] }
sub _grant_map {
    my ($acc) = @_;
    my %g;
    for my $line ( @{ $acc->{grants} || [] } ) {
        my ( $p, $obj ) = $line =~ /\A(.+?)\s+ON\s+(\S+)\z/ or next;
        $g{ _norm_obj($obj) } = [ _priv_list($p) ];
    }
    return \%g;
}

sub _store_grants {
    my ( $acc, $g ) = @_;
    $acc->{grants} = [ map { join( ', ', @{ $g->{$_} } ) . " ON $_" } sort grep { @{ $g->{$_} } } keys %$g ];
    return;
}

sub _has_priv {
    my ( $m, $acc, $priv ) = @_;
    return 1 if ( $acc // '' ) =~ /\Aroot@/;
    my $a = $m->{users}{ $acc // '' } or return 0;
    my $g = _grant_map($a)->{'*.*'} || [];
    return scalar grep { $_ eq 'ALL PRIVILEGES' || $_ eq $priv } @$g;
}

# --- SQL ----------------------------------------------------------------------------

sub _split_sql {
    my ($s) = @_;
    my @st;
    my $cur = '';
    my $q;
    for my $c ( split //, $s ) {
        if ($q) { $q = undef if $c eq $q; $cur .= $c; next }
        if ( $c eq "'" || $c eq '"' || $c eq '`' ) { $q = $c; $cur .= $c; next }
        if ( $c eq ';' ) { push @st, $cur; $cur = ''; next }
        $cur .= $c;
    }
    push @st, $cur;
    my @out;
    for (@st) {
        my $x = $_;
        while ( $x =~ s/\\G// ) { }
        my $vert = $_ =~ /\\G\s*\z/ ? 1 : 0;
        $x =~ s/\A\s+|\s+\z//g;
        push @out, [ $x, $vert ] if length $x;
    }
    return @out;
}

sub _err { my ( $code, $state, $msg ) = @_; return ( "ERROR $code ($state) at line 1: $msg", 0 ) }

# an Kommas der obersten Ebene trennen (nicht in Klammern oder Anfuehrungszeichen)
sub _split_top {
    my ($s) = @_;
    my @p;
    my ( $cur, $depth, $q ) = ( '', 0, '' );
    for my $ch ( split //, $s ) {
        if ($q) { $q = '' if $ch eq $q; $cur .= $ch; next }
        if ( $ch eq "'" || $ch eq '"' ) { $q = $ch; $cur .= $ch; next }
        $depth++ if $ch eq '(';
        $depth-- if $ch eq ')';
        if ( $ch eq ',' && !$depth ) { push @p, $cur; $cur = ''; next }
        $cur .= $ch;
    }
    push @p, $cur;
    return map { s/\A\s+|\s+\z//gr } @p;
}

# Spaltenliste eines SELECT: [ { expr, label } ]; Alias mit AS oder nachgestellt, sonst der
# Ausdruck wie geschrieben (ein Text ohne Anfuehrungszeichen) als Ueberschrift
sub _sel_items {
    my ($cols) = @_;
    return [ map {
        my ( $e, $al ) = /\A(.+?)\s+(?:AS\s+)?[`"]?(\w+)[`"]?\z/is ? ( $1, $2 ) : ( $_, undef );
        ( $e, $al ) = ( $_, undef ) if $e =~ /\A'[^']*\z/;    # Leerzeichen im Text, kein Alias
        +{ expr => $e, label => $al // ( $e =~ /\A'(.*)'\z/s ? $1 =~ s/''/'/gr : $e ) }
    } _split_top($cols) ];
}

# Wert eines Ausdrucks in einer Zeile: Spalte, Zahl, 'Text', NOW(), USER(), VERSION(), CONCAT,
# LEFT, RIGHT, LENGTH, CHAR_LENGTH, UPPER, LOWER, PASSWORD; undef = nicht nachgebildet (Luecke)
sub _sql_val {
    my ( $e, $row, $env ) = @_;
    $e =~ s/\A\s+|\s+\z//g;
    return $1 =~ s/''/'/gr if $e =~ /\A'((?:[^']|'')*)'\z/s;
    return $e if $e =~ /\A-?\d+(?:\.\d+)?\z/;
    if ( $e =~ /\A(\w+)\s*\((.*)\)\z/s ) {
        my ( $f, $in ) = ( uc $1, $2 );
        return $env->{now}     if $f eq 'NOW' && $in !~ /\S/;
        return $env->{user}    if ( $f eq 'USER' || $f eq 'CURRENT_USER' ) && $in !~ /\S/;
        return $env->{version} if $f eq 'VERSION' && $in !~ /\S/;
        my @a = map { _sql_val( $_, $row, $env ) } _split_top($in);
        return undef if !@a || grep { !defined } @a;
        return join( '', @a ) if $f eq 'CONCAT';
        return substr( $a[0], 0, $a[1] ) if $f eq 'LEFT' && @a == 2 && $a[1] =~ /\A\d+\z/;
        return $a[1] ? substr( $a[0], -$a[1] ) : '' if $f eq 'RIGHT' && @a == 2 && $a[1] =~ /\A\d+\z/;
        if ( @a == 1 ) {
            if ( $f eq 'LENGTH' ) { require Encode; return length Encode::encode( 'UTF-8', $a[0] ) }
            return length $a[0] if $f eq 'CHAR_LENGTH' || $f eq 'CHARACTER_LENGTH';
            return uc $a[0]     if $f eq 'UPPER' || $f eq 'UCASE';
            return lc $a[0]     if $f eq 'LOWER' || $f eq 'LCASE';
            return _pwhash( $a[0] ) if $f eq 'PASSWORD';
        }
        return undef;
    }
    return $row->{ lc $1 } if $e =~ /\A`?(\w+)`?\z/ && $row && exists $row->{ lc $1 };
    return undef;
}

# Ergebnis einer Spaltenliste ueber Zeilen: nur COUNT(*) -> eine Zeile mit der Anzahl;
# ( \@ueberschriften, \@zeilen ) oder () wenn ein Ausdruck nicht nachgebildet ist
sub _sel_rows {
    my ( $items, $rows, $env ) = @_;
    my @h = map { $_->{label} } @$items;
    if ( !grep { $_->{expr} !~ /\ACOUNT\s*\(\s*\*\s*\)\z/i } @$items ) { return ( \@h, [ [ map { scalar @$rows } @$items ] ] ) }
    return if grep { $_->{expr} =~ /\A\w+\s*\(\s*(?:\*|DISTINCT\b)/i } @$items;
    my @out;
    for my $r (@$rows) {
        my @v;
        for (@$items) { my $x = _sql_val( $_->{expr}, $r, $env ); return unless defined $x; push @v, $x }
        push @out, \@v;
    }
    return ( \@h, \@out );
}

sub _statement {
    my ( $dev, $sql, $o, $acc ) = @_;
    my $m = $dev->{mariadb};
    my $v = _vars($dev);
    my $super = _has_priv( $m, $acc, 'SUPER' ) || _has_priv( $m, $acc, 'ALL PRIVILEGES' );
    ( my $s = $sql ) =~ s/\s+/ /g;
    my $env = { user => $acc // '', version => $v->{version},
        now => '2026-10-24 ' . ( ( $dev->{clock} // '' ) =~ /(\d+:\d+)\z/ ? "$1:00" : '09:12:00' ) };

    if ( $s =~ /\ASHOW (?:(GLOBAL|SESSION) )?VARIABLES(?: (?:LIKE (\S+)|WHERE .*))?\z/i ) {
        my $re = _like($2);
        my @r = map { [ $_, $v->{$_} ] } grep { !defined $re || $_ =~ $re } sort keys %$v;
        return ( _render( $o, [qw( Variable_name Value )], \@r ), 1 );
    }
    if ( $s =~ /\ASHOW (?:(GLOBAL|SESSION) )?STATUS(?: LIKE (\S+))?\z/i ) {
        my $re = _like($2);
        my %st = ( Uptime => 1728000, Threads_running => 2, %{ $m->{status} || {} } );
        my @r = map { [ $_, $st{$_} ] } grep { !defined $re || $_ =~ $re } sort keys %st;
        return ( _render( $o, [qw( Variable_name Value )], \@r ), 1 );
    }
    if ( $s =~ /\ASELECT (\@\@.+?)\s*\z/i ) {
        my @cols = split /\s*,\s*/, $1;
        my @vals;
        my @names;
        for my $c (@cols) {
            my ( $expr, $alias ) = $c =~ /\A(.+?)(?:\s+AS\s+[`'"]?(\w+)[`'"]?)?\z/i;
            my $bad;
            my $num = $expr;
            for my $n ( $expr =~ /\@\@(?:global\.|session\.)?(\w+)/g ) {
                my $k = lc $n;
                if ( !exists $v->{$k} ) { $bad = [ 1, $k ]; last }
                my $x = $v->{$k};
                if ( $x =~ /\A-?\d+(?:\.\d+)?\z/ ) { $num =~ s/\@\@(?:global\.|session\.)?\Q$n\E\b/($x)/ }
                else { $bad //= [ 0, $k ] }
            }
            return _err( 1193, 'HY000', "Unknown system variable '$bad->[1]'" ) if $bad && $bad->[0];
            if ( $expr =~ /\A\s*\@\@(?:global\.|session\.)?\w+\s*\z/ ) { my ($n) = $expr =~ /(\w+)\s*\z/; push @vals, $v->{ lc $n } }
            elsif ( !$bad && $num =~ m{\A[\d\s.+\-*/()]+\z} ) {
                my $r = eval $num;
                return _gap($sql) unless defined $r;
                push @vals, $num =~ m{/} ? sprintf( '%.4f', $r ) : $r;
            }
            else { return _gap($sql) }
            push @names, $alias // $expr;
        }
        return ( _render( $o, \@names, [ \@vals ] ), 1 );
    }
    if ( $s =~ /\ASET (?:(GLOBAL|SESSION|PERSIST) |\@\@(?:global|GLOBAL)\.)?(.+)\z/i ) {
        my ( $scope, $rest ) = ( $1, $2 );
        my $glob = ( $s =~ /\ASET (?:GLOBAL |\@\@global\.)/i ) ? 1 : 0;
        for my $as ( split /\s*,\s*(?=(?:GLOBAL |\@\@)?[\w.]+\s*=)/i, $rest ) {
            $as =~ s/\A(?:GLOBAL\s+|\@\@global\.)//i;
            my ( $n, $val ) = $as =~ /\A\@?\@?([\w.]+)\s*=\s*(.+?)\s*\z/ or return _gap($sql);
            $n = _norm_name($n);
            return _err( 1193, 'HY000', "Unknown system variable '$n'" ) unless exists $VAR{$n};
            return _err( 1238, 'HY000', "Variable '$n' is a read only variable" ) unless $VAR{$n}[1];
            return _err( 1229, 'HY000', "Variable '$n' is a GLOBAL variable and should be set with SET GLOBAL" ) unless $glob;
            return _err( 1227, '42000', 'Access denied; you need (at least one of) the SUPER privilege(s) for this operation' ) unless $super;
            # parallele Replikation: nur bei angehaltenem SQL-Thread
            if ( $n =~ /\Aslave_parallel_(?:threads|mode)\z/ && $m->{replica} && $m->{replica}{sql} eq 'Yes' ) {
                return _err( 1198, 'HY000', "This operation cannot be performed as you have a running slave ''; run STOP SLAVE '' first" );
            }
            if ( $n eq 'sql_slave_skip_counter' ) {
                my $r = $m->{replica} or return _err( 1200, 'HY000', 'Misconfigured slave: MASTER_HOST was not set; Fix in config file or with CHANGE MASTER TO' );
                return _err( 1198, 'HY000', 'This operation cannot be performed as you have a running slave; run STOP SLAVE first' ) if $r->{sql} eq 'Yes';
            }
            # SET GLOBAL x = 256*1024*1024 — einfache Rechnung wie MariaDB
            if ( $val =~ m{\A[\d\s()+\-*/]+\z} && $val =~ m{[+\-*/]} ) {
                my $r = eval $val;
                $val = int($r) if defined $r;
            }
            my ( $x, $e ) = _value( $n, $val );
            return _err( 1232, '42000', $e ) unless defined $x;
            $v->{$n} = $x;
            $v->{expire_logs_days} = sprintf '%.6f', $x / 86400 if $n eq 'binlog_expire_logs_seconds';
            $v->{binlog_expire_logs_seconds} = int( $x * 86400 ) . '' if $n eq 'expire_logs_days';
        }
        return ( '', 1 );
    }
    # information_schema.processlist: dieselben Verbindungen wie SHOW PROCESSLIST
    if ( $s =~ /\ASELECT (.+?) FROM information_schema\.processlist(?: WHERE (.+?))?(?: ORDER BY (\w+)(?: (ASC|DESC))?)?(?: LIMIT (\d+))?\z/i ) {
        my ( $cols, $where, $ord, $dir, $lim ) = ( $1, $2, $3, $4, $5 );
        my @all = qw( ID USER HOST DB COMMAND TIME STATE INFO );
        my @c = $cols eq '*' ? @all : map { s/[`\s]//gr } split /,/, $cols;
        my @r;
        for my $p ( @{ $m->{processlist} || [] } ) {
            for my $i ( 0 .. ( $p->{count} // 1 ) - 1 ) {
                my %row = ( id => $p->{id} + $i, user => $p->{user}, host => $p->{host} // 'localhost', db => $p->{db} // 'NULL',
                    command => $p->{command} // 'Sleep', time => $p->{time} // 0, state => $p->{state} // '', info => $p->{info} // 'NULL' );
                my $keep = _where( \%row, $where ) // return _gap($sql);
                push @r, \%row if $keep;
            }
        }
        if ( defined $ord ) {
            my $k = lc $ord;
            return _gap($sql) unless grep { lc $_ eq $k } @all;
            @r = sort { $a->{$k} =~ /\A-?\d+\z/ && $b->{$k} =~ /\A-?\d+\z/ ? $a->{$k} <=> $b->{$k} : $a->{$k} cmp $b->{$k} } @r;
            @r = reverse @r if uc( $dir // '' ) eq 'DESC';
        }
        splice @r, $lim if defined $lim && @r > $lim;
        return ( _render( $o, \@c, [ map { my $x = $_; [ map { $x->{ lc $_ } // return _gap($sql) } @c ] } @r ] ), 1 );
    }
    if ( $s =~ /\ASHOW (FULL )?PROCESSLIST\z/i ) {
        my @r;
        for my $p ( @{ $m->{processlist} || [] } ) {
            for my $i ( 0 .. ( $p->{count} // 1 ) - 1 ) {
                push @r, [ $p->{id} + $i, $p->{user}, $p->{host} // 'localhost', $p->{db} // 'NULL', $p->{command} // 'Sleep', $p->{time} // 0,
                    $p->{state} // '', $p->{info} // 'NULL', '0.000' ];
            }
        }
        return ( _render( $o, [qw( Id User Host db Command Time State Info Progress )], \@r ), 1 );
    }
    if ( $s =~ /\AKILL (?:CONNECTION )?(\d+)\z/i ) {
        my $id = $1;
        for my $p ( @{ $m->{processlist} || [] } ) {
            next unless $id >= $p->{id} && $id < $p->{id} + ( $p->{count} // 1 );
            $p->{count} = ( $p->{count} // 1 ) - 1;
            $m->{status}{Threads_connected}-- if $m->{status} && $m->{status}{Threads_connected};
            $m->{processlist} = [ grep { ( $_->{count} // 1 ) > 0 } @{ $m->{processlist} } ];
            return ( '', 1 );
        }
        return _err( 1094, 'HY000', "Unknown thread id: $id" );
    }
    if ( $s =~ /\ASHOW DATABASES(?: LIKE (\S+))?\z/i ) {
        my $pat = $1;
        my $re  = _like($pat);
        my @d = grep { !defined $re || $_ =~ $re } sort( qw( information_schema mysql performance_schema sys ), @{ $m->{databases} || [] } );
        return ( _render( $o, [ defined $pat ? "Database ($pat)" =~ s/['"]//gr : 'Database' ], [ map { [$_] } @d ] ), 1 );
    }
    if ( $s =~ /\ASELECT (.+?) FROM mysql\.user(?: WHERE (.+?))?(?: ORDER BY .+)?\z/i ) {
        my ( $cols, $where ) = ( $1, $2 );
        $cols = 'Host,User' if $cols =~ /\A\s*\*\s*\z/;
        my @rows;
        for my $k ( sort keys %{ $m->{users} || {} } ) {
            my ( $u, $h ) = split /@/, $k, 2;
            my $a  = $m->{users}{$k};
            my $hash = defined $a->{password} ? _pwhash( $a->{password} ) : '';
            my %row = ( user => $u, host => $h, plugin => ( $a->{auth} // 'mysql_native_password' ), authentication_string => $hash,
                password => $hash, account_locked => 'N', password_expired => 'N' );
            my $keep = _where( \%row, $where ) // return _gap($sql);
            push @rows, \%row if $keep;
        }
        my ( $hd, $r ) = _sel_rows( _sel_items($cols), \@rows, $env ) or return _gap($sql);
        return ( _render( $o, $hd, $r ), 1 );
    }
    # mysql.db: Rechte je Datenbank aus den Grants (db.*)
    if ( $s =~ /\ASELECT (.+?) FROM mysql\.db(?: WHERE (.+?))?(?: ORDER BY .+)?\z/i ) {
        my ( $cols, $where ) = ( $1, $2 );
        my @c = map { s/[`\s]//gr } split /,/, $cols;
        @c = ( qw( Host Db User ), map { $DB_PRIV{$_} } @DB_PRIVS ) if $c[0] eq '*';
        my @r;
        for my $k ( sort keys %{ $m->{users} || {} } ) {
            my ( $u, $h ) = split /@/, $k, 2;
            my $g = _grant_map( $m->{users}{$k} );
            for my $obj ( sort keys %$g ) {
                my ($db) = $obj =~ /\A`([^`]+)`\.\*\z/ or next;
                my %have = map { $_ => 1 } @{ $g->{$obj} };
                my %row = ( host => $h, db => $db, user => $u,
                    map { lc $DB_PRIV{$_} => ( $have{'ALL PRIVILEGES'} || $have{$_} ? 'Y' : 'N' ) } @DB_PRIVS );
                $row{grant_priv} = 'N';
                my $keep = _where( \%row, $where ) // return _gap($sql);
                next unless $keep;
                push @r, [ map { $row{ lc $_ } // return _gap($sql) } @c ];
            }
        }
        return ( _render( $o, \@c, \@r ), 1 );
    }
    # SELECT ohne FROM: Konstanten und Funktionen (SELECT 1 AS ok, SELECT NOW(), CONCAT(…))
    if ( $s =~ /\ASELECT (.+)\z/i && $1 !~ /\bFROM\b|\@\@|\(\s*SELECT\b/i ) {
        my ( $h, $r ) = _sel_rows( _sel_items($1), [ {} ], $env ) or return _gap($sql);
        return ( _render( $o, $h, $r ), 1 );
    }
    # Tabellen der Anwendung: nur, was der Fall unter mariadb.tables vorgibt
    if ( $s =~ /\ASELECT (.+?) FROM `?(\w+)`?\.`?(\w+)`?(?: WHERE (.+?))?(?: LIMIT \d+)?\z/i && lc $2 ne 'mysql' && lc $2 ne 'information_schema' && lc $2 ne 'performance_schema' ) {
        my ( $cols, $db, $tb, $where ) = ( $1, $2, $3, $4 );
        my $t = ( $m->{tables} || {} )->{"$db.$tb"};
        if ( !$t ) {
            return _err( 1049, '42000', "Unknown database '$db'" ) unless grep { $_ eq $db } @{ $m->{databases} || [] };
            return _gap($sql);
        }
        my @all = @{ $t->{columns} || [] };
        my @r;
        for my $row ( @{ $t->{rows} || [] } ) {
            my %row = map { lc $all[$_] => $row->[$_] } 0 .. $#all;
            my $keep = _where( \%row, $where ) // return _gap($sql);
            push @r, \%row if $keep;
        }
        my ( $hd, $r ) = _sel_rows( _sel_items( $cols eq '*' ? join( ',', @all ) : $cols ), \@r, $env ) or return _gap($sql);
        return ( _render( $o, $hd, $r ), 1 );
    }
    if ( $s =~ /\ASHOW CREATE USER (.+?)\z/i ) {
        my ( $u, $h ) = _account($1) or return _gap($sql);
        my $a = $m->{users}{"$u\@$h"} or return _err( 1396, 'HY000', "Operation SHOW CREATE USER failed for '$u'\@'$h'" );
        my $ident = ( $a->{auth} // '' ) eq 'unix_socket' ? ' IDENTIFIED VIA unix_socket' : defined $a->{password} ? " IDENTIFIED BY PASSWORD '" . _pwhash( $a->{password} ) . "'" : '';
        return ( _render( $o, ["CREATE USER for $u\@$h"], [ ["CREATE USER `$u`\@`$h`$ident"] ] ), 1 );
    }
    if ( $s =~ /\ASHOW GRANTS(?: FOR (.+?))?\z/i ) {
        my $who = $1;
        my $key;
        if ( defined $who && $who !~ /\ACURRENT_USER/i ) {
            my ( $u, $h ) = _account($who) or return _gap($sql);
            $key = "$u\@$h";
            return _err( 1141, '42000', "There is no such grant defined for user '$u' on host '$h'" ) unless $m->{users}{$key};
        }
        else { $key = $acc }
        my ( $u, $h ) = split /@/, $key, 2;
        my $a = $m->{users}{$key} || {};
        my $g = _grant_map($a);
        my @l;
        my $ident = $a->{auth} && $a->{auth} eq 'unix_socket' ? ' IDENTIFIED VIA unix_socket' : defined $a->{password} ? " IDENTIFIED BY PASSWORD '" . _pwhash( $a->{password} ) . "'" : '';
        my $global = $g->{'*.*'} ? join( ', ', @{ $g->{'*.*'} } ) : 'USAGE';
        push @l, "GRANT $global ON *.* TO `$u`\@`$h`$ident" . ( $u eq 'root' ? ' WITH GRANT OPTION' : '' );
        push @l, 'GRANT ' . join( ', ', @{ $g->{$_} } ) . " ON $_ TO `$u`\@`$h`" for sort grep { $_ ne '*.*' } keys %$g;
        return ( _render( $o, ["Grants for $u\@$h"], [ map { [$_] } @l ] ), 1 );
    }
    if ( $s =~ /\ACREATE USER (IF NOT EXISTS )?(\S+)(?: IDENTIFIED BY (PASSWORD )?(['"])(.*)\4)?\z/i ) {
        my ( $ine, $who, $pw ) = ( $1, $2, $3 ? _pw_from_hash( $m, $5 ) : $5 );
        return _err( 1372, 'HY000', 'Password hash should be a 41-digit hexadecimal number' ) if $3 && !defined $pw;
        return _err( 1227, '42000', 'Access denied; you need (at least one of) the CREATE USER privilege(s) for this operation' ) unless $super;
        my ( $u, $h ) = _account($who) or return _gap($sql);
        if ( $m->{users}{"$u\@$h"} ) { return ( '', 1 ) if $ine; return _err( 1396, 'HY000', "Operation CREATE USER failed for '$u'\@'$h'" ) }
        $m->{users}{"$u\@$h"} = { defined $pw ? ( password => $pw ) : (), grants => [] };
        return ( '', 1 );
    }
    if ( $s =~ /\ADROP USER (IF EXISTS )?(.+)\z/i ) {
        my ( $ie, $list ) = ( $1, $2 );
        return _err( 1227, '42000', 'Access denied; you need (at least one of) the CREATE USER privilege(s) for this operation' ) unless $super;
        for my $who ( split /\s*,\s*/, $list ) {
            my ( $u, $h ) = _account($who) or return _gap($sql);
            next if !$m->{users}{"$u\@$h"} && $ie;
            return _err( 1396, 'HY000', "Operation DROP USER failed for '$u'\@'$h'" ) unless delete $m->{users}{"$u\@$h"};
        }
        return ( '', 1 );
    }
    if ( $s =~ /\A(?:ALTER USER|SET PASSWORD FOR) (\S+) (?:IDENTIFIED BY (PASSWORD )?(['"])(.*)\3|= PASSWORD\((['"])(.*)\5\))\z/i ) {
        my ( $who, $pw ) = ( $1, $2 ? _pw_from_hash( $m, $4 ) : $4 // $6 );
        return _err( 1372, 'HY000', 'Password hash should be a 41-digit hexadecimal number' ) if $2 && !defined $pw;
        my ( $u, $h ) = _account($who) or return _gap($sql);
        return _err( 1396, 'HY000', "Operation ALTER USER failed for '$u'\@'$h'" ) unless $m->{users}{"$u\@$h"};
        $m->{users}{"$u\@$h"}{password} = $pw;
        return ( '', 1 );
    }
    if ( $s =~ /\A(GRANT|REVOKE) (.+?) ON (?:TABLE )?(\S+) (TO|FROM) (\S+)(?: IDENTIFIED BY (PASSWORD )?(['"])(.*)\7)?(?: WITH GRANT OPTION)?\z/i ) {
        my ( $verb, $privs, $obj, $who, $pw ) = ( uc $1, $2, $3, $5, $6 ? _pw_from_hash( $m, $8 ) : $8 );
        return _err( 1227, '42000', 'Access denied; you need (at least one of) the GRANT OPTION privilege(s) for this operation' ) unless $super;
        my ( $u, $h ) = _account($who) or return _gap($sql);
        my $a = $m->{users}{"$u\@$h"};
        if ( !$a ) {
            return _err( 1141, '42000', "There is no such grant defined for user '$u' on host '$h'" ) if $verb eq 'REVOKE';
            return _err( 1133, '28000', "Can't find any matching row in the user table" ) unless defined $pw;
            $a = $m->{users}{"$u\@$h"} = { password => $pw, grants => [] };
        }
        $a->{password} = $pw if defined $pw;
        my $g = _grant_map($a);
        my $k = _norm_obj($obj);
        my @p = _priv_list($privs);
        if ( $verb eq 'GRANT' ) {
            my %have = map { $_ => 1 } @{ $g->{$k} || [] }, @p;
            $g->{$k} = $have{'ALL PRIVILEGES'} ? ['ALL PRIVILEGES'] : [ _priv_list( join ',', keys %have ) ];
        }
        else {
            return _err( 1141, '42000', "There is no such grant defined for user '$u' on host '$h'" ) unless $g->{$k};
            my %drop = map { $_ => 1 } @p;
            $g->{$k} = $drop{'ALL PRIVILEGES'} ? [] : [ grep { !$drop{$_} } @{ $g->{$k} } ];
        }
        _store_grants( $a, $g );
        return ( '', 1 );
    }
    return ( '', 1 ) if $s =~ /\AFLUSH (?:PRIVILEGES|LOGS|TABLES|STATUS|HOSTS)\z/i;
    if ( $s =~ /\AFLUSH BINARY LOGS\z/i ) { _rotate_binlog($dev); return ( '', 1 ) }
    if ( $s =~ /\ASHOW (?:BINARY|MASTER) LOGS\z/i ) {
        return _err( 1381, 'HY000', 'You are not using binary logging' ) unless ( $v->{log_bin} // 'OFF' ) eq 'ON';
        return ( _render( $o, [qw( Log_name File_size )], [ map { [ $_->{name}, _binlog_size( $dev, $_ ) ] } @{ $m->{binlogs} || [] } ] ), 1 );
    }
    if ( $s =~ /\ASHOW (?:MASTER|BINLOG) STATUS\z/i ) {
        my $last = ( $m->{binlogs} || [] )->[-1] or return ( '', 1 );
        return ( _render( $o, [qw( File Position Binlog_Do_DB Binlog_Ignore_DB )], [ [ $last->{name}, $last->{position} // 4211, '', '' ] ] ), 1 );
    }
    if ( $s =~ /\APURGE (?:BINARY|MASTER) LOGS (TO|BEFORE) (['"])(.+)\2\z/i ) {
        my ( $how, $what ) = ( uc $1, $3 );
        return _err( 1227, '42000', 'Access denied; you need (at least one of) the SUPER, BINLOG ADMIN privilege(s) for this operation' ) unless $super;
        my @b = @{ $m->{binlogs} || [] };
        my @drop;
        if ( $how eq 'TO' ) {
            my ($i) = grep { $b[$_]{name} eq $what } 0 .. $#b;
            return _err( 1373, 'HY000', 'Target log not found in binlog index' ) unless defined $i;
            @drop = @b[ 0 .. $i - 1 ];
        }
        else {
            @drop = grep { defined $_->{mtime} && $_->{mtime} lt $what } @b[ 0 .. $#b - 1 ];
        }
        _drop_binlogs( $dev, @drop );
        return ( '', 1 );
    }
    if ( $s =~ /\ASHOW (?:SLAVE|REPLICA) STATUS\z/i ) {
        my $r = $m->{replica} or return ( '', 1 );
        my @c = qw( Slave_IO_State Master_Host Master_User Master_Port Master_Log_File Read_Master_Log_Pos Relay_Log_File Relay_Master_Log_File
            Slave_IO_Running Slave_SQL_Running Last_Errno Last_Error Skip_Counter Exec_Master_Log_Pos Seconds_Behind_Master Last_IO_Errno Last_IO_Error
            Last_SQL_Errno Last_SQL_Error Using_Gtid );
        my $err = $r->{sql} eq 'No' ? ( $r->{last_error} // '' ) : '';
        my %row = (
            Slave_IO_State => $r->{io} eq 'Yes' ? 'Waiting for master to send event' : '', Master_Host => $r->{master_host}, Master_User => $r->{master_user} // 'repl',
            Master_Port => $r->{master_port} // 3306, Master_Log_File => $r->{master_log_file} // 'mariadb-bin.000412', Read_Master_Log_Pos => $r->{read_pos} // 8811204,
            Relay_Log_File => 'mysqld-relay-bin.000077', Relay_Master_Log_File => $r->{master_log_file} // 'mariadb-bin.000412', Slave_IO_Running => $r->{io},
            Slave_SQL_Running => $r->{sql}, Last_Errno => $r->{sql} eq 'No' ? $r->{last_errno} // 0 : 0, Last_Error => $err,
            Skip_Counter => $v->{sql_slave_skip_counter} // 0, Exec_Master_Log_Pos => $r->{exec_pos} // 8810770,
            Seconds_Behind_Master => $r->{sql} eq q{Yes} && $r->{io} eq q{Yes} ? $r->{behind} // 0 : q{NULL}, Last_IO_Errno => $r->{io} eq 'No' ? $r->{last_io_errno} // 2003 : 0,
            Last_IO_Error => $r->{io} eq 'No' ? $r->{last_io_error} // '' : '', Last_SQL_Errno => $r->{sql} eq 'No' ? $r->{last_errno} // 0 : 0,
            Last_SQL_Error => $err, Using_Gtid => 'No',
        );
        return ( _render( $o, \@c, [ [ map { $row{$_} } @c ] ] ), 1 );
    }
    if ( $s =~ /\A(STOP|START) (?:SLAVE|REPLICA)(?: (IO_THREAD|SQL_THREAD))?\z/i ) {
        my ( $verb, $which ) = ( uc $1, uc( $2 // '' ) );
        my $r = $m->{replica} or return _err( 1200, 'HY000', 'Misconfigured slave: MASTER_HOST was not set; Fix in config file or with CHANGE MASTER TO' );
        if ( $verb eq 'STOP' ) {
            $r->{io}  = 'No' if $which ne 'SQL_THREAD';
            $r->{sql} = 'No' if $which ne 'IO_THREAD';
            return ( '', 1 );
        }
        $r->{io} = 'Yes' if $which ne 'SQL_THREAD';
        if ( $which ne 'IO_THREAD' ) {
            my $skip = $v->{sql_slave_skip_counter} // 0;
            if ( $r->{last_errno} && $skip > 0 ) {
                $r->{skipped} = ( $r->{skipped} // 0 ) + $skip;
                $v->{sql_slave_skip_counter} = '0';
                delete @{$r}{qw( last_errno last_error )} if $r->{skipped} >= ( $r->{bad_events} // 1 );
            }
            $r->{sql} = $r->{last_errno} ? 'No' : 'Yes';
            # mit parallelen Threads holt das Replikat auf (behind_parallel)
            $r->{behind} = $r->{behind_parallel} if $r->{sql} eq 'Yes' && defined $r->{behind_parallel} && ( $v->{slave_parallel_threads} // 0 ) >= 2;
        }
        return ( '', 1 );
    }
    if ( $s =~ /\A(?:RESET (?:SLAVE|REPLICA)|CHANGE MASTER TO)/i ) {
        my $r = $m->{replica} or return _gap($sql);
        $r->{reset} = JSON::MaybeXS::true();
        $r->{io} = $r->{sql} = 'No';
        return ( '', 1 );
    }
    if ( $s =~ /\A(?:SELECT VERSION\(\)|SELECT \@\@VERSION)\z/i ) { return ( _render( $o, ['VERSION()'], [ [ $v->{version} ] ] ), 1 ) }
    if ( $s =~ /\AUSE (\S+)\z/i ) { return ( '', 1 ) }
    if ( $s =~ /\ASTATUS\z/i ) { return _gap($sql) }
    return _gap($sql);
}

# WHERE a = 'x' AND b LIKE 'y%' AND id = 5 auf einer Zeile (Spalten klein); undef: nicht nachgebildet
sub _where {
    my ( $row, $where ) = @_;
    return 1 unless defined $where;
    for my $cond ( split /\s+AND\s+/i, $where ) {
        if ( my ( $f, $not, $list ) = $cond =~ /\A\s*`?(\w+)`?\s+(NOT\s+)?IN\s*\((.*)\)\s*\z/i ) {
            my @v = map { s/\A\s*['"]?|['"]?\s*\z//gr } split /,/, $list;
            my $have = $row->{ lc $f } // return undef;
            my $hit = grep { lc $_ eq lc $have } @v;
            return 0 if $not ? $hit : !$hit;
            next;
        }
        if ( my ( $f, $not ) = $cond =~ /\A\s*`?(\w+)`?\s+IS\s+(NOT\s+)?NULL\s*\z/i ) {
            return undef unless exists $row->{ lc $f };
            my $null = !defined $row->{ lc $f } || $row->{ lc $f } eq 'NULL';
            return 0 if $not ? $null : !$null;
            next;
        }
        if ( my ( $f, $op, $n ) = $cond =~ /\A\s*`?(\w+)`?\s*(>=|<=|>|<)\s*(-?\d+(?:\.\d+)?)\s*\z/ ) {
            my $have = $row->{ lc $f } // return undef;
            return undef unless $have =~ /\A-?\d+(?:\.\d+)?\z/;
            my $hit = $op eq '>' ? $have > $n : $op eq '<' ? $have < $n : $op eq '>=' ? $have >= $n : $have <= $n;
            return 0 unless $hit;
            next;
        }
        my ( $f, $op, $val ) = $cond =~ /\A\s*`?(\w+)`?\s*(=|!=|<>|LIKE|NOT LIKE)\s*(?:['"]([^'"]*)['"]|(-?\d+))\s*\z/i or return undef;
        $val //= $4;
        my $have = $row->{ lc $f } // return undef;
        my $hit = $op =~ /LIKE/i ? $have =~ _like("'$val'") : lc $have eq lc $val;
        $hit = !$hit if $op =~ /\A(?:!=|<>|NOT LIKE)\z/i;
        return 0 unless $hit;
    }
    return 1;
}

sub _gap { my ($st) = @_; push @GAPS, "mysql: $st"; return ( '', 0 ) }

sub _binlog_size {
    my ( $dev, $b ) = @_;
    my $dir = _vars($dev)->{datadir} // '/var/lib/mysql/';
    $dir =~ s{/?\z}{/};
    my $e = ( $dev->{files} || {} )->{"$dir$b->{name}"};
    return $b->{size} // 1073741824 unless ref $e eq 'HASH' && defined $e->{size};
    return Langertha::Holmgang::Sim::Linux::_bytes( $e->{size} );
}

sub _drop_binlogs {
    my ( $dev, @drop ) = @_;
    my $m = $dev->{mariadb};
    my %gone = map { $_->{name} => 1 } @drop;
    return unless %gone;
    $m->{binlogs} = [ grep { !$gone{ $_->{name} } } @{ $m->{binlogs} || [] } ];
    my $dir = _vars($dev)->{datadir} // '/var/lib/mysql/';
    $dir =~ s{/?\z}{/};
    delete $dev->{files}{"$dir$_"} for keys %gone;
    my $idx = "$dir" . ( ( $m->{binlogs}[0] // {} )->{name} // 'mariadb-bin.000001' ) =~ s/\.\d+\z/.index/r;
    if ( exists $dev->{files}{$idx} ) {
        my $e = $dev->{files}{$idx};
        my $t = join '', map {"./$_->{name}\n"} @{ $m->{binlogs} };
        if ( ref $e eq 'HASH' ) { $e->{content} = $t } else { $dev->{files}{$idx} = $t }
    }
    _check_replicas($dev);
    return;
}

# Replikate, deren Binlog fehlt, brechen
sub _check_replicas {
    my ($dev) = @_;
    my $m = $dev->{mariadb};
    my %have = map { $_->{name} => 1 } @{ $m->{binlogs} || [] };
    for my $r ( sort keys %{ $m->{replicas} || {} } ) {
        my $need = $m->{replicas}{$r};
        $m->{broken_replicas}{$r} = $need unless $have{$need} || $need eq 'broken';
    }
    return;
}


sub file_removed {
    my ( $dev, $path ) = @_;
    my $m = $dev->{mariadb} or return;
    my $dir = _vars($dev)->{datadir} // '/var/lib/mysql/';
    $dir =~ s{/?\z}{/};
    return unless index( $path, $dir ) == 0;
    my $name = substr( $path, length $dir );
    return unless grep { $_->{name} eq $name } @{ $m->{binlogs} || [] };
    # von Hand geloescht: das Index-File nennt die Datei weiter, der Server merkt es erst spaeter
    $m->{binlogs_missing}{$name} = 1;
    $m->{binlogs} = [ grep { $_->{name} ne $name } @{ $m->{binlogs} } ];
    _check_replicas($dev);
    return;
}

sub _rotate_binlog {
    my ($dev) = @_;
    my $m = $dev->{mariadb};
    my $last = ( $m->{binlogs} || [] )->[-1] or return;
    my ( $base, $n ) = $last->{name} =~ /\A(.+)\.(\d+)\z/ or return;
    push @{ $m->{binlogs} }, { name => sprintf( '%s.%06d', $base, $n + 1 ), size => 365 };
    return;
}

# --- Verbindung ---------------------------------------------------------------------


sub client {
    my ( $dev, $av, $ctx, $stdin, $os_user, $prog ) = @_;
    my @a = @$av;
    my %o;
    my ( $user, $pw, $host, @exec, $db );
    my $pw_prompt;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-u' || $x eq '--user' ) { $user = shift @a }
        elsif ( $x =~ /\A-u(.+)\z/ || $x =~ /\A--user=(.+)\z/ ) { $user = $1 }
        elsif ( $x eq '-p' || $x eq '--password' ) { $pw_prompt = 1 }
        elsif ( $x =~ /\A-p(.+)\z/ || $x =~ /\A--password=(.*)\z/ ) { $pw = $1 }
        elsif ( $x eq '-h' || $x eq '--host' ) { $host = shift @a }
        elsif ( $x =~ /\A-h(.+)\z/ || $x =~ /\A--host=(.+)\z/ ) { $host = $1 }
        elsif ( $x eq '-P' || $x eq '--port' ) { shift @a }
        elsif ( $x eq '--connect-timeout' ) { shift @a }
        elsif ( $x =~ /\A--(?:connect-timeout|port)=\d+\z/ ) { }
        elsif ( $x eq '-D' || $x eq '--database' ) { $db = shift @a }
        elsif ( $x eq '-e' || $x eq '--execute' ) { push @exec, shift(@a) // '' }
        elsif ( $x =~ /\A--execute=(.*)\z/s ) { push @exec, $1 }
        elsif ( $x eq '-N' || $x eq '--skip-column-names' ) { $o{skip_names} = 1 }
        elsif ( $x eq '-t' || $x eq '--table' ) { $o{table} = 1 }
        elsif ( $x eq '-E' || $x eq '--vertical' ) { $o{vertical} = 1 }
        elsif ( $x =~ /\A-[BsrnNA]+\z/ || $x =~ /\A--(?:batch|silent|raw|skip-pager|no-auto-rehash|protocol=\w+|defaults-file=\S+|socket=\S+)\z/ ) {
            $o{skip_names} = 1 if $x =~ /N/ && $x =~ /\A-[A-Za-z]+\z/;
        }
        elsif ( $x =~ /\A-/ ) { push @GAPS, join( ' ', $prog // 'mysql', @$av ); return ( '', 0 ) }
        else { $db //= $x }
    }
    $prog //= 'mysql';
    my $m = $dev->{mariadb};
    my $sock = "Can't connect to local server through socket '/run/mysqld/mysqld.sock' (2)";
    return ( "ERROR 2002 (HY000): $sock", 0 ) unless $m && _active($dev);
    my $v = _vars($dev);
    my $from = 'localhost';
    if ( defined $host && $host ne 'localhost' ) {
        my @b = split /\s*,\s*/, $v->{bind_address} // '127.0.0.1';
        my $ok = grep { $_ eq '0.0.0.0' || $_ eq '*' || $_ eq '::' || $_ eq $host } @b;
        return ( "ERROR 2002 (HY000): Can't connect to server on '$host' (115)", 0 ) unless $ok;
        $from = $host eq '127.0.0.1' ? 'localhost' : $host;
    }
    if ( $pw_prompt && !defined $pw ) {
        # ohne Terminal liest -p von stdin — hier eine Luecke (interaktiv)
        push @GAPS, "$prog -p (Passwortabfrage)";
        return ( 'Enter password: ', 0 );
    }
    $user //= $os_user // 'root';
    my $acc;
    if ( $user eq 'root' && $from eq 'localhost' && ( $os_user // 'root' ) eq 'root' && !defined $pw ) { $acc = 'root@localhost' }
    else {
        $acc = _find_account( $m, $user, $from );
        my $a = $acc ? $m->{users}{$acc} : undef;
        my $good = $a && ( ( $a->{auth} // '' ) eq 'unix_socket' ? ( $os_user // 'root' ) eq $user && !defined $pw
            : defined $a->{password} ? ( defined $pw && $pw eq $a->{password} ) : !defined $pw );
        return ( "ERROR 1045 (28000): Access denied for user '$user'\@'$from' (using password: " . ( defined $pw ? 'YES' : 'NO' ) . ')', 0 ) unless $good;
    }
    my $tc = ( $m->{status} || {} )->{Threads_connected} // 1;
    my $super = _has_priv( $m, $acc, 'SUPER' ) || _has_priv( $m, $acc, 'ALL PRIVILEGES' );
    return ( 'ERROR 1040 (HY000): Too many connections', 0 ) if $tc >= ( my $mc = "" . ( $v->{max_connections} // 151 ) ) + ( $super ? 1 : 0 );
    my $sql = @exec ? join( ';', @exec ) : $stdin // '';
    if ( $sql !~ /\S/ ) { push @GAPS, "$prog (interaktiv)"; return ( '', 0 ) }
    my @out;
    for my $st ( _split_sql($sql) ) {
        my ( $t, $k ) = _statement( $dev, $st->[0], { %o, vertical => $o{vertical} || $st->[1] }, $acc );
        push @out, $t if defined $t && length $t;
        return ( join( "\n", @out ), 0 ) unless $k;
    }
    return ( join( "\n", @out ), 1 );
}


sub mysqladmin {
    my ( $dev, $av, $ctx, $os_user ) = @_;
    my ( @opts, @cmd );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-[uhP]\z/ || $x =~ /\A--(?:user|host|port)\z/ ) { push @opts, $x, shift(@a) // '' }
        elsif ( $x eq '-S' || $x eq '--socket' ) { shift @a }    # Socket: immer der des Servers
        elsif ( $x =~ /\A-S./ || $x =~ /\A--socket=/ ) { }
        elsif ( $x =~ /\A-/ ) { push @opts, $x }
        else  { push @cmd, $x }
    }
    my ($host) = map { /\A(?:-h|--host=)(.+)\z/ ? $1 : () } @opts;
    for my $i ( 0 .. $#opts - 1 ) { $host = $opts[ $i + 1 ] if $opts[$i] =~ /\A(?:-h|--host)\z/ }
    $host //= 'localhost';
    my $map = { variables => 'SHOW GLOBAL VARIABLES', status => undef, processlist => 'SHOW PROCESSLIST', 'flush-privileges' => 'FLUSH PRIVILEGES',
        'flush-logs' => 'FLUSH LOGS', ping => undef, version => 'SELECT VERSION()' };
    my $c = $cmd[0] // '';
    return ( "mysqladmin: connect to server at '$host' failed\nerror: 'Can't connect to local server through socket '/run/mysqld/mysqld.sock' (2)'", 0 )
        unless $dev->{mariadb} && _active($dev);
    if ( !exists $map->{$c} ) { push @GAPS, join( ' ', 'mysqladmin', @$av ); return ( '', 0 ) }
    # Verbindung und Anmeldung wie beim Client (bind-address, Konten, max_connections)
    my ( $e, $ok ) = client( $dev, [ @opts, '-e', 'SELECT 1' ], $ctx, undef, $os_user, 'mysqladmin' );
    if ( !$ok ) {
        return ( $e, 0 ) unless ( $e // '' ) =~ /\AERROR \d+ \(\w+\): (.*)\z/s;
        my $msg = $1;
        # ping: Der Server laeuft, auch wenn er die Anmeldung verweigert (Exit 0)
        return ( "mysqladmin: connect to server at '$host' failed\nerror: '$msg'", $c eq 'ping' && $msg =~ /\AAccess denied/ ? 1 : 0 );
    }
    return ( 'mysqld is alive', 1 ) if $c eq 'ping';
    if ( $c eq 'status' ) {
        my $st = $dev->{mariadb}{status} || {};
        return ( 'Uptime: 1728000  Threads: ' . ( $st->{Threads_connected} // 1 ) . '  Questions: 88120441  Slow queries: 12  Opens: 2210  Open tables: 2000  Queries per second avg: 51.000', 1 );
    }
    return client( $dev, [ @opts, '-t', '-e', $map->{$c} ], $ctx, undef, $os_user, 'mysqladmin' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::MariaDB - MariaDB on a simulated Linux server — mysql/mariadb client, variables, users, binlogs, replica

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator: mysql/mariadb, effect of starting/restarting the service
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::MariaDB::client( $dev, \@argv, $ctx, $stdin, $os_user );
  Langertha::Holmgang::Sim::Linux::MariaDB::service_event( $dev, 'restart' );

=head1 DESCRIPTION

A MariaDB server (Debian 12, MariaDB 10.11) on a device of type C<linux>
(cai-platform F<docs/entwurf-evals.md> §3.3.1). The state lives under C<mariadb> of
the device, the option files under C<files>, the service under C<services> (name in
C<mariadb.service>):

  mariadb:
    service:   mariadb
    conf:      [ /etc/mysql/mariadb.conf.d/50-server.cnf, /etc/mysql/mariadb.conf.d/90-tuning.cnf ]
    variables: { max_connections: "151", … }      # running values; without: from the files
    status:    { Threads_connected: 152, Max_used_connections: 152, … }
    users:     { "root@localhost": { auth: unix_socket }, "app@10.20.0.%": { password: secret, grants: [ "ALL PRIVILEGES ON `shop`.*" ] } }
    databases: [ shop ]
    processlist: [ { id: 1001, user: app, host: "10.20.0.21:41234", db: shop, command: Sleep, time: 12, count: 150 } ]
    binlogs:   [ { name: mariadb-bin.000410, size: 1073741824 }, … ]   # files under datadir with size
    replicas:  { db2: mariadb-bin.000412 }        # primary: binlog a replica is reading right now
    replica:   { master_host: 10.20.0.31, io: "Yes", sql: "No", last_errno: 1062, last_error: "…", skip: 1,
                 behind: 14400, behind_parallel: 30 }   # lag; with slave_parallel_threads >= 2 after START
    tables:    { shop.orders: { columns: [ id, customer ], rows: [ [ 77120, K-1 ] ] } }   # read only

B<Client> C<mysql>/C<mariadb> (C<-u>, C<-p…>/C<--password=…>, C<-h>, C<-P>,
C<-D>, C<-e>/C<--execute>, C<-N>, C<-B>, C<-s>, C<-t>, C<-E>, SQL on stdin;
C<root> via C<unix_socket> when the caller is root), C<mysqladmin
variables|status|processlist|ping|flush-privileges>. B<SQL>: C<SHOW [GLOBAL]
VARIABLES|STATUS [LIKE …]>, C<SELECT @@[global.]var, …>, C<SET [GLOBAL]
var = value> (dynamic ones only; otherwise error 1238), C<SHOW [FULL] PROCESSLIST>,
C<KILL id>, C<SHOW DATABASES>, C<SELECT … FROM mysql.user|mysql.db [WHERE …]>,
C<SELECT 1>, C<SELECT … FROM db.table [WHERE …]> (only C<tables>), C<SELECT … FROM
information_schema.processlist [WHERE …] [ORDER BY …] [LIMIT n]> (WHERE with C<=>, C<LIKE>,
C<IN (…)>, numeric comparisons, C<IS [NOT] NULL>, joined with C<AND>), C<SHOW CREATE USER>, C<SHOW
GRANTS [FOR …]>, C<CREATE USER>, C<DROP USER>, C<ALTER USER … IDENTIFIED BY>,
C<GRANT>/C<REVOKE> (privileges on C<*.*>, C<db.*>, C<db.table>), C<FLUSH
PRIVILEGES|LOGS|BINARY LOGS>, C<SHOW BINARY|MASTER LOGS>, C<SHOW MASTER STATUS>,
C<PURGE BINARY|MASTER LOGS TO|BEFORE …>, C<SHOW SLAVE|REPLICA STATUS>,
C<STOP|START SLAVE|REPLICA [IO_THREAD|SQL_THREAD]>, C<SET GLOBAL sql_slave_skip_counter = N>,
C<SET GLOBAL slave_parallel_threads|mode> (only with the SQL thread stopped, otherwise 1198); terminated by
C<;> or C<\G> (vertical). Anything else is a B<gap in the simulation>.

B<Effect>: A start or restart reads the option files (sections
C<[mysqld]>, C<[mariadb]>, C<[server]>, C<[mariadb-10.11]>); an unknown
variable or a wrong value prevents the start (C<conf_error>). A
restart ends all connections. When C<Threads_connected> is as high as
C<max_connections>, only an account with C<SUPER> (root) still gets a
connection (error 1040). Deleting a binlog a replica is still reading
(C<PURGE> beyond it, or C<rm>) breaks the replica (C<replicas>).

Pure functions on the state, neutral.

=head2 parse_conf

  my ( $values, $file, $line, $error ) = parse_conf( $dev );

Reads the server's option files (C<mariadb.conf>) over the defaults: the
variables (as C<SHOW VARIABLES> shows them) or C<undef> with file, line and
error.

=head2 conf_error

  my $lines = conf_error( $dev );   # undef or [ journal lines ]

=head2 service_event

  service_event( $dev, 'start'|'restart'|'stop' );

=head2 file_removed

  file_removed( $dev, $path );   # rm in the Linux simulator: binlog gone?

=head2 client

  my ( $out, $ok ) = client( $dev, \@argv, $ctx, $stdin, $os_user, $prog );

=head2 mysqladmin

  my ( $out, $ok ) = mysqladmin( $dev, \@argv, $ctx, $os_user );

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
