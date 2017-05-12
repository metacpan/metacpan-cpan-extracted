#! /usr/bin/perl -w
use strict;

use Test::NoWarnings;
use Test::More tests => 134;

BEGIN { use_ok('IMAP::BodyStructure'); }

my %nstrings = (
    '"aaaa" '	    =>  ['aaaa', 6],
    'NIL '	    =>  [undef, 3],
    '  "QNIL"'	    =>  ['QNIL', 8],
    ' "ka\\\\ppa" ' =>  ['ka\ppa', 10],
    ' "a \"bb\" a" '=>  ['a "bb" a', 13],
    "{4}\r\nLNIL"   =>  ['LNIL', 9],
    'AA'	    =>  ['AA', 2],
    "{33000}\r\n" 
     . ('@' x 33000)=>  ['@' x 33000, 33000 + 9],
    '"\\\\"'        =>  ['\\', 4],
    '"\\\\" "'      =>  ['\\', 4],
);

while (my ($nstr, $data) = each (%nstrings)) {
    is(IMAP::BodyStructure::_get_nstring($nstr), $data->[0], "nstring [" . (substr($data->[0] || '', 0, 20) || '<undef>') . ']');
    is(pos($nstr), $data->[1], "pos for [" . (substr($data->[0] || '', 0, 20) || '<undef>') . ']');
}

ok(my $bs = IMAP::BodyStructure->new('("text" "plain" NIL NIL NIL "8bit" 41 5 NIL NIL NIL)'),
    'parsed');

is($bs->{type}, 'text/plain', 'type');
ok(exists $bs->{params} && !defined $bs->{params}, 'NIL body params');
ok(exists $bs->{cid} && !defined $bs->{cid}, 'NIL body id');
is($bs->{encoding}, '8bit', 'non-NIL body encoding');
is($bs->{size}, 41, 'body size');
is($bs->{textlines}, 5, 'textlines of text/plain');
ok(exists $bs->{disp} && !defined $bs->{disp}, 'NIL body disp');
is($bs->{part_id}, 1, 'part_id of a single-part message');

$bs = IMAP::BodyStructure->new('("text" "plain" ("cool" "\"yeah\"") "cont\\\\id" "Really cool message" "8bit" 41 5 NIL NIL NIL)');
is($bs->{params}->{cool}, '"yeah"', 'non-NIL body params');
is($bs->{cid}, 'cont\\id', 'non-NIL body id');
is($bs->{desc}, 'Really cool message', 'non-NIL body desc');

isa_ok($bs->part_at('1'), 'IMAP::BodyStructure');
is($bs->part_at('1')->type, 'text/plain', 'simple part_at access 1');
isa_ok($bs->part_at(''), 'IMAP::BodyStructure');
is($bs->part_at('')->type, 'text/plain', 'simple part_at access 2');

ok(!defined $bs->part_at('1.u1'), 'no UU-parts work in this module at all');

$bs = IMAP::BodyStructure->new('("text" "plain" ("charset" "utf-8") NIL NIL "8bit" 75 4 NIL ("inline" ("filename" "tolower")) "en_US")');
is($bs->{params}->{charset}, 'utf-8', 'body charset');
is($bs->charset, 'utf-8', 'oop body charset');
is($bs->{disp}->[0], 'inline', 'body disp');
is($bs->{disp}->[1]->{filename}, 'tolower', 'body filename');
is($bs->{lang}->[0], 'en_US', 'body lang');

ok($bs = IMAP::BodyStructure->new('("message" "rfc822" ("name" "nice.name") NIL NIL "8bit" 269 (NIL "Part 5 of the outer message is itself an RFC822 message!" NIL NIL NIL NIL NIL NIL NIL NIL) ("text" "plain" ("charset" "ISO-8859-1") NIL NIL "quoted-printable" 58 1 NIL NIL NIL) 8 NIL NIL NIL)'), 'parse message/rfc822');
is($bs->{type}, 'message/rfc822', 'message/rfc822 type');
is($bs->{envelope}->{subject}, "Part 5 of the outer message is itself an RFC822 message!",
    'subject from envelope');
is($bs->{bodystructure}->{params}->{charset}, 'ISO-8859-1', 'message/rfc822 body charset');
is($bs->{textlines}, 8, 'textlines of message/rfc822');
is($bs->{part_id}, '1', 'part_id of a message/rfc822 part');

ok($bs = IMAP::BodyStructure->new('(("text" "plain" ("charset" "utf-8") NIL NIL "8bit" 75 4 NIL ("inline" NIL) NIL)("text" "plain" ("charset" "us-ascii" "name" "tolower") NIL NIL "8bit" 84 5 NIL ("attachment" ("filename" "tolower")) ("tr_CY" "tr_TR"))("application" "x-tar-gz" ("name" "p5-HTML-Template-JIT.tar.gz") NIL NIL "base64" 1642 NIL ("attachment" ("filename" "p5-HTML-Template-JIT.tar.gz")) NIL)("image" "png" ("name" "=?KOI8-R?Q?=C4=C9=D3=CB=C9=CD=C7.png?=") NIL NIL "base64" 280 NIL ("attachment" ("filename" "=?KOI8-R?Q?=C4=C9=D3=CB=C9=CD=C7.png?=")) NIL) "mixed" ("boundary" "ExXT7PjY8AI4Hyfa") ("inline" NIL) NIL)'), 'multipart parse');
is($bs->{type}, 'multipart/mixed', 'multipart type');
is($bs->{params}->{boundary}, 'ExXT7PjY8AI4Hyfa', 'multipart boundary');
is($bs->{disp}->[0], 'inline', 'multipart disp');
is($bs->{parts}->[0]->{type}, 'text/plain', 'multipart[0] type');
is($bs->{parts}->[0]->{params}->{charset}, 'utf-8', 'multipart[0] charset');
is($bs->{parts}->[1]->{disp}->[0], 'attachment', 'multipart[1] disp');
is($bs->{parts}->[1]->{disp}->[1]->{filename}, 'tolower', 'multipart[1] filename');
is($bs->{parts}->[1]->{lang}->[1], 'tr_TR', 'multipart[1] lang from a list');
is($bs->{parts}->[2]->{encoding}, 'base64', 'multipart[2] encoding');
is($bs->{parts}->[3]->{type}, 'image/png', 'multipart[3] type');
ok(!exists $bs->{parts}->[3]->{textlines}, 'multipart[3] does not have textlines');
is($bs->{parts}->[1]->{part_id}, '2', 'part_id of a second part');

is(scalar @{$bs->{parts}->[0]->{parts}}, 0, 'singlepart contains 0 parts');

ok($bs = IMAP::BodyStructure->new('(("text" "plain" NIL NIL NIL "8bit" 213 5 NIL NIL NIL)("text" "plain" ("charset" "us-ascii") NIL NIL "8bit" 144 4 NIL NIL NIL)(("image" "gif" ("name" "3d-vise.gif") NIL NIL "base64" 574 NIL ("inline" ("filename" "3d-vise.gif")) NIL)("image" "gif" ("name" "3d-eye.gif") NIL NIL "base64" 568 NIL ("inline" ("filename" "3d-eye.gif")) NIL) "parallel" ("boundary" "unique-boundary-2") NIL NIL)("text" "richtext" NIL NIL NIL "8bit" 152 4 NIL NIL NIL)("message" "rfc822" ("name" "nice.name") NIL NIL "8bit" 275 (NIL "Part 5 of the outer message is itself an RFC822 message!" NIL NIL NIL NIL NIL NIL NIL NIL) ("text" "plain" ("charset" "ISO-8859-1") NIL NIL "quoted-printable" 58 1 NIL NIL NIL) 8 NIL NIL NIL) "mixed" ("boundary" "unique-boundary-1") NIL NIL)'), 'multipart 2 parse');
is($bs->{parts}->[2]->{type}, 'multipart/parallel', 'nested multipart type');
is($bs->{parts}->[2]->{parts}->[0]->{part_id}, '3.1', 'nested part_id');
is($bs->{parts}->[4]->{type}, 'message/rfc822', 'nested message');
is($bs->{parts}->[4]->{bodystructure}->{encoding}, 'quoted-printable', 'QP body in nested message');

ok($bs = IMAP::BodyStructure->new('(("text" "plain" ("charset" "KOI8-R") NIL NIL "8bit" 41 4 NIL ("inline" NIL) NIL)("message" "rfc822" NIL NIL NIL "8bit" 7140 (NIL "A postcard for you" (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) ((NIL NIL "noone" "")) NIL NIL NIL NIL) (("text" "plain" NIL NIL NIL "binary" 91 3 NIL ("inline" NIL) NIL)(("text" "html" NIL NIL NIL "binary" 126 3 NIL ("inline" NIL) NIL)("image" "jpeg" ("name" "bluedot.jpg") "my-graphic" NIL "base64" 5886 NIL ("inline" ("filename" "bluedot.jpg")) NIL) "related" ("boundary" "----------=_961872013-1436-1") NIL NIL) "alternative" ("boundary" "----------=_961872013-1436-0") NIL NIL) 139 NIL ("inline" NIL) NIL) "mixed" ("boundary" "SUOF0GtieIMvvwua") ("inline" NIL) NIL)'), 'multipart with real nested message parse');

is($bs->{parts}->[1]->{part_id}, '2', 'message/rfc822 part part_id');
is($bs->{parts}->[1]->type, 'message/rfc822', 'message/rfc822 part type');
is($bs->{parts}->[1]->{bodystructure}->{part_id}, '2.TEXT', 'message/rfc822 bodystructure part_id');
is($bs->{parts}->[1]->{bodystructure}->type, 'multipart/alternative', 'message/rfc822 bodystructure type');
is($bs->{parts}->[1]->{bodystructure}->{parts}->[0]->{part_id}, '2.1', 'message/rfc822 nested part_id');
is($bs->{parts}->[1]->{bodystructure}->{parts}->[0]->type, 'text/plain', 'message/rfc822 nested type 1');
is($bs->{parts}->[1]->{bodystructure}->{parts}->[1]->{part_id}, '2.2', 'nested part_id 2');
is($bs->{parts}->[1]->{bodystructure}->{parts}->[1]->type, 'multipart/related', 'message/rfc822 nested type 2');
is($bs->{parts}->[1]->{bodystructure}->{parts}->[1]->{parts}->[0]->{part_id}, '2.2.1', 'nested nested part_id');
is($bs->{parts}->[1]->{bodystructure}->{parts}->[1]->{parts}->[0]->type, 'text/html', 'nested nested part type');

is($bs->{parts}->[1]->{type}, 'message/rfc822', 'message inside indeed');
is($bs->{parts}->[1]->{envelope}->{from}->[0]->{full}, 'Mail Delivery System <MAILER-DAEMON@capella.rambler.ru>', 'full from address');
is($bs->{parts}->[1]->{envelope}->{sender}->[0]->{name}, 'Mail Delivery System', 'sender name');
is($bs->{parts}->[1]->{envelope}->{to}->[0]->{account}, 'noone', 'full account');
is($bs->{parts}->[1]->{envelope}->{to}->[0]->{full}, 'noone@', 'full to');

ok($bs = IMAP::BodyStructure->new('(("text" "plain" ("charset" "utf-8") NIL NIL "8bit" 75 4 NIL ("inline" NIL) NIL)("text" "plain" ("charset" "us-ascii" "name" "tolower") NIL NIL "8bit" 84 5 NIL ("attachment" ("filename" "tolower")) NIL)("application" "x-tar-gz" ("name" "p5-HTML-Template-JIT.tar.gz") NIL NIL "base64" 1642 NIL ("attachment" ("filename" "p5-HTML-Template-JIT.tar.gz")) NIL)("image" "png" ("name" "=?KOI8-R?Q?=C4=C9=D3=CB=C9=CD=C7.png?=") NIL NIL "base64" 280 NIL ("attachment" ("filename" "=?KOI8-R?Q?=C4=C9=D3=CB=C9=CD=C7.png?=")) NIL) "mixed" ("boundary" "ExXT7PjY8AI4Hyfa") ("inline" NIL) NIL)'), 'oop multipart parse');
is($bs->type, 'multipart/mixed', 'oop multipart type');
is($bs->disp, 'inline', 'oop multipart disp');
is($bs->parts, 4, '4 parts inside');
is($bs->parts(0)->type, 'text/plain', 'oop multipart[0] type');
is($bs->parts(0)->charset, 'utf-8', 'oop multipart[0] charset');
is($bs->parts(1)->disp, 'attachment', 'oop multipart[1] disp');
is($bs->parts(1)->filename, 'tolower', 'oop multipart[1] filename');

is($bs->parts(0), $bs->part_at('1'), 'part_path 1');

ok($bs = IMAP::BodyStructure->new('(("text" "plain" ("charset" "KOI8-R") NIL NIL "8bit" 41 4 NIL ("inline" NIL) NIL)("message" "rfc822" NIL NIL NIL "8bit" 7140 (NIL "A postcard for you" (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) ((NIL NIL "noone" "")) NIL NIL NIL NIL) (("text" "plain" NIL NIL NIL "binary" 91 3 NIL ("inline" NIL) NIL)(("text" "html" NIL NIL NIL "binary" 126 3 NIL ("inline" NIL) NIL)("image" "jpeg" ("name" "bluedot.jpg") "my-graphic" NIL "base64" 5886 NIL ("inline" ("filename" "bluedot.jpg")) NIL) "related" ("boundary" "----------=_961872013-1436-1") NIL NIL) "alternative" ("boundary" "----------=_961872013-1436-0") NIL NIL) 139 NIL ("inline" NIL) NIL) "mixed" ("boundary" "SUOF0GtieIMvvwua") ("inline" NIL) NIL)'), 'oop multipart with real nested message parse');

is($bs->parts(0), $bs->part_at('1'), 'part_path 2');
is($bs->parts(1), $bs->part_at('2'), 'part_path 2 1/2');
is($bs->parts(1)->{bodystructure}, $bs->part_at('2.TEXT'), 'part_path 3 - 1/4');
is($bs->parts(1)->{bodystructure}->parts(0), $bs->part_at('2.1'), 'part_path 3');

ok(!defined $bs->part_at('4'), 'wrong 1st level part');
ok(!defined $bs->part_at('4.3'), 'wrong 1st level part (deep 1)');
ok(!defined $bs->part_at('4.3.4'), 'wrong 1st level part (deep 2)');
ok(!defined $bs->part_at('2.666'), 'wrong 2nd level part');
ok(!defined $bs->part_at('2.666.1'), 'wrong 2nd level part (deep 1)');
ok(!defined $bs->part_at('2.666.TEXT'), 'wrong 2nd level part (deep 1 TEXT)');
ok(!defined $bs->part_at('2.1.33'), 'wrong 3rd level part');
ok(!defined $bs->part_at('2.1.33.1'), 'wrong 3rd level part (deep 1)');

ok($bs = IMAP::BodyStructure->new('(("text" "plain" ("charset" "KOI8-R") NIL NIL "8bit" 41 4 NIL ("inline" NIL) NIL)("message" "rfc822" NIL NIL NIL "8bit" 7140 (NIL "A postcard for you" (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) (("Mail Delivery System" NIL "MAILER-DAEMON" "capella.rambler.ru")) ((NIL NIL "noone" "")) NIL NIL NIL NIL) ("message" "rfc822" ("name" "nice.name") NIL NIL "8bit" 269 (NIL "Part 5 of the outer message is itself an RFC822 message!" NIL NIL NIL NIL NIL NIL NIL NIL) ("text" "plain" ("charset" "ISO-8859-1") NIL NIL "quoted-printable" 58 1 NIL NIL NIL) 8 NIL NIL NIL) 139 NIL ("inline" NIL) NIL) "mixed" ("boundary" "SUOF0GtieIMvvwua") ("inline" NIL) NIL)'), 'm/r inside single-part m/r (extra artificial hierarchy level)');

isa_ok($bs->part_at('2.1'), 'IMAP::BodyStructure');

is($bs->{parts}->[1]->{part_id}, '2', 'obvious');
is($bs->{parts}->[1]->{type}, 'message/rfc822', 'm/r type');
is($bs->{parts}->[1]->{bodystructure}->{part_id}, '2.TEXT', 'm/r bs part_id');
is($bs->{parts}->[1]->{bodystructure}->{type}, 'message/rfc822',
    'm/r inside m/r type');
is($bs->{parts}->[1]->{bodystructure}->{bodystructure}->{part_id}, '2.1',
    'm/r inside m/r part_id');
is($bs->{parts}->[1]->{bodystructure}->{bodystructure}->{type}, 'text/plain',
    'm/r inside m/r type');
is($bs->{parts}->[1]->{bodystructure}->{bodystructure},
    $bs->part_at('2.1'), 'part_at on m/r inside m/r');

is($bs->part_at(''), $bs);
is($bs->part_at('1')->type, 'text/plain');
is($bs->part_at('1'), $bs->{parts}->[0]);
is($bs->part_at('2')->type, 'message/rfc822');
is($bs->part_at('2')->size, 7140);
is($bs->part_at('2'), $bs->{parts}->[1]);
is($bs->part_at('2.TEXT')->type, 'message/rfc822');
is($bs->part_at('2.TEXT')->size, 269);
is($bs->part_at('2.TEXT'), $bs->{parts}->[1]->{bodystructure});
is($bs->part_at('2.1')->type, 'text/plain', 'dive into TWO nested m/r for type');
is($bs->part_at('2.1')->size, 58, '... for size');
is($bs->part_at('2.1'), $bs->{parts}->[1]->{bodystructure}->{bodystructure}, '... ref compare to direct access');

ok(!defined $bs->part_at('2.2'), 'only 1 part inside message/rfc822');

#is($bs->parts(1)->from, 'Mail Delivery System <MAILER-DAEMON@capella.rambler.ru>', 'oop full from address');
#is($bs->parts(1)->sender_name, 'Mail Delivery System', 'oop sender name');

ok($bs = IMAP::BodyStructure->new(qq|("message" "rfc822" ("name" "nice.name") NIL NIL "8bit" 269 ("Tue, 18 May 2004 15:33:05 +0400" {94}\r\n[ura\@antar.bryansk.ru: =?koi8-r?B?7sUgyM/E?=\t=?koi8-r?B?ydTFLCDExcbGy8ksIMsg5sTV3tUuLi4=?= :)] (("Alexander M. Pravking" NIL "fduch" "antar.bryansk.ru")) (("Alexander M. Pravking" NIL "fduch" "dyatel.antar.bryansk.ru")) (("Alexander M. Pravking" NIL "fduch" "antar.bryansk.ru")) (("Alex Kapranoff" NIL "alex" "kapranoff.ru")) NIL NIL NIL "<20040518113305.GB39041\@dyatel.antar.bryansk.ru>") ("text" "plain" ("charset" "ISO-8859-1") NIL NIL "quoted-printable" 58 1 NIL NIL NIL) 8 NIL NIL NIL)|), 'parse message/rfc822');
ok($bs->{envelope}->{from}, 'literal with ")" inside'); 

ok($bs = IMAP::BodyStructure->new(q|(("text" "plain" ("charset" "koi-8") NIL NIL "7bit" 324 15 NIL NIL NIL)("application" "octet-stream" ("name" "sms_name.zip") NIL NIL "base64" 384 NIL ("attachment" ("filename" "sms_name.zip")) NIL) "mixed" ("boundary" "------------F3493D6EC57AF05DFDF58977") NIL NIL)|), 'paragon mail that failed');
is($bs->parts(0)->type, 'text/plain', '1st part type');
is($bs->parts(1)->type, 'application/octet-stream', '2nd part type');
