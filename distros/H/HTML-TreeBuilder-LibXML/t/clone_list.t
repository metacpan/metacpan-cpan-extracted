use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTML::TreeBuilder::LibXML;
use HTML::TreeBuilder::LibXML::Node;
use Data::Dumper;


my $tree = HTML::TreeBuilder::LibXML->new_from_content('<div class="foo">foo</div><span>bar</span>');

my @original = $tree->guts;
my @clones = HTML::TreeBuilder::LibXML::Node->clone_list(@original);

is join('|', map{$_->as_HTML} @clones), '<div class="foo">foo</div>|<span>bar</span>', 'clone_list';
is $clones[0]->{node}->isSameNode($original[0]->{node}), 0, 'clone is not the same as original';


done_testing;
