use strict;
use warnings FATAL => 'all';

use Test::More tests => 34;
use File::Temp qw(tempdir);
use File::Slurp;
use HTML::Tested::Test;
use URI::file;
use HTTP::Daemon;
use HTML::Tested::Test::Request;
use Data::Dumper;
use File::Basename qw(dirname);
use Encode;
use Cwd qw(abs_path);

BEGIN { use_ok('HTML::Tested::JavaScript::Serializer');
	use_ok('HTML::Tested::JavaScript::Serializer::Value');
	use_ok('HTML::Tested::JavaScript::Serializer::List');
	use_ok('HTML::Tested::Value::Hidden');

	my $_exit = 1;
	eval "use Mozilla::Mechanize::GUITester";
SKIP: {
	skip "No Mozilla::Mechanize::GUITester installed", 30 if $@;
	$_exit = undef;
};
	exit if $_exit;
}

#use Carp;
#BEGIN { $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); }; }

$HTML::Tested::JavaScript::Location = "javascript";
my $td = tempdir('/tmp/ht_ser_XXXXXX', CLEANUP => 1);

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::Value::Hidden", "hid");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Value", "sv");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer", "ser", "sv");

package T1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Value", "sv");

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Value", "jv");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::List"
					, "l", 'T1');
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer"
				, "ser", "jv", "l");

package main;

my $pid = fork();
if (!$pid) {
	my $d = HTTP::Daemon->new;
	write_file("$td/url", $d->url);
	my $freq = HTML::Tested::Test::Request->new;
	while (my $c = $d->accept) {
		while (my $r = $c->get_request) {
			if ($r->uri =~ /td\/(.*)$/) {
				$c->send_file_response("$td/$1");
				next;
			}

			my $tc = $r->uri =~ /T2/ ? 'T2' : 'T';
			$freq->parse_url('?' . $r->content);
			my $resp = HTTP::Response->new(200);
			my $tested = $tc->ht_load_from_params(
				map { $_, $freq->param($_) } $freq->param);
			my $s = HTML::Entities::encode_entities($r->as_string);
			$resp->content("<html><body><pre>\n$s"
				. Dumper($tested) . "</pre></body></html>");
			$c->send_response($resp);
		}
		$c->close;
		undef($c);
	}
	exit;
}

sleep 1;
my $d_url = read_file("$td/url");
my $obj = T->new({ sv => 'a', hid => 'b' });
my $stash = {};
$obj->ht_render($stash);

my $str = sprintf(<<ENDS, $stash->{ser}, $stash->{hid});
<html>
<head>
%s
</head>
<body>
<form action="$d_url/submit" method="post">
%s
</form>
</body>
</html>
ENDS

is_deeply([ HTML::Tested::Test->check_text(ref($obj), $str, { sv => 'a' }) ]
		, []);

write_file("$td/a.html", $str);
like($str, qr#javascript/seri#);

symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");
like(read_file("$td/javascript/serializer.js"), qr/ht_serial/);

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
my $url = URI::file->new_abs("$td/a.html")->as_string;
ok($mech->get($url));
is($mech->run_js('return ser.sv'), 'a');
is_deeply($mech->console_messages, []) or exit 1;

$mech->submit_form;
like($mech->content, qr/hid.*=.*'b'/);
like($mech->content, qr/Content-Type[^\n]*application\/x-www-form-urlencoded/);

# because of security we need to fetch it from daemon
ok($mech->get("$d_url/td/a.html"));

$mech->pull_alerts;
$mech->run_js('return ht_serializer_get("/td/a.html"'
			. ', function(r) { window.rt = r.responseText; })');
$mech->x_send_keys("");
is_deeply($mech->console_messages, []) or exit 1;
like($mech->run_js('return window.rt'), qr/CDATA/);

is($mech->run_js('return ht_serializer_extract("ser", window.rt)'), '{
	"sv": "a"
}');

$mech->run_js("return ht_serializer_submit(ser, '$d_url/js'"
		. ", function(r) { window.rt = r.responseText; })");
$mech->x_send_keys("");
is_deeply($mech->console_messages, []);
like($mech->run_js('return window.rt'), qr/'sv' => 'a'/);

$obj = T2->new({ jv => '"a', l => [ map { T->new({ sv => "f&$_" }) }
			(1 .. 2) ] });
$stash = {};
$obj->ht_render($stash);

$str = sprintf(<<ENDS, $stash->{ser});
<html>
<head>
%s
</head>
<body></body>
</html>
ENDS
write_file("$td/a.html", $str);
like($str, qr/"l":/);

ok($mech->get("$d_url/td/a.html"));
is_deeply($mech->console_messages, []) or diag($mech->content);

$mech->pull_alerts;
$mech->run_js(<<ENDS);
return ht_serializer_submit(ser, '$d_url/T2', function(r) {
	alert("readyState is " + r.readyState + " " + r.responseText);
});
ENDS

# Run events loop
$mech->x_send_keys(""); 
is_deeply($mech->console_messages, []) or diag($mech->content);

my $res = $mech->pull_alerts;
like($res, qr/'l' => /);
like($res, qr/'sv' => 'f%261'/);
like($res, qr/'sv' => 'f%262'/);
like($res, qr/readyState is 4/);
like($res, qr/Content-Type[^\n]*application\/x-www-form-urlencoded/);

$obj = T2->new({ jv => '"a', l => [] });
$stash = {};
$obj->ht_render($stash);

$str = sprintf(<<ENDS, $stash->{ser});
<html>
<head>
%s
</head>
<body></body>
</html>
ENDS
write_file("$td/a.html", $str);
like($str, qr/"l":/);

ok($mech->get("$d_url/td/a.html"));
is_deeply($mech->console_messages, []) or diag($mech->content);
is($mech->run_js('return ser.l.length'), 0);

$obj = T2->new({ jv => Encode::decode_utf8("\r\tЛист\t\r"), l => [] });
$stash = {};
$obj->ht_render($stash);

$str = sprintf(<<ENDS, $stash->{ser});
<html>
<head>
%s
</head>
<body></body>
</html>
ENDS
$str = Encode::encode_utf8($str);
like($str, qr/Лист/);

write_file("$td/a.html", $str);
ok($mech->get("$d_url/td/a.html"));
is_deeply($mech->console_messages, []) or diag($mech->content);

kill(9, $pid);
waitpid($pid, 0);
