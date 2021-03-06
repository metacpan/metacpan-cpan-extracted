use strict;
use warnings;
use Test::More;
use Dir::Flock;

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
    my $z = Dir::Flock::lock_sh($dir);
    if (!$z) {
        diag "child failed to get lock. Expect trouble";
    }
    print P2 "$z\n";
    sleep 10;
    Dir::Flock::unlock($dir);
    close P2;
    exit 0;
}

close P2;
my $z = <P1>;
close P1;

@t = glob("$dir/dir-flock-*");
ok(@t > 0, "lock directory is not empty because child has lock");

my $t1 = time;
my $p = Dir::Flock::lock_sh($dir, 0);
my $t2 = time;
ok($p, "got shared lock in parent");
ok($t2-$t1 < 2, "flock finished fast with 0 timeout");
my $pp = Dir::Flock::unlock($dir);
ok($pp, "released shared lock in parent");
$t1 = time;
$p = Dir::Flock::lock_ex($dir,0);
$t2 = time;
ok(!$p && $t2-$t1 < 2, "failed to get exclusive lock")
    or Dir::Flock::unlock($dir);
ok($t2-$t1 < 2, "timeout quickly");
my $q = Dir::Flock::lock_ex($dir);
my $t3 = time;
ok($q, "flock succeeded in parent");
ok($t3-$t2 > 5, "flock in parent had to wait for child to release");
my $r = Dir::Flock::unlock($dir);
ok($r, "funlock successful");

done_testing;

