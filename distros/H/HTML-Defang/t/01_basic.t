#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 93;
use HTML::Defang;
use strict;

my ($Res, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', '/\*SC\*/', '/\*EC\*/');

my $Defang = HTML::Defang->new();

$H = <<EOF;
1:<html>
2:<head>
3:<title>some title</title>
4:</head>
5:</html>
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<html>}, "Skip html tag");
like($Res, qr{2:<head>}, "Skip head tag");
like($Res, qr{3:<title>}, "Skip title tag");
like($Res, qr{3:.*</title>}, "Skip end-title tag");
like($Res, qr{4:</head>}, "Skip end-head tag");
like($Res, qr{5:</html>}, "Skip end-html tag");

$H = <<EOF;
1:<body>
2:<br>
3:<br />
4:<br/>
5:<br>
6:</br>
7:</body>
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<body>}, "Skip body tag");
like($Res, qr{2:<br>}, "Skip open br tag");
like($Res, qr{3:<br />}, "Skip br self-closing tag with space");
like($Res, qr{4:<br/>}, "Skip br self-closing tag without space");
like($Res, qr{5:<br>}, "Skip open br tag");
like($Res, qr{6:</br>}, "Skip br closing tag");
like($Res, qr{7:</body>}, "Skip body closing tag");

$H = <<EOF;
1:<h1>
2:<img>
3:</img>
4:<img />
5:<unknownTag>
6:</unknownTag>
7:<anotherUnknownTag />
8:<unknownTagWithAttrib attrib="a">
9:<unknownTagWithAttribs attrib1="a" attrib2="b">
10:<img border="3" vspace="3px" >
11:<img border="30%" vspace="3.5px" />
12:<img unknownAttrib="a">
13:<img unknownAttrib1="a" unknownAttrib2="b">
14:<img border="a\@">
15:<img border="a\@" vspace="a\@">
16:<applet>
17:<!-- single line comment with spaces -->
18:<!--single line comment without spaces-->
19:<!-- multi-line
20:
21: comment -->
22:<!--[if gte IE 4]>
23:<SCRIPT>alert('XSS');</SCRIPT>
24:<![endif]-->
25:<![if gte IE 4]>
26:<SCRIPT>alert('XSS');</SCRIPT>
27:<![endif]>
27a:<!--[if gte IE 4]--><foo>
28:<XML ID=I><X><C>
29:<![CDATA[<IMG SRC="javas]]>
30:<![CDATA[cript:alert('XSS');">
31:]]>
32:</C></X></xml>
33:<?import namespace="xss" implementation="http://ha.ckers.org/xss.htc">
34:<xss:xss>XSS</xss:xss>
35:<?import namespace="xss" implementation="http://ha.ckers.org/xss.htc"?>
36:<xss:xss>XSS</xss:xss>
37:<a href=`javascript:alert("Surprise");`>
38:<img border=`3` vspace=`3px` >
39:<H1>
40:<IMG SRC="HTTP://SOMESITE.COM" WIDTH=30>
41:<BR />
42:<UNKNOWN>
43:<UNKNOWN UNKNOWNATTRIBUTE="1">
44:<UNKNOWN UNKNOWNATTRIBUTE1="1" UNKNOWNATTRIBUTE2="2">
45:<UNKNOWN/>
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<h1>}, "Skip known attrib-incapable h1 tag");
like($Res, qr{2:<img>}, "Skip known attrib-capable img opening tag");
like($Res, qr{3:</img>}, "Skip known attrib-capable img closing tag");
like($Res, qr{4:<img />}, "Skip known attrib-capable img self-closing tag");
like($Res, qr{5:<!--${DefangString}unknownTag-->}, "Defang unknown opening tag");
like($Res, qr{6:<!--/${DefangString}unknownTag-->}, "Defang unknown closing tag");
like($Res, qr{7:<!--${DefangString}anotherUnknownTag /-->}, "Defang unknown self-closing tag");
like($Res, qr{8:<!--${DefangString}unknownTagWithAttrib defang_attrib="a"-->}, "Defang unknown tag with attrib");
like($Res, qr{9:<!--${DefangString}unknownTagWithAttribs defang_attrib1="a" defang_attrib2="b"-->}, "Defang unknown tag with attribs");
like($Res, qr{10:<img border="3" vspace="3px" >}, "Skip known tag with known attribs");
like($Res, qr{11:<img border="30%" vspace="3.5px" />}, "Skip known tag with known attribs");
like($Res, qr{12:<img defang_unknownAttrib="a">}, "Defang unknown attrib of known tag");
like($Res, qr{13:<img defang_unknownAttrib1="a" defang_unknownAttrib2="b">}, "Defang unknown attrib of known tag");
like($Res, qr{14:<img defang_border="a@">}, "Defang invalid value in known attrib in known tag");
like($Res, qr{15:<img defang_border="a@" defang_vspace="a@">}, "Defang multiple invalid values in known attrib in known tag");
like($Res, qr{16:<!--${DefangString}applet-->}, "Defang known vulnerable tag");

like($Res, qr{17:<!--${CommentStartText} single line comment with spaces ${CommentEndText}-->}, "Single line comment with spaces");
like($Res, qr{18:<!--${CommentStartText}single line comment without spaces${CommentEndText}-->}, "Single line comment without spaces");
like($Res, qr{19:<!--${CommentStartText} multi-line}, "Multi-line comment start");
like($Res, qr{20:}, "Multi-line comment content");
like($Res, qr{21: comment ${CommentEndText}-->}, "Multi-line comment end");

# IE conditional comments
# Refer http://msdn.microsoft.com/en-us/library/ms537512.aspx for IE conditional comment information
like($Res, qr{22:<!--${CommentStartText}\[if gte IE 4\]>}, "IE conditional downlevel-hidden comment start");
like($Res, qr{23:<SCRIPT>alert\('XSS'\);</SCRIPT>}, "IE conditional downlevel-hidden comment body");
like($Res, qr{24:<!\[endif\]${CommentEndText}-->}, "IE conditional downlevel-hidden comment end");
like($Res, qr{25:<!--${CommentStartText}\[if gte IE 4\]${CommentEndText}-->}, "IE conditional downlevel-revealed comment start");
like($Res, qr{26:<!--defang_SCRIPT--><!-- alert\('XSS'\); --><!--/defang_SCRIPT-->}, "IE conditional downlevel-revealed comment body");
like($Res, qr{27:<!--${CommentStartText}\[endif\]${CommentEndText}-->}, "IE conditional downlevel-revealed comment end");
like($Res, qr{27a:<!--${CommentStartText}\[if gte IE 4\]${CommentEndText}--><!--${DefangString}foo-->}, "IE conditional defang content");

# Some XML tests
# Refer http://www.w3schools.com/XML/xml_cdata.asp for information on CDATA
like($Res, qr{28:<!--${DefangString}XML ID=I--><!--${DefangString}X--><!--${DefangString}C-->}, "Defang unknown xml and other opening tags");
like($Res, qr{29:<!--${CommentStartText}\[CDATA\[<IMG SRC="javas]]${CommentEndText}-->}, "Comment out single-line cdata section");
like($Res, qr{30:<!--${CommentStartText}\[CDATA\[cript:alert\('XSS'\);">}, "Comment out multi-line cdata section start");
like($Res, qr{31:]]${CommentEndText}-->}, "Comment out multi-line cdata section end");
like($Res, qr{32:<!--/${DefangString}C--><!--/${DefangString}X--><!--/${DefangString}xml-->}, "Defang unknown xml and other closing tags");
# Make sure xss:xss tag comes after each import in the original html for the below checks
# HTML::Defang.pm tended to dump all HTML output without defanging if a '<?' tag was closed by just '>'
like($Res, qr{33:<!--\?import namespace="xss" implementation="http://ha.ckers.org/xss.htc"-->}, "Defang <?import tag");
like($Res, qr{34:<!--${DefangString}xss:xss-->XSS<!--/${DefangString}xss:xss-->}, "Defang xss:xss");
like($Res, qr{35:<!--\?import namespace="xss" implementation="http://ha.ckers.org/xss.htc"\?-->}, "Defang <?import tag with ending ?");
like($Res, qr{36:<!--${DefangString}xss:xss-->XSS<!--/${DefangString}xss:xss-->}, "Defang xss:xss");

# Attributes surrounded by backticks
like($Res, qr{37:<a defang_href="javascript:alert\(&quot;Surprise&quot;\);">}, "Defang invalid attribute surrounded by backticks");
like($Res, qr{38:<img border="3" vspace="3px" >}, "Skip valid attribute surrounded by backticks");

# Case tests
like($Res, qr{39:<H1>}, "Skip known tag in upper case with no attributes");
like($Res, qr{40:<IMG SRC="HTTP://SOMESITE.COM" WIDTH=30>}, "Skip known tag in upper case with attributes");
like($Res, qr{41:<BR />}, "Skip known self-closing tag in upper case");
like($Res, qr{42:<!--${DefangString}UNKNOWN-->}, "Defang unknown tag in upper case");
like($Res, qr{43:<!--${DefangString}UNKNOWN defang_UNKNOWNATTRIBUTE="1"-->}, "Defang unknown tag in upper case with attribute");
like($Res, qr{44:<!--${DefangString}UNKNOWN defang_UNKNOWNATTRIBUTE1="1" defang_UNKNOWNATTRIBUTE2="2"-->}, "Defang unknown tag in upper case with multiple attributes");
like($Res, qr{45:<!--${DefangString}UNKNOWN/-->}, "Defang unknown self-closing tag in upper case");

$H = <<EOF;
1:<table border="0" cellpadding="2" cellspacing="0">
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<table border="0" cellpadding="2" cellspacing="0">}, "Skip known attributes of <table> tag");

$H = <<EOF;
1:<img style="width: some's">
2:<img style='width: some"s'>
3:<img style='width: some`s'>
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<img style="width: some's">}, "Attribute containing single quote");
like($Res, qr{2:<img style='width: some"s'>}, "Attribute containing double quote");
like($Res, qr{3:<img style='width: some`s'>}, "Attribute containing backtick");

$H = <<EOF;
<img width="1" /  = "/">
EOF
$Res = $Defang->defang($H);

like($Res, qr{<img width="1" defang_/  = "/">}, "Use '/' as an attribute key");

$H = <<'EOF';
1:<img width="1" / style="color: red">
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<img width="1" / style="color: red">$}, "Stray / in tag");

$H = <<EOF;
1:<html><!--
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<html><!--${CommentStartText}\s${CommentEndText}-->}, "Unclosed HTML comment 1");

$H = <<EOF;
1:<html><!--</html>
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<html><!--${CommentStartText}</html>\s${CommentEndText}-->}, "Unclosed HTML comment 2");

$H = <<EOF;
1:<html><!--</htm---l>
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<html><!--${CommentStartText}</htm-l>\s${CommentEndText}-->}, "Unclosed HTML comment with internal HTML comment markers");

$H = <<EOF;
1:<?xml tag left unclosed
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<!--\?xml tag left unclosed\s-->}, "Unclosed XML comment");

$H = <<EOF;
1:<?xml tag left --unclosed
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<!--\?xml tag left unclosed\s-->}, "Unclosed XML comment with internal HTML comment markers");

$H = <<'EOF';
<script>alert("XSS")</script>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<!--defang_script--><!-- alert\("XSS"\) --><!--/defang_script-->$}, "<script> tag defanging and commenting");

$H = <<'EOF';
<script src="somesite.com/some.js"></script>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<!--defang_script src="somesite.com/some.js"--><!--  --><!--/defang_script-->$}, "<script> tag with src attribute");

$H = <<'EOF';
<script src="somesite.com/some.js">
EOF
$Res = $Defang->defang($H);

like($Res, qr{^<!--defang_script src="somesite.com/some.js"-->$}, "Half-opened <script> tag with src attribute");

$H = <<'EOF';
<script>
/*multi line script start*/
alert("XSS");
/*multi line script end*/
</script>
EOF
$Res = $Defang->defang($H);

like($Res, qr{<!--defang_script--><!-- 
/\*multi line script start\*/
alert\("XSS"\);
/\*multi line script end\*/
 --><!--/defang_script-->}, "Multi-line <script> tag with opening HTML comments alone");

$H = <<'EOF';
<script>
<!--
alert("XSS");
</script>
EOF
$Res = $Defang->defang($H);

like($Res, qr{<!--defang_script--><!-- 

alert\("XSS"\);
 --><!--/defang_script-->}, "Multi-line <script> tag with closing HTML comments alone");

$Defang = HTML::Defang->new(
    fix_mismatched_tags => 1,
);

$H = <<EOF;
<table>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table>
</table>$}, "Add missing closing tag");

$H = <<EOF;
<table>
<tr>
<td>
<td>
<td>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table>
<tr>
<td>
<td>
<td>
</td></td></td></tr></table>$}, "Add multiple missing closing tags");

$H = <<EOF;
<table>
<tr>
<td>
<pre>
</tr>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table>
<tr>
<td>
<pre>
</pre></td></tr>
</table>$}, "Add multiple missing closing tags when one closing tag is present");

$H = <<EOF;
<table>
<tr>
<td><i>non-blank
<pre>
</tr>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table>
<tr>
<td><i>non-blank
</i><pre><i>
</i></pre></td></tr>
</table>$}, "Add multiple missing closing tags when one closing tag and one non-callback tag is present");

$H = <<EOF;
<h1>
<pre>
<div>
<h1>
</div>
<blockquote>
</blockquote>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<h1>
<pre>
<div>
<h1>
</h1></div>
<blockquote>
</blockquote>
</pre></h1>$}, "Don't break all the way to top in nested tag case");


$H = <<EOF;
<pre>
<table>
</table>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<pre>
<table>
</table>
</pre>$}, "Add missing closing tag to end of HTML");

$H = <<EOF;
<PRE>
<div></a></A>
</DIV>
</pre>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<PRE>
<div>
</DIV>
</pre>$}, "Check uppercase/lowercase tags");

$H = <<EOF;
<table><tr><td>before-font</font>after-font
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table><tr><td>before-fontafter-font
</td></tr></table>$}, "Don't close out all tags on mismatched close");

$H = <<EOF;
<table><div>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table><tr><td><div>
</div></td></tr></table>$}, "Check implicit opening tags");

$H = <<EOF;
<table></div>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table><tr><td>
</td></tr></table>$}, "Check implicit opening tags 2");

$H = <<EOF;
<table><tr><td><table></table><div>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table><tr><td><table></table><div>
</div></td></tr></table>$}, "Check implicit opening tags with nested closed");

$H = <<EOF;
<table><tr><td></td></tr><td>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<table><tr><td></td></tr><tr><td>
</td></tr></table>$}, "Check implicit opening tags partial");

$H = <<EOF;
<div>abc<span>def<p>abc</p>def</span>abc</div>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<div>abc<span>def</span><p><span>abc</span></p><span>def</span>abc</div>$}, "Check close/open inline within block tags");

#	$H = <<EOF;
#	<div><i><b><p><span>abc</span></p></i></b></div>
#	EOF
#	$Res = $Defang->defang($H);
#	$Res =~ s/<!--.*?-->//g;
#	
#	# Note: This result isn't actually quite right (should be reopened with <p><i><b><span>), but it'll do
#	like($Res, qr{^<div><i><b></b></i><p><span><i><b>abc</b></i></span></p></div>$}, "Check close/open multiple inline within block tags");


$Defang = HTML::Defang->new(
    fix_mismatched_tags => 1,
    mismatched_tags_to_fix => [qw(html body)],
);
$H = <<EOF;
<html>
<body>
<table>
<tr>
<td><font>
<pre>
</tr>
EOF
$Res = $Defang->defang($H);
$Res =~ s/<!--.*?-->//g;

like($Res, qr{^<html>
<body>
<table>
<tr>
<td><font>
<pre>
</tr>
</body></html>$}, "Add multiple missing closing tags by overriding default tag lists to close");

#################### Below tests are taken from realworld emails #########################

$H = <<EOF;
<!--[if gte mso 10]> <mce:style><!    /* Style Definitions */  table.MsoNormalTable	{mso-fareast-font-family:"Times New Roman";}  --> <!--[endif]--></p>
<p>&nbsp;<span style="font-size: medium;">I need your help now!</span></p>
EOF
$Res = $Defang->defang($H);

like($Res, qr{<!--$CommentStartText\[if gte mso 10\]> <mce:style><!    /\* Style Definitions \*/  table.MsoNormalTable	{mso-fareast-font-family:"Times New Roman";}  $CommentEndText--> <!--$CommentStartText\[endif\]$CommentEndText--></p>
<p>&nbsp;<span style="font-size: medium;">I need your help now!</span></p>}, "IE conditional comment without appropriate closing tag");

$H = <<'EOF';
1:<br>
2:<br  >
3:<br/>
4:<br />
5:<br/ >
6:<br / >
7:<br\>
8:<br \>
9:<br\ >
9:<br \ >
10:<br\\>
11:<br \\>
12:<br\\ >
13:<br \\ >
14:<br\\\\>
15:<br \\\\>
16:<br\\\\ >
17:<br \\\\ >
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<br>
2:<br  >
3:<br/>
4:<br />
5:<br/ >
6:<br / >
7:<br\\>
8:<br \\>
9:<br\\ >
9:<br \\ >
10:<br\\\\>
11:<br \\\\>
12:<br\\\\ >
13:<br \\\\ >
14:<br\\\\\\\\>
15:<br \\\\\\\\>
16:<br\\\\\\\\ >
17:<br \\\\\\\\ >$}, "Self closing tag in all its incarnations. Eg: <br>, <br/>, <br / >, <br \\>");

$H = <<EOF;
1:<unknownTag title="something with -- in it">
2:<b><noscript><!-- </noscript><img src=xx: onerror=alert(document.domain) --></noscript>
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<!--${DefangString}unknownTag title="something with  in it"-->}, "Defang unknown tag with --'s in it");
like($Res, qr{^2:<b><!--${DefangString}noscript--><!--$CommentStartText </noscript><img src=xx: onerror=alert\(document\.domain\) $CommentEndText--><!--/${DefangString}noscript-->}m, "Defang noscript tag");

