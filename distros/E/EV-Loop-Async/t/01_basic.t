print "1..8\n"; $|=1;

use EV::Loop::Async;

print "ok 1\n";

my $loop = EV::Loop::Async::default;
my $flag;

print "ok 2\n";

$loop->lock;
my $timer = $loop->timer (0, 100, sub { $flag = 1 });
$loop->notify;
print "ok 3\n";
$loop->unlock;

print "ok 4\n";
1 until $flag;
print "ok 5\n";

{
   $loop->scope_lock;
   $timer->stop;
}

print "ok 6\n";

undef $timer;

print "ok 7\n";

undef $loop;

print "ok 8\n";

