# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GRID-Cluster.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Test::More tests => 13;
BEGIN { use_ok('GRID::Cluster') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $executable = "pi_qx/pi_grid.pl";
if (-x $executable) {
}
else {
  chdir "t";
}
SKIP: {
  skip("Developer test", 12) unless ($ENV{DEVELOPER} && $ENV{GRID_REMOTE_MACHINES} && -x "$executable" && ($^O =~ /nux$|darwin/));

     my $output = `perl $executable -N 1000 2>&1`;
     like($output, qr{Pi Value: 3.14159.*}, "Example to calculate PI with 1000 iterations");
     
     $output = `perl $executable -N 1000000 2>&1`;
     like($output, qr{Pi Value: 3.14159.*}, "Example to calculate PI with 1000000 iterations");
     
     $output = `perl $executable -N 1000000000 2>&1`;
     like($output, qr{Pi Value: 3.14159.*}, "Example to calculate PI with 1000000000 iterations");
     
     my $old_machines = $ENV{GRID_REMOTE_MACHINES};
     $ENV{GRID_REMOTE_MACHINES} = "";
     
     $output = `perl $executable 2>&1`;
     like($output,
          qr{No machines has been initialized in the cluster at $executable line 26.},
          "Error: No machines have been initialized in the cluster");

     $ENV{GRID_REMOTE_MACHINES} = "not_exists";
     $output = `perl $executable 2>&1`;
     like($output,
          qr{ssh:.*: Name or service not known.*
Warning: Host.*has not been initialized: Can't execute perl in.*using ssh connection with automatic authentication
No machines has been initialized in the cluster at $executable line 26.},
          "Error: No cluster has been initialized due to a machine does not exists. PI can not be calculated");

     $ENV{GRID_REMOTE_MACHINES} = $old_machines.":not_exists";
     $output = `perl $executable 2>&1`;
     like($output,
          qr{ssh:(.|\n)*: Name or service not known.*
Warning: Host.*has not been initialized: Can't execute perl in.*using ssh connection with automatic authentication
(.|\n)*Pi Value: 3.14159.*},
          "Warning: Trying to connect with a machine that not exists. PI can be calculated with other resources");

     $ENV{GRID_REMOTE_MACHINES} = $old_machines;

     $output = `matrix_open/matrix_grid.pl 2>&1`;
     like($output,
          qr{216.055896 340.538918 219.958772 147.537158 248.492591 231.614635 285.933882 216.412527 211.255458 237.70321
246.216711 380.764001 266.026315 260.787624 341.618645 255.531927 300.953928 260.487294 286.772753 293.859173
238.08124 356.33172 227.90812 241.739394 300.548096 240.394931 308.732171 227.326683 225.843145 298.760848
204.384892 332.612688 218.419861 248.934403 254.776449 229.748582 288.098228 255.335166 245.471755 266.733135
160.917361 309.851273 239.734604 236.254269 277.854148 240.405647 278.119375 228.062012 229.0742 266.193599
173.766894 317.277033 258.118349 293.159597 291.901052 208.167003 296.038168 245.774915 249.808038 262.047142
108.7277 203.51178 205.644219 114.415559 157.161238 167.942761 247.975523 190.921357 176.703082 150.653645
196.516235 282.225293 218.274114 126.001155 213.27412 260.018774 212.379201 219.676533 246.249364 193.18947
201.12868 303.293499 233.838549 240.997015 223.783521 279.816457 298.493001 285.022892 274.296799 268.972347
179.914778 305.954129 220.628227 187.61374 253.242992 272.872378 205.02935 214.041359 234.093674 230.088919},
          "Example to calculate a parallel matrix product using unidirectional pipes (10x10 matrix)");

     $output = `matrix_open2/matrix_grid.pl 2>&1`;
     like($output,
          qr{216.055896 340.538918 219.958772 147.537158 248.492591 231.614635 285.933882 216.412527 211.255458 237.70321
246.216711 380.764001 266.026315 260.787624 341.618645 255.531927 300.953928 260.487294 286.772753 293.859173
238.08124 356.33172 227.90812 241.739394 300.548096 240.394931 308.732171 227.326683 225.843145 298.760848
204.384892 332.612688 218.419861 248.934403 254.776449 229.748582 288.098228 255.335166 245.471755 266.733135
160.917361 309.851273 239.734604 236.254269 277.854148 240.405647 278.119375 228.062012 229.0742 266.193599
173.766894 317.277033 258.118349 293.159597 291.901052 208.167003 296.038168 245.774915 249.808038 262.047142
108.7277 203.51178 205.644219 114.415559 157.161238 167.942761 247.975523 190.921357 176.703082 150.653645
196.516235 282.225293 218.274114 126.001155 213.27412 260.018774 212.379201 219.676533 246.249364 193.18947
201.12868 303.293499 233.838549 240.997015 223.783521 279.816457 298.493001 285.022892 274.296799 268.972347
179.914778 305.954129 220.628227 187.61374 253.242992 272.872378 205.02935 214.041359 234.093674 230.088919},
          "Example to calculate a parallel matrix product using bidirectional pipes (10x10 matrix)");

     $output = `matrix_open/matrix_grid.pl -a not_exists -b not_exists 2>&1`;
     like($output,
          qr{Cant find matrix file.*},
          "Error: A file that contains a matrix specification can not be opened");
     
     $output = `matrix_open/matrix_grid.pl -a matrix_open/data/A2x2.dat -b matrix_open/data/B100x100.dat 2>&1`;
     like($output,
          qr{Dimensions error. Matrix A: 2 x 2, Matrix B: 100 x 100},
          "Error: A product with invalid matrix dimensions");
     
     $output = `pi_eval/eval_pi.pl 2>&1`;
     like($output,
          qr{(?i)El\s*resultado\s*del\s*cálculo\s*de\s*PI\s*es:\s*3\.14},
          "Parallel eval");

     $output = `modput/modput.pl 2>&1`;
     my @num = ($output =~ /results'\s*=>\s*\[\s*(\d+)\s*\]/g);

     my @expected = 1..(@num);
     my $ok = "@num" eq "@expected";
     ok($ok, "Parallel modput (not binary module)");
}
