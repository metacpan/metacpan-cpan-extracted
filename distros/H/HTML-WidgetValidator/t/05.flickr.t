use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'FlickrBadge' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Flickr Badge 1
--- input
<style type="text/css">
.zg_div {margin:0px 5px 5px 0px; width:117px;}
.zg_div_inner {border: solid 1px #000000; background-color:#ffffff; color:#666666; text-align:center; font-family:arial, helvetica; font-size:11px;}
.zg_div a, .zg_div a:hover, .zg_div a:visited {color:#3993ff; background:inherit !important; text-decoration:none !important;}
</style>
--- expected
Flickr Bagde

=== Flickr Badge 2
--- input
<script type="text/javascript">
zg_insert_badge = function() {
var zg_bg_color = 'ffffff';
var zgi_url = 'http://www.flickr.com/apps/badge/badge_iframe.gne?zg_bg_color='+zg_bg_color+'&';
document.write('<iframe style="background-color:#'+zg_bg_color+'; border-color:#'+zg_bg_color+'; border:none;" width="113" height="151" frameborder="0" scrolling="no" src="'+zgi_url+'" title="Flickr Badge"><\/iframe>');
if (document.getElementById) document.write('<div id="zg_whatlink"><a href="http://www.flickr.com/badge.gne"	style="color:#3993ff;" onclick="zg_toggleWhat(); return false;">What is this?<\/a><\/div>');
}
zg_toggleWhat = function() {
document.getElementById('zg_whatdiv').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
document.getElementById('zg_whatlink').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
return false;
}
</script>
--- expected
Flickr Bagde

=== Flickr Badge 3
--- input
<script type="text/javascript">zg_insert_badge();</script>
--- expected
Flickr Bagde

=== Flickr Badge 4
--- input
<script type="text/javascript">if (document.getElementById) document.getElementById('zg_whatdiv').style.display = 'none';</script>
--- expected
Flickr Bagde

=== Flickr Badge 5
--- input
<style type="text/css">
.zg_div {margin:0px 5px 5px 0px; width:117px;}
.zg_div_inner { color:#FF66FF; text-align:center; font-family:arial, helvetica; font-size:11px;}
.zg_div a, .zg_div a:hover, .zg_div a:visited {color:#00FF00; background:inherit !important; text-decoration:none !important;}
</style>
--- expected
Flickr Bagde

=== Flickr Badge 6
--- input
<script type="text/javascript">
zg_insert_badge = function() {
var zg_bg_color = 'ffffff';
var zgi_url = 'http://www.flickr.com/apps/badge/badge_iframe.gne?zg_bg_color='+zg_bg_color+'&zg_person_id=72225163%40N00';
document.write('<iframe style="background-color:#'+zg_bg_color+'; border-color:#'+zg_bg_color+'; border:none;" width="113" height="151" frameborder="0" scrolling="no" src="'+zgi_url+'" title="Flickr Badge"><\/iframe>');
if (document.getElementById) document.write('<div id="zg_whatlink"><a href="http://www.flickr.com/badge.gne"	style="color:#00FF00;" onclick="zg_toggleWhat(); return false;">What is this?<\/a><\/div>');
}
zg_toggleWhat = function() {
document.getElementById('zg_whatdiv').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
document.getElementById('zg_whatlink').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
return false;
}
</script>
--- expected
Flickr Bagde

=== Flickr Badge 7
--- input
<style type="text/css">
.zg_div {margin:0px 5px 5px 0px; width:117px;}
.zg_div_inner { color:#666666; text-align:center; font-family:arial, helvetica; font-size:11px;}
.zg_div a, .zg_div a:hover, .zg_div a:visited {color:#3993ff; background:inherit !important; text-decoration:none !important;}
</style>
--- expected
Flickr Bagde

=== Flickr Badge 8
--- input
<script type="text/javascript">
zg_insert_badge = function() {
var zg_bg_color = 'ffffff';
var zgi_url = 'http://www.flickr.com/apps/badge/badge_iframe.gne?zg_bg_color='+zg_bg_color+'&zg_person_id=77214379%40N00';
document.write('<iframe style="background-color:#'+zg_bg_color+'; border-color:#'+zg_bg_color+'; border:none;" width="113" height="151" frameborder="0" scrolling="no" src="'+zgi_url+'" title="Flickr Badge"><\/iframe>');
if (document.getElementById) document.write('<div id="zg_whatlink"><a href="http://www.flickr.com/badge.gne"	style="color:#3993ff;" onclick="zg_toggleWhat(); return false;">What is this?<\/a><\/div>');
}
zg_toggleWhat = function() {
document.getElementById('zg_whatdiv').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
document.getElementById('zg_whatlink').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
return false;
}
</script>
--- expected
Flickr Bagde

=== Flickr Badge 9
--- input
<script type="text/javascript">
zg_insert_badge = function() {
var zg_bg_color = 'ffffff';
var zgi_url = 'http://www.flickr.com/apps/badge/badge_iframe.gne?zg_bg_color='+zg_bg_color+'&zg_tags=cat&zg_tag_mode=any';
document.write('<iframe style="background-color:#'+zg_bg_color+'; border-color:#'+zg_bg_color+'; border:none;" width="113" height="151" frameborder="0" scrolling="no" src="'+zgi_url+'" title="Flickr Badge"><\/iframe>');
if (document.getElementById) document.write('<div id="zg_whatlink"><a href="http://www.flickr.com/badge.gne"	style="color:#3993ff;" onclick="zg_toggleWhat(); return false;">What is this?<\/a><\/div>');
}
zg_toggleWhat = function() {
document.getElementById('zg_whatdiv').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
document.getElementById('zg_whatlink').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
return false;
}
</script>
--- expected
Flickr Bagde

=== Flickr Badge 10
--- input
<script type="text/javascript">
zg_insert_badge = function() {
var zg_bg_color = 'ffffff';
var zgi_url = 'http://www.flickr.com/apps/badge/badge_iframe.gne?zg_bg_color='+zg_bg_color+'&zg_person_id=72225163%40N00&zg_tags=jenga&zg_tag_mode=any';
document.write('<iframe style="background-color:#'+zg_bg_color+'; border-color:#'+zg_bg_color+'; border:none;" width="113" height="151" frameborder="0" scrolling="no" src="'+zgi_url+'" title="Flickr Badge"><\/iframe>');
if (document.getElementById) document.write('<div id="zg_whatlink"><a href="http://www.flickr.com/badge.gne"	style="color:#3993ff;" onclick="zg_toggleWhat(); return false;">What is this?<\/a><\/div>');
}
zg_toggleWhat = function() {
document.getElementById('zg_whatdiv').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
document.getElementById('zg_whatlink').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
return false;
}
</script>
--- expected
Flickr Bagde

=== Flickr Badge 11
--- input
<style type="text/css">
.zg_div {margin:0px 5px 5px 0px; width:117px;}
.zg_div_inner {border: solid 1px #000000; background-color:#ffffff;  color:#666666; text-align:center; font-family:arial, helvetica; font-size:11px;}
.zg_div a, .zg_div a:hover, .zg_div a:visited {color:#0063dc; background:inherit !important; text-decoration:none !important;}
</style>
--- expected
Flickr Bagde

=== Flickr Badge 12
--- input
<script type="text/javascript">
zg_insert_badge = function() {
var zg_bg_color = 'ffffff';
var zgi_url = 'http://www.flickr.com/apps/badge/badge_iframe.gne?zg_bg_color='+zg_bg_color+'&zg_person_id=84521258%40N00&zg_set_id=72157601255031956&zg_context=in%2Fset-72157601255031956%2F';
document.write('<iframe style="background-color:#'+zg_bg_color+'; border-color:#'+zg_bg_color+'; border:none;" width="113" height="151" frameborder="0" scrolling="no" src="'+zgi_url+'" title="Flickr Badge"><\/iframe>');
if (document.getElementById) document.write('<div id="zg_whatlink"><a href="http://www.flickr.com/badge.gne"	style="color:#0063dc;" onclick="zg_toggleWhat(); return false;">What is this?<\/a><\/div>');
}
zg_toggleWhat = function() {
document.getElementById('zg_whatdiv').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
document.getElementById('zg_whatlink').style.display = (document.getElementById('zg_whatdiv').style.display != 'none') ? 'none' : 'block';
return false;
}
</script>
--- expected
Flickr Bagde
