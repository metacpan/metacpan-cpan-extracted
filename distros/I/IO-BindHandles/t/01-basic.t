#!/usr/bin/perl


# we're going to do a very basic test, we're openning two sets of
# pipes. We will bind one set to the other, try writing in one side to
# read in the other and vice-versa.
use IO::BindHandles;
use IO::Handle;

my ($r1, $w1, $r2, $w2) = map { IO::Handle->new() } 1..4;
pipe($r1, $w1);
pipe($r2, $w2);


$r1->autoflush(1);
$w1->autoflush(1);
$r2->autoflush(1);
$w2->autoflush(1);

my $bh = IO::BindHandles->new(
                              handles => [
                                          $r1, $w2, # read from r1, write to w2
                                         ]
                             );

# now, if we write to w1 we should see the results in r2
my $pid = fork();
if (!$pid) {
    close $r2;
    close $w1;
    while ($bh->bound()) {
        $bh->rwcycle();
    }
    exit 0;
} else {
    close $r1;
    close $w2;

    require Test::More;
    Test::More->import(tests => 4);

    pass("Will start to write on w1");
    $w1->print("Test\n");

    pass("Will read from r2");
    is($r2->getline(), "Test\n", "got the output in the third pipe");

    pass("Will close all");
    close $r2;
    close $w1;

    waitpid $pid, 0;
}
