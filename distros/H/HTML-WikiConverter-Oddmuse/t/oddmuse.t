local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'Oddmuse', wiki_uri => 'http://www.test.com/wiki/', camel_case => 1 );
close DATA;

__DATA__
bold
__H__
<b>bold</b>
__W__
*bold*
__NEXT__
strong
__H__
<strong>strong</strong>
__W__
*strong*
__NEXT__
italic
__H__
<i>italic</i>
__W__
/italic/
__NEXT__
em
__H__
<em>em</em>
__W__
~em~
__NEXT__
underline
__H__
<u>underline</u>
__W__
_underline_
__NEXT__
image
__H__
<img src="http://www.test.com/image.png" />
__W__
http://www.test.com/image.png
__NEXT__
external link (free link)
__H__
<a href="http://www.google.com">http://www.google.com</a>
__W__
http://www.google.com
__NEXT__
external link (alt text)
__H__
<a href="http://www.google.com">Google</a>
__W__
[http://www.google.com Google]
__NEXT__
internal link
__H__
<a href="http://www.test.com/wiki/Markup_Extension">Markup Extension</a>
__W__
[[Markup Extension]]
__NEXT__
internal link (alt text)
__H__
<a href="http://www.test.com/wiki/Markup_Extension">markup ext</a>
__W__
[[Markup Extension|markup ext]]
__NEXT__
internal link (camel case)
__H__
<a href="http://www.test.com/wiki/CamelCaseLink">CamelCaseLink</a>
__W__
CamelCaseLink
__NEXT__
table
__H__
<table>
<tr><th>foo</th><th>bar</th><th>baz</th></tr>
<tr><td>one</td><td>two</td><td>three</td></tr>
<tr><td>1</td><td>2</td><td>3</td></tr>
</table>
__W__
||foo ||bar ||baz ||
||one ||two ||three ||
||1 ||2 ||3 ||
__NEXT__
table (align)
__H__
<table>
<tr><th align="left">foo</th><th align="center">bar</th><th align="right">baz</th></tr>
<tr><td align="right">one</td><td align="left">two</td><td align="center">three</td></tr>
<tr><td align="center">1</td><td align="right">2</td><td align="left">3</td></tr>
</table>
__W__
||foo || bar || baz||
|| one||two || three ||
|| 1 || 2||3 ||
__NEXT__
table (colspan)
__H__
<table>
<tr><th colspan="2" align="left">foo</th><th align="center">bar</th></tr>
<tr><td align="right">one</td><td align="left">two</td><td align="center">three</td></tr>
<tr><td colspan="3" align="center">1</td></tr>
</table>
__W__
||||foo || bar ||
|| one||two || three ||
|||||| 1 ||
__NEXT__
list (ul)
__H__
<ul>
  <li>one
  <li>two
  <li>three
</ul>
__W__
* one
* two
* three
__NEXT__
list (ol)
__H__
<ol>
  <li>one
  <li>two
  <li>three
</ol>
__W__
* one
* two
* three
__NEXT__
list (nested ul/ul)
__H__
<ul>
  <li>1
    <ul>
      <li>1.a
      <li>1.b
    </ul>
  </li>
  <li>2
  <li>3
    <ul>
      <li>3.a
      <li>3.b
    </ul>
  </li>
</ul>
__W__
* 1
** 1.a
** 1.b
* 2
* 3
** 3.a
** 3.b
__NEXT__
list (nested ul/ol)
__H__
<ul>
  <li>1
    <ol>
      <li>1.a
      <li>1.b
    </ol>
  </li>
  <li>2
  <li>3
    <ol>
      <li>3.a
      <li>3.b
    </ol>
  </li>
</ul>
__W__
* 1
** 1.a
** 1.b
* 2
* 3
** 3.a
** 3.b
__NEXT__
list (nested ol/ul)
__H__
<ol>
  <li>1
    <ul>
      <li>1.a
      <li>1.b
    </ul>
  </li>
  <li>2
  <li>3
    <ul>
      <li>3.a
      <li>3.b
    </ul>
  </li>
</ol>
__W__
* 1
** 1.a
** 1.b
* 2
* 3
** 3.a
** 3.b
__NEXT__
h1..h6
__H__
<h1>1</h1>
<h2>2</h2>
<h3>3</h3>
<h4>4</h4>
<h5>5</h5>
<h6>6</h6>
__W__
=1=

==2==

===3===

====4====

=====5=====

======6======
