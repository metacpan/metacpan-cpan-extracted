local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'UseMod' );
close DATA;

__DATA__
line break
__H__
<html><p>line 1<br/>line 2</p></html>
__W__
line 1<br>line 2
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
### i
** b
* 2
:: indented
__NEXT__
hr
__H__
<html><hr /></html>
__W__
----
__NEXT__
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
<tt>$name = 'stan';</tt>
__NEXT__
tt
__H__
<html><tt>tt text</tt></html>
__W__
<tt>tt text</tt>
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
definition list
__H__
<html><dl><dt>term</dt><dd>definition</dd></dl></html>
__W__
; term : definition
