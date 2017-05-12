#!/usr/bin/perl
#-*-perl-*-
#
# OPTIONS
#
#  -c align-file ..... aligned treebank in stockholm treealigner format
#  -f features ....... specify features to be used in training
#  -t nrTrain ........ max number of training sentences (default = 100)
#  -m learner ........ classifier model to be used (default=megam)
#  -C ................ enable linked-children feature
#  -S ................ enable linked-subtree-nodes feature
#  -P ................ enable linked-parent feature
#  -D ................ enable link distance feature (parent-current)
#  -k ................ keep feature file for training
#  -M dir ............ Moses data dir (giza align + lexfiles)
#  -o model-file ..... name of the model file
#
#

use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use vars qw($opt_f $opt_t $opt_c $opt_m $opt_o
	    $opt_C $opt_S $opt_P $opt_D $opt_k $opt_M);
use Getopt::Std;

getopts('f:t:c:m:SCPDkM:o:x:');


use Lingua::Align::Trees;

my $featureStr = $opt_f || 'insideST2:insideTS2:outsideST2:outsideTS2';
my $nrTrain = $opt_t || 100;
my $model = $opt_m || 'megam';
my $modelfile = $opt_o || 'treealign.'.$model;

my $MosesDir = $opt_M || 'moses-sophie';
my $algfile = $opt_c || 'Alignments_SMULTRON_Sophies_World_SV_EN.xml';


my $treealigner = new Lingua::Align::Trees(

    -features => $featureStr,             # features to be used

    -classifier => $model,                # classifier used
    -classifier_weight_sure => 3,         # training: weight for sure links
    -classifier_weight_possible => 1,     # training: weight for possible links
    -classifier_weight_negative => 1,     # training: weight for non-linked

    -keep_training_data => $opt_k,             # don't remove feature file

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

$treealigner->train(\%corpus,$modelfile,$nrTrain);

