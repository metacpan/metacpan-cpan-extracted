#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 42;
use HTML::Defang;

use strict;
use warnings;

my ($D, $R);

#################################
#  url_policy => 'mail'
#################################

$D = HTML::Defang->new(url_policy => 'mail', delete_defang_content => 1);

$R = $D->defang(<<'EOF');
1:<a href="http://example.com/">http</a>
2:<a href="mailto:a@example.com">mailto</a>
3:<a href="#top">anchor</a>
4:<a href="javascript:alert(1)">js</a>
5:<a href="java&#x09;script:alert(1)">js entity</a>
6:<a href="page.html">relative</a>
7:<img src="cid:part1@example.com">
8:<img src="data:image/png;base64,AAAA">
9:<img src="data:image/svg+xml;base64,AAAA">
10:<img src="https://example.com/i.png">
11:<img src="mailto:a@example.com">
12:<table background="cid:bg@example.com">
13:<p style="background: url(cid:bg@example.com)">
14:<p style="background: url(javascript:alert(1))">
15:<p style="background: url(http://example.com/a.png), url(file:///etc/passwd)">
EOF

like($R, qr{1:<a href="http://example.com/">}, "http link kept");
like($R, qr{2:<a href="mailto:a\@example.com">}, "mailto link kept");
like($R, qr{3:<a href="#top">}, "anchor link kept");
like($R, qr{4:<a >}, "javascript link removed");
like($R, qr{5:<a >}, "entity obfuscated javascript link removed");
like($R, qr{6:<a >}, "relative link removed");
like($R, qr{7:<img src="cid:part1\@example.com">}, "cid image kept");
like($R, qr{8:<img src="data:image/png;base64,AAAA">}, "inline png kept");
like($R, qr{9:<img >}, "inline svg removed");
like($R, qr{10:<img src="https://example.com/i.png">}, "https image kept");
like($R, qr{11:<img >}, "mailto image removed");
like($R, qr{12:<table background="cid:bg\@example.com">}, "cid table background kept");
like($R, qr{13:<p style="background: url\(cid:bg\@example.com\)">}, "cid CSS url kept");
like($R, qr{14:<p style="">}, "javascript CSS url removed");
like($R, qr{15:<p style="">}, "file CSS url after a good one removed");

ok(!eval { HTML::Defang->new(url_policy => 'nope'); 1 }, "Unknown url_policy dies");

#################################
#  extract_styles
#################################

$D = HTML::Defang->new(extract_styles => 1, delete_defang_content => 1);

$R = $D->defang(<<'EOF');
<style>p { color: red }</style><p>Text</p>
<style media="print">p { color: black }</style>
<style>q { color: blue } </div> { x: y }</style>
<style></style>
EOF

unlike($R, qr{<style|</style}i, "Style tags removed from output");
like($R, qr{<p>Text</p>}, "Content kept");
like($D->extracted_styles, qr{^p \{ color: red \}\n}, "First style extracted");
like($D->extracted_styles, qr{\@media print \{\np \{ color: black \}\n\}}, "media attribute becomes an \@media block");
unlike($D->extracted_styles, qr{</}, "Nothing in extracted styles can close a style element");

$D->defang('<p>No styles</p>');
is($D->extracted_styles, '', "Extracted styles reset on each call");

$R = HTML::Defang->new(extract_styles => 1)->defang('<style>p { color: red }</style>');
is($R, '', "Style tags removed without delete_defang_content too");

#################################
#  scope_id
#################################

$D = HTML::Defang->new(scope_id => 'qt', extract_styles => 1, delete_defang_content => 1);

$R = $D->defang(<<'EOF');
<style>
body { color: red }
html body td, .a .b, #c > p.d { padding: 0 }
body.e, body > table, :root { margin: 0 }
body + div, html ~ p { dropped: 1 }
* p, a:not(.f):hover { x: y }
[class~="g h"], [class*=i], [id^=j], [title="a,b"] { z: 1 }
@media (max-width: 600px) { .m td { display: block } }
@font-face { font-family: X }
</style>
<div id="c" class="a  b"><a href="#c">to c</a><a name="n">n</a><a href="#">top</a>
<label for="k">L</label><img usemap="#map"><map name="map"></map></div>
EOF

my @Rules = split /\n/, $D->extracted_styles;
is($Rules[1], '#qt { color: red }', "body selector is the scope element");
is($Rules[2], '#qt td, #qt .qt-a .qt-b, #qt #qt-c > p.qt-d { padding: 0 }', "Selectors scoped, ids and classes prefixed");
is($Rules[3], '#qt.qt-e, #qt > table, #qt { margin: 0 }', "Compound and child selectors on body, and :root");
unlike($D->extracted_styles, qr{dropped}, "Rule matching only siblings of html/body dropped");
is($Rules[4], '#qt p, #qt a:not(.qt-f):hover { x: y }', "Leading * and classes inside :not()");
is($Rules[5], '#qt [class~="qt-g qt-h"], #qt [class*="i"], #qt [id^="qt-j"], #qt [title="a,b"] { z: 1 }', "Attribute selectors");
is($Rules[6], '@media (max-width: 600px) { #qt .qt-m td { display: block } }', "Rules inside \@media scoped");
is($Rules[7], '@font-face { font-family: X }', "Other at-rules left alone");

like($R, qr{<div id="qt-c" class="qt-a  qt-b">}, "id and classes prefixed in markup");
like($R, qr{<a href="#qt-c">to c</a><a name="qt-n">n</a><a href="#">top</a>}, "Anchor links and names prefixed, bare # left");
like($R, qr{<label for="qt-k">L</label><img usemap="#qt-map"><map name="qt-map"></map>}, "for, usemap and map name prefixed");

ok(!eval { HTML::Defang->new(scope_id => 'a b'); 1 }, "Invalid scope_id dies");

#################################
#  new_quote/quote
#################################

$D = HTML::Defang->new_quote();

my $Q = $D->quote(<<'EOF');
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Promo</title><base href="http://example.com/">
<style>body { color: red } td.x { background: url(cid:bg@example.com) }</style><script>bad()</script></head>
<body bgcolor="#eee" text="navy" style="margin: 0; height: 100%; overflow: hidden; font-family: Arial">
<!--[if mso]>junk<![endif]--><table><tr><td class="x">Big <b>sale</b> <a href="javascript:x()">js</a>
<img src="cid:i1@example.com"></td></tr></table></blockquote><div>unclosed
</body></html>
EOF

unlike($Q->{html}, qr{DOCTYPE|<html|<head|<meta|<title|Promo|<base|<style|<script|bad\(\)|<body|junk|<!--}i, "Boilerplate, head, scripts and comments removed");
like($Q->{html}, qr{<td class="qt-x">Big <b>sale</b> <a >js</a>\n<img src="cid:i1\@example.com"></td>}, "Content kept, scoped, and URLs checked");
unlike($Q->{html}, qr{</blockquote>}, "Stray end tag that would close the quote removed");
like($Q->{html}, qr{<div>unclosed\s*</div>\s*$}, "Unclosed tag closed");
is($Q->{styles}, "#qt { color: red } #qt td.qt-x { background: url(cid:bg\@example.com) }\n", "Styles extracted and scoped");
is($Q->{body_style}, "background-color: #eee; color: navy; margin: 0; font-family: Arial", "Body presentation kept, without its sizing");

$Q = $D->quote('<p>Plain</p>');
is_deeply($Q, { html => '<p>Plain</p>', styles => '', body_style => '' }, "Nothing left over from the previous quote");
