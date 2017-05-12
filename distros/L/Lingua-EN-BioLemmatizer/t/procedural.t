#########################
# 
# test the regular procedural interface


use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN { use_ok("Lingua::EN::BioLemmatizer", "biolemma") };

# return first whitespace-separated "word" in argument string
sub fw($) {
    my($string) = @_;
    my @words = split /\s+/, $string;
    return $words[0];
} 

ok defined(&biolemma) => "import of biolemma as function call";

is fw(biolemma("theses")), 	    	fw("thesis NNS PennPOS");
is fw(biolemma("these")), 	    	fw("these d NUPOS");
is fw(biolemma("are")), 	    	fw("be vbb NUPOS");
is fw(biolemma("phyla")), 	    	fw("phylum NNS PennPOS");
is fw(biolemma("grandchildren")),       fw("grandchild n2 NUPOS");

is fw(biolemma("broken")), fw("broken j-vvn NUPOS||break VBN PennPOS||break vvn NUPOS");

is fw(biolemma("lives NNS")), 	fw("life n2 NUPOS");
is fw(biolemma("lives VBZ")), 	fw("live VBZ PennPOS");

done_testing();
