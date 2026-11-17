#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );
use Langertha::Holmgang::Sim::Linux::Calendar ();

# Linux-Simulator: systemd-Timer und Logs.
# Behauptet wird: Kalenderausdruecke werden wie von systemd
# angenommen oder abgewiesen und normalisiert, der naechste Ablauf stimmt (Ortszeit
# Europe/Berlin, UTC auf Wunsch); Timer heissen x.timer (nicht x.timer.service),
# starten nur mit gueltigem Ausloeser und vorhandener Ziel-Unit; ein Timer wird in
# timers.target eingehaengt; eine Unit ohne [Install] ist static (enable wirkt
# nicht); oneshot-Dienste laufen einmal durch; neue Unit-Dateien laden beim ersten
# Zugriff; list-timers zeigt NEXT/LAST; journald setzt MaxRetentionSec und
# Storage=persistent beim Neustart um.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $C = 'Langertha::Holmgang::Sim::Linux::Calendar';

# --- Kalender ----------------------------------------------------------------
{
    # Abgeglichen mit dem echten systemd-analyze calendar (systemd 257.13, Debian 13,
    # TZ=Europe/Berlin, --base-time='2026-10-20 14:00:00 CEST' = Simulationszeit):
    # [ Ausdruck, Normalform (undef = ungueltig), Next elapse ]. Zwischen 252
    # (Debian 12) und 257 sind fuer diese Formen keine Unterschiede bekannt;
    # gegen 252 selbst ist die Tabelle nicht geprueft.
    my @table = (
    [ 'minutely', '*-*-* *:*:00', 'Tue 2026-10-20 14:01:00 CEST' ],
    [ 'hourly', '*-*-* *:00:00', 'Tue 2026-10-20 15:00:00 CEST' ],
    [ 'daily', '*-*-* 00:00:00', 'Wed 2026-10-21 00:00:00 CEST' ],
    [ 'weekly', 'Mon *-*-* 00:00:00', 'Mon 2026-10-26 00:00:00 CET' ],
    [ 'monthly', '*-*-01 00:00:00', 'Sun 2026-11-01 00:00:00 CET' ],
    [ 'quarterly', '*-01,04,07,10-01 00:00:00', 'Fri 2027-01-01 00:00:00 CET' ],
    [ 'semiannually', '*-01,07-01 00:00:00', 'Fri 2027-01-01 00:00:00 CET' ],
    [ 'yearly', '*-01-01 00:00:00', 'Fri 2027-01-01 00:00:00 CET' ],
    [ 'annually', '*-01-01 00:00:00', 'Fri 2027-01-01 00:00:00 CET' ],
    [ 'Daily', '*-*-* 00:00:00', 'Wed 2026-10-21 00:00:00 CEST' ],
    [ 'DAILY', '*-*-* 00:00:00', 'Wed 2026-10-21 00:00:00 CEST' ],
    [ '02:30', '*-*-* 02:30:00', 'Wed 2026-10-21 02:30:00 CEST' ],
    [ '2:30', '*-*-* 02:30:00', 'Wed 2026-10-21 02:30:00 CEST' ],
    [ '02:30:15', '*-*-* 02:30:15', 'Wed 2026-10-21 02:30:15 CEST' ],
    [ '*-*-* 02:30', '*-*-* 02:30:00', 'Wed 2026-10-21 02:30:00 CEST' ],
    [ '*-*-* 2:30:00', '*-*-* 02:30:00', 'Wed 2026-10-21 02:30:00 CEST' ],
    [ 'Mon..Fri 06:00', 'Mon..Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon-Fri 06:00', 'Mon..Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon-Fri *-*-* 06:00:00', 'Mon..Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon..Fri,Sat 06:00', 'Mon..Sat *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon,Tue,Wed,Thu,Fri 06:00', 'Mon..Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon,Tue 06:00', 'Mon,Tue *-*-* 06:00:00', 'Mon 2026-10-26 06:00:00 CET' ],
    [ 'Mon,Wed,Fri 06:00', 'Mon,Wed,Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Sat,Sun 03:30', 'Sat,Sun *-*-* 03:30:00', 'Sat 2026-10-24 03:30:00 CEST' ],
    [ 'Sun,Sat 03:30', 'Sat,Sun *-*-* 03:30:00', 'Sat 2026-10-24 03:30:00 CEST' ],
    [ 'monday 01:00', 'Mon *-*-* 01:00:00', 'Mon 2026-10-26 01:00:00 CET' ],
    [ 'Monday 01:00', 'Mon *-*-* 01:00:00', 'Mon 2026-10-26 01:00:00 CET' ],
    [ 'MON 01:00', 'Mon *-*-* 01:00:00', 'Mon 2026-10-26 01:00:00 CET' ],
    [ 'mon 01:00', 'Mon *-*-* 01:00:00', 'Mon 2026-10-26 01:00:00 CET' ],
    [ 'Tuesday,Thursday 07:00', 'Tue,Thu *-*-* 07:00:00', 'Thu 2026-10-22 07:00:00 CEST' ],
    [ 'Fri..Mon 06:00', undef ],
    [ 'Sun 04:00', 'Sun *-*-* 04:00:00', 'Sun 2026-10-25 04:00:00 CET' ],
    [ 'Sunday 04:00', 'Sun *-*-* 04:00:00', 'Sun 2026-10-25 04:00:00 CET' ],
    [ 'Sat..Sun 04:00', 'Sat,Sun *-*-* 04:00:00', 'Sat 2026-10-24 04:00:00 CEST' ],
    [ 'Mon', 'Mon *-*-* 00:00:00', 'Mon 2026-10-26 00:00:00 CET' ],
    [ 'Mon..Fri', 'Mon..Fri *-*-* 00:00:00', 'Wed 2026-10-21 00:00:00 CEST' ],
    [ '*:0/15', '*-*-* *:00/15:00', 'Tue 2026-10-20 14:15:00 CEST' ],
    [ '*:00/15', '*-*-* *:00/15:00', 'Tue 2026-10-20 14:15:00 CEST' ],
    [ '*-*-* *:0/15:00', '*-*-* *:00/15:00', 'Tue 2026-10-20 14:15:00 CEST' ],
    [ '*:*:0/30', '*-*-* *:*:00/30', 'Tue 2026-10-20 14:00:30 CEST' ],
    [ '0/2:00', '*-*-* 00/2:00:00', 'Tue 2026-10-20 16:00:00 CEST' ],
    [ '*-*-* 0/6:00:00', '*-*-* 00/6:00:00', 'Tue 2026-10-20 18:00:00 CEST' ],
    [ '*-*-01 00:00', '*-*-01 00:00:00', 'Sun 2026-11-01 00:00:00 CET' ],
    [ '*-01-01', '*-01-01 00:00:00', 'Fri 2027-01-01 00:00:00 CET' ],
    [ '2026-12-24 18:00', '2026-12-24 18:00:00', 'Thu 2026-12-24 18:00:00 CET' ],
    [ '*-*-* 05:00 UTC', '*-*-* 05:00:00 UTC', 'Wed 2026-10-21 07:00:00 CEST' ],
    [ '05:00 UTC', '*-*-* 05:00:00 UTC', 'Wed 2026-10-21 07:00:00 CEST' ],
    [ '05:00 Etc/UTC', '*-*-* 05:00:00 Etc/UTC', 'Wed 2026-10-21 07:00:00 CEST' ],
    [ '05:00 Europe/Berlin', '*-*-* 05:00:00 Europe/Berlin', 'Wed 2026-10-21 05:00:00 CEST' ],
    [ '05:00 America/New_York', '*-*-* 05:00:00 America/New_York', 'Wed 2026-10-21 11:00:00 CEST' ],
    [ '*-*-* 05:00:00 GMT', '*-*-* 05:00:00 GMT', 'Wed 2026-10-21 07:00:00 CEST' ],
    [ 'Mon..Fri 08:00..17:00', 'Mon..Fri *-*-* 08:00..17:00', 'Wed 2026-10-21 08:00:00 CEST' ],
    [ '*-*-* 08..17:00', '*-*-* 08..17:00:00', 'Tue 2026-10-20 15:00:00 CEST' ],
    [ '*-*-* 08,12,18:00', '*-*-* 08,12,18:00:00', 'Tue 2026-10-20 18:00:00 CEST' ],
    [ '*-*-* 08:00,30', '*-*-* 08:00,30:00', 'Wed 2026-10-21 08:00:00 CEST' ],
    [ '*-*-~1', undef ],
    [ '*-02-~1 00:00', undef ],
    [ '12:00 daily', undef ],
    [ 'daily 02:00', undef ],
    [ '02:00 daily', undef ],
    [ 'Mo..Fr 06:00', undef ],
    [ 'Mo-Fr 06:00', undef ],
    [ 'Mon..Fri 06:00, Sat 08:00', undef ],
    [ 'Mon..Fri 06:00,Sat 08:00', undef ],
    [ '24:00', undef ],
    [ '25:00', undef ],
    [ '*-*-* 23:60', undef ],
    [ '*-*-32', undef ],
    [ '30 2 * * *', undef ],
    [ '@daily', undef ],
    [ 'now', undef ],
    [ 'today', undef ],
    [ 'tomorrow', undef ],
    [ 'Mon 25:00', undef ],
    [ '*-*-* 06:00:00.5', '*-*-* 06:00:00.500000', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon-Wed,Fri 06:00', 'Mon..Wed,Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon..Wed,Fri..Sun 06:00', 'Mon..Wed,Fri..Sun *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon,Tue,Wed 06:00', 'Mon..Wed *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Wed..Mon 06:00', undef ],
    [ '*-02~1', '*-02~01 00:00:00', 'Sun 2027-02-28 00:00:00 CET' ],
    [ '*-*~01 00:00', '*-*~01 00:00:00', 'Sat 2026-10-31 00:00:00 CET' ],
    [ '*-*~07/1 03:00', '*-*~07/1 03:00:00', 'Sun 2026-10-25 03:00:00 CET' ],
    [ 'Mon *-*-1..7 03:00', 'Mon *-*-01..07 03:00:00', 'Mon 2026-11-02 03:00:00 CET' ],
    [ '*-*-1..7 Mon 03:00', undef ],
    [ '26-10-20 08:00', '2026-10-20 08:00:00', 'never' ],
    [ '2026-10..12-01 00:00', '2026-10..12-01 00:00:00', 'Sun 2026-11-01 00:00:00 CET' ],
    [ '8:5', '*-*-* 08:05:00', 'Wed 2026-10-21 08:05:00 CEST' ],
    [ '*:5', '*-*-* *:05:00', 'Tue 2026-10-20 14:05:00 CEST' ],
    [ '5', undef ],
    [ '06', undef ],
    [ 'Mon 6:00', 'Mon *-*-* 06:00:00', 'Mon 2026-10-26 06:00:00 CET' ],
    [ '05:00 utc', '*-*-* 05:00:00 UTC', 'Wed 2026-10-21 07:00:00 CEST' ],
    [ '05:00 Utc', '*-*-* 05:00:00 UTC', 'Wed 2026-10-21 07:00:00 CEST' ],
    [ '05:00 CET', '*-*-* 05:00:00 CET' ],    # 257 meldet hier Next elapse: never (Eigenheit), nicht nachgebildet
    [ '05:00 Europe/Nowhere', undef ],
    [ '*-*-* 05:00:00 UTC+1', undef ],
    [ 'Sunday,Saturday 03:00', 'Sat,Sun *-*-* 03:00:00', 'Sat 2026-10-24 03:00:00 CEST' ],
    [ 'MONDAY..FRIDAY 06:00', 'Mon..Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon..Fri,Sat,Sun 06:00', '*-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon,Mon 06:00', 'Mon *-*-* 06:00:00', 'Mon 2026-10-26 06:00:00 CET' ],
    [ 'Mon.. Fri 06:00', undef ],
    [ 'Mon .. Fri 06:00', undef ],
    [ 'Mon..Fri  06:00', 'Mon..Fri *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ '06:00', '*-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ '*-*-* 06:00:00', '*-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Fri-Mon 06:00', undef ],
    [ 'Mon-Tue 06:00', 'Mon,Tue *-*-* 06:00:00', 'Mon 2026-10-26 06:00:00 CET' ],
    [ 'Mon..Tue 06:00', 'Mon,Tue *-*-* 06:00:00', 'Mon 2026-10-26 06:00:00 CET' ],
    [ 'Mon-Wed 06:00', 'Mon..Wed *-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ '*-*-* 06:00/2', '*-*-* 06:00/2:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ '*-*-* 6/2:00', '*-*-* 06/2:00:00', 'Tue 2026-10-20 16:00:00 CEST' ],
    [ '*-*-* 06..08/1:00', '*-*-* 06..08:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ '*-*-* 00/15:00', '*-*-* 00/15:00:00', 'Tue 2026-10-20 15:00:00 CEST' ],
    [ '1/2', undef ],
    [ 'Mon,Tue,Wed,Thu,Fri,Sat,Sun 06:00', '*-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'Mon..Sun 06:00', '*-*-* 06:00:00', 'Wed 2026-10-21 06:00:00 CEST' ],
    [ 'hourly UTC', '*-*-* *:00:00 UTC', 'Tue 2026-10-20 15:00:00 CEST' ],
    [ 'daily UTC', '*-*-* 00:00:00 UTC', 'Wed 2026-10-21 02:00:00 CEST' ],
    [ 'weekly Europe/Berlin', 'Mon *-*-* 00:00:00 Europe/Berlin', 'Mon 2026-10-26 00:00:00 CET' ],
    [ '*-*-* *:*:*', '*-*-* *:*:*', 'Tue 2026-10-20 14:00:01 CEST' ],
    [ '*:*', '*-*-* *:*:00', 'Tue 2026-10-20 14:01:00 CEST' ],
    );
    my $now0 = Time::Local::timegm( 0, 0, 12, 20, 9, 2026 );
    for my $r (@table) {
        my ( $e, $norm, $next ) = @$r;
        my $c = $C->can('parse')->($e);
        if ( !defined $norm ) { ok( !$c, "Kalender: '$e' ungueltig wie bei systemd" ); next }
        is( $c && $c->{normalized}, $norm, "Kalender: '$e' -> '$norm'" );
        my $t = $c && $C->can('next_elapse')->( $c, $now0 );
        next unless defined $next;
        is( defined $t ? $C->can('format_local')->($t) : 'never', $next, "Kalender: '$e' naechster Ablauf $next" ) if $c;
    }
    is( $C->can('parse')->('06:00 ') && $C->can('parse')->('06:00 ')->{normalized}, '*-*-* 06:00:00', 'Leerraum am Ende: gueltig' );
    ok( !$C->can('parse')->(' 06:00'), 'Leerraum am Anfang: ungueltig (wie systemd-analyze)' );
    ok( !$C->can('parse')->(''), 'leer: ungueltig' );
    # jetzt = Di 2026-10-20 12:00 UTC = 14:00 CEST
    my $now = Time::Local::timegm( 0, 0, 12, 20, 9, 2026 );
    my $next = sub { $C->can('format_local')->( $C->can('next_elapse')->( $C->can('parse')->( $_[0] ), $now ), $_[1] ) };
    is( $next->('02:30'), 'Wed 2026-10-21 02:30:00 CEST', 'naechster Ablauf morgen frueh' );
    is( $next->('15:00'), 'Tue 2026-10-20 15:00:00 CEST', 'naechster Ablauf heute' );
    is( $next->('Sat 08:00'), 'Sat 2026-10-24 08:00:00 CEST', 'Wochentag' );
    is( $next->('Mon 08:00'), 'Mon 2026-10-26 08:00:00 CET', 'nach der Zeitumstellung: MEZ' );
    is( $next->( '*-*-* 05:00 UTC', 1 ), 'Wed 2026-10-21 05:00:00 UTC', 'UTC' );
    is( $C->can('format_local')->( $C->can('next_elapse')->( $C->can('parse')->('*-*-* 07:00'), $now + 5 * 86400 ), 1 ),
        'Mon 2026-10-26 06:00:00 UTC', '07:00 Ortszeit ist im Winter 06:00 UTC' );
}

my $unit_timer = "[Unit]\nDescription=Export taeglich\n\n[Timer]\nOnCalendar=*-*-* 02:30:00\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n";
my $unit_svc   = "[Unit]\nDescription=Export\n\n[Service]\nType=oneshot\nUser=export\nExecStart=/usr/local/bin/export\n";
my $start = {
    srv => {
        type   => 'linux',
        users  => { export => { uid => 1001, groups => ['export'] } },
        files  => {
            '/etc/systemd/system/export.service' => $unit_svc,
            '/etc/systemd/system/export.timer'   => $unit_timer,
            '/etc/systemd/system/alt.timer'      => "[Timer]\nOnCalendar=daily 02:00\nUnit=export.service\n\n[Install]\nWantedBy=timers.target\n",
            '/etc/systemd/journald.conf'         => "[Journal]\n#Storage=auto\n",
            '/var/log/journal/m/system@1.journal' => { size => '100M', mtime => 'Aug  2 03:10' },
            '/var/log/journal/m/system@2.journal' => { size => '100M', mtime => 'Oct 16 03:10' },
            '/var/log/journal/m/system.journal'   => { size => '10M' },
        },
        services => {
            'logrotate.timer' => { active => JSON::MaybeXS::true(), unit => '/lib/systemd/system/logrotate.timer',
                unit_loaded => "[Timer]\nOnCalendar=daily\nAccuracySec=1h\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n",
                last => 'Tue 2026-10-20 00:00:07 CEST', triggers => ['*-*-* 00:00:00'], activates => 'logrotate.service' },
            logrotate => { active => JSON::MaybeXS::false(), unit_loaded => "[Unit]\nDescription=Rotate log files\n\n[Service]\nType=oneshot\nExecStart=/usr/sbin/logrotate /etc/logrotate.conf\n" },
            app => { active => JSON::MaybeXS::true(), unit_loaded => "[Service]\nExecStart=/usr/local/bin/app\n" },
            'systemd-journald' => { active => JSON::MaybeXS::true(), config => '/etc/systemd/journald.conf', running => "[Journal]\n#Storage=auto\n" },
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
my $S;
sub svc { $state->{srv}{services}{ $_[0] } }

# --- Neuer Timer, static-Dienst, oneshot ----------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('systemctl enable export.service');
    ok( $ok, 'enable eines Dienstes ohne [Install]: kein Fehler' );
    like( $o, qr/no installation config/, '... aber die Meldung von systemd' );
    is( sh('systemctl is-enabled export'), 'static', '... und static' );
    ok( !exists svc('export')->{enabled} || !svc('export')->{enabled}, '... enabled bleibt aus' );
    ( $o, $ok ) = sh('systemctl enable --now export.timer');
    ok( $ok, 'neuer Timer: enable --now' ) or diag $o;
    like( $o, qr{Created symlink /etc/systemd/system/timers\.target\.wants/export\.timer}, 'Timer haengt in timers.target' );
    ok( svc('export.timer')->{active} && svc('export.timer')->{enabled}, 'Timer laeuft und ist enabled' );
    is_deeply( svc('export.timer')->{triggers}, ['*-*-* 02:30:00'], 'Ausloeser in Normalform im Zustand' );
    is( svc('export.timer')->{activates}, 'export.service', 'loest export.service aus' );
    like( sh('systemctl status export.timer'), qr/\A● export\.timer - Export taeglich\n.*active \(waiting\).*\n\s+Trigger: Wed 2026-10-21 02:30:00 CEST; 12h 30min left\n\s+Triggers: ● export\.service/s, 'status des Timers' );
    my $lt = sh('systemctl list-timers');
    like( $lt, qr/^NEXT\s+LEFT\s+LAST\s+PASSED\s+UNIT\s+ACTIVATES$/m, 'list-timers: Kopf' );
    like( $lt, qr/^Wed 2026-10-21 00:00:00 CEST 10h left\s+Tue 2026-10-20 00:00:07 CEST 13h 59min ago\s+logrotate\.timer\s+logrotate\.service$/m, 'list-timers: logrotate' );
    like( $lt, qr/^Wed 2026-10-21 02:30:00 CEST 12h 30min left\s+-\s+-\s+export\.timer\s+export\.service$/m, 'list-timers: neuer Timer ohne LAST' );
    like( $lt, qr/^2 timers listed\.$/m, 'list-timers: Zahl' );
    ( $o, $ok ) = sh('systemctl start export.service');
    ok( $ok, 'oneshot laeuft durch' );
    ok( !svc('export')->{active}, '... und ist danach inactive' );
    is( svc('export')->{runs}, 1, '... ein Lauf gezaehlt' );
    like( sh('journalctl -u export.service'), qr/Finished export\.service - Export\./, 'Journal: Finished' );
}

# --- Ungueltiger Kalender, fehlende Ziel-Unit, daemon-reload ----------------------
{
    fresh();
    my ( $o, $ok ) = sh('systemctl start alt.timer');
    ok( !$ok, 'Timer mit ungueltigem OnCalendar startet nicht' );
    like( $o, qr/Unit alt\.timer has a bad unit file setting/, '... mit der Meldung von systemd' );
    ok( !svc('alt.timer')->{active}, '... und laeuft nicht' );
    like( sh('journalctl -u alt.timer'), qr{alt\.timer:2: Failed to parse calendar specification, ignoring: daily 02:00\n.*Timer unit lacks value setting}s, 'Journal nennt die Zeile' );
    like( sh('systemd-analyze verify /etc/systemd/system/alt.timer'), qr/Failed to parse calendar specification, ignoring: daily 02:00/, 'verify' );
    sh(q{sed -i 's/^OnCalendar=daily 02:00$/OnCalendar=*-*-* 02:00/' /etc/systemd/system/alt.timer});
    ( $o, $ok ) = sh('systemctl start alt.timer');
    ok( !$ok, 'ohne daemon-reload wirkt die Korrektur nicht' );
    like( $o, qr/daemon-reload/, '... Warnung' );
    sh('systemctl daemon-reload');
    ( $o, $ok ) = sh('systemctl start alt.timer');
    ok( $ok, 'nach daemon-reload startet der Timer' ) or diag $o;
    is_deeply( svc('alt.timer')->{triggers}, ['*-*-* 02:00:00'], 'neue Ausloeser' );

    fresh();
    $state->{srv}{files}{'/etc/systemd/system/neu.timer'} = "[Timer]\nOnCalendar=daily\nUnit=gibtsnicht.service\n";
    ( $o, $ok ) = sh('systemctl start neu.timer');
    ok( !$ok, 'Timer ohne Ziel-Unit startet nicht' );
    like( $o, qr/Unit gibtsnicht\.service not found/, '... Meldung' );
    like( sh('systemctl status nichtda.timer'), qr/Unit nichtda\.timer could not be found/, 'unbekannter Timer heisst x.timer' );
}

# --- systemd-analyze calendar ----------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh(q{systemd-analyze calendar 'Mon..Fri 06:00'});
    ok( $ok, 'calendar: gueltig' );
    like( $o, qr/Normalized form: Mon\.\.Fri \*-\*-\* 06:00:00\n\s+Next elapse: Wed 2026-10-21 06:00:00 CEST\n\s+\(in UTC\): Wed 2026-10-21 04:00:00 UTC\n\s+From now: 16h left/, 'calendar: Ausgabe' );
    ( $o, $ok ) = sh(q{systemd-analyze calendar 'Mo..Fr 06:00'});
    ok( !$ok, 'calendar: ungueltig' );
    is( $o, "Failed to parse calendar specification 'Mo..Fr 06:00': Invalid argument", '... Meldung von systemd' );
    my ( undef, undef, $gap ) = sh('systemd-analyze blame');
    ok( $gap, 'andere Unterkommandos: Luecke der Simulation' );
}

# --- journald --------------------------------------------------------------------
{
    fresh();
    sh(q{printf '[Journal]\nStorage=persistent\nMaxRetentionSec=30day\n' > /etc/systemd/journald.conf});
    ok( exists $state->{srv}{files}{'/var/log/journal/m/system@1.journal'}, 'vor dem Neustart bleibt alles' );
    sh('systemctl restart systemd-journald');
    ok( !exists $state->{srv}{files}{'/var/log/journal/m/system@1.journal'}, 'MaxRetentionSec: altes Archiv weg' );
    ok( exists $state->{srv}{files}{'/var/log/journal/m/system@2.journal'}, '... juengeres bleibt' );
    fresh();
    delete $state->{srv}{files}{$_} for grep {m{^/var/log/journal}} keys %{ $state->{srv}{files} };
    sh(q{printf '[Journal]\nStorage=persistent\n' > /etc/systemd/journald.conf});
    sh('systemctl restart systemd-journald');
    ok( exists $state->{srv}{dirs}{'/var/log/journal'}, 'Storage=persistent legt /var/log/journal an' );
    is( sh('journalctl -u logrotate -g nichts'), '-- No entries --', 'journalctl -g filtert' );
}

# --- systemctl show, reload von journald ---------------------------------------
{
    fresh();
    sh('systemctl enable --now export.timer');
    my $o = sh('systemctl show export.timer');
    like( $o, qr/^TimersCalendar=\{ OnCalendar=\*-\*-\* 02:30:00 ; next_elapse=Wed 2026-10-21 02:30:00 CEST \}$/m, 'show: TimersCalendar' );
    like( $o, qr/^Persistent=yes$/m, 'show: Persistent' );
    like( $o, qr/^AccuracyUSec=1min$/m, 'show: AccuracyUSec (Vorgabe)' );
    like( $o, qr/^RandomizedDelayUSec=0$/m, 'show: RandomizedDelayUSec' );
    like( $o, qr/^Unit=export\.service$/m, 'show: Unit' );
    like( $o, qr/^ActiveState=active\nSubState=waiting$/m, 'show: Zustand eines Timers' );
    is( sh('systemctl show -p NextElapseUSecRealtime,Unit,Gibtsnicht export.timer'),
        "Unit=export.service\nNextElapseUSecRealtime=Wed 2026-10-21 02:30:00 CEST", 'show -p: Reihenfolge wie systemd, Unbekanntes fehlt' );
    is( sh('systemctl show export.service -p Type -p UnitFileState --value'), "oneshot\nstatic", 'show --value, -p mehrfach' );
    like( sh('systemctl show export.service -p ExecStart'),
        qr{\AExecStart=\{ path=/usr/local/bin/export ; argv\[\]=/usr/local/bin/export ; ignore_errors=no ; start_time=\[n/a\]}, 'show: ExecStart wie systemd' );
    is( sh('systemctl show logrotate.timer -p LastTriggerUSec --value'), 'Tue 2026-10-20 00:00:07 CEST', 'show: LastTriggerUSec' );
    is( sh('systemctl show nichtda.service -p Id,LoadState,ActiveState'), "Id=nichtda.service\nLoadState=not-found\nActiveState=inactive", 'show: unbekannte Unit' );
    my ( $r, $ok ) = sh('systemctl reload systemd-journald');
    ok( !$ok, 'journald: reload gibt es nicht' );
    is( $r, 'Failed to reload systemd-journald.service: Job type reload is not applicable for unit systemd-journald.service.', '... Meldung von systemd' );
    is( sh('systemctl show systemd-journald -p CanReload --value'), 'no', 'show: CanReload=no' );
    like( sh(q{systemd-analyze calendar '05:00 UTC'}), qr/Next elapse: Wed 2026-10-21 07:00:00 CEST\n\s+\(in UTC\): Wed 2026-10-21 05:00:00 UTC/,
        'calendar mit UTC: Ablauf in Ortszeit und in UTC' );
}

# --- .service unveraendert --------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('systemctl disable app');
    like( $o, qr{Removed "/etc/systemd/system/multi-user\.target\.wants/app\.service"}, 'Dienst ohne [Unit]: disable wie bisher' );
    is( sh('systemctl is-enabled app'), 'disabled', '... disabled' );
}

done_testing;
