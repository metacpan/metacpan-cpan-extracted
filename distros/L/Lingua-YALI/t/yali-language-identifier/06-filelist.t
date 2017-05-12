use strict;
use warnings;

use Test::More tests => 5;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $input_file = dirname(__FILE__) . "/../LanguageIdentifier/files.txt";

my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-language-identifier";
my $cmd_suffix = " -l='ces eng'";

my $cmd_full = "";

exit_is_num($cmd_base . " -i=adasdasd --filelist=aaa" . $cmd_suffix, 101);
exit_is_num($cmd_base . " --filelist=nonexisting_file " . $cmd_suffix, 2);

$cmd_full = $cmd_base . " --filelist=$input_file " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\neng\n", "--filelist=file");
stderr_is_eq($cmd_full, "", $cmd_full);

# TODO add option for specifying working dir

#stdout_is_eq("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, "ces\neng\n", "--input=-");
#stderr_is_eq("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, "ces\neng\n", "--input=-");
#exit_is_num("cat $input_file | " . $cmd_base . " --filelist=- " . $cmd_suffix, 0);
