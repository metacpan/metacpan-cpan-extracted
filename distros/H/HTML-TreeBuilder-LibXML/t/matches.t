use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;
use Data::Dumper;



my $tree = HTML::TreeBuilder::LibXML->new_from_content('<p class="foo">bar</p>');
my ($el) = $tree->guts;


is $el->matches('//p[@class="foo"]'), 1, 'matches - positive';
is $el->matches('//p[@class="bar"]'), undef, 'matches - negative';



 

done_testing;
