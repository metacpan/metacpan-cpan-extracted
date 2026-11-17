#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: ls /. Bisher leer — ein Modell fragte 16 Mal
# hintereinander "ls -la /". Behauptet wird: "/" zeigt die ueblichen
# Verzeichnisse eines Debian und alles, was im Zustand direkt darunter liegt
# (Dateien, Verzeichnisse, Einhaengepunkte); Unterverzeichnisse erscheinen,
# auch wenn sie nur aus tieferen Eintraegen folgen.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $state = clone( { srv => { type => 'linux',
    mounts => { '/' => { size => '20G', used => '1G' }, '/data' => { size => '10G', used => '0' } },
    dirs   => { '/opt/app/var/cache' => {} },
    files  => { '/etc/hosts' => "127.0.0.1 localhost\n", '/backup.tar' => { size => '1G', content => '' } } } } );
sub sh { my ( $o, $ok ) = run_command( $state, 'srv', $_[0] ); return wantarray ? ( $o, $ok ) : $o }

my ( $o, $ok ) = sh('ls /');
ok( $ok, 'ls / gelingt' );
like( $o, qr/\bbin\b.*\betc\b.*\busr\b.*\bvar\b/s, 'die ueblichen Verzeichnisse' );
like( $o, qr/\bdata\b/, 'Einhaengepunkt' );
like( $o, qr/\bbackup\.tar\b/, 'Datei direkt unter /' );
like( sh('ls -la /'), qr{^-\S+ 1 root\s+root\s+\d+ \S+ +\d+ \S+ backup\.tar$}m, 'ls -l zeigt die Datei mit Metadaten' );
like( sh('ls /opt/app'), qr/\bvar\b/, 'Verzeichnis aus einem tieferen Eintrag' );

done_testing;
