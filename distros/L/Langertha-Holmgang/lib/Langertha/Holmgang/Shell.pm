package Langertha::Holmgang::Shell;
# ABSTRACT: The bash grammar of the simulators — words, items, heredocs, blocks, expansion, test

use strict;
use warnings;
use utf8;

our $VERSION = '0.002';


# --- Glieder -------------------------------------------------------------------


sub split_items {
    my ($s) = @_;
    my @items;
    my ( $cur, $op, @docs ) = ( '', ';' );
    my $i = 0;
    my $n = length $s;
    my $finish = sub {
        my ($sep) = @_;
        ( my $raw = $cur ) =~ s/\A\s+|\s+\z//g;
        push @items, { raw => $raw, op => $op, sep => $sep } if length $raw || $sep eq ';;';
        $cur = '';
        $op = $sep eq '&' || $sep eq "\n" || $sep eq ';;' ? ';' : $sep;
    };
    while ( $i < $n ) {
        my $c = substr( $s, $i, 1 );
        if ( $c eq "'" ) {
            my $j = index( $s, "'", $i + 1 );
            die "bash: unexpected EOF while looking for matching `''\n" if $j < 0;
            $cur .= substr( $s, $i, $j - $i + 1 );
            $i = $j + 1;
            next;
        }
        if ( $c eq '"' || $c eq '`' ) {
            my $j = _close_quote( $s, $i );
            die "bash: unexpected EOF while looking for matching `$c'\n" if $j < 0;
            $cur .= substr( $s, $i, $j - $i + 1 );
            $i = $j + 1;
            next;
        }
        if ( $c eq '\\' ) { $cur .= substr( $s, $i, 2 ) if substr( $s, $i + 1, 1 ) ne "\n"; $i += 2; next }    # \ am Zeilenende: Fortsetzung
        if ( $c eq '$' && substr( $s, $i + 1, 1 ) =~ /[({]/ ) {
            my $j = _close_paren( $s, $i + 1 );
            die "bash: unexpected EOF while looking for matching `" . ( substr( $s, $i + 1, 1 ) eq '(' ? ')' : '}' ) . "'\n" if $j < 0;
            $cur .= substr( $s, $i, $j - $i + 1 );
            $i = $j + 1;
            next;
        }
        if ( $c eq '$' && substr( $s, $i + 1, 1 ) eq "'" ) {    # $'…'
            my $j = $i + 2;
            $j++ while $j < $n && substr( $s, $j, 1 ) ne "'" && ( substr( $s, $j, 1 ) ne '\\' || $j++ );
            die "bash: unexpected EOF while looking for matching `''\n" if $j >= $n;
            $cur .= substr( $s, $i, $j - $i + 1 );
            $i = $j + 1;
            next;
        }
        my $wordstart = $cur eq '' || $cur =~ /\s\z/ || $cur =~ /[;&|(]\z/;
        if ( $c eq '#' && $wordstart ) {    # Kommentar bis zum Zeilenende
            $i++ while $i < $n && substr( $s, $i, 1 ) ne "\n";
            next;
        }
        if ( $wordstart && substr( $s, $i, 2 ) eq '[[' && substr( $s, $i + 2, 1 ) =~ /\s/ ) {
            my $j = index( $s, ']]', $i + 2 );
            die "bash: syntax error: unexpected end of file\n" if $j < 0;
            $cur .= substr( $s, $i, $j - $i + 2 );
            $i = $j + 2;
            next;
        }
        if ( substr( $s, $i, 3 ) eq '<<<' ) {    # Here-String: das naechste Wort
            my $rest = substr( $s, $i + 3 );
            my ($ws) = $rest =~ /\A(\s*)/;
            my $k = $i + 3 + length $ws;
            my $j = $k;
            while ( $j < $n && substr( $s, $j, 1 ) !~ /[\s;&|]/ ) {
                my $x = substr( $s, $j, 1 );
                if    ( $x eq "'" ) { my $e = index( $s, "'", $j + 1 ); $j = $e < 0 ? $n : $e + 1 }
                elsif ( $x eq '"' ) { my $e = _close_quote( $s, $j ); $j = $e < 0 ? $n : $e + 1 }
                elsif ( $x eq '$' && substr( $s, $j + 1, 1 ) =~ /[({]/ ) { my $e = _close_paren( $s, $j + 1 ); $j = $e < 0 ? $n : $e + 1 }
                else { $j++ }
            }
            $cur .= ' ';
            push @docs, { word => substr( $s, $k, $j - $k ), herestring => 1 };
            $i = $j;
            next;
        }
        if ( substr( $s, $i, 2 ) eq '<<' ) {    # Heredoc: Text ab der naechsten Zeile
            my ( $dash, $q1, $q2, $plain ) = substr( $s, $i ) =~ /\A<<(-?)[ \t]*(?:'([^']*)'|"([^"]*)"|\\?([^\s;&|<>]+))/
                or do { $cur .= '<<'; $i += 2; next };
            my ($all) = substr( $s, $i ) =~ /\A(<<-?[ \t]*(?:'[^']*'|"[^"]*"|\\?[^\s;&|<>]+))/;
            my $quoted = defined $q1 || defined $q2 || substr( $s, $i ) =~ /\A<<-?[ \t]*\\/;
            push @docs, { delim => $q1 // $q2 // $plain, dash => $dash, expand => !$quoted };
            $cur .= ' ';
            $i += length $all;
            next;
        }
        if ( $c eq "\n" ) {
            # Heredocs dieser Zeile einsammeln
            $i++;
            my @here;
            for my $d (@docs) {
                if ( $d->{herestring} ) { push @here, $d; next }
                my $body = '';
                while ( $i < $n ) {
                    my $e = index( $s, "\n", $i );
                    my $line = $e < 0 ? substr( $s, $i ) : substr( $s, $i, $e - $i );
                    $i = $e < 0 ? $n : $e + 1;
                    my $cmp = $line;
                    $cmp =~ s/\A\t+// if $d->{dash};
                    last if $cmp eq $d->{delim};
                    $line =~ s/\A\t+// if $d->{dash};
                    $body .= "$line\n";
                }
                push @here, { %$d, body => $body };
            }
            my $before = scalar @items;
            $finish->("\n");
            _attach( \@items, $before, \@here ) if @here;
            @docs = ();
            next;
        }
        if ( $c eq ';' ) {
            my $sep = substr( $s, $i, 2 ) eq ';;' ? ';;' : ';';
            my $before = scalar @items;
            $finish->($sep);
            _attach( \@items, $before, [ map { $_->{herestring} ? $_ : () } @docs ] ) if @docs;
            @docs = ();
            $i += length $sep;
            next;
        }
        if ( $c eq '&' || $c eq '|' ) {
            my $two = substr( $s, $i, 2 );
            if ( $two eq '&&' || $two eq '||' ) {
                my $before = scalar @items;
                $finish->($two);
                _attach( \@items, $before, [ grep { $_->{herestring} } @docs ] ) if @docs;
                @docs = ();
                $i += 2;
                next;
            }
            # & als Hintergrund (nicht >&, &>, 2>&1)
            if ( $c eq '&' && $cur !~ /[<>]\z/ && substr( $s, $i + 1, 1 ) ne '>' ) {
                my $before = scalar @items;
                $finish->('&');
                _attach( \@items, $before, [ grep { $_->{herestring} } @docs ] ) if @docs;
                @docs = ();
                $i++;
                next;
            }
        }
        $cur .= $c;
        $i++;
    }
    my $before = scalar @items;
    $finish->(';');
    if (@docs) {
        # Heredoc ohne Zeilenende danach: leerer Text (bash warnt nur)
        _attach( \@items, $before, [ map { $_->{herestring} ? $_ : { %$_, body => '' } } @docs ] );
    }
    return @items;
}

sub _attach {
    my ( $items, $before, $docs ) = @_;
    return unless @$items > $before && @$docs;
    my $it = $items->[-1];
    my $d  = $docs->[-1];    # mehrere Heredocs an einem Befehl: der letzte ist die Eingabe
    if ( $d->{herestring} ) { $it->{herestring} = $d->{word} }
    else { $it->{heredoc} = $d->{body}; $it->{expand_doc} = $d->{expand} ? 1 : 0 }
    return;
}

# Ende eines "…" bzw. `…` ab Position $i (Backslash, $( ) darin)
sub _close_quote {
    my ( $s, $i ) = @_;
    my $q = substr( $s, $i, 1 );
    my $j = $i + 1;
    while ( $j < length $s ) {
        my $x = substr( $s, $j, 1 );
        return $j if $x eq $q;
        if ( $x eq '\\' ) { $j += 2; next }
        if ( $q eq '"' && $x eq '$' && substr( $s, $j + 1, 1 ) =~ /[({]/ ) {
            my $e = _close_paren( $s, $j + 1 );
            return -1 if $e < 0;
            $j = $e + 1;
            next;
        }
        if ( $q eq '"' && $x eq '`' ) { my $e = _close_quote( $s, $j ); return -1 if $e < 0; $j = $e + 1; next }
        $j++;
    }
    return -1;
}

# Ende der Klammer ( bzw. { ab Position $i (verschachtelt, Anfuehrungszeichen darin)
sub _close_paren {
    my ( $s, $i ) = @_;
    my $open = substr( $s, $i, 1 );
    my $close = $open eq '(' ? ')' : '}';
    my ( $d, $j ) = ( 0, $i );
    while ( $j < length $s ) {
        my $x = substr( $s, $j, 1 );
        if ( $x eq "'" && $open eq '(' ) { my $e = index( $s, "'", $j + 1 ); return -1 if $e < 0; $j = $e + 1; next }
        if ( $x eq '"' ) { my $e = _close_quote( $s, $j ); return -1 if $e < 0; $j = $e + 1; next }
        if ( $x eq '\\' ) { $j += 2; next }
        if    ( $x eq $open )  { $d++ }
        elsif ( $x eq $close ) { return $j unless --$d }
        $j++;
    }
    return -1;
}


sub top_pipe {
    my ($s) = @_;
    my @at;
    my $i = 0;
    while ( $i < length $s ) {
        my $c = substr( $s, $i, 1 );
        if ( $c eq "'" ) { my $j = index( $s, "'", $i + 1 ); last if $j < 0; $i = $j + 1; next }
        if ( $c eq '"' || $c eq '`' ) { my $j = _close_quote( $s, $i ); last if $j < 0; $i = $j + 1; next }
        if ( $c eq '\\' ) { $i += 2; next }
        if ( $c eq '$' && substr( $s, $i + 1, 1 ) =~ /[({]/ ) { my $j = _close_paren( $s, $i + 1 ); last if $j < 0; $i = $j + 1; next }
        push @at, $i if $c eq '|' && substr( $s, $i + 1, 1 ) ne '|' && ( $i == 0 || substr( $s, $i - 1, 1 ) ne '|' );
        $i++;
    }
    return () unless @at;
    return ( substr( $s, 0, $at[-1] ), substr( $s, $at[-1] + 1 ) );
}

# --- Bloecke ---------------------------------------------------------------------


my $KW = qr/(?:if|then|elif|else|fi|for|while|until|do|done|case|esac|function|select|\{|\}|\(|\(\(|break|continue)/;

sub parse {
    my ($items) = @_;
    my @it = map { {%$_} } @$items;
    my ( $nodes, $stop ) = eval { _parse_list( \@it, {} ) };
    if ( my $e = $@ ) { $e =~ s/\s+\z//; return $e }
    return "bash: syntax error near unexpected token `$stop->{word}'" if $stop;
    return $nodes;
}

# naechstes Glied, ein fuehrendes Schluesselwort mit Rest (then echo a) abgespalten
sub _next {
    my ($it) = @_;
    my $x = shift @$it or return;
    if ( $x->{raw} =~ /\A(then|else|do|elif)\s+(\S.*)\z/s && $1 ne 'elif' ) {
        unshift @$it, { %$x, raw => $2, op => ';' };
        return { %$x, raw => $1 };
    }
    return $x;
}

sub _kw {
    my ($x) = @_;
    return $x->{raw} =~ /\A(if|then|elif|else|fi|for|while|until|do|done|case|esac|function|select)(?=\s|\z|;)/ ? $1
         : $x->{raw} =~ /\A(\{|\}|\(\(|\()/ ? $1
         : $x->{raw} =~ /\A[A-Za-z_][\w-]*\s*\(\)/ ? 'function'
         : undef;
}

sub _parse_list {
    my ( $it, $stops ) = @_;
    my @nodes;
    while (@$it) {
        my $x = _next($it);
        my $kw = _kw($x) // '';
        if ( $stops->{$kw} ) { return ( \@nodes, { word => $kw, item => $x } ) }
        if ( $kw eq 'if' ) {
            unshift @$it, { %$x, raw => substr( $x->{raw}, 2 ) =~ s/\A\s+//r, op => ';' } if $x->{raw} =~ /\Aif\s+\S/;
            my @arms;
            my $else;
            while (1) {
                my ( $cond, $s1 ) = _parse_list( $it, { then => 1 } );
                die "bash: syntax error: unexpected end of file\n" unless $s1;
                die "bash: syntax error near unexpected token `then'\n" unless @$cond;
                my ( $body, $s2 ) = _parse_list( $it, { elif => 1, else => 1, fi => 1 } );
                die "bash: syntax error: unexpected end of file\n" unless $s2;
                push @arms, [ $cond, $body ];
                if ( $s2->{word} eq 'elif' ) {
                    ( my $r = $s2->{item}{raw} ) =~ s/\Aelif\s*//;
                    unshift @$it, { %{ $s2->{item} }, raw => $r, op => ';' } if length $r;
                    next;
                }
                if ( $s2->{word} eq 'else' ) {
                    my ( $eb, $s3 ) = _parse_list( $it, { fi => 1 } );
                    die "bash: syntax error: unexpected end of file\n" unless $s3;
                    $else = $eb;
                    $s2 = $s3;
                }
                push @nodes, { type => 'if', op => $x->{op}, arms => \@arms, else => $else, post => _post( $s2->{item}, 'fi' ) };
                last;
            }
            next;
        }
        if ( $kw eq 'for' ) {
            if ( $x->{raw} =~ /\Afor\s*\(\(/ ) { push @nodes, _skip_block( $it, $x ); next }
            my ( $var, $words ) = $x->{raw} =~ /\Afor\s+([A-Za-z_]\w*)(?:\s+in\b\s*(.*))?\z/s
                or die "bash: syntax error near unexpected token `" . ( split ' ', $x->{raw} )[1] . "'\n";
            my $do = _next($it) or die "bash: syntax error: unexpected end of file\n";
            die "bash: syntax error near unexpected token `" . ( split ' ', $do->{raw} )[0] . "'\n" unless ( _kw($do) // '' ) eq 'do';
            my ( $body, $s ) = _parse_list( $it, { done => 1 } );
            die "bash: syntax error: unexpected end of file\n" unless $s;
            die "bash: syntax error near unexpected token `done'\n" unless @$body;
            push @nodes, { type => 'for', op => $x->{op}, var => $var, words => $words // '"$@"', body => $body, post => _post( $s->{item}, 'done' ) };
            next;
        }
        if ( $kw eq 'while' || $kw eq 'until' ) {
            ( my $r = $x->{raw} ) =~ s/\A\Q$kw\E\s*//;
            unshift @$it, { %$x, raw => $r, op => ';' } if length $r;
            my ( $cond, $s1 ) = _parse_list( $it, { do => 1 } );
            die "bash: syntax error: unexpected end of file\n" unless $s1;
            my ( $body, $s2 ) = _parse_list( $it, { done => 1 } );
            die "bash: syntax error: unexpected end of file\n" unless $s2;
            die "bash: syntax error near unexpected token `done'\n" unless @$body;
            push @nodes, { type => 'while', op => $x->{op}, until => $kw eq 'until' ? 1 : 0, cond => $cond, body => $body, post => _post( $s2->{item}, 'done' ) };
            next;
        }
        if ( $x->{raw} =~ /\|\s*(?:while|until)\b/ && ( my ( $left, $right ) = top_pipe( $x->{raw} ) ) ) {
            if ( $right =~ /\A\s*(while|until)\b/ ) {    # befehl | while …; do …; done
                ( my $r = $right ) =~ s/\A\s*(?:while|until)\s*//;
                my $kw2 = $1;
                unshift @$it, { %$x, raw => $r, op => ';' } if length $r;
                my ( $cond, $s1 ) = _parse_list( $it, { do => 1 } );
                die "bash: syntax error: unexpected end of file\n" unless $s1;
                my ( $body, $s2 ) = _parse_list( $it, { done => 1 } );
                die "bash: syntax error: unexpected end of file\n" unless $s2;
                push @nodes, { type => 'while', op => $x->{op}, until => 0, input_cmd => $left, cond => $cond, body => $body, post => _post( $s2->{item}, 'done' ) };
                next;
            }
        }
        if ( $kw eq 'case' ) {
            my ( $word ) = $x->{raw} =~ /\Acase\s+(.+?)\s+in\b/s or die "bash: syntax error near unexpected token `" . ( split ' ', $x->{raw} )[-1] . "'\n";
            ( my $rest = $x->{raw} ) =~ s/\Acase\s+.+?\s+in\b\s*//s;
            my @arms;
            my $cur;
            my @queue = length $rest ? ( { %$x, raw => $rest, op => ';' } ) : ();
            while (1) {
                my $y = @queue ? shift @queue : _next($it);
                die "bash: syntax error: unexpected end of file\n" unless $y;
                if ( $y->{raw} =~ /\Aesac\b\s*(.*)\z/s ) { push @arms, $cur if $cur; push @nodes, { type => 'case', op => $x->{op}, word => $word, arms => \@arms, post => $1 }; last }
                if ( !$cur ) {
                    my ( $pats, $after ) = $y->{raw} =~ /\A\(?\s*((?:[^)\\]|\\.)*?)\s*\)\s*(.*)\z/s
                        or die "bash: syntax error near unexpected token `" . ( split ' ', $y->{raw} )[0] . "'\n";
                    $cur = { pats => [ _split_pats($pats) ], items => [] };
                    push @{ $cur->{items} }, { %$y, raw => $after, op => ';' } if length $after;
                }
                else { push @{ $cur->{items} }, $y if length $y->{raw} }
                if ( ( $y->{sep} // '' ) eq ';;' ) {
                    my ( $body, $s ) = _parse_list( [ @{ $cur->{items} } ], {} );
                    die "bash: syntax error near unexpected token `$s->{word}'\n" if $s;
                    push @arms, { pats => $cur->{pats}, body => $body };
                    $cur = undef;
                }
            }
            # letzter Zweig ohne ;; vor esac
            if ( my $last = $nodes[-1]{arms}[-1] ) {
                if ( ref $last eq 'HASH' && $last->{items} ) {
                    my ( $body, $s ) = _parse_list( [ @{ $last->{items} } ], {} );
                    $nodes[-1]{arms}[-1] = { pats => $last->{pats}, body => $body };
                }
            }
            next;
        }
        if ( $kw eq '{' && $x->{raw} =~ /\A\{(?:\s+(.*))?\z/s ) {    # { liste; } [> datei | filter]
            unshift @$it, { %$x, raw => $1, op => ';' } if defined $1 && length $1;
            my ( $body, $s ) = _parse_list( $it, { '}' => 1 } );
            die "bash: syntax error: unexpected end of file\n" unless $s;
            push @nodes, { type => 'group', op => $x->{op}, body => $body, post => _post( $s->{item}, '}' ) };
            next;
        }
        if ( $kw eq '(' && ( my $sub = _subshell( $it, $x ) ) ) { push @nodes, $sub; next }    # ( liste ) [| filter | > datei]
        # Funktion: name() { … } bzw. function name [()] { … } — der Rumpf ist eine Gruppe
        if ( $kw eq 'function' && ( my ( $fname, $frest ) = $x->{raw} =~ /\A(?:function\s+)?([A-Za-z_][\w-]*)\s*(?:\(\s*\))?\s*(.*)\z/s ) ) {
            if ( !length $frest ) { my $y = _next($it) or die "bash: syntax error: unexpected end of file\n"; $frest = $y->{raw} }
            if ( $frest =~ /\A\{(?:\s+(.*))?\z/s ) {
                unshift @$it, { %$x, raw => $1, op => ';' } if defined $1 && length $1;
                my ( $body, $s ) = _parse_list( $it, { '}' => 1 } );
                die "bash: syntax error: unexpected end of file\n" unless $s;
                push @nodes, { type => 'func', op => $x->{op}, name => $fname, body => $body, raw => $x->{raw} };
                next;
            }
            unshift @$it, { %$x, raw => $frest, op => ';' };
            push @nodes, _skip_block( $it, $x );
            next;
        }
        if ( $kw eq 'function' || $kw eq '{' || $kw eq '(' || $kw eq '((' || $kw eq 'select' ) { push @nodes, _skip_block( $it, $x ); next }
        if ( $kw && $kw =~ /\A(?:then|elif|else|fi|do|done|esac|\})\z/ ) { die "bash: syntax error near unexpected token `$kw'\n" }
        if ( $x->{raw} =~ /\A(break|continue)(?:\s+(\d+))?\s*\z/ ) { push @nodes, { type => $1, op => $x->{op}, n => $2 // 1 }; next }
        push @nodes, { type => 'cmd', op => $x->{op}, raw => $x->{raw}, map { exists $x->{$_} ? ( $_ => $x->{$_} ) : () } qw( heredoc expand_doc herestring ) };
    }
    return ( \@nodes, undef );
}

# Rest hinter done/fi: Umleitung oder Pipe (done < datei, done | sort, done > aus)
sub _post {
    my ( $item, $kw ) = @_;
    ( my $r = $item->{raw} ) =~ s/\A\Q$kw\E\s*//;
    return { raw => $r, map { exists $item->{$_} ? ( $_ => $item->{$_} ) : () } qw( heredoc expand_doc herestring ) };
}

sub _split_pats {
    my ($p) = @_;
    my @p;
    my $cur = '';
    my $q = '';
    for my $c ( split //, $p ) {
        if ( $q ) { $cur .= $c; $q = '' if $c eq $q; next }
        if ( $c eq '"' || $c eq "'" ) { $q = $c; $cur .= $c; next }
        if ( $c eq '|' ) { push @p, $cur; $cur = ''; next }
        $cur .= $c;
    }
    push @p, $cur;
    return map { s/\A\s+|\s+\z//gr } @p;
}

# Subshell ( liste ): Glieder bis zur schliessenden Klammer (nicht in Anführungszeichen,
# $( ), verschachtelten Klammern); dahinter Pipe oder Umleitung wie bei { }. Ohne
# schliessende Klammer: undef (dann eine Luecke wie bisher).
sub _subshell {
    my ( $it, $x ) = @_;
    my @items = ( { %$x, raw => substr( $x->{raw}, 1 ) =~ s/\A\s+//r, op => ';' } );
    my $taken = 0;
    while (1) {
        my $y  = $items[-1];
        my $at = _close_sub( $y->{raw} );
        if ( defined $at ) {
            my $post = substr( $y->{raw}, $at + 1 ) =~ s/\A\s+//r;
            $y->{raw} = substr( $y->{raw}, 0, $at ) =~ s/\s+\z//r;
            splice @$it, 0, $taken;
            my ( $body, $s ) = _parse_list( [ grep { length $_->{raw} } @items ], {} );
            die "bash: syntax error near unexpected token `$s->{word}'\n" if $s;
            return { type => 'group', subshell => 1, op => $x->{op}, body => $body, post => { raw => $post } };
        }
        return undef if $taken >= @$it;
        push @items, { %{ $it->[ $taken++ ] } };
    }
}

# Stelle der schliessenden Klammer einer Subshell in einem Glied (oder undef)
sub _close_sub {
    my ($r) = @_;
    my ( $depth, $i, $n ) = ( 0, 0, length $r );
    while ( $i < $n ) {
        my $c = substr( $r, $i, 1 );
        if ( $c eq '\\' ) { $i += 2; next }
        if ( $c eq "'" ) { my $j = index( $r, "'", $i + 1 ); return undef if $j < 0; $i = $j + 1; next }
        if ( $c eq '"' || $c eq '`' ) { my $j = _close_quote( $r, $i ); return undef if $j < 0; $i = $j + 1; next }
        if ( $c eq '(' ) { $depth++ }
        elsif ( $c eq ')' ) { return $i unless $depth; $depth-- }
        $i++;
    }
    return undef;
}

# nicht nachgebildeter Block (Funktion, { }, ( ), for (( ))): bis zum Ende ueberspringen, Luecke
sub _skip_block {
    my ( $it, $x ) = @_;
    my @raw = ( $x->{raw} );
    my $open = () = $x->{raw} =~ /(?:^|[\s;])(?:\{|do|then)(?=\s|$)/g;
    my $close = () = $x->{raw} =~ /(?:^|[\s;])(?:\}|done|fi)(?=\s|$)/g;
    my $depth = $open - $close;
    $depth = 0 if $x->{raw} =~ /\A\(/ && $x->{raw} =~ /\)\s*\z/;
    while ( $depth > 0 && @$it ) {
        my $y = shift @$it;
        push @raw, $y->{raw};
        $depth++ while $y->{raw} =~ /(?:^|[\s;])(?:\{|do|then)(?=\s|$)/g;
        $depth-- while $y->{raw} =~ /(?:^|[\s;])(?:\}|done|fi)(?=\s|$)/g;
    }
    return { type => 'gap', op => $x->{op}, raw => join( '; ', @raw ) };
}

# --- Expansion ---------------------------------------------------------------------


sub expand {
    my ( $s, $env, $cmdsub ) = @_;
    my $out = '';
    my $q   = '';
    my $i   = 0;
    my $n   = length $s;
    my $word = '';    # bisheriges Wort (ohne Quotes) — fuer NAME=wert ohne Wortaufteilung
    my $emit = sub {
        my ($v) = @_;
        $v //= '';
        if ( $q eq '"' ) { $out .= $v =~ s/(["\\\$`])/\\$1/gr; return }
        if ( $word =~ /\A[A-Za-z_]\w*\+?=/ ) { $out .= "'" . ( $v =~ s/'/'\\''/gr ) . "'"; return }    # Zuweisung: ein Wort
        my @w = split ' ', $v;
        $out .= join ' ', map { "'" . s/'/'\\''/gr . "'" } @w;
    };
    while ( $i < $n ) {
        my $c = substr( $s, $i, 1 );
        if ( $q eq '' && $c eq "'" ) {
            my $j = index( $s, "'", $i + 1 );
            $j = $n - 1 if $j < 0;
            $out .= substr( $s, $i, $j - $i + 1 );
            $word .= 'x';
            $i = $j + 1;
            next;
        }
        if ( $c eq '"' ) { $q = $q eq '"' ? '' : '"'; $out .= $c; $i++; next }
        if ( $c eq '\\' ) { $out .= substr( $s, $i, 2 ); $word .= substr( $s, $i + 1, 1 ); $i += 2; next }
        if ( $q eq '' && $c =~ /\s/ ) { $out .= $c; $word = ''; $i++; next }
        if ( $c eq '`' ) {
            my $j = _close_quote( $s, $i );
            $j = $n - 1 if $j < 0;
            my $inner = substr( $s, $i + 1, $j - $i - 1 );
            $emit->( _strip_nl( $cmdsub->($inner) ) );
            $i = $j + 1;
            next;
        }
        if ( $c eq '$' ) {
            my $nx = substr( $s, $i + 1, 1 );
            if ( $q eq '' && $nx eq "'" ) {    # $'…' mit Escapes
                my $j = $i + 2;
                my $v = '';
                while ( $j < $n && substr( $s, $j, 1 ) ne "'" ) {
                    my $x = substr( $s, $j, 1 );
                    if ( $x eq '\\' ) {
                        my $e = substr( $s, $j + 1, 1 );
                        $v .= { n => "\n", t => "\t", r => "\r", '\\' => '\\', "'" => "'", '"' => '"', a => "\a", e => "\e", 0 => "\0" }->{$e} // "\\$e";
                        $j += 2;
                        next;
                    }
                    $v .= $x;
                    $j++;
                }
                $out .= "'" . ( $v =~ s/'/'\\''/gr ) . "'";
                $word .= 'x';
                $i = $j + 1;
                next;
            }
            if ( substr( $s, $i, 3 ) eq '$((' ) {
                my $j = _close_paren( $s, $i + 1 );
                if ( $j > 0 && substr( $s, $j - 1, 1 ) eq ')' ) {
                    my $expr = substr( $s, $i + 3, $j - $i - 4 );
                    $emit->( arith( $expr, $env, $cmdsub ) );
                    $i = $j + 1;
                    next;
                }
            }
            if ( $nx eq '(' ) {
                my $j = _close_paren( $s, $i + 1 );
                $j = $n - 1 if $j < 0;
                $emit->( _strip_nl( $cmdsub->( substr( $s, $i + 2, $j - $i - 2 ) ) ) );
                $i = $j + 1;
                next;
            }
            if ( $nx eq '{' ) {
                my $j = _close_paren( $s, $i + 1 );
                $j = $n - 1 if $j < 0;
                $emit->( _param( substr( $s, $i + 2, $j - $i - 2 ), $env, $cmdsub ) );
                $i = $j + 1;
                next;
            }
            if ( substr( $s, $i + 1 ) =~ /\A([A-Za-z_]\w*|[0-9?\$#@*!-])/ ) {
                my $name = $1;
                if ( $name eq '@' && $q eq '"' ) {    # "$@": jedes Argument ein Wort
                    $out .= join '" "', map { s/(["\\\$`])/\\$1/gr } @{ $env->{args} || [] };
                }
                else { $emit->( $name eq '@' || $name eq '*' ? join( ' ', @{ $env->{args} || [] } ) : _var( $name, $env ) ) }
                $i += 1 + length $name;
                next;
            }
        }
        $out .= $c;
        $word .= $c;
        $i++;
    }
    return $out;
}

sub _strip_nl { my ($v) = @_; $v //= ''; $v =~ s/\n+\z//; return $v }

sub _var {
    my ( $name, $env ) = @_;
    return $env->{rc} // 0 if $name eq '?';
    return 4242 if $name eq '$';
    return scalar @{ $env->{args} || [] } if $name eq '#';
    return $env->{args}[ $name - 1 ] // '' if $name =~ /\A[1-9]\z/;
    return $env->{arg0} // 'bash' if $name eq '0';
    return '' if $name eq '!' || $name eq '-';
    return ( $env->{pipestatus} || [ $env->{rc} // 0 ] )->[0] if $name eq 'PIPESTATUS';
    return $env->{vars}{$name} if exists $env->{vars}{$name};
    return $env->{defaults}{$name} if $env->{defaults} && exists $env->{defaults}{$name};
    return '';
}

sub _isset {
    my ( $name, $env ) = @_;
    return 1 if $name =~ /\A[?\$#0]\z/;
    return defined $env->{args}[ $name - 1 ] if $name =~ /\A[1-9]\z/;
    return exists $env->{vars}{$name} || $env->{defaults} && exists $env->{defaults}{$name};
}

# ${…}
sub _param {
    my ( $p, $env, $cmdsub ) = @_;
    my $word = sub { my ($w) = @_; my $x = expand( $w, $env, $cmdsub ); my @w = eval { shell_words($x) }; join ' ', grep { !ref } @w };
    if ( $p =~ /\A(#?)PIPESTATUS(?:\[(\d+|[@*])\])?\z/ ) {    # Status der Stufen der letzten Pipeline
        my ( $len, $ix ) = ( $1, $2 );
        my $ps = $env->{pipestatus} || [ $env->{rc} // 0 ];
        my $all = defined $ix && ( $ix eq '@' || $ix eq '*' );
        return $all ? scalar @$ps : length( $ps->[ $ix // 0 ] // '' ) if $len;
        return $all ? join( ' ', @$ps ) : $ps->[ $ix // 0 ] // '';
    }
    return length _var( $1, $env ) if $p =~ /\A#([A-Za-z_]\w*|[0-9?#])\z/;
    my ( $name, $rest ) = $p =~ /\A([A-Za-z_]\w*|[0-9?\$#@*])(.*)\z/s or die "gap: \${$p}\n";
    my $v = $name eq '@' || $name eq '*' ? join( ' ', @{ $env->{args} || [] } ) : _var( $name, $env );
    return $v if $rest eq '';
    if ( $rest =~ /\A(:?)([-=+?])(.*)\z/s ) {
        my ( $colon, $o, $w ) = ( $1, $2, $3 );
        my $unset = $colon ? !length $v : !_isset( $name, $env );
        if ( $o eq '-' ) { return $unset ? $word->($w) : $v }
        if ( $o eq '=' ) { return $v unless $unset; my $x = $word->($w); $env->{vars}{$name} = $x; return $x }
        if ( $o eq '+' ) { return $unset ? '' : $word->($w) }
        die "bash: $name: " . ( length $w ? $word->($w) : 'parameter null or not set' ) . "\n" if $unset;
        return $v;
    }
    if ( $rest =~ /\A(##?|%%?)(.*)\z/s ) {
        my ( $o, $pat ) = ( $1, $word->($2) );
        my $re = glob_re($pat);
        my @cut;
        if ( $o =~ /#/ ) { @cut = grep { substr( $v, 0, $_ ) =~ /\A$re\z/s } 0 .. length $v }
        else { @cut = grep { substr( $v, $_ ) =~ /\A$re\z/s } 0 .. length $v }
        return $v unless @cut;
        return substr( $v, $cut[0] ) if $o eq '#';
        return substr( $v, $cut[-1] ) if $o eq '##';
        return substr( $v, 0, $cut[-1] ) if $o eq '%';
        return substr( $v, 0, $cut[0] );
    }
    if ( $rest =~ /\A:(?![-=+?])(.*)\z/s ) {    # ${v:o} ${v:o:l}, o/l auch $(( )), $n, Ausdruck
        my @ol = _split_colon($1);
        die "gap: \${$p}\n" if @ol > 2;
        my ( $o, $l ) = map { defined $_ ? arith( $_, $env, $cmdsub ) : undef } @ol;
        $o = length($v) + $o if $o < 0;
        $o = 0 if $o < 0;
        return '' if $o > length $v;
        return substr( $v, $o ) unless defined $l;
        return $l < 0 ? substr( $v, $o, length($v) - $o + $l ) : substr( $v, $o, $l );
    }
    if ( $rest =~ m{\A(//?|/#|/%)((?:[^/\\]|\\.)*)(?:/(.*))?\z}s ) {
        my ( $o, $pat, $r ) = ( $1, $word->($2), defined $3 ? $word->($3) : '' );
        my $re = glob_re( $pat, 1 );
        return $v =~ s/$re/$r/gr if $o eq '//';
        return $v =~ s/\A$re/$r/r if $o eq '/#';
        return $v =~ s/$re\z/$r/r if $o eq '/%';
        return $v =~ s/$re/$r/r;
    }
    return uc $v if $rest eq '^^';
    return lc $v if $rest eq ',,';
    return ucfirst $v if $rest eq '^';
    return lcfirst $v if $rest eq ',';
    die "gap: \${$p}\n";
}

# "o:l" an Doppelpunkten oberster Ebene teilen (nicht in $(( )) bzw. ( ))
sub _split_colon {
    my ($s) = @_;
    my ( @p, $cur, $d ) = ();
    ( $cur, $d ) = ( '', 0 );
    for my $c ( split //, $s ) {
        $d++ if $c eq '(';
        $d-- if $c eq ')';
        if ( $c eq ':' && !$d ) { push @p, $cur; $cur = ''; next }
        $cur .= $c;
    }
    push @p, $cur;
    return @p;
}


sub glob_re {
    my ( $g, $greedy ) = @_;
    my $re = '';
    my $i = 0;
    while ( $i < length $g ) {
        my $c = substr( $g, $i, 1 );
        if    ( $c eq '*' ) { $re .= $greedy ? '.*' : '.*?' }
        elsif ( $c eq '?' ) { $re .= '.' }
        elsif ( $c eq '\\' ) { $re .= quotemeta substr( $g, $i + 1, 1 ); $i++ }
        elsif ( $c eq '[' && ( my $j = index( $g, ']', $i + 2 ) ) > 0 ) {
            my $set = substr( $g, $i + 1, $j - $i - 1 );
            $set =~ s/\A!/^/;
            $set =~ s/\\/\\\\/g;
            $re .= "[$set]";
            $i = $j;
        }
        else { $re .= quotemeta $c }
        $i++;
    }
    return qr/$re/s;
}


sub arith {
    my ( $e, $env, $cmdsub ) = @_;
    $e = expand( $e, $env, $cmdsub ) if $e =~ /\$/;
    $e =~ s/'//g;
    my @t = $e =~ /\G\s*(\d+|[A-Za-z_]\w*|\*\*|<=|>=|==|!=|&&|\|\||<<|>>|\+\+|--|\+=|-=|\*=|\/=|[-+*\/%()<>!=?:&|^~,])/gc;
    die "gap: \$(( $e ))\n" if ( pos($e) // 0 ) < length( $e =~ s/\s+\z//r ) || grep { /\A(?:\+\+|--|[+\-*\/]?=|\?|:|,)\z/ && $_ ne '==' } @t;
    my $k = 0;
    my ( $or, $un );
    my $val = sub { my $x = $_[0]; $x =~ /\A\d+\z/ ? 0 + $x : do { my $v = _var( $x, $env ); $v =~ /\A\s*-?\d+\s*\z/ ? 0 + $v : $v eq '' ? 0 : die "gap: \$(( $e ))\n" } };
    my $bin;
    my %prec = ( '||' => 1, '&&' => 2, '|' => 3, '^' => 4, '&' => 5, '==' => 6, '!=' => 6, '<' => 7, '>' => 7, '<=' => 7, '>=' => 7,
        '<<' => 8, '>>' => 8, '+' => 9, '-' => 9, '*' => 10, '/' => 10, '%' => 10, '**' => 11 );
    $un = sub {
        my $x = $t[ $k++ ] // die "bash: syntax error in expression\n";
        return -$un->() if $x eq '-';
        return +$un->() if $x eq '+';
        return ( $un->() ? 0 : 1 ) if $x eq '!';
        return ~$un->() if $x eq '~';
        if ( $x eq '(' ) { my $v = $bin->(0); ( $t[ $k++ ] // '' ) eq ')' or die "bash: syntax error in expression\n"; return $v }
        return $val->($x);
    };
    $bin = sub {
        my ($min) = @_;
        my $l = $un->();
        while ( $k < @t && exists $prec{ $t[$k] } && $prec{ $t[$k] } > $min ) {
            my $o = $t[ $k++ ];
            my $r = $bin->( $o eq '**' ? $prec{$o} - 1 : $prec{$o} );
            die "bash: division by 0 (error token is \"$r\")\n" if ( $o eq '/' || $o eq '%' ) && $r == 0;
            use integer;
            $l = $o eq '+' ? $l + $r : $o eq '-' ? $l - $r : $o eq '*' ? $l * $r : $o eq '/' ? $l / $r : $o eq '%' ? $l % $r
               : $o eq '**' ? do { no integer; int( $l**$r ) } : $o eq '<' ? ( $l < $r ? 1 : 0 ) : $o eq '>' ? ( $l > $r ? 1 : 0 )
               : $o eq '<=' ? ( $l <= $r ? 1 : 0 ) : $o eq '>=' ? ( $l >= $r ? 1 : 0 ) : $o eq '==' ? ( $l == $r ? 1 : 0 )
               : $o eq '!=' ? ( $l != $r ? 1 : 0 ) : $o eq '&&' ? ( $l && $r ? 1 : 0 ) : $o eq '||' ? ( $l || $r ? 1 : 0 )
               : $o eq '&' ? $l & $r : $o eq '|' ? $l | $r : $o eq '^' ? $l ^ $r : $o eq '<<' ? $l << $r : $l >> $r;
        }
        return $l;
    };
    return 0 unless @t;
    my $v = $bin->(0);
    die "bash: syntax error in expression (error token is \"$t[$k]\")\n" if $k < @t;
    return $v;
}

# --- test / [ ] / [[ ]] ----------------------------------------------------------


sub test_expr {
    my ( $args, $fi, $dbl ) = @_;
    my @a = @$args;
    my $k = 0;
    my $name = $dbl ? '[[' : '[';
    my %un = map { $_ => 1 } qw( -e -f -d -s -r -w -x -L -h -z -n -b -c -p -S -g -u -k -O -G -N -t );
    my %bin = map { $_ => 1 } qw( = == != < > -eq -ne -lt -le -gt -ge -nt -ot -ef =~ );
    my $int = sub { my ($x) = @_; $x =~ /\A\s*-?\d+\s*\z/ or die "bash: $name: $x: integer expression expected\n"; 0 + $x };
    my ( $or, $and, $not, $prim );
    $prim = sub {
        my $x = $a[$k] // die "bash: $name: argument expected\n";
        if ( $x eq '(' ) {
            $k++;
            my $v = $or->();
            ( $a[ $k++ ] // '' ) eq ')' or die "bash: $name: `)' expected\n";
            return $v;
        }
        if ( $un{$x} && $k + 1 < @a && !( $k + 2 < @a && $bin{ $a[ $k + 1 ] } ) ) {
            my $v = $a[ $k + 1 ];
            $k += 2;
            return length $v ? 0 : 1 if $x eq '-z';
            return length $v ? 1 : 0 if $x eq '-n';
            return 0 if $x eq '-t';
            my $f = $fi->($v);
            return 0 unless $f;
            return 1 if $x eq '-e';
            return $f->{kind} eq 'f' || $f->{kind} eq 'l' && ( $f->{target_kind} // 'f' ) eq 'f' ? 1 : 0 if $x eq '-f';
            return $f->{kind} eq 'd' || $f->{kind} eq 'l' && ( $f->{target_kind} // '' ) eq 'd' ? 1 : 0 if $x eq '-d';
            return $f->{kind} eq 'l' ? 1 : 0 if $x eq '-L' || $x eq '-h';
            return ( $f->{size} // 0 ) > 0 ? 1 : 0 if $x eq '-s';
            return 1 if $x eq '-r' || $x eq '-w';
            return ( $f->{mode} // 0 ) & 0111 || $f->{kind} eq 'd' ? 1 : 0 if $x eq '-x';
            return ( $f->{mode} // 0 ) & 04000 ? 1 : 0 if $x eq '-u';
            return ( $f->{mode} // 0 ) & 02000 ? 1 : 0 if $x eq '-g';
            return ( $f->{mode} // 0 ) & 01000 ? 1 : 0 if $x eq '-k';
            return 0;
        }
        if ( $k + 2 < @a + 0 && $bin{ $a[ $k + 1 ] } ) {
            my ( $l, $o, $r ) = @a[ $k .. $k + 2 ];
            $k += 3;
            return ( $dbl ? $l =~ /\A${\ glob_re($r, 1)}\z/s : $l eq $r ) ? 1 : 0 if $o eq '=' || $o eq '==';
            return ( $dbl ? $l =~ /\A${\ glob_re($r, 1)}\z/s : $l eq $r ) ? 0 : 1 if $o eq '!=';
            return ( $l lt $r ) ? 1 : 0 if $o eq '<';
            return ( $l gt $r ) ? 1 : 0 if $o eq '>';
            if ( $o eq '=~' ) { my $re = eval { qr/$r/ } // die "bash: $name: invalid regular expression\n"; return $l =~ $re ? 1 : 0 }
            if ( $o eq '-nt' || $o eq '-ot' ) {
                my ( $fl, $fr ) = ( $fi->($l), $fi->($r) );
                return 0 unless $fl && $fr;
                return $o eq '-nt' ? ( $fl->{mtime} > $fr->{mtime} ? 1 : 0 ) : ( $fl->{mtime} < $fr->{mtime} ? 1 : 0 );
            }
            die "gap: test $o\n" if $o eq '-ef';
            my ( $x, $y ) = ( $int->($l), $int->($r) );
            return { -eq => $x == $y, -ne => $x != $y, -lt => $x < $y, -le => $x <= $y, -gt => $x > $y, -ge => $x >= $y }->{$o} ? 1 : 0;
        }
        $k++;
        die "bash: $name: $x: unary operator expected\n" if $un{$x} && $k < @a;
        return length $x ? 1 : 0;
    };
    $not = sub {
        if ( ( $a[$k] // '' ) eq '!' && $k + 1 < @a ) { $k++; return $not->() ? 0 : 1 }
        return $prim->();
    };
    $and = sub {
        my $v = $not->();
        while ( $k < @a && ( $a[$k] eq '-a' && !$dbl || $a[$k] eq '&&' && $dbl ) ) { $k++; my $w = $not->(); $v = $v && $w ? 1 : 0 }
        return $v;
    };
    $or = sub {
        my $v = $and->();
        while ( $k < @a && ( $a[$k] eq '-o' && !$dbl || $a[$k] eq '||' && $dbl ) ) { $k++; my $w = $and->(); $v = $v || $w ? 1 : 0 }
        return $v;
    };
    return ( 1, undef ) unless @a;
    my $v = eval {
        my $r = $or->();
        die "bash: $name: too many arguments\n" if $k < @a;
        $r;
    };
    if ( my $e = $@ ) { die $e if $e =~ /\Agap:/; $e =~ s/\s+\z//; return ( 2, $e ) }
    return ( $v ? 0 : 1, undef );
}

# --- Woerter und Kette -----------------------------------------------------------


sub shell_words {
    my ( $s, $globs ) = @_;    # $globs: je Wort 1, wenn es ungequotete * ? [ traegt (Muster fuer den Glob)
    my @w;
    my ( $cur, $have, $glob ) = ( '', 0, 0 );
    my $push = sub { if ($have) { $globs->[ scalar @w ] = $glob if $globs; push @w, $cur } ( $cur, $have, $glob ) = ( '', 0, 0 ) };
    pos($s) = 0;
    while ( pos($s) < length $s ) {
        if    ( $s =~ /\G[ \t]+/gc )            { $push->() }
        # Umleitungen von Dateideskriptoren: die Simulation kennt nur einen Ausgabestrom.
        # 2>&1, >&2, 2>datei und 2>/dev/null lassen ihn unveraendert; &> und 1> leiten ihn um.
        elsif ( !$have && $s =~ /\G[12]?>&[12]|\G<&\d/gc ) { }
        elsif ( !$have && $s =~ /\G2>>?[ \t]*(?:'[^']*'|"[^"]*"|[^\s|;&>]+)/gc ) { }
        elsif ( !$have && $s =~ /\G(?:&|1)(>>?)/gc ) { push @w, { op => $1 } }
        elsif ( $s =~ /\G(\|\||&&|>>|[|;>\n])/gc ) { $push->(); push @w, { op => $1 eq "\n" ? ';' : $1 } }
        elsif ( $s =~ /\G'([^']*)'/gc )         { $cur .= $1; $have = 1 }
        elsif ( $s =~ /\G"((?:[^"\\]|\\.)*)"/gc ) { ( my $x = $1 ) =~ s/\\(["\\\$`])/$1/g; $cur .= $x; $have = 1 }
        elsif ( $s =~ /\G\\(.)/gcs )            { $cur .= $1; $have = 1 }
        elsif ( $s =~ /\G(['"])/gc )            { die "bash: unexpected EOF while looking for matching `$1'\n" }
        elsif ( $s =~ /\G(<\()/gc )             { $cur .= $1; $have = 1 }
        elsif ( !$have && $s =~ /\G0?<(?![(<])/gc ) { push @w, { op => '<' } }    # Eingabe aus einer Datei (nur ohne Quotes)
        elsif ( $s =~ /\G([^\s'"\\|;&>]+|&)/gc ) { $cur .= $1; $have = 1; $glob = 1 if $1 =~ /[*?\[]/ }
        else                                    { last }
    }
    $push->();
    return @w;
}


sub split_chain {
    my ($s) = @_;
    my @out;
    my ( $cur, $op, $q ) = ( '', ';', '' );
    my @c = split //, $s;
    for ( my $i = 0; $i < @c; $i++ ) {
        my $ch = $c[$i];
        if ($q) { $cur .= $ch; $q = '' if $ch eq $q && ( $q eq "'" || $c[ $i - 1 ] ne '\\' ); next }
        if ( $ch eq "'" || $ch eq '"' ) { $q = $ch; $cur .= $ch; next }
        my $two = $ch . ( $c[ $i + 1 ] // '' );
        if ( $two eq '&&' || $two eq '||' || $ch eq ';' || $ch eq "\n" ) {
            push @out, [ $op, $cur ] if $cur =~ /\S/;
            ( $op, $cur ) = ( $two eq '&&' || $two eq '||' ? $two : ';', '' );
            $i++ if length($two) == 2 && ( $two eq '&&' || $two eq '||' );
            next;
        }
        $cur .= $ch;
    }
    push @out, [ $op, $cur ] if $cur =~ /\S/;
    $_->[1] =~ s/\A\s+|\s+\z//g for @out;
    return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Shell - The bash grammar of the simulators — words, items, heredocs, blocks, expansion, test

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Shell ();
  my @items = Langertha::Holmgang::Shell::split_items($text);
  my $nodes = Langertha::Holmgang::Shell::parse(\@items);   # or the bash message as text
  my $raw   = Langertha::Holmgang::Shell::expand( $raw, $env, $cmdsub );
  my ( $ok, $err ) = Langertha::Holmgang::Shell::test_expr( \@args, $fileinfo );

=head1 DESCRIPTION

The parts of a bash that the Linux simulator needs not per command but for a
whole command line or script. Execution happens in the simulator
(L<Langertha::Holmgang::Sim::Linux>); this module only splits and computes.
Also L</shell_words> (the words of a command line) and L</split_chain> (items at
C<&&>, C<||>, C<;> for the observations of the world).

=over

=item * L</split_items>: items at C<;>, C<;;>, C<&&>, C<||>, C<&> and
line ends (not inside quotes, C<$( )>, C<${ }>, C<[[ ]]>),
comments, line continuation, heredocs (C<<< <<EOF >>>, C<<< <<-EOF >>>,
C<<< <<'EOF' >>>) and here-strings (C<<<< <<< word >>>>).

=item * L</parse>: C<if/elif/else/fi>, C<for … in>, C<while>/C<until> (also
C<… | while read>), C<case … esac>, C<break>/C<continue> as nodes.
C<{ … }> groups and subshells C<( … )> (own variables and own
directory), also with a pipe or redirection after them. Functions (C<name() { … }>,
C<function name { … }>) as node C<func>; C<for (( ))> is not modelled:
the node C<gap>.

=item * L</expand>: variables (C<$v>, C<${v}>, C<${#v}>, C<${v:-w}>,
C<${v#p}>/C<${v##p}>/C<${v%p}>/C<${v%%p}>, C<${v:o:l}>, C<${v/p/r}>,
C<${v^^}>/C<${v,,}>), C<$?>, C<$$>, C<$#>, C<$1…>, arithmetic C<$(( ))>,
command substitution C<$( )> and C<` `> (through a callback), C<$'…'>.
The result is again a command line: substituted values are quoted so that
C<shell_words> reads them as words the way bash does (unquoted with word
splitting, otherwise as one word).

=item * L</test_expr>: C<test>/C<[ ]>/C<[[ ]]> with file, string and
number comparisons, C<!>, C<-a>/C<-o>, C<&&>/C<||>, parentheses, patterns with C<==>
in C<[[ ]]>, C<=~>.

=back

=head2 split_items

  my @items = split_items($text);
  # ( { raw => 'cd /x', op => ';' }, { raw => 'cat > f', op => '&&', heredoc => "…\n", expand_doc => 1 }, … )

C<op> is the separator I<before> the item (C<;> at the start), C<sep> the one
after it (C<;;> separates the branches of C<case>). An unclosed quote dies with
the bash message.

=head2 top_pipe

  my ( $left, $right ) = top_pipe($raw);   # last pipe at the top level, else ()

=head2 parse

  my $nodes = parse(\@items);   # [ { type => 'cmd'|'if'|'for'|'while'|'case'|'gap', op => …, … } ]

On a syntax error returns the bash message (text instead of a list).

=head2 expand

  my $raw = expand( $raw, $env, $cmdsub );

C<$env>: C<< { vars => {…}, rc => 0, args => [ … ], defaults => {…} } >>;
C<$cmdsub>: C<< sub { my ($text) = @_; return $output } >>. Dies with
C<"gap: …\n"> for what is not modelled (e.g. C<${!v}>, C<i++>).

=head2 glob_re

  my $re = glob_re('www-*.tar.gz');   # regex without anchors; $greedy for ${v//p/r}

=head2 arith

  my $n = arith( 'i + 1', $env, $cmdsub );   # integers like bash

=head2 test_expr

  my ( $status, $err ) = test_expr( \@args, $fileinfo, $dbl );   # 0 true, 1 false, 2 error

C<$fileinfo>: C<< sub { my ($path) = @_; return undef | { kind => 'f'|'d'|'l', size => n, mode => 0644, mtime => epoch } } >>.
C<$dbl> (C<[[ ]]>): pattern right of C<==>/C<!=>, C<=~>, C<&&>/C<||>, C<< < >>/C<< > >> without a backslash.

=head2 shell_words

  my @w = shell_words(q{nft add rule ip nat postrouting oifname "eth0" masquerade});

Splits a command line into words like a POSIX shell (single and
double quotes, backslash). Operators (C<|>, C<< > >>, C<<< >> >>>,
C<&&>, C<||>, C<;>) become words of their own, as a hash C<< { op => '|' } >>. An
unclosed quote is an error (C<die> with the shell message).

=head2 split_chain

  my @chain = split_chain('systemctl restart a && journalctl -u a | tail -n 3');
  # ( [ ';', 'systemctl restart a' ], [ '&&', 'journalctl -u a | tail -n 3' ] )

Splits a command line roughly at C<&&>, C<||>, C<;> and line ends outside
quotes: per item the separator before it and the text. For the
observations of the world, which check item by item; the simulator itself uses
L</split_items>.

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
