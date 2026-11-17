#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Shell ();
use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );
use Langertha::Holmgang::Shell ();

# Shell-Grammatik des Linux-Simulators (Befund des Leitstands:
# Schleifen in Skripten als legitimer Weg). Behauptet wird: Glieder, Heredocs,
# Kommentare und Fortsetzungszeilen werden wie von bash getrennt; Variablen,
# ${…}-Formen, $(( )) und $( ) werden zur Laufzeit eines Glieds eingesetzt (in
# Schleifen also je Durchlauf); if/for/while/case/break/continue/exit/set -e
# laufen wie in bash; test/[ ]/[[ ]] pruefen Dateien, Texte und Zahlen; was nicht
# nachgebildet ist (Funktionen, Subshells, while ohne Ende), ist eine Luecke der
# Simulation statt einer falschen Ausgabe.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $S = 'Langertha::Holmgang::Shell';

subtest 'Glieder' => sub {
    my @i = Langertha::Holmgang::Shell::split_items("a; b && c || d # Kommentar\ne 'x;y' \"\$(f; g)\" &\nh \\\n  weiter");
    is_deeply( [ map { [ $_->{raw}, $_->{op} ] } @i ],
        [ [ 'a', ';' ], [ 'b', ';' ], [ 'c', '&&' ], [ 'd', '||' ], [ q{e 'x;y' "$(f; g)"}, ';' ], [ 'h   weiter', ';' ] ],
        '; && || Zeilenende &, Quotes und $( ) bleiben ganz, Kommentar und Fortsetzung' );
    @i = Langertha::Holmgang::Shell::split_items("cat > f <<EOF\neins \$x\n  zwei\nEOF\necho ok");
    is( $i[0]{raw}, 'cat > f', 'Heredoc: Befehl' );
    is( $i[0]{heredoc}, "eins \$x\n  zwei\n", '... Text bis zur Endmarke' );
    ok( $i[0]{expand_doc}, '... ohne Quotes mit Expansion' );
    is( $i[1]{raw}, 'echo ok', '... danach weiter' );
    @i = Langertha::Holmgang::Shell::split_items("cat <<-'E'\n\ta\n\tE");
    is( $i[0]{heredoc}, "a\n", '<<- und Quote: Tabs weg, keine Expansion' );
    ok( !$i[0]{expand_doc}, '... (expand_doc aus)' );
    is( ( Langertha::Holmgang::Shell::split_items(q{grep x <<< "$v"}) )[0]{herestring}, '"$v"', 'Here-String' );
    is( ( Langertha::Holmgang::Shell::split_items(q{[[ $a && $b ]] && echo j}) )[0]{raw}, '[[ $a && $b ]]', '[[ ]] bleibt ganz' );
    throws_ok { Langertha::Holmgang::Shell::split_items(q{echo 'offen}) } qr/unexpected EOF/, 'offenes Quote';
};

subtest 'Bloecke' => sub {
    my $p = sub { Langertha::Holmgang::Shell::parse( [ Langertha::Holmgang::Shell::split_items( $_[0] ) ] ) };
    my $n = $p->("for f in a b; do echo \$f; done | sort");
    is( $n->[0]{type}, 'for', 'for' );
    is( $n->[0]{post}{raw}, '| sort', '... done | filter' );
    $n = $p->("if [ -f x ]; then echo a; elif true; then echo b; else echo c; fi");
    is( scalar @{ $n->[0]{arms} }, 2, 'if/elif' );
    ok( $n->[0]{else}, '... else' );
    $n = $p->("ls | while read -r l; do echo \$l; done");
    is( $n->[0]{input_cmd}, 'ls ', '... | while: Eingabe aus der Pipe' );
    $n = $p->("case \$x in a|b) echo ab;; *) echo sonst;; esac");
    is_deeply( $n->[0]{arms}[0]{pats}, [ 'a', 'b' ], 'case: Muster' );
    is( $p->('for x in a; echo $x'), "bash: syntax error near unexpected token `echo'", 'for ohne do' );
    like( $p->('if true; then echo'), qr/unexpected end of file/, 'if ohne fi' );
    is( $p->('f() { echo; }')->[0]{type}, 'func', 'Funktion: Knoten func' );
};

subtest 'Expansion' => sub {
    my $env = { vars => { f => 'www-2026-09-02.tar.gz', n => '7', leer => '', p => 'a b' }, rc => 3, args => [ 'x', 'y' ] };
    my $e = sub { Langertha::Holmgang::Shell::expand( $_[0], $env, sub { "[$_[0]]\n" } ) };
    my $w = sub { join '|', grep { !ref } Langertha::Holmgang::Shell::shell_words( $e->( $_[0] ) ) };
    is( $w->('${f#www-}'), '2026-09-02.tar.gz', '${v#p}' );
    is( $w->('${f%.tar.gz}'), 'www-2026-09-02', '${v%p}' );
    is( $w->('${f##*-}'), '02.tar.gz', '${v##p}' );
    is( $w->('${f%%-*}'), 'www', '${v%%p}' );
    is( $w->('${f:4:10}'), '2026-09-02', '${v:o:l}' );
    is( $w->('${#f}'), '21', '${#v}' );
    is( $w->('${leer:-std} ${unset-x}'), 'std|x', '${v:-w}, ${v-w}' );
    is( $w->('${f/tar/TAR}'), 'www-2026-09-02.TAR.gz', '${v/p/r}' );
    is( $w->('$p'), 'a|b', 'ohne Quotes: Wortaufteilung' );
    is( $w->('"$p"'), 'a b', 'in Quotes: ein Wort' );
    is( $w->(q{'$p'}), '$p', 'einfache Quotes: nichts' );
    is( $w->('x=$p'), 'x=a b', 'Zuweisung: ein Wort' );
    is( $w->('$? $# $1 $2 $3'), '3|2|x|y', '$? $# $1 …' );
    is( $w->('$((n * 2 + 1)) $(( (n+1) % 3 ))'), '15|2', '$(( )) mit Variablen' );
    is( $w->('"$(cmd a)"'), '[cmd a]', '$( ) ueber den Rueckruf, Zeilenende weg' );
    is( $w->(q{$'a\tb'}), "a\tb", q{$'…'} );
    is( $w->('$unbekannt'), '', 'ungesetzt: leer wie bash' );
    throws_ok { $e->('$((i++))') } qr/\Agap:/, 'i++: Luecke';
    throws_ok { $e->('$((1/0))') } qr/division by 0/, 'Division durch 0 wie bash';
};

subtest 'test' => sub {
    my %fs = ( '/f' => { kind => 'f', size => 3, mode => 0644, mtime => 2 }, '/d' => { kind => 'd', size => 4096, mode => 0755, mtime => 1 },
        '/leer' => { kind => 'f', size => 0, mode => 0755, mtime => 1 } );
    my $t = sub { my ( $st, $err ) = Langertha::Holmgang::Shell::test_expr( [@_], sub { $fs{ $_[0] } } ); $err // $st };
    my $tt = sub { my ( $st, $err ) = Langertha::Holmgang::Shell::test_expr( [@_], sub { $fs{ $_[0] } }, 1 ); $err // $st };
    is( $t->( '-f', '/f' ), 0, '-f' );
    is( $t->( '-d', '/f' ), 1, '-d auf Datei' );
    is( $t->( '!', '-e', '/x' ), 0, '! -e' );
    is( $t->( '-s', '/leer' ), 1, '-s leer' );
    is( $t->( '-x', '/leer', '-a', '-f', '/leer' ), 0, '-x -a -f' );
    is( $t->( '2026-09-02', '<', '2026-10-06' ), 0, 'Text <' );
    is( $t->( '10', '-lt', '9' ), 1, '-lt' );
    like( $t->( 'abc', '-lt', '9' ), qr/integer expression expected/, 'keine Zahl: Fehler' );
    is( $t->( '/f', '-nt', '/d' ), 0, '-nt' );
    is( $t->( '-z', '' ), 0, '-z' );
    is( $t->( 'x', '=', 'x', '-o', 'a', '=', 'b' ), 0, '-o' );
    like( $t->( 'a', 'b', 'c' ), qr/too many arguments|binary operator/, 'zu viele Argumente' );
    is( $tt->( 'www-1.tar.gz', '==', 'www-*.tar.gz' ), 0, '[[ == muster ]]' );
    is( $tt->( 'abc', '=~', '^a.c$', '&&', '1', '-eq', '1' ), 0, '[[ =~ && ]]' );
};

# --- im Simulator ---------------------------------------------------------------

sub world {
    return { h => { type => 'linux', hostname => 'h', files => {
        '/srv/a/README' => "liesmich\n",
        ( map { ( "/srv/a/www-2026-$_.tar.gz" => { content => 'x', mtime => 'Oct 01 00:00' } ) } qw( 09-01 09-02 09-30 10-01 10-05 10-06 10-07 ) ),
        '/root/liste' => "a 1\nb 2\nc 3\n",
        '/root/s.sh' => { content => "#!/bin/bash\nset -e\necho \"start \$1\"\nfor x in \"\$@\"; do\n  echo \"- \$x\"\ndone\nfalse\necho nie\n", mode => '0755' },
    } } };
}
my $W;
sub sh { my ( $o, $ok, $gap ) = run_command( $W, 'h', $_[0] ); return wantarray ? ( $o, $ok, $gap ) : $o }

subtest 'Variablen, if, $?' => sub {
    $W = world();
    is( sh('X=5; Y="$X und $X"; echo "$Y"'), '5 und 5', 'Zuweisung und Einsetzen' );
    is( sh('export A=1 B; echo $A$B'), '1', 'export' );
    is( sh('K=$(cat /srv/a/README); echo "[$K]"'), '[liesmich]', 'Befehlsersetzung in eine Variable' );
    is( sh('if [ -f /srv/a/README ]; then echo da; else echo weg; fi'), 'da', 'if [ -f ]' );
    is( sh('if [ -d /srv/a/README ]; then echo d; elif test -s /srv/a/README; then echo s; fi'), 's', 'elif test' );
    is( sh('[ 3 -gt 2 ] && echo ja || echo nein'), 'ja', '[ ] && ||' );
    is( sh('false; echo $?; true; echo $?'), "1\n0", '$?' );
    is( sh('[ abc -lt 3 ]; echo $?'), "bash: [: abc: integer expression expected\n2", 'Fehler in [ ]: Status 2' );
    is( sh('[[ www-2026-09-02.tar.gz == www-*.tar.gz && 2026-09-02 < 2026-10-06 ]] && echo alt'), 'alt', '[[ ]] mit Muster und <' );
    is( sh('cd /srv/a; echo $PWD'), '/srv/a', '$PWD nach cd' );
};

subtest 'Schleifen' => sub {
    $W = world();
    is( sh('cd /srv/a && for f in www-*.tar.gz; do d=${f#www-}; d=${d%.tar.gz}; [ "${d:8:2}" = 01 ] && continue; if [[ $d < 2026-10-06 ]]; then echo "$f"; fi; done'),
        "www-2026-09-02.tar.gz\nwww-2026-09-30.tar.gz\nwww-2026-10-05.tar.gz", 'for ueber Glob (relativ), ${…}, continue, [[ < ]]' );
    is( sh('n=0; for f in /srv/a/www-*; do n=$((n+1)); done; echo $n'), '7', 'Zaehler ueber die Schleife hinaus' );
    is( sh('for i in 1 2 3 4; do [ $i = 3 ] && break; echo $i; done'), "1\n2", 'break' );
    is( sh('for x in a b; do for y in 1 2; do [ $y = 2 ] && continue 2; echo $x$y; done; done'), "a1\nb1", 'continue 2' );
    is( sh('while read -r k v; do echo "$v=$k"; done < /root/liste'), "1=a\n2=b\n3=c", 'while read < datei' );
    is( sh('cat /root/liste | while read l; do echo "<$l>"; done | head -2'), "<a 1>\n<b 2>", 'befehl | while read … | filter' );
    is( sh(q{echo 'x:y:z' | while IFS=: read -r a b c; do echo $c$b$a; done}), 'zyx', 'IFS=: read' );
    is( sh('i=0; while [ $i -lt 3 ]; do echo $i; i=$((i+1)); done'), "0\n1\n2", 'while mit Bedingung' );
    is( sh('i=0; until [ $i -ge 2 ]; do i=$((i+1)); done; echo $i'), '2', 'until' );
    is( sh('for f in /srv/a/www-2026-09-0*; do rm "$f"; done; ls /srv/a | wc -l'), '6', 'rm in der Schleife wirkt' );
    my ( $o, $ok, $gap ) = sh('while true; do :; done');
    ok( $gap, 'while ohne Ende: Luecke' );
};

subtest 'case, Heredoc, Skripte' => sub {
    $W = world();
    is( sh('for f in a.tar.gz b.txt c; do case "$f" in *.tar.gz) echo "T $f";; *.txt|*.md) echo "D $f";; *) echo "? $f";; esac; done'),
        "T a.tar.gz\nD b.txt\n? c", 'case mit Mustern und |' );
    is( sh("V=welt\ncat > /root/g <<EOF\nhallo \$V\nEOF\ncat /root/g"), 'hallo welt', 'Heredoc in eine Datei, mit Expansion' );
    is( sh("cat <<'EOF'\n\$V bleibt\nEOF"), '$V bleibt', 'Heredoc mit Quote: wortwoertlich' );
    is( sh('grep -c . <<< "a"'), '1', 'Here-String' );
    my ( $o, $ok ) = sh('/root/s.sh eins zwei');
    is( $o, "start eins\n- eins\n- zwei", 'Skript mit Argumenten, for "$@", set -e bricht ab' );
    ok( !$ok, '... mit Fehler' );
    ( $o, $ok ) = sh('bash -c \'echo "$0 $1"; exit 3\' null eins; echo "rc=$?"');
    is( $o, "null eins\nrc=3", 'bash -c mit $0/$1, exit N' );
    is( sh('{ echo eins; printf "zwei\n"; } > /root/g; cat /root/g'), "eins\nzwei", '{ …; } > datei' );
    is( sh('{ echo a; echo b; } | sort -r'), "b\na", '{ …; } | filter' );
    is( sh('K=abcdefghij; C=3; E=5; echo "${K:$((C-1)):$((E-C+1))} ${K: -3} ${K:0:$C}"'), 'cde hij abc', '${v:$((…)):$((…))}' );
    is( sh('basename /srv/a/www-2026-09-01.tar.gz .tar.gz; dirname /srv/a/README'), "www-2026-09-01\n/srv/a", 'basename, dirname' );
    is( sh('cd /srv/a && wc -c README'), '9 README', 'wc nach cd: Name wie angegeben' );
    is( sh('cd /srv/a && ls www-2026-09-0* README'), "README\nwww-2026-09-01.tar.gz\nwww-2026-09-02.tar.gz", 'Glob relativ bleibt relativ, ls wie angegeben' );
    is( sh(q{cd /srv/a && ls | grep -c 'www-*'}), '7', 'gequotetes Muster wird nicht gegolbt' );
    is( sh('echo /srv/a/www-2026-10-0[5-6]*'), '/srv/a/www-2026-10-05.tar.gz /srv/a/www-2026-10-06.tar.gz', 'Glob mit Klasse, absolut' );
    is( sh('echo /srv/a/nix*'), '/srv/a/nix*', 'ohne Treffer bleibt das Wort' );
    my ( $ro, $rok ) = sh('rm -v /srv/a/fehlt /srv/a/README');
    is( $ro, "rm: cannot remove '/srv/a/fehlt': No such file or directory\nremoved '/srv/a/README'", 'rm -v, weiter nach einem Fehler' );
    ok( !$rok, '... Status: Fehler' );
    my $gap;
    ( $o, $ok, $gap ) = sh('f() { echo x; }; f');
    ok( !$gap && $o eq 'x', 'Funktion: laeuft' );
    ( $o, $ok, $gap ) = sh('( cd /tmp && ls ) ; pwd');
    ok( !$gap && $o eq '/root', 'Subshell: laeuft, cd bleibt drinnen' );
};

done_testing;
