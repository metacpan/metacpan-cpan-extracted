use strict;
use warnings;
use Test::More;
use Dir::Flock;
use Fcntl ':flock';

# exercise flock semantics

pipe *P1, *P2;
(*P2)->autoflush(1);
sleep 2;

my $dir = Dir::Flock::getDir("t");
ok(!!$dir, 'getDir returned value');
ok(-d $dir, 'getDir returned dir');
ok(-r $dir, 'getDir return value is readable');
ok(-w $dir, 'getDir return value is writeable');

my @t = glob("$dir/dir-flock-*");
ok(@t == 0, "lock directory is empty because it is new");

if (fork() == 0) {
    close P1;
    my $z = Dir::Flock::flock($dir,LOCK_EX);
    if (!$z) {
        diag "child failed to get lock. Expect trouble";
    }
    print P2 "$z\n";
    sleep 10;
    Dir::Flock::flock($dir,LOCK_UN);
    close P2;
    exit 0;
}

close P2;
my $z = <P1>;
close P1;

@t = glob("$dir/dir-flock-*");
ok(@t > 0, "lock directory is not empty because child has lock");

my $t1 = time;
my $p = Dir::Flock::flock($dir, LOCK_EX | LOCK_NB);
my $t2 = time;

# this is an intermittent test failure point. Does the flock succeed?
ok(!$p, "flock failed in parent")
    or Dir::Flock::unlock($dir);

ok($t2-$t1 < 2, "flock failed fast with 0 timeout");
my $q = Dir::Flock::flock($dir, LOCK_EX);
my $t3 = time;
ok($q, "flock succeeded in parent");
ok($t3-$t2 > 5, "flock in parent had to wait for child to release");
my $r = Dir::Flock::flock($dir, LOCK_UN);
ok($r, "funlock successful");

done_testing;

