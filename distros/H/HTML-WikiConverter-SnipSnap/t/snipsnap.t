local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'SnipSnap', wiki_uri => 'http://www.test.com/space/' );
close DATA;

__DATA__
bold
__H__
<b>bold</b>
__W__
__bold__
__NEXT__
strong
__H__
<strong>strong</strong>
__W__
__strong__
__NEXT__
italic
__H__
<i>italic</i>
__W__
~~italic~~
__NEXT__
emphasized
__H__
<em>em</em>
__W__
~~em~~
__NEXT__
strike
__H__
<strike>strike</strike>
__W__
--strike--
__NEXT__
internal link
__H__
<a href="http://www.test.com/space/SnipSnap">SnipSnap</a>
__W__
[SnipSnap]
__NEXT__
internal link (alt text)
__H__
<a href="http://www.test.com/space/SnipSnap">link text</a>
__W__
[link text|SnipSnap]
__NEXT__
external link (plain)
__H__
<a href="http://www.google.com">http://www.google.com</a>
__W__
http://www.google.com
__NEXT__
external link (alt text)
__H__
<a href="http://www.google.com">Google</a>
__W__
{link:Google|http://www.google.com}
__NEXT__
citation
__H__
<blockquote>citation</blockquote>
__W__
{quote}citation{quote}
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
1.1 h3
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
1.1 h4
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
1.1 h5
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
1.1 h6
__NEXT__
linebreak
__H__
line<br />break
__W__
line\\break
__NEXT__
hr
__H__
<hr />
__W__
----
__NEXT__
tables
__H__
<table>
<tr><th>name</th><th>age</th><th>city</th></tr>
<tr><td>foo</td><td>57</td><td>hollywood</td></tr>
<tr><td>bar</td><td>45</td><td>rubble</td></tr>
<tr><td>baz</td><td>39</td><td>hammock</td></tr>
</table>
__W__
{table}
name | age | city
foo | 57 | hollywood
bar | 45 | rubble
baz | 39 | hammock
{table}
__NEXT__
ordered list
__H__
<ol>
  <li>one
  <li>two
  <li>three
</ol>
__W__
1. one
1. two
1. three
__NEXT__
<ul>
__H__
  <li>one
  <li>two
  <li>three
</ul>
__W__
* one
* two
* three
__NEXT__
nested list (ol/ul)
__H__
<ol>
  <li>1
    <ul>
      <li>1.a
      <li>1.b
      <li>1.c
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
1. 1
** 1.a
** 1.b
** 1.c
1. 2
1. 3
** 3.a
** 3.b
__NEXT__
nested list (ul/ol)
__H__
<ul>
  <li>1
    <ol>
      <li>1.a
      <li>1.b
        <ol>
          <li>1.c
        </ol>
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
11. 1.a
11. 1.b
111. 1.c
* 2
* 3
11. 3.a
11. 3.b
