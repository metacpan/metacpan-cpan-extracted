use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTML::TreeBuilder::LibXML;
use HTML::TreeBuilder::LibXML::Node;
use Data::Dumper;


my $tree = HTML::TreeBuilder::LibXML->new_from_content('<div class="foo">foo</div><span>bar</span>');
my @nodes = $tree->guts;

my ($p) = HTML::TreeBuilder::LibXML->new_from_content('<div><p/></div>')->findnodes('//p');

$p->postinsert(@nodes);
is $p->parent->as_HTML, '<div><p></p><div class="foo">foo</div><span>bar</span></div>', 'postinsert';


done_testing;
