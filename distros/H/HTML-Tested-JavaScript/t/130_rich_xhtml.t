use strict;
use warnings FATAL => 'all';

use Test::More tests => 23;
use File::Temp qw(tempdir);
use File::Slurp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use URI::file;

BEGIN { use_ok("HTML::Tested::JavaScript::RichEdit");
	use_ok('HTML::Tested::JavaScript::Test::RichEdit', qw(HTRE_Get_Body
			HTRE_Get_Value HTRE_Set_Value));
	use_ok('HTML::Tested::JavaScript', qw(HTJ $Location));

	our $_T = 17; do "t/use_guitester.pl";
};

use constant HTJRE => HTJ."::RichEdit";

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJRE, "v");

package main;

$HTML::Tested::JavaScript::Location = "javascript";
my $obj = T->new;
my $stash = {};
$obj->ht_render($stash);

my $str = sprintf(<<'ENDS', $stash->{v_script}, $stash->{v});
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html  xmlns="http://www.w3.org/1999/xhtml">
<head>%s
<style>
#v {
	width: 300px;
	height: 300px;
}
</style>
</head><body> %s </body> </html>
ENDS

my $td = tempdir('/tmp/060_re_XXXXXX', CLEANUP => 1);
my $tf = "$td/re.xhtml";
write_file($tf, $str);
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
my $url = URI::file->new_abs($tf)->as_string;
ok($mech->get($url));
is_deeply($mech->console_messages, []) or diag($mech->content);
is($mech->run_js('return document.contentType'), 'application/xhtml+xml');
is($mech->run_js('return htre_document("v").contentType'), 'application/xhtml+xml');

my $if_ns = HTRE_Get_Body($mech, "v", "IFrame");
isnt($if_ns, undef) or exit 1;
my $br = HTRE_Get_Value($mech, "v");
like($br, qr/^<br ?\/>$/);
is($mech->run_js('return htre_get_value("v")'), $br);

HTRE_Set_Value($mech, "v", $br);
is(HTRE_Get_Value($mech, "v"), $br);

$mech->x_click($if_ns, 10, 10);
$mech->x_send_keys('treb');
$mech->x_send_keys("^(a)");
$mech->run_js('htre_exec_command("v", "CreateLink", "a.com");');
$mech->x_click($if_ns, 10, 10);
is(HTRE_Get_Value($mech, "v"), '<a href="a.com">treb' . "$br</a>");
is($mech->run_js('return htre_get_selection_state("v").link;'), "a.com");
is_deeply($mech->console_messages, []) or diag($mech->content);

$mech->x_click($mech->get_html_element_by_id("v"), 10, 10);
$mech->x_send_keys("^(a)");
is($mech->run_js('return htre_get_selection_state("v").link;'), "a.com");
is_deeply($mech->console_messages, []) or diag($mech->content);

my $imsrc = "file://$td/javascript/images/color_picker.png";
$mech->run_js("htre_insert_image('v', '$imsrc').setAttribute('class', 'foobar');");
is_deeply($mech->console_messages, []) or diag($mech->content);

my @ims = $mech->qi($if_ns)->GetElementsByTagName("img");
is(@ims, 1);

my $img = $ims[0]->QueryInterface(Mozilla::DOM::HTMLImageElement->GetIID);
is($img->GetSrc, $imsrc) or diag($mech->pull_alerts);
is($img->GetClassName, "foobar");

HTRE_Set_Value($mech, "v", '<a href="a.com">bbbbb</a><span>aaaaa</span>');
my @ps = $mech->qi($if_ns)->GetElementsByTagName("span");
is(@ps, 1);
$mech->x_mouse_down($ps[0], 15, 25);
$mech->x_mouse_up($ps[0], -55, 25);
is($mech->run_js('return _htre_win("v").getSelection()'), 'bbbbb');
is($mech->run_js('return htre_get_selection_state("v").link;'), "a.com");
