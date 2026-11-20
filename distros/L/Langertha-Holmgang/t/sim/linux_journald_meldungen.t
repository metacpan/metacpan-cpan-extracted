#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command prepare clone );

# Was journald ueber sich selbst sagt. Behauptet wird: journalctl -u systemd-journald
# zeigt beim Systemstart "Runtime Journal (/run/log/journal/ID)" bzw. "System Journal
# (/var/log/journal/ID)" mit Groesse und Grenze; nach einem Neustart mit
# Storage=persistent meldet der neue Prozess NACH "Started" das System-Journal mit der
# neuen Grenze und den Umzug, und die Startmeldung bleibt, wie sie war. journalctl
# --header nennt Pfad und Zeitraum jeder Datei; -t/SYSLOG_IDENTIFIER= und _COMM=
# (vom Kernel auf 15 Zeichen gekuerzt, wie echt) filtern nach dem Absender.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $id    = '9e4b2c7a1f3d5e6b8a0c2d4f6e8a1b3c';
my $conf  = "[Journal]\n#Storage=auto\n#SystemMaxUse=\n";
my $start = {
    srv7 => {
        type   => 'linux',
        clock  => 'Oct 21 10:30',
        mounts => { '/' => { dev => '/dev/vda1', size => '40G', used => '9G' } },
        files  => {
            '/etc/systemd/journald.conf' => $conf,
            "/run/log/journal/$id/system.journal" => { size => '24M', owner => 'root', group => 'systemd-journal', mode => '0640', content => '', open_by => 'systemd-journald' },
        },
        services => {
            'systemd-journald' => { active => JSON::MaybeXS::true(), exec => 'systemd-journald', config => '/etc/systemd/journald.conf', running => $conf },
            app => { active => JSON::MaybeXS::true(), exec => 'app' },
        },
    },
};
my $state = clone($start);
prepare($state);
sub sh { my ( $o, $ok, $gap ) = run_command( $state, 'srv7', $_[0] ); return wantarray ? ( $o, $ok, $gap ) : $o }

my $j = sh('journalctl -u systemd-journald --no-pager');
like( $j, qr/\AOct 20 09:00:00 srv7 systemd-journald\[231\]: Journal started\n/, 'Start: Journal started zur Startzeit' );
like( $j, qr{Runtime Journal \(/run/log/journal/$id\) is 24\.0M, max 195\.2M, 171\.2M free\.}, '... Runtime Journal in /run' );
is( sh('journalctl -t systemd-journald --no-pager'), $j, '-t: dieselben Zeilen' );
is( sh('journalctl SYSLOG_IDENTIFIER=systemd-journald --no-pager'), $j, 'SYSLOG_IDENTIFIER=' );
is( sh('journalctl _COMM=systemd-journald --no-pager'), '-- No entries --', '_COMM= mit 16 Zeichen: nichts (wie echt)' );
like( sh('journalctl _COMM=systemd-journal --no-pager'), qr/Runtime Journal/, '_COMM= gekuerzt' );
like( sh('journalctl _SYSTEMD_UNIT=systemd-journald.service --no-pager'), qr/Journal started/, '_SYSTEMD_UNIT=' );

my $h = sh('journalctl --header');
like( $h, qr{\AFile path: /run/log/journal/$id/system\.journal\n}, '--header: Pfad' );
like( $h, qr{Head realtime timestamp: Tue 2026-10-20 09:00:00 CEST\nTail realtime timestamp: Wed 2026-10-21 10:30:00 CEST}, '... vom Start bis jetzt' );

sh(q{sed -i -e 's/^#Storage=auto$/Storage=persistent/' -e 's/^#SystemMaxUse=$/SystemMaxUse=1G/' /etc/systemd/journald.conf});
sh('systemctl restart systemd-journald');
$j = sh('journalctl -u systemd-journald --no-pager');
like( $j, qr/Runtime Journal \(\/run/, 'nach dem Neustart: Startmeldung bleibt' );
like( $j, qr/Started systemd-journald\.service[^\n]*\n[^\n]*Journal started\n[^\n]*System Journal \(\/var\/log\/journal\/$id\) is 24\.0M, max 1\.0G, 1000\.0M free\.\n[^\n]*Time spent on flushing to \/var\/log\/journal\/$id/,
    '... danach: System Journal mit neuer Grenze und Umzug' );
like( sh('journalctl --header'), qr{\AFile path: /var/log/journal/$id/system\.journal}, '--header: jetzt in /var' );

done_testing;
