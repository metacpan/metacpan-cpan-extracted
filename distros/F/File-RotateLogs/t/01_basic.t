use strict;
use warnings;
use File::RotateLogs;
use File::Temp qw/tempdir/;
use Test::More;
use Time::HiRes qw//;

my $tempdir = tempdir(CLEANUP=>1);

my $rotatelogs = File::RotateLogs->new(
    logfile => $tempdir.'/test_log.%Y%m%d%H%M%S',
    linkname => $tempdir.'/test_log',
    rotationtime => 2,
    maxage => 4,
    sleep_before_remove => 2,
);

ok($rotatelogs);

my $n = Time::HiRes::time();
$n = $n - int($n);
select undef, undef, undef, $n;

$rotatelogs->print("foo\n");
{
    my $c=0;
    my $link;
    my $linkf;
    my $log;
    my $logf;
    for my $f ( glob($tempdir.'/test_log*') ) {
        $c++;
        if ( -l $f ) {
            $link++;
            $linkf = $f;
        }
        if ( -f $f && ! -l $f ) {
            $log++;
            $logf = $f;
        }
    }
    is($c,2);
    is($link,1);
    is($log,1);
    is($logf, readlink($linkf));
}

sleep(3);
$rotatelogs->print("bar\n");
{
    my $c=0;
    my $link;
    my $linkf;
    my $log;
    my $logf;
    for my $f ( sort { $a cmp $b } glob($tempdir.'/test_log*') ) {
        $c++;
        if ( -l $f ) {
            $link++;
            $linkf = $f;
        }
        if ( -f $f && ! -l $f ) {
            $log++;
            $logf = $f
        }
    }
    is($c,3);
    is($link,1);
    is($log,2);
    is($logf, readlink($linkf));
}

sleep(2);
$rotatelogs->print("baz\n");
sleep(1);
{
    my $c=0;
    my $link;
    my $log;
    my $lock;
    for my $f ( glob($tempdir.'/test_log*') ) {
        $c++;
        $link++ if -l $f;
        $log++ if -f $f && ! -l $f;
        $lock++ if $f =~ m!lock$!;
    }
    is($c,5);
    ok($link);
    is($log,4);
    ok($lock);
}

sleep(2);
{
    my $c=0;
    my $link;
    my $log;
    my $lock;
    for my $f ( glob($tempdir.'/test_log*') ) {
        $c++;
        $link++ if -l $f;
        $log++ if -f $f && ! -l $f;
        $lock++ if $f =~ m!lock$!;
    }
    is($c,3);
    ok($link);
    is($log,2);
    ok(!$lock);
}

done_testing();
