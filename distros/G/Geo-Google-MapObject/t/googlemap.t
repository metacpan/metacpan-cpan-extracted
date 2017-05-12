#!perl 

use strict;
use warnings;
use Test::More tests => 17;
use Geo::Google::MapObject;
use Test::Differences;
use Test::JSON;
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
   my $map = Geo::Google::MapObject->new ( key=>'api1', center=>'Berlin',zoom=>10,size=>"512x512");
   ok($map, "map created");
   ok($map->static_map_url eq "http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api1&amp;sensor=false&amp;size=512x512", "static_map_url");
   ok($map->javascript_url eq "http://maps.google.com/maps?file=api&amp;v=2&amp;key=api1&amp;sensor=false", "javascript_url");
   is_json($map->json, '{"sensor":"false","zoom":"10","markers":[],"mobile":"false","center":"Berlin","size":{"width":"512","height":"512"}}', "json");
   ok($map->width == 512, "width");
   ok($map->height == 512, "height");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api2', center=>'Berlin',zoom=>10, size=>"512x512");
   my $t = HTML::Template::Pluggable->new(scalarref=>\$template, die_on_bad_params=>0);
   $t->param(map=>$map);
   my $output =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=api2&amp;sensor=false" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api2&amp;sensor=false&amp;size=512x512" width="512" height="512"/>
     
   </body>
</html>
EOS
;
   eq_or_diff($t->output, $output, "zero markers");
}


{
   my $map = Geo::Google::MapObject->new ( key=>'api3', center=>'Berlin',zoom=>10, markers=>[{location=>'Zoo'},{location=>'Garten'},{location=>'Polizei'}], size=>"512x512");
   my $t = HTML::Template::Pluggable->new(scalarref=>\$template, die_on_bad_params=>0);
   $t->param(map=>$map);
   my $output =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=api3&amp;sensor=false" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api3&amp;sensor=false&amp;size=512x512&amp;markers=Zoo|Garten|Polizei" width="512" height="512"/>
     
     <table>
     
       <tr><td>Zoo</td></tr>
     
       <tr><td>Garten</td></tr>
     
       <tr><td>Polizei</td></tr>
     
     </table>
     
   </body>
</html>
EOS
;
   eq_or_diff($t->output, $output, "location markers");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[{"location":"Zoo"},{"location":"Garten"},{"location":"Polizei"}],"mobile":"false","center":"Berlin","size":{"width":"512","height":"512"}}', "json");
}



{
   my $map = Geo::Google::MapObject->new ( key=>'api4', center=>'Berlin',zoom=>10, markers=>[{location=>'Zoo',label=>'Z'},{location=>'Garten',label=>'G'},{location=>'Polizei',label=>'P'}], size=>"512x512");
   my $t = HTML::Template::Pluggable->new(scalarref=>\$template, die_on_bad_params=>0);
   $t->param(map=>$map);
   my $output =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=api4&amp;sensor=false" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api4&amp;sensor=false&amp;size=512x512&amp;markers=label:G|Garten&amp;markers=label:P|Polizei&amp;markers=label:Z|Zoo" width="512" height="512"/>
     
     <table>
     
       <tr><td>Zoo</td></tr>
     
       <tr><td>Garten</td></tr>
     
       <tr><td>Polizei</td></tr>
     
     </table>
     
   </body>
</html>
EOS
;
   eq_or_diff($t->output, $output, "label markers");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[{"location":"Zoo","label":"Z"},{"location":"Garten","label":"G"},{"location":"Polizei","label":"P"}],"mobile":"false","center":"Berlin","size":{"width":"512","height":"512"}}', "json");
}





{
   my $map = Geo::Google::MapObject->new ( key=>'api5', center=>'Berlin',zoom=>10, markers=>[{location=>'Zoo',color=>'red'},{location=>'Garten',color=>'red'},{location=>'Polizei',color=>'green'}], size=>"512x512");
   my $t = HTML::Template::Pluggable->new(scalarref=>\$template, die_on_bad_params=>0);
   $t->param(map=>$map);
   my $output =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=api5&amp;sensor=false" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api5&amp;sensor=false&amp;size=512x512&amp;markers=color:green|Polizei&amp;markers=color:red|Zoo|Garten" width="512" height="512"/>
     
     <table>
     
       <tr><td>Zoo</td></tr>
     
       <tr><td>Garten</td></tr>
     
       <tr><td>Polizei</td></tr>
     
     </table>
     
   </body>
</html>
EOS
;
   eq_or_diff($t->output, $output, "label markers");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[{"color":"red","location":"Zoo"},{"color":"red","location":"Garten"},{"color":"green","location":"Polizei"}],"mobile":"false","center":"Berlin","size":{"width":"512","height":"512"}}', "json");
}

{
   my $map = Geo::Google::MapObject->new ( key=>'api6', center=>'Berlin',zoom=>10, markers=>[{location=>'Zoo',color=>'red',size=>'tiny'},{location=>'Garten',color=>'red',size=>'small'},{location=>'Polizei',color=>'green'}], size=>"512x512");
   my $t = HTML::Template::Pluggable->new(scalarref=>\$template, die_on_bad_params=>0);
   $t->param(map=>$map);
   my $output =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=api6&amp;sensor=false" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api6&amp;sensor=false&amp;size=512x512&amp;markers=color:green|Polizei&amp;markers=color:red|size:small|Garten&amp;markers=color:red|size:tiny|Zoo" width="512" height="512"/>
     
     <table>
     
       <tr><td>Zoo</td></tr>
     
       <tr><td>Garten</td></tr>
     
       <tr><td>Polizei</td></tr>
     
     </table>
     
   </body>
</html>
EOS
;
   eq_or_diff($t->output, $output, "label markers");
   is_json($map->json, '{"zoom":"10","sensor":"false","markers":[{"color":"red","location":"Zoo","size":"tiny"},{"color":"red","location":"Garten","size":"small"},{"color":"green","location":"Polizei"}],"mobile":"false","center":"Berlin","size":{"width":"512","height":"512"}}', "json");
}

{
   my $map = Geo::Google::MapObject->new (hl=>'de', key=>'api7', center=>'Berlin',zoom=>10, markers=>[{location=>'Zoo',color=>'red',size=>'tiny'},{location=>'Garten',color=>'red',size=>'small'},{location=>'Polizei',color=>'green'},{location=>'Schlo&szlig;',color=>'green'}], size=>"512x512");
   my $t = HTML::Template::Pluggable->new(scalarref=>\$template, die_on_bad_params=>0);
   $t->param(map=>$map);
   my $output =<<EOS;
<html>
   <head>
     <title>Test</title>
     <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=api7&amp;sensor=false&amp;hl=de" type="text/javascript"></script>
   </head>
   <body>
     <img alt="TEST" src="http://maps.google.com/maps/api/staticmap?center=Berlin&amp;zoom=10&amp;mobile=false&amp;key=api7&amp;sensor=false&amp;size=512x512&amp;markers=color:green|Polizei|Schlo&szlig;&amp;markers=color:red|size:small|Garten&amp;markers=color:red|size:tiny|Zoo" width="512" height="512"/>
     
     <table>
     
       <tr><td>Zoo</td></tr>
     
       <tr><td>Garten</td></tr>
     
       <tr><td>Polizei</td></tr>
     
       <tr><td>Schlo&szlig;</td></tr>
     
     </table>
     
   </body>
</html>
EOS
;
   eq_or_diff($t->output, $output, "label markers");
   is_json($map->json, '{"zoom":"10","sensor":"false","mobile":"false","center":"Berlin","size":{"width":"512","height":"512"},"hl":"de","markers":[{"color":"red","location":"Zoo","size":"tiny"},{"color":"red","location":"Garten","size":"small"},{"color":"green","location":"Polizei"},{"color":"green","location":"Schlo&szlig;"}]}', "json");
}

