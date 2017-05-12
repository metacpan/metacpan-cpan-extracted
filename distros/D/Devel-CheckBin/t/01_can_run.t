use strict;
use warnings;
use utf8;
use Test::More;
use Devel::CheckBin;

if ($^O eq 'linux' || $^O eq 'darwin') {
    ok can_run("ls");
    ok !can_run("unknown_command");
} else {
    plan 'skip_all' => "Skip: $^O";
}

done_testing;

