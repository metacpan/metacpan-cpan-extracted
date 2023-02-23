use strict;
use warnings;
use Test::Needs 'LWP::UserAgent';

use Test::More tests => 45;
use lib 't/lib';

use TestServer::BasicTests;

use HTTP::Request;
use File::Temp qw(tempfile);
use MIME::Base64;

my $daemon = TestServer::BasicTests->new;
my $base = $daemon->start;

note "Will access HTTP server at $base\n";

my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/0.01 " . $ua->agent);
$ua->from('gisle@aas.no');

my $req;
my $res;

#----------------------------------------------------------------
note "Bad request...\n";
$req = HTTP::Request->new(GET => $daemon->url("/not_found"));
$req->header(X_Foo => "Bar");
$res = $ua->request($req);

ok($res->is_error);
is($res->code,    404);
like($res->message, qr/not\s+found/i);

# we also expect a few headers
ok($res->server);
ok($res->date);

#----------------------------------------------------------------
note "Simple echo...\n";

$req = HTTP::Request->new(GET => $daemon->url("/echo/path_info?query"));
$req->push_header(Accept     => 'text/html');
$req->push_header(Accept     => 'text/plain; q=0.9');
$req->push_header(Accept     => 'image/*');
$req->push_header(':foo_bar' => 1);
$req->if_modified_since(time - 300);
$req->header(
    Long_text => 'This is a very long header line
which is broken between
more than one line.'
);
$req->header(X_Foo => "Bar");

$res = $ua->request($req);

#print $res->as_string;

ok($res->is_success);
is($res->code,    200);
is($res->message, "OK");

$_      = $res->content;
my @accept = /^Accept:\s*(.*)/mg;

like($_,      qr/^From:\s*gisle\@aas\.no\n/m);
like($_,      qr/^Host:/m);
is(scalar @accept, 3);
like($_,      qr/^Accept:\s*text\/html/m);
like($_,      qr/^Accept:\s*text\/plain/m);
like($_,      qr/^Accept:\s*image\/\*/m);
like($_,      qr/^If-Modified-Since:\s*\w{3},\s+\d+/m);
like($_,      qr/^Long-Text:\s*This.*broken between/m);
like($_,      qr/^Foo-Bar:\s*1\n/m);
like($_,      qr/^X-Foo:\s*Bar\n/m);
like($_,      qr/^User-Agent:\s*Mozilla\/0.01/m);

# Try it with the higher level 'get' interface
$res = $ua->get(
    $daemon->url("/echo/path_info?query"),
    Accept => 'text/html',
    Accept => 'text/plain; q=0.9',
    Accept => 'image/*',
    X_Foo  => "Bar",
);

#$res->dump;
is($res->code,    200);
like($res->content, qr/^From: gisle\@aas.no$/m);

#----------------------------------------------------------------
note "Send file...\n";

{
    my ($fh, $filename) = tempfile( 'http-daemon-test-XXXXXX', TMPDIR => 1, SUFFIX => '.html' );
    binmode $fh;
    print $fh <<"EOT";
<html><title>En pr\xF8ve</title>
<h1>Dette er en testfil</h1>
Jeg vet ikke hvor stor fila beh\xF8ver \xE5 v\xE6re heller, men dette
er sikkert nok i massevis.
EOT
    close $fh;

    $req = HTTP::Request->new(GET => $daemon->url("/file", { file => $filename }));
    $res = $ua->request($req);

    #print $res->as_string;

    ok($res->is_success);
    is($res->content_type,   'text/html');
    is($res->content_length, 147);
    is($res->title,          "En pr\xF8ve");
    like($res->content,      qr/\xE5 v\xE6re/);

    unlink $filename;

    # A second try on the same file, should fail because we unlink it
    $res = $ua->request($req);

    #print $res->as_string;
    ok($res->is_error);
    is($res->code, 404);    # not found
}

# Then try to list current directory
$req = HTTP::Request->new(GET => $daemon->url("/file?file=."));
$res = $ua->request($req);

#print $res->as_string;
is($res->code, 501);    # NYI


#----------------------------------------------------------------
note "Check redirect...\n";

$req = HTTP::Request->new(GET => $daemon->url("/redirect/foo"));
$res = $ua->request($req);

ok($res->is_success);
like($res->content, qr|/echo/redirect|);
ok($res->previous->is_redirect);
is($res->previous->code, 301);


#----------------------------------------------------------------
note "Check basic authorization...\n";

$req = HTTP::Request->new(GET => $daemon->url("/basic"));
my $auth = MIME::Base64::encode("ok 12:xyzzy");

$req->header(Authorization => 'Basic ' . $auth);
$res = $ua->request($req);

ok($res->is_success);

$req->header('Authorization' => undef);
$res = $ua->request($req);
is($res->code, 401);

$auth = MIME::Base64::encode("user:passwd");

$req->header(Authorization => 'Basic ' . $auth);
# Then illegal credentials
$res = $ua->request($req);
is($res->code, 401);


#----------------------------------------------------------------
note "Check proxy...\n";

$ua->proxy(ftp => $base);
$req = HTTP::Request->new(GET => "ftp://ftp.perl.com/proxy");
$res = $ua->request($req);

#print $res->as_string;
ok($res->is_success);

$ua->proxy(ftp => undef);

#----------------------------------------------------------------
note "Check POSTing...\n";

$req = HTTP::Request->new(POST => $daemon->url("/echo/foo"));
$req->content_type("application/x-www-form-urlencoded");
$req->content("foo=bar&bar=test");
$res = $ua->request($req);

#print $res->as_string;

$_ = $res->content;
ok($res->is_success);
like($_, qr/^Content-Length:\s*16$/mi);
like($_, qr/^Content-Type:\s*application\/x-www-form-urlencoded$/mi);
like($_, qr/^foo=bar&bar=test$/m);

$req = HTTP::Request->new(POST => $daemon->url("/echo/foo"));
$req->content_type("multipart/form-data");
$req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "Hi\n"));
$req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "there\n"));
$res = $ua->request($req);

#print $res->as_string;
ok($res->is_success);
like($res->content, qr/^Content-Type: multipart\/form-data; boundary=/m);

#----------------------------------------------------------------
note "Terminating server...\n";

$req = HTTP::Request->new(GET => $daemon->url("/quit"));
$res = $ua->request($req);

is($res->code,    503);
like($res->content, qr/Bye, bye/);
