use strict;
use warnings;

use Test::More tests => 26;

require_ok('HTML::Laundry');

my $l1 = HTML::Laundry->new({ notidy => 1 });
isa_ok($l1, 'HTML::Laundry', 'New object isa HTML::Laundry');

my $plaintext = 'She was the youngest of the two daughters of a most affectionate, indulgent father...';
is( $l1->clean($plaintext), $plaintext, 'Short plain text passes through cleanly');
$plaintext = 'She was the youngest of the two daughters of a most affectionate, indulgent father; and had, in consequence of her sister\'s marriage, been mistress of his house from a very early period. Her mother had died too long ago for her to have more than an indistinct remembrance of her caresses; and her place had been supplied by an excellent woman as governess, who had fallen little short of a mother in affection.';
is( $l1->clean($plaintext), $plaintext, 'Longer plain text passes through cleanly');
my $kurosawa = q[Akira Kurosawa (Kyūjitai: 黒澤 明, Shinjitai: 黒沢 明 Kurosawa Akira, 23 March 1910 – 6 September 1998) was a legendary Japanese filmmaker, producer, screenwriter and editor];
is( $l1->clean($kurosawa), $kurosawa, 'UTF-8 text passes through cleanly');
my $valid = '<p class="opening">She was the youngest of the two daughters of a most affectionate, indulgent <a href="#footnote1">father</a>; and had, in consequence of her sister\'s marriage, been mistress of his house from a very early period. Her mother had died too long ago for her to have more than an indistinct remembrance of her caresses; and her place had been supplied by an excellent woman as governess, who had fallen little short of a mother in affection.</p>';
is( $l1->clean($valid), $valid, 'Validating text passes through cleanly');
is( $l1->clean('<p></p>'), '<p></p>', 'Non-empty tag passes through cleanly');
is( $l1->clean('<br />'), '<br />', 'Empty tag passes through cleanly');
is( $l1->clean('<br /   >'), '<br />', 'Empty tag with whitespace passes through cleanly');
is( $l1->clean('<p />'), '<p></p>', 'Non-empty tag passed in as empty is normalized to non-empty format');
is( $l1->clean('<br></br>'), '<br />', 'Empty tag passed in as non-empty is normalized to empty format');
is( $l1->clean('<br class="foo" />'), '<br class="foo" />', 'Empty tag attribute is preserved');
is( $l1->clean('<p class="foo"></p>'), '<p class="foo"></p>', 'Non-empty tag attribute is preserved');
my $attributes = '<img src="foo.jpg" alt="example" id="foo"/>';
my $cleaned = $l1->clean($attributes);
ok( $cleaned eq '<img src="foo.jpg" alt="example" id="foo" />' ||
    $cleaned eq '<img src="foo.jpg" id="foo" alt="example" />' ||
    $cleaned eq '<img alt="example" src="foo.jpg" id="foo" />' ||
    $cleaned eq '<img alt="example" id="foo" src="foo.jpg" />' ||
    $cleaned eq '<img id="foo" alt="example" src="foo.jpg" />' ||
    $cleaned eq '<img id="foo" src="foo.jpg" alt="example" />'
    , 'Multiple legal attributes are preserved (may be rearranged)' );
is( $l1->clean('<BR />'), '<br />', 'Empty tag\'s tagname normalized to lower case');
is( $l1->clean('<br ID="FOO" />'), '<br id="FOO" />', 'Empty tag\'s attribute name (NOT value) normalized to lower case');
is( $l1->clean('<SPAN></SPAN>'), '<span></span>', 'Non-empty tag\'s tagname normalized to lower case');
is( $l1->clean('<SPAN ID="FOO"></SPAN>'), '<span id="FOO"></span>', 'Non-empty tag\'s attribute name (NOT value) normalized to lower case ');
is( $l1->clean('<br id=BAR />'), '<br id="BAR" />', 'Empty tag\'s attribute normalized with quotes');
is( $l1->clean('<span id=BAR></span>'), '<span id="BAR"></span>', 'Non-empty tag\'s attribute normalized with quotes');
my $whitespace = "<img alt=\"
You're in a small chamber lit by an eerie green light. An extremely narrow tunnel exits to the west. A dark corridor leads NE.
\" />";
is ( $l1->clean($whitespace), "<img alt=\"\nYou're in a small chamber lit by an eerie green light. An extremely narrow tunnel exits to the west. A dark corridor leads NE.\n\" />", 'Parser handles vertical spacing (by leaving it alone) in attributes');
ok( ! $l1->clean('<!-- <p>test</p> -->'), 'Comments are not parsed or passed through');
is( $l1->clean(q[< script>]),
    q[&lt; script&gt;],
    'Tag with leading space is treated as text and brackets are escaped');
is( $l1->clean(q[<
script>]),
    qq[&lt;\nscript&gt;],
    'Tag with leading vertical space is treated as text and brackets are escaped');
is( $l1->clean(q[An ampersand (&), also commonly called an 'and sign', is a logogram representing the conjunction "and".]),
    q[An ampersand (&amp;), also commonly called an 'and sign', is a logogram representing the conjunction &quot;and&quot;.],
    'Raw quotes and ampersands are escaped');
is( $l1->clean(q[1 > 0, but 1 < 2]),
    q[1 &gt; 0, but 1 &lt; 2],
    'Raw left and right angle brackets are escaped');
