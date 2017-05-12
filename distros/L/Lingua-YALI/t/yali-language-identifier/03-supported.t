use strict;
use warnings;

use Test::More tests => 10;
use Time::HiRes;
use Test::Command;
use File::Basename;

my $tmp_file = "tmp.yali-builder.out.gz";
my $rm_cmd = "rm -rf tmp.*";

my $cmd_pref = " ";
my $cmd_base = $^X . " " . dirname(__FILE__) . "/../../bin/yali-language-identifier";
my $cmd_suffix = "";

my $cmd_full = "";
my $cmd_wc = $^X . ' -e \'while (<STDIN>){}; print $.\'';

exit_is_num($cmd_pref . $cmd_base . " --supported=-10" . $cmd_suffix, 105);
exit_is_num($cmd_pref . $cmd_base . " -s=-10" . $cmd_suffix, 105);

$cmd_full = $cmd_pref . $cmd_base . " -s " . $cmd_suffix;
exit_is_num($cmd_full, 0);
stderr_is_eq($cmd_full, "", $cmd_full);
# sed does not work on solaris and darwin
#stdout_is_eq($cmd_full. " | wc -l | sed -r 's/ //g' ", "122\n", "there is 122 supported languages");
#stderr_is_eq($cmd_full. " | wc -l | sed -r 's/ //g' ", "", $cmd_full. " | wc -l | sed -r 's/ //g' ");

stdout_is_eq($cmd_full . " | " . $cmd_wc, "122", "there is 122 supported languages");


$cmd_full = $cmd_pref . $cmd_base . " --supported" . $cmd_suffix;
exit_is_num($cmd_full, 0);
stderr_is_eq($cmd_full, "", $cmd_full);

# sed does not work on solaris and darwin
#stdout_is_eq($cmd_full . " | wc -l | sed -r 's/ //g' ", "122\n", "there is 122 supported languages");
#stderr_is_eq($cmd_full. " | wc -l | sed -r 's/ //g' ", "", $cmd_full. " | wc -l | sed -r 's/ //g' ");
#exit_is_num($cmd_full. " | wc -l | sed -r 's/ //g' ", 0);

stdout_is_eq($cmd_full . " | " . $cmd_wc, "122", "there is 122 supported languages");
stderr_is_eq($cmd_full. " | " . $cmd_wc, "", $cmd_full. " | " . $cmd_wc);
exit_is_num($cmd_full. " | " . $cmd_wc, 0);

#
#stdout_is_eq($cmd_full. " | wc -l | sed -r 's/\\s+//g'", "122\n", "s");
#stdout_is_eq($cmd_full. " | wc -l | sed -r 's/ //g'", "122\n", " ");

