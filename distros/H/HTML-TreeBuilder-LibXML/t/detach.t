use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTML::TreeBuilder::LibXML;
use Data::Dumper;


my $tree = HTML::TreeBuilder::LibXML->new_from_content('<div class="foo"><p>bar</p></div>');
my ($el) = $tree->guts;
my ($p) = $el->findnodes('./p');

my $parent = $p->detach;

is $parent->as_HTML, '<div class="foo"></div>', 'detach returns old parent';
isa_ok $p->{node}->parentNode, 'XML::LibXML::Document', 'element new parent';

done_testing;