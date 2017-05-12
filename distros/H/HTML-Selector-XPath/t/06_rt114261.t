use strict;
use Test::Base;
use HTML::Selector::XPath qw(selector_to_xpath);

plan tests => 1 * blocks;
filters { selector => 'chomp', xpath => 'chomp' };

run {
    my $block = shift;
    is selector_to_xpath($block->selector), $block->xpath, $block->selector;
}

__END__
===
--- selector
a:contains("s1")
--- xpath
//a[text()[contains(string(.),"s1")]]

===
--- selector
a:contains('s1')
--- xpath
//a[text()[contains(string(.),"s1")]]

===
--- selector
:not(a:contains("s3"))
--- xpath
//*[not(self::a[text()[contains(string(.),"s3")]])]

===
--- selector
:not(a:contains('s3'))
--- xpath
//*[not(self::a[text()[contains(string(.),"s3")]])]
