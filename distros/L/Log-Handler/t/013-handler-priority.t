use strict;
use warnings;
use Test::More tests => 7;
use Log::Handler;

my $PRIO_CHECK = 1;

sub prio_1 {
    ok(1 == $PRIO_CHECK, "checking prio 1 ($PRIO_CHECK)");
    $PRIO_CHECK++;
}

sub prio_2 {
    ok(2 == $PRIO_CHECK, "checking prio 2 ($PRIO_CHECK)");
    $PRIO_CHECK++;
}

sub prio_3 {
    ok(3 == $PRIO_CHECK, "checking prio 3 ($PRIO_CHECK)");
    $PRIO_CHECK++;
}

sub prio_10 {
    ok(4 == $PRIO_CHECK, "checking prio 10 ($PRIO_CHECK)");
    $PRIO_CHECK++;
}

sub prio_11 {
    ok(5 == $PRIO_CHECK, "checking prio 11 ($PRIO_CHECK)");
    $PRIO_CHECK++;
}

sub prio_12 {
    ok(6 == $PRIO_CHECK, "checking prio 12 ($PRIO_CHECK)");
    $PRIO_CHECK++;
}

my $log = Log::Handler->new();
$log->add(forward => { forward_to => \&prio_3, priority => 3 });
$log->add(forward => { forward_to => \&prio_2, priority => 2 });
$log->add(forward => { forward_to => \&prio_1, priority => 1 });
$log->add(forward => { forward_to => \&prio_10 });
$log->add(forward => { forward_to => \&prio_11 });
$log->add(forward => { forward_to => \&prio_12 });
$log->error('foo');

ok($PRIO_CHECK == 7, 'all prios checked');
