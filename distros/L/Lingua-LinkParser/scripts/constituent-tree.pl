use strict;
use Lingua::LinkParser;

my $parser = new Lingua::LinkParser;

## This script demonstrates processing of the constituent tree nodes by
## printing out the tree using Perl.

$parser->opts('max_null_count' => 3);
$parser->opts('min_null_count' => 1);

my $sentence = $parser->create_sentence($ARGV[0]);

for my $num (1 .. $sentence->num_linkages) {

    my $linkage = $sentence->linkage($num);
    $linkage->compute_union();

    ## our custom tree, built using the output_tree() recursive function below
    my $tree_string = output_tree( $linkage->constituent_tree() );

    ## the API's constituent tree string
    chomp(my $tree_from_api = $parser->print_constituent_tree($linkage,2));

    print $tree_from_api . "\n";
    print $tree_string . "\n";

    ## yes, these match
    if ($tree_string eq $tree_from_api) {
        print "\The trees match!\n";
    }

}

sub output_tree {
    my $node = shift;
    my $string;
    for my $subnode (@$node) {
        if (ref($subnode) eq "HASH") {
            my $isa_word = 0;
            if ($subnode->{label} =~ /^[a-z]+$/ ||
                   $subnode->{label} !~ /^S|NP|VP|PP|SBAR|WHNP|WHPP|ADJP|ADVP|SINV|PRT|QP|WHADVP$/) {
                   ## http://www.abisource.com/projects/link-grammar/dict/ph-explanation.html
                $isa_word = 1;
                ## a word, not a constituent label
            }

            if ($isa_word) {
                $string .= $subnode->{label} . " ";
            }
            else
            {
                ## a constituent label with a start to end span
                $string .= "[" . $subnode->{label} . " ";
            }

            ## go down a node
            if ($subnode->{child}) {
                $string .= output_tree($subnode->{child});
            }

            if (!$isa_word) {
                $string .= $subnode->{label} . "] ";
            }
        } 
        ## inside a leaf, keep going
        elsif (ref($subnode) eq "ARRAY") {
            $string .= output_tree($subnode);
        }
    }
    return $string;
}


## an extract of the format for the constituent tre:
#
#    [
#          {
#             'child' => [
#                          {
#                            'child' => [
#                                         {
#                                           'label' => 'We',
#                                           'end' => 0,
#                                           'start' => 0
#                                         }
#                                       ],
#                            'label' => 'NP',
#                            'end' => 0,
#                            'start' => 0
#                          },
#                          [ ...

