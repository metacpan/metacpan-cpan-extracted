use strict;
use warnings FATAL => 'all';

use Test::More tests => 25;
use File::Temp qw(tempdir);
use File::Slurp;
use HTML::Tested::Test;
use URI::file;
use HTTP::Daemon;
use HTML::Tested::Test::Request;
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use HTML::Tested::Value::Hidden;
use HTML::Tested::JavaScript qw(HTJ);
use HTTP::Request::Params;

BEGIN { use_ok('HTML::Tested::JavaScript::Serializer::Form');
	use_ok('HTML::Tested::JavaScript::Serializer');
	use_ok('HTML::Tested::JavaScript::Serializer::Value');
	use_ok('HTML::Tested::JavaScript::Serializer::List');

	our $_T = 21; do "t/use_guitester.pl";
}

#use Carp;
#BEGIN { $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); }; }

package T1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::Serializer::Value", "t1v");

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::Value::Hidden", "hid");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Value", "sv");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::List"
					, "l", 'T1');
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer", "ser"
		, "sv", "l");
__PACKAGE__->ht_add_widget(::HTJ() . "::Serializer::Form"
		, sform => default_value => 'moo');

package main;

$HTML::Tested::JavaScript::Location = "javascript";
my $td = tempdir('/tmp/ht_ser_XXXXXX', CLEANUP => 1);

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
			$resp->content($tst->sform_response(Dumper($tst)
						, 'gggg'));
			$c->send_response($resp);
		}
		$c->close;
		undef($c);
	}
	exit;
}

sleep 1;
my $d_url = read_file("$td/url");
my $obj = T->new({ sv => 'a b', hid => 'b'
		, l => [ map { T1->new({ t1v => "l $_" }) } (1 .. 2) ] });
my $stash = {};
$obj->ht_render($stash);
is($stash->{sform}, <<'ENDS');
<iframe id="sform_iframe" name="sform_iframe" style="display:none;"></iframe>
<form id="sform" name="sform" method="post" action="moo"
	enctype="multipart/form-data" target="sform_iframe">
ENDS

my $str = sprintf(<<ENDS, $stash->{ser}, $stash->{sform}, $stash->{hid});
<html>
<head>
%s
<script>
function on_sform_response(str, g) { alert("rrrr " + str + " " + g); }
</script>
</head>
<body>
%s
%s
</form>
</body>
</html>
ENDS
write_file("$td/a.html", $str);
like($str, qr/l 2/);
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
ok($mech->get("$d_url/td/a.html"));
like($mech->content, qr/sform/);

$mech->run_js('ht_serializer_prepare_form("sform", ser);');
is_deeply($mech->console_messages, []) or diag($mech->content);

is($mech->run_js('return document.getElementById("sform")["sv"].value;')
		, "a b");
is($mech->run_js('return document.getElementById("sform")["l__1__t1v"].value;')
		, "l 1");
is_deeply($mech->console_messages, []);

$mech->run_js('ht_serializer_reset_form("sform");');
is_deeply($mech->console_messages, []);
is($mech->run_js('return document.getElementById("sform")["sv"]'), 'undefined');
is_deeply($mech->console_messages, []);

is($mech->run_js('return document.getElementById("sform")["hid"].value'), 'b');
is_deeply($mech->console_messages, []);

$mech->run_js('ht_serializer_prepare_form("sform", ser);');
is_deeply($mech->console_messages, []) or diag($mech->content);
is($mech->run_js('return document.getElementById("sform")["l__2__t1v"].value;')
		, "l 2");
is_deeply($mech->console_messages, []) or diag($mech->content);

$mech->submit_form;
is_deeply($mech->console_messages, []) or diag($mech->content);
my $alerts = $mech->pull_alerts;
like($alerts, qr/'l' =/);
like($alerts, qr/rrrr/);
like($alerts, qr/gggg/);

is(HTML::Tested::JavaScript::Serializer::Form->form_response("aa", "bb", "cc")
		, <<ENDS);
<html>
<head>
<script>
top.on_aa_response("bb", "cc");
</script>
</head>
<body></body>
</html>
ENDS

kill(9, $pid);
waitpid($pid, 0);

