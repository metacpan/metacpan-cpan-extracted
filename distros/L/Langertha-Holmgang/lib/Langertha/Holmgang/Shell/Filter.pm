package Langertha::Holmgang::Shell::Filter;
# ABSTRACT: The text filters behind a pipe — grep, head, tail, wc, sort, uniq, cut, awk, tr, fold, python3 -m json.tool

use strict;
use warnings;
use utf8;

use Encode ();

our $VERSION = '0.002';


# cut -d X -f N[,M|N-M] | cut -c N-M
sub _cut {
    my ( $lines, @a ) = @_;
    my ( $d, $f, $c ) = ("\t");
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-d(.+)\z/s ) { $d = $1 }
        elsif ( $x eq '-d' )          { $d = shift @a }
        elsif ( $x =~ /\A-f(.+)\z/ )  { $f = $1 }
        elsif ( $x eq '-f' )          { $f = shift @a }
        elsif ( $x =~ /\A-c(.+)\z/ )  { $c = $1 }
        elsif ( $x eq '-c' )          { $c = shift @a }
    }
    my $spec = $f // $c // return ( 'cut: you must specify a list of bytes, characters, or fields', 0 );
    my @want;
    for my $p ( split /,/, $spec ) {
        my ( $from, $to ) = $p =~ /\A(\d*)(?:-(\d*))?\z/ or return ( "cut: invalid field value '$p'", 0 );
        $from = 1 if $from eq '';
        push @want, [ $from, defined $2 ? ( $to eq '' ? 1e9 : $to ) : $from ];
    }
    my @out;
    for my $l (@$lines) {
        if ( defined $c ) {
            push @out, join '', map { substr( $l, $_->[0] - 1, $_->[1] - $_->[0] + 1 ) } @want;
            next;
        }
        if ( index( $l, $d ) < 0 ) { push @out, $l; next }
        my @fld = split /\Q$d\E/, $l, -1;
        push @out, join $d, map { my $w = $_; grep { defined } @fld[ ( $w->[0] - 1 ) .. ( $w->[1] > @fld ? $#fld : $w->[1] - 1 ) ] } @want;
    }
    return ( join( "\n", @out ), 1 );
}

# awk: die gaengigen Einzeiler — [-F sep] '[BEGIN {…}] [muster] { anweisungen } [END {…}]'
# mit Rechnen (+ - * / %), Variablen und Feldern (Arrays a[k]), Zuweisungen (= += -= *= /=
# %= ++ --), if/else, for (k in a), print/printf, length, int, substr, tolower, toupper;
# was darueber hinausgeht (andere Funktionen, Umleitungen, getline), ist eine Luecke (undef)
# statt einer stillen Leerstelle.
sub _awk {
    my ( $lines, @a ) = @_;
    my ( $sep, $prog, %var, %arr );
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A-F(.+)\z/s ) { $sep = $1 }
        elsif ( $x eq '-F' )          { $sep = shift @a }
        elsif ( $x eq '-v' )          { my ( $k, $v ) = ( shift(@a) // '' ) =~ /\A(\w+)=(.*)\z/s or return (undef); $var{$k} = $v }
        elsif ( !defined $prog )      { $prog = $x }
    }
    return ( 'usage: awk [-F fs][-v var=value][prog | -f progfile][file ...]', 0 ) unless defined $prog;
    my $ofs = ' ';
    # Tokens: Zahlen, Texte, /re/, $, Namen, Operatoren, { } ( ) ; ,
    my @t;
    my $s = $prog;
    my $prev = '';
    while ( length $s ) {
        if    ( $s =~ s/\A\s+// ) { next }
        elsif ( $s =~ s/\A"((?:[^"\\]|\\.)*)"// ) { ( my $v = $1 ) =~ s/\\n/\n/g; $v =~ s/\\t/\t/g; $v =~ s/\\(.)/$1/g; push @t, [ 'str', $v ] }
        elsif ( $prev !~ /\A(?:num|str|name|\)|field)\z/ && $s =~ s{\A/((?:[^/\\]|\\.)*)/}{} ) { push @t, [ 're', $1 ] }
        elsif ( $s =~ s/\A(\d+(?:\.\d+)?)// ) { push @t, [ 'num', $1 ] }
        elsif ( $s =~ s/\A([A-Za-z_]\w*)// ) { push @t, [ 'name', $1 ] }
        elsif ( $s =~ s/\A(\+\+|--|\+=|-=|\*=|\/=|%=|==|!=|<=|>=|!~|&&|\|\||[<>~!\$(){};,=+*\/%\[\]-])// ) { push @t, [ 'op', $1 ] }
        else { return (undef) }
        $prev = $t[-1][0] eq 'op' ? $t[-1][1] : $t[-1][0];
        $prev = 'field' if $t[-1][0] eq 'num' && @t > 1 && $t[-2][0] eq 'op' && $t[-2][1] eq '$';
    }
    my $i = 0;
    my $peek = sub { my $k = $t[$i]; $k && ( @_ ? $k->[0] eq 'op' && $k->[1] eq $_[0] : 1 ) };
    my $take = sub { die "awk\n" unless $peek->(@_); $t[ $i++ ] };
    my ( $or, $cmp, $prim, $concat, $sum );
    # Zahlwert wie awk (fuehrende Zahl, sonst 0) und Ausgabe einer Rechnung (OFMT %.6g)
    my $num = sub { ( $_[0] // '' ) =~ /\A\s*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)/ ? $1 + 0 : 0 };
    my $fmt = sub { my ($v) = @_; $v == int($v) && abs($v) < 1e16 ? sprintf( '%d', $v ) : sprintf( '%.6g', $v ) };
    # Werte: Zahl oder Text wie awk (strnum: Felder, die wie Zahlen aussehen)
    $prim = sub {
        my $k = $t[$i] or die "awk\n";
        if ( $k->[0] eq 'op' && $k->[1] eq '(' ) { $i++; my $e = $or->(); $take->(')'); return $e }
        if ( $k->[0] eq 'op' && $k->[1] eq '!' ) { $i++; my $e = $prim->(); return sub { $e->(@_) ? 0 : 1 } }
        if ( $k->[0] eq 'op' && $k->[1] eq '-' ) { $i++; my $e = $prim->(); return sub { $fmt->( -$num->( $e->(@_) ) ) } }
        if ( $k->[0] eq 'op' && $k->[1] eq '$' ) {
            $i++;
            my $n = $t[$i] or die "awk\n";
            if ( $n->[0] eq 'num' ) { $i++; my $f = $n->[1]; return sub { $f == 0 ? $_[0] : $_[1][ $f - 1 ] // '' } }
            if ( $n->[0] eq 'name' && $n->[1] eq 'NF' ) { $i++; return sub { $_[1][-1] // '' } }
            if ( $n->[0] eq 'op' && $n->[1] eq '(' ) { my $e = $prim->(); return sub { my $f = int $num->( $e->(@_) ); $f == 0 ? $_[0] : $f < 0 ? '' : $_[1][ $f - 1 ] // '' } }
            die "awk\n";
        }
        $i++;
        return sub { $k->[1] } if $k->[0] eq 'num' || $k->[0] eq 'str';
        if ( $k->[0] eq 're' ) { my $re = eval { qr/$k->[1]/ } // die "awk\n"; return sub { $_[0] =~ $re ? 1 : 0 } }
        if ( $k->[0] eq 'name' ) {
            my $n = $k->[1];
            return sub { $_[2] } if $n eq 'NR' || $n eq 'FNR';
            return sub { scalar @{ $_[1] } } if $n eq 'NF';
            if ( $n eq 'length' ) {    # length, length(), length(ausdruck), length(array)
                return sub { length $_[0] } unless $peek->('(');
                $i++;
                if ( $peek->(')') ) { $i++; return sub { length $_[0] } }
                my $an = $t[$i][0] eq 'name' && $t[ $i + 1 ] && $t[ $i + 1 ][1] eq ')' ? $t[$i][1] : undef;
                my $e = $or->();
                $take->(')');
                return sub { defined $an && $arr{$an} ? scalar keys %{ $arr{$an} } : length $e->(@_) };
            }
            if ( $n =~ /\A(?:int|tolower|toupper|substr)\z/ && $peek->('(') ) {
                $i++;
                my @p = ( $or->() );
                while ( $peek->(',') ) { $i++; push @p, $or->() }
                $take->(')');
                return sub { int $num->( $p[0]->(@_) ) } if $n eq 'int' && @p == 1;
                return sub { lc $p[0]->(@_) } if $n eq 'tolower' && @p == 1;
                return sub { uc $p[0]->(@_) } if $n eq 'toupper' && @p == 1;
                if ( $n eq 'substr' && ( @p == 2 || @p == 3 ) ) {
                    return sub {
                        my ( $str, $m ) = ( $p[0]->(@_) // '', int( $num->( $p[1]->(@_) ) + 0.5 ) );
                        my $len = @p == 3 ? int( $num->( $p[2]->(@_) ) + 0.5 ) : length($str) + 1;
                        my ( $from, $to ) = ( $m < 1 ? 1 : $m, $m + $len - 1 );    # wie POSIX awk: 1-basiert, gekappt
                        $to = length $str if $to > length $str;
                        return $to < $from ? '' : substr( $str, $from - 1, $to - $from + 1 );
                    };
                }
                die "awk\n";
            }
            die "awk\n" if $peek->('(') || $n =~ /\A(?:getline|in|if|else|for|while|do|next|exit|function|return|delete|BEGIN|END)\z/;
            if ( $peek->('[') ) {    # Array-Element
                $i++;
                my $ke = $or->();
                $take->(']');
                return sub { my $key = $ke->(@_); ( $arr{$n} || {} )->{$key} // '' };
            }
            return sub { $var{$n} // '' };    # nicht gesetzt: "" bzw. 0 wie awk
        }
        die "awk\n";
    };
    my $isnum = sub { defined $_[0] && $_[0] =~ /\A\s*[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*\z/ };
    # Rechnen: * / % vor + -
    my $prod = sub {
        my $l = $prim->();
        while ( my $k = $t[$i] ) {
            last unless $k->[0] eq 'op' && $k->[1] =~ m{\A[*/%]\z};
            $i++;
            my ( $op, $a, $b ) = ( $k->[1], $l, $prim->() );
            $l = sub {
                my ( $x, $y ) = ( $num->( $a->(@_) ), $num->( $b->(@_) ) );
                die "awk: cmd. line:1: fatal: division by zero attempted\n" if $op ne '*' && $y == 0;
                $fmt->( $op eq '*' ? $x * $y : $op eq '/' ? $x / $y : $x - $y * int( $x / $y ) );
            };
        }
        return $l;
    };
    $sum = sub {
        my $l = $prod->();
        while ( my $k = $t[$i] ) {
            last unless $k->[0] eq 'op' && $k->[1] =~ /\A[+-]\z/;
            $i++;
            my ( $op, $a, $b ) = ( $k->[1], $l, $prod->() );
            $l = sub { my ( $x, $y ) = ( $num->( $a->(@_) ), $num->( $b->(@_) ) ); $fmt->( $op eq '+' ? $x + $y : $x - $y ) };
        }
        return $l;
    };
    $concat = sub {
        my @e = ( $sum->() );
        while ( my $k = $t[$i] ) {
            last if $k->[0] eq 'op' && $k->[1] !~ /\A[\$(]\z/;
            last if $k->[0] eq 'name' && $k->[1] =~ /\A(?:print|printf|in|if|else|for|while)\z/;
            last if $k->[0] eq 'op' && $k->[1] =~ /\A(?:\+\+|--|\+=|-=|\*=|\/=|%=|=|\])\z/;
            push @e, $sum->();
        }
        return $e[0] if @e == 1;
        return sub { my @x = @_; join '', map { $_->(@x) } @e };
    };
    $cmp = sub {
        my $l = $concat->();
        if ( $t[$i] && $t[$i][0] eq 'name' && $t[$i][1] eq 'in' ) {    # (schluessel in array)
            $i++;
            my $an = ( $t[ $i++ ] // die "awk\n" )->[1];
            return sub { exists( ( $arr{$an} || {} )->{ $l->(@_) } ) ? 1 : 0 };
        }
        my $k = $t[$i];
        return $l unless $k && $k->[0] eq 'op' && $k->[1] =~ /\A(?:==|!=|<=|>=|<|>|~|!~)\z/;
        my $op = $k->[1];
        $i++;
        if ( $op eq '~' || $op eq '!~' ) {
            my $r = $t[$i];
            my $re;
            if ( $r && $r->[0] eq 're' ) { $i++; $re = eval { qr/$r->[1]/ } // die "awk\n" }
            else { my $e = $concat->(); return sub { my $m = $l->(@_) =~ /${\ $e->(@_)}/ ? 1 : 0; $op eq '~' ? $m : 1 - $m } }
            return sub { my $m = $l->(@_) =~ $re ? 1 : 0; $op eq '~' ? $m : 1 - $m };
        }
        my $rt = $concat->();
        return sub {
            my ( $x, $y ) = ( $l->(@_), $rt->(@_) );
            my $c = $isnum->($x) && $isnum->($y) ? ( $x <=> $y ) : ( "$x" cmp "$y" );
            ( $op eq '==' ? $c == 0 : $op eq '!=' ? $c != 0 : $op eq '<' ? $c < 0 : $op eq '<=' ? $c <= 0 : $op eq '>' ? $c > 0 : $c >= 0 ) ? 1 : 0;
        };
    };
    my $and = sub {
        my @e = ( $cmp->() );
        while ( $peek->('&&') ) { $i++; push @e, $cmp->() }
        return @e == 1 ? $e[0] : sub { for my $f (@e) { return 0 unless $f->(@_) } 1 };
    };
    $or = sub {
        my @e = ( $and->() );
        while ( $peek->('||') ) { $i++; push @e, $and->() }
        return @e == 1 ? $e[0] : sub { for my $f (@e) { return 1 if $f->(@_) } 0 };
    };
    # Anweisungen: print/printf, Zuweisungen (auch a[k], ++/--), if/else, for (k in a), { … };
    # jede Anweisung ist ein Code, der ihre Ausgabe (Text) liefert
    my $setv = sub {    # Wert setzen: Variable (FS/OFS wirken), Array-Element
        my ( $n, $key, $v ) = @_;
        if ( defined $key ) { $arr{$n}{$key} = $v; return }
        $var{$n} = $v;
        $sep = $v if $n eq 'FS';
        $ofs = $v if $n eq 'OFS';
    };
    my ( $stmt, $block );
    $block = sub {
        my @st;
        while ( $t[$i] && !$peek->('}') ) {
            if ( $peek->(';') ) { $i++; next }
            push @st, $stmt->();
        }
        return sub { my @x = @_; join '', map { $_->(@x) } @st };
    };
    $stmt = sub {
        my $k = $t[$i] or die "awk\n";
        if ( $peek->('{') ) { $i++; my $b = $block->(); $take->('}'); return $b }
        if ( $k->[0] eq 'name' && $k->[1] eq 'if' ) {
            $i++;
            $take->('(');
            my $c = $or->();
            $take->(')');
            $i++ while $peek->(';');
            my $then = $stmt->();
            my $save = $i;
            $i++ while $peek->(';');
            my $else;
            if ( $t[$i] && $t[$i][0] eq 'name' && $t[$i][1] eq 'else' ) { $i++; $else = $stmt->() }
            else { $i = $save }
            return sub { $c->(@_) ? $then->(@_) : $else ? $else->(@_) : '' };
        }
        if ( $k->[0] eq 'name' && $k->[1] eq 'for' && $t[ $i + 1 ] && $t[ $i + 1 ][1] eq '(' && $t[ $i + 3 ] && $t[ $i + 3 ][1] eq 'in' ) {
            $i += 2;
            my $kv = $t[ $i++ ][1];
            $i++;
            my $an = ( $t[ $i++ ] // die "awk\n" )->[1];
            $take->(')');
            $i++ while $peek->(';');
            my $body = $stmt->();
            return sub {
                my @x = @_;
                my @keys = keys %{ $arr{$an} || {} };
                @keys = ( grep { !/\A-?\d+(?:\.\d+)?\z/ } @keys ) ? sort @keys : sort { $a <=> $b } @keys;
                my $o = '';
                for my $key (@keys) { $var{$kv} = $key; $o .= $body->(@x) }
                return $o;
            };
        }
        if ( $k->[0] eq 'name' && $k->[1] =~ /\A(?:print|printf)\z/ ) {
            $i++;
            my @items;
            my $at = $i;
            if ( $peek->('(') ) {    # print( a, b ) / printf( fmt, … )
                $i++;
                my @p = eval { my @x = ( $or->() ); while ( $peek->(',') ) { $i++; push @x, $or->() } $take->(')'); @x };
                if ( @p && ( !$t[$i] || $peek->(';') || $peek->('}') ) ) { @items = @p } else { $i = $at }
            }
            if ( !@items && $t[$i] && !$peek->(';') && !$peek->('}') ) {
                push @items, $concat->();
                while ( $peek->(',') ) { $i++; push @items, $concat->() }
            }
            die "awk\n" if $t[$i] && !$peek->(';') && !$peek->('}') && !( $t[$i][0] eq 'name' && $t[$i][1] eq 'else' );    # print > datei, print | befehl
            my $how = $k->[1];
            return sub {
                my @x = @_;
                my @v = map { $_->(@x) } @items;
                return sprintf( shift(@v) // '', @v ) if $how eq 'printf';
                return @v ? join( $ofs, @v ) . "\n" : "$x[0]\n";
            };
        }
        # Zuweisung: [++|--]name[[k]] [= += -= *= /= %= ++ --] ausdruck
        my $pre;
        if ( $peek->('++') || $peek->('--') ) { $pre = $t[ $i++ ][1] }
        my $n = $t[$i];
        die "awk\n" unless $n && $n->[0] eq 'name' && $n->[1] !~ /\A(?:NR|NF|FNR|getline|next|exit|delete|while|do|function|return)\z/;
        $i++;
        my $ke;
        if ( $peek->('[') ) { $i++; $ke = $or->(); $take->(']') }
        my $name = $n->[1];
        my $get = sub { my $key = shift; defined $key ? ( $arr{$name} || {} )->{$key} // '' : $var{$name} // '' };
        if ($pre) { my $d = $pre eq '++' ? 1 : -1; return sub { my $key = $ke ? $ke->(@_) : undef; $setv->( $name, $key, $fmt->( $num->( $get->($key) ) + $d ) ); '' } }
        my $op = $t[$i] && $t[$i][0] eq 'op' ? $t[$i][1] : '';
        if ( $op eq '++' || $op eq '--' ) {
            $i++;
            my $d = $op eq '++' ? 1 : -1;
            return sub { my $key = $ke ? $ke->(@_) : undef; $setv->( $name, $key, $fmt->( $num->( $get->($key) ) + $d ) ); '' };
        }
        die "awk\n" unless $op =~ /\A(?:=|\+=|-=|\*=|\/=|%=)\z/;
        $i++;
        my $e = $or->();
        return sub {
            my $key = $ke ? $ke->(@_) : undef;
            my $v = $e->(@_);
            if ( $op ne '=' ) {
                my ( $x, $y ) = ( $num->( $get->($key) ), $num->($v) );
                die "awk: cmd. line:1: fatal: division by zero attempted\n" if ( $op eq '/=' || $op eq '%=' ) && $y == 0;
                $v = $fmt->( $op eq '+=' ? $x + $y : $op eq '-=' ? $x - $y : $op eq '*=' ? $x * $y : $op eq '/=' ? $x / $y : $x - $y * int( $x / $y ) );
            }
            $setv->( $name, $key, $v );
            '';
        };
    };
    my ( @rules, @begin, @end );
    my $ok = eval {
        while ( $i < @t ) {
            if ( $peek->(';') ) { $i++; next }
            if ( $t[$i][0] eq 'name' && $t[$i][1] =~ /\A(BEGIN|END)\z/ ) {
                my $which = $1;
                $i++;
                $take->('{');
                my $b = $block->();
                $take->('}');
                push @{ $which eq 'BEGIN' ? \@begin : \@end }, $b;
                next;
            }
            my $pat = $peek->('{') ? undef : $or->();
            my $act;
            if ( $peek->('{') ) { $i++; $act = $block->(); $take->('}') }
            push @rules, [ $pat, $act ];
            $i++ while $peek->(';');
        }
        1;
    };
    return (undef) unless $ok;
    my $out = '';
    my $nr  = 0;
    my ( $last, @lastf ) = ('');
    my $run = eval {
        $out .= join '', map { $_->( '', [], 0 ) } @begin;
        for my $l ( @rules || @end ? @$lines : () ) {    # nur BEGIN: awk liest keine Eingabe
            $nr++;
            my @f = !defined $sep || $sep eq ' ' ? split( ' ', $l ) : length($sep) == 1 ? split( /\Q$sep\E/, $l, -1 ) : split( /$sep/, $l, -1 );
            ( $last, @lastf ) = ( $l, @f );
            for my $r (@rules) {
                my ( $pat, $act ) = @$r;
                next if $pat && !$pat->( $l, \@f, $nr );
                $out .= $act ? $act->( $l, \@f, $nr ) : "$l\n";
            }
        }
        $out .= join '', map { $_->( $last, \@lastf, $nr ) } @end;    # END: der letzte Satz und NR bleiben
        1;
    };
    if ( !$run ) { ( my $e = $@ ) =~ s/\s+\z//; return ( $out . $e, 0 ) }
    $out =~ s/\n\z//;
    return ( $out, 1 );
}

# tr [-c|-C] [-d] [-s] SATZ1 [SATZ2] wie GNU tr: Escapes, Bereiche a-z, Klassen
# [:alpha:] …; SATZ2 wird mit seinem letzten Zeichen aufgefuellt. [=c=] und [c*n]: Luecke.
my %TR_CLASS = (
    alpha => qr/[[:alpha:]]/, digit => qr/[0-9]/, alnum => qr/[[:alnum:]]/, upper => qr/[A-Z]/, lower => qr/[a-z]/,
    space => qr/\s/, blank => qr/[ \t]/, punct => qr/[[:punct:]]/, print => qr/[^\x00-\x1f\x7f]/,
    graph => qr/[^\x00-\x20\x7f]/, cntrl => qr/[\x00-\x1f\x7f]/, xdigit => qr/[0-9A-Fa-f]/,
);

sub _tr_set {
    my ($s) = @_;
    my %esc = ( n => "\n", t => "\t", r => "\r", '\\' => '\\', a => "\a", b => "\b", f => "\f", v => "\x0b" );
    my @c;
    my $i = 0;
    while ( $i < length $s ) {
        if ( substr( $s, $i ) =~ /\A\[:(\w+):\]/ ) {
            my $re = $TR_CLASS{$1} // return;
            push @c, grep { $_ =~ $re } map { chr } 0 .. 127;
            $i += length "[:$1:]";
            next;
        }
        return if substr( $s, $i ) =~ /\A\[(?:=.=|.\*\d*\])/;
        my $c = substr( $s, $i, 1 );
        if ( $c eq '\\' && $i + 1 < length $s ) {
            my $n = substr( $s, $i + 1 );
            if ( $n =~ /\A([0-7]{1,3})/ ) { $c = chr oct $1; $i += 1 + length $1 }
            else { $c = $esc{ substr( $n, 0, 1 ) } // substr( $n, 0, 1 ); $i += 2 }
        }
        else { $i++ }
        if ( substr( $s, $i, 1 ) eq '-' && $i + 1 < length $s ) {    # Bereich
            my $to = substr( $s, $i + 1, 1 );
            $i += 2;
            if ( $to eq '\\' ) { my $n = substr( $s, $i, 1 ); $to = $esc{$n} // $n; $i++ }
            return if ord $to < ord $c;
            push @c, map { chr } ord($c) .. ord($to);
            next;
        }
        push @c, $c;
    }
    return \@c;
}

sub _tr {
    my ( $text, @a ) = @_;
    my ( %o, @sets );
    for my $x (@a) {
        if ( $x =~ /\A-([cCdst]+)\z/ ) { $o{ $_ eq 'C' ? 'c' : $_ } = 1 for split //, $1 }
        elsif ( $x =~ /\A--/ ) { return (undef) }
        else { push @sets, $x }
    }
    return ( 'tr: missing operand', 0 ) unless @sets;
    my $s1 = _tr_set( $sets[0] ) // return (undef);
    my $s2 = defined $sets[1] ? _tr_set( $sets[1] ) // return (undef) : undef;
    my %in1 = map { $_ => 1 } @$s1;
    my $m1 = $o{c} ? sub { !$in1{ $_[0] } } : sub { $in1{ $_[0] } };
    my @out;
    if ( $o{d} ) {
        @out = grep { !$m1->($_) } split //, $text;
    }
    elsif ( $s2 && !$o{d} ) {
        return ( 'tr: when not truncating set1, string2 must be non-empty', 0 ) unless @$s2;
        my %map;
        if ( $o{c} ) { %map = () }
        else { $map{ $s1->[$_] } //= $s2->[ $_ < @$s2 ? $_ : -1 ] for 0 .. $#$s1 }
        @out = map { $o{c} ? ( $m1->($_) ? $s2->[-1] : $_ ) : exists $map{$_} ? $map{$_} : $_ } split //, $text;
    }
    elsif ( $o{s} ) { @out = split //, $text }
    else { return ( "tr: missing operand after '$sets[0]'", 0 ) }
    if ( $o{s} ) {    # Wiederholungen aus dem letzten Satz zusammenziehen
        my %sq = map { $_ => 1 } @{ $s2 && !$o{d} ? $s2 : $s1 };
        my $msq = $s2 && !$o{d} ? sub { $sq{ $_[0] } } : $m1;
        my @z;
        for (@out) { push @z, $_ unless @z && $z[-1] eq $_ && $msq->($_) }
        @out = @z;
    }
    return ( join( '', @out ), 1 );
}


# Grundlegender regulaerer Ausdruck (grep ohne -E) als Perl: \| \( \) \+ \? \{ \} sind
# besonders, ohne \ stehen | ( ) + ? { } fuer sich
sub _bre {
    my ($p) = @_;
    my $out = '';
    while ( $p =~ /\G(?:\\(.)|([|()+?{}])|(.))/gcs ) {
        if    ( defined $1 ) { my $c = $1; $out .= $c =~ /\A[|()+?{}]\z/ ? $c : "\\$c" }
        elsif ( defined $2 ) { $out .= "\\$2" }
        else                 { $out .= $3 }
    }
    return $out;
}

sub filter_output {
    my ( $text, $argv ) = @_;
    my ( $cmd, @a ) = @$argv;
    my @lines = length $text ? split /\n/, $text, -1 : ();
    pop @lines if @lines && $lines[-1] eq '';
    if ( $cmd eq 'grep' || $cmd eq 'egrep' ) {
        my %f;
        my @pat;
        my %n = ( A => 0, B => 0 );
        while (@a) {
            my $x = shift @a;
            if ( $x =~ /\A-([ivEFwcnHhs]*)([ABCm])(\d*)\z/ ) {
                my ( $fl, $o, $num ) = ( $1, $2, $3 );
                $f{$_} = 1 for split //, $fl;
                my $v = length $num ? $num : shift(@a) // 0;
                $v = $v =~ /\A(\d+)\z/ ? 0 + $1 : 0;
                if    ( $o eq 'C' ) { @n{qw( A B )} = ( $v, $v ) }
                elsif ( $o eq 'm' ) { $n{m} = $v }
                else                { $n{$o} = $v }
                $f{ctx} = 1 if $o ne 'm';
                next;
            }
            if ( $x =~ /\A-([ivEFwcnHhs]+)\z/ ) { $f{$_} = 1 for split //, $1; next }
            if ( $x eq '-e' ) { push @pat, shift @a; next }
            push @pat, $x;
        }
        return ( "Usage: grep [OPTION]... PATTERNS [FILE]...", 0 ) unless @pat;
        my @re = map {
            my $p = $_;
            $p = quotemeta $p if $f{F};
            $p = _bre($p) unless $f{E} || $f{F} || $cmd eq 'egrep';    # BRE: \| ist Alternative, { steht fuer sich
            $p = "\\b$p\\b" if $f{w};
            my $re = eval { $f{i} ? qr/$p/i : qr/$p/ };
            $re // qr/\Q$_\E/;
        } @pat;
        my @idx = grep { my $l = $lines[$_]; my $m = grep { $l =~ $_ } @re; $f{v} ? !$m : $m } 0 .. $#lines;
        @idx = @idx[ 0 .. $n{m} - 1 ] if defined $n{m} && @idx > $n{m};
        return ( scalar(@idx), @idx ? 1 : 0 ) if $f{c};
        my %hit = map { $_ => 1 } @idx;
        my ( @out, $last );
        for my $i ( $f{ctx} ? ( map { ( $_ - $n{B} < 0 ? 0 : $_ - $n{B} ) .. ( $_ + $n{A} > $#lines ? $#lines : $_ + $n{A} ) } @idx ) : @idx ) {
            next if defined $last && $i <= $last;
            push @out, '--' if $f{ctx} && defined $last && $i > $last + 1;
            push @out, ( $f{n} ? ( $i + 1 ) . ( $hit{$i} ? ':' : '-' ) : '' ) . $lines[$i];
            $last = $i;
        }
        return ( join( "\n", @out ), @idx ? 1 : 0 );
    }
    if ( $cmd eq 'head' || $cmd eq 'tail' ) {
        my $n = 10;
        while (@a) {
            my $x = shift @a;
            if    ( $x eq '-n' || $x eq '--lines' ) { $n = shift(@a) // 10 }
            elsif ( $x =~ /\A(?:-n|--lines=)([-+]?\d+)\z/ || $x =~ /\A-(\d+)\z/ ) { $n = $1 }
            elsif ( $x =~ /\A-c(\d*)\z/ ) {    # Bytes statt Zeilen: -cN oder -c N
                my $c = length $1 ? $1 : shift(@a) // 0;
                $c = 0 + ( $c =~ /(\d+)/ ? $1 : 0 );
                return ( $cmd eq 'head' ? substr( $text, 0, $c ) : substr( $text, length($text) > $c ? -$c : 0 ), 1 );
            }
        }
        return ( "$cmd: invalid number of lines: '$n'", 0 ) unless $n =~ /\A([-+]?)(\d+)\z/;
        my ( $sg, $k ) = ( $1, 0 + $2 );
        my @l;
        if ( $cmd eq 'head' ) {    # head -n -K: alles ausser den letzten K
            my $last = $sg eq '-' ? @lines - $k - 1 : ( $k < @lines ? $k : @lines ) - 1;
            @l = @lines[ 0 .. $last ];
        }
        else {                     # tail -n +K: ab Zeile K
            @l = $sg eq '+' ? @lines[ ( $k > 0 ? $k - 1 : 0 ) .. $#lines ] : @lines[ ( @lines > $k ? @lines - $k : 0 ) .. $#lines ];
        }
        return ( join( "\n", @l ), 1 );
    }
    return ( scalar(@lines), 1 ) if $cmd eq 'wc' && "@a" eq '-l';
    if ( $cmd eq 'wc' && !grep { !/\A-[lcwm]+\z/ } @a ) {    # wc -l/-c/-w/-m, kombiniert bzw. alle; Bytes genau (aus einer Pipe ohne letztes Zeilenende)
        my $nw = () = $text =~ /\S+/g;
        my %n = ( l => scalar(@lines), w => $nw, m => length $text, c => length Encode::encode( 'UTF-8', $text ) );
        my @want = @a ? map { /\A-(\w+)\z/ ? split //, $1 : () } @a : qw( l w c );
        return ( join( ' ', map { $n{$_} } grep { my $k = $_; grep { $_ eq $k } @want } qw( l w m c ) ), 1 );
    }
    if ( $cmd eq 'sort' ) {
        my %o = map { $_ => 1 } map { /\A-(\w+)\z/ ? split( //, $1 ) : () } @a;
        my %u = ( K => 1024, M => 1024**2, G => 1024**3, T => 1024**4 );
        my $hv = sub { my ( $x, $s ) = $_[0] =~ /(-?\d+(?:\.\d+)?)([KMGT]?)/; $x //= 0; $s ? $x * $u{$s} : $x };
        my @s = $o{h} ? sort { $hv->($a) <=> $hv->($b) } @lines
            : $o{n} ? sort { ( ( $a =~ /(-?\d+)/ )[0] // 0 ) <=> ( ( $b =~ /(-?\d+)/ )[0] // 0 ) } @lines
            :         sort @lines;
        @s = reverse @s if $o{r};
        if ( $o{u} ) { my %seen; @s = grep { !$seen{$_}++ } @s }
        return ( join( "\n", @s ), 1 );
    }
    if ( $cmd eq 'uniq' ) {    # -c zaehlt (wie GNU: %7d), -d nur doppelte, -u nur einzelne
        my %o;
        for (@a) { return (undef) unless /\A-([cdu]+)\z/; $o{$_} = 1 for split //, $1 }
        my @u;
        for (@lines) { if ( @u && $u[-1][0] eq $_ ) { $u[-1][1]++ } else { push @u, [ $_, 1 ] } }
        @u = grep { $_->[1] > 1 } @u if $o{d};
        @u = grep { $_->[1] == 1 } @u if $o{u};
        return ( join( "\n", map { $o{c} ? sprintf( '%7d %s', $_->[1], $_->[0] ) : $_->[0] } @u ), 1 );
    }
    return _cut( \@lines, @a ) if $cmd eq 'cut';
    return _awk( \@lines, @a ) if $cmd eq 'awk';
    return _tr( join( "\n", @lines ), @a ) if $cmd eq 'tr';
    if ( $cmd eq 'fold' ) {    # fold [-b] [-s] [-w N]: Zeilen auf N Zeichen umbrechen
        my ( $w, $sp ) = ( 80, 0 );
        while (@a) {
            my $x = shift @a;
            if    ( $x =~ /\A-w(\d+)\z/ || $x =~ /\A--width=(\d+)\z/ ) { $w = $1 }
            elsif ( $x eq '-w' ) { $w = shift(@a) // '' }
            elsif ( $x =~ /\A-(\d+)\z/ ) { $w = $1 }
            elsif ( $x =~ /\A-[bs]+\z/ ) { $sp = 1 if $x =~ /s/ }
            else { return (undef) }
        }
        return ( "fold: invalid number of columns: '$w'", 0 ) unless $w =~ /\A\d+\z/ && $w > 0;
        my @o;
        for my $l (@lines) {
            my $r = $l;
            while ( length $r > $w ) {
                my $cut = $w;
                if ( $sp && substr( $r, 0, $w ) =~ /.*\s/s ) { $cut = $+[0] }
                push @o, substr( $r, 0, $cut );
                $r = substr( $r, $cut );
            }
            push @o, $r;
        }
        return ( join( "\n", @o ), 1 );
    }
    return ( $text, 1 ) if $cmd eq 'cat' && !@a;
    return _json_tool( $text, @a[ 2 .. $#a ] ) if $cmd =~ m{\A(?:/usr/bin/)?python3\z} && @a >= 2 && "@a[0,1]" eq '-m json.tool';
    return (undef);
}

# python3 -m json.tool [--sort-keys] [--indent N] [--no-ensure-ascii]: Reihenfolge der Schluessel
# bleibt, Einrueckung 4, Nicht-ASCII als \uXXXX. Was nicht als JSON lesbar ist: undef (ausser leer).
sub _json_tool {
    my ( $text, @o ) = @_;
    my ( $sort, $ind, $ascii ) = ( 0, 4, 1 );
    while (@o) {
        my $x = shift @o;
        if    ( $x eq '--sort-keys' )       { $sort  = 1 }
        elsif ( $x eq '--no-ensure-ascii' ) { $ascii = 0 }
        elsif ( $x eq '--indent' && ( $o[0] // '' ) =~ /\A\d+\z/ ) { $ind = shift @o }
        elsif ( $x =~ /\A--indent=(\d+)\z/ ) { $ind = $1 }
        else  { return (undef) }
    }
    return ( 'Expecting value: line 1 column 1 (char 0)', 0 ) if $text !~ /\S/;
    my $ws = sub { $text =~ /\G\s*/gc };
    my $val;
    $val = sub {
        $ws->();
        if ( $text =~ /\G\{/gc ) {
            my @kv;
            $ws->();
            return [ obj => \@kv ] if $text =~ /\G\}/gc;
            while (1) {
                my $k = $val->() // return;
                return unless $k->[0] eq 'str';
                $ws->();
                $text =~ /\G:/gc or return;
                my $v = $val->() // return;
                push @kv, [ $k, $v ];
                $ws->();
                next if $text =~ /\G,/gc;
                last if $text =~ /\G\}/gc;
                return;
            }
            return [ obj => \@kv ];
        }
        if ( $text =~ /\G\[/gc ) {
            my @l;
            $ws->();
            return [ arr => \@l ] if $text =~ /\G\]/gc;
            while (1) {
                push @l, $val->() // return;
                $ws->();
                next if $text =~ /\G,/gc;
                last if $text =~ /\G\]/gc;
                return;
            }
            return [ arr => \@l ];
        }
        if ( $text =~ /\G"((?:[^"\\\x00-\x1f]|\\["\\\/bfnrt]|\\u[0-9a-fA-F]{4})*)"/gc ) {
            my $s = $1;
            $s =~ s/\\u([dD][89abAB][0-9a-fA-F]{2})\\u([dD][c-fC-F][0-9a-fA-F]{2})/chr( 0x10000 + ( hex($1) - 0xD800 ) * 0x400 + hex($2) - 0xDC00 )/ge;
            my %esc = ( b => "\b", f => "\f", n => "\n", r => "\r", t => "\t" );
            $s =~ s/\\(?:u([0-9a-fA-F]{4})|(.))/defined $1 ? chr hex $1 : $esc{$2} \/\/ $2/ge;
            return [ str => $s ];
        }
        return [ lit => $1 ] if $text =~ /\G(-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null)/gc;
        return;
    };
    my $doc = $val->() // return (undef);
    $ws->();
    return (undef) if ( pos($text) // 0 ) != length $text;
    my $q = sub {
        my $s = shift;
        $s =~ s/(["\\])/\\$1/g;
        $s =~ s/\n/\\n/g;
        $s =~ s/\r/\\r/g;
        $s =~ s/\t/\\t/g;
        $s =~ s/\x08/\\b/g;
        $s =~ s/\f/\\f/g;
        $s =~ s/([\x00-\x1f])/sprintf '\\u%04x', ord $1/ge;
        $s =~ s/([^\x00-\x7f])/_u16( ord $1 )/ge if $ascii;
        return qq{"$s"};
    };
    my $out;
    $out = sub {
        my ( $n, $d ) = @_;
        my $pad = ' ' x ( $ind * ( $d + 1 ) );
        my $end = ' ' x ( $ind * $d );
        return $n->[1] if $n->[0] eq 'lit';
        return $q->( $n->[1] ) if $n->[0] eq 'str';
        if ( $n->[0] eq 'arr' ) {
            return '[]' unless @{ $n->[1] };
            return "[\n" . join( ",\n", map { $pad . $out->( $_, $d + 1 ) } @{ $n->[1] } ) . "\n$end]";
        }
        my @kv = @{ $n->[1] };
        return '{}' unless @kv;
        @kv = sort { $a->[0][1] cmp $b->[0][1] } @kv if $sort;
        return "{\n" . join( ",\n", map { $pad . $q->( $_->[0][1] ) . ': ' . $out->( $_->[1], $d + 1 ) } @kv ) . "\n$end}";
    };
    return ( $out->( $doc, 0 ), 1 );
}

sub _u16 {
    my ($c) = @_;
    return sprintf '\\u%04x', $c if $c <= 0xFFFF;
    $c -= 0x10000;
    return sprintf '\\u%04x\\u%04x', 0xD800 + ( $c >> 10 ), 0xDC00 + ( $c & 0x3FF );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Shell::Filter - The text filters behind a pipe — grep, head, tail, wc, sort, uniq, cut, awk, tr, fold, python3 -m json.tool

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Shell::Filter ();

  my ( $text, $ok ) = Langertha::Holmgang::Shell::Filter::filter_output( $output, [ 'grep', '-i', 'wg0' ] );
  # ( undef ) when the filter (or this program of it) is not modelled

=head1 DESCRIPTION

The filters a command's output goes through behind a C<|>: used by the Linux
simulator for its pipes and by the World for the output of observations. They
work only on the text they are given.

=head2 filter_output

  my $text = filter_output( $text, [ 'grep', '-i', 'wg0' ] );

Applies a filter command of a pipe: C<grep> (C<-i>, C<-v>, C<-E>, C<-F>,
C<-w>, C<-c>), C<head>/C<tail> (C<-n N>, C<-N>, C<-n -N>, C<-n +N>, C<-c N>), C<wc>
(C<-l>/C<-w>/C<-m>/C<-c>, combined), C<sort> (C<-n>,
C<-r>, C<-u>), C<uniq> (C<-c>, C<-d>, C<-u>), C<cut> (C<-d>, C<-f>, C<-c>), C<awk> (a small part: C<-F>, C<-v>,
C<BEGIN { FS/OFS = "…" }> or C<BEGIN { print … }>, patterns with C<== != E<lt> E<lt>= E<gt> E<gt>=> (number or string like awk),
C<~>/C<!~> with C</re/>, C<&&>, C<||>, C<!>, parentheses, C<NR>, C<NF>, C<$N>, C<$NF>, arithmetic
C<+ - * / %>, C<length>, C<int>, C<substr>, C<tolower>, C<toupper>; variables and arrays
(C<a[k]>, C<k in a>), assignments C<= += -= *= /= %= ++ -->, C<if/else>, C<for (k in a)>,
C<END>; actions C<print> with fields, literals and concatenation, comma as OFS, C<printf>;
other functions, C<while>, C<?:>, redirections and C<getline> are a gap),
C<tr> (ranges, classes, C<-c>/C<-d>/C<-s>), C<fold> (C<-w N>, C<-s>), C<cat>.
Returns C<( $text, $ok )>, or C<( undef )> when the
command (or this program of it) is not modelled here.

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
