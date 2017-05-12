#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Test;
BEGIN { plan tests => 7991 };

# File       : GO-TermFinder.t
# Author     : Gavin Sherlock
# Date Begun : September 1st 2003

# $Id: GO-TermFinder-Obo.t,v 1.2 2007/11/15 18:34:39 sherlock Exp $

# This file forms a set of tests for the GO::TermFinder class

use GO::TermFinder;
use GO::AnnotationProvider::AnnotationParser;
use GO::OntologyProvider::OboParser;

$|=1;

# turn off warnings from the TermFinder

$GO::TermFinder::WARNINGS = 0;

my $ontologyFile   = "t/gene_ontology_edit.obo";
my $annotationFile = "t/gene_association.sgd"; 
my $aspect         = "P";

# we'll check that all the public methods still exist in the interface

my @methods = qw (findTerms);

my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
						    aspect       => $aspect);

my $annotation = GO::AnnotationProvider::AnnotationParser->new(annotationFile=>$annotationFile);

my $termFinder = GO::TermFinder->new(annotationProvider=> $annotation,
				     ontologyProvider  => $ontology,
				     aspect            => $aspect);

ok($termFinder->isa("GO::TermFinder"));

# check the object returns a code reference when asked it it can do a
# method that should exist

foreach my $method (@methods){

    ok(ref($termFinder->can($method)), "CODE", "TermFinder can $method");

}

# now check that the findTerms method actually returns the correct
# answers for a selected list of genes (actually the methionine
# cluster from Spellman et al, 1998).

my @pvalues = $termFinder->findTerms(genes=>[qw(YPL250C
						MET11
						MXR1
						MET17
						SAM3
						MET28
						STR3
						MMP1
						MET1
						YIL074C
						MHT1
						MET14
						MET16
						MET3
						MET10
						ECM17
						MET2
						MUP1
						MET6)]);

&testHypotheses(@pvalues);

# now let's run exactly the same test again, but with a different
# casing of the genes

my @newpvalues = $termFinder->findTerms(genes=>[qw(ypl250c
						   Met11
						   mxr1
						   Met17
						   SAM3
						   met28
						   Str3
						   MMp1
						   mET1
						   YIl074c
						   Mht1
						   mEt14
						   Met16
						   Met3
						   mET10
						   ecm17
						   Met2
						   MuP1
						   MeT6)]);

# and compare that the stuff returned looks exactly the same

&compareHypotheses(\@pvalues, \@newpvalues, 1);

# now let's test the functionality of using a defined population
# to create the background distribution.  If we simply say that
# the defined population is every gene from the annotation parser
# then we should get the same result
    
my $newTermFinder = GO::TermFinder->new(annotationProvider=> $annotation,
					ontologyProvider  => $ontology,
					population        => [$annotation->allDatabaseIds],
					aspect            => $aspect);

my @poppvalues = $newTermFinder->findTerms(genes=>[qw(ypl250c
						      Met11
						      mxr1
						      Met17
						      SAM3
						      met28
						      Str3
						      MMp1
						      mET1
						      YIl074c
						      Mht1
						      mEt14
						      Met16
						      Met3
						      mET10
						      ecm17
						      Met2
						      MuP1
						      MeT6)]);

# again, check that the stuff returned looks exactly the same

&compareHypotheses(\@pvalues, \@poppvalues, 1);

# now try using a TermFinder with a limited population of just a few genes.
# All of the returned nodes should have a probability of 1

my $nextTermFinder = GO::TermFinder->new(annotationProvider=> $annotation,
					 ontologyProvider  => $ontology,
					 population        => [qw(ypl250c
								  Met11
								  mxr1
								  Met17
								  SAM3
								  met28
								  Str3
								  MMp1
								  mET1
								  YIl074c
								  Mht1
								  mEt14
								  Met16
								  Met3
								  mET10
								  ecm17
								  Met2
								  MuP1
								  MeT6)],
					 aspect            => $aspect);


@pvalues = $nextTermFinder->findTerms(genes=>[qw(ypl250c
						 Met11
						 mxr1
						 Met17
						 SAM3
						 met28
						 Str3
						 MMp1
						 mET1
						 YIl074c
						 Mht1
						 mEt14
						 Met16
						 Met3
						 mET10
						 ecm17
						 Met2
						 MuP1
						 MeT6)]);

foreach my $pvalue (@pvalues){

    # round the pvalue to 2 decimal places, to avoid precision problems

    my $val = sprintf("%.2f", $pvalue->{PVALUE});

    ok($val, "1.00");

}

# Now we need a test to see what happens when we create a term finder,
# and find terms for three 'nonsense' genes, to check that it doesn't
# cause a problem - we'll defined the population as being of a size
# of 3 more than exist in the annotation file, to accommodate these
# 3 extra nonsense genes

my @genes = qw (foo bar baz);

my $numGenes = scalar(@genes);

my $populationSize = $annotation->numAnnotatedGenes + $numGenes;

my $nonsenseTester = GO::TermFinder->new(annotationProvider=> $annotation,
					 ontologyProvider  => $ontology,
					 aspect            => $aspect,
					 totalNumGenes     => $populationSize);

@pvalues = $nonsenseTester->findTerms(genes=>\@genes);

# grab best node, which should be the 'unannotated' node

my $hypothesis = shift(@pvalues);

# check attributes

ok($hypothesis->{NODE}->term, "unannotated");
ok($hypothesis->{NODE}->goid, "GO:XXXXXXX");

# all our tested genes should be annotated to the node

ok($hypothesis->{NUM_ANNOTATIONS}, $numGenes);

# the total number of annotations to this node out of all genes should
# be the total number of genes minus those which have an annotation to
# this aspect.

ok($hypothesis->{TOTAL_NUM_ANNOTATIONS}, 

   ($populationSize - $annotation->numAnnotatedGenes($aspect)));

# all of the above tests have been using the default setting for
# multiple hypothesis correction, which should default to bonferroni.
# We now need to test that using bonferroni as the supplied argument
# gives the same answers as no argument, and also check that it gives
# the expected correction factor, and run the termfinder with the
# 'simulation' argument, and with the 'none' argument.

# first try with an explicit bonferroni argument

my @bonferroni = $termFinder->findTerms(genes      => [qw(ypl250c
							  Met11
							  mxr1
							  Met17
							  SAM3
							  met28
							  Str3
							  MMp1
							  mET1
							  YIl074c
							  Mht1
							  mEt14
							  Met16
							  Met3
							  mET10
							  ecm17
							  Met2
							  MuP1
							  MeT6)],
					correction => 'bonferroni');

# and compare the results to previously generated pvalues

&compareHypotheses(\@newpvalues, \@bonferroni, 1);

# we can also check that the correction value was correct - it should
# be the same as the number of hypotheses we got back; also, in this
# case, we know that should be 37.  Can only test if the corrected
# p_value is less than 1, as we have a ceiling placed on it at 1.

ok(scalar(@newpvalues), 37);

foreach my $hypothesis (@newpvalues){    

    if ($hypothesis->{CORRECTED_PVALUE} < 1){

	ok ($hypothesis->{CORRECTED_PVALUE}/$hypothesis->{PVALUE}, scalar(@newpvalues));

    }

}

# now let's test the termFinder when we ask for no correction - we
# should get identical results as we got above, except there are no
# corrected p-values.

my @noCorrection = $termFinder->findTerms(genes      => [qw(ypl250c
							    Met11
							    mxr1
							    Met17
							    SAM3
							    met28
							    Str3
							    MMp1
							    mET1
							    YIl074c
							    Mht1
							    mEt14
							    Met16
							    Met3
							    mET10
							    ecm17
							    Met2
							    MuP1
							    MeT6)],
					  correction => 'none');

&compareHypotheses(\@newpvalues, \@noCorrection, 0);

# as our final test of multiple hypothesis correction, we want to
# see if the simulation method works correctly

my @simulation = $termFinder->findTerms(genes      => [qw(ypl250c
							  Met11
							  mxr1
							  Met17
							  SAM3
							  met28
							  Str3
							  MMp1
							  mET1
							  YIl074c
							  Mht1
							  mEt14
							  Met16
							  Met3
							  mET10
							  ecm17
							  Met2
							  MuP1
							  MeT6)],
					correction => 'simulation');

# and compare the results to previously generated pvalues, but ignore
# the corrected pvalues

&compareHypotheses(\@newpvalues, \@simulation, 0);

# not sure what tests we'll do for the FDR calculations, but we should
# at least make sure that they don't throw an error when generated,
# and that the pvalues are the same:

my @fdr = $termFinder->findTerms(genes      => [qw(ypl250c
						   Met11
						   mxr1
						   Met17
						   SAM3
						   met28
						   Str3
						   MMp1
						   mET1
						   YIl074c
						   Mht1
						   mEt14
						   Met16
						   Met3
						   mET10
						   ecm17
						   Met2
						   MuP1
						   MeT6)],
				 calculateFDR => 1);

&compareHypotheses(\@fdr, \@bonferroni, 1);

# now let's test that if we say that we're looking for significant
# terms when we simply have a list of all genes, that we get none -
# indeed the uncorrected p-values should all be equal to 1.

my @nonsignificant = $termFinder->findTerms(genes=>[$annotation->allDatabaseIds]);

foreach my $hypothesis (@nonsignificant){

    ok($hypothesis->{PVALUE}, 1);

}

# now we want to test what happens when we use a TermFinder with a
# defined population, and ask if to findTerms for a list of genes,
# some of which are not in the population.

# above, we generated @poppvalues, which were the pvalues generated
# with a list of genes, with all databaseIds as the background.  Now
# we will generate some new pvalues with that same TermFinder object,
# but add in a few bogus genes at the end.  The bogus genes should be
# ignored, and we should get exactly the same result.

my @poppvalues2 = $newTermFinder->findTerms(genes=>[qw(ypl250c
						       Met11
						       mxr1
						       Met17
						       SAM3
						       met28
						       Str3
						       MMp1
						       mET1
						       YIl074c
						       Mht1
						       mEt14
						       Met16
						       Met3
						       mET10
						       ecm17
						       Met2
						       MuP1
						       MeT6

						       BLAH
						       BLAH2
						       XXXZZZ
						       CDCDCDC)]);

my @discardedGenes = $newTermFinder->discardedGenes;

# 4 genes should have been discarded

ok(scalar(@discardedGenes), 4);

# now check that the nodes and pvalues returned look exactly the same
# as we saw before, when there were no genes to be discarded

&compareHypotheses(\@poppvalues, \@poppvalues2, 1);

# also need to test that the genes are correctly discarded when we 
# are doing a correction or calculating the FDR

my @poppvalues3 = $newTermFinder->findTerms(genes=>[qw(ypl250c
						       Met11
						       mxr1
						       Met17
						       SAM3
						       met28
						       Str3
						       MMp1
						       mET1
						       YIl074c
						       Mht1
						       mEt14
						       Met16
						       Met3
						       mET10
						       ecm17
						       Met2
						       MuP1
						       MeT6

						       BLAH
						       BLAH2
						       XXXZZZ
						       CDCDCDC)],

					    calculateFDR => 1);

my @discardedGenes2 = $newTermFinder->discardedGenes;

# 4 genes should have been discarded

ok(scalar(@discardedGenes), 4);
 
my @poppvalues4 = $newTermFinder->findTerms(genes=>[qw(ypl250c
						       Met11
						       mxr1
						       Met17
						       SAM3
						       met28
						       Str3
						       MMp1
						       mET1
						       YIl074c
						       Mht1
						       mEt14
						       Met16
						       Met3
						       mET10
						       ecm17
						       Met2
						       MuP1
						       MeT6

						       BLAH
						       BLAH2
						       XXXZZZ
						       CDCDCDC)],

					    correction => 'simulation');

my @discardedGenes3 = $newTermFinder->discardedGenes;

# 4 genes should have been discarded

ok(scalar(@discardedGenes), 4);

# now let's test that if we have a background population defined, and
# that if none of the genes provided to find terms for are in the
# background, that a fatal error is thrown

eval {

    $newTermFinder->findTerms(genes=>[qw(BLAH
					 BLAH2
					 XXXZZZ
					 CDCDCDC)]);

};

ok($@, qr/None of the genes provided for analysis are found in the background population/, "should die if genes not in background");

# now some tests that check that we have GO::TermFinder working
# correctly with respect to the aspect node - in this case, test the
# biological_process node, using a bunch of genes that are all
# annotated directly to this node.  Note, this is to accommodate the
# changed behaviour, required by the change Ontologies, where they
# eliminated the unannotated nodes

my @unannotatedGenes = qw(YPR108W-A
			  YPR109W
			  YPR114W
			  YPR115W
			  YPR116W
			  YPR117W
			  YPR127W
			  YPR145C-A
			  YPR147C
			  YPR148C
			  YPR153W
			  YPR157W
			  YPR158W
			  YPR159C-A
			  YPR172W
			  YPR174C
			  YPR196W
			  YPR202W
			  YPR203W
			  YPR204W);

my @unannotatedListPValues = $newTermFinder->findTerms(genes=>\@unannotatedGenes);

ok(scalar(@unannotatedListPValues), 1, "unannotated genes return a single term.");

my $topHypothesis = $unannotatedListPValues[0];

ok($topHypothesis->{NODE}->goid, "GO:0008150");
ok($topHypothesis->{NODE}->term, "biological_process");
ok($topHypothesis->{NUM_ANNOTATIONS}, scalar(@unannotatedGenes), "all in list should be in this node");
ok($topHypothesis->{TOTAL_NUM_ANNOTATIONS}, 1505, "total num directly annotated to biological_process, hand checked");

# now add a single annotated gene, and make sure that we still get the
# same number of total annotatations

@unannotatedListPValues = $newTermFinder->findTerms(genes=>[(@unannotatedGenes, "CLB2", "CDC28")]);

ok(scalar(@unannotatedListPValues), 15, "many terms are now tested.");

$topHypothesis = $unannotatedListPValues[0];

ok($topHypothesis->{NODE}->goid, "GO:0008150");
ok($topHypothesis->{NODE}->term, "biological_process");
ok($topHypothesis->{NUM_ANNOTATIONS}, scalar(@unannotatedGenes), "should still be the same size as the list");
ok($topHypothesis->{TOTAL_NUM_ANNOTATIONS}, 1505, "total num directly annotated to biological_process, hand checked");

######################################################################################
sub testHypotheses{
######################################################################################
# the following are what should be the 11 most significant goids for
# the test set of genes using this frozen dataset.  Note if two nodes
# result in the same p-value, they will be sorted by GOID, using a
# text sort.

    my @pvalues = @_;

    my @topGoids = ("GO:0006790",
		    "GO:0000096",
		    "GO:0006555",
		    "GO:0000097",
		    "GO:0006520",
		    "GO:0006519",
		    "GO:0009066",
		    "GO:0009308",
		    "GO:0006807",
		    "GO:0044272",
		    "GO:0000103");

    # now check that these are returned by the TermFinder

    for (my $i = 0; $i< @topGoids; $i++){

	ok($pvalues[$i]->{NODE}->goid, $topGoids[$i], "$topGoids[$i] is ${i}th in the list of top hypotheses");        

    }

    return;

}

######################################################################################
sub compareHypotheses{
######################################################################################
# This subroutine expects to receive two arrays (by reference) of
# hypotheses generated by GO::TermFinder.  It will check whether they
# are identical.  An third arguments indicates if corrected p-values
# should be compared.

    my ($ref1, $ref2, $shouldCompareCorrectedPValues) = @_;

    for (my $i = 0; $i < @{$ref1}; $i++){

	ok($ref1->[$i]->{PVALUE},                $ref2->[$i]->{PVALUE}, $i."th p-value");

	# Sometimes we don't want to compare the corrected p-values,
	# as a different method of multiple hypothesis correction may
	# have been used between two different runs

	if ($shouldCompareCorrectedPValues){

	    ok($ref1->[$i]->{CORRECTED_PVALUE},      $ref2->[$i]->{CORRECTED_PVALUE}, $i."th corrected p-value");  

	}

	ok($ref1->[$i]->{NUM_ANNOTATIONS},       $ref2->[$i]->{NUM_ANNOTATIONS},       $i."th NUM_ANNOTATIONS");  
	ok($ref1->[$i]->{TOTAL_NUM_ANNOTATIONS}, $ref2->[$i]->{TOTAL_NUM_ANNOTATIONS}, $i."th TOTAL_NUM_ANNOTATIONS"); 
	ok($ref1->[$i]->{NODE}->goid,            $ref2->[$i]->{NODE}->goid,            $i."th GOID");  
	ok($ref1->[$i]->{NODE}->term,            $ref2->[$i]->{NODE}->term,            $i."th TERM");  

	# now check the genes

	# same number

	ok(scalar keys (%{$ref1->[$i]->{ANNOTATED_GENES}}), scalar keys (%{$ref2->[$i]->{ANNOTATED_GENES}}), $i."th number of annotated genes");

	foreach my $gene (keys (%{$ref1->[$i]->{ANNOTATED_GENES}})){

	    # each one exists

	    ok (exists $ref2->[$i]->{ANNOTATED_GENES}{$gene}, 1,  $i."th ANNOTATED_GENE exists");

	    # and has the same name - note has to be done case-insensitively
	    
	    ok(uc($ref1->[$i]->{ANNOTATED_GENES}{$gene}), uc($ref2->[$i]->{ANNOTATED_GENES}{$gene}), $i."th ANNOTATED_GENE name");

	}

    }

    return;

}


=head1 Modifications

 List them here.

 CVS information:

 # $Author: sherlock $
 # $Date: 2007/11/15 18:34:39 $
 # $Log: GO-TermFinder-Obo.t,v $
 # Revision 1.2  2007/11/15 18:34:39  sherlock
 # Tweaked test to be regex instead of equality, as different Perls might
 # add different things to exceptions.  This fixes a failure I was seeing
 # on Solaris.
 #
 # Revision 1.1  2007/03/18 01:33:14  sherlock
 # Adding new test files
 #
 # Revision 1.10  2006/07/28 00:02:46  sherlock
 # added new tests to make sure discarded genes are not lost when
 # calculating FDR or running simulations.
 #
 # Revision 1.9  2006/07/23 21:27:19  sherlock
 # forgot to turn warnings back off
 #
 # Revision 1.8  2006/07/23 00:41:40  sherlock
 # uncommented tests that were previously commented out for performance
 # reasons, as they seem to run fine.  Also, added test for discarded
 # genes when using a population.
 #
 # Revision 1.7  2004/10/14 22:32:04  ihab
 # Removed tests of the internal P value computation; these are now in
 # GO-TermFinder-Native.t and are testing the C++ version.
 #
 # Revision 1.6  2004/05/06 01:58:27  sherlock
 # Added in tests to check that simulation, bonferroni and FDR options
 # work correctly.
 #
 # Revision 1.5  2003/12/11 19:47:35  sherlock
 # added in some tests to check that TermFinder behaves correctly in the
 # case that unrecognized gene names are passed in, which was not working
 # properly previously.
 #
 # Revision 1.4  2003/12/03 02:30:25  sherlock
 # added in a bunch of tests to be more precise in the testing of the
 # term finder, and to test the functionality of providing a population
 # of genes from which to calculate the background distribution
 #
 # Revision 1.3  2003/11/22 00:09:12  sherlock
 # added some new tests to see that differently cased versions of the
 # gene names still give the same result.
 #

=cut
