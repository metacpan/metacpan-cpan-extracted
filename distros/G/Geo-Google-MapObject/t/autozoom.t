#!perl 

use strict;
use warnings;
use Test::More tests => 42;
use Geo::Google::MapObject;
use Test::Differences;
use Test::Deep;
use JSON;
use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;
our $template =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="<TMPL_VAR NAME="map.javascript_url">" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="<TMPL_VAR NAME="map.static_map_url">" width="<TMPL_VAR NAME="map.width">" height="<TMPL_VAR NAME="map.height">"/>
     <TMPL_IF NAME="map.markers">
     <table>
     <TMPL_LOOP NAME="map.markers">
       <tr><td><TMPL_VAR NAME="this.location"></td></tr>
     </TMPL_LOOP>
     </table>
     </TMPL_IF>
   </body>
</html>
EOS
;



{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"58.222128,-5.316499"}]);
   ok($map, "map created");
   ok($map->static_map_url eq "http://maps.google.com/maps/api/staticmap?center=58.222128,-5.316499&amp;zoom=21&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=58.222128,-5.316499", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"sensor":"false","zoom":"21","markers":[{"location": "58.222128,-5.316499"}],"mobile":"false","center":"58.222128,-5.316499","size":{"width":"512","height":"512"}}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"58.222128,-5.316499"},{location=>"58.22211,-5.315194"}]);
   ok($map, "map created");
   like($map->static_map_url, qr"^http://maps\.google\.com/maps/api/staticmap?center=58\.222119001\d+,-5\.315846\d+&amp;zoom=16&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=58\.222128,-5\.316499|58\.22211,-5\.315194$", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"16","sensor":"false","markers":[{"location":"58.222128,-5.316499"},{"location":"58.22211,-5.315194"}],"mobile":"false","size":{"width":"512","height":"512"},"center":"58.2221190016633,-5.31584649983455"}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"58.222128,-5.316499"},{location=>"58.22211,-5.315194"},{location=>"58.198937,-5.20546"}]);
   ok($map, "map created");
   like($map->static_map_url, qr"^http://maps\.google\.com/maps/api/staticmap?center=58\.21053\d+,-5\.26063523\d+&amp;zoom=9&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=58\.222128,-5\.316499|58\.22211,-5\.315194|58\.198937,-5\.20546$", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"9","sensor":"false","markers":[{"location":"58.222128,-5.316499"},{"location":"58.22211,-5.315194"},{"location":"58.198937,-5.20546"}],"mobile":"false","size":{"width":"512","height":"512"},"center":"58.210539904431,-5.26063523415997"}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"-16.807513,179.991839"},{location=>"-16.795715,-179.996503"},{location=>"-16.800433,179.999099"}]);
   ok($map, "map created");
   like($map->static_map_url, qr"^http://maps\.google\.com/maps/api/staticmap?center=-16\.801614\d+,179\.997668\d+&amp;zoom=11&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=-16\.807513,179\.991839|-16\.795715,-179\.996503|-16\.800433,179\.999099$", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"11","sensor":"false","markers":[{"location":"-16.807513,179.991839"},{"location":"-16.795715,-179.996503"},{"location":"-16.800433,179.999099"}],"mobile":"false","size":{"width":"512","height":"512"},"center":"-16.8016140820493,179.99766818121"}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"-16.807513,179.991839"},{location=>"-16.805715,-179.996503"},{location=>"-16.800433,179.999099"}]);
   ok($map, "map created");
   like($map->static_map_url, qr"^http://maps\.google\.com/maps/api/staticmap?center=-16\.806614\d+,179\.997668\d+&amp;zoom=12&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=-16\.807513,179\.991839|-16\.805715,-179\.996503|-16\.800433,179\.999099$", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"12","sensor":"false","markers":[{"location":"-16.807513,179.991839"},{"location":"-16.805715,-179.996503"},{"location":"-16.800433,179.999099"}],"mobile":"false","size":{"width":"512","height":"512"},"center":"-16.8066140820709,179.997668027625"}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"-16.805513,179.999939"},{location=>"-16.805715,-179.999903"},{location=>"-16.805433,179.999099"}]);
   ok($map, "map created");
   like($map->static_map_url, qr"^http://maps\.google\.com/maps/api/staticmap?center=-16\.805523\d+,179\.999558\d+&amp;zoom=15&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=-16\.805513,179\.999939|-16\.805715,-179\.999903|-16\.805433,179\.999099$", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"15","sensor":"false","markers":[{"location":"-16.805513,179.999939"},{"location":"-16.805715,-179.999903"},{"location":"-16.805433,179.999099"}],"mobile":"false","size":{"width":"512","height":"512"},"center":"-16.8055235005174,179.99955849975"}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api1', size=>"512x512", autozoom=>21, markers=>[{location=>"-16.8057131,179.999998"},{location=>"-16.805713,-179.999993"},{location=>"-16.8057129,179.999999"}]);
   ok($map, "map created");
   like($map->static_map_url, qr"^http://maps\.google\.com/maps/api/staticmap?center=-16\.805713\d+,-179\.999997\d+&amp;zoom=21&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512&amp;markers=-16\.8057131,179\.999998|-16\.805713,-179\.999993|-16\.8057129,179\.999999$", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"zoom":"21","sensor":"false","markers":[{"location":"-16.8057131,179.999998"},{"location":"-16.805713,-179.999993"},{"location":"-16.8057129,179.999999"}],"mobile":"false","size":{"width":"512","height":"512"},"center":"-16.8057130500001,-179.9999975"}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}


sub is_json {
	my $got_text = shift;
	my $expected_text = shift;
	my $name = shift;
	my $got = JSON->new->utf8->decode($got_text);
	my $expected = JSON->new->decode($expected_text);
	my $ex_center = $expected->{center};
	my ($ex_x, $ex_y) = split(",", $ex_center);
	$expected->{center} = code(sub {
		my ($x, $y) = split(",", shift);
		my $tolerance = 0.0000000001;
		return abs($x-$ex_x) < $tolerance && abs($y-$ex_y) < $tolerance;
	});
	cmp_deeply($got, $expected, $name);
}

