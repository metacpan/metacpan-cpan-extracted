######################################################################
#
# t/0002-unit.t - Unit tests for url_decode, parse_query, mime_type,
#                 response builders, is_htmx, and HTTPS::Handy::Input.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }
sub like { my ($g, $re, $n) = @_; $T++; defined($g) && ($g =~ $re) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }

use HTTPS::Handy;

# --- url_decode (ok 1-10) -----------------------------------------------

is(HTTPS::Handy->url_decode('hello'),         'hello',       'url_decode: plain string');
is(HTTPS::Handy->url_decode('hello%20world'), 'hello world', 'url_decode: %20 -> space');
is(HTTPS::Handy->url_decode('hello+world'),   'hello world', 'url_decode: + -> space');
is(HTTPS::Handy->url_decode('foo%3Dbar'),     'foo=bar',     'url_decode: %3D -> =');
is(HTTPS::Handy->url_decode('%2F'),           '/',           'url_decode: %2F -> /');
is(HTTPS::Handy->url_decode('%61%62%63'),     'abc',         'url_decode: lower hex');
is(HTTPS::Handy->url_decode('%41%42%43'),     'ABC',         'url_decode: upper hex');
is(HTTPS::Handy->url_decode(''),              '',            'url_decode: empty string');
is(HTTPS::Handy->url_decode(undef),           '',            'url_decode: undef -> empty');
is(HTTPS::Handy->url_decode('no%2Bchange'),   'no+change',   'url_decode: literal +');

# --- parse_query (ok 11-25) ---------------------------------------------

my %p;

%p = HTTPS::Handy->parse_query('name=ina');
is($p{name}, 'ina', 'parse_query: single key');

%p = HTTPS::Handy->parse_query('a=1&b=2&c=3');
is($p{a}, '1', 'parse_query: a');
is($p{b}, '2', 'parse_query: b');
is($p{c}, '3', 'parse_query: c');

%p = HTTPS::Handy->parse_query('tag=perl&tag=cpan');
is(ref($p{tag}), 'ARRAY',        'parse_query: repeated key -> arrayref');
is($p{tag}[0],   'perl',         'parse_query: repeated key [0]');
is($p{tag}[1],   'cpan',         'parse_query: repeated key [1]');

%p = HTTPS::Handy->parse_query('name=ina+abe&msg=hello%20world');
is($p{name}, 'ina abe',     'parse_query: value + decoded');
is($p{msg},  'hello world', 'parse_query: value %20 decoded');

%p = HTTPS::Handy->parse_query('flag');
ok(exists $p{flag}, 'parse_query: key with no =value exists');
is($p{flag}, '',    'parse_query: key with no =value is empty string');

%p = HTTPS::Handy->parse_query('');
is(scalar(keys %p), 0, 'parse_query: empty string -> empty hash');

%p = HTTPS::Handy->parse_query(undef);
is(scalar(keys %p), 0, 'parse_query: undef -> empty hash');

%p = HTTPS::Handy->parse_query('a%3Db=1');
ok(exists $p{'a=b'}, 'parse_query: %3D decoded inside key');

%p = HTTPS::Handy->parse_query('x=1&x=2&x=3');
is(scalar(@{$p{x}}), 3, 'parse_query: 3 repeats collected');

# --- mime_type (ok 26-38) ------------------------------------------------

is(HTTPS::Handy->mime_type('html'),  'text/html; charset=utf-8', 'mime_type: html');
is(HTTPS::Handy->mime_type('.html'), 'text/html; charset=utf-8', 'mime_type: leading dot stripped');
is(HTTPS::Handy->mime_type('HTML'),  'text/html; charset=utf-8', 'mime_type: case-insensitive');
is(HTTPS::Handy->mime_type('css'),   'text/css',                 'mime_type: css');
is(HTTPS::Handy->mime_type('js'),    'application/javascript',   'mime_type: js');
is(HTTPS::Handy->mime_type('json'),  'application/json',         'mime_type: json');
is(HTTPS::Handy->mime_type('png'),   'image/png',                'mime_type: png');
is(HTTPS::Handy->mime_type('jpg'),   'image/jpeg',               'mime_type: jpg');
is(HTTPS::Handy->mime_type('svg'),   'image/svg+xml',            'mime_type: svg');
is(HTTPS::Handy->mime_type('pdf'),   'application/pdf',          'mime_type: pdf');
is(HTTPS::Handy->mime_type('ltsv'),  'text/plain; charset=utf-8', 'mime_type: ltsv');
is(HTTPS::Handy->mime_type('csv'),   'text/csv; charset=utf-8',  'mime_type: csv');
is(HTTPS::Handy->mime_type('xyz'),   'application/octet-stream', 'mime_type: unknown extension');

# --- is_htmx (ok 39-41) ---------------------------------------------------

is(HTTPS::Handy->is_htmx({ HTTP_HX_REQUEST => 'true' }),  1, 'is_htmx: true when header set');
is(HTTPS::Handy->is_htmx({ HTTP_HX_REQUEST => 'false' }), 0, 'is_htmx: false when header wrong value');
is(HTTPS::Handy->is_htmx({}),                             0, 'is_htmx: false when header absent');

# --- response_redirect (ok 42-45) -----------------------------------------

my $r = HTTPS::Handy->response_redirect('/new/path');
is($r->[0], 302, 'response_redirect: default status 302');
is((grep { $_ eq '/new/path' } @{$r->[1]})[0], '/new/path', 'response_redirect: Location value present');

$r = HTTPS::Handy->response_redirect('/new/path', 301);
is($r->[0], 301, 'response_redirect: explicit status 301');
like($r->[2][0], qr{/new/path}, 'response_redirect: body mentions location');

# --- response_json / response_html / response_text (ok 46-53) ------------

$r = HTTPS::Handy->response_json('{"ok":true}');
is($r->[0], 200, 'response_json: default status 200');
is($r->[2][0], '{"ok":true}', 'response_json: body is passed through');

$r = HTTPS::Handy->response_json('{"error":"bad"}', 400);
is($r->[0], 400, 'response_json: explicit status');

$r = HTTPS::Handy->response_html('<h1>Hello</h1>');
is($r->[0], 200, 'response_html: default status 200');
is($r->[2][0], '<h1>Hello</h1>', 'response_html: body passed through');

$r = HTTPS::Handy->response_text('Hello, World!');
is($r->[0], 200, 'response_text: default status 200');
is($r->[2][0], 'Hello, World!', 'response_text: body passed through');

$r = HTTPS::Handy->response_text('bad', 500);
is($r->[0], 500, 'response_text: explicit status');

# --- HTTPS::Handy::Input (ok 54-62) ---------------------------------------

my $input = HTTPS::Handy::Input->new('hello=world&lang=perl');
is($input->tell, 0, 'Input: initial position is 0');

my $buf;
my $n = $input->read($buf, 5);
is($n,   5,       'Input: read() returns bytes read');
is($buf, 'hello', 'Input: read() fills buffer');
is($input->tell, 5, 'Input: tell() advances after read');

$input->seek(0, 0);
is($input->tell, 0, 'Input: seek(0, SET) rewinds');

my $line = $input->getline;
is($line, 'hello=world&lang=perl', 'Input: getline() reads whole line (no newline)');

$input = HTTPS::Handy::Input->new("line1\nline2\nline3");
my @lines = $input->getlines;
is(scalar(@lines), 3,        'Input: getlines() splits on newline');
is($lines[0], "line1\n",     'Input: getlines()[0] keeps newline');
is($lines[2], 'line3',       'Input: getlines() last line has no trailing newline');

print "1..$T\n";
exit($FAIL ? 1 : 0);
