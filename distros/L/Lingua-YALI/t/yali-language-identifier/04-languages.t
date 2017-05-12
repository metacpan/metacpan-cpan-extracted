use strict;
use warnings;

use Test::More tests => 11;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $cmd_pref = "echo 'ahoj jak' | ";
my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-language-identifier";
my $cmd_suffix = "";

my $cmd_full = "";

exit_is_num($cmd_pref . $cmd_base . " --languages" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " --languages=" . $cmd_suffix, 105);

exit_is_num($cmd_pref . $cmd_base . " -l" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " -l=" . $cmd_suffix, 105);

$cmd_full = $cmd_pref . $cmd_base . " -l='ces eng'" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "format=single");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " --language='ces eng'" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "format=single");
stderr_is_eq($cmd_full, "", $cmd_full);

exit_is_num($cmd_pref . $cmd_base . " -l='unknown'" . $cmd_suffix, 255);

#exit_is_num($cmd_pref . $cmd_base . ' -l=`'.$cmd_base.' -s`' . $cmd_suffix, 0);
#stdout_is_eq($cmd_pref . $cmd_base . " -l=`$cmd_base -s`" . $cmd_suffix, "ces\n", "format=single");
#stderr_is_eq($cmd_pref . $cmd_base . " -l=`$cmd_base -s`" . $cmd_suffix, "ces\n", "format=single");


