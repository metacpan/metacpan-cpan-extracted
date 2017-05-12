use strict;
use warnings;

use Test::More tests => 12;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $class_file = dirname(__FILE__) . "/../Identifier/classes.list";
my $input_file = dirname(__FILE__) . "/../Identifier/aaa01.txt";

my $script_file = dirname(__FILE__) . "/../../bin/yali-identifier";
my $cmd_base = $^X . " " . $script_file;
my $cmd_suffix = " -c=$class_file --each ";

my $cmd_full = "";

my $stderr = "File model.a1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.a1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 1.\n";
$stderr .= "File model.b1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.b1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 2.\n";

my $stdout_a = "a\na\na\na\n";

$cmd_full = $cmd_base . " -i=$input_file " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_base . " -i=$input_file " . $cmd_suffix, $stdout_a, "-i=file");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = "cat $input_file | " . $cmd_base . " -i=- " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, $stdout_a, "-i=-");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

$cmd_full = "cat $input_file | " . $cmd_base . " " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, $stdout_a, "-i is ommited");
stderr_is_eq($cmd_full, $stderr, $cmd_full);


stdout_is_eq($cmd_base . " --input=$input_file " . $cmd_suffix, $stdout_a, "--input=file");
stdout_is_eq("cat $input_file | " . $cmd_base . " --input=- " . $cmd_suffix, $stdout_a, "--input=-");
stdout_is_eq("cat $input_file | " . $cmd_base . " " . $cmd_suffix, $stdout_a, "--input is ommited");
