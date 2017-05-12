local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'WikkaWiki' );
close DATA;

__DATA__
h1
__H__
<h1>one</h1>
__W__
====== one ======
__NEXT__
h2
__H__
<h2>two</h2>
__W__
===== two =====
__NEXT__
h3
__H__
<h3>three</h3>
__W__
==== three ====
__NEXT__
h4
__H__
<h4>four</h4>
__W__
=== four ===
__NEXT__
h5
__H__
<h5>five</h5>
__W__
== five ==
__NEXT__
h6
__H__
<h6>six</h6>
__W__
== six ==
__NEXT__
bold
__H__
<b>bold text</b>
__W__
**bold text**
__NEXT__
strong
__H__
<strong>strong text</strong>
__W__
**strong text**
__NEXT__
italic
__H__
<i>italic text</i>
__W__
//italic text//
__NEXT__
emphasized
__H__
<em>em text</em>
__W__
//em text//
__NEXT__
ul
__H__
<ul>
  <li>one
  <li>two
  <li>three
</ul>
__W__
~- one
~- two
~- three
__NEXT__
ul (nested)
__H__
<ul>
  <li>one
    <ul>
      <li>one.one</li>
      <li>one.two</li>
      <li>one.three</li>
    </ul>
  </li>
  <li>two
    <ul>
      <li>two.one</li>
      <li>two.two</li>
    </ul>
  </li>
  <li>three</li>
  <li>four</li>
</ul>
__W__
~- one
~~- one.one
~~- one.two
~~- one.three
~- two
~~- two.one
~~- two.two
~- three
~- four
__NEXT__
ol
__H__
<ol>
  <li>one
  <li>two
  <li>three
</ol>
__W__
~1) one
~1) two
~1) three
__NEXT__
ol (nested)
__H__
<ol>
  <li>one
    <ol>
      <li>one.one</li>
      <li>one.two</li>
      <li>one.three</li>
    </ol>
  </li>
  <li>two
    <ol>
      <li>two.one</li>
      <li>two.two</li>
    </ol>
  </li>
  <li>three</li>
  <li>four</li>
</ol>
__W__
~1) one
~~1) one.one
~~1) one.two
~~1) one.three
~1) two
~~1) two.one
~~1) two.two
~1) three
~1) four
__NEXT__
ul/ol (nested)
__H__
<ul>
  <li>one
    <ol>
      <li>one.one</li>
      <li>one.two</li>
      <li>one.three</li>
    </ol>
  </li>
  <li>two
    <ol>
      <li>two.one</li>
      <li>two.two</li>
    </ol>
  </li>
  <li>three</li>
  <li>four</li>
</ul>
__W__
~- one
~~1) one.one
~~1) one.two
~~1) one.three
~- two
~~1) two.one
~~1) two.two
~- three
~- four
__NEXT__
table
__H__
<table border="1" class="thingy">
  <tr>
    <td>one</td>
    <td><em>two</em></td>
    <td>three</td>
  </tr>
  <tr>
    <td>four</td>
    <td>five</td>
    <td><b>six</b></td>
  </tr>
</table>
__W__
|| one || //two// || three ||
|| four || five || **six** ||
__NEXT__
image (internal)
__H__
<img src="images/logo.png" alt="Logo" title="Our logo" />
__W__
{{image alt="Logo" title="Our logo" src="images/logo.png"}}
__NEXT__
image (external)
__H__
<img src="http://www.example.com/logo.png" alt="Logo" title="Example logo" />
__W__
{{image alt="Logo" title="Example logo" src="http://www.example.com/logo.png"}}
