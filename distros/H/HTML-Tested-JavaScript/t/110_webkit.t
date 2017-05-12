use strict;
use warnings FATAL => 'all';

use Test::More tests => 26;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Slurp;
use HTTP::Request::Params;
use HTML::Tested::Test::Request;
use HTTP::Daemon;
use Data::Dumper;
use File::Copy;

BEGIN { use_ok("HTML::Tested::JavaScript::Serializer::Array"); };
BEGIN { our $_T = 19; our $_M = "Gtk2::WebKit::Mechanize";
		do "t/use_guitester.pl"; }

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Array", "sv");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Array", "sk");

package main;

my $td = tempdir('/tmp/ht_120_ser_XXXXXX', CLEANUP => 1);
my $pid = fork();
if (!$pid) {
	my $d = HTTP::Daemon->new;
	write_file("$td/url", $d->url);
	while (my $c = $d->accept) {
		while (my $r = $c->get_request) {
			if ($r->uri !~ /moo/ && $r->uri =~ /td\/(.*)$/) {
				$c->send_file_response("$td/$1");
				next;
			}
			my $freq = HTML::Tested::Test::Request->new;
			{
				local $SIG{__WARN__} = sub {};
				my $rp = HTTP::Request::Params->new({
						req => $r });
				$freq->set_params($rp->params);
			};
			my $resp = HTTP::Response->new(200);
			my $tst = T->ht_load_from_params(
				map { $_, $freq->param($_) } $freq->param);
			$resp->content(Dumper($tst));
			$c->send_response($resp);
		}
		$c->close;
		undef($c);
	}
	exit;
}

my $mech = Gtk2::WebKit::Mechanize->new;
my $dir = abs_path(dirname($0));
copy("$dir/tiger.xhtml", "$td/tiger.xhtml") or die;
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");

$mech->get("file://$td/tiger.xhtml");
is($mech->title, 'XHTML test');
is_deeply($mech->console_messages, []);

write_file("$td/a.html", <<'ENDS');
<html>
<head>
<title>Diff Array</title>
<script src="javascript/rich_edit.js"></script>
<script src="javascript/serializer.js"></script>
<script>
var o1 = { a: [ 12, 14 ] };
var o2 = { a: [ 12, 14 ] };
var o3 = { a: [ 12, 15 ] };
var res = {};
</script>
</head>
<body>
</body>
</html>
ENDS

$mech->get("file://$td/a.html");
is($mech->title, 'Diff Array');
is_deeply($mech->console_messages, []) or exit 1;

like($mech->run_js('return htre_escape("<OL>a</OL><F>b</F><A>c</A>")')
	, qr#<OL>a</OL>b<A>c</A>#);
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return htre_escape("<OL>a</OL><F><K>b</K></F><A>c</A>")')
	, "<OL>a</OL>b<A>c</A>");
is_deeply($mech->console_messages, []) or exit 1;

like($mech->run_js('return htre_escape("<ol>a</ol>")'), qr#<ol>a</ol>#);
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_diff_hash(o1, o2, {})'), 0);
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_diff_hash(o1, o3, res)'), 1);
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return res.a[0] + "." + res.a[1]'), '12.15');
is($mech->run_js('return ht_serializer_flatten(res)'), 'a,12,15');
is($mech->run_js('return ht_serializer_encode(res)'), 'a=12%2C15');
is_deeply($mech->console_messages, []) or exit 1;

write_file("$td/b.html", <<'ENDS');
<html>
<head>
<title>Submit Page</title>
<script src="javascript/serializer.js"></script>
<script>
var ser = { sv: [ "aa", "bb" ], sk: [] };
</script>
</head>
<body>
</body>
</html>
ENDS

my $d_url = read_file("$td/url");
ok($d_url);

$mech->get("$d_url/td/b.html");
is($mech->title, 'Submit Page');
is_deeply($mech->console_messages, []);

$mech->run_js("return ht_serializer_submit(ser, '$d_url/moo'"
		. ", function(r) { alert(r.responseText); })");
is_deeply($mech->console_messages, []) or exit 1;
Glib::Timeout->add(600, sub { Gtk2->main_quit; });
Gtk2->main;

my $als = join("\n", @{ $mech->alerts });
like($als, qr/VAR/);
like($als, qr/'aa',[^\]]+'bb'/ms);
like($als, qr/'sk' => \[\]/ms);

kill(9, $pid);
waitpid($pid, 0);
