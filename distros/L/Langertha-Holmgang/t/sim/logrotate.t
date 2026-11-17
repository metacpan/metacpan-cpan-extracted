#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# logrotate im Linux-Simulator. Behauptet
# wird: -d liest die Konfiguration (auch ueber include) und zeigt den Plan ohne
# etwas zu aendern; Fehler in der Konfiguration meldet logrotate mit Datei und
# Zeile; -f rotiert wirklich: copytruncate kopiert und leert, ohne dass der Dienst
# die Datei verliert; create benennt um, legt neu an, und erst ein reload im
# postrotate laesst den Dienst in die neue Datei schreiben; Generationen werden
# weitergeschoben und mit delaycompress verzoegert komprimiert.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $start = {
    srv => {
        type   => 'linux',
        users  => { app => { uid => 1050, groups => [ 'app', 'adm' ] } },
        groups => { adm => { gid => 4 } },
        files  => {
            '/etc/logrotate.conf'        => "weekly\nrotate 4\ncreate\ninclude /etc/logrotate.d\n",
            '/etc/logrotate.d/apt'       => "/var/log/apt/term.log {\n  rotate 12\n  monthly\n  compress\n  missingok\n  notifempty\n}\n",
            '/etc/logrotate.d/alt.dpkg-old' => "# alt\n",
            '/etc/logrotate.d/app'       => "/var/log/app/*.log {\n    daily\n    rotate 3\n    compress\n    delaycompress\n    missingok\n    notifempty\n    create 0640 app adm\n    sharedscripts\n    postrotate\n        systemctl reload app\n    endscript\n}\n",
            '/etc/logrotate.d/alt'       => "/var/log/alt/alt.log {\n    daily\n    rotate 7\n    copytruncate\n}\n",
            '/var/log/app/app.log'       => { size => '100M', owner => 'app', group => 'adm', mode => '0640', open_by => 'app', content => '' },
            '/var/log/app/app.log.1'     => { size => '90M', owner => 'app', group => 'adm', mode => '0640', content => '' },
            '/var/log/app/app.log.2.gz'  => { size => '9M', owner => 'app', group => 'adm', mode => '0640', content => '' },
            '/var/log/app/app.log.3.gz'  => { size => '9M', owner => 'app', group => 'adm', mode => '0640', content => '' },
            '/var/log/alt/alt.log'       => { size => '50M', owner => 'root', group => 'adm', mode => '0640', open_by => 'alt', content => '' },
        },
        services => {
            app => { active => $T, unit_loaded => "[Service]\nExecStart=/usr/bin/app\nExecReload=/bin/kill -HUP \$MAINPID\n" },
            alt => { active => $T, reload => JSON::MaybeXS::false() },
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'srv', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
sub f { $state->{srv}{files}{ $_[0] } }

{
    fresh();
    my ( $o, $ok, $gap ) = sh('logrotate --version');
    ok( $ok && !$gap, '--version' );
    like( $o, qr/\Alogrotate 3\.21\.0\n/, '... Debian 12' );

    my $before = clone($state);
    ( $o, $ok, $gap ) = sh('logrotate -d /etc/logrotate.conf');
    ok( $ok, '-d ueber logrotate.conf: kein Fehler' ) or diag $o;
    ok( !$gap, '... keine Luecke' );
    like( $o, qr/\Awarning: logrotate in debug mode does nothing/, '... Warnung des Debug-Modus' );
    like( $o, qr/^reading config file \/etc\/logrotate\.conf\nincluding \/etc\/logrotate\.d\n/m, '... include' );
    like( $o, qr/^Ignoring alt\.dpkg-old, because of \.dpkg-old ending$/m, '... .dpkg-old uebergangen' );
    like( $o, qr/^Handling 3 logs$/m, '... drei Bloecke' );
    like( $o, qr/^rotating pattern: \/var\/log\/app\/\*\.log  after 1 days \(3 rotations\)$/m, '... Muster mit Zeitraum' );
    like( $o, qr/^  log \/var\/log\/apt\/term\.log does not exist -- skipping$/m, '... missingok' );
    is_deeply( $state, $before, '-d aendert nichts' );

    ( $o, $ok ) = sh('logrotate -d -f /etc/logrotate.d/app');
    like( $o, qr/forced from command line \(3 rotations\)/, '-d -f: erzwungen' );
    like( $o, qr/renaming \/var\/log\/app\/app\.log to \/var\/log\/app\/app\.log\.1\ncreating new \/var\/log\/app\/app\.log mode = 0640 uid = 1050 gid = 4/, '... Plan mit create' );
    like( $o, qr/running postrotate script/, '... postrotate' );
    is_deeply( $state, $before, '-d -f aendert nichts' );
}

# --- Fehler in der Konfiguration ---------------------------------------------
{
    fresh();
    $state->{srv}{files}{'/etc/logrotate.d/kaputt'} = "/var/log/k.log {\n    daily\n    rotete 7\n";
    my ( $o, $ok ) = sh('logrotate -d /etc/logrotate.d/kaputt');
    ok( !$ok, 'Fehler: Exit-Status ungleich 0' );
    like( $o, qr/^error: \/etc\/logrotate\.d\/kaputt:3 unknown option 'rotete' -- ignoring line$/m, 'unbekannte Angabe mit Zeile' );
    like( $o, qr/missing '\}' at end of file/, 'fehlende Klammer' );
    ( $o, $ok ) = sh('logrotate /etc/logrotate.d/kaputt');
    unlike( $o, qr/reading config/, 'ohne -d/-v nur die Fehler' );
    $state->{srv}{files}{'/etc/logrotate.d/doppelt'} = "/var/log/app/app.log {\n  daily\n}\n";
    ( $o, $ok ) = sh('logrotate -d /etc/logrotate.d/app /etc/logrotate.d/doppelt');
    ok( !$ok, 'doppelter Eintrag: Fehler' );
    like( $o, qr/duplicate log entry for \/var\/log\/app\/app\.log/, '... Meldung' );
    $state->{srv}{files}{'/etc/logrotate.d/app'} = { content => f('/etc/logrotate.d/app'), mode => '0666' };
    ( $o, $ok ) = sh('logrotate -d /etc/logrotate.d/app');
    like( $o, qr/Ignoring \/etc\/logrotate\.d\/app because of bad file mode - must be 0644 or 0444\./, 'fuer alle schreibbar: abgewiesen' );
}

# --- -f: create, delaycompress, postrotate reload ------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('logrotate -f /etc/logrotate.d/app');
    ok( $ok, '-f mit create' ) or diag $o;
    ok( !exists f('/var/log/app/app.log.3.gz')->{x}, 'aelteste Generation bleibt bis rotate' );
    is( f('/var/log/app/app.log.1')->{size}, '100M', 'app.log ist jetzt .1 (unkomprimiert, delaycompress)' );
    ok( f('/var/log/app/app.log.2.gz'), 'alte .1 ist jetzt .2.gz' );
    is( f('/var/log/app/app.log')->{size}, '0', 'neue leere app.log' );
    is( f('/var/log/app/app.log')->{mode}, '0640', '... mit Rechten aus create' );
    is( f('/var/log/app/app.log')->{open_by}, 'app', 'nach dem reload schreibt app in die neue Datei' );
    ok( !defined f('/var/log/app/app.log.1')->{open_by}, '... nicht mehr in die alte' );
}
{
    fresh();
    $state->{srv}{files}{'/etc/logrotate.d/app'} =~ s/    postrotate\n.*?endscript\n//s;
    sh('logrotate -f /etc/logrotate.d/app');
    is( f('/var/log/app/app.log.1')->{open_by}, 'app', 'ohne Neuladen schreibt app weiter in die umbenannte Datei' );
    ok( !defined f('/var/log/app/app.log')->{open_by}, '... die neue bleibt leer' );
    sh('systemctl restart app');
    is( f('/var/log/app/app.log')->{open_by}, 'app', 'Neustart: app oeffnet neu' );
}

# --- -f: copytruncate ----------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('logrotate -v -f /etc/logrotate.d/alt');
    ok( $ok, '-v -f copytruncate' ) or diag $o;
    like( $o, qr/copying \/var\/log\/alt\/alt\.log to \/var\/log\/alt\/alt\.log\.1\ntruncating \/var\/log\/alt\/alt\.log/, '-v zeigt die Schritte' );
    is( f('/var/log/alt/alt.log.1')->{size}, '50M', 'Kopie hat den Inhalt' );
    is( f('/var/log/alt/alt.log')->{size}, '0', 'Original geleert' );
    is( f('/var/log/alt/alt.log')->{open_by}, 'alt', '... der Dienst schreibt weiter hinein' );
    my ( undef, $rok ) = sh('systemctl reload alt');
    ok( !$rok, 'alt kann nicht neu laden (reload: false)' );
}

done_testing;
