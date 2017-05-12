use strict;
use warnings;

use Test::More tests => 2;

use Fork::Promise;
use AnyEvent;


my $cv;

my $cb = sub {
    my ($error) = @_;
    $cv->send($error);
};

my $pfork = Fork::Promise->new();

$cv = AnyEvent->condvar;
$pfork->run(sub {exit 10})->catch($cb);
is($cv->recv(), 'Child returned error 10', 'exitcode');

$cv = AnyEvent->condvar;
$pfork->run(sub {kill 9, $$})->catch($cb);
is($cv->recv(), 'Child killed by signal 9', 'kill signal');
