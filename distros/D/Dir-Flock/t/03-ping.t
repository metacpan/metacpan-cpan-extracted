use strict;
use warnings;
use Test::More;
use Dir::Flock;

# can we detect a stale lock and override it?

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
    my $z1 = Dir::Flock::lock($dir);
    # make a copy of the lockfile
    my ($t) = glob("$dir/dir-flock-*");
    open my $fh2, ">", "$t-copy";
    open my $fh1, "<", $t;
    print $fh2 readline($fh1);
    close $fh1;
    close $fh2;
    my $z2 = Dir::Flock::unlock($dir);
    print P2 "$z1 $z2\n";
    exit 0;
}

close P2;
my $z = <P1>;
close P1;
wait;         # so child process is reaped

@t = glob("$dir/dir-flock-*");
ok(@t > 0, "lock directory is not empty because child has lock");

my $t1 = time;
my $p = Dir::Flock::lock($dir, 0);
my $t2 = time;
ok(!$p, "flock failed in parent");
ok($t2-$t1 < 2, "flock failed fast with 0 timeout");

$Dir::Flock::HEARTBEAT_CHECK = 3;

my $q = Dir::Flock::lock($dir,10);
my $t3 = time;
ok($q, "flock succeeded in parent") or diag $t3-$t2;
ok($t3-$t2 > 2, "flock in parent had to wait for stale lock to be removed");
my $r = Dir::Flock::unlock($dir);
ok($r, "funlock successful");

done_testing;


