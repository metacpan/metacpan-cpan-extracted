# -*-perl-*- ASAP

use Test; plan tests => 13;
use Event qw(loop unloop);

# $Event::DebugLevel = 3;

my $c=0;
Event->idle(repeat => 1, cb => sub { 
		++$c;
		unloop if $c >= 2;
	    })
    ->now;
my $tm = Event->timer(after => 10, cb => sub { ok 1 });
ok !$tm->pending;
$tm->stop;
$tm->now;

ok $tm->pending;
my @e = $tm->pending;
ok @e, 1;
ok ref $e[0], 'Event::Event';
ok $e[0]->hits;
ok $e[0]->w, $tm;

$tm->prio($tm->prio + 1);
$tm->now;
$tm->prio($tm->prio - 1);
$tm->now;
$tm->now;

@e = $tm->pending;   # in order of occurance (FIFO)
ok join('', map { $_->prio } @e), join('', $tm->prio, $tm->prio+1,
				       $tm->prio, $tm->prio);

loop;
ok $c, 2;
ok $tm->cbtime;
