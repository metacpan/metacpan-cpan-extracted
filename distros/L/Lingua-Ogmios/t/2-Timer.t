use strict;
use warnings;

use Test::More tests => 7;

use Lingua::Ogmios;
use Lingua::Ogmios::Timer;


my $timer = Lingua::Ogmios::Timer->new;
ok(defined($timer), 'Timer->new works');

$timer->start;
ok(defined($timer) && defined($timer->{'timeStart'}), 'Timer->start works');
warn "\nTimeStart: " . $timer->getTime($timer->getTimeStart) . "\n";

my $suspendTime = $timer->suspend;
ok(defined($timer) && defined($suspendTime)  && defined($timer->{'temporaryTimeEnd'}), 'Timer->suspend works');
warn "SuspendTime: $suspendTime\n";

my $timeFromStart =  $timer->suspendFromStart;
ok(defined($timer) && defined($timeFromStart)  && defined($timer->{'temporaryTimeEnd'}), 'Timer->suspendFromStart works');
warn "SuspendTime from start: $timeFromStart\n\n";

$timer->markStartUserTime;
my $uTimeS = $timer->getStartUserTime;
ok(defined($timer) && defined($uTimeS), 'Timer->markStartUserTime works');

$timer->markEndUserTime;
my $uTimeE = $timer->getEndUserTime;
ok(defined($timer) && defined($uTimeE), 'Timer->markEndUserTime works');

my @times = $timer->suspendWithUserTime;
ok(defined($timer) && defined($times[0]) && defined($times[1]) && defined($times[2]), 'Timer->suspendWithUserTime works');
warn "FullTime: " .$times[0] . "\n";
warn "SystemTime: " . $times[1] . "\n";
warn "UserTime: " . $times[2] . "\n";


