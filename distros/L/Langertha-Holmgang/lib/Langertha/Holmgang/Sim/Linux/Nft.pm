package Langertha::Holmgang::Sim::Linux::Nft;
# ABSTRACT: Evaluates the nftables ruleset of a simulated Linux device against a packet

use strict;
use warnings;
use utf8;

use Socket qw( inet_pton AF_INET AF_INET6 );

our $VERSION = '0.001';


my %PRIO = ( raw => -300, mangle => -150, dstnat => -100, filter => 0, security => 50, srcnat => 100 );
my %SERVICE = (
    ssh => 22, http => 80, https => 443, domain => 53, smtp => 25, submission => 587, submissions => 465,
    imap => 143, imaps => 993, pop3 => 110, pop3s => 995, ntp => 123, snmp => 161, ldap => 389, ldaps => 636,
    'http-alt' => 8080, mysql => 3306, postgresql => 5432, bgp => 179, telnet => 23, ftp => 21, rsync => 873,
    'openvpn' => 1194, 'sip' => 5060, 'syslog' => 514, 'bootps' => 67, 'bootpc' => 68, 'tftp' => 69, 'kerberos' => 88,
    'microsoft-ds' => 445, 'ms-wbt-server' => 3389, 'redis' => 6379, 'zabbix-agent' => 10050, ipp => 631, printer => 515,
    nfs => 2049, sunrpc => 111, 'netbios-ns' => 137, 'netbios-dgm' => 138, 'netbios-ssn' => 139, mdns => 5353, git => 9418,
    'domain-s' => 853, 'http-alt' => 8080, 'webcache' => 8080, 'xmpp-client' => 5222, 'mqtt' => 1883, 'ntp' => 123,
);
my %PROTO = ( tcp => 6, udp => 17, icmp => 1, icmpv6 => 58, ipv6icmp => 58, 'ipv6-icmp' => 58, gre => 47, esp => 50, ah => 51 );
my %CTSTATUS = map { $_ => 1 } qw( expected seen-reply assured confirmed snat dnat dying );
my %CTSTATE = map { $_ => 1 } qw( new established related invalid untracked );
my %VERDICT = map { $_ => 1 } qw( accept drop reject continue return );
my %ICMP = map { $_ => 1 } qw( echo-request echo-reply destination-unreachable time-exceeded parameter-problem
    source-quench redirect router-advertisement router-solicitation timestamp-request timestamp-reply
    packet-too-big nd-router-solicit nd-router-advert nd-neighbor-solicit nd-neighbor-advert mld-listener-query
    mld-listener-report mld-listener-done mld2-listener-report );

my %ICMPCODE = map { $_ => 1 } qw( net-unreachable host-unreachable prot-unreachable port-unreachable frag-needed
    net-prohibited host-prohibited admin-prohibited no-route addr-unreachable reject-route policy-fail );

# --- Zerlegen --------------------------------------------------------------------

sub _tokens {
    my ($text) = @_;
    my @t;
    pos($text) = 0;
    while ( pos($text) < length $text ) {
        if    ( $text =~ /\G\s+/gc )                    { next }
        elsif ( $text =~ /\G"((?:[^"\\]|\\.)*)"/gc )     { push @t, { q => $1 } }
        elsif ( $text =~ /\G(!=|==|[{},;])/gc )          { push @t, $1 }
        elsif ( $text =~ /\G([^\s{},;"]+)/gc ) {
            my $w = $1;
            # IPv6 bleibt ein Wort; "established : accept" bzw. "established:accept" (vmap) nicht
            if    ( $w eq ':' )                              { push @t, ':' }
            elsif ( $w =~ /\A([a-z][\w-]*):\z/ )             { push @t, $1, ':' }
            elsif ( $w =~ /\A([a-z][\w-]*):([a-z][\w-]*)\z/ ) { push @t, $1, ':', $2 }
            else                                             { push @t, $w }
        }
        else { die "unerwartetes Zeichen\n" }
    }
    return \@t;
}

# Wert oder Menge { a, b } (mit vmap: { a : verdict, … })
sub _value {
    my ( $t, $map ) = @_;
    my $x = shift @$t // die "Wert fehlt\n";
    if ( !ref $x && $x eq '{' ) {
        my @items;
        while (1) {
            my $y = shift @$t // die "} fehlt\n";
            last if !ref $y && $y eq '}';
            next if !ref $y && $y eq ',';
            my $v = ref $y ? $y->{q} : $y;
            if ($map) {
                my $c = shift @$t;
                die "vmap ohne :\n" unless defined $c && !ref $c && $c eq ':';
                my $verd = _verdict_tokens($t);
                push @items, [ $v, $verd ];
            }
            else { push @items, $v }
        }
        return { set => \@items };
    }
    return { named => $1 } if !ref $x && $x =~ /\A@([\w-]+)\z/;
    return { one => ref $x ? $x->{q} : $x };
}

sub _verdict_tokens {
    my ($t) = @_;
    my $v = shift @$t // die "Urteil fehlt\n";
    die "Urteil erwartet\n" if ref $v;
    if ( $v eq 'jump' || $v eq 'goto' ) {
        my $c = shift @$t // die "Kette fehlt\n";
        return { $v => ref $c ? $c->{q} : $c };
    }
    die "unbekanntes Urteil $v\n" unless $VERDICT{$v};
    return { $v => 1 };
}

my %FIELD = (
    'iifname' => 'iif', 'oifname' => 'oif', 'iif' => 'iif', 'oif' => 'oif',
);


sub parse {
    my ($text) = @_;
    my $t = eval { _tokens($text) } or return ( undef, "nicht zerlegbar: $text" );
    my ( @m, $verdict );
    my $res = eval {
        while (@$t) {
            my $w = shift @$t;
            die "unerwartet\n" if ref $w;
            next if $w eq ';';
            if ( $w eq 'counter' ) {
                if ( @$t >= 4 && $t->[0] eq 'packets' ) { splice @$t, 0, 4 }
                next;
            }
            if ( $w eq 'comment' ) { shift @$t; next }
            if ( $w eq 'log' ) {
                while ( @$t && !ref $t->[0] && $t->[0] =~ /\A(?:prefix|level|flags|group)\z/ ) {
                    my $k = shift @$t;
                    shift @$t;
                    shift @$t if $k eq 'flags' && @$t && !ref $t->[0] && $t->[0] =~ /\A(?:tcp|ip)\z/;
                }
                next;
            }
            if ( $w eq 'limit' ) {
                die "limit ohne rate\n" unless ( shift(@$t) // '' ) eq 'rate';
                my $over = 0;
                if ( @$t && $t->[0] eq 'over' ) { shift @$t; $over = 1 }
                my $r = shift @$t // die "rate fehlt\n";
                if ( @$t && $t->[0] =~ m{\A/} ) { $r .= shift @$t }
                die "rate unklar\n" unless $r =~ m{\A\d+(?:/|\s*)?(?:second|minute|hour|day|\w*bytes/\w+)?};
                shift @$t if @$t && $t->[0] =~ m{\A/(?:second|minute|hour|day)\z};
                if ( @$t && $t->[0] eq 'burst' ) { shift @$t; shift @$t; shift @$t if @$t && $t->[0] =~ /\A(?:packets|bytes|kbytes|mbytes)\z/ }
                push @m, { field => 'never' } if $over;
                next;
            }
            if ( $VERDICT{$w} || $w eq 'jump' || $w eq 'goto' ) {
                unshift @$t, $w;
                $verdict = _verdict_tokens($t);
                if ( $w eq 'reject' && @$t && !ref $t->[0] && $t->[0] eq 'with' ) {
                    shift @$t while @$t && !( !ref $t->[0] && $t->[0] eq 'comment' );
                }
                # hinter dem Urteil: counter, log …, comment "…" (wirken nicht auf das Urteil)
                while ( @$t && !ref $t->[0] && $t->[0] =~ /\A(?:comment|counter|log)\z/ ) {
                    my $k = shift @$t;
                    if    ( $k eq 'comment' ) { shift @$t }
                    elsif ( $k eq 'log' ) { while ( @$t && !ref $t->[0] && $t->[0] =~ /\A(?:prefix|level|flags|group)\z/ ) { shift @$t; shift @$t } }
                }
                die "nach dem Urteil: " . join( ' ', map { ref $_ ? qq{"$_->{q}"} : $_ } @$t ) . "\n" if @$t;
                last;
            }
            my $field;
            if ( $w eq 'meta' ) {
                my $k = shift @$t // die "meta ohne Schluessel\n";
                if    ( $FIELD{$k} )        { $field = $FIELD{$k} }
                elsif ( $k eq 'l4proto' )   { $field = 'l4proto' }
                elsif ( $k eq 'nfproto' )   { $field = 'nfproto' }
                else                        { die "meta $k\n" }
            }
            elsif ( $FIELD{$w} ) { $field = $FIELD{$w} }
            elsif ( $w eq 'ip' || $w eq 'ip6' ) {
                my $k = shift @$t // die "$w ohne Feld\n";
                if    ( $k eq 'saddr' || $k eq 'daddr' ) { $field = "$w $k" }
                elsif ( $w eq 'ip' && $k eq 'protocol' ) { $field = 'ipproto4' }
                elsif ( $w eq 'ip6' && $k eq 'nexthdr' ) { $field = 'ipproto6' }
                else { die "$w $k\n" }
            }
            elsif ( $w eq 'tcp' || $w eq 'udp' || $w eq 'th' ) {
                my $k = shift @$t // die "$w ohne Feld\n";
                # MSS-Anpassung: Anweisung ohne Wirkung auf das Urteil
                if ( $w eq 'tcp' && $k eq 'option' && @$t >= 4 && !( grep {ref} @$t[ 0 .. 3 ] ) && "@$t[0..3]" =~ /\Amaxseg size set (?:rt mtu|\d+)/ ) {
                    splice @$t, 0, ( $t->[3] eq 'rt' ? 5 : 4 );
                    next;
                }
                die "$w $k\n" unless $k eq 'dport' || $k eq 'sport';
                $field = "$w $k";
            }
            elsif ( $w eq 'ct' ) {
                my $k = shift @$t // die "ct ohne Feld\n";
                die "ct $k\n" unless $k eq 'state' || $k eq 'status';
                $field = $k eq 'state' ? 'ct' : 'ct status';
            }
            elsif ( $w eq 'icmp' || $w eq 'icmpv6' ) {
                my $k = shift @$t // die "$w ohne Feld\n";
                die "$w $k\n" unless $k eq 'type' || $k eq 'code';
                $field = "$w $k";
            }
            else { die "unbekannt: $w\n" }
            my $neg = 0;
            if ( @$t && !ref $t->[0] && $t->[0] eq '!=' ) { shift @$t; $neg = 1 }
            elsif ( @$t && !ref $t->[0] && $t->[0] eq '==' ) { shift @$t }
            if ( @$t && !ref $t->[0] && $t->[0] eq 'vmap' ) {
                shift @$t;
                my $v = _value( $t, 1 );
                die "vmap braucht { }\n" unless $v->{set};
                push @m, { field => $field, vmap => $v->{set} };
                while ( @$t && !ref $t->[0] && $t->[0] eq 'comment' ) { shift @$t; shift @$t }
                die "nach vmap: " . join( ' ', map { ref $_ ? qq{"$_->{q}"} : $_ } @$t ) . "\n" if @$t;
                last;
            }
            my $v = _value($t);
            # ct state established,related ohne Klammern
            if ( $field =~ /\Act/ && $v->{one} && $v->{one} =~ /,/ ) { $v = { set => [ split /,/, $v->{one} ] } }
            while ( $field =~ /\Act/ && @$t && !ref $t->[0] && $t->[0] eq ',' ) { shift @$t; my $n = shift @$t; $v = { set => [ ( $v->{set} ? @{ $v->{set} } : $v->{one} ), $n ] } }
            _check_val( $field, $v );
            push @m, { field => $field, neg => $neg, val => $v };
        }
        1;
    };
    return ( undef, "nicht auswertbar: $text" . ( $@ ? " ($@)" =~ s/\n//r : '' ) ) unless $res;
    return ( { matches => \@m, verdict => $verdict } );
}

sub _check_val {
    my ( $field, $v ) = @_;
    my @vals = $v->{set} ? @{ $v->{set} } : defined $v->{one} ? ( $v->{one} ) : ();
    for my $x (@vals) {
        if ( $field =~ /addr\z/ ) { die "Adresse $x\n" unless _range($x) }
        elsif ( $field =~ /port\z/ ) { die "Port $x\n" unless _port_range($x) }
        elsif ( $field eq 'ct' ) { die "ct state $x\n" unless $CTSTATE{$x} }
        elsif ( $field eq 'ct status' ) { die "ct status $x\n" unless $CTSTATUS{$x} }
        elsif ( $field eq 'nfproto' ) { die "nfproto $x\n" unless $x =~ /\Aipv[46]\z/ }
        elsif ( $field =~ /proto/ ) { die "Protokoll $x\n" unless exists $PROTO{$x} || $x =~ /\A\d+\z/ }
        elsif ( $field =~ /type\z/ ) { die "$field $x\n" unless $ICMP{$x} || $x =~ /\A\d+\z/ }
        elsif ( $field =~ /code\z/ ) { die "$field $x\n" unless $ICMPCODE{$x} || $x =~ /\A\d+\z/ }
    }
    return;
}


sub parse_error { my ( undef, $e ) = parse( $_[0] ); return $e }


my %KEYWORD = map { $_ => 1 } qw( meta fib rt ether vlan arp ip ip6 tcp udp udplite sctp dccp ah esp comp icmp icmpv6
    igmp th ct mark iif oif iifname oifname iiftype oiftype skuid skgid pkttype cpu nftrace priority socket osf ipsec
    exthdr hbh frag dst mh srh numgen jhash symhash quota limit counter log reject drop accept queue continue return
    jump goto masquerade snat dnat redirect notrack dup fwd synproxy tproxy flow add update delete set map vmap comment
    xt l4proto nfproto length protocol );

sub syntax_error {
    my ($text) = @_;
    my ( undef, $e ) = parse($text);
    return undef unless defined $e;
    if ( $e =~ /\((icmpv6|icmp) (?:type|code) (\S+)\)/ ) { return "Error: Could not parse " . ( $1 eq 'icmpv6' ? 'ICMPv6' : 'ICMP' ) . " type\n$text" }
    return "Error: Could not resolve service: Servname not supported for ai_socktype\n$text" if $e =~ /\(Port \S+\)/;
    return "Error: Could not resolve hostname: Name or service not known\n$text" if $e =~ /\(Adresse \S+\)/;
    return "Error: Could not parse conntrack state\n$text" if $e =~ /\(ct state \S+\)/;
    return undef unless $e =~ /\(unbekannt: (\S+)\)/;
    my $w = $1;
    return undef if $KEYWORD{$w};
    return "Error: syntax error, unexpected " . ( $w =~ /\A\d+\z/ ? 'number' : 'string' ) . "\n$text";
}

# --- Werte ------------------------------------------------------------------------

sub _addr_bin {
    my ($a) = @_;
    return ( 4, inet_pton( AF_INET, $a ) ) if $a =~ /\A\d+\.\d+\.\d+\.\d+\z/ && inet_pton( AF_INET, $a );
    return ( 6, inet_pton( AF_INET6, $a ) ) if $a =~ /:/ && inet_pton( AF_INET6, $a );
    return;
}

# Adresse, Praefix oder Bereich -> [ familie, von, bis ] (Bitfolgen)
sub _range {
    my ($x) = @_;
    if ( $x =~ m{\A([^/\-]+)/(\d+)\z} ) {
        my ( $f, $b ) = _addr_bin($1) or return;
        my $len = $f == 4 ? 32 : 128;
        return if $2 > $len;
        my $bits = unpack( 'B*', $b );
        my $p = substr( $bits, 0, $2 );
        return [ $f, $p . ( '0' x ( $len - $2 ) ), $p . ( '1' x ( $len - $2 ) ) ];
    }
    if ( $x =~ /\A([^\-]+)-([^\-]+)\z/ ) {
        my ( $f1, $b1 ) = _addr_bin($1) or return;
        my ( $f2, $b2 ) = _addr_bin($2) or return;
        return unless $f1 == $f2;
        return [ $f1, unpack( 'B*', $b1 ), unpack( 'B*', $b2 ) ];
    }
    my ( $f, $b ) = _addr_bin($x) or return;
    my $bits = unpack( 'B*', $b );
    return [ $f, $bits, $bits ];
}

sub _port { my ($p) = @_; return $p =~ /\A\d+\z/ && $p <= 65535 ? 0 + $p : $SERVICE{$p} }

sub _port_range {
    my ($x) = @_;
    if ( $x =~ /\A([^\-]+)-([^\-]+)\z/ ) {
        my ( $a, $b ) = ( _port($1), _port($2) );
        return defined $a && defined $b ? [ $a, $b ] : undef;
    }
    my $p = _port($x);
    return defined $p ? [ $p, $p ] : undef;
}

sub _family { my ($a) = @_; return defined $a && $a =~ /:/ ? 6 : 4 }

sub _l4 {
    my ($pkt) = @_;
    my $p = $pkt->{proto} // '';
    $p = 'icmpv6' if $p eq 'icmp' && _family( $pkt->{saddr} // $pkt->{daddr} ) == 6;
    return $p;
}

sub _proto_num { my ($p) = @_; return $p =~ /\A\d+\z/ ? 0 + $p : $PROTO{$p} }

# Passt ein einzelner Wert des Pakets auf einen Ausdruckswert?
sub _one {
    my ( $field, $have, $want ) = @_;
    return 0 unless defined $have;
    if ( $field =~ /addr\z/ ) {
        my $r = _range($want) or return 0;
        my ( $f, $b ) = _addr_bin($have) or return 0;
        return 0 unless $f == $r->[0];
        my $bits = unpack( 'B*', $b );
        return $bits ge $r->[1] && $bits le $r->[2] ? 1 : 0;
    }
    if ( $field =~ /port\z/ ) {
        my $r = _port_range($want) or return 0;
        return $have >= $r->[0] && $have <= $r->[1] ? 1 : 0;
    }
    if ( $field eq 'iif' || $field eq 'oif' ) {
        my $re = quotemeta $want;
        $re =~ s/\\\*/.*/g;
        return $have =~ /\A$re\z/ ? 1 : 0;
    }
    if ( $field =~ /proto/ && $field ne 'nfproto' ) {
        my ( $a, $b ) = ( _proto_num($have), _proto_num($want) );
        return defined $a && defined $b && $a == $b ? 1 : 0;
    }
    return $have eq $want ? 1 : 0;
}

# Wert des Pakets fuer ein Feld; undef = das Feld gibt es an diesem Paket nicht
# (dann passt der Ausdruck nicht — auch nicht mit !=, wie in nft).
sub _have {
    my ( $field, $pkt ) = @_;
    my $l4 = _l4($pkt);
    my $fam = _family( $pkt->{saddr} // $pkt->{daddr} );
    return $pkt->{iif} if $field eq 'iif';
    return $pkt->{oif} if $field eq 'oif';
    return $fam == 4 ? $pkt->{saddr} : undef if $field eq 'ip saddr';
    return $fam == 4 ? $pkt->{daddr} : undef if $field eq 'ip daddr';
    return $fam == 6 ? $pkt->{saddr} : undef if $field eq 'ip6 saddr';
    return $fam == 6 ? $pkt->{daddr} : undef if $field eq 'ip6 daddr';
    return $fam == 4 ? $l4 : undef if $field eq 'ipproto4';
    return $fam == 6 ? $l4 : undef if $field eq 'ipproto6';
    return $l4 if $field eq 'l4proto';
    return "ipv$fam" if $field eq 'nfproto';
    if ( $field =~ /\A(tcp|udp|th) (dport|sport)\z/ ) {
        my ( $p, $k ) = ( $1, $2 );
        return undef if $p ne 'th' && $p ne $l4;
        return undef if $p eq 'th' && $l4 ne 'tcp' && $l4 ne 'udp';
        return $pkt->{$k};
    }
    return $pkt->{ct} // 'new' if $field eq 'ct';
    return [ split /\s*,\s*/, $pkt->{ct_status} // '' ] if $field eq 'ct status';
    return $l4 eq 'icmp' ? ( $pkt->{icmp_type} // 'echo-request' ) : undef if $field eq 'icmp type';
    return $l4 eq 'icmpv6' ? ( $pkt->{icmp_type} // 'echo-request' ) : undef if $field eq 'icmpv6 type';
    return $l4 eq ( $field =~ /\Aicmpv6/ ? 'icmpv6' : 'icmp' ) ? $pkt->{icmp_code} : undef if $field =~ /code\z/;
    return undef;
}

sub _elements {
    my ( $table, $v, $why ) = @_;
    return @{ $v->{set} } if $v->{set};
    return ( $v->{one} ) if defined $v->{one};
    my $s = ( $table->{sets} || {} )->{ $v->{named} };
    die "Set \@$v->{named} gibt es nicht\n" unless ref $s eq 'HASH';
    return @{ $s->{elements} || [] };
}

sub _match {
    my ( $m, $pkt, $table ) = @_;
    return 0 if $m->{field} eq 'never';
    my $have = _have( $m->{field}, $pkt );
    return 0 unless defined $have;
    my @have = ref $have eq 'ARRAY' ? @$have : ($have);
    my @want = _elements( $table, $m->{val} );
    my $hit = grep { my $h = $_; grep { _one( $m->{field}, $h, $_ ) } @want } @have;
    return $m->{neg} ? !$hit : $hit ? 1 : 0;
}

# --- Auswerten --------------------------------------------------------------------

sub _prio {
    my ($p) = @_;
    $p //= 0;
    return 0 + $p if $p =~ /\A-?\d+\z/;
    if ( $p =~ /\A(\w+)\s*([+-])\s*(\d+)\z/ && exists $PRIO{$1} ) { return $PRIO{$1} + ( $2 eq '+' ? $3 : -$3 ) }
    return $PRIO{$p} // 0;
}

# Eine Kette durchlaufen -> ( 'accept'|'drop'|'return'|undef (Ende), Spur )
sub _chain {
    my ( $tname, $table, $cname, $pkt, $depth ) = @_;
    die "Ketten zu tief verschachtelt\n" if $depth > 16;
    my $ch = $table->{chains}{$cname} or die "Kette $cname gibt es nicht\n";
    for my $text ( @{ $ch->{rules} || [] } ) {
        my ( $r, $err ) = parse($text);
        die "$err\n" unless $r;
        my $all = 1;
        my $verdict = $r->{verdict};
        for my $m ( @{ $r->{matches} } ) {
            if ( $m->{vmap} ) {
                my $have = _have( $m->{field}, $pkt );
                my ($hit) = defined $have ? grep { _one( $m->{field}, $have, $_->[0] ) } @{ $m->{vmap} } : ();
                if ($hit) { $verdict = $hit->[1] } else { $all = 0 }
                last;
            }
            next if _match( $m, $pkt, $table );
            $all = 0;
            last;
        }
        next unless $all && $verdict;
        my $where = "$tname $cname: $text";
        return ( 'accept', $where ) if $verdict->{accept};
        return ( 'drop',   $where ) if $verdict->{drop} || $verdict->{reject};
        return ( 'return', $where ) if $verdict->{return};
        next if $verdict->{continue};
        my ($to) = grep {defined} @{$verdict}{qw( jump goto )};
        my ( $v, $w ) = _chain( $tname, $table, $to, $pkt, $depth + 1 );
        return ( $v, $w ) if defined $v && $v ne 'return';
        return ( undef, "$tname $to: Ende (goto)" ) if $verdict->{goto};
    }
    return ( undef, "$tname $cname: Ende" );
}


sub verdict {
    my ( $dev, $pkt ) = @_;
    my $fam = _family( $pkt->{saddr} // $pkt->{daddr} );
    my $T = ref $dev->{nft} eq 'HASH' ? $dev->{nft} : {};
    my @base;
    for my $tn ( sort keys %$T ) {
        my ($f) = split / /, $tn;
        next unless $f eq 'inet' || ( $f eq 'ip' && $fam == 4 ) || ( $f eq 'ip6' && $fam == 6 );
        my $chains = $T->{$tn}{chains} || {};
        for my $cn ( sort keys %$chains ) {
            my $c = $chains->{$cn};
            next unless ( $c->{hook} // '' ) eq $pkt->{hook} && ( $c->{type} // '' ) eq 'filter';
            push @base, [ _prio( $c->{priority} ), $tn, $cn ];
        }
    }
    my @why;
    my $ok = eval {
        for my $b ( sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] || $a->[2] cmp $b->[2] } @base ) {
            my ( undef, $tn, $cn ) = @$b;
            my ( $v, $w ) = _chain( $tn, $T->{$tn}, $cn, $pkt, 0 );
            if ( !defined $v || $v eq 'return' ) {
                my $pol = $T->{$tn}{chains}{$cn}{policy} // 'accept';
                $v = $pol;
                $w = "$tn $cn: policy $pol";
            }
            push @why, $w;
            return ( 'drop' ) if $v eq 'drop';
        }
        'accept';
    };
    return ( undef, ( $@ =~ s/\n\z//r ) ) unless defined $ok;
    return ( $ok, @why ? join( '; ', @why ) : 'keine Basiskette' );
}


sub boot_verdict {
    my ( $dev, $pkt, $file ) = @_;
    $file //= '/etc/nftables.conf';
    require Langertha::Holmgang::Sim::Linux;
    my $text = Langertha::Holmgang::Sim::Linux::_file_text( $dev, $file );
    my $boot = Langertha::Holmgang::Sim::Linux::clone_state($dev);
    $boot->{nft} = {};
    return ( undef, "$file fehlt" ) unless defined $text;
    local @Langertha::Holmgang::Sim::Linux::GAPS;
    my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::_nft_load( $boot, $text, $file );
    return ( undef, "$file lädt nicht: $out" ) unless $ok;
    return verdict( $boot, $pkt );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Nft - Evaluates the nftables ruleset of a simulated Linux device against a packet

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Langertha::Holmgang::Sim::Linux::Nft ();

  my ( $verdict, $why ) = Langertha::Holmgang::Sim::Linux::Nft::verdict( $dev, {
      hook => 'input', iif => 'eth0', saddr => '203.0.113.7', daddr => '198.51.100.2',
      proto => 'tcp', dport => 22,                     # ct: new (default)
  } );
  # ( 'accept' | 'drop', 'inet filter input: tcp dport 22 drop' )
  # ( undef, 'nicht auswertbar: …' ) when a rule on the way is not understood

  my $err = Langertha::Holmgang::Sim::Linux::Nft::parse_error('ip saddr @admins tcp dport ssh accept');   # undef = understood

=head1 DESCRIPTION

Evaluates an nftables ruleset (C<nft> in the state of a device of type
C<linux>, see L<Langertha::Holmgang::Sim::Linux>) by its B<behaviour>: what happens
to a given packet? So every technically correct way of writing a
rule counts (port as number or service name, set or single rules, named set,
C<vmap>, own chain with C<jump>), and a rule in the wrong place stands
out even when its text is right.

B<Path of the packet:> all base chains with the packet's C<hook> and C<type
filter> in tables of a matching family (C<inet> for IPv4 and IPv6, C<ip> IPv4
only, C<ip6> IPv6 only), ordered by C<priority> (number or C<raw>, C<mangle>,
C<dstnat>, C<filter>, C<security>, C<srcnat>, also C<filter - 5>). C<accept>
ends only the chain — the next base chain keeps checking; C<drop>/C<reject>
end everything. At the end of a base chain its C<policy> applies; C<jump> returns,
C<goto> does not, C<return> returns to the calling chain.

B<Packet:> C<hook>, C<iif>, C<oif>, C<saddr>, C<daddr> (IPv4 or IPv6 — the
family follows from the address), C<proto> (C<tcp>, C<udp>, C<icmp>, C<icmpv6>),
C<sport>, C<dport>, C<icmp_type> (default C<echo-request>), C<icmp_code>, C<ct> (default
C<new>), C<ct_status> (e.g. C<dnat> for a forwarded connection; several separated by commas).

B<Understood expressions:> C<iifname>/C<oifname>/C<iif>/C<oif> (also with
C<meta>, wildcard C<*>), C<ip>/C<ip6 saddr|daddr> (address, prefix,
range C<a-b>, set C<{ … }>, named set C<@name>), C<ip protocol>,
C<ip6 nexthdr>, C<meta l4proto>, C<meta nfproto>, C<tcp>/C<udp>/C<th
dport|sport> (number, service name, range, set, named set), C<ct state>
(also C<a,b>), C<ct status>, C<icmp type|code>, C<icmpv6 type|code>, comparison with C<!=>, C<vmap>
after each of these expressions; without effect on the verdict: C<counter>,
C<log …>, C<tcp option maxseg size set …>, C<limit rate …> (matches; C<over> never matches), C<comment "…">.
Verdicts: C<accept>, C<drop>, C<reject [with …]>, C<jump>, C<goto>,
C<return>, C<continue>. Everything else is B<not evaluable>: the verdict is
then C<undef> with a reason, and the Linux simulator records a gap in the
simulation when such a rule is added (cai-platform F<docs/entwurf-evals.md> §3.3.2).

B<Named sets> live per table in the state:

  nft:
    inet filter:
      sets: { admins: { type: ipv4_addr, flags: [interval], elements: [ 10.1.0.7, 10.1.0.32/28 ] } }
      chains: { … }

=head2 parse

  my ( $rule, $err ) = parse($rule_text);
  # { matches => [ { field, neg, val } | { field, vmap } ], verdict => { accept => 1 } | undef }

Splits a rule into expressions and verdict; if it cannot be evaluated,
C<$rule> is C<undef> and C<$err> names the reason.

=head2 parse_error

  my $err = parse_error($rule_text);   # undef: evaluable

The reason a rule cannot be evaluated, otherwise C<undef>.

=head2 syntax_error

  my $err = syntax_error($rule_text);   # undef: nft syntax (even if not evaluable)

Error text as from nft when a rule starts with a word that does not exist in
nft at that position (e.g. a number without C<position>), or has a
value nft does not know (ICMP type like C<neighbor-solicit> instead of
C<nd-neighbor-solicit>, service name, address, C<ct state>); otherwise
C<undef>. Real expressions that are merely not modelled (C<fib>, C<meta mark> …)
are not a syntax error but a gap in the simulation.

=head2 verdict

  my ( $verdict, $why ) = verdict( $dev, \%packet );

C<accept> or C<drop> and the place that decided (table, chain,
rule text or C<policy>). If a rule on the way cannot be evaluated,
the verdict is C<undef> and C<$why> names it.

=head2 boot_verdict

  my ( $verdict, $why ) = boot_verdict( $dev, \%packet, '/etc/nftables.conf' );

Like L</verdict>, but for the ruleset B<after a reboot>: empty
ruleset, then the file loaded like C<nft -f> (service C<nftables> at
boot). If the file does not load, the verdict is C<undef> and C<$why> names the
error.

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
