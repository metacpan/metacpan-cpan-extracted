local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'XWiki', wiki_uri => 'http://www.test.com/wiki/' );
close DATA;

__DATA__
external link
__H__
<p><a href="http://example.com">http://example.com</a></p>
__W__
http://example.com
__NEXT__
wrap in html
__H__
<a href="http://google.com">GOOGLE</a><br/>
NewLine
__W__
[GOOGLE>http://google.com]
 NewLine
__NEXT__
bold
__H__
<html><b>bold</b></html>
__W__
*bold*
__NEXT__
italics
__H__
<html><i>italics</i></html>
__W__
~~italics~~
__NEXT__
bold and italics
__H__
<html><b>bold</b> and <i>italics</i></html>
__W__
*bold* and ~~italics~~
__NEXT__
bold-italics nested
__H__
<html><b><i>bold-italics</i> nested</b></html>
__W__
*~~bold-italics~~ nested*
__NEXT__
strong
__H__
<html><strong>strong</strong></html>
__W__
*strong*
__NEXT__
emphasized
__H__
<html><em>emphasized</em></html>
__W__
~~emphasized~~
__NEXT__
underlined
__H__
<html><u>underlined</u></html>
__W__
underlined
__NEXT__
strikethrough
__H__
<html><s>strike</s></html>
__W__
--strike--
__NEXT__
deleted
__H__
<html><del>deleted text</del></html>
__W__
--deleted text--
__NEXT__
inserted
__H__
<html><ins>inserted</ins></html>
__W__
inserted
__NEXT__
span
__H__
<html><span>span</span></html>
__W__
span
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
~~phrasals in one line~~
__NEXT__
paragrahs
__H__
<html><p>first</p><p>second</p></html>
__W__
first

second
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
**1. i
** b
* 2<dl><dd>indented</dd></dl>
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
stuff
stuff two
__NEXT__
div
__H__
<html><div>thing</div></html>
__W__
thing
__NEXT__
sub
__H__
<html><p>H<sub>2</sub>O</p></html>
__W__
H2O
__NEXT__
sup
__H__
<html><p>x<sup>2</sup></p></html>
__W__
x2
__NEXT__
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
{code}$name = 'stan';{code}
__NEXT__
pre
__H__
<html><pre>this
  is
    preformatted
      text</pre></html>
__W__
<pre>{pre}this
  is
    preformatted
      text{/pre}</pre>
__NEXT__
indent
__H__
<html><dl><dd>indented text</dd></dl></html>
__W__
<dl><dd>indented text</dd></dl>
__NEXT__
nested indent
__H__
<html><dl><dd>stuff<dl><dd>double-indented</dd></dl></dd></dl></html>
__W__
<dl><dd>stuff<dl><dd>double-indented</dd></dl></dd></dl>
__NEXT__
h1
__H__
<h1>h1</h1>
__W__
1 h1
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
1.1 h2
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
1.1.1 h3
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
1.1.1.1 h4
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
1.1.1.1.1 h5
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
1.1.1.1.1.1 h6
__NEXT__
table
__H__
<table>
  <tr>
    <th> Name </th> <td> David </td>
  </tr>
  <tr>
    <th> Age </th> <td> 24 </td>
  </tr>
  <tr>
    <th> Height </th> <td> 6' </td>
  </tr>
</table>
__W__
{table}
 Name  |  David
 Age  |  24
 Height  |  6'
{table}
__NEXT__
strip empty aname
__H__
<html><a name="thing"></a>some text</html>
__W__
some text
__NEXT__
wiki link (text == title)
__H__
<html><a href="/wiki/Some_wiki_page">Some wiki page</a></html>
__W__
[Some wiki page|Main.Some_wiki_page]
__NEXT__
wiki link (text case != title case)
__H__
<html><a href="/wiki/Another_page">another page</a></html>
__W__
[another page|Main.Another_page]
__NEXT__
wiki link (text != title)
__H__
<html><a href="/wiki/Another_page">some text</a></html>
__W__
[some text|Main.Another_page]
__NEXT__
external links
__H__
<html><a href="http://www.test.com">thing</a></html>
__W__
[thing>http://www.test.com]
__NEXT__
external links (rel2abs)
__H__
<html><a href="thing.html">thing</a></html>
__W__
[thing>http://www.test.com/thing.html]
__NEXT__
strip urlexpansion
__H__
<html><a href="http://www.google.com">Google</a> <span class=" urlexpansion ">(http://www.google.com)</span></html>
__W__
[Google>http://www.google.com] (http://www.google.com)
