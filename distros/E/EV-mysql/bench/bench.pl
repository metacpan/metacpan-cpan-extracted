#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use EV;
use EV::mysql;
use DBI;

my $socket = $ENV{TEST_MYSQL_SOCKET};
my $host   = $ENV{TEST_MYSQL_HOST}   // ($socket ? 'localhost' : '127.0.0.1');
my $port   = $ENV{TEST_MYSQL_PORT}   // 3306;
my $user   = $ENV{TEST_MYSQL_USER}   // 'root';
my $pass   = $ENV{TEST_MYSQL_PASS}   // '';
my $db     = $ENV{TEST_MYSQL_DB}     // 'test';

my $N = $ENV{BENCH_N} || 10_000;

my $dsn = "dbi:MySQL:database=$db"
    . ($socket ? ";mysql_socket=$socket" : ";host=$host;port=$port");

sub fmt { sprintf "%d in %.3fs  (%.0f q/s, %.1f us/q)", $_[0], $_[1], $_[0]/$_[1], $_[1]/$_[0]*1e6 }

# --- EV::mysql ---

sub ev_connect {
    my $m;
    $m = EV::mysql->new(
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
    $m;
}

my $m = ev_connect();
my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1, PrintError => 0});

printf "server: %s, libmysql: %s\n", $m->server_info, EV::mysql->lib_info;
printf "DBD::MySQL %s, DBI %s\n", $DBD::MySQL::VERSION, $DBI::VERSION;
printf "N = %d\n\n", $N;

# 1) EV::mysql — simple query
{
    my $done = 0;
    my $t0 = time;
    my $run; $run = sub {
        $m->q("select 1", sub {
            if (++$done >= $N) {
                printf "%-36s %s\n", "EV::mysql query:", fmt($N, time - $t0);
                EV::break;
                return;
            }
            $run->();
        });
    };
    $run->();
    EV::timer(120, 0, sub { die "timeout\n" });
    EV::run;
}

# 2) DBD::MySQL — sync simple query
{
    my $sth = $dbh->prepare("select 1");
    my $t0 = time;
    for (1..$N) {
        $sth->execute;
        $sth->fetchall_arrayref;
    }
    printf "%-36s %s\n", "DBD::MySQL sync query:", fmt($N, time - $t0);
}

# 3) DBD::MySQL — async simple query via EV
{
    my $sth = $dbh->prepare("select 1", {mysql_async => 1});
    my $fd = $dbh->mysql_sockfd;
    my $done = 0;
    my $t0 = time;

    my $run; $run = sub {
        $sth->execute;
        my $w; $w = EV::io($fd, EV::READ, sub {
            undef $w;
            $sth->mysql_async_result;
            $sth->fetchall_arrayref;
            if (++$done >= $N) {
                printf "%-36s %s\n", "DBD::MySQL async+EV query:", fmt($N, time - $t0);
                EV::break;
                return;
            }
            $run->();
        });
    };
    $run->();
    EV::timer(120, 0, sub { die "timeout\n" });
    EV::run;
}

# 4) EV::mysql — prepared stmt execute
{
    my $done = 0;
    my $t0;
    $m->prepare("select ?", sub {
        my ($stmt, $err) = @_;
        die "prepare: $err\n" if $err;
        $t0 = time;
        my $run; $run = sub {
            $m->execute($stmt, [42], sub {
                if (++$done >= $N) {
                    printf "%-36s %s\n", "EV::mysql prepared:", fmt($N, time - $t0);
                    $m->close_stmt($stmt, sub { EV::break });
                    return;
                }
                $run->();
            });
        };
        $run->();
    });
    EV::timer(120, 0, sub { die "timeout\n" });
    EV::run;
}

# 5) DBD::MySQL — sync prepared stmt
{
    my $dbh2 = DBI->connect($dsn, $user, $pass,
        {RaiseError => 1, PrintError => 0, mysql_server_prepare => 1});
    my $sth = $dbh2->prepare("select ?");
    my $t0 = time;
    for (1..$N) {
        $sth->execute(42);
        $sth->fetchall_arrayref;
    }
    printf "%-36s %s\n", "DBD::MySQL sync prepared:", fmt($N, time - $t0);
    $dbh2->disconnect;
}

# 6) DBD::MySQL — async prepared stmt via EV
{
    my $dbh2 = DBI->connect($dsn, $user, $pass,
        {RaiseError => 1, PrintError => 0, mysql_server_prepare => 1});
    my $sth = $dbh2->prepare("select ?", {mysql_async => 1});
    my $fd = $dbh2->mysql_sockfd;
    my $done = 0;
    my $t0 = time;

    my $run; $run = sub {
        $sth->execute(42);
        my $w; $w = EV::io($fd, EV::READ, sub {
            undef $w;
            $sth->mysql_async_result;
            $sth->fetchall_arrayref;
            if (++$done >= $N) {
                printf "%-36s %s\n", "DBD::MySQL async+EV prepared:", fmt($N, time - $t0);
                EV::break;
                return;
            }
            $run->();
        });
    };
    $run->();
    EV::timer(120, 0, sub { die "timeout\n" });
    EV::run;
    $dbh2->disconnect;
}

# 7) EV::mysql — pipelined queries (queue all at once)
{
    my $done = 0;
    my $t0 = time;
    for my $i (1..$N) {
        $m->q("select 1", sub {
            if (++$done >= $N) {
                printf "%-36s %s\n", "EV::mysql pipelined:", fmt($N, time - $t0);
                EV::break;
            }
        });
    }
    EV::timer(120, 0, sub { die "timeout\n" });
    EV::run;
}

# 8) EV::mysql — pipelined batches (queue BATCH at a time)
{
    my $BATCH = $ENV{BENCH_BATCH} || 10;
    my $done = 0;
    my $t0 = time;
    my $fill; $fill = sub {
        while ($m->pending_count < $BATCH && $done + $m->pending_count < $N) {
            $m->q("select 1", sub {
                $done++;
                if ($done >= $N) {
                    printf "%-36s %s\n",
                        "EV::mysql pipeline(batch=$BATCH):", fmt($N, time - $t0);
                    EV::break;
                    return;
                }
                $fill->();
            });
        }
    };
    $fill->();
    EV::timer(120, 0, sub { die "timeout\n" });
    EV::run;
}

# 9) EV::Future — parallel sequential (series of N queries)
eval {
    require EV::Future;
    {
        my $t0 = time;
        my @tasks;
        for my $i (1..$N) {
            push @tasks, sub {
                my $done = shift;
                $m->q("select 1", sub { $done->() });
            };
        }
        EV::Future::series(\@tasks, sub {
            printf "%-36s %s\n", "EV::Future series:", fmt($N, time - $t0);
            EV::break;
        });
        EV::timer(120, 0, sub { die "timeout\n" });
        EV::run;
    }

    # 10) EV::Future — parallel_limit (N queries, limited concurrency)
    {
        my $LIMIT = $ENV{BENCH_BATCH} || 10;
        my $t0 = time;
        my @tasks;
        for my $i (1..$N) {
            push @tasks, sub {
                my $done = shift;
                $m->q("select 1", sub { $done->() });
            };
        }
        EV::Future::parallel_limit(\@tasks, $LIMIT, sub {
            printf "%-36s %s\n",
                "EV::Future parallel_limit($LIMIT):", fmt($N, time - $t0);
            EV::break;
        });
        EV::timer(120, 0, sub { die "timeout\n" });
        EV::run;
    }
};
if ($@ && $@ =~ /Can't locate/) {
    printf "EV::Future not available, skipping\n";
} elsif ($@) {
    die $@;
}

$m->finish;
$dbh->disconnect;
printf "\ndone.\n";
