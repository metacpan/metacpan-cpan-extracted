# -*- Mode: Perl -*-
# t/01_ini.t; just test load Getopt::Gen by using it

use vars qw($TEST_DIR);
$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

BEGIN {
  use Test;
  plan(test => 4);
}

# 1: load module
eval "use Getopt::Gen;";
ok(!$@);

eval "use Getopt::Gen::cmdline_c;";
ok(!$@);

eval "use Getopt::Gen::cmdline_h;";
ok (!$@);

eval "use Getopt::Gen::cmdline_pod;";
ok(!$@);

print "\n";
# end of t/01_ini.t
