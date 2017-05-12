#!perl 
use strict;
use warnings;
use Test::More tests => 33;
use Test::JSON;
use Geo::Google::MapObject;

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>"512x640");
   ok($map, "map created");
   ok($map->static_map_url eq "http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x640", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[],"mobile":"false","center":"Berlin","size":{"width":"512","height":"640"}}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 640, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>"600x100");
   ok($map, "map created");
   ok($map->static_map_url eq "http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=600x100", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[],"mobile":"false","center":"Berlin","size":{"width":"600","height":"100"}}', "json");
   ok($map->width == 600, "width");
   ok($map->height == 100, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width=>100,height=>200});
   ok($map, "map created");
   ok($map->static_map_url eq "http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=100x200", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[],"mobile":"false","center":"Berlin","size":{"width":"100","height":"200"}}', "json");
   ok($map->width == 100, "width");
   ok($map->height == 200, "height");
}

eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width1=>100,height=>200})};
like($@, qr/^no width/, "no width");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width=>100,height1=>200})};
like($@, qr/^no height/, "no height");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>"100X200")};
like($@, qr/^cannot recognize size/, "X instead of x");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>"100x2000")};
like($@, qr/^cannot recognize size/, "massive height");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>"-100x200")};
like($@, qr/^cannot recognize size/, "negative width");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width=>-10,height=>1})};
like($@, qr/^width should positive and be no more than 640 /, "negative width");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width=>641,height=>1})};
like($@, qr/^width should positive and be no more than 640 /, "boundary condition");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width=>10,height=>-1})};
like($@, qr/^height should positive and be no more than 640 /, "negative height");
eval{ Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>{width=>10,height=>641})};
like($@, qr/^height should positive and be no more than 640 /, "boundary condition");

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10);
   ok($map, "map created");
   ok($map->static_map_url eq "http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api1&amp;sensor=false", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[],"mobile":"false","center":"Berlin"}', "json");
   ok(!defined($map->width), "width");
   ok(!defined($map->height), "height");
}
