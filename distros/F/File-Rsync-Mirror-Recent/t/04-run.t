#!perl -- -*- mode: cperl -*-

use Test::More;
use File::Spec;
sub _f ($) {File::Spec->catfile(split /\//, shift);}

my @s = grep {-x $_} grep { !/~/ } glob("bin/rrr*");

my $tests_per_loop = 3;
my $plan = scalar @s * $tests_per_loop;
plan tests => $plan;

my $devnull = File::Spec->devnull;
for my $s (1..@s) {
  my $script = _f($s[$s-1]);
  open my $fh, "-|", qq{"$^X" "-Ilib" "-cw" "$script" 2>&1} or die "could not fork: $!";
  while (<$fh>) {
      next if /syntax OK/;
      print;
  }
  my $ret = close $fh;
  ok 1==$ret, "$script:-c:$ret";
  open $fh, "-|", qq{"$^X" "-Ilib" "$script" "-help" 2>&1} or die "could not fork: $!";
  my $seen_usage = 0;
  while (<$fh>) {
    $seen_usage++ if /Usage:/;
  }
  $ret = close $fh;
  ok 1==$ret, "$script:-help:ret=$ret";
  ok 0<$seen_usage, "$script:-help:su=$seen_usage";
}

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
