#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Monitoring auf dem Linux-Simulator.
# Behauptet wird: Prometheus mit mehreren Dateien liest beim reload nur, was
# reload_config nennt (prometheus.yml, nicht die Startoptionen), samt den
# Regeldateien; eine fehlerhafte Datei laesst beim reload alles, wie es lief
# (Fehler im Journal), und verhindert den Start; promtool und amtool pruefen wie
# die echten Werkzeuge; logrotate -d aendert nichts, -f rotiert (umbenennen +
# create bzw. copytruncate, compress, postrotate im Simulator), ueberspringt
# unsichere Verzeichnisse ohne su und meldet unbekannte Optionen.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $yml   = "global:\n  scrape_interval: 15s\nrule_files:\n  - rules/*.yml\nscrape_configs:\n  - job_name: node\n    static_configs:\n      - targets: ['10.20.0.11:9100']\n";
my $rules = "groups:\n  - name: platte\n    rules:\n      - alert: PlatteVoll\n        expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.2\n        for: 5m\n";
my $start = {
    mon => {
        type  => 'linux',
        clock => 'Oct 24 09:12',
        dirs  => { '/var/log/app' => { owner => 'app', group => 'app', mode => '0775' } },
        users => { app => { uid => 1001, groups => ['app'] } },
        files => {
            '/etc/prometheus/prometheus.yml'   => $yml,
            '/etc/prometheus/rules/platte.yml' => $rules,
            '/etc/default/prometheus'          => qq{ARGS=""\n},
            '/etc/systemd/system/prometheus.service' => "[Service]\nExecStart=/usr/bin/prometheus \$ARGS\nExecReload=/bin/kill -HUP \$MAINPID\n",
            '/etc/prometheus/alertmanager.yml' => "route:\n  receiver: team\n  routes:\n    - matchers: ['team=\"db\"']\n      receiver: dba\nreceivers:\n  - name: team\n",
            '/var/log/app/app.log'             => { content => "zeile\n", size => '2G', owner => 'app', group => 'app', mode => '0640', open_by => 'app' },
            '/etc/logrotate.d/app'             => "/var/log/app/*.log {\n  daily\n  rotate 7\n  compress\n  delaycompress\n  missingok\n  create 0640 app app\n  postrotate\n    systemctl reload app\n  endscript\n}\n",
        },
        services => {
            prometheus => { active => JSON::MaybeXS::true(), exec => 'prometheus', unit => '/etc/systemd/system/prometheus.service',
                config => [ '/etc/prometheus/prometheus.yml', '/etc/default/prometheus' ], config_main => '/etc/prometheus/prometheus.yml',
                config_check => 'prometheus', reload_config => ['/etc/prometheus/prometheus.yml'] },
            app => { active => JSON::MaybeXS::true(), exec => 'node', unit => '/etc/systemd/system/app.service' },
        },
    },
};
$start->{mon}{files}{'/etc/systemd/system/app.service'} = "[Service]\nExecStart=/usr/bin/node app.js\nExecReload=/bin/kill -HUP \$MAINPID\n";

my $state;
sub fresh { $state = clone($start); prepare($state); sh('systemctl restart prometheus') }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'mon', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
my $P = sub { $state->{mon}{services}{prometheus} };

{
    fresh();
    is( $P->()->{running}{'/etc/prometheus/rules/platte.yml'}, $rules, 'Start: Regeldatei geladen' );
    like( sh('promtool check config /etc/prometheus/prometheus.yml'), qr/SUCCESS: 1 rule files found.*SUCCESS: 1 rules found/s, 'promtool check config' );
    sh(q{sed -i 's/< 0.2/< 0.1/' /etc/prometheus/rules/platte.yml});
    sh(q{sed -i 's/ARGS=""/ARGS="--storage.tsdb.retention.time=15d"/' /etc/default/prometheus});
    sh('systemctl reload prometheus');
    like( $P->()->{running}{'/etc/prometheus/rules/platte.yml'}, qr/< 0\.1/, 'reload liest die Regeldatei' );
    is( $P->()->{running}{'/etc/default/prometheus'}, qq{ARGS=""\n}, '... nicht die Startoptionen' );
    sh('systemctl restart prometheus');
    like( $P->()->{running}{'/etc/default/prometheus'}, qr/15d/, 'Neustart liest sie' );
    $P->()->{reload_config} = JSON::MaybeXS::true();
    $state = clone($state);    # wie im Lauf: Wahrheitswert nach JSON-Kopie
    sh(q{sed -i 's/15d/20d/' /etc/default/prometheus});
    ok( ( sh('systemctl reload prometheus') )[1], 'reload_config true bei mehreren Dateien' );
    like( $P->()->{running}{'/etc/default/prometheus'}, qr/20d/, '... liest alle' );

    sh(q{sed -i 's/for: 5m/fro: 5m/' /etc/prometheus/rules/platte.yml});
    like( sh('promtool check rules /etc/prometheus/rules/platte.yml'), qr/FAILED:.*field fro not found in type rulefmt\.RuleNode/s, 'promtool check rules' );
    sh('systemctl reload prometheus');
    like( $P->()->{running}{'/etc/prometheus/rules/platte.yml'}, qr/for: 5m/, 'reload mit Fehler: alte Regeln bleiben' );
    like( sh('journalctl -u prometheus -n 3'), qr/Error reloading config/, '... Journal zeigt den Fehler' );
    my ( $o, $ok ) = sh('systemctl restart prometheus');
    ok( !$ok, 'Neustart mit Fehler scheitert' );
    ok( !$P->()->{active}, '... Prometheus steht' );

    fresh();
    sh(q{echo '  - job_name: node' >> /etc/prometheus/prometheus.yml});
    like( sh('promtool check config /etc/prometheus/prometheus.yml'), qr/FAILED: .*multiple scrape configs with job name "node"/, 'doppelter job_name' );
    like( sh('amtool check-config /etc/prometheus/alertmanager.yml'), qr/FAILED: undefined receiver "dba" used in route/, 'amtool: unbekannter Empfaenger' );

    # amtool config routes: Ladefehler wie amtool; Baum mit sortierten Matchern und continue;
    # test folgt dem ersten passenden Zweig, mit continue auch den naechsten
    like( sh('amtool config routes show --config.file=/etc/prometheus/alertmanager.yml'), qr/\Aamtool: error: undefined receiver "dba" used in route\z/,
        'amtool config routes: Ladefehler' );
    $state->{mon}{files}{'/etc/prometheus/alertmanager.yml'} = "route:\n  receiver: team\n  routes:\n"
        . "    - matchers: ['team=\"db\"', 'severity=~\"crit|warn\"']\n      receiver: dba\n      continue: true\n"
        . "    - match_re:\n        team: 'db|web'\n      receiver: chat\n"
        . "    - match:\n        team: db\n      receiver: nie\n"
        . "receivers:\n  - name: team\n  - name: dba\n  - name: chat\n  - name: nie\n";
    is( sh('amtool config routes --config.file /etc/prometheus/alertmanager.yml'),
        qq{Routing tree:\n.\n\x{2514}\x{2500}\x{2500} default-route  receiver: team\n}
            . qq{    \x{251c}\x{2500}\x{2500} {severity=~"crit|warn",team="db"}, continue: true  receiver: dba\n}
            . qq{    \x{251c}\x{2500}\x{2500} {team=~"db|web"}  receiver: chat\n}
            . qq{    \x{2514}\x{2500}\x{2500} {team="db"}  receiver: nie},
        'amtool config routes: Baum' );
    is( sh('amtool config routes test --config.file=/etc/prometheus/alertmanager.yml team=db severity=crit'), 'dba,chat', 'test: continue' );
    is( sh('amtool config routes test --config.file=/etc/prometheus/alertmanager.yml team=db'), 'chat', 'test: erster Treffer' );
    is( sh('amtool config routes test --config.file=/etc/prometheus/alertmanager.yml team=mail'), 'team', 'test: Vorgabe' );
    ( $o, $ok ) = sh('amtool config routes test --config.file=/etc/prometheus/alertmanager.yml --verify.receivers=dba team=mail');
    ok( !$ok, 'test --verify.receivers falsch' );
    like( $o, qr/\Ateam\nWARNING: Expected receivers did not match/, '… Meldung' );

    fresh();
    sh(q{sed -i 's/^  - job_name: node$/  - job_name: node\n    scrape_timeout: 30s/' /etc/prometheus/prometheus.yml});
    like( sh('promtool check config /etc/prometheus/prometheus.yml'), qr/scrape timeout greater than scrape interval for scrape config with job name "node"/,
        'scrape_timeout > scrape_interval' );
    sh(q{sed -i 's/^    scrape_timeout: 30s$/    scrape_interval: 60s\n    scrape_timeout: 30s/' /etc/prometheus/prometheus.yml});
    like( sh('promtool check config /etc/prometheus/prometheus.yml'), qr/SUCCESS: \/etc\/prometheus\/prometheus\.yml is valid/, '... mit eigenem Intervall gueltig' );
}

# --- logrotate ---------------------------------------------------------------------
{
    fresh();
    like( sh('logrotate -d /etc/logrotate.d/app'), qr/skipping "\/var\/log\/app\/app\.log" because parent directory has insecure permissions/, 'unsicheres Verzeichnis ohne su' );
    is( $state->{mon}{files}{'/var/log/app/app.log'}{size}, '2G', '-d aendert nichts' );
    sh(q{sed -i 's/^  daily$/  daily\n  su app app/' /etc/logrotate.d/app});
    like( sh('logrotate -d /etc/logrotate.d/app'), qr/considering log \/var\/log\/app\/app\.log/, 'mit su: wird betrachtet' );
    ok( ( sh('logrotate -f /etc/logrotate.d/app') )[1], 'logrotate -f' );
    is( $state->{mon}{files}{'/var/log/app/app.log.1'}{size}, '2G', 'umbenannt (delaycompress: noch nicht gepackt)' );
    is( $state->{mon}{files}{'/var/log/app/app.log'}{mode}, '0640', 'create legt neu an' );
    like( sh('journalctl -u app -n 2'), qr/Reloaded app\.service/, 'postrotate lief' );
    sh('logrotate -f /etc/logrotate.d/app');
    ok( exists $state->{mon}{files}{'/var/log/app/app.log.2.gz'} || exists $state->{mon}{files}{'/var/log/app/app.log.2'}, 'zweite Runde schiebt weiter' );

    fresh();
    sh(q{sed -i 's/^  compress$/  compres/' /etc/logrotate.d/app});
    like( sh('logrotate -d /etc/logrotate.d/app'), qr{error: /etc/logrotate\.d/app:4 unknown option 'compres' -- ignoring line}, 'unbekannte Option' );

    fresh();
    $state->{mon}{dirs}{'/var/log/app'}{mode} = '0755';
    $state->{mon}{files}{'/etc/logrotate.d/app'} =~ s/  create 0640 app app\n/  copytruncate\n/;
    sh('logrotate -f /etc/logrotate.d/app');
    is( $state->{mon}{files}{'/var/log/app/app.log'}{size}, 0, 'copytruncate leert die Datei' );
    is( $state->{mon}{files}{'/var/log/app/app.log'}{open_by}, 'app', '... die offen bleibt' );
    is( $state->{mon}{files}{'/var/log/app/app.log.1'}{size}, '2G', '... und kopiert' );
}

# --- HTTP-Schnittstelle (wget -O -) -----------------------------------------------
# Behauptet: wget gegen die eigene Maschine bekommt von Prometheus die laufende
# Konfiguration und Regeln (nicht die Datei auf der Platte); /-/reload nur per POST
# und nur mit --web.enable-lifecycle; ohne laufenden Dienst Verbindung abgelehnt.
{
    fresh();
    is( sh('wget -qO- http://localhost:9090/-/healthy'), 'Prometheus Server is Healthy.', 'healthy' );
    sh(q{sed -i 's/< 0.2/< 0.1/' /etc/prometheus/rules/platte.yml});
    my $r = JSON::MaybeXS::decode_json( sh('wget -q -O - http://127.0.0.1:9090/api/v1/rules') );
    like( $r->{data}{groups}[0]{rules}[0]{query}, qr/< 0\.2\z/, 'rules: die laufende Regel, nicht die Datei' );
    is( $r->{data}{groups}[0]{rules}[0]{duration}, 300, '... mit Dauer in Sekunden' );
    my $c = JSON::MaybeXS::decode_json( sh('wget -qO - http://localhost:9090/api/v1/status/config') );
    like( $c->{data}{yaml}, qr/job_name: node/, 'status/config' );
    is( ( sh('wget -qO- --post-data= http://localhost:9090/-/reload') )[0], 'ERROR 403: Forbidden.', 'reload ohne lifecycle: 403' );
    sh(q{sed -i 's/ARGS=""/ARGS="--web.enable-lifecycle"/' /etc/default/prometheus});
    sh('systemctl restart prometheus');
    sh(q{sed -i 's/< 0.2/< 0.1/' /etc/prometheus/rules/platte.yml});
    ok( ( sh('wget -qO- --post-data= http://localhost:9090/-/reload') )[1], 'reload per POST mit lifecycle' );
    like( $P->()->{running}{'/etc/prometheus/rules/platte.yml'}, qr/< 0\.1/, '... laedt die Regeln' );
    # status/flags aus den laufenden Startoptionen, Standardwerte wie Prometheus; alerts ohne feuernde Regel leer
    my $f = JSON::MaybeXS::decode_json( sh('wget -qO- http://localhost:9090/api/v1/status/flags') );
    is( $f->{data}{'web.enable-lifecycle'}, 'true', 'status/flags: gesetzte Option' );
    is( $f->{data}{'storage.tsdb.retention.time'}, '0s', '... Standardwert' );
    sh(q{sed -i 's/ARGS="--web.enable-lifecycle"/ARGS="--web.enable-lifecycle --storage.tsdb.retention.time=15d"/' /etc/default/prometheus});
    $f = JSON::MaybeXS::decode_json( sh('wget -qO- http://localhost:9090/api/v1/status/flags') );
    is( $f->{data}{'storage.tsdb.retention.time'}, '0s', '... die Datei wirkt erst nach Neustart' );
    sh('systemctl restart prometheus');
    $f = JSON::MaybeXS::decode_json( sh('wget -qO- http://localhost:9090/api/v1/status/flags') );
    is( $f->{data}{'storage.tsdb.retention.time'}, '15d', '... nach Neustart' );
    is_deeply( JSON::MaybeXS::decode_json( sh('wget -qO- http://localhost:9090/api/v1/alerts') ), { status => 'success', data => { alerts => [] } }, 'alerts: keine feuernde Regel' );
    sh('systemctl stop prometheus');
    like( ( sh('wget -qO- http://localhost:9090/-/healthy') )[0], qr/Connection refused/, 'gestoppt: abgelehnt' );
    like( ( sh('wget -qO- http://10.9.9.9:9090/-/healthy') )[2], qr/wget/, 'fremde Maschine: Luecke' );
}

# --- Alertmanager: Routen, Stummschaltungen, date ------------------------------
# Behauptet: _routes nennt je Empfaenger die wirksamen Zeiten (Unterrouten erben);
# amtool silence braucht --alertmanager.url und einen Kommentar, rechnet Zeiten
# (RFC 3339, Dauer) gegen die Uhr des Geraets und haelt fest, welche Ziele eine
# Stummschaltung trifft; alert query laesst Stummgeschaltetes weg; date folgt der Uhr.
{
    my $am = "route:\n  receiver: team\n  repeat_interval: 1h\n  routes:\n    - matchers: ['team=\"db\"']\n      receiver: dba\n      repeat_interval: 4h\n    - matchers: ['team=\"web\"']\n      receiver: web\nreceivers:\n  - name: team\n  - name: dba\n  - name: web\n";
    my $st = { am1 => { type => 'linux', clock => 'Oct 24 09:12',
        files => { '/etc/prometheus/alertmanager.yml' => $am },
        services => { 'prometheus-alertmanager' => { active => JSON::MaybeXS::true(), exec => 'prometheus-alertmanager',
            config => ['/etc/prometheus/alertmanager.yml'], config_check => 'alertmanager',
            alert_targets => { db7 => { instance => 'db7.example.internal:9100', job => 'node' }, db8 => { instance => 'db8.example.internal:9100', job => 'node' } },
            alerts => [ { alertname => 'PlatteFastVoll', target => 'db7', summary => 'db7 /var 85%' }, { alertname => 'PlatteFastVoll', target => 'db8', summary => 'db8 /var 81%' } ] } } } };
    prepare($st);
    my $sh = sub { run_command( $st, 'am1', $_[0] ) };
    my $S = $st->{am1}{services}{'prometheus-alertmanager'};
    is( $S->{_routes}{dba}{repeat_interval}, '4h', 'Unterroute mit eigenem Wert' );
    is( $S->{_routes}{web}{repeat_interval}, '1h', 'Unterroute erbt' );
    is( $S->{_routes}{team}{group_wait}, '30s', 'Vorgabe von Alertmanager' );

    is( ( $sh->('date') )[0], 'Sat Oct 24 09:12:00 CEST 2026', 'date aus der Uhr' );
    is( ( $sh->('date -u +%Y-%m-%dT%H:%M:%SZ') )[0], '2026-10-24T07:12:00Z', 'date -u mit Format' );
    is( ( $sh->(q{date -u -d 'today 22:00' +%FT%TZ}) )[0], '2026-10-24T20:00:00Z', 'date -d heute 22:00 (Ortszeit) in UTC' );

    like( ( $sh->('amtool silence add instance=db7.example.internal:9100 --comment=x') )[0], qr/required flag --alertmanager\.url/, 'ohne URL' );
    like( ( $sh->('amtool silence add instance=db7.example.internal:9100 --alertmanager.url=http://localhost:9093') )[0], qr/comment required/, 'ohne Kommentar' );
    my ( $id, $ok ) = $sh->(q{amtool silence add 'instance=~db7.*' --start=2026-10-24T22:00:00+02:00 --end=2026-10-24T23:30:00+02:00 --comment='Wartung db7' --alertmanager.url=http://localhost:9093});
    ok( $ok, 'silence add' );
    my $x = $S->{silences}[0];
    is_deeply( [ @{$x}{qw( id starts ends state )}, $x->{covers} ], [ $id, '2026-10-24T20:00:00Z', '2026-10-24T21:30:00Z', 'pending', ['db7'] ], 'Zeiten in UTC, wartend, trifft db7' );
    like( ( $sh->('amtool alert query --alertmanager.url=http://localhost:9093') )[0], qr/db7 \/var 85%/, 'wartend: Alarm noch sichtbar' );
    $sh->('amtool silence add alertname=PlatteFastVoll instance=db8.example.internal:9100 -d 2h -c jetzt --alertmanager.url=http://localhost:9093');
    is( $S->{silences}[1]{state}, 'active', 'ohne Start: ab jetzt' );
    is( $S->{silences}[1]{ends}, '2026-10-24T09:12:00Z', 'Dauer 2h' );
    unlike( ( $sh->('amtool alert query --alertmanager.url=http://localhost:9093') )[0], qr/db8/, 'aktiv: Alarm weg' );
    $sh->("amtool silence expire $S->{silences}[1]{id} --alertmanager.url=http://localhost:9093");
    is( $S->{silences}[1]{state}, 'expired', 'expire' );
    like( ( $sh->('amtool silence query --alertmanager.url=http://localhost:9093') )[0], qr/instance=~db7\.\*/, 'query zeigt die wartende' );
}

done_testing;
