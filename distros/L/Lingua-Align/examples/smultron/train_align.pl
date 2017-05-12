#!/usr/bin/env perl
#-*-perl-*-
#
# OPTIONS
#
#  -c align-file ..... aligned treebank in stockholm treealigner format
#  -f features ....... specify features to be used in training
#  -t nrTrain ........ max number of training sentences (default = 100)
#  -a nrAlign ........ max number of test sentences (default = 100)
#  -s strategy ....... alignment search strategy (default = greedy)
#  -m learner ........ classifier model to be used (default=megam)
#  -C ................ enable linked-children feature
#  -S ................ enable linked-subtree-nodes feature
#  -P ................ enable linked-parent feature
#  -D ................ enable link distance feature (parent-current)
#  -k ................ keep feature file for training
#  -x threshold ...... score threshold for aligning
#  -M dir ............ Moses data dir (giza align + lexfiles)
#
#

use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use vars qw($opt_f $opt_t $opt_a $opt_s $opt_c $opt_m 
	    $opt_C $opt_S $opt_P $opt_D $opt_k $opt_x $opt_M);
use Getopt::Std;

getopts('f:t:a:s:c:m:SCPDkx:M:');


use Lingua::Align::Trees;

my $featureStr = $opt_f || 'insideST2:insideTS2:outsideST2:outsideTS2';
my $nrTrain = $opt_t || 100;
my $nrAlign = $opt_a || 100;
my $search = $opt_s || 'greedy';
my $model = $opt_m || 'megam';

my $MosesDir = $opt_M || 'moses-sophie';
my $algfile = $opt_c || 'Alignments_SMULTRON_Sophies_World_SV_EN.xml';


my $treealigner = new Lingua::Align::Trees(

    -features => $featureStr,             # features to be used

    -classifier => $model,                # classifier used
    -classifier_weight_sure => 3,         # training: weight for sure links
    -classifier_weight_possible => 1,     # training: weight for possible links
    -classifier_weight_negative => 1,     # training: weight for non-linked

#    -megam => '/Users/joerg/work/align/MaxEnt/megam_0.92/megam',
    -megam => '/storage/tiedeman/projects/align/MaxEnt/megam_i686.opt',

    -keep_training_data => $opt_k,             # don't remove feature file

    -same_types_only => 1,                # link only T&T and nonT&nonT
#    -nonterminals_only => 1,              # link non-terminals only
#    -terminals_only => 1,                 # link terminals only
    -skip_unary => 1,                     # skip nodes with unary productions

    -linked_children => $opt_C,                # add first-order dependency
                                          # (proportion of linked children)
    -linked_subtree => $opt_S,                # add first-order dependency
    -linked_parent => $opt_P,
    -linked_parent_distance => $opt_D,

    -lexe2f => $MosesDir.'/model/lex.0-0.e2f',
    -lexf2e => $MosesDir.'/model/lex.0-0.f2e',

    ## for the GIZA++ word alignment features
    -gizaA3_e2f => $MosesDir.'/giza.src-trg/src-trg.A3.final.gz',
    -gizaA3_f2e => $MosesDir.'/giza.trg-src/trg-src.A3.final.gz',

    ## for the Moses word alignment features
    -moses_align => $MosesDir.'/model/aligned.intersect',

    -lex_lower => 1,                      # always convert to lower case!

#    -output_format => 'dublin',          # Dublin format (default = sta)
    -min_score => $opt_x,                    # classification score threshold
    -verbose => 1,

    );


# corpus to be used for training (and testing)

my %corpus = (
    -alignfile => $algfile,
    -type => 'STA');


#-------------------------------------------------------------------
# train a model on the first <nrTrain> sentences 
# and save it into "treealign.$model"
#-------------------------------------------------------------------

$treealigner->train(\%corpus,'treealign.'.$model,$nrTrain);

#-------------------------------------------------------------------
# skip the first <nrTrain> sentences and aligne the following <nrAlign>
# tree pairs with the model stored in "treealign.$model" 
#-------------------------------------------------------------------

$treealigner->align(\%corpus,'treealign.'.$model,$search,$nrAlign,$nrTrain);
