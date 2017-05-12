use strict;
use warnings FATAL => 'all';

use Test::More tests => 129;
use File::Temp qw(tempdir);
use File::Slurp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

BEGIN { use_ok("HTML::Tested::JavaScript::ColorPicker");
	use_ok('HTML::Tested::JavaScript', qw(HTJ $Location));

	our $_T = 114; do "t/use_guitester.pl";
};

$Location = "javascript";

package H;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::ColorPicker", "cp");
__PACKAGE__->ht_add_widget(::HTJ . "::ColorPicker", "nothing");

package main;

my $obj = H->new;
my $stash = {};
$obj->ht_render($stash);
isnt($stash->{cp_color}, undef);
isnt($stash->{cp_hue}, undef);

my $td = tempdir('/tmp/ht_color_p_XXXXXX', CLEANUP => 1);
write_file("$td/a.html", <<ENDS);
<html>
<head><title>Color Picker</title>
<script src="javascript/color_picker.js"></script>
<style>
$stash->{cp_color_sample_style}
$stash->{cp_color_style}
$stash->{cp_hue_style}
$stash->{nothing_color_style}
$stash->{nothing_hue_style}
#nothing_color {
	height: 22px;
}
</style>
<script>
htcp_init("nothing", function(name, r, g, b) {
	alert("nothing " + name + " " + r + " " + g + " " + b); 
});
htcp_init("cp", function(name, r, g, b) {
	alert("cp " + name + " " + r + " " + g + " " + b); 
});
</script>
</head>
<body>
<form method="post" action="/just_in_case">
<!-- check that init still works -->
<div id="nothing_cont" style="display: none;"> 
$stash->{nothing_color}
$stash->{nothing_hue}
</div>
$stash->{cp_color}
$stash->{cp_hue}
$stash->{cp_rgb_r}
$stash->{cp_rgb_g}
$stash->{cp_rgb_b}
$stash->{cp_rgb_hex}
$stash->{cp_color_sample}
</form>
</body>
</html>
ENDS

symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");
write_file("$td/abs.html", <<'ENDS');
<html>
<head>
<script src="javascript/color_picker.js"></script>
<body style="position: relative;">
<div id="d1" style="position: absolute; top: 10px; left: 10px;">
<div id="d2" style="position: absolute; top: 10px; left: 10px;">
<div id="d3" style="position: absolute; top: 10px; left: 10px;"></div>
</div>
</div>
</body>
</head>
</html>
ENDS

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
ok($mech->get("file://$td/abs.html"));
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return htcp_get_absolute_offsets(document.getElementById("d3")).toString()')
	, "30,30") or exit 1;
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return htcp_get_absolute_offsets('
	. 'document.getElementById("d3"), document.getElementById("d1"))'
	. '.toString()'), "20,20") or exit 1;
is_deeply($mech->console_messages, []) or exit 1;

ok($mech->get("file://$td/a.html"));
is($mech->title, "Color Picker");
is_deeply($mech->console_messages, []) or exit 1;
is($mech->get_element_style_by_id("nothing_color", "height"), "22px");
is($mech->get_element_style_by_id("cp_current_color", "height"), "60px");

unlike($mech->pull_alerts, qr/nothing nothing 255 255 255/);
is_deeply($mech->console_messages, []) or exit 1;
$mech->run_js('document.getElementById("nothing_cont").style.display'
	. '= "block"');
$mech->run_js('htcp_set_indicators_from_rgb("nothing", 12, 13, 14);');
is_deeply($mech->console_messages, []) or exit 1;
like($mech->pull_alerts, qr/nothing nothing 12 13 14/);

$mech->run_js('htcp_set_indicators_from_rgb("cp", 255, 255, 255);');
is_deeply($mech->console_messages, []) or exit 1;

my $res = $mech->run_js('return htcp_int_to_rgb(122922).toString()');
is($res, '1,224,42') or exit 1;

$res = $mech->run_js('return htcp_rgb_to_hsv(0, 0, 0).toString()');
is_deeply($mech->console_messages, []) or exit 1;
is($res, '0,0,0') or exit 1;
is($mech->run_js('return htcp_rgb_to_hsv(87, 149, 50).toString()')
	, '98,66,58') or exit 1;
is($mech->run_js('return htcp_rgb_to_hsv(52, 100, 56).toString()')
	, '125,48,39') or exit 1;
is($mech->run_js('return htcp_rgb_to_hsv(255, 255, 255).toString()')
	, '360,0,100') or exit 1;
is_deeply($mech->console_messages, []) or exit 1;

my $cp_div = $mech->get_html_element_by_id("cp_color");
isnt($cp_div, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($cp_div, "background-image")
	, qr/color_picker\.png/);

my $point = $mech->get_html_element_by_id("cp_color_pointer");
isnt($point, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($point, "background-image")
	, qr/color_picker\.png/);
is_deeply($mech->console_messages, []) or exit 1;

my $cur_color = $mech->get_html_element_by_id("cp_current_color");
isnt($cur_color, undef) or exit 1;

my $prev_color = $mech->get_html_element_by_id("cp_prev_color");
isnt($prev_color, undef) or exit 1;

my $rr = $mech->get_html_element_by_id("cp_rgb_r", "Input");
my $rg = $mech->get_html_element_by_id("cp_rgb_g", "Input");
my $rb = $mech->get_html_element_by_id("cp_rgb_b", "Input");
isnt($rr, undef);
isnt($rg, undef);
isnt($rb, undef);
is($rr->GetValue, 255);
is($rg->GetValue, 255);
is($rb->GetValue, 255);

is($mech->get_element_style($cur_color, "background-color"), "rgb(255, 255, 255)");
is($mech->get_element_style($prev_color, "background-color"), "rgb(255, 255, 255)");

my $mg1 = $mech->gesture($point);
$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, 22, 22);
is_deeply($mech->console_messages, []) or exit 1;

my $mg2 = $mech->gesture($point);
is($mg2->element_left - $mg1->element_left, 21) or do {
	diag($mech->pull_alerts);
	exit 1;
};
is($mg2->element_top - $mg1->element_top, 21);
is_deeply($mech->console_messages, []) or exit 1;

is($rr->GetValue, 227);
is($rg->GetValue, 202);
is($rb->GetValue, 202);
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 202)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 202)");

$res = $mech->run_js('return htcp_current_color("cp").toString()');
is_deeply($mech->console_messages, []) or exit 1;
is($res, '227,202,202');

$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, -16, -16);

my $mg5 = $mech->gesture($point);
is($mg5->element_left - $mg1->element_left, 2) or exit 1;

$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, 202, 202);

my $mg3 = $mech->gesture($point);
is($mg3->element_left - $mg2->element_left, 160);
is($mg3->element_top - $mg2->element_top, 160);
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(0, 0, 0)") or exit 1;

$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, -202, -202);

my $mg4 = $mech->gesture($point);
is($mg4->element_left, $mg1->element_left);
is($mg4->element_top, $mg1->element_top);

my $hue = $mech->get_html_element_by_id("cp_hue");
isnt($hue, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($hue, "background-image"), qr/color_picker\.png/);

my $hue_ptr = $mech->get_html_element_by_id("cp_hue_pointer");
isnt($hue_ptr, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($hue_ptr, "background-image")
	, qr/color_picker\.png/);

sub px_to_int {
	$_[0] =~ s/px$//;
	return int($_[0]);
}

is(px_to_int($mech->get_element_style($hue_ptr, "width")) - 1
		+ 2 * px_to_int($mech->get_element_style($hue_ptr, "left"))
	, px_to_int($mech->get_element_style($hue, "width")));

is($mech->get_element_style($cur_color, "background-color")
	, "rgb(255, 255, 255)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

$mech->pull_alerts;
$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_move($point, 22, 22);
unlike($mech->pull_alerts, qr/cp cp/);

is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 202)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

$mech->x_mouse_up($point, 1, 1);
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 202)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 202)");
like($mech->pull_alerts, qr/cp cp 227 202 202/);

my $hg1 = $mech->gesture($hue_ptr);
$mech->x_mouse_down($hue_ptr, 2, 2);
$mech->x_mouse_up($hue_ptr, 22, 22);

my $hg2 = $mech->gesture($hue_ptr);
is($hg2->element_left - $hg1->element_left, 0);
is($hg2->element_top - $hg1->element_top, 21); # because of .5
is_deeply($mech->console_messages, []) or exit 1;

is($mech->get_element_style($cp_div, "background-color"), 'rgb(255, 0, 168)');
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 218)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 218)");

my $hex = $mech->get_html_element_by_id("cp_rgb_hex", "Input");
isnt($hex, undef) or exit 1;
is($hex->GetValue, 'e3cada');

$mech->run_js('htcp_set_indicators_from_rgb("cp", 255, 255, 255);');
is_deeply($mech->console_messages, []) or exit 1;
is($mech->get_element_style($hue_ptr, "top"), '-4.5px');
is($mech->get_element_style($cp_div, "background-color"), 'rgb(255, 0, 0)');
is($mech->get_element_style($point, "left"), '-5.5px');
is($mech->get_element_style($point, "top"), '-5.5px');
is($hex->GetValue, 'ffffff');
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

$mech->run_js('htcp_set_indicators_from_rgb("cp", 0, 0, 0);');
my $gcp_div = $mech->gesture($cp_div);
my $gpoint = $mech->gesture($point);

cmp_ok($gpoint->element_top, '>=', $gcp_div->element_top);

my $cpdns = $cp_div->QueryInterface(Mozilla::DOM::NSHTMLElement->GetIID);
cmp_ok($gpoint->element_top, '<=' , $gcp_div->element_top
		+ $cpdns->GetOffsetHeight);

$gcp_div = $mech->gesture($hue);
$gpoint = $mech->gesture($hue_ptr);
my $hns = $hue->QueryInterface(Mozilla::DOM::NSHTMLElement->GetIID);
cmp_ok($gpoint->element_top, '>=', $gcp_div->element_top);
cmp_ok($gpoint->element_top, '<=' , $gcp_div->element_top
		+ $hns->GetOffsetHeight);

$mech->run_js('htcp_set_indicators_from_rgb("cp", 255, 255, 0);');
$gcp_div = $mech->gesture($cp_div);
$gpoint = $mech->gesture($point);
cmp_ok($gpoint->element_left, '>=', $gcp_div->element_left);
cmp_ok($gpoint->element_left, '<=' , $gcp_div->element_left
		+ $cpdns->GetOffsetWidth);

$mech->run_js('htcp_set_indicators_from_rgb("cp", 7, 202, 218);');
is($rr->GetValue, 7);
is($rg->GetValue, 202);
is($rb->GetValue, 218);
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(7, 202, 218)");

$mech->run_js('htcp_set_indicators_from_rgb("cp", 227, 202, 218);');
is(px_to_int($mech->get_element_style($hue_ptr, "top")), 14); # ~20 - 4.5
is(px_to_int($mech->get_element_style($point, "top")), 14);
is(px_to_int($mech->get_element_style($point, "left")), 14);

is($mech->get_element_style($cp_div, "background-color"), 'rgb(255, 0, 156)');
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 218)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 218)");
is($hex->GetValue, 'e3cada');
is($rr->GetValue, 227);
is($rg->GetValue, 202);
is($rb->GetValue, 218);

$mech->x_click($rr, 3, 3);
$rr->SetValue(7);
$mech->x_send_keys("\n");

is($rr->GetValue, 7);
is($rg->GetValue, 202);
is($rb->GetValue, 218);
is($hex->GetValue, '07cada');
is_deeply($mech->console_messages, []) or exit 1;

$mech->x_change_text($rg, 100);
is($rr->GetValue, 7);
is($rg->GetValue, 100);
is($rb->GetValue, 218);
is($hex->GetValue, '0764da');
is($mech->get_element_style($cur_color, "background-color"), "rgb(7, 100, 218)");

$mech->x_change_text($hex, '07cada');
is_deeply($mech->console_messages, []) or exit 1;
is($rr->GetValue, 7);
is($rg->GetValue, 202);
is($rb->GetValue, 218);
is($hex->GetValue, '07cada');
is($mech->get_element_style($prev_color, "background-color"), "rgb(7, 202, 218)");

$mech->pull_alerts;
$mech->x_click($cp_div, 50, 50);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->get_element_style($cur_color, "background-color"), "rgb(185, 247, 255)");
is($mech->get_element_style($prev_color, "background-color"), "rgb(185, 247, 255)");

$mech->x_click($hue, 5, 150);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->get_element_style($cur_color, "background-color"), "rgb(255, 185, 185)");
is($mech->get_element_style($prev_color, "background-color"), "rgb(255, 185, 185)");
