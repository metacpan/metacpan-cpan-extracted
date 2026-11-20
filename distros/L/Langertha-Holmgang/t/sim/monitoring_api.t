#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command prepare clone );

# Die Abfrage-Schnittstellen von Prometheus und Alertmanager auf dem Linux-Simulator.
# Behauptet wird: /api/v1/targets nennt die Ziele der laufenden Konfiguration; ihre
# Gesundheit kommt aus scrape_health des Dienstes oder aus der Verbindungsprobe, und
# ein Ziel, das keins von beiden beurteilt, macht die Antwort zur Luecke.
# /api/v1/query beantwortet nur einen Selektor (optional time() - davor, ein Vergleich
# mit einer Zahl dahinter): up aus den Zielen, sonst nur Reihen aus metrics; was der
# Fall nicht nennt, ist eine Luecke. Alertmanager /api/v2/alerts, /silences und
# /receivers kommen aus alerts, silences und der laufenden Konfiguration.
# python3 -m json.tool formatiert JSON hinter einer Pipe wie das echte Modul.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $yml = "global:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: node\n    static_configs:\n      - targets: ['10.20.0.11:9100', '10.20.0.12:9100']\n"
    . "  - job_name: prometheus\n    static_configs:\n      - targets: ['localhost:9090']\n";
my $am = "route:\n  receiver: team\n  routes:\n    - matchers: ['team=\"db\"']\n      receiver: dba\nreceivers:\n  - name: team\n  - name: dba\n";
my $start = {
    mon => {
        type       => 'linux',
        clock      => 'Oct 24 09:12',
        interfaces => { eth0 => { addr => ['10.20.0.50/24'], state => 'UP' } },
        files      => {
            '/etc/prometheus/prometheus.yml'   => $yml,
            '/etc/default/prometheus'          => qq{ARGS=""\n},
            '/etc/prometheus/alertmanager.yml' => $am,
        },
        services => {
            prometheus => { active => JSON::MaybeXS::true(), exec => 'prometheus',
                config => [ '/etc/prometheus/prometheus.yml', '/etc/default/prometheus' ], config_main => '/etc/prometheus/prometheus.yml',
                config_check => 'prometheus', reload_config => ['/etc/prometheus/prometheus.yml'],
                scrape_health => { '10.20.0.11:9100' => 'up', '10.20.0.12:9100' => 'dial tcp 10.20.0.12:9100: connect: connection refused' },
                metrics => qq{# letzte Werte\nbackup_last_success_seconds{instance="10.20.0.77:9100",job="backup"} 1792700000\n} },
            'prometheus-alertmanager' => { active => JSON::MaybeXS::true(), exec => 'prometheus-alertmanager',
                config => ['/etc/prometheus/alertmanager.yml'], config_main => '/etc/prometheus/alertmanager.yml', config_check => 'alertmanager',
                alert_targets => { db7 => { instance => 'db7:9100', team => 'db' } },
                alerts => [ { alertname => 'PlatteVoll', target => 'db7', summary => 'Platte voll' } ] },
        },
    },
};

my $state;
sub fresh { $state = clone($start); prepare($state); sh('systemctl restart prometheus prometheus-alertmanager') }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'mon', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
sub js { my $o = sh( $_[0] ); JSON::MaybeXS->new->decode($o) }

# --- Prometheus: Ziele -------------------------------------------------------------
{
    fresh();
    my $t = js('wget -qO- http://localhost:9090/api/v1/targets')->{data}{activeTargets};
    is_deeply( [ map { "$_->{labels}{instance} $_->{health}" } @$t ],
        [ '10.20.0.11:9100 up', '10.20.0.12:9100 down', 'localhost:9090 up' ], 'Ziele: scrape_health und Probe (eigener Dienst lauscht)' );
    like( $t->[1]{lastError}, qr{\AGet "http://10\.20\.0\.12:9100/metrics": dial tcp .*connection refused\z}, '... lastError aus scrape_health' );
    is( $t->[0]{scrapeInterval}, '15s', '... Intervall aus global' );

    delete $state->{mon}{services}{prometheus}{scrape_health}{'10.20.0.12:9100'};
    my ( $o, $ok, $gap ) = sh('wget -qO- http://localhost:9090/api/v1/targets');
    ok( !$ok && defined $gap, 'ein Ziel, das niemand beurteilt: Luecke' );
}

# --- Prometheus: Abfragen ------------------------------------------------------------
{
    fresh();
    my $r = js('wget -qO- http://localhost:9090/api/v1/query?query=up')->{data};
    is( $r->{resultType}, 'vector', 'query: Vektor' );
    is_deeply( [ map { "$_->{metric}{instance}=$_->{value}[1]" } @{ $r->{result} } ], [ '10.20.0.11:9100=1', '10.20.0.12:9100=0', 'localhost:9090=1' ], 'up aus den Zielen' );
    $r = js(q{wget -qO- 'http://localhost:9090/api/v1/query?query=up{job="node"} == 0'})->{data}{result};
    is_deeply( [ map { $_->{metric}{instance} } @$r ], ['10.20.0.12:9100'], 'Selektor und Vergleich' );
    is( $r->[0]{metric}{__name__}, 'up', '... Vergleich ohne bool behaelt den Namen' );
    $r = js(q{wget -qO- 'http://localhost:9090/api/v1/query?query=up%7Bjob%3D~%22no.*%22%7D'})->{data}{result};
    is( scalar @$r, 2, 'URL-kodiert, Regex-Matcher' );
    $r = js('wget -qO- http://localhost:9090/api/v1/query?query=backup_last_success_seconds')->{data}{result};
    is( $r->[0]{value}[1], '1792700000', 'Reihe aus metrics' );
    $r = js(q{wget -qO- 'http://localhost:9090/api/v1/query?query=time() - backup_last_success_seconds'})->{data}{result};
    is( $r->[0]{value}[1], $r->[0]{value}[0] - 1792700000, 'time() - x: Alter' );
    ok( !exists $r->[0]{metric}{__name__}, '... ohne Namen' );
    is_deeply( js('wget -qO- http://localhost:9090/api/v1/query?query=ALERTS')->{data}{result}, [], 'ALERTS leer wie /api/v1/alerts' );
    for my $q ( 'node_load1', 'rate(up[5m])', 'sum(up)' ) {
        my ( $o, $ok, $gap ) = sh("wget -qO- 'http://localhost:9090/api/v1/query?query=$q'");
        ok( !$ok && defined $gap, "Luecke: $q" );
    }
    is( ( sh('wget -qO- http://localhost:9090/api/v1/query') )[0], 'ERROR 400: Bad Request.', 'ohne query: 400' );
}

# --- Alertmanager --------------------------------------------------------------------
{
    fresh();
    is_deeply( js('wget -qO- http://localhost:9093/api/v2/receivers'), [ { name => 'team' }, { name => 'dba' } ], 'receivers' );
    my $a = js('wget -qO- http://localhost:9093/api/v2/alerts');
    is( $a->[0]{labels}{alertname}, 'PlatteVoll', 'alerts: Labels' );
    is_deeply( $a->[0]{receivers}, [ { name => 'dba' } ], '... Empfaenger nach der Route' );
    is( $a->[0]{status}{state}, 'active', '... aktiv' );
    is_deeply( js('wget -qO- http://localhost:9093/api/v2/silences'), [], 'silences: leer' );
    sh(q{amtool silence add team=db --duration=2h --comment=Wartung --alertmanager.url=http://localhost:9093});
    my $s = js('wget -qO- http://localhost:9093/api/v2/silences');
    is( $s->[0]{status}{state}, 'active', 'silences: die neue' );
    is_deeply( $s->[0]{matchers}, [ { name => 'team', value => 'db', isRegex => JSON::MaybeXS::false(), isEqual => JSON::MaybeXS::true() } ], '... Matcher' );
    $a = js('wget -qO- http://localhost:9093/api/v2/alerts');
    is( $a->[0]{status}{state}, 'suppressed', 'alerts: stummgeschaltet' );
    is_deeply( $a->[0]{status}{silencedBy}, [ $s->[0]{id} ], '... von der Stummschaltung' );
    is_deeply( js('wget -qO- "http://localhost:9093/api/v2/alerts?silenced=false"'), [], '?silenced=false' );
}

# --- python3 -m json.tool --------------------------------------------------------------
{
    fresh();
    is( sh(q{echo '{"b": [1, {}], "a": "ä", "c": []}' | python3 -m json.tool}),
        qq({\n    "b": [\n        1,\n        {}\n    ],\n    "a": "\\u00e4",\n    "c": []\n}), 'json.tool: Reihenfolge, Einrueckung, ASCII' );
    is( sh(q{echo '{"b": 1, "a": "ä"}' | python3 -m json.tool --sort-keys --indent 2 --no-ensure-ascii}),
        qq({\n  "a": "ä",\n  "b": 1\n}), '... Optionen' );
    my ( $o, $ok ) = sh(q{echo -n '' | python3 -m json.tool});
    is( $o, 'Expecting value: line 1 column 1 (char 0)', 'leer: Fehler' );
    ok( !$ok, '... scheitert' );
    like( sh('wget -qO- http://localhost:9093/api/v2/receivers | python3 -m json.tool'), qr/\A\[\n    \{\n        "name": "team"\n    \},/, 'hinter wget' );
}

done_testing;
