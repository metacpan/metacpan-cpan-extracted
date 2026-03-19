#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use EV;
use EV::MariaDB;
use DBI;

my $socket = $ENV{TEST_MARIADB_SOCKET};
my $host   = $ENV{TEST_MARIADB_HOST}   // ($socket ? 'localhost' : '127.0.0.1');
my $port   = $ENV{TEST_MARIADB_PORT}   // 3306;
my $user   = $ENV{TEST_MARIADB_USER}   // 'root';
my $pass   = $ENV{TEST_MARIADB_PASS}   // '';
my $db     = $ENV{TEST_MARIADB_DB}     // 'test';

my $N = $ENV{BENCH_N} || 500_000;
my $BATCH = $ENV{BENCH_BATCH} || 64;

my $dsn = "dbi:MariaDB:database=$db"
    . ($socket ? ";mariadb_socket=$socket" : ";host=$host;port=$port");

sub fmt { sprintf "%d in %.3fs  (%.0f q/s, %.1f us/q)", $_[0], $_[1], $_[0]/$_[1], $_[1]/$_[0]*1e6 }

my $heap_size = '512*1024*1024';

my $m = do {
    my $obj;
    $obj = EV::MariaDB->new(
        host       => $host,
        port       => $port,
        user       => $user,
        password   => $pass,
        database   => $db,
        ($socket ? (unix_socket => $socket) : ()),
        init_command => "set max_heap_table_size = $heap_size, tmp_table_size = $heap_size",
        on_connect => sub { EV::break },
        on_error   => sub { die "connect: $_[0]\n" },
    );
    EV::timer(5, 0, sub { die "connect timeout\n" });
    EV::run;
    $obj;
};

my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1, PrintError => 0});
$dbh->do("set max_heap_table_size = $heap_size, tmp_table_size = $heap_size");
my $dbh_prep = DBI->connect($dsn, $user, $pass,
    {RaiseError => 1, PrintError => 0, mariadb_server_prepare => 1});
$dbh_prep->do("set max_heap_table_size = $heap_size, tmp_table_size = $heap_size");

printf "server: %s, libmariadb: %s\n", $m->server_info, EV::MariaDB->lib_info;
printf "DBD::MariaDB %s, DBI %s\n", $DBD::MariaDB::VERSION, $DBI::VERSION;
printf "N = %d, pipeline batch = %d, engine = memory (no disk I/O)\n\n", $N, $BATCH;

# --- helpers (trampoline via EV::idle to avoid deep recursion on sync completion) ---

sub ev_sequential {
    my ($label, $gen_sql) = @_;
    my $done = 0;
    my $t0 = time;
    my $run; $run = sub {
        $m->q($gen_sql->($done), sub {
            die "$label: $_[1]" if $_[1];
            if (++$done >= $N) {
                printf "  %-44s %s\n", $label, fmt($N, time - $t0);
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

sub ev_pipeline {
    my ($label, $gen_sql) = @_;
    my $done = 0;
    my $queued = 0;
    my $t0 = time;
    my $fill; $fill = sub {
        while ($m->pending_count < $BATCH && $queued < $N) {
            my $i = $queued++;
            $m->q($gen_sql->($i), sub {
                die "$label: $_[1]" if $_[1];
                $done++;
                if ($done >= $N) {
                    printf "  %-44s %s\n", $label, fmt($N, time - $t0);
                    EV::break;
                    return;
                }
                $fill->();
            });
        }
    };
    $fill->();
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
}

sub ev_prepared {
    my ($label, $sql, $gen_params) = @_;
    my $done = 0;
    my $t0;
    $m->prepare($sql, sub {
        my ($stmt, $err) = @_;
        die "prepare: $err" if $err;
        $t0 = time;
        my $run; $run = sub {
            $m->execute($stmt, $gen_params->($done), sub {
                die "$label: $_[1]" if $_[1];
                if (++$done >= $N) {
                    printf "  %-44s %s\n", $label, fmt($N, time - $t0);
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

sub dbd_sync_reuse {
    my ($label, $sth, $gen_bind, %opt) = @_;
    my $is_select = !$opt{dml};
    my $t0 = time;
    for my $i (0..$N-1) {
        my $params = $gen_bind->($i);
        $sth->execute(@$params);
        $sth->fetchall_arrayref if $is_select;
    }
    printf "  %-44s %s\n", $label, fmt($N, time - $t0);
}

sub dbd_sync_prepared {
    my ($label, $sql, $gen_bind, %opt) = @_;
    my $is_select = !$opt{dml};
    my $sth = $dbh_prep->prepare($sql);
    my $t0 = time;
    for my $i (0..$N-1) {
        my $params = $gen_bind->($i);
        $sth->execute(@$params);
        $sth->fetchall_arrayref if $is_select;
    }
    printf "  %-44s %s\n", $label, fmt($N, time - $t0);
}

sub dbd_async_ev_reuse {
    my ($label, $sth, $gen_bind, %opt) = @_;
    my $is_select = !$opt{dml};
    my $fd = $dbh->mariadb_sockfd;
    my $done = 0;
    my $t0 = time;
    my $run; $run = sub {
        my $params = $gen_bind->($done);
        $sth->execute(@$params);
        my $w; $w = EV::io($fd, EV::READ, sub {
            undef $w;
            $sth->mariadb_async_result;
            $sth->fetchall_arrayref if $is_select;
            if (++$done >= $N) {
                printf "  %-44s %s\n", $label, fmt($N, time - $t0);
                EV::break;
                return;
            }
            $run->();
        });
    };
    $run->();
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
}

# ========== setup ==========
$dbh->do("drop table if exists bench_t");
$dbh->do("create table bench_t (id int primary key, val varchar(64), counter int default 0) engine=MEMORY");

# ========== select ==========
printf "=== select (select 1+1) ===\n";
{
    my $sql = sub { "select 1+1" };
    ev_sequential("EV::MariaDB sequential", $sql);
    ev_pipeline("EV::MariaDB pipeline($BATCH)", $sql);
    ev_prepared("EV::MariaDB prepared", "select ? + ?", sub { [1, 1] });
    dbd_sync_reuse("DBD::MariaDB sync", $dbh->prepare("select 1+1"), sub { [] });
    dbd_async_ev_reuse("DBD::MariaDB async+EV",
        $dbh->prepare("select 1+1", {mariadb_async => 1}), sub { [] });
    dbd_sync_prepared("DBD::MariaDB sync prepared", "select ? + ?", sub { [1, 1] });
}
print "\n";

# ========== insert ==========
printf "=== insert (engine=memory) ===\n";
{
    my $sql = sub { "insert into bench_t(id,val) values($_[0],'v$_[0]')" };

    $dbh->do("truncate table bench_t");
    ev_sequential("EV::MariaDB sequential", $sql);

    $dbh->do("truncate table bench_t");
    ev_pipeline("EV::MariaDB pipeline($BATCH)", $sql);

    $dbh->do("truncate table bench_t");
    ev_prepared("EV::MariaDB prepared",
        "insert into bench_t(id,val) values(?,?)",
        sub { [$_[0], "v$_[0]"] });

    $dbh->do("truncate table bench_t");
    {
        my $sth = $dbh->prepare("insert into bench_t(id,val) values(?,?)");
        my $t0 = time;
        for my $i (0..$N-1) { $sth->execute($i, "v$i") }
        printf "  %-44s %s\n", "DBD::MariaDB sync", fmt($N, time - $t0);
    }

    $dbh->do("truncate table bench_t");
    {
        my $sth = $dbh->prepare("insert into bench_t(id,val) values(?,?)", {mariadb_async => 1});
        dbd_async_ev_reuse("DBD::MariaDB async+EV", $sth, sub { [$_[0], "v$_[0]"] }, dml => 1);
    }

    $dbh->do("truncate table bench_t");
    dbd_sync_prepared("DBD::MariaDB sync prepared",
        "insert into bench_t(id,val) values(?,?)",
        sub { [$_[0], "v$_[0]"] }, dml => 1);
}
print "\n";

# ========== pre-fill for upsert + lookup ==========
$dbh->do("truncate table bench_t");
{
    my $done = 0;
    my $queued = 0;
    my $fill; $fill = sub {
        while ($m->pending_count < $BATCH && $queued < $N) {
            my $i = $queued++;
            $m->q("insert into bench_t(id,val,counter) values($i,'v$i',0)", sub {
                die "prefill: $_[1]" if $_[1];
                $done++;
                if ($done >= $N) { EV::break; return }
                $fill->();
            });
        }
    };
    $fill->();
    EV::timer(600, 0, sub { die "timeout\n" });
    EV::run;
    printf "pre-filled %d rows\n\n", $N;
}

# ========== upsert ==========
printf "=== upsert (engine=memory) ===\n";
{
    my $upsert_sql = sub {
        "insert into bench_t(id,val,counter) values($_[0],'u$_[0]',1) on duplicate key update val=values(val), counter=counter+1"
    };
    ev_sequential("EV::MariaDB sequential", $upsert_sql);
    ev_pipeline("EV::MariaDB pipeline($BATCH)", $upsert_sql);
    ev_prepared("EV::MariaDB prepared",
        "insert into bench_t(id,val,counter) values(?,?,1) on duplicate key update val=values(val), counter=counter+1",
        sub { [$_[0], "u$_[0]"] });

    {
        my $sth = $dbh->prepare(
            "insert into bench_t(id,val,counter) values(?,?,1) on duplicate key update val=values(val), counter=counter+1");
        my $t0 = time;
        for my $i (0..$N-1) { $sth->execute($i, "u$i") }
        printf "  %-44s %s\n", "DBD::MariaDB sync", fmt($N, time - $t0);
    }

    {
        my $sth = $dbh->prepare(
            "insert into bench_t(id,val,counter) values(?,?,1) on duplicate key update val=values(val), counter=counter+1",
            {mariadb_async => 1});
        dbd_async_ev_reuse("DBD::MariaDB async+EV", $sth, sub { [$_[0], "u$_[0]"] }, dml => 1);
    }

    dbd_sync_prepared("DBD::MariaDB sync prepared",
        "insert into bench_t(id,val,counter) values(?,?,1) on duplicate key update val=values(val), counter=counter+1",
        sub { [$_[0], "u$_[0]"] }, dml => 1);
}
print "\n";

# ========== select point lookup ==========
printf "=== select point lookup (engine=memory, hash index) ===\n";
{
    my $sql = sub { "select * from bench_t where id=$_[0]" };
    ev_sequential("EV::MariaDB sequential", $sql);
    ev_pipeline("EV::MariaDB pipeline($BATCH)", $sql);
    ev_prepared("EV::MariaDB prepared",
        "select * from bench_t where id=?", sub { [$_[0]] });
    dbd_sync_reuse("DBD::MariaDB sync",
        $dbh->prepare("select * from bench_t where id=?"), sub { [$_[0]] });
    dbd_async_ev_reuse("DBD::MariaDB async+EV",
        $dbh->prepare("select * from bench_t where id=?", {mariadb_async => 1}), sub { [$_[0]] });
    dbd_sync_prepared("DBD::MariaDB sync prepared",
        "select * from bench_t where id=?", sub { [$_[0]] });
}
print "\n";

# cleanup
$dbh->do("drop table if exists bench_t");
$m->finish;
$dbh->disconnect;
$dbh_prep->disconnect;
printf "done.\n";
