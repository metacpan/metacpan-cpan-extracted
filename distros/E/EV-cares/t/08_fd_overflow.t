use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# Concurrent TCP queries across several servers must all terminate.

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my @servers = map "127.0.0.$_", 1..20;
my $r = EV::cares->new(
    servers => \@servers,
    timeout => 1,
    tries   => 1,
    flags   => ARES_FLAG_USEVC,  # TCP, one socket per server
    rotate  => 1,
);

my $count = 30;
my $done = 0;
for my $i (1..$count) {
    $r->query("test$i.invalid.", C_IN, T_A, sub { $done++ });
}

my $stop;
my $t = EV::timer 8, 0, sub { $stop = 1 };
EV::run until $stop || $done >= $count;

ok($done > 0, "queries terminated ($done/$count)");
is($r->active_queries, 0,
    'all callbacks fired (active_queries returned to 0)');
is_deeply(\@warnings, [], 'concurrent TCP queries need no warnings');

done_testing;
