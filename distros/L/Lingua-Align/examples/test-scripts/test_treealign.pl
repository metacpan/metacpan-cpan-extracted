#!/usr/bin/perl
#-*-perl-*-
#
# this is a test script to run a simple training/alignment procedure
# on the SMULTRON corpus
#

use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Trees;

my @features = (
    'nr_leafs_ratio',          # ratio of nr_leafs in both subtrees
    'inside2',                 # non-normalized inside score
    'outside2',                # non-normalized outside score
    'inside2*outside2',        # product of the 2 above
    'parent_inside2',          # inside score of parent nodes
#    'catpos',                  # cat OR pos attribute pair
    'parent_catpos',           # labels of the parent nodes
    'catpos.parent_catpos',     # label plus parent's label
    'insideST2',               # inside1 score for lex.e2f only
    'insideTS2',               # inside1 score for lex.f2e only
    'joerg_insideST',          # disjunction of prob's (lexe2f)
    'joerg_insideTS',          # disjunction of prob's (lexf2e)
#    'joerg_inside*inside2',
#    'joerg_inside',           # disjunction of prob's (lexe2f & lexf2e)
#    'joerg_outside',          # the same for outside word pairs
    'inside2*parent_inside2',  # current * parent's inside score
    'tree_level_sim',          # similarity in relative tree level
    'tree_level_sim*inside2',
    'tree_span_sim',           # similarity of subtree positions
    'tree_span_sim*tree_level_sim',
#    'gizae2f',                 # proportion of word links inside/outside
#    'gizaf2e',                 # the same for the other direction
    'giza',                    # both alignment directions combined
    'parent_giza',
#    'parent_giza*giza',
#    'gizae2f*gizaf2e'
    'giza.catpos',              # catpos with giza score
#    'parent_giza.parent_catpos',
    'moses',
    'moses.catpos',
    );


my $featureStr = join(':',@features);
my $treealigner = new Lingua::Align::Trees(

    -features => $featureStr,             # features to be used

    -classifier => 'megam',               # classifier used
    -classifier_weight_sure => 3,         # training: weight for sure links
    -classifier_weight_possible => 1,     # training: weight for possible links
    -classifier_weight_negative => 1,     # training: weight for non-linked

    -keep_training_data => 1,             # don't remove feature file

    -same_types_only => 1,                # link only T&T and nonT&nonT
#    -nonterminals_only => 1,              # link non-terminals only
#    -terminals_only => 1,                 # link terminals only
    -skip_unary => 1,                     # skip nodes with unary productions

#    -lexe2f => $FindBin::Bin.'/../../'.'moses/model/lex.0-0.e2f',
#    -lexf2e => $FindBin::Bin.'/../../'.'moses/model/lex.0-0.f2e',
    -lexe2f => $FindBin::Bin.'/../../'.'ep+sw.lex.e2f',
    -lexf2e => $FindBin::Bin.'/../../'.'ep+sw.lex.f2e',


    ## for the GIZA++ word alignment features
    -gizaA3_e2f=>$FindBin::Bin.'/../../'.'moses/giza.src-trg/src-trg.A3.final.gz',
    -gizaA3_f2e=>$FindBin::Bin.'/../../'.'moses/giza.trg-src/trg-src.A3.final.gz',

    ## for the Moses word alignment features
    -moses_align=>$FindBin::Bin.'/../../'.'moses/model/aligned.grow-diag-final-and',

    -lex_lower => 1,                      # always convert to lower case!

#    -output_format => 'dublin',          # Dublin format (default = sta)
    -min_score => 0.25,                    # classification score threshold
#    -min_score => 0.1,                    # classification score threshold
    -verbose => 1,

    );


# corpus to be used for training (and testing)

my $SMULTRON = $ENV{HOME}.'/projects/SMULTRON/';
my %corpus = (
    -alignfile => $SMULTRON.'/Alignments_SMULTRON_Sophies_World_SV_EN.xml',
    -type => 'STA');


#-------------------------------------------------------------------
# train a model on the first 20 sentences 
# and save it into 'testmodel.megam'
#-------------------------------------------------------------------

# $treealigner->train(\%corpus,'testmodel.megam',20);
$treealigner->train(\%corpus,'testmodel_big.megam',100);


#-------------------------------------------------------------------
# skip the first 20 sentences and aligne the following 10 tree pairs
# with the model stored in 'testmodel.megam' using various search algorithms
# (this will print alignments to STDOUT and a short evaluation to STDERR)
#-------------------------------------------------------------------

# $treealigner->align(\%corpus,'testmodel.megam','greedy',10,20);
$treealigner->align(\%corpus,'testmodel_big.megam','greedy',200,100);






# $treealigner->align(\%corpus,'testmodel.megam','greedy',200,100);
# $treealigner->align(\%corpus,'testmodel.megam','inter',10,20);
# $treealigner->align(\%corpus,'testmodel.megam','src2trg',10,20);
# $treealigner->align(\%corpus,'testmodel.megam','trg2src',10,20);



# test aligning the training data (this should be forbidden ... sanity check)
# $treealigner->align(\%corpus,'testmodel.megam','greedy',20,0);


