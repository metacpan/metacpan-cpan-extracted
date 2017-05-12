use strict;
use warnings FATAL => 'all';

use Test::More tests => 15;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

BEGIN { use_ok('Gtk2::WebKit::Mechanize'); }

my $mech = Gtk2::WebKit::Mechanize->new();
isa_ok($mech, 'Gtk2::WebKit::Mechanize');

my $file = abs_path(dirname($0)) . "/test.html";
$mech->get("file://$file");
like($mech->title, qr/Test File/);

is_deeply($mech->console_messages, []);
is($mech->run_js('return HELLO'), undef);

my $cm = $mech->console_messages;
is(scalar(@$cm), 1);
like($cm->[0], qr/ReferenceError/);
is_deeply($mech->alerts, []);

$mech->console_messages([]);
is($mech->run_js('return "HELLO"'), 'HELLO');
is_deeply($mech->console_messages, []);
is_deeply($mech->alerts, []);

is($mech->run_js('alert("FOO")'), 'undefined');
is_deeply($mech->alerts, [ "FOO" ]);

like($mech->content, qr/Hello, test.*comment/ms);

$mech->submit_form(fields => { hello => 'A', world => 'B' });
like($mech->run_js('return document.location.href'), qr/hello=A&world=B/);
