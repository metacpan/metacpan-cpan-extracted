#!./perl -w
# check FIFO dispatch of equal priority events

use Test; plan test => 1;
use Event;

my @hit;
sub cb {
    my ($e) = @_;
    push @hit, $e->w->desc;
}

my $t1 = Event->timer(desc => 1, after => 10, cb => \&cb);
my $t2 = Event->timer(desc => 2, after => 10, cb => \&cb);
my $t3 = Event->timer(desc => 3, after => 10, cb => \&cb);
my $h4 = Event->timer(desc => 4, nice => -1, after => 10, cb => \&cb);
my $h5 = Event->timer(desc => 5, nice => -1, after => 10, cb => \&cb);

$t2->now;
$h4->now;
$t1->now;
$t1->now;
$t3->now;
$h5->now;
$t2->now;
$t1->now;

Event::loop();
ok join('', @hit), '45211321';
