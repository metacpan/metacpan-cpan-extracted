# -*-perl-*-

use Test; plan test => 2;
use Event 0.37 qw(loop unloop sleep);
use Event::Stats;

# $Event::DebugLevel = 3;

my $runs=0;
my $e;
$e = Event->idle(desc => "yawn", repeat => 1, cb => sub {
		     ++$runs;
		     sleep 1;
		     unloop if ($e->stats(15))[0];
		 });
Event::Stats::collect(1);
loop;

my @s = $e->stats(15);
ok abs($s[0] - $runs) <= 1;
my $diff = abs($s[2] - $s[0]);
if (!ok(($diff < .3))) {
    warn "abs($s[2] - $s[0]) = $diff";
}
