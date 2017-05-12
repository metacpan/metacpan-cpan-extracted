use strict;
use warnings;

use Test::More tests => 3;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $class_file = dirname(__FILE__) . "/../Identifier/classes.list";
my $input_file = dirname(__FILE__) . "/../Identifier/files.txt";

my $script_file = dirname(__FILE__) . "/../../bin/yali-identifier";
my $cmd_base = $^X . " " . $script_file;
my $cmd_suffix = " -c=$class_file --each ";

my $cmd_full = "";

my $stderr = "File model.a1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.a1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 1.\n";
$stderr .= "File model.b1.gz does not exist, using ".dirname(__FILE__) . "/../Identifier/model.b1.gz instead. at ".$script_file." line 82, <\$fh_classes> line 2.\n";

my $stdout = "a\na\na\na\n";

$cmd_full = $cmd_base . " --filelist=$input_file " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "a\na\na\na\nb\nb\nb\nb\n", "--filelist=file");
stderr_is_eq($cmd_full, $stderr, $cmd_full);

# TODO add option for specifying working dir

#stdout_is_eq("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, "ces\neng\n", "--input=-");
#stderr_is_eq("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, "ces\neng\n", "--input=-");
#exit_is_num("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, 0);
