use strict;
use warnings;

use Test::More tests => 4;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-identifier";

my $cmd_full = "";

$cmd_full = $cmd_base . " --help";
exit_is_num($cmd_full, 0);
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = $cmd_base . " -h";
exit_is_num($cmd_full, 0);
stderr_is_eq($cmd_full, "", $cmd_full);
