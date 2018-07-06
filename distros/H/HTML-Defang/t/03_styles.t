#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 93;
use HTML::Defang;
use strict;

my ($Res, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', ' ', ' ');

my $Defang = HTML::Defang->new();

$H = <<EOF;
<style>
body {color: black}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
body \{color: black\}
$CommentEndText--></style>$}s, "Simple style tag");

$H = <<EOF;
<style>
body {font-family: &quot;sans\\0020serif&#x22;\\003b color\\003a black; }
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
body \{font-family: "sans serif"; color: black; \}
$CommentEndText--></style>$}s, "Style tag with html and unicode entities");

$H = <<EOF;
<style>
p {font-family: "sans serif"}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
p \{font-family: "sans serif"\}
$CommentEndText--></style>$}s, "Style tag property with quotes and space");

$H = <<EOF;
<style>
p {text-align:center;color:red}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
p \{text-align:center;color:red\}
$CommentEndText--></style>
$}s, "Multiple properties");

$H = <<EOF;
<style>
p
{
text-align: center;
color: black;
font-family: arial
}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
p
\{
text-align: center;
color: black;
font-family: arial
\}
$CommentEndText--></style>
$}s, "Multiple properties in readable format");

$H = <<EOF;
<style>
h1,h2,h3,h4,h5,h6 
{
color: green
}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
h1,h2,h3,h4,h5,h6 
\{
color: green
\}
$CommentEndText--></style>
$}s, "Multiple selectors");

$H = <<EOF;
<style>
p.right {text-align: right}
p.center {text-align: center}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
p.right \{text-align: right\}
p.center \{text-align: center\}
$CommentEndText--></style>
$}s, "Selector with a period");

$H = <<EOF;
<style>
.center {text-align: center}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
.center \{text-align: center\}
$CommentEndText--></style>
$}, "Selector starting in a period");

$H = <<EOF;
<style>
input[type="text"] {background-color: blue}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
input\[type="text"\] \{background-color: blue\}
$CommentEndText--></style>
$}s, "Selector with square brackets");

$H = <<EOF;
<style>
#green {color: green}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
#green \{color: green\}
$CommentEndText--></style>
$}s, "Selector starting with a hash");

$H = <<EOF;
<style>
p#para1
{
text-align: center;
color: red
}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
p#para1
\{
text-align: center;
color: red
\}
$CommentEndText--></style>
$}s, "Selector with a hash");

$H = <<EOF;
<style>
/* This is a comment */
p
{
text-align: center;
/* This is another comment */
color: black;
font-family: arial /* Comment here */
}/*
multi-line
comment here
*/
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}

p
\{
text-align: center;

color: black;
font-family: arial 
\}
$CommentEndText--></style>
$}s, "All sorts of comments");

$H = <<EOF;
<style>
body {color: black}
<divd>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
body \{color: black\}
$CommentEndText--></style><!--defang_divd-->
$}s, "Missing closing style tag");

$H = <<EOF;
<style>
body, super, man, spider, man {1color: black; kulam : potta; valippam:2%;}
abc {sup: s-up}
li {list-style-image: url("javascript:alert('XSS')");}
</style>
dinkiri/* some more */
<style>
body, super, man, spider, man {2color: black; kulam : potta; valippam:2%;}
abc {sup: s-up}
li {list-style-image: url("javascript:alert('XSS')");}
</style>
dinkare
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
body, super, man, spider, man \{1color: black; kulam : potta; valippam:2%;\}
abc \{sup: s-up\}
li \{/\*list-style-image: url\("javascript:alert\('XSS'\)"\);\*/\}
$CommentEndText--></style>
dinkiri/\* some more \*/
<style><!--${CommentStartText}
body, super, man, spider, man \{2color: black; kulam : potta; valippam:2%;\}
abc \{sup: s-up\}
li \{/\*list-style-image: url\("javascript:alert\('XSS'\)"\);\*/\}
$CommentEndText--></style>
dinkare
$}s, "Multiple style tags");

$H = <<EOF;
<STYLE>\@import'http://ha.ckers.org/xss.css';</STYLE>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<STYLE><!--${CommentStartText}$CommentEndText--></STYLE>$}s, "Remote style sheet part 2");

$H = <<EOF;
<STYLE>BODY{-moz-binding:url("http://ha.ckers.org/xssmoz.xml#xss")}</STYLE>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<STYLE><!--${CommentStartText}BODY\{/\*-moz-binding:url\("http://ha.ckers.org/xssmoz.xml#xss"\)\*/\}$CommentEndText--></STYLE>$}s, "Remote style sheet part 4");

$H = <<EOF;
<STYLE>li {list-style-image: url("javascript:alert('XSS')");}</STYLE><UL><LI>XSS
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<STYLE><!--${CommentStartText}li \{/\*list-style-image: url\("javascript:alert\('XSS'\)"\);\*/\}$CommentEndText--></STYLE><UL><LI>XSS$}s, "List-style-image");

$H = <<'EOF';
<STYLE>@im\port'\ja\vasc\ript:alert("XSS")';</STYLE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<STYLE><!--${CommentStartText}$CommentEndText--></STYLE>$}s, "List-style-image");

$H = <<EOF;
<STYLE>\@import'javascript:alert("XSS")';</STYLE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<STYLE><!--${CommentStartText}$CommentEndText--></STYLE>$}s, "Removing css imports");

$H = <<EOF;
<STYLE>\@import'javascript:alert("XSS")';
\@import'javascript:alert("XSS")';
a{sss:sss}</STYLE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<STYLE><!--${CommentStartText}

a\{sss:sss\}$CommentEndText--></STYLE>$}s, "Removing multiple css imports");

$H = <<EOF;
<STYLE>\@import'javascript:alert("XSS")';
\@import'javascript:alert("XSS")';
a{sss:11111111}</STYLE>
<someunknowntag>
<br>
<STYLE>\@import'javascript:alert("XSS")';
\@import'javascript:alert("XSS")';
a{sss:22222222}</STYLE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<STYLE><!--${CommentStartText}

a\{sss:11111111\}$CommentEndText--></STYLE>
<!--defang_someunknowntag-->
<br>
<STYLE><!--${CommentStartText}

a\{sss:22222222\}$CommentEndText--></STYLE>$}s, "Removing multiple css imports with multiple styles");

$H = <<EOF;
<STYLE>
<!--
p {property: value}
-->
</STYLE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<STYLE>
<!--${CommentStartText}
p \{property: value\}
$CommentEndText-->
</STYLE>$}s, "Removing HTML comments");


# Tests taken from http://imfo.ru/csstest/css_hacks/import.php

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 1");

$H = <<EOF;
<style>\@import url(style.css);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 2");

$H = <<EOF;
<style>\@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 3");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;) all;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 4");

$H = <<EOF;
<style>\@import url(&#34;&#38;#115;tyle.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 5");

$H = <<EOF;
<style>&#38;#64;import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 6");

$H = <<EOF;
<style>\@import url(&#34;style.%63ss&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 7");

$H = <<EOF;
<style>\@import/**/&#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 8");

$H = <<EOF;
<style>\@import &#34;style.css&#34;/**/;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 9");

$H = <<EOF;
<style>\@import url(/**/&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 10");

$H = <<EOF;
<style>\@imp\6F rt url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 11");

$H = <<EOF;
<style>\@import\**\&#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 12");

$H = <<'EOF';
<style>@im\port url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 13");

$H = <<EOF;
<style>\@import\ url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 14");

$H = <<EOF;
<style>\@import_url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 15");

$H = <<EOF;
<style>\@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 16");

$H = <<EOF;
<style> \@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 17");

$H = <<EOF;
<style>\@import &#34;style.css&#34; ;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 18");

$H = <<EOF;
<style>\@import url (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 19");

$H = <<EOF;
<style>\@import: url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 20");

$H = <<EOF;
<style>\@ import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 21");

$H = <<EOF;
<style>\@import url (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 22");

$H = <<EOF;
<style>\@import style.css;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 23");

$H = <<EOF;
<style>_\@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 24");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;)_;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 25");

$H = <<EOF;
<style>em{color:red};\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}em\{color:red\}$CommentEndText--></style>$}, "Test 26");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 27");

$H = <<EOF;
<style>\@import url\ (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 28");

$H = <<EOF;
<style>\@import ur\6C (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 29");

$H = <<EOF;
<style>\@import(style.css);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 30");

$H = <<EOF;
<style>\@import url(&#34;style.\63 ss&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 31");

$H = <<EOF;
<style>\@import url(&#34;style.
css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 32");

$H = <<EOF;
<style>\@import url(&#34;style.\
css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}$CommentEndText--></style>$}, "Test 33");

$H = <<EOF;
1:<a style="a:b">
2:<a style=" c  :   d    ">
3:<a style="e:f;">
4:<a style=" g  :   h    ;     ">

5:<a style="i:j;k:l">
6:<a style=" i2  :   j2    ;     k2      :       l2        ">
7:<a style="i3:j3;k3:l3;">
8:<a style=" i4  :   j4    ;     k4      :       l4        ;         ">

9:<a style="{q:r}">
10:<a style=" {  s   :    t     }      ">
11:<a style="{u:v;}">
12:<a style=" {  w   :    x     ;      }       ">

13:<a style="{i5:j5;k5:l5}">
14:<a style=" {  i6   :    j6     ;      k6       :        l6         }          ">
15:<a style="{i7:j7;k7:l7;}">
16:<a style=" {  i8   :    j8     ;      k8       :        l8         ;          }          ">

17:<a style="s1{y:z}">
18:<a style=" s1  {   y2    :     z2      }       ">
19:<a style="s1{y3:z3;}">
20:<a style=" s1  {   y4    :     z4      ;       }        ">

21:<a style="s1{y5:z5;y6:z6}">
22:<a style=" s2  {   y7    :     z7      ;       y8        :         z8          }           ">
23:<a style="s3{y9:z9;y10:z11;}">
24:<a style=" s4  {   y12    :     z12      ;       y13        :         z13          ;           }            ">

25:<a style="s5{aa:ab}s6{ac:ad}">
26:<a style=" s7  {   ae    :     af      }       s8        {         ag          :           ah            }             ">
27:<a style="s5{ai:aj;}s6{ak:al;}">
28:<a style=" s7  {   am    :     an      }       s8        {         ao          :           ap            ;             }              ">

29:<a style="{color: #900} :link {background: #ff0} :visited {background: #fff} :hover {outline: thin red solid} :active {background: #00f}">
30:<a style="{color: #090; line-height: 1.2} ::first-letter {color: #900}">
31:<a href="abccomscript" title="a" id="a1" style="{color: #900}
          :link {background: #ff0}
          :visited {background: #fff}
          :hover {outline: thin red solid}
          :active {background: #00f}">
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<a style="a:b">}, "Test style attribute - single property pair without braces, spaces and semi-colon");
like($Res, qr{2:<a style=" c  :   d    ">}, "Test style attribute - single property pair with spaces but without braces and semi-colon");
like($Res, qr{3:<a style="e:f;">}s, "Test style attribute - single property pair with semi-colon but without braces and spaces");
like($Res, qr{4:<a style=" g  :   h    ;     ">}s, "Test style attribute - single property pair with spaces and semi-colon but without braces");

like($Res, qr{5:<a style="i:j;k:l">}s, "Test style attribute - multiple property pairs without braces, spaces and semi-colon");
like($Res, qr{6:<a style=" i2  :   j2    ;     k2      :       l2        ">}s, "Test style attribute - multiple property pairs with spaces but without braces and semi-colon");
like($Res, qr{7:<a style="i3:j3;k3:l3;">}s, "Test style attribute - multiple property pairs with semi-colon  but without braces and spaces");
like($Res, qr{8:<a style=" i4  :   j4    ;     k4      :       l4        ;         ">}s, "Test style attribute - multiple property pairs with spaces and semi-colon but without braces ");

like($Res, qr{9:<a style="\{q:r\}">}s, "Test style attribute - single property pair with braces but without spaces and semi-colon");
like($Res, qr{10:<a style=" \{  s   :    t     \}      ">}s, "Test style attribute - single property pair with braces and spaces but without semi-colon");
like($Res, qr{11:<a style="\{u:v;\}">}s, "Test style attribute - single property pair with braces and semi-colon but without spaces");
like($Res, qr{12:<a style=" \{  w   :    x     ;      \}       ">}s, "Test style attribute - single property pair with braces, spaces and semi-colon");

like($Res, qr{13:<a style="\{i5:j5;k5:l5\}">}s, "Test style attribute - multiple property pair with braces but without spaces and semi-colon");
like($Res, qr{14:<a style=" \{  i6   :    j6     ;      k6       :        l6         \}          ">}s, "Test style attribute - multiple property pair with braces and spaces but without semi-colon");
like($Res, qr{15:<a style="\{i7:j7;k7:l7;\}">}s, "Test style attribute - multiple property pair with braces and semi-colon but without spaces");
like($Res, qr{16:<a style=" \{  i8   :    j8     ;      k8       :        l8         ;          \}          ">}s, "Test style attribute - multiple property pair with braces, spaces and semi-colon");

like($Res, qr{17:<a style="s1\{y:z\}">}s, "Test style attribute - single property pair with selectors and braces but without spaces and semi-colon");
like($Res, qr{18:<a style=" s1  \{   y2    :     z2      \}       ">}s, "Test style attribute - single property pair with selectors, braces and spaces but without semi-colon");
like($Res, qr{19:<a style="s1\{y3:z3;\}">}s, "Test style attribute - single property pair with selectors, braces and semi-colon but without spaces");
like($Res, qr{20:<a style=" s1  \{   y4    :     z4      ;       \}        ">}s, "Test style attribute - single property pair with selectors, braces spaces and semi-colon");

like($Res, qr{21:<a style="s1\{y5:z5;y6:z6\}">}s, "Test style attribute - multiple property pairs with selector and braces but without spaces and semi-colon");
like($Res, qr{22:<a style=" s2  \{   y7    :     z7      ;       y8        :         z8          \}           ">}s, "Test style attribute - multiple property pairs with selector, braces and spaces but without semi-colon");
like($Res, qr{23:<a style="s3\{y9:z9;y10:z11;\}">}s, "Test style attribute - multiple property pairs with selector, braces and semi-colon but without spaces");
like($Res, qr{24:<a style=" s4  \{   y12    :     z12      ;       y13        :         z13          ;           \}            ">}s, "Test style attribute - multiple property pairs with selector, braces spaces and semi-colon");

like($Res, qr{25:<a style="s5\{aa:ab\}s6\{ac:ad\}">}s, "Test style attribute - multiple property pairs with selectors and braces but without spaces and semi-colon");
like($Res, qr{26:<a style=" s7  \{   ae    :     af      \}       s8        \{         ag          :           ah            \}             ">}s, "Test style attribute - multiple property pairs with selectors, braces and spaces but without semi-colon");
like($Res, qr{27:<a style="s5\{ai:aj;\}s6\{ak:al;\}">}s, "Test style attribute - multiple property pairs with selectors, braces and semi-colon but without spaces");
like($Res, qr{28:<a style=" s7  \{   am    :     an      \}       s8        \{         ao          :           ap            ;             \}              ">}s, "Test style attribute - multiple property pairs with selectors, braces spaces and semi-colon");
like($Res, qr{29:<a style="\{color: #900\} :link \{background: #ff0\} :visited \{background: #fff\} :hover \{outline: thin red solid\} :active \{background: #00f\}">}s, "Test style attribute - style rule with and without selectors");
like($Res, qr{30:<a style="\{color: #090; line-height: 1.2\} ::first-letter \{color: #900\}">}, "Test style attribute - style rule with and without selectors in single line");
like($Res, qr{31:<a href="abccomscript" title="a" id="a1" style="\{color: #900\}&#x0a;          :link \{background: #ff0\}&#x0a;          :visited \{background: #fff\}&#x0a;          :hover \{outline: thin red solid\}&#x0a;          :active \{background: #00f\}">$}, "Test style attribute - style rule with and without selectors over multiple lines");

$H = <<EOF;
<style>   

selector1{ab:cd}
selector2{ab:cd;}
selector3{ab:cd;ef:gh}
selector4{ab:cd;ef:gh;}
selector5{ab:cd;x:y;p:q;r:url(http://a.com);e:url("http://b.com") ;}
 selector6  {   ab    :     cd      }       
 selector7  {   ab    :     cd      ;       }        
 selector8  {   ab    :     cd      ;       ef        :         gh          }           
 selector9  {   ab    :     cd      ;       ef        :         gh          ;           }            
 selector10  {   ab    :     cd      ;       x         :         y           ;           r            :             url(http://a.com)              }               
    </style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{<style><!--${CommentStartText}   

selector1\{ab:cd\}
selector2\{ab:cd;\}
selector3\{ab:cd;ef:gh\}
selector4\{ab:cd;ef:gh;\}
selector5\{ab:cd;x:y;p:q;/\*r:url\(http://a.com\);\*//\*e:url\("http://b.com"\) ;\*/\}
 selector6  \{   ab    :     cd      \}       
 selector7  \{   ab    :     cd      ;       \}        
 selector8  \{   ab    :     cd      ;       ef        :         gh          \}           
 selector9  \{   ab    :     cd      ;       ef        :         gh          ;           \}            
 selector10  \{   ab    :     cd      ;       x         :         y           ;           /\*r            :             url\(http://a.com\)              \*/\}               
    $CommentEndText--></style>}s, "Test style tag css with and without spaces");

$H = <<EOF;
<style>

<!--

body {color: black}

-->  
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style>

<!--${CommentStartText}

body \{color: black\}

$CommentEndText-->  
</style>$}s, "Style tag with HTML comments");

$H = <<EOF;
<style>
body {color: black}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
body \{color: black\}
$CommentEndText--></style>$}s, "Style tag without HTML comments");

$H = <<EOF;
<style><!--
body { background: #fff url("javascript:alert('XSS')"); }
--></style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
body \{ /\*background: #fff url\("javascript:alert\('XSS'\)"\);\*/ \}
${CommentEndText}--></style>$}s, "Background with separate url");

$H = <<EOF;
<style><!-- body { */background*/-image: url("javascript:alert('XSS')")/* } --></style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText} body \{ /\*background-image: url\("javascript:alert\('XSS'\)"\) \*/\} ${CommentEndText}--></style>$}s, "Lone end-comment/start-comment in style");


$H = <<EOF;
<style>
\@media all and (max-width: 699px) {
  body {
    border: 10px;
    color: black;
    padding: 20px
  }
}
\@media all and (min-width: 700px) {
  body {
    padding:1px;
    border:  2px;
    color: white
  }
}
</style>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<style><!--${CommentStartText}
\@media all and \(max-width: 699px\) \{
  body \{
    border: 10px;
    color: black;
    padding: 20px
  \}
\}
\@media all and \(min-width: 700px\) \{
  body \{
    padding:1px;
    border:  2px;
    color: white
  \}
\}
$CommentEndText--></style>$}s, "Media selectors");

$H = <<EOF;
<p style="font-size: 30px;; font-weight: lighter ;; line-height: 38px; ; color: #ffffff; font-family: 'Segoe UI Light', 'Segoe WP Light', 'Segoe UI', Helvetica, Arial;; ; ;; ">
EOF

$Res = $Defang->defang($H);

like($Res, qr{^<p style="font-size: 30px;; font-weight: lighter ;; line-height: 38px; ; color: #ffffff; font-family: 'Segoe UI Light', 'Segoe WP Light', 'Segoe UI', Helvetica, Arial;">}, "Rule with multiple semi-colons");

