local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'PmWiki' );
close DATA;

__DATA__
aname
__H__
<h2><a name="introduction">Introduction</a></h2>
__W__
!! [[#introduction]]Introduction
__NEXT__
aname w/ content
__H__
<h2><a name="intro">Introduction <b>stuff</b></a></h2>
__W__
!! [[#intro]]Introduction '''stuff'''
__NEXT__
aname w/ href
__H__
<h2><a name="intro" href="http://www.google.com">Google</a></h2>
__W__
!! [[#intro]][[http://www.google.com | Google]]
__NEXT__
ext. link
__H__
<a href="http://www.google.com">http://www.google.com</a>
__W__
http://www.google.com
__NEXT__
ext. link w/ alt text
__H__
<a href="http://www.google.com">Google</a>
__W__
[[http://www.google.com | Google]]
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
deleted
__H__
<html><del>deleted text</del></html>
__W__
{-deleted text-}
__NEXT__
inserted
__H__
<html><ins>inserted text</ins></html>
__W__
{+inserted text+}
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
<html><ul><li>1<ul><li>a<ol><li>i</li></ol></li><li>b</li></ul></li><li>2<dl><dt>foo</dt><dd>bar</dd></dl></li></ul></html>
__W__
* 1
** a
### i
** b
* 2
:: foo: bar
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
stuff \\
stuff two
__NEXT__
sub
__H__
<html><p>H<sub>2</sub>O</p></html>
__W__
H'_2_'O
__NEXT__
sup
__H__
<html><p>x<sup>2</sup></p></html>
__W__
x'^2^'
__NEXT__
small
__H__
<html><small>small text</small></html>
__W__
'-small text-'
__NEXT__
big
__H__
<html><big>big text</big></html>
__W__
'+big text+'
__NEXT__
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
@@$name = 'stan';@@
__NEXT__
tt
__H__
<html><tt>tt text</tt></html>
__W__
@@tt text@@
__NEXT__
indent
__H__
<html><blockquote>indented text</blockquote></html>
__W__
->indented text
__NEXT__
nested indent
__H__
<html><blockquote>stuff 
  <blockquote>double-indented stuff</blockquote>
</blockquote></html>
__W__
->stuff
-->double-indented stuff
__NEXT__
h1
__H__
<h1>h1</h1>
__W__
! h1
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
!! h2
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
!!! h3
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
!!!! h4
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
!!!!! h5
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
!!!!!! h6
__NEXT__
<html>
__H__
<table border="1" width="50%" onclick="alert('hello')">
  <tr><th>First</th><th>Last</th></tr>
  <tr><td>Barney</td><td>Rubble</td></tr>
  <tr><td>Foo</td><td>Bar</td></tr>
</table>
</html>
__W__
|| border="1" width="50%"
||!First ||!Last ||
||Barney ||Rubble ||
||Foo ||Bar ||
__NEXT__
table w/ colspan
__H__
<table align='center' border='1' width='50%'>
<tr>
  <th>Table</th>
  <th>Heading</th>
  <th>Example</th>
</tr>
<tr>
  <th align='left'>Left</th>
  <td align='center'>Center</td>
  <td align='right'>Right</td>
</tr>
<tr>
  <td align='left'> A </td>
  <th align='center'> B </th>
  <td align='right'> C </td>
</tr>
<tr>
  <td> </td>
  <td align='center'>single</td>
  <td> </td>
</tr>
<tr>
  <td> </td>
  <td align='center' colspan='2'>multi span</td>
</tr>
</table>
__W__
|| border="1" width="50%" align="center"
||!Table ||!Heading ||!Example ||
||!Left || Center || Right||
||A ||! B || C||
|| || single || ||
|| || multi span ||||
__NEXT__
pre
__H__
<html><pre>this
  is pre-
     formatted
  text</pre></html>
__W__
 this
   is pre-
      formatted
   text
__NEXT__
pre w/ formatting
__H__
<html><pre>this
  is pre-
     formatted tex<sup>t</sup>
        with <b>special</b> <del>formatting</del></pre></html>
__W__
 this
   is pre-
      formatted tex'^t^'
         with '''special''' {-formatting-}
__NEXT__
br on separate lines (bug #18287)
__H__
line1<br>
line2
__W__
line1 \\
line2
