use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 32;
  } else {
    plan skip_all => "PPI not available";
  }
}
use strict;
use warnings;

my $dmodule = "-d:DumpTrace::PPI";

# check output of Devel::DumpTrace module, compare with reference output.

# for lib/demo.pl, levels 1,2,3 should be indistinguishable
#                  levels 4,5 should be indistinguishable

for my $level (1, 2, 3) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib",
		  "lib/demo.pl");

  ok($c1 == 0, "ran level $level");

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;
  my $keep = 0;

  ok(@xh == 4, "smoke output has 4 lines level=$level") or $keep++;

  ok($xh[0] =~ m{^>>>>> lib/demo.pl:3:.*\$a:1 = 1;},
     "level=$level line 1 ok") or $keep++;

  ok($xh[1] =~ m{^>>>>> lib/demo.pl:4:.*\$b:3 = 3;},
     "level=$level line 2 ok") or $keep++;

  ok($xh[2] =~ m{^>>>>> lib/demo.pl:5:.*\$c:23 = 2 \* \$a:1 \+ 7 \* \$b:3;},
     "level=$level line 3 ok") or $keep++;

  ok($xh[3] =~ m{^>>>>>[ ]lib/demo.pl:6:
		 .*\@d:\(1,3,26\)[ ]
		 =[ ]\(\$a:1,[ ]\$b:3,
                 [ ]\$c:23[ ]\+[ ]\$b:3\);}x,
     "level=$level line 4 ok")
    or diag("\$xh[3] => $xh[3] ",$keep++);

  unlink $file unless $keep;
}


for my $level (4, 5) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib",
		  "lib/demo.pl");
  my $keep = 0;

  ok($c1 == 0, "ran level $level") or $keep++;

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;

  ok(@xh == 18, "smoke output has 18 lines level=$level") or $keep++;

  my $separate_line_for_line_and_file = qr{^>>\s+lib/demo.pl:\d+:};
  my $uneval_lhs = qr#^>{3,4}\s+[\$\@]\w+.*=#;
  my $uneval_rhs = qr{=.*[\$\@]};

  ok($xh[0] =~ $separate_line_for_line_and_file
     && $xh[4] =~ $separate_line_for_line_and_file
     && $xh[8] =~ $separate_line_for_line_and_file
     && $xh[13] =~ $separate_line_for_line_and_file,
     "level $level separate line for line & file")
    or diag(@xh[0,4,8,13],$keep++);

  ok($xh[1] =~ $uneval_lhs
     && $xh[5] =~ $uneval_lhs
     && $xh[9] =~ $uneval_lhs
     && $xh[14] =~ $uneval_lhs && $xh[15] =~ $uneval_lhs,
     "level $level unevaluated source") or $keep++;

  ok($xh[14] =~ $uneval_rhs && $xh[15] !~ $uneval_rhs,
     "level $level separate unevaluated rhs and evaluated rhs") or $keep++;

  ok($xh[2] !~ $uneval_lhs 
     && $xh[6] !~ $uneval_lhs
     && $xh[11] !~ $uneval_lhs,
     "level $level seperate line for evaluate lhs") or $keep++;

  ok($xh[3] eq $xh[7] && $xh[3] eq $xh[12] && $xh[3] eq $xh[17]
     && substr($xh[3],0,10) eq '-' x 10,
     "level $level output has separator lines") or $keep++;

  unlink $file unless $keep;
}
