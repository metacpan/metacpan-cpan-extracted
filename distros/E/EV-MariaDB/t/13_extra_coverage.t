use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 17;
use EV;
use EV::MariaDB;

my $m;

sub with_mariadb {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
        %args,
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# --- Test 1-2: die inside query callback is caught and warned ---
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    with_mariadb(cb => sub {
        $m->q("select 1", sub {
            die "intentional test exception";
        });
        $m->q("select 2", sub {
            my ($rows, $err) = @_;
            ok(scalar(grep { /intentional test exception/ } @warnings),
               'die in callback: caught as warning');
            ok(!$err && $rows->[0][0] == 2,
               'die in callback: subsequent query still works');
            EV::break;
        });
    });
}

# --- Test 3-4: warning_count > 0 ---
with_mariadb(cb => sub {
    $m->q("select cast('abc' as signed)", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'warning_count: query ok');
        cmp_ok($m->warning_count, '>', 0,
               'warning_count: >0 after truncation warning');
        EV::break;
    });
});

# --- Test 5-6: info accessor with non-NULL return ---
with_mariadb(cb => sub {
    $m->q("create temporary table _test_info (id int)", sub {
        die $_[1] if $_[1];
        $m->q("insert into _test_info values (1),(2),(3)", sub {
            my ($affected, $err) = @_;
            ok(!$err, 'info accessor: insert ok');
            my $info = $m->info;
            ok(defined $info && $info =~ /Records/i,
               'info accessor: returns non-NULL after multi-row insert');
            EV::break;
        });
    });
});

# --- Test 7: new() with unknown argument ---
{
    eval { EV::MariaDB->new(on_error => sub {}, bogus_key => 1) };
    like($@, qr/unknown argument/, 'new: unknown argument croaks');
}

# --- Test 8: db alias for database in new() ---
{
    my $obj;
    $obj = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        database => undef,
        db       => $TestMariaDB::db,
        on_connect => sub {
            $obj->q("select database()", sub {
                my ($rows, $err) = @_;
                ok(!$err && lc($rows->[0][0]) eq lc($TestMariaDB::db),
                   'db alias: connects to correct database');
                EV::break;
            });
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $obj->finish if $obj && $obj->is_connected;
}

# --- Test 9-10: execute() with zero parameters ---
with_mariadb(cb => sub {
    $m->prepare("select 1", sub {
        my ($stmt, $err) = @_;
        ok(!$err, 'execute 0 params: prepare ok');
        $m->execute($stmt, [], sub {
            my ($rows, $err2) = @_;
            ok(!$err2 && $rows->[0][0] == 1,
               'execute 0 params: returns correct result');
            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});

# --- Test 11-12: change_user error path ---
with_mariadb(cb => sub {
    $m->change_user("nonexistent_user_xyzzy_$$", "badpass", undef, sub {
        my ($ok, $err) = @_;
        ok($err, 'change_user error: got error for bad user');
        ok(!defined $ok, 'change_user error: result is undef');
        EV::break;
    });
});

# --- Test 13: die inside on_connect handler is caught as warning ---
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            die "intentional on_connect exception";
        },
        on_error => sub { },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok(scalar(grep { /intentional on_connect exception/ } @warnings),
       'die in on_connect: caught as warning');
    $m->finish if $m && $m->is_connected;
}

# --- Test 14: die inside on_error handler is caught as warning ---
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    # Connect with bad credentials to trigger on_error (connection-level error)
    $m = EV::MariaDB->new(
        host     => $TestMariaDB::host,
        port     => $TestMariaDB::port,
        ($TestMariaDB::socket ? (unix_socket => $TestMariaDB::socket) : ()),
        user     => "nonexistent_user_xyzzy_$$",
        password => "badpass",
        on_error => sub {
            die "intentional on_error exception";
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok(scalar(grep { /intentional on_error exception/ } @warnings),
       'die in on_error: caught as warning');
}

# --- Test 15: handler setter with non-CODE value silently ignores ---
{
    my $obj = EV::MariaDB->new(on_error => sub { "test" });
    $obj->on_error("not a coderef");
    ok(!defined $obj->on_error,
       'handler setter: non-CODE value clears handler');
}

# --- Test 16: handler setter with non-CODE (on_connect) ---
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    $obj->on_connect(sub { 1 });
    ok(defined $obj->on_connect, 'handler setter: CODE ref sets ok');
    $obj->on_connect(42);
    ok(!defined $obj->on_connect,
       'handler setter: non-CODE value clears on_connect');
}
