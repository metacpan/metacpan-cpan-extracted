use strict;
use Lingua::LinkParser;

## This uses the link parser API's constituent parser to just get the tree
## string; see constituent-tree.pl to see how to process the tree itself.

my $parser = new Lingua::LinkParser;

$parser->opts('max_null_count' => 3);
$parser->opts('min_null_count' => 1);

my $sentence = $parser->create_sentence("The man put the book on the table..");

print "linkages: ", $sentence->num_linkages, "\n";

for my $i (1 .. $sentence->num_linkages) {
    print $i, ": ", $parser->print_constituent_tree($sentence->linkage($i),1), "\n";
}

