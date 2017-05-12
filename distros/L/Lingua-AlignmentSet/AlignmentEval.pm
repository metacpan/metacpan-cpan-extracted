package Lingua::AlignmentEval;

use strict;

my $true = 1;
my $false = 0;

sub new {
	my ($pkg,$surePrecision,$sureRecall,$sureFMeasure,$possiblePrecision,$possibleRecall,$possibleFMeasure,$AER) = @_;
	my $this = {};

	$this->{surePrecision}=$surePrecision;
	$this->{sureRecall}=$sureRecall;
	$this->{possiblePrecision}=$possiblePrecision;
	$this->{possibleRecall}=$possibleRecall;
	$this->{sureFMeasure}=$sureFMeasure;
	$this->{possibleFMeasure}=$possibleFMeasure;
	$this->{AER}=$AER;
	
    return bless $this,$pkg;    
}

sub display{
	my ($this,$fileHandle,$format)=@_;
	my $output;
	
	if (!defined($format)){$format="text"}
	if (!defined($fileHandle)){$fileHandle=*STDOUT}

	if ($format eq "text"){
		printf($fileHandle "\n    Word Alignment Evaluation   \n");
		printf($fileHandle "----------------------------------\n");
		printf($fileHandle "   Evaluation of SURE alignments \n");
		printf($fileHandle "   Precision = %5.4f  \n", $this->{surePrecision});
		printf($fileHandle "   Recall    = %5.4f\n",$this->{sureRecall});
		printf($fileHandle "   F-measure = %5.4f\n",$this->{sureFMeasure});
		printf($fileHandle "-----------------------------------\n");
		printf($fileHandle "   Evaluation of POSSIBLE alignments\n");
		printf($fileHandle "   Precision = %5.4f\n",$this->{possiblePrecision});
		printf($fileHandle "   Recall    = %5.4f\n",$this->{possibleRecall});
		printf($fileHandle "   F-measure = %5.4f\n",$this->{possibleFMeasure});
		printf($fileHandle "-----------------------------------\n");
		printf($fileHandle "   AER       = %5.4f\n",$this->{AER});	
	}else{
		print "AlignmentEval::compare: format no supported";
	}
}

#input: hash: ("title",$refToResultsRef,"title2",$refToResultsRef2...)
#filehandle:where do you print it (default:stdin)
#format: text,latex (default:text)
sub compare{
	my ($results,$title,$fileHandle,$format)=@_;
	#defaults
	if (!defined($format)){$format="text"}
	if (!defined($fileHandle)){$fileHandle=*STDOUT}
	my ($ref,$expName,$result,$line);
	my $numResults = scalar(@$results);
	my ($titleLine,$rowSep1,$header,$rowSep2);
	my ($colSep1,$colSep2,$rowEnd);
	my @measures;
	# variables for latex format
	my $latex;
	# variables for text format
	my $initialSpace=25;
	
	if ($format ne "text" && $format ne "latex"){
		print "AlignmentEval::compare: format no supported";
		return;
		}
	if ($format eq "latex"){
		$latex = Lingua::Latex->new;
		print $fileHandle $latex->startFile;
		print $fileHandle $latex->setTabcolsep("0.5mm");		
		print $fileHandle '\vspace{5mm}'."\n"; 	
		$titleLine = "\n".'\begin{tabular}{|p{4cm}|'.'r@{ }|' x (7)."}\n";
		$titleLine.= "\n".' \multicolumn{8}{p{14cm}}{ '.$latex->fromText($title).'} \\\\ '."\n";
		$rowSep1 = '\hline'."\n".'\hline'."\n";
		$header =' Experiment & \parbox{1.3cm}{\centering $P_S\ (\%)$} & \parbox{1.3cm}{\centering $R_S\ (\%)$} & \parbox{1.3cm}{\centering $F_S\ (\%)$}';
		$header.=' & \parbox{1.3cm}{\centering $P_P\ (\%)$} & \parbox{1.3cm}{\centering $R_P\ (\%)$} & \parbox{1.3cm}{\centering $F_P\ (\%)$}';
		$header.=' & \parbox{1.5cm}{\centering $AER\ (\%)$}\\\\'."\n";
		$rowSep2='\hline'."\n";
		$colSep1=' & ';
		$colSep2=' & ';
		$rowEnd = '\\\\';
	}elsif ($format eq "text"){
		$titleLine = "\n    $title   \n";
		$rowSep1 = "----------------------------------\n";
		$colSep2='	';
		$header = " Experiment"." " x ($initialSpace-11)."  Ps$colSep2  Rs$colSep2  Fs$colSep2  Pp$colSep2  Rp$colSep2  Fp$colSep2 AER  \n\n";
		$rowEnd='';
	}
		
	printf $fileHandle $titleLine;
	printf $fileHandle $rowSep1;
	printf $fileHandle $header;#,@titleLine;
	printf $fileHandle $rowSep2;
	foreach $ref (@$results){
		$result=$ref->[0];	
		$expName=$ref->[1];
		if ($format eq "text"){
			if (length($expName)>=$initialSpace){
				$expName = substr $expName,0,$initialSpace-1;
				$colSep1=' ';	
			}else{
				$colSep1=' ' x ($initialSpace-length($expName));	
			}
		}else{
			$expName = $latex->fromText($expName);
		}
		@measures = ($result->{surePrecision}*100,$result->{sureRecall}*100,$result->{sureFMeasure}*100,
					$result->{possiblePrecision}*100,$result->{possibleRecall}*100,$result->{possibleFMeasure}*100,
					$result->{AER}*100);
		printf $fileHandle $expName.$colSep1."%5.2f"."$colSep2%5.2f" x (6)."$rowEnd\n",@measures;
	}
	if ($format eq "latex"){
		print $fileHandle '\hline'."\n";
		print $fileHandle '\end{tabular}';
		print $fileHandle $latex->endFile;
	}
}

1;
