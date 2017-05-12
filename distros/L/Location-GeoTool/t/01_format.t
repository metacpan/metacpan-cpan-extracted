use strict;
use Test::More tests => 393;

BEGIN { use_ok 'Location::GeoTool' }

my @key = ('mapion','dmsn','second','degree','radian','gpsone','spacetag');
my @testcase = (
  [
    '35/39/24.491','139/40/10.478','353924.491','1394010.478',128364.491,502810.478,35.6568031,139.6695772,
    0.622328614,2.437693987,'35.39.24.491','139.40.10.478','+0353924491','+1394010478'
  ],
  [
    '40/36/14.307','141/01/33.022','403614.307','1410133.022',146174.307,507693.022,40.6039742,141.0258394,
    0.708673039,2.461365229,'40.36.14.307','141.01.33.022','+0403614307','+1410133022'
  ],
  [
    '32/36/57.906','131/11/01.538','323657.906','1311101.538',117417.906,472261.538,32.6160850,131.1837606,
    0.569258072,2.289588547,'32.36.57.906','131.11.01.538','+0323657906','+1311101538'
  ],
  [
    '28/11/38.862','129/19/45.892','281138.862','1291945.892',101498.862,465585.892,28.1941283,129.3294144,
    0.492080369,2.257224102,'28.11.38.862','129.19.45.892','+0281138862','+1291945892'
  ]
);

foreach my $testcase (@testcase)
{
  for (my $i = 0;$i < @key;$i++)
  {
    my @tc = @{$testcase};
    my $obj = Location::GeoTool->create_coord($tc[$i*2],$tc[$i*2+1],'wgs84',$key[$i]);
    for (my $j = 0;$j < @key;$j++)
    {
      my $meth = 'format_'.$key[$j];
      my ($clat,$clong) = $obj->$meth->array;
      my ($tlat,$tlong) = ($tc[$j*2],$tc[$j*2+1]);
      ($clat,$clong,$tlat,$tlong) = map { sprintf("%.3f",$_) } ($clat,$clong,$tlat,$tlong) if ($key[$j] eq 'second');
      ($clat,$clong,$tlat,$tlong) = map { sprintf("%.5f",$_) } ($clat,$clong,$tlat,$tlong) if ($key[$j] eq 'degree');
      ($clat,$clong,$tlat,$tlong) = map { sprintf("%.6f",$_) } ($clat,$clong,$tlat,$tlong) if ($key[$j] eq 'radian');
      is $clat, $tlat;
      is $clong, $tlong;
    }
  }
}

