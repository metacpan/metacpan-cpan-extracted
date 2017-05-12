local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'Socialtext', wiki_uri => 'index.cgi?' );
close DATA;

__DATA__
external link
__H__
<p><a href="http://example.com">[http://example.com]</a></p>
__W__
http://example.com
__NEXT__
Don't keep excessive whitespace
__H__
<strong> This thing</strong>
__W__
*This thing*
__NEXT__
Take care with external links
__H__
<img src="http://this.company.com/test/link.jpg">
__W__
http://this.company.com/test/link.jpg
__NEXT__
Leave {{This}} alone
__H__
<p>mark stubs with {{stub}}</p>
__W__
mark stubs with {{stub}}
__NEXT__
quoted
__H__
<p>what happens to 'quoted text'?</p>
__W__
what happens to 'quoted text'?
__NEXT__
doubly quoted
__H__
<p>how about ''doubly quoted''?</p>
__W__
how about ''doubly quoted''?
__NEXT__
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
_italics_
__NEXT__
bold and italics
__H__
<html><b>bold</b> and <i>italics</i></html>
__W__
*bold* and _italics_
__NEXT__
bold-italics nested
__H__
<html><b><i>bold-italics</i> nested</b></html>
__W__
*_bold-italics_ nested*
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
_emphasized_
__NEXT__
underlined
__H__
<html><u>underlined</u></html>
__W__
_underlined_
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
_phrasals in one line_
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
>> indented
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
`$name = 'stan';`
__NEXT__
tt
__H__
<html><tt>tt text</tt></html>
__W__
`tt text`
__NEXT__
pre
__H__
<html><pre>this
  is
    preformatted
      text</pre></html>
__W__
.pre
this
  is
    preformatted
      text
.pre
__NEXT__
indent
__H__
<html><dl><dd>indented text</dd></dl></html>
__W__
> indented text
__NEXT__
nested indent
__H__
<html><dl><dd>stuff<dl><dd>double-indented</dd></dl></dd></dl></html>
__W__
> stuff
>> double-indented
__NEXT__
h1
__H__
<h1>h1</h1>
__W__
^ h1
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
^^ h2
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
^^^ h3
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
^^^^ h4
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
^^^^^ h5
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
^^^^^^ h6
__NEXT__
img
__H__
<html><img src="thing.gif" /></html>
__W__
{image: thing.gif}
__NEXT__
table w/ lists 
__H__
<table cellpadding="1" cellspacing="1" style="border: 1px solid rgb(0, 0, 0); border-collapse: collapse; width: 100%;">
   <tbody>
      <tr>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">This</td>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">IS</td>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">A</td>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">Table</td>
      </tr>
      <tr>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;"> With</td>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">Some</td>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">
           <ul>
              <li>Bullets</li>
              <li>in</li>
              <li>it</li>
           </ul>
        </td>
        <td style="border: 1px solid rgb(0, 0, 0); width: 25%;">
           <ol>
              <li>And</li>
              <li>Also</li>
              <li>Numbers</li>
           </ol>
        </td>
      </tr>
      <tr>
        <td valign="top">This</td>
        <td valign="top">is</td>
        <td valign="top">an</td>
        <td valign="top">extraline</td>
      </tr>
    </tbody>
</table>
__W__
| This | IS | A | Table  |
|  With | Some | * Bullets
* in
* it | # And
# Also
# Numbers |
| This | is | an | extraline  |
__NEXT__
strip empty aname
__H__
<html><a name="thing"></a> some text</html>
__W__
 some text
__NEXT__
wiki link (text == title)
__H__
<html><a href="index.cgi?Some_wiki_page">Some wiki page</a></html>
__W__
[Some wiki page]
__NEXT__
wiki link (text case != title case)
__H__
<html><a href="index.cgi?Another_page">another page</a></html>
__W__
[another page]
__NEXT__
wiki link (text != title)
__H__
<html><a href="index.cgi?Another_page">some text</a></html>
__W__
"some text"[Another_page]
__NEXT__
external links
__H__
<html><a href="http://www.test.com">thing</a></html>
__W__
"thing"<http://www.test.com>
__NEXT__
external links (rel2abs)
__H__
<html><a href="http://www.test.com/thing.html">thing</a></html>
__W__
"thing"<http://www.test.com/thing.html>
__NEXT__
pre following pre
__H__
<html><pre>preformatted text</pre>
<pre>more preformatted text</pre>
<pre>once again</pre></html>
__W__
.pre
preformatted text
.pre

.pre
more preformatted text
.pre

.pre
once again
.pre
