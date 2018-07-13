#!/usr/bin/perl

use strict;
use warnings;


use Const::Fast;
use JSON::MaybeXS;
use File::Spec;
use File::Basename;
use File::Temp;
use File::Slurper qw(write_text);
use IPC::Run qw(run);
use Test::More;

BEGIN {
    sub get_directory_of_this_file {
        my (undef, $filename) = caller;
        return dirname(File::Spec->rel2abs( $filename ));
    }

    use lib get_directory_of_this_file() . '/../lib/';
}

const my $PORT          => 17755;
const my $TMPDIR_HANDLE => File::Temp->newdir(CLEANUP => 1);
const my $TMPDIR        => $TMPDIR_HANDLE->dirname();

const my $TIME     => time();
const my $DATABASE => "test_$TIME";
const my $FIELD    => 'f1';
const my $TAGS     => 'server=zrh01';
const my $VALUE    => 123;

const my $M_NAME => 'm_test';
const my $M_BASE => "$M_NAME,$TAGS";

const my $M_OK         => $M_BASE.' '.$FIELD.'='.$VALUE;
const my $M_BAD_TYPE   => $M_BASE.' '.$FIELD.'="bad"';
const my $M_BAD_FORMAT => $M_BASE.$FIELD.'=bad';

const my $Q_OK => "SELECT LAST($FIELD) FROM $DATABASE.\"autogen\".$M_NAME";

sub main {

    my $influx_pid = setup_influx();

    eval {
        require_ok( 'InfluxDB::HTTP' );
        my $influx = InfluxDB::HTTP->new(port => $PORT);
        setup($influx);

        test_ping($influx);
        test_write($influx);
        test_query($influx);

        cleanup($influx);
        done_testing();
    };
    diag($@) if $@;
    cleanup_influx($influx_pid);

    return;
}

sub setup_influx {


    my $conf = get_test_conf();
    write_text("$TMPDIR/influx.conf", $conf);

    # check if influxd is found before forking
    eval {
        my $out_and_err;
        run(['influxd', 'version'], '>&', \$out_and_err);
    };
    plan(skip_all => $@) if $@;

    my $pid;
    defined($pid = fork()) or die "unable to fork: $!\n";
    if ($pid == 0) {
        exec("influxd -config $TMPDIR/influx.conf");
        warn "unable to exec 'influxd -config $TMPDIR/influx.conf': $!\n";
        exit 1;
    }
    sleep 1; # wait for influxdb to start

    return $pid;
}

sub cleanup_influx {
    my $pid = shift;
    kill 'KILL', $pid;
    return;
}


sub setup {
    my $influx = shift;

    my $rv = $influx->query("CREATE DATABASE $DATABASE");
    ok($rv, 'CREATE DATABASE');

    return;
}

sub cleanup {
    my $influx = shift;

    my $rv = $influx->query("DROP DATABASE $DATABASE");
    ok($rv, 'DROP DATABASE');

    return;
}

sub test_ping {
    my $influx = shift;

    my $ping = $influx->ping();
    ok($ping, 'ping');

    return;
}

sub test_write {
    my $influx = shift;

    my $rv;

    $rv = $influx->write($M_OK, database => $DATABASE, precision => 's');
    ok($rv, 'successful write');

    $rv = $influx->write($M_BAD_FORMAT, database => $DATABASE, precision => 's');
    ok(!$rv, 'write with bad format');

    $rv = $influx->write($M_BAD_TYPE, database => $DATABASE, precision => 's');
    ok(!$rv, 'write with bad data type');

    return;
}

sub test_query {
    my $influx = shift;

    my $rv = $influx->query($Q_OK, epoch => 's');
    ok($rv, 'query');
    # [{"series":[{"values":[[1530794448,123]],"columns":["time","last"],"name":"m_test"}],"statement_id":0}]
    is($rv->data()->{results}->[0]->{series}->[0]->{values}->[0]->[1], $VALUE, 'query result');

    return;
}

# ------------------------------------------------------------------------------

sub get_test_conf {
    return <<"END";
reporting-disabled = true

[logging]
  level = "warn"
  suppress-logo = true

[meta]
  dir = "$TMPDIR/meta"
  retention-autocreate = true
  logging-enabled = true

[data]
  dir = "$TMPDIR/data"
  engine = "tsm1"
  wal-dir = "$TMPDIR/wal"
  wal-logging-enabled = true
  query-log-enabled = true
  cache-max-memory-size = 0
  max-points-per-block = 0
  max-series-per-database = 0
  max-values-per-tag = 0
  data-logging-enabled = true
  index-version = "tsi1"

[coordinator]
  write-timeout = "10s"
  max-concurrent-queries = 0
  query-timeout = "0s"
  log-queries-after = "0s"
  max-select-point = 0
  max-select-series = 0
  max-select-buckets = 0

[retention]
  enabled = true
  check-interval = "30m0s"

[shard-precreation]
  enabled = true
  check-interval = "10m0s"
  advance-period = "30m0s"

[admin]
  enabled = false

[monitor]
  store-enabled = true
  store-database = "_internal"
  store-interval = "10s"

[subscriber]
  enabled = true
  http-timeout = "30s"

[http]
  enabled = true
  bind-address = ":$PORT"
  auth-enabled = false
  log-enabled = false
  write-tracing = false
  https-enabled = false
  max-row-limit = 0
  max-connection-limit = 0
  shared-secret = ""
  realm = "InfluxDB"

[[graphite]]
  enabled = false

[[collectd]]
  enabled = false

[[opentsdb]]
  enabled = false

[[udp]]
  enabled = false

[continuous_queries]
  log-enabled = true
  enabled = true
  run-interval = "1s"
  query-stats-enabled = true
END
}

# ------------------------------------------------------------------------------


main;
