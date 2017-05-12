
use strict;

BEGIN {
binmode STDOUT,':utf8';
binmode STDERR,':utf8';
    $^W = 1;

    use vars qw(@tests);
    @tests = (
        [ 'empty',    q{},                q{} ],
        [ 'space',    q{ },               q{ } ],
        [ 'plain',    q{hello mum},       q{hello mum} ],
        [ 'plain nl', qq{hello mum\n},    "hello mum\n" ],
        [ 'nonprint', qq{foo\0bar},       "foo bar" ],
        [ 'p tag',    qq{<p>hello mum\n}, "<p>hello mum\n</p>" ],
        [ 'i tag',    qq{<i>hello mum\n}, "<i>hello mum\n</i>" ],
        [  'valid p',
           q{<ins><p>valid p</p></ins>},
           q{<ins><p>valid p</p></ins>}
        ],
        [ 'misplaced tr', q{misplaced <tr>}, q{misplaced <!--filtered-->} ],
        [ 'misplaced td', q{misplaced <td>}, q{misplaced <!--filtered-->} ],
        [ 'misplaced li', q{misplaced <li>}, q{misplaced <!--filtered-->} ],
        [  'misplaced cdata',
           q{<table><tr>misplaced cdata<td>hello},
           q{<table><tr/></table>misplaced cdata<!--filtered-->hello}
        ],
        [ 'pass emtpy img', q{<img>}, q{<img/>} ],
        [  'block img src',
           q{<img src="http://example.com/foo.png" />},
           q{<img/>}
        ],
        [ 'block a href',   q{<a href="http://foo.foo/foo">x}, q{<a>x</a>} ],
        [ 'block a mailto', q{<a href="mailto:foo@foo.foo">x}, q{<a>x</a>} ],
        [ 'unknown tag',     q{<foo>},       q{<!--filtered-->} ],
        [ 'unknown attr',    q{<i foo=foo>}, q{<i/>} ],
        [ 'misplaced close', q{</i>},        q{<!--filtered-->} ],
        [ 'br',          q{<br>hello</br>},   q{<br/>hello<!--filtered-->} ],
        [ 'hr width',    q{x<hr width=4>y},   q{x<hr width="4"/>y} ],
        [ 'hr width dq', q{x<hr width="4">y}, q{x<hr width="4"/>y} ],
        [ 'hr width sq', q{x<hr width='4'>y}, q{x<hr width="4"/>y} ],
        [  'hr silly width',
           q{x<hr width=18234081234019840138340938410242343144>y},
           q{x<hr/>y}
        ],
        [  'hr silly width dq',
           q{x<hr width="18234081234019840138340938410242343144">y},
           q{x<hr/>y}
        ],
        [  'hr silly width sq',
           q{x<hr width='18234081234019840138340938410242343144'>y},
           q{x<hr/>y}
        ],
        [ 'bad trailing /',  q{<i />hello</i>}, q{<i>hello</i>} ],
        [ 'good trailing /', q{<br/>},         q{<br/>} ],
        [ 'interleave', q{<i>g<b>h</i>E</b>}, q{<i>g<b>h</b></i><b>E</b>} ],
        [  'interleave case', q{<i>g<B>h</i>E</b>},
           q{<i>g<b>h</b></i><b>E</b>}
        ],
        [ 'interleave open', q{<i>g<b>h</i>E}, q{<i>g<b>h</b></i><b>E</b>} ],
        [  'p close order', q{<p>one<p>two<p>three},
           q{<p>one</p><p>two</p><p>three</p>}
        ],
        [  'p/li close order',
           q{<ul><li><p>1<li><p>2</ul>},
           q{<ul><li><p>1</p></li><li><p>2</p></li></ul>},
        ],
        [  'p/li left open',
           q{<ul><li><p>1<li><p>2},
           q{<ul><li><p>1</p></li><li><p>2</p></li></ul>},
        ],
        [ 'italic p',        q{<i>foo<p>bar}, q{<i>foo</i><p>bar</p>} ],
        [ 'misplaced close', q{foo</i>},      q{foo<!--filtered-->} ],

        #   [ 'lonley <',          q{<}, q{&lt;} ],
        [ 'lonley >',          q{>},         q{&gt;} ],
        [ 'lonley "',          q{"},         q{"} ],
        [ 'lonley &',          q{&},         q{&amp;} ],
        [ 'valid entity',      q{&lt;},      q{&lt;} ],
        [ 'uppercase entity',  q{&THORN;},   qq{\x{00DE}} ],
        [ 'valid numeric ent', q{&#123;},    '{' ],
        [ 'valid hex entity',  q{&#x6B;},    q{k} ],
        [ 'unicode numeric',   q{&#3202;},   qq{\x{0C82}} ],
        [ 'unicode hex lc',    q{&#xBF94;},  qq{\x{BF94}} ],
        [ 'unicode hex uc',    q{&#XBF94;},  qq{\x{BF94}} ],
        [ 'unknown entity',    q{&foo;},     q{&amp;foo;} ],
        [ 'nasty entity',      q{ &{foo}; }, q{ &amp;{foo}; } ],
        [ 'minus entity',      q{&foo-foo;}, q{&amp;foo-foo;} ],
        [ 'underscore entity', q{&foo_foo;}, q{&amp;foo_foo;} ],
        [  'overlong entity',
           q{&littlesquigglethingwithalinethroughit;},
           q{&amp;littlesquigglethingwithalinethroughit;}
        ],
        [ 'overlong hex',     q{&#x7FB20A4E;}, q{&amp;#x7FB20A4E;} ],
        [ 'overlong decimal', q{&#349850348;}, q{&amp;#349850348;} ],
        [ '-ve decimal',      q{&#-7;},        q{&amp;#-7;} ],
        [ '+ve decimal',      q{&#+7;},        q{&amp;#+7;} ],
        [ 'invalid numeric',  q{&#o777;},      q{&amp;#o777;} ],
        [ '<<script>',        q{<<script>},    q{&lt;<!--filtered-->} ],
        [ '< script>',        q{< script>},    q{&lt; script&gt;} ],

        #   [ '<>',                q{<>}, q{&lt;&gt;} ],
        #   [ '><',                q{><}, q{&gt;&lt;} ],
        #   [ '<<',                q{<<}, q{&lt;&lt;} ],
        [ '>>',  q{>>},  q{&gt;&gt;} ],
        [ '< >', q{< >}, q{&lt; &gt;} ],

        #  [ '</>',               q{</>}, q{&lt;/&gt;} ],

        [ 'nest pre', q{<pre>foo<pre>bar}, q{<pre>foo</pre><pre>bar</pre>} ],
        [  'nest pre with i', q{<pre><i>foo<pre>bar},
           q{<pre><i>foo</i></pre><pre>bar</pre>}
        ],
        [  'ins block level',
           q{xxxx<ins><p>foo</p></ins>yyyy},
           q{xxxx<ins><p>foo</p></ins>yyyy}
        ],
        [  'ins inline level', q{<i>foo<ins>FOO</ins>bar</i>},
           q{<i>foo<ins>FOO</ins>bar</i>}
        ],
        [  'ins inline2block',
           q{x<i><ins><p>foo</p></ins></i>},
           q{x<i><ins/></i><p>foo</p><!--filtered--><!--filtered-->}
        ],
        [  'del block level',
           q{xxxx<del><p>foo</p></del>yyyy},
           q{xxxx<del><p>foo</p></del>yyyy}
        ],
        [  'del inline level', q{<i>foo<del>FOO</del>bar</i>},
           q{<i>foo<del>FOO</del>bar</i>}
        ],
        [  'del inline2block',
           q{x<i><del><p>foo</p></del></i>},
           q{x<i><del/></i><p>foo</p><!--filtered--><!--filtered-->}
        ],
        [  'nested a', q{<a>foo<a>bar</a></a>},
           q{<a>foo<!--filtered-->bar</a><!--filtered-->}
        ],
        [  'sneaky nested a',
           q{<a>f<i>o<b>g<a>o</a>b</b>r</i>x</a>},
           q{<a>f<i>o<b>g<!--filtered-->o</b></i></a>b<!--filtered-->r<!--filtered-->x<!--filtered-->}
        ],

        [  'strip comment',
           q{x<i>y<!-- hello -->foo},
           q{x<i>y<!--filtered-->foo</i>}
        ],
        [  'strip comment 2',
           q{x<i>y<<!-- hello -->foo},
           q{x<i>y&lt;<!--filtered-->foo</i>}
        ],
        [ 'bare comment', q{x<!-- hello -->y}, q{x<!--filtered-->y} ],
        [  'SSI', q{foo<!--# exec "/tmp/grunion" -->pah},
           q{foo<!--filtered-->pah}
        ],

#   [ 'SSI unclosed',      q{foo<!--# exec "/tmp/grunion"}, q{foo&lt;!--# exec &quot;/tmp/grunion&quot;} ],
#   [ 'SSI misclosed',     q{foo<!--# exec "/tmp/grunion" >}, q{foo&lt;!--# exec &quot;/tmp/grunion&quot; &gt;} ],
        [  'xml metatag',
           q{x<?xml version="1.0" encoding="utf-8"?>y},
           q{x<!--filtered-->y}
        ],
        [ 'doctype', <<'END', "<!--filtered-->\n" ],
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
END
        [  'trailing garbage',
           q{<i /(&(&(&(*%&^^*%&*&%)>hello},
           q{<i>hello</i>}
        ],
        [  'newline confusion', qq{<foo>\n<foo>},
           qq{<!--filtered-->\n<!--filtered-->}
        ],

        [  'dual attr',
           q{<font color=red size=2>foo},
           q{<font color="red" size="2">foo</font>}
        ],
        [  'dual attr bad',
           q{<font color=red size=2 foo=4>foo},
           q{<font color="red" size="2">foo</font>}
        ],
        [  'dual attr empty',
           q{<font color=red foo="" size=2>foo},
           q{<font color="red" size="2">foo</font>}
        ],
        [  'dual attr noval',
           q{<font color=red foo size=2>foo},
           q{<font color="red" size="2">foo</font>}
        ],
        [  'dual attr mixed',
           q{<font color="red" size='2'>foo},
           q{<font color="red" size="2">foo</font>}
        ],
        [  'dual attr 1st bad',
           q{<font color="$-" size="3">foo},
           q{<font size="3">foo</font>}
        ],
        [  'dual attr 2nd bad',
           q{<font color="red" size="fish">foo},
           q{<font color="red">foo</font>}
        ],
        [  'attr mixed case',
           q{<FoNt COLOR="red" size="fish">foo},
           q{<font color="red">foo</font>}
        ],
        [  'attr upper case',
           q{<FONT COLOR="red" SIZE="fish">foo</FONT>},
           q{<font color="red">foo</font>}
        ],

        [  'heavy duty de-interleave',
           q{<u>x<font size=4 color=red>y<i>b<b><font color=blue style="background-color: pink">X</u>Y},
           q{<u>x<font color="red" size="4">y<i>b<b><font color="blue" style="background-color:pink">X}
               . q{</font></b></i></font></u><font color="red" size="4"><i><b><font color="blue" style="background-color:pink">Y}
               . q{</font></b></i></font>}
        ],

        [  'tags in pre',
           q{<pre>}
               . q{<br/><span><tt><i><b><u><s><strike><em><ins><strong><dfn>}
               . q{<code><q><samp><kbd><var><del><cite><abbr><acronym><a>foo},

           q{<pre>}
               . q{<br/><span><tt><i><b><u><s><strike><em><ins><strong><dfn>}
               . q{<code><q><samp><kbd><var><del><cite><abbr><acronym><a>foo}
               . q{</a></acronym></abbr></cite></del></var></kbd></samp></q></code></dfn>}
               . q{</strong></ins></em></strike></s></u></b></i></tt></span></pre>}
        ],

        [  'interleave i/a', q{<i><a><tt>foo</a>},
           q{<i><a><tt>foo</tt></a></i>},
        ],

        [  'tags in i',
           q{<i><a>}
               . q{<br/><span><tt><i><b><u><s><strike><em><ins><strong><dfn><big><small>}
               . q{<font size="3" face="Helvetica" color="#FFFFFF">}
               . q{<code><q><samp><kbd><var><del><cite><abbr><acronym><sub><sup><nobr>foo},

           q{<i><a>}
               . q{<br/><span><tt><i><b><u><s><strike><em><ins><strong><dfn><big><small>}
               . q{<font color="#FFFFFF" face="Helvetica" size="3">}
               . q{<code><q><samp><kbd><var><del><cite><abbr><acronym><sub><sup><nobr>foo}
               . q{</nobr></sup></sub></acronym></abbr></cite></del></var></kbd></samp></q></code>}
               . q{</font>}
               . q{</small></big></dfn></strong></ins></em></strike></s></u></b></i></tt></span>}
               . q{</a></i>}
        ],

        [ 'pre close pre', q{<pre><pre>}, q{<pre/><pre/>} ],
        [ 'p close pre',   q{<pre><p>D},  q{<pre/><p>D</p>} ],
        [  'no big in pre',
           q{<pre>x<big>y</big></pre>},
           q{<pre>x</pre><big>y</big><!--filtered-->}
        ],
        [  'no h3 in pre',
           q{<pre>x<h3>y</h3></pre>},
           q{<pre>x</pre><h3>y</h3><!--filtered-->}
        ],
        [  'no tr in pre',
           q{<pre>x<tr>y</tr></pre>},
           q{<pre>x<!--filtered-->y<!--filtered--></pre>}
        ],
        [  'deinterleave pre',
           q{<pre>hello<i>there</pre>foo</i>},
           q{<pre>hello<i>there</i></pre>foo<!--filtered-->}
        ],

        [  'no bare td', q{<table><td>foo},
           q{<table><!--filtered--></table>foo}
        ],
        [  'no bare th', q{<table><th>foo},
           q{<table><!--filtered--></table>foo}
        ],
        [  'td in tr', q{<table><tr><td>foo},
           q{<table><tr><td>foo</td></tr></table>}
        ],
        [  'th in tr', q{<table><tr><th>foo},
           q{<table><tr><th>foo</th></tr></table>}
        ],
    );

}

use Test::More tests => scalar(@tests);
use HTML::StripScripts::LibXML;

my $filt = HTML::StripScripts::LibXML->new;

foreach my $t (@tests) {
    my ( $name, $in, $want ) = @$t;
    is( $filt->filter_html($in)->toString, $want, $name );
}


