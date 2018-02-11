use Forks::Super ':test';
use Test::More tests => 12;
use strict;
use warnings;

# fork { exec/cmd => \@array } should always be run as 
# exec LIST  or  system LIST ,
# even when @array has exactly one element

# assumes that an "echo" command is in your $PATH.

for my $ec ("cmd","exec") {

    my $pid1 = fork { $ec => "echo surprise 1", child_fh => 'all' };
    my $pid2 = fork { $ec => [ "echo surprise 2" ], child_fh => 'all' };
    my $pid3 = fork { $ec => [ "echo", "surprise 3" ], child_fh => 'all' };

    waitall;

    ok($pid1->status == 0, "$ec no ARRAY ok");
    ok($pid1->read_stdout =~ /surprise/, "$ec no ARRAY ok");
  SKIP:
    {
        if ($^O eq 'MSWin32') {
            skip "MSWin32 $ec doesn't distinguish list args", 2;
        }
        ok($pid2->status > 0, '"echo surprise" fail');
        ok(!$pid2->read_stdout, '"echo surprise" no output');
    }
    ok($pid3->status == 0, "$ec 'echo','surprise' ok");
    ok($pid3->read_stdout =~ /surprise/,  "$ec 'echo','surprise' ok");
}

