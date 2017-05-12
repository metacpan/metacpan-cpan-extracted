use strict;
use warnings;

use Test::More tests => 2;

use Fork::Promise;
use AnyEvent;

my $pp = Fork::Promise->new();
my $duration = -time;

my $cv = AnyEvent->condvar;

$pp->run(sub { system('perl -e "sleep 2"') }, 1)->then(sub {
    my ($exitcode, $number) = @_;
    is($number, 1, '1 finished');
    $cv->send();
});
my $promise = $pp->run(sub { system('perl -e "sleep 1"') }, 2)->then(sub {
    my ($exitcode, $number) = @_;
    is($number, 2, '2 finished');
});

$cv->recv;

done_testing;
