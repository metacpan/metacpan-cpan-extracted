#!/usr/bin/perl -w

           use Test::Simple tests => 12;

use MathML::Entities;

ok(name2numbered('&copy;&nbsp;2004') eq '&#x000A9;&#x000A0;2004', 'XHTML entities to numeric char refs');
ok(name2utf8('&copy;&nbsp;2004') eq chr(169).chr(160).'2004', 'XHTML entities to utf-8');
ok(name2numbered('by &foo;') eq 'by &amp;foo;', 'Unknown entities I');
ok(name2utf8('by &foo;') eq 'by &amp;foo;', 'Unknown entities II');
ok(name2numbered('&amp;, &lt;, &gt;, &apos; &quot;') eq '&amp;, &lt;, &gt;, &apos; &quot;', 'Safe five I');
ok(name2utf8('&amp;, &lt;, &gt;, &apos; &quot;') eq '&amp;, &lt;, &gt;, &apos; &quot;', 'Safe five II');
ok(name2numbered('&AMP;, &LT;, &GT;, &APOS; &QUOT;') eq '&amp;, &lt;, &gt;, &apos; &quot;', 'Uppercase safe five I');
ok(name2utf8('&AMP;, &LT;, &GT;, &APOS; &QUOT;') eq '&amp;, &lt;, &gt;, &apos; &quot;', 'Uppercase safe five II');
ok(name2numbered('&conint;d&Ffr;') eq '&#x0222E;d&#x1D509;', 'MathML entities to numeric char refs');
ok(name2utf8('&conint;d&Ffr;') eq chr(8750).'d'.chr(120073), 'MathML entities to utf-8');
ok(name2numbered('&ThickSpace;&bne;') eq '&#x0205F;&#x0200A;&#x0003D;&#x020E5;', 'Multiple character refs');
ok(name2utf8('&ThickSpace;&bne;') eq chr(8287).chr(8202).chr(61).chr(8421), 'Multiple utf-8 characters');
