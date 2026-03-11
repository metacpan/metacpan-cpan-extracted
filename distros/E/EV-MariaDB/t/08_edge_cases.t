use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 8;
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

# Test 1-2: query initiated from inside ping callback
with_mariadb(sub {
    $m->ping(sub {
        my ($ok, $err) = @_;
        die "ping: $err" if $err;
        $m->q("select 42", sub {
            my ($rows, $err2) = @_;
            ok(!$err2, 'callback-initiated: query after ping no error');
            is($rows->[0][0], 42, 'callback-initiated: query after ping correct');
            EV::break;
        });
    });
});

# Test 3-5: reset_connection from inside query callback, then query after
with_mariadb(sub {
    $m->q("select 1", sub {
        my ($rows, $err) = @_;
        die "query: $err" if $err;
        $m->reset_connection(sub {
            my ($ok, $err2) = @_;
            ok(!$err2, 'callback-initiated: reset_connection after query no error');
            $m->q("select 99", sub {
                my ($rows2, $err3) = @_;
                ok(!$err3, 'callback-initiated: query after reset no error');
                is($rows2->[0][0], 99, 'callback-initiated: query after reset correct');
                EV::break;
            });
        });
    });
});

# Test 6-7: finish() cancels pending queries synchronously
with_mariadb(sub {
    my @results;
    for my $i (1..3) {
        $m->q("select $i", sub {
            my ($rows, $err) = @_;
            push @results, $err ? 'err' : 'ok';
        });
    }
    $m->finish;
    is(scalar @results, 3, 'finish: all 3 callbacks fired');
    is(scalar(grep { $_ eq 'err' } @results), 3, 'finish: all got errors');
    EV::break;
});

# Test 8: sequential chain: query -> ping -> query
with_mariadb(sub {
    my @order;
    $m->q("select 'first'", sub {
        my ($rows, $err) = @_;
        die "first: $err" if $err;
        push @order, $rows->[0][0];
        $m->ping(sub {
            my ($ok, $err2) = @_;
            die "ping: $err2" if $err2;
            push @order, 'ping';
            $m->q("select 'last'", sub {
                my ($rows2, $err3) = @_;
                die "last: $err3" if $err3;
                push @order, $rows2->[0][0];
                is_deeply(\@order, ['first', 'ping', 'last'],
                    'sequential chain: correct order');
                EV::break;
            });
        });
    });
});
