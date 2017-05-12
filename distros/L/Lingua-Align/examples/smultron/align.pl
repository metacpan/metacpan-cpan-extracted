#!/usr/bin/perl
#-*-perl-*-
#
# OPTIONS
#
#  -c align-file ..... aligned treebank in stockholm treealigner format
#  -a nrAlign ........ max number of test sentences (default = 100)
#  -s strategy ....... alignment search strategy (default = greedy)
#  -m learner ........ classifier model to be used (default=megam)
#  -C ................ enable linked-children feature
#  -S ................ enable linked-subtree-nodes feature
#  -P ................ enable linked-parent feature
#  -D ................ enable link distance feature (parent-current)
#  -x threshold ...... score threshold for aligning
#  -M dir ............ Moses data dir (giza align + lexfiles)
#  -o model-file ..... name of the model file
#
#

use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use vars qw($opt_a $opt_s $opt_c $opt_m $opt_o
	    $opt_C $opt_S $opt_P $opt_D $opt_x $opt_M);
use Getopt::Std;

getopts('f:a:s:c:m:SCPDkx:M:o:');


use Lingua::Align::Trees;

my $nrAlign = $opt_a || 100;
my $search = $opt_s || 'greedy';
my $model = $opt_m || 'megam';
my $modelfile = $opt_o || 'treealign.'.$model;

my $MosesDir = $opt_M || 'moses-sophie';
my $algfile = $opt_c || 'Alignments_SMULTRON_Sophies_World_SV_EN.xml';


my $treealigner = new Lingua::Align::Trees(

    -classifier => $model,                # classifier used

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
$treealigner->align(\%corpus,$modelfile,$search,$nrAlign);
