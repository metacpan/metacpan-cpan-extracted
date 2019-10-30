use strict;
use warnings;
use Test::More;
use Dir::Flock;

require Dir::Flock::Mock;
ok(\&Dir::Flock::lock_ex eq \&Dir::Flock::Mock::lock_ex,
   'Mock version of function loaded');
ok(Dir::Flock::Mock->can("unlock"),
   'Some Dir::Flock functions are mocked');
ok(!Dir::Flock::Mock->can("sync_ex"),
   'Not all Dir::Flock functions are mocked');

pipe *P1, *P2;
(*P2)->autoflush(1);
sleep 2;

# try to choose a test dir that won't be NFS
my $test_dir;
for my $candidate ("/tmp","/dev/shm","C:/Temp",$ENV{TMPDIR},$ENV{TEMP}) {
    next if !defined $candidate;
    if (-d $candidate) {
        $test_dir = $candidate;
        last;
    }
}
$test_dir //= "t";

my $dir = Dir::Flock::getDir($test_dir);
ok(!!$dir, 'getDir returned value');
ok(-d $dir, 'getDir returned dir');
ok(-r $dir, 'getDir return value is readable');
ok(-w $dir, 'getDir return value is writeable');

if (fork() == 0) {
    close P1;
    my $z = Dir::Flock::Mock::lock($dir);
    if ($z) {
        diag "lock held in child";
    } else {
        diag "child failed to get lock. Expect trouble";
    }
    print P2 "$z\n";
    sleep 10;
    diag "releasing lock in child";
    Dir::Flock::Mock::unlock($dir);
    close P2;
    exit 0;
}

close P2;
my $z = <P1>;
close P1;

# core semantics
my $t1 = time;
my $p = Dir::Flock::Mock::lock($dir, 0);
my $t2 = time;
ok(!$p, "flock failed in parent");
ok($t2-$t1 < 2, "flock failed fast with 0 timeout");
my $q = Dir::Flock::Mock::lock($dir);
my $t3 = time;
ok($q, "flock succeeded in parent");
ok($t3-$t2 > 5, "flock in parent had to wait for child to release");
my $r = Dir::Flock::Mock::unlock($dir);
ok($r, "funlock successful");

if (eval "use threads;1") {
    # scope semantics
    my $dir = Dir::Flock::getDir($test_dir);
    ok(!!$dir, 'getDir returned value');
    ok(-d $dir, 'getDir returned dir for scope test');
    ok(-r $dir, 'getDir return value is readable');
    ok(-w $dir, 'getDir return value is writeable');
    my $f = "t/09a-$$.out";
    unlink $f;
    my @data = map [ ($_) x $_ ], 10 .. 20;
    write_f($f,"");
    my @thr = map threads->create(
        sub {
            my @list = @{$_[0]};
            my $obj = Dir::Flock::lockobj($dir);
            write_f($f,@list);
        }, $_ ), @data;
    $_->join for @thr;
    ok(-f "$dir/_lock_", "lockobj used advisory directory flmocking");
    open my $fh, "<", $f;
    my @contents = <$fh>;
    close $fh;
    ok(@contents == 1, "thread output is on a single line");
    my $data = $contents[0];
    my $found_fail = 0;
    for my $n (10..20) {
        my $patt = qr/( $n){$n}/;
        ok( $data =~ $patt, "found instances of $n" ) or $found_fail++;
    }
    if ($found_fail) {
        diag "data was '$data'";
    }
    unlink $f;
    unlink "$dir/_lock_";
    rmdir $dir;

    # block semantics
    $dir = Dir::Flock::getDir($test_dir);
    ok(-d $dir, 'getDir returned dir for block test');
    $f = "t/09b-$$.out";
    unlink $f;
    @data = map [ ($_) x $_ ], 12 .. 18;
    write_f($f,"");
    @thr = map threads->create( 
        sub {
            my @list = @{$_[0]};
            Dir::Flock::sync  { write_f($f,@list) } $dir;
        }, $_ ), @data;
    $_->join for @thr;
    open $fh, "<", $f;
    @contents = <$fh>;
    close $fh;
    ok(@contents == 1, "thread output is on a single line");
    $data = $contents[0];
    for my $n (12..18) {
        my $patt = qr/( $n){$n}/;
        ok( $data =~ $patt, "found instances of token $n" );
    }
    unlink $f;
}

sub write_f {
    my ($f,@list) = @_;
    open my $fh, ">>", $f;
    $fh->autoflush(1);
    seek $fh, 0, 2;
    foreach my $item (@list) {
        print $fh $item;
        print $fh " ";
        select undef,undef,undef,0.1*rand;
    }
    close $fh;
}


done_testing;
