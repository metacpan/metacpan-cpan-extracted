use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;
use Data::Dumper;

my $tree = HTML::TreeBuilder::LibXML->new_from_content('<header>foo</header><footer>bar</footer>');
my $guts = $tree->guts;

is join('|', map {$_->as_HTML} $guts->content_list), '<header>foo</header>|<footer>bar</footer>', 'content_list - list context';
is $guts->content_list, 2, 'content_list - scalar context';

done_testing;
