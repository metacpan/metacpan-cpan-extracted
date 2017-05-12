package GO::TermFinderReport::Html;

=pod

=head1 NAME

GO::TermFinderReport::Html - prints an html table of the results of GO::TermFinder

=head1 DESCRIPTION

This print() method of this Perl module receives a reference to an the
array that is the return value from the findTerms method of
GO::TermFinder, the aspect for which terms were found, the number of
genes that were used to generate the terms, and the number of genes
that were said to be in the genome.  It will then generate an html
table that summarizes those results.  Optionally, filehandle, p-value
cutoff, gene URL, and GOID URL arguments may also be passed in.  Url
links should have the string <REPLACE_THIS> to indicate where the gene
name, or GOID should be put.

=head1 SYNOPSIS

    use GO::TermFinder;
    use GO::TermFinderReport::Html;

    .
    .
    .

    my @pvalues = $termFinder->findTerms(genes=>\@genes);

    my $report  = GO::TermFinderReport::Html->new();

    open (HTML, ">blah.html");

    print HTML "<html><body>";

    my $numRows = $report->print(pvalues  => \@pvalues,
                                 aspect   => $aspect,
                                 numGenes => scalar(@genes),
                                 totalNum => $totalNum,
                                 fh       => \*HTML,
                                 cutoff   => 0.01,
                                 geneUrl  => 'http://db.yeastgenome.org/cgi-bin/SGD/locus.pl?locus=<REPLACE_THIS>',
                                 goidUrl  => 'http://amigo.geneontology.org/cgi-bin/amigo/go.cgi?view=details&search_constraint=terms&depth=0&query=<REPLACE_THIS>');

    print HTML "</body></html>";

    close HTML;

=cut

use strict;
use warnings;
use diagnostics;

use vars qw ($VERSION);

$VERSION = 0.12;

use CGI qw/:all :html3/;

######################################################################################
sub new{
######################################################################################

=head2 new

This is the constructor.

Usage:

    my $report = GO::TermFinderReport::Html->new();

A GO::TermFinderReport::Html object is returned.

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

This method prints out the report, in the form of an html table.  The
table is ordered in ascending order of p-value (i.e. most significant
first), and will print out the GO node, the frequency of use of that
node within the selected group of genes, and the population as a
whole, the corrected p-value of that, and a list of the genes
annotated to that node.  If the FDR was calculated, the FDR will also
be printed.  It returns the number of annotation rows in the table
that exceed the provided p-value cutoff (which may even be zero, in
which case nothing is printed).

Usage:

    my $numRows = $report->print(pvalues      => \@pvalues,
				 aspect       => $aspect,   # P, C, or F
				 numGenes     => scalar(@genes),
				 totalNum     => $totalNum,
				 fh           => \*HTML,
				 pvalueCutOff => 0.01,
				 geneUrl      => 'http://db.yeastgenome.org/cgi-bin/SGD/locus.pl?locus=<REPLACE_THIS>',
				 goidUrl      => 'http://amigo.geneontology.org/cgi-bin/amigo/go.cgi?view=details&search_constraint=terms&depth=0&query=<REPLACE_THIS>');

Required arguments:

    pvalues   :  A reference to the array returned by the findTerms() method of GO::TermFinder

    aspect    :  The aspect of the Gene Ontology for which terms were found (C, F or P)

    numGenes  :  The number of genes that were in the list passed to the findTerms method

    totalNum  :  The total number of genes that were indicated to be in the genome for finding terms.

Optional arguments:


    fh       : A reference to a file handle to which the table should be
               printed.  Defaults to standard out.

    pvalueCutOff   : The p-value cutoff, above which p-values and associated
                     information will not be printed.  Default is no cutoff.

    geneUrl  : A url to which you want genes linked.  Must contain the
               text '<REPLACE_THIS>', which will be replaced with the
               gene name.

    goidUrl  : A url to which you want the GOIDs linked.  Must contain the
               text '<REPLACE_THIS>', which will be replaced with the
               goid.

=cut

######################################################################################

    my ($self, %args) = @_;

    if (!exists($args{'pvalues'})){

	die "You must supply a pvalues argument to the print method.";

    }

    if (!exists($args{'aspect'})){

	die "You must supply a aspect argument to the print method.";

    }
    

    if (!exists $args{'numGenes'}){

	die "You must supply a numGene argument to the print method.";

    }

    if (!exists $args{'totalNum'}){

	die "You must supply a totalNum argument to the print method.";

    }

    my $pvalues  = $args{'pvalues'};
    my $aspect   = $args{'aspect'};
    my $numGenes = $args{'numGenes'};
    my $totalNum = $args{'totalNum'};
    my $fh       = $args{'fh'}           || \*STDOUT;
    my $cutoff   = $args{'pvalueCutOff'} || 1;
    my $geneUrl  = $args{'geneUrl'};
    my $goidUrl  = $args{'goidUrl'};

    my $replacementText = "<REPLACE_THIS>";

    my $rows;
    my $numRows = 0;

    my $hasFdr = 0;

    foreach my $pvalue (@{$pvalues}){

	# skip if above cutoff

	next if ($pvalue->{CORRECTED_PVALUE} > $cutoff);

	# now generate a list of loci annotated to this node, with
	# links if requested

	my @loci;
	
	foreach my $databaseId (keys %{$pvalue->{ANNOTATED_GENES}}){
	    
	    my $gene = $pvalue->{ANNOTATED_GENES}->{$databaseId};
	    
	    if (defined $geneUrl) {
		
		my $url = $geneUrl;

		$url =~ s/$replacementText/$gene/;

		$gene = a({-href=>$url,
			   -target=>'infowin'}, $gene);

	    }

	    push (@loci, $gene);
		
	}

	my $loci = join(", ", @loci);
	
	# now calculate the frequency for annotation for the list and the genome

	my $frequencyPercent = sprintf("%.1f", ($pvalue->{NUM_ANNOTATIONS}/$numGenes) * 100);
  
	my $frequency = $pvalue->{NUM_ANNOTATIONS}." out of $numGenes genes, $frequencyPercent\%";

        my $geneFrequencyPercent = sprintf("%.1f", ($pvalue->{TOTAL_NUM_ANNOTATIONS}/$totalNum) * 100);

	my $genomeFrequency = $pvalue->{TOTAL_NUM_ANNOTATIONS}." out of $totalNum genes, $geneFrequencyPercent\%";

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

	    $value = "&lt;".$value;

	}

	# now deal with the GOID column

	my $goColumn;

	if (defined $goidUrl){

	    my $url  = $goidUrl;
	    my $goid = $pvalue->{NODE}->goid;

	    $url =~ s/$replacementText/$goid/;

	    # make link with name of term as the text

	    $goColumn = a({-href=>$url,
			   -target=>'infowin'}, $pvalue->{NODE}->term);

	}else{

	    # if no link, just use term, and parenthetical GOID

	    $goColumn = $pvalue->{NODE}->term." (".$pvalue->{NODE}->goid.")";

	}

	# deal with FDR

	my ($fdr, $falsePositives);

	if (exists ($pvalue->{FDR_RATE})){

	    $hasFdr = 1;

	    $fdr = sprintf ("%.2f%%", $pvalue->{FDR_RATE} * 100);

	    $falsePositives = sprintf ("%.2f", $pvalue->{EXPECTED_FALSE_POSITIVES});

	}

	$rows .= $self->_oneRow($goColumn, $frequency,
				$genomeFrequency, $value, $loci, $fdr,
				$falsePositives);

	$numRows++;

    }

    # print the table out, if there were any rows

    $self->_printTable($fh, $rows, $aspect, $cutoff, $hasFdr) if ($numRows > 0);

    return $numRows;

}

###################################################################
sub _oneRow{
###################################################################
# This protected method simply returns a row from the html table,
# based on what was passed in.

    my ($self, $goColumn, $frequency, $genomeFrequency, $pvalue,
	$loci, $fdr, $falsePositives) = @_;

    my $row = td($goColumn).
	      td($frequency).
	      td($genomeFrequency).
	      td($pvalue);

    if (defined($fdr)){

	$row .= td($fdr).td($falsePositives);

    }
	      td($loci);

    $row .= td($loci);

    return Tr($row);

}

###################################################################
sub _printTable{
###################################################################
# This method prints out the actual html table

    my ($self, $fh, $rows, $aspect, $cutoff, $hasFdr) = @_;

    $aspect =~ s/^F/Function/i;
    $aspect =~ s/^P/Process/i;
    $aspect =~ s/^C/Component/i;

    print $fh a({-name=>'table'});
    print $fh center(h3("Result Table")), p;
    
    print $fh table({-align       => 'center',
		     -border      => 1,
		     -cellpadding => 2,
		     -width       => 400},
		    Tr(td({-bgcolor => '#FFCC99',
			   -align   => 'center',
			   -width   => '100%',
			   -nowrap  => undef},
			  b("Terms from the $aspect Ontology with p-value as good or better than $cutoff"))));

    my $headings = th({-align => 'center'}, "Gene Ontology term").
		   th({-align => 'center'}, "Cluster frequency").
		   th({-align => 'center'}, "Genome frequency of use").
		   th({-align => 'center'}, "Corrected P-value");

    if ($hasFdr){

	$headings .= th({-align => 'center'}, "FDR").
	    th({-align => 'center'}, "False Positives");

    }

    $headings .= th({-align => 'center'}, "Genes annotated to the term");

    print $fh table({-align  => 'center',
		     -border => 2},
		    Tr({-bgcolor  => '#CCCCFF'},
		       $headings).
		    $rows), p;

}
    
1; # to keep Perl happy

=pod

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut
