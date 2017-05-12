use Test::More tests => 14;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store "dbi:SQLite:dbname=t/test.db";
Email::Store->setup( );
ok(1, "Set up");

my $data = read_file("t/htmltest.mail");
Email::Store::Mail->store($data);
my ($m) = Email::Store::Mail->retrieve_all(); #('myfakeid@localhost');
ok($m, "Got the mail back");



my (@html, $html, $body, $raw, $scrubbed, $as_text);
ok(@html     = $m->html,      "Got html");
is(@html, 1, "Only one part");

$html = shift @html;

ok($body     = $m->simple->body,   "Got body");
ok($raw      = $html->raw,      "Got raw");
ok($scrubbed = $html->scrubbed, "Got scrubbed");
ok($as_text  = $html->as_text,  "Got text");

unlike($body,     qr/</, "No html in body");
like($raw,        qr/</, "Got html in raw");
like($raw,        qr/javascript/, "Got javascript in raw");
unlike($scrubbed, qr/javascript/, "No html in body");
unlike($as_text,  qr/</, "No html in text");
like($as_text,    qr!this [ http://buscador.thegestalt.org ]!, "Text has link and sentence");

