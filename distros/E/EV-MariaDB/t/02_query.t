use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 10;
use EV;
use EV::MariaDB;

my $m;

sub with_mariadb {
    my ($cb) = @_;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# Test simple query
with_mariadb(sub {
    $m->query("select 1 as num, 'hello' as greeting", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'query: no error');
        is(ref $rows, 'ARRAY', 'query: got arrayref');
        is(scalar @$rows, 1, 'query: 1 row');
        is(scalar @{$rows->[0]}, 2, 'query: 2 columns');
        is($rows->[0][0], '1', 'query: value(0,0)');
        is($rows->[0][1], 'hello', 'query: value(0,1)');
        EV::break;
    });
});

# Test DML (no result set)
with_mariadb(sub {
    $m->query("select 1", sub {
        # discard, just warm up
        $m->query("do 1", sub {
            my ($affected, $err) = @_;
            ok(!$err, 'DML: no error');
            ok(defined $affected, 'DML: got affected rows');
            EV::break;
        });
    });
});

# Test multi-row result
with_mariadb(sub {
    $m->query("select 1 as a, 2 as b union all select 3, 4", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-row: no error');
        is_deeply($rows, [['1','2'],['3','4']], 'multi-row: correct values');
        EV::break;
    });
});
