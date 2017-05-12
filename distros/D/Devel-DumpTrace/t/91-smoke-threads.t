use Test::More tests => 35;
use strict;
use warnings;

my $dmodule = "-d:DumpTrace::noPPI";

# exercise Devel::DumpTrace module in a simple
# threaded demo

if (!eval 'use threads;1') {
    ok(1,'# skip threads test - threads not configured') for 1..35;
    exit;
}

for my $level (1, 2, 3) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib",
		  "lib/thread-demo2.pl");

  ok($c1 == 0, "ran level $level");

  open XH, '<', $file;
  my @xh = sort grep /\[demo\]/, <XH>;
  close XH;
  my $keep = 0;

  ok(@xh == 10, "smoke output has 10 lines level=$level") or $keep++;

  ok(!!(grep m{^>>>>> .*:3:.*\$a:-1 =},@xh),
     "level=$level line 1-1 ok") or $keep++;
  ok(!!(grep m{^>>>>> .*:3:.*\$a:5 =},@xh),
     "level=$level line 1-2 ok") or $keep++;

  ok(!!(grep m{^>>>>> .*:5:.*\$c:19 = 2 \* \$a:-1 \+ 7 \* \$b:3;},@xh),
     "level=$level line 3-1 ok") or $keep++;
  ok(!!(grep m{^>>>>> .*:5:.*\$c:31 = 2 \* \$a:5 \+ 7 \* \$b:3;},@xh),
     "level=$level line 3-2 ok") or $keep++;

  ok(!!(grep m{>>>>> .*:6:.*\@d:\(5,3,34\) = \(\$a:5},@xh),
     "level=$level line 4-2 ok") or $keep++;

  unlink $file unless $keep;
}

for my $level (4, 5) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib",
		  "lib/thread-demo2.pl");
  my $keep = 0;

  ok($c1 == 0, "ran level $level") or $keep++;

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;

  ok(@xh == 72 || @xh == 68,
     "smoke output has right number of lines level=$level") or $keep++;

  my $separate_line_for_line_and_file = qr{^>> \s+.*:?lib/thread-demo2.pl:\d+:};
  my $uneval_lhs = qr#^>{3,4}\s+[\$\@]\w+.*=#;
  my $uneval_rhs = qr{=.*[\$\@]};

  my @linespec = grep $_ =~ $separate_line_for_line_and_file, @xh;
  ok(@linespec == 16 || @linespec == 15,
     "level $level separate lines for line & file")
      or diag "had ",0+@linespec,++$keep;

  my @uneval_lhs = grep $xh[$_] =~ $uneval_lhs, 0..$#xh;
  ok(@uneval_lhs == 14, "level $level unevaluated source")
      or diag "had ",0+@uneval_lhs,++$keep;

  my $eval_rhs = 0;
  for my $i (@uneval_lhs) {
      $eval_rhs++ if $xh[$i] =~ $uneval_rhs && $xh[$i+1] !~ $uneval_rhs;
  }
  ok($eval_rhs, "level $level separate unevaluated and evaluated rhs") or ++$keep;

  my $eval_lhs = 0;
  for my $i (@uneval_lhs) {
      $eval_lhs++ if $xh[$i+1] !~ $uneval_lhs;
  }
  ok($eval_lhs, "level $level separate line for evaluated lhs");

  my @separators = grep /^----------/, @xh;
  ok(@separators > 10, "level $level output has separator lines") or ++$keep;

  unlink $file unless $keep;
}

# on 5.8.8, this test spits out (harmlessly, as far as I can tell):
#
#        (in cleanup) Can't call method "FETCH" on an undefined value at 
#        blib/lib/Devel/DumpTrace.pm line 169 during global destruction.
#
# is this from the lack of a "threads cleanup veto" mentioned in perl589delta?

