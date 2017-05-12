use strict;
use Test::More tests => 33;

BEGIN { use_ok 'Location::GeoTool' }

my @key = ('tokyo','wgs84');
my @testcase = (
  [ 128364.49100,502810.47800,128376.14524,502798.87076 ], 
  [ 146174.30700,507693.02200,146184.03707,507680.28556 ], 
  [ 117417.90600,472261.53800,117430.13724,472253.01868 ],
  [ 101498.86200,465585.89200,101512.48750,465578.47885 ] 
);

foreach my $testcase (@testcase)
{
  for (my $i = 0;$i < @key;$i++)
  {
    my @tc = @{$testcase};
    my $obj = Location::GeoTool->create_coord($tc[$i*2],$tc[$i*2+1],$key[$i],'second');
    for (my $j = 0;$j < @key;$j++)
    {
      my $meth = 'datum_'.$key[$j];
      my ($clat,$clong) = $obj->$meth->array;
      my ($tlat,$tlong) = ($tc[$j*2],$tc[$j*2+1]);
      ok abs($clat - $tlat) < 0.5;
      ok abs($clong - $tlong) < 0.5;
    }
  }
}

