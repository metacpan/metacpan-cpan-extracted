use strict;
use warnings;

use Test::More tests => 19;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $class_file = dirname(__FILE__) . "/../Identifier/classes.list";

my $cmd_pref = "echo 'ahoj jak' | ";
my $script_file = dirname(__FILE__) . "/../../bin/yali-identifier";
my $cmd_base = $^X . " " . $script_file;
my $cmd_suffix = " -i=- -c=$class_file";

my $cmd_full = "";

exit_is_num($cmd_pref . $cmd_base . " --format=" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " --format=adads" . $cmd_suffix, 101);

exit_is_num($cmd_pref . $cmd_base . " -f=" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " -f=adads" . $cmd_suffix, 101);

my $stderr = "File model.a1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.a1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 1.\n";
$stderr .= "File model.b1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.b1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 2.\n";

$cmd_full = $cmd_pref . $cmd_base . " --format=single" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\n", "format=single");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=single " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\n", "format=single");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=all " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\tb\n", "format=all");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=all_p " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a:1\tb:0\n", "format=all_p");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " -f=tabbed " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "1\t0\n", "format=tabbed");
stderr_is_eq($cmd_full, $stderr, $cmd_full);
