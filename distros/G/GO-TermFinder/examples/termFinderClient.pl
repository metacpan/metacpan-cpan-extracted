#!/usr/bin/perl

# $Id: termFinderClient.pl,v 1.9 2007/03/18 05:46:39 sherlock Exp $

# License information (the MIT license)

# Copyright (c) 2003-2007 Gavin Sherlock; Stanford University

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

use strict;
use warnings;
use diagnostics;

use GO::TermFinder;
use GO::AnnotationProvider::AnnotationParser;
use GO::OntologyProvider::OboParser;

use GO::TermFinderReport::Text;

use GO::Utils::File qw (GenesFromFile);

print "Enter the fully qualified name of your obo file:\n";

chomp(my $ontologyFile = <STDIN>);

print "What is the aspect of this ontology (F, P, or C)?\n";

chomp(my $aspect = uc(<STDIN>));

print "Enter the fully qualified name of your associations file:\n";

chomp(my $annotationFile = <STDIN>); 

print "Enter a the fully qualified name of your file with a list of genes for which to find term:\n";

chomp(my $genesFile = <STDIN>);

print "How many genes (roughly) exist within the organism?\n";

chomp(my $totalNum = <STDIN>);

print "Finding terms...\n";

my $ontology   = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
						      aspect       => $aspect);

my $annotation = GO::AnnotationProvider::AnnotationParser->new(annotationFile=>$annotationFile);

my $termFinder = GO::TermFinder->new(annotationProvider => $annotation,
				     ontologyProvider   => $ontology,
				     totalNumGenes      => $totalNum,
				     aspect             => $aspect);

my @genes = GenesFromFile($genesFile);

my @pvalues    = $termFinder->findTerms(genes        => \@genes,
					calculateFDR => 1);

# now just print the info back to the client

my $report = GO::TermFinderReport::Text->new();

my $cutoff = 0.05;

my $numHypotheses = $report->print(pvalues  => \@pvalues,
				   numGenes => scalar(@genes),
				   totalNum => $totalNum,
				   cutoff   => $cutoff);

# if they had no significant P-values

if ($numHypotheses == 0){
    
    print "No terms were found for this aspect with a corrected P-value <= $cutoff.\n";
    
}

=pod

=head1 NAME

termFinderClient.pl - interactive client to find significant GO terms for a list of genes

=head1 SYNOPSIS

This program is a very simply client for the GO::TermFinder object,
that prompts a user for the various pieces of information that are
required to determine significant GO terms associated with the list of
genes.  It uses a p-value cut-off (for the corrected p-value) of .05,
and simply prints the information back to the screen.  An example
below uses the genes : YPL250C, MET11, MXR1, MET17, SAM3, MET28, STR3,
MMP1, MET1, YIL074C, MHT1, MET14, MET16, MET3, MET10, ECM17, MET2,
MUP1 and MET6, which formed the so called methionine cluster from
Spellman et al, 1998:

    > termFinderClient.pl
    Enter the fully qualified name of your obo file:
    ../t/gene_ontology_edit.obo
    What is the aspect of this ontology you want to use (F, P, or C)?
    P
    Enter the fully qualified name of your associations file:
    ../t/gene_association.sgd
    Enter a the fully qualified name of your file with a list of genes for which to find term:
    genes.txt
    How many genes (roughly) exist within the organism?
    7300
    Finding terms...
    -- 1 of 37 --
    GOID    GO:0006790
    TERM    sulfur metabolism
    CORRECTED P-VALUE       1.47659150177758e-22
    UNCORRECTED P-VALUE     3.99078784264211e-24
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 59 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET10, MET1, MET11, MET2, MET16, MET17
    
    -- 2 of 37 --
    GOID    GO:0000096
    TERM    sulfur amino acid metabolism
    CORRECTED P-VALUE       4.5287552955708e-21
    UNCORRECTED P-VALUE     1.22398791772184e-22
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 11 of 19 in the list, vs 32 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, MET17
    
    -- 3 of 37 --
    GOID    GO:0006555
    TERM    methionine metabolism
    CORRECTED P-VALUE       1.70050438966192e-17
    UNCORRECTED P-VALUE     4.59595780989708e-19
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 9 of 19 in the list, vs 23 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET1, MET11, MET3, STR3, MET2, MET16, MET17, MET6
    
    -- 4 of 37 --
    GOID    GO:0006520
    TERM    amino acid metabolism
    CORRECTED P-VALUE       9.54842088570323e-16
    UNCORRECTED P-VALUE     2.58065429343331e-17
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 184 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, YIL074C, MET17
    
    -- 5 of 37 --
    GOID    GO:0000097
    TERM    sulfur amino acid biosynthesis
    CORRECTED P-VALUE       1.01918487720888e-15
    UNCORRECTED P-VALUE     2.75455372218618e-17
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 7 of 19 in the list, vs 10 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, MET28, MET17, MET6
    
    -- 6 of 37 --
    GOID    GO:0006519
    TERM    amino acid and derivative metabolism
    CORRECTED P-VALUE       2.70276218187099e-15
    UNCORRECTED P-VALUE     7.30476265370537e-17
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 199 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, YIL074C, MET17
    
    -- 7 of 37 --
    GOID    GO:0009308
    TERM    amine metabolism
    CORRECTED P-VALUE       1.14774161056767e-14
    UNCORRECTED P-VALUE     3.10200435288561e-16
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 222 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, YIL074C, MET17
    
    -- 8 of 37 --
    GOID    GO:0009066
    TERM    aspartate family amino acid metabolism
    CORRECTED P-VALUE       1.79446311877879e-14
    UNCORRECTED P-VALUE     4.84990032102375e-16
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 9 of 19 in the list, vs 45 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET1, MET11, MET3, STR3, MET2, MET16, MET17, MET6
    
    -- 9 of 37 --
    GOID    GO:0006807
    TERM    nitrogen compound metabolism
    CORRECTED P-VALUE       3.77265283361447e-14
    UNCORRECTED P-VALUE     1.01963590097688e-15
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 243 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, YIL074C, MET17
    
    -- 10 of 37 --
    GOID    GO:0044272
    TERM    sulfur compound biosynthesis
    CORRECTED P-VALUE       2.67188341651488e-13
    UNCORRECTED P-VALUE     7.2213065311213e-15
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 7 of 19 in the list, vs 18 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, MET28, MET17, MET6
    
    -- 11 of 37 --
    GOID    GO:0006082
    TERM    organic acid metabolism
    CORRECTED P-VALUE       7.06399274294626e-13
    UNCORRECTED P-VALUE     1.90918722782331e-14
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 304 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, YIL074C, MET17
    
    -- 12 of 37 --
    GOID    GO:0019752
    TERM    carboxylic acid metabolism
    CORRECTED P-VALUE       7.06399274294626e-13
    UNCORRECTED P-VALUE     1.90918722782331e-14
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 13 of 19 in the list, vs 304 of 7300 in the genome
    The genes annotated to this node are:
    MET14, MET3, STR3, ECM17, MET28, MHT1, MET6, MET1, MET11, MET2, MET16, YIL074C, MET17
    
    -- 13 of 37 --
    GOID    GO:0000103
    TERM    sulfate assimilation
    CORRECTED P-VALUE       9.98928836937253e-13
    UNCORRECTED P-VALUE     2.69980766739798e-14
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 6 of 19 in the list, vs 10 of 7300 in the genome
    The genes annotated to this node are:
    MET10, MET14, MET1, MET3, ECM17, MET16
    
    -- 14 of 37 --
    GOID    GO:0006791
    TERM    sulfur utilization
    CORRECTED P-VALUE       9.98928836937253e-13
    UNCORRECTED P-VALUE     2.69980766739798e-14
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 6 of 19 in the list, vs 10 of 7300 in the genome
    The genes annotated to this node are:
    MET10, MET14, MET1, MET3, ECM17, MET16
    
    -- 15 of 37 --
    GOID    GO:0008652
    TERM    amino acid biosynthesis
    CORRECTED P-VALUE       4.728301511661e-11
    UNCORRECTED P-VALUE     1.27791932747595e-12
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 9 of 19 in the list, vs 103 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, ECM17, YIL074C, MET28, MET17, MET6
    
    -- 16 of 37 --
    GOID    GO:0009309
    TERM    amine biosynthesis
    CORRECTED P-VALUE       9.42530020402032e-11
    UNCORRECTED P-VALUE     2.54737843351901e-12
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 9 of 19 in the list, vs 111 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, ECM17, YIL074C, MET28, MET17, MET6
    
    -- 17 of 37 --
    GOID    GO:0044271
    TERM    nitrogen compound biosynthesis
    CORRECTED P-VALUE       9.42530020402032e-11
    UNCORRECTED P-VALUE     2.54737843351901e-12
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 9 of 19 in the list, vs 111 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, ECM17, YIL074C, MET28, MET17, MET6
    
    -- 18 of 37 --
    GOID    GO:0009086
    TERM    methionine biosynthesis
    CORRECTED P-VALUE       1.81352587001198e-08
    UNCORRECTED P-VALUE     4.90142127030265e-10
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 4 of 19 in the list, vs 6 of 7300 in the genome
    The genes annotated to this node are:
    MET1, STR3, MET2, MET6
    
    -- 19 of 37 --
    GOID    GO:0009067
    TERM    aspartate family amino acid biosynthesis
    CORRECTED P-VALUE       4.58690073266533e-06
    UNCORRECTED P-VALUE     1.23970290072036e-07
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 4 of 19 in the list, vs 19 of 7300 in the genome
    The genes annotated to this node are:
    MET1, STR3, MET2, MET6
    
    -- 20 of 37 --
    GOID    GO:0000101
    TERM    sulfur amino acid transport
    CORRECTED P-VALUE       5.51387718608536e-06
    UNCORRECTED P-VALUE     1.49023707732037e-07
    FDR_RATE        0.00%
    EXPECTED_FALSE_POSITIVES        0.00
    NUM_ANNOTATIONS 3 of 19 in the list, vs 5 of 7300 in the genome
    The genes annotated to this node are:
    MMP1, MUP1, SAM3
    
    -- 21 of 37 --
    GOID    GO:0009069
    TERM    serine family amino acid metabolism
    CORRECTED P-VALUE       0.00108164983836796
    UNCORRECTED P-VALUE     2.92337794153502e-05
    FDR_RATE        0.10%
    EXPECTED_FALSE_POSITIVES        0.02
    NUM_ANNOTATIONS 3 of 19 in the list, vs 24 of 7300 in the genome
    The genes annotated to this node are:
    MET2, YIL074C, MET17
    
    -- 22 of 37 --
    GOID    GO:0006865
    TERM    amino acid transport
    CORRECTED P-VALUE       0.00406448231248132
    UNCORRECTED P-VALUE     0.000109850873310306
    FDR_RATE        0.18%
    EXPECTED_FALSE_POSITIVES        0.04
    NUM_ANNOTATIONS 3 of 19 in the list, vs 37 of 7300 in the genome
    The genes annotated to this node are:
    MMP1, MUP1, SAM3
    
    -- 23 of 37 --
    GOID    GO:0044249
    TERM    cellular biosynthesis
    CORRECTED P-VALUE       0.00858173589265904
    UNCORRECTED P-VALUE     0.000231938807909704
    FDR_RATE        0.26%
    EXPECTED_FALSE_POSITIVES        0.06
    NUM_ANNOTATIONS 9 of 19 in the list, vs 927 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, ECM17, YIL074C, MET28, MET17, MET6
    
    -- 24 of 37 --
    GOID    GO:0015837
    TERM    amine transport
    CORRECTED P-VALUE       0.00888521048932255
    UNCORRECTED P-VALUE     0.000240140824035745
    FDR_RATE        0.33%
    EXPECTED_FALSE_POSITIVES        0.08
    NUM_ANNOTATIONS 3 of 19 in the list, vs 48 of 7300 in the genome
    The genes annotated to this node are:
    MMP1, MUP1, SAM3
    
    -- 25 of 37 --
    GOID    GO:0046942
    TERM    carboxylic acid transport
    CORRECTED P-VALUE       0.0100357228763322
    UNCORRECTED P-VALUE     0.000271235753414384
    FDR_RATE        0.40%
    EXPECTED_FALSE_POSITIVES        0.10
    NUM_ANNOTATIONS 3 of 19 in the list, vs 50 of 7300 in the genome
    The genes annotated to this node are:
    MMP1, MUP1, SAM3
    
    -- 26 of 37 --
    GOID    GO:0015849
    TERM    organic acid transport
    CORRECTED P-VALUE       0.0106454218366372
    UNCORRECTED P-VALUE     0.000287714103692899
    FDR_RATE        0.46%
    EXPECTED_FALSE_POSITIVES        0.12
    NUM_ANNOTATIONS 3 of 19 in the list, vs 51 of 7300 in the genome
    The genes annotated to this node are:
    MMP1, MUP1, SAM3
    
    -- 27 of 37 --
    GOID    GO:0009070
    TERM    serine family amino acid biosynthesis
    CORRECTED P-VALUE       0.0154325886116854
    UNCORRECTED P-VALUE     0.000417096989505011
    FDR_RATE        0.44%
    EXPECTED_FALSE_POSITIVES        0.12
    NUM_ANNOTATIONS 2 of 19 in the list, vs 12 of 7300 in the genome
    The genes annotated to this node are:
    YIL074C, MET17
    
    -- 28 of 37 --
    GOID    GO:0009058
    TERM    biosynthesis
    CORRECTED P-VALUE       0.0156316633253993
    UNCORRECTED P-VALUE     0.000422477387172954
    FDR_RATE        0.43%
    EXPECTED_FALSE_POSITIVES        0.12
    NUM_ANNOTATIONS 9 of 19 in the list, vs 1002 of 7300 in the genome
    The genes annotated to this node are:
    MET1, MET11, STR3, MET2, ECM17, YIL074C, MET28, MET17, MET6

=head1 AUTHORS

Gavin Sherlock, sherlock@genome.stanford.edu

=cut
