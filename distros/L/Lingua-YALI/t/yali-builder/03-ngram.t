use strict;
use warnings;

use Test::More tests => 14;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $cmd_pref = "echo 'aaaaaaaa' | ";
my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-builder";
my $cmd_suffix = " -o=$tmp_file";

my $cmd_full = "";

exit_is_num($cmd_pref . $cmd_base . " --ngram=0" . $cmd_suffix, 101);
exit_is_num($cmd_pref . $cmd_base . " --ngram=-10" . $cmd_suffix, 101);
exit_is_num($cmd_pref . $cmd_base . " --ngram" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " --ngram=adads" . $cmd_suffix, 105);

exit_is_num($cmd_pref . $cmd_base . " -n=0" . $cmd_suffix, 101);
exit_is_num($cmd_pref . $cmd_base . " -n=-10" . $cmd_suffix, 101);
exit_is_num($cmd_pref . $cmd_base . " -n" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " -n=adads" . $cmd_suffix, 105);

`$rm_cmd`;
$cmd_full = $cmd_pref . $cmd_base . " -n=4 " . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=4" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;