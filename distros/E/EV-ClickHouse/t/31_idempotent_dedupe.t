#!/usr/bin/env perl
# Idempotent INSERT silent-dedupe contract requires a ReplicatedMergeTree
# table backed by a Keeper. A non-replicated table just runs INSERTs and
# the deduplication_token does nothing. We spin up a single-shard
# CH + Keeper bundle in podman, exercise the contract end-to-end, and
# tear it all down.
#
# Activate with TEST_PODMAN_CLUSTER=1 (the test silently skips otherwise
# because pulling the CH image is multi-hundred-MB and takes minutes).
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp ();
use EV;
use EV::ClickHouse;

plan skip_all => "set TEST_PODMAN_CLUSTER=1 to opt into podman-backed test"
    unless $ENV{TEST_PODMAN_CLUSTER};

chomp(my $podman = `which podman 2>/dev/null`);
plan skip_all => "podman not in PATH" unless $podman;

# Choose ports unlikely to collide with a real CH instance.
my $http_port = 28123;
my $tcp_port  = 29000;
my $kpr_port  = 29181;
my $cname     = "ev_ch_dedupe_$$";
my $kname     = "ev_ch_keeper_$$";

# ClickHouse Keeper + CH server, single-node-replicated. Keeper config
# is embedded in the CH config via `<keeper_server>` (CH-bundled Keeper)
# so we only need one container.
my $cfg_dir = File::Temp::tempdir(CLEANUP => 1);
open my $fh, '>', "$cfg_dir/config.xml" or die "open config: $!";
print $fh <<XML;
<?xml version="1.0"?>
<clickhouse>
  <logger><level>warning</level><console>1</console></logger>
  <http_port>8123</http_port>
  <tcp_port>9000</tcp_port>
  <listen_host>0.0.0.0</listen_host>
  <path>/var/lib/clickhouse/</path>
  <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
  <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>
  <format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>
  <users_config>users.xml</users_config>
  <default_profile>default</default_profile>
  <default_database>default</default_database>
  <mark_cache_size>67108864</mark_cache_size>

  <keeper_server>
    <tcp_port>9181</tcp_port>
    <server_id>1</server_id>
    <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
    <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>
    <coordination_settings>
      <operation_timeout_ms>10000</operation_timeout_ms>
      <session_timeout_ms>30000</session_timeout_ms>
      <raft_logs_level>warning</raft_logs_level>
    </coordination_settings>
    <raft_configuration>
      <server>
        <id>1</id><hostname>localhost</hostname><port>9234</port>
      </server>
    </raft_configuration>
  </keeper_server>

  <zookeeper>
    <node><host>localhost</host><port>9181</port></node>
  </zookeeper>

  <macros>
    <shard>01</shard>
    <replica>r1</replica>
  </macros>
</clickhouse>
XML
close $fh;

open my $uh, '>', "$cfg_dir/users.xml" or die "open users: $!";
print $uh <<XML;
<?xml version="1.0"?>
<clickhouse>
  <profiles><default><max_memory_usage>10000000000</max_memory_usage></default></profiles>
  <users>
    <default>
      <password></password>
      <networks><ip>::/0</ip></networks>
      <profile>default</profile>
      <quota>default</quota>
    </default>
  </users>
  <quotas><default><interval><duration>3600</duration></interval></default></quotas>
</clickhouse>
XML
close $uh;

# Wipe any previous instance.
system("$podman rm -f $cname 2>/dev/null");

# Spin up the container. Use the official image — readers running the test
# should already have it cached.
my $run = "$podman run -d --rm --name $cname".
          " -p $http_port:8123 -p $tcp_port:9000 -p $kpr_port:9181".
          " -v $cfg_dir/config.xml:/etc/clickhouse-server/config.d/config.xml:Z".
          " -v $cfg_dir/users.xml:/etc/clickhouse-server/users.d/users.xml:Z".
          " --ulimit nofile=262144:262144".
          " clickhouse/clickhouse-server:latest 2>&1";
my $out = `$run`;
chomp $out;
if ($? != 0) {
    plan skip_all => "podman run failed: $out";
}

# Wait until both Keeper and CH respond, up to 60s.
my $deadline = time + 60;
my $ready;
while (time < $deadline) {
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $tcp_port, Timeout => 1);
    if ($s) { $s->close; $ready = 1; last }
    sleep 1;
}
unless ($ready) {
    diag(`$podman logs $cname 2>&1`);
    system("$podman rm -f $cname >/dev/null 2>&1");
    plan skip_all => "ClickHouse never became reachable inside container";
}

# Extra grace for Keeper init — DDL on Replicated* fails until Keeper is
# done initialising.
sleep 3;

plan tests => 4;

my $tbl = "ev_ch_idem";
my $ddl = <<"SQL";
create table if not exists $tbl (n UInt32)
engine = ReplicatedMergeTree('/clickhouse/tables/{shard}/$tbl', '{replica}')
order by n
settings non_replicated_deduplication_window = 0
SQL

my @stage_err;
my $rounds_done = 0;
my $count_after_dup;
my $count_after_distinct;

my $ch; $ch = EV::ClickHouse->new(
    host => '127.0.0.1', port => $tcp_port, protocol => 'native',
    connect_timeout => 10,
    on_connect => sub {
        $ch->query("drop table if exists $tbl sync", sub {
            my (undef, $err) = @_;
            push @stage_err, "drop: $err" if $err;
            $ch->query($ddl, sub {
                my (undef, $err) = @_;
                push @stage_err, "ddl: $err" if $err;

                # Same token → second insert silently deduplicated.
                $ch->insert($tbl, [[1],[2],[3]],
                            { insert_deduplication_token => 'tok-A' }, sub {
                    my (undef, $err) = @_;
                    push @stage_err, "ins1: $err" if $err;
                    $ch->insert($tbl, [[4],[5],[6]],
                                { insert_deduplication_token => 'tok-A' }, sub {
                        my (undef, $err) = @_;
                        push @stage_err, "ins2: $err" if $err;
                        $ch->query("select count() from $tbl", sub {
                            my ($rows, $err) = @_;
                            push @stage_err, "cnt1: $err" if $err;
                            $count_after_dup = $rows ? $rows->[0][0] : undef;

                            # Distinct token → insert proceeds.
                            $ch->insert($tbl, [[7],[8],[9]],
                                        { insert_deduplication_token => 'tok-B' }, sub {
                                my (undef, $err) = @_;
                                push @stage_err, "ins3: $err" if $err;
                                $ch->query("select count() from $tbl", sub {
                                    my ($rows, $err) = @_;
                                    push @stage_err, "cnt2: $err" if $err;
                                    $count_after_distinct = $rows ? $rows->[0][0] : undef;
                                    $rounds_done = 1;
                                    EV::break;
                                });
                            });
                        });
                    });
                });
            });
        });
    },
    on_error => sub { push @stage_err, "conn: $_[0]"; EV::break },
);

my $bail = EV::timer(45, 0, sub { EV::break });
EV::run;
undef $bail;
eval { $ch->finish };

ok $rounds_done,                            'reached final stage';
is "@stage_err", '',                        'no per-stage errors';
is $count_after_dup,      3,                'duplicate token did not insert again';
is $count_after_distinct, 6,                'distinct token inserted a fresh batch';

# Always clean up the container, even on test failure.
system("$podman rm -f $cname >/dev/null 2>&1");
