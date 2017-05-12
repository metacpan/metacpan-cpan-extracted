use strict;
use warnings;

use Test::More tests => 10;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $class_file = dirname(__FILE__) . "/../Identifier/classes.list";

my $cmd_pref = "echo 'ahoj jak' | ";
my $script_file = dirname(__FILE__) . "/../../bin/yali-identifier";
my $cmd_base = $^X . " " . $script_file;
my $cmd_suffix = "";

my $cmd_full = "";

exit_is_num($cmd_pref . $cmd_base . " --classes" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " --classes=" . $cmd_suffix, 105);

exit_is_num($cmd_pref . $cmd_base . " -c" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " -c=" . $cmd_suffix, 105);

my $stderr = "File model.a1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.a1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 1.\n";
$stderr .= "File model.b1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.b1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 2.\n";


$cmd_full = $cmd_pref . $cmd_base . " -c=$class_file" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = $cmd_pref . $cmd_base . " --classes=$class_file" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stderr_is_eq($cmd_full, $stderr, $cmd_full);

exit_is_num($cmd_pref . $cmd_base . " -c=unknown_file" . $cmd_suffix, 2);

#exit_is_num($cmd_pref . $cmd_base . ' -l=`'.$cmd_base.' -s`' . $cmd_suffix, 0);
#stdout_is_eq($cmd_pref . $cmd_base . " -l=`$cmd_base -s`" . $cmd_suffix, "ces\n", "format=single");
#stderr_is_eq($cmd_pref . $cmd_base . " -l=`$cmd_base -s`" . $cmd_suffix, "ces\n", "format=single");

stdout_is_eq($cmd_pref . $cmd_base . " -c=$class_file" . $cmd_suffix, "a\n", "format=single");
