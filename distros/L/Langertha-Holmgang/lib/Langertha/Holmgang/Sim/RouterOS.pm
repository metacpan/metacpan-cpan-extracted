package Langertha::Holmgang::Sim::RouterOS;
# ABSTRACT: The simulator of device type routeros — a RouterOS (MikroTik) console

use Moose;
use namespace::autoclean;
use utf8;

with 'Langertha::Holmgang::Role::Simulator';

our $VERSION = '0.001';


my @FLAGS = ( [ X => 'disabled' ], [ I => 'invalid' ], [ D => 'dynamic' ] );

my %MENU;

sub _menu {
    my ( $path, %o ) = @_;
    my $m = { kind => 'list', flags => \@FLAGS, props => [], readonly => [], required => [], %o, path => $path };
    $m->{is_prop}  = { map { $_ => 1 } @{ $m->{props} }, 'comment', map { $_->[1] } @{ $m->{flags} } };
    $m->{ro}       = { map { $_ => 1 } @{ $m->{readonly} }, grep { $_ ne 'disabled' } map { $_->[1] } @{ $m->{flags} } };
    $m->{is_flag}  = { map { $_->[1] => 1 } @{ $m->{flags} } };
    $m->{has_name} = grep { $_ eq 'name' } @{ $m->{props} };
    $MENU{$path} = $m;
    return;
}

my @FW = qw(
    chain action src-address dst-address protocol src-port dst-port port in-interface out-interface
    in-interface-list out-interface-list connection-state connection-nat-state connection-type
    connection-mark packet-mark routing-mark src-address-list dst-address-list src-address-type
    dst-address-type src-mac-address in-bridge-port out-bridge-port tcp-flags tcp-mss icmp-options
    packet-size ttl dscp priority limit dst-limit connection-limit connection-rate content
    layer7-protocol ipsec-policy fragment nth random time per-connection-classifier jump-target
    address-list address-list-timeout passthrough log log-prefix
);
my @FW_ACT = qw( accept add-dst-to-address-list add-src-to-address-list jump log passthrough return );
my @RUN    = ( [ X => 'disabled' ], [ R => 'running' ] );

_menu '/ip firewall filter',
    props    => [ @FW, qw( reject-with hw-offload ) ],
    actions  => [ @FW_ACT, qw( drop fasttrack-connection reject tarpit ) ],
    required => ['chain'], move => 1, fw => 1;
_menu '/ip firewall nat',
    props    => [ @FW, qw( to-addresses to-ports randomise ) ],
    actions  => [ @FW_ACT, qw( dst-nat endpoint-independent-nat masquerade netmap redirect same src-nat ) ],
    required => ['chain'], move => 1, fw => 1;
_menu '/ip firewall mangle',
    props => [ @FW, qw( new-connection-mark new-packet-mark new-routing-mark new-mss new-dscp new-ttl
        new-priority route-dst sniff-id sniff-target sniff-target-port ) ],
    actions => [ @FW_ACT, qw( change-dscp change-mss change-ttl clear-df fasttrack-connection mark-connection
        mark-packet mark-routing route set-priority sniff-pc sniff-tzsp strip-ipv4-options ) ],
    required => ['chain'], move => 1, fw => 1;
_menu '/ip firewall raw',
    props    => [@FW],
    actions  => [ @FW_ACT, qw( drop notrack ) ],
    required => ['chain'], move => 1, fw => 1;
_menu '/ip firewall address-list',
    props => [qw( list address timeout creation-time )], readonly => ['creation-time'], required => [qw( list address )];
_menu '/ip address', props => [qw( address network interface )], required => [qw( address interface )];
_menu '/ip route', props => [qw( dst-address gateway distance scope target-scope routing-table routing-mark
    pref-src check-gateway type blackhole vrf-interface suppress-hw-offload )];
_menu '/ip pool', props => [qw( name ranges next-pool )], autoname => 'pool';
_menu '/ip dhcp-server',
    props => [qw( name interface address-pool lease-time authoritative add-arp bootp-support always-broadcast
        conflict-detection lease-script relay server-address use-radius )],
    required => ['interface'], autoname => 'dhcp';
_menu '/ip dhcp-server network',
    props => [qw( address gateway netmask dns-server domain ntp-server wins-server next-server boot-file-name
        dhcp-option )],
    required => ['address'];
_menu '/ip dhcp-server lease',
    props => [qw( address mac-address client-id server lease-time host-name status last-seen active-address
        active-mac-address active-client-id active-server expires-after always-broadcast block-access
        address-lists rate-limit use-src-mac )],
    readonly => [qw( host-name status last-seen active-address active-mac-address active-client-id
        active-server expires-after )],
    flags    => [ [ X => 'disabled' ], [ R => 'radius' ], [ D => 'dynamic' ], [ B => 'blocked' ] ],
    required => ['address'], lease => 1;
_menu '/ip dhcp-client',
    props => [qw( interface add-default-route default-route-distance use-peer-dns use-peer-ntp status address
        gateway dhcp-server )],
    readonly => [qw( status address gateway dhcp-server )], required => ['interface'];
_menu '/ip dns static',
    props => [qw( name regexp address type cname text forward-to ttl match-subdomain address-list )], move => 1;
_menu '/ip arp', props => [qw( address mac-address interface published )], required => ['address'];
_menu '/ip dns', kind => 'settings',
    props => [qw( servers dynamic-servers use-doh-server verify-doh-cert doh-max-server-connections
        doh-max-concurrent-queries doh-timeout allow-remote-requests max-udp-packet-size query-server-timeout
        query-total-timeout max-concurrent-queries max-concurrent-tcp-sessions cache-size cache-max-ttl
        address-list-extra-time vrf mdns-repeat-ifaces cache-used )],
    readonly => [qw( dynamic-servers cache-used )];
_menu '/system identity', kind => 'settings', props => ['name'], identity => 1;
_menu '/system resource', kind => 'resource';
_menu '/interface',
    props => [qw( name default-name type mtu actual-mtu l2mtu max-l2mtu mac-address last-link-up-time
        link-downs )],
    readonly => [qw( default-name type actual-mtu max-l2mtu mac-address last-link-up-time link-downs )],
    flags => [ [ D => 'dynamic' ], [ X => 'disabled' ], [ R => 'running' ], [ S => 'slave' ] ], noadd => 1;
_menu '/interface ethernet',
    props => [qw( name default-name mtu l2mtu mac-address arp auto-negotiation speed )],
    readonly => ['default-name'], flags => \@RUN, noadd => 1;
_menu '/interface pppoe-client',
    props => [qw( name interface user password service-name ac-name add-default-route default-route-distance
        use-peer-dns max-mtu max-mru mrru profile dial-on-demand allow keepalive-timeout )],
    flags => \@RUN, required => ['interface'], autoname => 'pppoe-out';
_menu '/interface vlan', props => [qw( name mtu arp vlan-id interface )], flags => \@RUN,
    required => [qw( interface vlan-id )], autoname => 'vlan';
_menu '/interface bridge', props => [qw( name mtu arp protocol-mode vlan-filtering admin-mac auto-mac )],
    flags => \@RUN, autoname => 'bridge';
_menu '/interface bridge port', props => [qw( interface bridge pvid frame-types ingress-filtering horizon hw )],
    required => [qw( interface bridge )], move => 1;
_menu '/interface list', props => [qw( name include exclude )], required => ['name'];
_menu '/interface list member', props => [qw( list interface )], required => [qw( list interface )];
_menu '/interface wireguard', props => [qw( name mtu listen-port private-key public-key )], flags => \@RUN,
    autoname => 'wireguard';
_menu '/interface wireguard peers',
    props => [qw( name interface public-key endpoint-address endpoint-port allowed-address preshared-key
        persistent-keepalive )],
    required => [qw( interface public-key )];

# Reihenfolge der Bloecke in export (wie RouterOS: erst Schnittstellen, dann IP)
my @EXPORT_ORDER = (
    '/interface bridge',        '/interface pppoe-client',     '/interface vlan',         '/interface wireguard',
    '/interface list',          '/ip pool',                    '/ip dhcp-server',         '/interface bridge port',
    '/interface list member',   '/interface wireguard peers',  '/ip address',             '/ip arp',
    '/ip dhcp-client',          '/ip dhcp-server lease',       '/ip dhcp-server network', '/ip dns',
    '/ip dns static',           '/ip firewall address-list',   '/ip firewall filter',     '/ip firewall mangle',
    '/ip firewall nat',         '/ip firewall raw',            '/ip route',               '/system identity',
);

my %ESC = ( n => "\n", t => "\t", r => "\r", _ => ' ' );

my %CMD = (
    print           => \&_c_print,
    export          => \&_c_export,
    add             => \&_c_add,
    set             => \&_c_set,
    remove          => \&_c_remove,
    disable         => \&_c_disable,
    enable          => \&_c_enable,
    comment         => \&_c_comment,
    move            => \&_c_move,
    find            => \&_c_find,
    'make-static'   => \&_c_make_static,
    'reset-counters'     => \&_c_noop,
    'reset-counters-all' => \&_c_noop,
    reboot          => \&_c_reboot,
    shutdown        => \&_c_shutdown,
    ping            => \&_c_ping,
    traceroute      => \&_c_traceroute,
    quit            => sub { return { stop => 1 } },
);

my $VERSION_ROS = '7.16.2';


# Echte RouterOS-Menues und -Optionen, die der Simulator nicht nachbildet: die
# Zeile bekommt eine neutrale (leere) Antwort und wird als Luecke gemeldet.
our $GAP_RE = qr{
    \A\s*/?\s*(?:
        log\b | tool\s+(?!traceroute\b|ping\b)\S | ppp\b | routing\b | queue\b | certificate\b | snmp\b | ipv6\b | user\b | file\b | caps-man\b
      | system\s+(?:script|scheduler|logging|package|clock|history|ntp|routerboard|health|license|note|backup|upgrade)\b
      | ip\s+(?:service|neighbor|firewall\s+connection|pool\s+used|cloud|ssh|socks|proxy|traffic-flow|upnp|ipsec|hotspot|smb|settings|kid-control)\b
      | interface\s+(?:monitor-traffic|ethernet\s+monitor|wireless|wifi|lte|sstp-client|l2tp-client|ovpn-client|bonding|eoip|gre)\b
    )
  | \bprint\b.*\b(?:stats|interval|follow|follow-only|oid|without-paging|brief|value-list|as-value|stats-detail)\b
  | \b(?:monitor|monitor-traffic|torch|bandwidth-test|sniffer)\b
}xi;

sub run {
    my ( $class, $dev, $command, $ctx ) = @_;
    $ctx //= {};
    my @gaps;
    my $host = $ctx->{host} // $dev->{identity} // 'router';
    return ( "ssh: connect to host $host port 22: Connection timed out", 0 ) if _yes( $dev->{shutdown} );
    my $s = { dev => $dev, ctx => $ctx, path => '' };
    my @out;
    my $L = 0;
    for my $line ( split /\r?\n/, $command // '' ) {
        $L++;
        next if $line =~ /\A\s*(?:#.*)?\z/;
        if ( $line =~ $GAP_RE ) { push @gaps, $line =~ s/\A\s+|\s+\z//gr; next }
        my @stmts = eval { _statements( $line, $L ) };
        if ( my $e = $@ ) { push @out, _msg($e); return ( join( "\n", @out ), 0, _gaps(@gaps) ) }
        for my $st (@stmts) {
            my $r = eval { _statement( $s, $st, $L ) };
            if ( my $e = $@ ) { push @out, _msg($e); return ( join( "\n", @out ), 0, _gaps(@gaps) ) }
            $r = { out => $r } unless ref $r;
            push @out, $r->{out} if defined $r->{out} && length $r->{out};
            return ( join( "\n", @out ), 1, _gaps(@gaps) ) if $r->{stop};
        }
    }
    return ( join( "\n", @out ), 1, _gaps(@gaps) );
}

sub device_type { 'routeros' }


sub run_command {
  my ( $self, $dev, $command, $ctx ) = @_;
  return $self->run( $dev, $command, $ctx );
}


sub menus { return sort keys %MENU }

sub _gaps { return @_ ? join( '; ', @_ ) : undef }

# --- Fehler -------------------------------------------------------------------

sub _err   { die { msg => $_[0] } }
sub _errat { my ( $msg, $L, $col ) = @_; die { msg => "$msg (line $L column $col)" } }

sub _msg {
    my ($e) = @_;
    die $e unless ref $e eq 'HASH';    # Programmfehler nicht verschlucken
    return $e->{msg};
}

# --- Zerlegen -----------------------------------------------------------------

sub _statements {
    my ( $line, $L ) = @_;
    my @st = ( [] );
    for my $t ( _tokenize( $line, $L, 0 ) ) {
        if   ( $t->{semi} ) { push @st, [] }
        else                { push @{ $st[-1] }, $t }
    }
    return grep {@$_} @st;
}

# Woerter mit Spalte; "..." mit Escapes; [ ... ] als Klammer (br) am Wortende; ; als Trenner
sub _tokenize {
    my ( $line, $L, $off ) = @_;
    my @t;
    my $len = length $line;
    pos($line) = 0;
    while (1) {
        $line =~ /\G[ \t]+/gc;
        last if ( pos($line) // $len ) >= $len;
        my $col = pos($line) + 1 + $off;
        if ( $line =~ /\G;/gc ) { push @t, { semi => 1, col => $col }; next }
        my %tok = ( text => '', col => $col );
        $tok{quoted} = 1 if substr( $line, pos($line), 1 ) eq '"';
        while ( pos($line) < $len ) {
            if ( $line =~ /\G"/gc ) {
                while (1) {
                    if    ( $line =~ /\G\\(.)/gcs )    { $tok{text} .= $ESC{$1} // $1 }
                    elsif ( $line =~ /\G"/gc )         { last }
                    elsif ( $line =~ /\G([^"\\]+)/gc ) { $tok{text} .= $1 }
                    else                               { _errat( 'syntax error', $L, $len + 1 + $off ) }
                }
            }
            elsif ( $line =~ /\G\[/gc ) {
                my $start = pos($line);
                my ( $i, $depth, $inq ) = ( $start, 1, 0 );
                while ( $i < $len ) {
                    my $c = substr( $line, $i, 1 );
                    if    ( $inq && $c eq '\\' ) { $i++ }
                    elsif ( $c eq '"' )          { $inq = !$inq }
                    elsif ( !$inq && $c eq '[' ) { $depth++ }
                    elsif ( !$inq && $c eq ']' ) { last unless --$depth }
                    $i++;
                }
                _errat( 'syntax error', $L, $len + 1 + $off ) if $depth;
                $tok{br}    = substr( $line, $start, $i - $start );
                $tok{brcol} = $start + 1 + $off;
                pos($line) = $i + 1;
                last;
            }
            elsif ( $line =~ /\G([^\s";\[\]]+)/gc ) { $tok{text} .= $1 }
            elsif ( $line =~ /\G\]/gc ) { _errat( 'syntax error', $L, pos($line) + $off ) }
            else                        { last }
        }
        push @t, \%tok;
    }
    return @t;
}

# --- Menuebaum ----------------------------------------------------------------

sub _paths {
    my ($s) = @_;
    my %p = map { $_ => 1 } keys %MENU, '/system', '/tool';
    for my $k (qw( menus settings )) {
        next unless ref $s->{dev}{$k} eq 'HASH';
        $p{$_} = 1 for grep {m{\A/[a-z]}} keys %{ $s->{dev}{$k} };
    }
    return keys %p;
}

sub _children {
    my ( $s, $path ) = @_;
    my $pre = $path eq '' ? '/' : "$path ";
    my %c;
    for my $p ( _paths($s) ) {
        next unless length $p > length $pre && index( $p, $pre ) == 0;
        my ($first) = split / /, substr( $p, length $pre );
        $c{$first} = $pre . $first;
    }
    return \%c;
}

sub _kind {
    my ( $s, $path ) = @_;
    return $MENU{$path}{kind} if $MENU{$path};
    return 'list'     if ref $s->{dev}{menus} eq 'HASH'    && ref $s->{dev}{menus}{$path} eq 'ARRAY';
    return 'settings' if ref $s->{dev}{settings} eq 'HASH' && ref $s->{dev}{settings}{$path} eq 'HASH';
    return 'dir';
}

sub _spec {
    my ( $s, $path ) = @_;
    return $MENU{$path} if $MENU{$path};
    return {
        kind => _kind( $s, $path ), path => $path, any => 1, flags => \@FLAGS, props => [], required => [],
        is_prop => { comment => 1, map { $_->[1] => 1 } @FLAGS }, ro => { dynamic => 1, invalid => 1 },
        is_flag => { map { $_->[1] => 1 } @FLAGS }, has_name => 1,
    };
}

sub _commands {
    my ( $s, $path ) = @_;
    my $kind = _kind( $s, $path );
    my $m    = _spec( $s, $path );
    my @c;
    if ( $kind eq 'list' ) {
        push @c, qw( print export find set disable enable comment );
        push @c, qw( add remove ) unless $m->{noadd};
        push @c, 'move'        if $m->{move};
        push @c, 'make-static' if $m->{lease};
        push @c, qw( reset-counters reset-counters-all ) if $m->{fw};
    }
    elsif ( $kind eq 'settings' ) { push @c, qw( print set export ) }
    elsif ( $kind eq 'resource' ) { push @c, 'print' }
    else                          { push @c, 'export' }
    push @c, qw( reboot shutdown ) if $path eq '/system';
    return ( @c, qw( ping traceroute quit ) );
}

# Name -> Unterpfad oder Befehl; exakt vor eindeutiger Abkuerzung
sub _resolve_word {
    my ( $s, $path, $w ) = @_;
    my $ch = _children( $s, $path );
    my @cmd = _commands( $s, $path );
    return ( child => $ch->{$w} ) if $ch->{$w};
    return ( cmd => $w ) if grep { $_ eq $w } @cmd;
    my @hit = ( ( map { [ child => $ch->{$_} ] } grep { index( $_, $w ) == 0 } sort keys %$ch ),
        ( map { [ cmd => $_ ] } grep { index( $_, $w ) == 0 } @cmd ) );
    return @hit == 1 ? @{ $hit[0] } : ();
}

sub _parent { my ($p) = @_; return $p =~ /\A(.+) [^ ]+\z/ ? $1 : '' }

# Pfad am Anfang der Woerter abarbeiten: ( neuer Pfad, Rest )
sub _navigate {
    my ( $s, $path, $toks ) = @_;
    my @t = @$toks;
    if ( @t && !defined $t[0]{br} && !$t[0]{quoted} && $t[0]{text} =~ m{\A/(.*)\z}s ) {
        my $rest = $1;
        my $col  = $t[0]{col} + 1;
        shift @t;
        $path = '';
        unshift @t, map { { text => $_, col => $col } } grep { length } split m{/}, $rest;
    }
    while (@t) {
        my $w = $t[0];
        last if defined $w->{br} || $w->{quoted} || $w->{text} =~ /[=!~]/;
        if ( $w->{text} eq '..' ) { $path = _parent($path); shift @t; next }
        my ( $what, $to ) = _resolve_word( $s, $path, $w->{text} );
        last unless $what && $what eq 'child';
        $path = $to;
        shift @t;
    }
    return ( $path, @t );
}

sub _statement {
    my ( $s, $toks, $L ) = @_;
    my ( $path, @t ) = _navigate( $s, $s->{path}, $toks );
    unless (@t) { $s->{path} = $path; return '' }
    my $ct = shift @t;
    my ( $what, $cmd ) = defined $ct->{br} || $ct->{quoted} ? () : _resolve_word( $s, $path, $ct->{text} );
    unless ( $what && $what eq 'cmd' ) {
        my $name = $ct->{text};
        $name = '[' if $name eq '' && defined $ct->{br};
        _errat( "bad command name $name", $L, $ct->{col} );
    }
    return $CMD{$cmd}->( $s, $path, \@t, $L );
}

# --- Argumente ----------------------------------------------------------------

sub _key {
    my ( $spec, $k, $extra, $mode ) = @_;
    my @c = @$extra;
    if ($mode) {
        if ( $spec->{any} ) {
            return undef if $mode eq 'write' && $spec->{ro}{$k};
            return $k;
        }
        push @c, grep { $mode eq 'read' || !$spec->{ro}{$_} } sort keys %{ $spec->{is_prop} };
    }
    return $k if grep { $_ eq $k } @c;
    my @p = grep { index( $_, $k ) == 0 } @c;
    return @p == 1 ? $p[0] : undef;
}

# o: keys => [..] (weitere k=v), props => 'write'|'read', words => [..], pos => max, unset => 1
sub _args {
    my ( $spec, $toks, $L, %o ) = @_;
    my %r = ( kv => [], unset => [], pos => [], word => {} );
    for my $t (@$toks) {
        my $text = $t->{text};
        if ( !$t->{quoted} && $text =~ /\A([a-z][a-z0-9-]*)=(.*)\z/s ) {
            my $k = _key( $spec, $1, $o{keys} || [], $o{props} ) // _errat( 'expected end of command', $L, $t->{col} );
            push @{ $r{kv} }, [ $k, { text => $2, br => $t->{br}, brcol => $t->{brcol}, col => $t->{col} } ];
            next;
        }
        if ( $o{unset} && !$t->{quoted} && !defined $t->{br} && $text =~ /\A!([a-z][a-z0-9-]*)\z/ ) {
            my $k = _key( $spec, $1, [], 'write' ) // _errat( 'expected end of command', $L, $t->{col} );
            push @{ $r{unset} }, $k;
            next;
        }
        if ( !$t->{quoted} && !defined $t->{br} && grep { $_ eq $text } @{ $o{words} || [] } ) {
            $r{word}{$text} = 1;
            next;
        }
        _errat( 'expected end of command', $L, $t->{col} ) if @{ $r{pos} } >= ( $o{pos} // 0 );
        push @{ $r{pos} }, $t;
    }
    return \%r;
}

sub _take {
    my ( $a, $k ) = @_;
    my ($hit) = grep { $_->[0] eq $k } @{ $a->{kv} };
    $a->{kv} = [ grep { $_->[0] ne $k } @{ $a->{kv} } ];
    return $hit ? $hit->[1] : undef;
}

sub _val {
    my ( $v, $L ) = @_;
    _errat( 'expected end of command', $L, $v->{brcol} // $v->{col} ) if defined $v->{br};
    return $v->{text};
}

sub _norm {
    my ( $spec, $k, $v ) = @_;
    if ( $k eq 'action' && $spec->{actions} ) {
        _err('input does not match any value of action') unless grep { $_ eq $v } @{ $spec->{actions} };
    }
    if ( $spec->{is_flag}{$k} ) {
        $v = lc $v;
        $v = 'yes' if $v eq 'true';
        $v = 'no'  if $v eq 'false';
        _err("input does not match any value of $k") unless $v eq 'yes' || $v eq 'no';
    }
    return $v;
}

sub _yes {
    my ($v) = @_;
    return 0 unless defined $v && length "$v";
    return "$v" =~ /\A(?:no|false|0)\z/i ? 0 : 1;
}

# --- Listen -------------------------------------------------------------------

sub _list {
    my ( $s, $path, $create ) = @_;
    my $dev = $s->{dev};
    if ($create) {
        $dev->{menus} = {} unless ref $dev->{menus} eq 'HASH';
        return $dev->{menus}{$path} //= [];
    }
    return ref $dev->{menus} eq 'HASH' && ref $dev->{menus}{$path} eq 'ARRAY' ? $dev->{menus}{$path} : [];
}

sub _index_of {
    my ( $list, $ref ) = @_;
    for ( 0 .. $#$list ) { return $_ if $list->[$_] == $ref }
    return undef;
}

# Nummern, Namen oder [find ...] -> Eintraege (Referenzen in die Liste)
sub _refs {
    my ( $s, $spec, $path, $list, $v, $L ) = @_;
    my @r;
    if ( defined $v->{br} ) {
        @r = _bracket( $s, $path, $v, $L );
        defined _index_of( $list, $_ ) or _err('no such item') for @r;
    }
    else {
        _err('no such item') unless length $v->{text};
        for my $p ( split /,/, $v->{text} ) {
            if ( $p =~ /\A\d+\z/ ) { push @r, $list->[$p] // _err('no such item'); next }
            my ($it) = $spec->{has_name} ? grep { defined $_->{name} && $_->{name} eq $p } @$list : ();
            push @r, $it // _err('no such item');
        }
    }
    my %seen;
    return grep { !$seen{$_}++ } @r;
}

sub _bracket {
    my ( $s, $path, $v, $L ) = @_;
    my @t = _tokenize( $v->{br}, $L, ( $v->{brcol} // 1 ) - 1 );
    _errat( 'syntax error', $L, $_->{col} ) for grep { $_->{semi} } @t;
    ( $path, @t ) = _navigate( $s, $path, \@t );
    my $ct = shift @t or _errat( 'expected command name', $L, $v->{brcol} // 1 );
    my ( $what, $cmd ) = defined $ct->{br} || $ct->{quoted} ? () : _resolve_word( $s, $path, $ct->{text} );
    _errat( "bad command name $ct->{text}", $L, $ct->{col} ) unless $what && $what eq 'cmd' && $cmd eq 'find';
    shift @t if @t && !$t[0]{quoted} && $t[0]{text} eq 'where';
    my $spec = _spec( $s, $path );
    my $cond = _cond( $spec, \@t, $L );
    return grep { $cond->($_) } @{ _list( $s, $path ) };
}

# where-Ausdruck: Begriffe, und vor oder, not/! verneint
sub _cond {
    my ( $spec, $toks, $L ) = @_;
    my @or = ( [] );
    my $neg = 0;
    for my $t (@$toks) {
        my $x = $t->{text};
        _errat( 'expected end of command', $L, $t->{col} ) if defined $t->{br};
        if ( !$t->{quoted} ) {
            next if $x eq 'and' || $x eq '&&';
            if ( $x eq 'or' || $x eq '||' ) { push @or, []; next }
            if ( $x eq 'not' || $x eq '!' ) { $neg = !$neg; next }
        }
        my ( $bang, $k, $op, $v ) = $x =~ /\A(!?)([a-z][a-z0-9-]*)(?:(!=|=|~|<|>)(.*))?\z/s
            or _errat( 'expected end of command', $L, $t->{col} );
        $k = _key( $spec, $k, [], 'read' ) // _errat( 'expected end of command', $L, $t->{col} );
        my $flip = ( $bang ? 1 : 0 ) ^ ( $neg ? 1 : 0 );
        $neg = 0;
        my $flag = $spec->{is_flag}{$k};
        if ( $flag && defined $v ) {
            $v = lc $v;
            $v = 'yes' if $v eq 'true';
            $v = 'no'  if $v eq 'false';
        }
        my $re = defined $op && $op eq '~' ? eval {qr/$v/} : undef;
        push @{ $or[-1] }, sub {
            my ($it) = @_;
            my $iv = $flag ? ( _yes( $it->{$k} ) ? 'yes' : 'no' ) : $it->{$k};
            my $m;
            if ( !defined $op ) { $m = $flag ? _yes( $it->{$k} ) : defined $iv && length $iv }
            elsif ( $op eq '=' )  { $m = ( $iv // '' ) eq $v }
            elsif ( $op eq '!=' ) { $m = ( $iv // '' ) ne $v }
            elsif ( $op eq '~' )  { $m = $re && ( $iv // '' ) =~ $re }
            else {
                my ( $a, $b ) = ( $iv // '', $v );
                my $num = $a =~ /\A-?\d+\z/ && $b =~ /\A-?\d+\z/;
                $m = $op eq '<' ? ( $num ? $a < $b : $a lt $b ) : ( $num ? $a > $b : $a gt $b );
            }
            return $flip ? !$m : $m;
        };
    }
    return sub {1} if @or == 1 && !@{ $or[0] };
    _errat( 'expected end of command', $L, $toks->[-1]{col} ) if grep { !@$_ } @or;
    return sub {
        my ($it) = @_;
        for my $and (@or) { return 1 unless grep { !$_->($it) } @$and }
        return 0;
    };
}

# --- Ausgabe ------------------------------------------------------------------

sub _q {
    my ($v) = @_;
    $v = "$v";
    return $v if $v =~ /\A[^\s"\\;\$\[\]{}=]+\z/;
    $v =~ s/(["\\\$])/\\$1/g;
    $v =~ s/\n/\\n/g;
    $v =~ s/\t/\\t/g;
    return qq{"$v"};
}

sub _pairs {
    my ( $spec, $it ) = @_;
    my %in = map { $_ => 1 } @{ $spec->{props} };
    my @k  = ( ( grep { exists $it->{$_} } @{ $spec->{props} } ), ( sort grep { !$in{$_} } keys %$it ) );
    return map { "$_=" . _q( $it->{$_} // '' ) } grep { $_ ne 'comment' && !$spec->{is_flag}{$_} } @k;
}

sub _flags {
    my ( $spec, $it ) = @_;
    return join '', map { $_->[0] } grep { _yes( $it->{ $_->[1] } ) } @{ $spec->{flags} };
}

sub _rtrim { my ($x) = @_; $x =~ s/[ \t]+$//mg; return $x }

sub _entry {
    my ( $spec, $n, $it ) = @_;
    my $pre = sprintf '%2d %-3s', $n, _flags( $spec, $it );
    my $kv  = join ' ', _pairs( $spec, $it );
    return _rtrim( $pre . $kv ) unless defined $it->{comment} && length $it->{comment};
    return _rtrim( "$pre;;; $it->{comment}" . ( length $kv ? "\n      $kv" : '' ) );
}

sub _settings_get {
    my ( $s, $spec ) = @_;
    return { name => $s->{dev}{identity} // $s->{ctx}{host} // 'MikroTik' } if $spec->{identity};
    my $h = ref $s->{dev}{settings} eq 'HASH' ? $s->{dev}{settings}{ $spec->{path} } : undef;
    return ref $h eq 'HASH' ? $h : {};
}

sub _resource {
    my ($s) = @_;
    my @r = (
        uptime => '3d04:12:31', version => "$VERSION_ROS (stable)", 'build-time' => '2024-11-26 13:15:01',
        'factory-software' => '7.1', 'free-memory' => '811.5MiB', 'total-memory' => '1024.0MiB',
        cpu => 'ARMv7', 'cpu-count' => 4, 'cpu-load' => '2%', 'free-hdd-space' => '3.4MiB',
        'total-hdd-space' => '16.0MiB', 'architecture-name' => 'arm', 'board-name' => 'hEX',
        platform => 'MikroTik',
    );
    my @l;
    while ( my ( $k, $v ) = splice @r, 0, 2 ) { push @l, sprintf '%19s: %s', $k, $v }
    return join "\n", @l;
}

# --- Befehle ------------------------------------------------------------------

sub _c_print {
    my ( $s, $path, $toks, $L ) = @_;
    my $kind = _kind( $s, $path );
    my $spec = _spec( $s, $path );
    if ( $kind eq 'resource' ) { _args( $spec, $toks, $L, words => ['without-paging'] ); return _resource($s) }
    if ( $kind eq 'settings' ) {
        _args( $spec, $toks, $L, words => ['without-paging'] );
        my $h  = _settings_get( $s, $spec );
        my %in = map { $_ => 1 } @{ $spec->{props} };
        my @k  = ( ( grep { exists $h->{$_} } @{ $spec->{props} } ), sort grep { !$in{$_} } keys %$h );
        my ($w) = sort { $b <=> $a } map {length} @k;
        return join "\n", map { sprintf '%*s: %s', ( $w // 0 ) + 2, $_, $h->{$_} // '' } @k;
    }
    my @t = @$toks;
    my ($wi) = grep { !$t[$_]{quoted} && !defined $t[$_]{br} && $t[$_]{text} eq 'where' } 0 .. $#t;
    my @w;
    if ( defined $wi ) {
        @w = @t[ $wi + 1 .. $#t ];
        _errat( 'expected end of command', $L, $t[$wi]{col} + 5 ) unless @w;
        @t = @t[ 0 .. $wi - 1 ];
    }
    my $a    = _args( $spec, \@t, $L, words => [qw( detail terse brief without-paging count-only )] );
    my $cond = defined $wi ? _cond( $spec, \@w, $L ) : sub {1};
    my $list = _list( $s, $path );
    my @idx  = grep { $cond->( $list->[$_] ) } 0 .. $#$list;
    return scalar @idx if $a->{word}{'count-only'};
    if ( $a->{word}{terse} ) {
        return join "\n", map {
            my $it = $list->[$_];
            my @c  = defined $it->{comment} ? ( 'comment=' . _q( $it->{comment} ) ) : ();
            _rtrim( sprintf '%2d %-2s %s', $_, _flags( $spec, $it ), join ' ', @c, _pairs( $spec, $it ) );
        } @idx;
    }
    my $head = 'Flags: ' . join ', ', map {"$_->[0] - $_->[1]"} @{ $spec->{flags} };
    return $head unless @idx;
    return join "\n", $head, join( "\n\n", map { _entry( $spec, $_, $list->[$_] ) } @idx );
}

sub _export_block {
    my ( $s, $path, $terse ) = @_;
    my $spec = _spec( $s, $path );
    my $kind = _kind( $s, $path );
    my $pre  = $terse ? "$path " : '';
    my @l;
    my $kv = sub {
        my ($h) = @_;
        return map { "$_=" . _q( $h->{$_} ) }
            grep { defined $h->{$_} && !$spec->{ro}{$_} && !( $spec->{is_flag}{$_} && !_yes( $h->{$_} ) ) }
            sort keys %$h;
    };
    if ( $kind eq 'settings' ) {
        return () if $spec->{identity} && !defined $s->{dev}{identity};
        my @p = $kv->( _settings_get( $s, $spec ) );
        push @l, $pre . join ' ', 'set', @p if @p;
    }
    elsif ( $kind eq 'list' ) {
        push @l, $pre . join ' ', 'add', $kv->($_) for grep { !_yes( $_->{dynamic} ) } @{ _list( $s, $path ) };
    }
    return () unless @l;
    return $terse ? @l : ( $path, @l );
}

sub _c_export {
    my ( $s, $path, $toks, $L ) = @_;
    my $a = _args( {}, $toks, $L, words => [qw( compact verbose terse hide-sensitive show-sensitive )],
        keys => ['file'] );
    return '' if _take( $a, 'file' );
    my %known = map { $_ => 1 } @EXPORT_ORDER;
    my @extra = sort grep { !$known{$_} && !$MENU{$_} && _kind( $s, $_ ) ne 'dir' } _paths($s);
    my $pre   = $path eq '' ? '/' : "$path ";
    my @l     = ("# by RouterOS $VERSION_ROS");
    for my $p ( @EXPORT_ORDER, @extra ) {
        next unless $path eq '' || $p eq $path || index( $p, $pre ) == 0;
        push @l, _export_block( $s, $p, $a->{word}{terse} );
    }
    return join "\n", @l;
}

sub _fixup {
    my ( $spec, $it, $changed ) = @_;
    return unless $spec->{path} eq '/ip address' && $changed->{address} && defined $it->{address};
    $it->{address} .= '/32' unless $it->{address} =~ m{/};
    return if $changed->{network};
    my ( $n, $m ) = _net( $it->{address} ) or return;
    $it->{network} = _ntoa( $n & $m );
    return;
}

sub _name_taken {
    my ( $list, $name, @except ) = @_;
    for my $it (@$list) {
        next if grep { $_ == $it } @except;
        return 1 if defined $it->{name} && $it->{name} eq $name;
    }
    return 0;
}

sub _c_add {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, props => 'write', keys => ['place-before'] );
    my $before = _take( $a, 'place-before' );
    my ( %it, %changed );
    for ( @{ $a->{kv} } ) {
        my ( $k, $v ) = @$_;
        $v = _norm( $spec, $k, _val( $v, $L ) );
        $changed{$k} = 1;
        next if $v eq '' || ( $spec->{is_flag}{$k} && $v eq 'no' );
        $it{$k} = $v;
    }
    my $list = _list( $s, $path );
    if ( $spec->{autoname} && !defined $it{name} ) {
        my $i = 1;
        $i++ while _name_taken( $list, "$spec->{autoname}$i" );
        $it{name} = "$spec->{autoname}$i";
    }
    for my $r ( @{ $spec->{required} } ) {
        _err("failure: $r not specified") unless defined $it{$r} && length $it{$r};
    }
    _err('failure: already have item with such name') if $spec->{has_name} && defined $it{name} && _name_taken( $list, $it{name} );
    _fixup( $spec, \%it, \%changed );
    my $at = @$list;
    if ($before) {
        my ($ref) = _refs( $s, $spec, $path, $list, $before, $L );
        $at = _index_of( $list, $ref ) if $ref;
    }
    splice @{ _list( $s, $path, 1 ) }, $at, 0, \%it;
    return '';
}

sub _numbers {
    my ( $s, $spec, $path, $a, $L ) = @_;
    my $v = _take( $a, 'numbers' ) // shift @{ $a->{pos} };
    _err('missing value(s) of argument(s) numbers') unless $v;
    return _refs( $s, $spec, $path, _list( $s, $path ), $v, $L );
}

sub _no_dynamic {
    my ( $verb, @refs ) = @_;
    _err("failure: can not $verb dynamic item") if grep { _yes( $_->{dynamic} ) } @refs;
    return;
}

sub _apply {
    my ( $spec, $it, $k, $v ) = @_;
    if ( !defined $v || $v eq '' ) { delete $it->{$k}; return }
    return if $spec->{is_flag}{$k} && $v eq 'no' && !exists $it->{$k};
    $it->{$k} = $v;
    return;
}

sub _c_set {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    if ( _kind( $s, $path ) eq 'settings' ) {
        my $a = _args( $spec, $toks, $L, props => 'write', unset => 1 );
        my @ch = ( ( map { [ $_->[0], _norm( $spec, $_->[0], _val( $_->[1], $L ) ) ] } @{ $a->{kv} } ),
            map { [ $_, undef ] } @{ $a->{unset} } );
        if ( $spec->{identity} ) {
            for (@ch) { $s->{dev}{identity} = $_->[1] if $_->[0] eq 'name' && defined $_->[1] && length $_->[1] }
            return '';
        }
        return '' unless @ch;
        $s->{dev}{settings} = {} unless ref $s->{dev}{settings} eq 'HASH';
        my $h = $s->{dev}{settings}{$path} //= {};
        _apply( $spec, $h, @$_ ) for @ch;
        return '';
    }
    my $a = _args( $spec, $toks, $L, props => 'write', keys => ['numbers'], pos => 1, unset => 1 );
    my @refs = _numbers( $s, $spec, $path, $a, $L );
    my @ch   = ( ( map { [ $_->[0], _norm( $spec, $_->[0], _val( $_->[1], $L ) ) ] } @{ $a->{kv} } ),
        map { [ $_, undef ] } @{ $a->{unset} } );
    return '' unless @ch;
    _no_dynamic( 'change', @refs );
    my ($name) = map { $_->[1] } grep { $_->[0] eq 'name' && defined $_->[1] && length $_->[1] } @ch;
    _err('failure: already have item with such name')
        if defined $name && ( @refs > 1 || _name_taken( _list( $s, $path ), $name, @refs ) );
    my %changed = map { $_->[0] => 1 } @ch;
    for my $it (@refs) {
        _apply( $spec, $it, @$_ ) for @ch;
        _fixup( $spec, $it, \%changed );
    }
    return '';
}

sub _c_remove {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, keys => ['numbers'], pos => 1 );
    my @refs = _numbers( $s, $spec, $path, $a, $L );
    _no_dynamic( 'remove', @refs ) unless $spec->{lease};
    my $list = _list( $s, $path );
    my %gone = map { $_ => 1 } @refs;
    @$list = grep { !$gone{$_} } @$list;
    return '';
}

sub _endis {
    my ( $s, $path, $toks, $L, $v ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, keys => ['numbers'], pos => 1 );
    my @refs = _numbers( $s, $spec, $path, $a, $L );
    _no_dynamic( 'change', @refs );
    _apply( $spec, $_, disabled => $v ) for @refs;
    return '';
}
sub _c_disable { return _endis( @_, 'yes' ) }
sub _c_enable  { return _endis( @_, 'no' ) }

sub _c_comment {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, keys => [qw( numbers comment )], pos => 2 );
    my $c    = _take( $a, 'comment' );
    my $num  = _take( $a, 'numbers' ) // shift @{ $a->{pos} };
    $c //= shift @{ $a->{pos} };
    _errat( 'expected end of command', $L, $a->{pos}[0]{col} ) if @{ $a->{pos} };
    _err('missing value(s) of argument(s) numbers') unless $num;
    _err('missing value(s) of argument(s) comment') unless $c;
    my $text = _val( $c, $L );
    my @refs = _refs( $s, $spec, $path, _list( $s, $path ), $num, $L );
    _no_dynamic( 'change', @refs );
    _apply( $spec, $_, comment => $text ) for @refs;
    return '';
}

sub _c_move {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, keys => [qw( numbers destination )], pos => 2 );
    my $dv   = _take( $a, 'destination' );
    my $num  = _take( $a, 'numbers' ) // shift @{ $a->{pos} };
    $dv //= shift @{ $a->{pos} };
    _errat( 'expected end of command', $L, $a->{pos}[0]{col} ) if @{ $a->{pos} };
    _err('missing value(s) of argument(s) numbers') unless $num;
    my $list = _list( $s, $path );
    my @refs = _refs( $s, $spec, $path, $list, $num, $L );
    my ($dest) = $dv ? _refs( $s, $spec, $path, $list, $dv, $L ) : ();
    _no_dynamic( 'move', @refs );
    return '' if $dest && grep { $_ == $dest } @refs;
    my %mv   = map { $_ => 1 } @refs;
    my @keep = grep { !$mv{$_} } @$list;
    my @move = grep { $mv{$_} } @$list;    # Reihenfolge der Liste behalten
    my $at   = $dest ? _index_of( \@keep, $dest ) : @keep;
    splice @keep, $at, 0, @move;
    @$list = @keep;
    return '';
}

sub _c_find {
    my ( $s, $path, $toks, $L ) = @_;
    my @t = @$toks;
    shift @t if @t && !$t[0]{quoted} && $t[0]{text} eq 'where';
    _cond( _spec( $s, $path ), \@t, $L );
    return '';
}

sub _c_make_static {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, keys => ['numbers'], pos => 1 );
    delete $_->{dynamic} for _numbers( $s, $spec, $path, $a, $L );
    return '';
}

sub _c_noop {
    my ( $s, $path, $toks, $L ) = @_;
    my $spec = _spec( $s, $path );
    my $a    = _args( $spec, $toks, $L, keys => ['numbers'], pos => 1 );
    _numbers( $s, $spec, $path, $a, $L ) if @{ $a->{pos} } || @{ $a->{kv} };
    return '';
}

sub _c_reboot {
    my ( $s, $path, $toks, $L ) = @_;
    _args( {}, $toks, $L );
    $s->{dev}{reboots} = ( $s->{dev}{reboots} // 0 ) + 1;
    return { out => "Reboot, yes? [y/N]: y\nsystem will reboot shortly", stop => 1 };
}

sub _c_shutdown {
    my ( $s, $path, $toks, $L ) = @_;
    _args( {}, $toks, $L );
    $s->{dev}{shutdown} = 'yes';
    return { out => "Shutdown, yes? [y/N]: y\nsystem will shutdown promptly", stop => 1 };
}

# --- ping / traceroute aus dem Zustand ----------------------------------------

sub _ip {
    my ($x) = @_;
    return undef unless defined $x && $x =~ /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/;
    return undef if grep { $_ > 255 } $1, $2, $3, $4;
    return ( $1 << 24 ) | ( $2 << 16 ) | ( $3 << 8 ) | $4;
}

sub _net {
    my ($cidr) = @_;
    my ( $a, $l ) = ( $cidr // '' ) =~ m{\A([\d.]+)(?:/(\d+))?\z} or return;
    $l //= 32;
    return if $l > 32;
    my $n = _ip($a) // return;
    my $m = $l ? ( 0xFFFFFFFF << ( 32 - $l ) ) & 0xFFFFFFFF : 0;
    return ( $n, $m, $l );
}

sub _ntoa { my ($n) = @_; return join '.', map { ( $n >> $_ ) & 255 } 24, 16, 8, 0 }

# { kind => local|connected|routed|blackhole, gw => ip } oder undef
sub _route {
    my ( $s, $ip ) = @_;
    my @conn;
    for my $a ( @{ _list( $s, '/ip address' ) } ) {
        next if _yes( $a->{disabled} ) || _yes( $a->{invalid} );
        my ( $n, $m ) = _net( $a->{address} ) or next;
        return { kind => 'local' } if $n == $ip;
        push @conn, [ $n, $m ];
    }
    my $on_link = sub { my ($x) = @_; return grep { ( $x & $_->[1] ) == ( $_->[0] & $_->[1] ) } @conn };
    return { kind => 'connected' } if $on_link->($ip);
    my ( $best, $bl, $bd );
    for my $r ( @{ _list( $s, '/ip route' ) } ) {
        next if _yes( $r->{disabled} );
        next if defined $r->{'routing-table'} && $r->{'routing-table'} ne 'main';
        my ( $n, $m, $l ) = _net( $r->{'dst-address'} // '0.0.0.0/0' ) or next;
        next unless ( $ip & $m ) == ( $n & $m );
        my $bh = _yes( $r->{blackhole} ) || ( $r->{type} // '' ) =~ /\A(?:blackhole|unreachable|prohibit)\z/;
        my ($gw) = split /,/, $r->{gateway} // '';
        unless ($bh) {
            next unless defined $gw && length $gw;
            my $g = _ip($gw);
            next if defined $g && !$on_link->($g);
        }
        my $d = $r->{distance} // 1;
        $d = 1 unless $d =~ /\A\d+\z/;
        next if $best && ( $l < $bl || ( $l == $bl && $d >= $bd ) );
        ( $best, $bl, $bd ) = ( { kind => $bh ? 'blackhole' : 'routed', gw => defined _ip($gw) ? $gw : undef }, $l, $d );
    }
    return $best;
}

sub _target {
    my ( $s, $toks, $L, @keys ) = @_;
    my $a = _args( {}, $toks, $L, keys => [ 'address', @keys ], pos => 1, words => ['do-not-fragment'] );
    my $t = _take( $a, 'address' ) // shift @{ $a->{pos} };
    _err('missing value(s) of argument(s) address') unless $t;
    my $name = _val( $t, $L );
    my $ip   = _ip($name);
    unless ( defined $ip ) {
        my ($st) = grep { !_yes( $_->{disabled} ) && ( $_->{name} // '' ) eq $name && defined _ip( $_->{address} ) }
            @{ _list( $s, '/ip dns static' ) };
        _err('invalid value for argument address') unless $st;
        $ip = _ip( $st->{address} );
    }
    return ( $a, $ip );
}

sub _c_ping {
    my ( $s, $path, $toks, $L ) = @_;
    my ( $a, $ip ) = _target( $s, $toks, $L,
        qw( count interface src-address size interval ttl routing-table vrf arp-ping ) );
    my %kv    = map { $_->[0] => _val( $_->[1], $L ) } @{ $a->{kv} };
    my $count = $kv{count} // 3;
    _err('invalid value for argument count') unless $count =~ /\A\d+\z/ && $count > 0;
    $count = 10 if $count > 10;
    my $size = $kv{size} // 56;
    _err('invalid value for argument size') unless $size =~ /\A\d+\z/;
    my $host = _ntoa($ip);
    my $r    = _route( $s, $ip );
    my ( $ttl, $time );
    if    ( !$r || $r->{kind} eq 'blackhole' ) { }
    elsif ( $r->{kind} eq 'routed' )           { ( $ttl, $time ) = ( 57, '12ms' ) }
    elsif ( $r->{kind} eq 'local' )            { ( $ttl, $time ) = ( 64, '0ms' ) }
    else                                       { ( $ttl, $time ) = ( 64, '1ms' ) }
    my @l = ('  SEQ HOST                                     SIZE TTL TIME       STATUS');
    for my $i ( 0 .. $count - 1 ) {
        push @l, $ttl
            ? sprintf( '  %3d %-40s %4d %3d %s', $i, $host, $size, $ttl, $time )
            : sprintf( '  %3d %-40s %4s %3s %-10s %s', $i, $host, '', '', '', $r ? 'timeout' : 'no route to host' );
    }
    push @l, $ttl
        ? "    sent=$count received=$count packet-loss=0% min-rtt=$time avg-rtt=$time max-rtt=$time"
        : "    sent=$count received=0 packet-loss=100%";
    return _rtrim( join "\n", @l );
}

sub _c_traceroute {
    my ( $s, $path, $toks, $L ) = @_;
    my ( $a, $ip ) = _target( $s, $toks, $L, qw( count interface src-address size timeout max-hops use-dns protocol port ) );
    my $host = _ntoa($ip);
    my $r    = _route( $s, $ip );
    my @l    = (
        'Columns: ADDRESS, LOSS, SENT, LAST, AVG, BEST, WORST, STD-DEV, STATUS',
        '#  ADDRESS          LOSS  SENT  LAST  AVG   BEST  WORST  STD-DEV  STATUS',
    );
    my $row = sub { my ( $n, $ad, $loss, $last, $st ) = @_;
        push @l, sprintf '%-2d %-16s %-5s %4d  %-5s %-5s %-5s %-6s %-8s %s', $n, $ad, $loss, 3, $last,
            ( $last eq '' ? ('') x 3 : ( $last =~ s/ms//r ) x 3 ), ( $last eq '' ? '' : '0' ), $st };
    if ( !$r || $r->{kind} eq 'blackhole' ) { $row->( 1, '', '100%', '', $r ? 'timeout' : 'no route to host' ) }
    else {
        my @hops = $r->{kind} eq 'routed' && $r->{gw} && $r->{gw} ne $host ? ( $r->{gw}, $host ) : ($host);
        for my $i ( 0 .. $#hops ) { $row->( $i + 1, $hops[$i], '0%', $i ? '12ms' : '1ms', '' ) }
    }
    return _rtrim( join "\n", @l );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::RouterOS - The simulator of device type routeros — a RouterOS (MikroTik) console

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $out, $ok, $gap ) = $sims->run_command( $state, 'r1', '/ip firewall filter print' );

  # directly, as in cai-platform:

  my $dev = {
      type     => 'routeros',
      identity => 'r1',
      menus    => {
          '/ip firewall filter' => [
              { chain => 'forward', action => 'accept', 'connection-state' => 'established,related', comment => 'LAN raus' },
              { chain => 'forward', action => 'drop', disabled => 'yes' },
          ],
          '/ip address' => [ { address => '192.168.88.1/24', interface => 'bridge', network => '192.168.88.0' } ],
      },
      settings => { '/ip dns' => { servers => '9.9.9.9', 'allow-remote-requests' => 'yes' } },
  };

  my ( $output, $ok ) = Langertha::Holmgang::Sim::RouterOS->run( $dev,
      "/ip firewall filter\nmove 1 0\nprint", { host => 'r1' } );

=head1 DESCRIPTION

Simulator of the RouterOS console for the test suites (contract in
L<Langertha::Holmgang::Role::Simulator>). A model types real RouterOS commands
through C<run_command(host, command)>; the common read and change commands are
B<really executed on the state>. What the simulator cannot do, it answers like
a real RouterOS (C<bad command name …>, C<expected end of command (line 1
column N)>, C<no such item>, C<input does not match any value of action>,
C<failure: …>) — never with a hint at a solution. Column numbers are
approximate. There is no file access (no C<write>).

=head2 State of a device

  r1:
    type: routeros
    identity: r1                       # optional, else the host name
    menus:                             # list menus: ordered entries, values as text
      /ip firewall filter:
        - { chain: forward, action: accept, connection-state: "established,related", comment: "LAN raus" }
        - { chain: forward, action: drop, disabled: "yes" }
      /ip address: [ { address: 192.168.88.1/24, interface: bridge, network: 192.168.88.0 } ]
      /ip route:   [ { dst-address: 0.0.0.0/0, gateway: 203.0.113.1, distance: "1" } ]
      /ip dhcp-server lease: [ { address: 192.168.88.20, mac-address: "AA:BB:CC:00:00:01", server: dhcp1, dynamic: "yes" } ]
    settings:                          # settings menus: a hash
      /ip dns: { servers: "9.9.9.9", allow-remote-requests: "yes" }
    reboots: 1                         # set only by the simulator (/system reboot)
    shutdown: "yes"                    # set only by the simulator (/system shutdown)

Flags are properties: C<disabled> (C<X>, missing = C<no>), C<dynamic> (C<D>,
neither changeable nor removable — except by C<lease remove>), C<invalid>
(C<I>), on interfaces C<running> (C<R>). A known menu missing from the state
counts as empty; it is created on the first C<add>. Menus in the state that
the simulator does not know are kept as lists without checking their
properties. C<disabled=no> is written only when the key was already there.

=head2 Menus

Lists: C</ip firewall filter|nat|mangle|raw|address-list>, C</ip address>,
C</ip route>, C</ip pool>, C</ip dhcp-server>, C</ip dhcp-server network>,
C</ip dhcp-server lease>, C</ip dhcp-client>, C</ip dns static>, C</ip arp>,
C</interface> (no add/remove), C</interface ethernet> (no add/remove),
C</interface pppoe-client|vlan|bridge|bridge port|list|list member|wireguard|wireguard peers>.
Settings: C</ip dns>, C</system identity> (writes C<identity>).
Read only: C</system resource>. Each menu has a list of allowed properties
(also the order in C<print>); C<action> only from the menu's value list;
required properties on C<add> (firewall: C<chain>).

=head2 Commands

Paths with or without C</>, also C</ip/firewall/filter>; unique abbreviations
of menus and commands (C</ip fi fi pr>); a line with only a path changes the
menu for the following lines, C</> is the root, C<..> one level up. Several
commands separated by newline or C<;>; lines with C<#> are comments. When a
command aborts, the earlier ones stay executed and the later ones do not run;
each single command changes either completely or not at all.

=over

=item Lists

C<print> (numbered from 0 in the current order, header C<Flags: …>, comment
as C<;;; text>, then C<k=v>), C<print detail>, C<print terse>,
C<print count-only>, C<print where …>; C<add k=v … [place-before=N]>,
C<set N[,M] k=v !k k="">, C<remove>, C<disable>, C<enable>,
C<comment N comment="x">, C<move N [destination=]M> (entry N moves in front of
the entry that now has number M; without a destination to the end; only
firewall, DNS static, bridge ports), C<find>, C<make-static> (leases),
C<reset-counters> (firewall), C<export>. Numbers: C<0>, C<0,2>, C<[find …]>,
for menus with C<name> also the name. Numbers always count over the whole list
(also after C<print where>).

=item find and where

C<[find]>, C<[find k=v k2=v2]>, C<[find where k=v and k2!=v2 or k~"re"]>,
C<[find dynamic=yes]>, C<[find !disabled]>, C<[/ip firewall nat find …]>;
C<not>, C<!>, C<and>/C<&&>, C<or>/C<||> (no parentheses; and before or).

=item Settings

C<print> (C<  servers: 9.9.9.9>, keys right-aligned), C<set k=v>,
C<export>.

=item export

C<export> (also C<compact>, C<verbose>, C<terse>, C<hide-sensitive>) in every
menu, for the subtree; at the root everything. Blocks like RouterOS: path
line, then C<add …> or C<set …>, properties in alphabetical order, values with
spaces in quotes; dynamic entries are left out; C</interface> is not
exported. C<export file=x> prints nothing (no files).

=item System and diagnostics

C</system reboot> increments C<reboots>, C</system shutdown> sets
C<shutdown: yes> (after that the device no longer answers); both end the
call. C</system identity print|set>, C</system resource print> (fixed
values). C<quit> ends the call.

C<ping ADDRESS [count=N]> (default 3, at most 10) and C<traceroute ADDRESS>
are B<not> really simulated but derived from the state: replies come when the
address is one of the device's own, lies in a connected network from
C</ip address>, or an active route from C</ip route> leads to it (table
C<main>, gateway in a connected network or an interface; longest prefix, then
lowest C<distance>); otherwise C<no route to host>, for C<blackhole>
C<timeout>. Names are resolved only through C</ip dns static>. The case's
observations (C<observe>) take precedence and never reach the simulator.

=back

=head2 Limits

No scripting language (C<:put>, C<:foreach>, variables), no C<edit>, no
C<get>, no internal IDs (C<*1>), no dynamic routes from connected networks in
C</ip route print>, no table view, no wrapping of long lines, no logs, no
C</tool sniffer>.

=head2 run

  my ( $output, $ok ) = Langertha::Holmgang::Sim::RouterOS->run( $dev, $command, { host => 'r1' } );

Runs the command lines in C<$command> one after another on the device state
C<$dev> (C<$dev> is changed). Every call starts at the root (a new
session). C<$ok> is false as soon as a command fails; the output then ends
with the error message.

=head2 device_type

C<routeros>.

=head2 run_command

  my ( $output, $ok, $gap ) = $sim->run_command( $dev, $command, $ctx );

L<Langertha::Holmgang::Role::Simulator/run_command>: runs the lines through
L</run>. There is no C<write_file>: a RouterOS device has only its console.

=head2 menus

  my @paths = Langertha::Holmgang::Sim::RouterOS::menus();

The known menus (sorted), for documentation and for checking cases.

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
