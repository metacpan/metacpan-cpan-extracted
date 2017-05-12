use strict;
use Test::Base;
use HTML::Selector::XPath qw(selector_to_xpath);

plan tests => 1 * blocks;
filters { selector => 'chomp', xpath => 'chomp' };

run {
    my $block = shift;
    is selector_to_xpath($block->selector, root => '/R', prefix => 'xhtml'), $block->xpath, $block->selector;
}

__END__
===
--- selector
*
--- xpath
/R/*

===
--- selector
E
--- xpath
/R/xhtml:E

===
--- selector
E F
--- xpath
/R/xhtml:E//xhtml:F

===
--- selector
E > F
--- xpath
/R/xhtml:E/xhtml:F

===
--- selector
E + F
--- xpath
/R/xhtml:E/following-sibling::*[1]/self::xhtml:F

===
--- selector
E[foo]
--- xpath
/R/xhtml:E[@foo]

===
--- selector
E[foo="warning"]
--- xpath
/R/xhtml:E[@foo='warning']

===
--- selector
E#myid
--- xpath
/R/xhtml:E[@id='myid']

===
--- selector
foo.bar, bar
--- xpath
/R/xhtml:foo[contains(concat(' ', normalize-space(@class), ' '), ' bar ')] | /R/xhtml:bar


