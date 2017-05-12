local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'TikiWiki', wiki_uri => 'http://www.test.com/wiki/' );
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
''italic''
__NEXT__
em
__H__
<em>em</em>
__W__
''em''
__NEXT__
center
__H__
<center>center</center>
__W__
::center::
__NEXT__
code
__H__
<code>code</code>
__W__
-+code+-
__NEXT__
tt
__H__
<tt>tt</tt>
__W__
-+tt+-
__NEXT__
underline
__H__
<u>underline</u>
__W__
===underline===
__NEXT__
internal link
__H__
<a href="http://www.test.com/wiki/Sandbox">Sandbox</a>
__W__
((Sandbox))
__NEXT__
internal link (camel case)
__H__
<a href="http://www.test.com/wiki/SandBox">SandBox</a>
__W__
SandBox
__NEXT__
internal link (alt text)
__H__
<a href="http://www.test.com/wiki/Sandbox">my sandbox</a>
__W__
((Sandbox|my sandbox))
__NEXT__
external link
__H__
<a href="http://www.google.com">http://www.google.com</a>
__W__
[http://www.google.com]
__NEXT__
external link (alt text)
__H__
<a href="http://www.google.com">Google</a>
__W__
[http://www.google.com|Google]
__NEXT__
external link (mailto)
__H__
<a href="mailto:test@test.com">Test User</a>
__W__
[mailto:test@test.com|Test User]
__NEXT__
image
__H__
<img src="http://www.test.com/image.png" />
__W__
{img src=http://www.test.com/image.png}
__NEXT__
image (w/ attrs)
__H__
<img src="http://www.test.com/image.png" width="10" height="20" />
__W__
{img src=http://www.test.com/image.png width=10 height=20}
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
# one
# two
# three
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
      <li>3.c
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
** 3.c
__NEXT__
list (nested ul/ol)
__H__
<ul>
  <li>one
    <ol><li>1<li>2<li>3</ol>
  <li>two
  <li>three
    <ol><li>1<li>2<li>3</ol>
  </li>
</ul>
__W__
* one
## 1
## 2
## 3
* two
* three
## 1
## 2
## 3
__NEXT__
dl/dt/dd
__H__
<dl><dt>term</dt><dd>definition</dd></dl>
__W__
; term : definition
