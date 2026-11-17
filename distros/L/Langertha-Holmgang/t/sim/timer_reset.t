#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: leere Zuweisung OnCalendar=.
# Behauptet wird wie systemd.timer(5): eine leere Zuweisung
# setzt die Liste der Kalender-Ausloeser zurueck — ein Drop-in mit
# "OnCalendar=" und danach "OnCalendar=…" ersetzt den Ausloeser der Unit; ohne
# die leere Zeile kommt der neue Ausloeser HINZU (beide gelten).

my $start = {
    srv => {
        type  => 'linux',
        dirs  => { '/etc/systemd/system' => { mode => '0755', owner => 'root', group => 'root' } },
        files => {
            '/lib/systemd/system/job.timer'   => "[Unit]\nDescription=Job\n\n[Timer]\nOnCalendar=*-*-* 02:00:00\n\n[Install]\nWantedBy=timers.target\n",
            '/lib/systemd/system/job.service' => "[Unit]\nDescription=Job\n\n[Service]\nType=oneshot\nExecStart=/bin/true\n",
        },
        services => {
            'job.timer' => { active => 1, enabled => 1, description => 'Job', unit => '/lib/systemd/system/job.timer',
                unit_loaded => 'current', triggers => ['*-*-* 02:00:00'], activates => 'job.service' },
            job => { active => 0, description => 'Job', unit => '/lib/systemd/system/job.service', unit_loaded => 'current' },
        },
    },
};
my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok ) = run_command( $state, 'srv', $cmd );
    return wantarray ? ( $o, $ok ) : $o;
}

fresh();
my ( $o, $ok ) = sh(q{mkdir -p /etc/systemd/system/job.timer.d && printf '[Timer]\nOnCalendar=\nOnCalendar=*-*-01 03:15:00\n' > /etc/systemd/system/job.timer.d/m.conf && systemctl daemon-reload});
ok( $ok, 'Drop-in mit leerer Zuweisung geladen' ) or diag $o;
is_deeply( $state->{srv}{services}{'job.timer'}{triggers}, ['*-*-01 03:15:00'], 'leere Zuweisung ersetzt den Ausloeser der Unit' );
like( sh('systemctl list-timers job.timer'), qr/Sun 2026-11-01 03:15:00 CET/, '... list-timers zeigt nur den neuen naechsten Lauf' );

fresh();
sh(q{mkdir -p /etc/systemd/system/job.timer.d && printf '[Timer]\nOnCalendar=*-*-01 03:15:00\n' > /etc/systemd/system/job.timer.d/m.conf && systemctl daemon-reload});
is_deeply( [ sort @{ $state->{srv}{services}{'job.timer'}{triggers} } ], [ '*-*-* 02:00:00', '*-*-01 03:15:00' ],
    'ohne leere Zuweisung: beide Ausloeser gelten' );

fresh();
sh(q{mkdir -p /etc/systemd/system/job.timer.d && printf '[Timer]\nOnCalendar=\n' > /etc/systemd/system/job.timer.d/m.conf && systemctl daemon-reload});
is_deeply( $state->{srv}{services}{'job.timer'}{triggers}, [], 'nur die leere Zuweisung: kein Kalender-Ausloeser mehr' );

done_testing;
