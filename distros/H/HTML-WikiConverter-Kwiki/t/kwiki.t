local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'Kwiki', wiki_uri => 'http://www.test.com?' );
close DATA;

__DATA__
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
/italics/
__NEXT__
bold and italics
__H__
<html><b>bold</b> and <i>italics</i></html>
__W__
*bold* and /italics/
__NEXT__
bold-italics nested
__H__
<html><i><b>bold-italics</b> nested</i></html>
__W__
/*bold-italics* nested/
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
/emphasized/
__NEXT__
underlined
__H__
<html><u>text</u></html>
__W__
_text_
__NEXT__
strikethrough
__H__
<html><s>text</s></html>
__W__
-text-
__NEXT__
one-line phrasals
__H__
<html><i>phrasals
in one line</i></html>
__W__
/phrasals in one line/
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
<html><ul><li>1<ul><li>a<ol><li>i</li></ol></li><li>b</li></ul></li><li>2</li></ul></html>
__W__
* 1
** a
000 i
** b
* 2
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
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
[=$name = 'stan';]
__NEXT__
tt
__H__
<html><tt>tt text</tt></html>
__W__
[=tt text]
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
h1
__H__
<h1>h1</h1>
__W__
= h1
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
== h2
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
=== h3
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
==== h4
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
===== h5
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
====== h6
__NEXT__
img
__H__
<html><img src="thing.gif" /></html>
__W__
http://www.test.com/thing.gif
__NEXT__
internal links (camel-case)
__H__
<html><a href="?FunTimes">FunTimes</a></html>
__W__
FunTimes
__NEXT__
forced internal links (no camel-case)
__H__
<html><a href="?funTimes">funTimes</a></html>
__W__
[funTimes]
__NEXT__
internal links (camel-case w/ diff. text)
__H__
<html><a href="?FunTimes">click here</a></html>
__W__
[click here http:?FunTimes]
__NEXT__
external links
__H__
<html><a href="test.html">thing</a></html>
__W__
[thing http://www.test.com/test.html]
__NEXT__
external link (plain)
__H__
<html><a href="http://www.test.com">http://www.test.com</a></html>
__W__
http://www.test.com
__NEXT__
simple tables
__H__
<html><table>
<tr><td> </td><td>Dick</td><td>Jane</td></tr>
<tr><td>height</td><td>72"</td><td>65"</td></tr>
<tr><td>weigtht</td><td>130lbs</td><td>150lbs</td></tr>
</table></html>
__W__
|  | Dick | Jane  |
| height | 72" | 65"  |
| weigtht | 130lbs | 150lbs  |
__NEXT__
table w/ caption
__H__
<html><table>
<caption>Caption</caption>
<tr><td> </td><td>Dick</td><td>Jane</td></tr>
<tr><td>height</td><td>72"</td><td>65"</td></tr>
<tr><td>weigtht</td><td>130lbs</td><td>150lbs</td></tr>
</table></html>
__W__
Caption

|  | Dick | Jane  |
| height | 72" | 65"  |
| weigtht | 130lbs | 150lbs  |
