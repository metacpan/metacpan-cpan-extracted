use HTML::WikiConverter;

local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'Markdown', wiki_uri => 'http://www.test.com/wiki/' );
close DATA;

__DATA__
unordered list
__H__
<ul>
<li>one</li>
<li>two</li>
<li>three</li>
</ul>
__W__
* one
* two
* three
__NEXT__
ordered list
__H__
<ol>
<li>one</li>
<li>two</li>
<li>three</li>
</ol>
__W__
1. one
2. two
3. three
__NEXT__
blockquote
__H__
<blockquote>text</blockquote>
__W__
> text
__NEXT__
nested blockquote
__H__
<blockquote>text<blockquote>text2</blockquote></blockquote>
__W__
> text
>
> > text2
__NEXT__
nested blockquote cont'd
__H__
<blockquote>This is the first level of quoting.
<blockquote>This is nested blockquote.</blockquote>
<p>Back to the first level.</p></blockquote>
__W__
> This is the first level of quoting.
>
> > This is nested blockquote.
>
> Back to the first level.
__NEXT__
h1
__H__
<h1>text</h1>
__W__
# text
__NEXT__
bold
__H__
<b>bold text</b>
__W__
**bold text**
__NEXT__
italics
__H__
<i>text</i>
__W__
_text_
__NEXT__
strong
__H__
<strong>text</strong>
__W__
**text**
__NEXT__
em
__H__
<em>text</em>
__W__
_text_
__NEXT__
inline link ::link_style('inline')
__H__
<p>It's called <a href="http://en.wikipedia.org/wiki/Long-term_potentiation" title="Long-term potentiation">LTP</a>.</p>
__W__
It's called [LTP](http://en.wikipedia.org/wiki/Long-term_potentiation "Long-term potentiation").
__NEXT__
reference link ::link_style('reference')
__H__
<p>It's called <a href="http://en.wikipedia.org/wiki/Long-term_potentiation" title="Long-term potentiation">LTP</a>.</p>
__W__
It's called [LTP][1].

  [1]: http://en.wikipedia.org/wiki/Long-term_potentiation "Long-term potentiation"
__NEXT__
reference link no title ::link_style('inline')
__H__
<p><a href="http://example.net/">This link</a> has no title attribute.</p>
__W__
[This link](http://example.net/) has no title attribute.
__NEXT__
multi-paragraphs with reference links ::link_style('reference')
__H__
<p>This is a paragraph with a link to <a href="http://google.com">Google</a>.
There's also a link to some other stuff, like <a href="http://digg.com">Digg</a>
and <a href="http://wikipedia.org">Wikipedia</a>.

<p>Here's another paragraph.</p>

<p>This is fun stuff:</p>
<ul>
  <li><a href="http://video.google.com" title="Google Video">Google Video is the best!</a></li>
  <li><a href="http://www.example.org" title="Examples">Example.org is a close second</a></li>
</ul>
__W__
This is a paragraph with a link to [Google][1]. There's also a link to some other stuff, like [Digg][2] and [Wikipedia][3].

Here's another paragraph.

This is fun stuff:

* [Google Video is the best!][4]
* [Example.org is a close second][5]

  [1]: http://google.com
  [2]: http://digg.com
  [3]: http://wikipedia.org
  [4]: http://video.google.com "Google Video"
  [5]: http://www.example.org "Examples"
__NEXT__
code
__H__
<code>printf()</code>
__W__
`printf()`
__NEXT__
inline image ::image_style('inline')
__H__
<img src="http://example.com/delete.png" alt="Delete" title="Click to delete" />
__W__
![Delete](http://example.com/delete.png "Click to delete")
__NEXT__
reference image ::image_style('reference')
__H__
<img src="http://example.com/delete.png" alt="Delete" title="Click to delete" />
__W__
![Delete][1]

  [1]: http://example.com/delete.png "Click to delete"
__NEXT__
mixed inline images and links ::image_style('inline') ::link_style('inline')
__H__
<p>Link goes <a href="http://example.com" title="Link to example.com">Here</a>.
Image goes below:</p>

<p><img src="http://example.com/logo.png" alt="Logo"/></p>
__W__
Link goes [Here](http://example.com "Link to example.com"). Image goes below:

![Logo](http://example.com/logo.png)
__NEXT__
mixed reference images and links ::image_style('reference') ::link_style('reference')
__H__
<p>This is a paragraph with a link to <a href="http://google.com">Google</a>.  There's also a link to some other stuff, like <a href="http://digg.com">Digg</a> and <a href="http://wikipedia.org">Wikipedia</a>. <img src="http://example.com/delete.png" alt="Delete" title="Click to delete" /></p>
__W__
This is a paragraph with a link to [Google][1]. There's also a link to some other stuff, like [Digg][2] and [Wikipedia][3]. ![Delete][4]

  [1]: http://google.com
  [2]: http://digg.com
  [3]: http://wikipedia.org
  [4]: http://example.com/delete.png "Click to delete"
__NEXT__
fallback to tag if image has dimensions ::image_tag_fallback(1)
__H__
<img src="http://example.com/origin.png" alt="Thingy" title="The title" width="100" />
__W__
<img src="http://example.com/origin.png" width="100" alt="Thingy" title="The title" />
__NEXT__
no fallback ::image_tag_fallback(0) ::image_style('inline')
__H__
<img src="http://example.com/origin.png" alt="Thingy" title="The title" width="100" />
__W__
![Thingy](http://example.com/origin.png "The title")
__NEXT__
automatic links
__H__
<a href="http://example.com">http://example.com</a>
__W__
<http://example.com>
__NEXT__
escapes
__H__
<p>a backslash \</p>
<p>a weird combo ![</p>
<p>a curly brace {</p>
<p>1992. not a list item!</p>
__W__
a backslash \\

a weird combo \![

a curly brace \{

1992\. not a list item!
__NEXT__
multi-headers
__H__
<h1>One</h1>
<h2>Two</h2>
<h3>Three</h3>
__W__
# One

## Two

### Three
__NEXT__
one-dot lists ::ordered_list_style('one-dot')
__H__
<ol>
<li>one</li>
<li>two</li>
<li>three</li>
</ol>
__W__
1. one
1. two
1. three
__NEXT__
plus lists ::unordered_list_style('plus')
__H__
<ul>
<li>one</li>
<li>two</li>
<li>three</li>
</ul>
__W__
+ one
+ two
+ three
__NEXT__
dash lists ::unordered_list_style('dash')
__H__
<ul>
<li>one</li>
<li>two</li>
<li>three</li>
</ul>
__W__
- one
- two
- three
__NEXT__
forced inline anchors ::force_inline_anchor_links(1) ::unordered_list_style('asterisk')
__H__
<ul>
  <li><a href="#overview">Overview</a>
    <ul>
      <li><a href="#philosophy">Philosophy</a></li>
      <li><a href="#html">Inline HTML</a></li>
    </ul>
  </li>
</ul>
__W__
* [Overview](#overview)
  * [Philosophy](#philosophy)
  * [Inline HTML](#html)
__NEXT__
table
__H__
<table>
  <caption>My favorite animals</caption>
  <tr>
    <th>Animal</th>
    <th>Region</th>
    <th>Physical traits</th>
    <th>Food</th>
  </tr>
  <tr>
    <td>Pacman frog</td>
    <td>Gran Chaco (Argentina)</td>
    <td>Half mouth, half stomach (quite literally!)</td>
    <td>Crickets, fish, etc.</td>
  </tr>
</table>
__W__
<table>
<caption>My favorite animals</caption>
<tr>
<th>Animal</th>
<th>Region</th>
<th>Physical traits</th>
<th>Food</th>
</tr>
<tr>
<td>Pacman frog</td>
<td>Gran Chaco (Argentina)</td>
<td>Half mouth, half stomach (quite literally!)</td>
<td>Crickets, fish, etc.</td>
</tr>
</table>
__NEXT__
setext header ::header_style('setext')
__H__
<h1>header1</h1>
<p>Fun stuff here.</p>
<h2>header2</h2>
<p>More fun stuff!</p>
__W__
header1
=======

Fun stuff here.

header2
-------

More fun stuff!
__NEXT__
more complete example ::header_style('atx')
__H__
<h2>Aaron Swartz's html2text</h2>

<p>A handful of people have asked if there's a way to translate Markdown
in reverse — to turn HTML back into Markdown-formatted plain text.
The short answer is yes, by using Aaron Swartz's new version of
<a href="http://www.aaronsw.com/2002/html2text/">html2text</a>:</p>

<blockquote>
  <p>html2text is a Python script that convers a page of HTML into clean,
  easy-to-read plain ASCII. Better yet, that ASCII also happens to be
  valid Markdown (a text-to-HTML format).</p>
</blockquote>

<p>html2text works so well that I'm planning to use it to convert most of
my old Daring Fireball articles (the ones I wrote in raw HTML). It's
worth noting that if you start with a Markdown document, translate it
to HTML, then use html2text to go back to Markdown, it won't give you
the exact same document you started with. That sort of complete
round-trip fidelity simply is not possible, but html2text comes pretty
close.</p>

<p>Also, much like Markdown and SmartyPants, html2text works as a BBEdit
text filter. Simply save a copy in the Unix Filters folder in your
BBEdit Support folder.</p>
__W__
## Aaron Swartz's html2text

A handful of people have asked if there's a way to translate Markdown in reverse — to turn HTML back into Markdown-formatted plain text. The short answer is yes, by using Aaron Swartz's new version of [html2text][1]:

> html2text is a Python script that convers a page of HTML into clean, easy-to-read plain ASCII. Better yet, that ASCII also happens to be valid Markdown (a text-to-HTML format).

html2text works so well that I'm planning to use it to convert most of my old Daring Fireball articles (the ones I wrote in raw HTML). It's worth noting that if you start with a Markdown document, translate it to HTML, then use html2text to go back to Markdown, it won't give you the exact same document you started with. That sort of complete round-trip fidelity simply is not possible, but html2text comes pretty close.

Also, much like Markdown and SmartyPants, html2text works as a BBEdit text filter. Simply save a copy in the Unix Filters folder in your BBEdit Support folder.

  [1]: http://www.aaronsw.com/2002/html2text/
__NEXT__
blockquotes containing only phrasal elements
__H__
<p>Via <a href="http://en.wikipedia.org/wiki/Long-term_potentiation">Wikipedia</a>:</p>
<blockquote>Long-term potentiation is the long-lasting enhancement in communication between two <a href="http://en.wikipedia.org/wiki/Neuron">neurons</a> that lasts from minutes to hours.</blockquote>
<p>Sweet.</p>
__W__
Via [Wikipedia][1]:

> Long-term potentiation is the long-lasting enhancement in communication between two [neurons][2] that lasts from minutes to hours.

Sweet.

  [1]: http://en.wikipedia.org/wiki/Long-term_potentiation
  [2]: http://en.wikipedia.org/wiki/Neuron
__NEXT__
blockquote containing p
__H__
<blockquote><p>shouldn't add a paragraph parent</p></blockquote>
__W__
> shouldn't add a paragraph parent
__NEXT__
__H__
<blockquote>unmarked paragraph <p>another paragraph</p> <p>yet another</p></blockquote>
__W__
> unmarked paragraph
>
> another paragraph
>
> yet another
__NEXT__
code containing backticks (bug #43998)
__H__
<p><code>There is a literal backtick (`) here.</code></p>
__W__
``There is a literal backtick (`) here.``
__NEXT__
amp, lt, gt within code blocks (bug #43996)
__H__
<code>print("a &lt; b") if $c > $d</code>
__W__
`print("a < b") if $c > $d`
__NEXT__
amp, lt, gt within code blocks (bug #43996, example from markdown docs, http://bit.ly/NSrG3)
__H__
<p>I strongly recommend against using any
<code>&lt;blink&gt;</code> tags.</p>

<p>I wish SmartyPants used named entities like <code>&amp;mdash;</code> instead of decimal-encoded entites like <code>&amp;#8212;</code>.</p>
__W__
I strongly recommend against using any `<blink>` tags.

I wish SmartyPants used named entities like `&mdash;` instead of decimal-encoded entites like `&#8212;`.
__NEXT__
escape literal backticks outside of <code> tags
__H__
<p>Hi there, this is a backtick (`).</p>
__W__
Hi there, this is a backtick (\`).
__NEXT__
don't backslash-escape underscores within <code> tags (bug #43993)
__H__
<code>foo _bar_ baz foo_bar</code>
__W__
`foo _bar_ baz foo_bar`
__NEXT__
but do backslash-escape other underscores
__H__
<p>foo _bar_</p>
__W__
foo \_bar\_
__NEXT__
code blocks
__H__
<p>Here's an example:</p>

<code><pre>if( chomp( my $foo = <> ) ) {
  print "entered: $foo\n";
}</pre></code>
__W__
Here's an example:

    if( chomp( my $foo = <> ) ) {
      print "entered: $foo\n";
    }
__NEXT__
code blocks
__H__
<code><pre>if( chomp( my $foo = <> ) ) {
  print "entered: $foo\n";
}</pre></code>
__W__
    if( chomp( my $foo = <> ) ) {
      print "entered: $foo\n";
    }
__NEXT__
DIV
__H__
<div>outer div<div>nested div</div></div>
__W__
outer div

nested div
__NEXT__
PRE
__H__
<pre>this is
	a 
pre
</pre>
__W__
	this is
		a
	pre
__NEXT__
Heading with ID
__H__
<h1 id="linkhere">my heading</h1>
__W__
# my heading	{#linkhere}
__NEXT__
BR
__H__
need to add a new line between here<br /> and here
__W__
need to add a new line between here<br />
 and here

