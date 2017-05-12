use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 27;
  } else {
    plan skip_all => "PPI not available";
  }
}
use strict;
use warnings;

# check output of Devel::DumpTrace module, compare with reference output.

my $dmodule = "-d:DumpTrace::PPI";

open T, '>', "$0.pl";
print T <<'EO_T;';

# test program for t/82-smoke.t, t/ppi/82-smoke.t
our $u = '_';
for my $v (17, 37) {
    $u .= $v x $v
}

EO_T;





# levels 1,2,3 can be distinguished by which lines are abbreviated.
# level 1: two lines should have abbrev
# level 2: one line
# level 3: no lines

for my $level (1, 2, 3) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib", "$0.pl");
  my $keep = 0;

  ok($c1 == 0, "ran level $level") or $keep++;

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;

  # 0.10: foreach decorator adds one more line to @xh
  ok(@xh >= 4 && @xh <= 5, 
     "smoke output has 4-5 lines level=$level") or $keep++;
  my (@abbrevs) = grep { /\.\.\./ } @xh;
  ok(@abbrevs = 3 - $level,
     "smoke output has 3-$level lines abbreviated") or $keep++;
  ok(4 == (grep { /\>\>\s+$0.pl:\d+\S*:\s+\S/ } @xh),
     "smoke output displays file and line on all output") or $keep++;

  unlink $file unless $keep;
}


my @xh4;

for my $level (4, 5) {

  my $file = "$0.out.$level";
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = $level;
  my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib", "$0.pl");
  my $keep = 0;

  ok($c1 == 0, "ran level $level") or $keep++;

  open XH, '<', $file;
  my @xh = <XH>;
  close XH;

  ok(@xh == 18, "smoke output has 18 lines level=$level") or $keep++;

  my $separate_line_for_line_and_file = qr{^>>\s+$0.pl:\d+:};
  my $uneval_lhs = qr#^>{3,4}\s+[\$\@]\w+.*=#;
  my $uneval_rhs = qr{=.*[\$\@]};

  ok($xh[0] =~ $separate_line_for_line_and_file
     && $xh[4] =~ $separate_line_for_line_and_file
     && $xh[8] =~ $separate_line_for_line_and_file
     && $xh[13] =~ $separate_line_for_line_and_file,
     "level $level separate line for line & file") or $keep++;

  ok($xh[14] =~ $uneval_rhs && $xh[15] !~ $uneval_rhs,
     "level $level separate unevaluated rhs and evaluated rhs") or $keep++;

  ok($xh[2] !~ $uneval_lhs 
     && $xh[6] !~ $uneval_lhs
     && $xh[11] !~ $uneval_lhs,
     "level $level seperate line for evaluate lhs") or $keep++;

  ok($xh[3] eq $xh[7] && $xh[3] eq $xh[12] && $xh[3] eq $xh[17]
     && substr($xh[3],0,10) eq '-' x 10,
     "level $level output has separator lines") or $keep++;

  if (@xh4) {
    # expect @xh, @xh4 to be identical except for one
    # abbreviated line
    my $diff = 0;
    for my $i (0..$#xh4) {
      if ($diff==0 && $xh[$i] ne $xh4[$i]) {
        ok($xh4[$i] =~ /\.\.\./, "level 4 has abbreviation") or $keep++;
        ok(length($xh4[$i]) < length($xh[$i]),
           "level 4/5 diff line shorter in level 4") or $keep++;
        $diff++;
      }
    }
    ok($diff==1, "one difference between level 4 & 5") or $keep++;
  } else {
    @xh4 = @xh;
  }

  unlink $file unless $keep;
}

unlink "$0.pl";
