package Langertha::Holmgang::Sim::Linux::Dns;
# ABSTRACT: BIND 9 on a simulated Linux server — named.conf, zones, rndc, dig, secondaries

use strict;
use warnings;
use utf8;

use JSON::MaybeXS ();

our $VERSION = '0.002';


my $T = JSON::MaybeXS::true();
my $F = JSON::MaybeXS::false();

sub _lx { 'Langertha::Holmgang::Sim::Linux' }
sub _text { _lx()->can('_file_text')->(@_) }

sub _bind { $_[0]{bind} }
sub _svc_name { ( _bind( $_[0] ) || {} )->{service} // 'named' }
sub _conf_path { ( _bind( $_[0] ) || {} )->{conf} // '/etc/bind/named.conf' }

sub _ip_of {
    my ($dev) = @_;
    my @ip;
    for my $i ( sort keys %{ $dev->{interfaces} || {} } ) {
        for my $a ( @{ $dev->{interfaces}{$i}{addr} || [] } ) { push @ip, $1 if $a =~ m{\A([\d.]+)/} }
    }
    return @ip;
}

sub _running {
    my ($dev) = @_;
    my $s = ( $dev->{services} || {} )->{ _svc_name($dev) };
    return $s && $s->{active} ? 1 : 0;
}

# --- named.conf ------------------------------------------------------------------

sub _conf_tokens {
    my ( $text, $file ) = @_;
    my @t;
    my $line = 1;
    pos($text) = 0;
    while ( pos($text) < length $text ) {
        if    ( $text =~ /\G\n/gc )                    { $line++ }
        elsif ( $text =~ /\G[ \t\r]+/gc )              { }
        elsif ( $text =~ m{\G(?://|\#)[^\n]*}gc )      { }
        elsif ( $text =~ m{\G/\*(.*?)\*/}gcs )         { $line += () = $1 =~ /\n/g }
        elsif ( $text =~ /\G"((?:[^"\\\n]|\\.)*)"/gc ) { push @t, { v => $1, q => 1, line => $line, file => $file } }
        elsif ( $text =~ /\G([{};])/gc )               { push @t, { v => $1, p => 1, line => $line, file => $file } }
        elsif ( $text =~ /\G([^\s{};"]+)/gc )          { push @t, { v => $1, line => $line, file => $file } }
        else { die "$file:$line: unexpected character\n" }
    }
    return @t;
}

# Anweisungen: { words => [...], block => [...]|undef }
sub _conf_block {
    my ( $toks, $inner ) = @_;
    my @st;
    while (@$toks) {
        my $t = $toks->[0];
        if ( $t->{p} && $t->{v} eq '}' ) {
            die "$t->{file}:$t->{line}: unexpected token near '}'\n" unless $inner;
            return \@st;
        }
        my ( @w, $block );
        while (1) {
            my $x = shift @$toks;
            die "$t->{file}:$t->{line}: unexpected end of input\n" unless $x;
            if ( $x->{p} && $x->{v} eq ';' ) { last }
            if ( $x->{p} && $x->{v} eq '{' ) {
                $block = _conf_block( $toks, 1 );
                my $close = shift @$toks or die "$x->{file}:$x->{line}: unexpected end of input\n";
                my $semi = $toks->[0];
                die "$close->{file}:$close->{line}: missing ';' before " . ( $semi ? "'$semi->{v}'" : 'end of file' ) . "\n"
                    unless $semi && $semi->{p} && $semi->{v} eq ';';
                shift @$toks;
                last;
            }
            if ( $x->{p} && $x->{v} eq '}' ) { die "$x->{file}:$x->{line}: missing ';' before '}'\n" }
            push @w, $x->{v};
        }
        push @st, { words => \@w, block => $block } if @w || $block;
    }
    die "unexpected end of input\n" if $inner;
    return \@st;
}

sub _conf_read {
    my ( $dev, $path, $depth ) = @_;
    my $text = _text( $dev, $path );
    die "$path: file not found\n" unless defined $text;
    my @toks = _conf_tokens( $text, $path );
    my $st = _conf_block( \@toks, 0 );
    my @out;
    for my $s (@$st) {
        if ( $s->{words}[0] eq 'include' ) {
            die "$path: include loop\n" if ( $depth // 0 ) > 8;
            push @out, @{ _conf_read( $dev, $s->{words}[1], ( $depth // 0 ) + 1 ) };
        }
        else { push @out, $s }
    }
    return \@out;
}

sub _addr_list {
    my ($block) = @_;
    return [ map { join ' ', @{ $_->{words} } } @{ $block || [] } ];
}

# named.conf -> { directory, allow_transfer, zones => { name => {...} } }

sub parse_conf {
    my ( $dev, $path ) = @_;
    $path //= _conf_path($dev);
    my $st = _conf_read( $dev, $path );
    my %c = ( directory => '/var/cache/bind', zones => {} );
    for my $s (@$st) {
        my $k = $s->{words}[0];
        if ( $k eq 'options' ) {
            for my $o ( @{ $s->{block} || [] } ) {
                my $ok = $o->{words}[0];
                $c{directory} = $o->{words}[1] if $ok eq 'directory';
                $c{allow_transfer} = _addr_list( $o->{block} ) if $ok eq 'allow-transfer';
                $c{also_notify} = _addr_list( $o->{block} ) if $ok eq 'also-notify';
                $c{notify} = $o->{words}[1] if $ok eq 'notify';
            }
        }
        elsif ( $k eq 'zone' ) {
            my $name = lc( $s->{words}[1] // '' );
            $name =~ s/\.\z// unless $name eq '.';
            die "zone '' : missing name\n" unless length $name;
            die "zone '$name': already exists\n" if $c{zones}{$name};
            my %z = ( name => $name );
            for my $o ( @{ $s->{block} || [] } ) {
                my $ok = $o->{words}[0];
                if    ( $ok eq 'type' ) { $z{type} = $o->{words}[1] }
                elsif ( $ok eq 'file' ) { $z{file} = $o->{words}[1] }
                elsif ( $ok eq 'allow-transfer' ) { $z{allow_transfer} = _addr_list( $o->{block} ) }
                elsif ( $ok eq 'also-notify' )    { $z{also_notify}    = _addr_list( $o->{block} ) }
                elsif ( $ok eq 'masters' || $ok eq 'primaries' ) { $z{primaries} = _addr_list( $o->{block} ) }
                elsif ( $ok eq 'notify' ) { $z{notify} = $o->{words}[1] }
            }
            my $t = $z{type} // '';
            $z{type} = $t eq 'master' ? 'primary' : $t eq 'slave' ? 'secondary' : $t;
            die "zone '$name': type not present\n" unless length $t;
            die "zone '$name': type '$t' not supported\n" unless $z{type} =~ /\A(?:primary|secondary|hint|forward)\z/;
            die "zone '$name': missing 'file' entry\n" if $z{type} eq 'primary' && !defined $z{file};
            die "zone '$name': missing 'primaries' entry\n" if $z{type} eq 'secondary' && !$z{primaries};
            $c{zones}{$name} = \%z;
        }
    }
    for my $z ( values %{ $c{zones} } ) {
        $z->{path} = !defined $z->{file} ? undef : $z->{file} =~ m{\A/} ? $z->{file} : "$c{directory}/$z->{file}";
    }
    return \%c;
}

# --- Zonendateien -----------------------------------------------------------------

sub _ttl {
    my ($w) = @_;
    return undef unless defined $w && $w =~ /\A(?:\d+[smhdw]?)+\z/i;
    my %m = ( '' => 1, s => 1, m => 60, h => 3600, d => 86400, w => 604800 );
    my $t = 0;
    $t += $1 * $m{ lc $2 } while $w =~ /(\d+)([smhdw]?)/gi;
    return $t;
}

sub _abs {
    my ( $n, $origin ) = @_;
    return $origin if $n eq '@';
    return lc( $n =~ /\.\z/ ? $n : "$n.$origin" ) =~ s/\A\.//r;
}

sub _ipv4 { my ($a) = @_; return $a =~ /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/ && !grep { $_ > 255 } $1, $2, $3, $4 }

# Zeilen der Datei in logische Zeilen (Klammern ueber Zeilen), Kommentare weg
sub _zone_lines {
    my ($text) = @_;
    my ( @out, $cur, $depth, $start );
    my $n = 0;
    for my $raw ( split /\n/, $text ) {
        $n++;
        my ( $l, $inq ) = ( '', 0 );
        for my $ch ( split //, $raw ) {
            if ( $ch eq '"' ) { $inq = !$inq }
            last if $ch eq ';' && !$inq;
            if ( !$inq && ( $ch eq '(' || $ch eq ')' ) ) { $depth += $ch eq '(' ? 1 : -1; $l .= ' '; next }
            $l .= $ch;
        }
        if ( defined $cur ) { $cur .= " $l" }
        else { ( $cur, $start ) = ( $l, $n ) }
        next if $depth;
        push @out, [ $start, $cur ] if $cur =~ /\S/;
        undef $cur;
    }
    push @out, [ $start, $cur, 'eof' ] if defined $cur;
    return @out;
}

sub _zone_words {
    my ($l) = @_;
    my @w;
    while ( $l =~ /\G\s*(?:"((?:[^"\\]|\\.)*)"|(\S+))/gc ) { push @w, defined $1 ? { s => $1 } : $2 }
    return @w;
}

sub _q { my ($s) = @_; return '"' . $s . '"' }


sub parse_zone {
    my ( $text, $zone, $file ) = @_;
    $file //= "db.$zone";
    my $origin = "$zone.";
    my ( $ttl, $last, @rec, @err, @warn, %show );
    my $fail = sub { push @err, "zone $zone/IN: loading from master file $file failed: $_[0]"; };
    for my $ln ( _zone_lines($text) ) {
        my ( $no, $l, $eof ) = @$ln;
        if ($eof) { $fail->('unexpected end of input'); last }
        if ( $l =~ /\A\$TTL\s+(\S+)/ ) {
            $ttl = _ttl($1) // do { $fail->("$file:$no: bad ttl"); last };
            next;
        }
        if ( $l =~ /\A\$ORIGIN\s+(\S+)/ ) { $origin = _abs( $1, $origin ); $origin .= '.' unless $origin =~ /\.\z/; next }
        if ( $l =~ /\A\$/ ) { $fail->("$file:$no: unknown \$ directive"); last }
        my $inherit = $l =~ /\A[ \t]/;
        my @w = _zone_words($l);
        my $owner;
        if ($inherit) {
            $owner = $last // do { $fail->("$file:$no: no current owner name"); last };
        }
        else {
            my $o = shift @w;
            $owner = _abs( $o, $origin );
            $owner .= '.' unless $owner =~ /\.\z/;
        }
        my ( $rttl, $type );
        while ( @w && !ref $w[0] ) {
            if    ( !defined $rttl && defined _ttl( $w[0] ) ) { $rttl = _ttl( shift @w ) }
            elsif ( uc $w[0] eq 'IN' ) { shift @w }
            else { $type = uc shift @w; last }
        }
        unless ( defined $type ) { $fail->("$file:$no: unexpected end of line"); last }
        $last = $owner;
        my @d = @w;
        my $bad = sub { $fail->("$file:$no: $_[0]") };
        my $name = sub { my $n = _abs( $_[0], $origin ); $n .= '.' unless $n =~ /\.\z/; $n };
        my ( $rd, $sh );
        if ( $type eq 'A' ) {
            unless ( @d == 1 && !ref $d[0] && _ipv4( $d[0] ) ) { $bad->('bad dotted quad'); last }
            $rd = $d[0];
        }
        elsif ( $type eq 'AAAA' ) {
            unless ( @d == 1 && !ref $d[0] && $d[0] =~ /\A[0-9a-f:.]+\z/i && $d[0] =~ /:/ ) { $bad->('bad IPv6 address'); last }
            $rd = lc $d[0];
        }
        elsif ( $type =~ /\A(?:NS|CNAME|PTR)\z/ ) {
            unless ( @d == 1 && !ref $d[0] ) { $bad->( @d ? 'extra input text' : 'unexpected end of input' ); last }
            $rd = $name->( $d[0] );
        }
        elsif ( $type eq 'MX' ) {
            unless ( @d == 2 && !ref $d[0] && $d[0] =~ /\A\d+\z/ && $d[0] <= 65535 && !ref $d[1] ) { $bad->('not a valid number'); last }
            $rd = ( 0 + $d[0] ) . ' ' . $name->( $d[1] );
        }
        elsif ( $type eq 'SRV' ) {
            unless ( @d == 4 && !grep( { ref } @d ) && !grep( { !/\A\d+\z/ } @d[ 0 .. 2 ] ) ) { $bad->('not a valid number'); last }
            $rd = join( ' ', map { 0 + $_ } @d[ 0 .. 2 ] ) . ' ' . $name->( $d[3] );
        }
        elsif ( $type eq 'TXT' ) {
            unless (@d) { $bad->('unexpected end of input'); last }
            my @s = map { ref $_ ? $_->{s} : $_ } @d;
            if ( grep { length( $_ =~ s/\\(.)/$1/gr ) > 255 } @s ) { $fail->('ran out of space'); last }
            $rd = _q( join '', @s );
            $sh = join ' ', map { _q($_) } @s;
        }
        elsif ( $type eq 'CAA' ) {
            unless ( @d == 3 && $d[0] =~ /\A\d+\z/ ) { $bad->('not a valid number'); last }
            $rd = "$d[0] $d[1] " . _q( ref $d[2] ? $d[2]{s} : $d[2] );
        }
        elsif ( $type eq 'SOA' ) {
            unless ( @d == 7 && !grep( { ref } @d ) ) { $bad->( @d < 7 ? 'unexpected end of input' : 'extra input text' ); last }
            my @n = @d[ 2 .. 6 ];
            unless ( $n[0] =~ /\A\d+\z/ && $n[0] <= 4294967295 ) { $bad->('bad serial number'); last }
            if ( grep { !defined _ttl($_) } @n[ 1 .. 4 ] ) { $bad->('bad ttl'); last }
            $rd = join ' ', $name->( $d[0] ), $name->( $d[1] ), 0 + $n[0], map { _ttl($_) } @n[ 1 .. 4 ];
        }
        else { $fail->("$file:$no: unknown RR type '$type'"); last }
        push @rec, { owner => $owner, ttl => $rttl // $ttl, type => $type, rd => $rd, show => $sh // $rd, line => $no };
    }
    my $apex = "$zone.";
    my ($soa) = grep { $_->{type} eq 'SOA' && $_->{owner} eq $apex } @rec;
    if ( !@err ) {
        if ( !$soa ) { push @err, "zone $zone/IN: has no SOA record" }
        else {
            my $min = ( split ' ', $soa->{rd} )[-1];
            for my $r ( grep { !defined $_->{ttl} } @rec ) {
                push @warn, "$file:$r->{line}: no TTL specified; using SOA MINTTL instead" unless @warn && $warn[-1] =~ /no TTL/;
                $r->{ttl} = $min;
            }
        }
    }
    # Daten ausserhalb der Zone
    my @in;
    for my $r (@rec) {
        if ( $r->{owner} eq $apex || $r->{owner} =~ /\.\Q$apex\E\z/ ) { push @in, $r }
        else { ( my $o = $r->{owner} ) =~ s/\.\z//; push @warn, "$file:$r->{line}: ignoring out-of-zone data ($o)" }
    }
    my %seen;
    @in = grep { !$seen{"$_->{owner} $_->{type} $_->{rd}"}++ } @in;
    my %by;
    push @{ $by{ $_->{owner} } }, $_ for @in;
    if ( !@err ) {
        push @err, "zone $zone/IN: has no NS records" unless grep { $_->{type} eq 'NS' && $_->{owner} eq $apex } @in;
        for my $o ( sort keys %by ) {
            my @t = map { $_->{type} } @{ $by{$o} };
            if ( grep( { $_ eq 'CNAME' } @t ) && grep { $_ ne 'CNAME' } @t ) {
                ( my $s = $o ) =~ s/\.\z//;
                push @err, "zone $zone/IN: $s: CNAME and other data";
            }
        }
        my $has_addr = sub { grep { $_->{type} eq 'A' || $_->{type} eq 'AAAA' } @{ $by{ $_[0] } || [] } };
        my $is_cname = sub { grep { $_->{type} eq 'CNAME' } @{ $by{ $_[0] } || [] } };
        for my $r ( grep { $_->{type} eq 'NS' || $_->{type} eq 'MX' || $_->{type} eq 'SRV' } @in ) {
            my $tg = ( split ' ', $r->{rd} )[-1];
            next unless $tg eq $apex || $tg =~ /\.\Q$apex\E\z/;
            ( my $t = $tg ) =~ s/\.\z//;
            ( my $o = $r->{owner} ) =~ s/\.\z//;
            if ( $is_cname->($tg) ) {
                push @{ $r->{type} eq 'NS' ? \@err : \@warn }, "zone $zone/IN: $o/$r->{type} '$t' is a CNAME (illegal)";
            }
            elsif ( !$has_addr->($tg) ) {
                if   ( $r->{type} eq 'NS' ) { push @err, "zone $zone/IN: NS '$t' has no address records (A or AAAA)" }
                else                        { push @warn, "zone $zone/IN: $o/$r->{type} '$t' has no address records (A or AAAA)" }
            }
        }
        push @err, "zone $zone/IN: not loaded due to errors." if @err;
    }
    else { push @err, "zone $zone/IN: not loaded due to errors." }
    my ( @records, %sh );
    for my $r (@in) {
        my $k = "$r->{owner} $r->{ttl} IN $r->{type} $r->{rd}";
        push @records, $k;
        $sh{$k} = $r->{show} if $r->{show} ne $r->{rd};
    }
    return { ok => @err ? 0 : 1, errors => \@err, warnings => \@warn,
        ( $soa ? ( serial => 0 + ( split ' ', $soa->{rd} )[2] ) : () ), records => \@records, show => \%sh };
}

# --- Laden ------------------------------------------------------------------------

sub _log {
    my ( $dev, @l ) = @_;
    my $b = $dev->{bind} //= {};
    my $h = $dev->{hostname} // 'ns';
    push @{ $b->{log} }, map {"Oct 20 12:00:00 $h named[812]: $_"} @l;
    splice @{ $b->{log} }, 0, @{ $b->{log} } - 40 if @{ $b->{log} } > 40;
    return;
}

sub _zone_entry {
    my ( $z, $p ) = @_;
    my %e = ( type => $z->{type} );
    $e{file} = $z->{path} if defined $z->{path};
    $e{$_} = $z->{$_} for grep { $z->{$_} } qw( allow_transfer also_notify primaries );
    $e{notify} = $z->{notify} if defined $z->{notify};
    if ($p) { $e{serial} = $p->{serial}; $e{records} = $p->{records}; $e{show} = $p->{show} if %{ $p->{show} || {} } }
    return \%e;
}

sub _serial_gt {
    my ( $a, $b ) = @_;
    return 1 if !defined $b;
    return 0 if !defined $a || $a == $b;
    my $d = ( $a - $b ) % 4294967296;
    return $d > 0 && $d < 2147483648 ? 1 : 0;
}


sub prepare {
    my ( $dev, $ctx ) = @_;
    my $b = $dev->{bind} or return;
    return if $b->{zones};
    my %over = map { $_ => $b->{source}{$_} } grep {m{\A/}} keys %{ $b->{source} || {} };
    local $dev->{files} = { %{ $dev->{files} || {} }, %over };
    my $c = parse_conf($dev);
    my %z;
    for my $n ( sort keys %{ $c->{zones} } ) {
        my $cz = $c->{zones}{$n};
        my %d = ( %$cz, allow_transfer => $cz->{allow_transfer} // $c->{allow_transfer}, also_notify => $cz->{also_notify} // $c->{also_notify} );
        if ( $cz->{type} eq 'primary' ) {
            my $text = ( $b->{source} || {} )->{$n} // _text( $dev, $cz->{path} );
            die "prepare: Zone $n ohne Text\n" unless defined $text;
            my $p = parse_zone( $text, $n, $cz->{file} );
            die "prepare: Zone $n laedt nicht: @{ $p->{errors} }\n" unless $p->{ok};
            $z{$n} = _zone_entry( \%d, $p );
        }
        elsif ( $cz->{type} eq 'secondary' ) {
            my $text = ( $b->{source} || {} )->{$n};
            $z{$n} = _zone_entry( \%d, defined $text ? parse_zone( $text, $n ) : undef );
            _secondary_file( $dev, $z{$n} );
        }
    }
    $b->{zones} = \%z;
    delete $b->{source};
    $dev->{dirs}{$_} //= {} for '/var/cache/bind', '/etc/bind';    # legt das Paket an
    return;
}

# Sekundaerzone: named schreibt die uebertragene Zone in ihre Datei (hier als Text)
sub _secondary_file {
    my ( $dev, $z ) = @_;
    return unless defined $z->{file} && $z->{records};
    my $text = '$ORIGIN .' . "\n" . join( '', map {"$_\n"} map { my @f = split ' ', $_, 5; "$f[0]\t$f[1]\tIN $f[3]\t" . ( ( $z->{show} || {} )->{$_} // $f[4] ) } @{ $z->{records} } );
    $dev->{files}{ $z->{file} } = { content => $text, owner => 'bind', group => 'bind', mode => '0644' };
    return;
}

# named laedt: mode reload (alte Zone bleibt bei Fehler), start (frisch),
# reconfig (nur neue Zonen und Optionen), zone (nur diese Zone).

sub load {
    my ( $dev, $ctx, $mode, $only ) = @_;
    my $b = $dev->{bind} //= {};
    my $old = $b->{zones} || {};
    my $c = eval { parse_conf($dev) };
    if ( my $e = $@ ) {
        $e =~ s/\s+\z//;
        _log( $dev, $e, 'reloading configuration failed: unexpected token' );
        return ( $e, 0 );
    }
    my %new;
    my @notify;
    for my $n ( sort keys %{ $c->{zones} } ) {
        my $cz = $c->{zones}{$n};
        my %d = ( %$cz, allow_transfer => $cz->{allow_transfer} // $c->{allow_transfer}, also_notify => $cz->{also_notify} // $c->{also_notify} );
        my $was = $old->{$n};
        if ( $cz->{type} eq 'primary' ) {
            my $keep = $mode eq 'reconfig' && $was || defined $only && $only ne $n && $was;
            if ($keep) { $new{$n} = { %{ _zone_entry( \%d ) }, map { exists $was->{$_} ? ( $_ => $was->{$_} ) : () } qw( serial records show ) }; next }
            my $text = _text( $dev, $cz->{path} );
            my $p = defined $text ? parse_zone( $text, $n, $cz->{file} ) : { ok => 0,
                errors => [ "zone $n/IN: loading from master file $cz->{file} failed: file not found", "zone $n/IN: not loaded due to errors." ] };
            if ( $p->{ok} ) {
                _log( $dev, @{ $p->{warnings} }, "zone $n/IN: loaded serial $p->{serial}" );
                $new{$n} = _zone_entry( \%d, $p );
                push @notify, $n if !$was || _serial_gt( $p->{serial}, $was->{serial} );
            }
            else {
                _log( $dev, @{ $p->{errors} } );
                $new{$n} = $mode eq 'start' || !$was || !$was->{records} ? _zone_entry( \%d )
                    : { %{ _zone_entry( \%d ) }, map { exists $was->{$_} ? ( $_ => $was->{$_} ) : () } qw( serial records show ) };
                return ( $p->{errors}[0] =~ s/\A.*failed: //r, 0, \%new ) if defined $only && $only eq $n;
            }
        }
        elsif ( $cz->{type} eq 'secondary' ) {
            $new{$n} = { %{ _zone_entry( \%d ) }, $was ? ( map { exists $was->{$_} ? ( $_ => $was->{$_} ) : () } qw( serial records show ) ) : () };
        }
    }
    $b->{zones} = \%new;
    _notify( $dev, $ctx, $_ ) for @notify;
    # neue Sekundaerzonen holen
    for my $n ( grep { $new{$_}{type} eq 'secondary' && !$new{$_}{records} } sort keys %new ) { transfer( $dev, $ctx, $n, 1 ) }
    return ( '', 1 );
}

sub _devices {
    my ($ctx) = @_;
    my $st = $ctx->{state} || {};
    return map { [ $_, $st->{$_} ] } grep { ref $st->{$_} eq 'HASH' && ( $st->{$_}{type} // '' ) eq 'linux' } sort keys %$st;
}

sub _device_by_ip {
    my ( $ctx, $ip ) = @_;
    for my $d ( _devices($ctx) ) { return @$d if $d->[0] eq $ip || grep { $_ eq $ip } _ip_of( $d->[1] ) }
    return;
}

sub _allowed {
    my ( $list, @ips ) = @_;
    return 1 unless $list;
    for my $e (@$list) {
        return 0 if $e eq 'none';
        return 1 if $e eq 'any';
        for my $ip (@ips) {
            return 1 if $e eq $ip || $e eq "$ip/32";
            if ( $e =~ m{\A([\d.]+)/(\d+)\z} ) {
                my ( $n, $len ) = ( $1, $2 );
                my $m = $len ? ( 0xffffffff << ( 32 - $len ) ) & 0xffffffff : 0;
                my $f = sub { my $x = 0; $x = $x * 256 + $_ for split /\./, $_[0]; $x };
                return 1 if ( $f->($ip) & $m ) == ( $f->($n) & $m );
            }
        }
    }
    return 0;
}

sub _notify {
    my ( $dev, $ctx, $n ) = @_;
    my $z = $dev->{bind}{zones}{$n} or return;
    return if ( $z->{notify} // '' ) eq 'no';
    my $apex = "$n.";
    my %ip;
    for my $r ( grep {/\A\Q$apex\E \d+ IN NS /} @{ $z->{records} || [] } ) {
        my $tg = ( split ' ', $r )[-1];
        $ip{$_} = 1 for map { ( split ' ', $_ )[-1] } grep {/\A\Q$tg\E \d+ IN A /} @{ $z->{records} };
    }
    $ip{$_} = 1 for map { ( split ' ' )[0] } @{ $z->{also_notify} || [] };
    my %self = map { $_ => 1 } _ip_of($dev);
    my $host = $ctx->{host};
    for my $ip ( sort grep { !$self{$_} } keys %ip ) {
        my ( $name, $sec ) = _device_by_ip( $ctx, $ip ) or next;
        next if $name eq ( $host // '' );
        my $sz = ( ( $sec->{bind} || {} )->{zones} || {} )->{$n} or next;
        next unless $sz->{type} eq 'secondary' && _running($sec);
        _log( $dev, "zone $n/IN: sending notifies (serial $z->{serial})" );
        transfer( $sec, { %$ctx, host => $name }, $n, 0 );
    }
    return;
}


sub transfer {
    my ( $dev, $ctx, $n, $force ) = @_;
    my $z = $dev->{bind}{zones}{$n} or return ( "zone $n: not found", 0 );
    my @mine = _ip_of($dev);
    for my $p ( map { ( split ' ' )[0] } @{ $z->{primaries} || [] } ) {
        my ( $pn, $pd ) = _device_by_ip( $ctx, $p ) or next;
        next unless _running($pd);
        my $pz = ( ( $pd->{bind} || {} )->{zones} || {} )->{$n};
        next unless $pz && $pz->{type} eq 'primary' && $pz->{records};
        if ( !_allowed( $pz->{allow_transfer}, @mine ) ) {
            _log( $dev, "transfer of '$n/IN' from $p#53: failed while receiving responses: REFUSED" );
            _log( $pd, "client \@0x7f3a $mine[0]#40112 ($n): zone transfer '$n/AXFR/IN' denied" );
            return ( 'REFUSED', 0 );
        }
        if ( !$force && !_serial_gt( $pz->{serial}, $z->{serial} ) ) {
            _log( $dev, "zone $n/IN: zone is up to date (serial $z->{serial})" ) if defined $z->{serial};
            return ( 'up to date', 1 );
        }
        @{$z}{qw( serial records )} = @{$pz}{qw( serial records )};
        if ( $pz->{show} ) { $z->{show} = $pz->{show} } else { delete $z->{show} }
        _secondary_file( $dev, $z );
        _log( $dev, "zone $n/IN: transferred serial $pz->{serial}", "transfer of '$n/IN' from $p#53: Transfer completed" );
        return ( 'transferred', 1 );
    }
    _log( $dev, "zone $n/IN: refresh: retry limit for primary reached" );
    return ( 'no primary reachable', 0 );
}


sub service_event {
    my ( $dev, $verb, $ctx ) = @_;
    return if $verb eq 'stop';
    my ( $o, $ok ) = load( $dev, $ctx, $verb eq 'reload' ? 'reload' : 'start' );
    die "Job for named.service failed because the control process exited with error code.\n"
        . "See \"systemctl status named.service\" and \"journalctl -xeu named.service\" for details.\n"
        if !$ok && $verb ne 'reload';
    return;
}

# --- Befehle ----------------------------------------------------------------------


sub rndc {
    my ( $dev, $av, $ctx ) = @_;
    my @a = grep { !/\A-/ } @$av;
    my $cmd = shift(@a) // '';
    return ( "rndc: connect failed: 127.0.0.1#953: connection refused", 0 ) unless _running($dev);
    my $zone = defined $a[0] ? lc( $a[0] =~ s/\.\z//r ) : undef;
    my $zones = $dev->{bind}{zones} || {};
    if ( $cmd eq 'reload' ) {
        if ( defined $zone ) {
            return ( "rndc: 'reload' failed: not found\nno matching zone '$zone' in any view", 0 ) unless $zones->{$zone};
            return ( "rndc: 'reload' failed: not a primary zone", 0 ) unless $zones->{$zone}{type} eq 'primary';
            my $before = JSON::MaybeXS->new( canonical => 1 )->encode( $zones->{$zone} );
            my ( $o, $ok ) = load( $dev, $ctx, 'zone', $zone );
            return ( "rndc: 'reload' failed: $o", 0 ) unless $ok;
            return ( JSON::MaybeXS->new( canonical => 1 )->encode( $dev->{bind}{zones}{$zone} ) eq $before ? 'zone reload up-to-date' : 'zone reload queued', 1 );
        }
        my ( $o, $ok ) = load( $dev, $ctx, 'reload' );
        return ( "rndc: 'reload' failed: unexpected token", 0 ) unless $ok;
        return ( 'server reload successful', 1 );
    }
    if ( $cmd eq 'reconfig' ) {
        my ( $o, $ok ) = load( $dev, $ctx, 'reconfig' );
        return ( "rndc: 'reconfig' failed: unexpected token", 0 ) unless $ok;
        return ( '', 1 );
    }
    if ( $cmd =~ /\A(?:retransfer|refresh|notify|zonestatus)\z/ ) {
        return ( "rndc: '$cmd' failed: not found\nno matching zone '" . ( $zone // '' ) . "' in any view", 0 ) unless defined $zone && $zones->{$zone};
        my $z = $zones->{$zone};
        if ( $cmd eq 'zonestatus' ) {
            return ( join( "\n", "name: $zone", "type: $z->{type}", ( defined $z->{file} ? "files: $z->{file}" : () ),
                'serial: ' . ( $z->{serial} // 0 ), 'nodes: ' . scalar( @{ $z->{records} || [] } ),
                'loaded: ' . ( $z->{records} ? 'yes' : 'no' ) ), 1 );
        }
        if ( $cmd eq 'notify' ) {
            return ( "rndc: 'notify' failed: not a primary zone", 0 ) unless $z->{type} eq 'primary';
            _notify( $dev, $ctx, $zone );
            return ( 'zone notify queued', 1 );
        }
        return ( "rndc: '$cmd' failed: not a secondary zone", 0 ) unless $z->{type} eq 'secondary';
        transfer( $dev, $ctx, $zone, $cmd eq 'retransfer' );
        return ( $cmd eq 'refresh' ? 'zone refresh queued' : '', 1 );
    }
    if ( $cmd eq 'status' ) {
        return ( join( "\n", 'version: BIND 9.18.28-1~deb12u2-Debian (Extended Support Version) <id:>', 'running on localhost: Linux x86_64 6.1.0-26-amd64',
            'number of zones: ' . ( 100 + keys %$zones ) . ' (99 automatic)', 'debug level: 0', 'xfers running: 0', 'server is up and running' ), 1 );
    }
    return ( '', 1 ) if $cmd eq 'flush' || $cmd eq 'freeze' || $cmd eq 'thaw';
    return ( "rndc: '$cmd' failed: unknown command", 0 );
}


sub checkconf {
    my ( $dev, $av, $ctx ) = @_;
    my $z = grep { $_ eq '-z' } @$av;
    my ($file) = grep { !/\A-/ } @$av;
    my $c = eval { parse_conf( $dev, $file ) };
    if ( my $e = $@ ) { $e =~ s/\s+\z//; return ( $e, 0 ) }
    return ( '', 1 ) unless $z;
    my ( @o, $ok );
    $ok = 1;
    for my $n ( sort keys %{ $c->{zones} } ) {
        my $cz = $c->{zones}{$n};
        next unless $cz->{type} eq 'primary';
        my $t = _text( $dev, $cz->{path} );
        my $p = defined $t ? parse_zone( $t, $n, $cz->{file} ) : { ok => 0, errors => ["zone $n/IN: loading from master file $cz->{file} failed: file not found"] };
        push @o, @{ $p->{warnings} || [] }, $p->{ok} ? "zone $n/IN: loaded serial $p->{serial}" : @{ $p->{errors} };
        $ok = 0 unless $p->{ok};
    }
    return ( join( "\n", @o ), $ok );
}


sub checkzone {
    my ( $dev, $av, $ctx ) = @_;
    my @a = grep { !/\A-/ } @$av;
    return ( "usage: named-checkzone [-djqvD] [-c class] [-f inputformat] [-F outputformat] zonename [ filename ]", 0 ) unless @a == 2;
    my ( $zone, $file ) = @a;
    $zone = lc( $zone =~ s/\.\z//r );
    my $t = _text( $dev, $file );
    return ( "zone $zone/IN: loading from master file $file failed: file not found\nzone $zone/IN: not loaded due to errors.", 0 ) unless defined $t;
    my $p = parse_zone( $t, $zone, $file );
    return ( join( "\n", @{ $p->{warnings} }, "zone $zone/IN: loaded serial $p->{serial}", 'OK' ), 1 ) if $p->{ok};
    return ( join( "\n", @{ $p->{warnings} }, @{ $p->{errors} } ), 0 );
}

# Antwort eines Servers auf eine Frage: ( status, \@answer, \@authority, $aa ) oder Fehlertext
sub _answer {
    my ( $srv, $qname, $qtype ) = @_;
    my $zones = ( $srv->{bind} || {} )->{zones} || {};
    my ($zn) = sort { length $b <=> length $a } grep { $qname eq "$_." || $qname =~ /\.\Q$_\E\.\z/ } keys %$zones;
    return ( 'REFUSED', [], [], 0 ) unless defined $zn;
    my $z = $zones->{$zn};
    return ( 'SERVFAIL', [], [], 0 ) unless $z->{records};
    my @r = @{ $z->{records} };
    my ($soa) = grep {/\A\Q$zn\E\. \d+ IN SOA /} @r;
    if ( $qtype eq 'AXFR' ) { return ( 'NOERROR', [ $soa, ( grep { $_ ne $soa } @r ), $soa ], [], 1, $z ) }
    my ( @ans, %seen );
    my $name = $qname;
    for ( 1 .. 8 ) {
        my @here = grep { ( split ' ' )[0] eq $name } @r;
        my @t = grep { my $ty = ( split ' ' )[3]; $qtype eq 'ANY' || $ty eq $qtype } @here;
        if (@t) { push @ans, @t; last }
        my ($cn) = grep { ( split ' ' )[3] eq 'CNAME' } @here;
        last unless $cn && !$seen{$name}++;
        push @ans, $cn;
        $name = ( split ' ', $cn )[-1];
        last unless $name eq "$zn." || $name =~ /\.\Q$zn\E\.\z/;
    }
    return ( 'NOERROR', \@ans, [], 1, $z ) if @ans;
    my $exists = grep { my $o = ( split ' ' )[0]; $o eq $qname || $o =~ /\.\Q$qname\E\z/ } @r;
    return ( $exists ? 'NOERROR' : 'NXDOMAIN', [], [$soa], 1, $z );
}

sub _show {
    my ( $z, $rr ) = @_;
    my @f = split ' ', $rr, 5;
    my $d = ( $z && $z->{show} || {} )->{$rr} // $f[4];
    return ( sprintf( "%s\t\t%s\tIN\t%s\t%s", @f[ 0, 1 ], $f[3], $d ), $d );
}

# Server waehlen: ( name, dev ) | 'ext' mit dns_servers | Fehlertext
sub _server {
    my ( $dev, $ctx, $srv ) = @_;
    my $host = $ctx->{host};
    if ( !defined $srv ) {
        ($srv) = _lx()->can('_nameservers')->($dev);
        return ( undef, undef, ';; no nameservers configured' ) unless defined $srv;
    }
    if ( $srv eq '127.0.0.1' || $srv eq 'localhost' || $srv eq '::1' || $srv eq ( $host // '' ) || grep { $_ eq $srv } _ip_of($dev) ) {
        return ( $srv, $dev );
    }
    my ( $n, $d ) = _device_by_ip( $ctx, $srv );
    return ( $srv, $d ) if $d;
    return ( $srv, undef, undef, ( $dev->{dns_servers} || {} )->{$srv} ) if ( $dev->{dns_servers} || {} )->{$srv};
    return ( $srv, undef, ";; communications error to $srv#53: timed out\n;; communications error to $srv#53: timed out\n;; communications error to $srv#53: timed out\n\n; <<>> DiG 9.18.28-1~deb12u2-Debian <<>> \@$srv\n;; global options: +cmd\n;; no servers could be reached" );
}

sub _query {
    my ( $dev, $ctx, $srv, $qname, $qtype ) = @_;
    my ( $sname, $sdev, $err, $map ) = _server( $dev, $ctx, $srv );
    return ( undef, $err ) if $err;
    if ($map) {
        my $ip = $map->{ $qname =~ s/\.\z//r };
        return ( { status => defined $ip ? 'NOERROR' : 'NXDOMAIN', ans => defined $ip && $qtype =~ /\A(?:A|ANY)\z/ ? ["$qname 300 IN A $ip"] : [],
            auth => [], aa => 0, server => $sname } );
    }
    if ( !_running($sdev) || !$sdev->{bind} ) {
        return ( undef, ";; communications error to $sname#53: connection refused\n" x 3 . ";; no servers could be reached" );
    }
    my ( $st, $ans, $auth, $aa, $z ) = _answer( $sdev, $qname, $qtype );
    if ( $qtype eq 'AXFR' && $st eq 'NOERROR' && !_allowed( $z->{allow_transfer}, _ip_of($dev), ( $sdev == $dev ? ('127.0.0.1') : () ) ) ) {
        return ( { status => 'XFRFAIL', ans => [], auth => [], server => $sname } );
    }
    return ( { status => $st, ans => $ans, auth => $auth, aa => $aa, zone => $z, server => $sname } );
}

sub _rev { my ($ip) = @_; return join( '.', reverse split /\./, $ip ) . '.in-addr.arpa.' }


sub dig {
    my ( $dev, $av, $ctx ) = @_;
    my ( $srv, $name, $type, $short, $answer_only, $rev );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A@(.+)\z/ ) { $srv = $1 }
        elsif ( $x eq '+short' ) { $short = 1 }
        elsif ( $x eq '+noall' ) { $answer_only //= 0 }
        elsif ( $x eq '+answer' ) { $answer_only = 1 }
        elsif ( $x =~ /\A\+/ ) { }
        elsif ( $x eq '-x' ) { $name = _rev( shift(@a) // '' ); $type //= 'PTR' }
        elsif ( $x eq '-t' ) { $type = uc( shift(@a) // '' ) }
        elsif ( $x eq '-c' ) { shift @a }
        elsif ( $x =~ /\A-[46]\z/ ) { }
        elsif ( $x =~ /\A(?:A|AAAA|MX|NS|TXT|SOA|CNAME|PTR|SRV|CAA|ANY|AXFR)\z/i && !defined $type ) { $type = uc $x }    # Typ vor oder nach dem Namen (dig TXT name)
        elsif ( uc $x eq 'IN' ) { }
        elsif ( !defined $name ) { $name = $x }
        else { $type = uc $x }
    }
    $name //= '.';
    $type //= 'A';
    my $q = lc $name;
    $q .= '.' unless $q =~ /\.\z/;
    my ( $r, $err ) = _query( $dev, $ctx, $srv, $q, $type );
    return ( $err, 0 ) unless $r;
    my @show = map { [ _show( $r->{zone}, $_ ) ] } @{ $r->{ans} };
    if ( $r->{status} eq 'XFRFAIL' ) { return ( "; Transfer failed.", 0 ) }
    if ($short) { return ( join( "\n", map { $_->[1] } @show ), 1 ) }
    if ( $type eq 'AXFR' ) {
        return ( join( "\n", "; <<>> DiG 9.18.28-1~deb12u2-Debian <<>> " . join( ' ', @$av ), ';; global options: +cmd',
            ( map { $_->[0] } @show ), ";; XFR size: " . scalar(@show) . ' records (messages 1, bytes 1024)' ), 1 );
    }
    my @l;
    if ( !defined $answer_only ) {
        my $rec = $r->{aa} ? 'qr aa rd' : 'qr rd ra';
        push @l, "; <<>> DiG 9.18.28-1~deb12u2-Debian <<>> " . join( ' ', @$av ), ';; global options: +cmd', ';; Got answer:',
            ";; ->>HEADER<<- opcode: QUERY, status: $r->{status}, id: 4711",
            ";; flags: $rec; QUERY: 1, ANSWER: " . scalar(@show) . ', AUTHORITY: ' . scalar( @{ $r->{auth} } ) . ', ADDITIONAL: 1';
        push @l, ';; WARNING: recursion requested but not available' if $r->{aa} || $r->{status} eq 'REFUSED';
        push @l, '', ';; QUESTION SECTION:', ";$q\t\t\tIN\t$type";
        push @l, '', ';; ANSWER SECTION:', map { $_->[0] } @show if @show;
        push @l, '', ';; AUTHORITY SECTION:', map { ( _show( $r->{zone}, $_ ) )[0] } @{ $r->{auth} } if @{ $r->{auth} };
        push @l, '', ';; Query time: 0 msec', ";; SERVER: $r->{server}#53($r->{server}) (UDP)", ';; WHEN: Tue Oct 20 12:00:00 CEST 2026', ';; MSG SIZE  rcvd: 120';
    }
    else { push @l, map { $_->[0] } @show }
    return ( join( "\n", @l ), 1 );
}


sub host {
    my ( $dev, $av, $ctx ) = @_;
    my ( $type, @a );
    my @w = @$av;
    while (@w) { my $x = shift @w; if ( $x eq '-t' ) { $type = uc( shift(@w) // '' ) } elsif ( $x !~ /\A-/ ) { push @a, $x } }
    my ( $name, $srv ) = @a;
    return ( 'Usage: host [-aCdilrTvVw] [-c class] [-N ndots] [-t type] [-W time] [-R number] [-m flag] [-p port] hostname [server]', 0 ) unless defined $name;
    my $q = lc $name;
    $q = _rev($q) if $q =~ /\A[\d.]+\z/ && _ipv4($q);
    $q .= '.' unless $q =~ /\.\z/;
    my @types = defined $type ? ($type) : $q =~ /in-addr\.arpa\.\z/ ? ('PTR') : qw( A AAAA MX );
    my @l;
    for my $t (@types) {
        my ( $r, $err ) = _query( $dev, $ctx, $srv, $q, $t );
        return ( ";; connection timed out; no servers could be reached", 0 ) unless $r;
        if ( $r->{status} ne 'NOERROR' ) {
            my %c = ( NXDOMAIN => 3, SERVFAIL => 2, REFUSED => 5 );
            return ( "Host $name not found: $c{ $r->{status} }($r->{status})", 0 );
        }
        for my $rr ( @{ $r->{ans} } ) {
            my ( $o, undef, undef, $ty, $d ) = split ' ', $rr, 5;
            $d = ( ( $r->{zone} || {} )->{show} || {} )->{$rr} // $d;
            $o =~ s/\.\z//;
            push @l, $ty eq 'A' ? "$o has address $d" : $ty eq 'AAAA' ? "$o has IPv6 address $d" : $ty eq 'MX' ? "$o mail is handled by $d"
                : $ty eq 'CNAME' ? "$o is an alias for $d" : $ty eq 'TXT' ? "$o descriptive text $d" : $ty eq 'PTR' ? "$o domain name pointer $d"
                : $ty eq 'NS' ? "$o name server $d" : "$o has $ty record $d";
        }
        push @l, "$name has no $t record" if defined $type && !@{ $r->{ans} };
    }
    return ( join( "\n", @l ), 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Dns - BIND 9 on a simulated Linux server — named.conf, zones, rndc, dig, secondaries

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator: rndc, named-checkconf, named-checkzone, dig, host
  Langertha::Holmgang::Sim::Linux::Dns::prepare( $dev, $ctx );     # when the case loads
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Dns::rndc( $dev, \@argv, $ctx );

=head1 DESCRIPTION

An authoritative BIND 9.18 (Debian 12, service C<named>) on a device of type
C<linux> (cai-platform F<docs/entwurf-evals.md> §3.3.1). Configuration and zones are
files under C<files>; what is B<loaded> is under C<bind.zones>:

  bind:
    conf:    /etc/bind/named.conf        # default; include files are read along
    service: named                        # default
    zones:                                # loaded; when missing, prepare() loads the files
      example.com: { type: primary, file: /etc/bind/db.example.com, serial: 2026102001,
                     records: [ "example.com. 3600 IN SOA …", "www.example.com. 3600 IN A 192.0.2.10", … ] }
      example.net: { type: secondary, primaries: [ 192.0.2.53 ], serial: …, records: [ … ] }
    source:  { example.com: "<zone text>" }   # start only: loaded like this (instead of the file)
    log:     [ … ]                        # by the simulator: messages of named (journalctl -u named)

C<records> are canonical lines C<owner. ttl IN TYPE data> (names lower case
and absolute, TXT as B<one> joined text in quotes), so rules check with
C<any>/C<none>/C<contains> no matter how the zone file is written.

B<prepare> (when the case loads) fills C<bind.zones> from C<bind.source> or
the zone files, as a freshly started named would have loaded them.

B<Commands>: C<rndc reload [zone]|reconfig|retransfer zone|refresh zone|notify
zone|status|zonestatus zone|flush>, C<named-checkconf [-z] [file]>,
C<named-checkzone zone file>, C<dig [@server] name [type] [+short]
[-x address] [axfr]>, C<host [-t type] name [server]>; C<systemctl
reload|restart|start|stop named> (through the Linux simulator).

B<Like BIND>: C<rndc reload> and C<systemctl reload named> reread named.conf and
all zones; a broken zone keeps its old state (message in the log), a restart
does not load it at all (SERVFAIL). An error in named.conf makes reload fail;
a restart then fails. Relative file names are taken under C<directory>
(Debian: F</var/cache/bind>). When the serial of a primary zone rises, NOTIFYs
go to the addresses of the NS records and C<also-notify>; a secondary zone on
another device takes over the zone when C<allow-transfer> (zone, else
C<options>; when missing: everyone) allows its address and the serial is newer
(RFC 1982). C<rndc retransfer> fetches without comparing. Checks like
C<named-checkzone>: SOA and NS at the apex, "CNAME and other data", NS without
an address in the zone, TXT text over 255 characters, addresses; data outside
the zone is skipped with a warning.

=head2 parse_conf

  my $c = parse_conf( $dev [, $path] );   # { directory, allow_transfer, zones => { name => {...} } }

Reads named.conf with its include files; an error dies with named's message.

=head2 parse_zone

  my $z = parse_zone( $text, 'example.com', $filename );
  # { ok, serial, records => [...], show => { "<canonical>" => "<display>" }, errors => [...], warnings => [...] }

Reads a zone file like named (see above) and checks it like
C<named-checkzone>.

=head2 prepare

When the case loads, fills C<bind.zones>: every zone from named.conf, loaded
from C<bind.source.E<lt>zoneE<gt>> or the file (primary zones); secondary zones
without a state stay empty. A C<bind.zones> already set is kept.
C<bind.source.E<lt>pathE<gt>> (absolute path) replaces a file while deriving —
so named loads an older version of a named.conf that has since been broken.

=head2 load

  my ( $message, $ok ) = load( $dev, $ctx, $mode [, $zone] );

named loads: C<reload> (old zone stays on error), C<start> (fresh), C<reconfig> (only new zones and options), C<zone> (only this zone).

=head2 transfer

  transfer( $secondary_dev, $ctx, 'example.com', $force );

Fetch a secondary zone: from the first reachable primary, when its
C<allow-transfer> allows the address and (without C<$force>) the serial is
newer. Returns C<( $message, $ok )>.

=head2 service_event

From the Linux simulator on C<systemctl start|restart|reload|stop> of the
service C<named>. An error in named.conf makes start and restart fail (C<die>).

=head2 rndc

C<rndc> (see above).

=head2 checkconf

C<named-checkconf [-z] [file]>.

=head2 checkzone

C<named-checkzone zone file>.

=head2 dig

C<dig> (see above).

=head2 host

C<host [-t type] name [server]>.

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
