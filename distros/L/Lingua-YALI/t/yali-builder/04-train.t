use strict;
use warnings;

use Test::More tests => 36;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $input_file = dirname(__FILE__) . "/../Identifier/aaa01.txt";

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $cmd_pref = "cat $input_file | ";
my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-builder";
my $cmd_suffix = " -o=$tmp_file";

my $cmd_full = "";

# TODO add check whether the results are as expected
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=2 --count=20" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=2" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=3 --count=20" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=3" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_suffix .= " -i=-";

$cmd_full = $cmd_pref . $cmd_base . " --ngram=2 --count=20" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=2" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=3 --count=20" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=3" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;


$cmd_pref = "";
$cmd_suffix =~ s/-i=-//;
$cmd_suffix .= " -i=$input_file";

$cmd_full = $cmd_pref . $cmd_base . " --ngram=2 --count=20" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=2" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=3 --count=20" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

$cmd_full = $cmd_pref . $cmd_base . " --ngram=3" . $cmd_suffix;
exit_is_num($cmd_full, 0);
ok(-f $tmp_file);
stderr_is_eq($cmd_full, "", $cmd_full);
`$rm_cmd`;

