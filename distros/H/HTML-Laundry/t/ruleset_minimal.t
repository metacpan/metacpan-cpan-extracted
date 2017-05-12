use strict;
use warnings;

use Test::More tests => 158;

require_ok('HTML::Laundry');
require_ok('HTML::Laundry::Rules::Minimal');

my $l1 = HTML::Laundry->new({ notidy => 1,
    rules => 'HTML::Laundry::Rules::Minimal' });

my @ok = qw( a b br blockquote code em i li ol p pre strong u ul );
my %ok = map { $_ => 1 } @ok;

my @e = (
  'a', 'abbr', 'acronym', 'address', 'area', 'b', 'bdo', 'big', 'blockquote',
  'br', 'button', 'caption', 'center', 'cite', 'code', 'col', 'colgroup', 'dd',
  'del', 'dfn', 'dir', 'div', 'dl', 'dt', 'em', 'fieldset', 'font', 'form',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'input', 'ins', 'kbd',
  'label', 'legend', 'li', 'map', 'menu', 'ol', 'optgroup', 'option', 'p',
  'pre', 'q', 's', 'samp', 'select', 'small', 'span', 'strike', 'strong',
  'sub', 'sup', 'table', 'tbody', 'td', 'textarea', 'tfoot', 'th', 'thead',
  'tr', 'tt', 'u', 'ul', 'var', 'wbr'
);

foreach my $e ( @e ) {
    if ( $ok{$e} and $e ne 'br' ) {
        # The only allowed empty element in this ruleset is <br />
        is( $l1->clean("<$e></$e>"), "<$e></$e>", "element $e is not sanitized");
    } elsif ( $ok{$e} ) {
        is( $l1->clean("<$e></$e>"), "<$e />", "element $e is not sanitized");
    } else {
        is( $l1->clean("<$e></$e>"), "", "element $e is sanitized");
    }
}

my @a =  ( 'abbr', 'accept', 'accept-charset', 'accesskey', 'action', 'align', 'alt',
  'axis', 'border', 'cellpadding', 'cellspacing', 'char', 'charoff', 'charset',
  'checked', 'cite', 'class', 'clear', 'color', 'cols', 'colspan', 'compact',
  'coords', 'datetime', 'dir', 'disabled', 'enctype', 'for', 'frame',
  'headers', 'height', 'href', 'hreflang', 'hspace', 'id', 'ismap', 'label',
  'lang', 'longdesc', 'maxlength', 'media', 'method', 'multiple', 'name',
  'nohref', 'noshade', 'nowrap', 'prompt', 'readonly', 'rel', 'rev', 'rows',
  'rowspan', 'rules', 'scope', 'selected', 'shape', 'size', 'span', 'src',
  'start', 'summary', 'tabindex', 'target', 'title', 'type', 'usemap',
  'valign', 'value', 'vspace', 'width', 'xml:lang' );

ok( ! $l1->clean('<script>alert("Jane Austen was here!");</script>'), '<script> is removed in its entirety');
ok( ! $l1->clean('<applet>blah blah</applet>'), '<applet> is removed in its entirety');
is( $l1->clean('<heroine>No one who had ever seen Catherine Morland in her infancy...</heroine>'),
  'No one who had ever seen Catherine Morland in her infancy...',
  'Unknown tag is stripped, but its contents remain' );
is( $l1->clean('<body>foo</body>'), 'foo', '<body> tag is stripped');
is( $l1->clean('<link />'), '', '<link> tag is stripped');
is( $l1->clean('<meta />'), '', '<meta> tag is stripped');
is( $l1->clean('<html>foo</html>'), 'foo', '<html> tag is stripped');
ok( ! $l1->clean('<?php echo("Foo"); ?>') && ! $l1->clean('<?= $foo ?>'), 'PHP tags are stripped entirely');
is( $l1->clean('<%= "Hello World!" %>'), '&lt;%= &quot;Hello World!&quot; %&gt;', 'ASP tags are transformed into literal text');
is( $l1->clean('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'),
  '', 'DOCTYPE declaration is stripped');
is( $l1->clean('<a href="xyzzy" plugh="plover">Her situation in life, the character of her father and mother, her own person and disposition, were all equally against her.</a>'),
  '<a href="xyzzy">Her situation in life, the character of her father and mother, her own person and disposition, were all equally against her.</a>',
  'Unknown attribute is stripped, but known attribute remains' );

foreach my $a ( @a ) {
    if ( $a eq 'href' ) {
        is( $l1->clean("<p $a=\"frotz\"></p>"), "<p $a=\"frotz\"></p>", "attribute $a is not sanitized");
    } else {
        is( $l1->clean("<p $a=\"frotz\"></p>"), "<p></p>", "attribute $a is sanitized");
    }
}
