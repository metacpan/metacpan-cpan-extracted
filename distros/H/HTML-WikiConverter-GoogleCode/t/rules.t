#!perl -T

use warnings;
use strict;

use Test::More tests => 36;

BEGIN {
	use_ok( 'HTML::WikiConverter');
	use_ok( 'HTML::WikiConverter::GoogleCode');
}
my $wc = new HTML::WikiConverter( dialect => 'GoogleCode' );

is($wc->html2wiki('<p>foo</p>'), 
	'foo',  
	'tag - p'
);

is($wc->html2wiki('<pre>foo</pre>'), 
	"{{{\nfoo\n}}}", 
	'tag - pre'
);

is($wc->html2wiki('<i>foo</i>'), 
	'_foo_', 
	'tag - i'
);

is($wc->html2wiki('<em>foo</em>'), 
	'_foo_', 
	'tag - em');
	
is($wc->html2wiki('<b>foo</b>'), 
	'*foo*', 
	'tag - b'
);

is($wc->html2wiki('<strong>foo</strong>'), 
	'*foo*', 
	'tag - strong'
);

is($wc->html2wiki('<sup>foo</sup>'), 
	'^foo^', 
	'tag - sup'
);

is($wc->html2wiki('<sub>foo</sub>'), 
	',,foo,,', 
	'tag - sub'
);

is($wc->html2wiki('<code>foo</code>'), 
	'`foo`', 
	'tag - code'
);

is($wc->html2wiki('<tt>foo</tt>'), 
	'`foo`', 
	'tag - tt'
);

is($wc->html2wiki('<a href="#foo">see foo</a>'), 
	'[#foo see foo]', 
	'tag - a - anchor'
);

is($wc->html2wiki('<a href="http://beavercreekconsulting.com">see foo</a>'), 
	'[http://beavercreekconsulting.com see foo]', 
	'tag - a'
);

is($wc->html2wiki('<a href="http://beavercreekconsulting.com">http://beavercreekconsulting.com</a>'), 
	'http://beavercreekconsulting.com', 
	'tag - a - autolink'
);

is($wc->html2wiki('<img src="img.png"/>'), 
	'[img.png]', 
	'tag - rel'
);

is($wc->html2wiki('<img src="http://example.com/img.png"/>'), 
	'[http://example.com/img.png]', 
	'tag - abs'
);

is($wc->html2wiki('<ul>foo</ul>'), 
	'', 
	'tag - ul'
);

is($wc->html2wiki('<ol>foo</ol>'), 
	'', 
	'tag - ol'
);

is($wc->html2wiki('<ul><li>foo</li></ul>'), 
	'  * foo', 
	'tag - ul/li'
);

is($wc->html2wiki('<ol><li>foo</li></ol>'), 
	'  # foo', 
	'tag - ol/li'
);

is($wc->html2wiki('<br>'), 
	'', 
	'tag - br'
);

is($wc->html2wiki('<br/>'), 
	'', 
	'tag - br'
);

is($wc->html2wiki('<hr>'), 
	'----', 
	'tag - hr'
);

is($wc->html2wiki('<hr/>'), 
	'----', 
	'tag - hr'
);

is($wc->html2wiki('<table></table>'), 
	'', 
	'tag - table'
);

is($wc->html2wiki('<tr></tr>'), 
	'||', 
	'tag - tr'
);

is($wc->html2wiki('<td></td>'), 
	'||  ||', 
	'tag - td'
);

is($wc->html2wiki('<th></th>'), 
	'||  ||', 
	'tag - th'
);

is($wc->html2wiki('<table><tr><td>foo</td><td>bar</td></tr><tr><td>baz</td><td>bing</td></tr></table>'), 
	"|| foo || bar ||\n|| baz || bing ||", 
	'a table'
);

is($wc->html2wiki('<h1>foo</h1>'), 
	'= foo =', 
	'tag - h1'
);

is($wc->html2wiki('<h2>foo</h2>'), 
	'== foo ==', 
	'tag - h2'
);

is($wc->html2wiki('<h3>foo</h3>'), 
	'=== foo ===', 
	'tag - h3'
);

is($wc->html2wiki('<h4>foo</h4>'), 
	'==== foo ====', 
	'tag - h4'
);

is($wc->html2wiki('<h5>foo</h5>'), 
	'===== foo =====', 
	'tag - h5'
);

is($wc->html2wiki('<h6>foo</h6>'), 
	'====== foo ======', 
	'tag - h6'
);

