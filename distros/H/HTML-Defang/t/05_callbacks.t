#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 94;
use HTML::Defang;
use strict;

my ($Res, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', ' ', ' ');

#################################
#  Basic tag callback tests
#################################

my $Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img font unknown1 unknown2 button hr area) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    my $DefangFlag = 2;
    $DefangFlag = 0 if $Tag eq "img" || $Tag eq "unknown1" || $Tag eq "button";
    $DefangFlag = 1 if $Tag eq "font" || $Tag eq "unknown2" || $Tag eq "hr";
    return $DefangFlag;
  }
);
$H = <<EOF;
1:<img>
2:<font>
3:<unknown1>
4:<unknown2>

5:<img></img>
6:<font></font>
7:<unknown1></unknown1>
8:<unknown2></unknown2>

9:<button tabindex="1">
10:<hr width="75%">
11:<unknown1 key="value">
12:<unknown2 key="value">

13:<button tabindex="1"></button>
14:<hr width="75%"></hr>
15:<unknown1 key="value"></unknown1>
16:<unknown2 key="value"></unknown2>

17:<button tabindex="1" type="button">
18:<hr width="75%" size="1">
19:<unknown1 key1="value" key2="value">
20:<unknown2 key1="value" key2="value">

21:<button tabindex="1" key="anything">
22:<hr key1="value" key="value">

23:<button key1="1" key2="anything">
24:<hr key1="value" key2="value">

25:<p></p>
26:<unknown3></unknown3>

27:<FONT>
28:<UNKNOWN1 UNKNOWNATTRIB=SOMEVALUE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^1:<img>}, "Force skip known tag without attributes and closing tags");
like($Res, qr{2:<!--${DefangString}font-->}, "Force defang known tag without attributes and closing tags");
like($Res, qr{3:<unknown1>}, "Force skip unknown tag without attributes and closing tags");
like($Res, qr{4:<!--${DefangString}unknown2-->}, "Force defang unknown tag without attritues and closing tags");

like($Res, qr{5:<img></img>}, "Force skip known tag with closing tags but without attributes");
like($Res, qr{6:<!--${DefangString}font--><!--/${DefangString}font-->}, "Force defang known tag with closing tags but without attributes");
like($Res, qr{7:<unknown1></unknown1>}, "Force skip unknown tag with closing tags but without attributes");
like($Res, qr{8:<!--${DefangString}unknown2--><!--/${DefangString}unknown2-->}, "Force defang unknown tag with closing tags but without attritues");

like($Res, qr{9:<button tabindex="1">}, "Force skip known tag with attributes but without closing tags");
like($Res, qr{10:<!--${DefangString}hr width="75%"-->}, "Force defang known tag with attributes but without closing tags");
like($Res, qr{11:<unknown1 defang_key="value">}, "Force skip unknown tag with attributes but without closing tags");
like($Res, qr{12:<!--${DefangString}unknown2 defang_key="value"-->}, "Force defang unknown tag with attritues but without closing tags");

like($Res, qr{13:<button tabindex="1"></button>}, "Force skip known tag with closing tags and attributes");
like($Res, qr{14:<!--${DefangString}hr width="75%"--><!--/${DefangString}hr-->}, "Force defang known tag with closing tags and attributes");
like($Res, qr{15:<unknown1 defang_key="value"></unknown1>}, "Force skip unknown tag with closing tags and attributes");
like($Res, qr{16:<!--${DefangString}unknown2 defang_key="value"--><!--/${DefangString}unknown2-->}, "Force defang unknown tag with closing tags and attritues");

like($Res, qr{17:<button tabindex="1" type="button">}, "Force skip known tag with multiple known attributes");
like($Res, qr{18:<!--${DefangString}hr width="75%" size="1"-->}, "Force defang known tag with multiple known attributes");
like($Res, qr{19:<unknown1 defang_key1="value" defang_key2="value">}, "Force skip unknown tag with multiple unknown attribtues");
like($Res, qr{20:<!--${DefangString}unknown2 defang_key1="value" defang_key2="value"-->}, "Force defang unknown tag with multiple unknown attributes");

like($Res, qr{21:<button tabindex="1" defang_key="anything">}, "Force skip known tag with known and unknown attributes");
like($Res, qr{22:<!--${DefangString}hr defang_key1="value" defang_key="value"-->}, "Force defang known tag with known and unknown attributes");

like($Res, qr{23:<button defang_key1="1" defang_key2="anything">}, "Force skip known tag with multiple unknown attributes");
like($Res, qr{24:<!--${DefangString}hr defang_key1="value" defang_key2="value"-->}, "Force defang known tag with multiple unknown attributes");

like($Res, qr{25:<p></p>}, "Skip known tags not specified as callback tags");
like($Res, qr{26:<!--${DefangString}unknown3--><!--/${DefangString}unknown3-->}, "Defang unknown tags not specified as callback tags");

like($Res, qr{27:<!--${DefangString}FONT-->}, "Force defang known callback tag in uppercase");
like($Res, qr{28:<UNKNOWN1 defang_UNKNOWNATTRIB=SOMEVALUE>}, "Force skip unknown callback tag in upper case");


$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img blockquote bgsound button basefont area span) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    return 0 if $IsEndTag;
    ${$AttributeHash->{border}} = "2" if $Tag eq 'img';
    ${$AttributeHash->{unknown}} = "unknown1a" if $Tag eq 'blockquote';
    ${$AttributeHash->{balance}} = "2" if $Tag eq 'bgsound';
    ${$AttributeHash->{delay}} = "2" if $Tag eq 'bgsound';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'button';
    ${$AttributeHash->{unknown2}} = "unknown2a" if $Tag eq 'button';
    ${$AttributeHash->{size}} = "2" if $Tag eq 'basefont';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'basefont';
    ${$AttributeHash->{ptsize}} = "3" if $Tag eq 'basefont';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'area';
    ${$AttributeHash->{coords}} = "5,6,7,8" if $Tag eq 'area';
    ${$AttributeHash->{unknown2}} = "unknown2a" if $Tag eq 'area';
    ${$AttributeHash->{nowrap}} = undef if $Tag eq 'span';
    return 2;
  }
);
$H = <<EOF;
1:<img border="1">
2:<blockquote unknown="unknown1">
3:<bgsound balance="1" delay="1">
4:<button unknown1="unknown1" unknown2="unknown2">
5:<basefont size="1" unknown1="unknown1" ptsize="2">
6:<area unknown1="unknown1" coords="1,2,3,4" unknown2="unknown2">
7:<span>text</span>
EOF
$Res = $Defang->defang($H);
like($Res, qr{1:<img border="2">}, "Tag callback - change attribute value of known attribute in callback for known tag");
like($Res, qr{2:<blockquote defang_unknown="unknown1a">}, "Tag callback - change attribute value of unknown attribute in callback for known tag");
like($Res, qr{3:<bgsound balance="2" delay="2">}, "Tag callback - change attribute value of mutliple known attributes in callback for known tag");
like($Res, qr{4:<button defang_unknown1="unknown1a" defang_unknown2="unknown2a">}, "Tag callback - change attribute value of multiple unknown attributes in callback for known tag");
like($Res, qr{5:<basefont size="2" defang_unknown1="unknown1a" ptsize="3">}, "Tag callback - change attribute value of known and unknown attributes in callback for known tag");
like($Res, qr{6:<area defang_unknown1="unknown1a" coords="5,6,7,8" defang_unknown2="unknown2a">}, "Tag callback - change attribute value of known and unknown attributes in reverse order in callback for known tag");
like($Res, qr{7:<span nowrap>text</span>}, "Tag callback - change attribute value with undef");

$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img blockquote bgsound button basefont area) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    ${$AttributeHash->{border}} = "2" if $Tag eq 'img';
    ${$AttributeHash->{unknown}} = "unknown1a" if $Tag eq 'blockquote';
    ${$AttributeHash->{balance}} = "2" if $Tag eq 'bgsound';
    ${$AttributeHash->{delay}} = "2" if $Tag eq 'bgsound';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'button';
    ${$AttributeHash->{unknown2}} = "unknown2a" if $Tag eq 'button';
    ${$AttributeHash->{size}} = "2" if $Tag eq 'basefont';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'basefont';
    ${$AttributeHash->{ptsize}} = "3" if $Tag eq 'basefont';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'area';
    ${$AttributeHash->{coords}} = "5,6,7,8" if $Tag eq 'area';
    ${$AttributeHash->{unknown2}} = "unknown2a" if $Tag eq 'area';
    return 0;
  }
);
$H = <<EOF;
1:<img border="1">
2:<blockquote unknown="unknown1">
3:<bgsound balance="1" delay="1">
4:<button unknown1="unknown1" unknown2="unknown2">
5:<basefont size="1" unknown1="unknown1" ptsize="2">
6:<area unknown1="unknown1" coords="1,2,3,4" unknown2="unknown2">
EOF
$Res = $Defang->defang($H);
like($Res, qr{1:<img border="2">}, "Tag callback - change attribute value of known attribute in callback for known tag and force skip tag");
like($Res, qr{2:<blockquote defang_unknown="unknown1a">}, "Tag callback - change attribute value of unknown attribute in callback for known tag and force skip tag");
like($Res, qr{3:<bgsound balance="2" delay="2">}, "Tag callback - change attribute value of mutliple known attributes in callback for known tag and force skip tag");
like($Res, qr{4:<button defang_unknown1="unknown1a" defang_unknown2="unknown2a">}, "Tag callback - change attribute value of multiple unknown attributes in callback for known tag and force skip tag");
like($Res, qr{5:<basefont size="2" defang_unknown1="unknown1a" ptsize="3">}, "Tag callback - change attribute value of known and unknown attributes in callback for known tag and force skip tag");
like($Res, qr{6:<area defang_unknown1="unknown1a" coords="5,6,7,8" defang_unknown2="unknown2a">}, "Tag callback - change attribute value of know and unknown attributes in reverse order in callback for known tag and force skip tag");


$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img blockquote bgsound button basefont area) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    ${$AttributeHash->{border}} = "2" if $Tag eq 'img';
    ${$AttributeHash->{unknown}} = "unknown1a" if $Tag eq 'blockquote';
    ${$AttributeHash->{balance}} = "2" if $Tag eq 'bgsound';
    ${$AttributeHash->{delay}} = "2" if $Tag eq 'bgsound';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'button';
    ${$AttributeHash->{unknown2}} = "unknown2a" if $Tag eq 'button';
    ${$AttributeHash->{size}} = "2" if $Tag eq 'basefont';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'basefont';
    ${$AttributeHash->{ptsize}} = "3" if $Tag eq 'basefont';
    ${$AttributeHash->{unknown1}} = "unknown1a" if $Tag eq 'area';
    ${$AttributeHash->{coords}} = "5,6,7,8" if $Tag eq 'area';
    ${$AttributeHash->{unknown2}} = "unknown2a" if $Tag eq 'area';
    return 1;
  }
);
$H = <<EOF;
1:<img border="1">
2:<blockquote unknown="unknown1">
3:<bgsound balance="1" delay="1">
4:<button unknown1="unknown1" unknown2="unknown2">
5:<basefont size="1" unknown1="unknown1" ptsize="2">
6:<area unknown1="unknown1" coords="1,2,3,4" unknown2="unknown2">
EOF
$Res = $Defang->defang($H);
like($Res, qr{1:<!--${DefangString}img border="2"-->}, "Tag callback - change attribute value of known attribute in callback for known tag and force defang tag");
like($Res, qr{2:<!--${DefangString}blockquote defang_unknown="unknown1a"-->}, "Tag callback - change attribute value of unknown attribute in callback for known tag and force defang tag");
like($Res, qr{3:<!--${DefangString}bgsound balance="2" delay="2"-->}, "Tag callback - change attribute value of mutliple known attributes in callback for known tag and force defang tag");
like($Res, qr{4:<!--${DefangString}button defang_unknown1="unknown1a" defang_unknown2="unknown2a"-->}, "Tag callback - change attribute value of multiple unknown attributes in callback for known tag and force defang tag");
like($Res, qr{5:<!--${DefangString}basefont size="2" defang_unknown1="unknown1a" ptsize="3"-->}, "Tag callback - change attribute value of known and unknown attributes in callback for known tag and force defang tag");
like($Res, qr{6:<!--${DefangString}area defang_unknown1="unknown1a" coords="5,6,7,8" defang_unknown2="unknown2a"-->}, "Tag callback - change attribute value of know and unknown attributes in reverse order in callback for known tag and force defang tag");


$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img blockquote bgsound button basefont area font) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    delete $$AttributeHash{border} if $Tag eq 'img';
    delete $$AttributeHash{unknown} if $Tag eq 'font';
    delete $$AttributeHash{ptsize} if $Tag eq 'font';
    return 2;
  }
);
$H = <<EOF;
1:<img border="1">
2:<img border="1" hspace="1">
3:<img border="1" unknown="unknown1">
4:<img border="1" hspace="1" unknown="unknown1">
5:<font unknown="unknown1">
6:<font unknown="unknown1" size="1">
7:<font unknown="unknown1" unknown2="unknown2">
8:<font unknown="unknown1" size="1" unknown2="unknown2">
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<img >}, "Tag callback - remove known attribute for known tag");
like($Res, qr{2:<img hspace="1">}, "Tag callback - remove known attribute for known tag but preserve another known attribute");
like($Res, qr{3:<img defang_unknown="unknown1">}, "Tag callback - remove known attribute for known tag but preserve unknown attribute");
like($Res, qr{4:<img hspace="1" defang_unknown="unknown1">}, "Tag callback - remove known attribute for known tag but preserve unknown and another known attribute");

like($Res, qr{5:<font >}, "Tag callback - remove unknown attribute for known tag");
like($Res, qr{6:<font size="1">}, "Tag callback - remove unknown attribute for known tag but preserve another known attribute");
like($Res, qr{7:<font defang_unknown2="unknown2">}, "Tag callback - remove unknown attribute for known tag but preserve unknown attribute");
like($Res, qr{8:<font size="1" defang_unknown2="unknown2">$}, "Tag callback - remove unknown attribute for known tag but preserve unknown and another known attribute");

$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img font) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    delete $$AttributeHash{border} if $Tag eq 'img';
    delete $$AttributeHash{hspace} if $Tag eq 'img';
    delete $$AttributeHash{unknown} if $Tag eq 'font';
    delete $$AttributeHash{unknown2} if $Tag eq 'font';
    return 2;
  }
);
$H = <<EOF;
1:<img border="1" hspace="1">
2:<img border="1" hspace="1" vspace="1">
3:<img border="1" hspace="1" unknown="unknown1">
4:<font unknown="unknown1" unknown2="unknown2">
5:<font unknown="unknown1" size="1" unknown2="unknown2">
6:<font unknown="unknown1" unknown3="unknown3" unknown2="unknown2">
EOF
$Res = $Defang->defang($H);

like($Res, qr{1:<img >}, "Tag callback - remove multiple known attributes for known tag");
like($Res, qr{2:<img vspace="1">}, "Tag callback - remove multiple known attributes for known tag but preserve another known attribute");
like($Res, qr{3:<img defang_unknown="unknown1">}, "Tag callback - remove multiple known attributes for known tag but preserve another unknown attribute");
like($Res, qr{4:<font >}, "Tag callback - remove multiple unknown attributes for known tag");
like($Res, qr{5:<font size="1" >}, "Tag callback - remove multiple unknown attributes for known tag but preserve known attribute");
like($Res, qr{6:<font defang_unknown3="unknown3" >}, "Tag callback - remove multiple unknown attributes for known tag but preserve another unknown attribute");


$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img font) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    ${$AttributeHash->{border}} = "1" if $Tag eq 'img';
    ${$AttributeHash->{unknown}} = "unknown1" if $Tag eq 'font';
    return 2;
  }
);
$H = <<EOF;
1:<img>
2:<img hspace="1">
3:<img unknown="unknown1">
4:<img hspace="1" unknown="unknown1">
5:<font>
6:<font size="1">
7:<font unknown2="unknown2">
8:<font size="1" unknown2="unknown2">
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<img border="1">}, "Tag callback - add known attribute for known tag");
like($Res, qr{2:<img hspace="1" border="1">}, "Tag callback - add known attribute for known tag but preserve another known attribute");
like($Res, qr{3:<img defang_unknown="unknown1" border="1">}, "Tag callback - add known attribute for known tag but preserve unknown attribute");
like($Res, qr{4:<img hspace="1" defang_unknown="unknown1" border="1">}, "Tag callback - add known attribute for known tag but preserve unknown and another known attribute");

like($Res, qr{5:<font unknown="unknown1">}, "Tag callback - add unknown attribute for known tag");
like($Res, qr{6:<font size="1" unknown="unknown1">}, "Tag callback - add unknown attribute for known tag but preserve another known attribute");
like($Res, qr{7:<font defang_unknown2="unknown2" unknown="unknown1">}, "Tag callback - add unknown attribute for known tag but preserve unknown attribute");
like($Res, qr{8:<font size="1" defang_unknown2="unknown2" unknown="unknown1">$}, "Tag callback - add unknown attribute for known tag but preserve unknown and another known attribute");

$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img font) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    ${$AttributeHash->{border}} = "1" if $Tag eq 'img';
    ${$AttributeHash->{hspace}} = "1" if $Tag eq 'img';
    ${$AttributeHash->{unknown}} = "unknown1" if $Tag eq 'font';
    ${$AttributeHash->{unknown2}} = "unknown2" if $Tag eq 'font';
    return 2;
  }
);
$H = <<EOF;
1:<img>
2:<img vspace="1">
3:<img unknown="unknown1">
4:<font>
5:<font size="1">
6:<font unknown3="unknown3">
EOF
$Res = $Defang->defang($H);

like($Res, qr{^1:<img (border="1" hspace="1"|hspace="1" border="1")>}, "Tag callback - add multiple known attributes for known tag");
like($Res, qr{2:<img vspace="1" (border="1" hspace="1"|hspace="1" border="1")>}, "Tag callback - add multiple known attributes for known tag but preserve another known attribute");
like($Res, qr{3:<img defang_unknown="unknown1" (border="1" hspace="1"|hspace="1" border="1")>}, "Tag callback - add multiple known attributes for known tag but preserve another unknown attribute");
like($Res, qr{4:<font (unknown="unknown1" unknown2="unknown2"|unknown2="unknown2" unknown="unknown1")>}, "Tag callback - add multiple unknown attributes for known tag");
like($Res, qr{5:<font size="1" (unknown="unknown1" unknown2="unknown2"|unknown2="unknown2" unknown="unknown1")>}, "Tag callback - add multiple unknown attributes for known tag but preserve known attribute");
like($Res, qr{6:<font defang_unknown3="unknown3" (unknown="unknown1" unknown2="unknown2"|unknown2="unknown2" unknown="unknown1")>$}, "Tag callback - add multiple unknown attributes for known tag but preserve another unknown attribute");


#3:<bgsound balance="1" delay="1">
#4:<button unknown1="unknown1" unknown2="unknown2">
#5:<basefont size="1" unknown1="unknown1" ptsize="2">
#6:<area unknown1="unknown1" coords="1,2,3,4" unknown2="unknown2">


$H = <<EOF;
5:<img></img>
6:<font></font>
7:<unknown1></unknown1>
8:<unknown2></unknown2>

9:<button tabindex="1">
10:<hr width="75%">
11:<unknown1 key="value">
12:<unknown2 key="value">

13:<button tabindex="1"></button>
14:<hr width="75%"></hr>
15:<unknown1 key="value"></unknown1>
16:<unknown2 key="value"></unknown2>

17:<button tabindex="1" type="button">
18:<hr width="75%" size="1">
19:<unknown1 key1="value" key2="value">
20:<unknown2 key1="value" key2="value">

21:<button tabindex="1" key="anything">
22:<hr key1="value" key="value">

23:<button key1="1" key2="anything">
24:<hr key1="value" key2="value">

25:<p></p>
26:<unknown3></unknown3>

27:<area shape="circle" cd="dc" coords="3,3,3,3" aa="bb" cc="dd">
EOF
$Res = $Defang->defang($H);

#like($Res, qr{}, "Tag callback - change attribute value of known attribute in callback for unknown tag");
#like($Res, qr{}, "Tag callback - Change attribute value of unknown attribute in callback for unknown tag");
#like($Res, qr{}, "Tag callback - Change attribute value of mutliple known attributes in callback for unknown tag");
#like($Res, qr{}, "Tag callback - Change attribute value of multiple unknown attributes in callback for unknown tag");
#like($Res, qr{}, "Tag callback - Remove known attribute for unknown tag");
#like($Res, qr{}, "Tag callback - Remove unknown attribute for unknown tag");
#like($Res, qr{}, "Tag callback - Add known attribute for unknown tag");
#like($Res, qr{}, "Tag callback - Add unknown attribute for unknown tag");
#like($Res, qr{}, "Tag callback - Remove multiple known attributes for unknown tag");
#like($Res, qr{}, "Tag callback - Remove multiple unknown attributes for unknown tag");
#like($Res, qr{}, "Tag callback - Add multiple known attributes for unknown tag");
#like($Res, qr{}, "Tag callback - Add multiple unknown attributes for unknown tag");

#################################
#  URL callback tests
#################################

$Defang = HTML::Defang->new(
  url_callback => sub {
    my ($Context, $Defang, $Tag, $Attribute, $Value, $AttributeHash, $HtmlR) = @_;
    return 0 if $$Value eq 'http://forceskip.com';
    return 1 if $$Value eq 'http://forcedefang.com';
    if ($$Value eq 'http://forceskipandchange.com') {
      $$Value = 'http://someredirector.com/redirect?' . $$Value;
      return 0;
    }
    if ($$Value eq 'http://forcedefangandchange.com') {
      $$Value = 'http://someredirector.com/redirect?' . $$Value;
      return 1;
    }
    if ($$Value eq 'http://saa.com') {
      return 0;
    }
    if ($$Value eq 'http://sab.com') {
      return 1;
    }
    if ($$Value eq 'http://sac.com') {
      $$Value = 'http://someredirector.com/redirect?' . $$Value;
      return 0;
    }
    if ($$Value eq 'http://sea.com') {
      $$Value = 'http://someredirector.com/redirect?' . $$Value;
      return 1;
    }
    $$Value = 'http://someredirector.com/redirect?' . $$Value;
    return 0;
  },
);
$H = <<EOF;
1:<a href="http://forceskip.com" title="a" id="a1">
2:<img src="http://forcedefang.com" title="a" id="a1">
3:<a href="http://forceskipandchange.com" title="a" id="a1">
4:<img src="http://forcedefangandchange.com" title="a" id="a1">
5:<img src="http://www.example1.com" style="b:url(http://www.example2.com)">
6:<img SRC="http://www.example1.com" style="b:URL(http://www.example2.com)">
<style>
a {b:url('http://saa.com');c:url("http://sab.com");d:url(http://sac.com)}
e {f:url('http://sea.com');g:url("http://seb.com");h:url(http://sec.com)}
i {j:URL('http://saa.com');k:URL("http://sab.com");l:URL(http://sac.com)}
</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{1:<a href="http://forceskip.com" title="a" id="a1">}s, "URL callback - force skip in regular tag");
like($Res, qr{2:<img defang_src="http://forcedefang.com" title="a" id="a1">}s, "URL callback - force defang in regular tag");
like($Res, qr{3:<a href="http://someredirector.com/redirect\?http://forceskipandchange.com" title="a" id="a1">}s, "URL callback - force skip and modify attribute value in regular tag");
like($Res, qr{4:<img defang_src="http://someredirector.com/redirect\?http://forcedefangandchange.com" title="a" id="a1">}s, "URL callback - force defang and modify attribute value in regular tag");
like($Res, qr{5:<img src="http://someredirector.com/redirect\?http://www.example1.com" style="b:url\(http://someredirector.com/redirect\?http://www.example2.com\)">}, "URL callback - change style attribute and force skip in tag with style attribute");
like($Res, qr{6:<img SRC="http://someredirector.com/redirect\?http://www.example1.com" style="b:URL\(http://someredirector.com/redirect\?http://www.example2.com\)">}, "URL callback - change style attribute and force skip in tag with style attribute - upper case test");
like($Res, qr{\{b:url\('http://saa.com'\);}, "URL callback - force skip in style tag");
like($Res, qr{/\*c:url\("http://sab.com"\);\*/}, "URL callback - force defang in style tag");
like($Res, qr{d:url\(http://someredirector.com/redirect\?http://sac.com\)\}}, "URL callback - force skip and change value in style tag");
like($Res, qr{\{/\*f:url\('http://someredirector.com/redirect\?http://sea.com'\);\*/}, "URL callback - force defang and change value in style tag");
like($Res, qr{i \{j:URL\('http://saa.com'\);/\*k:URL\("http://sab.com"\);\*/l:URL\(http://someredirector.com/redirect\?http://sac.com\)\}}, "URL callback - upper case tests for style tag");


#################################
#  CSS callback tests
#################################

$Defang = HTML::Defang->new(
  css_callback => sub {
    my $StyleRules = $_[3];
    foreach my $StyleRule (@$StyleRules) {
      foreach my $KeyValueRules (@$StyleRule) {
        foreach my $KeyValueRule (@$KeyValueRules) {
          $$KeyValueRule[2] = 2;
        }
      }
    }
    return 1;
  },
);
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
<style>   

selector1{ab:cd}
selector2{ab:cccd;}
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
like($Res, qr{^1:<a style="a:b">
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
31:<a href="abccomscript" title="a" id="a1" style="{color: #900}&#x0a;          :link {background: #ff0}&#x0a;          :visited {background: #fff}&#x0a;          :hover {outline: thin red solid}&#x0a;          :active {background: #00f}">
<style><!--${CommentStartText}   

selector1{ab:cd}
selector2{ab:cccd;}
selector3{ab:cd;ef:gh}
selector4{ab:cd;ef:gh;}
selector5{ab:cd;x:y;p:q;/\*r:url\(http://a.com\);\*//\*e:url\("http://b.com"\) ;\*/}
 selector6  {   ab    :     cd      }       
 selector7  {   ab    :     cd      ;       }        
 selector8  {   ab    :     cd      ;       ef        :         gh          }           
 selector9  {   ab    :     cd      ;       ef        :         gh          ;           }            
 selector10  {   ab    :     cd      ;       x         :         y           ;           /\*r            :             url\(http://a.com\)              \*/}               
    ${CommentEndText}--></style>$}, "CSS callback - force normal");

$Defang = HTML::Defang->new(
  css_callback => sub {
    my $StyleRules = $_[3];
    foreach my $StyleRule (@$StyleRules) {
      foreach my $KeyValueRules (@$StyleRule) {
        foreach my $KeyValueRule (@$KeyValueRules) {
          $$KeyValueRule[2] = 0;
        }
      }
    }
    return 1;
  },
);
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
<style>   

selector1{ab:cd}
selector2{ab:cccd;}
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
like($Res, qr{^1:<a style="a:b">
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
31:<a href="abccomscript" title="a" id="a1" style="{color: #900}&#x0a;          :link {background: #ff0}&#x0a;          :visited {background: #fff}&#x0a;          :hover {outline: thin red solid}&#x0a;          :active {background: #00f}">
<style><!--${CommentStartText}   

selector1{ab:cd}
selector2{ab:cccd;}
selector3{ab:cd;ef:gh}
selector4{ab:cd;ef:gh;}
selector5{ab:cd;x:y;p:q;r:url\(http://a.com\);e:url\("http://b.com"\) ;}
 selector6  {   ab    :     cd      }       
 selector7  {   ab    :     cd      ;       }        
 selector8  {   ab    :     cd      ;       ef        :         gh          }           
 selector9  {   ab    :     cd      ;       ef        :         gh          ;           }            
 selector10  {   ab    :     cd      ;       x         :         y           ;           r            :             url\(http://a.com\)              }               
    ${CommentEndText}--></style>$}, "CSS callback - force skip");

$Defang = HTML::Defang->new(
  css_callback => sub {
    my $StyleRules = $_[3];
    foreach my $StyleRule (@$StyleRules) {
      foreach my $KeyValueRules (@$StyleRule) {
        foreach my $KeyValueRule (@$KeyValueRules) {
          $$KeyValueRule[2] = 1;
        }
      }
    }
    return 1;
  },
);
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
<style>   

selector1{ab:cd}
selector2{ab:cccd;}
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
like($Res, qr{^1:<a style="/\*a:b\*/">
2:<a style=" /\*c  :   d    \*/">
3:<a style="/\*e:f;\*/">
4:<a style=" /\*g  :   h    ;\*/     ">

5:<a style="/\*i:j;\*//\*k:l\*/">
6:<a style=" /\*i2  :   j2    ;\*/     /\*k2      :       l2        \*/">
7:<a style="/\*i3:j3;\*//\*k3:l3;\*/">
8:<a style=" /\*i4  :   j4    ;\*/     /\*k4      :       l4        ;\*/         ">

9:<a style="{/\*q:r\*/}">
10:<a style=" {  /\*s   :    t     \*/}      ">
11:<a style="{/\*u:v;\*/}">
12:<a style=" {  /\*w   :    x     ;\*/      }       ">

13:<a style="{/\*i5:j5;\*//\*k5:l5\*/}">
14:<a style=" {  /\*i6   :    j6     ;\*/      /\*k6       :        l6         \*/}          ">
15:<a style="{/\*i7:j7;\*//\*k7:l7;\*/}">
16:<a style=" {  /\*i8   :    j8     ;\*/      /\*k8       :        l8         ;\*/          }          ">

17:<a style="s1{/\*y:z\*/}">
18:<a style=" s1  {   /\*y2    :     z2      \*/}       ">
19:<a style="s1{/\*y3:z3;\*/}">
20:<a style=" s1  {   /\*y4    :     z4      ;\*/       }        ">

21:<a style="s1{/\*y5:z5;\*//\*y6:z6\*/}">
22:<a style=" s2  {   /\*y7    :     z7      ;\*/       /\*y8        :         z8          \*/}           ">
23:<a style="s3{/\*y9:z9;\*//\*y10:z11;\*/}">
24:<a style=" s4  {   /\*y12    :     z12      ;\*/       /\*y13        :         z13          ;\*/           }            ">

25:<a style="s5{/\*aa:ab\*/}s6{/\*ac:ad\*/}">
26:<a style=" s7  {   /\*ae    :     af      \*/}       s8        {         /\*ag          :           ah            \*/}             ">
27:<a style="s5{/\*ai:aj;\*/}s6{/\*ak:al;\*/}">
28:<a style=" s7  {   /\*am    :     an      \*/}       s8        {         /\*ao          :           ap            ;\*/             }              ">

29:<a style="{/\*color: #900\*/} :link {/\*background: #ff0\*/} :visited {/\*background: #fff\*/} :hover {/\*outline: thin red solid\*/} :active {/\*background: #00f\*/}">
30:<a style="{/\*color: #090;\*/ /\*line-height: 1.2\*/} ::first-letter {/\*color: #900\*/}">
31:<a href="abccomscript" title="a" id="a1" style="{/\*color: #900\*/}&#x0a;          :link {/\*background: #ff0\*/}&#x0a;          :visited {/\*background: #fff\*/}&#x0a;          :hover {/\*outline: thin red solid\*/}&#x0a;          :active {/\*background: #00f\*/}">
<style><!--${CommentStartText}   

selector1{/\*ab:cd\*/}
selector2{/\*ab:cccd;\*/}
selector3{/\*ab:cd;\*//\*ef:gh\*/}
selector4{/\*ab:cd;\*//\*ef:gh;\*/}
selector5{/\*ab:cd;\*//\*x:y;\*//\*p:q;\*//\*r:url\(http://a.com\);\*//\*e:url\("http://b.com"\) ;\*/}
 selector6  {   /\*ab    :     cd      \*/}       
 selector7  {   /\*ab    :     cd      ;\*/       }        
 selector8  {   /\*ab    :     cd      ;\*/       /\*ef        :         gh          \*/}           
 selector9  {   /\*ab    :     cd      ;\*/       /\*ef        :         gh          ;\*/           }            
 selector10  {   /\*ab    :     cd      ;\*/       /\*x         :         y           ;\*/           /\*r            :             url\(http://a.com\)              \*/}               
    ${CommentEndText}--></style>}, "CSS callback - force defang");

$Defang = HTML::Defang->new(
  css_callback => sub {
    my $StyleRules = $_[3];
    foreach my $StyleRule (@$StyleRules) {
      foreach my $KeyValueRules (@$StyleRule) {
        unshift @$KeyValueRules, ["apricot", "nectar", 0];
        push @$KeyValueRules, ["orange", "juice", 0];
      }
    }
    return 1;
  },
);
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
<style>   

selector1{ab:cd}
selector2{ab:cccd;}
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
like($Res, qr{^1:<a style="apricot:nectar;a:b;orange:juice">
2:<a style=" apricot:nectar;c  :   d    ;orange:juice">
3:<a style="apricot:nectar;e:f;orange:juice">
4:<a style=" apricot:nectar;g  :   h    ;     orange:juice">

5:<a style="apricot:nectar;i:j;k:l;orange:juice">
6:<a style=" apricot:nectar;i2  :   j2    ;     k2      :       l2        ;orange:juice">
7:<a style="apricot:nectar;i3:j3;k3:l3;orange:juice">
8:<a style=" apricot:nectar;i4  :   j4    ;     k4      :       l4        ;         orange:juice">

9:<a style="{apricot:nectar;q:r;orange:juice}">
10:<a style=" {apricot:nectar;  s   :    t     ;orange:juice}      ">
11:<a style="{apricot:nectar;u:v;orange:juice}">
12:<a style=" {apricot:nectar;  w   :    x     ;      orange:juice}       ">

13:<a style="{apricot:nectar;i5:j5;k5:l5;orange:juice}">
14:<a style=" {apricot:nectar;  i6   :    j6     ;      k6       :        l6         ;orange:juice}          ">
15:<a style="{apricot:nectar;i7:j7;k7:l7;orange:juice}">
16:<a style=" {apricot:nectar;  i8   :    j8     ;      k8       :        l8         ;          orange:juice}          ">

17:<a style="s1{apricot:nectar;y:z;orange:juice}">
18:<a style=" s1  {apricot:nectar;   y2    :     z2      ;orange:juice}       ">
19:<a style="s1{apricot:nectar;y3:z3;orange:juice}">
20:<a style=" s1  {apricot:nectar;   y4    :     z4      ;       orange:juice}        ">

21:<a style="s1{apricot:nectar;y5:z5;y6:z6;orange:juice}">
22:<a style=" s2  {apricot:nectar;   y7    :     z7      ;       y8        :         z8          ;orange:juice}           ">
23:<a style="s3{apricot:nectar;y9:z9;y10:z11;orange:juice}">
24:<a style=" s4  {apricot:nectar;   y12    :     z12      ;       y13        :         z13          ;           orange:juice}            ">

25:<a style="s5{apricot:nectar;aa:ab;orange:juice}s6{apricot:nectar;ac:ad;orange:juice}">
26:<a style=" s7  {apricot:nectar;   ae    :     af      ;orange:juice}       s8        {apricot:nectar;         ag          :           ah            ;orange:juice}             ">
27:<a style="s5{apricot:nectar;ai:aj;orange:juice}s6{apricot:nectar;ak:al;orange:juice}">
28:<a style=" s7  {apricot:nectar;   am    :     an      ;orange:juice}       s8        {apricot:nectar;         ao          :           ap            ;             orange:juice}              ">

29:<a style="{apricot:nectar;color: #900;orange:juice} :link {apricot:nectar;background: #ff0;orange:juice} :visited {apricot:nectar;background: #fff;orange:juice} :hover {apricot:nectar;outline: thin red solid;orange:juice} :active {apricot:nectar;background: #00f;orange:juice}">
30:<a style="{apricot:nectar;color: #090; line-height: 1.2;orange:juice} ::first-letter {apricot:nectar;color: #900;orange:juice}">
31:<a href="abccomscript" title="a" id="a1" style="{apricot:nectar;color: #900;orange:juice}&#x0a;          :link {apricot:nectar;background: #ff0;orange:juice}&#x0a;          :visited {apricot:nectar;background: #fff;orange:juice}&#x0a;          :hover {apricot:nectar;outline: thin red solid;orange:juice}&#x0a;          :active {apricot:nectar;background: #00f;orange:juice}">
<style><!--${CommentStartText}   

selector1{apricot:nectar;ab:cd;orange:juice}
selector2{apricot:nectar;ab:cccd;orange:juice}
selector3{apricot:nectar;ab:cd;ef:gh;orange:juice}
selector4{apricot:nectar;ab:cd;ef:gh;orange:juice}
selector5{apricot:nectar;ab:cd;x:y;p:q;/\*r:url\(http://a.com\);\*//\*e:url\("http://b.com"\) ;\*/orange:juice}
 selector6  {apricot:nectar;   ab    :     cd      ;orange:juice}       
 selector7  {apricot:nectar;   ab    :     cd      ;       orange:juice}        
 selector8  {apricot:nectar;   ab    :     cd      ;       ef        :         gh          ;orange:juice}           
 selector9  {apricot:nectar;   ab    :     cd      ;       ef        :         gh          ;           orange:juice}            
 selector10  {apricot:nectar;   ab    :     cd      ;       x         :         y           ;           /\*r            :             url\(http://a.com\)              ;\*/orange:juice}               
    ${CommentEndText}--></style>$}, "CSS callback - insert attribute");


$Defang = HTML::Defang->new(
  css_callback => sub {
    my $StyleRules = $_[3];
    foreach my $StyleRule (@$StyleRules) {
      foreach my $KeyValueRules (@$StyleRule) {
        pop @$KeyValueRules;
      }
    }
    return 1;
  },
);
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
<style>   

selector1{ab:cd}
selector2{ab:cccd;}
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
like($Res, qr{^1:<a style="">
2:<a style=" ">
3:<a style="">
4:<a style=" ">

5:<a style="i:j;">
6:<a style=" i2  :   j2    ;     ">
7:<a style="i3:j3;">
8:<a style=" i4  :   j4    ;     ">

9:<a style="{}">
10:<a style=" {}      ">
11:<a style="{}">
12:<a style=" {}       ">

13:<a style="{i5:j5;}">
14:<a style=" {  i6   :    j6     ;      }          ">
15:<a style="{i7:j7;}">
16:<a style=" {  i8   :    j8     ;      }          ">

17:<a style="s1{}">
18:<a style=" s1  {}       ">
19:<a style="s1{}">
20:<a style=" s1  {}        ">

21:<a style="s1{y5:z5;}">
22:<a style=" s2  {   y7    :     z7      ;       }           ">
23:<a style="s3{y9:z9;}">
24:<a style=" s4  {   y12    :     z12      ;       }            ">

25:<a style="s5{}s6{}">
26:<a style=" s7  {}       s8        {}             ">
27:<a style="s5{}s6{}">
28:<a style=" s7  {}       s8        {}              ">

29:<a style="{} :link {} :visited {} :hover {} :active {}">
30:<a style="{color: #090; } ::first-letter {}">
31:<a href="abccomscript" title="a" id="a1" style="{}&#x0a;          :link {}&#x0a;          :visited {}&#x0a;          :hover {}&#x0a;          :active {}">
<style><!--${CommentStartText}   

selector1{}
selector2{}
selector3{ab:cd;}
selector4{ab:cd;}
selector5{ab:cd;x:y;p:q;/\*r:url\(http://a.com\);\*/}
 selector6  {}       
 selector7  {}        
 selector8  {   ab    :     cd      ;       }           
 selector9  {   ab    :     cd      ;       }            
 selector10  {   ab    :     cd      ;       x         :         y           ;           }               
    ${CommentEndText}--></style>$}, "CSS callback - remove attribute from style rule end");

$Defang = HTML::Defang->new(
  css_callback => sub {
    my $StyleRules = $_[3];
    foreach my $StyleRule (@$StyleRules) {
      foreach my $KeyValueRules (@$StyleRule) {
        push @$KeyValueRules, ["orange", "juice", 0];
      }
    }
    return 1;
  },
);
$H = <<EOF;
1:<a STYLE="a:b">
2:<a STYLE="A:b">
3:<STYLE>A {WIDTH: 30}</STYLE>
EOF
$Res = $Defang->defang($H);
like($Res, qr{1:<a STYLE="a:b;orange:juice">}, "Style callback attribute in upper case");
like($Res, qr{2:<a STYLE="A:b;orange:juice">}, "Style callback attribute and style property in upper case");
like($Res, qr{3:<STYLE><!--${CommentStartText}A {WIDTH: 30;orange:juice}${CommentEndText}--></STYLE>}, "Style callback tag and style property in upper case");

#################################
#  Multiple callback test
#################################

$Defang = HTML::Defang->new(
  tags_to_callback => [ qw(img font unknown1 unknown2 button hr area) ],
  tags_callback => sub {
    my ($Context, $Defang, $Tag, $IsEndTag, $AttributeHash, $HtmlR) = @_;
    my $DefangFlag = 2;
    $DefangFlag = 0 if $Tag eq "img" || $Tag eq "unknown1" || $Tag eq "button";
    $DefangFlag = 1 if $Tag eq "font" || $Tag eq "unknown2" || $Tag eq "hr";
    return $DefangFlag;
  }
);
$H = <<EOF;
<img width=0 style="key:url(http://example.com)"
EOF
$Res = $Defang->defang($H);
