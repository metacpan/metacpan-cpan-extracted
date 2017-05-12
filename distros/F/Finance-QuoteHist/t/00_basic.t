use FindBin;
use lib $FindBin::RealBin;
use testload;

my $tcount;
BEGIN {
  my @mods = modules();
  $tcount = scalar @mods + 2;
}

use Test::More tests => $tcount;

BEGIN {
  use_ok('Finance::QuoteHist');
  use_ok('Finance::QuoteHist::Generic');
  use_ok($_) foreach modules();
}
