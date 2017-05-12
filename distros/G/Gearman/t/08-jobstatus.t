use strict;
use warnings;

use Test::More;

my ($mn) = qw/
    Gearman::JobStatus
    /;

use_ok($mn);

can_ok(
    $mn, qw/
        known
        percent
        progress
        running
        /
);

subtest "known", sub {
    is(new_ok($mn, [])->known(),  undef);
    is(new_ok($mn, [1])->known(), 1);
};

subtest "running", sub {
    is(new_ok($mn, [])->running(), undef);
    is(new_ok($mn, [undef, 1])->running(), 1);
};

subtest "progress/percent", sub {
    my $js = new_ok($mn, []);
    is($js->progress(), undef);
    is($js->percent(),  undef);

    my @x = (int(rand(2)), int(rand(1)) + 1);
    $js = new_ok($mn, [undef, undef, @x]);
    my $p = $js->progress();
    is(@{$p},   @x);
    is($p->[0], $x[0]);
    is($p->[1], $x[1]);

    is($js->percent(), $x[0] / $x[1]);

    $x[1] = 0;
    is(new_ok($mn, [undef, undef, @x])->percent(), undef);
};

done_testing();

