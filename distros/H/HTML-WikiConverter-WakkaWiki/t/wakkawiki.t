local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'WakkaWiki' );
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
	- one
	- two
	- three
__NEXT__
ol
__H__
<ol>
  <li>one
  <li>two
  <li>three
</ol>
__W__
	1) one
	2) two
	3) three
__NEXT__
nested list
__H__
<ul>
  <li> one
    <ol> <li>1 <li>2 <li>3 </ol>
  </li>
  <li> two
    <ol> <li>1 <li>2 <li>3 </ol>
  </li>
  <li>three
</ul>  
__W__
	- one
		1) 1
		2) 2
		3) 3
	- two
		1) 1
		2) 2
		3) 3
	- three
__NEXT__
image
__H__
<img src="http://www.test.com/image.png" />
__W__
""<img src="http://www.test.com/image.png" />""
__NEXT__
image (w/ attrs)
__H__
<img src="http://www.test.com/image.png" alt="my image" width="50" height="45" />
__W__
""<img src="http://www.test.com/image.png" alt="my image" width="50" height="45" />""
__NEXT__
image (strip attrs)
__H__
<img src="http://www.test.com/image.png" alt="my image" width="50" height="45" onclick="alert('hello')" />
__W__
""<img src="http://www.test.com/image.png" alt="my image" width="50" height="45" />""
__NEXT__
image (escape attrs)
__H__
<img src="http://www.test.com/image.png" alt="my < thing" />
__W__
""<img src="http://www.test.com/image.png" alt="my &lt; thing" />""
