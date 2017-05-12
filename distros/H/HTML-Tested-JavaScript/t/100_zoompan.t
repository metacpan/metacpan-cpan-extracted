use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Path qw(rmtree);
use File::Slurp;
use File::Copy;

BEGIN { our $_T = 22; do "t/use_guitester.pl"; }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
my $dir = abs_path(dirname($0));

my $td = tempdir('/tmp/ht_zp_ser_XXXXXX', CLEANUP => 1);
copy("$dir/tiger.xhtml", "$td/tiger.xhtml") or die;
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");

ok($mech->get("file://$td/tiger.xhtml"));
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js(<<ENDS), '0 0 800 800');
return document.getElementsByTagName("svg")[0].getAttribute("viewBox");
ENDS

my $zptr = $mech->get_html_element_by_id("zoom_ptr");
isnt($zptr, undef);
is($mech->get_element_style($zptr, "top"), "85px");

$mech->x_mouse_down($zptr, 3, 3);
$mech->x_mouse_up($zptr, 6, 13);
is($mech->get_element_style($zptr, "top"), "95px");
is_deeply($mech->console_messages, []) or do {
	diag($mech->pull_alerts);
	exit 1;
};

is($mech->run_js(<<ENDS), '0 0 800 800');
return document.getElementsByTagName("svg")[0].getAttribute("viewBox");
ENDS

is($mech->run_js(<<ENDS), 'translate(200, 200) scale(0.836251)');
return document.getElementsByTagName("g")[0].getAttribute("transform");
ENDS

$mech->x_mouse_down($zptr, 3, 3);
$mech->x_mouse_up($zptr, 6, -17);
is($mech->get_element_style($zptr, "top"), "75px");
is_deeply($mech->console_messages, []) or do {
	diag($mech->pull_alerts);
	exit 1;
};

is($mech->run_js(<<ENDS), '0 0 800 800');
return document.getElementsByTagName("svg")[0].getAttribute("viewBox");
ENDS

is($mech->run_js(<<ENDS), 'translate(200, 200) scale(1.19581)');
return document.getElementsByTagName("g")[0].getAttribute("transform");
ENDS

my $sva = $mech->get_html_element_by_id("svg_area");
isnt($sva, undef);

$mech->x_mouse_down($sva, 100, 100);
$mech->x_mouse_up($sva, 200, 200);
is($mech->run_js(<<ENDS), '-100 -100 800 800') or do {
return document.getElementsByTagName("svg")[0].getAttribute("viewBox");
ENDS
	diag($mech->pull_alerts);
	exit 1;
};

$td = '/tmp/100_zoompan_dir';
rmtree($td);
mkdir $td;
my $tf = read_file('t/tiger.xhtml');
$tf =~ s/translate/scale(0.5 0.5) translate/;
$tf =~ s/ 5\);/ 10);/;
write_file("$td/t.xhtml", $tf);
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");
ok($mech->get("file://$td/t.xhtml"));
is($mech->run_js(<<ENDS), 'scale(0.5) translate(200, 200)');
return document.getElementsByTagName("g")[0].getAttribute("transform");
ENDS

$zptr = $mech->get_html_element_by_id("zoom_ptr");
isnt($zptr, undef);

$mech->x_mouse_down($zptr, 3, 3);
$mech->x_mouse_up($zptr, 6, 13);
is($mech->get_element_style($zptr, "top"), "95px");
is_deeply($mech->console_messages, []) or do {
	diag($mech->pull_alerts);
	exit 1;
};
is($mech->run_js(<<ENDS), '0 0 800 800');
return document.getElementsByTagName("svg")[0].getAttribute("viewBox");
ENDS
is($mech->run_js(<<ENDS)
return document.getElementsByTagName("g")[0].getAttribute("transform");
ENDS
	, 'scale(0.5) translate(200, 200) scale(0.774264)');

