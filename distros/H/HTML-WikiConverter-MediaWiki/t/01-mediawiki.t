local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'MediaWiki', wiki_uri => 'http://www.test.com/wiki/' );
close DATA;

__DATA__
external link
__H__
<p><a href="http://example.com">[http://example.com]</a></p>
__W__
[http://example.com <nowiki>[http://example.com]</nowiki>]
__NEXT__
nowiki template
__H__
<p>mark stubs with {{stub}}</p>
__W__
<nowiki>mark stubs with {{stub}}</nowiki>
__NEXT__
nowiki quoted
__H__
<p>what happens to 'quoted text'?</p>
__W__
what happens to 'quoted text'?
__NEXT__
nowiki doubly quoted
__H__
<p>how about ''doubly quoted''?</p>
__W__
<nowiki>how about ''doubly quoted''?</nowiki>
__NEXT__
nowiki triply quoted
__H__
<p>and '''triply quoted'''?</p>
__W__
<nowiki>and '''triply quoted'''?</nowiki>
__NEXT__
nowiki hr
__H__
<p>----</p>
__W__
<nowiki>----</nowiki>
__NEXT__
nowiki ul
__H__
<p>* ul</p>
__W__
<nowiki>* ul</nowiki>
__NEXT__
nowiki ol
__H__
<p># ol</p>
__W__
<nowiki># ol</nowiki>
__NEXT__
nowiki def
__H__
<p>; def</p>
__W__
<nowiki>; def</nowiki>
__NEXT__
nowiki indent
__H__
<p>: indent</p>
__W__
<nowiki>: indent</nowiki>
__NEXT__
nowiki internal links
__H__
<p>an [[internal]] link</p>
__W__
<nowiki>an [[internal]] link</nowiki>
__NEXT__
nowiki table markup
__H__
<p>{|<br />
| table<br />
|}</p>
__W__
<nowiki>{|</nowiki><br /> | table<br /> |}
__NEXT__
nowiki ext link
__H__
<p>[http://example.com]</p>
__W__
<nowiki>[http://example.com]</nowiki>
__NEXT__
(bug #46453) triggering <nowiki> too often
__H__
<em>x</em>:bla
__W__
''x'':bla
__NEXT__
do not add a <nowiki> tag only if offending character(s) occur at the beginning of text node
__H__
<p>text <strong>*</strong>
<p>text <strong>#</strong>
<p>text <strong>;</strong>
<p>text <strong>:</strong>
<p>text <strong>=</strong>
<p>text <strong>!</strong>
<p>text <strong>|</strong>
<p>text <strong>----</strong>
<p>text <strong>{|</strong>
__W__
text '''*'''

text '''#'''

text ''';'''

text ''':'''

text '''='''

text '''!'''

text '''|'''

text '''----'''

text '''{|'''
__NEXT__
tr attributes
__H__
<html><table><tr align="left" valign="top"><td>ok</td></tr></table></html>
__W__
{|
|- align="left" valign="top"
| ok
|}
__NEXT__
preserve cite
__H__
<html><cite id="good">text</cite></html>
__W__
<cite id="good">text</cite>
__NEXT__
preserve var
__H__
<html><var id="good">text</var></html>
__W__
<var id="good">text</var>
__NEXT__
preserve blockquote
__H__
<html><blockquote cite="something" onclick="alert('hello')">text</blockquote></html>
__W__
<blockquote cite="something">text</blockquote>
__NEXT__
preserve ruby
__H__
<html><ruby>text</ruby></html>
__W__
<ruby>text</ruby>
__NEXT__
preserve rb
__H__
<html><rb id="ok">text</rb></html>
__W__
<rb id="ok">text</rb>
__NEXT__
preserve rt
__H__
<html><rt id="ok" blah="blah">text</rt></html>
__W__
<rt id="ok">text</rt>
__NEXT__
preserve rp
__H__
<html><rp id="ok" something="ok" bad="good" class="stuff">text</rp></html>
__W__
<rp id="ok" class="stuff">text</rp>
__NEXT__
preserve div
__H__
<html><div id="thing" align="left" bad="good">ok</div></html>
__W__
<div id="thing" align="left">ok</div>
__NEXT__
empty line break
__H__
<html><br id="thing"></br></html>
__W__
<br id="thing" />
__NEXT__
br attribs
__H__
<html>ok<br id="stuff" class="things" title="ok" style="clear:both" clear="both"></html>
__W__
ok<br id="stuff" class="things" title="ok" style="clear: both" clear="both" />
__NEXT__
wrap in html
__H__
<a href="http://google.com">GOOGLE</a><br/>
NewLine
__W__
[http://google.com GOOGLE]<br /> NewLine
__NEXT__
bold
__H__
<html><b>bold</b></html>
__W__
'''bold'''
__NEXT__
italics
__H__
<html><i>italics</i></html>
__W__
''italics''
__NEXT__
bold and italics
__H__
<html><b>bold</b> and <i>italics</i></html>
__W__
'''bold''' and ''italics''
__NEXT__
bold-italics nested
__H__
<html><b><i>bold-italics</i> nested</b></html>
__W__
'''''bold-italics'' nested'''
__NEXT__
strong
__H__
<html><strong>strong</strong></html>
__W__
'''strong'''
__NEXT__
emphasized
__H__
<html><em>emphasized</em></html>
__W__
''emphasized''
__NEXT__
underlined
__H__
<html><u>underlined</u></html>
__W__
<u>underlined</u>
__NEXT__
strikethrough
__H__
<html><s>strike</s></html>
__W__
<s>strike</s>
__NEXT__
deleted
__H__
<html><del>deleted text</del></html>
__W__
<del>deleted text</del>
__NEXT__
inserted
__H__
<html><ins>inserted</ins></html>
__W__
<ins>inserted</ins>
__NEXT__
span tags removed if naked (ie, have no attribs)
__H__
<html><span>text here</span></html>
__W__
text here
__NEXT__
strip aname
__H__
<html><a name="thing"></a></html>
__W__

__NEXT__
one-line phrasals
__H__
<html><i>phrasals
in one line</i></html>
__W__
''phrasals in one line''
__NEXT__
paragraph blocking
__H__
<html><p>p1</p><p>p2</p></html>
__W__
p1

p2
__NEXT__
lists
__H__
<html><ul><li>1</li><li>2</li></ul></html>
__W__
* 1
* 2
__NEXT__
nested lists
__H__
<html><ul><li>1<ul><li>1a</li><li>1b</li></ul></li><li>2</li></ul>
__W__
* 1
** 1a
** 1b
* 2
__NEXT__
nested lists (different types)
__H__
<html><ul><li>1<ul><li>a<ol><li>i</li></ol></li><li>b</li></ul></li><li>2<dl><dd>indented</dd></dl></li></ul></html>
__W__
* 1
** a
**# i
** b
* 2
*: indented
__NEXT__
hr
__H__
<html><hr /></html>
__W__
----
__NEXT__
br
__H__
<html><p>stuff<br />stuff two</p></html>
__W__
stuff<br />stuff two
__NEXT__
div
__H__
<html><div>thing</div></html>
__W__
<div>thing</div>
__NEXT__
div w/ attrs
__H__
<html><div id="name" class="panel" onclick="popup()">thing</div></html>
__W__
<div id="name" class="panel">thing</div>
__NEXT__
sub
__H__
<html><p>H<sub>2</sub>O</p></html>
__W__
H<sub>2</sub>O
__NEXT__
sup
__H__
<html><p>x<sup>2</sup></p></html>
__W__
x<sup>2</sup>
__NEXT__
center
__H__
<html><center>centered text</center></html>
__W__
<center>centered text</center>
__NEXT__
small
__H__
<html><small>small text</small></html>
__W__
<small>small text</small>
__NEXT__
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
<code>$name = 'stan';</code>
__NEXT__
tt
__H__
<html><tt>tt text</tt></html>
__W__
<tt>tt text</tt>
__NEXT__
font-to-span conversion ::TODO("HTML::WikiConverter::Normalizer not doing font-to-span conversion yet")
__H__
<html><font color="blue" face="Arial" size="+2">font</font></html>
__W__
<span style="font-size:+2; color:blue; font-family:Arial">font</span>
__NEXT__
font
__H__
<html><font color="blue" face="Arial" size="+2">font</font></html>
__W__
<font size="+2" color="blue" face="Arial">font</font>
__NEXT__
pre
__H__
<html><pre>this
  is
    preformatted
      text</pre></html>
__W__
 this
   is
     preformatted
       text
__NEXT__
indent
__H__
<html><dl><dd>indented text</dd></dl></html>
__W__
: indented text
__NEXT__
nested indent
__H__
<html><dl><dd>stuff<dl><dd>double-indented</dd></dl></dd></dl></html>
__W__
: stuff
:: double-indented
__NEXT__
h1
__H__
<h1>h1</h1>
__W__
=h1=
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
==h2==
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
===h3===
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
====h4====
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
=====h5=====
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
======h6======
__NEXT__
img
__H__
<html><img src="thing.gif" /></html>
__W__
[[Image:thing.gif]]
__NEXT__
table
__H__
<table>
  <caption>Stuff</caption>
  <tr>
    <th> Name </th> <td> David </td>
  </tr>
  <tr>
    <th> Age </th> <td> 24 </td>
  </tr>
  <tr>
    <th> Height </th> <td> 6' </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
          <td> Nested </td>
          <td> tables </td>
        </tr>
        <tr>
          <td> are </td>
          <td> fun </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
__W__
{|
|+ Stuff
|-
! Name
| David
|-
! Age
| 24
|-
! Height
| 6'
|-
|
{|
| Nested
| tables
|-
| are
| fun
|}
|}
__NEXT__
table w/ attrs
__H__
<table border=1 cellpadding=3 bgcolor=#ffffff onclick='alert("alert!")'>
  <caption>Stuff</caption>
  <tr id="first" class="unselected">
    <th id=thing bgcolor=black> Name </th> <td> Foo </td>
  </tr>
  <tr class="selected">
    <th> Age </th> <td>24</td>
  </tr>
  <tr class="unselected">
    <th> <u>Height</u> </th> <td> 6' </td>
  </tr>
</table>
__W__
{| border="1" cellpadding="3" bgcolor="#ffffff"
|+ Stuff
|- id="first" class="unselected"
! id="thing" bgcolor="black" | Name
| Foo
|- class="selected"
! Age
| 24
|- class="unselected"
! <u>Height</u>
| 6'
|}
__NEXT__
table w/ blocks
__H__
<table>
  <tr>
    <td align=center>
      <p>Paragraph 1</p>
      <p>Paragraph 2</p>
    </td>
  </tr>
</table>
__W__
{|
| align="center" |
Paragraph 1

Paragraph 2
|}
__NEXT__
strip empty aname
__H__
<html><a name="thing"></a> some text</html>
__W__
some text
__NEXT__
wiki link (text == title)
__H__
<html><a href="/wiki/Some_wiki_page">Some wiki page</a></html>
__W__
[[Some wiki page]]
__NEXT__
wiki link (text case != title case)
__H__
<html><a href="/wiki/Another_page">another page</a></html>
__W__
[[another page]]
__NEXT__
wiki link (text != title)
__H__
<html><a href="/wiki/Another_page">some text</a></html>
__W__
[[Another page|some text]]
__NEXT__
external links
__H__
<html><a href="http://www.test.com">thing</a></html>
__W__
[http://www.test.com thing]
__NEXT__
external links (rel2abs)
__H__
<html><a href="thing.html">thing</a></html>
__W__
[http://www.test.com/thing.html thing]
__NEXT__
strip urlexpansion
__H__
<html><a href="http://www.google.com">Google</a> <span class=" urlexpansion ">(http://www.google.com)</span></html>
__W__
[http://www.google.com Google]
__NEXT__
strip printfooter
__H__
<html><div class="printfooter">Retrieved from blah blah</div></html>
__W__

__NEXT__
strip catlinks
__H__
<html><div id="catlinks"><p>Categories: ...</p></div></html>
__W__

__NEXT__
strip editsection
__H__
<html>This is <div class="editsection"><a href="?action=edit&section=1">edit</a></div> great</html>
__W__
This is

great
__NEXT__
escape bracketed urls
__H__
<html><p>This is a text node with what looks like an ext. link [http://example.org].</p></html>
__W__
This is a text node with what looks like an ext. link <nowiki>[http://example.org]</nowiki>.
__NEXT__
line with vertical bar
__H__
<html><p>| a line with a vertical bar</p></html>
__W__
<nowiki>| a line with a vertical bar</nowiki>
__NEXT__
line that starts with a bang
__H__
<html><p>! a line that starts with a bang</p></html>
__W__
<nowiki>! a line that starts with a bang</nowiki>
__NEXT__
line that looks like a section
__H__
<html><p>= a line that looks like a section</p></html>
__W__
<nowiki>= a line that looks like a section</nowiki>
__NEXT__
pre-many (bug #14527)
__H__
<html><pre>preformatted text

with spaces

should produce only one

pre-block</pre></html>
__W__
 preformatted text
 
 with spaces
 
 should produce only one
 
 pre-block
__NEXT__
pre following pre
__H__
<html><pre>preformatted text</pre>
<pre>more preformatted text</pre>
<pre>once again</pre></html>
__W__
 preformatted text

 more preformatted text

 once again
__NEXT__
preserve ::preserve_bold(1)
__H__
<b>hello</b>
__W__
<b>hello</b>
__NEXT__
hr under td
__H__
<table><tr><td><hr></td></tr></table>
__W__
{|
|
----
|}
__NEXT__
img alt
__H__
<img src="thing.gif" alt="Just a test" />
__W__
[[Image:thing.gif|Just a test]]
__NEXT__
no preserve templates ::preserve_templates(0)
__H__
{{template}}
__W__
<nowiki>{{template}}</nowiki>
__NEXT__
preserve templates ::preserve_templates(1)
{{template}}
__W__
{{template}}
__NEXT__
no preserve nowiki ::preserve_nowiki(0)
__H__
<nowiki>hey</nowiki>
__W__
hey
__NEXT__
preserve nowiki ::preserve_nowiki(1)
__H__
<nowiki>hey</nowiki>
__W__
<nowiki>hey</nowiki>
__NEXT__
preserve image width
__H__
<img src="thing.jpg" width="200" height="400" alt="The Thing" />
__W__
[[Image:thing.jpg|200px|The Thing]]
__NEXT__
tbody and thead fixes (bug #28402)
__H__
<table border="1">
<colgroup>
<col />
<col />
<col />
</colgroup>
<thead>
<tr>
<th>heading col 1</th>
<th>heading col 2</th>
<th>heading last col</th>
</tr>
</thead>
<tbody>
<tr>
<td>data first col first row</td>
<td>data c2 r1</td>
<td>data c3 r1</td>
</tr>
<tr>
<td>data c1 r2</td>
<td>data c2 r2</td>
<td>data c3 r2</td>
</tr>
<tr>
<td>data c1 r3</td>
<td>data c2 r3</td>
<td>data c3 r3</td>
</tr>
</tbody>
</table>
__W__
{| border="1"
|-
! heading col 1
! heading col 2
! heading last col
|-
| data first col first row
| data c2 r1
| data c3 r1
|-
| data c1 r2
| data c2 r2
| data c3 r2
|-
| data c1 r3
| data c2 r3
| data c3 r3
|}
__NEXT__
don't pad headings ::pad_headings(0)
__H__
<h2>Heading</h2>
__W__
==Heading==
__NEXT__
table with zeros
__H__
<table>
<tr><td>0</td></tr>
<tr><td>1</td></tr>
<tr><td>0</td></tr>
<tr><td>1</td></tr>
</table>
__W__
{|
| 0
|-
| 1
|-
| 0
|-
| 1
|}
__NEXT__
(bug #40845) internal links, without wiki_uri
__H__
<a href='class_browser.html'>Class Browser</a>
__W__
[http://www.test.com/class_browser.html Class Browser]
__NEXT__
(bug #40845) internal links, with wiki_uri=base_uri ::wiki_uri('http://www.test.com/')
__H__
<a href='class_browser.html'>Class Browser</a>
__W__
[[class browser.html|Class Browser]]
__NEXT__
(bug #40845) broken links with anchors, without wiki_uri
__H__
<a href='#Adding'>adding</a>
__W__
[http://www.test.com#Adding adding]
__NEXT__
(bug #40845) links with anchors, with wiki_uri ::wiki_uri('http://www.test.com/') ::TODO('wiki_uri not working with an ending slash')
__H__
<a href='#Adding'>adding</a>
__W__
[[#Adding|adding]]
__NEXT__
(bug #24745) font/span weirdness ::TODO("HTML::WikiConverter::Normalizer doesn't handle this yet");
__H__
<p><span style='font-size:40.0pt; font-family:"ArialNarrow"'>The Test Header</span></p>
__W__
<span style="font-size:40pt; font-family:ArialNarrow">The Test Header</span>
__NEXT__
(bug #29342) Tag attributes with 0 ::TODO("this is actually an H::WC-specific bug")
__H__
<table cellspacing="0" cellpadding="3" border="1">
<tr><td>Hello</td><td>World</td></tr>
</table>
__W__
{| border="1" cellpadding="3" cellspacing="0"
| Hello
| World
|}
