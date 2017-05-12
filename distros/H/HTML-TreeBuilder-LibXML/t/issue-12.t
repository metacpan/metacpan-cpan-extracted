use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;

# https://github.com/tokuhirom/HTML-TreeBuilder-LibXML/issues/12

my $html = <<EOF;
<html><a href="/">top</a></html>
EOF

my $tree = HTML::TreeBuilder::LibXML->new;
$tree->parse($html);
$tree->eof;
my ($element) = $tree->findnodes('//a');
my $new_element = ref($element)->new('div', foo => 'bar');
$element->replace_with($new_element);
is $tree->as_HTML, q{<html><body><div foo="bar"></div></body></html>};

done_testing;
