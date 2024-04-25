#!/usr/bin/env perl
use 5.008;
use warnings;
use strict;

# Test MIME::Mini

use MIME::Mini ':all';
use POSIX;
use Encode ();

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use locale;
setlocale(LC_TIME, 'C');

plan tests => 16;

sub rfc822date { strftime '%a, %d %b %Y %H:%M:%S +0000', gmtime shift }
my $rfc822date_re = '\S+,\s{1,2}\d{1,2} \S+ \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}';
my $mboxdate_re = '\S+ \S+\s{1,2}\d{1,2}\s{1,2}\d{1,2}:\d{2}:\d{2} \d{4}';
sub writefile { open my $fh, '>', $_[0] or return; print $fh $_[1]; close $fh; }
sub readfile { local $/; open my $fh, '<', shift or return ''; return <$fh>; }
my $boundary_re = '("[^"]+"|\S+)';
my $display_enc = (defined $ENV{LANG} && $ENV{LANG} =~ /^.+\.(.+)$/) ? $1 : 'UTF-8';

sub display_encode
{
	return Encode::encode($display_enc, shift);
}

# Test header manipulation

subtest build => sub
{
	plan tests => 7;

	my $m = {};
	append_header($m, 'To: xxx@to.org');
	insert_header($m, 'From: from@from.org');
	append_header($m, 'Subject: subject');
	insert_header($m, 'X-X: test');
	append_header($m, 'Date: ' . rfc822date(time));
	replace_header($m, 'To: to@to.org');
	delete_header($m, 'x-x');

	like mail2str($m), "/^From: from\@from\.org\nTo: to\@to\.org\nSubject: subject\nDate: $rfc822date_re\n\n\$/", 'build: mail2str';
	cmp_deeply [header($m, 'from')], ['from@from.org'], 'build: header(from)';
	cmp_deeply [header($m, 'to')], ['to@to.org'], 'build: header(to)';
	cmp_deeply [header($m, 'subject')], ['subject'], 'build: header(subject)';
	cmp_deeply [header($m, 'date')], [re($rfc822date_re)], 'build: header(date)';
	cmp_deeply [sort(header_names($m))], ['date', 'from', 'subject', 'to'], 'build: header_names';
	cmp_deeply [sort(headers($m))], [re("Date: $rfc822date_re"), 'From: from@from.org', 'Subject: subject', 'To: to@to.org'], 'build: headers';
};

# Test decoding of encoded headers

subtest header => sub
{
	plan tests => 4;

	is MIME::Mini::header_display("Header: (this is a \\(nested\\) comment) =?US-ASCII?Q?Keith_Moore_?= =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?=\n"), "Header: Keith Moore Keld Jørn Simonsen\n", 'header_display: nested comment, 2 encodings, characters';
	is MIME::Mini::header_display("Content-Type: multipart/mixed; (this is a \\(nested\\) comment) param=\"va(not a comment)lue\"\n"), "Content-Type: multipart/mixed; param=\"va(not a comment)lue\"\n", 'header_display: multipart/mixed, nested comment, param';
	is MIME::Mini::header_display("Subject: =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?= =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=\n"), "Subject: If you can read this you understand the example.\n", 'header_display: multiple latin encodings';
	is MIME::Mini::header_display("Subject: =?UTF-8?Q?=C3=BCtf?=\n"), "Subject: ütf\n", 'header_display: utf8 encoding (latin1-compatible chars)';
};

# Test parsing of nasty header parameters

subtest param => sub
{
	plan tests => 1;

	my $m = {};
	append_header($m, (my $h = "Content-Type: multipart/mixed; boundary*0*=\"iso-8859-1'en'%61a%61\" boundary*2=ccc boundary*1*=%62b%62"));
	is param($m, 'content-type', 'boundary'), 'aaabbbccc', 'param: split into out-of-order pieces with encoding';
};

# Test mimetype identification and defaults

subtest mimetype => sub
{
	plan tests => 5;

	my $m = {};
	append_header($m, "Content-Transfer-Encoding: wierd");
	append_header($m, "Content-Type: image/png");
	is mimetype($m), 'application/octet-stream', 'mimetype: unknown content transfer encoding';
	replace_header($m, "Content-Transfer-Encoding: 7bit");
	is mimetype($m), 'image/png', 'mimetype: explicit type';
	replace_header($m, "Content-Type: invalid/junk");
	is mimetype($m), 'text/plain', 'mimetype: invalid type';
	my $p = { mime_type => 'multipart/digest'};
	delete_header($m, 'Content-Type');
	is mimetype($m, $p), 'message/rfc822', 'mimetype: default in digest';
	is mimetype($m), 'text/plain', 'mimetype: default elsewhere';
};

# Test encoding identification and defaults

subtest encoding => sub
{
	plan tests => 9;

	my $m = {};
	$m->{body} = "hi\n";
	is encoding($m), '7bit', 'encoding: default encoding (7bit)';
	$m->{body} = "hi\xff\n";
	is encoding($m), '8bit', 'encoding: default encoding (8bit)';
	replace_header($m, "Content-Transfer-Encoding: wierd");
	$m->{body} = "hi\n";
	is encoding($m), '7bit', 'encoding: unknown encoding (7bit)';
	$m->{body} = "hi\xff\n";
	is encoding($m), '8bit', 'encoding: unknown encoding (8bit)';
	replace_header($m, "Content-Transfer-Encoding: 7bit");
	is encoding($m), '7bit', 'encoding: explicit encoding (7bit)';
	replace_header($m, "Content-Transfer-Encoding: 8bit");
	is encoding($m), '8bit', 'encoding: explicit encoding (8bit)';
	replace_header($m, "Content-Transfer-Encoding: BinAry");
	is encoding($m), 'binary', 'encoding: explicit encoding (binary)';
	replace_header($m, "Content-Transfer-Encoding: Quoted-Printable");
	is encoding($m), 'quoted-printable', 'encoding: explicit encoding (qp)';
	replace_header($m, "Content-Transfer-Encoding: BASE64");
	is encoding($m), 'base64', 'encoding: explicit encoding (b64)';
};

# Test filename identification and cleanup

subtest filename => sub
{
	plan tests => 1;

	my $m = {};
	append_header($m, (my $h = "Content-Type: text/plain; name=\"abc.txt\""));
	replace_header($m, ($h = "Content-Disposition: attachment; filename*0*=\"iso-8859-1'en_AU'C:\\\\a\\\\b\\\\c\\\\I'd tried to put lots\$ of !spaces\" filename*1*=\" &and (punctuation) and an escape %1b character in this filename.doc\""));
	is filename($m), 'I_d_tried_to_put_lots_of_spaces_and_punctuation_and_an_escape_character_in_this_filename.doc', 'filename: long, absolute, split, encoded, with nasty chars';
};

# Test creating encoded headers

subtest newheader => sub
{
	plan tests => 6;

	my $h1 = 'text with öne non-ascii char for qp';
	my $h2 = 'text with lööööööööööööööööööööööööööööts of non-ascii chars for b64';
	my $h3 = 'text with a loooooooooooooooooooooooooooöooooooooooooooooooooooong word with 1 non-ascii char for split qp';
	my $h4 = 'text with a löööööööööööööööööööööööööööööööööööööööööööööööööööñg word of non-ascii chars for split b64';
	my $h5 = 'text with Q-encoding special ö?=_chars for qp';

	my $m = {};
	append_header($m, "Header1: $h1");
	append_header($m, "Header2: $h2");
	append_header($m, "Header3: $h3");
	append_header($m, "Header4: $h4");
	append_header($m, "Header5: $h5");

	is mail2str($m), 'Header1: text with =?iso-8859-1?q?=F6ne?= non-ascii char for qp
Header2: text with
 =?iso-8859-1?b?bPb29vb29vb29vb29vb29vb29vb29vb29vb29vZ0cw==?= of non-ascii
 chars for b64
Header3: text with a =?iso-8859-1?q?loooooooooooooooo?=
 =?iso-8859-1?q?ooooooooooo=F6ooooo?= =?iso-8859-1?q?ooooooooooooooooo?=
 =?iso-8859-1?q?ong?= word with 1 non-ascii char for split qp
Header4: text with a
 =?iso-8859-1?b?bPb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vY=?=
 =?iso-8859-1?b?9vb29vb29vb29vb29vbxZw==?= word of non-ascii chars for split
 b64
Header5: text with Q-encoding special =?iso-8859-1?q?=F6=3F=3D=5Fchars?= for
 qp

', 'newheader: long encoded headers';
	cmp_deeply [display_encode header($m, 'header1')], [display_encode $h1], 'newheader: one non-ascii, qp';
	cmp_deeply [display_encode header($m, 'header2')], [display_encode $h2], 'newheader: many non-ascii, b64';
	cmp_deeply [display_encode header($m, 'header3')], [display_encode $h3], 'newheader: long, one non-ascii, split qp';
	cmp_deeply [display_encode header($m, 'header4')], [display_encode $h4], 'newheader: long, many non-ascii, split b64';
	cmp_deeply [display_encode header($m, 'header5')], [display_encode $h5], 'newheader: two non-ascii, qcode special chars, qp';
};

# Test creating encoded parameters

subtest newparam => sub
{
	plan tests => 7;

	my $m = {};
	append_header($m, 'Content-type: text/plain' .
		newparam('charset', 'us-ascii') .
		newparam('filename', 'he he he') .
		newparam('name', 'hé hé') .
		newparam('long1', '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890') .
		newparam('long2', '123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 ') .
		newparam('french', 'Ceci est un exemple très simple mais un peu long et avec un accent grave sur deux è', 'fr')
	);
	is mail2str($m), "Content-type: text/plain; charset=us-ascii; filename=\"he he he\";
 name*=iso-8859-1'en'h%E9%20h%E9;
 long1*0=1234567890123456789012345678901234567890;
 long1*1=1234567890123456789012345678901234567890; long1*2=1234567890;
 long2*0=\"123456789 123456789 123456789 123456789 \";
 long2*1=\"123456789 123456789 123456789 123456789 \"; long2*2=\"123456789 \";
 french*0*=iso-8859-1'fr'Ceci%20est%20un%20exemple%20tr%E8s%20s;
 french*1*=\"imple mais un peu long et avec un accent\";
 french*2*=%20grave%20sur%20deux%20%E8

", 'newparam';
	is param($m, 'content-type', 'charset'), 'us-ascii', 'newparam: charset';
	is param($m, 'content-type', 'filename'), 'he he he', 'newparam: filename';
	is param($m, 'content-type', 'name'), 'hé hé', 'newparam: name';
	is param($m, 'content-type', 'long1'), '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890', 'newparam: long1'; 
	is param($m, 'content-type', 'long2'), '123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 ', 'newparam: long2'; 
	is param($m, 'content-type', 'french'), 'Ceci est un exemple très simple mais un peu long et avec un accent grave sur deux è', 'newparam: french'; 
};

# Test creating mail objects

subtest newmail => sub
{
	plan tests => 10;

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'plain', body => "hello mail\n"))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: plain
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>

hello mail

\$/",
		'newmail: plain';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'latin1', body => "hello maîl\n"))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: latin1
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: text\/plain; charset=iso-8859-1
Content-Transfer-Encoding: quoted-printable

hello ma=EEl

\$/",
		'newmail: latin1';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'ctrl', body => "help me \x1b"))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: ctrl
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Transfer-Encoding: base64

aGVscCBtZSAb

\$/",
		'newmail: ctrl';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'plain longline', body => 'x' x 999 . "\n"))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: plain longline
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Transfer-Encoding: quoted-printable

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxx

\$/",
		'newmail: plain longline';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'latin1 longline no newline', body => 'Â' . 'x' x 998))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: latin1 longline no newline
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: text\/plain; charset=iso-8859-1
Content-Transfer-Encoding: quoted-printable

=C2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
xxxxxxxxxxxxxxxxxxxxxxxxxx

\$/",
		'newmail: latin1 longline no newline';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'parts', parts => [newmail(body => "hello\n"), newmail(body => "hëllô\n", filename => 'latin.txt'), newmail(body => "\x1b", filename=> 'escape.dat')]))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: parts
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=$boundary_re

--.+

hello

--.+
Content-Type: text\/plain; charset=iso-8859-1
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline; filename=latin.txt

h=EBll=F4

--.+
Content-Transfer-Encoding: base64
Content-Disposition: inline; filename=escape.dat

Gw==
--.+--

\$/",
		'newmail: parts';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'msg', message => newmail(qw(To to From from Subject nested), body => "hello\n")))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: msg
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: message\/rfc822

To: to
From: from
Subject: nested
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>

hello

\$/",
		'newmail: msg';

	like mail2str(mail2mbox(newmail(To => 'to@to.org', From => 'from@from.org', Subject => 'digest', type => 'multipart/digest', parts => [newmail(message => newmail(Subject => 'a', body => "hello\n")), newmail(message => newmail(Subject => 'b', body => "hëllô\n")), newmail(message => newmail(Subject => 'c', body => "\x1b\n"))]))),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: digest
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/digest; boundary=$boundary_re

--.+
Content-Type: message\/rfc822

Subject: a

hello

--.+
Content-Type: message\/rfc822

Subject: b
Content-Type: text\/plain; charset=iso-8859-1
Content-Transfer-Encoding: quoted-printable

h=EBll=F4

--.+
Content-Type: message\/rfc822

Subject: c
Content-Transfer-Encoding: base64

Gwo=
--.+--

\$/",
		'newmail: digest';

	my $m = mail2mbox newmail(qw(To to@to.org From from@from.org Subject parts), parts => []);
	append_part($m, newmail(body => "hello\n"));
	append_part($m, newmail(body => "hëllô\n", filename => 'latin.txt'));
	append_part($m, newmail(body => "\x1b", filename=> 'escape.dat'));

	like mail2str($m),
"/^From from\@from\.org  $mboxdate_re
To: to\@to\.org
From: from\@from\.org
Subject: parts
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=$boundary_re

--.+

hello

--.+
Content-Type: text\/plain; charset=iso-8859-1
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline; filename=latin.txt

h=EBll=F4

--.+
Content-Transfer-Encoding: base64
Content-Disposition: inline; filename=escape.dat

Gw==
--.+--

\$/",
		'newmail: append parts';

	writefile 'fname', "This is a file.\n";
	like mail2str(mail2mbox(newmail(qw(To to From from), filename => 'fname'))),
"/^From from  $mboxdate_re
To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Disposition: inline; filename=fname; size=1[67];
 creation-date.+;\\s+modification-date.+;\\s+read-date.+

This is a file.

\$/m",
		'newmail: headers and read file by name';
	unlink 'fname';
};

# Test manipulating mail objects

subtest manipulate => sub
{
	plan tests => 6;

	# Construct a message with headers to delete

	my $m = newmail(qw(To to From from), body => "This is a part.\n");
	$m = mail2multipart $m;
	append_header($m, 'X-Header: outer value');

	my $p = newmail(body => "This is another part.\n");
	append_header($p, 'X-Header: inner part value');
	append_part($m, $p);

	my $m2 = newmail(qw(To to From from), body => "This is a message.\n");
	append_header($m2, 'X-Header: inner message value');
	append_part($m, newmail(message => $m2));

	# Make sure that it looks like we expect

	like mail2str($m),
"/^To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=\"[^\"]+\"
X-Header: outer value

--\\S+

This is a part\.

--\\S+
X-Header: inner part value

This is another part.

--\\S+
Content-Type: message\/rfc822

To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
X-Header: inner message value

This is a message.

--\\S+?--
\$/",
		'manipulate: setup';

	# Delete a header from the top-level (not recursively)

	delete_header($m, 'x-header');

	like mail2str($m),
"/^To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=\"[^\"]+\"

--\\S+

This is a part\.

--\\S+
X-Header: inner part value

This is another part\.

--\\S+
Content-Type: message\/rfc822

To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
X-Header: inner message value

This is a message\.

--\\S+?--
\$/",
		'manipulate: delete_header non-recursive';

	# Delete a header recursively from a plain part and a message/rfc822 part

	delete_header($m, 'x-header', 1);

	like mail2str($m),
"/^To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=\"[^\"]+\"

--\\S+

This is a part\.

--\\S+

This is another part\.

--\\S+
Content-Type: message\/rfc822

To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>

This is a message\.

--\\S+?--
\$/",
		'manipulate: delete_header recursive';

	# Insert/replace/delete parts

	delete_part($m, 2);

	like mail2str($m),
"/^To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=\"[^\"]+\"

--\\S+

This is a part\.

--\\S+

This is another part\.

--\\S+?--
\$/",
		'manipulate: delete_part';

	$p = newmail(body => "This is a new part.\n");
	replace_part($m, $p, 1);

	like mail2str($m),
"/^To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=\"[^\"]+\"

--\\S+

This is a part\.

--\\S+

This is a new part\.

--\\S+?--
\$/",
		'manipulate: replace_part';

	$p = newmail(body => "This is a new new part.\n");
	insert_part($m, $p, 1);

	like mail2str($m),
"/^To: to
From: from
Date: $rfc822date_re
MIME-Version: 1\.0
Message-ID: <[^>]+>
Content-Type: multipart\/mixed; boundary=\"[^\"]+\"

--\\S+

This is a part\.

--\\S+

This is a new new part\.

--\\S+

This is a new part\.

--\\S+?--
\$/",
		'manipulate: insert_part';

};

# Test accessing mail objects components (body/parts/message)

subtest access => sub
{
	plan tests => 11;

	# Test body/parts/message when the message has a body

	my $m = newmail(qw(To to From from), body => "This is the body.\n");
	cmp_deeply body($m), "This is the body.\n", 'access: body';
	cmp_deeply message($m), undef, 'access: message when no message';
	cmp_deeply parts($m), [], 'access: parts when no parts';

	# Test body/parts/message when the message has parts

	$m = mail2multipart($m);
	my $p = parts($m);
	cmp_deeply body($m), undef, 'access: body when no body (parts)';
	cmp_deeply parts($m), [{ body => "This is the body.\n\n" }], 'access: parts';
	cmp_deeply message($m), undef, 'access: message when no message (parts)';

	#  Test replacing parts

	parts($m, $p);
	cmp_deeply parts($m), [{ body => "This is the body.\n\n" }], 'access: parts';

	# Test body/parts/message when the message has a message/rfc822

	$m = newmail(message => newmail(qw(To to From from), body => "This is a message.\n"));
	cmp_deeply body($m), undef, 'access: body when no body (message)';
	cmp_deeply parts($m), [], 'access: parts when no parts (message)';
	cmp_deeply message($m),
	{
		header => {
			to => ["To: to\n"],
			from => ["From: from\n"],
			date => [re("Date: $rfc822date_re\n")],
			'message-id', [re("Message-ID: <[^>]+>\n")],
			'mime-version', ["MIME-Version: 1.0\n"]
		},
		headers => [
			"To: to\n",
			"From: from\n",
			re("Date: $rfc822date_re"),
			"MIME-Version: 1.0\n",
			re("Message-ID: <[^>]+>\n")
		],
		body => "This is a message.\n\n"
	},
	'access: message';

	is MIME::Mini::MESSAGE_CLASS(), 0x00078008, 'silly test just for coverage';
};

# Helper function for the following parsing tests

sub test_filter
{
	my ($ifname, $ofunc, $desc) = @_;
	my $ofname = $ifname;
	my $gfname = $ifname;
	$ofname =~ s,^t/in,t/out,;
	$gfname =~ s,^t/in,t/good,;
	mkdir $_ for grep { ! -d } qw(t/out t/out.m t/out.s t/out.sm);

	open my $ifh, '<', $ifname or warn("$0: Failed to open $ifname for reading: $!\n"), next;
	open my $ofh, '>', $ofname or warn("$0: Failed to open $ofname for writing: $!\n"), next;
	formail sub { <$ifh> }, sub { print $ofh $ofunc->(shift) };
	close $ifh;
	close $ofh;

	my $pathsep = ($ENV{PATH} =~ /;/) ? ';' : ':';
	if (scalar(grep { -x "$_/diff" } split /$pathsep/, $ENV{PATH})) # Windows has no diff
	{
		is `diff -u "$gfname" "$ofname" | grep -v 'No differences encountered'`, '', $desc; # Solaris diff is wierd
	}
	else
	{
		is readfile($ofname), readfile($gfname), $desc;
	}

	unlink $ofname if -f $gfname; # Keep the outfile if there's no goodfile yet
	use File::Copy; move $ofname, $gfname if -f $ofname; # Define it as good (first time)
}

# Test parser: "identity" mbox filter

subtest parse => sub
{
	my @fname = glob 't/in/*' or return;
	plan tests => scalar(@fname);
	test_filter $_, sub { mail2str mail2mbox shift }, "parse: $_" for @fname;
};

# Replace all(!) generated boundaries with static test boundary

sub boundary2test
{
	my $m = shift;
	my $b = 'test-boundary';
	$m =~ s/^(Content-Type:.+boundary=")[^"]+(")$/${1}$b${2}/img;
	$m =~ s/^(Content-Type:.+boundary=)[^"]\S+$/${1}$b/img;
	$m =~ s/^(--).+?((?:--)?)$/${1}$b${2}/mg;
	return $m;
}

# Test the boundary2test helper function

subtest boundary2test => sub
{
	plan tests => 7;

	is boundary2test("Content-Type: multipart/mixed; boundary=asdfasdf\n"), "Content-Type: multipart/mixed; boundary=test-boundary\n", 'boundary2test: Content-Type noquotes';
	is boundary2test("content-type: multipart/mixed; boundary=asdfasdf\n"), "content-type: multipart/mixed; boundary=test-boundary\n", 'boundary2test: content-type noquotes';
	is boundary2test("Content-Type: multipart/mixed; boundary=\"asdfasdf\"\n"), "Content-Type: multipart/mixed; boundary=\"test-boundary\"\n", 'boundary2test: Content-Type noquotes';
	is boundary2test("content-type: multipart/mixed; boundary=\"asdfasdf\"\n"), "content-type: multipart/mixed; boundary=\"test-boundary\"\n", 'boundary2test: content-type noquotes';
	is boundary2test("--asdfadf\n"), "--test-boundary\n", 'boundary2test: --asdfasdf\n';
	is boundary2test("--asdfadf-\n"), "--test-boundary\n", 'boundary2test: --asdfasdf-\n';
	is boundary2test("--asdfadf--\n"), "--test-boundary--\n", 'boundary2test: --asdfasdf--\n';
};

# Test parser: mbox filter with mail2multipart

subtest parse2multi => sub
{
	my @fname = glob 't/in.m/*' or return;
	plan tests => scalar(@fname);
	test_filter $_, sub { boundary2test mail2str mail2multipart shift }, "parse2multi: $_" for @fname;
};

# Test parser: mbox filter with mail2singlepart

subtest parse2single => sub
{
	my @fname = glob 't/in.s/*' or return;
	plan tests => scalar(@fname);
	test_filter $_, sub { mail2str mail2singlepart shift }, "parse2single: $_" for @fname;
};

# Test parser: mbox filter with both (multi then single)

subtest parse2multi2single => sub
{
	my @fname = glob 't/in.sm/*' or return;
	plan tests => scalar(@fname);
	test_filter $_, sub { mail2str mail2singlepart mail2multipart shift }, "parse2multi2single: $_" for @fname;
};

# vim:set fenc=latin1:
# vi:set ts=4 sw=4:
