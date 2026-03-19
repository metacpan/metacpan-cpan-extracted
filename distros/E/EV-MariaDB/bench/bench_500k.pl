#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use EV;
use EV::MariaDB;

my $socket = $ENV{TEST_MARIADB_SOCKET};
my $host   = $ENV{TEST_MARIADB_HOST}   // ($socket ? 'localhost' : '127.0.0.1');
my $port   = $ENV{TEST_MARIADB_PORT}   // 3306;
my $user   = $ENV{TEST_MARIADB_USER}   // 'root';
my $pass   = $ENV{TEST_MARIADB_PASS}   // '';
my $db     = $ENV{TEST_MARIADB_DB}     // 'test';

my $N = $ENV{BENCH_N} || 500_000;
my $BATCH = $ENV{BENCH_BATCH} || 64;

sub fmt { sprintf "%d in %.3fs  (%.0f q/s, %.1f us/q)", $_[0], $_[1], $_[0]/$_[1], $_[1]/$_[0]*1e6 }

my $m;

sub ev_connect {
    $m = EV::MariaDB->new(
        host       => $host,
        port       => $port,
        user       => $user,
        password   => $pass,
        database   => $db,
        ($socket ? (unix_socket => $socket) : ()),
        on_connect => sub { EV::break },
        on_error   => sub { die "connect: $_[0]\n" },
    );
    EV::timer(5, 0, sub { die "connect timeout\n" });
    EV::run;
}

sub run_sequential {
    my ($label, $gen_sql) = @_;
    my $done = 0;
    my $t0 = time;
    my $run; $run = sub {
        $m->q($gen_sql->($done), sub {
            my ($res, $err) = @_;
            die "$label: $err" if $err;
            if (++$done >= $N) {
                printf "  %-40s %s\n", "$label:", fmt($N, time - $t0);
                EV::break;
                return;
            }
            my $idle; $idle = EV::idle(sub { undef $idle; $run->() });
        });
    };
    $run->();
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
}

sub run_pipeline {
    my ($label, $gen_sql) = @_;
    my $done = 0;
    my $queued = 0;
    my $t0 = time;
    my $fill; $fill = sub {
        while ($m->pending_count < $BATCH && $queued < $N) {
            $m->q($gen_sql->($queued), sub {
                my ($res, $err) = @_;
                die "$label: $err" if $err;
                $done++;
                if ($done >= $N) {
                    printf "  %-40s %s\n", "$label:", fmt($N, time - $t0);
                    EV::break;
                    return;
                }
                $fill->();
            });
            $queued++;
        }
    };
    $fill->();
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
}

sub run_prepared_sequential {
    my ($label, $sql, $gen_params) = @_;
    my $done = 0;
    my $t0;
    $m->prepare($sql, sub {
        my ($stmt, $err) = @_;
        die "prepare: $err" if $err;
        $t0 = time;
        my $run; $run = sub {
            $m->execute($stmt, $gen_params->($done), sub {
                my ($res, $err2) = @_;
                die "$label: $err2" if $err2;
                if (++$done >= $N) {
                    printf "  %-40s %s\n", "$label:", fmt($N, time - $t0);
                    $m->close_stmt($stmt, sub { EV::break });
                    return;
                }
                my $idle; $idle = EV::idle(sub { undef $idle; $run->() });
            });
        };
        $run->();
    });
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
}

ev_connect();
printf "server: %s, libmariadb: %s\n", $m->server_info, EV::MariaDB->lib_info;
printf "N = %d, batch = %d\n\n", $N, $BATCH;

# setup table
{
    my $setup_done = 0;
    $m->q("drop table if exists bench_t", sub {
        $m->q("create table bench_t (id int primary key, val varchar(64), counter int default 0)", sub {
            $setup_done = 1;
            EV::break;
        });
    });
    EV::timer(10, 0, sub { die "setup timeout\n" });
    EV::run;
}

# === select ===
printf "select (select 1+1):\n";
run_sequential("sequential", sub { "select 1+1" });
run_pipeline("pipeline(batch=$BATCH)", sub { "select 1+1" });
run_prepared_sequential("prepared sequential", "select ? + ?", sub { [1, 1] });
print "\n";

# === insert ===
printf "insert:\n";
$m->q("truncate table bench_t", sub { EV::break });
EV::timer(10, 0, sub { die "timeout\n" }); EV::run;

run_sequential("sequential", sub { "insert into bench_t(id,val) values($_[0],'v$_[0]')" });

$m->q("truncate table bench_t", sub { EV::break });
EV::timer(10, 0, sub { die "timeout\n" }); EV::run;

run_pipeline("pipeline(batch=$BATCH)", sub { "insert into bench_t(id,val) values($_[0],'v$_[0]')" });

$m->q("truncate table bench_t", sub { EV::break });
EV::timer(10, 0, sub { die "timeout\n" }); EV::run;

run_prepared_sequential("prepared sequential",
    "insert into bench_t(id,val) values(?,?)",
    sub { [$_[0], "v$_[0]"] });
print "\n";

# === upsert (insert ... on duplicate key update) ===
printf "upsert (insert on duplicate key update):\n";

# pre-fill table for upsert
$m->q("truncate table bench_t", sub { EV::break });
EV::timer(10, 0, sub { die "timeout\n" }); EV::run;
{
    my $done = 0;
    my $queued = 0;
    my $fill; $fill = sub {
        while ($m->pending_count < $BATCH && $queued < $N) {
            $m->q("insert into bench_t(id,val,counter) values($queued,'v$queued',0)", sub {
                $done++;
                if ($done >= $N) { EV::break; return }
                $fill->();
            });
            $queued++;
        }
    };
    $fill->();
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
}

run_sequential("sequential", sub {
    "insert into bench_t(id,val,counter) values($_[0],'u$_[0]',1) on duplicate key update val=values(val), counter=counter+1"
});

run_pipeline("pipeline(batch=$BATCH)", sub {
    "insert into bench_t(id,val,counter) values($_[0],'u$_[0]',1) on duplicate key update val=values(val), counter=counter+1"
});

run_prepared_sequential("prepared sequential",
    "insert into bench_t(id,val,counter) values(?,?,1) on duplicate key update val=values(val), counter=counter+1",
    sub { [$_[0], "u$_[0]"] });
print "\n";

# === select with where (point lookup) ===
printf "select point lookup (select * from bench_t where id=N):\n";
run_sequential("sequential", sub { "select * from bench_t where id=$_[0]" });
run_pipeline("pipeline(batch=$BATCH)", sub { "select * from bench_t where id=$_[0]" });
run_prepared_sequential("prepared sequential",
    "select * from bench_t where id=?",
    sub { [$_[0]] });
print "\n";

# cleanup
$m->q("drop table if exists bench_t", sub { EV::break });
EV::timer(10, 0, sub { die "timeout\n" }); EV::run;

$m->finish;
printf "done.\n";
