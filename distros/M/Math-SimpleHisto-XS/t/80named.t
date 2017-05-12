use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Math::SimpleHisto::XS') };
BEGIN { use_ok('Math::SimpleHisto::XS::Named') };

use lib 't/lib', 'lib';
use Test_Functions;

my $h = Math::SimpleHisto::XS::Named->new(names => [qw(foo bar baz)]);
isa_ok($h, 'Math::SimpleHisto::XS::Named');

$h->fill("baz", 12.4);
pass("Alive");

my $data = $h->all_bin_contents;
ok(ref($data) && ref($data) eq 'ARRAY', "got ary ref");
is(scalar(@$data), 3, "3 bins");
is($h->nfills, 1, "1 fill");
is_approx($h->total, 12.4, "total is right");

SCOPE: {
  my $exp = [0,0,12.4];
  for (0..2) {
    is_approx($data->[$_], $exp->[$_], "Bin $_ is right");
  }
  for (qw(foo bar baz)) {
    is_approx($h->bin_content($_), shift(@$exp), "Bin $_ is right (extra call)");
  }
}

$h->fill_by_bin("foo");
$h->fill_by_bin("bar", 2.3);
$h->fill_by_bin(["baz", "baz"]);
$h->fill_by_bin(["foo","baz"], [2,3]);

SCOPE: {
  my $exp = [3,2.3,12.4+2+3];

  my $data = $h->all_bin_contents;
  for (0..2) {
    is_approx($data->[$_], $exp->[$_], "Bin $_ is right (after fill_by_bin)");
  }
  for (qw(foo bar baz)) {
    is_approx($h->bin_content($_), shift(@$exp), "Bin $_ is right (extra call, after fill_by_bin))");
  }
}

histo_eq($h, $h->clone(), "clone equal");

# Test empty clone
my $hclone = $h->new_alike();
is($hclone->nfills, 0, "new_alike returns fresh object");
is($hclone->total, 0, "new_alike returns fresh object");
is_approx($hclone->overflow, 0, "new_alike returns fresh object");
is_approx($hclone->underflow, 0, "new_alike returns fresh object");
is_approx($hclone->bin_content("bar"), 0, "new_alike returns fresh object");
$hclone->set_bin_content("baz", 12);
is_approx($hclone->bin_content("baz"), 12, "setting bin content by name works");
is_approx($hclone->total, $hclone->bin_content("foo")+$hclone->bin_content("bar")
                         +$hclone->bin_content("baz"), "clone total");

# clone test
histo_eq($h->clone, $h, "clone equal");

# test dump/load
if (defined $Math::SimpleHisto::XS::JSON) {
  my $dump = $h->dump('simple');
  my $dumpclone = Math::SimpleHisto::XS::Named->new_from_dump('simple', $dump);

  histo_eq($dumpclone, $h, "dump clone equal");
}

done_testing;
