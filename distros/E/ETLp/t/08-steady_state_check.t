#!perl -w
use strict;
use Test::More;
use FindBin qw($Bin);

if (!eval "require  Parallel::SubFork") {
    plan skip_all => 'require Parallel::SubFork';
} else {
    plan tests => 1;
}

use ETLp::Plugin::Iterative::SteadyStateCheck;
use DateTime;

my $file = "$Bin/tests/csv/ss_chk.test";

sub gen_file {
    open my $fh, '>', $file;
    for my $j (1 .. 20) {
        print $fh " $j";
        sleep 1;
    }
    close $fh;
    #unlink $file;
}

my $ss_chk = ETLp::Plugin::Iterative::SteadyStateCheck->new(
    config        => {},
    item          => {interval => 5},
    original_item => {},
    env_conf      => {},
);

Parallel::SubFork->import;

unlink $file if -f $file;
my $manager = Parallel::SubFork->new();
$manager->start(sub {
    my $file = shift;
    local $| = 1;
    open my $fh, '>', $file;
    for my $j (1 .. 20) {
        print $fh 'x' x 100000;
        sleep 1;
    }
    close $fh;
}, $file);
sleep 1;

my $dt = DateTime->now;
$ss_chk->run($file);
my $duration = DateTime->now->subtract_datetime($dt);

ok($duration->seconds > 20, 'Waited for steady state');

unlink $file if -f $file;
