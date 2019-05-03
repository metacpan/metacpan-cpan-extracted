use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 20;
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
		  "t/ppi/smoke85.pl");

  ok($c1 == 0, "ran level $level");

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;
  my $keep = $ENV{KEEP} || 0;

  ok(@xh >= 6 && @xh <= 7, "smoke output has 6-7 lines level=$level") or $keep++;

  ok(0 < grep(m{^>>>>> t/ppi/smoke85.pl:7:.*split},@xh),
     "level=$level split seen at line 7") or $keep++;

  ok(0 < grep(m{^>>>>> t/ppi/smoke85.pl:15:.*split},@xh),
     "level=$level split seen at line 15") or $keep++;

  unlink $file unless $keep;
}


for my $level (4, 5) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib",
		  "t/ppi/smoke85.pl");
  my $keep = $ENV{KEEP} || 0;

  ok($c1 == 0, "ran level $level") or $keep++;

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;

  ok(@xh >= 21 && @xh <= 25, "smoke output has 21-25 lines level=$level") or $keep++;

#  my $separate_line_for_line_and_file = qr{^>>\s+t/ppi/smoke85.pl:\d+:};
#  my $uneval_lhs = qr#^>{3,4}\s+[\$\@]\w+.*=#;
#  my $uneval_rhs = qr{=.*[\$\@]};

  my @splitfoobar = grep { /split.*foo,bar/ } @xh;
  my @splithello  = grep { /split.*hello/   } @xh;

  ok(@splitfoobar >= 2, "split in naked block seen at level $level")
      or diag @xh, $keep++;
  ok(@splithello == 2, "split in sub seen at level $level")
      or $keep++;

  unlink $file unless $keep;
}
