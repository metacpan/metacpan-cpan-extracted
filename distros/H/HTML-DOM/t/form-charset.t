#!/usr/bin/perl -T

use strict; use warnings; use utf8; use lib 't';

use HTML::DOM;
my $doc = new HTML::DOM;

$doc->write(<<'EOF'); $doc->close;
	<form action=http://10.11.12.20/cgi-bin/printenv>
	<input name=foo >
	<!--(This is not valid HTML; but that makes the test better. :-)-->
EOF

my $form = $doc->forms->[0];
my $input = $form->elements->[0];

# -------------------------- #
use tests 3; # GET

$form->acceptCharset('windows-1253');
$input->value("φου is foo in Greek");
is $form->make_request->as_string, <<'EOR','get with ascii-based encoding';
GET http://10.11.12.20/cgi-bin/printenv?foo=%F6%EF%F5+is+foo+in+Greek

EOR

$form->acceptCharset('utf-16be');
is $form->make_request->as_string, <<'EOR','get with non-ascii encoding';
GET http://10.11.12.20/cgi-bin/printenv?foo=%CF%86%CE%BF%CF%85+is+foo+in+Greek

EOR

$form->enctype('multipart/form-data');
is $form->make_request->as_string,
	<<'EOR','get w/multipart rejects non-ascii';
GET http://10.11.12.20/cgi-bin/printenv?foo=%CF%86%CE%BF%CF%85+is+foo+in+Greek

EOR


# -------------------------- #
use tests 3; # POST with xwfu

$form->enctype('application/x-www-form-urlencoded');
$form->method('post');
$form->acceptCharset('ISO-8859-1');
is $form->make_request->as_string,
	<<'EOR','post with xwfu and ascii-based charset';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 29
Content-Type: application/x-www-form-urlencoded; charset="ISO-8859-1"

foo=%3F%3F%3F+is+foo+in+Greek
EOR

$form->acceptCharset('utf-32le');
is $form->make_request->as_string,
	<<'EOR','post with xwfu and non-ascii charset';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 38
Content-Type: application/x-www-form-urlencoded; charset="utf-8"

foo=%CF%86%CE%BF%CF%85+is+foo+in+Greek
EOR

$form->enctype('oteth/=.=eetete');
is $form->make_request->as_string,
	<<'EOR','post with unknown enctype';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 38
Content-Type: application/x-www-form-urlencoded; charset="utf-8"

foo=%CF%86%CE%BF%CF%85+is+foo+in+Greek
EOR


# -------------------------- #
use tests 2; # POST with multipart/form-data

$doc->write(<<'EOF'); $doc->close;
	<form action=http://10.11.12.20/cgi-bin/printenv
		enctype=multipart/form-data method=post>
	<input name=foo value><input type=file name=phial>
EOF

$form = $doc->forms->[0];
$input = $form->elements->[0];

use File::Temp 'tempfile';
my($fh,$filename) = tempfile uc 'suffix', '.txt', uc 'unlink', 1;
binmode $fh; print $fh "This is some text\n"; close $fh;

$form->acceptCharset('iso-8859-1');
$form->elements->[1]->value($filename);
$input->value("φου is foo in Greek");
(my $esc_fn = $filename) =~ s/(["\\])/\\$1/g;
is $form->make_request->as_string,
	<<EOR,'post with m/fd and ascii-based charset';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: ${\(251+length $esc_fn)}
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="foo"\r
Content-Type: text/plain; charset="iso-8859-1"\r
\r
??? is foo in Greek\r
--xYzZY\r
Content-Disposition: form-data; name="phial"; filename="$esc_fn"\r
Content-Type: text/plain\r
\r
This is some text
\r
--xYzZY--\r
EOR

$form->acceptCharset('utf-32le');
is $form->make_request->as_string,
	<<EOR,'post with m/fd and non-ascii charset';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: ${\(306+length $esc_fn)}
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="foo"\r
Content-Type: text/plain; charset="utf-32le"\r
\r
\xc6\3\0\0\xbf\3\0\0\xc5\3\0\0 \0\0\0i\0\0\0s\0\0\0 \0\0\0f\0\0\0o\0\0\0o\0\0\0 \0\0\0i\0\0\0n\0\0\0 \0\0\0G\0\0\0r\0\0\0e\0\0\0e\0\0\0k\0\0\0\r
--xYzZY\r
Content-Disposition: form-data; name="phial"; filename="$esc_fn"\r
Content-Type: text/plain\r
\r
This is some text
\r
--xYzZY--\r
EOR


# -------------------------- #
use tests 9; # various charset issues

$doc->write(<<'EOF'); $doc->close;
	<form action=http://10.11.12.20/cgi-bin/printenv
		enctype=multipart/form-data method=post
		accept-charset='us-ascii windows-1253 iso-8859-1 utf-8'>
	<input name=foo value='English'>
	<input name=bar value='Français'>
	<input name=baz value='Ελληνικά'>
	<input name=bonk value='Ἑλληνικὰ'>
EOF

$form = $doc->forms->[0];
$input = $form->elements->[0];

is $form->make_request->as_string,
	<<EOR,'choosing enctype based on chars with m/f-d';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 468
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="foo"\r
Content-Type: text/plain; charset="us-ascii"\r
\r
English\r
--xYzZY\r
Content-Disposition: form-data; name="bar"\r
Content-Type: text/plain; charset="iso-8859-1"\r
\r
Fran\xe7ais\r
--xYzZY\r
Content-Disposition: form-data; name="baz"\r
Content-Type: text/plain; charset="windows-1253"\r
\r
\305\353\353\347\355\351\352\334\r
--xYzZY\r
Content-Disposition: form-data; name="bonk"\r
Content-Type: text/plain; charset="utf-8"\r
\r
\341\274\231\316\273\316\273\316\267\316\275\316\271\316\272\341\275\260\r
--xYzZY--\r
EOR

$form->enctype('tiddley-pom');
$form->{baz}->value('');
$form->{bonk}->value('');
is $form->make_request->as_string,
	<<EOR,'choosing enctype based on chars with m/f-d';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 37
Content-Type: application/x-www-form-urlencoded; charset="iso-8859-1"

foo=English&bar=Fran%E7ais&baz=&bonk=
EOR

map $_->detach, @{$form->elements};
$form->appendChild($input = $doc->createElement('input'));
$input->name('foo');
$input->value("φου is foo in Greek");
$form->acceptCharset(' te ethiod o deth');
$doc->charset('windows-1253');
$form->method('GET');
is $form->make_request->as_string, <<'EOR','fallback to doc encoding';
GET http://10.11.12.20/cgi-bin/printenv?foo=%F6%EF%F5+is+foo+in+Greek

EOR

$form->acceptCharset('');
$doc->charset('');
$input->value("\x{120000}");
$form->method('post');     # the default encoding is utf8, but called utf-8
is $form->make_request->as_string, <<'EOR','default encoding is utf(-)8';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 16
Content-Type: application/x-www-form-urlencoded; charset="utf-8"

foo=%F4%A0%80%80
EOR

$doc->charset('utf-8');
$form->acceptCharset('iso-8859-1 iso-8859-7');
$input->value('Ἐγένετο δὲ λόγῳ μὲν δημοκρατία...');
is $form->make_request->as_string,
 <<'EOR','1st charset in accept-charset is used when none is satisfactory';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 89
Content-Type: application/x-www-form-urlencoded; charset="iso-8859-1"

foo=%3F%3F%3F%3F%3F%3F%3F+%3F%3F+%3F%3F%3F%3F+%3F%3F%3F+%3F%3F%3F%3F%3F%3F%3F%3F%3F%3F...
EOR

$form->acceptCharset('oenteohnttn');
$doc->charset('oentuh');
$input->value('...λόγῳ δὲ τοῦ πρώτου ἀνδρὸς ἀρχή. —Θουκυδίδης');
is $form->make_request->as_string,
 <<'EOR','doc charset is not used when invalid';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 263
Content-Type: application/x-www-form-urlencoded; charset="utf-8"

foo=...%CE%BB%E1%BD%B9%CE%B3%E1%BF%B3+%CE%B4%E1%BD%B2+%CF%84%CE%BF%E1%BF%A6+%CF%80%CF%81%E1%BD%BD%CF%84%CE%BF%CF%85+%E1%BC%80%CE%BD%CE%B4%CF%81%E1%BD%B8%CF%82+%E1%BC%80%CF%81%CF%87%E1%BD%B5.+%E2%80%94%CE%98%CE%BF%CF%85%CE%BA%CF%85%CE%B4%E1%BD%B7%CE%B4%CE%B7%CF%82
EOR

$input->name('имя');
$input->value('foo');
is $form->make_request->as_string,<<'EOR','non-ascii field name with xwfu';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 22
Content-Type: application/x-www-form-urlencoded; charset="utf-8"

%D0%B8%D0%BC%D1%8F=foo
EOR

$form->enctype('multipart/form-data');
is $form->make_request->as_string,
	<<EOR,'nonascii field names with m/f-d';
POST http://10.11.12.20/cgi-bin/printenv
Content-Length: 131
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="=?UTF-8?B?0LjQvNGP?="\r
Content-Type: text/plain; charset="utf-8"\r
\r
foo\r
--xYzZY--\r
EOR

$input->value('π≈3.14');
$form->method('get');
$form->acceptCharset('x-mac-roman');
is $form->make_request->uri,
	'http://10.11.12.20/cgi-bin/printenv?%3F%3F%3F=%B9%C53.14',
	'x-mac- charsets';
