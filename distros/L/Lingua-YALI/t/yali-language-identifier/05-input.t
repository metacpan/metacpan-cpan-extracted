use strict;
use warnings;

use Test::More tests => 14;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $input_file = dirname(__FILE__) . "/../LanguageIdentifier/ces01.txt";

my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-language-identifier";
my $cmd_suffix = " -l='ces eng'";

my $cmd_full = "";

exit_is_num($cmd_base . " -i=adasdasd --filelist=aaa" . $cmd_suffix, 101);
exit_is_num($cmd_base . " -i=nonexisting_file " . $cmd_suffix, 2);

$cmd_full = $cmd_base . " -i=$input_file " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "-i=file");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = "cat $input_file | " . $cmd_base . " -i=- " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "-i=-");
stderr_is_eq($cmd_full, "", $cmd_full);

$cmd_full = "cat $input_file | " . $cmd_base . " " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stdout_is_eq($cmd_full, "ces\n", "-i is ommited");
stderr_is_eq($cmd_full, "", $cmd_full);


stdout_is_eq($cmd_base . " --input=$input_file " . $cmd_suffix, "ces\n", "--input=file");
stdout_is_eq("cat $input_file | " . $cmd_base . " --input=- " . $cmd_suffix, "ces\n", "--input=-");
stdout_is_eq("cat $input_file | " . $cmd_base . " " . $cmd_suffix, "ces\n", "--input is ommited");
