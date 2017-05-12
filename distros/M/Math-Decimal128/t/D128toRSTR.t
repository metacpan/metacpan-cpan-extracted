use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..6\n";

my @n  = qw(1001.95  1.85  1.84  1.86  1.851 1.850001 99.95  0.95  1234567);
my @s  = qw(1002.0   1.8   1.8   1.9   1.9   1.9      100.0  1.0   1234567.0   inf -inf nan);
my @s2 = qw(1001.95  1.85  1.84  1.86  1.85  1.85     99.95  0.95  1234567.00  inf -inf nan);
my @s3 = qw(1001.950 1.850 1.840 1.860 1.851 1.850    99.950 0.950 1234567.000 inf -inf nan);

push @n, InfD128(1), InfD128(-1), NaND128();

my $ok = 1;

for(my $i = 0; $i < @n; $i++) {
  my $d128 = Math::Decimal128->new($n[$i]);
  my $neg_d128 = $d128 * - 1;
  my $str = D128toRSTR($d128, 1);
  my $nstr = D128toRSTR($neg_d128, 1);
  #next if $nstr =~ /n/;
  if($str ne $s[$i]) {
    warn "\n$i: Expected $s[$i]\nGot $str\n";
    $ok = 0;
  }
  if($nstr ne '-' . $s[$i]) {
    next if ($nstr eq 'inf' && $s[$i] eq '-inf');
    next if ($nstr eq 'nan' && $s[$i] eq 'nan');
    warn "\n$i: Expected -$s[$i]\nGot $nstr\n";
    $ok = 0;
  }
}

if($ok) {print "ok 1\n"}
else    {print "not ok 1\n"}

$ok = 1;

@s = qw(1002    2    2    2    2     2        100   1    1234567   inf -inf nan);

for(my $i = 0; $i < @n; $i++) {
  my $d128 = Math::Decimal128->new($n[$i]);
  my $neg_d128 = $d128 * - 1;
  my $str = D128toRSTR($d128, 0);
  my $nstr = D128toRSTR($neg_d128, 0);
  #next if $nstr =~ /n/;
  if($str ne $s[$i]) {
    warn "\n$i: Expected $s[$i]\nGot $str\n";
    $ok = 0;
  }
  if($nstr ne '-' . $s[$i]) {
    next if ($nstr eq 'inf' && $s[$i] eq '-inf');
    next if ($nstr eq 'nan' && $s[$i] eq 'nan');
    warn "\n$i: Expected -$s[$i]\nGot $nstr\n";
    $ok = 0;
  }
}

if($ok) {print "ok 2\n"}
else    {print "not ok 2\n"}

$ok = 1;

for(my $i = 0; $i < @n; $i++) {
  my $d128 = Math::Decimal128->new($n[$i]);
  my $neg_d128 = $d128 * - 1;
  my $str = D128toRSTR($d128, 2);
  my $nstr = D128toRSTR($neg_d128, 2);
  #next if $nstr =~ /n/;
  if($str ne $s2[$i]) {
    warn "\n$i: Expected $s2[$i]\nGot $str\n";
    $ok = 0;
  }
  if($nstr ne '-' . $s2[$i]) {
    next if ($nstr eq 'inf' && $s2[$i] eq '-inf');
    next if ($nstr eq 'nan' && $s2[$i] eq 'nan');
    warn "\n$i: Expected -$s2[$i]\nGot $nstr\n";
    $ok = 0;
  }
}

if($ok) {print "ok 3\n"}
else    {print "not ok 3\n"}

$ok = 1;

for(my $i = 0; $i < @n; $i++) {
  my $d128 = Math::Decimal128->new($n[$i]);
  my $neg_d128 = $d128 * - 1;
  my $str = D128toRSTR($d128, 3);
  my $nstr = D128toRSTR($neg_d128, 3);
  #next if $nstr =~ /n/;
  if($str ne $s3[$i]) {
    warn "\n$i: Expected $s3[$i]\nGot $str\n";
    $ok = 0;
  }
  if($nstr ne '-' . $s3[$i]) {
    next if ($nstr eq 'inf' && $s3[$i] eq '-inf');
    next if ($nstr eq 'nan' && $s3[$i] eq 'nan');
    warn "\n$i: Expected -$s3[$i]\nGot $nstr\n";
    $ok = 0;
  }
}

if($ok) {print "ok 4\n"}
else    {print "not ok 4\n"}

$ok = 1;

@n = qw(2.999 0.0005 0.00007 0.00050001 0.0095 323.4   323.411 323.5001 323.9995 32.99940 inf -inf nan);
@s = qw(2.999 0.000  0.000   0.001      0.010  323.400 323.411 323.500    324.000  32.999 inf -inf nan);

for(my $i = 0; $i < @n; $i++) {
  my $d128 = Math::Decimal128->new($n[$i]);
  my $neg_d128 = $d128 * - 1;
  my $str = D128toRSTR($d128, 3);
  my $nstr = D128toRSTR($neg_d128, 3);
  #next if $nstr =~ /n/;
  if($str ne $s[$i]) {
    warn "\n$i: Expected $s[$i]\nGot $str\n";
    $ok = 0;
  }
  if($nstr ne '-' . $s[$i]) {
    next if ($nstr eq 'inf' && $s[$i] eq '-inf');
    next if ($nstr eq 'nan' && $s[$i] eq 'nan');
    warn "\n$i: Expected -$s[$i]\nGot $nstr\n";
    $ok = 0;
  }
}

if($ok) {print "ok 5\n"}
else    {print "not ok 5\n"}

$ok = 1;

eval{D128toRSTR(Math::Decimal128->new(234), -1);};

if($@ =~ /2nd arg to D128toRSTR\(\)/) {print "ok 6\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 6\n";
}

#sub random_select {
#  my $ret = '';
#  for(1 .. $_[0]) {
#    $ret .= int(rand(10));
#  }
#  return "$ret";
#}

##############################
##############################
##############################

