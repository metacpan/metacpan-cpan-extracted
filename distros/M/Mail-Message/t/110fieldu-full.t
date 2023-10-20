#!/usr/bin/env perl
#
# Test processing of full fields, the most complex (and slowest) kind of fields.
#

use strict;
use warnings;
use utf8;

use Mail::Message::Test;
use Mail::Message::Field::Structured;

use Test::More tests => 74;
use Encode qw(decode);


my $mmfs = 'Mail::Message::Field::Structured';

#
# Test construction
#

my $a = $mmfs->new('a', '');
isa_ok($a, $mmfs);

is($a->unfoldedBody, '');

my $a2 = $mmfs->new('a2', 0);
isa_ok($a2, $mmfs);
is($a2->string, "a2: 0\n");

is($a2->unfoldedBody, '0');

is($a->study, $a, 'is studied');

#
# Test adding comments
#

my @p =
 ( 'abc'      => 'abc'
 , '(abc)'    => '(abc)'
 , 'a(bc)'    => 'a(bc)'
 , '(ab)c'    => '(ab)c'
 , '(a)b(c)'  => '(a)b(c)'
 , '(a)(b)c'  => '(a)(b)c'
 , '(a)b(c)'  => '(a)b(c)'
 , '(a)(b)(c)'=> '(a)(b)(c)'
 , '()abc'    => '()abc'
 , 'ab()c'    => 'ab()c'
 , 'abc()'    => 'abc()'
 , '()a()b()c()' => '()a()b()c()'
 , ')abc'     => '\)abc'
 , '(abc'     => '\(abc'
 , 'abc('     => 'abc\('
 , 'abc)'     => 'abc\)'
 , 'a)b(c'    => 'a\)b\(c'
 , 'a)(bc'    => 'a\)\(bc'
 , 'a))(bc'   => 'a\)\)\(bc'
 , ')a)(bc'   => '\)a\)\(bc'
 , '(a(b)c'   => '\(a(b)c'
 , 'a\bc'     => 'a\bc'
 , 'a\(bc'    => 'a\(bc'
 , 'abc\('    => 'abc\('
 , 'abc\\'    => 'abc'
 , 'abc\\\\'  => 'abc'
 , '\\'       => ''
 );

while(@p)
{  my ($f, $t) = (shift @p, shift @p);
   is($mmfs->createComment($f), "($t)",       "from $f");
}

#
# Test adding phrases
#

@p =
 ( 'a'         => 'a'
 , 'a b c'     => '"a b c"'
 , 'a \b c'    => '"a \\\\b c"'     # even within ', you have to use \\
 , 'a "b c'    => '"a \"b c"'
 , 'a \\"b c'   => '"a \\\\\"b c"'
 );

while(@p)
{  my ($f, $t) = (shift @p, shift @p);
   is($mmfs->createPhrase($f), $t,  "from $f");
}

#
# Test word encoding Quoted-Printable
#

my $b = $mmfs->new('b', '');
isa_ok($b, $mmfs);

is($b->encode('abc'), 'abc');
is($b->encode('abc', force => 1), '=?us-ascii?q?abc?=');
is($b->encode('abc', encoding => 'Q', force => 1), '=?us-ascii?Q?abc?=');

my $utf8 = decode('ISO-8859-1', "\x{E4}bc");

is($b->encode($utf8), '=?utf8?q?=C3=A4bc?=');  # autodetect utf8
is($b->encode($utf8, encoding => 'Q'), '=?utf8?Q?=C3=A4bc?=');

is($b->encode($utf8, charset => 'iso-8859-1'), '=?iso-8859-1?q?=E4bc?=');
is($b->encode($utf8, charset => 'ISO-8859-1'), '=?ISO-8859-1?q?=E4bc?=');
is($b->encode($utf8, charset => 'ISO-8859-1', language => 'nl-BE'),
      '=?ISO-8859-1*nl-BE?q?=E4bc?=');

my $long;
{  no utf8;
   $long = 'This is a long @text, with !! a few w3iRD ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ­ ® ¯ ° ± ² ³ ´ characters in it...';
}
$utf8 = decode('iso-8859-1', $long);

is $b->encode($utf8, charset => 'ISO-8859-9', language => 'nl-BE'),
  '=?ISO-8859-9*nl-BE?q?This_is_a_long_=40text=2C_with_!!_a_few_w3iRD_=A1_?= '
 .'=?ISO-8859-9*nl-BE?q?=A2_=A3_=A4_=A5_=A6_=A7_=A8_=A9_=AA_=AB_=AC_=AD_=AE_?= '
 .'=?ISO-8859-9*nl-BE?q?=AF_=B0_=B1_=B2_=B3_=B4_characters_in_it=2E=2E=2E?=';

is $b->encode($utf8, charset => 'ISO-8859-9'),
  '=?ISO-8859-9?q?This_is_a_long_=40text=2C_with_!!_a_few_w3iRD_=A1_=A2_=A3_?= '
 .'=?ISO-8859-9?q?=A4_=A5_=A6_=A7_=A8_=A9_=AA_=AB_=AC_=AD_=AE_=AF_=B0_=B1_?= '
 .'=?ISO-8859-9?q?=B2_=B3_=B4_characters_in_it=2E=2E=2E?=';

#
# Test word encoding Base64
#

my $c = $mmfs->new('c', '');
is($c->encode('abc', encoding => 'b'), '=?us-ascii?b?YWJj?=');
is($c->encode('abc', encoding => 'B'), '=?us-ascii?B?YWJj?=');
is($c->encode('abc', encoding => 'b', charset => 'iso-8859-1'), '=?iso-8859-1?b?YWJj?=');
is($c->encode('abc', encoding => 'b', charset => 'ISO-8859-1'),
       '=?ISO-8859-1?b?YWJj?=');
is($c->encode('abc', encoding => 'b', charset => 'ISO-8859-1', language => 'nl-BE'),
      '=?ISO-8859-1*nl-BE?b?YWJj?=');
is($c->encode($long, encoding => 'b', charset => 'ISO-8859-9', language => 'nl-BE'),
  '=?ISO-8859-9*nl-BE?b?VGhpcyBpcyBhIGxvbmcgQHRleHQsIHdpdGggISEgYSBmZXcgdzNp?= '
. '=?ISO-8859-9*nl-BE?b?UkQgoSCiIKMgpCClIKYgpyCoIKkgqiCrIKwgrSCuIK8gsCCxILIg?= '
. '=?ISO-8859-9*nl-BE?b?syC0IGNoYXJhY3RlcnMgaW4gaXQuLi4=?='
);

is($c->encode($long, encoding => 'b', charset => 'ISO-8859-9'),
  '=?ISO-8859-9?b?VGhpcyBpcyBhIGxvbmcgQHRleHQsIHdpdGggISEgYSBmZXcgdzNpUkQg?= '
. '=?ISO-8859-9?b?oSCiIKMgpCClIKYgpyCoIKkgqiCrIKwgrSCuIK8gsCCxILIgsyC0IGNo?= '
. '=?ISO-8859-9?b?YXJhY3RlcnMgaW4gaXQuLi4=?='
);

#
# Test word decoding Quoted-Printable
#

my $d = $mmfs->new('d', '');

no utf8;   # Next list is typed in iso-8859-1  (latin-1)
my @ex_qp =
 ( # examples from rfc2047
   '=?iso-8859-1?q?this=20is=20some=20text?=' => 'this is some text'
 , '=?US-ASCII?Q?Keith_Moore?='               => 'Keith Moore'
 , '=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?='    => 'Keld Jørn Simonsen'
 , '=?ISO-8859-1?Q?Andr=E9?= Pirard'          => 'André Pirard'
 , '=?ISO-8859-1?Q?Olle_J=E4rnefors?='        => 'Olle Järnefors'
 , '=?ISO-8859-1?Q?Patrik_F=E4ltstr=F6m?='    => 'Patrik Fältström'
 , '(=?ISO-8859-1?Q?a?=)'                     => '(a)'
 , '(=?ISO-8859-1?Q?a?= b)'                   => '(a b)'
 , '(=?ISO-8859-1?Q?a?= =?ISO-8859-1?Q?b?=)'  => '(ab)'
 , '(=?ISO-8859-1?Q?a?=   =?ISO-8859-1?Q?b?=)'=> '(ab)'
 , '(=?ISO-8859-1?Q?a?=
       =?ISO-8859-1?Q?b?=)'                   => '(ab)'
 , '(=?ISO-8859-1?Q?a_b?=)'                   => '(a b)'
 , '(=?ISO-8859-1?Q?a?= =?ISO-8859-1?Q?_b?=)' => '(a b)'
 , '(=?ISO-8859-1?Q?a_?= =?ISO-8859-1?Q?b?=)' => '(a b)'

   # extra tests
 , '=???abc?='                                => 'abc'  # illegal but accepted
 , '=?ISO-8859-1*nl-BE?Q?a?='                 => 'a'
 , '(a =?ISO-8859-1?Q?b?=)'                   => '(a b)'
 );

use utf8;

while(@ex_qp)
{   my ($from, $to) = (shift @ex_qp, shift @ex_qp);
    my $utf8_to = decode('iso-8859-1', $to);
    is($d->decode($from), $utf8_to, $from);
}

#
# Test word decoding Quoted-Printable
#

no utf8;   # Next list is typed in iso-8859-1  (latin-1)
my @ex_b64 =
 ( # examples from rfc2047

   ' =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
     =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?='
         => ' If you can read this you understand the example.'


# Hebrew example cannot be used: I do not know what it should look like.
# =?iso-8859-8?b?7eXs+SDv4SDp7Oj08A==?=
 );
use utf8;

while(@ex_b64)
{   my ($from, $to) = (shift @ex_b64, shift @ex_b64);
    my $utf8_to = decode('iso-8859-1', $to);
    is($d->decode($from), $utf8_to);
}
