use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTML::TreeBuilder::LibXML;
use HTML::TreeBuilder::LibXML::Node;
use Data::Dumper;

my $tree = HTML::TreeBuilder::LibXML->new_from_content('<div>foo</div>');
my ($div) = $tree->guts;


# get parent
isa_ok $div->parent, 'HTML::TreeBuilder::LibXML::Node', 'parent()';
is $div->parent->as_HTML, '<body><div>foo</div></body>', 'parent()->as_HTML';

# unset parent
$div->parent(undef);
is $div->parent, undef;

# set parent
dies_ok { $div->parent($div) } "can't set itself as parent";

# set a doc as parent
my $doc = HTML::TreeBuilder::LibXML::Node->new(XML::LibXML->createDocument);
$tree = HTML::TreeBuilder::LibXML->new_from_content('<div>foo</div>');
($div) = $tree->guts;

$div->parent($doc);
is $doc->as_HTML, "<div>foo</div>\n", 'set a doc as parent';

# set a doc with child as parent
$tree = HTML::TreeBuilder::LibXML->new_from_content('<div>foo</div><div>bar</div>');
my ($div_foo, $div_bar) = $tree->guts(1);
$div_foo->parent($div_bar->parent);
is $div_foo->parent->as_HTML, "<div>bar</div><div>foo</div>\n", 'set a doc with child as parent';





done_testing;
