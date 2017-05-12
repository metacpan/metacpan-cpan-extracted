use strict;
use warnings;

use Test::More tests => 3;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $script_file = dirname(__FILE__) . "/../../bin/yali-builder";
my $cmd_base = $^X . " " . $script_file;

ok(-x $script_file);

exit_is_num($cmd_base . " --unknownoption", 105);
exit_is_num($cmd_base, 101);



