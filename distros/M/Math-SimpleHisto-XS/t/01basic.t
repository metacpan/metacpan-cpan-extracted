use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

my $h = Math::SimpleHisto::XS->new(nbins => 10, min => 0, max => 1);
isa_ok($h, 'Math::SimpleHisto::XS');

$h->fill(0.11, 12.4);
pass("Alive");

is_approx($h->binsize, 0.1, "binsize default");
is_approx($h->binsize(0), 0.1, "binsize(0)");
is_approx($h->binsize(2), 0.1, "binsize(2)");
is_approx($h->binsize(5), 0.1, "binsize(5)");
ok(!eval{$h->binsize(-1); 1}, "binsize(-1) fails");
ok(!eval{$h->binsize(100); 1}, "binsize(100) fails");

my $data = $h->all_bin_contents;
ok(ref($data) && ref($data) eq 'ARRAY', "got ary ref");
is(scalar(@$data), 10, "10 bins");
is($h->nfills, 1, "1 fill");
is_approx($h->total, 12.4, "total is right");
SCOPE: {
  my $exp = [0,12.4,(0)x8];
  for (0..9) {
    is_approx($data->[$_], $exp->[$_], "Bin $_ is right");
    is_approx($h->bin_content($_), $exp->[$_], "Bin $_ is right (extra call)");
  }
}

$h->fill_by_bin(0);
$h->fill_by_bin(-1);
$h->fill_by_bin(1, 2.3);
$h->fill_by_bin([2, 5]);
$h->fill_by_bin([3,4], [2,3]);
$h->fill_by_bin(1e9, 1);

SCOPE: {
  my $exp = [0,12.4,(0)x8];
  for ([0, 1], [1, 2.3], [2, 1], [5, 1], [3, 2], [4, 3]) {
    $exp->[$_->[0]] += $_->[1];
  }

  my $data = $h->all_bin_contents;
  for (0..9) {
    is_approx($data->[$_], $exp->[$_], "Bin $_ is right (after fill_by_bin)");
    is_approx($h->bin_content($_), $exp->[$_], "Bin $_ is right (extra call, after fill_by_bin))");
  }
}

$h->fill(-2.);
$h->fill(0.5);
$h->fill(0.5, 13.);
$h->fill([0.5], [13.]);
$h->fill([0.5, 2.], [13., 1.]);
pass("alive");

# Test empty clone
my $hclone = $h->new_alike();
is($hclone->nfills, 0, "new_alike returns fresh object");
is($hclone->total, 0, "new_alike returns fresh object");
is_approx($hclone->overflow, 0, "new_alike returns fresh object");
is_approx($hclone->underflow, 0, "new_alike returns fresh object");

# Test addition
$hclone->set_bin_content(0, 23.4);
SCOPE: {
  my $hcloneclone = $hclone->clone;
  $hcloneclone->add_histogram($h);
  foreach my $meth (qw(total overflow underflow nfills)) {
    is_approx($hcloneclone->$meth, $hclone->$meth + $h->$meth);
  }
  foreach my $i (0..$h->nbins-1) {
    is_approx($hcloneclone->bin_content($i), $hclone->bin_content($i) + $h->bin_content($i));
  }
}

# Test subtraction
SCOPE: {
  my $hcloneclone = $hclone->clone;
  $hcloneclone->subtract_histogram($h);
  foreach my $meth (qw(total overflow underflow)) {
    is_approx($hcloneclone->$meth, $hclone->$meth - $h->$meth, "subtraction: $meth");
  }
  is_approx($hcloneclone->nfills, $hclone->nfills + $h->nfills, "subtraction: nfills");

  foreach my $i (0..$h->nbins-1) {
    is_approx($hcloneclone->bin_content($i), $hclone->bin_content($i) - $h->bin_content($i));
  }
}

# Test multiplication
SCOPE: {
  my $hcloneclone = $hclone->clone;
  $hcloneclone->multiply_histogram($h);
  foreach my $meth (qw(overflow underflow)) {
    is_approx($hcloneclone->$meth, $hclone->$meth * $h->$meth, "multiplication: $meth");
  }

  my $total = 0.;
  foreach my $i (0..$h->nbins-1) {
    my $x = $hclone->bin_content($i) * $h->bin_content($i);
    $total += $x;
    is_approx($hcloneclone->bin_content($i), $x, "multiplication: bin $i");
  }
  is_approx($hcloneclone->nfills, $hclone->nfills + $h->nfills, "multiplication: nfills");
  is_approx($hcloneclone->total, $total, "multiplication: total");
}

# Test division
SCOPE: {
  my $hcloneclone = $hclone->clone;
  my $h = $hclone->clone;
  $h->fill($_) for map 0.05 + $_/10, -2..11;

  $hcloneclone->divide_histogram($h);
  foreach my $meth (qw(overflow underflow)) {
    is_approx($hcloneclone->$meth, $hclone->$meth / $h->$meth, "division: $meth");
  }

  my $total = 0.;
  foreach my $i (0..$h->nbins-1) {
    my $x = eval {$hclone->bin_content($i) / $h->bin_content($i)};
    $total += $x;
    is_approx($hcloneclone->bin_content($i), $x, "division: bin $i");
  }
  is_approx($hcloneclone->nfills, $hclone->nfills + $h->nfills, "division: nfills");
  is_approx($hcloneclone->total, $total, "division: total");
}

SCOPE: {
  my $exp = [map $_/10, 0..9];
  my $c = $h->bin_centers();
  my $up = $h->bin_upper_boundaries();
  my $low = $h->bin_lower_boundaries();
  for (0..9) {
    is_approx($low->[$_], $exp->[$_], "Bin $_ is lower boundary is right");
    is_approx($h->bin_lower_boundary($_), $exp->[$_], "Bin $_ is lower boundary is right (extra call)");
    is_approx($c->[$_], $exp->[$_]+0.05, "Bin $_ center is right");
    is_approx($h->bin_center($_), $exp->[$_]+0.05, "Bin $_ center is right (extra call)");
    is_approx($up->[$_], $exp->[$_]+0.1, "Bin $_ upper boundary is right");
    is_approx($h->bin_upper_boundary($_), $exp->[$_]+0.1, "Bin $_ upper boundary is right (extra call)");
  }
}

# test clone from range
$h = Math::SimpleHisto::XS->new(nbins => 10, min => 0, max => 1);
$h->fill(-123., 99.1);
$h->fill(123., 199.1);
$h->set_bin_content($_, $_+1) for 0..9;
$hclone = $h->new_from_bin_range(2, 5);
my $hclone_empty = $h->new_alike_from_bin_range(2, 5);
isa_ok($h, "Math::SimpleHisto::XS") for ($hclone, $hclone_empty);

is($hclone->nfills, $h->nfills, "range clone nfills");
is($hclone_empty->nfills, 0, "range clone empty nfills");
is($hclone->nbins, 4, "range clone nbins");
is($hclone_empty->nbins, 4, "empty range clone nbins");
is_approx($hclone->total, $h->bin_content(2)+$h->bin_content(3)
                         +$h->bin_content(4)+$h->bin_content(5), "range clone total");
is_approx($hclone->underflow, $h->underflow+$h->bin_content(0)+$h->bin_content(1), "range clone underflow");
is_approx($hclone->overflow, $h->overflow+$h->bin_content(6)+$h->bin_content(7)
                                         +$h->bin_content(8)+$h->bin_content(9),
          "range clone overflow");
is_approx($hclone_empty->underflow, 0., "range clone empty underflow");
is_approx($hclone_empty->overflow, 0., "range clone empty overflow");

foreach my $i (2..5) {
  is_approx($hclone->bin_content($i-2), $h->bin_content($i), "range clone bin content $i or $i-2");
  is_approx($hclone->bin_lower_boundary($i-2), $h->bin_lower_boundary($i), "range clone bin lower bound $i or $i-2");
  is_approx($hclone->bin_upper_boundary($i-2), $h->bin_upper_boundary($i), "range clone bin upper bound $i or $i-2");
  is_approx($hclone->bin_center($i-2), $h->bin_center($i), "range clone bin center $i or $i-2");
}

is_deeply($hclone->bin_centers, $hclone_empty->bin_centers, "Cloned bin centers agree");

# memory leaks
#while (1) {do {my $x = $h->all_bin_contents()}}
#while (1) {  do {my $h = Math::SimpleHisto::XS->new(nbins => 100, min => 0, max => 1);};}
#while (1) {  do {$h->fill([0.5], [1.]);};}

done_testing;
