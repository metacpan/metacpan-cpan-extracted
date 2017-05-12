use strict;
use warnings;

use Test::More tests => 5;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $class_file = dirname(__FILE__) . "/../Identifier/classes.list";
my $input_file = dirname(__FILE__) . "/../Identifier/files.txt";

my $script_file = dirname(__FILE__) . "/../../bin/yali-identifier";
my $cmd_base = $^X . " " . $script_file;
my $cmd_suffix = " -c=$class_file";

my $cmd_full = "";

exit_is_num($cmd_base . " -i=adasdasd --filelist=aaa" . $cmd_suffix, 101);
exit_is_num($cmd_base . " --filelist=nonexisting_file " . $cmd_suffix, 2);

my $stderr = "File model.a1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.a1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 1.\n";
$stderr .= "File model.b1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.b1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 2.\n";

$cmd_full = $cmd_base . " --filelist=$input_file " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\nb\n", "--filelist=file");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

# TODO add option for specifying working dir

#stdout_is_eq("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, "ces\neng\n", "--input=-");
#stderr_is_eq("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, "ces\neng\n", "--input=-");
#exit_is_num("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, 0);
