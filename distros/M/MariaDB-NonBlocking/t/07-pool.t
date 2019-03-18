#!perl
use v5.18.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use AnyEvent::XSPromises qw/collect/;
use MariaDB::NonBlocking::Promises::Pool;
use Data::Dumper;
AnyEvent::detect();

use lib 't', '.';
require 'lib.pl';

sub wait_for_promise ($) {
    my $p = shift;
    my $cv = AnyEvent->condvar;
    $p->then(
        sub { $cv->send($_[0]); },
        sub { $cv->croak($_[0]); },
    );
    $cv->recv;
}

my $connect_args = {
    user     => $::test_user,
    host     => '127.0.0.1',
    password => $::test_password || '',
};

package Pool {
    use parent 'MariaDB::NonBlocking::Promises::Pool';
    sub _get_connection_args { return $connect_args }
}

my $pool = Pool->new({database => 'foo'});
my $query1 = $pool->run_query("SELECT 1")->then(sub {
    my ($res) = @_;
    is_deeply($res, [{1=>1}], "pool works!");
    return $pool->run_query("SELECT 3");
});
my $query2 = $pool->run_query("SELECT 2");

wait_for_promise collect($query1, $query2)->then(sub {
    is_deeply(\@_, [[[{3=>3}]],[[{2=>2}]]], "scheduling multiple queries works") or diag(Dumper(\@_));
})->catch(\&fail);

my $p1 = $pool->run_query("SELECT 1")->then(sub {
    return collect(map $pool->run_query("SELECT $_, SLEEP(RAND(2))", {want_hashrefs => 0}), 1..20)->then(sub {
        my $expect = [ map +[[[$_, 0]]], 1..20 ];
        is_deeply(\@_, $expect, "partially started and then resumed works") or diag(Dumper(\@_));
    })->catch(\&fail);
})->catch(\&fail);

my $pool2 = Pool->new({database => 'bar'});
wait_for_promise $pool2->run_query("SELECT 99, SLEEP(2)", {want_hashrefs => 0})->then(sub {
    is_deeply($_[0], [[99, 0]], "second pool works") or diag(Dumper($_[0]));
})->catch(\&fail);

wait_for_promise $pool2->run_query('ermvsp 22')->then(\&fail)->catch(sub {
    my ($e) = @_;
    like($e, qr/You have an error/, "failing a query works");
    $pool2->run_query('select 66')->then(sub {
        is_deeply($_[0], [{66=>66}], "pool 2 still usable after a failed query");
    })->catch(\&fail);
});

wait_for_promise $p1;

my $p2 = $pool2->run_query("select 1, sleep(4)")->then(\&fail)->catch(sub {
    my ($e) = @_;
    like($e, qr/Pool was released before/, "in-flight queries are marked as rejected if the pool goes away");
});
undef $pool2;
wait_for_promise $p2;

done_testing;
