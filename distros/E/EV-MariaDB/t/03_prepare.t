use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 7;
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

# prepare + execute
with_mariadb(sub {
    $m->prepare("select ? + ? as sum", sub {
        my ($stmt, $err) = @_;
        ok(!$err, 'prepare: no error');
        ok(defined $stmt, 'prepare: got stmt handle');

        $m->execute($stmt, [10, 20], sub {
            my ($rows, $err2) = @_;
            ok(!$err2, 'execute: no error');
            is($rows->[0][0], '30', 'execute: 10+20=30');

            $m->close_stmt($stmt, sub {
                my ($ok, $err3) = @_;
                ok(!$err3, 'close_stmt: no error');
                EV::break;
            });
        });
    });
});

# execute with null param
with_mariadb(sub {
    $m->prepare("select ? is null as isnull", sub {
        my ($stmt, $err) = @_;
        ok(!$err, 'prepare null test');

        $m->execute($stmt, [undef], sub {
            my ($rows, $err2) = @_;
            is($rows->[0][0], '1', 'null param: is null is 1');

            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});
