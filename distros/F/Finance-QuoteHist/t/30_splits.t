use strict;

my $tcount;
BEGIN { $tcount = 4 }
use Test::More tests => $tcount;

use FindBin;
use lib $FindBin::RealBin;
use testload;

SKIP: {
  skip("split (no connect)", $tcount) unless network_ok();
  for my $src (sources()) {
    SKIP: {
      my($m, $sym, $start, $end, $dat) = basis($src, 'split');
      next unless $m;
      skip("(dev only) split $src test", 2)
        unless DEV_TESTS || $src eq GOLDEN_CHILD;
      eval "use $m";
      my %parms = ( class => $m );
      split_cmp(
        $sym, $start, $end,
        "direct split ($src)",
        $dat, %parms
      );
    }
  }
}

sub split_cmp {
  @_ >= 5 or die "Problem with args\n";
  my($symbol, $start_date, $end_date, $label, $dat, %parms) = @_;
  my $q = new_quotehist($symbol, $start_date, $end_date, %parms);
  my @rows = $q->splits;
  cmp_ok(scalar @rows, '==', scalar @$dat, "$label (rows)");
  for my $i (0 .. $#rows) {
    $rows[$i] = join(':', @{$rows[$i]});
  }
  is_deeply(\@rows, $dat, "$label (content)");
}
