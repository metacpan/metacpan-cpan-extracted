use strict;
use Test::More tests => 73;

BEGIN { use_ok 'Location::GeoTool' }

my @testcase = (
  ['353924.491','1394010.478'],
  ['403614.307','1410133.022'],
  ['323657.906','1311101.538'],
  ['281138.862','1291945.892']
);
my @result = (
  [
    [],
    [11.8035750,561836.65713],
    [249.1127114,851878.29734],
    [232.6026041,1279581.44566]
  ],
  [
    [192.6418109,561836.65713],
    [],
    [227.8483170,1247809.15636],
    [221.4801454,1743448.25043]
  ],
  [
    [64.3430830,851878.29734],
    [41.9551613,1247809.15636],
    [],
    [200.4513258,521565.01988]
  ],
  [
    [47.1121436,1279581.44566],
    [34.8174208,1743448.25043],
    [19.5120587,521565.01988],
    []
  ]
);

for (my $i = 0;$i < @testcase;$i++)
{
  my @from = @{$testcase[$i]};
  my $obj = Location::GeoTool->create_coord($from[0],$from[1],'wgs84','dmsn');
  for (my $j = 0;$j < @testcase;$j++)
  {
    next if ($i == $j);
    my @cto = @{$testcase[$j]};
    my ($tdir,$tdist) = @{$result[$i]->[$j]};
    my $dirobj = $obj->direction_point($cto[0],$cto[1],'wgs84','dmsn');
    isa_ok $dirobj, 'Location::GeoTool::Direction';
    my ($cdir,$cdist) = map { $dirobj->$_ } ('direction','distance');
    ($tdir,$cdir) = map { sprintf("%.2f",$_) } ($tdir,$cdir);
    ($tdist,$cdist) = map { sprintf("%d",$_) } ($tdist,$cdist);
    is $tdir,$cdir;
    is $tdist,$cdist;

    $dirobj = $obj->direction_vector(@{$result[$i]->[$j]});
    isa_ok $dirobj, 'Location::GeoTool::Direction';
    my ($clat,$clong) = $dirobj->to_point->array;
     
    is $clat, $cto[0];
    is $clong, $cto[1];
  }
}

