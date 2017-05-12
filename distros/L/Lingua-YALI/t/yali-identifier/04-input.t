use strict;
use warnings;

use Test::More tests => 15;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $class_file = dirname(__FILE__) . "/../Identifier/classes.list";
my $input_file = dirname(__FILE__) . "/../Identifier/aaa01.txt";

my $script_file = dirname(__FILE__) . "/../../bin/yali-identifier";
my $cmd_base = $^X . " " . $script_file;
my $cmd_suffix = " -c=$class_file";

my $cmd_full = "";

exit_is_num($cmd_base . " -i=adasdasd --filelist=aaa" . $cmd_suffix, 101);
exit_is_num($cmd_base . " -i=nonexisting_file " . $cmd_suffix, 2);

my $stderr = "File model.a1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.a1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 1.\n";
$stderr .= "File model.b1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.b1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 2.\n";

$cmd_full = $cmd_base . " -i=$input_file " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_base . " -i=$input_file " . $cmd_suffix, "a\n", "-i=file");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = "cat $input_file | " . $cmd_base . " -i=- " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\n", "-i=-");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = "cat $input_file | " . $cmd_base . " " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\n", "-i is ommited");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

stdout_is_eq($cmd_base . " --input=$input_file " . $cmd_suffix, "a\n", "--input=file");
stdout_is_eq("cat $input_file | " . $cmd_base . " --input=- " . $cmd_suffix, "a\n", "--input=-");
stdout_is_eq("cat $input_file | " . $cmd_base . " " . $cmd_suffix, "a\n", "--input is ommited");

$cmd_full = "echo 'cccc' | " . $cmd_base . " --format tabbed --input=- " . $cmd_suffix;
stdout_is_eq($cmd_full, "0\t0\n", $cmd_full);