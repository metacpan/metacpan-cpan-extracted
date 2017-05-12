local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'PhpWiki' );
close DATA;

__DATA__
pre
__H__
<html>
<pre>
Device ID                 : 0
Device Revision           : 0
Firmware Revision         : 1.71
IPMI Version              : 1.0
Manufacturer ID           : 674
Product ID                : 1 (0x0001)
Device Available          : yes
Provides Device SDRs      : yes
Additional Device Support :
    Sensor Device
    SDR Repository Device
    SEL Device
    FRU Inventory Device
    IPMB Event Receiver
Aux Firmware Rev Info     :
    0x00
    0x00
    0x00
    0x00
</pre>
</html>
__W__
<pre>
Device ID                 : 0
Device Revision           : 0
Firmware Revision         : 1.71
IPMI Version              : 1.0
Manufacturer ID           : 674
Product ID                : 1 (0x0001)
Device Available          : yes
Provides Device SDRs      : yes
Additional Device Support :
    Sensor Device
    SDR Repository Device
    SEL Device
    FRU Inventory Device
    IPMB Event Receiver
Aux Firmware Rev Info     :
    0x00
    0x00
    0x00
    0x00
</pre>
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
<html><i><b>bold-italics</b> nested</i></html>
__W__
_*bold-italics* nested_
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
<html><ul><li>1<ul><li>a<ol><li>i</li></ol></li><li>b</li></ul></li><li>2</li></ul></html>
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
----
__NEXT__
br
__H__
<html><p>stuff<br />stuff two</p></html>
__W__
stuff%%%stuff two
__NEXT__
sub
__H__
<html><p>H<sub>2</sub>O</p></html>
__W__
H<sub>2</sub>O
__NEXT__
sup
__H__
<html><p>x<sup>2</sup></p></html>
__W__
x<sup>2</sup>
__NEXT__
small
__H__
<html><small>small text</small></html>
__W__
<small>small text</small>
__NEXT__
big
__H__
<html><big>big text</big></html>
__W__
<big>big text</big>
__NEXT__
code
__H__
<html><code>$name = 'stan';</code></html>
__W__
<code>$name = 'stan';</code>
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
<pre>this
  is
    preformatted
      text</pre>
__NEXT__
indent
__H__
<html><blockquote>indented text</blockquote></html>
__W__
  indented text
__NEXT__
nested indent
__H__
<html><blockquote>indented text <blockquote>double-indented</blockquote></blockquote></html>
__W__
  indented text
    double-indented
__NEXT__
h1
__H__
<h1>h1</h1>
__W__
!!! h1
__NEXT__
h2
__H__
<h2>h2</h2>
__W__
!!! h2
__NEXT__
h3
__H__
<h3>h3</h3>
__W__
!! h3
__NEXT__
h4
__H__
<h4>h4</h4>
__W__
! h4
__NEXT__
h5
__H__
<h5>h5</h5>
__W__
! h5
__NEXT__
h6
__H__
<h6>h6</h6>
__W__
! h6
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
[thing|http://www.test.com/test.html]
__NEXT__
definition lists
__H__
<html><dl><dt>Some term</dt><dd><p>Embedded <i>formatting</i> is fun<sup>2</sup>!</p><p>Another <strong>formatted</strong> paragraph.</p></dd></dl></html>
__W__
Some term:

  Embedded _formatting_ is fun<sup>2</sup>!

  Another *formatted* paragraph.
__NEXT__
simple tables
__H__
<html>
  <table>
    <tr>
      <td> Name </td>
      <td> David </td></tr><tr><td> Age </td>
      <td> 24 </td>
    </tr>
  </table>
</html>
__W__
Name |
  David
Age |
  24
__NEXT__
brbr
__H__
<br><br>
__W__
%%% %%%
__NEXT__
brbrbr
__H__
<br><br><br>
__W__
%%% %%% %%%
