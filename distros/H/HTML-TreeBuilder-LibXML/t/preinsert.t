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

$p->preinsert(@nodes);
is $p->parent->as_HTML, '<div><div class="foo">foo</div><span>bar</span><p></p></div>', 'preinsert';


done_testing;
