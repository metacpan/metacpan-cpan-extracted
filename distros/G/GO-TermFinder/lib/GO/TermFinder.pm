package GO::TermFinder;

# File        : TermFinder.pm
# Author      : Gavin Sherlock
# Date Begun  : December 31st 2002

# $Id: TermFinder.pm,v 1.52 2009/11/19 17:27:52 sherlock Exp $

# License information (the MIT license)

# Copyright (c) 2003-2006 Gavin Sherlock; Stanford University

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

=pod

=head1 NAME

GO::TermFinder - identify GO nodes that annotate a group of genes with a significant p-value

=head1 DESCRIPTION

This package is intended to provide a method whereby the P-values of a
set of GO annotations can be determined for a set of genes, based on
the number of genes that exist in the particular genome (or in a
selected background distribution from the genome), and their
annotation, and the frequency with which the GO nodes are annotated
across the provided set of genes.  The P-value is simply calculated
using the hypergeometric distribution as the probability of x or more
out of n genes having a given annotation, given that G of N have that
annotation in the genome in general.  We chose the hypergeometric
distribution (sampling without replacement) since it is more accurate,
though slower to calculate, than the binomial distribution (sampling
with replacement).

In addition, a corrected p-value can be calculated, to correct for
multiple hypothesis testing.  The correction factor used is the total
number of nodes to which the provided list of genes are annotated,
excepting any nodes which have only a single annotation in the
background, as a priori, we know that these cannot be significantly
enriched.  The client has access to both the corrected and uncorrected
values.  It is also possible to correct the p-value using 1000
simulations, which control the Family Wise Error Rate - using this
option suggests that the Bonferroni correction is in fact somewhat
liberal, rather than conservative, as might be expected.  Finally, the
False Discovery Rate can also be calculated.

The general idea is that a list of genes may have been identified for
some reason, e.g. they are co-regulated, and TermFinder can be used to
find out if any nodes annotate the set of genes to a level which is
extremely improbable if the genes had simply been picked at random.

=head1 TODO

1.  May want the client to decide the behavior for ambiguous names,
    rather than having it hard coded (e.g. always ignore; use if
    standard name (current implementation); use all databaseIds for
    the ambiguous name; decide on a case by case basis (potentially
    useful if running on command line)).

2.  Create new GO::Hypothesis and GO::HypothesisSet objects, so that
    it is easier to access the information generated about the p-value
    etc. of any particular GO node that annotates a set of genes.

3.  Instead of all the global variables, $k..., replace them with
    constants, which may improve runtime, as the optimizer should
    optimize the hash look ups to look like hard-coded strings at
    runtime, rather than variable lookups.

4.  Lots of other stuff....

=cut

use strict;
use warnings;
use diagnostics;

use vars qw ($PACKAGE $VERSION $WARNINGS);

use GO::Node;
use GO::TermFinder::Native;

$VERSION = '0.86';
$PACKAGE = 'GO::TermFinder';

$WARNINGS = 1; # toggle this to zero if you don't want warnings

# class variables

my @kRequiredArgs = qw (annotationProvider ontologyProvider aspect);

my $kArgs                     = $PACKAGE.'::__args';
my $kPopulationNamesHash      = $PACKAGE.'::__populationNamesHash';
my $kBackgroundDatabaseIds    = $PACKAGE.'::__backgroundDatabaseIds';
my $kTotalGoNodeCounts        = $PACKAGE.'::__totalGoNodeCounts';
my $kGoCounts                 = $PACKAGE.'::__goCounts';
my $kGOIDsForDatabaseIds      = $PACKAGE.'::__goidsForDatabaseIds';
my $kDatabaseIds              = $PACKAGE.'::__databaseIds';
my $kTotalNumAnnotatedGenes   = $PACKAGE.'::__totalNumAnnotatedGenes';
my $kCorrectionMethod         = $PACKAGE.'::__correctionMethod';
my $kShouldCalculateFDR       = $PACKAGE.'::__shouldCalculateFDR';
my $kPvalues                  = $PACKAGE.'::__pValues';
my $kDatabaseId2OrigName      = $PACKAGE.'::__databaseId2OrigName';
my $kDistributions            = $PACKAGE.'::__distributions';
my $kDiscardedGenes           = $PACKAGE.'::__discardedGenes';
my $kDirectAnnotationToAspect = $PACKAGE.'::__directAnnotationToAspect';

# the methods by which the p-value can be corrected

my %kAllowedCorrectionMethods = ('bonferroni' => undef,
				 'none'       => undef,
				 'simulation' => undef);

# set up a GO node that corresponds to anything passed in that has no
# annotation

my $kUnannotatedNode = GO::Node->new(goid => "GO:XXXXXXX",
				     term => "unannotated");

my $kFakeIdPrefix    = "NO_DETERMINED_DATABASE_ID_";

#####################################################################
sub new{
#####################################################################
=pod

=head1 Instance Constructor

=head2 new

This is the constructor.  It expects to be passed named arguments for
an annotationProvider, and an ontologyProvider.  In addition, it must
be told the aspect of the ontology provider, so that it knows how to
query the annotationProvider.

There are also some additional, optional arguments:

population:

This argument allows a client to indicate the population that should
used to calculate a background distribution of GO terms.  In the
absence of population argument, then the background distribution will
be drawn from all genes in the annotationProvider.  This should be
provided as an array reference, and no ambiguous names should be
provided (see AnnotationProvider for details of name ambiguity).  This
option is particularly pertinent in a case where for example you
assayed only 2000 genes in a two hybrid experiment, and found 20
interesting ones.  To find significant terms, you need to do it in the
context of the genes that you assayed, not in the context of all genes
with annotation.

Note, new in version 0.71, if you provided a population as the
background distribution from which genes have been drawn, any genes
provided to the findTerms method that are not in the background
distribution will be discarded from the calculations.  The identity of
these genes can be retrieved using the discardedGenes() method, after
the findTerms() method has been called.

totalNumGenes:

This argument allows a client to indicate that the size of the
background distribution is in fact larger that the number of genes
that exist in the annotation provider, and the extra genes are merely
assumed to be entirely unannotated.

NB: This is an API change, as totalNumGenes was previously required.

Thus - if using 'population', the total number of genes considered as
the background will be the number of genes in the provided population.
If not using 'population', then the number of genes that will be
considered as the total population will be the number of genes in the
annotationProvider.  However, if the totalNumGenes argument is
provided, then that number will be used as the size of the population.
If it is not larger than the total number of genes in the
annotationParser, then the number of genes in the annotationParser
will be used.  The totalNumGenes and the population arguments are
mutually exclusive, and both should not be provided at the same time.

Usage ($num is larger than the number of genes with annotations):

   my $termFinder = GO::TermFinder->new(annotationProvider=> $annotationProvider,
                                        ontologyProvider  => $ontologyProvider,
                                        totalNumGenes     => $num,
                                        aspect            => <P|C|F>);


Usage (use all annotated genes as population):

   my $termFinder = GO::TermFinder->new(annotationProvider=> $annotationProvider,
                                        ontologyProvider  => $ontologyProvider,
                                        aspect            => <P|C|F>);

Usage (use a subset of genes as the background population):

   my $termFinder = GO::TermFinder->new(annotationProvider=> $annotationProvider,
                                        ontologyProvider  => $ontologyProvider,
                                        population        => \@genes,
                                        aspect            => <P|C|F>);

=cut

    my ($class, %args) = @_;

    my $self = {};

    bless $self, $class;

    $self->__checkAndStoreArgs(%args);

    $self->__init; # initialize counts for all GO nodes

    return $self;

}

#####################################################################
sub __checkAndStoreArgs{
#####################################################################
# This private method simply checks that all the required arguments
# have been provided, and stores them within the object

    my ($self, %args) = @_;

    # first check that the required arguments were provided

    foreach my $arg (@kRequiredArgs){

	if (!exists ($args{$arg})){

	    die "You did not provide a $arg argument.";

	}elsif (!defined ($args{$arg})){

	    die "Your $arg argument is not defined";

	}

	$self->{$kArgs}{$arg} = $args{$arg}; # store in object

    }

    # store the population, and also create a hash of the population
    # names for quick look up

    if (exists($args{'population'})){

	$self->{$kArgs}{'population'} = $args{'population'};

	my %population;

	foreach my $name (@{$args{'population'}}){

	    $population{$name} = undef;

	}

	$self->{$kPopulationNamesHash} = \%population;

    }

    if (exists($args{'totalNumGenes'})){

	$self->{$kArgs}{'totalNumGenes'} = $args{'totalNumGenes'};

    }

    # now check that we didn't get a funky combination

    if (exists($args{'population'}) && exists($args{'totalNumGenes'})){

	die "The population and totalNumGenes arguments are mutually exclusive, but you have provided both.";

    }

}

#####################################################################
sub __init{
#####################################################################
# This private method determines all counts to all GO nodes, as the
# background frequency of annotations in the genome

    my ($self) = @_;

    # first we determine the databaseIds for the background
    # distribution

    my @databaseIds;

    if ($self->__isUsingPopulation){

	# we need to get databaseids for the provided population

	my ($databaseIdsRef, $databaseId2OrigNameRef) = $self->__determineDatabaseIdsFromGenes($self->__population);

	@databaseIds = @{$databaseIdsRef};	

    }else{

	# we simply use all databaseIds from the annotationProvider

	@databaseIds = $self->__annotationProvider->allDatabaseIds();

    }

    my $populationSize = scalar(@databaseIds);

    # check that they said there's at least as many genes in total
    # as the annotation provider says that there is.    

    if (! defined $self->totalNumGenes){

	# in this case, no 'totalNumGenes' argument was provided

	$self->{$kArgs}{totalNumGenes} = $populationSize;

    }elsif ($populationSize > $self->totalNumGenes){

	# in this case, they are using an annotation provider, and
	# have provided a totalNumGenes that is less than the number
	# of genes that the annotation provider knows about

	if ($WARNINGS){

	    print STDERR "The annotation provider indicates that there are more genes than the client indicated.\n";
	    print STDERR "The annotation provider indicates there are $populationSize, while the client indicated only ", $self->totalNumGenes, ".\n";
	    print STDERR "Thus, assuming the correct total number of genes is that indicated by the annotation provider.\n";

	}

	$self->{$kArgs}{totalNumGenes} = $populationSize;

    }

    # now determine the level of annotation for each GO node in the
    # population of genes to be used as the background distribution

    my $totalNodeCounts = $self->__buildHashRefOfAnnotations(\@databaseIds);

    # adjust those counts if needs be

    if ($populationSize < $self->totalNumGenes){

    	# if there are extra, entirely unannotated genes (indicated by
    	# the total number of genes provided being greater than the
    	# number that existed in the annotation provider), we must
    	# make sure that it's treated that they will at least be
    	# annotated to the root (Gene Ontology), and its immediate
    	# child (which is the name of the Ontology, eg
    	# Biological_process, Molecular_function, and
    	# Cellular_component), and the 'unannotated' node

	# so simply add extra annotations

	my $rootNodeId  = $self->__ontologyProvider->rootNode->goid;
	
	my $childNodeId = ($self->__ontologyProvider->rootNode->childNodes())[0]->goid;

	$totalNodeCounts->{$rootNodeId} = $self->totalNumGenes;

	$totalNodeCounts->{$childNodeId} += ($self->totalNumGenes - $populationSize);

	$totalNodeCounts->{$kUnannotatedNode->goid} += ($self->totalNumGenes - $populationSize);

    }

    # and now store the information

    $self->{$kTotalGoNodeCounts}      = $totalNodeCounts;
    $self->{$kTotalNumAnnotatedGenes} = $populationSize;

    # set the discarded genes to be a reference to an empty list
    # (technically they shouldn't ask to retrieve the discarded genes
    # before calling findTerms, but this will prevent such behavior
    # from being fatal

    $self->{$kDiscardedGenes} = []; 

    # store a hash of the databaseIDs that are in the background set of genes

    my %databaseIds;

    foreach my $databaseId (@databaseIds){

	$databaseIds{$databaseId} = undef;

    }

    $self->{$kBackgroundDatabaseIds} = \%databaseIds;

    # create a Distributions object, which has C code for all the various 
    # Math that we will do.

    $self->{$kDistributions} = GO::TermFinder::Native::Distributions->new($self->totalNumGenes);

}

=pod

=head1 Instance Methods

=cut

#####################################################################
sub findTerms{
#####################################################################
=pod

=head2 findTerms

This method returns an array of hash references, one for each GO::Node
that was tested as a hypothesis, that indicates which terms annotate
the list of genes with what P-values.  The contents of the hashes in
the returned array depend on some of the run time options.  They are:

    key                   value
    -------------------------------------------------------------------------

Always Present:

    NODE                  A GO::Node

    PVALUE		  The P-value for having the observed number of
                          annotations that the provided list of genes
                          has to that node.

    NUM_ANNOTATIONS       The number of genes within the provided list that
                          are annotated to the node.

    TOTAL_NUM_ANNOTATIONS The number of genes in the population (total
                          or provided) that are annotated to the node.

    ANNOTATED_GENES       A hash reference, whose keys are the
                          databaseIds that are annotated to the node,
                          and whose values are the original name
                          supplied to the findTerms() method.

Present if corrected p-values are calculated:

    CORRECTED_PVALUE      The CORRECTED_PVALUE is the PVALUE, but corrected
                          for multiple hypothesis testing, due to the
                          fact that you are more likely to generate
                          significant looking p-values if you test a
                          lot of hypotheses.  See below for details of
                          how this pvalue is calculated, and the
                          options associated with it.

Present if p-values were corrected by simulation:

    NUM_OBSERVATIONS      The number of simulations in which a p-value as
                          good as this one, or better, was observed.

Present if the False Discovery Rate is calculated:

    FDR_RATE              The False Discovery Rate - this is a fraction 
                          of how many of the nodes with p-values as good or 
			  better than the node with this FDR would be expected 
			  to be false positives.

    FDR_OBSERVATIONS      The average number of nodes during simulations 
                          that had an uncorrected p-value as good or better
			  than the p-value of this node.

    EXPECTED_FALSE_POSITIVES The expected number of false positives if this node
                             is chosen as the cut-off.

The entries in the returned array are sorted by increasing p-value
(i.e. least likely is first).  If there is a tie in the p-value, then
the sort order is determined by GOID, using a cmp comparison.

findTerm() expects to be passed, by reference, a list of gene names
for which terms will be found.  If a passed in name is ambiguous (see
AnnotationProvider), then the following will occur:

    1) If the name can be used as a standard name, it will assume that
       it is that.

    2) Otherwise it will not use it.

Currently a warning will be printed to STDOUT in the case of an
ambiguous name being used.

The passed in gene names are converted into a list of databaseIds.  If
a gene does not map to a databaseId, then an undef is put in the list
- however, if the same gene name, which does not map to a databaseId,
is used twice then it will produce only one undef in the list.  If
more than one gene name maps to the same databaseId (either because
you used the same name twice, or you used an alias as well), then that
databaseId is only put into the list once, and a warning is printed.

If a gene name does not have any information returned from the
AnnotationProvider, then it is assumed that the gene is entirely
unannotated.  For these purposes, TermFinder annotates such genes to
the root node (Gene_Ontology), its immediate child (which indicates
the aspect of the ontology (such as biological_process), and a dummy
go node, corresponding to unannotated.  This node will have a goid of
'GO:XXXXXXX', and a term name of 'unannotated'.  No other information
will be set up for this GO::Node, so you should not count on being
able to retrieve it.  What it does mean is that you can determine if
the predominant feature of a set of genes is that they have no
annotation.

If more genes are provided that have been indicated exist in the
genome (as provided during object construction), then an error message
will be printed out, and an empty list will be returned.

In addition, it is possible that for a small list of genes, that no
hypotheses will be tested - in this case, those genes will only have
annotated nodes with a count of 1, other than the Gene_Ontology node
itself, and the node corresponding to the aspect of the ontology.
Neither of these are considered for p-value testing, as a priori they
must have a p-value of 1.

MULTIPLE HYPOTHESIS CORRECTION

An optional argument, 'correction' may be used, which indicates what
method of multiple hypothesis correction should be used.  Multiple
hypothesis correction attempts to keep the overall chance of getting
any false positives at the same level (e.g. 0.05).  Acceptable values
are:

bonferroni, none, simulation

 : 'bonferroni' will correct the p-values by using as the correction
    factor the total number of nodes to which the provided list of
    genes are annotated, either directly or indirectly, excepting any
    nodes that are annotated only once in the background distribution,
    as, a priori, these cannot be overrepresented.

 : 'none' will perform no multiple hypothesis correction

 : 'simulation' will run 1000 simulations with random lists of genes
   (the same size as the originally provided gene list), and determine
   a corrected value by how many simulations produced a p-value better
   than the p-value associated with one of the real hypotheses.
   E.g. if a node from the real data has a p-value of 0.05, but a
   p-value that good or better is generated in 500 out of 1000 trials,
   the corrected pvalue will be 0.5.  In the case that a p-value
   generated from a real list of genes is never seen in the
   simulations, it will be given a corrected p-value of < 0.001, and
   the NUM_OBSERVATIONS attribute of the hypothesis will be 0.  Using
   this option takes 1000 time as long!

The default for this argument, if not provided, is bonferroni.

FALSE DISCOVERY RATE

As a way of preempting the potential problems of using p-values
corrected for multiple hypothesis testing, the False Discovery Rate
can instead be calculated, and you can instead set your cutoff based
on an acceptable false discovery rate, such as 0.01 (1%), or 0.05 (5%)
etc.  Thus, the optional argument 'calculateFDR' can be used.  A
non-zero value means that the False Discovery Rate will be calculated
for each node, such that you can determine, if you chose your p-value
cut-off at that node, what the FDR would be.  The FDR is calculated by
running 50 simulations, and counting the average number of times a
p-value as good or better that a p-value generated from the real data
is seen.  This is used as the numerator.  The denominator is the
number of p-values in the real data that are as good or better than
it.

Usage example - in this example, the default (Bonferroni) correction
is used to calculate a corrected p-value, and in addition, the False
Discovery Rate is also calculated:

    my @pvalueStructures = $termFinder->findTerms(genes        => \@genes,
                                                  calculateFDR => 1);

    my $hypothesis = 1;						    

    foreach my $pvalue (@pvalueStructures){

    print "-- $hypothesis of ", scalar @pvalueStructures, "--\n",

	"GOID\t", $pvalue->{NODE}->goid, "\n",

	"TERM\t", $pvalue->{NODE}->term, "\n",

	"P-VALUE\t", $pvalue->{PVALUE}, "\n",

	"CORRECTED P-VALUE\t", $pvalue->{CORRECTED_PVALUE}, "\n",

        "FALSE DISCOVERY RATE\t", $pvalue->{FDR_RATE}, "\n",
	
        "NUM_ANNOTATIONS\t", $pvalue->{NUM_ANNOTATIONS}, " (of ", $pvalue->{TOTAL_NUM_ANNOTATIONS}, ")\n",

        "ANNOTATED_GENES\t", join(", ", values (%{$pvalue->{ANNOTATED_GENES}})), "\n\n";

        $hypothesis++;

    }

If a background population had been provided when the object was
constructed, you should check to see if any of your genes for which
you are finding terms were discarded, due to not being found in the background 
population, e.g.:

    my @pvalueStructures = $termFinder->findTerms(genes        => \@genes,
                                                  calculateFDR => 1);

    my @discardedGenes = $termFinder->discardedGenes;

    if (@discardedGenes){

        print "The following genes were not considered in the pvalue
calculations, as they were not found in the provided background
population.\n\n", join("\n", @discardedGenes), "\n\n";

    }

=cut

    my ($self, %args) = @_;

    # let's check that they have provided the required information

    $self->__checkAndStoreFindTermsArgs(%args);
    
    # now we determine all the count for direct and indirect
    # annotations for the provided list of genes.

    $self->{$kGoCounts} = $self->__buildHashRefOfAnnotations([$self->genesDatabaseIds]);

    # now we have these counts, and because we determined the counts
    # of the background distribution during object construction, we
    # can determine the p-values for the annotations of our list of
    # genes of interest.

    $self->__calculatePValues;

    # now we want to add in which genes were annotated to each node
    # so that the client can determine them

    $self->__addAnnotationsToPValues;

    # now what we want to do is calculate pvalues that are corrected
    # for multiple hypothesis testing, unless it is specifically
    # requested not to.

    $self->__correctPvalues unless ($self->__correctionMethod eq 'none');    

    # now calculate the False Discovery Rate, if requested to

    $self->__calculateFDR if ($self->__shouldCalculateFDR);

    return $self->__pValues;

}

#####################################################################
sub __checkAndStoreFindTermsArgs{
#####################################################################
# This private method checks the arguments that are passed into the
# findTerms() method, and stores various variables internally.

    my ($self, %args) = @_;

    # check they gave us a list of genes

    if (!exists ($args{'genes'})){

	die "You must provide a genes argument";

    }elsif (!defined ($args{'genes'})){

	die "Your genes argument is undefined";

    }

    # see if they gave us an allowable method by which to correct for
    # multiple hypotheses

    $self->{$kCorrectionMethod} = $args{'correction'} || 'bonferroni';

    if (!exists $kAllowedCorrectionMethods{$self->__correctionMethod}){

	die $self->__correctionMethod." is not an allowed correction method.  Use one of :". 

	    join(", ", keys %kAllowedCorrectionMethods);

    }

    # store whether to calculate the FDR

    if (exists $args{'calculateFDR'} && $args{'calculateFDR'} != 0){

	$self->{$kShouldCalculateFDR} = 1;

    }else{

	# default is not to calculate it
	
	$self->{$kShouldCalculateFDR} = 0;

    }

    # what we want to do now is build up an array of identifiers that
    # are unambiguous - ie databaseIds
    #
    # This means that when retrieving GOID's, we can always retrieve
    # them by databaseId, which is unambiguous.

    my ($databaseIdsRef, $databaseId2OrigNameRef) = $self->__determineDatabaseIdsFromGenes($args{'genes'});
    
    # now we want to make sure that if they provided a population as
    # the background, then all of the provided genes that are being
    # tested for enriched GO terms are sampled from that population

    my @discardedGenes;

    if ($self->__isUsingPopulation){

	my @missingIds;

	# go through each databaseID, and see if it is in the databaseIDs
	# associated with the GO counts for the background population.  If
	# it's a fake ID, then see if the original name is in the names
	# that were passed in.
	
	foreach my $databaseId (@{$databaseIdsRef}){

	    # if it's a fake databaseId, we have to see if the orig
	    # name was in the provided population, otherwise, if it's
	    # a real databaseId, check that the databaseId is in the
	    # background

	    if ((

		 $databaseId =~ /^$kFakeIdPrefix/o &&
		 !$self->__origNameInPopulation($databaseId2OrigNameRef->{$databaseId}))

		||

		!$self->__databaseIdIsInBackground($databaseId)){

		push(@missingIds, $databaseId);

	    }

	}

	# Now see if we have any missing names

	# If we have as many missing names as there were genes
	# provided, then we'll die, as there is nothing that can be
	# done, as no gene remain for any enrichment calculations

	if (@missingIds == @{$databaseIdsRef}){

	    die "None of the genes provided for analysis are found in the background population.\n";

	}

	# Otherwise, we will print a warning that genes were
	# discarded, but we also provide an API for them to retrieve
	# the names of genes that were discarded.

	if (@missingIds){

	    if ($WARNINGS){

		print STDERR "\nThe following names in the provided list of genes do not have a\n",

		"counterpart in the background population that you provided.\n",

		"These genes will not be used in the analysis for enriched GO terms.\n\n";

		foreach my $databaseId (@missingIds){

		    print STDERR $databaseId2OrigNameRef->{$databaseId}, "\n";		    

		}

		print STDERR "\n";

	    }

	    # now we have to actually remove them from the list of
	    # considered genes

	    # create a dummy hash of the databaseIds, delete the
	    # elements, and then assign the remaining keys back to the
	    # $databaseIdsRef

	    # we'll also remember it

	    my %dummyDatabaseIdsHash = %{$databaseId2OrigNameRef};

	    foreach my $databaseId (@missingIds){

		push (@discardedGenes, $databaseId2OrigNameRef->{$databaseId});

		delete $dummyDatabaseIdsHash{$databaseId};

	    }

	    $databaseIdsRef = [keys %dummyDatabaseIdsHash]

	}

    }

    # now remember the genes that were discarded

    $self->__setDiscardedGenes(\@discardedGenes);

    # now store them the databaseIDs for the genes that can be used to
    # determine enriched GO terms in the self object

    $self->{$kDatabaseIds} = $databaseIdsRef;

    # also store the mapping of the databaseId to its original name

    $self->{$kDatabaseId2OrigName} = $databaseId2OrigNameRef;

    # note, we need to provide the client with a way of determining
    # how many genes were used when calculating p-values for
    # annotations

    if (scalar ($self->genesDatabaseIds) > $self->totalNumGenes){

	if ($WARNINGS){

	    print "You have provided a list corresponding to ", scalar ($self->genesDatabaseIds), "genes, ",
	    
	    "yet you have indicated that there are only ", $self->totalNumGenes, " in the genome.\n";
	    
	    print "No probabilities can be calculated.\n";

	}

	return (); # simply return an empty list

    }



}

#####################################################################
sub discardedGenes {
#####################################################################
=pod

=head2 discardedGenes

This method returns an array of genes which were discarded from the
pvalue calculations, because they could not be found in the background
population.  It should only be called after findTerms.  It will either
return an empty list, if no genes were discarded, or an array of genes
that were discarded.

Usage:

    my @pvalueStructures = $termFinder->findTerms(genes        => \@genes,
                                                  calculateFDR => 1);

    my @discardedGenes = $termFinder->discardedGenes;

    if (@discardedGenes){

        print "The following genes were not considered in the pvalue
calculations, as they were not found in the provided background
population.\n\n", join("\n", @discardedGenes), "\n\n";

    }

=cut

    return @{$_[0]->{$kDiscardedGenes}};

}


#
# PRIVATE INSTANCE METHODS
#

#####################################################################
sub __databaseIdIsInBackground{
#####################################################################
# This private method will return a Boolean to indicate whether the
# supplied databaseId is in the set of databaseIds determined for the
# background set of genes.  Note, it does not check if the databaseId
# is a fake one, so the client should do that if it needs to

    return exists $_[0]->{$kBackgroundDatabaseIds}{$_[1]};

}

#####################################################################
sub __isUsingPopulation{
#####################################################################
# This private method returns a boolean to indicate whether the client
# passed in a population of genes to use as the background distribution

    return exists $_[0]->{$kArgs}{population};

}

#####################################################################
sub __population{
#####################################################################
# This private method returns a reference to an array of identifiers
# that were passed in to be used as a background population

    return $_[0]->{$kArgs}{population};

}

#####################################################################
sub __origNameInPopulation{
#####################################################################
# This private method returns a Boolean to indicate whether the
# provided name is in the list of names that were provided as a
# background population

    return exists $_[0]->{$kPopulationNamesHash}{$_[1]};

}

#####################################################################
sub __setDiscardedGenes{
#####################################################################
# This private method will store the passed in array reference, which
# points to a list of genes that had to be discarded.

    $_[0]->{$kDiscardedGenes} = $_[1];

}

#####################################################################
sub __totalNumAnnotatedGenes{
#####################################################################
# This private method returns the number of genes that have any annotation,
# as determined from the AnnotationProvider.  This is set during object
# initialization.

    return $_[0]->{$kTotalNumAnnotatedGenes};

}

#####################################################################
sub __numAnnotatedNodesInBackground{
#####################################################################
# This private method returns the number of nodes in the ontology that
# have any annotation in the background distribution.  This is stored
# during object initialization as a hash of GOID to the number of
# counts.

    return scalar keys %{$_[0]->{$kTotalGoNodeCounts}};

}

#####################################################################
sub __allGoIdsForBackground{
#####################################################################
# This private method returns as an array all the GOIDs of nodes in
# the ontology that have any annotation in the background
# distribution.  This is stored during object initialization as a hash
# of GOID to the number of counts.

    return keys %{$_[0]->{$kTotalGoNodeCounts}};

}

#####################################################################
sub genesDatabaseIds{
#####################################################################
=pod 

=head2 genesDatabaseIds

This method returns an array of databaseIds corresponding to the genes
that were used for the findTerms() method.  Thus it allows a client to
find out how many actual entities their list of genes that were passed
in mapped to, e.g. they may have passed in the same thing with two
different names.  Using this method, immediately following use of the
findTerms method, they will determine how many genes their list
collapsed to.

=cut

    return @{$_[0]->{$kDatabaseIds}};

}

#####################################################################
sub __origNameForDatabaseId{
#####################################################################
# This method returns the original name that was provided to the term
# finder for the databaseId that it was translated to.

    return $_[0]->{$kDatabaseId2OrigName}->{$_[1]};

}

#####################################################################
sub __pValues{
#####################################################################
# This method returns an array of pValues structures

    return @{$_[0]->{$kPvalues}};

}

#####################################################################
sub __correctionMethod{
#####################################################################
# This method returns the name of the method by which the client has
# chosen to have their p-values corrected - either none, bonferroni,
# custom, or simulation.

    return $_[0]->{$kCorrectionMethod};

}

#####################################################################
sub __shouldCalculateFDR{
#####################################################################
# This method returns a boolean, to indicate whether the false discovery
# rate should be calculated

    return $_[0]->{$kShouldCalculateFDR};

}

#####################################################################
sub __determineDatabaseIdsFromGenes{
#####################################################################
# This method determines a list of databaseIds for a list of genes
# passed in by reference.  It then returns a reference to that list,
# and a reference to a hash that maps the databaseIds to the
# originally supplied name
#
# If more than one gene maps to the same databaseId, then the
# databaseId is only put in the list once, and a warning is printed.
#
# If a gene does not map to a databaseId, then an undef is put in the
# list - however, if the same gene name, which does not map to a
# databaseId, is used twice then it will produce only one undef in the
# list.
#
# In addition, it removes leading and trailing whitespace from supplied
# gene names (assuming they should have none) and will skip any names that
# are either empty, or whitespace only.

    my ($self, $genesRef) = @_;

    my (@databaseIds, $databaseId, %databaseIds, %genes, %duplicates, %warned);

    foreach my $gene (@{$genesRef}){

	# strip leading and trailing spaces

	$gene =~ s/^\s+//;
	$gene =~ s/\s+$//;

	next if $gene eq ""; # skip empty names

	# skip and warn if we've already seen the gene

	if (exists ($genes{$gene})){

	    if ($WARNINGS && !exists($warned{$gene})){

		print "The gene name '$gene' was used more than once.\n";
		print "It will only be considered once.\n\n";
		
		$warned{$gene} = undef;

	    }

	    next; # just skip to the next supplied gene

	}

	# determine if the gene is ambiguous

	if ($self->__annotationProvider->nameIsAmbiguous($gene)){

	    print "$gene is an ambiguous name.\n" if $WARNINGS;

	    if ($self->__annotationProvider->nameIsStandardName($gene)){

		if ($WARNINGS){

		    print "Since $gene is used as a standard name, it will be assumed to be one.\n\n";
	
		}

		$databaseId = $self->__annotationProvider->databaseIdByStandardName($gene);
	
		push (@databaseIds, $databaseId);
		
	    }else{
		
		if ($WARNINGS){

		    print "Since $gene is an ambiguous alias, it will not be used.\n\n";
		
		}

	    }
	    
	}else{

	    # note, if the gene has no annotation, then we will want
	    # to create a fake databaseId, that we can easily
	    # recognize, and will have to make sure that we deal with
	    # this later when getting annotations.

	    $databaseId = $self->__annotationProvider->databaseIdByName($gene);

	    # if the total number of genes is equal to the number of
	    # things with some annotation, then there should be no
	    # genes that do not return a databaseId.  If this is the
	    # case, we will warn them.

	    if (!defined $databaseId){

		# If we've already defined the total number of genes
		# with annotation, and it's equal to the number of
		# genes for the background distribution, and we're not
		# using a population, we'll print a warning, as under
		# these circumstances we shouldn't not get a
		# databaseId.

		if (defined ($self->__totalNumAnnotatedGenes) && 
		    $self->__totalNumAnnotatedGenes == $self->totalNumGenes &&
		    $WARNINGS &&
		    !$self->__isUsingPopulation){

		    print "\nThe name '$gene' did not correspond to an entry from the AnnotationProvider.\n";
		    print "However, the client has indicated that all genes have annotation.\n";
		    print "You should probably check that '$gene' is a real name.\n\n";

		}

		# Now we need to deal with the lack of databaseId
		# We'll simply create a fake one, that we can easily
		# recognize later, so we can deal with it accordingly

		$databaseId = $kFakeIdPrefix.$gene;

	    }

	    push (@databaseIds, $databaseId);

	}

	# if we have a databaseId that we've already seen, we want to
	# make sure we only consider it once.

	if (defined ($databaseId) && exists($databaseIds{$databaseId})){
	    
	    pop (@databaseIds); # get rid of the extra

	    # and let's remember what it was, as well as the previous
	    # name associated with this databaseId, so we can give an
	    # appropriate warning

	    $duplicates{$databaseId}{$gene} = undef;
	    $duplicates{$databaseId}{$databaseIds{$databaseId}} = undef;
	    

	}

	# remember the databaseId and gene, in case we see them again

	$databaseIds{$databaseId} = $gene if (defined ($databaseId));
	$genes{$gene}             = undef;

    }


    if (%duplicates && $WARNINGS){
	
	print "The following databaseIds were represented multiple times:\n\n";

	foreach my $duplicate (sort keys %duplicates){

	    print $duplicate, " represented by ", join(", ", (sort keys %{$duplicates{$duplicate}})), "\n";

	}

	print "\nEach of these databaseIds will only be considered once.\n";

    }

    # return databaseIds, and their mapping to the originally supplied
    # name

    return (\@databaseIds, \%databaseIds);

}

############################################################################
sub __buildHashRefOfAnnotations{
############################################################################
# This private method takes a reference to an array of databaseIds and
# calculates the level of annotations for all GO nodes that those
# databaseIds have either direct or indirect annotation for.  It
# returns a reference to a hash of GO node counts, with the goids
# being the keys, and the number of annotations they have from the
# list of databaseId's being the values.

    my ($self, $databaseIdsRef) = @_;

    my %goNodeCounts;

    # keep track of how many are annotated to the aspect node
    # (e.g. such as molecular function).  See comments for
    # __allGOIDsForDatabaseId for more information

    my $aspectNodeDirectAnnotations = 0;

    my $aspectNodeGoid = ($self->__ontologyProvider->rootNode->childNodes())[0]->goid;

    # If gene has no annotation, annotate it to the top node
    # (Gene_Ontology), and its immediate child (the aspect itself) and
    # the 'unannotated' node.

    my @noAnnotationNodes = ($aspectNodeGoid, 
			     $self->__ontologyProvider->rootNode->goid,
			     $kUnannotatedNode->goid);

    foreach my $databaseId (@{$databaseIdsRef}) {

	# get goids count, if the databaseId is not a fake one

	my $goidsRef;

	if ($databaseId !~ /^$kFakeIdPrefix/o){

	    $goidsRef = $self->__allGOIDsForDatabaseId($databaseId);

	}

	if (!defined $goidsRef || !(@{$goidsRef})) { 

	    # If gene has no annotation, annotate it to the top node
	    # (Gene_Ontology), and its immediate child (the aspect itself)
	    # and the 'unannotated' node, which we cached earlier.

	    $goidsRef = [@noAnnotationNodes];

	    # now cache the goids for the unnannotated genes.  The
	    # ones that were annotated, had their goids cached in the
	    # __allGOIDsForDatabaseId.  It is an optimization to take
	    # care of that there, but this here.

	    $self->{$kGOIDsForDatabaseIds}->{$databaseId} = $goidsRef;
	    
	}

	# increment count for all goids appearing in @goids;

	foreach my $goid (@{$goidsRef}) {

	    $goNodeCounts{$goid}++;

	}

	# keep count of how many are directly annotated to the aspect node

	if (exists ($self->{$kDirectAnnotationToAspect}{$databaseId})){

	    $aspectNodeDirectAnnotations++;

	}

    }

    # now we'd like to replace the counts for the aspect annotations,
    # so that they only refer to the direct annotations, rather than
    # direct and indirect annotations

    $goNodeCounts{$aspectNodeGoid} = $aspectNodeDirectAnnotations;

    return \%goNodeCounts;

}

############################################################################
sub __allGOIDsForDatabaseId{
############################################################################
# This method returns a reference to an array of all GOIDs to which a
# databaseId is annotated, whether explicitly, or implicitly, by
# virtue of the GO node being an ancestor of an explicitly annotated
# one.  The returned array contains no duplicates.

# Because the Gene Ontology no longer has the unknown terms, then
# direct annotation to the aspect node (e.g. molecular function),
# means what annotation to the unknown terms previously meant.  But,
# as all nodes are descendents of the aspect node, then enrichment for
# this node will never happen, unless we only look for enrichment of
# direct annotations to this node.  Thus, in this method, we also
# record which databaseIds are directly annotated to the aspect node, which
# will be used elsewhere.

    my ($self, $databaseId) = @_;
    
    # cache aspect's ID, so we don't have to repeatedly retrieve it

    my $aspectId = ($self->__ontologyProvider->rootNode->childNodes())[0]->goid; # 

    # generate list of GOIDs if not cached
    
    if (!exists($self->{$kGOIDsForDatabaseIds}->{$databaseId})) {
	
	my %goids; # so we keep the list unique	

        # go through the direct annotations

	foreach my $goid (@{$self->__annotationProvider->goIdsByDatabaseId(databaseId => $databaseId,
									   aspect     => $self->aspect)}){

	    # just in case an annotation is to a goid not present in the ontology

	    if (!$self->__ontologyProvider->nodeFromId($goid)){

		if ($WARNINGS){

		    print STDERR "\nWarning : $goid, used to annotate $databaseId with an aspect of ".$self->aspect.", does not appear in the provided ontology.\n";
		    
		}
		    
		# don't record annotations to this goid

		next;

	    }

	    # record the goid and its ancestors

	    $goids{$goid} = undef;

	    foreach my $ancestor ($self->__ontologyProvider->nodeFromId($goid)->ancestors){

		$goids{$ancestor->goid} = undef;

	    }

	    # record in the self object if it's directly annotated to the aspectId

	    if ($goid eq $aspectId){

		$self->{$kDirectAnnotationToAspect}{$databaseId} = undef;

	    }

	}    
	
	# cache the value
	
	$self->{$kGOIDsForDatabaseIds}->{$databaseId} = [keys %goids];
	
    }
    
    return ($self->{$kGOIDsForDatabaseIds}->{$databaseId});
    
}

#####################################################################
sub __calculatePValues{
#####################################################################
# This method actually determines the p-values of the various levels
# of annotation for the particular GO nodes, and stores them within
# the object.

    my $self = shift;

    my $numDatabaseIds = scalar $self->genesDatabaseIds;

    my @pvalueArray;

    # cache so we don't have to repeatedly look it up

    my $rootGoid = $self->__ontologyProvider->rootNode->goid;

    # each node we consider here must have at least one annotation in
    # our list of provided genes.

    foreach my $goid ($self->__allGoIdsForList) {

	# skip the root node, as it has to have a probability of 1,
	# but don't skip its immediate child though, as we now test
	# for enriched direct annotations

	next if ($goid eq $rootGoid);

	# skip any that has only one (or zero - could happen for the
	# aspect goid, as we replaced its counts) annotation in the
	# background distribution, as by definition these cannot be
	# overrepresented

	next if ($self->__numAnnotationsToGoId($goid) <= 1);

	# if we get here, we should calculate a p-value for this node

	push (@pvalueArray, $self->__processOneGOID($goid, $numDatabaseIds));

    }

    # now sort the pvalueArray by their pValues.  If the values are the same,
    # then sort by goid (text based comparison).

    @pvalueArray = sort {$a->{PVALUE}     <=> $b->{PVALUE} ||
			 $a->{NODE}->goid cmp $b->{NODE}->goid } @pvalueArray;

    $self->{$kPvalues} = \@pvalueArray;

}

############################################################################
sub __processOneGOID{
############################################################################
# This processes one GOID.  It determines the number of annotations to
# the current GOID, and the P-value of that number of annotations.
# The pvalue is calculated as the probability of observing x or more
# positives in a sample on n, given that there are M positives in a
# population of N.  This is calculated using the hypergeometric
# distribution.
#
# It returns a hash reference encoding that information.

    my ($self, $goid, $n) = @_;

    my $M = $self->__totalNumAnnotationsToGoId($goid);
    my $x = $self->__numAnnotationsToGoId($goid);
    my $N = $self->totalNumGenes();

    # logic checking on data

    if (($N - $M) < ($n - $x)){

	# this situation should never arise, because the number of
	# failures in the sampling cannot exceed the total number of
	# failures in the population.  For example, if all but one
	# gene has a particular annotation, then you can't pick 3
	# genes and get 2 without it

	die 'For $N, $M, $n, $x being '."$N, $M, $n, $x, ".'($N - $M) < ($n - $x) which is impossible'."\n";
	
    }

    my $pvalue;

    if ($M == $N){

	# the p-value must be equal to 1, so we don't even need to
	# bother calling the p-value code

	$pvalue = 1;

    }else{

	$pvalue = $self->{$kDistributions}->pValueByHypergeometric($x, $n, $M, $N);

    }

    my $node = $self->__ontologyProvider->nodeFromId($goid) || $kUnannotatedNode;

    my $hashRef = {
	
	NODE                  => $node,
	PVALUE		      => $pvalue,
	NUM_ANNOTATIONS       => $x,
	TOTAL_NUM_ANNOTATIONS => $M

	};

    return $hashRef;

}

############################################################################
sub __numAnnotationsToGoId{
############################################################################
# This private method returns the number of annotations to a
# particular GOID for the list of genes supplied to the findTerms
# method.

    my ($self, $goid) = @_;

    return $self->{$kGoCounts}->{$goid};

}

############################################################################
sub __totalNumAnnotationsToGoId{
############################################################################
# This returns the total number of genes that have been annotated to a
# particular GOID based on all annotations.

    my ($self, $goid) = @_;

    return $self->{$kTotalGoNodeCounts}->{$goid};
}

############################################################################
sub totalNumGenes{
############################################################################
=pod

=head2 totalNumGenes

This returns the total number of genes that are in the background set
of genes from which the genes of interest were drawn.  Unannotated
genes are included in this count.

=cut

    return $_[0]->{$kArgs}{totalNumGenes};

}

############################################################################
sub __allGoIdsForList{
############################################################################
# This returns an array of GOIDs to which genes in the passed in gene
# list were directly or indirectly annotated.

    return keys %{$_[0]->{$kGoCounts}};

}

############################################################################
sub __correctPvalues{
############################################################################
# This method corrects the pvalues for multiple hypothesis testing, by
# dispatching to the appropriate method based on what method was
# requested for hypothesis correction.

    my $self = shift;

    my $correctionMethod = "__correctPvaluesBy".$self->__correctionMethod;

    $self->$correctionMethod;

}

#####################################################################
sub __correctPvaluesBybonferroni{
#####################################################################
# This method corrects the p-values using a Bonferroni correction,
# where the correction factor is the total number of nodes for which
# we tested whether there was significant enrichment

    my $self = shift;

    # now correct the pvalues with the correction factor

    my $correctionFactor = scalar(@{$self->{$kPvalues}});

    # no correction needs to be done if there is 0 or 1 hypotheses
    # that were tested

    if ($correctionFactor > 1){

	# simply go through each hypothesis and calculate the corrected
	# p-value by multiplying the uncorrected p-value by the number of
	# nodes in the ontology

	foreach my $hypothesis ($self->__pValues){

	    $hypothesis->{CORRECTED_PVALUE} = $hypothesis->{PVALUE} * $correctionFactor;

	    # make sure we have a ceiling of 1

	    $hypothesis->{CORRECTED_PVALUE} = 1 if ($hypothesis->{CORRECTED_PVALUE} > 1);

	}

    }

}

############################################################################
sub __correctPvaluesBysimulation{
############################################################################
# This method corrects the P-values based on a thousand random trials,
# using the same number of genes for each trial as was used in the
# client query.  A p-value will be corrected based on the number of
# simulations in which that p-value was seen, e.g. if an uncorrected
# p-value of 0.05 or better was observed in 100 of 1000 trials, the
# corrected value will be 0.1 (100/1000).

    my $self = shift;

    # when we run any simulation, any of the variables that get
    # modified during the findTerms method will be trampled on - thus
    # we have to save them away, and then restore them afterwards

    my $variables = $self->__saveVariables();

    # we will need access to the real hypotheses - we'll reverse them
    # for now, as it makes them easier when we use them later on

    my @realHypotheses = reverse @{$self->{$kPvalues}};

    # now let's get the population from which we will sample genes
    # randomly

    my @names = $self->__samplingPopulation;

    my $populationSize = scalar @names;

    # now get the number of genes in the original test set
    # for which terms were found.
    
    my $numGenes = scalar $self->genesDatabaseIds;

    # now we can finally run the simulations

    my $numSimulations = 1000;

    for (my $i = 1; $i <= $numSimulations; $i++) {

	# run simulation

	my @pvals = $self->__runOneSimulation(\@names, $numGenes, $populationSize);

	# go onto a new simulation if no hypothese resulted (which is
	# possible if the randomly selected genes did not have more
	# than one annotation to any particular GO node)

	next if !@pvals;

	# now we look at the best pvalue for the random genes, and
	# determine whether it is more significant that any of the
	# p-values generated for the real genes.  We will keep a count
	# of how many times we see a p-value that is better than one
	# calculated with the real genes, on a per simulation basis

	# if we go through the p-values for the real nodes in reverse
	# order (we reversed them above), then we can quit out of the
	# loop as soon as we have a p-value better than the best one
	# generated from the random genes

	foreach my $realHypothesis (@realHypotheses){

	    # skip examining, if the real pvalue is better than the
	    # best one for the random genes

	    last if ($pvals[0]->{PVALUE} > $realHypothesis->{PVALUE});

	    # if we get here, we know that this simulation has generated
	    # a P_VALUE that is better than the P_VALUE for the currently
	    # considered hypothesis.  We'll simply keep count for now

	    $realHypothesis->{NUM_OBSERVATIONS}++;

	}

    }

    # now we've run all the simulations, we should be able to simply divide
    # the observed frequency by the number of simulations.

    foreach my $realHypothesis (@realHypotheses){

	if (exists $realHypothesis->{NUM_OBSERVATIONS}){

	    $realHypothesis->{CORRECTED_PVALUE} = $realHypothesis->{NUM_OBSERVATIONS}/$numSimulations;

	}else{

	    # a pvalue better than this wasn't observed in any
	    # simulation - just record the minimum

	    $realHypothesis->{CORRECTED_PVALUE} = 1/$numSimulations;

	    # and say that we never saw it

	    $realHypothesis->{NUM_OBSERVATIONS} = 0;

	}

    }

    @realHypotheses = reverse @realHypotheses;

    # now restore the variables

    $self->__restoreVariables($variables);

    # finally replace the hypotheses with our local copy, which we've
    # made some modifications to

    $self->{$kPvalues} = \@realHypotheses;

}

############################################################################
sub __saveVariables{
############################################################################
# This private method returns a hash containing various of the
# instance variables that might get trampled on during a simulation

    my ($self) = @_;

    my %variables;

    my @keys = ($kCorrectionMethod, $kShouldCalculateFDR, $kDatabaseIds, 
		$kDatabaseId2OrigName, $kGoCounts, $kPvalues, $kDiscardedGenes);

    foreach my $key (@keys){

	$variables{$key} = $self->{$key};

    }

    return \%variables;

}

############################################################################
sub __restoreVariables{
############################################################################
# This private method uses a passed in hash (by reference) to restore
# variables within the instance

    my ($self, $hashRef) = @_;

    foreach my $key (%{$hashRef}){

      $self->{$key} = $hashRef->{$key};

    }

}

############################################################################
sub __samplingPopulation{
############################################################################
# This private method returns an array of id's that should be used as
# the sampling population for the simulation

    my $self = shift;

    # we will need to pick genes randomly from the background
    # population.  Note that population may be larger than the
    # databaseIds that are referenced in the annotations file - if so,
    # we have to be able to randomly select unannotated genes too

    # alternatively, the user may have specified a population of genes
    # that define the background - in which case we should pick only
    # from that population

    my @names;

    if ($self->__isUsingPopulation){

	@names = @{$self->__population};

    }else{

	# we simply use all databaseIds from the annotationProvider

	@names = $self->__annotationProvider->allDatabaseIds();

    }

    # note the population size

    my $populationSize;

    if (! defined $self->totalNumGenes){

	$populationSize = scalar @names;

    }else{

	$populationSize = $self->totalNumGenes;

    }

    # now, if the population from which we should sample is bigger
    # that the number of databaseIds which we have to sample from, we
    # want to expand the the list of databaseIds with some fake ones,
    # that correspond to unnannotated genes.

    my $numDatabaseIds = scalar @names;

    for (my $n = $numDatabaseIds; $n < $populationSize; $n++){
	
	push (@names, $kFakeIdPrefix.$n);
	    
    }

    return @names;

}

############################################################################
sub __runOneSimulation{
############################################################################
# This method runs a single simulation of GO::TermFinder, and returns the 
# generated hypotheses.  It requires a reference to a list of genes that
# should be used to sample from, the number of genes that should be chosen,
# and the size of the background distribution

    my ($self, $namesRef, $numGenes, $populationSize) = @_;

    # first get a random list of genes

    my $listRef = $self->__listOfRandomGenes($namesRef, $numGenes, $populationSize);	

    # now we have a list of genes, we can findTerms for them
	
    # however, we have to make sure that for these guys, we attempt
    # no p-value correction, otherwise we will infinitely recurse,
    # and make sure that we don't ask to calculate the FDR
    
    my @pvals = $self->findTerms(genes        => $listRef,
				 correction   => 'none',
				 calculateFDR => 0);

    # now return the hypotheses

    return (@pvals);

}

############################################################################
sub __listOfRandomGenes{
############################################################################
# This private method returns a reference to an array of randomly
# chosen genes from a population that was passed in by reference

    my ($self, $namesRef, $numGenes, $populationSize) = @_;

    # create an array with as many indices as there are genes in the
    # background set of genes from which those of interest were drawn

    my @indices;

    for (my $i = 0; $i < $populationSize; $i++){

	$indices[$i] = $i;

    }

    # now sample those indices, removing sampled elements as we go.
    # Use the randomly chosen index to get a random gene, and select
    # as many random genes as were in the test set

    my @list;

    for (my $i = 0; $i < $numGenes; $i++) {

	my $index = int(rand(scalar(@indices))); # random number between 0 and last array index.

	my $selectedIndex = splice(@indices, $index, 1); # Remove the randomly selected element from the array.

	push(@list, $namesRef->[$selectedIndex]);

    }

    return \@list;

}

############################################################################
sub __calculateFDR{
############################################################################
# This method calculates the false discovery rate for each hypothesis,
# such that you know if you draw your cut-off at a particular node,
# what the false discovery rate is.  It does 50 simulations with
# random genes, and calculates on average the percentage of nodes that
# exceed a given value in the simulation, compared to the number that
# exceed that p-value in the real data.

    my $self = shift;

    # when we run any simulation, any of the variables that get
    # modified during the findTerms method will be trampled on - thus
    # we have to save them away, and then restore them afterwards

    my $variables = $self->__saveVariables();

    # we will need access to the real hypotheses

    my @realHypotheses = @{$self->{$kPvalues}};

    # now let's get the population from which we will sample genes
    # randomly

    my @names = $self->__samplingPopulation;

    my $populationSize = scalar @names;

    # now get the number of genes in the original test set
    # for which terms were found.
    
    my $numGenes = scalar $self->genesDatabaseIds;

    # now we can finally run the simulations

    my $numSimulations = 50;

    for (my $i = 1; $i <= $numSimulations; $i++) {

	# now run a simulation

	my @pvals = $self->__runOneSimulation(\@names, $numGenes, $populationSize);

	# go onto a new simulation if no hypotheses resulted (which is
	# theoretically possible if the randomly selected genes did
	# not have more than one annotation to any particular GO node)

	next if !@pvals;

	# now we look at the best pvalue for the random genes, and
	# determine whether it is more significant that any of the
	# p-values generated for the real genes.  We will keep a count
	# of how many times we see a p-value that is better than one
	# calculated with the real genes, on a per simulation basis

	# if we go through the p-values for the real nodes in reverse
	# order (we reversed them above), then we can quit out of the
	# loop as soon as we have a p-value better than the best one
	# generated from the random genes

	foreach my $realHypothesis (@realHypotheses){

	    # count the number of nodes that this simulation has
	    # generated a P_VALUE that is better than the P_VALUE for
	    # the currently considered hypothesis.

	    foreach my $pval (@pvals){

		# finish considering this real hypothesis as soon as
		# we see a pvalue that is worse from the simulated
		# data

		last if ($pval->{PVALUE} > $realHypothesis->{PVALUE});

		# if we get here, our simulated pvalue must exceed the
		# pvalue associated with the real hypothesis

		$realHypothesis->{FDR_OBSERVATIONS}++;
		
	    }

	}

    }

    # now we've run all the simulations, and counted for each real
    # hypothesis how many hypotheses from the simulations were better,
    # we calculate on average how many were better per simulation,
    # then divide by the number of hypotheses as good or better in our
    # real data.  We threshold this at a maximum of 1, as we can't
    # have a FDR of greater than 100%

    foreach (my $i = 0; $i < @realHypotheses; $i++){

	if (exists $realHypotheses[$i]->{FDR_OBSERVATIONS}){

	    # the rate is the average number in the simulations that
	    # are better than this pvalue, divided by the number that
	    # are better in the real data

	    $realHypotheses[$i]->{FDR_OBSERVATIONS} /= $numSimulations;

	    $realHypotheses[$i]->{FDR_RATE} = $realHypotheses[$i]->{FDR_OBSERVATIONS} / ($i + 1);

	    if ($realHypotheses[$i]->{FDR_RATE} > 1){

		$realHypotheses[$i]->{FDR_RATE} = 1;

	    }	    

	}else{

	    # a pvalue better than this wasn't observed in any
	    # simulation - so the FDR should be 0

	    $realHypotheses[$i]->{FDR_RATE} = 0;

	    # and say that we never saw it

	    $realHypotheses[$i]->{FDR_OBSERVATIONS} = 0;

	}

	# now based on the FDR, and the number of hypotheses that would
	# be chosen at this point, we can calculate the expected number of
	# false positives, as the FDR x the number of hypotheses

	$realHypotheses[$i]->{EXPECTED_FALSE_POSITIVES} = $realHypotheses[$i]->{FDR_RATE} * ($i+1);	

    }

    # now restore the variables

    $self->__restoreVariables($variables);

    # finally we want to replace our real hypotheses with our local
    # copy, as we've made some changes

    $self->{$kPvalues} = \@realHypotheses;

}

############################################################################
sub __addAnnotationsToPValues{
############################################################################
# This method looks through the annotated nodes, and adds in information
# about which genes are annotated to them, so that the client can retrieve
# that information.

    my $self = shift;

    # to do this, we can take advantage of the fact that all the
    # nodes should have all their databaseIds cached, and we can
    # retrieve them through the __allGOIDsForDatabaseId() method

    # first go through the annotated nodes, and simply hash the goid to the
    # entry in the pValues array

    my %nodeToIndex;

    for (my $i = 0; $i < @{$self->{$kPvalues}}; $i++){
    
	$nodeToIndex{$self->{$kPvalues}->[$i]->{NODE}->goid} = $i;

    }

    # now go through each databaseId, and add the information in

    foreach my $databaseId ($self->genesDatabaseIds) {

	# look at all goids for this database id

	foreach my $goid (@{$self->__allGOIDsForDatabaseId($databaseId)}){
	    
	    next if (! exists $nodeToIndex{$goid}); # this node wasn't a hypothesis
	    
	    # if this goid was a hypothesis, we can annotate the
	    # corresponding hypothesis with the gene

	    $self->{$kPvalues}->[$nodeToIndex{$goid}]->{ANNOTATED_GENES}->{$databaseId} = $self->__origNameForDatabaseId($databaseId);
	    
	}

    }

}

############################################################################
sub __annotationProvider{
############################################################################
# This private method returns the annotationProvider that was used
# during construction.

    return $_[0]->{$kArgs}{annotationProvider};

}

############################################################################
sub __ontologyProvider{
############################################################################
# This private methid returns the ontologyProvider that was used
# during construction.

    return $_[0]->{$kArgs}{ontologyProvider};

}

############################################################################
sub aspect{
############################################################################
=pod

=head2 aspect

Returns the aspect with the the GO::TermFinder object was constructed.

Usage:

    my $aspect = $termFinder->aspect;

=cut

    return $_[0]->{$kArgs}{aspect};

}

1; # to make perl happy


__END__

#####################################################################
#
#  Additional POD Documentation from here on down
#
#####################################################################

=pod

=head1 Authors

    Gavin Sherlock; sherlock@genome.stanford.edu
    Elizabeth Boyle; ell@mit.edu
    Ihab Awad; ihab@genome.stanford.edu

=cut
