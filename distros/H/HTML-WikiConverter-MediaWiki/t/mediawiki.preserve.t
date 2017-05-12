local $/;
require 't/runtests.pl';
runtests( data => <DATA>, dialect => 'MediaWiki', minimal => 1, preserve_italic => 1, preserve_bold => 1 );
close DATA;

__DATA__
preserve bold
__H__
<b>bold</b>
__W__
<b>bold</b>
__NEXT__
preserve bold w/ attrs
__H__
<b id="this">this</b>
__W__
<b id="this">this</b>
__NEXT__
preserve bold w/ bad attrs
__H__
<b onclick="takeOverBrowser()">clickme</b>
__W__
<b>clickme</b>
__NEXT__
convert strong
__H__
<strong>strong</strong>
__W__
'''strong'''
__NEXT__
both strong/b
__H__
<ul>
  <li> <b>bold</b>
  <li> <strong>strong</strong>
</ul>
__W__
* <b>bold</b>
* '''strong'''
__NEXT__
preserve italic
__H__
<i>italic</i>
__W__
<i>italic</i>
__NEXT__
preserve italic w/ attrs
__H__
<i id="it">italic</i>
__W__
<i id="it">italic</i>
__NEXT__
preserve italic w/ bad attrs
__H__
<i onclick="alert('bad!')">clickme</i>
__W__
<i>clickme</i>
__NEXT__
convert em
__H__
<em>em</em>
__W__
''em''
__NEXT__
both em/i
__H__
<ul>
  <li> <i>italic</i>
  <li> <em>em</em>
</ul>
__W__
* <i>italic</i>
* ''em''
