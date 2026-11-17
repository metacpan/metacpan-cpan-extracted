package Langertha::Holmgang::Sim::Linux;
# ABSTRACT: The simulator of device type linux — a Debian shell with ip, nft, wg, sysctl, systemctl, nmcli, files

use Moose;
use namespace::autoclean;
use utf8;

use Langertha::Holmgang::Shell ();
use Langertha::Holmgang::Shell::Filter ();
use Langertha::Holmgang::Sim::Linux::Nft ();
use Langertha::Holmgang::Sim::Linux::Calendar ();
use Encode ();
use JSON::MaybeXS ();
use Module::Runtime ();

with 'Langertha::Holmgang::Role::Simulator';

our $VERSION = '0.001';


# --- IPv4 ------------------------------------------------------------------------

sub _ip2n {
    my ($ip) = @_;
    return undef unless defined $ip && $ip =~ /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/;
    return undef if grep { $_ > 255 } $1, $2, $3, $4;
    return ( ( $1 * 256 + $2 ) * 256 + $3 ) * 256 + $4;
}

sub _n2ip { my ($n) = @_; return join '.', map { ( $n >> ( 8 * $_ ) ) & 255 } 3, 2, 1, 0 }

# "10.1.0.0/24" | "default" | "10.1.0.5" -> ( netz, laenge ) oder ()
sub _prefix {
    my ($p) = @_;
    return ( 0, 0 ) if $p eq 'default' || $p eq '0.0.0.0/0';
    my ( $ip, $len ) = $p =~ m{\A([\d.]+)(?:/(\d{1,2}))?\z} or return ();
    $len //= 32;
    my $n = _ip2n($ip);
    return () unless defined $n && $len <= 32;
    my $mask = $len ? ( 0xFFFFFFFF << ( 32 - $len ) ) & 0xFFFFFFFF : 0;
    return ( $n & $mask, $len, $n );
}

sub _in {
    my ( $ip, $pfx ) = @_;
    my $n = _ip2n($ip) // return 0;
    my ( $net, $len ) = _prefix($pfx) or return 0;
    my $mask = $len ? ( 0xFFFFFFFF << ( 32 - $len ) ) & 0xFFFFFFFF : 0;
    return ( $n & $mask ) == $net ? 1 : 0;
}

sub _canon_dst {
    my ($p) = @_;
    return 'default' if $p eq 'default' || $p eq '0.0.0.0/0';
    return $p if $p =~ /:/;    # IPv6: nur speichern
    my ( $net, $len ) = _prefix($p) or return undef;
    return $len == 32 ? _n2ip($net) : _n2ip($net) . "/$len";
}

# --- Ablauf ------------------------------------------------------------------------

our @GAPS;

# Aufrufkontext (fuer Dienste, die andere Geraete beruehren) und Login-Benutzer von su
our ( $CTX, $LOGIN_USER );

# Aktuelles Verzeichnis (cd, je Aufruf frisch: eine SSH-Sitzung beginnt in /root) und
# Umgebung eines einzelnen Befehls (NAME=wert befehl …)
our ( $CWD_DIR, $SHENV );
our %EXT_NEED;    # Befehl eines Zusatz-Simulators (Code-Referenz) => Pakete im Zustand, ohne die er fehlt (which)

our $AS_USER;
our $IN_TIMEOUT;    # unter timeout: eine haengende Verbindung endet still mit Status 124
our $START_RC;   # $? zu Beginn einer Befehlszeile (Kette der Welt mit Beobachtungen)
our $ERRNULL;    # innerhalb eines Glieds: { programm => 1 } mit 2>/dev/null (_errnull_progs)
our $SH;      # Shell des laufenden Aufrufs: { vars, rc, args, arg0, ctl, errexit, defaults }
our $EXIT;    # Status der zuletzt beendeten (Sub-)Shell, fuer $? nach bash -c / Skript

# Gibt es im Zustand Webserver, Container, Anwendungen oder Proben
# (Langertha::Holmgang::Sim::Linux::Http)? Nur dann laufen dessen Haken.
sub _web_world {
    my ($ctx) = @_;
    my $s = $ctx && $ctx->{state};
    return 0 unless ref $s eq 'HASH';
    return 0 unless grep { ref $_ eq 'HASH' && ( $_->{nginx} || $_->{docker} || $_->{http} || $_->{probes} || $_->{pki} ) } values %$s;
    _part('Http');
    return 1;
}

# Werkzeuge der Server-Suiten: nur auf Geraeten mit passendem Zustand
# installiert (sonst bleibt es beim Verhalten ohne sie).
sub _web_cmd {
    my ( $dev, $cmd ) = @_;
    return undef unless ref $dev eq 'HASH' && defined $cmd;
    my $web = $dev->{nginx} || $dev->{docker} || $dev->{http} || $dev->{probes} || $dev->{pki};
    if ( $cmd eq 'curl' && $web ) {
        _part('Http');
        return \&Langertha::Holmgang::Sim::Linux::Http::curl;
    }
    if ( $cmd eq 'docker' && $dev->{docker} ) {
        _part('Docker');
        return \&Langertha::Holmgang::Sim::Linux::Docker::docker;
    }
    if ( $cmd eq 'nginx' && $dev->{nginx} ) {
        _part('Nginx');
        return \&Langertha::Holmgang::Sim::Linux::Nginx::nginx;
    }
    if ( ( $cmd eq 'openssl' || $cmd eq 'update-ca-certificates' ) && ( $dev->{pki} || $dev->{nginx} ) ) {
        _part('Pki');
        return $cmd eq 'openssl' ? \&Langertha::Holmgang::Sim::Linux::Pki::openssl : \&Langertha::Holmgang::Sim::Linux::Pki::update_ca_certificates;
    }
    return undef;
}

# Start, Neustart, reload eines Dienstes mit eigener Simulation (nginx):
# Fehlertext oder undef.
sub _svc_hook {
    my ( $dev, $n, $verb ) = @_;
    return undef unless $n eq 'nginx' && $dev->{nginx};
    _part('Nginx');
    return Langertha::Holmgang::Sim::Linux::Nginx::service( $dev, $verb, $CTX );
}


sub cwd_path { return _absp( $_[0] ) }


sub shell_env {
    return ( ( map { $_ => $SH->{vars}{$_} } grep { defined $SH->{vars}{$_} } keys %{ ( $SH || {} )->{exported} || {} } ), %{ $SHENV || {} } );
}

sub _new_shell { my (%o) = @_; return { vars => {}, rc => 0, args => [], %o } }

# Skript bzw. bash -c in einer neuen Shell; ihr Exit-Status wird $? des Aufrufers
sub _run_shell {
    my ( $dev, $text, $ctx, %o ) = @_;
    my @r = __PACKAGE__->_run_inner( $dev, $text, $ctx, _new_shell(%o) );
    $SH->{code} = $EXIT if $SH && !$r[1] && $EXIT;
    return @r;
}

# --- Plugin contract ---------------------------------------------------------------

# parts this call needed and could not load (see _part); localised per call
our @MISSING;

sub device_type { 'linux' }


sub run_command {
  my ( $self, $dev, $line, $ctx ) = @_;
  local $EXIT;
  my @r = $self->_guarded( sub { $self->run( $dev, $line, $ctx ) } );
  if ( !$r[1] && $EXIT && $EXIT != 1 ) { $#r = 2 if @r < 3; $r[3] = $EXIT }
  return @r;
}


sub write_file {
  my ( $self, $dev, $path, $content, $ctx ) = @_;
  return $self->_guarded( sub { $self->write( $dev, $path, $content, $ctx ) } );
}


sub packet_verdict {
  my ( $self, $dev, $pkt, $boot ) = @_;
  local @MISSING;
  return Langertha::Holmgang::Sim::Linux::Nft::verdict( $dev, $pkt ) unless $boot;
  return Langertha::Holmgang::Sim::Linux::Nft::boot_verdict( $dev, $pkt, $boot =~ m{\A/} ? $boot : undef );
}


sub login_check {
  my ( $self, $dev, $attempt, $host ) = @_;
  local @MISSING;
  return _part('SshAccess')->can('check')->( $dev, $attempt, $host );
}


sub _guarded {
  my ( $self, $code ) = @_;
  local @MISSING;
  my @r;
  my $ok = eval { @r = $code->(); 1 };
  if ( @MISSING ) {
    my %seen;
    return ( '', 0, join( '; ', map { $_.' is not installed' } grep { !$seen{$_}++ } @MISSING ) );
  }
  die $@ unless $ok;
  return @r;
}

# load a module the first time it is needed; a module that is not installed is noted in
# @MISSING and ends the call (_guarded), a module that does not compile dies as it is
sub _need {
  my ( $class ) = @_;
  my $file = Module::Runtime::module_notional_filename($class);
  return $class if $INC{$file};
  return $class if eval { Module::Runtime::require_module($class); 1 };
  my $err = $@;
  die $err unless $err =~ /\ACan't locate \Q$file\E in \@INC/;
  push @MISSING, $class;
  die $class.' is not installed'."\n";
}

sub _part { return _need( __PACKAGE__.'::'.$_[0] ) }

# expectations and templates belong to the World (k2); only a service whose state needs
# them loads them
sub _condition {
  my ( $data, $c ) = @_;
  return _need('Langertha::Holmgang::Expectation')->can('condition')->( $data, $c );
}

sub _render {
  my ( $tmpl, $state ) = @_;
  return 'ok' unless defined $tmpl;
  return $tmpl unless $tmpl =~ /<:|^\s*:/m;
  return _need('Langertha::Holmgang::Template')->can('render')->( $tmpl, $state, {} );
}

my $CLONE_JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );


sub clone_state { my ( $d ) = @_; return $CLONE_JSON->decode( $CLONE_JSON->encode($d) ) }


sub run {
    my ( $class, $dev, $line, $ctx ) = @_;
    _ssh_access()->can('remember')->($dev) if ref $dev->{files} eq 'HASH' && exists $dev->{files}{'/etc/ssh/sshd_config'};
    if ( my $cut = _locked_out( $dev, $ctx ) ) { return ( $cut, 0 ) }
    if ( $dev->{ssh_login} ) { my $no = _sshd_sim()->can('login_denied')->( $dev, $ctx->{host} ); return ( $no, 0 ) if defined $no }
    local @GAPS;
    local $CTX = $ctx;
    local $CWD_DIR;
    local $Langertha::Holmgang::Sim::Linux::Calendar::LOCAL = ref $dev eq 'HASH' && $dev->{timezone} ? $dev->{timezone} : 'Europe/Berlin';
    # $? aus dem vorigen Glied einer Kette, die die Welt Glied fuer Glied ausfuehrt (_rc)
    local $START_RC = ref $dev eq 'HASH' ? delete $dev->{_rc} : undef;
    my $web = _web_world($ctx);
    Langertha::Holmgang::Sim::Linux::Http::before( $ctx->{state} ) if $web;
    my @r = $class->_run_inner( $dev, $line, $ctx );
    Langertha::Holmgang::Sim::Linux::Http::after( $ctx->{state} ) if $web;
    return @r;
}

# trap [--] BEFEHLE SIGNAL… | trap - SIGNAL… | trap -p | trap -l: gemerkt je Shell; EXIT
# (bzw. 0) laeuft am Ende der Shell (_run_inner), Signale kommen in der Simulation nicht vor
sub _trap_cmd {
    my @a = @_;
    my %name = map { $_ => $_ } qw( EXIT HUP INT QUIT TERM ERR DEBUG RETURN USR1 USR2 PIPE ALRM CHLD );
    my $sig = sub { my $s = uc shift; $s =~ s/\ASIG//; return $s eq '0' ? 'EXIT' : $s =~ /\A\d+\z/ ? { 1 => 'HUP', 2 => 'INT', 3 => 'QUIT', 15 => 'TERM' }->{$s} : $name{$s} };
    if ( !@a || $a[0] eq '-p' ) {
        my $t = $SH->{traps} || {};
        return ( join( "\n", map { "trap -- '" . ( $t->{$_} =~ s/'/'\\''/gr ) . "' " . ( $_ eq 'EXIT' ? 'EXIT' : "SIG$_" ) } sort { ( $a eq 'EXIT' ) <=> ( $b eq 'EXIT' ) || $a cmp $b } keys %$t ), 1 );
    }
    return ( ' 1) SIGHUP	 2) SIGINT	 3) SIGQUIT	 9) SIGKILL	15) SIGTERM', 1 ) if $a[0] eq '-l';
    shift @a if $a[0] eq '--';
    my $act = shift @a;
    return ( '', 1 ) unless @a;    # trap ARG ohne Signal: nichts zu tun (selten)
    for my $s (@a) {
        my $n = $sig->($s) // return ( "bash: trap: $s: invalid signal specification", 0 );
        if ( $act eq '-' ) { delete $SH->{traps}{$n} }
        else               { $SH->{traps}{$n} = $act }
    }
    return ( '', 1 );
}

# Zugang ueber die eigene Firewall (nft_login: Weg der SSH-Verbindung des
# Modells): jeder Aufruf ist eine neue Verbindung. Verwirft der Regelsatz sie,
# ist das Geraet nicht mehr erreichbar — fuer den Rest des Falls (locked_out).
sub _locked_out {
    my ( $dev, $ctx ) = @_;
    my $l = $dev->{nft_login};
    return undef unless ref $l eq 'HASH';
    my $host = ( $ctx || {} )->{host} // 'host';
    my $msg = "ssh: connect to host $host port " . ( $l->{dport} // 22 ) . ': Connection timed out';
    return $msg if $dev->{locked_out};
    my ($v) = Langertha::Holmgang::Sim::Linux::Nft::verdict( $dev, { hook => 'input', proto => 'tcp', dport => 22, ct => 'new', %$l } );
    if ( !defined $v || $v ne 'drop' ) {
        # die Antworten der Sitzung muessen auch hinaus (Hook output)
        my %r = ( hook => 'output', proto => 'tcp', sport => $l->{dport} // 22, dport => 50022, ct => 'established',
            saddr => $l->{daddr}, daddr => $l->{saddr}, ( defined $l->{iif} ? ( oif => $l->{iif} ) : () ) );
        ($v) = Langertha::Holmgang::Sim::Linux::Nft::verdict( $dev, \%r );
    }
    return undef unless defined $v && $v eq 'drop';
    $dev->{locked_out} = JSON::MaybeXS::true();
    return $msg;
}

# Eine Befehlszeile bzw. ein Skript in einer Shell ($sh: geteilt, sonst eine neue)
sub _run_inner {
    my ( $class, $dev, $line, $ctx, $sh ) = @_;
    my $outer = scalar @GAPS;
    local $SH = $sh // _new_shell( defined $START_RC ? ( rc => $START_RC ) : () );
    $START_RC = undef;
    my $owner = !$SH->{_started};    # die Shell beginnt hier (nicht source, nicht Kopie fuer $( ) bzw. ( ))
    $SH->{_started} = 1;
    $EXIT = 2;
    my @items = eval { Langertha::Holmgang::Shell::split_items($line) };
    if ( my $e = $@ ) { $e =~ s/\s+\z//; return ( $e, 0 ) }
    my $nodes = Langertha::Holmgang::Shell::parse( \@items );
    return ( $nodes, 0 ) unless ref $nodes;
    my ( $out, $ok ) = $class->_exec_nodes( $dev, $nodes, $ctx );
    if ( ( $SH->{ctl} // [''] )->[0] eq 'exit' ) { $ok = !$SH->{rc} } elsif ( !$sh ) { delete $SH->{ctl} }
    # trap … EXIT: am Ende der Shell, auch nach exit und set -e; der Status bleibt
    if ( $owner && defined( my $h = delete( ( $SH->{traps} || {} )->{EXIT} ) ) ) {
        my ( $rc, $ctl, $ee ) = ( $SH->{rc}, delete $SH->{ctl}, $SH->{errexit} );
        $SH->{errexit} = 0;
        my @hi = eval { Langertha::Holmgang::Shell::split_items($h) };
        my $hn = @hi ? Langertha::Holmgang::Shell::parse( \@hi ) : undef;
        if ( ref $hn ) {
            my ($ho) = $class->_exec_nodes( $dev, $hn, $ctx );
            push @$out, @$ho;
        }
        if ( ( $SH->{ctl} // [''] )->[0] eq 'exit' ) { $ok = !$SH->{rc} }    # exit im Handler setzt den Status
        else { ( $SH->{rc}, $SH->{ctl} ) = ( $rc, $ctl ); delete $SH->{ctl} unless defined $ctl }
        $SH->{errexit} = $ee;
    }
    $EXIT = $ok ? 0 : $SH->{rc} || 1;
    my @new = @GAPS[ $outer .. $#GAPS ];
    return ( join( "\n", @$out ), $ok ? 1 : 0, @new ? join( '; ', @new ) : undef );
}

# Glieder ausfuehren (&&, ||, ;), mit $?, set -e, break/continue/exit
sub _exec_nodes {
    my ( $class, $dev, $nodes, $ctx ) = @_;
    my ( @out, $ok ) = ();
    $ok = 1;
    for my $i ( 0 .. $#$nodes ) {
        last if $SH->{ctl};
        my $nd = $nodes->[$i];
        my $op = $nd->{op} // ';';
        next if $op eq '&&' && !$ok || $op eq '||' && $ok;
        delete $SH->{code};
        my ( $o, $k ) = $class->_exec_node( $dev, $nd, $ctx );
        push @out, $o if defined $o && length $o;
        $ok = $k ? 1 : 0;
        $SH->{rc} = $ok ? 0 : $SH->{code} // 1 unless ( $SH->{ctl} // [''] )->[0] eq 'exit';
        if ( !$ok && $SH->{errexit} && !$SH->{in_cond} && $op eq ';' && ( ( $nodes->[ $i + 1 ] // {} )->{op} // ';' ) eq ';' ) {
            $SH->{ctl} = ['exit'];
        }
    }
    return ( \@out, $ok );
}

# Befehlsersetzung $( ) in einer Kopie der Shell (Subshell)
sub _cmdsub {
    my ( $class, $dev, $ctx ) = @_;
    return sub {
        my ($text) = @_;
        my $sub = { %$SH, vars => { %{ $SH->{vars} } }, ctl => undef };
        my ($o) = $class->_run_inner( $dev, $text, $ctx, $sub );
        return $o // '';
    };
}

sub _sh_expand {
    my ( $class, $dev, $raw, $ctx ) = @_;
    $SH->{defaults} = { HOME => '/root', USER => $AS_USER // 'root', LOGNAME => $AS_USER // 'root', SHELL => '/bin/bash',
        PWD => $CWD_DIR // '/root', HOSTNAME => $dev->{hostname} // $ctx->{host} // 'localhost', LANG => 'C.UTF-8',
        PATH => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', IFS => " \t\n" };
    return Langertha::Holmgang::Shell::expand( $raw, $SH, $class->_cmdsub( $dev, $ctx ) );
}

# Ein Glied: Ausdruck expandieren, in Woerter zerlegen, ungequotete Muster globben (relativ
# bleibt relativ wie in bash; ohne Treffer bleibt das Wort). $noglob: case-Muster, [[ ]].
sub _words_of {
    my ( $class, $dev, $raw, $ctx, $noglob ) = @_;
    my $x = $class->_sh_expand( $dev, $raw, $ctx );
    my @g;
    my @w = Langertha::Holmgang::Shell::shell_words( $x, \@g );
    return \@w if $noglob;
    my @out;
    for my $i ( 0 .. $#w ) {
        my $w = $w[$i];
        if ( ref $w || !$g[$i] || $w =~ /\A-/ || $w =~ /\A[A-Za-z_]\w*=/ ) { push @out, $w; next }
        my $abs = _absp($w);
        my @hit = _glob( $dev, $abs );
        if ( @hit == 1 && $hit[0] eq $abs ) { push @out, $w; next }
        my $cut = length($abs) - length( $w =~ s{\A\./}{}r );
        push @out, $w =~ m{\A/} ? @hit : map { ( $w =~ m{\A\./} ? './' : '' ) . substr( $_, $cut ) } @hit;
    }
    return \@out;
}

sub _exec_node {
    my ( $class, $dev, $nd, $ctx ) = @_;
    my $t = $nd->{type};
    my @r = eval {
        return $class->_exec_cmd( $dev, $nd, $ctx ) if $t eq 'cmd';
        return $class->_exec_if( $dev, $nd, $ctx ) if $t eq 'if';
        return $class->_exec_for( $dev, $nd, $ctx ) if $t eq 'for';
        return $class->_exec_while( $dev, $nd, $ctx ) if $t eq 'while';
        return $class->_exec_case( $dev, $nd, $ctx ) if $t eq 'case';
        if ( $t eq 'group' && $nd->{subshell} ) {    # ( liste ): Variablen, cd, exit bleiben drinnen
            my ( $o, $k );
            {
                local $CWD_DIR = $CWD_DIR;
                local $SH = { %$SH, vars => { %{ $SH->{vars} } }, ctl => undef };
                ( $o, $k ) = $class->_exec_nodes( $dev, $nd->{body}, $ctx );
                $k = !$SH->{rc} if ( $SH->{ctl} // [''] )->[0] eq 'exit';
            }
            my ( $po, $pk ) = $class->_post( $dev, $nd->{post}, $ctx, $o, $k );
            return ( join( "\n", @$po ), $pk );
        }
        if ( $t eq 'group' ) {
            my ( $o, $k ) = $class->_exec_nodes( $dev, $nd->{body}, $ctx );
            my ( $po, $pk ) = $class->_post( $dev, $nd->{post}, $ctx, $o, $k );
            return ( join( "\n", @$po ), $pk );
        }
        if ( $t eq 'func' ) { $SH->{funcs}{ $nd->{name} } = $nd->{body}; return ( '', 1 ) }
        if ( $t eq 'break' || $t eq 'continue' ) { $SH->{ctl} = [ $t, $nd->{n} ] if $SH->{loop}; return ( '', 1 ) }
        push @GAPS, $nd->{raw};    # Funktionen, { }, ( ), for (( )): nicht nachgebildet
        return ( '', 0 );
    };
    if ( my $e = $@ ) {
        if ( $e =~ /\Agap: / ) { push @GAPS, $nd->{raw} // $t; return ( '', 0 ) }
        $e =~ s/\s+\z//;
        return ( $e, 0 );
    }
    return @r;
}

# Eingabe eines Glieds aus Heredoc bzw. Here-String
sub _doc_input {
    my ( $class, $dev, $nd, $ctx ) = @_;
    if ( defined $nd->{heredoc} ) {
        return $nd->{heredoc} unless $nd->{expand_doc};
        ( my $b = $nd->{heredoc} ) =~ s/(?<!\\)"/\\"/g;
        my @w = Langertha::Holmgang::Shell::shell_words( $class->_sh_expand( $dev, qq{"$b"}, $ctx ) );
        return $w[0] // '';
    }
    if ( defined $nd->{herestring} ) {
        my $w = $class->_words_of( $dev, $nd->{herestring}, $ctx );
        return join( ' ', grep { !ref } @$w ) . "\n";
    }
    return undef;
}

sub _exec_cmd {
    my ( $class, $dev, $nd, $ctx ) = @_;
    my $raw = $nd->{raw};
    # ! befehl: der Status umgekehrt
    if ( $raw =~ /\A!\s+(\S.*)\z/s ) {
        my ( $o, $k ) = $class->_exec_cmd( $dev, { %$nd, raw => $1 }, $ctx );
        $SH->{code} = $k ? 1 : 0;
        return ( $o, $k ? 0 : 1 );
    }
    if ( $raw =~ /\A\[\[\s(.*)\s\]\]\s*\z/s ) {    # [[ … ]]: eigene Grammatik (&&, ||, <, > ohne Umleitung)
        my $w = $class->_words_of( $dev, $1, $ctx, 1 );
        my @a = map { ref $_ ? $_->{op} : $_ } @$w;
        my ( $st, $err ) = Langertha::Holmgang::Shell::test_expr( \@a, sub { _fileinfo( $dev, $_[0] ) }, 1 );
        $SH->{code} = $st;
        return ( $err // '', $st == 0 ? 1 : 0 );
    }
    my $w = $class->_words_of( $dev, $raw, $ctx );
    return ( '', 1 ) unless @$w;
    # nur Zuweisungen: Variablen der Shell
    if ( !grep { ref $_ || !/\A[A-Za-z_]\w*\+?=/s } @$w ) {
        for (@$w) { my ( $k, $plus, $v ) = /\A([A-Za-z_]\w*)(\+?)=(.*)\z/s; $SH->{vars}{$k} = $plus ? ( $SH->{vars}{$k} // '' ) . $v : $v }
        return ( '', 1 );
    }
    my @a = @$w;
    my $cmd = $a[0];
    if ( !ref $cmd && $cmd eq 'exec' && @a > 1 ) {
        my @r = @a[ 1 .. $#a ];
        my $only_fd = 1;
        my @files;
        while (@r) {
            my $x = shift @r;
            if ( !ref $x && $x =~ /\A\d+\z/ && ref $r[0] && $r[0]{op} =~ /\A(?:>|>>|<)\z/ && defined $r[1] && !ref $r[1] ) {
                my $op = ( shift @r )->{op};
                push @files, [ $op, shift @r ];
                next;
            }
            if ( !ref $x && $x =~ /\A\d*[<>]&-\z/ ) { next }    # N>&- / N<&-: schliesst
            $only_fd = 0;
            last;
        }
        if ($only_fd) {    # exec N>datei: oeffnet (legt an), haelt keine Sperre
            for my $f (@files) {
                my $pth = _absp( $f->[1] );
                if ( $f->[0] eq '<' ) { return ( "bash: $f->[1]: No such file or directory", 0 ) unless defined _file_text( $dev, $pth ); next }
                next if _file_entry( $dev, $pth ) && $f->[0] eq '>>';
                my ( $e, $wok ) = _write_path( $dev, $pth, '', $f->[0] eq '>>', $ctx );
                return ( $e, 0 ) unless $wok;
            }
            return ( '', 1 );
        }
    }
    if ( !ref $cmd && !grep { ref $_ && $_->{op} =~ /\A(?:\||>|>>)\z/ } @a ) {
        if ( $cmd =~ /\A(?:export|declare|typeset|local|readonly)\z/ ) {
            for my $x ( @a[ 1 .. $#a ] ) {
                next if $x =~ /\A-[xrgil]+\z/;
                die "gap: $cmd $x\n" if $x =~ /\A-/;
                my ( $k, $v ) = $x =~ /\A([A-Za-z_]\w*)(?:=(.*))?\z/s or return ( "bash: $cmd: `$x': not a valid identifier", 0 );
                $SH->{vars}{$k} = $v if defined $v;
                $SH->{vars}{$k} //= '' if $cmd ne 'export';
                $SH->{exported}{$k} = 1 if $cmd eq 'export' || grep { $_ eq '-x' } @a;
            }
            return ( '', 1 );
        }
        if ( $cmd eq 'unset' ) { delete $SH->{vars}{$_} for grep { !/\A-/ } @a[ 1 .. $#a ]; return ( '', 1 ) }
        if ( $cmd eq 'set' ) {
            my @o = @a[ 1 .. $#a ];
            while ( defined( my $x = shift @o ) ) {
                if ( $x eq '--' ) { $SH->{args} = [@o]; last }
                if ( $x eq '-o' || $x eq '+o' ) { my $n = shift(@o) // ''; $SH->{errexit} = $x eq '-o' ? 1 : 0 if $n eq 'errexit'; next }
                if ( my ( $sg, $fl ) = $x =~ /\A([-+])([a-zA-Z]+)\z/ ) {
                    $SH->{errexit} = $sg eq q{-} ? 1 : 0 if $fl =~ /e/;
                    if ( $fl =~ /o/ ) { my $n = shift(@o) // ''; $SH->{errexit} = $sg eq q{-} ? 1 : 0 if $n eq 'errexit' }    # set -euo pipefail
                    next;
                }
                $SH->{args} = [ $x, @o ];
                last;
            }
            return ( '', 1 );
        }
        if ( $cmd eq 'shift' ) { splice @{ $SH->{args} }, 0, $a[1] // 1; return ( '', 1 ) }
        if ( $cmd eq 'umask' ) { return _umask( @a[ 1 .. $#a ] ) }
        if ( $cmd eq 'exit' || $cmd eq 'return' ) {
            my $n = $a[1] // $SH->{rc} // 0;
            $n = 2 unless $n =~ /\A\d+\z/;
            $SH->{ctl} = [ $cmd eq 'return' && $SH->{in_func} ? 'return' : 'exit' ];
            $SH->{rc} = $SH->{code} = $n % 256;
            return ( '', $n ? 0 : 1 );
        }
        if ( $cmd eq 'read' ) {
            my $in = $class->_doc_input( $dev, $nd, $ctx );
            die "gap: read\n" unless defined $in;
            return _read_into( [ @a[ 1 .. $#a ] ], ( split /\n/, $in, 2 )[0] // '' ) ? ( '', 1 ) : ( '', 0 );
        }
        if ( $cmd eq 'source' || $cmd eq '.' ) {
            my $t = defined $a[1] ? _file_text( $dev, _absp( $a[1] ) ) : undef;
            return ( "bash: " . ( $a[1] // '' ) . ": No such file or directory", 0 ) unless defined $t;
            my ( $o, $k ) = $class->_run_inner( $dev, $t, $ctx, $SH );
            return ( $o, $k );
        }
        return _trap_cmd( @a[ 1 .. $#a ] ) if $cmd eq 'trap';
        die "gap: $cmd\n" if $cmd =~ /\A(?:eval|exec|wait|getopts|let|mapfile|readarray|pushd|popd|alias)\z/;
    }
    # Shell-Funktion (name() { … }): ihr Rumpf mit den Argumenten, return endet sie
    if ( !ref $cmd && ( my $fb = ( $SH->{funcs} || {} )->{$cmd} ) ) {
        die "gap: $cmd (Funktion mit Pipe oder Umleitung)\n" if grep { ref } @a;
        local $SH->{args} = [ @a[ 1 .. $#a ] ];
        local $SH->{in_func} = 1;
        my ( $o, $k ) = $class->_exec_nodes( $dev, $fb, $ctx );
        if ( ( $SH->{ctl} // [''] )->[0] eq 'return' ) { delete $SH->{ctl}; $k = !$SH->{rc} }
        $SH->{code} = $SH->{rc} unless $k;
        return ( join( "\n", @$o ), $k );
    }
    my $in = $class->_doc_input( $dev, $nd, $ctx );
    # 2>/dev/null an einem Befehl: seine Fehlermeldungen ("prog: …") verschwinden — die
    # Simulation kennt nur einen Ausgabestrom, Meldungen tragen den Namen des Programms
    my %quiet = map { $_ => 1 } _errnull_progs($raw);
    local $ERRNULL = %quiet ? \%quiet : undef;
    my ( $o, $k ) = $class->_pipeline( $dev, \@a, $ctx, $in );
    $o = _errnull_cut( $o, [ keys %quiet ] ) if %quiet;
    return ( $o, $k );
}

# Fehlermeldungen dieser Programme aus einer Ausgabe entfernen ("ls: …", "bash: cd: …")
sub _errnull_cut {
    my ( $o, $names ) = @_;
    return $o unless defined $o && length $o && @$names;
    my %q = map { $_ => 1 } @$names;
    my $t = join "\n", grep { !( /\A([\w.\[-]+): / && $q{$1} || /\Abash: ([\w.\[-]+): / && $q{$1} ) } split /\n/, $o, -1;
    $t =~ s/\A\n+//;
    return $t;
}

# Programme einer Pipeline, deren Fehlerausgabe nach /dev/null geht (2>/dev/null, 2>>/dev/null)
sub _errnull_progs {
    my ($raw) = @_;
    return () unless $raw =~ m{2>>?\s*/dev/null};
    my ( @seg, $cur, $q ) = ();
    $cur = '';
    for my $c ( split //, $raw ) {
        if ($q) { $q = '' if $c eq $q; $cur .= $c; next }
        if ( $c eq "'" || $c eq '"' ) { $q = $c; $cur .= $c; next }
        if ( $c eq '|' ) { push @seg, $cur; $cur = ''; next }
        $cur .= $c;
    }
    push @seg, $cur;
    my @p;
    for my $s ( grep { m{(?:\A|\s)2>>?\s*/dev/null} } @seg ) {
        my @w = grep { !/\A[A-Za-z_]\w*=/ } split ' ', $s;
        shift @w while @w && ( $w[0] eq 'sudo' || $w[0] =~ /\A-/ );
        if ( @w && $w[0] eq 'timeout' ) { shift @w; shift @w while @w && $w[0] =~ /\A-/; shift @w }    # timeout DAUER befehl
        next unless @w;
        ( my $n = $w[0] ) =~ s{.*/}{};
        push @p, $n;
        push @p, 'bash' if $n =~ /\A(?:ba)?sh\z/;    # bash -c '…': Meldungen der bash
    }
    return @p;
}

# read [-r] [-p prompt] [var …] aus einer Zeile; IFS aus der Shell
sub _read_into {
    my ( $av, $line ) = @_;
    my @a = @$av;
    my ( $raw, @names );
    while ( defined( my $x = shift @a ) ) {
        if    ( $x eq '-r' ) { $raw = 1 }
        elsif ( $x =~ /\A-[ptd]\z/ ) { shift @a }    # -d: Saetze kommen hier schon getrennt (find -print0 wie -print)
        elsif ( $x =~ /\A-r([d])\z/ ) { $raw = 1; shift @a }
        elsif ( $x =~ /\A-/ ) { die "gap: read $x\n" }
        else { push @names, $x }
    }
    @names = ('REPLY') unless @names;
    $line =~ s/\\(.)/$1/g unless $raw;
    my $ifs = $SHENV && exists $SHENV->{IFS} ? $SHENV->{IFS} : exists $SH->{vars}{IFS} ? $SH->{vars}{IFS} : " \t\n";
    my @v;
    if ( $ifs eq '' ) { @v = ($line) }
    else {
        my $ws = join '', grep { /\s/ } split //, $ifs;
        my $cls = '[' . quotemeta($ifs) . ']';
        $line =~ s/\A[\Q$ws\E]+|[\Q$ws\E]+\z//g if length $ws;
        @v = split /$cls/, $line, scalar @names;
        @v = split( ' ', $line, scalar @names ) if $ifs eq " \t\n";
    }
    $SH->{vars}{ $names[$_] } = $v[$_] // '' for 0 .. $#names;
    return 1;
}

sub _fileinfo {
    my ( $dev, $p ) = @_;
    $p = _absp($p);
    if ( my $e = _file_entry( $dev, $p ) ) {
        my $l = defined $e->{link};
        my $tk = $l ? ( _is_dir( $dev, $p ) ? 'd' : _file_entry( $dev, _link_target( $p, $e->{link} ) ) ? 'f' : undef ) : undef;
        return { kind => $l ? 'l' : 'f', target_kind => $tk, size => _file_size($e), mode => _mode_of($e), mtime => _mtime($e) };
    }
    return { kind => 'd', size => 4096, mode => oct( ( ( $dev->{dirs} || {} )->{$p} || {} )->{mode} // '0755' ), mtime => 0 } if _is_dir( $dev, $p );
    return undef;
}

sub _test_cmd {
    my ( $name, $dev, $av ) = @_;
    my @a = @$av;
    if ( $name eq '[' ) { return ( "bash: [: missing `]'", 0 ) unless @a && $a[-1] eq ']'; pop @a }
    my ( $st, $err ) = Langertha::Holmgang::Shell::test_expr( \@a, sub { _fileinfo( $dev, $_[0] ) } );
    $SH->{code} = $st if $SH;
    return ( $err // '', $st == 0 ? 1 : 0 );
}

# Ausgabe eines Blocks durch den Rest hinter done/fi (| filter, > datei)
sub _post {
    my ( $class, $dev, $post, $ctx, $out, $ok ) = @_;
    return ( $out, $ok ) unless $post && $post->{raw} =~ /\S/;
    return ( $out, $ok ) if $post->{raw} =~ /\A\s*<\s*<\(.*\)\s*\z/s;    # done < <( … ): schon als Eingabe gelesen
    my $w = $class->_words_of( $dev, $post->{raw}, $ctx );
    my @w;    # ohne < datei (schon als Eingabe gelesen)
    for ( my $i = 0; $i < @$w; $i++ ) {
        my $x = $w->[$i];
        if ( ref $x && $x->{op} eq '<' ) { $i++; next }
        push @w, $x;
    }
    return ( $out, $ok ) unless @w;
    my $text = join "\n", grep { length } @$out;
    if ( ref $w[0] && $w[0]{op} eq '|' ) {
        shift @w;
        my ( $o, $k ) = $class->_pipeline( $dev, \@w, $ctx, length $text ? "$text\n" : '' );
        return ( [ defined $o && length $o ? $o : () ], $k );
    }
    if ( ref $w[0] && ( $w[0]{op} eq '>' || $w[0]{op} eq '>>' ) && defined $w[1] && !ref $w[1] ) {
        my ( $e, $wok ) = _write_path( $dev, $w[1], length $text ? "$text\n" : '', $w[0]{op} eq '>>', $ctx );
        return $wok ? ( [], $ok ) : ( [$e], 0 );
    }
    die "gap: $post->{raw}\n";
}

# Eingabe eines Blocks aus done < datei, Heredoc oder Here-String
sub _post_input {
    my ( $class, $dev, $post, $ctx ) = @_;
    return undef unless $post;
    my $in = $class->_doc_input( $dev, $post, $ctx );
    return $in if defined $in;
    return undef unless $post->{raw} =~ /</;
    # done < <( befehl ): die Ausgabe des Befehls (in einer Kopie der Shell) als Eingabe
    if ( $post->{raw} =~ /<\s*<\((.*)\)\s*\z/s ) {
        my $sub = { %$SH, vars => { %{ $SH->{vars} } }, ctl => undef };
        my ($o) = $class->_run_inner( $dev, $1, $ctx, $sub );
        return length( $o // '' ) ? "$o\n" : '';
    }
    die "gap: <( )\n" if $post->{raw} =~ /<\s*<\(/;
    my $w = $class->_words_of( $dev, $post->{raw}, $ctx );
    for my $i ( 0 .. $#$w ) {
        next unless ref $w->[$i] && $w->[$i]{op} eq '<';
        my $f = $w->[ $i + 1 ];
        my $t = defined $f && !ref $f ? _file_text( $dev, _absp($f) ) : undef;
        die "bash: " . ( $f // '' ) . ": No such file or directory\n" unless defined $t;
        return $t;
    }
    return undef;
}

sub _exec_if {
    my ( $class, $dev, $nd, $ctx ) = @_;
    my ( $out, $ok ) = ( [], 1 );
    my $done;
    for my $arm ( @{ $nd->{arms} } ) {
        my ( $co, $ck ) = do { local $SH->{in_cond} = 1; $class->_exec_nodes( $dev, $arm->[0], $ctx ) };
        push @$out, @$co;
        return ( join( "\n", @$out ), 0 ) if $SH->{ctl};
        next unless $ck;
        my ( $bo, $bk ) = $class->_exec_nodes( $dev, $arm->[1], $ctx );
        push @$out, @$bo;
        ( $ok, $done ) = ( $bk, 1 );
        last;
    }
    if ( !$done && $nd->{else} ) { my ( $bo, $bk ) = $class->_exec_nodes( $dev, $nd->{else}, $ctx ); push @$out, @$bo; $ok = $bk }
    ( $out, $ok ) = $class->_post( $dev, $nd->{post}, $ctx, $out, $ok );
    return ( join( "\n", @$out ), $ok );
}

# Schleifenrumpf: break/continue (mit Ebenen) auswerten; wahr = weiter
sub _loop_ctl {
    my $c = $SH->{ctl} or return 1;
    return 0 if $c->[0] eq 'exit';
    if ( $c->[1] > 1 ) { $c->[1]--; return 0 }
    delete $SH->{ctl};
    return $c->[0] eq 'continue' ? 1 : 0;
}

sub _exec_for {
    my ( $class, $dev, $nd, $ctx ) = @_;
    my $w = $class->_words_of( $dev, $nd->{words}, $ctx );
    my @list = grep { !ref } @$w;    # Muster schon von _words_of geglobbt
    my ( @out, $ok ) = ();
    $ok = 1;
    local $SH->{loop} = 1;
    for my $v (@list) {
        $SH->{vars}{ $nd->{var} } = $v;
        my ( $o, $k ) = $class->_exec_nodes( $dev, $nd->{body}, $ctx );
        push @out, @$o;
        $ok = $k;
        last unless _loop_ctl();
    }
    my ( $po, $pk ) = $class->_post( $dev, $nd->{post}, $ctx, \@out, $ok );
    return ( join( "\n", @$po ), $pk );
}

sub _exec_while {
    my ( $class, $dev, $nd, $ctx ) = @_;
    my $in;
    if ( defined $nd->{input_cmd} ) {
        my $sub = { %$SH, vars => { %{ $SH->{vars} } }, ctl => undef };
        ($in) = $class->_run_inner( $dev, $nd->{input_cmd}, $ctx, $sub );
        $in = length( $in // '' ) ? "$in\n" : '';
    }
    $in //= $class->_post_input( $dev, $nd->{post}, $ctx );
    my $cond = $nd->{cond};
    my $read = @$cond == 1 && $cond->[0]{type} eq 'cmd' && $cond->[0]{raw} =~ /\A(?:IFS=\S*\s+)?read\b/ ? $cond->[0] : undef;
    die "gap: while\n" if defined $in && !$read;
    my ( @out, $ok ) = ();
    $ok = 1;
    local $SH->{loop} = 1;
    my @lines = defined $in ? split( /\n/, $in ) : ();
    my $n = 0;
    while (1) {
        die "gap: while (mehr als 1000 Durchlaeufe)\n" if ++$n > 1000;
        my $go;
        if ($read) {
            last if $nd->{until} || !@lines;
            my $w = $class->_words_of( $dev, $read->{raw}, $ctx );
            my @a = grep { !ref } @$w;
            local $SHENV = { %{ $SHENV || {} } };
            while ( @a && $a[0] =~ /\A(IFS)=(.*)\z/s ) { $SHENV->{$1} = $2; shift @a }
            shift @a;    # read
            _read_into( \@a, shift @lines );
            $go = 1;
        }
        else {
            my ( $co, $ck ) = do { local $SH->{in_cond} = 1; $class->_exec_nodes( $dev, $cond, $ctx ) };
            push @out, @$co;
            last if $SH->{ctl};
            $go = $nd->{until} ? !$ck : $ck;
        }
        last unless $go;
        my ( $o, $k ) = $class->_exec_nodes( $dev, $nd->{body}, $ctx );
        push @out, @$o;
        $ok = $k;
        last unless _loop_ctl();
    }
    my ( $po, $pk ) = $class->_post( $dev, $nd->{post}, $ctx, \@out, $ok );
    return ( join( "\n", @$po ), $pk );
}

sub _exec_case {
    my ( $class, $dev, $nd, $ctx ) = @_;
    my $w = $class->_words_of( $dev, $nd->{word}, $ctx, 1 );
    my $word = join ' ', grep { !ref } @$w;
    for my $arm ( @{ $nd->{arms} } ) {
        for my $p ( @{ $arm->{pats} } ) {
            my $pw = $class->_words_of( $dev, $p, $ctx, 1 );
            my $re = Langertha::Holmgang::Shell::glob_re( join( ' ', grep { !ref } @$pw ), 1 );
            next unless $word =~ /\A$re\z/s;
            my ( $o, $k ) = $class->_exec_nodes( $dev, $arm->{body}, $ctx );
            return ( join( "\n", @$o ), $k );
        }
    }
    return ( '', 1 );
}

sub _pipeline {
    my ( $class, $dev, $words, $ctx, $stdin ) = @_;
    my @stages = ([]);
    my ( $redir, $file );
    my @w = @$words;
    my $infile;
    while (@w) {
        my $t = shift @w;
        if ( ref $t && $t->{op} eq '|' ) { push @stages, []; next }
        if ( ref $t && $t->{op} eq '<' ) {    # < datei: Eingabe des ersten Befehls
            $infile = shift @w;
            die "gap: <( )\n" if defined $infile && !ref $infile && $infile =~ /\A<\(/;    # < <( … ): Prozessersetzung
            return ( 'bash: syntax error near unexpected token `newline\'', 0 ) unless defined $infile && !ref $infile;
            next;
        }
        if ( ref $t && ( $t->{op} eq '>' || $t->{op} eq '>>' ) ) {
            $redir = $t->{op};
            $file  = shift @w;
            return ( 'bash: syntax error near unexpected token `newline\'', 0 ) unless defined $file && !ref $file;
            next;
        }
        return ( 'bash: syntax error near unexpected token `' . $t->{op} . "'", 0 ) if ref $t;
        push @{ $stages[-1] }, $t;
    }
    if ( $redir && @stages == 1 && !@{ $stages[0] } ) {    # > datei: leeren bzw. anlegen
        my ( $e, $wok ) = _write_path( $dev, $file, '', $redir eq '>>', $ctx );
        return ( $wok ? '' : $e, $wok );
    }
    # < datei: Eingabe des ersten Befehls (sonst Heredoc bzw. Pipe in den Block)
    my $in = $stdin;
    # /dev/tcp/HOST/PORT oeffnet die bash als Verbindung — ohne Netz nicht nachgebildet: Luecke
    if ( defined $infile && $infile =~ m{\A/dev/(?:tcp|udp)/} ) { return _dev_tcp( $dev, $infile, '<' ) }
    if ( defined $infile && !$redir && @stages == 1 && !@{ $stages[0] } ) {    # nur < datei: oeffnen und schliessen
        return defined _file_text( $dev, _absp($infile) ) ? ( '', 1 ) : ( "bash: $infile: No such file or directory", 0 );
    }
    if ( defined $infile ) {
        $in = _file_text( $dev, _absp($infile) );
        return ( "bash: $infile: No such file or directory", 0 ) unless defined $in;
    }
    return ( "bash: syntax error near unexpected token `|'", 0 ) if grep { !@$_ } @stages;
    delete $SH->{code} if $SH;
    my ( $out, $ok ) = $class->_command( $dev, $stages[0], $ctx, $in );
    # ${PIPESTATUS[@]}: Status jeder Stufe
    my @ps = ( $ok ? 0 : ( $SH && $SH->{code} ) || 1 );
    $SH->{pipestatus} = \@ps if $SH;
    my @err;    # Meldungen der bash selbst (stderr) gehen nicht in die Pipe
    for my $i ( 1 .. $#stages ) {
        local $AS_USER = $AS_USER;
        if ($ERRNULL) {    # 2>/dev/null an der vorigen Stufe: ihre Meldungen nicht in die Pipe
            my ($pn) = map { s{.*/}{}r } _strip_sudo( @{ $stages[ $i - 1 ] } );
            $out = _errnull_cut( $out, [$pn] ) if defined $pn && $ERRNULL->{$pn};
        }
        if ( !$ok && defined $out && $out =~ /\Abash: [^\n]+: (?:command not found|No such file or directory)\z/ ) {
            push @err, $out;
            $out = '';
        }
        my $argv = [ _strip_sudo( @{ $stages[$i] } ) ];
        if ( $argv->[0] eq 'tee' ) {
            my $append = grep { $_ eq '-a' } @$argv;
            my @f = grep { !/\A-/ } @{$argv}[ 1 .. $#$argv ];
            for my $f (@f) {
                my ( $e, $wok ) = _write_path( $dev, $f, ( $out // '' ) . "\n", $append, $ctx );
                return ( $e, 0 ) unless $wok;
            }
            push @ps, 0;
            next;
        }
        my ( $t, $k ) = Langertha::Holmgang::Shell::Filter::filter_output( $out // '', $argv );
        if ( !defined $t ) {
            # hatte die vorige Stufe ein Zeilenende? (echo -n, printf ohne \n: nein) — fuer base64
            my @prev = _strip_sudo( @{ $stages[ $i - 1 ] } );
            local our $STDIN_NL = !( ( $prev[0] // '' ) eq 'echo' && grep( { /\A-[a-zA-Z]*n/ } @prev[ 1 .. $#prev ] )
                || ( $prev[0] // '' ) eq 'printf' && ( $prev[1] // '' ) !~ /\\n\z/ );
            delete $SH->{code} if $SH;
            ( $t, $k ) = $class->_command( $dev, $argv, $ctx, $out );
        }
        push @ps, $k ? 0 : ( $SH && $SH->{code} ) || 1;
        ( $out, $ok ) = ( $t, $k );
    }
    if ($redir) {
        my ( $e, $wok ) = _write_path( $dev, $file, defined $out && length $out ? "$out\n" : '', $redir eq '>>', $ctx );
        return ( $e, 0 ) unless $wok;
        return ( join( "\n", @err ), $ok );
    }
    return ( join( "\n", @err, defined $out && length $out ? $out : () ), $ok ) if @err;
    return ( $out, $ok );
}

# Shell-Muster (*, ?) gegen die Pfade im Zustand; ohne Treffer bleibt das Wort
sub _glob {
    my ( $dev, $w ) = @_;
    if ( $w =~ m{\A(.+?)/+\z} ) { my @h = _glob( $dev, $1 ); return @h == 1 && $h[0] eq $1 ? $w : map {"$_/"} @h }
    ( my $re = quotemeta $w ) =~ s/\\\*/[^\/]*/g;
    $re =~ s/\\\?/[^\/]/g;
    # Zeichenklassen [0-9], [!a] bzw. [^a]
    $re =~ s/\\\[((?:\\[!^])?)((?:(?!\\\]).)+)\\\]/'[' . ( length $1 ? '^' : '' ) . ( $2 =~ s{\\(.)}{$1}gr ) . ']'/ge;
    my %cand;
    for my $p ( keys %{ $dev->{files} || {} } ) {
        my @seg = split m{/}, $p;
        $cand{ join '/', @seg[ 0 .. $_ ] } = 1 for 1 .. $#seg;
    }
    my $rx = do { no warnings; eval { qr/\A$re\z/ } } // return $w;    # kein gueltiges Muster (sed-Ausdruck, JSON): das Wort bleibt
    my @hit = sort grep { $_ =~ $rx } keys %cand;
    return @hit ? @hit : $w;
}

# mkdir [-p] [-m MODUS] [-v] dir …: ohne -p muss der Elternordner da sein; als Benutzer
# braucht es Schreibrecht am Elternordner (s. _may_create); umask und setgid wirken.
sub _mkdir {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $p, $mode, $v, @d );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-m' || $x eq '--mode' ) { $mode = shift @a }
        elsif ( $x =~ /\A--mode=(.+)\z/ )     { $mode = $1 }
        elsif ( $x eq '--parents' )            { $p = 1 }
        elsif ( $x eq '--verbose' )            { $v = 1 }
        elsif ( $x =~ /\A-([pvm]+)\z/ )        { my $f = $1; $p = 1 if $f =~ /p/; $v = 1 if $f =~ /v/; $mode = shift @a if $f =~ /m/ }
        elsif ( $x eq '--' )                   { push @d, @a; last }
        else                                   { push @d, $x }
    }
    return ( "mkdir: missing operand\nTry 'mkdir --help' for more information.", 0 ) unless @d;
    return ( "mkdir: invalid mode '$mode'", 0 ) if defined $mode && $mode !~ /\A[0-7]{1,4}\z/;
    my ( @out, $ok ) = ();
    $ok = 1;
    for my $raw (@d) {
        ( my $d = _absp($raw) ) =~ s{(?<=.)/+\z}{};
        if ( _is_dir( $dev, $d ) || _file_entry( $dev, $d ) ) {
            next if $p && _is_dir( $dev, $d );
            push @out, "mkdir: cannot create directory '$raw': File exists";
            $ok = 0;
            next;
        }
        my @seg = split m{/}, $d;
        my @todo = grep { !_is_dir( $dev, $_ ) } map { join '/', @seg[ 0 .. $_ ] } 1 .. $#seg;
        if ( @todo > 1 && !$p ) { push @out, "mkdir: cannot create directory '$raw': No such file or directory"; $ok = 0; next }
        for my $t (@todo) {
            if ( my $err = _may_create( $dev, $t ) ) { push @out, "mkdir: cannot create directory '" . ( $t eq $d ? $raw : $t ) . "': $err"; $ok = 0; last }
            $dev->{dirs}{$t} = _new_meta( $dev, $t, 1, $t eq $d ? $mode : undef );
            push @out, "mkdir: created directory '$t'" if $v;
        }
    }
    return ( join( "\n", @out ), $ok );
}

# Wer gerade anlegt: der Benutzer des Befehls (sudo -u), sonst der Shell (su)
sub _who { return $AS_USER // $LOGIN_USER // 'root' }

# Verzeichnis-Eintrag mit Rechten (auch /tmp, /var/tmp: 1777; /home/<benutzer>: dem Benutzer)
sub _dir_meta {
    my ( $dev, $d ) = @_;
    return { mode => '0755', %{ $dev->{dirs}{$d} } } if ref( ( $dev->{dirs} || {} )->{$d} ) eq 'HASH';
    return { mode => '1777' } if $d eq '/tmp' || $d eq '/var/tmp';
    if ( $d =~ m{\A/home/([^/]+)\z} && ( my $u = ( $dev->{users} || {} )->{$1} ) ) {
        return { owner => $1, group => ( $u->{groups} || [$1] )->[0], mode => '0755' };
    }
    return { mode => '0755' };
}

# Recht (4 r, 2 w, 1 x) eines Benutzers an einem Eintrag mit owner/group/mode
sub _perm {
    my ( $dev, $user, $e, $bit ) = @_;
    return 1 if $user eq 'root';
    my $m = oct( $e->{mode} // '0644' );
    return ( ( $m >> 6 ) & $bit ) ? 1 : 0 if ( $e->{owner} // 'root' ) eq $user;
    my @groups = @{ ( ( $dev->{users} || {} )->{$user} || {} )->{groups} || [] };
    return ( ( $m >> 3 ) & $bit ) ? 1 : 0 if grep { $_ eq ( $e->{group} // 'root' ) } @groups;
    return ( $m & $bit ) ? 1 : 0;
}

# Darf der aktuelle Benutzer $path anlegen bzw. beschreiben? undef oder die Meldung
sub _may_create {
    my ( $dev, $path ) = @_;
    my $user = _who();
    return undef if $user eq 'root';
    return 'Permission denied' unless _traverse_ok( $dev, $path );
    if ( my $e = _file_entry( $dev, $path ) ) { return _perm( $dev, $user, $e, 2 ) ? undef : 'Permission denied' }
    ( my $dir = $path ) =~ s{/[^/]+\z}{};
    my $de = _dir_meta( $dev, length $dir ? $dir : '/' );
    return _perm( $dev, $user, $de, 2 ) && _perm( $dev, $user, $de, 1 ) ? undef : 'Permission denied';
}

# Darf der aktuelle Benutzer bis $path gehen (x an jedem Verzeichnis davor)? root immer
sub _traverse_ok {
    my ( $dev, $path ) = @_;
    my $user = _who();
    return 1 if $user eq 'root';
    my @seg = split m{/}, $path =~ s{(?<=.)/+\z}{}r;
    for my $i ( 1 .. $#seg - 1 ) {
        my $d = join '/', @seg[ 0 .. $i ];
        return 0 unless _perm( $dev, $user, _dir_meta( $dev, $d ), 1 );
    }
    return 1;
}

# Recht (4 r, 2 w, 1 x) des aktuellen Benutzers an einem Verzeichnis selbst
sub _dir_ok {
    my ( $dev, $d, $bit ) = @_;
    my $user = _who();
    return $user eq 'root' ? 1 : _perm( $dev, $user, _dir_meta( $dev, $d ), $bit );
}

# Darf der aktuelle Benutzer die Datei lesen (Weg und r)?
sub _read_ok {
    my ( $dev, $path ) = @_;
    my $user = _who();
    return 1 if $user eq 'root';
    my $e = _file_entry( $dev, $path ) or return 1;    # gibt es nicht: die Meldung dafuer kommt woanders
    return _traverse_ok( $dev, $path ) && _perm( $dev, $user, { mode => sprintf( '%o', _mode_of($e) ), owner => $e->{owner}, group => $e->{group} }, 4 );
}

# Metadaten eines neuen Eintrags: Eigentuemer der aktuelle Benutzer, Gruppe seine erste
# (im setgid-Verzeichnis die des Verzeichnisses, Verzeichnisse erben setgid), Rechte
# 0666/0777 ohne umask. Als root mit umask 022 ohne setgid: wie bisher (Vorgaben).
sub _new_meta {
    my ( $dev, $path, $isdir, $mode ) = @_;
    my $user = _who();
    ( my $dir = $path ) =~ s{/[^/]+\z}{};
    my $pe = _dir_meta( $dev, length $dir ? $dir : '/' );
    my $sgid = oct( $pe->{mode} // '0755' ) & 02000;
    my $umask = $SH && defined $SH->{umask} ? $SH->{umask} : 022;
    return $isdir ? {} : undef if $user eq 'root' && !$sgid && $umask == 022 && !defined $mode;
    my $m = defined $mode ? oct($mode) : ( $isdir ? 0777 : 0666 ) & ~$umask;
    $m |= 02000 if $isdir && $sgid;
    my $grp = $sgid ? $pe->{group} // 'root' : $user eq 'root' ? 'root' : ( ( ( $dev->{users} || {} )->{$user} || {} )->{groups} || [$user] )->[0];
    return { owner => $user, group => $grp, mode => sprintf( '%04o', $m ) };
}

# umask [-S] [MODUS] (eingebaut, je Shell)
sub _umask {
    my @a = @_;
    my $sym = @a && $a[0] eq '-S' ? shift @a : undef;
    my $cur = defined $SH->{umask} ? $SH->{umask} : 022;
    if ( !@a ) {
        return ( sprintf( '%04o', $cur ), 1 ) unless $sym;
        my @p = map { my $b = 7 & ~( $cur >> $_->[1] ); "$_->[0]=" . join '', map { $b & $_->[1] ? $_->[0] : () } [ r => 4 ], [ w => 2 ], [ x => 1 ] } [ u => 6 ], [ g => 3 ], [ o => 0 ];
        return ( join( ',', @p ), 1 );
    }
    die "gap: umask $a[0]\n" if $a[0] =~ /[ugoa=+-]/;    # symbolisch: nicht nachgebildet
    return ( "bash: umask: $a[0]: octal number out of range", 0 ) unless $a[0] =~ /\A[0-7]{1,4}\z/;
    $SH->{umask} = oct( $a[0] ) & 0777;
    return ( '', 1 );
}

# Pfad relativ zum aktuellen Verzeichnis (cd)
sub _absp {
    my ($p) = @_;
    return _dotdot($p) if $p =~ m{\A/};
    my $c = $CWD_DIR // '/root';
    $p =~ s{\A\./}{};
    return _dotdot( $p eq '.' ? $c : $c eq '/' ? "/$p" : "$c/$p" );
}

# . und .. in einem absoluten Pfad aufloesen (/srv/a/../b -> /srv/b); ein / am Ende bleibt
sub _dotdot {
    my ($p) = @_;
    return $p unless $p =~ m{(?:\A|/)\.\.?(?:/|\z)};
    my $end = $p =~ m{(?<=.)/\z} ? '/' : '';
    my @s;
    for my $x ( split m{/+}, $p ) {
        next if $x eq '' || $x eq '.';
        if ( $x eq '..' ) { pop @s; next }
        push @s, $x;
    }
    return '/' . join( '/', @s ) . ( @s ? $end : '' );
}

# cp wie GNU: ohne -p/-a gehoert die neue Datei root (Rechte der Quelle ohne umask 022),
# eine vorhandene Zieldatei behaelt Eigentuemer und Rechte; -a/-p erhaelt alles;
# Verzeichnisse nur mit -r/-R/-a.
sub _cp {
    my ( $dev, $av ) = @_;
    my ( %o, @a );
    for my $x (@$av) {
        if    ( $x =~ /\A--(archive|preserve(?:=.*)?|recursive|no-clobber)\z/ ) { $o{ substr( $1, 0, 1 ) eq 'a' ? 'a' : substr( $1, 0, 1 ) eq 'p' ? 'p' : substr( $1, 0, 1 ) eq 'r' ? 'r' : 'n' } = 1 }
        elsif ( $x =~ /\A--/ ) { }
        elsif ( $x =~ /\A-([a-zA-Z]+)\z/ ) { $o{ $_ eq 'R' ? 'r' : $_ } = 1 for split //, $1 }
        else  { push @a, _absp($x) }
    }
    return ( 'cp: missing file operand', 0 ) unless @a >= 2;
    my $to = pop @a;
    $to =~ s{(?<=.)/+\z}{};
    my $keep = $o{a} || $o{p};
    my $rec  = $o{a} || $o{r};
    return ( "cp: target '$to': Not a directory", 0 ) if @a > 1 && !_is_dir( $dev, $to );
    _part('Backup');
    my $put = sub {
        my ( $src, $dst ) = @_;
        return if $o{n} && _file_entry( $dev, $dst );
        my $new = Langertha::Holmgang::Sim::Linux::Backup::copy_entry( $dev->{files}{$src}, $keep );
        my $old = ref $dev->{files}{$dst} eq 'HASH' ? $dev->{files}{$dst} : undef;
        if ( $old && !$keep ) { $new->{$_} = $old->{$_} for grep { defined $old->{$_} } qw( owner group mode ) }
        $new->{open_by} = $old->{open_by} if $old && $old->{open_by};
        $dev->{files}{$dst} = $new;
    };
    for my $from (@a) {
        $from =~ s{(?<=.)/+\z}{};
        ( my $base = $from ) =~ s{.*/}{};
        if ( _file_entry( $dev, $from ) ) { $put->( $from, _is_dir( $dev, $to ) ? "$to/$base" : $to ); next }
        return ( "cp: cannot stat '$from': No such file or directory", 0 ) unless _is_dir( $dev, $from );
        return ( "cp: -r not specified; omitting directory '$from'", 0 ) unless $rec;
        my $root = _is_dir( $dev, $to ) ? ( $to eq '/' ? '' : $to ) . "/$base" : $to;
        $put->( $_, $root . substr( $_, length $from ) ) for _under( $dev, $from );
        for my $d ( sort grep { $_ eq $from || index( $_, "$from/" ) == 0 } keys %{ $dev->{dirs} || {} } ) {
            my $e = $dev->{dirs}{$d};
            $dev->{dirs}{ $root . substr( $d, length $from ) } = $keep && ref $e eq 'HASH' ? {%$e} : ref $e eq 'HASH' && defined $e->{mode} ? { mode => $e->{mode} } : {};
        }
        $dev->{dirs}{$root} //= {} unless _is_dir( $dev, $root );
    }
    return ( '', 1 );
}

# Ziel einer Kopie/Verschiebung: in ein vorhandenes Verzeichnis hinein, sonst der Name selbst
sub _dest {
    my ( $dev, $from, $to ) = @_;
    ( my $base = $from ) =~ s{/+\z}{};
    $base =~ s{.*/}{};
    $to =~ s{(?<=.)/+\z}{};
    return _is_dir( $dev, $to ) ? ( $to eq '/' ? "/$base" : "$to/$base" ) : $to;
}

# Verzeichnis samt Inhalt kopieren/verschieben (cp -r/-a, mv)
sub _tree {
    my ( $dev, $from, $to, $how ) = @_;
    $from =~ s{(?<=.)/+\z}{};
    my $who = $Langertha::Holmgang::Sim::Linux::AS_USER // 'root';
    my $own = sub {
        my $e = shift;
        return $e if $how ne 'copy';
        my %n = %$e;
        delete @n{qw( owner group open_by )};
        @n{qw( owner group )} = ( $who, $who ) if $who ne 'root';
        return \%n;
    };
    my $dirs = $dev->{dirs} ||= {};
    for my $d ( sort grep { $_ eq $from || index( $_, "$from/" ) == 0 } keys %$dirs ) {
        my $n = $to . substr( $d, length $from );
        $dirs->{$n} = $own->( { %{ $dirs->{$d} } } );
        delete $dirs->{$d} if $how eq 'move';
    }
    $dirs->{$to} //= {};
    for my $f ( _under( $dev, $from ) ) {
        my $n = $to . substr( $f, length $from );
        my $e = $dev->{files}{$f};
        $dev->{files}{$n} = ref $e ? $own->( { %$e } ) : $e;
        delete $dev->{files}{$f} if $how eq 'move';
    }
    return ( '', 1 );
}

# namei -l pfad: jeder Teil des Pfads mit Rechten und Besitzern (wie util-linux)
sub _namei {
    my ( $dev, $av ) = @_;
    my @p = grep { !/\A-/ } @$av or return ( 'namei: no pathname specified', 0 );
    my @out;
    for my $path (@p) {
        push @out, "f: $path";
        my @parts = grep {length} split m{/}, $path;
        my $cur = '';
        for my $i ( -1 .. $#parts ) {
            my $name = $i < 0 ? '/' : $parts[$i];
            $cur = $i < 0 ? '' : "$cur/$parts[$i]";
            my $p = $cur eq '' ? '/' : $cur;
            my $e = _file_entry( $dev, $p );
            my $dir = !$e && ( $p eq '/' || _is_dir( $dev, $p ) );
            return ( join( "\n", @out, "  $name - No such file or directory" ), 0 ) unless $e || $dir;
            my $x = $e // { mode => '0755', %{ ( $dev->{dirs} || {} )->{$p} || {} } };
            my $m = oct( $x->{mode} // ( $dir ? '0755' : '0644' ) );
            my $s = ( $dir ? 'd' : '-' ) . join '', map { my $b = ( $m >> ( 3 * $_ ) ) & 7; ( $b & 4 ? 'r' : '-' ) . ( $b & 2 ? 'w' : '-' ) . ( $b & 1 ? 'x' : '-' ) } 2, 1, 0;
            push @out, sprintf( '%s %-8s %-8s %s', $s, $x->{owner} // 'root', $x->{group} // 'root', $name );
        }
    }
    return ( join( "\n", @out ), 1 );
}

sub _mv {
    my ( $dev, $av ) = @_;
    my @a = map { _absp($_) } grep { !/\A-/ } @$av;
    return ( 'mv: missing file operand', 0 ) unless @a;
    return ( "mv: missing destination file operand after '$a[0]'", 0 ) if @a == 1;
    return _mv_many( $dev, @a ) if @a > 2 || !_file_entry( $dev, $a[0] ) && _is_dir( $dev, $a[0] );
    my ( $from, $to ) = @a;
    my $as_dir = $to =~ m{.(?:/+)\z};
    $to =~ s{(?<=.)/+\z}{};    # mv datei dir/
    _file_entry( $dev, $from ) or return ( "mv: cannot stat '$from': No such file or directory", 0 );
    return ( "mv: cannot move '$from' to '$to/': Not a directory", 0 ) if $as_dir && !_is_dir( $dev, $to );    # Ziel mit / muss ein Verzeichnis sein
    ( my $base = $from ) =~ s{.*/}{};
    my $no_dir = grep { /\A-\w*T/ || $_ eq '--no-target-directory' } @$av;
    if ( !$no_dir && _is_dir( $dev, $to ) ) {
        my $e = $dev->{files}{$to};
        $to = ( ref $e eq 'HASH' && defined $e->{link} ? _link_target( $to, $e->{link} ) : $to ) . "/$base";
    }
    my @keep = _parents_of( $dev, $from );
    $dev->{files}{$to} = delete $dev->{files}{$from};
    _keep_dirs( $dev, @keep );
    return ( '', 1 );
}

# mv QUELLE… VERZEICHNIS (auch Verzeichnisse als Quelle): Fehler je Quelle, die uebrigen laufen
sub _mv_many {
    my ( $dev, @a ) = @_;
    my $to = pop @a;
    $to =~ s{(?<=.)/+\z}{};
    if ( !_is_dir( $dev, $to ) ) {
        return ( "mv: target '$to': Not a directory", 0 ) if @a > 1 && _file_entry( $dev, $to );
        return ( "mv: target '$to': No such file or directory", 0 ) if @a > 1;
    }
    my ( @out, $ok ) = ();
    $ok = 1;
    for my $from (@a) {
        $from =~ s{(?<=.)/+\z}{};
        ( my $base = $from ) =~ s{.*/}{};
        if ( _file_entry( $dev, $from ) ) { my ( $o, $k ) = _mv( $dev, [ $from, $to ] ); push @out, $o if length $o; $ok &&= $k; next }
        if ( !_is_dir( $dev, $from ) ) { push @out, "mv: cannot stat '$from': No such file or directory"; $ok = 0; next }
        my $dst = _is_dir( $dev, $to ) ? ( $to eq '/' ? '' : $to ) . "/$base" : $to;
        if ( $dst eq $from || index( $dst, "$from/" ) == 0 ) { push @out, "mv: cannot move '$from' to a subdirectory of itself, '$dst'"; $ok = 0; next }
        ( my $up = $dst ) =~ s{/[^/]+\z}{};
        if ( length $up && !_is_dir( $dev, $up ) ) { push @out, "mv: cannot move '$from' to '$dst': No such file or directory"; $ok = 0; next }
        my @keep = _parents_of( $dev, $from );
        $dev->{files}{ $dst . substr( $_, length $from ) } = delete $dev->{files}{$_} for _under( $dev, $from );
        for my $k (qw( dirs _dirs )) {
            for my $d ( grep { $_ eq $from || index( $_, "$from/" ) == 0 } keys %{ $dev->{$k} || {} } ) { $dev->{$k}{ $dst . substr( $d, length $from ) } = delete $dev->{$k}{$d} }
        }
        $dev->{dirs}{$dst} //= {} unless _is_dir( $dev, $dst );
        _keep_dirs( $dev, @keep );
    }
    return ( join( "\n", @out ), $ok );
}

# Elternverzeichnisse eines Pfads, die es gibt — vor dem Loeschen gemerkt, damit sie danach
# bleiben (_keep_dirs; im Zustand unter _dirs, eine Laufzeitspur)
sub _parents_of {
    my ( $dev, $p ) = @_;
    my @seg = split m{/}, $p;
    return grep { length && _is_dir( $dev, $_ ) } map { join '/', @seg[ 0 .. $_ ] } 1 .. $#seg - 1;
}

sub _keep_dirs {
    my ( $dev, @d ) = @_;
    $dev->{_dirs}{$_} = 1 for grep { !_is_dir( $dev, $_ ) } @d;
    return;
}

our $STDIN_NL = 1;

sub _strip_sudo {
    my @a = @_;
    while ( @a && $a[0] eq 'sudo' ) {
        shift @a;
        my $invoker = $AS_USER // 'root';
        my ( $list, $lu, $target, $nonint );
        while ( @a && $a[0] =~ /\A-/ ) {
            my $o = shift @a;
            last if $o eq '--';
            if ( $o eq '-u' ) { $target = shift @a }
            elsif ( $o eq '-g' ) { shift @a }
            elsif ( $o =~ /\A--user=(.+)\z/ ) { $target = $1 }
            elsif ( $o eq '-U' ) { $lu = shift @a }
            elsif ( $o =~ /\A-l+\z/ || $o eq '--list' ) { $list = 1 }
            elsif ( $o eq '-n' || $o eq '--non-interactive' ) { $nonint = 1 }
            elsif ( $o =~ /\A-[nilsEHk]+\z/ ) { $nonint = 1 if $o =~ /n/; $list = 1 if $o =~ /l/ }
        }
        return ( 'sudo-list', $lu // $invoker ) if $list && !@a;
        # ein Benutzer ohne Root-Rechte: sudo prueft seine Regeln (wie sudo -n ohne Terminal)
        if ( $invoker ne 'root' && @a && $CTX && ref $CTX->{state} eq 'HASH' && defined $CTX->{host} ) {
            my $dev = $CTX->{state}{ $CTX->{host} };
            if ( ref $dev eq 'HASH' && defined _file_text( $dev, '/etc/sudoers' ) ) {
                my $path = $a[0] =~ m{/} ? $a[0] : do { my ( $p, $k ) = _which( 'which', $dev, [ $a[0] ] ); $k ? $p : undef };
                my $why = _acc()->can('sudo_check')->( $dev, $invoker, $target // 'root', $path // $a[0], defined $path,
                    [ @a[ 1 .. $#a ] ], $nonint, $CTX->{host} );
                return ( 'sudo-deny', $why ) if defined $why;
            }
        }
        $AS_USER = $target // 'root';
    }
    return @a;
}

# Verzeichnisse, die "ls /" auf jedem Debian zeigt (dazu, was im Zustand liegt)
our @ROOT_DIRS = qw( bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var );

# Auf dem simulierten Debian 12 (minimal, nftables) nicht installiert: hier ist
# "command not found" die Wahrheit.
our %NOT_INSTALLED = map { $_ => 1 } qw( iptables ip6tables iptables-save iptables-restore iptables-nft
    iptables-legacy ebtables arptables ifconfig netstat route arp brctl tcpdump traceroute dig nslookup host
    mtr nmap telnet nc netcat ncat curl ufw firewall-cmd vtysh );

# Echte Befehle eines Debian 12, die der Simulator nicht nachbildet: neutrale
# Antwort, Aufruf als Luecke der Simulation (sim_gap) vermerkt.
our %REAL = map { $_ => 1 } qw( xargs column less more vi vim nano editor top htop watch ps kill pkill
    pgrep uptime date w who last bridge tc ethtool systemd-resolve networkctl
    hostnamectl apt apt-get mount umount lsblk env od sleep timeout
    setfacl getfacl apachectl php mysql mariadb modprobe lsmod tracepath arping ss-ng ip6 nstat routel
    dhclient ifup ifdown wg-quick-save journalctl-x getent ping6 scp sftp rsync tar gzip
    zcat sha256sum md5sum realpath basename dirname seq yes tput clear
    python3 python node npm npx perl pip pip3 cpanm carton gunicorn uvicorn promtool amtool mysqladmin mysqldump
    openssl flock logger );
our %INTERACTIVE = map { $_ => 1 } qw( less more vi vim nano editor top htop watch );

# Befehle mit Dateiargumenten (fuer relative Pfade nach cd); f: nur die Datei hinter -f
our %FILEARGS = ( ( map { $_ => 1 } qw( cat ls stat rm cp mv chmod chown chgrp touch mkdir find du sed grep egrep head tail wc sort uniq tee ln truncate file diff readlink realpath md5sum sha256sum gzip gunzip zcat ) ),
    kubectl => 'f', helm => 'f' );

# Filter, die auch eine Datei lesen (head -n 3 /etc/x)
our %FILTER = map { $_ => 1 } qw( head tail wc sort uniq cut awk tr fold );

our $DATE_TZ;    # TZ=… vor einem Befehl (wirkt auf date)
our $BIN_MEMO;   # innerhalb eines ls: { bin|sbin => [ namen ] } (_bin_names)
our $LS_TIME;    # innerhalb eines ls: --time-style (full-iso, long-iso, iso)

# Wo die Programme auf dem simulierten Debian 12 liegen (usrmerge): /usr/sbin, sonst /usr/bin.
our %SBIN = map { $_ => 1 } qw( ip nft sysctl sshd usermod userdel useradd groupadd deluser visudo reboot shutdown
    poweroff halt logrotate nginx dhclient modprobe lsmod ifup ifdown ethtool tc bridge conntrack runuser arping
    chpasswd iptables ip6tables ss-ng mariadbd mysqld redis-server
    wg-quick e2fsck resize2fs tune2fs swapon swapoff mkswap mdadm sfdisk sgdisk xfs_growfs
    rndc postconf postfix postmap postalias newaliases postqueue postsuper );
our %BUILTIN = map { $_ => 1 } qw( echo printf true false : cd export type command test [ pwd umask );

my %CMD = (
    which      => sub { _which( 'which', @_ ) },
    whereis    => sub { _which( 'whereis', @_ ) },
    type       => sub { _which( 'type', @_ ) },
    command    => sub { _which( 'command', @_ ) },
    test       => sub { _test_cmd( 'test', @_ ) },
    '['        => sub { _test_cmd( '[', @_ ) },
    ip         => \&_ip,
    wg         => \&_wg,
    'wg-quick' => \&_wgquick,
    nft        => \&_nft,
    sysctl     => \&_sysctl,
    cat        => \&_cat,
    ls         => \&_ls,
    grep       => \&_grep_file,
    egrep      => \&_grep_file,
    sed        => \&_sed,
    echo       => \&_echo,
    printf     => \&_printf,
    systemctl  => \&_systemctl,
    service    => \&_service,
    nmcli      => \&_nmcli,
    ping       => \&_ping,
    hostname   => sub { ( $_[2]{host}, 1 ) },
    uname      => sub { ( "Linux $_[2]{host} 6.1.0-26-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.112-1 x86_64 GNU/Linux", 1 ) },
    whoami     => sub { ( _who(), 1 ) },
    pwd        => sub { ( $CWD_DIR // '/root', 1 ) },
    true       => sub { ( '', 1 ) },
    free       => sub {
        my $h = grep { /\A-[a-z]*h/ } @{ $_[1] };
        return ( $h ? "               total        used        free      shared  buff/cache   available\nMem:           7.8Gi       1.9Gi       3.1Gi        24Mi       2.8Gi       5.6Gi\nSwap:          975Mi          0B       975Mi"
            : "               total        used        free      shared  buff/cache   available\nMem:            7951        1946        3174          24        2867        5741\nSwap:            975           0         975", 1 );
    },
    sleep      => sub { ( '', 1 ) },
    date       => \&_date,
    lsmod      => sub {    # die fuer Netzwerk und Firewall uebliche Auswahl
        my ($dev) = @_;
        my @m = ( [ 'nf_tables', 307200, 1, '' ], [ 'nf_conntrack', 188416, 2, 'nf_nat,nft_ct' ], [ 'nf_nat', 57344, 1, 'nft_chain_nat' ],
            [ 'nft_ct', 24576, 1, '' ], [ 'nft_chain_nat', 16384, 1, '' ], [ 'nfnetlink', 20480, 2, 'nf_tables' ] );
        push @m, [ 'wireguard', 110592, 0, '' ], [ 'udp_tunnel', 28672, 1, 'wireguard' ] if %{ $dev->{wg} || {} };
        return ( join( "\n", sprintf( '%-24s %8s  %s', 'Module', 'Size', 'Used by' ), map { sprintf( '%-24s %8d  %d %s', @$_ ) } @m ), 1 );
    },
    ps         => \&_ps,
    base64     => \&_base64,
    od         => \&_od,
    flock      => \&_flock,
    nc         => \&_nc,
    netcat     => \&_nc,
    ncat       => \&_nc,
    curl       => \&_curl,
    env        => \&_env,
    last       => \&_last,
    uptime     => \&_uptime,
    lastlog    => \&_lastlog,
    pgrep      => \&_pgrep,
    false      => sub { ( '', 0 ) },
    journalctl => \&_journalctl,
    'systemd-analyze' => \&_systemd_analyze,
    timedatectl => \&_timedatectl,
    file        => \&_file_cmd,
    dpkg        => \&_dpkg,
    logrotate   => sub { _part('Logrotate'); Langertha::Holmgang::Sim::Linux::Logrotate::run(@_) },
    bash        => \&_shell_c,
    sh          => \&_shell_c,
    df         => \&_df,
    du         => \&_du,
    stat       => \&_stat,
    chmod      => \&_chmod,
    chown      => \&_chown,
    chgrp      => sub { _chown( @_[ 0 .. 3 ], 1 ) },
    rm         => \&_rm,
    truncate   => \&_truncate,
    touch      => \&_touch,
    find       => \&_find,
    lsof       => \&_lsof,
    id         => \&_id,
    groups     => \&_groups_cmd,
    usermod    => \&_usermod,
    namei      => \&_namei,
    useradd    => sub { _useradd( 'useradd', @_ ) },
    groupadd   => sub { _groupadd( 'groupadd', @_ ) },
    adduser    => sub { _useradd( 'adduser', @_ ) },
    addgroup   => sub { _groupadd( 'addgroup', @_ ) },
    install    => \&_install,
    gpasswd    => \&_gpasswd,
    passwd     => sub { _acc()->can('passwd')->(@_) },
    chage      => sub { _acc()->can('chage')->(@_) },
    deluser    => sub { _acc()->can('deluser')->(@_) },
    userdel    => sub { _acc()->can('userdel')->(@_) },
    visudo     => sub { _acc()->can('visudo')->(@_) },
    'sudo-list' => sub { _acc()->can('sudo_list')->( $_[0], $_[1][0], $_[2]{host} ) },
    'sudo-deny' => sub { ( $_[1][0], 0 ) },
    crontab    => \&_crontab,
    getfacl    => \&_getfacl,
    'redis-server' => sub { _redis_cmd( 'server', @_ ) },
    pkill      => \&_pkill,
    kill       => \&_kill,
    sshd       => \&_sshd,
    xargs      => \&_xargs,
    file       => \&_file_cmd,
    who        => \&_who_cmd,
    printenv   => \&_env,
    dpkg       => \&_dpkg,
    'dpkg-query' => \&_dpkg,
    'ssh-keygen' => sub {
        my ( $o, $k ) = _keygen( $_[0], $_[1], $_[2]{host} );
        return ( $o, $k ) if defined $o;
        ( $o, $k ) = _sshd_sim()->can('ssh_keygen')->( $_[0], $_[1], $_[2]{host} );
        return ( $o, $k ) if defined $o;
        push @GAPS, join( ' ', 'ssh-keygen', @{ $_[1] } );
        return ( '', 0 );
    },
    getent     => \&_getent,
    resolvectl => \&_resolvectl,
    ln         => \&_ln,
    readlink   => \&_readlink,
    diff       => \&_diff,
    ssh        => \&_ssh,
    nginx      => \&_nginx,
    wget       => \&_wget,
    cmp        => \&_cmp,
    mount      => \&_mount_cmd,
    mkdir      => \&_mkdir,
    cp         => \&_cp,
    mv         => \&_mv,
    ':'        => sub { ( '', 1 ) },
    dmesg      => sub { ( '', 1 ) },
    conntrack  => \&_conntrack,
    reboot     => \&_reboot,
    shutdown   => \&_reboot,
    poweroff   => \&_reboot,
    halt       => \&_reboot,
    ss         => \&_ss,
    psql          => \&_psql,
    kubectl       => \&_kubectl,
    'redis-cli'   => \&_redis_cli,
    promtool      => sub { _mon( 'promtool', @_ ) },
    amtool        => sub { _mon( 'amtool', @_ ) },
    mysql         => sub { _mysql_client( 'mysql', @_ ) },
    mariadb       => sub { _mysql_client( 'mariadb', @_ ) },
    mysqladmin    => sub { _mysql_client( 'mysqladmin', @_ ) },
    'mariadb-admin' => sub { _mysql_client( 'mariadb-admin', @_ ) },
    helm          => \&_helm,
    git           => \&_git,
    docker        => \&_docker,
    openssl       => sub { return _openssl(@_) if $_[0]{kubernetes}; push @GAPS, join( ' ', 'openssl', @{ $_[1] } ); return ( '', 0 ) },
    gunzip        => sub { _gzip( 'gunzip', @_ ) },
    zcat          => sub { _gzip( 'zcat', @_ ) },
    seq           => sub {
        my @n = grep {/\A-?\d+\z/} @{ $_[1] };
        return ( 'seq: missing operand', 0 ) unless @n;
        my ( $f, $s, $l ) = @n == 1 ? ( 1, 1, $n[0] ) : @n == 2 ? ( $n[0], 1, $n[1] ) : @n[ 0 .. 2 ];
        return ( '', 1 ) unless $s;
        my @o;
        for ( my $i = $f; $s > 0 ? $i <= $l : $i >= $l; $i += $s ) { push @o, $i; last if @o > 10000 }
        return ( join( "\n", @o ), 1 );
    },
    'forgejo-runner' => sub {
        my ( $dev, $av, $ctx ) = @_;
        _part('Git');
        local @Langertha::Holmgang::Sim::Linux::Git::GAPS;
        my ( $o, $ok ) = Langertha::Holmgang::Sim::Linux::Git::runner( $dev, $av, $ctx, $CWD_DIR, $AS_USER );
        push @GAPS, @Langertha::Holmgang::Sim::Linux::Git::GAPS;
        return ( $o, $ok );
    },
    pg_lsclusters => sub { _pg()->can('pg_lsclusters')->(@_) },
    pg_ctlcluster => \&_pg_ctlcluster,
    su            => \&_su,
    runuser       => \&_su,
    # BIND und Postfix: nur, wo installiert
    rndc              => _ext( 'Dns',     'rndc',      ['bind'] ),
    'named-checkconf' => _ext( 'Dns',     'checkconf', ['bind'] ),
    'named-checkzone' => _ext( 'Dns',     'checkzone', ['bind'] ),
    dig               => _ext( 'Dns',     'dig',       [ 'bind', 'dnsutils' ] ),
    host              => _ext( 'Dns',     'host',      [ 'bind', 'dnsutils' ] ),
    postconf          => _ext( 'Postfix', 'postconf',  ['postfix'] ),
    postfix           => _ext( 'Postfix', 'postfix',   ['postfix'] ),
    postmap           => _ext( 'Postfix', 'postmap',   ['postfix'] ),
    postalias         => _ext( 'Postfix', 'postmap',   ['postfix'], prog => 'postalias' ),
    newaliases        => _ext( 'Postfix', 'postmap',   ['postfix'], prog => 'newaliases' ),
    postqueue         => _ext( 'Postfix', 'postqueue', ['postfix'] ),
    mailq             => _ext( 'Postfix', 'postqueue', ['postfix'], pre => ['-p'] ),
    postsuper         => _ext( 'Postfix', 'postsuper', ['postfix'] ),
    postcat           => _ext( 'Postfix', 'postcat',   ['postfix'] ),
    # Sichern und Wiederherstellen; restic nur, wo installiert
    tar               => _ext( 'Backup', 'tar',       [] ),
    rsync             => _ext( 'Backup', 'rsync',     [] ),
    sha256sum         => do { my $x = _ext( 'Backup', 'sha256sum', [] ); sub { ( grep { !/\A-/ } @{ $_[1] } ) ? $x->(@_) : _digest( 'sha256', @_ ) } },    # ohne Datei: stdin
    md5sum            => \&_md5sum,
    basename          => sub {    # basename name [suffix] | -s suffix | -a name …
        my ( $d, $a ) = @_;
        my @a = @$a;
        my ( $suf, $multi );
        while ( @a && $a[0] =~ /\A-/ ) { my $x = shift @a; if ( $x eq '-s' ) { $suf = shift @a; $multi = 1 } elsif ( $x eq '-a' ) { $multi = 1 } }
        return ( 'basename: missing operand', 0 ) unless @a;
        ( $suf, @a ) = ( $a[1], $a[0] ) unless $multi;
        return ( join( "\n", map { my $b = $_ =~ s{/+\z}{}r =~ s{.*/}{}r; $b = '/' if $b eq '' && /\A\//; $b =~ s/\Q$suf\E\z// if defined $suf && $b ne $suf; $b } @a ), 1 );
    },
    dirname => sub {
        my ( $d, $a ) = @_;
        my @n = grep { !/\A-/ } @$a or return ( 'dirname: missing operand', 0 );
        return ( join( "\n", map { my $x = s{/+\z}{}r; $x =~ m{/} ? ( $x =~ s{/+[^/]*\z}{}r || '/' ) : '.' } @n ), 1 );
    },
    gzip              => do {
        my $file = _ext( 'Backup', 'gzip', [] );
        sub { my @x = @_; return _gzip( 'gzip', @x ) if !grep( { !/\A-/ } @{ $x[1] } ) && grep( { /\A-[a-z]*d|\A--decompress\z/ } @{ $x[1] } ); return $file->(@x) };
    },
    restic            => _ext( 'Backup', 'restic',    [ 'restic', 'restic_repos' ] ),
    cd                => \&_cd,
    xargs             => \&_xargs,
    timeout           => sub {    # timeout [-s SIG] DAUER befehl …: der Befehl laeuft (die Simulation wartet nie)
        my ( $d, $a, $c, $in ) = @_;
        my @w = @$a;
        shift @w while @w && $w[0] =~ /\A-/ && ( $w[0] !~ /\A-[sk]\z/ || shift @w );
        my $dur = shift @w;
        return ( "timeout: invalid time interval '" . ( $dur // '' ) . "'", 0 ) unless defined $dur && $dur =~ /\A\d+(?:\.\d+)?[smhd]?\z/;
        return ( 'timeout: missing operand', 0 ) unless @w;
        local $IN_TIMEOUT = 1;    # eine haengende Verbindung endet mit 124 statt einer Meldung
        return __PACKAGE__->_command( $d, \@w, $c, $in );
    },
    # Platten und Dateisysteme: nur mit storage im Zustand,
    # sonst wie bisher eine Luecke der Simulation
    ( map { $_->[0] => _ext( 'Storage', $_->[1], ['storage'], prog => $_->[0], gap => 1, ( $_->[0] eq 'mount' ? ( else => \&_mount_cmd ) : $_->[0] eq 'lsblk' ? ( else => \&_lsblk_basic ) : $_->[0] eq 'free' ? ( else => \&_free_mem ) : () ) ) }
        [ lsblk => 'lsblk' ], [ blkid => 'blkid' ], [ findmnt => 'findmnt' ], [ mount => 'mount' ], [ umount => 'umount' ],
        ( map { [ $_ => 'lvm' ] } qw( pvs vgs lvs pvdisplay vgdisplay lvdisplay pvcreate vgextend lvcreate lvextend lvresize ) ),
        [ resize2fs => 'resize2fs' ], [ xfs_growfs => 'xfs_growfs' ],
        ( map { [ $_ => 'mkfs' ] } qw( mkfs mkfs.ext4 mkfs.ext3 mkfs.xfs ) ), [ tune2fs => 'tune2fs' ],
        ( map { [ $_ => 'fsck' ] } qw( e2fsck fsck fsck.ext4 ) ),
        ( map { [ $_ => 'swap' ] } qw( mkswap swapon swapoff fallocate dd free ) ),
        ( map { [ $_ => 'part' ] } qw( sfdisk sgdisk growpart partprobe fdisk ) ), [ mdadm => 'mdadm' ] ),
);

# Ein Shell-Skript in einer neuen Shell (Argumente $1 …); Variablen, if, for, while, case
# wie bash (Sim::Shell); Funktionen und Subshells bleiben eine Luecke der Simulation.
sub _script {
    my ( $dev, $text, $ctx, $what, $arg0, @args ) = @_;
    return _run_shell( $dev, $text, $ctx, arg0 => $arg0, args => \@args );
}

# who: die eigene Sitzung (ssh_login des Geraets)
sub _who_cmd {
    my ($dev) = @_;
    my $l = $dev->{ssh_login} || {};
    return ( sprintf( '%-8s pts/0        2026-10-21 11:52 (%s)', $l->{user} // 'root', $l->{from} // '10.1.0.50' ), 1 );
}

sub _ssh_access { return _part('SshAccess') }

# ssh [-o …] [-p port] [-l user] [user@]host [befehl] — nur auf das Geraet selbst nachgebildet:
# Anmeldung gegen die geladene sshd-Konfiguration, ohne Schluessel (root hat keinen fuer andere Konten)
sub _ssh_client {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my ( $port, $user, $target );
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-[oiFlpJcmbeEDLRW]\z/ ) { my $v = shift @a; $port = $v if $x eq '-p'; $user = $v if $x eq '-l' }
        elsif ( $x =~ /\A-o(.+)\z/ ) { }
        elsif ( $x =~ /\A-p(\d+)\z/ ) { $port = $1 }
        elsif ( $x =~ /\A-[46AaCfGgKkMNnqsTtVvXxYy]+\z/ ) { return ( 'OpenSSH_9.2p1 Debian-2+deb12u3, OpenSSL 3.0.15 3 Sep 2024', 1 ) if $x =~ /V/ }
        else { $target = $x; last }
    }
    return ( 'usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface] [-b bind_address] destination [command [argument ...]]', 0 ) unless defined $target;
    my ( $u, $h ) = $target =~ /\A(?:([^@]+)@)?(.+)\z/;
    $user //= $u // ( $LOGIN_USER // 'root' );
    my $me = $ctx->{host} // '';
    my %own = map { $_ => 1 } _own_addrs($dev), 'localhost', $me;
    if ( !$own{$h} ) {
        return ( "ssh: Could not resolve hostname $h: Name or service not known", 0 ) unless $h =~ /\A[\d.]+\z|:/;
        push @GAPS, join( ' ', 'ssh', @$av );
        return ( "ssh: connect to host $h port " . ( $port // 22 ) . ': Connection timed out', 0 );
    }
    my $from = $h =~ /:/ ? '::1' : $h =~ /\A[\d.]+\z/ && $h ne '127.0.0.1' ? $h : '127.0.0.1';
    my ( $ok, $msg ) = _ssh_access()->can('check')->( $dev, { user => $user, from => $from, port => $port // 22, key => '' }, $h );
    return ( $msg, 0 ) unless $ok;
    return ( "$user\@$h: Permission denied (publickey).", 0 );
}

# ssh-keygen: -l -f datei (je Schluessel eine Zeile, auch authorized_keys), -t … -f pfad (Paar), -y -f privat
sub _keygen {
    my ( $dev, $av, $host ) = @_;
    my ( %o, $file, $type, $comment );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-f' ) { $file = shift @a }
        elsif ( $x eq '-t' ) { $type = shift @a }
        elsif ( $x eq '-C' ) { $comment = shift @a }
        elsif ( $x =~ /\A-[NEbZ]\z/ ) { shift @a }
        elsif ( $x =~ /\A-([lyqvf]+)\z/ ) { $o{$_} = 1 for split //, $1; $file = shift @a if $x =~ /f\z/ }
        else  { return undef }
    }
    my $files = $dev->{files} //= {};
    if ( $o{l} && defined $file && !( $file =~ m{/ssh_host_\w+_key(?:\.pub)?\z} ) ) {
        my $t = _file_text( $dev, $file ) // return ( "ssh-keygen: $file: No such file or directory", 0 );
        my @l;
        for my $line ( split /\n/, $t ) {
            next if $line =~ /\A\s*(?:#|\z)/;
            my ( $opts, $kt, $blob ) = _ssh_access()->can('_key_parts')->($line) or next;
            my ($cm) = $line =~ /\Q$blob\E\s+(.*?)\s*\z/;
            my $ty = uc( ( $kt =~ /ssh-(\w+)/ )[0] // 'KEY' );
            push @l, ( $ty eq 'RSA' ? 3072 : 256 ) . ' SHA256:' . substr( $blob, 12, 43 ) . ' ' . ( $cm // 'no comment' ) . " ($ty)";
        }
        return ( "$file is not a public key file.", 0 ) unless @l;
        return ( join( "\n", @l ), 1 );
    }
    if ( defined $type && defined $file ) {
        return ( "unknown key type $type", 0 ) unless $type =~ /\A(?:ed25519|rsa|ecdsa)\z/;
        my $n = unpack( '%32C*', $file . ( $comment // '' ) );
        my $blob = 'AAAAC3NzaC1lZDI1NTE5AAAAI' . substr( join( '', map { ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9 )[ ( $n * 7 + $_ * 13 ) % 62 ] } 1 .. 43 ), 0, 43 ) . '=';
        my $who = $comment // 'root@' . ( $host // 'localhost' );
        $files->{$file} = { content => "-----BEGIN OPENSSH PRIVATE KEY-----\n(simuliert: $blob)\n-----END OPENSSH PRIVATE KEY-----\n", mode => '0600' };
        $files->{"$file.pub"} = { content => "ssh-$type $blob $who\n", mode => '0644' };
        return ( $o{q} ? '' : "Generating public/private $type key pair.\nYour identification has been saved in $file\nYour public key has been saved in $file.pub", 1 );
    }
    if ( $o{y} && defined $file ) {
        my $t = _file_text( $dev, $file ) // return ( "Load key \"$file\": No such file or directory", 0 );
        my ($blob) = $t =~ /\(simuliert: (\S+)\)/ or do { push @GAPS, join( ' ', 'ssh-keygen', @$av ); return ( '', 0 ) };
        my $pub = _file_text( $dev, "$file.pub" ) // "ssh-ed25519 $blob";
        return ( ( split /\n/, $pub )[0], 1 );
    }
    return undef;
}

# xargs [-r] [-n N] [-I X] befehl …: Woerter der Eingabe als Argumente
sub _xargs {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my ( $r, $n, $rep );
    while ( @a && $a[0] =~ /\A-/ ) {
        my $x = shift @a;
        if    ( $x =~ /\A-r|--no-run-if-empty\z/ ) { $r = 1 }
        elsif ( $x eq '-n' ) { $n = shift @a }
        elsif ( $x =~ /\A-n(\d+)\z/ ) { $n = $1 }
        elsif ( $x eq '-I' ) { $rep = shift @a }
        elsif ( $x =~ /\A-I(.+)\z/ ) { $rep = $1 }
    }
    @a = ('echo') unless @a;
    my @w = defined $rep ? grep {length} split /\n/, $stdin // '' : split ' ', $stdin // '';
    return ( '', 1 ) if !@w && ( $r || defined $rep );
    my @sets = defined $rep ? map { [$_] } @w : $n ? do { my @s; push @s, [ splice @w, 0, $n ] while @w; @s } : ( [@w] );
    my ( @o, $ok );
    $ok = 1;
    for my $s (@sets) {
        my @argv = defined $rep ? map { s/\Q$rep\E/$s->[0]/gr } @a : ( @a, @$s );
        my ( $out, $k ) = __PACKAGE__->_command( $dev, \@argv, $ctx, undef );
        push @o, $out if defined $out && length $out;
        $ok = 0 unless $k;
    }
    return ( join( "\n", @o ), $ok );
}

sub _cd {
    my ( $dev, $av ) = @_;
    my ($arg) = grep { !/\A-/ } @$av;
    my $d = !defined $arg || $arg eq '~' ? '/root' : _absp( $arg =~ s{\A~/}{/root/}r );
    $d =~ s{(?<=.)/+\z}{};
    return ( "bash: cd: $arg: No such file or directory", 0 ) unless _is_dir( $dev, $d );
    return ( "bash: cd: $arg: Permission denied", 0 ) unless _traverse_ok( $dev, $d ) && _dir_ok( $dev, $d, 1 );
    $CWD_DIR = $d;
    return ( '', 1 );
}

# Befehl eines Zusatz-Simulators (Sim::<Modul>::<fn>( $dev, \@argv, $ctx, $stdin|$prog ));
# ohne das Paket (Schluessel im Zustand des Geraets) wie Debian: nicht installiert.
sub _ext {
    my ( $mod, $fn, $need, %o ) = @_;
    my $sub;
    $sub = sub {
        my ( $dev, $av, $ctx, $stdin ) = @_;
        unless ( !@$need || grep { $dev->{$_} } @$need ) {
            return $o{else}->(@_) if $o{else};    # ohne Paket: was der Grundsimulator kann
            if ( $o{gap} ) { push @GAPS, join( ' ', $o{prog} // $fn, @$av ); return ( '', 0 ) }
            return ( 'bash: ' . ( $o{name} // $o{prog} // ( $o{pre} ? 'mailq' : $fn =~ s/\Acheck/named-check/r ) ) . ': command not found', 0 );
        }
        my $class = _part($mod);
        return $class->can($fn)->( $dev, [ @{ $o{pre} || [] }, @$av ], { %{ $ctx || {} }, stdin => $stdin }, $o{prog} // $stdin );
    };
    $EXT_NEED{$sub} = $o{gap} ? [] : $need;
    return $sub;
}

sub _pg { return _part('Postgres') }
sub _redis { return _part('Redis') }
sub _maria { return _part('MariaDB') }


sub prepare {
    my ( $class, $dev, $ctx ) = @_;
    local @MISSING;    # a missing part dies here: the case does not load
    _redis()->can('_running')->($dev) if $dev->{redis};
    _maria()->can('_vars')->($dev)    if $dev->{mariadb};
    for ( [ bind => 'Dns' ], [ postfix => 'Postfix' ], [ storage => 'Storage' ] ) {
        my ( $key, $mod ) = @$_;
        next unless $dev->{$key};
        my $c = _part($mod);
        $c->can('prepare')->( $dev, $ctx );
    }
    # Dienste mit mehreren Dateien laufen mit dem, was beim Start in den Dateien stand
    for my $n ( sort keys %{ $dev->{services} || {} } ) {
        my $svc = $dev->{services}{$n};
        $svc->{unit_loaded} = _unit_text( $dev, $n, $svc ) if ( $svc->{unit_loaded} // '' ) eq 'current';
        if ( $svc->{active} && !$svc->{_started} && defined( my $t = $svc->{unit_loaded} // _unit_text( $dev, $n, $svc ) ) ) {
            $svc->{_started} = _unit_props($t);
        }
        next unless ref $svc->{config} eq 'ARRAY' && !defined $svc->{running} && $svc->{active};
        my ( undef, $extra ) = _config_check( $dev, $svc );
        $svc->{running} = { ( map { my $t = _file_text( $dev, $_ ); defined $t ? ( $_ => $t ) : () } @{ $svc->{config} } ), %{ $extra || {} } };
    }
    return;
}

# redis-cli gegen den Redis des Geraets (redis); ohne Redis nicht installiert
sub _redis_cli {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    # ohne den Redis-Zustand (redis): Redis nur aus dem Dienst (Sim::RedisService)
    return _redis_cmd( 'cli', $dev, $av, $ctx ) unless $dev->{redis};
    # -h <Adresse eines anderen Geraets>: dessen Redis antwortet
    my $target = $dev;
    for my $i ( 0 .. $#$av - 1 ) {
        next unless $av->[$i] eq '-h';
        my $h = $av->[ $i + 1 ];
        last if $h =~ /\A(?:127\.|localhost\z)/ || grep { $_ eq $h } _own_addrs($dev);
        my ($other) = grep { ref $_ eq 'HASH' && grep { $_ eq $h } _own_addrs($_) } values %{ $CTX ? $CTX->{state} : {} };
        $target = $other if $other;
        return ( "Could not connect to Redis at $h:6379: Connection refused", 1 ) unless $other && $other->{redis};
        last;
    }
    my $m = _redis();
    no strict 'refs';
    local @{"${m}::GAPS"};
    my ( $o, $ok ) = $m->can('redis_cli')->( $target, $av, $ctx, $stdin );
    push @GAPS, @{"${m}::GAPS"};
    return ( $o, $ok );
}

# promtool/amtool (Sim::Monitoring)
sub _mon {
    my ( $prog, $dev, $av, $ctx ) = @_;
    _part('Monitoring');
    my $m = 'Langertha::Holmgang::Sim::Linux::Monitoring';
    no strict 'refs';
    local @{"${m}::GAPS"};
    my ( $o, $ok ) = $m->can($prog)->( $dev, $av );
    push @GAPS, @{"${m}::GAPS"};
    return ( $o, $ok );
}

# mysql/mariadb/mysqladmin gegen den MariaDB-Server des Geraets (mariadb)
sub _mysql_client {
    my ( $prog, $dev, $av, $ctx, $stdin ) = @_;
    if ( !$dev->{mariadb} ) { push @GAPS, join( ' ', $prog, @$av ); return ( '', 0 ) }
    my $m = _maria();
    no strict 'refs';
    local @{"${m}::GAPS"};
    my ( $o, $ok ) = $prog =~ /admin/
        ? $m->can('mysqladmin')->( $dev, $av, $ctx, $AS_USER // 'root' )
        : $m->can('client')->( $dev, $av, $ctx, $stdin, $AS_USER // 'root', $prog );
    push @GAPS, @{"${m}::GAPS"};
    return ( $o, $ok );
}

# Datenbankdienste: Konfigurationsfehler verhindern den Start (Journalzeilen) oder undef
sub _app_conf_error {
    my ( $dev, $n ) = @_;
    my $svc = ( $dev->{services} || {} )->{$n} || {};
    if ( $svc->{config_check} ) { my ($e) = _config_check( $dev, $svc ); return $e if @$e }
    my ( $lines, $exe );
    if ( $dev->{redis} && $n eq ( $dev->{redis}{service} // 'redis-server' ) ) { $lines = _redis()->can('conf_error')->($dev); $exe = 'redis-server' }
    elsif ( $dev->{mariadb} && $n eq ( $dev->{mariadb}{service} // 'mariadb' ) ) { $lines = _maria()->can('conf_error')->($dev); $exe = 'mariadbd' }
    return undef unless $lines;
    return [ map { "$exe\[" . ( 50000 + ( $dev->{_tick} // 0 ) ) . "]: $_" } @$lines ];
}

# Pruefung der Konfiguration eines Dienstes (config_check: prometheus|alertmanager):
# ( [ Journalzeilen bei Fehler ], { nachgeladene Datei => Text } )
sub _config_check {
    my ( $dev, $svc ) = @_;
    my $kind = $svc->{config_check} or return ( [], {} );
    _part('Monitoring');
    my ( $err, $extra ) = Langertha::Holmgang::Sim::Linux::Monitoring::service_check( $dev, $svc, $kind );
    my $pid = 50000 + ( $dev->{_tick} // 0 );
    return ( [ map { ( $svc->{exec} // $kind ) . "[$pid]: $_" } @$err ], $extra || {} );
}

# Datenbankdienste: Wirkung von Start, Neustart, Stopp
sub _app_event {
    my ( $dev, $n, $verb ) = @_;
    if ( $dev->{redis} && $n eq ( $dev->{redis}{service} // 'redis-server' ) ) {
        _redis()->can('service_event')->( $dev, $verb, $CTX ? $CTX->{state} : {} );
    }
    if ( $dev->{mariadb} && $n eq ( $dev->{mariadb}{service} // 'mariadb' ) ) { _maria()->can('service_event')->( $dev, $verb ) }
    return;
}

sub _acc { return _part('Accounts') }
sub _sshd_sim { return _part('Sshd') }

sub _sshd {
    my ( $dev, $av ) = @_;
    return ( "sshd: no hostkeys available -- exiting.", 0 ) unless _sshd_sim()->can('active')->($dev);
    # sshd -T -C user=…,addr=…[,host=…,laddr=…,lport=…]: Match-Abschnitte fuer diese Verbindung
    my @a = @$av;
    my ($ci) = map { $a[ $_ + 1 ] } grep { $a[$_] eq '-C' } 0 .. $#a - 1;
    my ( $out, $ok ) = _sshd_sim()->can('sshd')->( $dev, $av );
    return ( $out, $ok ) unless $ok && defined $ci && grep { /\A-[a-zA-Z]*T/ } @a;
    my %c = map { /\A(\w+)=(.*)\z/ ? ( lc $1 => $2 ) : () } split /,/, $ci;
    return ( "sshd: Invalid test mode specification $ci", 0 ) unless defined $c{user} || defined $c{addr};
    my $u = ( $dev->{users} || {} )->{ $c{user} // '' } || {};
    my $over = _ssh_access()->can('match_overrides')->( $dev,
        { user => $c{user} // '', from => $c{addr}, groups => [ @{ $u->{groups} || [] } ], port => $c{lport} // 22 }, 1 );
    return ( $out, 1 ) unless %$over;
    my @l = grep { my ($k) = /\A(\S+)/; !exists $over->{ $k // '' } } split /\n/, $out;
    for my $k ( sort keys %$over ) {
        my $v = $over->{$k};
        push @l, map {"$k $_"} ref $v ? @$v : ( $k =~ /\A(?:passwordauthentication|pubkeyauthentication|permitrootlogin|strictmodes)\z/ ? lc $v : $v );
    }
    return ( join( "\n", @l ), 1 );
}

sub _psql {
    my ( $dev, $av, $ctx ) = @_;
    my $pg = _pg();
    no strict 'refs';
    local @{"${pg}::GAPS"};
    my ( $o, $ok ) = $pg->can('psql')->( $dev, $av, $ctx, $AS_USER // 'root' );
    push @GAPS, @{"${pg}::GAPS"};
    return ( $o, $ok );
}

# kubectl gegen den Cluster im Zustand des Geraets (kubernetes)
sub _kubectl {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    _part('Kubernetes');
    local @Langertha::Holmgang::Sim::Linux::Kubernetes::GAPS;
    my ( $o, $ok ) = Langertha::Holmgang::Sim::Linux::Kubernetes::kubectl( $dev, $av, $ctx, $stdin );
    push @GAPS, @Langertha::Holmgang::Sim::Linux::Kubernetes::GAPS;
    return ( $o, $ok );
}

# openssl x509 (Pseudo-PEM der Simulation), s_client ueber den Ingress eines simulierten Clusters
sub _openssl {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my $verb = shift(@a) // '';
    _part('Kubernetes');
    if ( $verb eq 'x509' ) {
        my $in;
        for my $i ( 0 .. $#a ) { $in = $a[ $i + 1 ] if $a[$i] eq '-in' }
        my $pem = defined $in ? _file_text( $dev, $in ) : $stdin;
        return ( "Could not open file or uri for loading certificate from $in", 0 ) unless defined $pem;
        return Langertha::Holmgang::Sim::Linux::Kubernetes::x509( $pem, \@a );
    }
    if ( $verb eq 's_client' ) {
        my ( $conn, $sni );
        for my $i ( 0 .. $#a ) { $conn = $a[ $i + 1 ] if $a[$i] eq '-connect'; $sni = $a[ $i + 1 ] if $a[$i] eq '-servername' }
        my ($h) = ( $conn // '' ) =~ /\A([^:]+)/;
        return ( "s_client: -connect requires an argument", 0 ) unless defined $h;
        return ( "4087F6B7A57F0000:error:8000006F:system library:BIO_connect:Connection refused", 0 ) unless $dev->{kubernetes};
        return Langertha::Holmgang::Sim::Linux::Kubernetes::tls_probe( $dev->{kubernetes}, $h, $sni );
    }
    return ( 'OpenSSL 3.0.15 3 Sep 2024 (Library: OpenSSL 3.0.15 3 Sep 2024)', 1 ) if $verb eq 'version';
    push @GAPS, "openssl $verb";
    return ( '', 0 );
}

# docker (nur, wo es einen Socket gibt): Zugriff wie echt ueber Rechte am Socket
sub _docker {
    my ( $dev, $av ) = @_;
    my $sock = '/var/run/docker.sock';
    return ( 'bash: docker: command not found', 0 ) unless _file_entry( $dev, $sock );
    my $user = $AS_USER // 'root';
    my ($verb) = grep { !/\A-/ } @$av;
    $verb //= '';
    return ( "Docker version 26.1.5+dfsg1, build a72d7cd", 1 ) if $verb eq '' && grep { $_ eq '--version' || $_ eq '-v' } @$av;
    return ( "permission denied while trying to connect to the Docker daemon socket at unix://$sock: Get \"http://%2Fvar%2Frun%2Fdocker.sock/v1.45/$verb\": dial unix $sock: connect: permission denied", 0 )
        unless _can( $dev, $user, $sock, 'w' );
    return ( 'Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?', 0 ) unless ( ( $dev->{services} || {} )->{docker} || {} )->{active};
    return ( 'CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES', 1 ) if $verb eq 'ps';
    return ( 'REPOSITORY   TAG       IMAGE ID   CREATED   SIZE', 1 ) if $verb eq 'images';
    return ( "Client: Docker Engine - Community\n Version:    26.1.5\n\nServer:\n Containers: 0\n Images: 0\n Server Version: 26.1.5\n Storage Driver: overlay2\n Cgroup Driver: systemd", 1 ) if $verb eq 'info';
    return ( "Client:\n Version:           26.1.5\n API version:       1.45\n\nServer:\n Engine:\n  Version:          26.1.5\n  API version:      1.45 (minimum version 1.24)", 1 ) if $verb eq 'version';
    my @p = grep { !/\A-/ } @$av;
    if ( $verb eq 'pull' && @p >= 2 ) {    # Registry erreichbar: Bild laedt
        ( my $img = $p[1] ) =~ s/\A(?![\w.-]+\.[\w-]+\/)/docker.io\/library\//;
        $img .= ':latest' unless $p[1] =~ /:[\w.-]+\z/;
        ( my $tag = $img ) =~ s/.*://;
        return ( "$tag: Pulling from " . ( $img =~ s/:[^:]+\z//r =~ s{\Adocker\.io/}{}r ) . "\nDigest: sha256:3f1b2c0e5d6a7b8c9d0e1f2a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e\nStatus: Downloaded newer image for $img\n$img", 1 );
    }
    if ( $verb eq 'run' && grep { $_ eq 'hello-world' } @p ) {
        return ( "Unable to find image 'hello-world:latest' locally\nlatest: Pulling from library/hello-world\nStatus: Downloaded newer image for hello-world:latest\n\nHello from Docker!\nThis message shows that your installation appears to be working correctly.", 1 );
    }
    push @GAPS, "docker @$av";
    return ( '', 0 );
}

# git auf den Arbeitskopien des Geraets (git.repos), Server ueber den Zustand
sub _git {
    my ( $dev, $av, $ctx ) = @_;
    _part('Git');
    local @Langertha::Holmgang::Sim::Linux::Git::GAPS;
    my ( $o, $ok ) = Langertha::Holmgang::Sim::Linux::Git::git( $dev, $av, $ctx, $CWD_DIR );
    push @GAPS, @Langertha::Holmgang::Sim::Linux::Git::GAPS;
    return ( $o, $ok );
}

# helm gegen den Cluster im Zustand des Geraets (kubernetes.helm)
sub _helm {
    my ( $dev, $av, $ctx ) = @_;
    _part('Helm');
    local @Langertha::Holmgang::Sim::Linux::Helm::GAPS;
    my ( $o, $ok ) = Langertha::Holmgang::Sim::Linux::Helm::helm( $dev, $av, $ctx );
    push @GAPS, @Langertha::Holmgang::Sim::Linux::Helm::GAPS;
    return ( $o, $ok );
}

# pg_ctlcluster 15 main reload -> systemctl reload postgresql@15-main
sub _pg_ctlcluster {
    my ( $dev, $av, $ctx ) = @_;
    my @a = grep { !/\A-/ } @$av;
    return ( 'Usage: /usr/bin/pg_ctlcluster <version> <cluster> <action> [-- <pg_ctl options>]', 0 ) unless @a >= 3;
    my ( $ver, $name, $verb ) = @a;
    my $pg = $dev->{postgres};
    return ( "Error: specified cluster $ver/$name does not exist", 0 ) unless $pg && ( $pg->{cluster} // '' ) eq "$ver/$name";
    return _systemctl( $dev, [ $verb eq 'status' ? 'status' : $verb, $pg->{service} ], $ctx )
        if $verb =~ /\A(?:start|stop|restart|reload|status)\z/;
    return ( "Error: Invalid action $verb", 0 );
}

# su [-|-l] benutzer -c 'befehl'  /  runuser -u benutzer -- befehl


sub _su {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my ( $user, $cmd );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-' || $x eq '-l' || $x eq '--login' ) { next }
        elsif ( $x eq '-c' || $x eq '--command' ) { $cmd = shift @a }
        elsif ( $x eq '-u' ) { $user = shift @a }
        elsif ( $x eq '--' ) { $cmd = join ' ', map { /[\s'"]/ ? "'$_'" : $_ } @a; last }
        elsif ( $x eq '-s' ) { shift @a }
        elsif ( !defined $user ) { $user = $x }
    }
    $user //= 'root';
    return ( "su: user $user does not exist or the user entry does not contain all the required fields", 0 )
        unless $user eq 'root' || $user eq 'postgres' || ( $dev->{users} || {} )->{$user};
    # su ohne -s startet die Shell des Kontos: nologin/false lehnen ab (runuser -u nicht)
    my $ushell = ( ( $dev->{users} || {} )->{$user} || {} )->{shell} // '';
    if ( !grep( { $_ eq '-s' || $_ eq '--shell' || $_ eq '-u' } @$av ) && $ushell =~ m{/(?:nologin|false)\z} ) {
        return ( $ushell =~ /nologin/ ? 'This account is currently not available.' : '', 0 );
    }
    if ( !defined $cmd ) { push @GAPS, 'su (interaktiv)'; return ( '', 0 ) }
    local $LOGIN_USER = $user;
    my ( $o, $ok, $gap ) = __PACKAGE__->_run_inner( $dev, $cmd, $ctx );
    push @GAPS, $gap if defined $gap;
    return ( $o, $ok );
}

sub _command {
    my ( $class, $dev, $argv, $ctx, $stdin ) = @_;
    local $AS_USER = $LOGIN_USER;
    my @a = _strip_sudo(@$argv);
    return ( '', 1 ) unless @a;
    my $cmd = shift @a;
    # NAME=wert befehl …: Umgebung nur fuer diesen Befehl
    local $SHENV = { %{ $SHENV || {} } };
    my %env;
    while ( $cmd =~ /\A([A-Za-z_]\w*)=(.*)\z/s && @a ) { $SHENV->{$1} = $env{$1} = $2; $cmd = shift @a }
    # TZ=… wirkt auf date
    local $DATE_TZ = exists $env{TZ} ? ( $env{TZ} =~ s/\A://r ) : $DATE_TZ;
    # nach cd: relative Pfade (die es gibt oder die ein Muster sind) gelten im aktuellen Verzeichnis
    if ( defined $CWD_DIR && $cmd !~ /\A(?:cd|tar|rsync|restic|echo|printf|basename|dirname|expr|test|\[|wc|ls|ln)\z/ ) {    # diese loesen selbst relativ auf bzw. geben nur Text aus
        @a = map {
            my $x = $_;
            $x !~ m{\A[-/]} && $x =~ m{\A[\w.@+][\w./@+*?\[\]!-]*\z}
                && ( _file_entry( $dev, _absp($x) ) || _is_dir( $dev, _absp($x) ) ) ? _absp($x) : $x
        } @a;
    }
    if ( $cmd =~ /\A[A-Za-z_]\w*=/ ) {    # Zuweisung ohne Befehl: Shell-Variablen sind nicht nachgebildet
        push @GAPS, join( ' ', $cmd, @a );
        return ( '', 0 );
    }
    # Skripte: bash|sh -c '…', bash|sh datei, ./datei bzw. /pfad/datei (ausfuehrbar)
    ( my $sh = $cmd ) =~ s{\A/(?:usr/)?bin/}{};
    local $LOGIN_USER = defined $AS_USER && ( $sh eq 'bash' || $sh eq 'sh' || $cmd =~ m{/} ) ? $AS_USER : $LOGIN_USER;
    if ( $sh eq 'bash' || $sh eq 'sh' ) {
        my $e;
        my $noexec;
        while ( @a && $a[0] =~ /\A-([euxon]+)\z/ ) { my $f = $1; $e = 1 if $f =~ /e/; $noexec = 1 if $f =~ /n/; shift @a; shift @a if $f =~ /o/ }
        if ($noexec) {    # bash -n: nur lesen und zerlegen
            my $t = @a && $a[0] eq '-c' ? $a[1] : @a ? _file_text( $dev, _absp( $a[0] ) ) : $stdin;
            return ( "$sh: $a[0]: No such file or directory", 0 ) if @a && $a[0] ne '-c' && !defined $t;
            my @it = eval { Langertha::Holmgang::Shell::split_items( $t // '' ) };
            my $err = $@;
            my $nodes = $err ? undef : Langertha::Holmgang::Shell::parse( \@it );
            $err ||= ref $nodes ? '' : $nodes;
            $err =~ s/\s+\z//;
            return ( length $err ? ( @a && $a[0] ne '-c' ? "$a[0]: " : '' ) . $err : '', length $err ? 0 : 1 );
        }
        if ( @a && $a[0] eq '-c' ) {
            my ( undef, $text, $arg0, @args ) = @a;
            return _run_shell( $dev, $text // q{}, $ctx, arg0 => $arg0 // $sh, args => \@args, errexit => $e );
        }
        my $t = @a ? _file_text( $dev, _absp( $a[0] ) ) : $stdin;
        return ( "$sh: $a[0]: No such file or directory", 0 ) if @a && !defined $t;
        return _run_shell( $dev, $t // q{}, $ctx, arg0 => $a[0] // $sh, args => [ @a[ 1 .. $#a ] ], errexit => $e );
    }
    # curl/wget gegen die HTTP-API eines Forgejo-Servers: auf dem Server selbst (localhost:3000 bzw. der
    # eigene Name), von anderen Geraeten ueber den oeffentlichen Namen (ROOT_URL, hinter dem Proxy)
    my $fsrv = $cmd =~ /\A(?:curl|wget)\z/ && !$dev->{pod} ? _forgejo_for( $dev, \@a ) : undef;
    if ($fsrv) {
        my $self = $fsrv == $dev;
        _part('Git');
        my ($url) = grep {m{\Ahttps?://}} @a;
        return ( $cmd eq 'curl' ? 'curl: (3) URL using bad/illegal format or missing URL' : 'wget: missing URL', 0 ) unless $url;
        my ( $h, $port, $path ) = $url =~ m{\Ahttps?://([^/:]+)(?::(\d+))?(/[^\s]*)?\z};
        ( my $root = $fsrv->{forgejo}{root_url} // '' ) =~ s{\Ahttps?://([^/:]+).*}{$1}s;
        unless ( $self && ( $h =~ /\A(?:127\.0\.0\.1|localhost)\z/ && ( $port // 80 ) == 3000 ) || $h eq $root ) {
            my $hf = ( $dev->{files} || {} )->{'/etc/hosts'} // '';
            $hf = $hf->{content} // '' if ref $hf eq 'HASH';
            return ( $cmd eq 'curl' ? "curl: (6) Could not resolve host: $h" : "wget: unable to resolve host address '$h'", 0 )
                unless $h =~ /\A[\d.]+\z|\Alocalhost\z/ || $hf =~ /^\s*[\d.:a-f]+\s+(?:\S+\s+)*\Q$h\E(?:\s|$)/m;
            return ( $cmd eq 'curl' ? "curl: (7) Failed to connect to $h port " . ( $port // ( $url =~ /\Ahttps/ ? 443 : 80 ) ) . " after 0 ms: Couldn't connect to server" : "wget: can't connect to remote host ($h): Connection refused", 0 );
        }
        $dev = $fsrv;
        my $method = 'GET';
        for my $i ( 0 .. $#a ) { $method = uc $a[ $i + 1 ] if $a[$i] eq '-X' && defined $a[ $i + 1 ]; $method = 'POST' if $a[$i] =~ /\A(?:-d|--data(?:-raw|-binary)?)\z/ && $method eq 'GET' }
        my ( $st, $body ) = Langertha::Holmgang::Sim::Linux::Git::api( $dev, $method, $path // '/' );
        my $fail = grep { /\A-[a-zA-Z]*f[a-zA-Z]*\z|\A--fail\z/ } @a;
        if ( $cmd eq 'wget' ) {
            my $quiet = grep { /\A-[a-zA-Z]*q/ } @a;
            my $hdr = ( grep { /\A-[a-zA-Z]*S\z|\A--server-response\z/ } @a ) ? "  HTTP/1.1 $st " . ( $st == 200 ? 'OK' : $st == 401 ? 'Unauthorized' : $st == 404 ? 'Not Found' : 'Error' ) . "\n  Content-Type: application/json;charset=utf-8\n" : '';
            my ($of) = map { $a[ $_ + 1 ] } grep { $a[$_] =~ /\A-[a-zA-Z]*O\z/ } 0 .. $#a;
            ($of) = map {/\A-[a-zA-Z]*O(.+)\z|\A--output-document=(.+)\z/ ? $1 // $2 : ()} @a unless defined $of;
            my $show = defined $of && $of eq '-' && !grep { $_ eq '--spider' } @a;
            return ( $hdr . ( $quiet ? '' : "--2026-10-20 12:00:00--  $url\n" ) . "wget: server returned error: HTTP/1.1 $st " . ( $st == 401 ? 'Unauthorized' : $st == 404 ? 'Not Found' : 'Error' ), 0 ) if $st != 200;
            return ( $hdr . ( $show ? $body : $quiet ? '' : "--2026-10-20 12:00:00--  $url\nHTTP request sent, awaiting response... 200 OK\nSaving to: '" . ( $of // 'index.html' ) . "'" ), 1 );
        }
        return ( "curl: (22) The requested URL returned error: $st", 0 ) if $fail && $st >= 400;
        my ($w) = map { $a[ $_ + 1 ] } grep { $a[$_] eq '-w' || $a[$_] eq '--write-out' } 0 .. $#a;
        my $out = ( grep { $_ eq '-I' || $_ eq '--head' } @a ) ? "HTTP/1.1 $st\nContent-Type: application/json;charset=utf-8" : $body;
        $out = '' if grep { $_ eq '-o' } @a;
        $out .= ( $w // '' ) =~ s/%\{http_code\}/$st/gr =~ s/\\n/\n/gr if defined $w;
        return ( $out, 1 );
    }
    # im Pod (kubectl exec): Netzwerkzeuge ueber den Cluster, Umgebung des Containers
    if ( my $pod = $dev->{pod} ) {
        _part('Kubernetes');
        my $K = 'Langertha::Holmgang::Sim::Linux::Kubernetes';
        if ( $cmd =~ /\A(?:curl|wget)\z/ || $cmd eq 'openssl' && ( $a[0] // '' ) eq 's_client' ) {
            my ($src) = grep { $_->{name} eq $pod->{name} } $K->can('_pods')->( $dev->{kubernetes}, $pod->{ns} );
            return ( "bash: $cmd: command not found", 0 ) unless $src;
            local @Langertha::Holmgang::Sim::Linux::Kubernetes::GAPS;
            my @r = $K->can('pod_tool')->( $dev->{kubernetes}, $pod->{ns}, $src, [ $cmd, @a ] );
            push @GAPS, @Langertha::Holmgang::Sim::Linux::Kubernetes::GAPS;
            return @r;
        }
        if ( $cmd eq 'env' || $cmd eq 'printenv' ) {
            my %e = ( PATH => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', HOSTNAME => $dev->{hostname}, HOME => '/root', %{ $dev->{env} || {} },
                KUBERNETES_SERVICE_HOST => '10.43.0.1', KUBERNETES_SERVICE_PORT => '443' );
            return @a ? ( join( "\n", map { $e{$_} // () } @a ), ( grep { exists $e{$_} } @a ) ? 1 : 0 ) : ( join( "\n", map {"$_=$e{$_}"} sort keys %e ), 1 );
        }
    }
    # (nur Shell-Skripte mit Inhalt; ein anderes Programm bleibt eine Luecke), auch ueber PATH
    my $web_cmd = _web_cmd( $dev, $cmd );
    my $prog_path = $cmd =~ m{\A\.?/} ? _absp($cmd) : !$web_cmd && !$CMD{$cmd} && !$FILTER{$cmd} && !$REAL{$cmd} ? _prog_file( $dev, $cmd ) : undef;
    if ( defined $prog_path && _shell_script( $dev, $prog_path ) ) {
        return ( "bash: $cmd: Permission denied", 0 ) unless _mode_of( _file_entry( $dev, $prog_path ) ) & 0111;
        return _script( $dev, _file_text( $dev, $prog_path ), $ctx, join( ' ', $cmd, @a ), $cmd, @a );
    }
    if ( $cmd =~ m{/} && !$CMD{$cmd} ) {    # anderes Programm mit Pfad (kein Shell-Skript)
        ( my $abs = $cmd ) =~ s{\A/(s?bin)/}{/usr/$1/};
        my ( $n ) = $abs =~ m{\A/usr/s?bin/([^/]+)\z};
        my ( $p, $k ) = defined $n ? _which( 'which', $dev, [$n] ) : ( '', 0 );
        if ( defined $n && $k && $p eq $abs && !_file_entry( $dev, $cmd ) ) { $cmd = $n }
        else {
            my $e = _file_entry( $dev, _absp($cmd) ) or return ( "bash: $cmd: No such file or directory", 0 );
            return ( "bash: $cmd: Permission denied", 0 ) unless _mode_of($e) & 0111;
            push @GAPS, join( ' ', $cmd, @a );    # Skript/Programm aus dem Zustand: nicht nachgebildet
            return ( '', 0 );
        }
    }
    my $f   = $web_cmd // $CMD{$cmd};
    if ( !$f && !$FILTER{$cmd} && !$REAL{$cmd} && ( my $prog = _prog_file( $dev, $cmd ) ) ) {
        push @GAPS, join( ' ', $prog, @a );    # installiertes Programm ohne Nachbildung
        return ( '', 0 );
    }
    if ( !$f && $FILTER{$cmd} ) {
        # Filter mit Datei-Argument: head -n 5 /etc/x, awk '{print $1}' datei, …
        # relative Dateinamen (ohne cd: unter /root) wie absolute
        my %shown;
        @a = map { !m{\A[-/]} && m{\A[\w.@+][\w./@+-]*\z} && defined _file_text( $dev, _absp($_) ) ? do { $shown{ _absp($_) } = $_; _absp($_) } : $_ } @a;
        my @files = grep { m{\A/} && defined _file_text( $dev, $_ ) } @a;
        # Dateiargumente, die es nicht gibt: Meldung wie coreutils/mawk (Status 1), kein stdin
        my %miss = map { $_ => 'No such file or directory' } grep { $_ ne '-' && !defined _file_text( $dev, _absp($_) ) && !_is_dir( $dev, _absp($_) ) } _filter_files( $cmd, @a );
        # als Benutzer ohne Leserecht (Weg oder Datei): Permission denied
        for my $f (@files) { $miss{$f} = 'Permission denied' unless _read_ok( $dev, $f ) }
        my @rest  = grep { my $x = $_; !grep { $_ eq $x } @files } grep { !$miss{$_} } @a;
        @files = grep { !$miss{$_} } @files;
        my $miss_text = sub {
            my ($p) = @_;
            my $why = $miss{$p};
            $p = $shown{$p} // $p;
            return $cmd eq 'head' || $cmd eq 'tail' ? "$cmd: cannot open '$p' for reading: $why"
                : $cmd eq 'sort' ? "sort: cannot read: $p: $why"
                : $cmd eq 'awk'  ? "awk: cannot open $p ($why)"
                :                  "$cmd: $p: $why";
        };
        if ( %miss && !( $cmd eq 'wc' && @files ) ) {
            my @err = map { $miss_text->($_) } grep { $miss{$_} } @a;
            return ( join( "\n", @err ), 0 ) unless @files;
            my ($t) = Langertha::Holmgang::Shell::Filter::filter_output( join( '', map { _file_text( $dev, $_ ) } @files ), [ $cmd, @rest ] );
            defined $t or do { push @GAPS, join( ' ', $cmd, @a ); return ( '', 0 ) };
            return ( join( "\n", grep {length} $t, @err ), 0 );
        }
        if ( $cmd eq 'wc' && @files ) {    # je Datei mit Namen, bei mehreren eine Summe (wie GNU wc)
            my ( @rows, @sum );
            my %is_file = map { $_ => 1 } @files;
            for my $p ( grep { $is_file{$_} || $miss{$_} } @a ) {    # in der Reihenfolge der Argumente
                if ( $miss{$p} ) { push @rows, \( $miss_text->($p) ); next }
                my ($t) = Langertha::Holmgang::Shell::Filter::filter_output( _file_text( $dev, $p ), [ 'wc', @rest ] );
                defined $t or do { push @GAPS, join( ' ', $cmd, @a ); return ( '', 0 ) };
                my @n = split ' ', $t;
                $sum[$_] += $n[$_] for 0 .. $#n;
                push @rows, [ @n, $shown{$p} // $p ];
            }
            my @num = grep { ref eq 'ARRAY' } @rows;
            push @rows, [ @sum, 'total' ] if @files + keys(%miss) > 1;
            my $w = @files > 1 || @{ $num[0] } > 2 ? length( ( sort { $b <=> $a } map { @$_[ 0 .. $#$_ - 1 ] } grep { ref eq 'ARRAY' } @rows )[0] ) : 0;
            return ( join( "\n", map { my $r = $_; ref $r eq 'SCALAR' ? $$r : join( ' ', ( map { sprintf '%*s', $w, $_ } @$r[ 0 .. $#$r - 1 ] ), $r->[-1] ) } @rows ),
                %miss ? 0 : 1 );
        }
        my $text  = @files ? join( '', map { _file_text( $dev, $_ ) } @files ) : $stdin // '';
        my ( $t, $k ) = Langertha::Holmgang::Shell::Filter::filter_output( $text, [ $cmd, @rest ] );
        $t .= " $files[0]" if defined $t && $cmd eq 'wc' && @files == 1;    # wc -c datei: "123 datei"
        return ( $t, $k ) if defined $t;
        push @GAPS, join( ' ', $cmd, @a );
        return ( '', 0 );
    }
    if ( !$f ) {
        if ( $cmd =~ m{/} ) {    # Programm mit Pfad: gibt es die Datei, laeuft es (Luecke), sonst wie bash
            return ( "bash: $cmd: No such file or directory", 0 ) unless _file_entry( $dev, $cmd );
            push @GAPS, join( ' ', $cmd, @a );
            return ( '', 0 );
        }
        return ( "bash: $cmd: command not found", 0 ) if $NOT_INSTALLED{$cmd} || !$REAL{$cmd};
        # Echter Befehl ohne Simulation: neutrale Antwort, als Luecke vermerkt
        push @GAPS, join( ' ', $cmd, @a );
        return ( 'Error opening terminal: unknown.', 0 ) if $INTERACTIVE{$cmd};
        return ( '', 0 );
    }
    my ( $out, $ok ) = eval { $f->( $dev, \@a, $ctx, $stdin ) };
    if ( my $e = $@ ) {
        $e =~ s/\s+\z//;
        return ( $e, 0 );
    }
    return ( $out // '', $ok );
}

# date: Uhr des Geraets (clock), sonst die Simulationszeit (_sim_now); -d ZEIT; Zone aus TZ=
# (Vorgabe timezone des Geraets bzw. Europe/Berlin). -u zeigt UTC; -d liest auch dann Ortszeit.
sub _date {
    my ( $dev, $av ) = @_;
    require POSIX;
    require Langertha::Holmgang::Sim::Linux::Calendar;
    my $C = 'Langertha::Holmgang::Sim::Linux::Calendar';
    my $tz = $DATE_TZ // ( $dev->{timezone} // 'Europe/Berlin' );
    my ( $utc, $fmt, $when ) = ( 0, '%a %b %e %H:%M:%S %Z %Y' );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-u' || $x eq '--utc' || $x eq '--universal' ) { $utc = 1 }
        elsif ( $x =~ /\A\+(.*)\z/s )                                  { $fmt = $1 }
        elsif ( $x eq '-d' || $x eq '--date' )                         { $when = shift @a // '' }
        elsif ( $x =~ /\A(?:-d|--date=)(.+)\z/s )                      { $when = $1 }
        elsif ( $x eq '-I' || $x =~ /\A--iso-8601(?:=date)?\z/ )       { $fmt = '%Y-%m-%d' }
        elsif ( $x eq '-Iseconds' || $x eq '--iso-8601=seconds' )      { $fmt = '%Y-%m-%dT%H:%M:%S%:z' }
        elsif ( $x eq '-R' || $x eq '--rfc-email' )                    { $fmt = '%a, %d %b %Y %H:%M:%S %z' }
        else { push @GAPS, join( ' ', 'date', @$av ); return ( '', 0 ) }    # -s, -r …
    }
    my $now = defined $dev->{clock} ? do { _part('Monitoring'); Langertha::Holmgang::Sim::Linux::Monitoring::now_epoch($dev) } : _pki_now($dev) // ( %{ $dev->{wg} || {} } ? $Langertha::Holmgang::Sim::Linux::NOW : _sim_now() );    # WireGuard: Zeit der Handshakes
    my $zone = $Langertha::Holmgang::Sim::Linux::Calendar::ZONE{$tz} or return ( POSIX::strftime( '%a %b %e %H:%M:%S UTC %Y', gmtime $now ), 1 );    # unbekannte TZ: UTC wie glibc
    my $t = $now;
    if ( defined $when ) {
        $t = _date_parse( $when, $tz, $C, $now );
        return ( "date: invalid date \x{2018}$when\x{2019}", 0 ) unless defined $t;
    }
    my ( $off, $abbr ) = ( 0, 'UTC' );
    if ( !$utc ) {
        $off = $C->can('offset')->( $t, $tz );
        $abbr = $zone->[1] && $off != $zone->[0] ? $zone->[3] : $zone->[2];
    }
    my $hm = sprintf '%s%02d%02d', $off < 0 ? '-' : '+', abs($off) / 3600, ( abs($off) % 3600 ) / 60;
    $fmt =~ s/%:z/ substr( $hm, 0, 3 ) . ':' . substr( $hm, 3 ) /ge;
    $fmt =~ s/%Z/$abbr/g;
    $fmt =~ s/%z/$hm/g;
    $fmt =~ s/%s/$t/g;
    return ( POSIX::strftime( $fmt, gmtime( $t + $off ) ), 1 );
}

# --- Dateien -----------------------------------------------------------------------

sub _file_text {
    my ( $dev, $path ) = @_;
    return '' if $path eq '/dev/null';
    return _file_text( $dev, _dotdot($path) ) if $path =~ m{\A/.*/\.\.?(?:/|\z)};
    if ( !( ref $dev->{files} eq 'HASH' && exists $dev->{files}{$path} ) && defined( my $r = _via_link( $dev, $path ) ) ) {
        return _file_text( $dev, $r );
    }
    if ( ref $dev->{files} eq 'HASH' && exists $dev->{files}{$path} ) {
        my $e = $dev->{files}{$path};
        return _with_append( $dev, $path, $e ) unless ref $e eq 'HASH';
        if ( defined $e->{link} ) {
            my $t = $e->{link};
            ( my $dir = $path ) =~ s{/[^/]+\z}{};
            $t = "$dir/$t" unless $t =~ m{\A/};
            1 while $t =~ s{/[^/]+/\.\./}{/};
            $t =~ s{/\./}{/}g;
            return _stub_resolv($dev) if $t =~ m{/run/systemd/resolve/stub-resolv\.conf\z} && $dev->{resolved};
            return _file_text( $dev, $t ) unless ( $_[2] // 0 ) > 5;
            return undef;
        }
        return _with_append( $dev, $path, $e->{content} // '' );
    }
    if ( $path =~ m{\A/proc/sys/(.+)\z} ) {
        ( my $k = $1 ) =~ s{/}{.}g;
        return "$dev->{sysctl}{$k}\n" if ref $dev->{sysctl} eq 'HASH' && exists $dev->{sysctl}{$k};
        return undef;
    }
    if ( $path =~ m{\A/etc/wireguard/(wg\d+)\.conf\z} && ref $dev->{wg} eq 'HASH' && $dev->{wg}{$1} ) {
        return _wg_conf( $dev->{wg}{$1} );
    }
    return _nft_conf($dev) if $path eq '/etc/nftables.conf' && ref $dev->{nft} eq 'HASH';
    if ( $path eq '/proc/mdstat' && $dev->{storage} ) { _part('Storage'); return Langertha::Holmgang::Sim::Linux::Storage::mdstat($dev) . "\n" }
    if ( $path eq '/proc/partitions' && $dev->{storage} ) {
        my $d = $dev->{storage}{disks} || {};
        my $i = 0;
        return join( '', "major minor  #blocks  name\n\n",
            map { sprintf "%5d %7d %10d %s\n", 254, $i++, int( _bytes( $d->{$_}{size} ) / 1024 ), s{\A/dev/}{}r } sort keys %$d );
    }
    if ( my $v = _git_virtual( $dev, $path ) ) { return $v->{text} if defined $v->{text} }
    return undef;
}

# .git einer Arbeitskopie bzw. Bare-Repo des Servers (aus dem Git-Zustand abgeleitet)
sub _git_virtual {
    my ( $dev, $path ) = @_;
    return undef unless ( $dev->{git} || $dev->{forgejo} ) && $path =~ m{\.git(?:/|\z)};
    _part('Git');
    return Langertha::Holmgang::Sim::Linux::Git::virtual( $dev, $path =~ s{/+\z}{}r );
}

# Stub-resolv.conf von systemd-resolved
sub _stub_resolv {
    my ($dev) = @_;
    my $r = $dev->{resolved};
    my @dom = grep { !/\A~/ } map { @{ $r->{links}{$_}{domains} || [] } } sort keys %{ $r->{links} || {} };
    return "nameserver 127.0.0.53\noptions edns0 trust-ad\n" . ( @dom ? 'search ' . join( ' ', @dom ) . "\n" : '' );
}

sub _write_path {
    my ( $dev, $path, $text, $append, $ctx ) = @_;
    return ( '', 1 ) if $path eq '/dev/null';
    # > /dev/tcp/HOST/PORT: Verbindung der bash, keine Datei — ohne Netz eine Luecke
    if ( $path =~ m{\A/dev/(?:tcp|udp)/} ) { return _dev_tcp( $dev, $path, '>' ) }
    $path = _absp($path);    # relativ (nach cd) und mit .. wie die Shell
    if ( $path =~ m{\A/proc/sys/(.+)\z} ) {
        ( my $k = $1 ) =~ s{/}{.}g;
        return ( "bash: $path: No such file or directory", 0 )
            unless ref $dev->{sysctl} eq 'HASH' && exists $dev->{sysctl}{$k};
        ( my $v = $text ) =~ s/\s+\z//;
        $dev->{sysctl}{$k} = $v;
        return ( '', 1 );
    }
    my ($dir) = $path =~ m{\A(.*)/[^/]+\z};
    return ( "bash: $path: No such file or directory", 0 ) unless $path =~ m{\A/} && defined $dir;
    return ( "bash: $path: No such file or directory", 0 ) unless _is_dir( $dev, $dir ) || $dir =~ m{\A/(?:etc|root|tmp|var|srv|opt|home|run|usr)\b};
    my $e = _file_entry( $dev, $path );
    if ( my $err = _may_create( $dev, $path ) ) { return ( "bash: $path: $err", 0 ) }
    if ( $e && defined $e->{link} ) {    # Schreiben durch einen Verweis: Verweis wird zur Datei (vereinfacht)
        $dev->{files}{$path} = $text;
        return ( '', 1 );
    }
    if ( !$e && !_is_dir( $dev, $path ) && ( my $meta = _new_meta( $dev, $path, 0 ) ) ) {    # neue Datei eines Benutzers, umask, setgid
        $dev->{files}{$path} = { content => $text, %$meta };
        return ( '', 1 );
    }
    my $old = _file_text( $dev, $path );
    _file_set( $dev, $path, $append ? ( $old // '' ) . $text : $text );
    return ( '', 1 );
}


sub write {
    my ( $class, $dev, $path, $content, $ctx ) = @_;
    _ssh_access()->can('remember')->($dev) if ref $dev->{files} eq 'HASH' && exists $dev->{files}{'/etc/ssh/sshd_config'};
    if ( my $cut = _locked_out( $dev, $ctx ) ) { return ( $cut =~ s/\Assh:/scp:/r, 0 ) }
    if ( $dev->{ssh_login} ) { my $no = _sshd_sim()->can('login_denied')->( $dev, $ctx->{host} ); return ( $no, 0 ) if defined $no }
    my $web = _web_world($ctx);
    Langertha::Holmgang::Sim::Linux::Http::before( $ctx->{state} ) if $web;
    my ( $e, $ok ) = _write_path( $dev, $path, $content, 0, $ctx );
    Langertha::Holmgang::Sim::Linux::Http::after( $ctx->{state} ) if $web;
    return ( $ok ? "geschrieben: $path (" . length($content) . ' Zeichen)' : $e, $ok );
}

sub _cat {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @out;
    my $ok = 1;
    # ohne Datei: die Eingabe (aus einer Pipe), -A/-E zeigen das Zeilenende als $
    if ( !grep { !/\A-/ } @$av ) {
        my $t = ( $stdin // '' ) =~ s/\n\z//r;
        $t =~ s/$/\$/mg if grep {/\A-\w*[AE]/} @$av;
        return ( $t, 1 );
    }
    for my $p ( grep { !/\A-/ } @$av ) {
        if ( $p =~ m{\A/proc/(\d+)/cmdline\z} ) {
            my ($x) = grep { $_->{pid} == $1 } _procs($dev);
            push @out, $x ? join( "\0", split ' ', $x->{cmd} ) . "\0" : "cat: $p: No such file or directory";
            $ok = 0 unless $x;
            next;
        }
        if ( $p =~ m{\A/proc/(\d+)/limits\z} ) {
            my $t = _proc_limits( $dev, $1 );
            push @out, $t // "cat: $p: No such file or directory";
            $ok = 0 unless defined $t;
            next;
        }
        if ( _file_entry( $dev, $p ) && !_read_ok( $dev, $p ) ) {
            push @out, "cat: $p: Permission denied";
            $ok = 0;
            next;
        }
        my $t = _file_text( $dev, $p );
        if ( !defined $t ) {
            push @out, "cat: $p: No such file or directory";
            $ok = 0;
            next;
        }
        $t =~ s/\n\z//;
        push @out, $t;
    }
    # -A/-T zeigen Tabs als ^I, -A/-E Zeilenenden als $, -n nummeriert (ueber alle Dateien)
    my $f = join '', map { /\A-([AETvn]+)\z/ ? $1 : '' } @$av;
    if ( $f =~ /[ATEn]/ && $ok ) {
        my @l = split /\n/, join( "\n", @out ), -1;
        @l = map { s/\t/^I/gr } @l if $f =~ /[AT]/;
        @l = map {"$_\$"} @l if $f =~ /[AE]/;
        my $i = 0;
        @l = map { sprintf '%6d	%s', ++$i, $_ } @l if $f =~ /n/;
        return ( join( "\n", @l ), 1 );
    }
    return ( join( "\n", @out ), $ok );
}

sub _grep_file {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my ( @opts, @plain, @pats );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-[a-zA-Z]*[ABCm]\z/ ) { push @opts, $x, shift(@a) // '' }    # -A 3, -m 1
        elsif ( $x eq '-e' )                 { push @pats, '-e', shift(@a) // '' }
        elsif ( $x =~ /\A-/ )                { push @opts, $x }
        else                                 { push @plain, $x }
    }
    my @pat = @pats ? @pats : ( shift @plain );
    return ( 'Usage: grep [OPTION]... PATTERNS [FILE]...', 0 ) unless defined $pat[-1];
    return Langertha::Holmgang::Shell::Filter::filter_output( $stdin // '', [ 'grep', @opts, @pat ] ) unless @plain;
    # Dateien (mit -r/-R auch Verzeichnisse); mehrere: Zeilen mit Dateinamen davor (wie GNU grep)
    my $flags = join '', map { /\A-([a-zA-Z]+)\z/ ? $1 : '' } @opts;
    my $rec   = $flags =~ /[rR]/ || grep { $_ eq '--recursive' } @opts;
    my ( @files, @err );
    for my $p (@plain) {
        if ( defined _file_text( $dev, $p ) && !( $rec && _is_dir( $dev, $p ) ) ) { push @files, $p; next }
        if ( _is_dir( $dev, $p ) ) {
            if ($rec) {    # -r folgt Verweisen unterwegs nicht (nur -R), wie GNU grep
                ( my $d = $p ) =~ s{(?<=.)/+\z}{};
                my $follow = $flags =~ /R/ || grep { $_ eq '--dereference-recursive' } @opts;
                push @files, grep { defined _file_text( $dev, $_ ) && ( $follow || !defined( ( _file_entry( $dev, $_ ) || {} )->{link} ) ) } _under( $dev, $d );
            }
            else { push @err, "grep: $p: Is a directory" }
            next;
        }
        push @err, "grep: $p: No such file or directory" unless $flags =~ /s/;    # -s: Meldungen fehlender Dateien unterdrueckt
    }
    my @fo = grep { !/\A-[a-zA-Z]*[lLchHrRs][a-zA-Z]*\z/ || /[ABCm]\z/ } @opts;
    push @fo, map {"-$_"} grep { $flags =~ /$_/ } qw( n i v w x o E F P );
    @fo = do { my %s; grep { !$s{$_}++ } @fo };
    my $names = ( @files > 1 || $rec && grep { _is_dir( $dev, $_ ) && !_file_entry( $dev, $_ ) } @plain ) && $flags !~ /h/ || $flags =~ /H/;
    my ( @out, $any );
    for my $f (@files) {
        my ( $t, $k ) = Langertha::Holmgang::Shell::Filter::filter_output( _file_text( $dev, $f ), [ 'grep', @fo, @pat ] );
        $t //= '';
        my @l = length $t ? split /\n/, $t : ();
        if ( $flags =~ /c/ ) { push @out, ( $names ? "$f:" : '' ) . scalar( grep { $_ ne '--' } @l ); $any = 1 if @l; next }
        next unless @l;
        $any = 1;
        if ( $flags =~ /l/ ) { push @out, $f; next }
        push @out, map { $_ eq '--' ? $_ : $names ? "$f:$_" : $_ } @l;
    }
    return ( join( "\n", @err, @out ), $any && !@err ? 1 : 0 );
}

sub _sed {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my ( $inplace, $quiet, $ere ) = ( 0, 0, 0 );
    my @expr;
    my @files;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-i/ )       { $inplace = 1 }
        elsif ( $x eq '-e' )         { push @expr, shift @a }
        elsif ( $x =~ /\A-([nErs]+)\z/ ) { my $f = $1; $quiet = 1 if $f =~ /n/; $ere = 1 if $f =~ /[Er]/ }
        elsif ( $x eq '--regexp-extended' ) { $ere = 1 }
        elsif ( $x eq '--quiet' || $x eq '--silent' ) { $quiet = 1 }
        elsif ( !@expr )             { push @expr, $x }
        else                         { push @files, $x }
    }
    return ( "Usage: sed [OPTION]... {script-only-if-no-other-script} [input-file]...", 0 )
        unless @expr && ( @files || !$inplace && defined $stdin );
    return ( 'sed: no input files', 0 ) if $inplace && !@files;
    my @cmds;
    for my $e (@expr) {
        for my $part ( _sed_split($e) ) {
            my $c = _sed_cmd( $part, $ere );
            return ( $c, 0 ) unless ref $c;
            push @cmds, $c;
        }
    }
    my @out;
    for my $f ( @files ? @files : (undef) ) {
        my $t = defined $f ? _file_text( $dev, $f ) : $stdin;
        return ( "sed: can't read $f: No such file or directory", 0 ) unless defined $t;
        my $r = _sed_apply( \@cmds, $t, $quiet );
        if ($inplace) { _file_set( $dev, $f, $r ) }
        else          { push @out, $r }
    }
    return ( join( '', @out ) =~ s/\n\z//r, 1 );
}

# sed-Skript an ; und Zeilenende in Befehle zerlegen; Inhalt von /re/ und s/…/…/ bleibt ganz
sub _sed_split {
    my ($e) = @_;
    my ( @cmd, $delim, $left ) = ();
    my $cur = '';
    my @c = split //, $e;
    for ( my $i = 0; $i < @c; $i++ ) {
        my $x = $c[$i];
        if ( defined $delim ) {    # in /re/ bzw. s/…/…/: bis zum letzten Trennzeichen
            $cur .= $x;
            if ( $x eq '\\' && $i + 1 < @c ) { $cur .= $c[ ++$i ]; next }
            undef $delim if $x eq $delim && !--$left;
            next;
        }
        if ( $x eq ';' || $x eq "\n" ) { push @cmd, $cur if $cur =~ /\S/; $cur = ''; next }
        if ( $x eq '/' ) { ( $delim, $left ) = ( '/', 1 ); $cur .= $x; next }
        my $at_cmd = $cur =~ m{\A\s*(?:(?:\d+|\$|/.*/)(?:,(?:\d+|\$|/.*/))?)?\s*!?\s*\z};
        # i/a/c an Befehlsstelle: der Text reicht bis zum Zeilenende (a\ + Zeilenumbruch: naechste Zeile)
        if ( $x =~ /\A[iac]\z/ && $at_cmd && ( $i + 1 >= @c || $c[ $i + 1 ] =~ /[\s\\]/ ) ) {
            my $all  = join '', @c[ $i + 1 .. $#c ];
            my $rest = $all;
            $rest =~ s/\A\\\n// or $rest =~ s/\A\\?[ \t]*//;
            my ($text) = $rest =~ /\A([^\n]*)/;
            push @cmd, "$cur$x\x00$text";
            $cur = '';
            $i += length($all) - length($rest) + length($text);
            next;
        }
        # s an Befehlsstelle (nach hoechstens einer Adresse und !)
        if ( $x eq 's' && $i + 1 < @c && $at_cmd ) {
            ( $delim, $left ) = ( $c[ $i + 1 ], 2 );
            $cur .= $x . $c[ ++$i ];
            next;
        }
        $cur .= $x;
    }
    push @cmd, $cur if $cur =~ /\S/;
    return map { /\x00/ ? s/\A\s+//r : s/\A\s+|\s+\z//gr } @cmd;
}

# Ein sed-Befehl: [adresse[,adresse]][!] d | p | s/…/…/[gI]; Adresse N, $ oder /re/.
sub _sed_cmd {
    my ( $e, $ere ) = @_;
    my $bad = "sed: -e expression #1, char " . length($e) . ": unknown command: `" . substr( $e, 0, 1 ) . "'";
    my $addr = qr{\d+|\$|/(?:[^/\\]|\\.)*/};
    my ( $a1, $a2, $neg, $rest ) = $e =~ /\A\s*($addr)?(?:,($addr))?\s*(!?)\s*(.*)\z/s or return $bad;
    my %c = ( neg => $neg );
    for ( [ a1 => $a1 ], [ a2 => $a2 ] ) {
        my ( $k, $v ) = @$_;
        next unless defined $v;
        if ( $v =~ m{\A/(.*)/\z}s ) {
            my $re = $ere ? $1 : _bre($1);
            $c{$k} = eval { qr/$re/ } or return "sed: -e expression #1: Invalid regular expression";
        }
        else { $c{$k} = $v }
    }
    if ( $rest =~ /\A([dp])\s*\z/ ) { $c{op} = $1; return \%c }
    if ( $rest =~ /\A([iac])\x00(.*)\z/s ) { @c{qw( op text )} = ( $1, $2 ); return \%c }
    my ( $d, $from, $to, $fl ) = $rest =~ /\As(.)(.*?)(?<!\\)\1(.*?)(?<!\\)\1([gI]*)\z/s or return $bad;
    $from = $ere ? $from =~ s/\\(\Q$d\E)/\Q$1\E/gr : _bre( $from, $d );    # \<trenner>: der Trenner selbst
    $to =~ s/\\\Q$d\E/$d/g;    # s/a\/b/c\/d/: Trenner im Ersatz entwertet
    if ( $from eq '' ) {       # s//…/: das zuletzt benutzte Muster (hier: der Adresse)
        my ($last) = grep { ref } @c{qw( a2 a1 )};
        return "sed: -e expression #1, char 0: no previous regular expression" unless $last;
        @c{qw( op to global re )} = ( 's', $to, $fl =~ /g/ ? 1 : 0, $last );
        return \%c;
    }
    $c{re} = eval { $fl =~ /I/ ? qr/$from/mi : qr/$from/m } or return "sed: -e expression #1: Invalid regular expression";
    @c{qw( op to global )} = ( 's', $to, $fl =~ /g/ ? 1 : 0 );
    return \%c;
}

# GNU-BRE -> Perl: blanke ( ) { } | + ? sind Zeichen, mit Backslash Operatoren;
# mit $delim (s|…|…|) ist \<trenner> der Trenner als Zeichen
sub _bre {
    my ( $re, $delim ) = @_;
    my $out = '';
    my @t = $re =~ /(\\.|.)/gs;
    for my $i ( 0 .. $#t ) {
        my $t = $t[$i];
        if    ( defined $delim && $t eq "\\$delim" ) { $out .= quotemeta $delim }
        elsif ( $t =~ /\A\\([(){}|+?])\z/ ) { $out .= $1 }
        elsif ( $t =~ /\A[(){}|+?]\z/ )     { $out .= "\\$t" }
        elsif ( $t eq '$' && $i < $#t )     { $out .= '\$' }    # $ nur am Ende ein Anker
        elsif ( $t eq '^' && $i > 0 && $t[ $i - 1 ] ne '[' ) { $out .= '\^' }    # ^ nur am Anfang
        else                                { $out .= $t }
    }
    return $out;
}

sub _sed_apply {
    my ( $cmds, $t, $quiet ) = @_;
    my $nl = $t =~ /\n\z/;
    my @lines = split /\n/, $t, -1;
    pop @lines if $nl;
    my @out;
    my %in;    # offene Bereiche je Befehl
    # GNU: 0,/re/ — der Bereich ist von Anfang an offen und endet beim ersten Treffer
    $in{$_} = 1 for grep { my $c = $cmds->[$_]; defined $c->{a1} && !ref $c->{a1} && $c->{a1} eq '0' && ref $c->{a2} } 0 .. $#$cmds;
    my $hit = sub {
        my ( $a, $i, $line ) = @_;
        return ref $a ? $line =~ $a : $a eq '$' ? $i == @lines : $i == $a;
    };
    for my $i ( 1 .. @lines ) {
        my $ps = $lines[ $i - 1 ];
        my ( $deleted, @after );
        for my $n ( 0 .. $#$cmds ) {
            my $c = $cmds->[$n];
            my $m;
            if ( !defined $c->{a1} ) { $m = 1 }
            elsif ( !defined $c->{a2} ) { $m = $hit->( $c->{a1}, $i, $ps ) }
            elsif ( $in{$n} ) {
                $m = 1;
                delete $in{$n} if $hit->( $c->{a2}, $i, $ps ) || !ref $c->{a2} && $c->{a2} ne '$' && $i >= $c->{a2};
            }
            elsif ( $hit->( $c->{a1}, $i, $ps ) ) {
                $m = 1;
                $in{$n} = 1 unless !ref $c->{a2} && $c->{a2} ne '$' && $c->{a2} <= $i;
            }
            $m = !$m if $c->{neg};
            next unless $m;
            if    ( $c->{op} eq 'd' ) { $deleted = 1; last }
            elsif ( $c->{op} eq 'p' ) { push @out, $ps }
            elsif ( $c->{op} eq 'i' ) { push @out, $c->{text} }
            elsif ( $c->{op} eq 'a' ) { push @after, $c->{text} }
            elsif ( $c->{op} eq 'c' ) { push @out, $c->{text}; $deleted = 1; last }
            else {
                my $re = $c->{re};
                if   ( $c->{global} ) { $ps =~ s/$re/_expand($c->{to})/ge }
                else                  { $ps =~ s/$re/_expand($c->{to})/e }
            }
        }
        push @out, $ps unless $deleted || $quiet;
        push @out, @after;
    }
    return join( "\n", @out ) . ( @out && $nl ? "\n" : '' );
}

# Ersatztext einer sed-Ersetzung: \1 .. \9 und & aus dem letzten Treffer.
sub _expand {
    my ($to) = @_;
    my $all = $&;
    my @c;
    {
        no strict 'refs';
        @c = map { ${$_} } 1 .. 9;
    }
    my $r = $to;
    $r =~ s/\\(\d)|(\\&)|(&)|\\([nt])|\\(.)/defined $1 ? ( $c[ $1 - 1 ] \/\/ '' ) : defined $2 ? '&' : defined $3 ? $all : defined $4 ? ( $4 eq 'n' ? "\n" : "\t" ) : $5/ges;
    return $r;
}

sub _echo {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $n = 0;
    while ( @a && $a[0] =~ /\A-[neE]+\z/ ) { $n = 1 if $a[0] =~ /n/; shift @a }
    return ( join( ' ', @a ), 1 );
}

# Bytes, ueber die eine Pruefsumme rechnet: der Inhalt. Hat der Zustand keinen (Archiv
# mit tar-Mitgliedern, nur eine Groesse), stehen die Daten des Eintrags ohne Eigentuemer,
# Rechte und Zeiten dafuer -- fest, gleich fuer eine Kopie, verschieden fuer anderen Inhalt.
# Nur eine leere Datei hat den Hash der leeren Eingabe.
my %ENTRY_META = map { $_ => 1 } qw( owner group mode mtime atime ctime open_by uid gid );
my $DIGEST_JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

sub _digest_bytes {
    my ( $e, $text ) = @_;
    require Encode;
    return Encode::encode( 'UTF-8', $text ) if defined $text;
    return '' unless ref $e eq 'HASH';
    my %d = map { $_ => $e->{$_} } grep { !$ENTRY_META{$_} && !/\A_/ } keys %$e;
    return '' if !grep { $_ ne 'size' } keys %d and ( $d{size} // 0 ) =~ /\A0*(?:[.,]0*)?[KMGTP]?i?B?\z/i;
    return "holmgang-sim-entry\0" . $DIGEST_JSON->encode( \%d );
}

# md5sum datei … bzw. aus der Eingabe; ohne Inhalt im Zustand siehe _digest_bytes
sub _md5sum {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    require Digest::MD5;
    require Encode;
    my $md5 = sub { Digest::MD5::md5_hex( Encode::encode( 'UTF-8', $_[0] ) ) };
    my @f = grep { !/\A-/ } @$av;
    if ( grep { /\A-(?:c|-check)\z/ } @$av ) { push @GAPS, join( ' ', 'md5sum', @$av ); return ( '', 0 ) }
    return ( $md5->( $stdin // '' ) . '  -', 1 ) unless @f;
    my ( @l, $ok ) = ();
    $ok = 1;
    for my $p (@f) {
        my $e = _file_entry( $dev, _absp($p) );
        if ( !$e ) { push @l, "md5sum: $p: " . ( _is_dir( $dev, _absp($p) ) ? 'Is a directory' : 'No such file or directory' ); $ok = 0; next }
        my $t = defined $e->{content} || defined $e->{link} ? _file_text( $dev, _absp($p) ) // '' : undef;
        push @l, Digest::MD5::md5_hex( _digest_bytes( $e, $t ) ) . "  $p";
    }
    return ( join( "\n", @l ), $ok );
}

# printf wie bash: Escapes, %s %b %c %d %i %o %u %x %X %e %f %g (Breite, Genauigkeit, *),
# 'A als Zeichencode; mehr Argumente als Umwandlungen: das Format wiederholt sich.
sub _printf {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    shift @a if @a && $a[0] eq '--';
    if ( @a && $a[0] eq '-v' ) { push @GAPS, join( ' ', 'printf', @$av ); return ( '', 0 ) }
    my $fmt = shift @a;
    return ( 'printf: usage: printf [-v var] format [arguments]', 0 ) unless defined $fmt;
    my %e = ( n => "\n", t => "\t", r => "\r", '\\' => '\\', a => "\a", b => "\b", f => "\f", v => "\x0b", '"' => '"', "'" => "'", e => "\e" );
    my $esc = sub {
        my ($s) = @_;
        $s =~ s/\\(?:0?([0-7]{1,3})|x([0-9a-fA-F]{1,2})|(.))/defined $1 ? chr( oct $1 ) : defined $2 ? chr( hex $2 ) : $e{$3} \/\/ "\\$3"/ges;
        return $s;
    };
    my ( @err, $ok ) = ();
    $ok = 1;
    my $num = sub {
        my ( $x, $float ) = @_;
        return 0 if !defined $x || $x eq '';
        return ord substr( $x, 1 ) if $x =~ /\A['"]./s;
        return 0 + $x if $float ? $x =~ /\A\s*[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*\z/ : $x =~ /\A\s*[-+]?\d+\s*\z/;
        return hex $x if !$float && $x =~ /\A0[xX][0-9a-fA-F]+\z/;
        push @err, "bash: printf: $x: invalid number";
        $ok = 0;
        return $x =~ /\A\s*([-+]?\d+(?:\.\d+)?)/ ? 0 + $1 : 0;
    };
    my $out = '';
    my $conv = qr/%(%|([-+ #0]*)(\*|\d+)?(?:\.(\*|\d+))?([diouxXeEfFgGcsbq]))/;
    my $has = $fmt =~ $conv && $fmt =~ /%[^%]/;
    while (1) {
        my $used = 0;
        my $piece = $esc->($fmt);
        $piece =~ s{$conv}{
            my ( $all, $fl, $w, $p, $c ) = ( $1, $2 // '', $3, $4, $5 );
            if ( $all eq '%' ) { '%' }
            else {
                $w = do { $used++; shift(@a) // 0 } if defined $w && $w eq '*';
                $p = do { $used++; shift(@a) // 0 } if defined $p && $p eq '*';
                my $spec = '%' . $fl . ( $w // '' ) . ( defined $p ? ".$p" : '' );
                my $arg = shift @a;
                $used++;
                $c eq 'q' ? do { push @GAPS, join( ' ', 'printf', @$av ); '' }
                : $c eq 's' ? sprintf( "${spec}s", $arg // '' )
                : $c eq 'b' ? sprintf( "${spec}s", $esc->( $arg // '' ) )
                : $c eq 'c' ? sprintf( "${spec}s", substr( $arg // '', 0, 1 ) )
                : $c =~ /[eEfFgG]/ ? sprintf( "$spec$c", $num->( $arg, 1 ) )
                : sprintf( $spec . ( $c eq 'i' ? 'd' : $c ), int $num->($arg) );
            }
        }ge;
        $out .= $piece;
        last unless $has && $used && @a;
    }
    $out =~ s/\n\z//;
    return ( join( "\n", grep { length } $out, @err ), $ok );
}

# --- ip --------------------------------------------------------------------------------

sub _abbrev {
    my ( $w, @full ) = @_;
    return undef unless defined $w;
    for my $f (@full) { return $f if index( $f, $w ) == 0 }
    return undef;
}

sub _ip {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my %o;
    while ( @a && $a[0] =~ /\A-/ ) {
        my $x = shift @a;
        $o{4} = 1 if $x eq '-4';
        $o{6} = 1 if $x eq '-6';
        $o{br} = 1 if $x =~ /\A-br/;
        $o{j}  = 1 if $x eq '-j' || $x eq '-json' || $x eq '--json';
        if ( $x eq '-c' || $x =~ /\A-col/ ) { }
    }
    my $obj = shift @a;
    return ( "Usage: ip [ OPTIONS ] OBJECT { COMMAND | help }\nwhere  OBJECT := { address | link | neigh | route | rule | … }", 0 ) unless defined $obj;
    my $o = _abbrev( $obj, qw( route rule address link neighbour neigh ) )
        // ( $obj eq 'r' ? 'route' : $obj eq 'a' ? 'address' : $obj eq 'l' ? 'link' : $obj eq 'n' ? 'neigh' : undef );
    $o = 'address' if $obj eq 'addr';
    return ( qq{Object "$obj" is unknown, try "ip help".}, 0 ) unless $o;
    if ( $o{j} && ( !@a || $a[0] =~ /\A(?:show|list|ls)\z/ ) ) {
        my $j = _ip_json( $dev, $o, @a ) // return ( 'Error: JSON fuer diese Ausgabe nicht vorhanden', 0 );
        return ( $j, 1 );
    }
    return _ip_route( $dev, \@a, \%o ) if $o eq 'route';
    return _ip_rule( $dev, \@a )       if $o eq 'rule';
    return _ip_addr( $dev, \@a, \%o )  if $o eq 'address';
    return _ip_link( $dev, \@a, \%o )  if $o eq 'link';
    return ( join( "\n", @{ $dev->{neigh} || [] } ), 1 );
}

# ip -j: Routen, Adressen, Schnittstellen als JSON wie iproute2
sub _ip_json {
    my ( $dev, $o, @a ) = @_;
    shift @a if @a && $a[0] =~ /\A(?:show|list|ls)\z/;
    require JSON::MaybeXS;
    my $J = JSON::MaybeXS->new( canonical => 1, utf8 => 0 );
    if ( $o eq 'route' ) {
        my $table = 'main';
        for my $i ( 0 .. $#a - 1 ) { $table = $a[ $i + 1 ] if $a[$i] eq 'table' }
        my @r = map {
            my $r = $_;
            +{ dst => $r->{dst}, ( map { defined $r->{$_} ? ( ( $_ eq 'via' ? 'gateway' : $_ eq 'src' ? 'prefsrc' : $_ ) => $r->{$_} ) : () }
                qw( via dev proto scope src metric ) ), flags => [] };
        } grep { $table eq 'all' || _table_of($_) eq $table } @{ $dev->{routes} || [] };
        return $J->encode( \@r );
    }
    if ( $o eq 'address' || $o eq 'link' ) {
        my $idx = 0;
        my @l;
        for my $n ( _ifaces($dev) ) {
            $idx++;
            my $i = _iface( $dev, $n );
            my %e = ( ifindex => $idx, ifname => $n, mtu => 0 + ( $i->{mtu} // 1500 ), operstate => $i->{state} // 'UP',
                flags => [ ( $i->{state} // 'UP' ) eq 'DOWN' ? qw( BROADCAST MULTICAST ) : qw( BROADCAST MULTICAST UP LOWER_UP ) ] );
            if ( $o eq 'address' ) {
                $e{addr_info} = [ map {
                    my ( $ip, $len ) = split m{/};
                    +{ family => /:/ ? 'inet6' : 'inet', local => $ip, prefixlen => 0 + ( $len // 32 ) };
                } @{ $i->{addr} || [] } ];
            }
            push @l, \%e;
        }
        return $J->encode( \@l );
    }
    return undef;
}

# ss: Sockets aus dem Zustand (sockets: [ Zeilen ]) unter dem Kopf von ss
sub _own_addrs { my ($dev) = @_; return map { s{/\d+\z}{}r } map { @{ $_->{addr} || [] } } values %{ $dev->{interfaces} || {} } }

sub _ss {
    my ( $dev, $av ) = @_;
    my $head = sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', qw( Netid State Recv-Q Send-Q ), 'Local Address:Port', 'Peer Address:Port', 'Process' );
    my @l = @{ $dev->{sockets} || [] };
    # Lauscher der Datenbankdienste aus ihren laufenden Werten
    my $svc = $dev->{services} || {};
    if ( $dev->{redis} && ( $svc->{ $dev->{redis}{service} // 'redis-server' } || {} )->{active} ) {
        my $run = _redis()->can('_running')->($dev);
        for my $a ( map { s/\A-//r } split /\s+/, $run->{bind} // '' ) {
            push @l, sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', 'tcp', 'LISTEN', 0, 511, ( $a =~ /:/ ? "[$a]" : $a ) . ":$run->{port}", '0.0.0.0:*',
                'users:(("redis-server",pid=811,fd=6))' );
        }
    }
    if ( $dev->{mariadb} && ( $svc->{ $dev->{mariadb}{service} // 'mariadb' } || {} )->{active} ) {
        my $v = _maria()->can('_vars')->($dev);
        push @l, map { sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', 'tcp', 'LISTEN', 0, 80, "$_:$v->{port}", '0.0.0.0:*', 'users:(("mariadbd",pid=911,fd=21))' ) }
            split /\s*,\s*/, $v->{bind_address} // '127.0.0.1';
    }
    # laufende Dienste mit listen bzw. nginx: dort, wo ihre Konfiguration es sagt
    for my $n ( sort keys %$svc ) {
        my $s = $svc->{$n};
        next unless ref $s eq 'HASH' && $s->{active} && ( $s->{listen} || ( $s->{exec} // $n ) eq 'nginx' );
        my @a = $s->{_listen} ? @{ $s->{_listen} } : _svc_listen( $dev, $n, $s );
        my $pid = _main_pid( $dev, $n );
        my $comm = substr( ( split ' ', $s->{exec} // $n )[0] =~ s{.*/}{}r, 0, 15 );
        my $fd = 5;
        for my $a (@a) {
            next if grep { /\s\Q$a\E\s/ } @l;
            push @l, sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', 'tcp', 'LISTEN', 0, $comm eq 'nginx' ? 511 : 4096, $a,
                $a =~ /\A\[/ ? '[::]:*' : '0.0.0.0:*', qq{users:(("$comm",pid=$pid,fd=} . $fd++ . '))' );
        }
    }
    my $ssh = ( $dev->{services} || {} )->{ssh};
    # sshd: Ports aus seiner Konfiguration (Sshd), ohne sshd_config im Zustand 22
    if ( $ssh && $ssh->{active} && !grep {/:22\s/} @l ) {
        my $eff = %{ $ssh->{effective} || {} } ? $ssh->{effective}
            : ( ref $dev->{files} eq 'HASH' && exists $dev->{files}{'/etc/ssh/sshd_config'}
            ? _ssh_access()->can('config_for')->( $dev, { user => "\0", from => "\0", groups => [], port => 0 } ) : {} );
        my @ports = _sshd_sim()->can('active')->($dev) || $eff->{port} ? @{ $eff->{port} || [22] } : (22);
        my ($pr) = grep { $_->{unit} eq 'ssh' } _procs($dev);
        my $pid = $pr ? $pr->{pid} : 701;
        for my $p (@ports) {
            push @l, sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', 'tcp', 'LISTEN', 0, 128, "0.0.0.0:$p", '0.0.0.0:*', qq{users:(("sshd",pid=$pid,fd=3))} ),
                sprintf( '%-6s %-7s %-6s %-6s %-25s %-25s %s', 'tcp', 'LISTEN', 0, 128, "[::]:$p", '[::]:*', qq{users:(("sshd",pid=$pid,fd=4))} );
        }
    }
    if ( ref $dev->{docker} eq 'HASH' ) { _part('Docker'); push @l, Langertha::Holmgang::Sim::Linux::Docker::ss_lines($dev) }
    return ( join( "\n", $head, @l ), 1 );
}

sub _ifaces {
    my ($dev) = @_;
    my $i = $dev->{interfaces} || {};
    return ( 'lo', grep { $_ ne 'lo' } sort keys %$i );
}

sub _iface {
    my ( $dev, $n ) = @_;
    return { addr => ['127.0.0.1/8'], mtu => 65536, state => 'UNKNOWN' } if $n eq 'lo' && !$dev->{interfaces}{lo};
    return $dev->{interfaces}{$n};
}

sub _route_text {
    my ( $r, $with_table ) = @_;
    my $s = $r->{type} && $r->{type} ne 'unicast' ? "$r->{type} $r->{dst}" : $r->{dst};
    $s .= " via $r->{via}"         if defined $r->{via};
    $s .= " dev $r->{dev}"         if defined $r->{dev};
    $s .= " table $r->{table}"     if $with_table && defined $r->{table} && $r->{table} ne 'main';
    $s .= " proto $r->{proto}"     if defined $r->{proto};
    $s .= " scope $r->{scope}"     if defined $r->{scope};
    $s .= " src $r->{src}"         if defined $r->{src};
    $s .= " metric $r->{metric}"   if defined $r->{metric};
    $s .= " onlink"                if $r->{onlink};
    return $s;
}

sub _table_of { my ($r) = @_; return defined $r->{table} ? "$r->{table}" : 'main' }

sub _ip_route {
    my ( $dev, $av, $o ) = @_;
    my @a   = @$av;
    my $sub = @a ? shift @a : 'show';
    my $cmd = _abbrev( $sub, qw( show list add delete replace change get flush append ) )
        // ( $sub eq 'del' ? 'delete' : undef );
    if ( !$cmd ) {
        # ip route 10.0.0.0/8 ... = show mit Filter
        unshift @a, $sub;
        $cmd = 'show';
    }
    $cmd = 'show' if $cmd eq 'list';
    $dev->{routes} //= [];
    if ( $cmd eq 'show' || $cmd eq 'flush' ) {
        my %f = ( table => 'main' );
        while (@a) {
            my $k = shift @a;
            if    ( $k eq 'table' ) { $f{table} = shift @a }
            elsif ( $k eq 'dev' )   { $f{dev}   = shift @a }
            elsif ( $k eq 'proto' ) { $f{proto} = shift @a }
            elsif ( $k eq 'via' )   { $f{via}   = shift @a }
            elsif ( $k =~ /\A(?:default|[\d.]+(?:\/\d+)?)\z/ ) { $f{dst} = _canon_dst($k) }
            elsif ( $k eq 'exact' || $k eq 'root' || $k eq 'match' ) { }
            else { return ( qq{Error: either "to" is duplicate, or "$k" is a garbage.}, 0 ) }
        }
        my $all = $f{table} eq 'all';
        return ( 'Error: ipv4: FIB table does not exist.', 0 )
            if !$all && $f{table} !~ /\A(?:main|local|default)\z/ && !grep { _table_of($_) eq $f{table} } @{ $dev->{routes} };
        my @hit = grep {
            my $r = $_;
            ( $all || _table_of($r) eq $f{table} )
                && ( !defined $f{dev} || ( $r->{dev} // '' ) eq $f{dev} )
                && ( !defined $f{proto} || ( $r->{proto} // 'boot' ) eq $f{proto} )
                && ( !defined $f{via} || ( $r->{via} // '' ) eq $f{via} )
                && ( !defined $f{dst} || $r->{dst} eq $f{dst} )
        } @{ $dev->{routes} };
        if ( $cmd eq 'flush' ) {
            my %drop = map { $_ => 1 } @hit;
            @{ $dev->{routes} } = grep { !$drop{$_} } @{ $dev->{routes} };
            return ( '', 1 );
        }
        my $v6 = sub { $_[0]{dst} =~ /:/ || ( $_[0]{via} // '' ) =~ /:/ || ( $_[0]{family} // '' ) eq 'inet6' };
        @hit = $o->{6} ? grep { $v6->($_) } @hit : grep { !$v6->($_) } @hit;
        return ( join( "\n", map { _route_text( $_, $all ) } @hit ), 1 );
    }
    if ( $cmd eq 'get' ) {
        my $to = shift @a // return ( 'Usage: ip route get ADDRESS [ from ADDRESS iif STRING ] …', 0 );
        my %g;
        while (@a) { my $k = shift @a; $g{$k} = shift @a }
        return ( "Error: inet prefix is expected rather than \"$to\".", 0 ) unless defined _ip2n($to);
        my ( $r, $table ) = _lookup( $dev, $to, $g{from}, $g{iif} );
        return ( 'RTNETLINK answers: Network is unreachable', 0 ) unless $r;
        my $src = $g{from} // _src_for( $dev, $r );
        my $s = $to;
        $s .= " from $g{from}" if defined $g{from};
        $s .= " via $r->{via}" if defined $r->{via};
        $s .= " dev $r->{dev}" if defined $r->{dev};
        $s .= " table $table" if $table ne 'main';
        $s .= " src $src" if defined $src && !defined $g{from};
        $s .= " uid 0";
        return ( "$s \n    cache ", 1 );
    }
    # add/delete/replace/change/append
    my $dst = shift @a // return ( 'Error: either "to" is duplicate, or "" is a garbage.', 0 );
    $dst = shift @a if $dst eq 'to';
    my %r;
    my $type;
    if ( $dst =~ /\A(?:unicast|blackhole|unreachable|prohibit)\z/ ) { $type = $dst; $dst = shift @a // '' }
    my $c = _canon_dst($dst) // return ( qq{Error: any valid prefix is expected rather than "$dst".}, 0 );
    $r{dst} = $c;
    $r{type} = $type if $type && $type ne 'unicast';
    while (@a) {
        my $k = shift @a;
        if ( $k =~ /\A(?:via|dev|metric|table|proto|scope|src|preference|pref)\z/ ) {
            my $v = shift @a;
            return ( qq{Command line is not complete. Try option "help"}, 0 ) unless defined $v;
            $k = 'metric' if $k eq 'preference' || $k eq 'pref';
            $r{$k} = $v;
        }
        elsif ( $k eq 'onlink' ) { $r{onlink} = 1 }
        else { return ( qq{Error: either "to" is duplicate, or "$k" is a garbage.}, 0 ) }
    }
    return ( qq{Error: argument "$r{metric}" is wrong: "metric" value is invalid}, 0 )
        if defined $r{metric} && $r{metric} !~ /\A\d+\z/;
    if ( defined $r{dev} && !_iface( $dev, $r{dev} ) ) {
        return ( qq{Cannot find device "$r{dev}"}, 0 );
    }
    if ( defined $r{via} && $cmd ne 'delete' ) {
        return ( qq{Error: inet address is expected rather than "$r{via}".}, 0 ) unless defined _ip2n( $r{via} );
        my $gwdev = _connected_dev( $dev, $r{via} );
        if ( !$r{onlink} ) {
            return ( 'Error: Nexthop has invalid gateway.', 0 ) unless $gwdev;
            return ( 'Error: Nexthop has invalid gateway.', 0 ) if defined $r{dev} && $r{dev} ne $gwdev;
        }
        $r{dev} //= $gwdev;
    }
    if ( !defined $r{via} && !defined $r{dev} && $cmd ne 'delete' && !$r{type} ) {
        return ( 'Error: Device for nexthop is not up.', 0 );
    }
    $r{metric} = 0 + $r{metric} if defined $r{metric};
    delete $r{table} if defined $r{table} && $r{table} eq 'main';
    my $same = sub {
        my ($x) = @_;
        return $x->{dst} eq $r{dst} && _table_of($x) eq _table_of( \%r ) && ( $x->{metric} // 0 ) == ( $r{metric} // 0 );
    };
    my @routes = @{ $dev->{routes} };
    if ( $cmd eq 'delete' ) {
        my ($i) = grep {
            my $x = $routes[$_];
            $x->{dst} eq $r{dst} && _table_of($x) eq _table_of( \%r )
                && ( !defined $r{via} || ( $x->{via} // '' ) eq $r{via} )
                && ( !defined $r{dev} || ( $x->{dev} // '' ) eq $r{dev} )
                && ( !defined $r{metric} || ( $x->{metric} // 0 ) == $r{metric} )
        } 0 .. $#routes;
        return ( 'RTNETLINK answers: No such process', 0 ) unless defined $i;
        splice @{ $dev->{routes} }, $i, 1;
        return ( '', 1 );
    }
    my ($i) = grep { $same->( $routes[$_] ) } 0 .. $#routes;
    if ( $cmd eq 'add' || $cmd eq 'append' ) {
        return ( 'RTNETLINK answers: File exists', 0 ) if defined $i && $cmd eq 'add';
        push @{ $dev->{routes} }, \%r;
        return ( '', 1 );
    }
    if ( $cmd eq 'change' ) {
        return ( 'RTNETLINK answers: No such file or directory', 0 ) unless defined $i;
        $dev->{routes}[$i] = \%r;
        return ( '', 1 );
    }
    # replace
    if ( defined $i ) { $dev->{routes}[$i] = \%r }
    else              { push @{ $dev->{routes} }, \%r }
    return ( '', 1 );
}

sub _connected_dev {
    my ( $dev, $ip ) = @_;
    for my $n ( _ifaces($dev) ) {
        my $i = _iface( $dev, $n ) or next;
        next if ( $i->{state} // 'UP' ) eq 'DOWN';
        for my $a ( @{ $i->{addr} || [] } ) {
            return $n if _in( $ip, $a );
        }
    }
    # Kernel-Routen auf Schnittstellen (z. B. wg0 ohne Adresse im selben Netz)
    for my $r ( @{ $dev->{routes} || [] } ) {
        return $r->{dev} if !defined $r->{via} && defined $r->{dev} && $r->{dst} ne 'default'
            && _table_of($r) eq 'main' && ( $r->{scope} // '' ) eq 'link' && _in( $ip, $r->{dst} );
    }
    return undef;
}

sub _src_for {
    my ( $dev, $r ) = @_;
    return $r->{src} if defined $r->{src};
    my $i = defined $r->{dev} ? _iface( $dev, $r->{dev} ) : undef;
    my ($first) = $i ? @{ $i->{addr} || [] } : ();
    return defined $first ? ( split m{/}, $first )[0] : undef;
}

sub _best {
    my ( $routes, $ip, $table ) = @_;
    my ( $best, $blen, $bm );
    for my $r (@$routes) {
        next unless _table_of($r) eq $table && $r->{dst} !~ /:/;
        my ( $net, $len ) = _prefix( $r->{dst} ) or next;
        next unless _in( $ip, $r->{dst} );
        my $m = $r->{metric} // 0;
        if ( !defined $best || $len > $blen || ( $len == $blen && $m < $bm ) ) { ( $best, $blen, $bm ) = ( $r, $len, $m ) }
    }
    return $best;
}

sub _lookup {
    my ( $dev, $ip, $from, $iif ) = @_;
    my @rules = sort { $a->{priority} <=> $b->{priority} } _all_rules($dev);
    for my $ru (@rules) {
        next if defined $ru->{from} && $ru->{from} ne 'all' && !( defined $from && _in( $from, $ru->{from} ) );
        next if defined $ru->{to} && $ru->{to} ne 'all' && !_in( $ip, $ru->{to} );
        next if defined $ru->{iif} && !( defined $iif && $iif eq $ru->{iif} );
        my $t = $ru->{table} // 'main';
        next if $t eq 'local' || $t eq 'default';
        my $r = _best( $dev->{routes} || [], $ip, $t );
        return ( $r, $t ) if $r;
    }
    return ();
}

# --- ip rule -------------------------------------------------------------------------

sub _all_rules {
    my ($dev) = @_;
    return ( { priority => 0, table => 'local' }, @{ $dev->{rules} || [] },
        { priority => 32766, table => 'main' }, { priority => 32767, table => 'default' } );
}

sub _rule_text {
    my ($r) = @_;
    my $s = "$r->{priority}:\tfrom " . ( $r->{from} // 'all' );
    $s .= " to $r->{to}"            if defined $r->{to};
    $s .= " fwmark $r->{fwmark}"    if defined $r->{fwmark};
    $s .= " iif $r->{iif}"          if defined $r->{iif};
    $s .= " oif $r->{oif}"          if defined $r->{oif};
    $s .= ' lookup ' . ( $r->{table} // 'main' );
    return $s;
}

sub _ip_rule {
    my ( $dev, $av ) = @_;
    my @a   = @$av;
    my $sub = @a ? shift @a : 'show';
    my $cmd = _abbrev( $sub, qw( show list add delete flush ) ) // ( $sub eq 'del' ? 'delete' : undef )
        // return ( qq{Command "$sub" is unknown, try "ip rule help".}, 0 );
    if ( $cmd eq 'show' || $cmd eq 'list' ) {
        return ( join( "\n", map { _rule_text($_) } sort { $a->{priority} <=> $b->{priority} } _all_rules($dev) ), 1 );
    }
    if ( $cmd eq 'flush' ) { $dev->{rules} = []; return ( '', 1 ) }
    my %r;
    while (@a) {
        my $k = shift @a;
        my $v = shift @a;
        return ( qq{Command line is not complete. Try option "help"}, 0 ) unless defined $v;
        if    ( $k =~ /\A(?:priority|pref|preference|prio)\z/ ) { $r{priority} = $v }
        elsif ( $k =~ /\A(?:lookup|table)\z/ )   { $r{table} = $v }
        elsif ( $k =~ /\A(?:from|to|iif|oif|fwmark)\z/ ) { $r{$k} = $v eq 'all' ? undef : $v }
        else  { return ( qq{Error: argument "$k" is wrong: Failed to parse rule type}, 0 ) }
    }
    delete $r{$_} for grep { !defined $r{$_} } keys %r;
    for my $k (qw( from to )) {
        next unless defined $r{$k};
        my $c = _canon_dst( $r{$k} ) // return ( qq{Error: inet prefix is expected rather than "$r{$k}".}, 0 );
        $r{$k} = $c;
    }
    $dev->{rules} //= [];
    if ( $cmd eq 'delete' ) {
        my ($i) = grep {
            my $x = $dev->{rules}[$_];
            !grep { ( $x->{$_} // '' ) ne ( $r{$_} // ( $_ eq 'priority' ? $x->{priority} : '' ) ) } qw( priority from to iif oif fwmark table )
        } 0 .. $#{ $dev->{rules} };
        return ( 'RTNETLINK answers: No such file or directory', 0 ) unless defined $i;
        splice @{ $dev->{rules} }, $i, 1;
        return ( '', 1 );
    }
    return ( 'Error: argument "' . $r{priority} . '" is wrong: preference value is invalid', 0 )
        if defined $r{priority} && $r{priority} !~ /\A\d+\z/;
    if ( !defined $r{priority} ) {
        my ($low) = sort { $a <=> $b } map { $_->{priority} } @{ $dev->{rules} };
        $r{priority} = ( $low // 32766 ) - 1;
    }
    $r{priority} = 0 + $r{priority};
    $r{table} //= 'main';
    push @{ $dev->{rules} }, \%r;
    @{ $dev->{rules} } = sort { $a->{priority} <=> $b->{priority} } @{ $dev->{rules} };
    return ( '', 1 );
}

# --- ip addr / link --------------------------------------------------------------------

sub _ip_addr {
    my ( $dev, $av, $o ) = @_;
    my @a   = @$av;
    my $sub = @a ? shift @a : 'show';
    my $cmd = _abbrev( $sub, qw( show list add delete flush ) ) // ( $sub eq 'del' ? 'delete' : undef );
    if ( !$cmd ) { unshift @a, $sub; $cmd = 'show' }
    if ( $cmd eq 'show' || $cmd eq 'list' ) {
        shift @a if @a && $a[0] eq 'dev';
        my $only = shift @a;
        return ( qq{Device "$only" does not exist.}, 0 ) if defined $only && !_iface( $dev, $only );
        my @out;
        my $idx = 0;
        for my $n ( _ifaces($dev) ) {
            $idx++;
            next if defined $only && $n ne $only;
            my $i = _iface( $dev, $n );
            my $st = $i->{state} // 'UP';
            if ( $o->{br} ) {
                push @out, sprintf( '%-16s %-14s %s', $n, $st, join( ' ', @{ $i->{addr} || [] } ) );
                next;
            }
            push @out, "$idx: $n: <" . ( $n eq 'lo' ? 'LOOPBACK,UP,LOWER_UP' : $st eq 'DOWN' ? 'BROADCAST,MULTICAST' : 'BROADCAST,MULTICAST,UP,LOWER_UP' )
                . "> mtu " . ( $i->{mtu} // 1500 ) . " qdisc noqueue state $st group default qlen 1000";
            push @out, "    inet $_ scope " . ( $n eq 'lo' ? 'host' : 'global' ) . " $n" for $o->{6} ? () : grep { !/:/ } @{ $i->{addr} || [] };
            push @out, "    inet6 $_ scope global" for $o->{4} ? () : grep {/:/} @{ $i->{addr} || [] };
        }
        return ( join( "\n", @out ), 1 );
    }
    my $addr = shift @a // return ( 'Command line is not complete. Try option "help"', 0 );
    my %k;
    while (@a) { my $x = shift @a; $k{$x} = shift @a }
    my $ifn = $k{dev} // return ( 'Not enough information: "dev" argument is required.', 0 );
    my $i = _iface( $dev, $ifn ) or return ( qq{Cannot find device "$ifn"}, 0 );
    $addr .= '/32' if $addr !~ m{/} && $addr !~ /:/;
    my $list = $i->{addr} //= [];
    if ( $cmd eq 'add' ) {
        return ( 'RTNETLINK answers: File exists', 0 ) if grep { $_ eq $addr } @$list;
        push @$list, $addr;
        if ( my ( $net, $len ) = _prefix($addr) ) {
            push @{ $dev->{routes} }, { dst => _n2ip($net) . "/$len", dev => $ifn, proto => 'kernel', scope => 'link',
                src => ( split m{/}, $addr )[0] } if $len < 32;
        }
        return ( '', 1 );
    }
    my $n = @$list;
    @$list = grep { $_ ne $addr } @$list;
    return ( 'RTNETLINK answers: Cannot assign requested address', 0 ) if @$list == $n;
    my $src = ( split m{/}, $addr )[0];
    @{ $dev->{routes} } = grep { !( ( $_->{proto} // '' ) eq 'kernel' && ( $_->{src} // '' ) eq $src ) } @{ $dev->{routes} || [] };
    return ( '', 1 );
}

sub _ip_link {
    my ( $dev, $av, $o ) = @_;
    my @a   = @$av;
    my $sub = @a ? shift @a : 'show';
    my $cmd = _abbrev( $sub, qw( show list set add delete ) ) // ( $sub eq 'del' ? 'delete' : undef );
    if ( !$cmd ) { unshift @a, $sub; $cmd = 'show' }
    if ( $cmd eq 'show' || $cmd eq 'list' ) {
        shift @a if @a && $a[0] eq 'dev';
        my $only = shift @a;
        return ( qq{Device "$only" does not exist.}, 0 ) if defined $only && !_iface( $dev, $only );
        my @out;
        my $idx = 0;
        for my $n ( _ifaces($dev) ) {
            $idx++;
            next if defined $only && $n ne $only;
            my $i  = _iface( $dev, $n );
            my $st = $i->{state} // 'UP';
            if ( $o->{br} ) { push @out, sprintf( '%-16s %-14s', $n, $st ); next }
            push @out, "$idx: $n: <" . ( $n eq 'lo' ? 'LOOPBACK,UP,LOWER_UP' : $st eq 'DOWN' ? 'BROADCAST,MULTICAST' : 'BROADCAST,MULTICAST,UP,LOWER_UP' )
                . "> mtu " . ( $i->{mtu} // 1500 ) . " qdisc noqueue state $st mode DEFAULT group default qlen 1000";
            push @out, $n eq 'lo' ? '    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00'
                : $n =~ /\Awg|\Atun|ppp/ ? '    link/none ' : '    link/ether ' . ( $i->{mac} // '52:54:00:00:00:' . sprintf( '%02x', $idx ) ) . ' brd ff:ff:ff:ff:ff:ff';
        }
        return ( join( "\n", @out ), 1 );
    }
    return ( qq{Command "$cmd" is not supported here.}, 0 ) unless $cmd eq 'set';
    shift @a if @a && $a[0] eq 'dev';
    my $n = shift @a // return ( 'Not enough of information: "dev" argument is required.', 0 );
    my $i = $dev->{interfaces}{$n} or return ( qq{Cannot find device "$n"}, 0 );
    return ( 'Command line is not complete. Try option "help"', 0 ) unless @a;
    my %set;
    while (@a) {
        my $k = shift @a;
        if ( $k eq 'mtu' ) {
            my $v = shift @a;
            return ( qq{Error: argument "} . ( $v // '' ) . qq{" is wrong: Invalid "mtu" value}, 0 ) unless defined $v && $v =~ /\A\d+\z/;
            return ( 'Error: mtu less than device minimum.', 0 ) if $v < 68;
            return ( 'Error: mtu greater than device maximum.', 0 ) if $v > 65535;
            $set{mtu} = 0 + $v;
        }
        elsif ( $k eq 'up' )   { $set{state} = 'UP' }
        elsif ( $k eq 'down' ) { $set{state} = 'DOWN' }
        else { return ( qq{Error: either "dev" is duplicate, or "$k" is a garbage.}, 0 ) }
    }
    $i->{$_} = $set{$_} for keys %set;
    return ( '', 1 );
}

# --- WireGuard ---------------------------------------------------------------------

sub _wg_conf {
    my ($w) = @_;
    my @l = ( '[Interface]' );
    push @l, "Address = $w->{address}" if defined $w->{address};
    push @l, "ListenPort = $w->{listen_port}" if defined $w->{listen_port};
    push @l, 'PrivateKey = ' . ( $w->{private_key} // '(nicht angezeigt)' );
    push @l, "MTU = $w->{mtu}" if defined $w->{mtu};
    for my $k ( sort keys %{ $w->{peers} || {} } ) {
        my $p = $w->{peers}{$k};
        push @l, '', '[Peer]';
        push @l, "# $p->{name}" if defined $p->{name};
        push @l, "PublicKey = $k";
        push @l, "Endpoint = $p->{endpoint}" if defined $p->{endpoint};
        push @l, 'AllowedIPs = ' . join( ', ', @{ $p->{allowed_ips} || [] } );
        push @l, "PersistentKeepalive = $p->{keepalive}" if defined $p->{keepalive};
    }
    return join( "\n", @l ) . "\n";
}

# wgN.conf lesen -> Zustand (ohne Address/MTU: die setzt wg-quick)
sub _wg_parse {
    my ( $text, $old ) = @_;
    my %w = ( %{ $old || {} }, peers => {} );
    my ( $sec, $peer, %pp );
    my $flush = sub {
        return unless $peer;
        my $prev = ( $old->{peers} || {} )->{$peer} || {};
        $w{peers}{$peer} = { %$prev, allowed_ips => [], %pp };
        _wg_claim( \%w, $peer );
        ( $peer, %pp ) = ();
    };
    my $n = 0;
    for my $line ( split /\n/, $text ) {
        $n++;
        ( my $l = $line ) =~ s/#.*//;
        $l =~ s/\A\s+|\s+\z//g;
        next unless length $l;
        if ( $l =~ /\A\[(Interface|Peer)\]\z/i ) { $flush->(); $sec = lc $1; next }
        # wie wg: aller Leerraum faellt weg ("Allowed IPs = a, b" ist AllowedIPs=a,b)
        ( my $flat = $l ) =~ s/\s+//g;
        my ( $k, $v ) = $flat =~ /\A(\w+)=(.*)\z/ or die "Line unrecognized: `$flat'\nConfiguration parsing error\n";
        $k = lc $k;
        if ( ( $sec // '' ) eq 'interface' ) {
            $w{listen_port} = $v =~ /\A\d+\z/ ? 0 + $v : $v if $k eq 'listenport';
            $w{address}     = $v if $k eq 'address';
            $w{mtu}         = 0 + $v if $k eq 'mtu';
        }
        elsif ( ( $sec // '' ) eq 'peer' ) {
            if    ( $k eq 'publickey' )  { $peer = $v }
            elsif ( $k eq 'allowedips' ) { $pp{allowed_ips} = [ grep {length} split /\s*,\s*/, $v ] }
            elsif ( $k eq 'endpoint' )   { $pp{endpoint} = $v }
            elsif ( $k eq 'persistentkeepalive' ) { $pp{keepalive} = $v =~ /\A\d+\z/ ? 0 + $v : $v }
            elsif ( $k ne 'presharedkey' ) { die "Line unrecognized: `$flat'\nConfiguration parsing error\n" }
        }
        else { die "Line unrecognized: `$flat'\nConfiguration parsing error\n" }
    }
    $flush->();
    return \%w;
}

# Eine AllowedIP gehoert in wg genau einem Peer: wer sie bekommt, nimmt sie den anderen.
sub _wg_claim {
    my ( $w, $peer ) = @_;
    my %mine = map { $_ => 1 } @{ $w->{peers}{$peer}{allowed_ips} || [] };
    for my $k ( grep { $_ ne $peer } keys %{ $w->{peers} || {} } ) {
        my $l = $w->{peers}{$k}{allowed_ips} || [];
        my @keep = grep { !$mine{$_} } @$l;
        $w->{peers}{$k}{allowed_ips} = \@keep if @keep != @$l;
    }
    return;
}

# [Interface] einer wgN.conf: was wg-quick daraus macht (Address, MTU, Table, Hooks, SaveConfig)
sub _wg_quick_conf {
    my ($text) = @_;
    my ( %c, $sec );
    for my $line ( split /\n/, $text ) {
        ( my $l = $line ) =~ s/#.*//;
        $l =~ s/\A\s+|\s+\z//g;
        next unless length $l;
        if ( $l =~ /\A\[(\w+)\]\z/ ) { $sec = lc $1; next }
        next unless ( $sec // '' ) eq 'interface';
        my ( $k, $v ) = $l =~ /\A(\w+)\s*=\s*(.*)\z/ or next;
        $k = lc $k;
        if ( $k =~ /\A(?:preup|postup|predown|postdown)\z/ ) { push @{ $c{$k} }, $v }
        elsif ( $k eq 'address' ) { push @{ $c{address} }, grep {length} split /\s*,\s*/, $v }
        else { $c{$k} = $v }
    }
    return \%c;
}

# PreUp/PostUp: scheitert ein Befehl, bricht wg-quick up ab. PreDown/PostDown
# ($soft): die Schnittstelle geht trotzdem herunter (wie der Stop der Unit).
sub _wg_hooks {
    my ( $dev, $n, $cmds, $soft ) = @_;
    for my $c ( @{ $cmds || [] } ) {
        ( my $x = $c ) =~ s/%i/$n/g;
        my ( $o, $ok ) = __PACKAGE__->_run_inner( $dev, $x, $CTX );
        die "[#] $x\n$o\n" unless $ok || $soft;
    }
    return;
}

# wg-quick up (von Hand: die Unit wg-quick@ behaelt ihren Stand): Schnittstelle mit Address/MTU, Peers aus der Datei, Routen zu den
# AllowedIPs (ohne Table = off), PreUp/PostUp.
sub _wg_up {
    my ( $dev, $n ) = @_;
    my $file = "/etc/wireguard/$n.conf";
    die "wg-quick: `$n' already exists\n" if ( ( ( $dev->{interfaces} || {} )->{$n} || {} )->{state} // 'DOWN' ) ne 'DOWN';
    my $t = _file_text( $dev, $file ) // die "wg-quick: `$file' does not exist\n";
    my $q = _wg_quick_conf($t);
    ( my $strip = $t ) =~ s/^\s*(Address|DNS|MTU|Table|PreUp|PostUp|PreDown|PostDown|SaveConfig)\s*=.*\n?//mgi;
    my $w = _wg_parse( $strip, $dev->{wg}{$n} );
    # ein UDP-Port gehoert genau einer laufenden WireGuard-Schnittstelle
    for my $o ( grep { $_ ne $n } sort keys %{ $dev->{wg} || {} } ) {
        next unless defined $w->{listen_port} && defined $dev->{wg}{$o}{listen_port} && $dev->{wg}{$o}{listen_port} eq $w->{listen_port};
        next if ( ( ( $dev->{interfaces} || {} )->{$o} || {} )->{state} // 'DOWN' ) eq 'DOWN';
        die "[#] ip link add $n type wireguard\n[#] wg setconf $n /dev/fd/63\nUnable to modify interface: Address already in use\n[#] ip link delete dev $n\n";
    }
    _wg_hooks( $dev, $n, $q->{preup} );
    $dev->{wg}{$n} = $w;
    $w->{address} = join( ', ', @{ $q->{address} } ) if $q->{address};
    my $if = $dev->{interfaces}{$n} //= {};
    $if->{addr}  = [ @{ $q->{address} || [] } ];
    $if->{mtu}   = defined $q->{mtu} ? 0 + $q->{mtu} : $if->{mtu} // 1420;
    $if->{state} = 'UP';
    my $routes = $dev->{routes} //= [];
    for my $a ( grep { m{\A[\d.]+/\d+\z} } @{ $q->{address} || [] } ) {
        my ( $ip, $len ) = split m{/}, $a;
        my $net = _n2ip( _ip2n($ip) & ( $len ? ( 0xffffffff << ( 32 - $len ) ) & 0xffffffff : 0 ) ) . "/$len";
        push @$routes, { dst => $net, dev => $n, proto => 'kernel', scope => 'link', src => $ip }
            unless grep { ( $_->{dst} // '' ) eq $net && ( $_->{dev} // '' ) eq $n } @$routes;
    }
    if ( lc( $q->{table} // '' ) ne 'off' ) {
        for my $k ( sort keys %{ $w->{peers} || {} } ) {
            for my $ip ( grep { m{\A[\d.]+/\d+\z} } @{ $w->{peers}{$k}{allowed_ips} || [] } ) {
                if ( $ip =~ m{/0\z} ) { push @GAPS, "wg-quick up $n: AllowedIPs $ip (Routing ueber fwmark)"; next }
                my $dst = $ip =~ m{/32\z} ? $ip : $ip;
                next if grep { _canon_dst( $_->{dst} // '' ) eq _canon_dst($dst) && !defined $_->{table} } @$routes;
                push @$routes, { dst => $dst, dev => $n, scope => 'link' };
            }
        }
    }
    _wg_hooks( $dev, $n, $q->{postup} );
    return "[#] ip link add $n type wireguard\n[#] wg setconf $n /dev/fd/63\n[#] ip link set mtu $if->{mtu} up dev $n";
}

# wg-quick down (zaehlt interfaces.wgN.downs): SaveConfig = true schreibt erst die laufende Konfiguration in die
# Datei (Interface-Abschnitt bleibt, Peers aus dem laufenden Zustand); Routen weg,
# PreDown/PostDown.
sub _wg_down {
    my ( $dev, $n ) = @_;
    my $file = "/etc/wireguard/$n.conf";
    die "wg-quick: `$n' is not a WireGuard interface\n"
        unless $dev->{wg}{$n} && ( ( ( $dev->{interfaces} || {} )->{$n} || {} )->{state} // 'UP' ) ne 'DOWN';
    my $t = _file_text( $dev, $file );
    my $q = defined $t ? _wg_quick_conf($t) : {};
    _wg_hooks( $dev, $n, $q->{predown}, 1 );
    if ( defined $t && ( $q->{saveconfig} // '' ) =~ /\A(?:true|yes|1)\z/i ) {
        my ($head) = $t =~ /\A(.*?)(?=^\s*\[Peer\])/ms;
        $head //= $t;
        $head =~ s/\n*\z/\n/;
        my ($peers) = _wg_conf( $dev->{wg}{$n} ) =~ /(^\[Peer\].*)\z/ms;
        _file_set( $dev, $file, $head . ( defined $peers ? "\n$peers" : '' ) );
    }
    $dev->{routes} = [ grep { ( $_->{dev} // '' ) ne $n } @{ $dev->{routes} || [] } ];
    if ( my $if = $dev->{interfaces}{$n} ) {
        $if->{state} = 'DOWN';
        $if->{downs} = ( $if->{downs} // 0 ) + 1;    # Tunnel unterbrochen (Nebenschaden sichtbar)
    }
    _wg_hooks( $dev, $n, $q->{postdown}, 1 );
    return "[#] ip link delete dev $n";
}

# Zeitpunkt des Simulators (wie date): Tue Oct 21 12:00:00 CEST 2026
our $NOW = 1792576800;

# "2 days, 3 hours ago" -> Sekunden seit 1970 (wie wg show latest-handshakes; nie = 0)
sub _wg_epoch {
    my ($h) = @_;
    return 0 unless defined $h && $h =~ /ago/;
    my %u = ( year => 365 * 86400, day => 86400, hour => 3600, minute => 60, second => 1 );
    my $s = 0;
    $s += $1 * $u{$2} while $h =~ /(\d+)\s+(year|day|hour|minute|second)s?/g;
    return $NOW - $s;
}

sub _wg_show_if {
    my ( $n, $w, $what ) = @_;
    my @l;
    my @peers = sort keys %{ $w->{peers} || {} };
    if ( defined $what ) {
        return join "\n", map { "$_\t" . join( ' ', @{ $w->{peers}{$_}{allowed_ips} || [] } ) } @peers if $what eq 'allowed-ips';
        return join "\n", @peers if $what eq 'peers';
        return join "\n", map { "$_\t" . ( $w->{peers}{$_}{endpoint} // '(none)' ) } @peers if $what eq 'endpoints';
        return $w->{public_key} // '' if $what eq 'public-key';
        return $w->{listen_port} // '' if $what eq 'listen-port';
        return join "\n", map { "$_\t" . _wg_epoch( $w->{peers}{$_}{handshake} ) } @peers if $what eq 'latest-handshakes';
        return join "\n", map { "$_\t" . ( $w->{peers}{$_}{keepalive} // 'off' ) } @peers if $what eq 'persistent-keepalive';
        if ( $what eq 'dump' ) {
            return join "\n", join( "\t", '(hidden)', $w->{public_key} // '(none)', $w->{listen_port} // 0, 'off' ), map {
                my $p = $w->{peers}{$_};
                join "\t", $_, '(none)', $p->{endpoint} // '(none)',
                    ( @{ $p->{allowed_ips} || [] } ? join( ',', @{ $p->{allowed_ips} } ) : '(none)' ),
                    _wg_epoch( $p->{handshake} ), 0, 0, $p->{keepalive} // 0;
            } @peers;
        }
        die "Invalid parameter: `$what'\n";
    }
    push @l, "interface: $n", "  public key: " . ( $w->{public_key} // '' ), '  private key: (hidden)',
        "  listening port: " . ( $w->{listen_port} // '' );
    for my $k (@peers) {
        my $p = $w->{peers}{$k};
        push @l, '', "peer: $k";
        push @l, "  endpoint: $p->{endpoint}" if defined $p->{endpoint};
        push @l, '  allowed ips: ' . ( @{ $p->{allowed_ips} || [] } ? join( ', ', @{ $p->{allowed_ips} } ) : '(none)' );
        push @l, "  latest handshake: $p->{handshake}" if defined $p->{handshake};
        push @l, "  transfer: $p->{transfer}" if defined $p->{transfer};
        push @l, "  persistent keepalive: every $p->{keepalive} seconds" if defined $p->{keepalive};
    }
    return join "\n", @l;
}

sub _wg {
    my ( $dev, $av ) = @_;
    my @a  = @$av;
    my $wg = $dev->{wg} || {};
    my $sub = shift(@a) // 'show';
    if ( $sub eq 'show' ) {
        my $n = shift @a;
        if ( !defined $n || ( $n eq 'all' && !@a ) || $n eq 'interfaces' ) {
            return ( join( "\n", sort keys %$wg ), 1 ) if defined $n && $n eq 'interfaces';
            return ( join( "\n\n", map { _wg_show_if( $_, $wg->{$_} ) } sort keys %$wg ), 1 );
        }
        if ( $n eq 'all' && @a ) {
            my $what = shift @a;
            return ( join( "\n", map { my $i = $_; map {"$i\t$_"} split /\n/, _wg_show_if( $i, $wg->{$i}, $what ) } sort keys %$wg ), 1 );
        }
        return ( "Unable to access interface: No such device", 0 ) unless $wg->{$n};
        return ( _wg_show_if( $n, $wg->{$n}, shift @a ), 1 );
    }
    if ( $sub eq 'showconf' ) {
        my $n = shift @a // return ( 'Usage: wg showconf <interface>', 0 );
        return ( "Unable to access interface: No such device", 0 ) unless $wg->{$n};
        return ( _wg_conf( $wg->{$n} ) =~ s/\n\z//r, 1 );
    }
    if ( $sub eq 'set' ) {
        my $n = shift @a // return ( 'Usage: wg set <interface> [listen-port <port>] … [peer <base64 public key> …]', 0 );
        my $w = $wg->{$n} or return ( "Unable to modify interface: No such device", 0 );
        my $peer;
        while (@a) {
            my $k = shift @a;
            if ( $k eq 'listen-port' ) { $w->{listen_port} = shift @a; next }
            if ( $k eq 'fwmark' || $k eq 'private-key' ) { shift @a; next }
            if ( $k eq 'peer' ) {
                my $key = shift @a // return ( 'Unable to parse peer key', 0 );
                return ( "Key is not the correct length or format: `$key'", 0 ) unless $key =~ m{\A[A-Za-z0-9+/]{42,43}=\z};
                $w->{peers}{$key} //= { allowed_ips => [] };
                $peer = $key;
                next;
            }
            return ( "Invalid argument: $k", 0 ) unless defined $peer;
            if ( $k eq 'remove' ) { delete $w->{peers}{$peer}; undef $peer; next }
            my $v = shift @a;
            return ( "Invalid argument: $k", 0 ) unless defined $v;
            if ( $k eq 'allowed-ips' ) {
                my @ips = grep {length} split /\s*,\s*/, $v;
                for (@ips) {
                    return ( "Unable to parse IP address: `$_'", 0 ) unless m{\A[\d.]+/\d+\z|\A[\d.]+\z|:};
                    $_ .= '/32' unless m{/} || /:/;
                }
                $w->{peers}{$peer}{allowed_ips} = \@ips;
                _wg_claim( $w, $peer );
            }
            elsif ( $k eq 'endpoint' )             { $w->{peers}{$peer}{endpoint} = $v }
            elsif ( $k eq 'persistent-keepalive' ) { $w->{peers}{$peer}{keepalive} = $v }
            elsif ( $k eq 'preshared-key' )        { }
            else { return ( "Invalid argument: $k", 0 ) }
        }
        return ( '', 1 );
    }
    if ( $sub eq 'syncconf' || $sub eq 'setconf' || $sub eq 'addconf' ) {
        my $n = shift @a // return ( "Usage: wg $sub <interface> <configuration filename>", 0 );
        my $src = shift @a // return ( "Usage: wg $sub <interface> <configuration filename>", 0 );
        return ( "Unable to modify interface: No such device", 0 ) unless $wg->{$n};
        my $text;
        my ($in) = $src =~ /\A<\(\s*wg-quick\s+strip\s+(\S+?)\)?\z/;
        if ( defined $in || ( $src eq '<(wg-quick' && ( $a[0] // '' ) eq 'strip' ) ) {
            my $f = $in // ( $a[1] // '' );    # nie $1 einer frueheren Suche
            $f =~ s/\)\z//;
            $f = $1 if $f =~ m{(wg\d+)};
            $text = _file_text( $dev, "/etc/wireguard/$f.conf" );
            $text =~ s/^\s*(Address|DNS|MTU|Table|PreUp|PostUp|PreDown|PostDown|SaveConfig)\s*=.*\n?//mgi if defined $text;
        }
        else { $text = _file_text( $dev, $src ) }
        return ( "fopen: No such file or directory", 0 ) unless defined $text;
        $wg->{$n} = _wg_parse( $text, $wg->{$n} );
        return ( '', 1 );
    }
    if ( $sub eq 'genkey' || $sub eq 'pubkey' || $sub eq 'genpsk' ) {
        return ( 'aGVsbG8tdGhpcy1pcy1hLXNpbXVsYXRlZC1rZXktMDA=', 1 );
    }
    return ( "Invalid subcommand: `$sub'\nUsage: wg <cmd> [<args>]", 0 );
}

sub _wgquick {
    my ( $dev, $av ) = @_;
    my ( $sub, $n ) = @$av;
    return ( 'Usage: wg-quick [ up | down | save | strip ] [ CONFIG_FILE | INTERFACE ]', 0 ) unless defined $n;
    $n = $1 if $n =~ m{(wg\d+)};
    my $file = "/etc/wireguard/$n.conf";
    if ( $sub eq 'strip' ) {
        my $t = _file_text( $dev, $file ) // return ( "wg-quick: `$file' does not exist", 0 );
        $t =~ s/^\s*(Address|DNS|MTU|Table|PreUp|PostUp|PreDown|PostDown|SaveConfig)\s*=.*\n?//mgi;
        return ( $t =~ s/\n\z//r, 1 );
    }
    if ( $sub eq 'save' ) {
        return ( "wg-quick: `$n' is not a WireGuard interface", 0 ) unless $dev->{wg}{$n};
        _file_set( $dev, $file, _wg_conf( $dev->{wg}{$n} ) ) if exists $dev->{files}{$file};
        return ( '', 1 );
    }
    if ( $sub eq 'down' || $sub eq 'up' ) {
        my $copy = Langertha::Holmgang::Sim::Linux::clone_state($dev);
        my $out = eval { $sub eq 'up' ? _wg_up( $copy, $n ) : _wg_down( $copy, $n ) };
        if ( my $e = $@ ) { $e =~ s/\s+\z//; return ( $e, 0 ) }
        %$dev = %$copy;
        return ( $out, 1 );
    }
    return ( 'Usage: wg-quick [ up | down | save | strip ] [ CONFIG_FILE | INTERFACE ]', 0 );
}

# --- nftables ------------------------------------------------------------------------

sub _norm_rule {
    my ($r) = @_;
    $r =~ s/\s+/ /g;
    $r =~ s/\A\s+|\s+\z//g;
    $r =~ s/\b(iifname|oifname)\s+(?!["{@]|!=|(?:v?map)\b)([^\s{}",]+)/$1 "$2"/g;
    $r =~ s/\b(iifname|oifname)\s+"([^"]+)"/$1 "$2"/g;
    return $r;
}

sub _nft_tables { my ($dev) = @_; return $dev->{nft} //= {} }

# Handles der Regeln einer Tabelle. Beim ersten Blick aus der Reihenfolge
# gezaehlt, danach fest wie in nft: eine neue Regel bekommt die naechste
# Nummer, die anderen behalten ihre. Gefuehrt in _handles/_next_handle
# (Buchfuehrung des Simulators; der Diff des Endzustands sieht sie nicht).
sub _handles {
    my ($t) = @_;
    my $chains = $t->{chains} || {};
    if ( !defined $t->{_next_handle} ) {
        my $n = 1 + scalar keys %$chains;
        for my $c ( sort keys %$chains ) { $chains->{$c}{_handles} = [ map { ++$n } @{ $chains->{$c}{rules} || [] } ] }
        $t->{_next_handle} = $n + 1;
    }
    my %h;
    for my $c ( sort keys %$chains ) {
        my $ch = $chains->{$c};
        my $n = @{ $ch->{rules} || [] };
        my $own = ref $ch->{_handles} eq 'ARRAY' ? $ch->{_handles} : [];
        splice @$own, $n if @$own > $n;
        push @$own, $t->{_next_handle}++ while @$own < $n;
        $ch->{_handles} = $own;
        $h{$c} = [@$own];
    }
    return \%h;
}

sub _nft_chain_text {
    my ( $tname, $t, $c, $with_h, $handles ) = @_;
    my $ch = $t->{chains}{$c};
    my @l  = ("\tchain $c {" . ( $with_h ? ' # handle ' . ( 1 + ( grep { $_ lt $c } keys %{ $t->{chains} } ) ) : '' ));
    if ( $ch->{type} ) {
        my $p = $ch->{priority} // 0;
        push @l, "\t\ttype $ch->{type} hook $ch->{hook} priority $p; policy " . ( $ch->{policy} // 'accept' ) . ';';
    }
    my $i = 0;
    for my $r ( @{ $ch->{rules} || [] } ) {
        push @l, "\t\t$r" . ( $with_h ? " # handle $handles->{$c}[$i]" : '' );
        $i++;
    }
    push @l, "\t}";
    return @l;
}

sub _nft_set_text {
    my ( $name, $s ) = @_;
    my @l = ( "\tset $name {", "\t\ttype " . ( $s->{type} // 'ipv4_addr' ) );
    push @l, "\t\tflags " . join( ',', @{ $s->{flags} } ) if ref $s->{flags} eq 'ARRAY' && @{ $s->{flags} };
    push @l, "\t\telements = { " . join( ', ', @{ $s->{elements} } ) . ' }' if ref $s->{elements} eq 'ARRAY' && @{ $s->{elements} };
    push @l, "\t}";
    return @l;
}

sub _nft_table_text {
    my ( $tname, $t, $with_h ) = @_;
    my $h = _handles($t);
    my @l = ( "table $tname {" . ( $with_h ? ' # handle 1' : '' ) );
    push @l, _nft_set_text( $_, $t->{sets}{$_} ), '' for sort keys %{ $t->{sets} || {} };
    my @c = sort keys %{ $t->{chains} || {} };
    for my $i ( 0 .. $#c ) {
        push @l, _nft_chain_text( $tname, $t, $c[$i], $with_h, $h );
        push @l, '' if $i < $#c;
    }
    push @l, '}';
    return @l;
}

# Regelsatz im Dateiformat von nft (wie /etc/nftables.conf): flush ruleset,
# table F T { chain C { type …; policy …; regel … } }, add/insert/delete-Zeilen.
# Alles oder nichts, wie nft -f.
sub _nft_load {
    my ( $dev, $text, $file, $check_only ) = @_;
    my $copy = { nft => Langertha::Holmgang::Sim::Linux::clone_state( $dev->{nft} || {} ) };
    my ( $table, $chain, $set, %def );
    my $n = 0;
    my $err = sub { ( "$file:$n:1-1: Error: syntax error, unexpected $_[0]\n$_[1]", 0 ) };
    for my $raw ( split /\n/, $text ) {
        $n++;
        ( my $l = $raw ) =~ s/#.*//;
        $l =~ s/\A\s+|\s+\z//g;
        next unless length $l;
        if ( $l =~ /\Adefine\s+(\w+)\s*=\s*(.+?)\s*;?\z/ ) { $def{$1} = $2; next }
        if ( $l =~ /\Ainclude\b/ ) {
            push @GAPS, "nft -f $file ($l)";
            return ( '', 0 );
        }
        $l =~ s/\$(\w+)/exists $def{$1} ? $def{$1} : "\$$1"/ge;
        return ( "$file:$n: Error: unknown identifier '$1'\n$raw", 0 ) if $l =~ /\$(\w+)/;
        if ( defined $set ) {    # Set-Block: bis die Klammern aufgehen
            $set->{text} .= " $l";
            my $open = () = $set->{text} =~ /\{/g;
            my $close = () = $set->{text} =~ /\}/g;
            next if $open > $close;
            ( my $spec = $set->{text} ) =~ s/\A\s*\{|\}\s*\z//g;
            my $e = _nft_set_spec( $copy->{nft}{$table}, $set->{name}, $spec );
            return ( "$file:$n: $e", 0 ) if $e;
            undef $set;
            next;
        }
        if ( defined $table && !defined $chain && $l =~ /\Aset\s+([\w-]+)\s*(\{.*)\z/ ) {
            $set = { name => $1, text => $2 };
            $l = $2;
            my $open = () = $l =~ /\{/g;
            my $close = () = $l =~ /\}/g;
            next if $open > $close;
            ( my $spec = $l ) =~ s/\A\s*\{|\}\s*\z//g;
            my $e = _nft_set_spec( $copy->{nft}{$table}, $set->{name}, $spec );
            return ( "$file:$n: $e", 0 ) if $e;
            undef $set;
            next;
        }
        if ( !defined $table ) {
            if ( $l eq 'flush ruleset' ) { $copy->{nft} = {}; next }
            if ( $l =~ /\Atable\s+(?:(ip|ip6|inet|arp|bridge|netdev)\s+)?(\S+)\s*\{\z/ ) {
                $table = ( $1 // 'ip' ) . " $2";
                $copy->{nft}{$table} //= { chains => {} };
                next;
            }
            if ( $l =~ /\A(?:add|insert|delete|flush|create|replace)\s/ ) {
                my ( $o, $k ) = _nft( $copy, [ split /\s+/, $l ] );
                return ( "$file:$n: $o", 0 ) unless $k;
                next;
            }
            return $err->( 'string', $raw );
        }
        if ( !defined $chain ) {
            if ( $l eq '}' ) { undef $table; next }
            if ( $l =~ /\Achain\s+(\S+)\s*\{\z/ ) {
                $chain = $1;
                $copy->{nft}{$table}{chains}{$chain} //= { rules => [] };
                next;
            }
            return $err->( 'string', $raw );
        }
        if ( $l eq '}' ) { undef $chain; next }
        my $c = $copy->{nft}{$table}{chains}{$chain};
        if ( $l =~ /\Atype\s+(\w+)\s+hook\s+(\w+)\s+(?:device\s+\S+\s+)?priority\s+([\w-]+)\s*;\s*(?:policy\s+(accept|drop)\s*;?)?\z/ ) {
            @{$c}{qw( type hook priority )} = ( $1, $2, $3 );
            $c->{policy} = $4 if defined $4;
            next;
        }
        if ( $l =~ /\Apolicy\s+(accept|drop)\s*;?\z/ ) { $c->{policy} = $1; next }
        if ( my $bad = _nft_bad_type($l) ) { return ( "$file:$n:1-1: $bad\n$raw", 0 ) }
        push @{ $c->{rules} }, _norm_rule($l);
    }
    return $err->( 'end of file', '' ) if defined $table;
    for my $t ( values %{ $copy->{nft} } ) {
        for my $r ( map { @{ $_->{rules} || [] } } values %{ $t->{chains} || {} } ) {
            if ( my $se = Langertha::Holmgang::Sim::Linux::Nft::syntax_error($r) ) { return ( "$file: $se", 0 ) }
            my $e = _nft_rule_refs( $t, $r );
            return ( "$file: $e\n$r", 0 ) if $e;
        }
    }
    # Regeln, die der Auswerter nicht versteht: Luecke (das Urteil daran waere geraten)
    for my $t ( values %{ $copy->{nft} } ) {
        for my $ch ( values %{ $t->{chains} || {} } ) { _nft_gap( $ch, $_ ) for @{ $ch->{rules} || [] } }
    }
    $dev->{nft} = $copy->{nft} unless $check_only;
    return ( '', 1 );
}

# Typnamen fuer "icmp type" / "icmpv6 type" wie nft sie kennt; ein unbekannter Name ist
# ein Fehler (nft lehnt die Regel ab), nicht still angenommen.
our %ICMP_TYPES = map { $_ => 1 } qw( echo-reply destination-unreachable source-quench redirect echo-request
    router-advertisement router-solicitation time-exceeded parameter-problem timestamp-request timestamp-reply
    info-request info-reply address-mask-request address-mask-reply );
our %ICMPV6_TYPES = map { $_ => 1 } qw( destination-unreachable packet-too-big time-exceeded parameter-problem
    echo-request echo-reply mld-listener-query mld-listener-report mld-listener-done mld-listener-reduction
    nd-router-solicit nd-router-advert nd-neighbor-solicit nd-neighbor-advert nd-redirect router-renumbering
    ind-neighbor-solicit ind-neighbor-advert mld2-listener-report );

sub _nft_bad_type {
    my ($rule) = @_;
    while ( $rule =~ /\b(icmpv6|icmp)\s+type\s+(?:!=\s*)?(\{[^}]*\}|\S+)/g ) {
        my ( $fam, $list ) = ( $1, $2 );
        my $known = $fam eq 'icmpv6' ? \%ICMPV6_TYPES : \%ICMP_TYPES;
        for my $t ( grep {length} split /[\s,{}]+/, $list ) {
            next if $t =~ /\A\d+\z/ || $known->{$t};
            return 'Error: Could not parse ' . ( $fam eq 'icmpv6' ? 'ICMPv6' : 'ICMP' ) . " type\n$t";
        }
    }
    return undef;
}

# Regel einer Filter- oder Sprungkette, die der Auswerter (Sim::Nft) nicht
# versteht: Luecke der Simulation — ein Urteil daran waere geraten. NAT-Ketten
# urteilen nicht und bleiben aussen vor.
sub _nft_gap {
    my ( $ch, $text ) = @_;
    return if defined $ch->{type} && $ch->{type} ne 'filter';
    my $why = Langertha::Holmgang::Sim::Linux::Nft::parse_error($text);
    push @GAPS, "nft: $why" if $why;
    return;
}

# Set-Angabe "type ipv4_addr; flags interval; elements = { … }" in die Tabelle;
# liefert einen Fehlertext oder undef.
sub _nft_set_spec {
    my ( $t, $name, $spec ) = @_;
    my %s = ( elements => [] );
    my $type = $spec =~ /\btype\s+(\w+)/ ? $1 : undef;
    return "Error: set definition does not specify key\nset $name" unless $type;
    return "Error: unknown datatype $type" unless $type =~ /\A(?:ipv4_addr|ipv6_addr|inet_service|ifname|inet_proto)\z/;
    $s{type} = $type;
    $s{flags} = [ split /\s*,\s*/, $1 ] if $spec =~ /\bflags\s+([\w,\s]+?)\s*(?:;|\z|elements|\})/;
    my $old = ( $t->{sets} || {} )->{$name};
    $t->{sets}{$name} = { %s, elements => $old ? [ @{ $old->{elements} || [] } ] : [] };
    if ( $spec =~ /\belements\s*=\s*\{([^}]*)\}/ ) {
        my $e = _nft_add_elements( $t->{sets}{$name}, $1 );
        return $e if $e;
    }
    return undef;
}

sub _nft_add_elements {
    my ( $s, $list ) = @_;
    my $interval = grep { $_ eq 'interval' } @{ $s->{flags} || [] };
    for my $e ( grep {length} map { s/\A\s+|\s+\z//gr } split /,/, $list ) {
        $e =~ s/\A"|"\z//g;
        if ( $s->{type} =~ /addr\z/ ) {
            my $want6 = $s->{type} eq 'ipv6_addr';
            return "Error: Could not resolve hostname: $e" unless $e =~ $want6 ? qr/:/ : qr{\A[\d./-]+\z};
            return "Error: You must add 'flags interval' to your set\nadd element $e" if $e =~ m{[/-]} && !$interval;
        }
        elsif ( $s->{type} eq 'inet_service' ) {
            return "Error: Could not resolve service: $e" unless $e =~ /\A\d+(?:-\d+)?\z|\A[a-z][\w-]*\z/;
        }
        push @{ $s->{elements} }, $e unless grep { $_ eq $e } @{ $s->{elements} };
    }
    return undef;
}

# Verweise einer Regel: benannte Sets und Ketten muessen in der Tabelle stehen
sub _nft_rule_refs {
    my ( $t, $r ) = @_;
    for my $s ( $r =~ /@([\w-]+)/g ) {
        return "Error: Could not process rule: No such file or directory\nset \@$s" unless ( $t->{sets} || {} )->{$s};
    }
    for my $c ( $r =~ /\b(?:jump|goto)\s+([^\s,}]+)/g ) {
        return "Error: Could not process rule: No such file or directory\nchain $c" unless ( $t->{chains} || {} )->{$c};
    }
    return undef;
}

# nft add|create|delete|flush set …, nft add|delete element … { … }
sub _nft_set_cmd {
    my ( $t, $tn, $verb, $obj, $cn, $rest, $syntax ) = @_;
    my $s = ( $t->{sets} || {} )->{$cn};
    if ( $obj eq 'set' ) {
        if ( $verb eq 'add' || $verb eq 'create' ) {
            return ( "Error: Could not process rule: File exists\n$verb set $tn $cn", 0 ) if $s && $verb eq 'create';
            ( my $spec = $rest ) =~ s/\A\s*\{|\}\s*\z//g;
            my $copy = Langertha::Holmgang::Sim::Linux::clone_state($t);
            my $e = _nft_set_spec( $copy, $cn, $spec );
            return ( $e, 0 ) if $e;
            %$t = %$copy;
            return ( '', 1 );
        }
        return ( "Error: Could not process rule: No such file or directory\n$verb set $tn $cn", 0 ) unless $s;
        if ( $verb eq 'delete' ) {
            my $used = grep {/\@\Q$cn\E\b/} map { @{ $_->{rules} || [] } } values %{ $t->{chains} || {} };
            return ( "Error: Could not process rule: Device or resource busy\ndelete set $tn $cn", 0 ) if $used;
            delete $t->{sets}{$cn};
            delete $t->{sets} unless %{ $t->{sets} };
        }
        elsif ( $verb eq 'flush' ) { $s->{elements} = [] }
        else { return $syntax->(qq{string "$verb"}) }
        return ( '', 1 );
    }
    return ( "Error: Could not process rule: No such file or directory\n$verb element $tn $cn", 0 ) unless $s;
    my ($list) = $rest =~ /\A\s*\{(.*)\}\s*\z/s or return $syntax->("end of file, expecting '\{'");
    if ( $verb eq 'add' || $verb eq 'create' ) {
        my $copy = Langertha::Holmgang::Sim::Linux::clone_state($s);
        my $e = _nft_add_elements( $copy, $list );
        return ( $e, 0 ) if $e;
        %$s = %$copy;
        return ( '', 1 );
    }
    if ( $verb eq 'delete' ) {
        my @del = grep {length} map { s/\A\s+|\s+\z//gr } split /,/, $list;
        for my $d (@del) {
            return ( "Error: Could not process rule: No such file or directory\ndelete element $tn $cn { $d }", 0 )
                unless grep { $_ eq $d } @{ $s->{elements} };
        }
        my %d = map { $_ => 1 } @del;
        $s->{elements} = [ grep { !$d{$_} } @{ $s->{elements} } ];
        return ( '', 1 );
    }
    return $syntax->(qq{string "$verb"});
}

# /etc/nftables.conf, wenn die Datei nicht eigens im Zustand steht: der laufende
# Regelsatz im Dateiformat (so wie ihn `nft list ruleset > …` schriebe).
sub _nft_conf {
    my ($dev) = @_;
    my @l = ( '#!/usr/sbin/nft -f', '', 'flush ruleset', '' );
    push @l, _nft_table_text( $_, $dev->{nft}{$_}, 0 ), '' for sort keys %{ $dev->{nft} || {} };
    return join( "\n", @l );
}

# Lesen legt keinen leeren Regelsatz an (sonst sieht "sonst nichts geaendert" eine Aenderung)
sub _nft {
    my ( $dev, $av ) = @_;
    my $had = exists $dev->{nft};
    my @r = _nft_cmd( $dev, $av );
    delete $dev->{nft} if !$had && ref $dev->{nft} eq 'HASH' && !%{ $dev->{nft} };
    return @r;
}

sub _nft_cmd {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $with_h, $check ) = ( 0, 0 );
    # Optionen duerfen wie bei getopt auch hinter dem Befehl stehen (nft list ruleset -a);
    # "priority -10" ist keine Option
    @a = split /\s+/, $a[0] =~ s/\A\s+//r if @a == 1 && $a[0] =~ /\s/;    # nft 'add rule …'
    my @opt;
    for ( my $i = 0; $i < @a; $i++ ) {
        next unless $a[$i] =~ /\A-[acnsejtfy]+\z|\A--(?:handle|check|json|file|echo|numeric|stateless|terse)\z/;
        next if $i > 0 && $a[ $i - 1 ] =~ /\A(?:priority|-f|--file)\z/;
        my @take = splice @a, $i, ( $a[$i] =~ /f\z|\A--file\z/ ? 2 : 1 );
        push @opt, @take;
        $i--;
    }
    unshift @a, @opt;
    while ( @a && $a[0] =~ /\A-/ ) {
        my $o = shift @a;
        $with_h = 1 if $o =~ /\A-[a-z]*a/ || $o eq '--handle';
        $check  = 1 if $o =~ /\A-[a-z]*c/ || $o eq '--check';
        return ( 'nftables v1.0.6 (Lester Gooch #5)', 1 ) if $o eq '-v' || $o eq '--version' || $o eq '-V';
        if ( $o =~ /\A-[a-z]*f\z/ || $o eq '--file' ) {
            my $f = shift @a // return ( 'nft: option requires an argument -- \'f\'', 0 );
            my $t = _file_text( $dev, $f ) // return ( "Error: Could not process rule: No such file or directory\n$f", 0 );
            return _nft_load( $dev, $t, $f, $check );
        }
        if ( $o eq '-j' || $o eq '--json' ) {
            push @GAPS, join( ' ', 'nft', @$av );
            return ( '', 0 );
        }
    }
    @a = map { split /\s+/ } @a if @a == 1;    # nft 'add rule …'
    my $verb = shift @a // return ( "Error: syntax error, unexpected end of file", 0 );
    # Lesen legt keinen nft-Zustand an (sonst saehe "sonst nichts geaendert" eine Aenderung; wie bei allen Lesebefehlen)
    my $T = $verb eq 'list' ? ( ref $dev->{nft} eq 'HASH' ? $dev->{nft} : {} ) : _nft_tables($dev);
    _handles($_) for values %$T;    # Handles stehen fest, bevor sich etwas aendert (wie im Kernel von Anfang an)
    my $syntax = sub { ( "Error: syntax error, unexpected $_[0]\n" . join( ' ', @$av ), 0 ) };
    if ( $verb eq 'list' ) {
        my $what = shift @a // return $syntax->('end of file');
        if ( $what eq 'ruleset' ) {
            my @l;
            push @l, _nft_table_text( $_, $T->{$_}, $with_h ) for sort keys %$T;
            return ( join( "\n", @l ), 1 );
        }
        if ( $what eq 'tables' ) { return ( join( "\n", map {"table $_"} sort keys %$T ), 1 ) }
        if ( $what eq 'sets' ) {
            my @l;
            for my $tn ( sort keys %$T ) {
                next unless %{ $T->{$tn}{sets} || {} };
                push @l, "table $tn {", ( map { _nft_set_text( $_, $T->{$tn}{sets}{$_} ) } sort keys %{ $T->{$tn}{sets} } ), '}';
            }
            return ( join( "\n", @l ), 1 );
        }
        my ( $fam, $tab, $chain ) = @a;
        return $syntax->('end of file') unless defined $fam;    # list ruleet u. a.: kein Objekt
        ( $fam, $tab, $chain ) = ( 'ip', $fam, $tab ) if defined $fam && $fam !~ /\A(?:ip|ip6|inet|arp|bridge|netdev)\z/;
        my $tn = "$fam $tab";
        return ( "Error: No such file or directory\nlist $what $tn", 0 ) unless $T->{$tn};
        return ( join( "\n", _nft_table_text( $tn, $T->{$tn}, $with_h ) ), 1 ) if $what eq 'table';
        if ( $what eq 'set' ) {
            my $sn = $chain // '';
            return ( "Error: No such file or directory\nlist set $tn $sn", 0 ) unless ( $T->{$tn}{sets} || {} )->{$sn};
            return ( join( "\n", "table $tn {", _nft_set_text( $sn, $T->{$tn}{sets}{$sn} ), '}' ), 1 );
        }
        if ( $what eq 'chain' ) {
            return ( "Error: No such file or directory\nlist chain $tn $chain", 0 ) unless defined $chain && $T->{$tn}{chains}{$chain};
            return ( join( "\n", "table $tn {", _nft_chain_text( $tn, $T->{$tn}, $chain, $with_h, _handles( $T->{$tn} ) ), '}' ), 1 );
        }
        return $syntax->("string \"$what\"");
    }
    if ( $verb eq 'flush' && ( $a[0] // '' ) eq 'ruleset' ) {
        %$T = ();
        return ( '', 1 );
    }
    my $obj = shift @a // return $syntax->('end of file');
    return $syntax->(qq{string "$verb"}) unless $verb =~ /\A(?:add|insert|delete|flush|create|replace)\z/;
    my $fam = shift @a // return $syntax->('end of file');
    my $tab;
    if ( $fam =~ /\A(?:ip|ip6|inet|arp|bridge|netdev)\z/ ) { $tab = shift @a }
    else { ( $fam, $tab ) = ( 'ip', $fam ) }
    return $syntax->('end of file') unless defined $tab;
    my $tn = "$fam $tab";
    if ( $obj eq 'table' ) {
        if ( $verb eq 'add' || $verb eq 'create' ) {
            return ( "Error: Could not process rule: File exists\n$verb table $tn", 0 ) if $verb eq 'create' && $T->{$tn};
            $T->{$tn} //= { chains => {} };
            return ( '', 1 );
        }
        return ( "Error: Could not process rule: No such file or directory\n$verb table $tn", 0 ) unless $T->{$tn};
        if ( $verb eq 'delete' ) { delete $T->{$tn} }
        elsif ( $verb eq 'flush' ) { $_->{rules} = [] for values %{ $T->{$tn}{chains} } }
        return ( '', 1 );
    }
    return ( "Error: Could not process rule: No such file or directory\n$verb $obj $tn", 0 ) unless $T->{$tn};
    my $t = $T->{$tn};
    my $cn = shift @a // return $syntax->('end of file');
    return _nft_set_cmd( $t, $tn, $verb, $obj, $cn, join( ' ', @a ), $syntax ) if $obj eq 'set' || $obj eq 'element';
    if ( $obj eq 'chain' ) {
        if ( $verb eq 'add' || $verb eq 'create' ) {
            my $spec = join ' ', @a;
            $spec =~ s/\A\{|\}\z//g;
            my %c = ( rules => [] );
            if ( $spec =~ /type\s+(\w+)\s+hook\s+(\w+)\s+(?:device\s+\S+\s+)?priority\s+([\w-]+)/ ) {
                @c{qw( type hook priority )} = ( $1, $2, $3 );
                $c{policy} = $1 if $spec =~ /policy\s+(accept|drop)/;
            }
            elsif ( $spec =~ /\A\s*policy\s+(accept|drop)\s*;?\s*\z/ ) { $c{policy} = $1 }
            elsif ( $spec =~ /\S/ ) { return $syntax->(qq{string "$spec"}) }
            return ( "Error: Could not process rule: File exists", 0 ) if $verb eq 'create' && $t->{chains}{$cn};
            $t->{chains}{$cn} //= \%c;
            $t->{chains}{$cn}{policy} = $c{policy} if $c{policy};
            return ( '', 1 );
        }
        return ( "Error: Could not process rule: No such file or directory\n$verb chain $tn $cn", 0 ) unless $t->{chains}{$cn};
        if    ( $verb eq 'delete' ) { delete $t->{chains}{$cn} }
        elsif ( $verb eq 'flush' )  { $t->{chains}{$cn}{rules} = []; $t->{chains}{$cn}{_handles} = [] }
        return ( '', 1 );
    }
    return $syntax->(qq{string "$obj"}) unless $obj eq 'rule';
    my $ch = $t->{chains}{$cn} or return ( "Error: Could not process rule: No such file or directory\n$verb rule $tn $cn", 0 );
    my $handles = _handles($t)->{$cn};
    my $rules   = $ch->{rules} //= [];
    my $pos;
    if ( @a >= 2 && ( $a[0] eq 'position' || $a[0] eq 'handle' || $a[0] eq 'index' ) ) {
        my ( $k, $v ) = splice @a, 0, 2;
        return $syntax->(qq{string "$v"}) unless $v =~ /\A\d+\z/;
        if ( $k eq 'index' ) {
            return ( "Error: Could not process rule: No such file or directory", 0 ) if $v > $#$rules && !( $v == 0 && !@$rules );
            $pos = $v;
        }
        else {
            my ($i) = grep { $handles->[$_] == $v } 0 .. $#$handles;
            return ( "Error: Could not process rule: No such file or directory\n$verb rule $tn $cn $k $v", 0 ) unless defined $i;
            $pos = $i;
        }
        if ( $verb eq 'delete' ) {
            splice @$rules, $pos, 1;
            splice @{ $ch->{_handles} }, $pos, 1;
            return ( '', 1 );
        }
    }
    return ( 'Error: syntax error, unexpected ' . ( !@a ? 'end of file' : $a[0] =~ /\A\d+\z/ ? 'number' : 'string' )
        . ", expecting handle\n" . join( ' ', 'delete rule', $tn, $cn, @a ), 0 ) if $verb eq 'delete';
    my $text = _norm_rule( join ' ', @a );
    return $syntax->('end of file') unless length $text;
    if ( my $bad = _nft_bad_type($text) ) { return ( "$bad\n$verb rule $tn $cn $text", 0 ) }
    return ( "Error: syntax error, unexpected number\n$verb rule $tn $cn $text", 0 ) if $text =~ /\A\d+\b/;    # Position ohne "position"/"index"
    return ( "Error: syntax error, unexpected string\n$verb rule $tn $cn $text", 0 )
        unless $text =~ /\b(?:accept|drop|reject|masquerade|snat|dnat|redirect|counter|log|jump|goto|return|continue|queue|set|notrack|meta|ct|limit|tcp|udp|icmp|icmpv6|ip|ip6)\b/;
    if ( my $e = _nft_rule_refs( $t, $text ) ) { return ( $e, 0 ) }
    if ( my $se = Langertha::Holmgang::Sim::Linux::Nft::syntax_error($text) ) { return ( $se, 0 ) }
    _nft_gap( $ch, $text );
    if ( $verb eq 'replace' ) {
        return ( "Error: syntax error, unexpected string, expecting handle", 0 ) unless defined $pos;
        $rules->[$pos] = $text;
        return ( '', 1 );
    }
    my $at = $verb eq 'insert' ? ( $pos // 0 ) : defined $pos ? $pos + 1 : scalar @$rules;
    splice @$rules, $at, 0, $text;
    splice @{ $ch->{_handles} }, $at, 0, $t->{_next_handle}++;
    return ( '', 1 );
}

# --- sysctl ------------------------------------------------------------------------

sub _sysctl {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $s = $dev->{sysctl} || {};    # nur lesen legt nichts an
    my ( $w, $all, $load, $quiet ) = ( 0, 0, undef, 0 );
    my @keys;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-w' ) { $w = 1 }
        elsif ( $x eq '-a' || $x eq '--all' ) { $all = 1 }
        elsif ( $x eq '-q' ) { $quiet = 1 }
        elsif ( $x eq '-n' || $x eq '-N' || $x eq '-e' ) { }
        elsif ( $x =~ /\A-p/ || $x eq '--load' ) { $load = @a && $a[0] !~ /\A-/ ? shift @a : '/etc/sysctl.conf' }
        elsif ( $x eq '--system' ) { $load = '--system' }
        else { push @keys, $x }
    }
    my $set = sub {
        my ( $k, $v ) = @_;
        ( my $p = $k ) =~ s{\.}{/}g;
        return "sysctl: cannot stat /proc/sys/$p: No such file or directory" unless exists $s->{$k};
        $s->{$k} = $v;
        return "$k = $v";
    };
    if ( defined $load ) {
        my @files = $load eq '--system'
            ? ( ( sort grep { m{\A/etc/sysctl\.d/.+\.conf\z} } keys %{ $dev->{files} || {} } ), '/etc/sysctl.conf' )
            : ($load);
        my @out;
    my $ok = 1;
        for my $f (@files) {
            my $t = _file_text( $dev, $f );
            if ( !defined $t ) {
                next if $load eq '--system';
                return ( "sysctl: cannot open \"$f\": No such file or directory", 0 );
            }
            push @out, "* Applying $f ..." if $load eq '--system';
            for my $l ( split /\n/, $t ) {
                $l =~ s/[#;].*//;
                next unless $l =~ /\A\s*([\w.\/-]+)\s*=\s*(.*?)\s*\z/;
                ( my $k = $1 ) =~ s{/}{.}g;
                my $r = $set->( $k, $2 );
                $ok = 0 if $r =~ /\Asysctl:/;
                push @out, $r;
            }
        }
        return ( join( "\n", @out ), $ok );
    }
    if ( $all || !@keys ) {
        return ( join( "\n", map {"$_ = $s->{$_}"} sort keys %$s ), 1 ) if $all;
        return ( "Usage:\n sysctl [options] [variable[=value] ...]", 0 );
    }
    my @out;
    my $ok = 1;
    for my $k (@keys) {
        if ( $k =~ /\A([^=]+)=(.*)\z/ ) {
            my $r = $set->( $1, $2 );
            $ok = 0 if $r =~ /\Asysctl:/;
            push @out, $r unless $quiet && $r !~ /\Asysctl:/;
            next;
        }
        if ($w) { push @out, qq{sysctl: "$k" must be of the form name=value}; $ok = 0; next }
        ( my $p = $k ) =~ s{\.}{/}g;
        if ( !exists $s->{$k} ) { push @out, "sysctl: cannot stat /proc/sys/$p: No such file or directory"; $ok = 0; next }
        push @out, "$k = $s->{$k}";
    }
    return ( join( "\n", @out ), $ok );
}

sub _conntrack {
    my ( $dev, $av ) = @_;
    my $s = $dev->{sysctl} || {};
    my $x = $av->[0] // '';
    return ( $s->{'net.netfilter.nf_conntrack_count'} // 0, 1 ) if $x eq '-C' || $x eq '--count';
    if ( $x eq '-S' || $x eq '--stats' ) {
        return ( "cpu=0   \tfound=0 invalid=0 insert=0 insert_failed=0 drop="
            . ( $dev->{conntrack_drops} // 0 ) . " early_drop=0 error=0 search_restart=0", 1 );
    }
    return ( "conntrack v1.4.7 (conntrack-tools): 0 flow entries have been shown.", 1 );
}

# --- Dateien mit Rechten und Groesse, Dateisysteme ----------------------------------

my %UNIT = ( '' => 1, B => 1, K => 1024, M => 1024**2, G => 1024**3, T => 1024**4 );

# Zeit der Simulation: Dienstag, 20.10.2026 12:00 (fest, deterministisch).
my %MON = ( Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5, Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11 );
sub _sim_now { require Time::Local; return Time::Local::timegm( 0, 0, 12, 20, 9, 2026 ) }

# Zeit der Umgebung aus pki.now (dieses Geraet, sonst eines im Zustand): Sekunden oder undef
sub _pki_now {
    my ($dev) = @_;
    for my $d ( $dev, map { values %$_ } grep { ref eq 'HASH' } ( $CTX && $CTX->{state} ) ) {
        next unless ref $d eq 'HASH' && ref $d->{pki} eq 'HASH' && $d->{pki}{now};
        my ( $Y, $M, $D, $h, $m, $sec ) = $d->{pki}{now} =~ /\A(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/ or next;
        require Time::Local;
        return Time::Local::timegm( $sec, $m, $h, $D, $M - 1, $Y );
    }
    return undef;
}

# free [-m|-h]: Speicher aus memory des Geraets (MB), sonst eine kleine VM
sub _free_mem {
    my ( $dev, $av ) = @_;
    my $m = $dev->{memory} || { total => 3936, used => 2210, free => 412, cache => 1314 };
    my $h = grep { $_ eq '-h' } @$av;
    my $f = sub { $h ? sprintf( '%.1fGi', $_[0] / 1024 ) : $_[0] };
    return ( join( "\n", '               total        used        free      shared  buff/cache   available',
        sprintf( 'Mem:    %12s%12s%12s%12s%12s%12s', $f->( $m->{total} ), $f->( $m->{used} ), $f->( $m->{free} ), $f->(12), $f->( $m->{cache} ),
            $f->( $m->{total} - $m->{used} ) ), sprintf( 'Swap:   %12s%12s%12s', $f->(0), $f->(0), $f->(0) ) ), 1 );
}

# "Aug  2 03:10" (Jahr 2026) -> Sekunden; ohne Angabe: jetzt
sub _mtime {
    my ($e) = @_;
    my $m = ( ref $e eq 'HASH' ? $e->{mtime} : undef ) // return _sim_now();
    require Time::Local;
    # aeltere Dateien wie ls sie zeigt: "Mar 12  2025" (Mitternacht)
    if ( my ( $ym, $yd, $y ) = $m =~ /\A(\w{3})\s+(\d+)\s+(\d{4})\z/ ) { return Time::Local::timegm( 0, 0, 0, $yd, $MON{$ym} // 0, $y ) }
    my ( $mon, $d, $h, $mi ) = $m =~ /\A(\w{3})\s+(\d+)\s+(\d+):(\d+)\z/ or return _sim_now();
    return Time::Local::timegm( 0, $mi, $h, $d, $MON{$mon} // 9, 2026 );
}

# Alte Journal-Archive loeschen, bis hoechstens $limit Bytes belegt sind bzw.
# keines aelter als $age Sekunden ist (system.journal bleibt).
sub _journal_vacuum {
    my ( $dev, %o ) = @_;
    my @j = sort { _mtime( _file_entry( $dev, $a ) ) <=> _mtime( _file_entry( $dev, $b ) ) || $a cmp $b }
        grep { $_ !~ m{/system\.journal\z|/user-\d+\.journal\z} } _under( $dev, '/var/log/journal' );
    my $t = 0;
    $t += _file_size( _file_entry( $dev, $_ ) ) for _under( $dev, '/var/log/journal' );
    my $freed = 0;
    for my $p (@j) {
        my $e = _file_entry( $dev, $p );
        my $old = defined $o{age} && _sim_now() - _mtime($e) > $o{age};
        my $big = defined $o{size} && $t - $freed > $o{size};
        next unless $old || $big;
        last if defined $o{size} && !defined $o{age} && !$big;
        $freed += _file_size($e);
        delete $dev->{files}{$p};
    }
    return $freed;
}

sub _secs {
    my ($v) = @_;
    my ( $n, $u ) = ( $v // '' ) =~ /\A(\d+)\s*(s|min|m|h|d|w|weeks?|days?|months?|y|seconds?|secs?|minutes?|mins|hours?|hr)?\z/ or return undef;
    my %f = ( s => 1, min => 60, m => 60, h => 3600, d => 86400, day => 86400, days => 86400, w => 604800, week => 604800,
        weeks => 604800, month => 2592000, months => 2592000, y => 31536000, second => 1, seconds => 1, sec => 1, secs => 1,
        minute => 60, minutes => 60, mins => 60, hour => 3600, hours => 3600, hr => 3600 );
    return $n * ( $f{ $u // 's' } // 1 );
}

# "14G", "1.5M", 12345 -> Bytes
sub _bytes {
    my ($v) = @_;
    return 0 unless defined $v;
    return 0 + $v if $v =~ /\A\d+\z/;
    my ( $n, $u ) = $v =~ /\A(\d+(?:\.\d+)?)\s*([BKMGT]?)i?B?\z/i or return 0;
    return int( $n * $UNIT{ uc $u } );
}

# Bytes -> wie df -h / ls -lh (1 Nachkommastelle unter 10)
sub _human {
    my ($b) = @_;
    for my $u (qw( T G M K )) {
        my $f = $UNIT{$u};
        next if $b < $f;
        my $x = $b / $f;
        return $x < 10 ? sprintf( '%.1f%s', int( $x * 10 + 0.999 ) / 10, $u ) : sprintf( '%d%s', int( $x + 0.999 ), $u );
    }
    return "$b";
}

# Ziel eines Symlinks als absoluter, bereinigter Pfad
sub _link_target {
    my ( $from, $t ) = @_;
    ( my $dir = $from ) =~ s{/[^/]+\z}{};
    $t = "$dir/$t" unless $t =~ m{\A/};
    1 while $t =~ s{/[^/]+/\.\./}{/};
    $t =~ s{/\./}{/}g;
    $t =~ s{(?<=.)/+\z}{};
    return $t;
}

# Pfad durch einen Symlink davor (/srv/app/current/x -> /srv/app/releases/1/x); undef ohne
sub _via_link {
    my ( $dev, $path, $depth ) = @_;
    return undef if ( $depth // 0 ) > 5 || ref $dev->{files} ne 'HASH';
    my @seg = split m{/}, $path;
    for my $i ( 1 .. $#seg - 1 ) {
        my $pre = join '/', @seg[ 0 .. $i ];
        my $e = $dev->{files}{$pre};
        next unless ref $e eq 'HASH' && defined $e->{link};
        my $new = join '/', _link_target( $pre, $e->{link} ), @seg[ $i + 1 .. $#seg ];
        return _via_link( $dev, $new, ( $depth // 0 ) + 1 ) // $new;
    }
    return undef;
}

# Eintrag einer Datei als Hash { content, size, mode, owner, group, open_by, link } (Kopie fuer Text)
sub _file_entry {
    my ( $dev, $path ) = @_;
    return _file_entry( $dev, _dotdot($path) ) if $path =~ m{\A/.*/\.\.?(?:/|\z)};
    if ( !( ref $dev->{files} eq 'HASH' && exists $dev->{files}{$path} ) && defined( my $r = _via_link( $dev, $path ) ) ) {
        return _file_entry( $dev, $r );
    }
    if ( !( ref $dev->{files} eq 'HASH' && exists $dev->{files}{$path} ) && ( my $v = _git_virtual( $dev, $path ) ) ) {
        return defined $v->{text} ? { content => $v->{text}, mode => '0644', owner => $dev->{forgejo} ? 'git' : 'root', group => $dev->{forgejo} ? 'git' : 'root' } : undef;
    }
    return undef unless ref $dev->{files} eq 'HASH' && exists $dev->{files}{$path};
    my $e = $dev->{files}{$path};
    return ref $e eq 'HASH' ? $e : { content => $e };
}

sub _file_size {
    my ($e) = @_;
    return _bytes( $e->{size} ) if defined $e->{size};
    return length( $e->{content} // '' );
}

# Inhalt setzen; Metadaten (Rechte, Eigentuemer) bleiben, eine feste Groesse faellt weg.
sub _file_set {
    my ( $dev, $path, $text ) = @_;
    my $old = $dev->{files}{$path};
    if ( ref $old eq 'HASH' ) {
        my %e = %$old;
        delete @e{qw( size link )};
        $e{content} = $text;
        $dev->{files}{$path} = \%e;
    }
    else { $dev->{files}{$path} = $text }
    return;
}

# Verzeichnisse ergeben sich aus den Dateipfaden (und den Einhaengepunkten).
# Verzeichnisse, die jedes Debian 12 (mit cron, OpenSSH, sudo) hat — leer, wenn der Zustand nichts darin nennt
our %STD_DIRS = map { $_ => 1 } qw( /bin /boot /dev /etc /home /lib /media /mnt /opt /proc /root /run /sbin /srv /sys /tmp
    /usr /usr/bin /usr/sbin /usr/lib /usr/local /usr/local/bin /usr/local/sbin /usr/local/etc /usr/local/lib /usr/share
    /var /var/backups /var/cache /var/lib /var/log /var/mail /var/spool /var/tmp /var/spool/cron /var/spool/cron/crontabs
    /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly /etc/default /etc/ssh /etc/ssh/sshd_config.d
    /etc/sudoers.d /etc/sysctl.d /etc/systemd /etc/systemd/system /etc/security /etc/ssl /etc/ssl/certs /etc/ssl/private
    /etc/logrotate.d /etc/apt /etc/network /lib/systemd /lib/systemd/system );

sub _is_dir {
    my ( $dev, $path ) = @_;
    $path = _dotdot($path) if $path =~ m{\A/.*/\.\.?(?:/|\z)};
    $path =~ s{/+\z}{};
    return 1 if $STD_DIRS{$path};
    return 1 if $path eq '' || exists( ( $dev->{mounts} || {} )->{$path} );
    return 1 if exists( ( $dev->{dirs} || {} )->{$path} );
    return 1 if exists( ( $dev->{_dirs} || {} )->{$path} );    # leer geraeumt (rm, mv): bleibt
    my $e = ref $dev->{files} eq 'HASH' ? $dev->{files}{$path} : undef;
    return _is_dir( $dev, _link_target( $path, $e->{link} ), ( $_[2] // 0 ) + 1 ) if ref $e eq 'HASH' && defined $e->{link} && ( $_[2] // 0 ) < 5;
    if ( !defined $e && defined( my $r = _via_link( $dev, $path ) ) ) { return _is_dir( $dev, $r ) }
    if ( my $v = _git_virtual( $dev, $path ) ) { return 1 if $v->{dir} }
    return scalar grep { index( $_, "$path/" ) == 0 } keys %{ $dev->{files} || {} };
}

sub _under {
    my ( $dev, $path ) = @_;
    $path =~ s{/+\z}{};
    return sort grep { $path eq '' ? 1 : index( $_, "$path/" ) == 0 } keys %{ $dev->{files} || {} };
}

# Einhaengepunkte; ohne Angabe im Fall ein Wurzeldateisystem mit reichlich Platz
sub _mounts {
    my ($dev) = @_;
    return $dev->{mounts} if ref $dev->{mounts} eq 'HASH' && %{ $dev->{mounts} };
    return { '/' => { dev => '/dev/vda1', size => '40G', used => '9G' } };
}

# mount: die Einhaengepunkte mit Typ und Optionen
sub _mount_cmd {
    my ( $dev, $av ) = @_;
    if ( grep { !/\A-/ } @$av ) { push @GAPS, join( ' ', 'mount', @$av ); return ( '', 0 ) }
    my $m = _mounts($dev);
    my @l = map { my $x = $m->{$_}; sprintf '%s on %s type %s (%s)', $x->{dev} // '/dev/vda1', $_, $x->{fstype} // ( ( $x->{dev} // '' ) eq 'tmpfs' ? 'tmpfs' : 'ext4' ),
        $x->{options} // 'rw,relatime' } sort keys %$m;
    unshift @l, 'proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)', 'sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)';
    return ( join( "\n", @l ), 1 );
}

sub _mount_of {
    my ( $dev, $path ) = @_;
    my ($best) = sort { length $b <=> length $a }
        grep { $_ eq '/' || $path eq $_ || index( $path, "$_/" ) == 0 } keys %{ _mounts($dev) };
    return $best;
}

# Belegung je Einhaengepunkt: Grundlast + Dateien + geloeschte, noch offene Dateien
sub _df_rows {
    my ($dev) = @_;
    my $m = _mounts($dev);
    my %used = map { $_ => _bytes( $m->{$_}{used} ) } keys %$m;
    for my $p ( keys %{ $dev->{files} || {} } ) {
        my $mp = _mount_of( $dev, $p ) // next;
        $used{$mp} += _file_size( _file_entry( $dev, $p ) );
    }
    for my $d ( @{ $dev->{deleted_open} || [] } ) {
        my $mp = _mount_of( $dev, $d->{path} ) // next;
        $used{$mp} += _bytes( $d->{size} );
    }
    return map {
        my $size = _bytes( $m->{$_}{size} );
        my $u = $used{$_} > $size ? $size : $used{$_};
        # fuer root reservierte Bloecke (ext*, reserved_pct) stehen anderen nicht zur Verfuegung
        my $res = int( $size * ( $m->{$_}{reserved_pct} // 0 ) / 100 );
        my $av = $size - $u - $res > 0 ? $size - $u - $res : 0;
        +{ mount => $_, dev => $m->{$_}{dev} // '/dev/vda1', size => $size, used => $u, avail => $av, type => $m->{$_}{fstype} // 'ext4',
            pct => $u + $av ? int( 100 * $u / ( $u + $av ) + 0.999 ) : 0 };
    } sort keys %$m;
}

sub _free {
    my ( $dev, $mount ) = @_;
    my ($r) = grep { $_->{mount} eq $mount } _df_rows($dev);
    return $r ? $r->{avail} : undef;
}

sub _df {
    my ( $dev, $av ) = @_;
    my $h = grep {/\A-\w*h/} @$av;
    my @paths = grep { !/\A-/ } @$av;
    my @rows = _df_rows($dev);
    return ( 'df: no file systems processed', 0 ) unless @rows;
    if (@paths) {
        my %want;
        for my $p (@paths) {
            my $mp = _mount_of( $dev, $p );
            return ( "df: $p: No such file or directory", 0 ) unless defined $mp && ( _is_dir( $dev, $p ) || _file_entry( $dev, $p ) );
            $want{$mp} = 1;
        }
        @rows = grep { $want{ $_->{mount} } } @rows;
    }
    my $f = $h ? sub { _human( $_[0] ) } : sub { int( $_[0] / 1024 ) };
    my $ty = grep { /\A-\w*T/ || $_ eq '--print-type' } @$av;
    my @l = ( sprintf( '%-15s ' . ( $ty ? '%-5s ' : '%s' ) . '%6s %6s %6s %4s %s', 'Filesystem', $ty ? 'Type' : '', $h ? 'Size' : '1K-blocks', 'Used', 'Avail', 'Use%', 'Mounted on' ) );
    push @l, sprintf( '%-15s ' . ( $ty ? '%-5s ' : '%s' ) . '%6s %6s %6s %4s %s', $_->{dev}, $ty ? $_->{type} : '', $f->( $_->{size} ), $f->( $_->{used} ), $f->( $_->{avail} ), "$_->{pct}%", $_->{mount} )
        for @rows;
    return ( join( "\n", @l ), 1 );
}

sub _du {
    my ( $dev, $av ) = @_;
    my $h = grep {/\A-\w*h/} @$av;
    my $sum = grep {/\A-\w*s/} @$av;
    my @paths = grep { !/\A-/ } @$av;
    @paths = ('.') unless @paths;
    my @l;
    for my $p (@paths) {
        my $total;
        if ( my $e = _file_entry( $dev, $p ) ) { $total = _file_size($e) }
        elsif ( _is_dir( $dev, $p ) ) {
            $total = 0;
            my %sub;
            for my $f ( _under( $dev, $p ) ) {
                my $sz = _file_size( _file_entry( $dev, $f ) );
                $total += $sz;
                ( my $d = $f ) =~ s{/[^/]+\z}{};
                while ( length $d > length $p ) { $sub{$d} += $sz; $d =~ s{/[^/]+\z}{} }
            }
            if ( !$sum ) { push @l, ( $h ? _human( $sub{$_} ) : int( $sub{$_} / 1024 ) ) . "\t$_" for sort { length $b <=> length $a || $a cmp $b } keys %sub }
        }
        else { return ( "du: cannot access '$p': No such file or directory", 0 ) }
        push @l, ( $h ? _human($total) : int( $total / 1024 ) ) . "\t$p";
    }
    return ( join( "\n", @l ), 1 );
}

sub _mode_of { my ($e) = @_; return oct( $e->{mode} // '0644' ) }

sub _mode_text {
    my ( $m, $dir, $link ) = @_;
    my $s = $link ? 'l' : $dir ? 'd' : '-';
    for my $sh ( 6, 3, 0 ) {
        my $b = ( $m >> $sh ) & 7;
        my $sp = $m & { 6 => 04000, 3 => 02000, 0 => 01000 }->{$sh};
        my $x = $sp ? ( $sh ? ( $b & 1 ? 's' : 'S' ) : ( $b & 1 ? 't' : 'T' ) ) : ( $b & 1 ? 'x' : '-' );
        $s .= ( $b & 4 ? 'r' : '-' ) . ( $b & 2 ? 'w' : '-' ) . $x;
    }
    return $s;
}

sub _ls_line {
    my ( $dev, $path, $name, $h ) = @_;
    my $e = _file_entry( $dev, $path );
    if ( !$e && defined( my $b = _virtual_bin( $dev, $path ) ) ) { return _bin_ls_line( $b, $name ) }
    if ( !$e ) {
        my $d = ( $dev->{dirs} || {} )->{$path} || {};
        return sprintf( '%s 2 %-8s %-8s %8s %s %s', _mode_text( oct( $d->{mode} // '0755' ), 1 ), $d->{owner} // 'root',
            $d->{group} // 'root', 4096, _ls_time($d), $name );
    }
    my $size = _file_size($e);
    return sprintf( '%s 1 %-8s %-8s %8s %s %s%s', _mode_text( $e->{link} ? 0777 : _mode_of($e), 0, $e->{link} ) =~ s/\A-/( $e->{type} \/\/ '' ) eq 'socket' ? 's' : '-'/er,
        $e->{owner} // 'root', $e->{group} // 'root', $h ? _human($size) : $size, _ls_time($e), $name,
        $e->{link} ? " -> $e->{link}" : '' );
}

sub _ls {
    my ( $dev, $av ) = @_;
    local $BIN_MEMO = {};
    local $LS_TIME;
    for (@$av) {
        if ( $_ eq '--full-time' ) { $LS_TIME = 'full-iso' }
        elsif (/\A--time-style=(?:posix-)?(full-iso|long-iso|iso)\z/) { $LS_TIME = $1 }
    }
    my $opt = join '', map { /\A-(\w+)\z/ ? $1 : '' } @$av;
    $opt .= 'l' if grep { $_ eq '--full-time' } @$av;
    my @paths = grep { !/\A-/ } @$av;
    @paths = ('.') unless @paths;    # ohne Pfad: das aktuelle Verzeichnis
    @paths = sort @paths unless $opt =~ /[fU]/;    # Operanden sortiert wie GNU ls
    my ( $long, $h, $rec ) = ( $opt =~ /[ln]/ ? 1 : 0, $opt =~ /h/ ? 1 : 0, $opt =~ /R/ ? 1 : 0 );
    my $all = $opt =~ /a/;
    my $hidden_ok = $all || $opt =~ /A/;
    my $multi = @paths > 1 || $rec;
    my ( @out, @files_out );
    my $ok = 1;
    # erst Dateien, dann Verzeichnisse (wie GNU ls)
    my @dirs;
    for my $p (@paths) {
        ( my $dir = _absp($p) ) =~ s{(?<=.)/+\z}{};    # relativ zum aktuellen Verzeichnis, angezeigt wie angegeben
        my $le = ref $dev->{files} eq 'HASH' ? $dev->{files}{$dir} : undef;
        my $followed;
        if ( ref $le eq 'HASH' && defined $le->{link} && ( $opt !~ /[ld]/ || $p =~ m{/\z} ) && _is_dir( $dev, $dir ) ) {
            $dir = _link_target( $dir, $le->{link} );    # ls link/ bzw. ohne -l: Inhalt des Ziels
            $followed = 1;
        }
        elsif ( !$le && defined( my $r = _via_link( $dev, $dir ) ) ) { $dir = $r }
        # als Benutzer: x auf dem Weg, r am Verzeichnis
        if ( _who() ne 'root' && ( _file_entry( $dev, $dir ) || _is_dir( $dev, $dir ) ) ) {
            if ( !_traverse_ok( $dev, $dir ) ) { push @out, "ls: cannot access '$p': Permission denied"; $ok = 0; next }
            if ( !_file_entry( $dev, $dir ) && $opt !~ /d/ && !_dir_ok( $dev, $dir, 4 ) ) {
                push @out, "ls: cannot open directory '$p': Permission denied";
                $ok = 0;
                next;
            }
        }
        # usrmerge: /bin und /sbin sind Verweise nach usr/ (ls -l zeigt den Verweis)
        if ( $dir =~ m{\A/s?bin\z} && $opt =~ /[ld]/ && $p !~ m{/\z} && !$le ) {
            push @files_out, $long ? sprintf( 'lrwxrwxrwx 1 root root %d Oct 20 09:00 %s -> usr%s', length("usr$dir"), $p, $dir ) : $p;
            next;
        }
        if ( defined( my $b = _virtual_bin( $dev, $dir ) ) ) { push @files_out, $long ? _bin_ls_line( $b, $p ) : $p; next }
        if ( $opt =~ /d/ && _is_dir( $dev, $dir ) && !_file_entry( $dev, $dir ) ) {
            push @files_out, $long ? _ls_line( $dev, $dir, $p, $h ) : $p;
            next;
        }
        if ( !$followed && _file_entry( $dev, $dir ) ) {    # auch mit / am Ende (pg_wal/ steht als ein Eintrag im Zustand)
            push @files_out, $long ? _ls_line( $dev, $dir, $p, $h ) : $p;
            next;
        }
        if ( $dev->{storage} && $dir =~ m{\A/dev/} ) {    # Blockgeraete
            _part('Storage');
            if ( Langertha::Holmgang::Sim::Linux::Storage::canon( $dev, $dir ) ) {
                push @files_out, $long ? "brw-rw---- 1 root disk 254, 0 Oct 20 09:00 $p" : $p;
                next;
            }
        }
        my $names = _ls_names( $dev, $dir );
        if ( !%$names && !_is_dir( $dev, $dir ) && $dir ne '/root' && $dir ne '/' ) {
            push @out, "ls: cannot access '$p': No such file or directory";
            $ok = 0;
            next;
        }
        push @dirs, [ $p, $dir ];    # wie angegeben, aufgeloest (Symlink)
    }
    push @out, @files_out;
    my @queue = @dirs;
    while ( defined( my $q = shift @queue ) ) {
        my ( $p, $dir ) = @$q;
        my $names = _ls_names( $dev, $dir );
        my @n = sort grep { $hidden_ok || !/\A\./ } keys %$names;
        if ( $opt =~ /t/ ) {    # -t: neueste zuerst (gleich alt: nach Namen)
            my %mt = map { my $e = _file_entry( $dev, "$dir/$_" ); ( $_ => $e ? _mtime($e) : _mtime( ( $dev->{dirs} || {} )->{"$dir/$_"} ) ) } @n;
            @n = sort { $mt{$b} <=> $mt{$a} || $a cmp $b } @n;
        }
        @n = reverse @n if $opt =~ /r/;
        push @out, '' if $multi && @out;
        push @out, "$p:" if $multi;
        if ($long) {
            push @out, 'total ' . 4 * ( @n + ( $all ? 2 : 0 ) );
            if ($all) {
                ( my $up = $dir ) =~ s{/[^/]+\z}{};
                push @out, _ls_line( $dev, $dir, '.', $h ), _ls_line( $dev, length $up ? $up : '/', '..', $h );
            }
            for (@n) {
                push @out, ref $names->{$_}
                    ? sprintf( 'lrwxrwxrwx 1 root     root     %8d Oct 20 09:00 %s -> %s', length ${ $names->{$_} }, $_, ${ $names->{$_} } )
                    : $dir eq '/dev' && $dev->{storage} && !_file_entry( $dev, "/dev/$_" ) && !_is_dir( $dev, "/dev/$_" )
                    ? "brw-rw---- 1 root disk 254, 0 Oct 20 09:00 $_"
                    : _ls_line( $dev, ( $dir eq "/" ? "" : $dir ) . "/$_", $_, $h );
            }
        }
        else {
            my @x = ( $all ? ( '.', '..' ) : (), @n );
            push @out, @x;    # ohne Terminal (Werkzeug-Aufruf): ein Name je Zeile
        }
        if ($rec) {
            my $base = $p =~ m{/\z} ? $p : "$p/";
            unshift @queue, map { [ "$base$_", ( $dir eq "/" ? "" : $dir ) . "/$_" ] } grep { !ref $names->{$_} && !_file_entry( $dev, "$dir/$_" ) && _is_dir( $dev, "$dir/$_" ) } @n;
        }
    }
    return ( join( "\n", @out ), $ok );
}

# Namen in einem Verzeichnis: Dateien, Unterverzeichnisse, virtuelle Eintraege
# (wg, /proc/sys, *.wants von systemd als Verweise: Wert ist dann \"ziel")
sub _ls_names {
    my ( $dev, $dir ) = @_;
    my %names;
    my $pre = $dir eq '/' ? '/' : "$dir/";
    for my $f ( keys %{ $dev->{files} || {} } ) {
        $names{$1} = 1 if index( $f, $pre ) == 0 && substr( $f, length $pre ) =~ m{\A([^/]+)};
    }
    for my $d ( keys %{ $dev->{dirs} || {} }, keys %{ $dev->{_dirs} || {} }, keys %{ $dev->{mounts} || {} } ) { $names{$1} = 1 if index( $d, $pre ) == 0 && substr( $d, length $pre ) =~ m{\A([^/]+)} }
    if ( $dir eq '/dev' && $dev->{storage} ) { $names{$_} = 1 for grep {defined} map { m{\A/dev/([^/]+)\z} ? $1 : () } keys %{ $dev->{storage}{disks} || {} }, keys %{ $dev->{storage}{md} || {} } }
    if ( $dir eq '/' ) { $names{$_} //= 1 for @ROOT_DIRS }
    if ( my $v = _git_virtual( $dev, $dir ) ) { $names{$_} //= 1 for @{ $v->{dir} || [] } }
    $names{'.git'} //= 1 if exists( ( ( $dev->{git} || {} )->{repos} || {} )->{$dir} );
    if ( $dir eq '/etc/wireguard' ) { $names{"$_.conf"} = 1 for keys %{ $dev->{wg} || {} } }
    if ( $dir =~ m{\A/proc/sys(?:/(.+))?\z} ) {
        my $p = defined $1 ? ( $1 =~ tr{/}{.}r ) . '.' : '';
        for my $k ( keys %{ $dev->{sysctl} || {} } ) { $names{$1} = 1 if $k =~ /\A\Q$p\E([^.]+)/ }
    }
    if ( $dir =~ m{\A/etc/systemd/system/([\w.@-]+\.(?:target|service))\.wants\z} ) {
        my $w = _wants($dev);
        $names{ $_->[0] } = \$_->[1] for @{ $w->{$1} || [] };
    }
    if ( $dir eq '/etc/systemd/system' ) { $names{"$_.wants"} = 1 for keys %{ _wants($dev) } }
    if ( $dir =~ m{\A(?:/usr)?/(s?bin)\z} ) { $names{$_} //= 1 for _bin_names( $dev, $1 ) }
    return \%names;
}

# Programme in /usr/bin bzw. /usr/sbin (usrmerge: /bin und /sbin verweisen dorthin): genau
# die, die which auf diesem Geraet findet — was ls zeigt, passt zu which, type und
# "command not found"
sub _bin_names {
    my ( $dev, $kind ) = @_;
    return @{ $BIN_MEMO->{$kind} //= [ _bin_names_all( $dev, $kind ) ] } if $BIN_MEMO;
    return _bin_names_all( $dev, $kind );
}

sub _bin_names_all {
    my ( $dev, $kind ) = @_;
    my %exec = map { ( $_->{exec} // '' ) => 1 } grep { ref eq 'HASH' } values %{ $dev->{services} || {} };
    my @cand = grep { /\A(?:\[|[A-Za-z0-9_][\w.+@-]*)\z/ } keys %CMD, keys %REAL, keys %FILTER, keys %INTERACTIVE, keys %exec,
        qw( ls bash sh cat cp mv rm mkdir tail head grep sed awk find echo printf true false test [ );
    my %seen;
    my @n;
    for my $n ( sort grep { !$seen{$_}++ } @cand ) {
        my ( $p, $ok ) = _which( 'which', $dev, [$n] );
        push @n, $n if $ok && $p eq "/usr/$kind/$n";
    }
    return @n;
}

# Programm aus _bin_names unter /usr/bin, /bin, /usr/sbin, /sbin? Liefert den Namen oder undef
sub _virtual_bin {
    my ( $dev, $path ) = @_;
    my ( $kind, $n ) = $path =~ m{\A(?:/usr)?/(s?bin)/([^/]+)\z} or return undef;
    return undef if _file_entry( $dev, $path );
    return ( grep { $_ eq $n } _bin_names( $dev, $kind ) ) ? $n : undef;
}

sub _bin_ls_line {
    my ( $n, $shown ) = @_;
    return sprintf( '-rwxr-xr-x 1 root     root     %8d Oct 20 09:00 %s', 30000 + 113 * unpack( '%32C*', $n ), $shown );
}

# Welche Units in welchem *.wants haengen (enabled): { ziel => [ [ unit, unit-datei ] ] }
sub _wants {
    my ($dev) = @_;
    my %w;
    for my $n ( sort keys %{ $dev->{services} || {} } ) {
        my $svc = $dev->{services}{$n};
        next if $svc->{masked} || !_symlinked( $dev, $n, $svc );
        my ($wb) = ( _unit_text( $dev, $n, $svc ) // '' ) =~ /^\s*WantedBy\s*=\s*(\S+)/m;
        $wb //= $svc->{wanted_by} // ( $n =~ /\.timer\z/ ? 'timers.target' : 'multi-user.target' );
        push @{ $w{$wb} }, [ _uname($n), _unit_file( $n, $svc ) ];
    }
    return \%w;
}

# Hat die Unit einen Verweis in einem *.wants? (enabled; static nur, wenn ausdruecklich enabled)
sub _symlinked {
    my ( $dev, $n, $svc ) = @_;
    return $svc->{enabled} ? 1 : 0 if exists $svc->{enabled};
    return _static( $dev, $n, $svc ) ? 0 : 1;
}

sub _stat {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $fmt;
    for ( my $i = 0; $i < @a; $i++ ) {
        if ( $a[$i] eq '-c' || $a[$i] eq '--format' || $a[$i] eq '--printf' ) { $fmt = $a[ $i + 1 ]; splice @a, $i, 2; last }
        if ( $a[$i] =~ /\A--(?:format|printf)=(.*)\z/s ) { $fmt = $1; splice @a, $i, 1; last }
    }
    if ( defined $fmt ) {
        my @out;
        for my $p ( grep { !/\A-/ } @a ) {
            my $e = _file_entry( $dev, $p );
            my $d = !$e && _is_dir( $dev, $p ) ? ( ( $dev->{dirs} || {} )->{$p} || {} ) : undef;
            return ( "stat: cannot statx '$p': No such file or directory", 0 ) unless $e || $d;
            my $m = $e ? _mode_of($e) : oct( $d->{mode} // '0755' );
            my $x = $e // $d;
            my %v = ( a => sprintf( '%o', $m ), A => _mode_text( $m, !$e ), U => $x->{owner} // 'root', G => $x->{group} // 'root',
                n => $p, s => $e ? _file_size($e) : 4096, u => _uid( $dev, $x->{owner} ), g => _gid( $dev, $x->{group} ),
                F => $e ? 'regular file' : 'directory', '%' => '%' );
            my ( $iso, $ep ) = _mtime_iso( $x );
            $v{$_} = $iso for qw( y x z );
            $v{$_} = $ep for qw( Y X Z );
            ( my $line = $fmt ) =~ s/%(.)/$v{$1} \/\/ "%$1"/ge;
            $line =~ s/\\n/\n/g;
            push @out, $line;
        }
        return ( join( "\n", @out ), 1 );
    }
    my @out;
    for my $p ( grep { !/\A-/ } @a ) {
        if ( !_file_entry( $dev, $p ) && _is_dir( $dev, $p ) ) {    # Verzeichnis
            my $d = ( $dev->{dirs} || {} )->{ $p =~ s{(?<=.)/+\z}{}r } || {};
            my $m = oct( $d->{mode} // '0755' );
            push @out, "  File: $p", "  Size: 4096\tBlocks: 8\tIO Block: 4096   directory",
                sprintf( 'Access: (%04o/%s)  Uid: (%5d/%8s)   Gid: (%5d/%8s)', $m, _mode_text( $m, 1 ), _uid( $dev, $d->{owner} ), $d->{owner} // 'root',
                    _gid( $dev, $d->{group} ), $d->{group} // 'root' );
            next;
        }
        my $e = _file_entry( $dev, $p ) or return ( "stat: cannot statx '$p': No such file or directory", 0 );
        my $m = _mode_of($e);
        push @out, "  File: $p", "  Size: " . _file_size($e) . "\tBlocks: 8\tIO Block: 4096   regular file",
            sprintf( 'Access: (%04o/%s)  Uid: (%5d/%8s)   Gid: (%5d/%8s)', $m, _mode_text($m), _uid( $dev, $e->{owner} ), $e->{owner} // 'root',
                _gid( $dev, $e->{group} ), $e->{group} // 'root' ),
            ( map { "$_: " . ( _mtime_iso($e) )[0] } qw( Access Modify Change ) ), ' Birth: -';
    }
    return ( join( "\n", @out ), 1 );
}

# Prozesse: je laufender Dienst einer (exec), PID fest nach Namen sortiert
# Prozesse der laufenden Dienste: Befehlszeile aus der Fassung, mit der sie laufen (_started,
# ExecStart), sonst exec; gunicorn mit seinen Workern (--workers/-w, sonst workers = in der
# --config-Datei, sonst 1) als Kinder des Masters
sub _procs {
    my ($dev) = @_;
    my $s = $dev->{services} || {};
    my $pid = 400;
    my @p;
    for my $n ( grep { $s->{$_}{active} } sort keys %$s ) {
        $pid += 37;
        my $svc  = $s->{$n};
        my $pid = $svc->{_pid} // $pid;    # im Simulator (neu) gestartet: eigene PID
        my $line = ( ( $svc->{_started} || {} )->{ExecStart} || [] )->[0];
        my $cmd  = defined $line ? ( $line =~ s/\A[-@+!:]+//r ) : $svc->{exec} // $n;
        $cmd =~ s/\$\{?MAINPID\}?/$pid/g;
        my $user = $svc->{user} // ( $svc->{_started} || {} )->{User} // 'root';
        push @p, { pid => $pid, ppid => 1, user => $user, cmd => $cmd, unit => $n };
        if ( $cmd =~ /\bgunicorn\b/ ) {
            my ($w) = $cmd =~ /(?:--workers[ =]|-w\s*)(\d+)/;
            if ( !defined $w && $cmd =~ /(?:--config[ =]|-c\s+)(\S+)/ ) { ($w) = ( _file_text( $dev, $1 ) // '' ) =~ /^\s*workers\s*=\s*(\d+)/m }
            push @p, map { { pid => $pid + $_, ppid => $pid, user => $user, cmd => $cmd, unit => $n } } 1 .. ( $w // 1 );
        }
    }
    return @p;
}

sub _main_pid {
    my ( $dev, $n ) = @_;
    my ($p) = grep { $_->{unit} eq $n } _procs($dev);
    return $p ? $p->{pid} : 0;
}

# Startzeit eines Dienstes (Epoche): der letzte Start im Simulator (_since, Zeit der
# Journalzeile "Started"), sonst since im Zustand ("Thu 2026-10-29 06:10:12 CET"), sonst undef
our $BOOT_STAMP = 'Tue 2026-10-20 09:00:00 CEST';    # Vorgabe fuer laufende Dienste ohne Angabe
sub _svc_since {
    my ($svc) = @_;
    return $svc->{_since} if defined $svc->{_since};
    return _parse_stamp( $svc->{since} );
}

# Jetzt auf dem Geraet (Epoche): seine Uhr (clock), sonst die der Simulation
sub _dev_now {
    my ($dev) = @_;
    return _sim_now() unless defined $dev->{clock};
    _part('Monitoring');
    return Langertha::Holmgang::Sim::Linux::Monitoring::now_epoch($dev);
}

# "5h ago" wie systemd; ein Start in derselben Minute wie die Uhr ist "1s ago"
sub _ago {
    my ( $dev, $t ) = @_;
    my $s = _dev_now($dev) - $t;
    return Langertha::Holmgang::Sim::Linux::Calendar::left( $s > 0 ? $s : 1 ) . ' ago';
}

# Startzeit eines Prozesses fuer ps: die seines Dienstes oder undef (Vorgabe von ps)
sub _proc_since {
    my ( $dev, $p ) = @_;
    my $svc = defined $p->{unit} ? ( $dev->{services} || {} )->{ $p->{unit} } : undef;
    return $svc ? _svc_since($svc) : undef;
}

# Zeilen, die ein laufender Dienst in seine Logdatei geschrieben hat (app_log), als
# Laufzeitspur _append: { pfad => { base => inhalt beim Schreiben, lines => [ … ] } } —
# sie gelten nur, solange die Datei den Inhalt von damals hat (sonst neu geschrieben)
sub _with_append {
    my ( $dev, $path, $t ) = @_;
    return $t unless defined $t;
    my $a = ( $dev->{_append} || {} )->{$path} or return $t;
    return $t unless $a->{base} eq $t;
    return $t . ( length $t && $t !~ /\n\z/ ? "\n" : '' ) . join( '', map {"$_\n"} @{ $a->{lines} } );
}

# app_log eines Dienstes: { file, start: [ zeilen ], fail: [ zeilen ] } — bei Start bzw.
# Fehlstart angehaengt; {ts} (JJJJ-MM-TT HH:MM:SS, Uhr des Geraets), {listen}, {pid}
sub _app_log {
    my ( $dev, $n, $svc, $kind, $t ) = @_;
    my $al = $svc->{app_log};
    return unless ref $al eq 'HASH' && defined $al->{file};
    my @lines = @{ $al->{$kind} || [] } or return;
    require POSIX;
    $t //= _jtime( sprintf '%s:%02d x', _clock($dev), 3 + ( ( $dev->{_tick} // 0 ) + 1 ) % 57 );
    my %v = ( ts => POSIX::strftime( '%Y-%m-%d %H:%M:%S', _local_tm($t) ), pid => _main_pid( $dev, $n ) || 3120,
        listen => ( $kind eq 'start' && $svc->{_listen} ? $svc->{_listen} : [ _svc_listen( $dev, $n, $svc ) ] )->[0] // '' );
    my $p = $al->{file};
    my $e = ( $dev->{files} || {} )->{$p};
    my $raw = ref $e eq 'HASH' ? $e->{content} // '' : $e;
    return unless defined $raw;    # keine Datei (z. B. geloescht): der Dienst legt sie hier nicht an
    my $old = ( $dev->{_append} || {} )->{$p};
    my @keep = $old && $old->{base} eq $raw ? @{ $old->{lines} } : ();
    $dev->{_append}{$p} = { base => $raw, lines => [ @keep, map { s/\{(ts|listen|pid)\}/$v{$1}/gr } @lines ] };
    return;
}

# Lauscher eines Dienstes ( "adresse:port", … ): listen am Dienst (Liste, oder { file, regex }
# — die Fangruppen aus der Datei, wie der Dienst sie gelesen hat), sonst fuer nginx die
# listen-Zeilen seiner Konfiguration (nginx.conf, conf.d/*.conf, sites-enabled/*)
sub _svc_listen {
    my ( $dev, $n, $svc ) = @_;
    my $l = $svc->{listen};
    my $run = ref $svc->{running} eq 'HASH' ? $svc->{running} : {};
    my $norm = sub {
        my ($a) = @_;
        $a =~ s/\Alocalhost:/127.0.0.1:/;
        $a =~ s/\A(?:\*|0\.0\.0\.0)?:?(?=\d+\z)/0.0.0.0:/ unless $a =~ /\A[\d.]+:\d+\z|\A\[/;
        return $a =~ /\A(?:[\d.]+|\[[0-9a-f:]*\]):\d+\z/i ? $a : ();
    };
    return map { $norm->($_) } @$l if ref $l eq 'ARRAY';
    if ( ref $l eq 'HASH' ) {
        my $t = $run->{ $l->{file} } // _file_text( $dev, $l->{file} ) // '';
        my $re = eval { qr/$l->{regex}/ } or return ();
        my @a;
        while ( $t =~ /$re/g ) { push @a, $1 if defined $1 }
        return map { $norm->($_) } @a;
    }
    return () unless ( $svc->{exec} // $n ) eq 'nginx';
    my %seen;
    my @a;
    for my $p ( sort grep { m{\A/etc/nginx/(?:nginx\.conf|conf\.d/[^/]+\.conf|sites-enabled/[^/]+)\z} } keys %{ $dev->{files} || {} } ) {
        my $t = $run->{$p} // _file_text( $dev, $p ) // '';
        $t =~ s/#[^\n]*//g;
        push @a, grep { !$seen{$_}++ } map { $norm->($_) } $t =~ /^\s*listen\s+([^;\s]+)[^;]*;/mg;
    }
    return @a;
}

# Jetzt als Ortszeit-Sekunden (wie _mtime sie liefert: timegm der Ortszeit)
sub _local_now { my ($dev) = @_; my $t = _dev_now($dev); return $t + Langertha::Holmgang::Sim::Linux::Calendar::offset($t) }

# mtime eines Eintrags wie stat %y ("2026-09-30 01:30:00.000000000 +0200") und als Epoche (%Y)
sub _mtime_iso {
    my ($e) = @_;
    require POSIX;
    my $lt = _mtime($e);
    my $off = Langertha::Holmgang::Sim::Linux::Calendar::offset( $lt - 3600 );
    return ( POSIX::strftime( '%Y-%m-%d %H:%M:%S', gmtime $lt ) . sprintf( '.000000000 %+03d%02d', $off / 3600, abs( $off % 3600 ) / 60 ), $lt - $off );
}

# Epoche -> mtime im Zustand ("Sep 30 01:30", in einem anderen Jahr "Sep 30  2025")
sub _mtime_str {
    my ($t) = @_;
    my @g = _local_tm($t);
    my $mon = (qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[ $g[4] ];
    return $g[5] + 1900 == 2026 ? sprintf( '%s %2d %02d:%02d', $mon, $g[3], $g[2], $g[1] ) : sprintf( '%s %2d  %04d', $mon, $g[3], $g[5] + 1900 );
}

# Zeitspalte von ls -l nach --time-style (full-iso, long-iso, iso; sonst wie im Zustand)
sub _ls_time {
    my ($e) = @_;
    my $m = ref $e eq 'HASH' ? $e->{mtime} : undef;
    return $m // 'Oct 20 09:00' unless $LS_TIME;
    my ($iso) = _mtime_iso( ref $e eq 'HASH' && defined $m ? $e : { mtime => 'Oct 20 09:00' } );
    return $iso if $LS_TIME eq 'full-iso';
    return substr( $iso, 0, 16 ) if $LS_TIME eq 'long-iso';
    return substr( $iso, 5, 11 );    # iso
}

# Epoche -> Ortszeit als gmtime-Liste (wie localtime in Europe/Berlin)
sub _local_tm { my ($t) = @_; return gmtime( $t + Langertha::Holmgang::Sim::Linux::Calendar::offset($t) ) }

# /proc/<pid>/limits eines Dienstes: offene Dateien aus der Fassung, mit der er laeuft
sub _proc_limits {
    my ( $dev, $pid ) = @_;
    my ($p) = grep { $_->{pid} == $pid } _procs($dev) or return undef;
    my $st = ( $dev->{services}{ $p->{unit} } || {} )->{_started} || {};
    my ( $soft, $hard ) = ( 1024, 524288 );
    if ( defined( my $l = $st->{LimitNOFILE} ) ) {
        ( $soft, $hard ) = $l =~ /\A(\w+):(\w+)\z/ ? ( $1, $2 ) : ( $l, $l );
        $_ = $_ eq 'infinity' ? 'unlimited' : $_ for $soft, $hard;
    }
    my $f = '%-26s%-21s%-21s%-10s';
    return join "\n", sprintf( $f, 'Limit', 'Soft Limit', 'Hard Limit', 'Units' ),
        sprintf( $f, 'Max cpu time', 'unlimited', 'unlimited', 'seconds' ),
        sprintf( $f, 'Max file size', 'unlimited', 'unlimited', 'bytes' ),
        sprintf( $f, 'Max core file size', 0, 'unlimited', 'bytes' ),
        sprintf( $f, 'Max processes', 63238, 63238, 'processes' ),
        sprintf( $f, 'Max open files', $soft, $hard, 'files' ),
        sprintf( $f, 'Max locked memory', 8388608, 8388608, 'bytes' );
}

sub _base64 {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    require MIME::Base64;
    my ($decode) = grep { /\A(?:-d|--decode)\z/ } @$av;
    my @files = grep { !/\A-/ } @$av;
    my $in;
    if (@files) {
        $in = _file_text( $dev, $files[0] );
        return ( "base64: $files[0]: No such file or directory", 0 ) unless defined $in;
    }
    else { $in = ( $stdin // '' ) . ( defined $stdin && length $stdin && $STDIN_NL ? "\n" : '' ) }
    if ($decode) {
        ( my $b = $in ) =~ s/\s+//g;
        return ( 'base64: invalid input', 0 ) if $b =~ m{[^A-Za-z0-9+/=]};
        my $d = MIME::Base64::decode_base64($b);
        utf8::decode($d);    # Text der Simulation sind Zeichen; gueltiges UTF-8 als Zeichen zurueck
        return ( $d =~ s/\n\z//r, 1 );
    }
    my $wrap = !grep { /\A(?:-w0|--wrap=0)\z/ } @$av;
    utf8::encode( my $bytes = $in );    # kodiert werden die Bytes (UTF-8), wie GNU base64
    my $e = MIME::Base64::encode_base64( $bytes, '' );
    $e =~ s/(.{76})(?=.)/$1\n/g if $wrap;
    return ( $e, 1 );
}

# ps [aux] | -ef | -eo spalten | --ppid N | -p N | -C name
sub _ps {
    my ( $dev, $av ) = @_;
    require POSIX;
    my @all = ( { pid => 1, ppid => 0, user => 'root', cmd => '/sbin/init' }, _procs($dev) );
    @all = map {    # nginx: Master und Worker wie echt
        ( split ' ', $_->{cmd} )[0] =~ m{(?:\A|/)nginx\z}
            ? ( { %$_, cmd => 'nginx: master process /usr/sbin/nginx -g daemon on; master_process on;' },
            { %$_, ppid => $_->{pid}, pid => $_->{pid} + 1, user => 'www-data', cmd => 'nginx: worker process' } )
            : $_
    } @all;
    my ( $fmt, @filt ) = ('aux');
    my @a = @{ $av || [] };
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-[eA]?f\z|\A-fe\z|\A-ef\z/ ) { $fmt = 'ef' }
        elsif ( $x =~ /\A-e?o\z/ || $x eq '-eo' || $x eq '--format' ) { $fmt = 'o:' . ( shift(@a) // '' ) }
        elsif ( $x =~ /\A-e?o(\S+)\z/ ) { $fmt = "o:$1" }
        elsif ( $x eq '--ppid' ) { my $v = shift @a // ''; push @filt, sub { grep { $_ == $_[0]{ppid} } split /,/, $v } }
        elsif ( $x eq '-p' || $x eq '--pid' ) { my $v = shift @a // ''; push @filt, sub { grep { $_ == $_[0]{pid} } split /,/, $v } }
        elsif ( $x eq '-C' ) { my $v = shift @a // ''; push @filt, sub { ( ( split ' ', $_[0]{cmd} )[0] =~ s{.*/}{}r ) eq $v } }
        elsif ( $x =~ /\A-([fFeAl]+)([pCuU])\z/ ) {    # -fp PID, -fu benutzer, …
            my ( $fl, $o ) = ( $1, $2 );
            $fmt = 'ef' if $fl =~ /f/i && $fmt !~ /\Ao:/;
            unshift @a, "-$o";
        }
        elsif ( $x eq '-u' || $x eq '-U' || $x eq '--user' ) {
            my $v = shift @a // '';
            my %u = map { $_ => 1 } split /,/, $v;
            push @filt, sub { $u{ $_[0]{user} } || $u{ _uid( $dev, $_[0]{user} ) } };
        }
        elsif ( $x =~ /\A(?:aux|-aux|ax|-e|-A|auxf|axu|-ww|ww|--no-headers|h)\z/ ) { $fmt = 'aux' if $x =~ /u/ && $fmt !~ /\Ao:/ }
        else  { push @GAPS, join( ' ', 'ps', @{ $av || [] } ); return ( '', 0 ) }
    }
    my @p = grep { my $p = $_; !grep { !$_->($p) } @filt } @all;
    my $noh = grep { $_ eq '--no-headers' || $_ eq 'h' } @{ $av || [] };
    my @l;
    if ( $fmt eq 'ef' ) {
        push @l, 'UID          PID    PPID  C STIME TTY          TIME CMD' unless $noh;
        push @l, map { sprintf( '%-8s %7d %7d  0 %-5s ?        00:00:12 %s', $_->{user}, $_->{pid}, $_->{ppid}, _ps_start( $dev, $_ ), $_->{cmd} ) } @p;
    }
    elsif ( $fmt =~ /\Ao:(.*)\z/ ) {
        my @spec = split /[,\s]+/, $1;
        my @c = map { lc s/=.*//r } @spec;
        $noh = 1 if @spec && !grep { !/=/ } @spec;    # pid= : leere Ueberschrift
        my %head = ( etimes => 'ELAPSED', comm => 'COMMAND', ucomm => 'COMMAND', args => 'COMMAND', command => 'COMMAND', cmd => 'CMD', '%cpu' => '%CPU', '%mem' => '%MEM' );
        my %w = ( pid => 7, ppid => 7, etime => 11, etimes => 7, user => 8, uid => 5, comm => 15 );
        my %val = (
            pid => sub { $_[0]{pid} }, ppid => sub { $_[0]{ppid} }, user => sub { $_[0]{user} }, uid => sub { _uid( $dev, $_[0]{user} ) },
            comm => sub { ( split ' ', $_[0]{cmd} )[0] =~ s{.*/}{}r }, ucomm => sub { ( split ' ', $_[0]{cmd} )[0] =~ s{.*/}{}r },
            args => sub { $_[0]{cmd} }, cmd => sub { $_[0]{cmd} }, command => sub { $_[0]{cmd} },
            etime => sub {
                my $t = _proc_since( $dev, $_[0] );
                return '4-00:12:00' unless defined $t;
                my $s = _dev_now($dev) - $t;
                $s = 1 if $s < 1;
                my ( $d, $h, $m ) = ( int( $s / 86400 ), int( $s % 86400 / 3600 ), int( $s % 3600 / 60 ) );
                return $d ? sprintf( '%d-%02d:%02d:%02d', $d, $h, $m, $s % 60 ) : $h ? sprintf( '%02d:%02d:%02d', $h, $m, $s % 60 ) : sprintf( '%02d:%02d', $m, $s % 60 );
            },
            etimes => sub { my $t = _proc_since( $dev, $_[0] ); return 346320 unless defined $t; my $s = _dev_now($dev) - $t; $s < 1 ? 1 : $s },
            stat => sub { 'Ss' }, '%cpu' => sub { '0.1' }, '%mem' => sub { '0.5' }, rss => sub { 41000 },
            lstart => sub {
                my $t = _proc_since( $dev, $_[0] );
                return defined $t ? POSIX::strftime( '%a %b %e %H:%M:%S %Y', _local_tm($t) ) : 'Tue Oct 20 09:00:00 2026';
            },
            nlwp => sub { 1 },
        );
        for (@c) { if ( !$val{$_} ) { push @GAPS, join( ' ', 'ps', @{ $av || [] } ); return ( '', 0 ) } }
        my $f = join ' ', map { $w{$_} ? ( /pid|etime/ ? "%$w{$_}s" : "%-$w{$_}s" ) : '%s' } @c;
        push @l, sprintf( $f, map { $head{$_} // uc } @c ) =~ s/\s+\z//r unless $noh;
        for my $p (@p) { push @l, sprintf( $f, map { $val{$_}->($p) } @c ) =~ s/\s+\z//r }
    }
    else {
        push @l, 'USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND' unless $noh;
        push @l, $_->{pid} == 1 ? 'root           1  0.0  0.1 168000 12000 ?        Ss   Oct20   0:04 /sbin/init'
            : sprintf( '%-8s %7d  0.1  0.5 220000 41000 ?        %-4s %-5s   0:12 %s', $_->{user}, $_->{pid}, $_->{ppid} == 1 ? 'Ss' : 'S', _ps_start( $dev, $_ ), $_->{cmd} ) for @p;
    }
    return ( join( "\n", @l ), @p ? 1 : 0 );
}

# Spalte START/STIME von ps: heute gestartet "09:12", sonst "Oct20"
sub _ps_start {
    my ( $dev, $p ) = @_;
    my $t = _proc_since( $dev, $p );
    return 'Oct20' unless defined $t;
    require POSIX;
    my @s = _local_tm($t);
    my @n = _local_tm( _dev_now($dev) );
    return $s[7] == $n[7] && $s[5] == $n[5] ? POSIX::strftime( '%H:%M', @s ) : POSIX::strftime( '%b%d', @s );
}

# Signal an einen Dienst: HUP liest neu ein (wie reload), sonst endet er (KILL: failed)
sub _signal {
    my ( $dev, $unit, $sig ) = @_;
    my $svc = $dev->{services}{$unit} or return;
    if ( $sig eq 'HUP' ) { _restart_effect( $dev, $unit, 'reload' ); return }
    return unless $svc->{active};
    $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1;
    $svc->{active} = JSON::MaybeXS::false();
    $svc->{failed} = JSON::MaybeXS::true() if $sig eq 'KILL' && !$svc->{failed};
    $dev->{deleted_open} = [ grep { ( $_->{by} // '' ) ne $unit } @{ $dev->{deleted_open} } ] if $dev->{deleted_open};
    # Restart= der geladenen Unit: systemd startet den Dienst neu — always immer, on-failure,
    # on-abnormal und on-abort nach einem unsauberen Signal (nicht TERM, INT, HUP, PIPE),
    # on-success nach einem sauberen
    my $pol   = _unit_props( _unit_loaded_text( $dev, $unit, $svc ) // '' )->{Restart} // 'no';
    my $clean = $sig =~ /\A(?:TERM|INT|HUP|PIPE)\z/;
    if ( $pol eq 'always' || ( $clean ? $pol eq 'on-success' : $pol =~ /\Aon-(?:failure|abnormal|abort)\z/ ) ) {
        $svc->{failed} = JSON::MaybeXS::false() if $svc->{failed};
        _systemd_start( $dev, $unit, $svc, 'start' );
        if ( $svc->{active} ) { $svc->{_nrestarts} = ( $svc->{_nrestarts} // 0 ) + 1 }
        else { $svc->{failed} = JSON::MaybeXS::true() }    # Neustart gescheitert: die Unit steht auf failed
    }
    return;
}

sub _sig_of {
    my ($x) = @_;
    my $s = uc( $x =~ s/\A-(?:s\s*)?//r );
    $s =~ s/\ASIG//;
    return { 1 => 'HUP', 9 => 'KILL', 15 => 'TERM', 2 => 'INT' }->{$s} // $s;
}

sub _pkill {
    my ( $dev, $av ) = @_;
    my ( $sig, $exact, @pat ) = ( 'TERM', 0 );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-x' || $x eq '--exact' ) { $exact = 1 }
        elsif ( $x eq '-f' || $x eq '--full' )  { }
        elsif ( $x eq '-u' || $x eq '-U' )      { shift @a }
        elsif ( $x eq '--signal' )              { $sig = _sig_of( shift(@a) // '' ) }
        elsif ( $x =~ /\A-(?:[A-Z]+|\d+)\z/ )   { $sig = _sig_of($x) }
        else                                    { push @pat, $x }
    }
    return ( "pkill: no matching criteria specified\nTry `pkill --help' for more information.", 0 ) unless @pat;
    my $re = $exact ? qr/\A\Q$pat[0]\E\z/ : ( eval { qr/$pat[0]/ } // qr/\Q$pat[0]\E/ );
    my @hit = grep { ( $_->{cmd} =~ s{.*/}{}r ) =~ $re } _procs($dev);
    _signal( $dev, $_->{unit}, $sig ) for @hit;
    return ( '', @hit ? 1 : 0 );
}

sub _kill {
    my ( $dev, $av ) = @_;
    my ( $sig, @pids ) = ('TERM');
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-s' ) { $sig = _sig_of( shift(@a) // '' ) }
        elsif ( $x eq '-l' ) { return ( ' 1) SIGHUP	 2) SIGINT	 3) SIGQUIT	 9) SIGKILL	15) SIGTERM', 1 ) }
        elsif ( $x =~ /\A-/ ) { $sig = _sig_of($x) }
        else { push @pids, $x }
    }
    return ( 'kill: usage: kill [-s sigspec | -n signum | -sigspec] pid | jobspec ... or kill -l [sigspec]', 0 ) unless @pids;
    my %by = map { $_->{pid} => $_ } _procs($dev);
    my ( @out, $ok ) = ();
    $ok = 1;
    for my $p (@pids) {
        if ( my $pr = $by{$p} ) { _signal( $dev, $pr->{unit}, $sig ); next }
        push @out, "bash: kill: ($p) - No such process";
        $ok = 0;
    }
    return ( join( "\n", @out ), $ok );
}

# getfacl: die Rechte als ACL (der Zustand kennt keine erweiterten ACLs)
sub _getfacl {
    my ( $dev, $av ) = @_;
    my @p = grep { !/\A-/ } @$av;
    return ( "Usage: getfacl [-aceEsRLPtpndvh] file ...\nTry `getfacl --help' for more information.", 0 ) unless @p;
    my ( @out, $ok, $strip );
    $ok = 1;
    for my $p (@p) {
        my $e = _file_entry( $dev, $p );
        my $d = !$e && _is_dir( $dev, $p ) ? { mode => '0755', %{ ( $dev->{dirs} || {} )->{$p} || {} } } : undef;
        if ( !$e && !$d ) { push @out, "getfacl: $p: No such file or directory"; $ok = 0; next }
        my $m = $e ? _mode_of($e) : oct( $d->{mode} );
        my $x = $e // $d;
        my $rwx = sub { my $b = shift; ( $b & 4 ? 'r' : '-' ) . ( $b & 2 ? 'w' : '-' ) . ( $b & 1 ? 'x' : '-' ) };
        ( my $shown = $p ) =~ s{\A/+}{};
        $strip = 1 if $p =~ m{\A/};
        push @out, '' if @out && $out[-1] ne '';
        push @out, "# file: $shown", '# owner: ' . ( $x->{owner} // 'root' ), '# group: ' . ( $x->{group} // 'root' );
        push @out, '# flags: ' . ( $m & 04000 ? 's' : '-' ) . ( $m & 02000 ? 's' : '-' ) . ( $m & 01000 ? 't' : '-' ) if $m & 07000;
        push @out, 'user::' . $rwx->( $m >> 6 ), 'group::' . $rwx->( $m >> 3 ), 'other::' . $rwx->($m), '';
    }
    pop @out while @out && $out[-1] eq '';
    unshift @out, "getfacl: Removing leading '/' from absolute path names" if $strip;
    return ( join( "\n", @out ), $ok );
}

# crontab -l [-u benutzer] liest /var/spool/cron/crontabs/<benutzer>
sub _crontab {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my ( $user, $verb, $file ) = ( $AS_USER // 'root' );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-u' ) { $user = shift(@a) // $user }
        elsif ( $x =~ /\A-([lre])\z/ ) { $verb = $1 }
        else { $verb //= 'install'; $file = $x }
    }
    return ( "crontab: user `$user' unknown", 0 ) unless $user eq 'root' || ( $dev->{users} || {} )->{$user};
    my $f = "/var/spool/cron/crontabs/$user";
    if ( ( $verb // '' ) eq 'l' ) {
        my $t = _file_text( $dev, $f ) // return ( "no crontab for $user", 0 );
        $t =~ s/\A# DO NOT EDIT THIS FILE[^\n]*\n(?:#[^\n]*\n){0,2}//;    # Kopf, den crontab beim Installieren schreibt
        return ( $t =~ s/\n\z//r, 1 );
    }
    if ( ( $verb // '' ) eq 'r' ) {
        return ( "no crontab for $user", 0 ) unless exists( ( $dev->{files} || {} )->{$f} );
        delete $dev->{files}{$f};
        return ( '', 1 );
    }
    if ( ( $verb // '' ) eq 'install' && defined $file ) {    # crontab [-u benutzer] DATEI|-: ersetzt den ganzen crontab
        my $t = $file eq '-' ? $stdin // '' : _file_text( $dev, _absp($file) );
        return ( "$file: No such file or directory", 0 ) unless defined $t;
        my $n = 0;
        for my $l ( split /\n/, $t ) {
            my $bad = _cron_line_error($l);
            return ( qq{"$file":$n: $bad\nerrors in crontab file, can't install.}, 0 ) if defined $bad;
            $n++;
        }
        $t .= "\n" if length $t && $t !~ /\n\z/;
        my $head = "# DO NOT EDIT THIS FILE - edit the master and reinstall.\n# ($file installed on Tue Oct 20 12:00:00 2026)\n"
            . "# (Cron version -- \$Id: crontab.c,v 2.13 1994/01/17 03:20:37 vixie Exp \$)\n";
        $dev->{files}{$f} = { content => $head . $t, owner => $user, group => 'crontab', mode => '0600' };
        return ( '', 1 );
    }
    push @GAPS, join( ' ', 'crontab', @$av );
    return ( '', 0 );
}

# Zeile eines crontab wie Debian-cron sie prueft: undef oder der Fehler ("bad minute" …)
my %CRON_NAMES = ( month => [qw( jan feb mar apr may jun jul aug sep oct nov dec )], 'day-of-week' => [qw( sun mon tue wed thu fri sat )] );
sub _cron_line_error {
    my ($l) = @_;
    return undef if $l =~ /\A\s*(?:#|\z)/ || $l =~ /\A\s*[A-Za-z_]\w*\s*=/;
    if ( $l =~ /\A\s*@(\S+)/ ) {
        return 'bad time specifier' unless $1 =~ /\A(?:reboot|yearly|annually|monthly|weekly|daily|midnight|hourly)\z/;
        return $l =~ /\A\s*@\S+\s+\S/ ? undef : 'bad command';
    }
    my @f = split ' ', $l, 6;
    my @spec = ( [ minute => 0, 59 ], [ hour => 0, 23 ], [ 'day-of-month' => 1, 31 ], [ month => 1, 12 ], [ 'day-of-week' => 0, 7 ] );
    for my $i ( 0 .. 4 ) {
        my ( $name, $lo, $hi ) = @{ $spec[$i] };
        my $v = $f[$i] // return "bad $name";
        my $names = $CRON_NAMES{$name};
        for my $part ( split /,/, $v, -1 ) {
            my ( $range, $step ) = split m{/}, $part, 2;
            return "bad $name" if defined $step && $step !~ /\A\d+\z/;
            next if $range eq '*';
            my @ends = split /-/, $range, 2;
            for (@ends) {
                if ( $names && /\A[a-z]{3}\z/i ) { my $x = lc; return "bad $name" unless grep { $_ eq $x } @$names; next }
                return "bad $name" unless /\A\d+\z/ && $_ >= $lo && $_ <= $hi;
            }
        }
    }
    return defined $f[5] && $f[5] =~ /\S/ ? undef : 'bad command';
}

sub _pgrep {
    my ( $dev, $av ) = @_;
    my ( $long, @pat ) = ( 0 );
    for (@$av) { if (/\A-(\w+)\z/) { $long = 1 if /[al]/ } else { push @pat, $_ } }
    return ( "pgrep: no matching criteria specified\nTry `pgrep --help' for more information.", 0 ) unless @pat;
    my $re = eval { qr/$pat[0]/ } // qr/\Q$pat[0]\E/;
    my @hit = grep { $_->{cmd} =~ $re } _procs($dev);
    return ( join( "\n", map { $long ? "$_->{pid} $_->{cmd}" : $_->{pid} } @hit ), @hit ? 1 : 0 );
}

sub _uid { my ( $dev, $u ) = @_; return 0 if !defined $u || $u eq 'root'; return ( ( $dev->{users} || {} )->{$u} || {} )->{uid} // 1000 }
sub _gid { my ( $dev, $g ) = @_; return 0 if !defined $g || $g eq 'root'; return ( ( $dev->{groups} || {} )->{$g} || {} )->{gid} // 1000 }

# Darf $user die Datei lesen/schreiben/ausfuehren? (r|w|x)
sub _can {
    my ( $dev, $user, $path, $what ) = @_;
    my $e = _file_entry( $dev, $path ) // ( ( $dev->{dirs} || {} )->{$path} ? { mode => '0755', %{ $dev->{dirs}{$path} } } : undef ) or return 0;
    return 1 if ( $user // 'root' ) eq 'root';
    my $bit = { r => 4, w => 2, x => 1 }->{$what} // 4;
    my $m = _mode_of($e);
    return ( ( $m >> 6 ) & $bit ) ? 1 : 0 if ( $e->{owner} // 'root' ) eq $user;
    my @groups = @{ ( ( $dev->{users} || {} )->{$user} || {} )->{groups} || [] };
    return ( ( $m >> 3 ) & $bit ) ? 1 : 0 if grep { $_ eq ( $e->{group} // 'root' ) } @groups;
    return ( $m & $bit ) ? 1 : 0;
}

# Datei-Eintrag als Hash im Zustand (fuer Rechte/Eigentuemer)
sub _entry_rw {
    my ( $dev, $path ) = @_;
    my $e = $dev->{files}{$path};
    $dev->{files}{$path} = $e = { content => $e } unless ref $e eq 'HASH';
    return $e;
}

# Ziele von chmod/chown: Dateien und (mit -R bzw. ausdruecklich) Verzeichnisse
# als 'dir:<pfad>'.
sub _targets {
    my ( $dev, $rec, @paths ) = @_;
    my @t;
    for my $p (@paths) {
        ( my $q = $p ) =~ s{(?<=.)/+\z}{};
        if ( _file_entry( $dev, $q ) ) { push @t, $q; next }
        if ( _is_dir( $dev, $q ) ) {
            push @t, "dir:$q";
            if ($rec) {
                my %d;
                for my $f ( _under( $dev, $q ) ) {
                    push @t, $f;
                    ( my $x = $f ) =~ s{/[^/]+\z}{};
                    while ( length $x > length $q ) { $d{$x} = 1; $x =~ s{/+[^/]*\z}{} or last }
                }
                $d{$_} = 1 for grep { index( $_, "$q/" ) == 0 } keys %{ $dev->{dirs} || {} };
                push @t, map {"dir:$_"} sort keys %d;
            }
            next;
        }
        return ( undef, $p );
    }
    return \@t;
}

sub _target_entry {
    my ( $dev, $t ) = @_;
    return _entry_rw( $dev, $t ) unless $t =~ /\Adir:(.*)\z/s;
    return $dev->{dirs}{$1} //= { mode => '0755' };
}

sub _chmod {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $rec = 0;
    while ( @a && $a[0] =~ /\A-[Rvf]+\z/ ) { $rec = 1 if shift(@a) =~ /R/ }
    my $spec = shift @a // return ( "chmod: missing operand", 0 );
    return ( "chmod: missing operand after '$spec'", 0 ) unless @a;
    my ( $t, $bad ) = _targets( $dev, $rec, @a );
    return ( "chmod: cannot access '$bad': No such file or directory", 0 ) unless $t;
    for my $p (@$t) {
        my $isdir = $p =~ /\Adir:/;
        my $e = _target_entry( $dev, $p );
        my $m = $isdir ? oct( $e->{mode} // '0755' ) : _mode_of($e);
        if ( $spec =~ /\A[0-7]{3,4}\z/ ) { $m = oct $spec }
        else {
            for my $part ( split /,/, $spec ) {
                my ( $who, $op, $perm ) = $part =~ /\A([ugoa]*)([+=-])([rwxXst]*)\z/ or return ( "chmod: invalid mode: '$spec'", 0 );
                $who = 'a' if $who eq '';
                my $bits = 0;
                my ( $s, $t ) = ( $perm =~ /s/ ? 1 : 0, $perm =~ /t/ ? 1 : 0 );
                for ( split //, $perm ) {
                    next if $_ eq 's' || $_ eq 't';
                    if ( $_ eq 'X' ) { $bits |= 1 if $isdir || ( $m & 0111 ); next }
                    $bits |= { r => 4, w => 2, x => 1 }->{$_};
                }
                for my $w ( $who =~ /a/ ? qw( u g o ) : split //, $who ) {
                    my $sh = { u => 6, g => 3, o => 0 }->{$w};
                    my $sp = { u => 04000, g => 02000, o => 01000 }->{$w};
                    my $spb = ( $w eq 'o' ? $t : $s ) ? $sp : 0;
                    if    ( $op eq '+' ) { $m |= ( $bits << $sh ) | $spb }
                    elsif ( $op eq '-' ) { $m &= ~( ( $bits << $sh ) | $spb ) }
                    else                 { $m = ( $m & ~( ( 7 << $sh ) | $sp ) ) | ( $bits << $sh ) | $spb }
                }
            }
        }
        my $new = sprintf '%04o', $m & 07777;
        my $cur = $isdir ? ( $e->{mode} // '0755' ) : sprintf( '%04o', _mode_of($e) );
        $e->{mode} = $new unless $cur eq $new && defined $e->{mode};
    }
    return ( '', 1 );
}

sub _chown {
    my ( $dev, $av, $ctx, $stdin, $only_group ) = @_;
    my @a = @$av;
    my $rec = 0;
    while ( @a && $a[0] =~ /\A-[Rvfh]+\z/ ) { $rec = 1 if shift(@a) =~ /R/ }
    my $spec = shift @a // return ( 'chown: missing operand', 0 );
    my ( $u, $g ) = $only_group ? ( undef, $spec ) : split /[:.]/, $spec, 2;
    my $users  = $dev->{users}  || {};
    my %groups = ( root => 1, map { $_ => 1 } keys %{ $dev->{groups} || {} }, map { @{ $_->{groups} || [] } } values %$users );
    # numerische IDs: auf den Namen abbilden, sonst die Zahl selbst (wie ls -l ohne Eintrag)
    if ( defined $u && $u =~ /\A\d+\z/ ) {
        my ($n) = grep { ( $users->{$_}{uid} // -1 ) == $u } sort keys %$users;
        $u = $u == 0 ? 'root' : $n // $u;
        $users = { %$users, $u => { uid => $u } } unless $users->{$u} || $u eq 'root';
    }
    if ( defined $g && $g =~ /\A\d+\z/ ) {
        my ($n) = grep { ( $dev->{groups}{$_}{gid} // -1 ) == $g } sort keys %{ $dev->{groups} || {} };
        $g = $g == 0 ? 'root' : $n // $g;
        $groups{$g} = 1;
    }
    return ( "chown: invalid user: '$spec'", 0 ) if defined $u && length $u && $u ne 'root' && !$users->{$u};
    return ( "chown: invalid group: '$spec'", 0 ) if defined $g && length $g && !$groups{$g};
    my ( $t, $bad ) = _targets( $dev, $rec, @a );
    return ( "chown: cannot access '$bad': No such file or directory", 0 ) unless $t;
    for my $p (@$t) {
        my $e = _target_entry( $dev, $p );
        $e->{owner} = $u if defined $u && length $u && ( $e->{owner} // 'root' ) ne $u;
        $e->{group} = $g if defined $g && length $g && ( $e->{group} // 'root' ) ne $g;
    }
    return ( '', 1 );
}

sub _rm {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $f, $r, $v ) = ( 0, 0, 0 );
    while ( @a && $a[0] =~ /\A-[rRfvi]+\z|\A--(?:force|recursive|verbose)\z/ ) {
        my $o = shift @a;
        $f = 1 if $o =~ /f/;
        $r = 1 if $o =~ /r/i;
        $v = 1 if $o =~ /v/;
    }
    return ( 'rm: missing operand', 0 ) unless @a;
    my ( @out, $ok ) = ();
    $ok = 1;
    for my $raw (@a) {    # wie GNU rm: Fehler je Operand, die uebrigen laufen weiter
        my $p = _absp($raw) =~ s{(?<=.)/+\z}{}r;
        my @gone;
        # als Benutzer: w und x am Elternordner (sticky: nur der Eigentuemer), x auf dem Weg
        if ( _who() ne 'root' && ( _file_entry( $dev, $p ) || _is_dir( $dev, $p ) ) ) {
            ( my $par = $p ) =~ s{/[^/]+\z}{};
            $par = '/' unless length $par;
            my $pm = _dir_meta( $dev, $par );
            my $owner = ( _file_entry( $dev, $p ) || _dir_meta( $dev, $p ) )->{owner} // 'root';
            if ( !_traverse_ok( $dev, $p ) || !_dir_ok( $dev, $par, 2 ) || !_dir_ok( $dev, $par, 1 )
                || ( oct( $pm->{mode} // '0755' ) & 01000 ) && $owner ne _who() && ( $pm->{owner} // 'root' ) ne _who() ) {
                push @out, "rm: cannot remove '$raw': Permission denied";
                $ok = 0;
                next;
            }
        }
        if ( _file_entry( $dev, $p ) ) { @gone = ($p) }
        elsif ( _is_dir( $dev, $p ) ) {
            if ( !$r ) { push @out, "rm: cannot remove '$raw': Is a directory"; $ok = 0; next }
            return ( "rm: it is dangerous to operate recursively on '/'", 0 ) if $p =~ m{\A/+\z};
            @gone = _under( $dev, $p );
        }
        else {
            next if $f;
            push @out, "rm: cannot remove '$raw': No such file or directory";
            $ok = 0;
            next;
        }
        my @keep = _parents_of( $dev, $p );
        for my $g (@gone) {
            my $e = _file_entry( $dev, $g );
            my $svc = defined $e->{open_by} ? ( $dev->{services} || {} )->{ $e->{open_by} } : undef;
            push @{ $dev->{deleted_open} }, { path => $g, size => _file_size($e), by => $e->{open_by} } if $svc && $svc->{active};
            delete $dev->{files}{$g};
            _maria()->can('file_removed')->( $dev, $g ) if $dev->{mariadb};
            push @out, "removed '$g'" if $v;
        }
        if ( !_file_entry( $dev, $p ) && _is_dir( $dev, $p ) ) {    # rm -r: auch die angelegten Verzeichnisse darunter
            ( my $q = $p ) =~ s{(?<=.)/+\z}{};
            for my $k (qw( dirs _dirs )) { delete $dev->{$k}{$_} for grep { $_ eq $q || index( $_, "$q/" ) == 0 } keys %{ $dev->{$k} || {} } }
        }
        _keep_dirs( $dev, @keep );
    }
    return ( join( "\n", @out ), $ok );
}

sub _truncate {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $size;
    my @files;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-s' )             { $size = shift @a }
        elsif ( $x =~ /\A--size=(.+)\z/ ) { $size = $1 }
        else                             { push @files, $x }
    }
    return ( "truncate: you must specify either '--size' or '--reference'", 0 ) unless defined $size;
    for my $p (@files) {
        my $e = _entry_rw( $dev, $p );
        my $b = _bytes($size);
        delete $e->{size};
        $e->{content} = substr( $e->{content} // '', 0, $b );
        $e->{size} = $b if $b > length $e->{content};
    }
    return ( '', 1 );
}

# touch [-a|-m|-c] [-d DATUM|--date=DATUM|-t [[CC]JJ]MMTThhmm[.ss]|-r DATEI] DATEI…:
# setzt die Zeit (mtime) wie GNU — ohne Angabe jetzt (Uhr des Geraets), -d wie date -d
# ("20 days ago", "2026-09-30 01:30", yesterday); -c legt nichts an
sub _touch {
    my ( $dev, $av ) = @_;
    my ( $when, $ref, $nocreate, @files );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-d' || $x eq '--date' ) { $when = [ d => shift(@a) // '' ] }
        elsif ( $x =~ /\A--date=(.*)\z/s )     { $when = [ d => $1 ] }
        elsif ( $x =~ /\A-[acmhf]*d(.+)\z/s )  { $when = [ d => $1 ] }
        elsif ( $x =~ /\A-[acmhf]*d\z/ )       { $nocreate = 1 if $x =~ /c/; $when = [ d => shift(@a) // '' ] }
        elsif ( $x =~ /\A-[acmhf]*t\z/ )       { $nocreate = 1 if $x =~ /c/; $when = [ t => shift(@a) // '' ] }
        elsif ( $x =~ /\A-[acmhf]*r\z/ || $x eq '--reference' ) { $nocreate = 1 if $x =~ /c/; $ref = shift(@a) // '' }
        elsif ( $x =~ /\A--reference=(.*)\z/ ) { $ref = $1 }
        elsif ( $x =~ /\A-[acmhf]+\z/ || $x eq '--no-create' ) { $nocreate = 1 if $x =~ /c/ || $x eq '--no-create' }
        elsif ( $x eq '--' ) { push @files, @a; last }
        elsif ( $x =~ /\A--/ ) { return ( "touch: unrecognized option '$x'\nTry 'touch --help' for more information.", 0 ) }
        elsif ( $x =~ /\A-(.)/ ) { return ( "touch: invalid option -- '$1'\nTry 'touch --help' for more information.", 0 ) }
        else { push @files, $x }
    }
    return ( "touch: missing file operand\nTry 'touch --help' for more information.", 0 ) unless @files;
    my $mtime;
    if ( defined $ref ) {
        my $re = _file_entry( $dev, _absp($ref) ) or return ( "touch: failed to get attributes of '$ref': No such file or directory", 0 );
        $mtime = $re->{mtime} // 'Oct 20 09:00';
    }
    elsif ( $when && $when->[0] eq 'd' ) {
        my $t = _date_parse( $when->[1], $dev->{timezone} // 'Europe/Berlin', 'Langertha::Holmgang::Sim::Linux::Calendar', _dev_now($dev) );
        return ( "touch: invalid date format '$when->[1]'", 0 ) unless defined $t;
        $mtime = _mtime_str($t);
    }
    elsif ($when) {
        my ( $y, $mo, $d, $h, $mi ) = $when->[1] =~ /\A(\d{4}|\d{2})?(\d\d)(\d\d)(\d\d)(\d\d)(?:\.\d\d)?\z/
            or return ( "touch: invalid date format '$when->[1]'", 0 );
        $y = !defined $y ? 2026 : length $y == 2 ? ( $y < 69 ? 2000 + $y : 1900 + $y ) : $y;
        return ( "touch: invalid date format '$when->[1]'", 0 ) if $mo < 1 || $mo > 12 || $d < 1 || $d > 31 || $h > 23 || $mi > 59;
        my $mon = (qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[ $mo - 1 ];
        $mtime = $y == 2026 ? sprintf( '%s %2d %02d:%02d', $mon, $d, $h, $mi ) : sprintf( '%s %2d  %04d', $mon, $d, $y );
    }
    else { $mtime = _mtime_str( _dev_now($dev) ) }
    for my $raw (@files) {
        my $p = _absp($raw);
        if ( _file_entry( $dev, $p ) ) {
            return ( "touch: cannot touch '$raw': Permission denied", 0 ) if _may_create( $dev, $p );
            my $e = _entry_rw( $dev, $p );
            $e->{mtime} = $mtime unless ( $e->{mtime} // '' ) eq $mtime;
            next;
        }
        next if _is_dir( $dev, $p ) || $nocreate;
        my ($dir) = $p =~ m{\A(.*)/[^/]+\z};
        return ( "touch: cannot touch '$raw': No such file or directory", 0 ) unless defined $dir && _is_dir( $dev, length $dir ? $dir : '/' );
        if ( my $err = _may_create( $dev, $p ) ) { return ( "touch: cannot touch '$raw': $err", 0 ) }
        my $meta = _new_meta( $dev, $p, 0 );
        $dev->{files}{$p} = { content => '', %{ $meta || {} }, mtime => $mtime };
    }
    return ( '', 1 );
}

# Forgejo-Server, den curl/wget mit dieser URL erreicht (das Geraet selbst oder ueber den Namen)
sub _forgejo_for {
    my ( $dev, $a ) = @_;
    my ($url) = grep {m{\Ahttps?://}} @$a;
    return $dev->{forgejo} ? $dev : undef unless defined $url;
    my ($h) = $url =~ m{\Ahttps?://([^/:]+)};
    return $dev if $dev->{forgejo};
    my $st = ( $CTX || {} )->{state} || {};
    my $any;
    for my $k ( sort keys %$st ) {
        my $f = ref $st->{$k} eq 'HASH' && $st->{$k}{forgejo} or next;
        ( my $root = $f->{root_url} // '' ) =~ s{\Ahttps?://([^/:]+).*}{$1}s;
        return $st->{$k} if length $root && $h eq $root;
        $any //= $st->{$k};
    }
    return $any;    # in einer Welt mit Forgejo gibt es curl/wget; andere Ziele sind nicht erreichbar
}

sub _dirname {
    my ( $dev, $av ) = @_;
    my @p = grep { !/\A-/ } @$av or return ( 'dirname: missing operand', 0 );
    return ( join( "\n", map { my $d = $_; $d =~ s{/+\z}{} if length $d > 1; $d =~ s{/*[^/]*\z}{}; length $d ? $d : m{\A/} ? '/' : '.' } @p ), 1 );
}

sub _basename {
    my ( $dev, $av ) = @_;
    my @p = grep { !/\A-/ } @$av or return ( 'basename: missing operand', 0 );
    my ( $p, $suf ) = @p;
    ( my $b = $p ) =~ s{/+\z}{};
    $b =~ s{.*/}{};
    $b =~ s/\Q$suf\E\z// if defined $suf && $b ne $suf;
    return ( $b, 1 );
}

sub _hashsum {
    my ( $alg, $dev, $av ) = @_;
    require Digest::MD5;
    require Digest::SHA;
    my ( @out, $ok );
    $ok = 1;
    for my $p ( grep { !/\A-/ } @$av ) {
        my $t = _file_entry( $dev, $p ) ? _file_text( $dev, $p ) : undef;
        if ( !defined $t ) { push @out, "${alg}sum: $p: No such file or directory"; $ok = 0; next }
        my $bytes = Encode::encode( 'UTF-8', $t );
        push @out, ( $alg eq 'md5' ? Digest::MD5::md5_hex($bytes) : Digest::SHA::sha256_hex($bytes) ) . "  $p";
    }
    return ( join( "\n", @out ), $ok );
}

# gzip -d/-dc/-t, gunzip, zcat: echte gzip-Daten (z. B. aus einem Helm-Release-Secret)
sub _gzip {
    my ( $mode, $dev, $av, $ctx, $stdin ) = @_;
    require IO::Uncompress::Gunzip;
    my $opt = join '', map { /\A-([a-z]+)\z/ ? $1 : '' } @$av;
    my $dec = $mode ne 'gzip' || $opt =~ /d/ || grep { $_ eq '--decompress' } @$av;
    my $toout = $mode eq 'zcat' || $opt =~ /c/ || grep { $_ eq '--stdout' } @$av;
    my $test = $opt =~ /t/;
    do { push @GAPS, join( ' ', $mode, @$av ); return ( '', 0 ) } unless $dec || $test;
    my @f = grep { !/\A-/ } @$av;
    my @src = @f ? @f : (undef);
    my ( @out, $ok );
    $ok = 1;
    for my $p (@src) {
        my $raw = defined $p ? ( _file_entry( $dev, $p ) ? _file_text( $dev, $p ) : undef ) : $stdin // '';
        if ( !defined $raw ) { push @out, "gzip: $p: No such file or directory"; $ok = 0; next }
        my $bytes = utf8::is_utf8($raw) ? Encode::encode( 'UTF-8', $raw ) : $raw;
        my $plain;
        if ( substr( $bytes, 0, 2 ) ne "\x1f\x8b" || !IO::Uncompress::Gunzip::gunzip( \$bytes => \$plain ) ) {
            push @out, 'gzip: ' . ( $p // 'stdin' ) . ': not in gzip format';
            $ok = 0;
            next;
        }
        next if $test;
        my $text = eval { Encode::decode( 'UTF-8', $plain, Encode::FB_CROAK() ) } // $plain;
        if ( $toout || !defined $p ) { push @out, $text; next }
        ( my $to = $p ) =~ s/\.(?:gz|z|tgz)\z//i;
        $to = "$p.out" if $to eq $p;
        $dev->{files}{$to} = $text;
        delete $dev->{files}{$p};
    }
    return ( join( '', @out ) =~ s/\n\z//r, $ok );
}

sub _find {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my @roots;
    push @roots, shift @a while @a && $a[0] !~ /\A[-(!]/;
    @roots = ('.') unless @roots;
    my ( $maxd, $mind, @exec, $has_action );
    # Ausdruck wie find: Tests und Aktionen als Code, Operatoren ! -a -o ( ) als Text
    my @tok;
    our ( @FIND_ACT, $FIND_PRUNE );
    my $glob = sub { my ( $g, $i ) = @_; ( my $r = quotemeta $g ) =~ s/\\\*/.*/g; $r =~ s/\\\?/./g; $r =~ s/\\\[/[/g; $r =~ s/\\\]/]/g; $i ? qr/\A$r\z/is : qr/\A$r\z/s };
    my $add = sub { push @tok, $_[0] };
    my $act = sub { my @x = @_; $has_action = 1; push @tok, sub { push @FIND_ACT, [@x]; 1 } };
    while (@a) {
        my $x = shift @a;
        my $need = sub { my $v = shift @a; defined $v or die "find: missing argument to `$x'\n"; $v };
        my $v;
        if    ( $x eq '!' || $x eq '-not' ) { push @tok, '!' }
        elsif ( $x eq '-o' || $x eq '-or' ) { push @tok, '-o' }
        elsif ( $x eq '-a' || $x eq '-and' ) { push @tok, '-a' }
        elsif ( $x eq '(' || $x eq ')' ) { push @tok, $x }
        elsif ( $x eq '-name' || $x eq '-iname' ) {
            my $re = $glob->( $need->(), $x eq '-iname' );
            $add->( sub { ( my $b = $_[0] ) =~ s{.*/}{}; $b =~ $re } );
        }
        elsif ( $x eq '-path' || $x eq '-wholename' || $x eq '-ipath' ) { my $re = $glob->( $need->(), $x eq '-ipath' ); $add->( sub { $_[0] =~ $re } ) }
        elsif ( $x eq '-perm' ) {
            $v = $need->();
            my $perm = _find_perm($v) // return ( "find: invalid mode `$v'", 0 );
            $add->( sub {
                my $m = ( $_[2] eq 'd' ? oct( $_[1]{mode} // '0755' ) : _mode_of( $_[1] ) ) & 07777;
                my ( $k, $want ) = @$perm;
                !( $k eq '-' && ( $m & $want ) != $want || $k eq '/' && $want && !( $m & $want ) || $k eq '' && $m != $want );
            } );
        }
        elsif ( $x eq '-size' ) {
            $v = $need->();
            my ( $s, $n, $u ) = $v =~ /\A([+-]?)(\d+)([ckMG]?)\z/ or return ( "find: invalid -size argument `$v'", 0 );
            my $lim = $n * { '' => 512, c => 1, k => 1024, M => 1024**2, G => 1024**3 }->{$u};
            $add->( sub { my $sz = $_[2] eq 'd' ? 4096 : _file_size( $_[1] ); $s eq '+' ? $sz > $lim : $s eq '-' ? $sz < $lim : $sz == $lim } );
        }
        elsif ( $x eq '-type' ) {
            $v = $need->();
            return ( "find: Unknown argument to -type: $v", 0 ) unless $v =~ /\A[fdl](?:,[fdl])*\z/;
            my %t = map { $_ => 1 } split /,/, $v;
            $add->( sub { $t{ $_[2] } } );
        }
        elsif ( $x eq '-user' )  { $v = $need->(); $add->( sub { ( $_[1]{owner} // 'root' ) eq $v } ) }
        elsif ( $x eq '-group' ) { $v = $need->(); $add->( sub { ( $_[1]{group} // 'root' ) eq $v } ) }
        elsif ( $x eq '-nouser' )  { $add->( sub { my $o = $_[1]{owner} // 'root'; $o ne 'root' && !( $dev->{users} || {} )->{$o} } ) }
        elsif ( $x eq '-nogroup' ) { $add->( sub { my $g = $_[1]{group} // 'root'; $g ne 'root' && !( $dev->{groups} || {} )->{$g} && !grep { $_ eq $g } map { @{ $_->{groups} || [] } } values %{ $dev->{users} || {} } } ) }
        elsif ( $x eq '-empty' ) { $add->( sub { $_[2] eq 'd' ? _ls_names_empty( $dev, $_[0] ) : _file_size( $_[1] ) == 0 } ) }
        elsif ( $x eq '-true' )  { $add->( sub {1} ) }
        elsif ( $x eq '-false' ) { $add->( sub {0} ) }
        elsif ( $x eq '-mtime' || $x eq '-mmin' ) {
            $v = $need->();
            my ( $sg, $n ) = $v =~ /\A([+-]?)(\d+)\z/ or return ( "find: invalid argument `$v' to `$x'", 0 );
            my $unit = $x eq '-mtime' ? 86400 : 60;
            my $lim = $n * $unit;
            $add->( sub {
                # ohne mtime im Zustand (Verzeichnisse, Vorgabe): gerade eben
                my $mt = ref $_[1] eq 'HASH' && defined $_[1]{mtime} ? _mtime( $_[1] ) : _local_now($dev);
                my $d = int( ( _local_now($dev) - $mt ) / $unit ) * $unit;
                !( $sg eq '+' && $d <= $lim || $sg eq '-' && $d >= $lim || $sg eq '' && $d != $lim );
            } );
        }
        elsif ( $x eq '-newer' ) {
            $v = $need->();
            my $r = _file_entry( $dev, $v ) or return ( "find: '$v': No such file or directory", 0 );
            my $t = _mtime($r);
            $add->( sub { _mtime( $_[1] ) > $t } );
        }
        elsif ( $x eq '-newermt' ) {
            $v = $need->();
            my $t = _parse_since( $v, _dev_now($dev) ) // return ( "find: I cannot figure out how to interpret '$v' as a date or time", 0 );
            $t += Langertha::Holmgang::Sim::Linux::Calendar::offset($t);    # mtime im Zustand ist Ortszeit
            $add->( sub { _mtime( $_[1] ) > $t } );
        }
        elsif ( $x eq '-maxdepth' || $x eq '-mindepth' ) {
            $v = shift(@a) // '';
            return ( "find: Expected a positive decimal integer argument to $x, but got `$v'", 0 ) unless $v =~ /\A\d+\z/;
            ( $x eq '-maxdepth' ? $maxd : $mind ) = $v;
        }
        elsif ( $x eq '-prune' ) { $add->( sub { $FIND_PRUNE = 1 if $_[2] eq 'd'; 1 } ) }    # wahr; nicht hinabsteigen
        elsif ( $x =~ /\A-(?:xdev|mount|depth|noleaf|ignore_readdir_race|follow)\z/ || $x eq '-L' || $x eq '-H' || $x eq '-P' ) { }
        elsif ( $x eq '-print' || $x eq '-print0' ) { $act->('print') }
        elsif ( $x eq '-ls' )     { $act->('ls') }
        elsif ( $x eq '-printf' ) { $act->( 'printf', $need->() ) }
        elsif ( $x eq '-exec' || $x eq '-execdir' ) {
            my @c;
            push @c, shift @a while @a && $a[0] !~ /\A(?:;|\\;|\+)\z/;
            my $end = shift @a // return ( "find: missing argument to `$x'", 0 );
            $end = ';' if $end eq '\\;';
            return ( "find: In '$x ... {} +' you must place {} at the end", 0 ) if $end eq '+' && ( !@c || $c[-1] ne '{}' );
            push @exec, [ \@c, $end ];
            $act->( 'exec', $#exec );
        }
        elsif ( $x eq '-delete' ) { $act->('delete') }
        else { return ( "find: unknown predicate `$x'", 0 ) }
    }
    # Vorrang wie find: ( ) vor ! vor -a (auch ohne Wort) vor -o
    my $pos = 0;
    my ( $p_or, $p_and, $p_un );
    $p_un = sub {
        my $t = $tok[$pos];
        die "find: expected an expression at the end\n" unless defined $t;
        if ( !ref $t && $t eq '!' ) { $pos++; my $e = $p_un->(); return sub { !$e->(@_) } }
        if ( !ref $t && $t eq '(' ) {
            $pos++;
            die "find: empty parentheses are not allowed in argument list\n" if defined $tok[$pos] && $tok[$pos] eq ')';
            my $e = $p_or->();
            die "find: invalid expression; you have too many '('\n" unless defined $tok[$pos] && !ref $tok[$pos] && $tok[$pos] eq ')';
            $pos++;
            return $e;
        }
        die "find: invalid expression; you have used a binary operator '$t' with nothing before it.\n" if !ref $t && ( $t eq '-o' || $t eq '-a' );
        die "find: invalid expression; you have too many ')'\n" if !ref $t;
        $pos++;
        return $t;
    };
    $p_and = sub {
        my @e = ( $p_un->() );
        while ( defined( my $t = $tok[$pos] ) ) {
            last if !ref $t && ( $t eq '-o' || $t eq ')' );
            $pos++ if !ref $t && $t eq '-a';
            push @e, $p_un->();
        }
        return @e == 1 ? $e[0] : sub { for my $f (@e) { return 0 unless $f->(@_) } 1 };
    };
    $p_or = sub {
        my @e = ( $p_and->() );
        while ( defined( my $t = $tok[$pos] ) && !ref $tok[$pos] && $tok[$pos] eq '-o' ) { $pos++; push @e, $p_and->() }
        return @e == 1 ? $e[0] : sub { for my $f (@e) { return 1 if $f->(@_) } 0 };
    };
    my $expr = sub {1};
    if (@tok) {
        $expr = eval { my $e = $p_or->(); die "find: invalid expression; you have too many ')'\n" if $pos < @tok; $e };
        if ( my $err = $@ ) { $err =~ s/\s+\z//; return ( $err, 0 ) }
    }
    my ( @hit, @err );
    for my $r (@roots) {
        ( my $root = $r ) =~ s{(?<=.)/+\z}{};
        if ( !_is_dir( $dev, $root ) && !_file_entry( $dev, $root ) ) { push @err, "find: '$r': No such file or directory"; next }
        my @cand = ( [ $root, 0 ] );
        if ( !_file_entry( $dev, $root ) ) {
            my %seen;
            my $pre = $root eq '/' ? '/' : "$root/";
            for my $p ( keys %{ $dev->{files} || {} }, keys %{ $dev->{dirs} || {} }, keys %{ $dev->{_dirs} || {} } ) {
                next unless index( $p, $pre ) == 0;
                my @seg = split m{/}, substr( $p, length $pre );
                $seen{ $pre . join( '/', @seg[ 0 .. $_ ] ) } = $_ + 1 for 0 .. $#seg;
            }
            push @cand, map { [ $_, $seen{$_} ] } sort keys %seen;
        }
        my @pruned;    # Eltern stehen vor ihren Kindern (sortiert)
        for my $c (@cand) {
            my ( $p, $depth ) = @$c;
            next if grep { index( $p, "$_/" ) == 0 } @pruned;
            next if defined $maxd && $depth > $maxd;
            next if defined $mind && $depth < $mind;
            my $fe = _file_entry( $dev, $p );
            my $kind = $fe ? ( defined $fe->{link} ? 'l' : 'f' ) : 'd';
            my $e = $fe // { mode => '0755', %{ ( $dev->{dirs} || {} )->{$p} || {} } };
            local @FIND_ACT = ();
            local $FIND_PRUNE;
            my $match = $expr->( $p, $e, $kind );
            push @pruned, $p if $FIND_PRUNE;
            if ($has_action) { push @hit, [ $p, $e, $kind, [@FIND_ACT] ] if @FIND_ACT }
            elsif ($match)  { push @hit, [ $p, $e, $kind, [ ['print'] ] ] }
        }
    }
    my @out = @err;
    my $ok = @err ? 0 : 1;
    my ( %exec_paths, @del, $txt );
    $txt = '';
    for my $h (@hit) {
        my ( $p, $e, $kind, $acts ) = @$h;
        for my $a (@$acts) {
            if    ( $a->[0] eq 'print' )  { $txt .= "$p\n" }
            elsif ( $a->[0] eq 'ls' )     { $txt .= _ls_line( $dev, $p, $p ) . "\n" }
            elsif ( $a->[0] eq 'printf' ) { $txt .= _find_printf( $dev, $a->[1], $p, $e, $kind ) }
            elsif ( $a->[0] eq 'exec' )   { push @{ $exec_paths{ $a->[1] } }, $p }
            elsif ( $a->[0] eq 'delete' ) { push @del, $p }
        }
    }
    $txt =~ s/\n\z//;
    push @out, $txt if length $txt;
    for my $i ( 0 .. $#exec ) {
        my ( $c, $end ) = @{ $exec[$i] };
        my @paths = @{ $exec_paths{$i} || [] };
        my @runs = $end eq '+' ? ( @paths ? [ map { $_ eq '{}' ? @paths : $_ } @$c ] : () )
            : map { my $h = $_; [ map { $_ eq '{}' ? $h : s/\{\}/$h/gr } @$c ] } @paths;
        for my $argv (@runs) {
            my ( $o, $k ) = __PACKAGE__->_command( $dev, $argv, $ctx, undef );
            push @out, $o if defined $o && length $o;
            $ok = 0 unless $k;
        }
    }
    for my $p ( reverse @del ) {
        if ( _file_entry( $dev, $p ) ) { my ( $o, $k ) = _rm( $dev, [$p] ); push @out, $o if length $o }
        elsif ( _ls_names_empty( $dev, $p ) ) { delete $dev->{dirs}{$p}; delete $dev->{_dirs}{$p} if $dev->{_dirs} }
        else { push @out, "find: cannot delete '$p': Directory not empty"; $ok = 0 }
    }
    return ( join( "\n", @out ), $ok );
}

# find -printf: %p %f %h %s %u %g %m %M %l %y %t %T+ %TY-%Tm-%Td, \n \t
sub _find_printf {
    my ( $dev, $fmt, $p, $e, $kind ) = @_;
    my $t = _mtime($e);    # Ortszeit
    my @g = gmtime $t;
    my ( $base, $dir ) = ( $p =~ m{([^/]*)\z} )[0];
    ( $dir = $p ) =~ s{/[^/]*\z}{};
    my $m = $kind eq 'd' ? oct( $e->{mode} // '0755' ) : _mode_of($e);
    my %f = (
        p => $p, f => $base, h => length $dir ? $dir : '.', s => $kind eq 'd' ? 4096 : _file_size($e), u => $e->{owner} // 'root',
        g => $e->{group} // 'root', m => sprintf( '%o', $m & 07777 ), M => _mode_text( $m, $kind eq 'd', $kind eq 'l' ),
        l => $kind eq 'l' ? $e->{link} : '', y => $kind, t => scalar gmtime($t),
        '%' => '%',
    );
    my %T = ( '+' => sprintf( '%04d-%02d-%02d+%02d:%02d:%02d.0000000000', $g[5] + 1900, $g[4] + 1, $g[3], $g[2], $g[1], $g[0] ),
        Y => sprintf( '%04d', $g[5] + 1900 ), m => sprintf( '%02d', $g[4] + 1 ), d => sprintf( '%02d', $g[3] ), H => sprintf( '%02d', $g[2] ),
        M => sprintf( '%02d', $g[1] ), S => sprintf( '%02d', $g[0] ), F => sprintf( '%04d-%02d-%02d', $g[5] + 1900, $g[4] + 1, $g[3] ),
        T => sprintf( '%02d:%02d:%02d', $g[2], $g[1], $g[0] ) );
    ( my $s = $fmt ) =~ s/\\n/\n/g;
    $s =~ s/\\t/\t/g;
    $s =~ s/%[TA]([+YmdHMSFT])/$T{$1}/g;
    $s =~ s/%(-?\d*)([pfhsugmMlyt%])/length $1 ? sprintf( "%$1s", $f{$2} ) : $f{$2}/ge;
    return $s;
}

sub _ls_names_empty { my ( $dev, $p ) = @_; return !%{ _ls_names( $dev, $p ) } }

# -perm [-/]oktal | [-/]u=s,g+w…  ->  [ art, maske ]
sub _find_perm {
    my ($v) = @_;
    my ( $kind, $rest ) = $v =~ /\A([-\/]?)(.+)\z/ or return undef;
    return [ $kind, oct $rest ] if $rest =~ /\A[0-7]{1,4}\z/;
    my $m = 0;
    for my $part ( split /,/, $rest ) {
        my ( $who, $p ) = $part =~ /\A([ugoa]*)[+=]([rwxst]+)\z/ or return undef;
        $who = 'a' if $who eq '';
        for my $w ( $who =~ /a/ ? qw( u g o ) : split //, $who ) {
            my $sh = { u => 6, g => 3, o => 0 }->{$w};
            for ( split //, $p ) {
                if    ( $_ eq 's' ) { $m |= { u => 04000, g => 02000, o => 0 }->{$w} }
                elsif ( $_ eq 't' ) { $m |= 01000 }
                else                { $m |= { r => 4, w => 2, x => 1 }->{$_} << $sh }
            }
        }
    }
    return [ $kind, $m ];
}

sub _lsof {
    my ( $dev, $av ) = @_;
    my @l = ('COMMAND     PID USER   FD   TYPE DEVICE     SIZE/OFF NLINK    NODE NAME');
    my $pid = 1200;
    for my $d ( @{ $dev->{deleted_open} || [] } ) {
        my $u = ( ( $dev->{services} || {} )->{ $d->{by} // '' } || {} )->{user} // 'root';
        push @l, sprintf( '%-9s %5d %-6s %4s %4s %6s %12d %5d %7d %s (deleted)', substr( $d->{by} // '?', 0, 9 ), $pid++, $u,
            '3w', 'REG', '254,1', _bytes( $d->{size} ), 0, 4242, $d->{path} );
    }
    if ( !grep { /\+L1|-a|deleted/ } @$av ) {
        for my $p ( sort keys %{ $dev->{files} || {} } ) {
            my $e = _file_entry( $dev, $p );
            next unless defined $e->{open_by};
            my $u = ( ( $dev->{services} || {} )->{ $e->{open_by} } || {} )->{user} // 'root';
            push @l, sprintf( '%-9s %5d %-6s %4s %4s %6s %12d %5d %7d %s', substr( $e->{open_by}, 0, 9 ), $pid++, $u, '3w', 'REG', '254,1',
                _file_size($e), 1, 4243, $p );
        }
    }
    return ( join( "\n", @l ), 1 );
}

# Datenbank-Programme gibt es nur, wo die Datenbank laeuft
our %NEEDS = ( ( map { $_ => 'redis' } qw( redis-cli redis-server ) ),
    ( map { $_ => 'mariadb' } qw( mysql mariadb mysqld mariadbd mysqladmin mariadb-admin mysqldump ) ) );

# Zeitangabe fuer date -d: @EPOCHE, now/today/tomorrow/yesterday, [JJJJ-MM-TT][ |T][HH:MM[:SS]] [ZONE|+HH:MM],
# [now] + N hours|minutes|days; $now ist die Uhr des Geraets
sub _date_parse {
    my ( $s, $tz, $C, $now ) = @_;
    $s =~ s/\A\s+|\s+\z//g;
    return $1 if $s =~ /\A\@(-?\d+)\z/;
    return $now + $1 * { h => 3600, m => 60, d => 86400 }->{ lc substr( $2, 0, 1 ) } if $s =~ /\A(?:now\s*)?\+\s*(\d+)\s*(hours?|minutes?|days?)\z/i;
    # "20 days ago", "-3 days", "2 hours ago" (Monate/Jahre wie GNU als Kalenderschritt genaehert)
    if ( $s =~ /\A(?:(\d+)\s*(\w+?)\s+ago|-\s*(\d+)\s*(\w+))\z/i ) {
        my ( $n, $u ) = defined $1 ? ( $1, lc $2 ) : ( $3, lc $4 );
        my %f = ( sec => 1, second => 1, seconds => 1, secs => 1, min => 60, mins => 60, minute => 60, minutes => 60, hour => 3600, hours => 3600,
            day => 86400, days => 86400, week => 604800, weeks => 604800, month => 2592000, months => 2592000, year => 31536000, years => 31536000 );
        return defined $f{$u} ? $now - $n * $f{$u} : undef;
    }
    my $fixed;    # +02:00 am Ende: fester Versatz
    if ( $s =~ s/\s*([+-])(\d\d):?(\d\d)\z// ) { $fixed = ( $1 eq '-' ? -1 : 1 ) * ( $2 * 3600 + $3 * 60 ) }
    my $zone = $tz;
    if ( $s =~ s/\s*\b(UTC|GMT|Z|CEST|CET|[A-Z][a-z]+\/[A-Za-z_]+)\z//i ) { my $z = $1; $zone = uc($z) eq 'Z' ? 'UTC' : $z =~ m{/} ? $z : uc $z }
    return undef unless $Langertha::Holmgang::Sim::Linux::Calendar::ZONE{$zone};
    my @l = gmtime( $now + $C->can('offset')->( $now, $zone ) );
    my ( $y, $m, $d, $H, $M, $S ) = ( $l[5] + 1900, $l[4] + 1, $l[3], 0, 0, 0 );
    my $day = 0;
    if    ( $s eq '' || $s eq 'now' ) { return $now }
    elsif ( $s =~ s/\A(today|tomorrow|yesterday)\b\s*//i ) {
        $day = { today => 0, tomorrow => 1, yesterday => -1 }->{ lc $1 };
        ( $H, $M, $S ) = @l[ 2, 1, 0 ] unless length $s;    # ohne Uhrzeit: die von jetzt (wie GNU)
    }
    elsif ( $s =~ s/\A(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T]+|\z)// ) { ( $y, $m, $d ) = ( $1, $2, $3 ) }
    if ( $s =~ s/\A(\d{1,2}):(\d{2})(?::(\d{2}))?\z// ) { ( $H, $M, $S ) = ( $1, $2, $3 // 0 ) }
    return undef if length $s || $m < 1 || $m > 12 || $d < 1 || $d > 31 || $H > 23 || $M > 59 || $S > 59;
    require Time::Local;
    my $u = eval { Time::Local::timegm( $S, $M, $H, $d, $m - 1, $y ) } // return undef;
    $u += 86400 * $day;
    return $u - $fixed if defined $fixed;
    my $off = $C->can('offset')->( $u - $C->can('offset')->( $u, $zone ), $zone );
    return $u - $off;
}

# redis-cli (ohne Redis-Zustand)/redis-server: nur mit einem Dienst redis-server (Langertha::Holmgang::Sim::Linux::RedisService)
sub _redis_cmd {
    my ( $how, $dev, $av, $ctx ) = @_;
    _part('RedisService');
    my $n = $how eq 'cli' ? 'redis-cli' : 'redis-server';
    if ( !Langertha::Holmgang::Sim::Linux::RedisService::installed($dev) ) {
        return ( "bash: $n: command not found", 0 ) unless _prog_file( $dev, $n );
        push @GAPS, join( ' ', $n, @$av );
        return ( '', 0 );
    }
    my ( $o, $k, $gap ) = $how eq 'cli' ? Langertha::Holmgang::Sim::Linux::RedisService::cli( $dev, $av, $ctx->{host} ) : Langertha::Holmgang::Sim::Linux::RedisService::server( $dev, $av );
    push @GAPS, $gap if defined $gap;
    return ( $o, $k );
}

# Dateiargumente eines Filters (head -n 3 DATEI, awk PROG DATEI …): ohne Optionen und
# ihre Werte, ohne das Programm von awk und ohne die Ausgabedatei von uniq; tr liest nur stdin
my %FILTER_VALUE = (
    head => qr/\A(?:-[nc]|--lines|--bytes)\z/, tail => qr/\A(?:-[ncs]|--lines|--bytes|--pid|--sleep-interval)\z/,
    sort => qr/\A(?:-[ktoTS]|--key|--field-separator|--output|--buffer-size)\z/, uniq => qr/\A-[fsw]\z/,
    cut  => qr/\A-[dfcb]\z/, awk => qr/\A-[Fvf]\z/, fold => qr/\A-w\z/, wc => qr/\A(?!)/,
);
sub _filter_files {
    my ( $cmd, @a ) = @_;
    my $val = $FILTER_VALUE{$cmd} or return ();
    my ( @ops, $prog_f );
    while (@a) {
        my $x = shift @a;
        if ( $x eq '--' ) { push @ops, @a; last }
        if ( $x =~ $val ) { $prog_f = 1 if $cmd eq 'awk' && $x eq '-f'; shift @a; next }
        next if $x =~ /\A-./;
        push @ops, $x;
    }
    if ( $cmd eq 'awk' ) {
        shift @ops unless $prog_f;    # das Programm
        @ops = grep { !/\A[A-Za-z_]\w*=/ } @ops;    # var=wert ist eine Zuweisung
    }
    @ops = @ops[ 0 .. 0 ] if $cmd eq 'uniq' && @ops > 1;
    return @ops;
}

# od -c | -An | -t c [DATEI…]: Bytes als Zeichen wie GNU od (je Zeile 16, Breite 4,
# \n \t … als Escapes, sonst oktal), Versatz oktal; anderes ist eine Luecke
sub _od {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my ( $chars, $hex, $noaddr, @files );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-c' || $x eq '-tc' ) { $chars = 1 }
        elsif ( $x eq '-t' && ( $a[0] // '' ) eq 'c' ) { shift @a; $chars = 1 }
        elsif ( $x eq '-tx1' || $x eq '-t' && ( $a[0] // '' ) eq 'x1' ) { shift @a if $x eq '-t'; $hex = 1 }
        elsif ( $x eq '-An' || $x eq '-A' && ( $a[0] // '' ) eq 'n' ) { shift @a if $x eq '-A'; $noaddr = 1 }
        elsif ( $x =~ /\A-(?:An)?c\z|\A-cAn\z/ ) { $chars = 1; $noaddr = 1 if $x =~ /An/ }
        elsif ( $x =~ /\A-/ ) { push @GAPS, join( ' ', 'od', @$av ); return ( '', 0 ) }
        else { push @files, $x }
    }
    unless ( $chars xor $hex ) { push @GAPS, join( ' ', 'od', @$av ); return ( '', 0 ) }
    my $in = '';
    if (@files) {
        for my $f (@files) {
            my $p = _absp($f);
            return ( "od: $f: Permission denied", 0 ) unless _read_ok( $dev, $p );
            my $t = _file_text( $dev, $p ) // return ( "od: $f: No such file or directory", 0 );
            $in .= $t;
        }
    }
    else { $in = ( $stdin // '' ) . ( defined $stdin && length $stdin && $STDIN_NL ? "\n" : '' ) }
    utf8::encode( my $b = $in );
    my %esc = ( 0 => '\0', 7 => '\a', 8 => '\b', 9 => '\t', 10 => '\n', 11 => '\v', 12 => '\f', 13 => '\r' );
    my ( @l, $prev, $star );
    for ( my $o = 0; $o < length $b; $o += 16 ) {
        my $chunk = substr( $b, $o, 16 );
        my $row = join '', map { my $c = ord; $hex ? sprintf( ' %02x', $c ) : sprintf '%4s', $esc{$c} // ( $c >= 32 && $c < 127 ? chr $c : sprintf '%03o', $c ) } split //, $chunk;
        if ( defined $prev && $chunk eq $prev ) { push @l, '*' unless $star; $star = 1; next }
        ( $prev, $star ) = ( $chunk, 0 );
        push @l, $noaddr ? $row : sprintf( '%07o', $o ) . $row;
    }
    push @l, sprintf '%07o', length $b unless $noaddr;
    return ( join( "\n", @l ), 1 );
}

# flock [-n|-x|-s|-w N|-E N] FD | DATEI [-c BEFEHL | BEFEHL …]: gelingt (die Simulation
# kennt keine nebenlaeufigen Laeufe, es haelt niemand die Sperre); die Sperrdatei wird
# angelegt, ein Befehl laeuft
sub _flock {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my $c;
    while ( @a && $a[0] =~ /\A-/ ) {
        my $x = shift @a;
        if    ( $x =~ /\A-[wE]\z/ || $x =~ /\A--(?:timeout|conflict-exit-code)\z/ ) { shift @a }
        elsif ( $x eq '-c' || $x eq '--command' ) { $c = shift @a }
        elsif ( $x =~ /\A-[nxseuo]+\z|\A--(?:nonblock|exclusive|shared|unlock|close)\z/ ) { }
        else { return ( "flock: unrecognized option '$x'", 0 ) }
    }
    my $t = shift(@a) // return ( "flock: not enough arguments\nTry 'flock --help' for more information.", 0 );
    if ( @a && ( $a[0] eq '-c' || $a[0] eq '--command' ) ) { shift @a; $c = shift @a }    # flock DATEI -c BEFEHL
    return ( '', 1 ) if $t =~ /\A\d+\z/ && !@a && !defined $c;    # flock FD
    my $p = _absp($t);
    if ( !_file_entry( $dev, $p ) && !_is_dir( $dev, $p ) ) {
        my ( $e, $wok ) = _write_path( $dev, $p, '', 0, $ctx );
        return ( "flock: cannot open lock file $t: " . ( $e =~ /: ([^:]+)\z/ ? $1 : 'No such file or directory' ), 0 ) unless $wok;
    }
    return __PACKAGE__->_run_inner( $dev, $c, $ctx ) if defined $c;
    return ( '', 1 ) unless @a;
    return __PACKAGE__->_command( $dev, \@a, $ctx, $stdin );
}

# Pruefsumme wie coreutils (md5, sha1, sha256) ueber die Bytes (UTF-8); hier fuer sha256sum
# ohne Datei (stdin) — Dateien rechnet Sim::Backup, md5sum hat _md5sum; -c ist eine Luecke
sub _digest {
    my ( $alg, $dev, $av, $ctx, $stdin ) = @_;
    my @f = grep { !/\A-/ } @$av;
    if ( grep { /\A-(?:c|-check)\z/ } @$av ) { push @GAPS, join( ' ', "${alg}sum", @$av ); return ( '', 0 ) }
    require Digest::MD5;
    require Digest::SHA;
    my $h = sub { my $b = shift; utf8::encode($b); $alg eq 'md5' ? Digest::MD5::md5_hex($b) : $alg eq 'sha1' ? Digest::SHA::sha1_hex($b) : Digest::SHA::sha256_hex($b) };
    return ( $h->( ( $stdin // '' ) . ( defined $stdin && length $stdin && $STDIN_NL ? "\n" : '' ) ) . '  -', 1 ) unless @f;
    my ( @out, $ok ) = ();
    $ok = 1;
    for my $f (@f) {
        my $p = _absp($f);
        if ( _is_dir( $dev, $p ) && !_file_entry( $dev, $p ) ) { push @out, "${alg}sum: $f: Is a directory"; $ok = 0; next }
        if ( _file_entry( $dev, $p ) && !_read_ok( $dev, $p ) ) { push @out, "${alg}sum: $f: Permission denied"; $ok = 0; next }
        my $t = _file_text( $dev, $p );
        if ( !defined $t ) { push @out, "${alg}sum: $f: No such file or directory"; $ok = 0; next }
        my $e = _file_entry( $dev, $p );
        if ( ref $e eq 'HASH' && defined $e->{size} && !length( $e->{content} // '' ) ) { push @GAPS, join( ' ', "${alg}sum", @$av ); return ( '', 0 ) }    # nur Groesse bekannt
        push @out, $h->($t) . "  $f";
    }
    return ( join( "\n", @out ), $ok );
}

# lsblk-Optionen: -o|--output LISTE (+LISTE ergaenzt die Vorgabe), -b, -n, -l, -p, -a, -f, -m,
# Geraete als Argumente. Rueckgabe \%o; ( undef, Text ) bei Fehler wie lsblk; () bei Luecke
our %LSBLK_COL = map { $_ => 1 } qw( NAME KNAME PATH MAJ:MIN RM SIZE RO TYPE MOUNTPOINT MOUNTPOINTS FSTYPE LABEL UUID FSAVAIL FSUSE% );

sub _lsblk_opts {
    my ($av) = @_;
    my %o = ( dev => [] );
    my %long = ( all => 'a', bytes => 'b', noheadings => 'n', list => 'l', paths => 'p', fs => 'f', perms => 'm' );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A--output=(.*)\z/ ) { $o{cols} = $1 }
        elsif ( $x eq '--output' ) { $o{cols} = shift(@a) // return }
        elsif ( $x =~ /\A--(\w+)\z/ && $long{$1} ) { $o{ $long{$1} } = 1 }
        elsif ( $x =~ /\A-([abnlpfm]*)(?:(o)(.*))?\z/ && length( $1 . ( $2 // '' ) ) ) {
            my ( $fl, $oo, $rest ) = ( $1, $2, $3 );
            $o{$_} = 1 for split //, $fl;
            $o{cols} = length $rest ? $rest : shift(@a) // return if $oo;
        }
        elsif ( $x =~ /\A-/ ) { return }
        else { push @{ $o{dev} }, $x }
    }
    return if $o{m};
    my @def = $o{f} ? qw( NAME FSTYPE LABEL UUID FSAVAIL FSUSE% MOUNTPOINTS ) : qw( NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS );
    if ( defined $o{cols} ) {
        my $plus = $o{cols} =~ s/\A\+//;
        my @c = map {uc} grep {length} split /,/, $o{cols};
        for (@c) { return ( undef, "lsblk: unknown column: $_" ) unless $LSBLK_COL{$_} }
        $o{list} = [ $plus ? ( @def, @c ) : @c ];
    }
    else { $o{list} = \@def }
    $o{table} = 1 if defined $o{cols} || grep { $o{$_} } qw( b n l p );
    return \%o;
}

# Zeilen -> Tabelle wie lsblk: Zeile { name, path, tree, majmin, size (Bytes), type, mps => [], fstype,
# label, uuid, fsavail (Bytes), fsuse }; Zahlenspalten rechtsbuendig, eine Leerstelle dazwischen
sub _lsblk_table {
    my ( $rows, $o ) = @_;
    my %right = map { $_ => 1 } qw( RM SIZE RO FSAVAIL FSUSE% );
    my $sz = sub { my $b = shift; return '' unless defined $b; $o->{b} ? $b : _human($b) };
    my %val = (
        NAME        => sub { ( $o->{l} ? '' : $_[0]{tree} // '' ) . ( $o->{p} ? $_[0]{path} : $_[0]{name} ) },
        KNAME       => sub { $o->{p} ? $_[0]{path} : $_[0]{name} },
        PATH        => sub { $_[0]{path} },
        'MAJ:MIN'   => sub { $_[0]{majmin} },
        RM          => sub {0},
        RO          => sub {0},
        SIZE        => sub { $sz->( $_[0]{size} ) },
        TYPE        => sub { $_[0]{type} },
        MOUNTPOINT  => sub { $_[0]{mps}[0] // '' },
        MOUNTPOINTS => sub { join ' ', @{ $_[0]{mps} } },
        FSTYPE      => sub { $_[0]{fstype} // '' },
        LABEL       => sub { $_[0]{label} // '' },
        UUID        => sub { $_[0]{uuid} // '' },
        FSAVAIL     => sub { $sz->( $_[0]{fsavail} ) },
        'FSUSE%'    => sub { defined $_[0]{fsuse} ? "$_[0]{fsuse}%" : '' },
    );
    my @c = @{ $o->{list} };
    my @t = ( $o->{n} ? () : [@c], map { my $r = $_; [ map { $val{$_}->($r) } @c ] } @$rows );
    my @w = map { my $i = $_; my $m = 0; for (@t) { my $l = length $_->[$i]; $m = $l if $l > $m } $m } 0 .. $#c;
    return join "\n", map {
        my $r = $_;
        join( ' ', map { $right{ $c[$_] } ? sprintf( '%*s', $w[$_], $r->[$_] ) : sprintf( '%-*s', $w[$_], $r->[$_] ) } 0 .. $#c ) =~ s/\s+\z//r
    } @t;
}

# lsblk ohne Platten im Zustand: die Geraete der Einhaengepunkte (vda1 -> Platte vda);
# LABEL, UUID und -f/-m kennt der Zustand hier nicht (Luecke)
sub _lsblk_basic {
    my ( $dev, $av ) = @_;
    my ( $o, $err ) = _lsblk_opts($av);
    return ( $err, 0 ) if defined $err;
    if ( !$o || $o->{f} || @{ $o->{dev} } || grep { /\A(?:LABEL|UUID)\z/ } @{ $o->{list} } ) { push @GAPS, join( ' ', 'lsblk', @$av ); return ( '', 0 ) }
    my $m = _mounts($dev);
    my ( %disk, @order );
    my $minor = 0;
    for my $mp ( sort keys %$m ) {
        my $d = $m->{$mp}{dev} // '/dev/vda1';
        next unless $d =~ m{\A/dev/((?:[sv]d[a-z]|nvme\d+n\d+)(?:p?\d+)?)\z};
        my $part = $1;
        ( my $disk = $part ) =~ s/(?:p?\d+)\z// unless $part =~ /\Anvme\d+n\d+\z/;
        $disk //= $part;
        push @order, $disk unless $disk{$disk};
        push @{ $disk{$disk} }, [ $part, $m->{$mp}{size} // '40G', $mp, $m->{$mp}{fstype} ];
    }
    my %df = map { $_->{mount} => $_ } _df_rows($dev);
    my @rows;
    my $maj = 254;
    for my $dk (@order) {
        my $base = $minor;
        my @parts = grep { $_->[0] ne $dk } @{ $disk{$dk} };
        my ($whole) = grep { $_->[0] eq $dk } @{ $disk{$dk} };
        my $size = $whole ? $whole->[1] : $parts[0][1];
        my @r = ( [ $dk, "$maj:$base", $size, 'disk', $whole, '' ] );
        my $i = 0;
        for my $pt (@parts) {
            $i++;
            push @r, [ $pt->[0], "$maj:" . ( $base + $i ), $pt->[1], 'part', $pt, $i == @parts ? "\x{2514}\x{2500}" : "\x{251c}\x{2500}" ];
        }
        for (@r) {
            my ( $n, $mm, $sz, $type, $src, $tree ) = @$_;
            my $mp = $src ? $src->[2] : undef;
            my $df = defined $mp ? $df{$mp} : undef;
            push @rows, { name => $n, path => "/dev/$n", tree => $tree, majmin => $mm, size => $sz, type => $type, mps => [ $mp // () ],
                fstype => $src ? $src->[3] // 'ext4' : undef, fsavail => $df ? $df->{avail} : undef, fsuse => $df ? $df->{pct} : undef };
        }
        $minor += 16;
    }
    if ( $o->{table} ) { $_->{size} = _bytes( $_->{size} ) for @rows; return ( _lsblk_table( \@rows, $o ), 1 ) }
    my @l = ( sprintf '%-8s %-7s %2s %5s %2s %-4s %s', 'NAME', 'MAJ:MIN', 'RM', 'SIZE', 'RO', 'TYPE', 'MOUNTPOINTS' );
    push @l, sprintf( '%-8s %-7s %2d %5s %2d %-4s %s', $_->{tree} . $_->{name}, $_->{majmin}, 0, $_->{size}, 0, $_->{type}, join( ' ', @{ $_->{mps} } ) ) =~ s/\s+\z//r for @rows;
    return ( join( "\n", @l ), 1 );
}

# Programm, das als ausfuehrbare Datei im Zustand liegt (z. B. /usr/bin/redis-cli)
sub _prog_file {
    my ( $dev, $n ) = @_;
    return undef if $n =~ m{/};
    for my $d (qw( /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin )) {
        my $e = _file_entry( $dev, "$d/$n" ) or next;
        return "$d/$n" if _mode_of($e) & 0111;
    }
    return undef;
}

# Shell-Skript im Zustand: Text mit sh/bash/dash-Shebang oder ohne Shebang (leer = Programm)
sub _shell_script {
    my ( $dev, $p ) = @_;
    return 0 unless _file_entry( $dev, $p );
    my $t = _file_text( $dev, $p ) // '';
    return $t =~ /\S/ && $t !~ m{\A#!(?!\s*(?:\S*/env\s+(?:-S\s+)?)?\S*\b(?:ba|da)?sh\b)} ? 1 : 0;    # auch #!/usr/bin/env bash
}

# which/whereis/type/command -v: Pfad eines Programms, das es auf dem System gibt
sub _which {
    my ( $how, $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    if ( $how eq 'command' ) {
        return __PACKAGE__->_command( $dev, \@a, $ctx, $stdin ) unless @a && $a[0] =~ /\A-[vV]\z/;
        shift @a;
    }
    @a = grep { !/\A-/ } @a;
    return ( '', 1 ) unless @a;
    my ( @out, $ok );
    $ok = 1;
    # Dienstprogramme aus ExecStart (exec); eine Datei des Falls gilt vor der Vorgabe
    my %exec = map { ( $_->{exec} // '' ) => 1 } grep { ref eq 'HASH' } values %{ $dev->{services} || {} };
    for my $n (@a) {
        my ($file) = grep { _file_entry( $dev, $_ ) } map {"$_/$n"} qw( /usr/local/bin /usr/bin /usr/sbin /bin );
        my $have = $NEEDS{$n} ? $dev->{ $NEEDS{$n} } : $CMD{$n} || $REAL{$n} || $FILTER{$n} || $INTERACTIVE{$n} || $exec{$n}
            || $n =~ /\A(?:ls|bash|sh|cat|cp|mv|rm|mkdir|tail|head|grep|sed|awk|find)\z/;
        $have = 0 if $NOT_INSTALLED{$n};
        $have = 1 if _web_cmd( $dev, $n );
        # Zusatz-Simulatoren (BIND, Postfix, Platten, …) nur, wo ihr Paket im Zustand steht
        if ( $have && $CMD{$n} && ( my $need = $EXT_NEED{ $CMD{$n} } ) ) { $have = 0 if @$need && !grep { $dev->{$_} } @$need }
        $have = 1 if $file;
        my $path = $file // ( $n =~ /\A(?:kubectl|helm)\z/ ? '/usr/local/bin/' : $SBIN{$n} || $n =~ /\A(?:mkfs.*|fsck.*|pv\w+|vg\w+|lv\w+|named-check\w+)\z/ ? '/usr/sbin/' : '/usr/bin/' ) . $n;
        if ( my $prog = _prog_file( $dev, $n ) ) { ( $have, $path ) = ( 1, $prog ) }
        if ( $how eq 'whereis' ) { push @out, $have && !$BUILTIN{$n} ? "$n: $path" : "$n:"; next }
        if ( $BUILTIN{$n} && $how ne 'which' ) { push @out, $how eq 'type' ? "$n is a shell builtin" : $n; next }
        if ( !$have || $BUILTIN{$n} && $n !~ /\A(?:echo|printf|true|false|test|\[)\z/ ) {
            push @out, "bash: type: $n: not found" if $how eq 'type';
            $ok = 0;
            next;
        }
        push @out, $how eq 'type' ? "$n is $path" : $path;
    }
    return ( join( "\n", @out ), $ok );
}

# --- Benutzer und Gruppen ------------------------------------------------------------

sub _id {
    my ( $dev, $av ) = @_;
    my ($u) = grep { !/\A-/ } @$av;
    $u //= _who();
    return ( 'uid=0(root) gid=0(root) groups=0(root)', 1 ) if $u eq 'root';
    my $e = ( $dev->{users} || {} )->{$u} or return ( "id: '$u': no such user", 0 );
    my @g = @{ $e->{groups} || [$u] };
    return ( "uid=$e->{uid}($u) gid=" . _gid( $dev, $g[0] ) . "($g[0]) groups=" . join( ',', map { _gid( $dev, $_ ) . "($_)" } @g ), 1 );
}

sub _groups_cmd {
    my ( $dev, $av ) = @_;
    my ($u) = @$av;
    $u //= 'root';
    return ( 'root', 1 ) if $u eq 'root';
    my $e = ( $dev->{users} || {} )->{$u} or return ( "groups: '$u': no such user", 0 );
    return ( "$u : " . join( ' ', @{ $e->{groups} || [] } ), 1 );
}

sub _usermod {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $add, $grps, $del, %set );
    while ( @a > 1 ) {
        my $x = shift @a;
        if    ( $x eq '-aG' || $x eq '-a' ) { $add = 1; $grps = shift @a if $x eq '-aG' }
        elsif ( $x eq '-rG' || $x eq '-r' || $x eq '--remove' ) { $del = 1; $grps = shift @a if $x eq '-rG' }
        elsif ( $x eq '-G' || $x eq '--groups' ) { $grps = shift @a }
        elsif ( $x eq '-L' || $x eq '--lock' )   { $set{locked} = 1 }
        elsif ( $x eq '-U' || $x eq '--unlock' ) { $set{locked} = 0 }
        elsif ( $x eq '-s' || $x eq '--shell' )  { $set{shell} = shift @a }
        elsif ( $x eq '-e' || $x eq '--expiredate' ) { $set{expire} = shift @a }
        elsif ( $x =~ /\A-[LU]+\z/ ) { $set{locked} = $x =~ /L/ ? 1 : 0 }
        elsif ( $x eq '-c' || $x eq '--comment' ) { shift @a }
        elsif ( $x eq '-d' || $x eq '--home' )    { $set{home} = shift @a }
        elsif ( $x eq '-m' || $x eq '--move-home' ) { $set{move} = 1 }
        else { return ( "usermod: invalid option -- '$x'", 0 ) }
    }
    my $u = shift @a;
    my $e = ( $dev->{users} || {} )->{ $u // '' } or return ( "usermod: user '" . ( $u // '' ) . "' does not exist", 0 );
    if ( defined $set{home} ) {
        my $old = $e->{home} // "/home/$u";
        my $new = delete $set{home};
        return ( "usermod: no changes", 1 ) if $old eq $new && !%set;
        _tree( $dev, $old, $new, 'move' ) if delete $set{move} && _is_dir( $dev, $old ) && !_is_dir( $dev, $new );
        $e->{home} = $new;
        return ( '', 1 ) unless %set || defined $grps;
    }
    delete $set{move};
    if ( exists $set{expire} ) { my $err = _acc()->can('set_expire')->( $dev, $e, $set{expire} ); return ( "usermod: $err", 0 ) if $err }
    if ( exists $set{locked} ) {
        my $want = $set{locked} ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
        $e->{locked} = $want if ( $e->{locked} ? 1 : 0 ) != $set{locked};
    }
    if ( defined $set{shell} ) {
        return ( "usermod: invalid shell '$set{shell}'", 0 ) unless $set{shell} =~ m{\A/};
        $e->{shell} = $set{shell} unless ( $e->{shell} // '' ) eq $set{shell};
    }
    if ( $del && defined $grps ) {
        my %rm = map { $_ => 1 } split /,/, $grps;
        my @g = grep { !$rm{$_} } @{ $e->{groups} || [] };
        $e->{groups} = \@g unless @g == @{ $e->{groups} || [] };
        return ( '', 1 );
    }
    return ( %set ? '' : "usermod: no changes", 1 ) unless defined $grps;
    my %known = ( map { $_ => 1 } keys %{ $dev->{groups} || {} }, map { @{ $_->{groups} || [] } } values %{ $dev->{users} } );
    my @new = split /,/, $grps;
    for (@new) { return ( "usermod: group '$_' does not exist", 0 ) unless $known{$_} }
    my @cur = @{ $e->{groups} || [] };
    my @g = $add ? ( @cur, grep { my $x = $_; !grep { $_ eq $x } @cur } @new ) : ( $cur[0] // $u, grep { $_ ne ( $cur[0] // $u ) } @new );
    $e->{groups} = \@g unless join( ',', @g ) eq join( ',', @cur );
    return ( '', 1 );
}

# Naechste freie Nummer: Konten ab 1000 nach der hoechsten vergebenen, Systemkonten von 999
# abwaerts (useradd/groupadd -r), adduser/addgroup --system ab 100 aufwaerts; $want zuerst
sub _free_id {
    my ( $used, $sys, $want, $up ) = @_;
    return $want if defined $want && !$used->{$want};
    if ($sys) {
        if ($up) { for my $i ( 100 .. 999 ) { return $i unless $used->{$i} } }
        for ( my $i = 999; $i >= 100; $i-- ) { return $i unless $used->{$i} }
    }
    my ($max) = sort { $b <=> $a } grep { $_ >= 1000 && $_ < 60000 } keys %$used;
    return defined $max ? $max + 1 : 1000;
}

sub _gids { my ($dev) = @_; return { map { ( $_->{gid} // -1 ) => 1 } values %{ $dev->{groups} || {} } } }

# groupadd [-r] [-g GID] name | addgroup [--system] [--gid GID] name
sub _groupadd {
    my ( $prog, $dev, $av ) = @_;
    my @a = @$av;
    my ( $sys, $gid, @n );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-r' || $x eq '--system' ) { $sys = 1 }
        elsif ( $x eq '-g' || $x eq '--gid' )    { $gid = shift @a }
        elsif ( $x eq '-f' || $x eq '--force' || $x eq '--quiet' || $x eq '-q' ) { }
        elsif ( $x =~ /\A-/ ) { return ( "$prog: unrecognized option '$x'", 0 ) }
        else { push @n, $x }
    }
    return ( $prog eq 'addgroup' ? 'fatal: Only one or two names allowed.' : "Usage: groupadd [options] GROUP", 0 ) unless @n == 1;
    my $g = $n[0];
    return ( $prog eq 'addgroup' ? "fatal: The group `$g' already exists." : "groupadd: group '$g' already exists", 0 ) if ( $dev->{groups} || {} )->{$g};
    return ( "$prog: '$g' is not a valid group name", 0 ) unless $g =~ /\A[a-z_][a-z0-9_-]*\$?\z/;
    my $used = _gids($dev);
    return ( "groupadd: GID '$gid' already exists", 0 ) if defined $gid && $used->{$gid};
    $dev->{groups}{$g} = { gid => 0 + _free_id( $used, $sys, $gid, $prog eq 'addgroup' ) };
    return ( '', 1 );
}

# useradd [-m|-M] [-r] [-s S] [-d D] [-g G] [-G a,b] [-u UID] name;
# adduser --system [--group|--ingroup G] [--no-create-home] [--home D] [--shell S] name;
# adduser BENUTZER GRUPPE. Interaktives adduser (Passwort): Luecke der Simulation.
sub _useradd {
    my ( $prog, $dev, $av ) = @_;
    my @a = @$av;
    my ( %o, @n );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-m' || $x eq '--create-home' )    { $o{home_make} = 1 }
        elsif ( $x eq '-M' || $x eq '--no-create-home' ) { $o{home_make} = 0 }
        elsif ( $x eq '-r' || $x eq '--system' )         { $o{sys} = 1 }
        elsif ( $x eq '-s' || $x eq '--shell' )          { $o{shell} = shift @a }
        elsif ( $x eq '-d' || $x eq '--home-dir' || $x eq '--home' ) { $o{home} = shift @a }
        elsif ( $x eq '-g' || $x eq '--gid' || $x eq '--ingroup' ) { $o{group} = shift @a }
        elsif ( $x eq '-G' || $x eq '--groups' )         { $o{groups} = shift @a }
        elsif ( $x eq '-u' || $x eq '--uid' )            { $o{uid} = shift @a }
        elsif ( $x eq '-c' || $x eq '--comment' || $x eq '--gecos' ) { shift @a }
        elsif ( $x eq '-U' || $x eq '--user-group' || $x eq '--group' ) { $o{usergroup} = 1 }
        elsif ( $x eq '-N' || $x eq '--no-user-group' )  { $o{usergroup} = 0 }
        elsif ( $x =~ /\A--(?:disabled-password|disabled-login|quiet|no-log-init)\z/ || $x eq '-q' ) { }
        elsif ( $x =~ /\A-/ ) { return ( $prog eq 'adduser' ? "Unknown option: " . ( $x =~ s/\A-+//r ) : "$prog: unrecognized option '$x'", 0 ) }
        else { push @n, $x }
    }
    my $users = $dev->{users} ||= {};
    if ( $prog eq 'adduser' && @n == 2 && !%o ) {    # adduser BENUTZER GRUPPE
        my ( $u, $g ) = @n;
        my $e = $users->{$u} or return ( "fatal: The user `$u' does not exist.", 0 );
        return ( "fatal: The group `$g' does not exist.", 0 ) unless ( $dev->{groups} || {} )->{$g};
        return ( "info: The user `$u' is already a member of `$g'.", 1 ) if grep { $_ eq $g } @{ $e->{groups} || [] };
        $e->{groups} = [ @{ $e->{groups} || [$u] }, $g ];
        return ( "Adding user `$u' to group `$g' ...\nDone.", 1 );
    }
    if ( $prog eq 'adduser' && !$o{sys} ) { push @GAPS, join( ' ', 'adduser', @$av ); return ( '', 0 ) }    # fragt nach Passwort und Namen
    return ( $prog eq 'adduser' ? 'fatal: Only one or two names allowed.' : "Usage: useradd [options] LOGIN", 0 ) unless @n == 1;
    my $u = $n[0];
    return ( $prog eq 'adduser' ? "fatal: The user `$u' already exists." : "useradd: user '$u' already exists", 0 ) if $users->{$u};
    return ( "$prog: invalid user name '$u'", 0 ) unless $u =~ /\A[a-z_][a-z0-9_-]*\$?\z/;
    my $groups = $dev->{groups} ||= {};
    my @extra = defined $o{groups} ? split /,/, $o{groups} : ();
    for ( ( defined $o{group} ? $o{group} : () ), @extra ) {
        return ( $prog eq 'adduser' ? "fatal: The group `$_' does not exist." : "useradd: group '$_' does not exist", 0 ) unless $groups->{$_};
    }
    my $usergroup = !defined $o{group} && ( $o{usergroup} // ( $prog eq 'useradd' ? 1 : 0 ) );
    return ( "useradd: group $u exists - if you want to add this user to that group, use -g.", 0 ) if $usergroup && $groups->{$u};
    my %uids = map { ( $_->{uid} // -1 ) => 1 } values %$users;
    my $uid = _free_id( \%uids, $o{sys}, $o{uid}, $prog eq 'adduser' );
    my $primary = defined $o{group} ? $o{group} : $usergroup ? $u : $prog eq 'adduser' ? 'nogroup' : 'users';
    if ($usergroup) { $groups->{$u} = { gid => 0 + _free_id( _gids($dev), $o{sys}, $uid, $prog eq 'adduser' ) } }
    $groups->{nogroup} //= { gid => 65534 } if $primary eq 'nogroup';
    $groups->{users}   //= { gid => 100 }   if $primary eq 'users';
    my $home = $o{home} // ( $prog eq 'adduser' && $o{sys} ? '/nonexistent' : "/home/$u" );
    my $shell = $o{shell} // ( $prog eq 'adduser' ? '/usr/sbin/nologin' : '/bin/sh' );
    $users->{$u} = { uid => 0 + $uid, groups => [ $primary, grep { $_ ne $primary } @extra ], shell => $shell,
        ( $home ne "/home/$u" ? ( home => $home ) : () ) };
    my $make = $o{home_make} // ( $prog eq 'adduser' && $o{sys} && $home ne '/nonexistent' ? 1 : 0 );
    $dev->{dirs}{$home} = { owner => $u, group => $primary, mode => '0755' } if $make && !_is_dir( $dev, $home );
    return ( '', 1 );
}

# install [-m MODUS] [-o BENUTZER] [-g GRUPPE] [-D] QUELLE… ZIEL | install -d [-m …] DIR…
sub _install {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( %o, @p );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-m' || $x eq '--mode' )  { $o{mode} = shift @a }
        elsif ( $x eq '-o' || $x eq '--owner' ) { $o{owner} = shift @a }
        elsif ( $x eq '-g' || $x eq '--group' ) { $o{group} = shift @a }
        elsif ( $x =~ /\A--(mode|owner|group)=(.*)\z/ ) { $o{$1} = $2 }
        elsif ( $x eq '-d' || $x eq '--directory' ) { $o{dir} = 1 }
        elsif ( $x eq '-D' ) { $o{parents} = 1 }
        elsif ( $x =~ /\A-([dDvpCcsb]+)\z/ ) { my $f = $1; $o{dir} = 1 if $f =~ /d/; $o{parents} = 1 if $f =~ /D/ }
        elsif ( $x =~ /\A-([dDvpC]*)([mog])\z/ ) { my ( $f, $k ) = ( $1, $2 ); $o{dir} = 1 if $f =~ /d/; $o{parents} = 1 if $f =~ /D/; $o{ { m => 'mode', o => 'owner', g => 'group' }->{$k} } = shift @a }
        elsif ( $x =~ /\A-/ ) { return ( "install: invalid option -- '" . substr( $x, 1, 1 ) . "'\nTry 'install --help' for more information.", 0 ) }
        else { push @p, $x }
    }
    return ( "install: invalid mode '$o{mode}'", 0 ) if defined $o{mode} && $o{mode} !~ /\A[0-7]{1,4}\z/;
    return ( "install: invalid user '$o{owner}'", 0 ) if defined $o{owner} && $o{owner} ne 'root' && !( $dev->{users} || {} )->{ $o{owner} };
    return ( "install: invalid group '$o{group}'", 0 )
        if defined $o{group} && $o{group} ne 'root' && !( $dev->{groups} || {} )->{ $o{group} } && !grep { grep { $_ eq $o{group} } @{ $_->{groups} || [] } } values %{ $dev->{users} || {} };
    my %meta = ( owner => $o{owner} // 'root', group => $o{group} // 'root', mode => sprintf( '%04o', oct( $o{mode} // '0755' ) ) );
    my $mkdirs = sub {
        my ($d) = @_;
        my @seg = split m{/}, $d;
        for my $t ( map { join '/', @seg[ 0 .. $_ ] } 1 .. $#seg ) { $dev->{dirs}{$t} //= {} unless _is_dir( $dev, $t ) }
    };
    if ( $o{dir} ) {
        return ( "install: missing file operand\nTry 'install --help' for more information.", 0 ) unless @p;
        for my $d ( map { _absp($_) =~ s{(?<=.)/+\z}{}r } @p ) { $mkdirs->($d); $dev->{dirs}{$d} = {%meta} }
        return ( '', 1 );
    }
    return ( "install: missing destination file operand after '" . ( $p[0] // '' ) . "'\nTry 'install --help' for more information.", 0 ) unless @p >= 2;
    my $to = _absp( pop @p ) =~ s{(?<=.)/+\z}{}r;
    if ( $o{parents} ) { ( my $d = @p > 1 ? "$to/x" : $to ) =~ s{/[^/]+\z}{}; $mkdirs->($d) if length $d }
    return ( "install: target '$to' is not a directory", 0 ) if @p > 1 && !_is_dir( $dev, $to );
    for my $src (@p) {
        my $e = ( $src eq '/dev/null' ? { content => '' } : _file_entry( $dev, _absp($src) ) ) or return ( "install: cannot stat '$src': No such file or directory", 0 );
        ( my $base = $src ) =~ s{.*/}{};
        my $dst = _is_dir( $dev, $to ) ? ( $to eq '/' ? '' : $to ) . "/$base" : $to;
        ( my $dd = $dst ) =~ s{/[^/]+\z}{};
        return ( "install: cannot create regular file '$dst': No such file or directory", 0 ) unless _is_dir( $dev, length $dd ? $dd : '/' );
        my %n = %$e;
        delete @n{qw( open_by link tar )};
        $dev->{files}{$dst} = { %n, %meta, mtime => 'Oct 20 12:00' };
    }
    return ( '', 1 );
}

sub _gpasswd {
    my ( $dev, $av ) = @_;
    my ( $o, $u, $g ) = @$av;
    return _acc()->can('remove_group')->( $dev, $u, $g, 'gpasswd' ) if defined $o && ( $o eq '-d' || $o eq '--delete' ) && defined $g;
    return ( 'Usage: gpasswd [option] GROUP', 0 ) unless defined $o && $o eq '-a' && defined $g;
    my ( $out, $ok ) = _usermod( $dev, [ '-aG', $g, $u ] );
    return ( $ok ? "Adding user $u to group $g" : $out, $ok );
}

sub _getent {
    my ( $dev, $av ) = @_;
    my ( $db, @keys ) = @$av;
    $db //= '';
    if ( $db eq 'passwd' ) {
        my @l;
        for my $u ( @keys ? @keys : ( 'root', sort keys %{ $dev->{users} || {} } ) ) {
            if ( $u eq 'root' ) { push @l, 'root:x:0:0:root:/root:/bin/bash'; next }
            my $e = ( $dev->{users} || {} )->{$u} or return ( join( "\n", @l ), 0 );
            push @l, "$u:x:$e->{uid}:" . _gid( $dev, ( $e->{groups} || [$u] )->[0] ) . ':' . ( $e->{gecos} // '' ) . ':' . ( $e->{home} // "/home/$u" ) . ':' . ( $e->{shell} // '/usr/sbin/nologin' );
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $db eq 'shadow' ) {
        my @l;
        for my $u ( @keys ? @keys : ( 'root', sort keys %{ $dev->{users} || {} } ) ) {
            if ( $u eq 'root' ) { push @l, 'root:*:20332:0:99999:7:::'; next }
            my $e = ( $dev->{users} || {} )->{$u} or return ( join( "\n", @l ), 0 );
            push @l, _acc()->can('shadow_line')->( $u, $e );
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $db eq 'group' ) {
        my %m;
        for my $u ( keys %{ $dev->{users} || {} } ) { push @{ $m{$_} }, $u for @{ $dev->{users}{$u}{groups} || [] } }
        my %known = ( %m, map { $_ => 1 } keys %{ $dev->{groups} || {} } );
        my @l = map { "$_:x:" . _gid( $dev, $_ ) . ':' . join( ',', sort @{ $m{$_} || [] } ) } grep { $known{$_} } @keys ? @keys : sort keys %m;
        return ( join( "\n", @l ), ( grep { !$known{$_} } @keys ) ? 0 : 1 );
    }
    if ( $db eq 'hosts' || $db eq 'ahosts' ) {
        my @l;
        for my $n (@keys) {
            my ($ip) = _resolve( $dev, $n );
            return ( join( "\n", @l ), 0 ) unless defined $ip;
            push @l, sprintf( '%-15s %s', $ip, $n );
        }
        return ( join( "\n", @l ), 1 );
    }
    return ( "Unknown database: $db\nTry `getent --help' or `getent --usage' for more information.", 0 );
}

# --- Resolver ---------------------------------------------------------------------

# Nameserver aus /etc/resolv.conf (bzw. dem Stub von systemd-resolved)
sub _nameservers {
    my ($dev) = @_;
    my $rc = _file_text( $dev, '/etc/resolv.conf' ) // '';
    my @ns = $rc =~ /^\s*nameserver\s+(\S+)/mg;
    if ( @ns == 1 && $ns[0] eq '127.0.0.53' && $dev->{resolved} ) {
        my $r = $dev->{resolved};
        @ns = ( ( map { @{ $_->{dns} || [] } } map { $r->{links}{$_} } sort keys %{ $r->{links} || {} } ), @{ $r->{global}{dns} || [] } );
    }
    return @ns;
}

# Name -> Adresse: /etc/hosts, dann die Nameserver der Reihe nach (dns_servers:
# { <adresse>: { <name>: <ip> } }; ein Server, der fehlt, antwortet nicht).
sub _resolve {
    my ( $dev, $name ) = @_;
    for my $l ( split /\n/, _file_text( $dev, '/etc/hosts' ) // '' ) {
        $l =~ s/#.*//;
        my ( $ip, @n ) = split ' ', $l;
        return ( $ip, 'hosts' ) if defined $ip && grep { $_ eq $name } @n;
    }
    my $rc = _file_text( $dev, '/etc/resolv.conf' ) // '';
    my @search = map { split ' ' } $rc =~ /^\s*(?:search|domain)\s+(.+)$/mg;
    for my $ns ( _nameservers($dev) ) {
        my $zone = ( $dev->{dns_servers} || {} )->{$ns} or next;
        for my $q ( $name, ( $name =~ /\./ ? () : map {"$name.$_"} @search ) ) {
            return ( $zone->{$q}, $ns ) if defined $zone->{$q};
        }
        return ( undef, $ns );    # Server antwortet: NXDOMAIN
    }
    return ();
}

sub _resolvectl {
    my ( $dev, $av ) = @_;
    my $r = $dev->{resolved} or return ( 'Failed to get global data: Unit dbus-org.freedesktop.resolve1.service not found.', 0 );
    my @a = @$av;
    my $verb = shift(@a) // 'status';
    if ( $verb eq 'status' || $verb eq 'dns' && !@a || $verb eq 'domain' && !@a ) {
        my @l;
        if ( $verb eq 'status' && !@a ) {
            push @l, 'Global', '       Protocols: +LLMNR +mDNS -DNSOverTLS DNSSEC=no/unsupported', 'resolv.conf mode: stub';
            push @l, 'Current DNS Server: ' . $r->{global}{dns}[0] if @{ $r->{global}{dns} || [] };
            push @l, '       DNS Servers: ' . join( ' ', @{ $r->{global}{dns} || [] } ) if @{ $r->{global}{dns} || [] };
        }
        my $i = 1;
        for my $n ( sort keys %{ $r->{links} || {} } ) {
            $i++;
            next if @a && $a[0] ne $n;
            my $k = $r->{links}{$n};
            if ( $verb eq 'dns' ) { push @l, "Link $i ($n): " . join( ' ', @{ $k->{dns} || [] } ); next }
            if ( $verb eq 'domain' ) { push @l, "Link $i ($n): " . join( ' ', @{ $k->{domains} || [] } ); next }
            push @l, '', "Link $i ($n)", '    Current Scopes: DNS', '         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS';
            push @l, 'Current DNS Server: ' . $k->{dns}[0] if @{ $k->{dns} || [] };
            push @l, '       DNS Servers: ' . join( ' ', @{ $k->{dns} || [] } ) if @{ $k->{dns} || [] };
            push @l, '        DNS Domain: ' . join( ' ', @{ $k->{domains} || [] } ) if @{ $k->{domains} || [] };
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $verb eq 'dns' || $verb eq 'domain' ) {
        my $if = shift @a;
        my $k = ( $r->{links} || {} )->{$if} or return ( "Failed to resolve interface \"$if\": No such device", 0 );
        $k->{ $verb eq 'dns' ? 'dns' : 'domains' } = [@a];
        return ( '', 1 );
    }
    if ( $verb eq 'query' ) {
        my @l;
        for my $n (@a) {
            my ( $ip, $src ) = _resolve( $dev, $n );
            return ( "$n: resolve call failed: " . ( defined $src ? "'$n' not found" : 'All attempts to contact name servers or networks failed' ), 0 )
                unless defined $ip;
            push @l, "$n: $ip", '', '-- Information acquired via protocol DNS in 1.2ms.';
        }
        return ( join( "\n", @l ), 1 );
    }
    return ( '', 1 ) if $verb eq 'flush-caches' || $verb eq 'reset-statistics';
    if ( $verb eq 'revert' ) {
        my $k = ( $r->{links} || {} )->{ $a[0] // '' } or return ( 'Failed to resolve interface', 0 );
        delete @{$k}{qw( dns domains )};
        return ( '', 1 );
    }
    return ( "Unknown command verb '$verb'.", 0 );
}

sub _ln {
    my ( $dev, $av ) = @_;
    my @a = grep { !/\A-/ } @$av;
    my $sym = grep {/s/} grep {/\A-/} @$av;
    return ( "ln: missing file operand", 0 ) unless @a == 2;
    return ( "ln: failed to create hard link: Operation not permitted", 0 ) unless $sym;
    my ( $target, $link ) = @a;
    my $flags = join '', map { /\A-(\w+)\z/ ? $1 : /\A--no-(?:target-directory|dereference)\z/ ? 'n' : /\A--force\z/ ? 'f' : '' } @$av;
    $link =~ s{(?<=.)/+\z}{};
    $link = _absp($link);    # der Name gilt im aktuellen Verzeichnis, das Ziel bleibt Text (relativ zum Link)
    # Ein Verzeichnis (auch ein Symlink darauf, ohne -n/-T) als Ziel: der Link entsteht darin
    if ( _is_dir( $dev, $link ) && $flags !~ /[nT]/ ) {
        my $e = ref $dev->{files} eq 'HASH' ? $dev->{files}{$link} : undef;
        my $d = ref $e eq 'HASH' && defined $e->{link} ? _link_target( $link, $e->{link} ) : $link;
        ( my $base = $target ) =~ s{/+\z}{};
        $base =~ s{.*/}{};
        $link = "$d/$base";
    }
    return ( "ln: failed to create symbolic link '$link': File exists", 0 )
        if ( ( ref $dev->{files} eq 'HASH' && exists $dev->{files}{$link} ) || _is_dir( $dev, $link ) ) && $flags !~ /f/;
    return ( "ln: cannot overwrite directory '$link'", 0 ) if _is_dir( $dev, $link ) && !( ref $dev->{files}{$link} eq 'HASH' && defined $dev->{files}{$link}{link} );
    $dev->{files}{$link} = { link => $target };
    return ( '', 1 );
}

# ssh [-o …] [user@]ziel befehl: der Befehl laeuft auf dem Geraet mit diesem Namen oder
# dieser Adresse (als root, Schluessel hinterlegt); ohne Befehl keine Sitzung; andere Ziele
# sind eine Luecke
sub _ssh {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my $host;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-[oipFlJ]\z/ ) { shift @a }
        elsif ( $x =~ /\A-/ )           { }
        else                            { $host = $x; last }
    }
    return ( 'usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] destination [command [argument ...]]', 0 ) unless defined $host;
    my ($login) = $host =~ /\A([^@]+)@/;
    $host =~ s/\A[^@]*@//;
    if ( ( $login // '' ) eq 'git' && ( my $git = ( $dev->{git} || {} )->{hosts} ) ) {
        _part('Git');
        my $srv = ( ( $ctx || {} )->{state} || {} )->{ $git->{$host} // '' } // Langertha::Holmgang::Sim::Linux::Git::_by_hosts_file( $ctx, $host );
        if ( $srv && $srv->{forgejo} ) {
            return ( "Hi there, dev! You've successfully authenticated with the key named dev\@dev1, but Forgejo does not provide shell access.\nIf this is unexpected, please log in with password and setup Forgejo under another user.", 1 ) unless @a;
            push @GAPS, join( ' ', 'ssh', @$av );
            return ( '', 0 );
        }
    }
    # auf sich selbst (localhost, eigene Adresse, eigener Name): Anmeldung gegen die geladene
    # sshd-Konfiguration, wie sshd selbst sie prueft
    my %own = map { $_ => 1 } _own_addrs($dev), 'localhost', ( $ctx || {} )->{host} // ();
    return _ssh_client( $dev, $av, $ctx ) if $own{$host} && ref $dev->{files} eq 'HASH' && exists $dev->{files}{'/etc/ssh/sshd_config'};
    my $state = $CTX ? $CTX->{state} : {};
    my $other = ref $state->{$host} eq 'HASH' ? $state->{$host}
        : ( grep { ref $_ eq 'HASH' && ( ( $_->{hostname} // '' ) eq $host || grep { $_ eq $host } _own_addrs($_) ) } values %$state )[0];
    # ein Geraet, das der Fall nicht nachbildet: Luecke (es kann es geben)
    if ( !$other ) { push @GAPS, join( ' ', 'ssh', @$av ); return ( '', 0 ) }
    return ( 'Pseudo-terminal will not be allocated because stdin is not a terminal.', 0 ) unless @a;
    return ( "ssh: connect to host $host port 22: Connection refused", 0 ) if ( $other->{type} // '' ) ne 'linux';
    # wie echtes ssh: die Woerter mit Leerzeichen verbunden, drueben neu gelesen (im Heimatverzeichnis)
    local $CWD_DIR;
    my ( $o, $k ) = __PACKAGE__->_run_inner( $other, join( ' ', @a ), $ctx );
    return ( $o, $k );
}

# nginx als Webserver fuer statische Dateien: ( text, status, typ ) fuer GET auf PORT/PFAD
# mit Host-Kopf, oder () wenn nicht nachgebildet (proxy_pass, kein passender server-Block).
# Der server-Block nach Port und server_name (sonst der erste mit dem Port), root + Pfad,
# index.html fuer ein Verzeichnis; 403, wenn der Arbeiter (user, Vorgabe www-data) ein
# Verzeichnis auf dem Weg nicht betreten oder die Datei nicht lesen darf, 404, wenn es sie
# nicht gibt. Status 0: nginx laeuft nicht oder lauscht nicht auf dem Port.
sub _nginx_http {
    my ( $dev, $port, $vhost, $path ) = @_;
    my ( $name, $svc ) = map { ( $_, $dev->{services}{$_} ) } grep { ( $dev->{services}{$_}{exec} // $_ ) eq 'nginx' } sort keys %{ $dev->{services} || {} };
    return ( '', 0 ) unless $svc && $svc->{active} && grep { /:\Q$port\E\z/ } _svc_listen( $dev, $name, $svc );
    my $run = ref $svc->{running} eq 'HASH' ? $svc->{running} : {};
    my $text = sub { $run->{ $_[0] } // _file_text( $dev, $_[0] ) // '' };
    my ($user) = $text->('/etc/nginx/nginx.conf') =~ /^\s*user\s+([^\s;]+)/m;
    $user //= 'www-data';
    my @blocks;
    for my $p ( sort grep { m{\A/etc/nginx/(?:nginx\.conf|conf\.d/[^/]+\.conf|sites-enabled/[^/]+)\z} } keys %{ $dev->{files} || {} } ) {
        ( my $t = $text->($p) ) =~ s/#[^\n]*//g;
        while ( $t =~ /\bserver\s*\{/g ) {    # Block mit ausgeglichenen Klammern
            my ( $start, $depth, $i ) = ( pos($t), 1, pos($t) );
            while ( $depth && $i < length $t ) { my $c = substr( $t, $i++, 1 ); $depth++ if $c eq '{'; $depth-- if $c eq '}' }
            my $body = substr( $t, $start, $i - $start - 1 );
            pos($t) = $i;
            ( my $top = $body ) =~ s/\blocation\b[^{]*\{(?:[^{}]|\{[^{}]*\})*\}//g;
            push @blocks, { body => $body, top => $top, ports => [ map { /(\d+)\z/ ? $1 : () } $top =~ /^\s*listen\s+([^;\s]+)/mg ],
                names => [ map { split ' ' } $top =~ /^\s*server_name\s+([^;]+);/mg ] };
        }
    }
    ( $vhost //= '' ) =~ s/:\d+\z//;
    my @on = grep { grep { $_ == $port } @{ $_->{ports} } } @blocks;
    my ($blk) = ( ( grep { my $x = $_; grep { $_ eq $vhost } @{ $x->{names} } } @on ), @on );
    return () unless $blk;
    $path =~ s/[?#].*//s;
    # eine location mit proxy_pass, die den Pfad betrifft: nicht nachgebildet
    for my $loc ( $blk->{body} =~ /\blocation\s+([^\s{]+)\s*\{[^{}]*\bproxy_pass\b/g ) { return () if index( $path, $loc ) == 0 }
    my ($root) = $blk->{top} =~ /^\s*root\s+([^;\s]+)\s*;/m;
    return () unless defined $root;
    my $f = $root =~ s{/+\z}{}r . $path;
    $f .= 'index.html' if $f =~ m{/\z};
    my @parts = split m{/}, $f;
    for my $i ( 1 .. $#parts - 1 ) {
        my $d = join '/', @parts[ 0 .. $i ];
        next unless length $d;
        return ( "<html>\n<head><title>404 Not Found</title></head>\n<body>\n<center><h1>404 Not Found</h1></center>\n<hr><center>nginx/1.22.1</center>\n</body>\n</html>", 404, 'text/html' )
            unless _is_dir( $dev, $d );
        next unless ( $dev->{dirs} || {} )->{$d};    # ohne Eintrag: root, 0755
        return ( "<html>\n<head><title>403 Forbidden</title></head>\n<body>\n<center><h1>403 Forbidden</h1></center>\n<hr><center>nginx/1.22.1</center>\n</body>\n</html>", 403, 'text/html' )
            unless _can( $dev, $user, $d, 'x' );
    }
    my $body = _file_text( $dev, $f );
    return ( "<html>\n<head><title>404 Not Found</title></head>\n<body>\n<center><h1>404 Not Found</h1></center>\n<hr><center>nginx/1.22.1</center>\n</body>\n</html>", 404, 'text/html' )
        unless defined $body;
    return ( "<html>\n<head><title>403 Forbidden</title></head>\n<body>\n<center><h1>403 Forbidden</h1></center>\n<hr><center>nginx/1.22.1</center>\n</body>\n</html>", 403, 'text/html' )
        unless _can( $dev, $user, $f, 'r' );
    my %type = ( css => 'text/css', js => 'application/javascript', html => 'text/html', svg => 'image/svg+xml', json => 'application/json', txt => 'text/plain' );
    my ($ext) = $f =~ /\.(\w+)\z/;
    return ( $body, 200, $type{ lc( $ext // '' ) } // 'application/octet-stream' );
}

# /dev/tcp/HOST/PORT der bash: Verbindung wie _tcp_probe; UDP und Unbekanntes sind eine Luecke
sub _dev_tcp {
    my ( $dev, $path, $dir ) = @_;
    my ( $proto, $h, $p ) = $path =~ m{\A/dev/(tcp|udp)/([^/]+)/(\d+)\z};
    my $st = defined $p && $proto eq 'tcp' ? _tcp_probe( $dev, $h, $p ) : undef;
    if ( !defined $st ) { push @GAPS, "$dir $path"; return ( '', 0 ) }
    return ( '', 1 ) if $st eq 'open';
    return ( "bash: $h: Name or service not known\nbash: $path: Invalid argument", 0 ) if $st eq 'noname';
    if ( $st eq 'timeout' && $IN_TIMEOUT ) { $SH->{code} = 124 if $SH; return ( '', 0 ) }
    my $m = { refused => 'Connection refused', timeout => 'Connection timed out', unreach => 'Network is unreachable' }->{$st};
    return ( "bash: connect: $m\nbash: $path: $m", 0 );
}

# --- Anmeldungen (wtmp) ------------------------------------------------------------------
# Laufender Start des Geraets (Epoche): der frueheste since eines Dienstes, sonst die Vorgabe
sub _boot_epoch {
    my ($dev) = @_;
    my ($t) = sort { $a <=> $b } grep {defined} map { _parse_stamp( $_->{since} // $BOOT_STAMP ) }
        grep { ref eq 'HASH' && ( $_->{active} || defined $_->{since} ) } values %{ $dev->{services} || {} };
    return $t // _parse_stamp($BOOT_STAMP);
}

# Anmeldungen aus dem Zustand (logins: [ { user, tty, from, start: "Mon Oct 19 16:02",
# end: "16:40"|"still logged in", duration } ]) und der laufende Start: [ epoche, zeile, -a-zeile, user, tty ]
sub _wtmp {
    my ($dev) = @_;
    require POSIX;
    require Time::Local;
    my @r;
    my $boot = _boot_epoch($dev);
    my $bs = POSIX::strftime( '%a %b %e %H:%M', _local_tm($boot) );
    my $kern = '6.1.0-26-amd64';
    push @r, [ $boot, sprintf( '%-8s %-12s %-16s %-16s   still running', 'reboot', 'system boot', $kern, $bs ),
        sprintf( '%-8s %-12s %-37s %s', 'reboot', 'system boot', "$bs   still running", $kern ), 'reboot', 'system boot' ];
    for my $l ( grep { ref eq 'HASH' } @{ $dev->{logins} || [] } ) {
        my ( $mon, $d, $h, $mi ) = ( $l->{start} // '' ) =~ /\A\w{3}\s+(\w{3})\s+(\d+)\s+(\d\d):(\d\d)\z/ or next;
        my $t = Time::Local::timegm( 0, $mi, $h, $d, $MON{$mon} // 9, 2026 );
        $t -= Langertha::Holmgang::Sim::Linux::Calendar::offset( $t - 3600 );
        my $end = $l->{end} // 'still logged in';
        my $dur = $l->{duration};
        if ( !defined $dur && $end =~ /\A(\d\d):(\d\d)\z/ ) { my $m = ( $1 * 60 + $2 ) - ( $h * 60 + $mi ); $m += 1440 if $m < 0; $dur = sprintf '(%02d:%02d)', int( $m / 60 ), $m % 60 }
        my $rest = $end =~ /\A\d\d:\d\d\z/ ? "- $end  " . ( $dur // '' ) : "  $end";
        my $start = sprintf '%-16s', $l->{start};
        push @r, [ $t, sprintf( '%-8s %-12s %-16s %s %s', $l->{user}, $l->{tty} // 'pts/0', $l->{from} // '', $start, $rest ),
            sprintf( '%-8s %-12s %-37s %s', $l->{user}, $l->{tty} // 'pts/0', "$start $rest", $l->{from} // '' ), $l->{user}, $l->{tty} // 'pts/0' ];
    }
    return sort { $b->[0] <=> $a->[0] } @r;
}

# uptime [-p|-s]: seit dem laufenden Start (_boot_epoch) an der Uhr des Geraets; ein
# Benutzer (die Sitzung des Modells), ruhige Last
sub _uptime {
    my ( $dev, $av ) = @_;
    require POSIX;
    my ( $boot, $now ) = ( _boot_epoch($dev), _dev_now($dev) );
    my $up = $now - $boot;
    $up = 60 if $up < 60;
    my ( $d, $h, $m ) = ( int( $up / 86400 ), int( $up % 86400 / 3600 ), int( $up % 3600 / 60 ) );
    my $opt = $av->[0] // '';
    return ( POSIX::strftime( '%Y-%m-%d %H:%M:%S', _local_tm($boot) ), 1 ) if $opt eq '-s' || $opt eq '--since';
    if ( $opt eq '-p' || $opt eq '--pretty' ) {
        my @p;
        push @p, $d == 1 ? '1 day' : "$d days" if $d;
        push @p, $h == 1 ? '1 hour' : "$h hours" if $h;
        push @p, $m == 1 ? '1 minute' : "$m minutes" if $m;
        return ( 'up ' . join( ', ', @p ), 1 );
    }
    if ( length $opt ) { push @GAPS, join( ' ', 'uptime', @$av ); return ( '', 0 ) }
    my $t = ( $d ? ( $d == 1 ? '1 day, ' : "$d days, " ) : '' ) . sprintf( '%2d:%02d', $h, $m );
    return ( POSIX::strftime( ' %H:%M:%S', _local_tm($now) ) . " up $t,  1 user,  load average: 0.08, 0.03, 0.01", 1 );
}

# last [-a] [-n N] [-F] [-x] [BENUTZER|reboot|TTY …]
sub _last {
    my ( $dev, $av ) = @_;
    my ( $a, $n, @who );
    my @x = @$av;
    while (@x) {
        my $o = shift @x;
        if    ( $o eq '-n' || $o eq '--limit' ) { $n = shift @x }
        elsif ( $o =~ /\A-(\d+)\z/ || $o =~ /\A-n(\d+)\z/ ) { $n = $1 }
        elsif ( $o =~ /\A-([aFxwiR]+)\z/ ) { $a = 1 if $1 =~ /a/ }
        elsif ( $o =~ /\A-/ ) { push @GAPS, join( ' ', 'last', @$av ); return ( '', 0 ) }
        else { push @who, $o }
    }
    my @r = _wtmp($dev);
    my $first = $r[-1][0];
    @r = grep { my $r = $_; grep { $r->[3] eq $_ || $r->[4] eq $_ } @who } @r if @who;
    @r = @r[ 0 .. $n - 1 ] if defined $n && $n =~ /\A\d+\z/ && @r > $n;
    require POSIX;
    my @l = map { ( $a ? $_->[2] : $_->[1] ) =~ s/\s+\z//r } @r;
    return ( join( "\n", @l, '', 'wtmp begins ' . POSIX::strftime( '%a %b %e %H:%M:%S %Y', _local_tm($first) ) ), 1 );
}

# lastlog [-u BENUTZER]: letzte Anmeldung je Konto (root und die Konten im Zustand)
sub _lastlog {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $only;
    while (@a) { my $o = shift @a; if ( $o eq '-u' ) { $only = shift @a } elsif ( $o =~ /\A-/ ) { push @GAPS, join( ' ', 'lastlog', @$av ); return ( '', 0 ) } }
    my %last;
    for my $r ( reverse _wtmp($dev) ) { $last{ $r->[3] } = $r if $r->[3] ne 'reboot' }
    my %login = map { $_->{user} => $_ } grep { ref eq 'HASH' } @{ $dev->{logins} || [] };
    require POSIX;
    my @l = ( sprintf '%-16s %-8s %-16s %s', 'Username', 'Port', 'From', 'Latest' );
    for my $u ( 'root', sort { ( $dev->{users}{$a}{uid} // 0 ) <=> ( $dev->{users}{$b}{uid} // 0 ) } keys %{ $dev->{users} || {} } ) {
        next if defined $only && $u ne $only;
        my $r = $last{$u};
        if ( !$r ) { push @l, sprintf '%-43s%s', $u, '**Never logged in**'; next }
        my $lg = $login{$u};
        my $t = $r->[0];
        my $off = Langertha::Holmgang::Sim::Linux::Calendar::offset($t);
        push @l, sprintf '%-16s %-8s %-16s %s', $u, $lg->{tty} // 'pts/0', $lg->{from} // '',
            POSIX::strftime( '%a %b %e %H:%M:%S', gmtime( $t + $off ) ) . sprintf( ' %+03d%02d %d', $off / 3600, 0, ( gmtime( $t + $off ) )[5] + 1900 );
    }
    return ( join( "\n", @l ), 1 );
}

# --- TCP zwischen Geraeten -------------------------------------------------------------
# Wo laufende Dienste ohne listen im Zustand lauschen (Debian-Vorgaben nach exec bzw. Name);
# Dienste, die nie lauschen. Ein anderer laufender Dienst macht die Ports des Geraets
# unbekannt (dann ist eine geschlossene Antwort nicht sicher: Luecke).
our %SVC_PORT = ( sshd => [22], postgres => [5432], 'redis-server' => [6379], mariadbd => [3306], mysqld => [3306],
    prometheus => [9090], alertmanager => [9093], 'prometheus-node-exporter' => [9100], node_exporter => [9100],
    named => [53], dnsmasq => [53], 'systemd-resolved' => [], unbound => [53], postfix => [25], master => [25],
    dovecot => [ 143, 993 ], 'grafana-server' => [3000], apache2 => [80], gunicorn => [8000] );
our %NO_LISTEN = map { $_ => 1 } qw( cron rsyslogd rsyslog systemd-journald nftables chronyd chrony unattended-upgrades
    systemd-timesyncd systemd-networkd networking auditd logrotate e2scrub_all fstrim apt-daily wg-quick smartd mdmonitor );

# Lauscher eines Geraets auf PORT: ( [ adresse, … ], vollstaendig? )
sub _listeners {
    my ( $dev, $port ) = @_;
    my @addr;
    for my $line ( split /\n/, ( _ss( $dev, [] ) )[0] ) {
        my ($a) = $line =~ /\A\S+\s+LISTEN\s+\S+\s+\S+\s+(\S+):\Q$port\E\s/ or next;
        push @addr, $a;
    }
    my $complete = 1;
    my $s = $dev->{services} || {};
    for my $n ( sort keys %$s ) {
        my $v = $s->{$n};
        next unless ref $v eq 'HASH' && $v->{active} && $n !~ /\.(?:timer|socket|target|mount|path)\z/;
        next if $v->{listen} || ( $v->{exec} // $n ) eq 'nginx' || $n eq 'ssh';
        next if defined $v->{run} || $NO_LISTEN{ $v->{exec} // $n } || $NO_LISTEN{$n};
        next if $n eq ( ( $dev->{redis} || {} )->{service} // 'redis-server' ) && $dev->{redis};
        next if $n eq ( ( $dev->{mariadb} || {} )->{service} // 'mariadb' ) && $dev->{mariadb};
        my $ports = $SVC_PORT{ ( split ' ', $v->{exec} // '' )[0] // '' } // $SVC_PORT{$n};
        if ( !$ports ) { $complete = 0; next }
        push @addr, '0.0.0.0' if grep { $_ == $port } @$ports;
    }
    return ( \@addr, $complete );
}

# Urteil der Firewall (nft, Ketten mit hook input) fuer ein neues TCP-Paket von $src an
# $dst:$port ueber $iif: 'accept', 'drop', 'reject' oder undef (Regel nicht nachgebildet)
sub _nft_verdict {
    my ( $dev, $src, $dst, $port, $iif ) = @_;
    my $T = ref $dev->{nft} eq 'HASH' ? $dev->{nft} : {};
    my @chains;
    for my $tn ( sort keys %$T ) {
        next unless $tn =~ /\A(?:inet|ip) /;
        for my $cn ( sort keys %{ $T->{$tn}{chains} || {} } ) {
            my $c = $T->{$tn}{chains}{$cn};
            push @chains, [ $tn, $c ] if ( $c->{hook} // '' ) eq 'input';
        }
    }
    my $inset = sub {    # Wert gegen "X", "{ a, b }", "a-b", "!= X"
        my ( $spec, $v, $kind ) = @_;
        my @alt = $spec =~ /\A\{\s*(.*?)\s*\}\z/ ? split( /\s*,\s*/, $1 ) : ($spec);
        for my $a (@alt) {
            $a =~ s/\A"|"\z//g;
            if ( $kind eq 'ip' ) { return 1 if $a =~ m{/} ? _in( $v, $a ) : $a eq $v }
            elsif ( $kind eq 'port' ) { return 1 if $a =~ /\A(\d+)-(\d+)\z/ ? $v >= $1 && $v <= $2 : $a =~ /\A\d+\z/ ? $a == $v : ( { ssh => 22, http => 80, https => 443 }->{$a} // -1 ) == $v }
            else { return 1 if $a eq $v }
        }
        return 0;
    };
    my $rule;
    $rule = sub {
        my ( $tn, $c, $depth ) = @_;
        return undef if $depth > 5;
        RULE: for my $r ( @{ $c->{rules} || [] } ) {
            my $t = ref $r eq 'HASH' ? $r->{rule} // '' : $r;
            $t =~ s/\s+comment\s+"[^"]*"//g;
            $t =~ s/\blog(?:\s+(?:prefix\s+"[^"]*"|level\s+\S+|flags\s+\S+))*//g;
            $t =~ s/\bcounter(?:\s+packets\s+\d+\s+bytes\s+\d+)?//g;
            $t =~ s/\blimit rate\s+\S+(?:\s+burst\s+\d+\s+packets)?//g;    # Grenze: ein einzelnes Paket liegt darunter
            my @w = $t =~ /(\{[^}]*\}|"[^"]*"|\S+)/g;
            my $verdict;
            while (@w) {
                my $x = shift @w;
                if ( $x eq 'ct' && ( $w[0] // '' ) eq 'state' ) { shift @w; my $neg = ( $w[0] // '' ) eq '!=' ? shift @w : 0; my $s = shift(@w) // '';
                    my $m = grep { $_ eq 'new' } map { s/[{}\s]//gr } split /,/, $s =~ s/\A\{|\}\z//gr; next RULE if $neg ? $m : !$m; next }
                if ( $x eq 'iif' || $x eq 'iifname' ) { my $neg = ( $w[0] // '' ) eq '!=' ? shift @w : 0; my $m = $inset->( shift(@w) // '', $iif, 's' ); next RULE if $neg ? $m : !$m; next }
                if ( $x eq 'ip' && ( $w[0] // '' ) =~ /\A[sd]addr\z/ ) {
                    my $which = shift @w;
                    my $neg = ( $w[0] // '' ) eq '!=' ? shift @w : 0;
                    my $m = $inset->( shift(@w) // '', $which eq 'saddr' ? $src : $dst, 'ip' );
                    next RULE if $neg ? $m : !$m;
                    next;
                }
                if ( ( $x eq 'tcp' || $x eq 'th' ) && ( $w[0] // '' ) =~ /\A[sd]port\z/ ) {
                    my $which = shift @w;
                    my $neg = ( $w[0] // '' ) eq '!=' ? shift @w : 0;
                    my $spec = shift(@w) // '';
                    my $m = $which eq 'dport' ? $inset->( $spec, $port, 'port' ) : 1;    # sport: ein beliebiger hoher Port
                    next RULE if $neg ? $m : !$m;
                    next;
                }
                if ( $x eq 'udp' || $x eq 'icmp' || $x eq 'icmpv6' || $x eq 'ip6' ) { next RULE }    # passt nie auf TCP/IPv4
                if ( $x eq 'meta' && ( $w[0] // '' ) eq 'l4proto' ) { shift @w; my $m = $inset->( shift(@w) // '', 'tcp', 's' ); next RULE unless $m; next }
                if ( $x eq 'ip' && ( $w[0] // '' ) eq 'protocol' ) { shift @w; my $m = $inset->( shift(@w) // '', 'tcp', 's' ); next RULE unless $m; next }
                if ( $x eq 'accept' || $x eq 'drop' ) { $verdict = $x; last }
                if ( $x eq 'reject' ) { $verdict = 'reject'; last }
                if ( $x eq 'return' ) { return 'return' }
                if ( ( $x eq 'jump' || $x eq 'goto' ) && @w ) {
                    my $sub = $T->{$tn}{chains}{ shift @w } or return undef;
                    my $v = $rule->( $tn, $sub, $depth + 1 );
                    return undef unless defined $v;
                    next RULE if $v eq 'return' || $v eq 'none';
                    return $v;
                }
                return undef;    # anderes: nicht nachgebildet
            }
            return $verdict if $verdict;
        }
        return 'none';
    };
    for my $ch ( sort { ( $a->[1]{priority} // 0 ) <=> ( $b->[1]{priority} // 0 ) } @chains ) {
        my $v = $rule->( $ch->[0], $ch->[1], 0 );
        return undef unless defined $v;
        $v = $ch->[1]{policy} // 'accept' if $v eq 'none' || $v eq 'return';
        return $v unless $v eq 'accept';
    }
    return 'accept';
}

# Neue TCP-Verbindung von diesem Geraet zu HOST:PORT (beide im Zustand): 'open', 'refused',
# 'timeout', 'unreach' oder undef (Ziel oder Regel nicht nachgebildet)
sub _tcp_probe {
    my ( $dev, $host, $port ) = @_;
    my $state = $CTX ? $CTX->{state} || {} : {};
    my @own = _own_addrs($dev);
    if ( $host =~ /\A(?:localhost|127\.\d+\.\d+\.\d+)\z/ || grep { $_ eq $host } @own, $dev->{hostname} // (), ( $CTX || {} )->{host} // () ) {
        my ( $addr, $complete ) = _listeners( $dev, $port );
        my $ip = _ip2n($host) ? $host : '127.0.0.1';
        return 'open' if grep { $_ =~ /\A(?:0\.0\.0\.0|\*|\[::\])\z/ || $_ eq $ip || ( $ip =~ /\A127\./ && $_ =~ /\A127\./ ) } @$addr;
        return $complete ? 'refused' : undef;
    }
    my $find = sub {
        my ($h) = @_;
        my ($t) = grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'linux' && $_ != $dev }
            ( ref $state->{$h} eq 'HASH' ? $state->{$h} : () ),
            map { $state->{$_} } grep { ref $state->{$_} eq 'HASH' && ( ( $state->{$_}{hostname} // '' ) eq $h || grep { $_ eq $h } _own_addrs( $state->{$_} ) ) } sort keys %$state;
        return $t;
    };
    my $tgt = $find->($host);
    my $ip;
    if ( !$tgt && !_ip2n($host) ) {    # Name: wie getent hosts (/etc/hosts, Nameserver); unbekannt: nicht aufloesbar
        my ($r) = _resolve( $dev, $host );
        return 'noname' unless defined $r;
        $tgt = $find->($r) or return undef;
        $ip = $r;
    }
    return undef unless $tgt;
    $ip //= _ip2n($host) ? $host : ( _own_addrs($tgt) )[0] // return undef;
    return 'unreach' unless _lookup( $dev, $ip );
    my ($src) = grep { my $s = $_; grep { _in( $s, $_ ) } map { @{ $_->{addr} || [] } } values %{ $tgt->{interfaces} || {} } } @own;
    $src //= $own[0] // return undef;
    my ($iif) = grep { grep { m{/} && _in( $src, $_ ) } @{ $tgt->{interfaces}{$_}{addr} || [] } } sort keys %{ $tgt->{interfaces} || {} };
    my $v = _nft_verdict( $tgt, $src, $ip, $port, $iif // 'eth0' ) // return undef;
    return 'timeout' if $v eq 'drop';
    return 'refused' if $v eq 'reject';
    my ( $addr, $complete ) = _listeners( $tgt, $port );
    return 'open' if grep { $_ =~ /\A(?:0\.0\.0\.0|\*|\[::\])\z/ || $_ eq $ip } @$addr;
    return $complete ? 'refused' : undef;
}

# nc [-z] [-v] [-w N] [-n] HOST PORT[-PORT]…: Verbindungsprobe (netcat-openbsd), nur wenn
# installiert (Programmdatei im Zustand); Daten senden (ohne -z) und UDP sind eine Luecke
sub _nc {
    my ( $dev, $av, $ctx ) = @_;
    my ($me) = grep { _prog_file( $dev, $_ ) } qw( nc netcat ncat );
    return ( 'bash: nc: command not found', 0 ) unless $me;
    my ( $z, $v, @pos );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-[wWiqpsTX]\z/ ) { shift @a }
        elsif ( $x =~ /\A-([zvnNw0-9]+)\z/ ) { my $f = $1; $z = 1 if $f =~ /z/; $v = 1 if $f =~ /v/; shift @a if $f =~ /w\z/ }
        elsif ( $x =~ /\A-/ ) { push @GAPS, join( ' ', 'nc', @$av ); return ( '', 0 ) }    # -u, -l, …
        else { push @pos, $x }
    }
    my ( $host, @ports ) = @pos;
    if ( !$z || !defined $host || !@ports ) { push @GAPS, join( ' ', 'nc', @$av ); return ( '', 0 ) }
    my %svc = ( 22 => 'ssh', 25 => 'smtp', 53 => 'domain', 80 => 'http', 443 => 'https', 3306 => 'mysql', 5432 => 'postgresql', 6379 => '*' );
    my ( @out, $any );
    for my $p ( map { /\A(\d+)-(\d+)\z/ ? ( $1 .. $2 ) : $_ } @ports ) {
        my $st = _tcp_probe( $dev, $host, $p );
        if ( !defined $st ) { push @GAPS, join( ' ', 'nc', @$av ); return ( join( "\n", @out ), 0 ) }
        if ( $st eq 'open' ) { $any = 1; push @out, "Connection to $host $p port [tcp/" . ( $svc{$p} // '*' ) . '] succeeded!' if $v; next }
        if ( $st eq 'noname' ) { push @out, qq{nc: getaddrinfo for host "$host" port $p: Name or service not known}; last }
        push @out, "nc: connect to $host port $p (tcp) "
            . { refused => 'failed: Connection refused', timeout => 'timed out: Operation now in progress', unreach => 'failed: Network is unreachable' }->{$st};
    }
    return ( join( "\n", @out ), $any ? 1 : 0 );
}

# curl (nur wenn installiert): eigene Maschine mit nginx wie wget; andere Geraete: nur das
# Scheitern der Verbindung (7 refused, 28 timeout); eine gelungene Verbindung zu einem
# anderen Geraet ist eine Luecke (dort antwortet kein nachgebildeter Dienst)
sub _curl {
    my ( $dev, $av, $ctx ) = @_;
    return ( 'bash: curl: command not found', 0 ) unless _prog_file( $dev, 'curl' );
    my ( $url, $silent, $show, $head, $out, $wfmt, $vhost );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-([sSIfLkv]+)\z/ ) { my $f = $1; $silent = 1 if $f =~ /s/; $show = 1 if $f =~ /S/; $head = 1 if $f =~ /I/ }
        elsif ( $x eq '-o' || $x eq '--output' ) { $out = shift @a }
        elsif ( $x eq '-w' || $x eq '--write-out' ) { $wfmt = shift @a }
        elsif ( $x eq '-H' || $x eq '--header' ) { my $h = shift(@a) // ''; $vhost = $1 if $h =~ /\AHost:\s*(\S+)/i }
        elsif ( $x =~ /\A(?:-m|--max-time|--connect-timeout)\z/ ) { shift @a }
        elsif ( $x =~ /\A--(?:silent|show-error|head|fail|location|insecure)\z/ ) { $silent = 1 if $x eq '--silent'; $show = 1 if $x eq '--show-error'; $head = 1 if $x eq '--head' }
        elsif ( $x =~ /\A-/ ) { push @GAPS, join( ' ', 'curl', @$av ); return ( '', 0 ) }
        else { $url = $x }
    }
    my ( $scheme, $h, $port, $path ) = ( $url // '' ) =~ m{\A(?:(https?)://)?([^/:]+)(?::(\d+))?(/.*)?\z} or do { push @GAPS, join( ' ', 'curl', @$av ); return ( '', 0 ) };
    $port //= ( $scheme // 'http' ) eq 'https' ? 443 : 80;
    my $st = _tcp_probe( $dev, $h, $port );
    if ( !defined $st ) { push @GAPS, join( ' ', 'curl', @$av ); return ( '', 0 ) }
    if ( $st ne 'open' ) {
        my ( $code, $msg ) = $st eq 'noname' ? ( 6, "Could not resolve host: $h" ) : $st eq 'timeout' ? ( 28, "Failed to connect to $h port $port after 130000 ms: Couldn't connect to server" )
            : $st eq 'unreach' ? ( 7, "Failed to connect to $h port $port after 0 ms: Couldn't connect to server" )
            : ( 7, "Failed to connect to $h port $port after 0 ms: Couldn't connect to server" );
        $SH->{code} = $code if $SH;
        my @o;
        push @o, $wfmt =~ s/%\{http_code\}/000/gr =~ s/\\n/\n/gr if defined $wfmt;
        push @o, "curl: ($code) $msg" if !$silent || $show;
        return ( join( "\n", @o ), 0 );
    }
    my $self = $h =~ /\A(?:localhost|127\.)/ || grep { $_ eq $h } _own_addrs($dev), $dev->{hostname} // (), ( $ctx || {} )->{host} // ();
    my ( $body, $code, $type ) = $self && ( $scheme // 'http' ) eq 'http' ? _nginx_http( $dev, $port, $vhost // $h, $path // '/' ) : ();
    if ( !defined $code || !$code ) { push @GAPS, join( ' ', 'curl', @$av ); return ( '', 0 ) }
    my %reason = ( 200 => 'OK', 403 => 'Forbidden', 404 => 'Not Found' );
    my @o;
    if ($head) { push @o, "HTTP/1.1 $code $reason{$code}", 'Server: nginx/1.22.1', "Content-Type: $type", 'Content-Length: ' . length($body), 'Connection: keep-alive' }
    elsif ( defined $out && $out ne '-' ) {
        if ( $out ne '/dev/null' ) { my ( $e, $wok ) = _write_path( $dev, $out, $body, 0, $ctx ); return ( $e, 0 ) unless $wok }
    }
    else { push @o, $body =~ s/\n\z//r }
    push @o, $wfmt =~ s/%\{http_code\}/$code/gr =~ s/\\n/\n/gr =~ s/\n\z//r if defined $wfmt;
    return ( join( "\n", @o ), 1 );
}

# env [NAME=wert …] [befehl …]: ohne Befehl die Umgebung der Shell (exportierte Variablen,
# Vorgaben der Anmeldung), sonst den Befehl mit diesen Variablen
sub _env {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my %set;
    while ( @a && $a[0] =~ /\A([A-Za-z_]\w*)=(.*)\z/s ) { $set{$1} = $2; shift @a }
    if ( @a && $a[0] =~ /\A-/ ) { push @GAPS, join( ' ', 'env', @$av ); return ( '', 0 ) }
    if (@a) {
        local $SHENV = { %{ $SHENV || {} }, %set };
        return __PACKAGE__->_command( $dev, \@a, $ctx, $stdin );
    }
    my $u = _who();
    my %e = ( PATH => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', HOME => $u eq 'root' ? '/root' : "/home/$u",
        USER => $u, LOGNAME => $u, SHELL => '/bin/bash', PWD => $CWD_DIR // ( $u eq 'root' ? '/root' : "/home/$u" ), LANG => 'C.UTF-8', SHLVL => 1,
        ( $dev->{ssh_login} ? ( SSH_CONNECTION => ( $dev->{ssh_login}{from} // '10.1.0.50' ) . ' 50122 ' . ( ( grep { !/\A(?:127\.|::1)/ } _own_addrs($dev) )[0] // '127.0.0.1' ) . ' 22' ) : () ),
        ( map { $_ => $SH->{vars}{$_} } grep { defined $SH->{vars}{$_} } keys %{ ( $SH || {} )->{exported} || {} } ), %{ $SHENV || {} }, %set );
    return ( join( "\n", ( map {"$_=$e{$_}"} sort keys %e ), '_=/usr/bin/env' ), 1 );
}

# wget gegen die eigene Maschine: Prometheus/Alertmanager (Sim::Monitoring), auf dem Port
# von nginx dessen statische Dateien (_nginx_http): -O -|DATEI, -q, -S, --spider,
# --header='Host: …'; anderes ist eine Luecke
sub _wget {
    my ( $dev, $av, $ctx ) = @_;
    my ( $url, $out, $post, $quiet, $show, $spider, $vhost );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-([qS]*)O\z/ || $x eq '--output-document' ) {
            my $f = $x =~ /\A-([qS]*)O\z/ ? $1 : '';
            $out = shift @a;
            $quiet = 1 if $f =~ /q/;
            $show = 1 if $f =~ /S/;
        }
        elsif ( $x =~ /\A-([qS]*)O(.+)\z/ ) { my $f = $1; $out = $2; $quiet = 1 if $f =~ /q/; $show = 1 if $f =~ /S/ }
        elsif ( $x =~ /\A--output-document=(.*)\z/ ) { $out = $1 }
        elsif ( $x =~ /\A--post-data=/ || $x =~ /\A--method=POST\z/i ) { $post = 1 }
        elsif ( $x eq '--post-data' ) { shift @a; $post = 1 }
        elsif ( $x eq '--header' ) { my $h = shift(@a) // ''; $vhost = $1 if $h =~ /\AHost:\s*(\S+)/i }
        elsif ( $x =~ /\A--header=Host:\s*(\S+)\z/i ) { $vhost = $1 }
        elsif ( $x eq '--spider' ) { $spider = 1 }
        elsif ( $x =~ /\A-([qSv]+)\z/ || $x eq '--quiet' || $x eq '--server-response' ) {
            my $f = $1 // ( $x eq '--quiet' ? 'q' : 'S' );
            $quiet = 1 if $f =~ /q/;
            $show = 1 if $f =~ /S/;
        }
        elsif ( $x =~ /\A-/ ) { }
        else { $url = $x }
    }
    my ( $h80, $port80, $path80 ) = ( $url // '' ) =~ m{\A(?:http://)?([^/:]+)(?::(\d+))?(/.*)?\z};
    my $self80 = defined $h80 && ( $h80 =~ /\A(?:localhost|127\.0\.0\.1)\z/ || grep { $_ eq $h80 } _own_addrs($dev), $dev->{hostname} // (), $ctx->{host} // () );
    if ( $self80 && !$post && ( $port80 // 80 ) !~ /\A(?:9090|9093)\z/ ) {
        my ( $body, $st, $type ) = _nginx_http( $dev, $port80 // 80, $vhost // $h80, $path80 // '/' );
        # nginx lauscht dort nicht, aber ein anderer Dienst: nicht nachgebildet
        my $pn = $port80 // 80;
        if ( defined $st && !$st && ( _ss( $dev, [] ) )[0] =~ /:\Q$pn\E\s/ ) { undef $st }
        if ( !defined $st ) { push @GAPS, join( ' ', 'wget', @$av ); return ( '', 0 ) }
        require POSIX;
        my $stamp = POSIX::strftime( '%Y-%m-%d %H:%M:%S', _local_tm( _dev_now($dev) ) );
        my $hp = $h80 . ( defined $port80 ? ":$port80" : '' );
        my $addr = $h80 eq 'localhost' ? '127.0.0.1' : $h80;
        my @err;
        push @err, "--$stamp--  http://$hp" . ( $path80 // '/' ), "Connecting to $hp ($addr:" . ( $port80 // 80 ) . ')... ' . ( $st ? 'connected.' : 'failed: Connection refused.' ) unless $quiet;
        return ( join( "\n", @err ), 0 ) unless $st;
        my %reason = ( 200 => 'OK', 403 => 'Forbidden', 404 => 'Not Found' );
        push @err, "HTTP request sent, awaiting response... " . ( $show ? '' : "$st $reason{$st}" ) unless $quiet;
        push @err, "  HTTP/1.1 $st $reason{$st}", '  Server: nginx/1.22.1', "  Content-Type: $type", '  Content-Length: ' . length($body), '  Connection: keep-alive' if $show;
        if ( $st != 200 ) { push @err, "$stamp ERROR $st: $reason{$st}." unless $quiet; return ( join( "\n", @err ), 0 ) }
        if ($spider) { push @err, 'Remote file exists.' unless $quiet; return ( join( "\n", @err ), 1 ) }
        my $file = $out // ( ( ( $path80 // '/' ) =~ m{([^/]+)\z} )[0] // 'index.html' );
        return ( join( "\n", @err, $body =~ s/\n\z//r ), 1 ) if $file eq '-';
        if ( $file ne '/dev/null' ) {
            my ( $e, $wok ) = _write_path( $dev, $file, $body, 0, $ctx );
            return ( $e, 0 ) unless $wok;
        }
        push @err, "Saving to: '$file'", '', "'$file' saved [" . length($body) . ']' unless $quiet;
        return ( join( "\n", @err ), 1 );
    }
    # ein anderes Geraet: nur das Scheitern der Verbindung ist nachgebildet
    if ( defined $h80 && !$self80 ) {
        my $pn = $port80 // ( ( $url // '' ) =~ m{\Ahttps://} ? 443 : 80 );
        my $st = _tcp_probe( $dev, $h80, $pn );
        if ( defined $st && $st ne 'open' ) {
            require POSIX;
            my $stamp = POSIX::strftime( '%Y-%m-%d %H:%M:%S', _local_tm( _dev_now($dev) ) );
            my $why = { refused => 'Connection refused', timeout => 'Connection timed out', unreach => 'Network is unreachable' }->{$st};
            $SH->{code} = 4 if $SH;
            return ( '', 0 ) if $quiet || $st eq 'timeout' && $IN_TIMEOUT;
            return ( "wget: unable to resolve host address '$h80'", 0 ) if $st eq 'noname';
            my $ip = _ip2n($h80) ? $h80 : ( _own_addrs( ( $ctx->{state} || {} )->{$h80} || {} ) )[0] // $h80;
            return ( "--$stamp--  $url\nConnecting to $h80 ($ip:$pn)... failed: $why.", 0 );
        }
    }
    my ( $host, $port, $path ) = ( $url // '' ) =~ m{\A(?:http://)?([^/:]+):(\d+)(/.*)?\z};
    my $local = defined $host && ( $host =~ /\A(?:localhost|127\.0\.0\.1)\z/ || grep { $_ eq $host } _own_addrs($dev) );
    if ( !$local || ( $out // '' ) ne '-' ) { push @GAPS, join( ' ', 'wget', @$av ); return ( '', 0 ) }
    _part('Monitoring');
    my ( $body, $st ) = Langertha::Holmgang::Sim::Linux::Monitoring::http( $dev, $post ? 'POST' : 'GET', $port, $path // '/',
        sub { my ( $o, $k ) = __PACKAGE__->_run_inner( $dev, $_[0], $ctx ); return ( $o, $k ) } );
    if ( !defined $st ) { push @GAPS, join( ' ', 'wget', @$av ); return ( '', 0 ) }
    return ( "failed: Connection refused.", 0 ) if !$st;
    return ( $body, 1 ) if $st == 200;
    my %reason = ( 403 => 'Forbidden', 405 => 'Method Not Allowed', 500 => 'Internal Server Error' );
    return ( "ERROR $st: " . ( $reason{$st} // 'Error' ) . '.', 0 );
}

# nginx -t|-T (Klammern und Semikolons je Datei pruefen: nginx.conf, conf.d/*.conf, sites-enabled/*),
# -v|-V, -s reload|stop|quit (wie systemctl); ohne nginx-Dienst nicht installiert
sub _nginx {
    my ( $dev, $av, $ctx ) = @_;
    return ( 'bash: nginx: command not found', 0 ) unless ( $dev->{services} || {} )->{nginx};
    my %o;
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-s' ) { $o{s} = shift(@a) // '' }
        elsif ( $x =~ /\A-([tTvVq]+)\z/ ) { $o{$_} = 1 for split //, $1 }
        else  { push @GAPS, join( ' ', 'nginx', @$av ); return ( '', 0 ) }
    }
    return ( 'nginx version: nginx/1.22.1', 1 ) if $o{v} && !$o{V};
    return ( "nginx version: nginx/1.22.1\nbuilt with OpenSSL 3.0.11 19 Sep 2023\nTLS SNI support enabled\nconfigure arguments: --with-cc-opt='-g -O2' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=stderr --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --with-http_ssl_module --with-http_v2_module --with-stream=dynamic", 1 ) if $o{V};
    if ( defined $o{s} ) {
        my %verb = ( reload => 'reload', stop => 'stop', quit => 'stop', reopen => 'reload' );
        my $v = $verb{ $o{s} } // return ( qq{nginx: invalid option: "-s $o{s}"}, 0 );
        return ( qq{nginx: [error] invalid PID number "" in "/run/nginx.pid"}, 0 ) unless $dev->{services}{nginx}{active};
        my ( $out, $k ) = _systemctl( $dev, [ $v, 'nginx' ], $ctx );
        return ( $k ? '' : $out, $k );
    }
    if ( $o{t} || $o{T} ) {
        my @f = grep { defined _file_text( $dev, $_ ) } '/etc/nginx/nginx.conf',
            grep { m{\A/etc/nginx/(?:conf\.d/[^/]+\.conf|sites-enabled/[^/]+)\z} } sort keys %{ $dev->{files} || {} };
        for my $f (@f) {
            my $t = _file_text( $dev, $f );
            ( my $c = $t ) =~ s/#[^\n]*//g;
            $c =~ s/"[^"\n]*"|'[^'\n]*'//g;
            my ( $depth, $line ) = ( 0, 0 );
            for my $l ( split /\n/, $c, -1 ) {
                $line++;
                for my $ch ( $l =~ /([{}])/g ) {
                    $depth += $ch eq '{' ? 1 : -1;
                    return ( qq~nginx: [emerg] unexpected "}" in $f:$line\nnginx: configuration file /etc/nginx/nginx.conf test failed~, 0 ) if $depth < 0;
                }
                ( my $st = $l ) =~ s/\A\s+|\s+\z//g;
                next if $st eq '' || $st =~ /[;{}]\z/;
                my $next = ( split /\n/, $c, -1 )[$line] // '';
                next if $next =~ /\A\s*[{;]/;    # Fortsetzung auf der naechsten Zeile
                return ( qq~nginx: [emerg] directive "~ . ( split /\s+/, $st )[0] . qq~" is not terminated by ";" in $f:$line\nnginx: configuration file /etc/nginx/nginx.conf test failed~, 0 );
            }
            return ( qq~nginx: [emerg] unexpected end of file, expecting "}" in $f:$line\nnginx: configuration file /etc/nginx/nginx.conf test failed~, 0 ) if $depth;
        }
        my @out = ( 'nginx: the configuration file /etc/nginx/nginx.conf syntax is ok', 'nginx: configuration file /etc/nginx/nginx.conf test is successful' );
        push @out, map { ( "# configuration file $_:", _file_text( $dev, $_ ) =~ s/\n\z//r, '' ) } @f if $o{T};
        return ( join( "\n", @out ), 1 );
    }
    push @GAPS, join( ' ', 'nginx', @$av );
    return ( '', 0 );
}


# diff a b (Normalformat) und diff -u (vereinheitlicht, 3 Zeilen Kontext);
# gleich: leer und Erfolg, verschieden: Ausgabe und Exit 1
sub _diff {
    my ( $dev, $av ) = @_;
    my @f = grep { !/\A-/ } @$av;
    my $u = grep {/\A-[a-zA-Z]*u|\A--unified/} @$av;
    my $r = grep {/\A-[a-zA-Z]*r|\A--recursive/} @$av;
    my $q = grep {/\A-[a-zA-Z]*q|\A--brief/} @$av;
    return ( 'diff: missing operand', 0 ) if @f < 2;
    my ( $fa, $fb ) = map { _absp( s{(?<=.)/+\z}{}r ) } @f[ 0, 1 ];
    if ( _is_dir( $dev, $fa ) && _is_dir( $dev, $fb ) ) {
        my %rel;
        for my $d ( $fa, $fb ) {
            my $real = _via_link( $dev, $d ) // ( ref $dev->{files}{$d} eq 'HASH' && defined $dev->{files}{$d}{link} ? _link_target( $d, $dev->{files}{$d}{link} ) : $d );
            for my $p ( _under( $dev, $real ) ) {
                my $x = substr $p, length($real) + 1;
                next if !$r && $x =~ m{/};
                $rel{$x}{$d} = 1;
            }
        }
        my @out;
        for my $x ( sort keys %rel ) {
            if ( !$rel{$x}{$fb} || !$rel{$x}{$fa} ) {
                my $d = $rel{$x}{$fa} ? $fa : $fb;
                my ( $sub, $n ) = $x =~ m{\A(?:(.*)/)?([^/]+)\z};
                push @out, "Only in $d" . ( defined $sub ? "/$sub" : '' ) . ": $n";
                next;
            }
            my @d = _diff_text( [ split /\n/, _file_text( $dev, "$fa/$x" ) // '' ], [ split /\n/, _file_text( $dev, "$fb/$x" ) // '' ], $u, "$fa/$x", "$fb/$x" );
            push @out, $q ? "Files $fa/$x and $fb/$x differ" : ( ( $u ? "diff -ru $fa/$x $fb/$x" : "diff -r $fa/$x $fb/$x" ), @d ) if @d;
        }
        return ( join( "\n", @out ), !@out );
    }
    my @t;
    for my $p ( $fa, $fb ) {
        my $x = _file_text( $dev, $p );
        return ( "diff: $p: No such file or directory", 0 ) if !defined $x;
        push @t, [ split /\n/, $x ];
    }
    my @out = _diff_text( @t, $u, @f[ 0, 1 ] );
    @out = ("Files $f[0] and $f[1] differ") if $q && @out;
    return ( join( "\n", @out ), !@out );
}

sub _diff_text {
    my ( $a, $b, $u, $fa, $fb ) = @_;
    my @ops = _lcs_ops( $a, $b );
    return () if !grep { $_->[0] ne '=' } @ops;
    return _diff_unified( \@ops, $fa, $fb ) if $u;
    my @out;
    my ( $i, $j ) = ( 0, 0 );
    my $k = 0;
    while ( $k < @ops ) {
        if ( $ops[$k][0] eq '=' ) { $i++; $j++; $k++; next }
        my ( @d, @a );
        while ( $k < @ops && $ops[$k][0] ne '=' ) {
            push @d, $ops[$k][1] if $ops[$k][0] eq '-';
            push @a, $ops[$k][1] if $ops[$k][0] eq '+';
            $k++;
        }
        my $r = sub { my ( $s, $n ) = @_; $n > 1 ? "$s," . ( $s + $n - 1 ) : $s };
        my $code = @d && @a ? $r->( $i + 1, scalar @d ) . 'c' . $r->( $j + 1, scalar @a )
            : @d ? $r->( $i + 1, scalar @d ) . 'd' . $j
            :      $i . 'a' . $r->( $j + 1, scalar @a );
        push @out, $code, ( map {"< $_"} @d ), ( @d && @a ? '---' : () ), map {"> $_"} @a;
        $i += @d;
        $j += @a;
    }
    return @out;
}

sub _lcs_ops {
    my ( $a, $b ) = @_;
    my ( $n, $m ) = ( scalar @$a, scalar @$b );
    my @L;
    for my $i ( reverse 0 .. $n ) {
        for my $j ( reverse 0 .. $m ) {
            $L[$i][$j] = $i == $n || $j == $m ? 0
                : $a->[$i] eq $b->[$j] ? $L[ $i + 1 ][ $j + 1 ] + 1
                : _max( $L[ $i + 1 ][$j], $L[$i][ $j + 1 ] );
        }
    }
    my ( $i, $j, @ops ) = ( 0, 0 );
    while ( $i < $n || $j < $m ) {
        if    ( $i < $n && $j < $m && $a->[$i] eq $b->[$j] )            { push @ops, [ '=', $a->[$i] ]; $i++; $j++ }
        elsif ( $j < $m && ( $i == $n || $L[$i][ $j + 1 ] > $L[ $i + 1 ][$j] ) ) { push @ops, [ '+', $b->[ $j++ ] ] }
        else                                                              { push @ops, [ '-', $a->[ $i++ ] ] }
    }
    return @ops;
}

sub _max { $_[0] > $_[1] ? $_[0] : $_[1] }

sub _diff_unified {
    my ( $ops, $fa, $fb ) = @_;
    my @out = ( "--- $fa", "+++ $fb" );
    my @chg = grep { $ops->[$_][0] ne '=' } 0 .. $#$ops;
    # Bereiche: Aenderungen, die hoechstens 6 Zeilen auseinander liegen, gehoeren zusammen
    my @h;
    for my $c (@chg) {
        if ( @h && $c - $h[-1][1] <= 7 ) { $h[-1][1] = $c }
        else                             { push @h, [ $c, $c ] }
    }
    for my $h (@h) {
        my $s = _max( 0, $h->[0] - 3 );
        my $e = $h->[1] + 3 > $#$ops ? $#$ops : $h->[1] + 3;
        my ( $ia, $ib ) = ( 1, 1 );
        for my $k ( 0 .. $s - 1 ) { $ia++ if $ops->[$k][0] ne '+'; $ib++ if $ops->[$k][0] ne '-' }
        my @l = map { ( $_->[0] eq '=' ? ' ' : $_->[0] ) . $_->[1] } @$ops[ $s .. $e ];
        my $na = grep { !/\A\+/ } @l;
        my $nb = grep { !/\A-/ } @l;
        push @out, sprintf( '@@ -%d,%d +%d,%d @@', $na ? $ia : $ia - 1, $na, $nb ? $ib : $ib - 1, $nb ), @l;
    }
    return @out;
}

sub _cmp {
    my ( $dev, $av ) = @_;
    my @f = grep { !/\A-/ } @$av;
    my @t = map { _file_text( $dev, $_ ) } @f[ 0, 1 ];
    for ( 0, 1 ) { return ( "cmp: $f[$_]: No such file or directory", 0 ) if !defined $t[$_] }
    return ( '', 1 ) if $t[0] eq $t[1];
    my $i = 0;
    $i++ while $i < length $t[0] && $i < length $t[1] && substr( $t[0], $i, 1 ) eq substr( $t[1], $i, 1 );
    my $line = 1 + ( () = substr( $t[0], 0, $i ) =~ /\n/g );
    return ( "$f[0] $f[1] differ: byte " . ( $i + 1 ) . ", line $line", 0 );
}

sub _readlink {
    my ( $dev, $av ) = @_;
    my $canon = grep {/\A-\w*[fem]/} @$av;
    my @out;
    for my $p ( grep { !/\A-/ } @$av ) {
        ( my $q = $p ) =~ s{(?<=.)/+\z}{};
        my $e = ref $dev->{files} eq 'HASH' ? $dev->{files}{$q} : undef;
        if ( !$canon ) {
            return ( '', 0 ) unless ref $e eq 'HASH' && defined $e->{link};    # keine Verknuepfung: Exit 1
            push @out, $e->{link};
            next;
        }
        my $t = $q;
        for ( 1 .. 6 ) {
            $t = _via_link( $dev, $t ) // $t;
            my $x = $dev->{files}{$t};
            last unless ref $x eq 'HASH' && defined $x->{link};
            $t = _link_target( $t, $x->{link} );
        }
        push @out, $t;
    }
    return ( join( "\n", @out ), 1 );
}

# --- systemd ----------------------------------------------------------------------

# Startbedingungen eines Dienstes (needs): erste nicht erfuellte oder undef.
#   { can: { user, read|write|exec: pfad } }  Benutzer darf die Datei …
#   { free: { mount, min } }                  mindestens so viel frei
#   { state: [pfad im Geraet], <Erwartungen> } Zustand (wie Regeln)
# Jede Bedingung traegt log: [ Zeilen ] fuer das Journal beim Scheitern.
sub _failing_need {
    my ( $dev, $svc ) = @_;
    # ohne Benutzer in der Bedingung: User= der geladenen Unit, sonst user des Dienstes
    my ($uu) = ( $svc->{unit_loaded} // '' ) =~ /^\s*User\s*=\s*(\S+)/m;
    for my $n ( @{ $svc->{needs} || [] } ) {
        if ( my $c = $n->{can} ) {
            my ($what) = grep { exists $c->{$_} } qw( read write exec );
            return $n unless _can( $dev, $c->{user} // $uu // $svc->{user} // 'root', $c->{$what}, substr( $what, 0, 1 ) eq 'e' ? 'x' : substr( $what, 0, 1 ) );
        }
        elsif ( my $f = $n->{free} ) {
            my $free = _free( $dev, $f->{mount} // '/' ) // 0;
            return $n if $free < _bytes( $f->{min} );
        }
        elsif ( my $want = $n->{env} ) {    # Umgebung des Prozesses: VAR => Muster
            my ( $env, $miss ) = _unit_env( $dev, $svc );
            if ( defined $miss ) {    # EnvironmentFile ohne - fehlt: systemd startet den Prozess gar nicht
                my $u = ( $svc->{unit} // 'unit.service' ) =~ s{.*/}{}r;
                my $h = $dev->{hostname} // ( $CTX || {} )->{host} // 'localhost';
                my $c = _clock($dev);
                return { log => [ "$c:03 $h systemd[1]: $u: Failed to load environment files: No such file or directory",
                    "$c:03 $h systemd[1]: $u: Failed to spawn 'start' task: No such file or directory" ] };
            }
            for my $k ( sort keys %$want ) { return $n unless defined $env->{$k} && $env->{$k} =~ /$want->{$k}/ }
        }
        elsif ( exists $n->{state} ) {
            my %c = %$n;
            delete @c{qw( state log )};
            my ($ok) = _condition( $dev, { %c, path => $n->{state} } );
            return $n unless $ok;
        }
    }
    return undef;
}

# Umgebung eines Dienstes aus der geladenen Unit: Environment=, dann EnvironmentFile= (in dieser
# Reihenfolge, die Datei gewinnt; Zeilen VAR=wert, Anfuehrungszeichen weg, Kommentare und
# Zeilen ohne VAR= uebergangen; ein vorangestelltes export ist erlaubt). ( \%env, $fehlende_datei )
sub _unit_env {
    my ( $dev, $svc ) = @_;
    my $p = _unit_props( $svc->{unit_loaded} // '' );
    my %env = %{ $p->{Environment} || {} };
    for my $f ( @{ $p->{EnvironmentFile} || [] } ) {
        my $opt = $f =~ s/\A-//;
        my $t = _file_text( $dev, $f );
        if ( !defined $t ) { return ( \%env, $f ) unless $opt; next }
        for my $l ( split /\n/, $t ) {
            next if $l =~ /\A\s*(?:[#;]|\z)/;
            my ( $k, $v ) = $l =~ /\A\s*(?:export\s+)?([A-Za-z_]\w*)=(.*?)\s*\z/ or next;
            $v = $1 if $v =~ /\A"(.*)"\z/ || $v =~ /\A'(.*)'\z/;
            $env{$k} = $v;
        }
    }
    return ( \%env, undef );
}

# Konten und Gruppen eines frischen Debian 12 (und gaengiger Pakete), die kein Fall nennen muss
our %BASE_USERS = map { $_ => 1 } qw( root daemon bin sys sync games man lp mail news uucp proxy www-data backup list irc _apt
    nobody systemd-network systemd-timesync messagebus sshd postgres redis mysql prometheus bind _chrony postfix nginx );
our %BASE_GROUPS = map { $_ => 1 } qw( root daemon bin sys adm tty disk lp mail news uucp man proxy kmem dialout fax voice cdrom
    floppy tape sudo audio dip www-data backup operator list irc src shadow utmp video sasl plugdev staff games users nogroup
    systemd-journal systemd-network systemd-timesync input sgx kvm render crontab messagebus ssl-cert postgres redis mysql
    prometheus bind _chrony postfix postdrop nginx );

# User=/Group= der Unit, die es auf dem Geraet nicht gibt: 'user' bzw. 'group' oder undef. Nur
# auf Geraeten mit check_accounts (der Fall nennt alle Konten); Nummern und Grundkonten zaehlen
# immer als vorhanden.
sub _cred_missing {
    my ( $dev, $u, $g ) = @_;
    return undef unless $dev->{check_accounts};
    return 'user' if defined $u && $u !~ /\A\d+\z/ && !$BASE_USERS{$u} && !$dev->{users}{$u};
    return 'group' if defined $g && $g !~ /\A\d+\z/ && !$BASE_GROUPS{$g} && !( $dev->{groups} || {} )->{$g}
        && !grep { grep { $_ eq $g } @{ $_->{groups} || [] } } values %{ $dev->{users} };
    return undef;
}

sub _unit_file { my ( $n, $svc ) = @_; return $svc->{unit} // '/lib/systemd/system/' . _uname($n) }

# Voller Unit-Name: "app" -> "app.service", "backup.timer" bleibt
sub _uname { my ($n) = @_; return $n =~ /\.(?:timer|socket|path|target|mount)\z/ ? $n : "$n.service" }

# Text der Unit, wie systemd sie geladen hat (sonst Datei und Drop-ins)
sub _unit_loaded_text {
    my ( $dev, $n, $svc ) = @_;
    return $svc->{unit_loaded} // _unit_text( $dev, $n, $svc );
}

# Ganze Unit ohne [Install]: "static", enable/disable wirken nicht
sub _static {
    my ( $dev, $n, $svc ) = @_;
    my $t = _unit_loaded_text( $dev, $n, $svc );
    return defined $t && $t =~ /^\[Unit\]/m && $t !~ /^\[Install\]/m ? 1 : 0;
}

sub _oneshot {
    my ( $dev, $n, $svc ) = @_;
    my $t = _unit_loaded_text( $dev, $n, $svc ) // '';
    return $t =~ /^\s*Type\s*=\s*oneshot\s*$/m && $t !~ /^\s*RemainAfterExit\s*=\s*(?:yes|true|1|on)\s*$/m ? 1 : 0;
}

# Timer aus dem geladenen Text: gueltige und ungueltige OnCalendar=, andere
# Ausloeser, ausgeloeste Unit.
sub _timer_info {
    my ( $dev, $n, $svc ) = @_;
    require Langertha::Holmgang::Sim::Linux::Calendar;
    my $t = _unit_loaded_text( $dev, $n, $svc ) // '';
    my ( @cal, @bad, $other );
    my $line = 0;
    for my $l ( split /\n/, $t ) {
        $line++;
        if ( $l =~ /^\s*OnCalendar\s*=\s*(.*?)\s*$/ ) {
            my $e = $1;
            # leere Zuweisung setzt die Liste zurueck (systemd.timer(5), z. B. im Drop-in)
            if ( $e eq '' ) { @cal = (); next }
            my $c = Langertha::Holmgang::Sim::Linux::Calendar::parse($e);
            if ($c) { push @cal, $c } else { push @bad, [ $line, $e ] }
        }
        $other = 1 if $l =~ /^\s*On(?:Boot|Startup|Active|UnitActive|UnitInactive)Sec\s*=\s*\S/;
    }
    ( my $base = $n ) =~ s/\.timer\z//;
    my ($unit) = $t =~ /^\s*Unit\s*=\s*(\S+)\s*$/m;
    return { cal => \@cal, bad => \@bad, other => $other, activates => $unit // "$base.service",
        persistent => $t =~ /^\s*Persistent\s*=\s*(?:yes|true|1|on)\s*$/m ? 1 : 0 };
}

# Abgeleitete Felder eines Timers im Zustand (fuer Regeln): Normalformen der
# gueltigen OnCalendar= und die ausgeloeste Unit. Nur wenn sich die geladene
# Unit aendert.
sub _timer_derive {
    my ( $dev, $n, $svc ) = @_;
    return unless $n =~ /\.timer\z/;
    my $i = _timer_info( $dev, $n, $svc );
    $svc->{triggers}  = [ map { $_->{normalized} } @{ $i->{cal} } ];
    $svc->{activates} = $i->{activates};
    return;
}

# Unit aus ihrer Datei laden, wenn systemd sie noch nicht kennt (wie beim ersten
# Zugriff auf eine neue Unit-Datei)
sub _load_unit {
    my ( $dev, $n, $peek ) = @_;
    for my $dir (qw( /etc/systemd/system /lib/systemd/system )) {
        my $p = "$dir/" . _uname($n);
        my $t = _file_text( $dev, $p );
        next unless defined $t;
        my ($desc) = $t =~ /^\s*Description\s*=\s*(.*?)\s*$/m;
        my $svc = { unit => $p, unit_loaded => $t, enabled => JSON::MaybeXS::false(), active => JSON::MaybeXS::false(),
            ( defined $desc ? ( description => $desc ) : () ) };
        _timer_derive( $dev, $n, $svc );
        $dev->{services}{$n} = $svc unless $peek;    # Lesen (status, is-*) laedt nur zur Ansicht
        return $svc;
    }
    return undef;
}

# Drop-ins <unit>.service.d/*.conf: gleichnamige unter /etc ueberdecken /run und /lib,
# gelesen nach Namen sortiert; ein Link auf /dev/null schaltet einen ab
sub _dropins {
    my ( $dev, $n ) = @_;
    my $u = _uname($n);
    my %by;
    for my $base (qw( /lib/systemd/system /usr/lib/systemd/system /run/systemd/system /etc/systemd/system )) {
        for my $p ( _under( $dev, "$base/$u.d" ) ) {
            next unless $p =~ m{\A\Q$base/$u.d/\E([^/]+\.conf)\z};
            my $e = $dev->{files}{$p};
            $by{$1} = ref $e eq 'HASH' && ( $e->{link} // '' ) eq '/dev/null' ? undef : $p;
        }
    }
    return map { $by{$_} } grep { defined $by{$_} } sort keys %by;
}

# Unit, wie systemd sie liest: Hauptdatei, dann die Drop-ins (mit Kopfzeile); undef ohne beides
sub _unit_text {
    my ( $dev, $n, $svc ) = @_;
    my $main = _file_text( $dev, _unit_file( $n, $svc ) );
    my @d = _dropins( $dev, $n );
    return $main unless @d;
    return join '', $main // '', map { "\n# $_\n" . ( _file_text( $dev, $_ ) // '' ) } @d;
}

# Wirksame Einstellungen einer Unit-Fassung (nur innerhalb eines Abschnitts, wie systemd;
# ein Drop-in ohne [Service] wirkt nicht): die letzte Zuweisung gilt; ExecStart*,
# EnvironmentFile sind Listen, die eine leere Zuweisung leert; Environment ist { VAR => wert }.
sub _unit_props {
    my ($text) = @_;
    my %p;
    my $sec;
    for my $l ( split /\n/, $text // '' ) {
        if ( $l =~ m{\A# /\S+\.conf\z} ) { undef $sec; next }    # Kopf eines Drop-ins: neue Datei
        if ( $l =~ /\A\s*\[(\w+)\]/ ) { $sec = $1; next }
        next if $l =~ /\A\s*(?:[#;]|\z)/;
        next unless defined $sec;    # ausserhalb eines Abschnitts: systemd ignoriert die Zeile
        my ( $k, $v ) = $l =~ /\A\s*([A-Za-z]+)\s*=\s*(.*?)\s*\z/ or next;
        if ( $k =~ /\A(?:ExecStart|ExecStartPre|ExecStartPost|ExecReload|EnvironmentFile)\z/ ) {
            $p{$k} = [] if $v eq '' || !$p{$k};
            push @{ $p{$k} }, $v if $v ne '';
        }
        elsif ( $k eq 'Environment' ) {
            $p{Environment} = {} if $v eq '' || !$p{Environment};
            while ( $v =~ /\G\s*(?:"([^"]*)"|'([^']*)'|(\S+))/gc ) {
                my $w = $1 // $2 // $3;
                my ( $a, $b ) = split /=/, $w, 2;
                $p{Environment}{$a} = $b // '' if defined $a && length $a;
            }
        }
        else { $p{$k} = $v }
    }
    return \%p;
}

# Fehler beim Laden der Unit (bad-setting) oder undef
sub _unit_bad {
    my ( $n, $props ) = @_;
    return _uname($n) . ": Service has more than one ExecStart= setting, which is only allowed for Type=oneshot services. Refusing."
        if @{ $props->{ExecStart} || [] } > 1 && ( $props->{Type} // 'simple' ) ne 'oneshot';
    # ExecStart= geleert und nichts mehr gesetzt
    return _uname($n) . ": Service has no ExecStart=, ExecStop=, or SuccessAction=. Refusing."
        if $props->{ExecStart} && !@{ $props->{ExecStart} };
    return undef;
}

sub _systemd_start {
    my ( $dev, $n, $svc, $verb ) = @_;
    my $u = _uname($n);
    return ( "Failed to $verb $u: Unit $u is masked.", 0 ) if $svc->{masked};
    my @warn;
    if ( defined $svc->{unit_loaded} ) {
        my $now = _unit_text( $dev, $n, $svc );
        push @warn, "Warning: The unit file, source configuration file or drop-ins of $u changed on disk. Run 'systemctl daemon-reload' to reload units."
            if defined $now && $now ne $svc->{unit_loaded};
    }
    if ( $n =~ /\.timer\z/ ) {
        my $i = _timer_info( $dev, $n, $svc );
        return ( join( "\n", @warn, "Failed to $verb $u: Unit $u has a bad unit file setting.",
            "See system logs and 'systemctl status $u' for details." ), 0 ) unless @{ $i->{cal} } || $i->{other};
        my $act = _unit( $i->{activates} );
        return ( join( "\n", @warn, "Failed to $verb $u: Unit $i->{activates} not found." ), 0 )
            unless ( $dev->{services} || {} )->{$act} || _load_unit( $dev, $act, 1 );
    }
    # RuntimeDirectory=/StateDirectory=/LogsDirectory= der geladenen Unit legt systemd beim Start an
    my $ut = $svc->{unit_loaded} // _unit_text( $dev, $n, $svc ) // '';
    my $props = _unit_props($ut);
    # bad-setting: systemd nimmt den Auftrag gar nicht an — ein laufender Prozess laeuft weiter
    if ( _unit_bad( $n, $props ) ) {
        return ( join( "\n", @warn, "Failed to $verb $u: Unit $u has a bad unit file setting.",
            "See system logs and 'systemctl status $u' for details." ), 0 );
    }
    my ($uuser) = $ut =~ /^\s*User\s*=\s*(\S+)/m;
    my ($ugrp)  = $ut =~ /^\s*Group\s*=\s*(\S+)/m;
    # User=/Group= der Unit, die es nicht gibt (Geraet mit check_accounts): 217/USER bzw. 216/GROUP wie systemd
    if ( my $miss = _cred_missing( $dev, $uuser, $ugrp ) ) {
        ( my $prog = ( $props->{ExecStart} || [''] )->[0] // '' ) =~ s/\A[-@+!:]+//;
        $prog =~ s/\s.*//s;
        ( my $short = $n ) =~ s/\A(.{1,15}).*/$1/;
        my $W = uc $miss;
        _log( $dev, $n, $svc, "($short)[3001]: $u: Failed to determine $miss credentials: No such process",
            "($short)[3001]: $u: Failed at step $W spawning $prog: No such process" );
        _app_event( $dev, $n, 'stop' ) if $svc->{active} && $verb =~ /restart/;
        $svc->{active} = JSON::MaybeXS::false() if $svc->{active} && $verb =~ /restart/;
        $svc->{failed} = JSON::MaybeXS::true() unless $svc->{failed} || $svc->{active};
        return ( join( "\n", @warn, "Job for $u failed because the control process exited with error code.",
            "See \"systemctl status $u\" and \"journalctl -xeu $u\" for details." ), 0 ) unless $svc->{active};
    }
    for ( [ RuntimeDirectory => '/run' ], [ StateDirectory => '/var/lib' ], [ LogsDirectory => '/var/log' ], [ CacheDirectory => '/var/cache' ] ) {
        my ( $k, $base ) = @$_;
        for my $d ( map { split /\s+/ } $ut =~ /^\s*\Q$k\E\s*=\s*(.+?)\s*$/mg ) {
            my $p = "$base/$d";
            next if _is_dir( $dev, $p );
            $dev->{dirs}{$p} = { owner => $uuser // 'root', group => $ugrp // $uuser // 'root', mode => '0755' };
        }
    }
    # Neustart gibt geloeschte, noch offene Dateien frei
    if ( $dev->{deleted_open} ) {
        my @keep = grep { ( $_->{by} // '' ) ne $n } @{ $dev->{deleted_open} };
        $dev->{deleted_open} = \@keep if @keep != @{ $dev->{deleted_open} };
    }
    my $conf_bad = _app_conf_error( $dev, $n );
    if ($conf_bad) {
        _app_event( $dev, $n, 'stop' ) if $svc->{active};
        _log( $dev, $n, $svc, @$conf_bad );
    }
    if ( $conf_bad || ( my $bad = _failing_need( $dev, $svc ) ) ) {
        _app_log( $dev, $n, $svc, 'fail' );
        $svc->{active} = JSON::MaybeXS::false() if $svc->{active};
        $svc->{failed} = JSON::MaybeXS::true() unless $svc->{failed};
        return ( join( "\n", @warn, "Job for $u failed because the control process exited with error code.",
            "See \"systemctl status $u\" and \"journalctl -xeu $u\" for details." ), 0 );
    }
    if ( defined $svc->{run} ) {    # Type=oneshot: der Befehl laeuft beim Start, danach ist der Dienst inaktiv
        $svc->{runs} = ( $svc->{runs} // 0 ) + 1;
        local $CWD_DIR = '/';
        my ( $o, $k ) = __PACKAGE__->_run_inner( $dev, $svc->{run}, $CTX || { state => {} } );
        my $h = $dev->{hostname} // 'localhost';
        push @{ $svc->{journal} }, ( map {"Oct 20 12:00:00 $h $n\[3001\]: $_"} grep {length} split /\n/, $o // '' ),
            $k ? "Oct 20 12:00:00 $h systemd[1]: $u: Deactivated successfully." : "Oct 20 12:00:00 $h systemd[1]: $u: Main process exited, code=exited, status=1/FAILURE";
        $svc->{active} = JSON::MaybeXS::false() if $svc->{active};
        if ($k) { $svc->{failed} = JSON::MaybeXS::false() if $svc->{failed}; return ( join( "\n", @warn ), 1 ) }
        $svc->{failed} = JSON::MaybeXS::true() unless $svc->{failed};
        return ( join( "\n", @warn, "Job for $u failed because the control process exited with error code.",
            "See \"systemctl status $u\" and \"journalctl -xeu $u\" for details." ), 0 );
    }
    # Geraet mit oneshot_scripts: Type=oneshot mit Shell-Skripten als ExecStart (ohne creates)
    # fuehrt die Skripte als User= der Unit aus; ihr Exit-Status entscheidet, ihre Ausgabe
    # steht im Journal
    if ( $dev->{oneshot_scripts} && !$svc->{creates} && _oneshot( $dev, $n, $svc ) && ( my @steps = _script_steps( $dev, $props ) ) ) {
        my ( @o, $k );
        {
            local $CWD_DIR = '/';
            local $LOGIN_USER = defined $uuser && $uuser ne 'root' ? $uuser : undef;
            local $AS_USER;
            for my $st (@steps) {
                if ( $st->[0] eq '!noexec' ) {    # direkt gestartet ohne Ausfuehrrecht: 203/EXEC wie systemd
                    push @o, "$u: Failed to execute $st->[1]: Permission denied", "$u: Failed at step EXEC spawning $st->[1]: Permission denied";
                    $k = 0;
                    last;
                }
                my ( $o, $kk ) = _script( $dev, _file_text( $dev, $st->[0] ), $CTX || { state => {} }, join( ' ', @$st ), @$st );
                push @o, $o if defined $o && length $o;
                $k = $kk;
                last unless $k;
            }
        }
        my $h = $dev->{hostname} // ( $CTX || {} )->{host} // 'localhost';
        push @{ $svc->{journal} }, ( map {"Oct 20 12:00:00 $h $n\[3001\]: $_"} grep {length} map { split /\n/ } @o ),
            $k ? "Oct 20 12:00:00 $h systemd[1]: $u: Deactivated successfully." : "Oct 20 12:00:00 $h systemd[1]: $u: Main process exited, code=exited, status=1/FAILURE";
        $svc->{active} = JSON::MaybeXS::false() if $svc->{active};
        if ($k) {
            $svc->{runs} = ( $svc->{runs} // 0 ) + 1;
            $svc->{failed} = JSON::MaybeXS::false() if $svc->{failed};
            return ( join( "\n", @warn ), 1 );
        }
        $svc->{failed} = JSON::MaybeXS::true() unless $svc->{failed};
        return ( join( "\n", @warn, "Job for $u failed because the control process exited with error code.",
            "See \"systemctl status $u\" and \"journalctl -xeu $u\" for details." ), 0 );
    }
    if ( _oneshot( $dev, $n, $svc ) ) {    # laeuft einmal durch und ist danach wieder inactive
        $svc->{runs} = ( $svc->{runs} // 0 ) + 1;
        # was ein erfolgreicher Lauf anlegt (creates: { pfad => eintrag })
        $dev->{files}{$_} = Langertha::Holmgang::Sim::Linux::clone_state( $svc->{creates}{$_} ) for sort keys %{ $svc->{creates} || {} };
        $svc->{failed} = JSON::MaybeXS::false() if $svc->{failed};
        $svc->{active} = JSON::MaybeXS::false() if $svc->{active};
        return ( join( "\n", @warn ), 1 );
    }
    my $was = $svc->{active};
    if ( defined( my $e = _svc_hook( $dev, $n, $verb ) ) ) {
        $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1 if $was && $verb =~ /restart/;
        $svc->{active} = JSON::MaybeXS::false() if $svc->{active};
        $svc->{failed} = JSON::MaybeXS::true() unless $svc->{failed};
        $svc->{last_error} = $e;
        return ( join( "\n", @warn, "Job for $n.service failed because the control process exited with error code.",
            "See \"systemctl status $n.service\" and \"journalctl -xeu $n.service\" for details." ), 0 );
    }
    $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1 if $was && $verb =~ /restart/;
    _restart_effect( $dev, $n, $verb );
    _app_event( $dev, $n, $was ? 'restart' : 'start' ) unless $was && $verb !~ /restart/;
    # journal_start: was der Dienst beim (Neu-)Start ins Journal schreibt
    push @{ $svc->{journal} }, @{ $svc->{journal_start} } if ref $svc->{journal_start} eq 'ARRAY' && !( $verb eq 'start' && $was );
    $svc->{active} = JSON::MaybeXS::true() unless $svc->{active};
    $svc->{failed} = JSON::MaybeXS::false() if $svc->{failed};
    # Laufzeitdateien (Socket, PID-Datei) legt der laufende Dienst an — sofern es das Verzeichnis gibt
    for my $rf ( @{ $svc->{runtime_files} || [] } ) {
        ( my $d = $rf->{path} ) =~ s{/[^/]+\z}{};
        next unless _is_dir( $dev, $d ) && !exists $dev->{files}{ $rf->{path} };
        $dev->{files}{ $rf->{path} } = { content => '', owner => $rf->{owner} // $svc->{user} // $uuser // 'root',
            group => $rf->{group} // $ugrp // $svc->{user} // $uuser // 'root',
            mode => $rf->{mode} // '0660', ( $rf->{type} ? ( type => $rf->{type} ) : () ) };
    }
    if ( !$was || $verb =~ /restart/ ) {
        $svc->{_started} = $props if length $ut;    # womit der Prozess laeuft
        _log( $dev, $n, $svc, $was ? ( "systemd[1]: Stopping $u" . _desc($svc) . '...', "systemd[1]: $u: Deactivated successfully." ) : (),
            "systemd[1]: Started $u" . _desc($svc) . '.' );
        # neuer Prozess: neue Haupt-PID (die der Startmeldungen), Startzeit = Zeit der Zeile "Started"
        my $pid = $svc->{_pid} = 50000 + ( $dev->{_tick} // 0 );
        require Time::Local;
        $svc->{_since} = _jtime( $svc->{_log}[-1] );
        # wo der neue Prozess lauscht (wie er die Datei gelesen hat), Zeilen in seinem Log
        $svc->{_listen} = [ _svc_listen( $dev, $n, $svc ) ] if ref $svc->{listen} eq 'HASH';
        _app_log( $dev, $n, $svc, 'start', $svc->{_since} );
        # Startmeldungen des Dienstes (Kolon, duerfen vom Zustand abhaengen)
        _log( $dev, $n, $svc, map { ( $svc->{exec} // $n ) . "[$pid]: " . _render( $_, $CTX ? $CTX->{state} : {} ) =~ s/\s+\z//r }
            @{ $svc->{start_log} || [] } );
    }
    _reopen_logs( $dev, $n ) unless $verb eq 'start' && $was;
    _pg_event( $dev, $n, $verb =~ /restart/ ? 'restart' : $verb ) unless $verb eq 'start' && $was;
    return ( join( "\n", @warn ), 1 );
}

# ExecStart= einer Unit als Shell-Skripte im Zustand: ( [ skript, argumente … ], … ) —
# leer, wenn eine Zeile kein Skript startet (dann wie bisher ohne Ausfuehrung)
sub _script_steps {
    my ( $dev, $props ) = @_;
    my @steps;
    for my $line ( @{ $props->{ExecStart} || [] } ) {
        my @w = split ' ', $line =~ s/\A[-@+!:]+//r;
        my $via = @w > 1 && $w[0] =~ m{\A/(?:usr/)?bin/(?:ba|da)?sh\z} && $w[1] !~ /\A-/ ? shift @w : undef;
        return () unless @w && $w[0] =~ m{\A/} && _shell_script( $dev, $w[0] );
        push @steps, !$via && !( _mode_of( _file_entry( $dev, $w[0] ) ) & 0111 ) ? [ '!noexec', $w[0] ] : \@w;
    }
    return @steps;
}

sub _desc { my ($svc) = @_; return defined $svc->{description} ? " - $svc->{description}" : '' }

# Uhr der Simulation fuer neue Journalzeilen (clock am Geraet, z. B. "Oct 24 09:12")
sub _clock { my ($dev) = @_; return $dev->{clock} // 'Oct 20 09:12' }

# Journalzeilen anhaengen (unter _log: Laufzeitspur, „sonst nichts geaendert" sieht sie nicht)
sub _log {
    my ( $dev, $n, $svc, @lines ) = @_;
    return unless @lines;
    my $host = $CTX && $CTX->{host} ? $CTX->{host} : $dev->{hostname} // 'localhost';
    for my $l (@lines) {
        my $t = ++$dev->{_tick};
        push @{ $svc->{_log} }, sprintf( '%s:%02d %s %s', _clock($dev), 3 + $t % 57, $host, $l );
    }
    return;
}

sub _journal_lines {
    my ( $dev, $n, $svc, $host ) = @_;
    $host //= $dev->{hostname} // 'localhost';
    my $u = _uname($n);
    my @l = ( @{ $svc->{journal} || [] }, @{ $svc->{_log} || [] } );
    # eigene Simulation (nginx): Meldung des letzten gescheiterten Starts bzw. reload
    push @l, map {"Oct 24 09:12:03 $host $n\[2210]: $_"} split /\n/, $svc->{last_error} if defined $svc->{last_error};
    push @l, @{ $dev->{bind}{log} || [] } if $dev->{bind} && $n eq ( $dev->{bind}{service} // 'named' );
    push @l, _ssh_access()->can('journal')->( $dev, $host ) if ( $n eq 'ssh' || $n eq 'sshd' ) && $dev->{ssh_tries};
    if ( $n =~ /\.timer\z/ ) {
        my $i = _timer_info( $dev, $n, $svc );
        push @l, map {"Oct 20 09:00:00 $host systemd[1]: " . _unit_file( $n, $svc ) . ":$_->[0]: Failed to parse calendar specification, ignoring: $_->[1]"} @{ $i->{bad} };
        push @l, "Oct 20 09:00:00 $host systemd[1]: $u: Timer unit lacks value setting. Refusing." unless @{ $i->{cal} } || $i->{other};
    }
    if ( !$svc->{active} && ( $svc->{failed} || _failing_need( $dev, $svc ) ) ) {
        my $bad = _failing_need( $dev, $svc );
        my $c = _clock($dev);
        push @l, @{ $bad->{log} || [] } if $bad;
        push @l, "$c:03 $host systemd[1]: $u: Main process exited, code=exited, status=1/FAILURE",
            "$c:03 $host systemd[1]: $u: Failed with result 'exit-code'.",
            "$c:03 $host systemd[1]: Failed to start $u" . _desc($svc) . '.'
            if $svc->{failed} && !_unit_bad( $n, _unit_props( $svc->{unit_loaded} // _unit_text( $dev, $n, $svc ) ) );
    }
    for my $r ( 1 .. ( $svc->{runs} // 0 ) ) {
        my $d = defined $svc->{description} ? " - $svc->{description}" : '';
        push @l, sprintf( "Oct 20 14:%02d:00 $host systemd[1]: Starting $u$d...", $r ), map( { sprintf "Oct 20 14:%02d:01 %s", $r, $_ } @{ $svc->{run_journal} || [] } ),
            sprintf( "Oct 20 14:%02d:01 $host systemd[1]: $u: Deactivated successfully.", $r ),
            sprintf( "Oct 20 14:%02d:01 $host systemd[1]: Finished $u$d.", $r );
    }
    return @l;
}

sub _journalctl {
    my ( $dev, $av, $ctx ) = @_;
    my $host = $ctx->{host};
    my @a = @$av;
    my ( @units, $n, $grep, $since, $until, $out, $reverse, $file, $boots, $all_units, $kernel );
    my $val = sub { my ($x) = @_; $x =~ /=(.*)\z/s ? $1 : shift(@a) };
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-u' || $x eq '--unit' ) { push @units, _unit( shift(@a) // '' ) }
        elsif ( $x =~ /\A--unit=(.+)\z/ )      { push @units, _unit($1) }
        elsif ( $x eq '-n' || $x eq '--lines' ) { $n = shift @a }
        elsif ( $x =~ /\A(?:-n|--lines=)(\d+)\z/ ) { $n = $1 }
        elsif ( $x eq '-e' || $x eq '--pager-end' ) { $n //= 1000 }
        elsif ( $x eq '-g' || $x eq '--grep' )  { $grep = shift @a }
        elsif ( $x =~ /\A--grep=(.+)\z/ )       { $grep = $1 }
        elsif ( $x =~ /\A(?:-S|--since)(?:=.*)?\z/ ) { $since = $val->($x) }
        elsif ( $x =~ /\A(?:-U|--until)(?:=.*)?\z/ ) { $until = $val->($x) }
        elsif ( $x =~ /\A(?:-o|--output)(?:=.*)?\z/ ) { $out = $val->($x) }
        elsif ( $x =~ /\A--file(?:=.*)?\z/ )   { $file = $val->($x) }
        elsif ( $x eq '-r' || $x eq '--reverse' ) { $reverse = 1 }
        elsif ( $x eq '--list-boots' )          { $boots = 1 }
        elsif ( $x eq '-k' || $x eq '--dmesg' ) { $kernel = 1 }    # Kernel-Meldungen: der Zustand kennt keine (wie dmesg)
        elsif ( $x eq '-p' || $x eq '--priority' || $x eq '-t' || $x eq '--identifier' ) { shift @a }    # Prioritaeten nicht nachgebildet: alles
        elsif ( $x =~ /\A-(?:b|-boot)\z/ ) {    # nachgebildet ist nur der laufende Start (--list-boots: einer)
            return ( "Data from the specified boot ($a[0]) is not available: No such boot ID in journal.", 0 ) if @a && $a[0] =~ /\A-[1-9]\d*\z/;
            shift @a if @a && $a[0] =~ /\A-?\d+\z|\A[0-9a-f]{32}\z/;
        }
        elsif ( $x eq '-f' || $x eq '--follow' ) { push @GAPS, join( ' ', 'journalctl', @$av ); return ( '', 0 ) }
        elsif ( $x eq '--flush' ) { _journal_flush($dev) if _journal_persistent($dev); return ( '', 1 ) }
        elsif ( $x =~ /\A--(?:rotate|sync|relinquish-var)\z/ ) { return ( '', 1 ) }
        elsif ( $x eq '--verify' ) {
            return ( join( "\n", map {"PASS: $_"} grep {/\.journal~?\z/} _under( $dev, '/var/log/journal' ), _under( $dev, '/run/log/journal' ) ), 1 );
        }
        elsif ( $x =~ /\A-\w*u\z/ ) { push @units, _unit( shift(@a) // '' ) }    # -xeu dienst
        elsif ( $x eq '--disk-usage' ) {
            my $t = 0;
            $t += _file_size( _file_entry( $dev, $_ ) ) for _under( $dev, '/var/log/journal' ), _under( $dev, '/run/log/journal' );
            return ( 'Archived and active journals take up ' . _human($t) . ' in the file system.', 1 );
        }
        elsif ( $x =~ /\A--vacuum-(size|time|files)=(.+)\z/ ) {
            my ( $kind, $v ) = ( $1, $2 );
            my $freed;
            if ( $kind eq 'size' ) { $freed = _journal_vacuum( $dev, size => _bytes($v) ) }
            elsif ( $kind eq 'time' ) {
                my $age = _secs($v) // return ( "Failed to parse timespan '$v'.", 0 );
                $freed = _journal_vacuum( $dev, age => $age );
            }
            else { push @GAPS, "journalctl --vacuum-files=$v"; return ( '', 0 ) }
            return ( 'Vacuuming done, freed ' . _human($freed) . ' of archived journals from /var/log/journal.', 1 );
        }
        elsif ( $x =~ /\A-(?:x|-no-pager|-no-hostname|-quiet|q|-catalog|a|-all|-merge|m|-system|-utc|-no-full|l|-full)\z/ ) { }
        elsif ( $x =~ /\A(?:-F|--field|--facility|--cursor|--after-cursor|--cursor-file|-D|--directory|--header|--namespace|-M|--machine|--output-fields|--show-cursor|--user|--user-unit|-I|-N|--fields)(?:=.*)?\z/ ) {
            push @GAPS, join( ' ', 'journalctl', @$av );    # echte Optionen ohne Nachbildung
            return ( '', 0 );
        }
        elsif ( $x =~ /\A--/ ) { ( my $o = $x ) =~ s/=.*//s; return ( "journalctl: unrecognized option '$o'", 0 ) }
        elsif ( $x =~ /\A-(.)/ ) { return ( "journalctl: invalid option -- '$1'", 0 ) }
        else { push @GAPS, join( ' ', 'journalctl', @$av ); return ( '', 0 ) }    # Treffer wie _SYSTEMD_UNIT=…
    }
    return ( '-- No entries --', 1 ) if $kernel;
    # Zeilen mit Zeitpunkt: [ epoche, text ]
    my @l;
    if ( defined $file ) {
        return ( "Failed to open journal file $file: No such file or directory", 0 ) unless _file_entry( $dev, $file );
        @l = grep { $_->[2] eq $file } _journal_file_lines( $dev, $host );
    }
    elsif (@units) {
        for my $u (@units) {
            my $svc = ( $dev->{services} || {} )->{$u} or next;
            push @l, map { [ _jtime($_), $_ ] } _journal_lines( $dev, $u, $svc, $host );
        }
    }
    else {
        @l = ( ( map { my $s = $_; map { [ _jtime($_), $_ ] } _journal_lines( $dev, $s, $dev->{services}{$s}, $host ) } sort keys %{ $dev->{services} || {} } ),
            _journal_file_lines( $dev, $host ) );
    }
    @l = sort { $a->[0] <=> $b->[0] } @l;
    if ($boots) {
        my @all = sort { $a->[0] <=> $b->[0] } ( _journal_file_lines( $dev, $host ),
            map { my $s = $_; map { [ _jtime($_), $_ ] } _journal_lines( $dev, $s, $dev->{services}{$s}, $host ) } keys %{ $dev->{services} || {} } );
        return ( 'No boots found.', 0 ) unless @all;
        my $f = Langertha::Holmgang::Sim::Linux::Calendar::format_local( $all[0][0] );
        my $t = Langertha::Holmgang::Sim::Linux::Calendar::format_local( _dev_now($dev) );
        return ( " 0 7f3e9c2b5a1d4e8f9b0c6a2d4e8f1a3c $f\x{2014}$t", 1 );
    }
    for my $b ( [ $since, 1 ], [ $until, 0 ] ) {
        next unless defined $b->[0];
        my $t = _parse_since( $b->[0], _dev_now($dev) ) // return ( "Failed to parse timestamp: $b->[0]", 0 );
        @l = grep { $b->[1] ? $_->[0] >= $t : $_->[0] <= $t } @l;
    }
    my @txt = map { $_->[1] } @l;
    if ( defined $grep ) {
        my $re = eval { qr/$grep/i } or return ( "Failed to compile pattern \"$grep\"", 0 );
        @txt = grep { $_ =~ $re } @txt;
    }
    @txt = @txt[ ( @txt > $n ? @txt - $n : 0 ) .. $#txt ] if defined $n && $n =~ /\A\d+\z/;
    @txt = reverse @txt if $reverse;
    if ( defined $out ) {
        if ( $out eq 'short-iso' || $out eq 'short-iso-precise' ) {
            @txt = map {
                my $l = $_;
                my $t = _jtime($l);
                my $off = Langertha::Holmgang::Sim::Linux::Calendar::offset($t);
                my @g = gmtime( $t + $off );
                $l =~ s/\A\w{3}\s+\d+ \d\d:\d\d:\d\d/sprintf( '%04d-%02d-%02dT%02d:%02d:%02d%s%02d%02d', $g[5] + 1900, $g[4] + 1, $g[3], $g[2], $g[1], $g[0], '+', $off \/ 3600, 0 )/e;
                $l
            } @txt;
        }
        elsif ( $out eq 'cat' ) { s/\A\w{3}\s+\d+ \d\d:\d\d:\d\d \S+ [^:]+: // for @txt }
        elsif ( $out !~ /\A(?:short|short-full|short-precise|with-unit)\z/ ) { push @GAPS, "journalctl -o $out"; return ( '', 0 ) }
    }
    return ( '-- No entries --', 1 ) unless @txt;
    return ( join( "\n", @txt ), 1 );
}

# "Oct 20 14:00:01 host …" -> Epoche (Ortszeit, Jahr 2026)
sub _jtime {
    my ($l) = @_;
    my ( $mon, $d, $h, $mi, $s ) = ( $l // '' ) =~ /\A(\w{3})\s+(\d+) (\d\d):(\d\d):(\d\d)/ or return _sim_now();
    my $lt = Time::Local::timegm( $s, $mi, $h, $d, $MON{$mon} // 9, 2026 );
    return $lt - Langertha::Holmgang::Sim::Linux::Calendar::offset( $lt - 3600 );
}

# --since/--until: 2026-10-01[ 12:00[:00]], 06:00[:00] (heute), today, yesterday, now, -2d,
# "2 days ago", "1 hour ago"; $now: die Uhr des Geraets (Vorgabe: die der Simulation)
sub _parse_since {
    my ( $v, $now ) = @_;
    require Time::Local;
    $now //= _sim_now();
    my $loc = sub { my $lt = Time::Local::timegm(@_); $lt - Langertha::Holmgang::Sim::Linux::Calendar::offset( $lt - 3600 ) };
    my @g = gmtime( $now + Langertha::Holmgang::Sim::Linux::Calendar::offset($now) );
    return $now if $v eq 'now';
    return $loc->( 0, 0, 0, $g[3], $g[4], $g[5] + 1900 ) if $v eq 'today';
    return $loc->( 0, 0, 0, $g[3], $g[4], $g[5] + 1900 ) - 86400 if $v eq 'yesterday';
    return $loc->( 0, 0, 0, $g[3], $g[4], $g[5] + 1900 ) + 86400 if $v eq 'tomorrow';
    if ( $v =~ /\A(\d{4})-(\d\d)-(\d\d)(?:[ T](\d\d):(\d\d)(?::(\d\d))?)?\z/ ) { return $loc->( $6 // 0, $5 // 0, $4 // 0, $3, $2 - 1, $1 ) }
    if ( $v =~ /\A(\d\d?):(\d\d)(?::(\d\d))?\z/ ) { return $loc->( $3 // 0, $2, $1, $g[3], $g[4], $g[5] + 1900 ) }
    if ( $v =~ /\A-(\d+)\s*(\w+)\z/ || $v =~ /\A(\d+)\s*(\w+?)\s+ago\z/ ) { my $s = _secs("$1$2") // _secs("$1 $2"); return defined $s ? $now - $s : undef }
    return undef;
}

# Je Journal-Datei eine unauffaellige Zeile zu ihrer Zeit (damit das Journal so weit
# zurueckreicht wie seine Dateien): [ epoche, text, datei ]
sub _journal_file_lines {
    my ( $dev, $host ) = @_;
    $host //= $dev->{hostname} // 'localhost';
    my @msg = ( 'CRON[%d]: pam_unix(cron:session): session closed for user root', 'systemd[1]: Starting systemd-tmpfiles-clean.service - Cleanup of Temporary Directories...',
        'systemd[1]: logrotate.service: Deactivated successfully.', 'sshd[%d]: Received disconnect from 10.0.0.5 port 52114:11: disconnected by user' );
    my @r;
    my $i = 0;
    for my $p ( grep {/\.journal~?\z/} _under( $dev, '/var/log/journal' ), _under( $dev, '/run/log/journal' ) ) {
        my $fe = _file_entry( $dev, $p );
        my $lt = defined $fe->{mtime} ? _mtime($fe) : _sim_now() + Langertha::Holmgang::Sim::Linux::Calendar::offset( _sim_now() );    # Ortszeit
        my @g = gmtime $lt;
        my $stamp = sprintf '%s %2d %02d:%02d:%02d', (qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[ $g[4] ], $g[3], $g[2], $g[1], $g[0];
        my $m = $msg[ $i++ % @msg ];
        $m = sprintf $m, 1000 + 37 * $i if $m =~ /%d/;
        push @r, [ $lt - Langertha::Holmgang::Sim::Linux::Calendar::offset( $lt - 3600 ), "$stamp $host $m", $p ];
    }
    return @r;
}

# Speichert journald dauerhaft? (Storage=persistent, oder auto mit /var/log/journal)
sub _journal_persistent {
    my ($dev) = @_;
    my $svc = ( $dev->{services} || {} )->{'systemd-journald'} || {};
    my $t = $svc->{running} // _file_text( $dev, '/etc/systemd/journald.conf' ) // '';
    my ($st) = $t =~ /^\s*Storage\s*=\s*(\S+)\s*$/m;
    $st //= 'auto';
    return 1 if $st eq 'persistent';
    return $st eq 'auto' && _is_dir( $dev, '/var/log/journal' ) ? 1 : 0;
}

# Laufzeit-Journal (/run/log/journal/<id>) nach /var/log/journal/<id> uebernehmen
sub _journal_flush {
    my ($dev) = @_;
    my @run = grep {/\.journal\z/} _under( $dev, '/run/log/journal' );
    my ($id) = map { m{\A/run/log/journal/([0-9a-f]{32})/} ? $1 : () } @run;
    ($id) = map { m{\A/var/log/journal/([0-9a-f]{32})/} ? $1 : () } _under( $dev, '/var/log/journal' ) unless defined $id;
    $id //= '3b1f5c7e9a2d4c6e8f0a1b3d5e7f9a1c';
    $dev->{dirs}{'/var/log/journal'} //= {} unless _is_dir( $dev, '/var/log/journal' );
    my $dst = "/var/log/journal/$id/system.journal";
    if ( !_file_entry( $dev, $dst ) ) {
        my $size = 0;
        $size += _file_size( _file_entry( $dev, $_ ) ) for @run;
        $dev->{files}{$dst} = { size => _human( $size || 8 * 1024 * 1024 ), owner => 'root', group => 'systemd-journal', mode => '0640',
            content => '', open_by => 'systemd-journald', mtime => 'Oct 20 14:00' };
    }
    delete $dev->{files}{$_} for @run;
    return;
}

sub _unit_changed {
    my ( $dev, $n, $svc ) = @_;
    return 0 unless defined $svc->{unit_loaded};
    my $now = _unit_text( $dev, $n, $svc );
    return defined $now && $now ne $svc->{unit_loaded} ? 1 : 0;
}

# Naechster Ablauf eines Timers (Epoche) oder undef
sub _timer_next {
    my ( $dev, $n, $svc ) = @_;
    my $i = _timer_info( $dev, $n, $svc );
    my ($t) = sort { $a <=> $b } grep {defined} map { Langertha::Holmgang::Sim::Linux::Calendar::next_elapse( $_, _sim_now() ) } @{ $i->{cal} };
    return $t;
}

# "Tue 2026-10-20 02:00:04 CEST" -> Epoche
sub _parse_stamp {
    my ($s) = @_;
    my ( $y, $m, $d, $h, $mi, $se, $tz ) = ( $s // '' ) =~ /(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d) (CEST|CET|UTC)/ or return undef;
    require Time::Local;
    return Time::Local::timegm( $se, $mi, $h, $d, $m - 1, $y ) - { CEST => 7200, CET => 3600, UTC => 0 }->{$tz};
}

sub _systemctl_status {
    my ( $dev, $n, $svc, $host ) = @_;
    my $u = _uname($n);
    my $uf = _unit_file( $n, $svc );
    my $timer = $n =~ /\.timer\z/;
    my $en = _static( $dev, $n, $svc ) ? 'static' : ( $svc->{enabled} // 1 ) ? 'enabled' : 'disabled';
    my $bad = $timer && do { my $i = _timer_info( $dev, $n, $svc ); !@{ $i->{cal} } && !$i->{other} };
    my $since = _svc_since($svc) // _parse_stamp($BOOT_STAMP);
    my $act = $svc->{active} ? ( $timer ? 'active (waiting)' : 'active (running)' ) . ' since '
            . Langertha::Holmgang::Sim::Linux::Calendar::format_local($since) . '; ' . _ago( $dev, $since )
        : $svc->{failed} ? "failed (Result: exit-code) since Tue 2026-10-20 09:12:03 CEST; 4h 47min ago"
        : $svc->{runs} ? 'inactive (dead) since Tue 2026-10-20 14:0' . $svc->{runs} . ':01 CEST; 1min ago'
        : 'inactive (dead)';
    my $head = ( $svc->{active} ? '●' : $svc->{failed} ? '×' : '○' ) . " $u" . ( defined $svc->{description} && !$svc->{masked} ? " - $svc->{description}" : '' );
    $bad ||= _unit_bad( $n, _unit_props( $svc->{unit_loaded} // _unit_text( $dev, $n, $svc ) ) );
    my @l = ( $head, $svc->{masked} ? "     Loaded: masked (Reason: Unit $u is masked.)"
        : $bad ? "     Loaded: bad-setting (Reason: Unit $u has a bad unit file setting.)"
        : "     Loaded: loaded ($uf; $en; preset: enabled)" );
    my @d = _dropins( $dev, $n );
    if (@d) {
        my %dir;
        for (@d) { my ( $dd, $f ) = m{\A(.*)/([^/]+)\z}; push @{ $dir{$dd} }, $f }
        my $first = 1;
        for my $dd ( sort keys %dir ) {
            push @l, ( $first ? '    Drop-In: ' : '             ' ) . $dd, '             └─' . join( ', ', @{ $dir{$dd} } );
            $first = 0;
        }
    }
    push @l, "     Warning: The unit file, source configuration file or drop-ins of $u changed on disk. Run 'systemctl daemon-reload' to reload units."
        if _unit_changed( $dev, $n, $svc );
    push @l, "     Active: $act";
    if ($timer) {
        my $next = $svc->{active} ? _timer_next( $dev, $n, $svc ) : undef;
        push @l, '    Trigger: ' . ( defined $next ? Langertha::Holmgang::Sim::Linux::Calendar::format_local($next) . '; '
            . Langertha::Holmgang::Sim::Linux::Calendar::left( $next - _sim_now() ) . ' left' : 'n/a' );
        push @l, '   Triggers: ● ' . _timer_info( $dev, $n, $svc )->{activates};
    }
    push @l, '   Main PID: ' . _main_pid( $dev, $n ) . ' (' . ( $svc->{exec} // $n ) . ')' if $svc->{active} && !$timer;
    my @j = _journal_lines( $dev, $n, $svc, $host );
    push @l, '', @j[ ( @j > 10 ? @j - 10 : 0 ) .. $#j ] if @j;
    return @l;
}

# Ein Dienst oeffnet seine Logdateien neu (Neustart, reload): schrieb er nach einer
# Rotation noch in die umbenannte Datei (opened_as), schreibt er jetzt wieder in die
# Originaldatei; fehlt sie, legt er sie an.
sub _reopen_logs {
    my ( $dev, $n ) = @_;
    my $files = $dev->{files} || {};
    for my $p ( sort grep { ref $files->{$_} eq 'HASH' && ( $files->{$_}{open_by} // '' ) eq $n && defined $files->{$_}{opened_as} } keys %$files ) {
        my $e = $files->{$p};
        my $orig = delete $e->{opened_as};
        delete $e->{open_by};
        if ( ref $files->{$orig} eq 'HASH' ) { $files->{$orig}{open_by} = $n }
        elsif ( !exists $files->{$orig} ) {
            $files->{$orig} = { content => '', size => '0', mode => $e->{mode} // '0644', owner => $e->{owner} // 'root',
                group => $e->{group} // 'root', open_by => $n, mtime => 'Oct 20 14:00' };
        }
    }
    return;
}

# systemctl list-timers [--all]
sub _list_timers {
    my ( $dev, $all, $pat ) = @_;    # $pat: Muster hinter dem Verb (export*)
    require Langertha::Holmgang::Sim::Linux::Calendar;
    my $svcs = $dev->{services} || {};
    my @rows;
    for my $n ( sort grep {/\.timer\z/} keys %$svcs ) {
        my $svc = $svcs->{$n};
        next unless $svc->{active} || $all;
        next if $pat && @$pat && !grep { $n =~ _unit_glob($_) } @$pat;
        my $next = $svc->{active} ? _timer_next( $dev, $n, $svc ) : undef;
        my $last = _parse_stamp( $svc->{last} );
        push @rows, [ $next // 9e12,
            defined $next ? Langertha::Holmgang::Sim::Linux::Calendar::format_local($next) : '-',
            defined $next ? Langertha::Holmgang::Sim::Linux::Calendar::left( $next - _sim_now() ) . ' left' : '-',
            defined $last ? $svc->{last} : '-',
            defined $last ? Langertha::Holmgang::Sim::Linux::Calendar::left( _sim_now() - $last ) . ' ago' : '-',
            $n, _timer_info( $dev, $n, $svc )->{activates} ];
    }
    @rows = sort { $a->[0] <=> $b->[0] || $a->[5] cmp $b->[5] } @rows;
    my @w = ( 0, 4, 4, 4, 6, 4, 9 );
    for my $r (@rows) { $w[$_] < length $r->[$_] and $w[$_] = length $r->[$_] for 1 .. 6 }
    my $fmt = join( ' ', map {"%-$w[$_]s"} 1 .. 6 );
    my @l = ( sprintf( $fmt, qw( NEXT LEFT LAST PASSED UNIT ACTIVATES ) ) =~ s/\s+\z//r );
    push @l, sprintf( $fmt, @{$_}[ 1 .. 6 ] ) =~ s/\s+\z//r for @rows;
    push @l, '', scalar(@rows) . ' timers listed.';
    push @l, 'Pass --all to see loaded but inactive timers, too.' unless $all;
    return join "\n", @l;
}

# Zeitspanne wie systemd (format_timespan): 1800 -> "30min", 90 -> "1min 30s"
sub _timespan {
    my ($s) = @_;
    return '0' unless $s;
    my @p;
    for my $u ( [ 'w', 604800 ], [ 'd', 86400 ], [ 'h', 3600 ], [ 'min', 60 ], [ 's', 1 ] ) {
        next if $s < $u->[1];
        my $n = int( $s / $u->[1] );
        $s -= $n * $u->[1];
        push @p, "$n$u->[0]";
    }
    return join ' ', @p;
}

# ExecStart=… -> Form von systemctl show
sub _exec_prop {
    my ($cmd) = @_;
    $cmd =~ s/\A[-\@:+!]+//;
    my ($path) = split /\s+/, $cmd;
    return "{ path=$path ; argv[]=$cmd ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }";
}

# systemctl show UNIT… [-p A,B | --property=A,B]… [--value]
sub _systemctl_show {
    my ( $dev, $av ) = @_;
    require Langertha::Holmgang::Sim::Linux::Calendar;
    my ( @want, @units, $value );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-p' || $x eq '--property' ) { push @want, split /,/, shift(@a) // '' }
        elsif ( $x =~ /\A--property=(.*)\z/ )      { push @want, split /,/, $1 }
        elsif ( $x =~ /\A-p(.+)\z/ )               { push @want, split /,/, $1 }
        elsif ( $x eq '--value' )                  { $value = 1 }
        elsif ( $x =~ /\A-/ || $x eq 'show' )      { }
        else                                       { push @units, _unit($x) }
    }
    return ( 'Too few arguments.', 0 ) unless @units;    # ohne Unit: Eigenschaften des Managers (nicht nachgebildet)
    my @blocks;
    for my $n (@units) {
        my $svc = ( $dev->{services} || {} )->{$n} // _load_unit( $dev, $n, 1 );
        my $u = _uname($n);
        my %p = ( Id => $u, Names => $u );
        if ( !$svc ) {
            %p = ( %p, LoadState => 'not-found', ActiveState => 'inactive', SubState => 'dead', UnitFileState => '', Description => $u );
        }
        else {
            my $t = _unit_loaded_text( $dev, $n, $svc ) // '';
            my $timer = $n =~ /\.timer\z/;
            my $i = $timer ? _timer_info( $dev, $n, $svc ) : undef;
            my $prop = sub { my ($k) = @_; my ($v) = $t =~ /^\s*\Q$k\E\s*=\s*(.*?)\s*$/m; $v };
            $p{Description} = $svc->{description} // $prop->('Description') // $u;
            $p{LoadState} = $svc->{masked} ? 'masked' : $timer && !@{ $i->{cal} } && !$i->{other} ? 'bad-setting' : 'loaded';
            $p{ActiveState} = $svc->{active} ? 'active' : $svc->{failed} ? 'failed' : 'inactive';
            $p{SubState} = $svc->{active} ? ( $timer ? 'waiting' : 'running' ) : $svc->{failed} ? 'failed' : 'dead';
            $p{UnitFileState} = $svc->{masked} ? 'masked' : _static( $dev, $n, $svc ) ? 'static' : ( $svc->{enabled} // 1 ) ? 'enabled' : 'disabled';
            $p{FragmentPath} = _unit_file( $n, $svc );
            if ($timer) {
                my $next = $svc->{active} ? _timer_next( $dev, $n, $svc ) : undef;
                $p{TimersCalendar} = join "\n", map {
                    my $ne = Langertha::Holmgang::Sim::Linux::Calendar::next_elapse( $_, _sim_now() );
                    "{ OnCalendar=$_->{normalized} ; next_elapse=" . ( defined $ne ? Langertha::Holmgang::Sim::Linux::Calendar::format_local($ne) : 'n/a' ) . ' }'
                } @{ $i->{cal} };
                $p{NextElapseUSecRealtime} = defined $next ? Langertha::Holmgang::Sim::Linux::Calendar::format_local($next) : '';
                $p{LastTriggerUSec} = defined _parse_stamp( $svc->{last} ) ? $svc->{last} : '';
                $p{Persistent} = $i->{persistent} ? 'yes' : 'no';
                $p{AccuracyUSec} = _timespan( _secs( $prop->('AccuracySec') // '1min' ) // 60 );
                $p{RandomizedDelayUSec} = _timespan( _secs( $prop->('RandomizedDelaySec') // 0 ) // 0 );
                $p{Unit} = $i->{activates};
            }
            else {
                # wirksame Werte der geladenen Fassung samt Drop-ins (letzte Zuweisung gilt)
                my $up = _unit_props($t);
                my %extra = %$up;
                delete @extra{qw( ExecStart ExecStartPre ExecStartPost ExecReload EnvironmentFile Environment )};
                %p = ( %extra, %p );
                $p{Type} = $up->{Type} // 'simple';
                $p{Restart} = $up->{Restart} // 'no';
                $p{User} = $up->{User} // $svc->{user} // '';
                $p{Group} = $up->{Group} // '';
                $p{WorkingDirectory} = $up->{WorkingDirectory} // '';
                $p{ExecStart} = join "\n", map { _exec_prop($_) } @{ $up->{ExecStart} || [] };
                $p{Environment} = $up->{Environment} ? join( ' ', map {"$_=$up->{Environment}{$_}"} sort keys %{ $up->{Environment} } ) : '';
                $p{EnvironmentFiles} = join ' ', map { s/\A-//r . ( /\A-/ ? ' (ignore_errors=yes)' : ' (ignore_errors=no)' ) } @{ $up->{EnvironmentFile} || [] };
                ( $p{LimitNOFILE}, $p{LimitNOFILESoft} ) = ( '524288', '1024' );
                if ( defined( my $l = $up->{LimitNOFILE} ) ) {
                    ( $p{LimitNOFILESoft}, $p{LimitNOFILE} ) = $l =~ /\A(\d+):(\d+)\z/ ? ( $1, $2 ) : ( $l, $l );
                }
                $p{MainPID} = _main_pid( $dev, $n );
                $p{ExecMainPID} = $p{MainPID};
                # Startzeit des laufenden Prozesses; NRestarts zaehlt wie systemd nur
                # automatische Neustarts (Restart= nach einem Signal, _signal)
                my $st = $svc->{active} ? _svc_since($svc) // _parse_stamp($BOOT_STAMP) : _svc_since($svc);
                $p{ExecMainStartTimestamp} = $p{ActiveEnterTimestamp} = defined $st ? Langertha::Holmgang::Sim::Linux::Calendar::format_local($st) : '';
                $p{NRestarts} = $svc->{_nrestarts} // 0;
                $p{LoadState} = 'bad-setting' if !$svc->{masked} && _unit_bad( $n, $up );
                $p{DropInPaths} = join ' ', _dropins( $dev, $n );
                $p{NeedDaemonReload} = _unit_changed( $dev, $n, $svc ) ? 'yes' : 'no';
                $p{CanReload} = $n ne 'systemd-journald' && ( !exists $svc->{reload} || $svc->{reload} ) && $t =~ /^\s*ExecReload\s*=/m ? 'yes' : 'no';
            }
        }
        # Reihenfolge wie systemctl show (systemd 257); unbekannte Eigenschaften gibt es nicht aus
        my @order = qw( Unit TimersCalendar NextElapseUSecRealtime LastTriggerUSec AccuracyUSec RandomizedDelayUSec Persistent
            Type Restart NRestarts MainPID ExecMainStartTimestamp ExecMainPID ExecStart Environment EnvironmentFiles WorkingDirectory
            LimitNOFILE LimitNOFILESoft Id Names Description LoadState ActiveState SubState ActiveEnterTimestamp FragmentPath DropInPaths UnitFileState NeedDaemonReload CanReload User Group );
        my %known = map { $_ => 1 } @order;
        push @order, sort grep { !$known{$_} } keys %p;
        my %w = map { $_ => 1 } @want;
        my @keys = grep { exists $p{$_} && ( !@want || $w{$_} ) } @order;
        my @l;
        for my $k (@keys) {
            my @v = split /\n/, $p{$k} // '', -1;
            @v = ('') unless @v;
            push @l, map { $value ? $_ : "$k=$_" } @v;
        }
        push @blocks, join "\n", @l;
    }
    return ( join( "\n\n", @blocks ), 1 );
}

# --- Dienste ---------------------------------------------------------------------------

sub _unit { my ($n) = @_; $n =~ s/\.service\z//; return $n }

sub _restart_effect {
    my ( $dev, $name, $verb ) = @_;
    my $svc = $dev->{services}{$name};
    if ( $name =~ /\Awg-quick\@(wg\d+)\z/ && $verb ne 'reload' ) {
        # start/restart wie die Unit: wg-quick down (falls oben), dann wg-quick up
        my $n  = $1;
        my $up = ( ( ( $dev->{interfaces} || {} )->{$n} || {} )->{state} // 'DOWN' ) ne 'DOWN';
        if ( $verb eq 'start' && $up ) {
            return if $svc && $svc->{active};
            # von Hand hochgefahren: die Unit scheitert an der vorhandenen Schnittstelle
            $svc->{failed} = JSON::MaybeXS::true() if $svc;
            $svc->{journal} = [ @{ $svc->{journal} || [] }, "Oct 20 09:12:03 wg-quick[4711]: wg-quick: `$n' already exists" ] if $svc;
            die "Job for $name.service failed because the control process exited with error code.\n"
                . "See \"systemctl status $name.service\" and \"journalctl -xeu $name.service\" for details.\n";
        }
        my $copy = Langertha::Holmgang::Sim::Linux::clone_state($dev);
        eval { _wg_down( $copy, $n ) if $up; 1 } or do { my $e = $@; die "Job for $name.service failed.\n$e" };
        my $down = Langertha::Holmgang::Sim::Linux::clone_state($copy);
        if ( !eval { _wg_up( $copy, $n ); 1 } ) {
            my $e = $@;
            %$dev = %$down;
            my $s = $dev->{services}{$name} //= {};
            $s->{active} = JSON::MaybeXS::false() if $s->{active};
            $s->{failed} = JSON::MaybeXS::true();
            $s->{journal} = [ @{ $s->{journal} || [] }, map {"Oct 20 09:12:03 wg-quick[4711]: $_"} split /\n/, $e ];
            die "Job for $name.service failed because the control process exited with error code.\n"
                . "See \"systemctl status $name.service\" and \"journalctl -xeu $name.service\" for details.\n";
        }
        my $s = $copy->{services}{$name};
        if ($s) { $s->{active} = JSON::MaybeXS::true(); $s->{failed} = JSON::MaybeXS::false() if $s->{failed} }
        %$dev = %$copy;
        return;
    }
    if ( $name =~ /\Awg-quick\@(wg\d+)\z/ ) {
        my $n = $1;
        my $t = _file_text( $dev, "/etc/wireguard/$n.conf" );
        if ( defined $t ) {
            my $old = $dev->{wg}{$n} || {};
            my $new = _wg_parse( $t, $old );
            if ( $verb eq 'reload' ) {    # wg syncconf <(wg-quick strip): nur Peers und Port
                $new->{$_} = $old->{$_} for grep { exists $old->{$_} } qw( address mtu );
                delete $new->{mtu} unless exists $old->{mtu};
                delete $new->{address} unless exists $old->{address};
            }
            elsif ( defined $new->{mtu} && $dev->{interfaces}{$n} ) {
                $dev->{interfaces}{$n}{mtu} = $new->{mtu};
            }
            $dev->{wg}{$n} = $new;
        }
    }
    if ( $name eq 'nftables' && ref $dev->{files} eq 'HASH' && exists $dev->{files}{'/etc/nftables.conf'} ) {
        my ( $o, $ok ) = _nft_load( $dev, _file_text( $dev, '/etc/nftables.conf' ), '/etc/nftables.conf' );
        die "Job for nftables.service failed because the control process exited with error code.\n$o\n" unless $ok;
    }
    if ( ( $name eq 'ssh' || $name eq 'sshd' ) && _sshd_sim()->can('active')->($dev) ) {
        _sshd_sim()->can('load')->( $dev, $name, $verb, $CTX ? $CTX->{host} : undef );
        _ssh_access()->can('loaded')->($dev);    # was sshd jetzt geladen hat (Match, AuthorizedKeysFile …)
    }
    if ( $name eq 'systemd-journald' && $verb ne 'reload' ) {
        my $t = $svc && defined $svc->{config} ? _file_text( $dev, $svc->{config} ) : _file_text( $dev, '/etc/systemd/journald.conf' );
        if ( defined $t && $t =~ /^\s*SystemMaxUse\s*=\s*(\S+)/m ) { _journal_vacuum( $dev, size => _bytes($1) ) }
        if ( defined $t && $t =~ /^\s*MaxRetentionSec\s*=\s*(\S+)/m && defined( my $age = _secs($1) ) ) { _journal_vacuum( $dev, age => $age ) }
        # dauerhaft (Storage=persistent, oder auto mit /var/log/journal): legt das Verzeichnis
        # an und uebernimmt das Laufzeit-Journal aus /run/log/journal
        my ($st) = ( $t // '' ) =~ /^\s*Storage\s*=\s*(\S+)\s*$/m;
        _journal_flush($dev) if ( $st // 'auto' ) eq 'persistent' || ( $st // 'auto' ) eq 'auto' && _is_dir( $dev, '/var/log/journal' );
    }
    if ( $dev->{bind} && $name eq ( $dev->{bind}{service} // 'named' ) && !( $verb eq 'start' && $svc->{active} ) ) {
        _part('Dns');
        Langertha::Holmgang::Sim::Linux::Dns::service_event( $dev, $verb, $CTX || { state => {} } );
    }
    if ( $dev->{postfix} && $name eq 'postfix' && !( $verb eq 'start' && $svc->{active} ) ) {
        _part('Postfix');
        Langertha::Holmgang::Sim::Linux::Postfix::service_event( $dev, $verb );
    }
    # dnsmasq & Co.: reload (SIGHUP) liest nur Hosts-Dateien neu, nicht die
    # Konfiguration — die wirkt erst nach restart. Dienste mit reload_config
    # (gunicorn, prometheus, …) lesen sie auch beim reload.
    # Mehrere Dateien (config: [ … ]): running ist { pfad => text }; reload_config
    # true liest alle, eine Liste nur diese (z. B. prometheus.yml, nicht die
    # Startoptionen in /etc/default). Mit config_check prueft der Dienst vorher;
    # beim reload bleibt bei einem Fehler alles, wie es lief (Fehler im Journal).
    if ( ref $svc->{config} eq 'ARRAY' ) {
        my $rc = $svc->{reload_config};
        return if $verb eq 'reload' && !$rc;
        my @paths = grep { my $p = $_; $verb ne 'reload' || ref $rc ne 'ARRAY' || grep { $_ eq $p } @$rc } @{ $svc->{config} };
        my ( $err, $extra ) = _config_check( $dev, $svc );
        if (@$err) {
            _log( $dev, $name, $svc, @$err );
            return;
        }
        my %run = ref $svc->{running} eq 'HASH' ? %{ $svc->{running} } : ();
        for my $p (@paths) { my $t = _file_text( $dev, $p ); if ( defined $t ) { $run{$p} = $t } else { delete $run{$p} } }
        # Dateien, die die Hauptdatei nachlaedt (Regeldateien), kommen mit ihr neu
        if ( defined $svc->{config_main} ? grep { $_ eq $svc->{config_main} } @paths : 1 ) {
            my %cfg = map { $_ => 1 } @{ $svc->{config} };
            delete @run{ grep { !$cfg{$_} } keys %run };
            %run = ( %run, %$extra );
        }
        $svc->{running} = \%run;
        return;
    }
    if ( defined $svc->{config} && ( $verb ne 'reload' || $svc->{reload_config} ) ) {
        my $t = _file_text( $dev, $svc->{config} );
        die "Job for $name.service failed because the control process exited with error code.\n"
            . "See \"systemctl status $name.service\" and \"journalctl -xeu $name.service\" for details.\n"
            unless defined $t;
        $svc->{running} = $t;
    }
    return;
}

# Muster einer Unit (Shell-Glob) als regulaerer Ausdruck; ohne Endung passt es
# auch auf NAME.service (systemctl status 'billing*')
sub _unit_glob {
    my ($g) = @_;
    ( my $r = quotemeta $g ) =~ s/\\\*/.*/g;
    $r =~ s/\\\?/./g;
    $r =~ s/\\\[/[/g;
    $r =~ s/\\\]/]/g;
    return qr/\A$r(?:\.service)?\z/;
}

# systemctl list-unit-files: UNIT FILE, STATE, VENDOR PRESET (systemd 252)
sub _list_unit_files {
    my ( $dev, $names ) = @_;
    my $svcs = $dev->{services} || {};
    my @r = map {
        my $v = $svcs->{$_};
        [ _uname($_), $v->{masked} ? 'masked' : _symlinked( $dev, $_, $v ) ? 'enabled' : _static( $dev, $_, $v ) ? 'static' : 'disabled' ]    # wie is-enabled
    } @$names;
    my ( $w1, $w2 ) = ( length 'UNIT FILE', length 'STATE' );
    for (@r) { $w1 = length $_->[0] if length $_->[0] > $w1; $w2 = length $_->[1] if length $_->[1] > $w2 }
    return join "\n", sprintf( '%-*s %-*s %s', $w1, 'UNIT FILE', $w2, 'STATE', 'VENDOR PRESET' ),
        ( map { sprintf( '%-*s %-*s %s', $w1, $_->[0], $w2, $_->[1], 'enabled' ) } @r ), '', scalar(@r) . ' unit files listed.';
}

sub _systemctl {
    my ( $dev, $av, $ctx ) = @_;
    {    # systemctl [-p A] show …: erstes Wort ohne Option (Werte von -p uebersprungen)
        my @x = @$av;
        while (@x) {
            my $y = shift @x;
            if ( $y eq '-p' || $y eq '--property' ) { shift @x; next }
            next if $y =~ /\A-/;
            return _systemctl_show( $dev, $av ) if $y eq 'show';
            last;
        }
    }
    my $now    = grep { $_ eq '--now' } @$av;
    my $failed = grep { $_ eq '--failed' || $_ eq '--state=failed' } @$av;
    # systemctl kill [-s SIG] dienst…: SIGHUP wirkt wie reload; TERM, KILL, INT treffen den
    # laufenden Dienst wie kill (Restart= der Unit gilt); nicht geladen, stehend, anderes: Luecke
    if ( ( $av->[0] // '' ) eq 'kill' ) {
        my ( @rest, $sig ) = ();
        my @k = @{$av}[ 1 .. $#$av ];
        while (@k) {
            my $x = shift @k;
            if    ( $x eq '-s' || $x eq '--signal' ) { $sig = shift @k }
            elsif ( $x =~ /\A--signal=(.+)\z/ )      { $sig = $1 }
            elsif ( $x =~ /\A--kill-whom=(?:all|main)\z/ ) { }
            elsif ( $x !~ /\A-/ )                    { push @rest, $x }
            else { push @GAPS, join( ' ', 'systemctl', @$av ); return ( '', 0 ) }
        }
        my $s = _sig_of( $sig // 'TERM' );
        return _systemctl( $dev, [ 'reload', @rest ], $ctx ) if $s eq 'HUP';
        my @units = map { _unit($_) } @rest;
        if ( !@units || $s !~ /\A(?:TERM|KILL|INT)\z/ || grep { !( ( $dev->{services} || {} )->{$_} || {} )->{active} } @units ) {
            push @GAPS, join( ' ', 'systemctl', @$av );
            return ( '', 0 );
        }
        _signal( $dev, $_, $s ) for @units;
        return ( '', 1 );
    }
    my $all    = grep { $_ eq '--all' || $_ eq '-a' } @$av;
    my ($type) = map { /\A--type=(\w+)\z/ ? $1 : () } @$av;
    my @a = grep { !/\A--/ && !/\A-[qlfa]\z/ } @$av;
    my $verb = shift(@a) // 'list-units';
    my @names = map { _unit($_) } @a;
    my $svcs = $dev->{services} //= {};
    # Debian: postgresql.service fasst die Cluster zusammen (ReloadPropagatedFrom=, PartOf=)
    if ( ref $dev->{postgres} eq 'HASH' && !$svcs->{postgresql} && $verb =~ /\A(?:reload|restart|start|stop|try-restart|reload-or-restart)\z/ ) {
        @names = map { $_ eq 'postgresql' ? $dev->{postgres}{service} // 'postgresql@15-main' : $_ } @names;
    }
    # systemctl status 'billing*': die passenden geladenen Units, ohne Treffer nichts
    if ( $verb eq 'status' && grep {/[*?[]/} @a ) {
        @names = map { my $p = $_; /[*?[]/ ? ( grep { _uname($_) =~ _unit_glob($p) } sort keys %$svcs ) : _unit($p) } @a;
        return ( '', 1 ) unless @names;
    }
    return ( _list_timers( $dev, $all, \@a ), 1 ) if $verb eq 'list-timers';
    if ( $verb eq 'list-units' || $verb eq 'list-unit-files' ) {
        my @n = sort grep { ( !$failed || $svcs->{$_}{failed} ) && ( !defined $type || _uname($_) =~ /\.\Q$type\E\z/ ) } keys %$svcs;
        # Muster hinter dem Verb (billing*, *.timer) wie systemd: gegen den Namen der Unit
        @n = grep { my $u = _uname($_); grep { $u =~ _unit_glob($_) } @a } @n if @a;
        return ( _list_unit_files( $dev, \@n ), 1 ) if $verb eq 'list-unit-files';
        return ( '  UNIT LOAD ACTIVE SUB DESCRIPTION' . "\n0 loaded units listed.", 1 ) if !@n && $failed;
        return ( join( "\n", sprintf( '  %-30s %-6s %-8s %-8s %s', qw( UNIT LOAD ACTIVE SUB DESCRIPTION ) ),
            map { my $v = $svcs->{$_};
                sprintf( '%s %-30s loaded %-8s %-8s %s', $v->{failed} ? '●' : ' ', _uname($_),
                    $v->{active} ? 'active' : $v->{failed} ? 'failed' : 'inactive',
                    $v->{active} ? ( /\.timer\z/ ? 'waiting' : 'running' ) : $v->{failed} ? 'failed' : 'dead', $v->{description} // '' ) } @n ), 1 );
    }
    if ( $verb eq 'daemon-reload' ) {
        if ( $dev->{storage} ) {    # systemd liest die fstab neu (Mount-Units)
            my $t = _file_text( $dev, '/etc/fstab' ) // '';
            $dev->{storage}{fstab_loaded} = $t if $t ne ( $dev->{storage}{fstab_loaded} // '' );
        }
        for my $n ( keys %$svcs ) {
            my $svc = $svcs->{$n};
            next unless exists $svc->{unit_loaded};
            my $t = _unit_text( $dev, $n, $svc );
            next unless defined $t && $t ne ( $svc->{unit_loaded} // '' );
            $svc->{unit_loaded} = $t;
            _timer_derive( $dev, $n, $svc );
            # Fehler der Unit meldet systemd beim Laden
            if ( my $bad = _unit_bad( $n, _unit_props($t) ) ) { _log( $dev, $n, $svc, "systemd[1]: $bad" ) }
        }
        return ( '', 1 );
    }
    return ( "Too few arguments.", 0 ) unless @names;
    my @out;
    my $ok = 1;
    for my $n (@names) {
        my $svc = $svcs->{$n};
        if ( !$svc ) {
            my ($real) = grep { grep { $_ eq $n } @{ $svcs->{$_}{aliases} || [] } } sort keys %$svcs;
            ( $n, $svc ) = ( $real, $svcs->{$real} ) if defined $real;
        }
        $svc //= _load_unit( $dev, $n, $verb eq 'status' || $verb eq 'cat' || $verb =~ /\Ais-/ );
        my $u = _uname($n);
        if ( !$svc ) {
            if ( $verb eq 'status' ) { push @out, "Unit $u could not be found."; $ok = 0; next }
            if ( $verb =~ /\Ais-/ ) { push @out, $verb eq 'is-enabled' ? 'not-found' : 'inactive'; $ok = 0; next }
            push @out, "Failed to $verb $u: Unit $u not found.";
            $ok = 0;
            next;
        }
        if ( $verb eq 'status' ) {
            push @out, _systemctl_status( $dev, $n, $svc, $ctx->{host} );
            $ok = 0 unless $svc->{active};
        }
        elsif ( $verb eq 'is-active' ) {
            push @out, $svc->{active} ? 'active' : $svc->{failed} ? 'failed' : 'inactive';
            $ok = 0 unless $svc->{active};
        }
        elsif ( $verb eq 'is-failed' ) { push @out, $svc->{failed} ? 'failed' : $svc->{active} ? 'active' : 'inactive'; $ok = 0 unless $svc->{failed} }
        elsif ( $verb eq 'is-enabled' ) {
            my $e = $svc->{masked} ? 'masked' : _symlinked( $dev, $n, $svc ) ? 'enabled' : _static( $dev, $n, $svc ) ? 'static' : 'disabled';
            push @out, $e;
            $ok = 0 unless $e eq 'enabled' || $e eq 'static';
        }
        elsif ( $verb eq 'cat' ) {
            my $uf = _unit_file( $n, $svc );
            my $t = _file_text( $dev, $uf ) // $svc->{unit_loaded};
            $t = ( $t // '' ) . join '', map { "\n# $_\n" . ( _file_text( $dev, $_ ) // '' ) } _dropins( $dev, $n );
            push @out, "# Warning: $u changed on disk, the version systemd has loaded is outdated.",
                "# This output shows the current version of the unit's original fragment and drop-in files.",
                "# If fragments or drop-ins were added or removed, they are not properly reflected in this output.",
                "# Run 'systemctl daemon-reload' to reload units." if _unit_changed( $dev, $n, $svc );
            push @out, "# $uf", ( $t // '' ) =~ s/\n\z//r;
        }
        elsif ( $verb =~ /\A(?:restart|reload|start|reload-or-restart|try-restart)\z/ ) {
            next if $verb eq 'try-restart' && !$svc->{active};
            # reload-or-restart: laeuft der Dienst und kann er neu laden, laedt er nur neu
            my $verb = $verb;
            if ( $verb eq 'reload-or-restart' ) {
                my $t = $svc->{unit_loaded} // _unit_text( $dev, $n, $svc );
                $verb = 'reload' if $svc->{active} && defined $t && $t =~ /^\s*ExecReload\s*=/m;
            }
            if ( $svc->{masked} ) { push @out, "Failed to $verb $u: Unit $u is masked."; $ok = 0; next }
            my $uft = $verb eq 'reload' ? $svc->{unit_loaded} // _unit_text( $dev, $n, $svc ) : undef;
            # Units ohne ExecReload (in der Unit, systemd-journald, oder reload: false im Zustand)
            if ( $verb eq 'reload' && ( !$svc->{active} || $n eq 'systemd-journald' || ( exists $svc->{reload} && !$svc->{reload} ) || $svc->{no_reload}
                || ( defined $uft && $uft !~ /^\s*ExecReload\s*=/m ) ) ) {
                push @out, "Failed to reload $u: Job type reload is not applicable for unit $u.";
                $ok = 0;
                next;
            }
            if ( $verb eq 'reload' ) {
                if ( defined( my $e = _svc_hook( $dev, $n, 'reload' ) ) ) {    # laeuft mit der alten Konfiguration weiter
                    $svc->{last_error} = $e;
                    push @out, "Job for $n.service failed because the control process exited with error code.",
                        "See \"systemctl status $n.service\" and \"journalctl -xeu $n.service\" for details.";
                    $ok = 0;
                    next;
                }
                _restart_effect( $dev, $n, 'reload' );
                _reopen_logs( $dev, $n );
                _pg_event( $dev, $n, 'reload' );
                _log( $dev, $n, $svc, "systemd[1]: Reloading $u" . _desc($svc) . '...',
                    ( map { ( $svc->{exec} // $n ) . '[' . ( 50000 + ( $dev->{_tick} // 0 ) ) . ']: ' . _render( $_, $CTX ? $CTX->{state} : {} ) =~ s/\s+\z//r }
                        @{ $svc->{reload_log} || [] } ),
                    "systemd[1]: Reloaded $u" . _desc($svc) . '.' );
                next;
            }
            my ( $o, $k ) = _systemd_start( $dev, $n, $svc, $verb );
            push @out, $o if length $o;
            $ok = 0 unless $k;
        }
        elsif ( $verb eq 'stop' ) {
            if ( $svc->{active} ) {
                $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1;
                $svc->{active} = JSON::MaybeXS::false();
                _pg_event( $dev, $n, 'stop' );
                _app_event( $dev, $n, 'stop' );
                _log( $dev, $n, $svc, "systemd[1]: Stopping $u" . _desc($svc) . '...', "systemd[1]: $u: Deactivated successfully.",
                    "systemd[1]: Stopped $u" . _desc($svc) . '.' );
            }
            $dev->{deleted_open} = [ grep { ( $_->{by} // '' ) ne $n } @{ $dev->{deleted_open} } ] if $dev->{deleted_open};
            if ( $n =~ /\Awg-quick\@(wg\d+)\z/ && $dev->{interfaces}{$1} && ( $dev->{interfaces}{$1}{state} // '' ) ne 'DOWN' ) {
                my $w = $1;
                my $copy = Langertha::Holmgang::Sim::Linux::clone_state($dev);
                if ( eval { _wg_down( $copy, $w ); 1 } ) { %$dev = %$copy }
                else { $dev->{interfaces}{$w}{state} = 'DOWN' }
                $dev->{services}{$n}{active} = JSON::MaybeXS::false();
            }
        }
        elsif ( $verb eq 'enable' || $verb eq 'disable' ) {
            my $want = $verb eq 'enable' ? 1 : 0;
            if ( $want && $svc->{masked} ) {
                push @out, "Failed to enable unit: Unit file /etc/systemd/system/$u is masked.";
                $ok = 0;
                next;
            }
            if ( _static( $dev, $n, $svc ) && !( !$want && $svc->{enabled} ) ) {
                push @out, 'The unit files have no installation config (WantedBy=, RequiredBy=, UpheldBy=,',
                    'Also=, or Alias= settings in the [Install] section, and DefaultInstance= for',
                    'template units). This means they are not meant to be enabled or disabled using systemctl.', ' ',
                    'Possible reasons for having these kinds of units are:',
                    "\x{2022} A unit may be statically enabled by being symlinked from another unit's",
                    '  .wants/, .requires/, or .upholds/ directory.',
                    "\x{2022} A unit's purpose may be to act as a helper for some other unit which has",
                    '  a requirement dependency on it.',
                    "\x{2022} A unit may be started when needed via activation (socket, path, timer,",
                    '  D-Bus, udev, scripted systemctl call, ...).',
                    "\x{2022} In case of template units, the unit is meant to be enabled with some",
                    '  instance name specified.';
            }
            else {
                $svc->{enabled} = $want ? JSON::MaybeXS::true() : JSON::MaybeXS::false() if ( $svc->{enabled} // 1 ) xor $want;
                my ($wb) = ( _unit_loaded_text( $dev, $n, $svc ) // '' ) =~ /^\s*WantedBy\s*=\s*(\S+)/m;
                $wb //= $n =~ /\.timer\z/ ? 'timers.target' : 'multi-user.target';
                push @out, $want ? "Created symlink /etc/systemd/system/$wb.wants/$u \x{2192} " . _unit_file( $n, $svc ) . '.'
                    : "Removed \"/etc/systemd/system/$wb.wants/$u\".";
            }
            if ($now) {
                if   ($want) { my ( $o, $k ) = _systemd_start( $dev, $n, $svc, 'start' ); push @out, $o if length $o; $ok = 0 unless $k }
                elsif ( $svc->{active} ) { $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1; $svc->{active} = JSON::MaybeXS::false(); _pg_event( $dev, $n, 'stop' ) }
            }
        }
        elsif ( $verb eq 'mask' )   { $svc->{masked} = 1 unless $svc->{masked}; push @out, "Created symlink /etc/systemd/system/$u \x{2192} /dev/null." }
        elsif ( $verb eq 'unmask' ) { delete $svc->{masked}; push @out, "Removed \"/etc/systemd/system/$u\"." }
        elsif ( $verb eq 'reset-failed' ) { $svc->{failed} = JSON::MaybeXS::false() if $svc->{failed} }
        elsif ( $verb eq 'edit' ) { push @GAPS, "systemctl edit $n"; push @out, 'Error opening terminal: unknown.'; $ok = 0 }
        else { return ( "Unknown command verb $verb.", 0 ) }
    }
    return ( join( "\n", @out ), $ok );
}

# systemd-analyze calendar AUSDRUCK… | verify DATEI… | cat-config PFAD…; anderes ist eine Luecke
sub _systemd_analyze {
    my ( $dev, $av ) = @_;
    my @a = grep { !/\A--(?:iterations|base-time)=/ } @$av;
    my $sub = shift(@a) // '';
    require Langertha::Holmgang::Sim::Linux::Calendar;
    if ( $sub eq 'calendar' ) {
        return ( 'Too few arguments.', 0 ) unless @a;
        my ( @out, $ok );
        $ok = 1;
        for my $e (@a) {
            my $c = Langertha::Holmgang::Sim::Linux::Calendar::parse($e);
            if ( !$c ) { push @out, "Failed to parse calendar specification '$e': Invalid argument"; $ok = 0; next }
            my $t = Langertha::Holmgang::Sim::Linux::Calendar::next_elapse( $c, _sim_now() );
            push @out, '' if @out;
            push @out, "  Original form: $e", "Normalized form: $c->{normalized}";
            if ( defined $t ) {
                push @out, '    Next elapse: ' . Langertha::Holmgang::Sim::Linux::Calendar::format_local($t);
                push @out, '       (in UTC): ' . Langertha::Holmgang::Sim::Linux::Calendar::format_local( $t, 1 );
                push @out, '       From now: ' . Langertha::Holmgang::Sim::Linux::Calendar::left( $t - _sim_now() ) . ' left';
            }
            else { push @out, '    Next elapse: never' }
        }
        return ( join( "\n", @out ), $ok );
    }
    if ( $sub eq 'verify' ) {
        my ( @out, $ok );
        $ok = 1;
        for my $p (@a) {
            my $t = _file_text( $dev, $p );
            if ( !defined $t ) { push @out, "Failed to prepare filename $p: No such file or directory"; $ok = 0; next }
            ( my $n = $p ) =~ s{.*/}{};
            next unless $n =~ /\.timer\z/;
            my $i = _timer_info( $dev, $n, { unit => $p } );
            push @out, map {"$p:$_->[0]: Failed to parse calendar specification, ignoring: $_->[1]"} @{ $i->{bad} };
            if ( !@{ $i->{cal} } && !$i->{other} ) {
                push @out, "$n: Timer unit lacks value setting. Refusing.", "Unit $n has a bad unit file setting.";
                $ok = 0;
            }
        }
        return ( join( "\n", @out ), $ok );
    }
    if ( $sub eq 'cat-config' ) {
        my @p = grep { !/\A-/ } @a;
        return ( 'Too few arguments.', 0 ) unless @p;
        my @out;
        for my $p (@p) {
            ( my $rel = $p ) =~ s{\A/(?:etc|run|usr/local/lib|usr/lib|lib)/}{};
            if ( $rel =~ m{\A/} ) { push @GAPS, join( ' ', 'systemd-analyze', @$av ); return ( '', 0 ) }
            my @roots = qw( /etc /run /usr/local/lib /usr/lib );
            my ($main) = grep { defined _file_text( $dev, $_ ) } map {"$_/$rel"} @roots;
            my %drop;    # Dateiname -> Pfad, das erste Verzeichnis gewinnt
            for my $r ( reverse @roots ) {
                my $d = "$r/$rel.d/";
                $drop{ substr( $_, length $d ) } = $_ for grep { index( $_, $d ) == 0 && substr( $_, length $d ) =~ m{\A[^/]+\.conf\z} } keys %{ $dev->{files} || {} };
            }
            my @f = ( ( $main // () ), map { $drop{$_} } sort keys %drop );
            if ( !@f ) { push @GAPS, join( ' ', 'systemd-analyze', @$av ); return ( '', 0 ) }
            push @out, map { "# $_\n" . ( _file_text( $dev, $_ ) =~ s/\n+\z//r ) } @f;
        }
        return ( join( "\n\n", @out ), 1 );
    }
    push @GAPS, join( ' ', 'systemd-analyze', @$av );
    return ( '', 0 );
}

# bash -c '…' / sh -c '…': die Zeile im Simulator ausfuehren
sub _shell_c {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    shift @a while @a && $a[0] =~ /\A-[^c]/;
    return ( '', 1 ) unless @a;
    if ( $a[0] eq '-c' ) {
        my $line = $a[1] // return ( 'bash: -c: option requires an argument', 0 );
        my ( $o, $k ) = __PACKAGE__->_run_inner( $dev, $line, $ctx );
        return ( $o, $k );
    }
    push @GAPS, join( ' ', 'bash', @a );    # Skript ausfuehren: nicht nachgebildet
    return ( '', 0 );
}

# timedatectl [status|show|set-timezone Z|list-timezones|timesync-status]
sub _timedatectl {
    my ( $dev, $av ) = @_;
    require Langertha::Holmgang::Sim::Linux::Calendar;
    my $C = 'Langertha::Holmgang::Sim::Linux::Calendar';
    my @a = grep { !/\A--(?:no-pager|no-ask-password)\z/ } @$av;
    my $verb = shift(@a) // 'status';
    my $tz = $dev->{timezone} // 'Europe/Berlin';
    my $now = _sim_now();
    my $off = $C->can('offset')->( $now, $tz );
    if ( $verb eq 'status' ) {
        my $loc = $C->can('format_local')->( $now, $tz );
        ( my $abbr = $loc ) =~ s/.* //;
        my $o = sprintf '%s%02d%02d', $off < 0 ? '-' : '+', abs($off) / 3600, ( abs($off) % 3600 ) / 60;
        ( my $rtc = $C->can('format_local')->( $now, 1 ) ) =~ s/ UTC\z//;
        return ( join( "\n", "               Local time: $loc", '           Universal time: ' . $C->can('format_local')->( $now, 1 ),
            "                 RTC time: $rtc", "                Time zone: $tz ($abbr, $o)", 'System clock synchronized: yes',
            '              NTP service: active', '          RTC in local TZ: no' ), 1 );
    }
    if ( $verb eq 'show' ) {
        my %p = ( Timezone => $tz, LocalRTC => 'no', CanNTP => 'yes', NTP => 'yes', NTPSynchronized => 'yes',
            TimeUSec => $C->can('format_local')->( $now, $tz ), RTCTimeUSec => $C->can('format_local')->( $now, $tz ) );
        my @want = map { /\A--property=(.*)\z/ ? split( /,/, $1 ) : () } @a;
        for ( my $i = 0; $i < @a; $i++ ) { push @want, split /,/, $a[ $i + 1 ] // '' if $a[$i] eq '-p' }
        my $value = grep { $_ eq '--value' } @a;
        my @k = grep { !@want || do { my $x = $_; grep { $_ eq $x } @want } } qw( Timezone LocalRTC CanNTP NTP NTPSynchronized TimeUSec RTCTimeUSec );
        return ( join( "\n", map { $value ? $p{$_} : "$_=$p{$_}" } @k ), 1 );
    }
    if ( $verb eq 'list-timezones' ) { return ( join( "\n", sort grep {m{/}} keys %Langertha::Holmgang::Sim::Linux::Calendar::ZONE ), 1 ) }
    if ( $verb eq 'set-timezone' ) {
        my $z = shift(@a) // return ( 'Too few arguments.', 0 );
        return ( "Failed to set time zone: Invalid or not installed time zone '$z'", 0 ) unless $Langertha::Holmgang::Sim::Linux::Calendar::ZONE{$z} && $z =~ m{/|\AUTC\z};
        $dev->{timezone} = $z unless $z eq $tz;
        return ( '', 1 );
    }
    push @GAPS, join( ' ', 'timedatectl', @$av );
    return ( '', 0 );
}

# file PFAD…: Art einer Datei aus dem Zustand
sub _file_cmd {
    my ( $dev, $av ) = @_;
    my @out;
    for my $p ( grep { !/\A-/ } @$av ) {
        my $e = _file_entry( $dev, $p );
        # ein Programm, das which an diesem Pfad findet (git, kubectl …): ausfuehrbare Datei
        if ( !$e && $p =~ m{\A/usr/(?:local/)?s?bin/([\w.+-]+)\z} && ( _which( 'which', $dev, [$1] ) )[0] eq $p ) {
            push @out, "$p: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped";
            next;
        }
        if ( !$e ) { push @out, _is_dir( $dev, $p ) ? "$p: directory" : "$p: cannot open `$p' (No such file or directory)"; next }
        if ( defined $e->{link} ) { push @out, "$p: symbolic link to $e->{link}"; next }
        my $t = $e->{content} // '';
        my $kind = $p =~ /\.gz\z/ ? 'gzip compressed data, from Unix'
            : $p =~ /\.journal(?:~)?\z/ ? 'Journal file'
            : $t =~ /\A#!\s*\S*\b(?:ba|da)?sh\b/ ? 'POSIX shell script, ASCII text executable'
            : $t =~ /BEGIN OPENSSH PRIVATE KEY/ ? 'OpenSSH private key'
            : ( grep { !/\A\s*(?:#|\z)/ } split /\n/, $t ) == 1 && $t =~ /^(?:\S+\s+)?ssh-(ed25519|rsa)\s+AAAA/m ? 'OpenSSH ' . uc($1) . ' public key'
            : length $t ? ( $t =~ /[^\x00-\x7f]/ ? 'Unicode text, UTF-8 text' : 'ASCII text' )
            : _file_size($e) > 0 && ( _mode_of($e) & 0111 ) ? 'ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped'
            : _file_size($e) > 0 ? 'data' : 'empty';
        push @out, "$p: $kind";
    }
    return ( join( "\n", @out ), 1 );
}

# Pakete, deren Dateien der Simulator kennt (dpkg -L/-S/-l/-s); weitere ueber
# packages: { name: [ pfade ] } im Zustand
our %PACKAGES = (
    'openssh-server' => { version => '1:9.2p1-2+deb12u3', files => [], desc => 'secure shell (SSH) server, for secure access from remote machines' },
    'openssh-client' => { version => '1:9.2p1-2+deb12u3', files => [], desc => 'secure shell (SSH) client, for secure access to remote machines' },
    nftables => { version => '1.0.6-2+deb12u2', files => [], desc => 'Program to control packet filtering rules by Netfilter project' },
    logrotate => { version => '3.21.0-1', files => [ qw( /etc/cron.daily/logrotate /etc/logrotate.conf /etc/logrotate.d/btmp
        /etc/logrotate.d/wtmp /lib/systemd/system/logrotate.service /lib/systemd/system/logrotate.timer /usr/sbin/logrotate
        /usr/share/doc/logrotate/changelog.Debian.gz /usr/share/man/man5/logrotate.conf.5.gz /usr/share/man/man8/logrotate.8.gz
        /var/lib/logrotate ) ], desc => 'Log rotation utility' },
    cron => { version => '3.0pl1-162', files => [ qw( /etc/cron.d /etc/cron.d/.placeholder /etc/cron.daily /etc/crontab
        /etc/init.d/cron /lib/systemd/system/cron.service /usr/sbin/cron /usr/bin/crontab ) ], desc => 'process scheduling daemon' },
);

sub _dpkg {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $op = shift(@a) // '';
    my %pk = ( %PACKAGES, map { ( $_ => { version => '1', files => $dev->{packages}{$_}, desc => '' } ) } keys %{ $dev->{packages} || {} } );
    my $known = sub { my ($n) = @_; $pk{$n} };
    if ( $op eq '-L' || $op eq '--listfiles' || $op eq '-s' || $op eq '--status' || $op eq '-l' || $op eq '--list' ) {
        my @out;
        my $ok = 1;
        for my $n (@a) {
            my $p = $known->($n);
            if ( !$p ) { push @GAPS, "dpkg $op $n"; return ( '', 0 ) }
            if ( $op =~ /\A-(?:L|-listfiles)\z/ ) { push @out, '/.', @{ $p->{files} } }
            elsif ( $op =~ /\A-(?:s|-status)\z/ ) { push @out, "Package: $n", 'Status: install ok installed', "Version: $p->{version}" }
            else { push @out, sprintf( 'ii  %-14s %-15s amd64        %s', $n, $p->{version}, $p->{desc} ) }
        }
        return ( join( "\n", @out ), $ok );
    }
    if ( $op eq '-S' || $op eq '--search' ) {
        my @out;
        for my $f (@a) {
            my ($n) = grep { my $x = $_; grep { $_ eq $f } @{ $pk{$x}{files} } } sort keys %pk;
            if ( !$n ) { push @GAPS, "dpkg -S $f"; return ( '', 0 ) }
            push @out, "$n: $f";
        }
        return ( join( "\n", @out ), 1 );
    }
    push @GAPS, join( ' ', 'dpkg', @$av );
    return ( '', 0 );
}

# PostgreSQL und seine Clients: Wirkung von Start, Neustart, reload, Stopp.
sub _pg_event {
    my ( $dev, $n, $verb ) = @_;
    my $svc = ( $dev->{services} || {} )->{$n} || {};
    return unless $dev->{postgres} || $svc->{pg_connect};
    _pg()->can('service_event')->( $dev, $n, $verb eq 'start' || $verb eq 'restart' || $verb eq 'reload' || $verb eq 'stop' ? $verb : 'restart',
        $CTX ? $CTX->{state} : {}, $CTX ? $CTX->{host} : undef );
    return;
}

sub _service {
    my ( $dev, $av, $ctx ) = @_;
    my ( $n, $verb ) = @$av;
    return ( 'Usage: service < option > | --status-all | [ service_name [ command | --full-restart ] ]', 0 ) unless defined $verb;
    return _systemctl( $dev, [ $verb, $n ], $ctx );
}

sub _reboot {
    my ( $dev, $av, $ctx ) = @_;
    $dev->{reboots} = ( $dev->{reboots} // 0 ) + 1;
    return ( "Connection to $ctx->{host} closed by remote host.", 0 );
}

# --- NetworkManager ----------------------------------------------------------------

sub _nmcli {
    my ( $dev, $av ) = @_;
    my @a;
    for ( my $i = 0; $i < @$av; $i++ ) {
        my $x = $av->[$i];
        if ( $x =~ /\A-(?:f|g|-fields|-get-values)\z/ ) { $i++; next }
        next if $x =~ /\A-[tp]\z|\A--(?:terse|pretty)\z/;
        push @a, $x;
    }
    my $nm = $dev->{nm} or return ( "Error: NetworkManager is not running.", 0 );
    my $cons = $nm->{connections} ||= {};
    my $obj = shift(@a) // 'general';
    my $o = _abbrev( $obj, qw( connection device general networking radio ) )
        // ( $obj eq 'c' || $obj eq 'con' ? 'connection' : $obj eq 'd' || $obj eq 'dev' ? 'device' : undef )
        // return ( "Error: argument '$obj' not understood. Try passing --help instead.", 0 );
    if ( $o eq 'connection' ) {
        my $verb = shift(@a) // 'show';
        $verb = _abbrev( $verb, qw( show modify up down reload ) ) // ( $verb eq 'mod' ? 'modify' : $verb );
        if ( $verb eq 'show' ) {
            my $n = shift @a;
            if ( !defined $n ) {
                return ( join( "\n", sprintf( '%-20s %-38s %-10s %s', qw( NAME UUID TYPE DEVICE ) ),
                    map { sprintf( '%-20s %-38s %-10s %s', $_, $cons->{$_}{uuid} // '00000000-0000-0000-0000-000000000000',
                        $cons->{$_}{type} // 'ethernet', $cons->{$_}{device} // '--' ) } sort keys %$cons ), 1 );
            }
            my $c = $cons->{$n} or return ( "Error: $n - no such connection profile.", 0 );
            my %p = ( 'connection.id' => $n, 'connection.interface-name' => $c->{device} // '--', %{ $c->{props} || {} } );
            return ( join( "\n", map { sprintf( '%-40s%s', "$_:", $p{$_} ) } sort keys %p ), 1 );
        }
        if ( $verb eq 'modify' ) {
            my $n = shift @a // return ( 'Error: No connection specified.', 0 );
            my $c = $cons->{$n} or return ( "Error: unknown connection '$n'.", 0 );
            return ( "Error: '$n' - no properties to modify.", 0 ) unless @a;
            while (@a) {
                my $k = shift @a;
                $k =~ s/\A\+|\A-//;
                my $v = shift @a // return ( "Error: value for '$k' is missing.", 0 );
                return ( "Error: invalid property '$k': '$k' not among [connection, ipv4, ipv6, …].", 0 )
                    unless $k =~ /\A(?:ipv4|ipv6|connection|802-3-ethernet|gsm)\.[\w-]+\z/;
                $c->{props}{$k} = $v;
            }
            return ( '', 1 );
        }
        if ( $verb eq 'up' || $verb eq 'down' ) {
            my $n = shift @a // return ( 'Error: No connection specified.', 0 );
            my $c = $cons->{$n} or return ( "Error: unknown connection '$n'.", 0 );
            if ( $verb eq 'down' ) { $c->{active} = 0; return ( "Connection '$n' successfully deactivated.", 1 ) }
            _nm_apply( $dev, $c );
            return ( "Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/7)", 1 );
        }
        return ( "Error: argument '$verb' not understood. Try passing --help instead.", 0 );
    }
    if ( $o eq 'device' ) {
        my $verb = shift(@a) // 'status';
        if ( $verb eq 'reapply' ) {
            my $d = shift @a // return ( 'Error: No interface specified.', 0 );
            my ($c) = grep { ( $_->{device} // '' ) eq $d } values %$cons;
            return ( "Error: Device '$d' not found.", 0 ) unless $c;
            _nm_apply( $dev, $c );
            return ( "Connection successfully reapplied to device '$d'.", 1 );
        }
        return ( join( "\n", sprintf( '%-10s %-10s %-10s %s', qw( DEVICE TYPE STATE CONNECTION ) ),
            map { sprintf( '%-10s %-10s %-10s %s', $cons->{$_}{device} // '--', $cons->{$_}{type} // 'ethernet', 'connected', $_ ) }
                sort keys %$cons ), 1 );
    }
    return ( "STATE      CONNECTIVITY  WIFI-HW  WIFI     WWAN-HW  WWAN\nconnected  full          missing  enabled  enabled  enabled", 1 );
}

# Metrik einer Verbindung auf ihre (nicht-Kernel-)Routen anwenden.
sub _nm_apply {
    my ( $dev, $c ) = @_;
    my $m = ( $c->{props} || {} )->{'ipv4.route-metric'};
    $m = $c->{default_metric} if !defined $m || $m eq '-1';
    return unless defined $m && defined $c->{device};
    for my $r ( @{ $dev->{routes} || [] } ) {
        next unless ( $r->{dev} // '' ) eq $c->{device} && ( $r->{proto} // '' ) ne 'kernel';
        $r->{metric} = 0 + $m;
    }
    return;
}

# --- ping (ohne Beobachtung des Falls) ---------------------------------------------

sub _ping {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $count, $from, $to ) = (4);
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-c' ) { $count = shift @a }
        elsif ( $x =~ /\A-c(\d+)\z/ ) { $count = $1 }    # -c1 zusammengeschrieben
        elsif ( $x eq '-I' || $x eq '-S' ) { $from = shift @a }
        elsif ( $x =~ /\A-[WwisMt]\z/ ) { shift @a }
        elsif ( $x =~ /\A-/ ) { }
        else { $to = $x }
    }
    return ( "ping: usage error: Destination address required", 0 ) unless defined $to;
    my $name;
    if ( !defined _ip2n($to) ) {    # Name: ueber /etc/hosts und die Nameserver aufloesen
        my ($ip) = _resolve( $dev, $to );
        return ( "ping: $to: Name or service not known", 0 ) unless defined $ip && defined _ip2n($ip);
        ( $name, $to ) = ( $to, $ip );
    }
    $count = 4 unless defined $count && $count =~ /\A\d+\z/ && $count > 0 && $count < 20;
    my $src = defined $from && defined _ip2n($from) ? $from : undef;
    my ($r) = _lookup( $dev, $to, $src );
    return ( "ping: connect: Network is unreachable", 0 ) unless $r;
    my @l = ( "PING " . ( $name // $to ) . " ($to) 56(84) bytes of data." );
    push @l, "64 bytes from $to: icmp_seq=$_ ttl=64 time=0.4" . $_ . ' ms' for 1 .. $count;
    push @l, '', "--- $to ping statistics ---", "$count packets transmitted, $count received, 0% packet loss, time " . ( $count - 1 ) . '003ms';
    return ( join( "\n", @l ), 1 );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux - The simulator of device type linux — a Debian shell with ip, nft, wg, sysctl, systemctl, nmcli, files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $out, $ok, $gap, $exit ) = $sims->run_command( $state, 'gw-a', 'ip route add 10.2.0.0/24 via 10.1.0.2' );
  my ( $out, $ok, $gap )        = $sims->write_file( $state, 'gw-a', '/etc/dnsmasq.conf', $text );

  # inside the simulator and its parts (Sim::Linux::<Part>), as in cai-platform:
  my ( $out, $ok, $gap ) = Langertha::Holmgang::Sim::Linux->run( $dev, $command_line, $ctx );

=head1 DESCRIPTION

Simulates the shell of a Debian system (contract:
L<Langertha::Holmgang::Role::Simulator>; device type C<linux>). Commands run on the state of the device:

  gw-a:
    type: linux
    interfaces: { eth0: { addr: [198.51.100.10/29], mtu: 1500, state: UP } }   # lo is always there
    routes:     [ { dst: default, via: 198.51.100.9, dev: eth0 },
                  { dst: 10.1.0.0/24, dev: eth1, proto: kernel, scope: link, src: 10.1.0.1 } ]
                # further fields: metric, table (missing = main), proto, scope, src
    rules:      [ { priority: 100, from: 10.2.0.0/24, table: "200" } ]       # ip rule; 0/32766/32767 always there
    sysctl:     { net.ipv4.ip_forward: "1" }    # only existing keys can be set
    nft:        { "inet filter": { chains: { forward: { type: filter, hook: forward, priority: "0",
                  policy: drop, rules: [ "ct state established,related accept" ] } } } }
    wg:         { wg0: { public_key: …, listen_port: 51820, address: 10.255.0.1/30,
                  peers: { "<key>": { name: …, endpoint: …, allowed_ips: […], handshake: … } } } }
    files:      { /etc/dnsmasq.conf: "…" }
    services:   { dnsmasq: { active: true, config: /etc/dnsmasq.conf, running: "…" },
                  "wg-quick@wg0": { active: true } }
    nm:         { connections: { lte: { device: wwan0, default_metric: 700, props: { ipv4.route-metric: "-1" } } } }
    nft_login:  { iif: eth1, saddr: 10.1.0.50, daddr: 10.1.0.1 }   # how the model comes in over SSH
    locked_out: true            # set by the simulator: the device's own firewall dropped this access
    neigh:      [ "10.1.0.20 dev eth1 lladdr 52:54:00:12:34:56 REACHABLE" ]
    reboots:    0
    # server cases:
    files:      { /var/log/app/debug.log: { size: 14G, owner: app, group: app, mode: "0640",
                  open_by: app, content: "…" },            # text OR an entry with metadata
                  /etc/resolv.conf: { link: ../run/systemd/resolve/stub-resolv.conf } }
    mounts:     { /var: { dev: /dev/vdb1, size: 16G, used: 1G } }   # used = base load without the files
    users:      { app: { uid: 1001, groups: [app] } }
    groups:     { ssl-cert: { gid: 110 } }
    services:   { app: { active, failed, enabled, masked, description, user, exec,
                  unit: /etc/systemd/system/app.service, unit_loaded: "…",
                  journal: [ … ], needs: [ { free: { mount: /var, min: 1G }, log: [ … ] },
                  { can: { user: app, read: /etc/ssl/private/app.key }, log: [ … ] },
                  { state: [ services, app, unit_loaded ], regex: …, log: [ … ] } ] } }
    resolved:   { global: { dns: [] }, links: { eth0: { dns: [ … ], domains: [ … ] } } }
    dns_servers: { 10.0.0.53: { db.example.internal: 10.0.0.20 } }   # what each name server answers
    deleted_open: [ { path, size, by } ]   # set by the simulator: deleted, but still open
    services:   { api: { …, restarts: 1 } }  # set by the simulator: restarts and stops of a running service
    services:   { api: { …, since: "Thu 2026-10-29 06:10:12 CET" } }  # start time without a start in the simulator
    # PostgreSQL: see Langertha::Holmgang::Sim::Linux::Postgres
    postgres:   { service: postgresql@15-main, settings: {…}, roles: {…}, tables: {…}, slots: {…}, … }
    # Kubernetes: see Langertha::Holmgang::Sim::Linux::Kubernetes
    kubernetes: { registry: […], storageclasses: {…}, namespaces: { shop: { deployments: {…}, … } } }

B<Reading:> C<ip [-4|-6|-br|-d|-s] route|rule|addr|link|neigh [show …]>,
C<ip route get>, C<wg [show [if] [allowed-ips|peers|endpoints]]>,
C<wg showconf>, C<nft [-a] list ruleset|table|chain>, C<sysctl [-a] [key]>,
C<cat> (files, F</proc/sys/…>, F</etc/wireguard/wgN.conf> from the state),
C<ls>, C<grep … file>, C<systemctl status|is-active>, C<nmcli connection show [name]>,
C<hostname>, C<uname -a>, C<which>, C<ping> (without an observation of the case: a reply when a
route leads to the target, else "Network is unreachable"), C<conntrack -C|-S>,
C<dmesg> (empty); servers: C<df [-h] [path]>, C<du [-sh] path…> (also with C<*>),
C<ls [-lah]>, C<stat>, C<find path [-name] [-size ±N[kMG]] [-type f]>, C<lsof [+L1]>,
C<which>, C<whereis>, C<type>, C<command -v> (paths as in Debian 12), C<id>, C<groups>, C<getent passwd|group|hosts>, C<journalctl [-u service] [-n N]
[--disk-usage]>, C<systemctl status|is-active|is-enabled|is-failed|cat|list-units
[--failed]>, C<resolvectl status|dns|domain|query>. C<getent passwd> shows the
GECOS field from the user's C<gecos>; C<systemctl list-units|list-unit-files [PATTERN…]>
filter by patterns (C<billing*>), C<list-unit-files> in its own format (UNIT FILE,
STATE, VENDOR PRESET); C<systemctl status 'PATTERN'> shows the matching loaded units
(nothing without a match).

B<Changing:> C<ip route add|del|replace|change|flush>, C<ip rule add|del>,
C<ip addr add|del>, C<ip link set [dev] X mtu N|up|down>,
C<wg set IF [listen-port N] [peer K [remove] [allowed-ips L] [endpoint E]
[persistent-keepalive N]]>, C<wg syncconf IF E<lt>(wg-quick strip IF)>, C<wg-quick
up|down|save|strip>, C<nft add|insert rule … [position H|index N]>,
C<nft delete rule … handle H>, C<nft add|delete table|chain>, C<nft flush
chain|table|ruleset>, C<sysctl -w k=v>, C<sysctl -p [file]>, C<echo/printf … E<gt>
file>, C<E<gt>E<gt>>, C<tee [-a]>, C<sed -i 's/…/…/[g]' file>, C<systemctl
restart|reload|start|stop|enable|disable>, C<nmcli connection modify|up>,
C<nmcli device reapply>, C<reboot>/C<shutdown>/C<poweroff> (count C<reboots>);
servers: C<chmod [-R] octal|u+x,…>, C<chown [-R] user[:group]>, C<chgrp>,
C<usermod -aG>, C<gpasswd -a>, C<rm [-rf]> (a file held open by a running service
keeps taking space until the service restarts or stops), C<truncate -s N>,
C<: E<gt> file>, C<touch>, C<mkdir>, C<cp>, C<mv> (also several sources into a directory), C<ln -s>, C<journalctl
--vacuum-size|--vacuum-time>, C<systemctl start|restart|enable|disable [--now]|mask|
unmask|daemon-reload|reset-failed>, C<resolvectl dns|domain IF …|revert>.

B<Hardening>: C<chmod> also with C<s>/C<t>
(C<u-s>, C<g+s>, C<ug-s>, four-digit octal), C<ls -l> shows C<s>/C<S>/C<t>/C<T>,
C<find … -perm [-/]octal|[-/]u=s,g=s> and C<-ls>; C<grep -r|-R|-l|-h|-H> over
directories and several files with file names; C<usermod -L|-U|-s shell|-e date|
-r -G groups>, C<gpasswd -d>, C<getent shadow> as well as C<passwd>, C<chage>,
C<deluser>, C<userdel>, C<visudo -c>, C<sudo -l -U user> (see
L<Langertha::Holmgang::Sim::Linux::Accounts>); C<sshd -t|-T>, C<ssh-keygen -A|-l> and the
effect of C<start|restart|reload> on the service C<ssh> (see
L<Langertha::Holmgang::Sim::Linux::Sshd>); C<nft -c -f file> only checks. With
C<ssh_login: { user, from }> the model is logged in over SSH: when sshd no longer
runs or its configuration shuts the user out, every further call answers like
an SSH client that was turned away. C<sed> reads expressions as BRE
(C<\(…\)> groups, C<(> is a character; the other way round with C<-E>/C<-r>), C<\/> in
the replacement is a C</>; C<2E<gt>/dev/null> and C<2E<gt>&1> redirect only the
error output.

B<Shell and processes> (round 1 of the bench measurement): C<for V in …; do …; done> (also
nested, C<done | filter>); programs with a path (C</usr/bin/id>, C</bin/…>
like C</usr/bin/…>); executable files in the state (e.g. F</usr/bin/redis-cli>)
are installed programs (C<which> finds them, a call without a model is a
gap instead of "command not found"); C<sudo> of a user without root rights
(C<sudo -u x sudo …>, C<su - x -c "sudo …">) checks that user's rules
(L<Langertha::Holmgang::Sim::Linux::Accounts/sudo_check>); the usual directories
of a Debian 12 exist, also empty; C<crontab -l|-r [-u user]>; C<ps -p|-C|-o>,
C<pkill [-SIG] [-x] name>, C<kill [-SIG] pid> with the same PIDs as C<ss> and
C<systemctl status> and C<systemctl kill [-s SIG] unit> (HUP rereads, otherwise the service ends
— and comes back as systemd brings it back by the unit's C<Restart=>: C<always> after
any signal, C<on-failure>, C<on-abnormal> and C<on-abort> after an unclean one such
as KILL, C<on-success> after TERM, INT, HUP or PIPE; C<NRestarts> counts it); C<nft --version>. C<find> evaluates
expressions like find: C<\( \)>, C<!>/C<-not>, C<-a> (also without the word) before
C<-o>/C<-or>; actions (C<-print>, C<-ls>, C<-printf>, C<-exec>, C<-delete>)
apply where the evaluation reaches them. C<redis-cli>/C<redis-server> with
a service redis-server: see L<Langertha::Holmgang::Sim::Linux::Redis> (state C<redis>) or
L<Langertha::Holmgang::Sim::Linux::RedisService> (the service alone).

A service B<starts only> when its C<needs> hold (enough free space on a
mount point, a user may read/write/execute a file, an
expectation on the state, C<env: { VAR: pattern }> — the environment of the process from
C<Environment=> and C<EnvironmentFile=> of the loaded unit, as systemd reads it);
otherwise it is C<failed>, and C<journalctl>/C<systemctl status> show the
C<log> lines of the first unmet condition. A condition C<can> without
C<user> applies to C<User=> of the loaded unit. On a device with
C<check_accounts: true>, C<User=> and C<Group=> of the unit must exist (else
217/USER or 216/GROUP like systemd). When
C<unit_loaded> is set, a changed unit file takes effect only after C<systemctl
daemon-reload> (with systemd's warning); C<unit_loaded: current> takes over
the unit as it is on disk at preparation. Drop-ins
(F<E<lt>unitE<gt>.service.d/*.conf> under F</etc>, F</run>, F</lib>) belong to the
unit (C<systemctl cat|status|show>); two C<ExecStart=> without an empty assignment
between them are C<bad-setting>. What a running process was started with is
under C<services.E<lt>serviceE<gt>._started> (last assignment per key,
C<ExecStart> as a list, C<Environment> as a hash). C<getent hosts> and
C<resolvectl query> resolve names through F</etc/hosts>, then the name servers from
F</etc/resolv.conf> (stub of systemd-resolved: the DNS servers of the links) along with
C<search> domains, with the answers from C<dns_servers>.

Commands can be chained with C<;>, C<&&>, C<||> and piped into filters
(C<| grep>, C<head>, C<tail>, C<wc -l>, C<sort>); C<sudo> is skipped.
Everything else answers like Debian (C<bash: x: command not found>, messages of
iproute2/nft/systemctl). iptables is not installed (nftables system).

B<Locking out:> when C<nft_login> is set (the path of the SSH connection the
model works over), every call is a new connection (C<ct new>, TCP 22):
if the ruleset drops it (L<Langertha::Holmgang::Sim::Linux::Nft>), the
device answers "Connection timed out" for the rest of the case and sets
C<locked_out>.

B<Restarts are in the state>: every restart (C<restart>, C<try-restart>,
C<reload-or-restart>) and every stop of a running service increments
C<services.E<lt>serviceE<gt>.restarts> — so a restart the task does not
ask for shows up in "nothing else changed", even when the service is
running again afterwards. C<reload> does not count; C<reload-or-restart> only
reloads a running service with C<ExecReload> (like systemd).

B<A start is visible>: every start and restart of a service
assigns a new main PID (the PID of its start messages in the journal, under
C<services.E<lt>serviceE<gt>._pid>) and sets the start time to the time of the
journal line "Started" (C<_since>, the device's clock C<clock>); C<reload> leaves both
as they are. Without a start in the simulator the service's C<since> in the state applies
(C<"Thu 2026-10-29 06:10:12 CET">), else Tue 2026-10-20 09:00:00 CEST. From this
C<systemctl status> ("since …; 4h 47min ago", measured against the device's
clock), C<systemctl show> (C<MainPID>, C<ExecMainPID>, C<ExecMainStartTimestamp>,
C<ActiveEnterTimestamp>, C<NRestarts>=0 — systemd counts only automatic
restarts there) and C<ps> (C<lstart>, C<etime>, START/STIME) read.

B<Filters with a file> (C<head>, C<tail>, C<wc>, C<sort>, C<uniq>, C<cut>, C<awk>,
C<fold>): the filter reports a missing file like coreutils or mawk
(C<wc: /x: No such file or directory>, C<head: cannot open '/x' for reading: …>,
C<sort: cannot read: /x: …>, C<awk: cannot open /x (…)>) with status 1; C<wc> counts
the others. B<Programs>: C<ls /usr/bin> and C<ls /usr/sbin> show exactly the
programs C<which> finds on the device (C</bin>, C</sbin> point there,
C<ls -l /bin> shows the link); what is not installed is missing. B<C</dev/tcp>> (and
C</dev/udp>) as a redirection is a bash connection, not modelled without a
network: a gap, not a missing file. B<Journal and clock>: C<journalctl
--since/--until> count relative to the device's clock (C<today>, C<"1 hour ago">,
C<06:00> for today 06:00), C<--list-boots> ends there; only the current boot
is modelled (C<-b -1> reports like journalctl that it does not exist).

B<Listeners and the application log> (round 2): a service with C<listen> (a list of
C<"address:port"> or C<{ file, regex }> — the capture group from the file, as the process
read it at start) listens while it runs, and C<ss -tlnp> shows it with
its PID; nginx listens per the C<listen> lines of its configuration, sshd without
F<sshd_config> in the state on 22. C<app_log: { file, start: [ … ], fail: [ … ] }> appends
lines to the log file on start or failed start (C<{ts}>, C<{listen}>, C<{pid}>); they
are a runtime trace (C<_append> on the device) and apply as long as the file is not
rewritten. B<nginx serves static files>: C<wget> against the own machine
(C<-O -|FILE>, C<-q>, C<-S>, C<--spider>, C<--header='Host: …'>) answers from C<root>
of the matching C<server> block with 200, 403 (the worker, C<user> or www-data, may not
enter a directory or may not read the file) or 404; C<proxy_pass> is
a gap. B<File times>: C<touch -d|--date> (like C<date -d>: C<"20 days ago">,
C<"2026-09-30 01:30">, C<yesterday>), C<-t [[CC]YY]MMDDhhmm>, C<-r FILE>, C<-c>; without
an argument now — by the device's clock; C<find -mtime/-mmin/-newer/-newermt>, C<stat>
(C<%y %Y>, lines Access/Modify/Change) and C<ls -l --time-style=full-iso|long-iso|iso>,
C<--full-time> read them. B<C<2E<gt>/dev/null>> on a command makes its
error messages (C<prog: …>, C<bash: cd: …>) disappear, also in a pipe.

B<Round 3>: as a user, on directories B<x> counts (traversal: C<cd>, C<ls>,
C<cat>, filters, redirections) and B<r> (C<ls> of a directory); C<rm> needs w and x
on the parent directory (sticky: only the owner of the file or of the directory). C<trap COMMANDS
EXIT> runs at the end of the shell (also after C<exit> and C<set -e>), C<trap -p>, C<trap -
SIGNAL>; shell functions (C<name() { … }>, C<function name>, C<return N>), C<! command>,
C<#!/usr/bin/env bash>, C<bash -n>, C<read -d "">, C<done E<lt> E<lt>( command )>; C<od -c>,
C<env>, C<uptime>, C<last [-a] [reboot|user]> and C<lastlog> (from C<logins> in the
state and the current boot), C<journalctl -k> (no kernel messages). B<TCP
between devices>: C<nc -z>, C</dev/tcp>, C<wget> and C<curl> (where installed) check
a connection to a device in the state against its firewall (nft, chains with hook
input: first matching rule, else policy; drop: timed out, reject: refused) and its
listeners (C<listen>, defaults per program like sshd 22, postgres 5432); a device with
services on unknown ports, a target outside the state or a rule that is not modelled
are a gap; a name the resolver does not know (like C<getent hosts>) does
not resolve.

B<Round 4>: C<flock [-n] FD|FILE [-c COMMAND|COMMAND]> (succeeds, creates the lock file),
C<exec NE<gt>file> (only opens), C<${PIPESTATUS[@]}>, C<done E<lt> E<lt>( … )> also over
several lines, C<sha256sum> from stdin, C<ps -fp PID>, C<ps -u USER>, C<lsblk> from the
mount points (without disks in the state).

B<Kubernetes> (L<Langertha::Holmgang::Sim::Linux::Kubernetes>): C<kubectl> against the
cluster under the device's C<kubernetes> (admin host).

B<Helm> (L<Langertha::Holmgang::Sim::Linux::Helm>): C<helm> against C<kubernetes.helm>.
B<git> (L<Langertha::Holmgang::Sim::Linux::Git>): C<git> on the working copies under
C<git.repos>, push to the device of a Forgejo server (C<forgejo.repos>);
C<forgejo-runner register>; C<docker ps|info|version> only with
F</var/run/docker.sock> and according to its permissions. C<cd> and C<pwd> hold until
the end of the command line; after that, relative file arguments become absolute. A
service with C<journal_start> writes these lines to the journal on every start;
with C<no_reload> it refuses C<reload> like a unit without ExecReload.

B<PostgreSQL> (L<Langertha::Holmgang::Sim::Linux::Postgres>): C<psql> (user from
C<sudo -u>, C<su [-] user -c '…'>, C<runuser -u>), C<pg_lsclusters>,
C<pg_ctlcluster VER NAME start|stop|restart|reload|status>; start, restart and
C<reload> of the cluster act as in Debian.

Start, restart and stop write lines to the journal (time from the device's
C<clock>, e.g. C<"Oct 24 09:12">), plus the service's start messages C<start_log> (on
C<reload>: C<reload_log>)
(a list of Kolon templates over C<$state>); they are under the service's C<_log> —
keys with C<_> are runtime traces and do not count in "nothing else changed".
At start systemd creates C<RuntimeDirectory=> (F</run>), C<StateDirectory=>,
C<LogsDirectory=> and C<CacheDirectory=> of the loaded unit for C<User>/C<Group>;
the running service creates its C<runtime_files> (socket, PID file: C<path>,
C<owner>, C<group>, C<mode>, C<type: socket>) when the directory exists.

B<Timers and logs>: units are named with their suffix
(C<backup.timer>; without a suffix C<.service> is meant). A new unit file
under F</etc/systemd/system> or F</lib/systemd/system> loads on the first
changing access (C<enable>, C<start>); C<status>, C<cat> and C<is-*> only
display it. A timer starts only with a valid trigger (C<OnCalendar=> per
L<Langertha::Holmgang::Sim::Linux::Calendar> or C<On*Sec=>) and an existing target unit
(C<Unit=>, else the same name with C<.service>); invalid calendar expressions are
in the journal with their line number. In the state every timer carries the derived
fields C<triggers> (normal forms of the valid C<OnCalendar=>) and C<activates>,
recomputed when the loaded unit changes (C<daemon-reload>, first
load) — rules check them instead of the text; C<last> (text like
"Tue 2026-10-20 02:00:04 CEST") is what C<list-timers> shows as LAST. C<enable> hooks
a timer into C<timers.target>, a service into its C<WantedBy=>; a complete
unit (with C<[Unit]>) without C<[Install]> is C<static>: C<enable>/C<disable>
report that like systemd and have no effect. A service with C<Type=oneshot> (without
C<RemainAfterExit=yes>) runs through once at start (C<runs> counts the
successful runs) and is C<inactive> afterwards. C<systemctl list-timers
[--all]>, C<list-units [--type=timer]>, C<systemd-analyze calendar EXPRESSION…>
(normal form, next elapse in local time Europe/Berlin and UTC) and
C<systemd-analyze verify FILE> (a timer's calendars), C<systemd-analyze
cat-config PATH> (file and drop-ins from /etc, /run, /usr/local/lib, /usr/lib); other
subcommands of C<systemd-analyze> are a gap in the simulation.
B<Files, journal, time> (added after the first measurement round): C<ls> shows
F<.> and F<..> with C<-a>, hides dot files without C<-a>/C<-A>, shows
empty directories (C<total 0>), C<-R> recursively, and systemd's C<*.wants>
as links of the enabled units; C<find> returns the root, directories and
files and knows C<-maxdepth>, C<-mindepth>, C<-type f|d|l>, C<-name>,
C<-iname>, C<-path>, C<-user>, C<-group>, C<-empty>, C<-newer>, C<-newermt>,
C<-o>, C<-not>/C<!>, parentheses, C<-prune>, C<-exec … {} +|;>, C<-delete>,
C<-printf>. The journal reaches back as far as its files
(one line per file at its time), lines are ordered by time;
C<journalctl> knows C<-u> (repeatable), C<-n>, C<-g>, C<-S|--since>,
C<-U|--until>, C<-o short|short-iso|cat>, C<-r>, C<--file>, C<--list-boots>,
C<--flush> (moves F</run/log/journal> to F</var/log/journal> when
journald stores persistently), C<--verify>, C<--disk-usage> (F</var/log/journal>
and F</run/log/journal>); it reports unknown options like journalctl. A
restart of journald with C<Storage=persistent> (or C<auto> and an existing
F</var/log/journal>) takes over the runtime journal. C<timedatectl
[status|show|set-timezone|list-timezones]> from the device's C<timezone> (default
Europe/Berlin; it also applies to the calendars), C<file>, C<dpkg -L|-S|-l|-s> for
the packages in C<%PACKAGES> and the device's C<packages> (others: gap), C<bash|sh
-c '…'>, C<logrotate> (L<Langertha::Holmgang::Sim::Linux::Logrotate>). A service with
C<creates> (path → entry) creates these files on every successful oneshot
run, C<run_journal> are its journal lines per run. A service reopens
its log files on C<reload> and restart (after a rotation by
renaming). C<disable> removes an existing link also for a unit
without C<[Install]>.

C<systemctl show UNIT… [-p A,B|--property=A,B]… [--value]> returns the
common properties from the state (Id, Names, Description, LoadState,
ActiveState, SubState, UnitFileState, FragmentPath, CanReload, Type, Restart,
User, MainPID, ExecStart; for timers Unit, TimersCalendar,
NextElapseUSecRealtime, LastTriggerUSec, AccuracyUSec, RandomizedDelayUSec,
Persistent) in systemd's order; unknown properties are missing
as with systemd. C<systemctl reload systemd-journald> (and every service with
C<reload: false>) reports like systemd "Job type reload is not applicable".
C<journalctl -g|--grep PATTERN> filters, C<--flush|--rotate|--sync> answer
empty. A restart of systemd-journald applies C<MaxRetentionSec=> (deletes
older archives) and C<Storage=persistent> (creates F</var/log/journal>) from
its file. A directory under C<dirs> (C<owner>, C<group>, C<mode>)
counts for the start condition C<can> like a file.

A service with C<config> (e.g. dnsmasq) reads its file into C<running> on start and
restart, on C<reload> only with C<reload_config: true>
(gunicorn, prometheus: SIGHUP rereads the configuration); C<wg-quick@wgN> takes
F</etc/wireguard/wgN.conf> over into the WireGuard state. What is only in the file
takes effect only after that.

B<Everyday terminal use>: C<mkdir [-p] [-m MODE]>
(without C<-p> the parent directory must exist, C<File exists>), C<umask [-S] [MODE]>
(builtin, per shell), C<pwd>; as a user without root rights (C<su - x -c>, C<sudo -u x>,
C<bash -c> beneath them) C<touch>, C<mkdir> and redirections need write permission on the
directory or the file (else C<Permission denied>); new entries belong to the
user and their first group, in a setgid directory to the directory's group
(directories inherit setgid), permissions 0666/0777 minus umask; F</tmp> is writable
for everyone. C<rm> of the last file leaves the directory in place (runtime trace
C<_dirs>), C<rm -r> also removes created directories; paths with C<.> and C<..>
are resolved. C<install [-d] [-D] [-m] [-o] [-g]>, C<crontab [-u user]
FILE|-> (syntax like Debian cron, replaces the whole crontab, file
C<user:crontab 0600> with a header; C<-l> shows it without the header), C<useradd>
(C<-m|-M>, C<-r>, C<-s>, C<-d>, C<-g>, C<-G>, C<-u>, C<-U|-N>; numbers like shadow,
group of the same name, default shell F</bin/sh>), C<groupadd [-r] [-g]>,
C<addgroup [--system]>, C<adduser --system …> and C<adduser USER GROUP>
(interactive C<adduser>: gap), C<getent group> only for existing groups,
C<getent passwd> with C<home>, C<mv SOURCE… DIRECTORY> (also directories),
C<ls -t|-r>, C<stat> of a directory, C<su> into an account with F<nologin>/F<false>
(without C<-s>) refuses, C<( … )> as a subshell. A device with C<oneshot_scripts: true>
runs, on the start of a C<Type=oneshot> unit whose C<ExecStart=> starts shell scripts in the
state, these scripts as C<User=> (exit status and journal; without
execute permission 203/EXEC). C<systemctl reload|restart|start|stop postgresql> acts on the
device's cluster.

Limits (documented): IPv4 arithmetic for routes (IPv6 routes are only
stored); nft handles are counted per table from the order on first look
and stay fixed afterwards (new rules get the next number);
nft rule text is only lightly normalised (whitespace, quotes around
interface names).

=head2 cwd_path

  my $abs = cwd_path('compose.yaml');   # /srv/shop/compose.yaml after cd /srv/shop

A path relative to the current directory of the command line (C<cd>), else to F</root>.

=head2 shell_env

  my %env = shell_env();

The environment a program of the command line sees: exported shell variables
and C<NAME=value command> (e.g. for C<docker compose>).

=head2 device_type

C<linux>.

=head2 run_command

  my ( $output, $ok, $gap, $exit ) = $sim->run_command( $dev, $command_line, $ctx );

L<Langertha::Holmgang::Role::Simulator/run_command>: runs the line through
L</run>. C<$exit> is the status of a failed line when it is not 1 (C<exit 3>
in a script, C<124> under C<timeout>).

=head2 write_file

  my ( $output, $ok, $gap ) = $sim->write_file( $dev, $path, $content, $ctx );

L<Langertha::Holmgang::Role::Simulator/write_file>: L</write>.

=head2 packet_verdict

  my ( $verdict, $why ) = $sim->packet_verdict( $dev, \%packet, $boot );

The rule kind C<packet>: L<Langertha::Holmgang::Sim::Linux::Nft/verdict>, or
with C<$boot> (a path, or true for F</etc/nftables.conf>)
L<Langertha::Holmgang::Sim::Linux::Nft/boot_verdict>.

=head2 login_check

  my ( $allowed, $client, @log ) = $sim->login_check( $dev, \%attempt, $host );

The rule kind C<login>: C<check> of the part C<SshAccess>. Dies when that part
is not installed.

=head2 Parts

The simulator is split into parts, C<Langertha::Holmgang::Sim::Linux::E<lt>PartE<gt>>
(C<Nft>, C<Calendar>, C<Accounts>, C<Backup>, C<Dns>, C<Docker>, C<Git>, C<Helm>,
C<Http>, C<Kubernetes>, C<Logrotate>, C<MariaDB>, C<Monitoring>, C<Nginx>, C<Pki>,
C<Postfix>, C<Postgres>, C<Redis>, C<RedisService>, C<SshAccess>, C<Sshd>,
C<Storage>). C<Nft> and C<Calendar> load with the simulator; every other part
loads the first time a command or a device state needs it. A part that is not
installed ends that call neutrally: empty output, failed, and the C<sim_gap>
C<Langertha::Holmgang::Sim::Linux::E<lt>PartE<gt> is not installed> — whatever the
call did up to there is discarded with it. In L</prepare> a missing part dies, so
a case that needs it does not load.

A part is a plain module of functions on the device state; it may call the
simulator's helpers (C<_file_text>, C<_file_set>, C<clone_state> …) and reports
its own gaps in C<@Langertha::Holmgang::Sim::Linux::E<lt>PartE<gt>::GAPS>, which the
simulator collects.

=head2 clone_state

  my $copy = Langertha::Holmgang::Sim::Linux::clone_state( $dev );

A deep copy of plain state data (through JSON, as the World copies a state), for
trial runs on a copy (C<nft -c>, a reboot's ruleset).

=head2 run

  my ( $output, $ok, $gap ) = Langertha::Holmgang::Sim::Linux->run( $dev, $command_line, $ctx );

The command line itself, as a class or object method — this is also how parts
(Kubernetes: a command in a pod) call the simulator. A missing part dies here;
L</run_command> turns that into the gap.

=head2 prepare

  Langertha::Holmgang::Sim::Linux->prepare( $dev, $ctx );

Initial state: Redis and MariaDB run with the values of their files
(C<redis.running>, C<mariadb.variables>) unless the case sets them itself;
BIND and Postfix have loaded what a freshly booted system would have loaded
(zones, parameters).

=head2 write

Writes a file (replaced whole). F</proc/sys/…> sets the kernel parameter.

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
