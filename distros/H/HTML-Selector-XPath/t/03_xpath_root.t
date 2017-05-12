use strict;
use Test::Base;
use HTML::Selector::XPath qw(selector_to_xpath);

plan tests => 1 * blocks;
filters { selector => 'chomp', xpath => 'chomp' };

run {
    my $block = shift;
    is selector_to_xpath($block->selector, root=> '/R'), $block->xpath, $block->selector;
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
/R/E

===
--- selector
E F
--- xpath
/R/E//F

===
--- selector
E > F
--- xpath
/R/E/F

===
--- selector
E + F
--- xpath
/R/E/following-sibling::*[1]/self::F

===
--- selector
E[foo]
--- xpath
/R/E[@foo]

===
--- selector
E[foo="warning"]
--- xpath
/R/E[@foo='warning']

===
--- selector
E#myid
--- xpath
/R/E[@id='myid']

===
--- selector
foo.bar, bar
--- xpath
/R/foo[contains(concat(' ', normalize-space(@class), ' '), ' bar ')] | /R/bar


