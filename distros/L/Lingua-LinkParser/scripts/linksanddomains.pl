use strict;
use Lingua::LinkParser;

my $parser = new Lingua::LinkParser;

## Outputs domains direction from the API's linkage_print_links_and_domains() function.

$parser->opts('max_null_count' => 3);
$parser->opts('min_null_count' => 1);

my $sentence = $parser->create_sentence("We met in New York.");

print "linkages: ", $sentence->num_linkages, "\n";

for my $i (1 .. $sentence->num_linkages) {
    print $i, ": ", $parser->get_domains($sentence->linkage($i),2), "\n";
}

