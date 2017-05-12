local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'MoinMoin' );
close DATA;

__DATA__
add space between [[BR]] and URL
__H__
<html><a href="http://example.com">http://example.com</a><br /></html>
__W__
http://example.com [[BR]]
__NEXT__
wrap in html
__H__
<a href="http://google.com">GOOGLE</a><br/>
NewLine
__W__
[[http://google.com|GOOGLE]][[BR]] NewLine
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
<html><i><b>bold-italics</b> nested</i></html>
__W__
'''''bold-italics''' nested''
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
<html><u>text</u></html>
__W__
__text__
__NEXT__
one-line phrasals
__H__
<html><i>phrasals
in one line</i></html>
__W__
''phrasals in one line''
__NEXT__
sup
__H__
<html>x<sup>2</sup></html>
__W__
x^2^
__NEXT__
sub
__H__
<html>H<sub>2</sub>O</html>
__W__
H,,2,,O
__NEXT__
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
`$name = 'stan';`
__NEXT__
tt
__H__
<html><tt>tt text</tt></html>
__W__
`tt text`
__NEXT__
small
__H__
<html>some <small>small</small> text</html>
__W__
some ~-small-~ text
__NEXT__
big
__H__
<html>some <big>big</big> text</html>
__W__
some ~+big+~ text
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
    * 1a
    * 1b
  * 2
__NEXT__
nested lists (different types)
__H__
<html><ul><li>1<ul><li>a<ol><li>i</li></ol></li><li>b</li></ul></li><li>2</li></ul></html>
__W__
  * 1
    * a
      1. i
    * b
  * 2
__NEXT__
hr
__H__
<html><hr /></html>
__W__
----
__NEXT__
pre
__H__
<html><pre>this
  is
    preformatted
      text</pre></html>
__W__
{{{
this
  is
    preformatted
      text
}}}
__NEXT__
h1
__H__
<h1>h1</h1>
__W__
= h1 =
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
== h2 ==
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
=== h3 ===
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
==== h4 ====
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
===== h5 =====
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
====== h6 ======
__NEXT__
img
__H__
<html><img src="thing.gif" /></html>
__W__
http://www.test.com/thing.gif
__NEXT__
external links
__H__
<html><a href="test.html">thing</a></html>
__W__
[[http://www.test.com/test.html|thing]]
__NEXT__
external link (plain)
__H__
<html><a href="http://www.test.com">http://www.test.com</a></html>
__W__
http://www.test.com
__NEXT__
definition list
__H__
<html><dl><dt>cookies</dt><dd>delicious delicacies</dd></dl></html>
__W__
cookies:: delicious delicacies
__NEXT__
simple table
__H__
<html><table><tr><td>name</td><td>david</td></tr></table>
__W__
|| name || david ||
__NEXT__
table w/ attrs
__H__
<html>
  <table bgcolor="white" width="100%">
    <tr>
      <td colspan=2 id="thing">thing</td>
    </tr>
    <tr>
      <td>next</td>
      <td id="crazy">crazy</td>
    </tr>
  </table>
</html>
__W__
||<-2 tablestyle="width:100%; background-color:white" id="thing"> thing ||
|| next ||<id="crazy"> crazy ||
__NEXT__
anchors with content (bug #29347) ::enable_anchor_macro(1)
__H__
<a id="top">This is the top of the page</a>
__W__
<<Anchor(top)>>
This is the top of the page
__NEXT__
anchors (bug #17813) ::enable_anchor_macro(1)
__H__
<a id="id-top" name="name-top"></a>

<p><a href="#href-top">Top of page</a></p>
__W__
<<Anchor(id-top)>>

[[#href-top|Top of page]]
