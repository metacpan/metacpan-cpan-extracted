#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: mv und cp mit mehreren Quellen in ein Verzeichnis.
# Behauptet wird: wie coreutils landet
# jede Quelle unter ihrem Namen im Zielverzeichnis, die Belegung wandert mit auf
# den Einhaengepunkt des Ziels; ist das Ziel kein Verzeichnis, scheitert der
# Aufruf und nichts bewegt sich; ein Ziel mit / am Ende, das es nicht gibt,
# ist ein Fehler (keine Datei namens "ziel/").

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = {
    srv => {
        type   => 'linux',
        mounts => { '/' => { size => '20G', used => '2G' }, '/var' => { size => '10G', used => '0' }, '/srv' => { size => '100G', used => '0' } },
        dirs   => { '/srv/archiv/2025' => {} },
        files  => {
            '/var/archiv/2025-01.tar' => { size => '3G', content => '' },
            '/var/archiv/2025-02.tar' => { size => '3G', content => '' },
            '/var/archiv/2026-01.tar' => { size => '3G', content => '' },
            '/etc/x.conf'             => "a\n",
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh { my ($cmd) = @_; my ( $o, $ok ) = run_command( $state, 'srv', $cmd ); return wantarray ? ( $o, $ok ) : $o }
sub files { [ sort keys %{ $state->{srv}{files} } ] }

fresh();
my ( $o, $ok ) = sh('mv /var/archiv/2025-* /srv/archiv/2025/');
ok( $ok, 'mv mit Muster und mehreren Quellen gelingt' ) or diag $o;
is_deeply( files(), [ '/etc/x.conf', '/srv/archiv/2025/2025-01.tar', '/srv/archiv/2025/2025-02.tar', '/var/archiv/2026-01.tar' ],
    'jede Quelle liegt unter ihrem Namen im Ziel, das laufende Jahr bleibt' );
like( sh('df -h /var'), qr/\s30%\s+\/var\b/, 'Belegung von /var sinkt (nur 2026-01.tar bleibt, 3 von 10 GB)' );
like( sh('df -h /srv'), qr/\s6%\s+\/srv\b/, 'und steht jetzt auf /srv' );

fresh();
( $o, $ok ) = sh('cp /var/archiv/2025-01.tar /var/archiv/2025-02.tar /srv/archiv/2025');
ok( $ok, 'cp mit zwei Quellen in ein Verzeichnis (ohne / am Ende)' ) or diag $o;
ok( exists $state->{srv}{files}{'/var/archiv/2025-01.tar'} && exists $state->{srv}{files}{'/srv/archiv/2025/2025-02.tar'}, 'Quellen bleiben, Kopien liegen im Ziel' );

fresh();
( $o, $ok ) = sh('mv /var/archiv/2025-01.tar /var/archiv/2025-02.tar /srv/fehlt/');
ok( !$ok, 'Ziel ist kein Verzeichnis: Fehler' );
like( $o, qr/target '\/srv\/fehlt\/?'/, 'Meldung nennt das Ziel' );
is_deeply( files(), [ sort keys %{ $start->{srv}{files} } ], 'nichts bewegt' );

fresh();
( $o, $ok ) = sh('mv /var/archiv/2025-01.tar /srv/archiv/2024/');
ok( !$ok, 'eine Quelle, Ziel mit / am Ende fehlt: Fehler' );
like( $o, qr/Not a directory/, 'Meldung wie coreutils' );

fresh();
( $o, $ok ) = sh('mv /etc/x.conf /etc/y.conf');
ok( $ok && exists $state->{srv}{files}{'/etc/y.conf'}, 'Umbenennen mit zwei Argumenten wie bisher' );

# Verzeichnisse samt Inhalt (auch ueber Einhaengepunkte, wie coreutils)
fresh();
( $o, $ok ) = sh('mv /var/archiv /srv/archiv/2025/');
ok( $ok, 'mv eines Verzeichnisses in ein vorhandenes Verzeichnis' ) or diag $o;
is_deeply( files(), [ '/etc/x.conf', '/srv/archiv/2025/archiv/2025-01.tar', '/srv/archiv/2025/archiv/2025-02.tar', '/srv/archiv/2025/archiv/2026-01.tar' ],
    'Inhalt liegt darunter' );
like( sh('df -h /var'), qr/\s0%\s+\/var\b/, '/var ist danach leer' );
fresh();
( $o, $ok ) = sh('mv /var/archiv /srv/neu');
ok( $ok && exists $state->{srv}{files}{'/srv/neu/2026-01.tar'}, 'mv auf einen neuen Namen benennt das Verzeichnis um' );
fresh();
( $o, $ok ) = sh('mv /var/archiv /srv/fehlt/neu');
ok( !$ok, 'Elternverzeichnis des Ziels fehlt: Fehler' );
is_deeply( files(), [ sort keys %{ $start->{srv}{files} } ], 'nichts bewegt' );

done_testing;
