use strict;
use warnings;

use Test::More tests => 19;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $cmd_pref = "echo 'ahoj jak' | ";
my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-language-identifier";
my $cmd_suffix = " -i=- -l='ces eng'";

my $cmd_full = "";

exit_is_num($cmd_pref . $cmd_base . " --format=" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " --format=adads" . $cmd_suffix, 101);

exit_is_num($cmd_pref . $cmd_base . " -f=" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " -f=adads" . $cmd_suffix, 101);

$cmd_full = $cmd_pref . $cmd_base . " --format=single" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "format=single");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=single " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "format=single");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=all " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\teng\n", "format=all");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=all_p " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces:1\teng:0\n", "format=all_p");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=tabbed " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "1\t0\n", "format=tabbed");
stderr_is_eq($cmd_full, "", $cmd_full);

