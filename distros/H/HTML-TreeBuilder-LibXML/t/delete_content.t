use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTML::TreeBuilder::LibXML;
use Data::Dumper;

my $tree = HTML::TreeBuilder::LibXML->new_from_content('<div class="foo"><p>bar</p></div>');
my ($el) = $tree->guts;


$el->delete_content;
is $el->as_HTML, '<div class="foo"></div>', 'delete_content';




done_testing;
