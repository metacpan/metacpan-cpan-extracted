# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Encode::Float' ); }

my $floatEncoder = Encode::Float->new ();
isa_ok ($floatEncoder, 'Encode::Float');

my @list;

my $totalTests = 5;
for (my $testNo = 0; $testNo < $totalTests; $testNo++)
{
  srand ($testNo);
  my $list = getTestList ();
  if (!isListCorrect ($list))
  {
    ok (0, "Test number $testNo failed.");
  }
  else
  {
    ok (1, "Test number $testNo passed.");
  }
}

sub isListCorrect
{
  my $list = $_[0];
  for (my $i = 1; $i < @$list; $i++)
  {
    if ($list->[$i - 1][1] > $list->[$i][1])
    {
      print $list->[$i - 1] . "\n";
      print $list->[$i] . "\n";
      warn "value $list->[$i - 1][1] > $list->[$i][1]\n";
    }
    
    my $error = getRelativeDifference ($list->[$i][1], $list->[$i][2]);
    if ($error > 1e-6)
    {
      print $list->[$i - 1] . "\n";
      print $list->[$i] . "\n";
      print "relative difference between $list->[$i][1], $list->[$i][2] is too large.\n";
      return 0;
    }
  }
  
  return 1;
}

sub getRelativeDifference
{
  my $max    = abs $_[0];
  my $value1 = abs $_[1];
  $max = $value1 if $value1 > $max;
  return 0 if $max == 0;
  return abs($_[0] - $_[1]) / $max;
}

sub getTestList
{
  my $size = 1 + int rand 50000;
  my @list;
  for (my $i = 0; $i < $size; $i++)
  {
    my $sign = 1;
    $sign = -1 if rand() < .5;
    my $exp = 200 - int rand 401;
    my $mant = rand 2;
    my $v = $sign * $mant * 10**$exp;
    push @list, [$floatEncoder->encode ($v), $v, $floatEncoder->decode ($floatEncoder->encode ($v)), sprintf ("%+16.14E", $v)];  
  }
  push @list, [$floatEncoder->encode (0), 0, $floatEncoder->decode ($floatEncoder->encode (0))];
  return [sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @list];
}
