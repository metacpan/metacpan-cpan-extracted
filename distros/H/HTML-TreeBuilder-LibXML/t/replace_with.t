use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTML::TreeBuilder::LibXML;
use Data::Dumper;


my $tree = HTML::TreeBuilder::LibXML->new_from_content('<div class="foo"><p>bar</p></div>');
my ($div) = $tree->guts;
my ($p) = $div->findnodes('//p');

my $p2 = $p->replace_with('foo', scalar HTML::TreeBuilder::LibXML->new_from_content('<p>baz</p>')->guts, 'bar');
isa_ok $p2, 'HTML::TreeBuilder::LibXML::Node', 'returned element';
ok $p2->{node}->isSameNode($p->{node}), 'returns same node';
isa_ok $p->{node}->parentNode, 'XML::LibXML::Document', 'replaced node has a document';
is $div->as_HTML, '<div class="foo">foo<p>baz</p>bar</div>', 'replace_with';

# when parent is a document 
$tree = HTML::TreeBuilder::LibXML->new_from_content('<div class="foo"><p>bar</p></div>');
($div) = $tree->disembowel; 

my $doc = $div->{node}->parentNode;
$div = $div->replace_with('foo', scalar HTML::TreeBuilder::LibXML->new_from_content('<p>baz</p>')->guts, 'bar');

is $doc->toString, "<?xml version=\"1.0\"?>\nfoo\n<p>baz</p>\nbar\n", 'replace_with when parent is a document';

#diag $div->as_HTML;
#diag ref $div->{node}->parentNode;


done_testing;