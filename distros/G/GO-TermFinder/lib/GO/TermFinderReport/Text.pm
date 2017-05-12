package GO::TermFinderReport::Text;

=pod

=head1 NAME

GO::TermFinderReport::Text - prints results of GO::TermFinder as a text report

=head1 DESCRIPTION

This print() method of this Perl module receives a reference to an the
array that is the return value from the findTerms method of
GO::TermFinder, the number of genes that were used to generate the
terms, and the number of genes that were said to be in the genome.  It
will then generate a text report that summarizes those results.
Optionally, filehandle and p-value cutoff arguments may also be passed
in.  It will return the 

=head1 SYNOPSIS

    use GO::TermFinder;
    use GO::TermFinderReport::Text;

    .
    .
    .

    my @pvalues = $termFinder->findTerms(genes=>\@genes);

    my $report  = GO::TermFinderReport::Text->new();

    open (OUT, ">report.text");

    my $numHypotheses = $report->print(pvalues  => \@pvalues,
                                       aspect   => $aspect,
                                       numGenes => scalar(@genes),
                                       totalNum => $totalNum,
                                       cutoff   => 0.01,
                                       fh       => \*OUT);

    close OUT;

=cut

use strict;
use warnings;
use diagnostics;

use vars qw ($VERSION);

$VERSION = 0.10;

######################################################################################
sub new{
######################################################################################

=head2 new

This is the constructor.

Usage:

    my $report = GO::TermFinderReport::Text->new();

A GO::TermFinderReport::Text object is returned.

=cut

######################################################################################

    my $self = {};

    bless $self, shift;

    return $self;

}

######################################################################################
sub print{
######################################################################################

=head2 print

This method prints out the text report of the passed in hypotheses.
The report is ordered in ascending order of p-value (i.e. most
significant first).  If the FDR was calculated, the FDR will also be
printed.  It returns the number of hypotheses that had corrected
p-values as good or better than the passed in cutoff.

Usage:

    my $numHypotheses = $report->print(pvalues  => \@pvalues,
				       numGenes => scalar(@genes),
				       totalNum => $totalNum,
				       cutoff   => 0.01,
				       fh       => \*OUT,
                                       table    => 0 );

Required arguments:

pvalues  : A reference to the array returned by the findTerms() method
           of GO::TermFinder

numGenes : The number of genes that were in the list passed to the
           findTerms method

totalNum : The total number of genes that were indicated to be in the
           genome for finding terms.

Optional arguments:

fh       : A reference to a file handle to which the table should be
           printed.  Defaults to standard out.

cutoff   : The p-value cutoff, above which p-values and associated
           information will not be printed.  Default is no cutoff.

table    : 0 for standard output, 1 for tab delimited table.  Default is 0

=cut

######################################################################################

    my ($self, %args) = @_;

    if (!exists($args{'pvalues'})){

	die "You must supply a pvalues argument to the print method.";

    }

    if (!exists $args{'numGenes'}){

	die "You must supply a numGene argument to the print method.";

    }

    if (!exists $args{'totalNum'}){

	die "You must supply a totalNum argument to the print method.";

    }

    my $pvalues  = $args{'pvalues'};
    my $numGenes = $args{'numGenes'};
    my $totalNum = $args{'totalNum'};
    my $fh       = $args{'fh'}     || \*STDOUT;
    my $cutoff   = $args{'cutoff'} || 1;
    my $table    = $args{'table'}  || 0;

    my $rows;
    my $numRows = 0;

    my $hasFdr = 0;

    my $hypothesis = 1;

    my @header = ("GOID", "TERM", "CORRECTED_PVALUE",
		  "UNCORRECTED_PVALUE", "NUM_LIST_ANNOTATIONS",
		  "LIST_SIZE", "TOTAL_NUM_ANNOTATIONS",
		  "POPULATION_SIZE", "FDR_RATE",
		  "EXPECTED_FALSE_POSITIVES", "ANNOTATED_GENES");

    print $fh join("\t", @header), "\n" if ($table);

    foreach my $pvalue (@{$pvalues}){

	# skip if above cutoff

	next if ($pvalue->{CORRECTED_PVALUE} > $cutoff);
	
	# now format the p-value	

	my $value = $pvalue->{CORRECTED_PVALUE};

	# if it's in scientific notation, we want up to two of the decimal places

	$value =~ s/^(.*\.[0-9]{2}).*(e.+)$/$1$2/;
	
	# otherwise, we'll take up to five decimal places

	$value =~ s/^(0\.[0-9]{5})[0-9]*$/$1/;

	if (defined ($pvalue->{NUM_OBSERVATIONS}) && $pvalue->{NUM_OBSERVATIONS} == 0){

	    # simulations were used to generate the corrected p-value.
	    # If we never saw anything better than this p-value in the
	    # simulations, then prepend a less than sign to the
	    # corrected p-value

	    $value = "<".$value;

	}
	
	if (!$table){

	    print $fh 

		"-- $hypothesis of ", scalar @{$pvalues}, " --\n",
		"GOID\t", $pvalue->{NODE}->goid, "\n",
		"TERM\t", $pvalue->{NODE}->term, "\n",
		"CORRECTED P-VALUE\t", $pvalue->{CORRECTED_PVALUE}, "\n",
		"UNCORRECTED P-VALUE\t", $pvalue->{PVALUE}, "\n";

	}else{

	    print $fh join("\t", ($pvalue->{NODE}->goid, 
				  $pvalue->{NODE}->term,
				  $pvalue->{CORRECTED_PVALUE},
				  $pvalue->{PVALUE},
				  $pvalue->{NUM_ANNOTATIONS},
				  $numGenes,
				  $pvalue->{TOTAL_NUM_ANNOTATIONS},
				  $totalNum)), "\t";

	}
	
	# deal with FDR

	my ($fdr, $falsePositives);

	if (exists ($pvalue->{FDR_RATE})){

	    $fdr = sprintf ("%.2f%%", $pvalue->{FDR_RATE} * 100);

	    $falsePositives = sprintf ("%.2f", $pvalue->{EXPECTED_FALSE_POSITIVES});

	    if(!$table){

		print $fh 

		    "FDR_RATE\t", $fdr, "\n",
		    "EXPECTED_FALSE_POSITIVES\t", $falsePositives, "\n";

	    }else{

	      print $fh $fdr, "\t", $falsePositives, "\t";

	    }

	}else{

	    print $fh "\t\t" if ($table); # Gotta fill in the blanks

	}

	if (!$table){
	
	    print $fh "NUM_ANNOTATIONS\t"; 
	    print $fh $pvalue->{NUM_ANNOTATIONS};
	    print $fh " of $numGenes in the list, vs ";
	    print $fh $pvalue->{TOTAL_NUM_ANNOTATIONS};
	    print $fh " of $totalNum in the genome\n";
	    print $fh "The genes annotated to this node are:\n";;

	}

	print $fh join(", ", values(%{$pvalue->{ANNOTATED_GENES}})), "\n";
	print $fh "\n" if (!$table);
	
	$hypothesis++;
	
    }

    return ($hypothesis - 1);

}
    
1; # to keep Perl happy

=pod

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut
