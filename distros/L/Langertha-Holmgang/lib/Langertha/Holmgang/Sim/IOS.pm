package Langertha::Holmgang::Sim::IOS;
# ABSTRACT: The simulator of device type ios — a Cisco IOS switch CLI

use Moose;
use namespace::autoclean;
use utf8;

use JSON::MaybeXS ();

with 'Langertha::Holmgang::Role::Simulator';

our $VERSION = '0.002';


# Typen: voller Name, Kurzform, physisch (Nummer mit Schraegstrichen)
my @TYPES = (
    [ 'Port-channel',       'Po', 0 ],
    [ 'FastEthernet',       'Fa', 1 ],
    [ 'GigabitEthernet',    'Gi', 1 ],
    [ 'TenGigabitEthernet', 'Te', 1 ],
    [ 'Vlan',               'Vl', 0 ],
);

my %SUFFIX = ( exec => '#', config => '(config)#', if => '(config-if)#', range => '(config-if-range)#',
    vlan => '(config-vlan)#' );

# --- Grammatik --------------------------------------------------------------------
# Knoten: { kw => 'wort' } oder { param => typ, name => … }; run = ausfuehrbar, sub = Kinder.

my @FILTERS = qw( begin count exclude include section );

my $EXEC = [
    {   kw  => 'show',
        sub => [
            {   kw  => 'running-config',
                run => \&_show_run,
                sub => [ { kw => 'interface', sub => [ { param => 'iface', name => 'if', run => \&_show_run } ] } ],
            },
            {   kw  => 'interfaces',
                run => \&_show_int,
                sub => [
                    { kw => 'trunk',  run => \&_show_int_trunk },
                    { kw => 'status', run => \&_show_int_status },
                    {   param => 'iface',
                        name  => 'if',
                        run   => \&_show_int,
                        sub   => [
                            { kw => 'switchport', run => \&_show_int_switchport },
                            { kw => 'trunk',      run => \&_show_int_trunk },
                            { kw => 'status',     run => \&_show_int_status },
                        ],
                    },
                ],
            },
            {   kw  => 'vlan',
                run => \&_show_vlan,
                sub => [
                    { kw => 'brief', run => \&_show_vlan },
                    { kw => 'id',    sub => [ { param => 'vlan_id', name => 'v', run => \&_show_vlan } ] },
                ],
            },
            { kw => 'version', run => \&_show_version },
            {   kw  => 'ip',
                sub => [ { kw => 'interface', sub => [ { kw => 'brief', run => \&_show_ip_int_brief } ] } ],
            },
        ],
    },
    { kw => 'configure', sub => [ { kw => 'terminal', run => \&_conf_t } ] },
    {   kw  => 'terminal',
        sub => [
            { kw => 'length', sub => [ { param => 'num', name => 'n', max => 512, run => \&_noop } ] },
            { kw => 'width',  sub => [ { param => 'num', name => 'n', max => 512, run => \&_noop } ] },
        ],
    },
    { kw => 'enable', run => \&_noop },
    { kw => 'write',  run => \&_write, sub => [ { kw => 'memory', run => \&_write } ] },
    {   kw  => 'copy',
        sub => [ { kw => 'running-config', sub => [ { kw => 'startup-config', run => \&_copy } ] } ],
    },
    { kw => 'reload', run => \&_reload },
    { kw => 'ping',   sub => [ { param => 'line', name => 'dst', run => \&_ping } ] },
    { kw => 'exit',   run => \&_close },
    { kw => 'logout', run => \&_close },
    { kw => 'end',    run => \&_noop },
];

my $CONFIG = [
    {   kw  => 'interface',
        sub => [
            { kw    => 'range', sub => [ { param => 'line', name => 'range', run => \&_interface_range } ] },
            { param => 'iface', name => 'if', create => 1, run => \&_interface },
        ],
    },
    { kw => 'vlan',     sub => [ { param => 'vlan_list', name => 'vlans', run => \&_vlan } ] },
    { kw => 'hostname', sub => [ { param => 'word',      name => 'name',  run => \&_hostname } ] },
    { kw => 'no', sub => [ { kw => 'vlan', sub => [ { param => 'vlan_list', name => 'vlans', run => \&_no_vlan } ] } ] },
    { kw => 'exit', run => \&_exit },
    { kw => 'end',  run => \&_end },
];

sub _allowed_node {
    my ($op) = @_;
    return { param => 'vlan_list', name => 'l', run => sub { _sw_allowed( @_, $op ) } };
}

my $IF = [
    { kw => 'description', sub => [ { param => 'line', name => 'text', run => \&_description } ] },
    {   kw  => 'switchport',
        run => \&_switchport,
        sub => [
            {   kw  => 'mode',
                sub => [
                    { kw => 'access', run => sub { _sw_set( @_, mode => 'access', 'access' ) } },
                    { kw => 'trunk',  run => sub { _sw_set( @_, mode => 'trunk',  'access' ) } },
                ],
            },
            {   kw  => 'access',
                sub => [ { kw => 'vlan', sub => [ { param => 'vlan_id', name => 'v', run => \&_sw_access } ] } ],
            },
            {   kw  => 'trunk',
                sub => [
                    {   kw  => 'native',
                        sub => [ { kw => 'vlan', sub => [ { param => 'vlan_id', name => 'v', run => \&_sw_native } ] } ],
                    },
                    {   kw  => 'allowed',
                        sub => [
                            {   kw  => 'vlan',
                                sub => [
                                    { kw => 'add',    sub => [ _allowed_node('add') ] },
                                    { kw => 'remove', sub => [ _allowed_node('remove') ] },
                                    { kw => 'except', sub => [ _allowed_node('except') ] },
                                    { kw => 'all',  run => sub { _sw_allowed( @_, 'all' ) } },
                                    { kw => 'none', run => sub { _sw_allowed( @_, 'none' ) } },
                                    _allowed_node('set'),
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    },
    { kw => 'shutdown', run => sub { _shutdown( @_, 1 ) } },
    {   kw  => 'no',
        sub => [
            {   kw  => 'description',
                run => \&_no_description,
                sub => [ { param => 'line', name => 'text', run => \&_no_description } ],
            },
            { kw => 'shutdown', run => sub { _shutdown( @_, 0 ) } },
            {   kw  => 'switchport',
                sub => [
                    { kw => 'mode', run => sub { _sw_set( @_, mode => 'access', 'access' ) }, sub => [ { param => 'line', name => 'x', run => sub { _sw_set( @_, mode => 'access', 'access' ) } } ] },
                    {   kw  => 'access',
                        sub => [
                            {   kw  => 'vlan',
                                run => sub { _sw_set( @_, access_vlan => 1, 1 ) },
                                sub => [ { param => 'vlan_id', name => 'v', run => sub { _sw_set( @_, access_vlan => 1, 1 ) } } ],
                            },
                        ],
                    },
                    {   kw  => 'trunk',
                        sub => [
                            {   kw  => 'native',
                                sub => [
                                    {   kw  => 'vlan',
                                        run => sub { _sw_set( @_, native_vlan => 1, 1 ) },
                                        sub => [ { param => 'vlan_id', name => 'v', run => sub { _sw_set( @_, native_vlan => 1, 1 ) } } ],
                                    },
                                ],
                            },
                            {   kw  => 'allowed',
                                sub => [ { kw => 'vlan', run => sub { _sw_allowed( @_, 'all' ) } } ],
                            },
                        ],
                    },
                ],
            },
        ],
    },
    { kw => 'exit', run => \&_exit },
    { kw => 'end',  run => \&_end },
];

my $VLAN = [
    { kw => 'name', sub => [ { param => 'word', name => 'name', run => \&_vlan_name } ] },
    { kw => 'no',   sub => [ { kw => 'name', run => \&_vlan_name } ] },
    { kw => 'exit', run => \&_exit },
    { kw => 'end',  run => \&_end },
];

my %GRAMMAR = ( exec => $EXEC, config => $CONFIG, if => $IF, range => $IF, vlan => $VLAN );

# --- Einstieg ---------------------------------------------------------------------


sub run {
    my ( $class, $dev, $command, $ctx ) = @_;
    my $S = { dev => $dev, host => $ctx->{host}, mode => 'exec', ifaces => [], vlans => [], ok => 1, out => [], gaps => [] };
    for my $raw ( split /\r?\n/, $command // '' ) {
        last if $S->{closed};
        _line( $S, $raw );
    }
    my $out = join "\n", grep { length } @{ $S->{out} };
    $out =~ s/[ \t]+$//mg;
    $out =~ s/\n+\z//;
    return ( $out, $S->{ok} ? 1 : 0, @{ $S->{gaps} } ? join( '; ', @{ $S->{gaps} } ) : undef );
}

sub device_type { 'ios' }


sub run_command {
  my ( $self, $dev, $command, $ctx ) = @_;
  return $self->run( $dev, $command, $ctx );
}

sub _prompt {
    my ($S) = @_;
    return ( $S->{dev}{hostname} // $S->{host} // 'Switch' ) . $SUFFIX{ $S->{mode} };
}

sub _tokens {
    my ($line) = @_;
    my @t;
    while ( $line =~ /(\|)|([^\s|]+)/g ) { push @t, { t => $1 // $2, pos => $-[0] } }
    return @t;
}

sub _line {
    my ( $S, $raw ) = @_;
    ( my $line = $raw ) =~ s/\s+\z//;
    $line =~ s/\A\s+//;
    return if $line eq '' || $line =~ /\A!/;
    my @tok    = _tokens($line);
    my $prompt = _prompt($S);

    my ( $r, @filter );
    if ( $S->{mode} eq 'exec' || lc $tok[0]{t} eq 'do' ) {
        shift @tok if $S->{mode} ne 'exec';
        my ($bar) = grep { $tok[$_]{t} eq '|' } 0 .. $#tok;
        @filter = splice @tok, $bar if defined $bar;
        $r = @tok ? _parse( $S, $EXEC, \@tok ) : { error => 'incomplete' };
        if ( $r->{run} && @filter ) {
            my $f = _parse_filter( \@filter, $line );
            $r = $f if $f->{error};
            $r->{filter} = $f unless $f->{error};
        }
    }
    else {
        $r = _parse( $S, $GRAMMAR{ $S->{mode} }, \@tok );
        if ( $r->{error} && $S->{mode} ne 'config' ) {
            my $g = _parse( $S, $CONFIG, \@tok );
            if ( $g->{run} ) {
                $S->{mode} = 'config';
                $r = $g;
            }
            elsif ( $r->{error} eq 'invalid' && $g->{error} eq 'invalid' && $g->{pos} > $r->{pos} ) {
                $r = $g;
            }
        }
    }

    if ( !$r->{error} ) {
        my ( $out, $ok, $bad ) = $r->{run}->( $S, $r->{args} );
        if ( defined $bad ) {
            $r = { error => 'invalid', pos => $bad };
        }
        else {
            $out //= '';
            $out = _filter( $out, @{ $r->{filter} }{qw(kw re)} ) if $r->{filter};
            push @{ $S->{out} }, $out;
            $S->{ok} = 0 if defined $ok && !$ok;
            return;
        }
    }
    # Ein echter show-/Diagnosebefehl, den der Simulator nicht kennt: neutrale
    # (leere) Antwort, als Luecke gemeldet — kein Fehler des Modells.
    # Nur wenn das Thema hinter show selbst unbekannt ist (nicht bei Tippfehlern
    # in Argumenten, Mehrdeutigkeit oder unvollstaendigen Befehlen).
    my ($subj) = $line =~ /\A((?:do\s+)?(?:sh|sho|show|traceroute|trace)\s+)\S/i;
    if ( ( $S->{mode} eq 'exec' || $line =~ /\Ado\s/i ) && defined $subj
        && $r->{error} eq 'invalid' && $r->{pos} == length $subj ) {
        push @{ $S->{gaps} }, $line;
        return;
    }
    $S->{ok} = 0;
    my $msg
        = $r->{error} eq 'invalid'   ? ( ' ' x ( length($prompt) + $r->{pos} ) ) . "^\n% Invalid input detected at '^' marker."
        : $r->{error} eq 'ambiguous' ? qq{% Ambiguous command:  "$line"}
        :                              '% Incomplete command.';
    push @{ $S->{out} }, "$prompt$line\n$msg";
    return;
}

# --- Parser -----------------------------------------------------------------------

sub _common {
    my ( $w, @cands ) = @_;
    my $best = 0;
    for my $c (@cands) {
        my $n = 0;
        $n++ while $n < length $w && $n < length $c && lc substr( $w, $n, 1 ) eq lc substr( $c, $n, 1 );
        $best = $n if $n > $best;
    }
    return $best;
}

sub _parse {
    my ( $S, $level, $toks ) = @_;
    my ( $node, %args );
    my $i = 0;
    while ( $i < @$toks ) {
        my $tok = $toks->[$i];
        my $w   = lc $tok->{t};
        my @kw  = grep { $_->{kw} } @$level;
        my @hit = grep { index( $_->{kw}, $w ) == 0 } @kw;
        my ($exact) = grep { $_->{kw} eq $w } @hit;
        @hit = ($exact) if $exact;
        return { error => 'ambiguous' } if @hit > 1;
        my $child;
        if (@hit) {
            $child = $hit[0];
            $args{_at}{ $child->{kw} } //= $tok->{pos};
            $i++;
        }
        else {
            my $kwpos = $tok->{pos} + _common( $w, map { $_->{kw} } @kw );
            my ($p) = grep { $_->{param} } @$level;
            return { error => 'invalid', pos => $kwpos } unless $p;
            my ( $val, $n, $err ) = _param( $S, $p, $toks, $i );
            if ($err) {
                $err->{pos} = $kwpos if $err->{error} eq 'invalid' && $kwpos > $err->{pos};
                return $err;
            }
            $args{ $p->{name} } = $val;
            $args{_pos}{ $p->{name} } = $tok->{pos};
            $i += $n;
            $child = $p;
        }
        $node  = $child;
        $level = $child->{sub} || [];
    }
    return { error => 'incomplete' } unless $node && $node->{run};
    return { run => $node->{run}, args => \%args };
}

sub _param {
    my ( $S, $p, $toks, $i ) = @_;
    my $tok = $toks->[$i];
    my $t   = $tok->{t};
    my $bad = { error => 'invalid', pos => $tok->{pos} };
    my $type = $p->{param};
    if ( $type eq 'line' ) {
        return ( _rest( $toks, $i ), scalar( @$toks ) - $i );
    }
    return ( $t, 1 ) if $type eq 'word';
    if ( $type eq 'num' ) {
        return ( $t, 1 ) if $t =~ /\A\d+\z/ && $t <= $p->{max};
        return ( undef, 0, $bad );
    }
    if ( $type eq 'vlan_id' ) {
        return ( 0 + $t, 1 ) if $t =~ /\A\d+\z/ && $t >= 1 && $t <= 4094;
        return ( undef, 0, $bad );
    }
    if ( $type eq 'vlan_list' ) {
        my $l = parse_vlan_list($t) or return ( undef, 0, $bad );
        return ( $l, 1 );
    }
    return _param_iface( $S, $p, $toks, $i ) if $type eq 'iface';
    die "unbekannter Parametertyp $type";
}

# Rohtext ab Token $i: die Zeile ist in den Tokens nicht mehr vorhanden, also zusammensetzen
sub _rest {
    my ( $toks, $i ) = @_;
    my $s    = '';
    my $base = $toks->[$i]{pos};
    for my $k ( $i .. $#$toks ) {
        my $off = $toks->[$k]{pos} - $base;
        $s .= ' ' x ( $off - length $s ) if $off > length $s;
        $s .= $toks->[$k]{t};
    }
    return $s;
}

sub _type_for {
    my ($pre) = @_;
    my @m = grep { index( lc $_->[0], lc $pre ) == 0 } @TYPES;
    return @m;
}

sub _param_iface {
    my ( $S, $p, $toks, $i ) = @_;
    my $tok = $toks->[$i];
    my ( $pre, $num ) = $tok->{t} =~ /\A([A-Za-z][A-Za-z-]*)(.*)\z/
        or return ( undef, 0, { error => 'invalid', pos => $tok->{pos} } );
    my @m = _type_for($pre);
    return ( undef, 0, { error => 'invalid', pos => $tok->{pos} + _common( $pre, map { $_->[0] } @TYPES ) } )
        unless @m;
    return ( undef, 0, { error => 'ambiguous' } ) if @m > 1;
    my ( $npos, $n ) = ( $tok->{pos} + length $pre, 1 );
    if ( $num eq '' ) {
        my $nt = $toks->[ $i + 1 ] or return ( undef, 0, { error => 'incomplete' } );
        ( $num, $npos, $n ) = ( $nt->{t}, $nt->{pos}, 2 );
    }
    my $type = $m[0];
    my $fmt  = $type->[2] ? $num =~ m{\A\d+(?:/\d+){1,2}\z} : $num =~ /\A\d+\z/;
    my $full = $type->[0] . $num;
    return ( $full, $n ) if $fmt && ( $S->{dev}{interfaces} || {} )->{$full};
    return ( $full, $n ) if $fmt && $p->{create} && !$type->[2] && $num >= 1 && $num <= 4094;
    return ( undef, 0, { error => 'invalid', pos => $npos } );
}

sub _parse_filter {
    my ( $toks, $line ) = @_;
    my $kt = $toks->[1] or return { error => 'incomplete' };
    my $w   = lc $kt->{t};
    my @hit = grep { index( $_, $w ) == 0 } @FILTERS;
    return { error => 'invalid', pos => $kt->{pos} + _common( $w, @FILTERS ) } unless @hit;
    return { error => 'ambiguous' } if @hit > 1;
    my $rt = $toks->[2] or return { error => 'incomplete' };
    my $re = substr $line, $rt->{pos};
    return { kw => $hit[0], re => $re };
}

sub _filter {
    my ( $text, $kw, $re ) = @_;
    my $rx = eval { qr/$re/ } // qr/\Q$re\E/;
    my @l  = split /\n/, $text;
    if ( $kw eq 'include' ) { return join "\n", grep { /$rx/ } @l }
    if ( $kw eq 'exclude' ) { return join "\n", grep { !/$rx/ } @l }
    if ( $kw eq 'count' ) {
        my $n = grep { /$rx/ } @l;
        return "Number of lines which match regexp = $n";
    }
    if ( $kw eq 'begin' ) {
        my ($k) = grep { $l[$_] =~ $rx } 0 .. $#l;
        return defined $k ? join "\n", @l[ $k .. $#l ] : '';
    }
    # section: Kopfzeile + eingerueckte Folgezeilen, ganzer Block bei einem Treffer
    my ( @out, @block );
    my $flush = sub { push @out, @block if grep { /$rx/ } @block; @block = () };
    for my $x (@l) {
        $flush->() if $x !~ /\A\s/;
        push @block, $x;
    }
    $flush->();
    return join "\n", @out;
}

# --- Hilfen am Zustand ------------------------------------------------------------


sub parse_vlan_list {
    my ($s) = @_;
    return undef unless defined $s && $s =~ /\A\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*\z/;
    my %v;
    for my $part ( split /,/, $s ) {
        my ( $lo, $hi ) = split /-/, $part;
        $hi //= $lo;
        return undef if $lo < 1 || $hi > 4094 || $lo > $hi;
        $v{$_} = 1 for $lo .. $hi;
    }
    return [ sort { $a <=> $b } map { 0 + $_ } keys %v ];
}


sub format_vlan_list {
    my @v = sort { $a <=> $b } @_;
    my @out;
    while (@v) {
        my $s = shift @v;
        my $e = $s;
        $e = shift @v while @v && $v[0] == $e + 1;
        push @out, $e - $s >= 2 ? "$s-$e" : $e > $s ? ( $s, $e ) : $s;
    }
    return join ',', @out;
}

sub _split_name {
    my ($name) = @_;
    for my $k ( 0 .. $#TYPES ) {
        return ( $k, $1 ) if $name =~ /\A\Q$TYPES[$k][0]\E(\d.*)\z/;
    }
    return ( 99, $name );
}

sub _short {
    my ($name) = @_;
    my ( $k, $num ) = _split_name($name);
    return $k == 99 ? $name : $TYPES[$k][1] . $num;
}

sub _is_svi { return ( _split_name( $_[0] ) )[0] == 4 }

sub _sorted_ifaces {
    my ($S) = @_;
    my $ifs = $S->{dev}{interfaces} || {};
    my %key;
    for my $n ( keys %$ifs ) {
        my ( $k, $num ) = _split_name($n);
        $key{$n} = join '.', sprintf( '%02d', $k ), map { sprintf '%06d', $_ } $num =~ /(\d+)/g;
    }
    return sort { $key{$a} cmp $key{$b} || $a cmp $b } keys %$ifs;
}

sub _mode   { $_[0]{mode} // 'access' }
sub _native { $_[0]{native_vlan} // 1 }
sub _access { $_[0]{access_vlan} // 1 }

sub _status {
    my ($if) = @_;
    return 'disabled' if $if->{shutdown};
    my $s = $if->{status} // 'connected';
    return $s eq 'disabled' ? 'notconnect' : $s;
}

# undef = alle
sub _allowed {
    my ($if) = @_;
    my $t = $if->{trunk_allowed};
    return undef if !defined $t || !ref $t;
    return [ sort { $a <=> $b } map { 0 + $_ } @$t ];
}

sub _vlans { $_[0]{dev}{vlans} || {} }

sub _vname {
    my ( $S, $v ) = @_;
    my $e = _vlans($S)->{$v};
    return ref $e eq 'HASH' && defined $e->{name} ? $e->{name} : !ref $e && defined $e ? $e : sprintf 'VLAN%04d', $v;
}

sub _same {
    my ( $x, $y ) = @_;
    return 1 if !defined $x && !defined $y;
    return 0 if !defined $x || !defined $y;
    return join( ',', @$x ) eq join( ',', @$y ) if ref $x eq 'ARRAY' && ref $y eq 'ARRAY';
    return 0 if ref $x eq 'ARRAY' || ref $y eq 'ARRAY';
    return "$x" eq "$y";
}

sub _set {
    my ( $h, $k, $v, $default ) = @_;
    my $cur = exists $h->{$k} ? $h->{$k} : $default;
    $h->{$k} = $v unless _same( $cur, $v );
    return;
}

sub _cur_ifaces {
    my ($S) = @_;
    return map { $S->{dev}{interfaces}{$_} } @{ $S->{ifaces} };
}

# --- Exec-Befehle -----------------------------------------------------------------

sub _noop { return '' }

sub _close { $_[0]{closed} = 1; return '' }

sub _conf_t {
    my ($S) = @_;
    $S->{mode} = 'config';
    return 'Enter configuration commands, one per line.  End with CNTL/Z.';
}

sub _write { return "Building configuration...\n[OK]" }

sub _copy { return "Destination filename [startup-config]? \nBuilding configuration...\n[OK]" }

sub _reload {
    my ($S) = @_;
    $S->{dev}{reloads} = ( $S->{dev}{reloads} // 0 ) + 1;
    $S->{closed} = 1;
    my $host = $S->{host} // $S->{dev}{hostname} // 'Switch';
    return "Proceed with reload? [confirm]\n\nConnection to $host closed by remote host.";
}

sub _ping {
    my ( $S, $g ) = @_;
    my ($dst) = split ' ', $g->{dst};
    my @o = $dst =~ /\A(\d+)\.(\d+)\.(\d+)\.(\d+)\z/;
    return ( '% Unrecognized host or address, or protocol not running.', 0 ) unless @o == 4 && !grep { $_ > 255 } @o;
    return join "\n", 'Type escape sequence to abort.',
        "Sending 5, 100-byte ICMP Echos to $dst, timeout is 2 seconds:", '!!!!!',
        'Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/2 ms';
}

sub _if_lines {
    my ( $name, $if ) = @_;
    my @l = ("interface $name");
    push @l, " description $if->{description}" if defined $if->{description} && length $if->{description};
    if ( _is_svi($name) ) {
        push @l, ' no ip address';
    }
    else {
        push @l, ' switchport access vlan ' . _access($if) if _access($if) != 1;
        push @l, ' switchport trunk native vlan ' . _native($if) if _native($if) != 1;
        my $al = _allowed($if);
        push @l, ' switchport trunk allowed vlan ' . ( @$al ? format_vlan_list(@$al) : 'none' ) if $al;
        push @l, " switchport mode $if->{mode}" if defined $if->{mode};
    }
    push @l, ' shutdown' if $if->{shutdown};
    return @l;
}

sub _show_run {
    my ( $S, $g ) = @_;
    my $ifs = $S->{dev}{interfaces} || {};
    my @body;
    if ( defined $g->{if} ) {
        @body = ( '!', _if_lines( $g->{if}, $ifs->{ $g->{if} } ), 'end' );
    }
    else {
        @body = (
            '!', 'version 17.9', 'service timestamps debug datetime msec', 'service timestamps log datetime msec',
            '!', 'hostname ' . ( $S->{dev}{hostname} // $S->{host} // 'Switch' ),
            '!', 'vtp mode transparent', '!', 'spanning-tree mode rapid-pvst', 'spanning-tree extend system-id', '!',
        );
        for my $v ( sort { $a <=> $b } grep { $_ != 1 } keys %{ _vlans($S) } ) {
            my $name = _vname( $S, $v );
            push @body, "vlan $v", ( $name ne sprintf( 'VLAN%04d', $v ) ? " name $name" : () ), '!';
        }
        push @body, _if_lines( $_, $ifs->{$_} ), '!' for _sorted_ifaces($S);
        push @body, 'end';
    }
    my $text = join "\n", @body;
    return join "\n", 'Building configuration...', '', 'Current configuration : ' . ( length($text) + 1 ) . ' bytes',
        $text;
}

sub _trunking {
    my ( $S, $only ) = @_;
    my $ifs = $S->{dev}{interfaces} || {};
    return grep {
        ( !defined $only || $_ eq $only ) && !_is_svi($_) && _mode( $ifs->{$_} ) eq 'trunk'
            && _status( $ifs->{$_} ) eq 'connected'
    } _sorted_ifaces($S);
}

sub _show_int_trunk {
    my ( $S, $g ) = @_;
    my $ifs   = $S->{dev}{interfaces} || {};
    my @ports = _trunking( $S, $g->{if} );
    return '' unless @ports;
    my %have = map { $_ => 1 } keys %{ _vlans($S) };
    my ( @allowed, @active );
    for my $p (@ports) {
        my $al  = _allowed( $ifs->{$p} );
        my @act = $al ? grep { $have{$_} } @$al : sort { $a <=> $b } keys %have;
        push @allowed, $al ? ( @$al ? format_vlan_list(@$al) : 'none' ) : '1-4094';
        push @active, @act ? format_vlan_list(@act) : 'none';
    }
    my @l = ( '', sprintf( '%-12s%-17s%-15s%-14s%s', 'Port', 'Mode', 'Encapsulation', 'Status', 'Native vlan' ) );
    push @l, sprintf( '%-12s%-17s%-15s%-14s%s', _short($_), 'on', '802.1q', 'trunking', _native( $ifs->{$_} ) )
        for @ports;
    for my $sec ( [ 'Vlans allowed on trunk', \@allowed ], [ 'Vlans allowed and active in management domain', \@active ],
        [ 'Vlans in spanning tree forwarding state and not pruned', \@active ] )
    {
        push @l, '', sprintf( '%-12s%s', 'Port', $sec->[0] );
        push @l, sprintf( '%-12s%s', _short( $ports[$_] ), $sec->[1][$_] ) for 0 .. $#ports;
    }
    return join "\n", @l;
}

sub _show_int_status {
    my ( $S, $g ) = @_;
    my $ifs = $S->{dev}{interfaces} || {};
    my @l   = ( '', 'Port      Name               Status       Vlan       Duplex  Speed Type' );
    for my $n ( _sorted_ifaces($S) ) {
        next if _is_svi($n) || defined $g->{if} && $n ne $g->{if};
        my $if  = $ifs->{$n};
        my $st  = _status($if);
        my $up  = $st eq 'connected';
        my $typ = ( _split_name($n) )[0] == 3 ? 'SFP-10GBase-SR' : '10/100/1000BaseTX';
        push @l, sprintf( '%-9s %-18.18s %-12s %-10s %6s %6s %s',
            _short($n), $if->{description} // '', $st, _mode($if) eq 'trunk' ? 'trunk' : _access($if),
            $up ? 'a-full' : 'auto', $up ? ( $typ =~ /10G/ ? 'a-10G' : 'a-1000' ) : 'auto', $typ );
    }
    return join "\n", @l;
}

sub _show_int_switchport {
    my ( $S, $g ) = @_;
    my $if    = $S->{dev}{interfaces}{ $g->{if} };
    return ( '', 0, $g->{_at}{switchport} ) if _is_svi( $g->{if} );
    my $trunk = _mode($if) eq 'trunk';
    my $up    = _status($if) eq 'connected';
    my $adm   = $trunk ? 'trunk' : 'static access';
    my $al    = _allowed($if);
    my $vl    = sub { my $v = shift; $v . ' (' . ( $v == 1 ? 'default' : _vname( $S, $v ) ) . ')' };
    return join "\n",
        'Name: ' . _short( $g->{if} ),
        'Switchport: Enabled',
        "Administrative Mode: $adm",
        'Operational Mode: ' . ( $up ? $adm : 'down' ),
        'Administrative Trunking Encapsulation: dot1q',
        ( $up && $trunk ? 'Operational Trunking Encapsulation: dot1q' : () ),
        'Negotiation of Trunking: ' . ( $trunk ? 'On' : 'Off' ),
        'Access Mode VLAN: ' . $vl->( _access($if) ),
        'Trunking Native Mode VLAN: ' . $vl->( _native($if) ),
        'Administrative Native VLAN tagging: enabled',
        'Voice VLAN: none',
        'Administrative private-vlan host-association: none',
        'Administrative private-vlan mapping: none',
        'Operational private-vlan: none',
        'Trunking VLANs Enabled: ' . ( !$al ? 'ALL' : @$al ? format_vlan_list(@$al) : 'NONE' ),
        'Pruning VLANs Enabled: 2-1001',
        'Capture Mode Disabled',
        'Capture VLANs Allowed: ALL',
        '',
        'Protected: false',
        'Unknown unicast blocked: disabled',
        'Unknown multicast blocked: disabled',
        'Appliance trust: none';
}

sub _show_int {
    my ( $S, $g ) = @_;
    my $ifs = $S->{dev}{interfaces} || {};
    my @names = defined $g->{if} ? ( $g->{if} ) : _sorted_ifaces($S);
    my @out;
    my %idx = do { my $k = 0; map { $_ => ++$k } _sorted_ifaces($S) };
    for my $n (@names) {
        my $if = $ifs->{$n};
        my $st = _status($if);
        my $head
            = $st eq 'connected' ? 'is up, line protocol is up'
            : $st eq 'disabled'  ? 'is administratively down, line protocol is down'
            :                      'is down, line protocol is down';
        my $mac = sprintf '00a3.d1c0.%04x', 0x100 + $idx{$n};
        push @out, "$n $head" . ( _is_svi($n) ? '' : " ($st)" ),
            '  Hardware is ' . ( _is_svi($n) ? 'Ethernet SVI' : 'Gigabit Ethernet' ) . ", address is $mac (bia $mac)",
            ( defined $if->{description} && length $if->{description} ? "  Description: $if->{description}" : () ),
            '  MTU 1500 bytes, BW 1000000 Kbit/sec, DLY 10 usec,',
            '     reliability 255/255, txload 1/255, rxload 1/255',
            '  Encapsulation ARPA, loopback not set';
    }
    return join "\n", @out;
}

sub _show_vlan {
    my ( $S, $g ) = @_;
    my $ifs  = $S->{dev}{interfaces} || {};
    my %have = %{ _vlans($S) };
    my @vl   = sort { $a <=> $b } grep { $_ < 1002 || $_ > 1005 } keys %have;
    if ( defined $g->{v} ) {
        return ( "VLAN id $g->{v} not found in current VLAN database", 0 ) unless exists $have{ $g->{v} };
        @vl = ( $g->{v} );
    }
    my %ports;
    for my $n ( _sorted_ifaces($S) ) {
        next if _is_svi($n) || _mode( $ifs->{$n} ) eq 'trunk';
        push @{ $ports{ _access( $ifs->{$n} ) } }, _short($n);
    }
    my @l = ( '', 'VLAN Name                             Status    Ports',
        '---- -------------------------------- --------- -------------------------------' );
    for my $v (@vl) {
        my @p = @{ $ports{$v} || [] };
        my @chunk;
        push @chunk, join ', ', splice @p, 0, 4 while @p;
        push @l, sprintf( '%-4s %-32.32s %-9s %s', $v, _vname( $S, $v ), 'active', shift(@chunk) // '' );
        push @l, ( ' ' x 48 ) . $_ for @chunk;
    }
    unless ( defined $g->{v} ) {
        push @l, sprintf( '%-4s %-32s %s', @$_, 'act/unsup' )
            for [ 1002, 'fddi-default' ], [ 1003, 'token-ring-default' ], [ 1004, 'fddinet-default' ],
            [ 1005, 'trnet-default' ];
    }
    return join "\n", @l;
}

sub _show_ip_int_brief {
    my ($S) = @_;
    my $ifs = $S->{dev}{interfaces} || {};
    my @l   = ( sprintf '%-22s %-15s %-3s %-6s %-21s %s', 'Interface', 'IP-Address', 'OK?', 'Method', 'Status', 'Protocol' );
    for my $n ( _sorted_ifaces($S) ) {
        my $st = _status( $ifs->{$n} );
        push @l, sprintf '%-22s %-15s %-3s %-6s %-21s %s', $n, 'unassigned', 'YES', 'unset',
            $st eq 'connected' ? 'up' : $st eq 'disabled' ? 'administratively down' : 'down',
            $st eq 'connected' ? 'up' : 'down';
    }
    return join "\n", @l;
}

sub _show_version {
    my ($S) = @_;
    my $host = $S->{dev}{hostname} // $S->{host} // 'Switch';
    my $rl   = $S->{dev}{reloads} // 0;
    return join "\n",
        'Cisco IOS XE Software, Version 17.09.04a',
        'Cisco IOS Software [Cupertino], Catalyst L3 Switch Software (CAT9K_IOSXE), Version 17.9.4a, RELEASE SOFTWARE (fc3)',
        'Technical Support: http://www.cisco.com/techsupport',
        'Copyright (c) 1986-2023 by Cisco Systems, Inc.',
        '',
        'ROM: IOS-XE ROMMON',
        'BOOTLDR: System Bootstrap, Version 17.9.1r, RELEASE SOFTWARE (P)',
        '',
        "$host uptime is " . ( $rl ? '1 minute' : '6 weeks, 2 days, 3 hours, 14 minutes' ),
        'System returned to ROM by ' . ( $rl ? 'Reload Command' : 'PowerOn' ),
        'System image file is "flash:packages.conf"',
        '',
        'cisco C9300-48P (X86) processor with 1392780K/6147K bytes of memory.',
        '48 Gigabit Ethernet interfaces',
        '8 Ten Gigabit Ethernet interfaces',
        '',
        'Configuration register is 0x102';
}

# --- Konfiguration ----------------------------------------------------------------

sub _exit {
    my ($S) = @_;
    $S->{mode} = $S->{mode} eq 'config' ? 'exec' : 'config';
    return '';
}

sub _end { $_[0]{mode} = 'exec'; return '' }

sub _hostname { $_[0]{dev}{hostname} = $_[1]{name}; return '' }

sub _interface {
    my ( $S, $g ) = @_;
    $S->{dev}{interfaces}{ $g->{if} } //= {};
    $S->{mode}   = 'if';
    $S->{ifaces} = [ $g->{if} ];
    return '';
}

sub _interface_range {
    my ( $S, $g ) = @_;
    my $txt  = $g->{range};
    my $base = $g->{_pos}{range};
    my $ifs  = $S->{dev}{interfaces} || {};
    my ( @names, $off );
    for my $part ( split /,/, $txt ) {
        $off = index( $txt, $part, $off // 0 );
        my ( $pre, $num, $last ) = $part =~ m{\A\s*([A-Za-z][A-Za-z-]*)\s*(\d+(?:/\d+)*)\s*(?:-\s*(\d+))?\s*\z}
            or return ( '', 0, $base + $off + ( $part =~ /\A(\s*)/ ? length $1 : 0 ) );
        my @m = _type_for($pre);
        return ( '', 0, $base + $off ) unless @m == 1;
        my ( $stem, $first ) = $num =~ m{\A(.*?)(\d+)\z};
        $last //= $first;
        return ( '', 0, $base + $off ) if $last < $first;
        for my $k ( $first .. $last ) {
            my $full = $m[0][0] . $stem . $k;
            return ( '', 0, $base + $off ) unless $ifs->{$full};
            push @names, $full;
        }
        $off += length $part;
    }
    $S->{mode}   = 'range';
    $S->{ifaces} = \@names;
    return '';
}

sub _vlan {
    my ( $S, $g ) = @_;
    for my $v ( @{ $g->{vlans} } ) {
        $S->{dev}{vlans}{$v} //= { name => sprintf 'VLAN%04d', $v };
    }
    $S->{mode}  = 'vlan';
    $S->{vlans} = $g->{vlans};
    return '';
}

sub _no_vlan {
    my ( $S, $g ) = @_;
    my @err;
    for my $v ( @{ $g->{vlans} } ) {
        if ( $v == 1 || ( $v >= 1002 && $v <= 1005 ) ) { push @err, "%Default VLAN $v may not be deleted."; next }
        delete $S->{dev}{vlans}{$v} if $S->{dev}{vlans};
    }
    return ( join( "\n", @err ), @err ? 0 : 1 );
}

sub _vlan_name {
    my ( $S, $g ) = @_;
    my @err;
    for my $v ( @{ $S->{vlans} } ) {
        if ( $v == 1 ) { push @err, "%Default VLAN $v may not have its name changed."; next }
        my $e = $S->{dev}{vlans}{$v};
        $e = $S->{dev}{vlans}{$v} = {} unless ref $e eq 'HASH';
        _set( $e, name => $g->{name} // sprintf( 'VLAN%04d', $v ) );
    }
    return ( join( "\n", @err ), @err ? 0 : 1 );
}

sub _description {
    my ( $S, $g ) = @_;
    _set( $_, description => $g->{text} ) for _cur_ifaces($S);
    return '';
}

sub _no_description {
    my ($S) = @_;
    delete $_->{description} for _cur_ifaces($S);
    return '';
}

sub _shutdown {
    my ( $S, $g, $on ) = @_;
    for my $if ( _cur_ifaces($S) ) {
        next if !!$if->{shutdown} == !!$on;
        $if->{shutdown} = $on ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
        _set( $if, status => $on ? 'disabled' : ( $if->{link} // 'connected' ), 'connected' );
    }
    return '';
}

# switchport-Befehle gibt es nicht auf SVIs
sub _l2_check {
    my ( $S, $g ) = @_;
    return undef unless grep { _is_svi($_) } @{ $S->{ifaces} };
    return $g->{_at}{switchport};
}

sub _switchport {
    my ( $S, $g ) = @_;
    my $bad = _l2_check( $S, $g );
    return ( '', 0, $bad ) if defined $bad;
    return '';
}

sub _sw_set {
    my ( $S, $g, $key, $val, $default ) = @_;
    my $bad = _l2_check( $S, $g );
    return ( '', 0, $bad ) if defined $bad;
    _set( $_, $key => $val, $default ) for _cur_ifaces($S);
    return '';
}

sub _sw_native { return _sw_set( @_[ 0, 1 ], native_vlan => $_[1]{v}, 1 ) }

sub _sw_access {
    my ( $S, $g ) = @_;
    my $bad = _l2_check( $S, $g );
    return ( '', 0, $bad ) if defined $bad;
    my $out = '';
    unless ( exists _vlans($S)->{ $g->{v} } ) {
        $out = "% Access VLAN does not exist. Creating vlan $g->{v}";
        $S->{dev}{vlans}{ $g->{v} } = { name => sprintf 'VLAN%04d', $g->{v} };
    }
    _set( $_, access_vlan => $g->{v}, 1 ) for _cur_ifaces($S);
    return $out;
}

sub _sw_allowed {
    my ( $S, $g, $op ) = @_;
    my $bad = _l2_check( $S, $g );
    return ( '', 0, $bad ) if defined $bad;
    for my $if ( _cur_ifaces($S) ) {
        my $cur = _allowed($if);
        my %set = map { $_ => 1 } $cur ? @$cur : 1 .. 4094;
        my @l   = @{ $g->{l} || [] };
        if    ( $op eq 'all' )    { %set = map { $_ => 1 } 1 .. 4094 }
        elsif ( $op eq 'none' )   { %set = () }
        elsif ( $op eq 'set' )    { %set = map { $_ => 1 } @l }
        elsif ( $op eq 'add' )    { $set{$_} = 1 for @l }
        elsif ( $op eq 'remove' ) { delete $set{$_} for @l }
        elsif ( $op eq 'except' ) { %set = map { $_ => 1 } 1 .. 4094; delete $set{$_} for @l }
        my @new = sort { $a <=> $b } map { 0 + $_ } keys %set;
        _set( $if, trunk_allowed => @new == 4094 ? 'all' : \@new, 'all' );
    }
    return '';
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::IOS - The simulator of device type ios — a Cisco IOS switch CLI

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $out, $ok, $gap ) = $sims->run_command( $state, 'sw-core', 'show vlan brief' );

  # directly, as in cai-platform:

  my ( $output, $ok ) = Langertha::Holmgang::Sim::IOS->run( $state->{'sw-core'},
      "configure terminal\ninterface Gi1/0/24\nswitchport trunk allowed vlan add 30\nend",
      { host => 'sw-core', state => $state } );

=head1 DESCRIPTION

Simulates the command line of a Catalyst switch (IOS XE) for the test suites
(contract in L<Langertha::Holmgang::Role::Simulator>). A call of C<run> is a
fresh SSH session in privileged mode (C<sw#>); several lines (separated by
newlines) run one after another as if pasted. Empty lines and lines starting
with C<!> are skipped.

The common show and configuration commands are B<really executed on the
state>. What the simulator does not know, it answers like IOS:

  sw-core(config-if)#switchport trunk alowed vlan 30
                                       ^
  % Invalid input detected at '^' marker.

as well as C<% Incomplete command.> and C<% Ambiguous command:  "…">. On an
error only the failing line is echoed with its prompt; successful lines give
only their output. A failing line changes nothing, the remaining lines go on
(IOS does not abort a pasted configuration); C<$ok> is then false. After
C<reload>, C<exit> or C<logout> in privileged mode the session is closed and
further lines are dropped.

Commands and keywords may be abbreviated as in IOS (unique prefixes:
C<sh run>, C<conf t>, C<int Gi1/0/24>, C<sw tr al vl add 30>), interface names
too (C<Gi>, C<Gig>, C<GigabitEthernet>, C<Fa>, C<Te>, C<Po>/C<Port-channel>,
C<Vlan>, also with a space: C<gi 1/0/24>). The state always holds the full
names.

=head2 State

  sw-core:
    type: ios
    hostname: sw-core
    vlans: { "1": { name: default }, "10": { name: BUERO }, "30": { name: GAST } }
    interfaces:
      GigabitEthernet1/0/24:
        description: Uplink to the router
        mode: trunk              # trunk | access (missing = access; dynamic auto is not modelled)
        trunk_allowed: [10, 20]  # list of numbers or "all" (missing = all)
        native_vlan: 1           # missing = 1
        access_vlan: 1           # missing = 1
        shutdown: false
        status: connected        # connected | notconnect | disabled (shutdown -> disabled)
        link: notconnect         # optional: status after "no shutdown" (missing = connected)
    reloads: 0                   # optional, counts "reload"

Only what really changes is written (a C<no shutdown> on an open interface
creates no key). A list in C<trunk_allowed> that contains all VLANs 1–4094
becomes C<all>.

=head2 Commands

Privileged mode (and with C<do …> in every configuration mode):

  show running-config [interface X]
  show interfaces [X [switchport|trunk|status] | trunk | status]
  show vlan [brief | id N]
  show ip interface brief
  show version
  … | include RE  | exclude RE  | begin RE  | section RE  | count RE
  configure terminal
  terminal length N, terminal width N, enable, end     (no effect)
  write [memory], copy running-config startup-config  ("Building configuration...", state unchanged)
  reload                                               (reloads + 1, session closed)
  ping ADDRESS                                         (always the normal case: !!!!!, 100 percent)
  exit, logout

Configuration (C<(config)#>):

  interface X | interface range Gi1/0/1 - 4[, Gi1/0/8]
  vlan N[,M-K]      no vlan N
  hostname NAME     exit     end

Interface (C<(config-if)#>, C<(config-if-range)#>):

  description TEXT                  no description
  switchport mode trunk|access      no switchport mode
  switchport access vlan N          no switchport access vlan
  switchport trunk native vlan N    no switchport trunk native vlan
  switchport trunk allowed vlan LIST           (REPLACES the list)
  switchport trunk allowed vlan add|remove|except LIST
  switchport trunk allowed vlan all|none       no switchport trunk allowed vlan
  shutdown                          no shutdown
  exit     end

VLAN (C<(config-vlan)#>): C<name NAME>, C<no name>, C<exit>, C<end>.

A global configuration command in a submode (e.g. C<interface Gi1/0/2> in
C<config-if>) leaves the submode as in IOS.

=head2 Limits

No startup configuration (C<write memory> and C<reload> do not change the
running configuration), no VTP, no spanning tree (the sections of C<show
interfaces trunk> show the allowed and present VLANs), no IP addresses, no
C<no switchport>, no port security, no voice VLAN. C<ping> shows only the
normal case — cases with faults bring their own observations. C<show vlan>
without C<brief> shows the short form. Long lists in C<show running-config>
are not wrapped.

Pure functions, deterministic, neutral.

=head2 run

  my ( $output, $ok ) = Langertha::Holmgang::Sim::IOS->run( $dev, $command, $ctx );

Runs a session (one or more lines in C<$command>) and changes C<$dev>.
C<$ok> is true when every line succeeded.

=head2 device_type

C<ios>.

=head2 run_command

  my ( $output, $ok, $gap ) = $sim->run_command( $dev, $command, $ctx );

L<Langertha::Holmgang::Role::Simulator/run_command>: runs the session through
L</run>. There is no C<write_file>: an IOS device has only its CLI.

=head2 parse_vlan_list

  my $list = parse_vlan_list('10,20,30-32');   # [10,20,30,31,32] or undef

=head2 format_vlan_list

  format_vlan_list( 10, 11, 12, 20 );   # "10-12,20"

Compresses like IOS: runs of three or more numbers become a range.

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
