local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'PbWiki', wiki_uri => 'http://www.test.com/wiki/' );
close DATA;

__DATA__
bold
__H__
<html><b>bold</b></html>
__W__
**bold**
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
**bold** and ''italics''
__NEXT__
bold-italics nested
__H__
<html><b><i>bold-italics</i> nested</b></html>
__W__
**''bold-italics'' nested**
__NEXT__
strong
__H__
<html><strong>strong</strong></html>
__W__
**strong**
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
__underlined__
__NEXT__
strikethrough
__H__
<html><s>strike</s></html>
__W__
-strike-
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
<html><ul><li>1</li><ul><li>a</li></ul></ul><ol><ol type=a><ol type=I><li>i</li></ol></ol></ol><ul><ul><li>b</li></ul><li>2</li></ul></html>
__W__
* 1
** a

### i

** b
* 2
__NEXT__
hr
__H__
<html><hr /></html>
__W__
---
__NEXT__
center
__H__
<html><center>centered text</center></html>
__W__
<center>centered text</center>
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
strip empty aname
__H__
<html><a name="thing"></a> some text</html>
__W__
some text
__NEXT__
wiki link (text == title)
__H__
<html><a href="/wiki/SomeWikiPage.html">SomeWikiPage</a></html>
__W__
[SomeWikiPage]
__NEXT__
wiki link (text case != title case)
__H__
<html><a href="/wiki/AnotherPage.html">anotherpage</a></html>
__W__
[anotherpage]
__NEXT__
wiki link (text != title)
__H__
<html><a href="/wiki/Another_page.html">some text</a></html>
__W__
[Another_page | some text]
__NEXT__
external links (rel2abs)
__H__
<html><a href="thing.html">thing</a></html>
__W__
[thing]
__NEXT__
pre-many
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