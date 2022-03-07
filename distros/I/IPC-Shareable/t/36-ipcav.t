use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

my $t  = 1;
my $ok = 1;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    sleep unless $awake;
    $awake = 0;

    my @av;

    my $ipch = tie @av, 'IPC::Shareable', "foco", {
        create    => 1,
        exclusive => 0,
        mode      => 0666,
        size      => 1024*512,
        destroy   => 0,
    };

    @av = ();

    for (my $i = 1; $i <= 10; $i++) {
        $ipch->shlock;
        push(@av, $i);
        $ipch->shunlock;
    }

    sleep unless $awake;
    @av and undef $ok;
    exit;

} else {
    my @av;
    my $ipch = tie @av, 'IPC::Shareable', "foco", {
        create    => 1,
        exclusive => 0,
        mode      => 0666,
        size      => 1024*512,
        destroy   => 'yes',
    };
    @av = ();
    kill ALRM => $pid;
    
    my %seen;
    sleep 1 until @av;

    while (@av) {
        $ipch->shlock;
        my $line = shift @av;
        ++$seen{$line};
        $ipch->shunlock;
    }
    kill ALRM => $pid;
    waitpid($pid, 0);

    my $count = 0;
    for (1..10){
        is $seen{$_}, 1, "child set elem $count to $_ ok";
        $count++;
    }
    IPC::Shareable->clean_up_all;
}

done_testing();
