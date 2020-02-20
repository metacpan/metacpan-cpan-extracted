package Metabolomics::Fragment::Annotation;

use 5.006;
use strict;
use warnings;

use Data::Dumper ;
use Text::CSV ;
use XML::Twig ;
use File::Share ':all'; 
use Carp qw (cluck croak carp) ;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../..";  # use the parent directory

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Fragment::Annotation ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	writeFullTabularWithPeakBankObject 
	writeTabularWithPeakBankObject 
	compareExpMzToTheoMzList
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	writeFullTabularWithPeakBankObject 
	writeTabularWithPeakBankObject  
	compareExpMzToTheoMzList
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Fragment::Annotation - Perl extension for fragment annotation in metabolomics 

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';


=head1 SYNOPSIS

    use Metabolomics::Fragment::Annotation;

=head1 DESCRIPTION

	Metabolomics::Fragment::Annotation is a full package for Perl dev allowing MS fragments annotation with ab initio database, contaminant and public metabolites ressources.
	

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 METHOD new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my ($class,$args) = @_;
    my $self={};
    
    $self->{_ANNOTATION_TOOL_} = 'mzBiH' ; ## Would be mzBiH, pcBiH, ...
    $self->{_ANNOTATION_TOOL_VERSION_} = '0.1' ;
    $self->{_ANNOTATION_ION_MODE_} = 'annotation_ion_mode' ; ## would be POSITIVE|NEGATIVE|NEUTRAL
    $self->{_ANNOTATION_DB_SOURCE_} = $args->{_DATABASE_NAME_} ;
    $self->{_ANNOTATION_DB_SOURCE_VERSION} = $args->{_DATABASE_VERSION_} ;
    $self->{_THEO_PEAK_LIST_} = $args->{_THEO_PEAK_LIST_} ;
    $self->{_EXP_PEAK_LIST_} = $args->{_EXP_PEAK_LIST_} ;

	bless($self) ;

    return $self ;
}
### END of SUB

=head2 METHOD compareExpMzToTheoMzList

	## Description : comparing two lists of mzs (theo and experimental) with a mz delta
	## Input : $deltaValue, $deltaType
	## Output : $oAnalysis with annotation results
	## Usage : $oAnalysis->compareExpMzToTheoMzList ( $deltaValue, $deltaType ) ;
	
=cut
## START of SUB
sub compareExpMzToTheoMzList {
    ## Retrieve Values
    my $self = shift ;
    my ($deltaType, $deltaValue ) = @_ ;
    
    my $expFragments = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
    my $theoFragments = $self->_getPeaksToAnnotated('_THEO_PEAK_LIST_') ;
    
#    print Dumper $expFragments ;
#    print Dumper $theoFragments ;
    
    if (  ( scalar (@{$expFragments}) > 0 ) and  ( scalar (@{$theoFragments}) > 0 ) ) {
    	
    	foreach my $expFrag (@{$expFragments}) {
    		
    		my $fragMz = $expFrag->_getPeak_MESURED_MONOISOTOPIC_MASS();
    		my ($min, $max) = _mz_delta_conversion (\$fragMz, \$deltaType, \$deltaValue) ; 
    		
#    		print "FOR frag $fragMz - MIN is: $$min and MAX is: $$max\n" ;
    		
    		foreach my $theoFrag (@{$theoFragments}) {
    			
    			my $motifMz = $theoFrag-> _getPeak_COMPUTED_MONOISOTOPIC_MASS();
    			
    			if (  ($motifMz > $$min ) and ($motifMz < $$max)  ) {
    				
#    				print "OK -> $motifMz MATCHING WITH $fragMz\n" ;
    				my $annotName = $theoFrag-> _getPeak_ANNOTATION_NAME();
    				my $computedMz = $theoFrag->_getPeak_COMPUTED_MONOISOTOPIC_MASS();
    				my $annotType = $theoFrag->_getPeak_ANNOTATION_TYPE() ;
    				my $annotID = $theoFrag->_getPeak_ANNOTATION_ID() if $theoFrag->_getPeak_ANNOTATION_ID ;
    				
    				my $annotInNegMode =  $theoFrag->_getPeak_ANNOTATION_IN_NEG_MODE() if $theoFrag->_getPeak_ANNOTATION_IN_NEG_MODE() ;
    				my $annotInPosMode =  $theoFrag->_getPeak_ANNOTATION_IN_POS_MODE() if $theoFrag->_getPeak_ANNOTATION_IN_POS_MODE() ;
    				
#    				print $annotInNegMode if $annotInNegMode ;
#    				print $annotInPosMode if $annotInPosMode ;
    				
    				my $deltaError = 0 ;
    				# compute error 
    				$deltaError = _computeMzDeltaInMmu($fragMz, $motifMz) ;
    				$expFrag-> _setPeak_ANNOTATION_DA_ERROR( $deltaError );
    				
    				my $deltaErrorMmu = _computeMzDeltaInMmu($fragMz, $motifMz) ;
    				$deltaError = _computeMzDeltaInPpm($fragMz, $deltaErrorMmu) ;
    				
    				$expFrag-> _setPeak_ANNOTATION_PPM_ERROR( $deltaError );
    				
    				$expFrag-> _setPeak_ANNOTATION_NAME( $annotName );
    				$expFrag-> _setPeak_COMPUTED_MONOISOTOPIC_MASS( $computedMz );
    				$expFrag-> _setPeak_ANNOTATION_TYPE( $annotType ) if (defined $annotType);
    				$expFrag-> _setPeak_ANNOTATION_ID( $annotID ) if (defined $annotID);
    				
    				$expFrag->_setPeak_ANNOTATION_IN_NEG_MODE($annotInNegMode) if (defined $annotInNegMode);
    				$expFrag->_setPeak_ANNOTATION_IN_POS_MODE($annotInPosMode) if (defined $annotInPosMode);
    				
    				## TODO...
    			}
    			else {
#    				print "KO -> $motifMz DON'T MATCHING WITH $fragMz\n" ;
    				next ;
    			}	
    		}
    	} ## END foreach
    }
    else {
    	croak "[ERROR]: One of peak list is empty or object is undef...\n" ;
    }
}
### END of SUB


=head2 METHOD writeTabularWithPeakBankObject

	## Description : write a full tabular file from a template and mapping peak bank objects features
	## Input : $oBank, $templateTabular, $tabular
	## Output : $tabular
	## Usage : my ( $tabular ) = $oBank->writeTabularWithPeakBankObject ( $templateTabular, $tabular ) ;
	
=cut
## START of SUB
sub writeTabularWithPeakBankObject {
    ## Retrieve Values
    my $self = shift ;
    my ( $templateTabular, $tabular ) = @_;
    
    my $peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
    
    my $templateFields = _getTEMPLATE_TABULAR_FIELDS($templateTabular) ;
    
    my $peakListRows = _mapPeakListWithTemplateFields($templateFields, $peakList) ;
	
	my $oCsv = Text::CSV_XS->new ( {
	    binary    =>  1,
	    auto_diag =>  1,
	    eol       => "\n",
	    sep_char=> "\t"
	    } );
	
	if (defined $tabular) {
		open my $oh, ">", "$tabular";
	
		$oCsv->column_names($templateFields);
		$oCsv->print($oh, $templateFields);
		foreach my $peak (@{$peakListRows}) {
			$oCsv->print_hr($oh, \%$peak);
		}
		
		close($oh) ;
	}
	else {
		croak "[ERROR] the tabular output file is not defined\n" ;
	}
	
	
    
    return ($tabular) ;
}
### END of SUB


=head2 METHOD writeFullTabularWithPeakBankObject

	## Description : write a output containing the input data and new column concerning annotation work
	## Input : $oBank, $inputData, $templateTabular, $tabular
	## Output : $tabular
	## Usage : my ( $tabular ) = $oBank->writeFullTabularWithPeakBankObject ( $inputData, $templateTabular, $tabular ) ;
	
=cut
## START of SUB
sub writeFullTabularWithPeakBankObject {
    ## Retrieve Values
    my $self = shift ;
    my ( $inputTabular, $templateTabular, $tabular ) = @_;
    
    my $inputFields = undef ;
    my @inputData = () ; # an array of hash correxponding to the input tabular file
    
    ## input source needs a header...
    if (-e $inputTabular) {
    	$inputFields = _getTEMPLATE_TABULAR_FIELDS($inputTabular) ;
    }
    else {
    	croak "[ERROR] Your input file does not exist ($inputTabular...)\n" ;
    }

    my $peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
    my $templateFields = _getTEMPLATE_TABULAR_FIELDS($templateTabular) ;
    my $peakListRows = _mapPeakListWithTemplateFields($templateFields, $peakList) ;
    
    # merge $inputFields and $templateFields
    my @tabularFields = (@{$inputFields}, @{$templateFields} ) ;
    
    # if input has header - set the last version of the peaklistRows
    if (defined $inputFields) {
		## open and parse input data
    	my $oInCsv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    		or die "Cannot use CSV: ".Text::CSV->error_diag ();
    	
    	open my $in, "<", $inputTabular or die "$inputTabular: $!";
    	
    	$oInCsv->header ($in);

    	while (my $row = $oInCsv->getline_hr ($in)) {
    		my %rowValues = () ;
#    		print Dumper $inputFields ;
#    		print Dumper $row ;
    		foreach my $field (@{$inputFields}) {
    			$rowValues{$field} = $row->{lc($field)} ;
    		}
    		push (@inputData, \%rowValues) ;
    	}
    }
    else {
    	croak "[ERROR] Your input file does not have any header\n" ;
    }
    
    my $oOutCsv = Text::CSV_XS->new ( {
	    binary    =>  1,
	    auto_diag =>  1,
	    eol       => "\n",
	    sep_char=> "\t"
	} );
    
    if (defined $tabular) {

    	my $pos = 0 ;
		open my $oh, ">", "$tabular";
#	
		$oOutCsv->column_names(\@tabularFields);
		$oOutCsv->print($oh, \@tabularFields);
		foreach my $peak (@{$peakListRows}) {
			my %row = ( %{$peak}, %{ $inputData[$pos] } ) ;
			$oOutCsv->print_hr($oh, \%row);
			$pos ++ ;
		}
		
		close($oh) ;
	}
	else {
		croak "[ERROR] the tabular output file is not defined\n" ;
	}
    
    return ($tabular) ;
}
### END of SUB


=head2 METHOD _getPeaksToAnnotated

	## Description : get a specific list of peaks from the Annotation analysis object
	## Input : $self, $type
	## Output : $peakList
	## Usage : my ( $peakList ) = $oAnalysis->_getPeakList ($type) ;
	
=cut
## START of SUB
sub _getPeaksToAnnotated {
    ## Retrieve Values
    my $self = shift ;
    my ($type) = @_ ;
    my ( $peakList ) = ( () ) ;
    
#    print "Using method with type: $type\n"  ;
    
    if ( (defined $type) and ($type eq '_EXP_PEAK_LIST_') ) {
    	$peakList = $self->{_EXP_PEAK_LIST_} ;
    }
    elsif ( (defined $type) and ($type eq '_THEO_PEAK_LIST_') ) {
    	$peakList = $self->{_THEO_PEAK_LIST_} ;
    }
    else {
    	croak "[ERROR] No type is undefined or does not correspond to _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ \n" ;
    }
    
    
    return ($peakList) ;
}
### END of SUB

=head2 METHOD _getTEMPLATE_TABULAR_FIELDS

	## Description : get all fields of the tabular template file
	## Input : $template
	## Output : $fields
	## Usage : my ( $fields ) = _getTEMPLATE_TABULAR_FIELDS ( $template ) ;
	
=cut
## START of SUB
sub _getTEMPLATE_TABULAR_FIELDS {
    ## Retrieve Values
    my ( $template ) = @_;
    my ( @fields ) = ( () ) ;
    
    if (-e $template) {
    	
    	my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    		or die "Cannot use CSV: ".Text::CSV->error_diag ();
    	
    	open my $fh, "<", $template or die "$template: $!";
    	
		## Checking header of the source file   	
    	$csv->header ($fh, { munge_column_names => sub {
		    push (@fields, $_) ;
		 }});
    	
    }
    else {
		croak "Tabular template file is not defined or is not existing.\n" ;
	}
    
    return (\@fields) ;
}
### END of SUB

=head2 METHOD _mapPeakListWithTemplateFields

	## Description : map any PeakList with any template fields from tabular
	## Input : $fields, $peakList
	## Output : $rows
	## Usage : my ( $rows ) = _mapPeakListWithTemplateFields ( $fields, $peakList ) ;
	
=cut
## START of SUB
sub _mapPeakListWithTemplateFields {
    ## Retrieve Values

    my ( $fields, $peakList ) = @_;
    my ( @rows ) = ( () ) ;
    
    foreach my $peak (@{$peakList}) {
    	my %tmp = () ;
    	
    	foreach my $field (@{$fields}) {
    		if (defined $peak->{$field}) 	{	$tmp{$field} = $peak->{$field}  ; }
    		else 							{	$tmp{$field} = 'NA'  ; }
    	}
    	push (@rows, \%tmp) ;
    }
    return (\@rows) ;
}
### END of SUB

=head2 METHOD _mz_delta_conversion

	## Description : returns the minimum and maximum mass according to the delta
	## Input : \$mass, \$delta_type, \$mz_delta
	## Output : \$min, \$max
	## Usage : ($min, $max)= mz_delta_conversion($mass, $delta_type, $mz_delta) ;
	
=cut
## START of SUB
sub _mz_delta_conversion {
	## Retrieve Values
    my ( $mass, $delta_type, $mz_delta ) = @_ ;
    my ( $computedDeltaMz, $min, $max ) = ( 0, undef, undef ) ;
    
    if 		($$delta_type eq 'PPM')		{	$computedDeltaMz = ($$mz_delta * 10**-6 * $$mass); }
	elsif 	($$delta_type eq 'DA')		{	$computedDeltaMz = $$mz_delta ; }
	else {	croak "The masses delta type '$$delta_type' isn't a valid type !\n" ;	}
    
    
    # Determine the number of decimals of the mz and of the delta (adding 0.1 if mz = 100 or 0.01 if mz = 100.1 )
    my @decimalMzPart = split (/\./, $$mass) ;
    my @decimalDeltaPart = split (/\./, $computedDeltaMz) ;
    
    my ($decimalMzPart, $decimalDeltaPart, $decimalLength, $nbDecimalMz, $nbDecimalDelta) = (0, 0, 0, 0, 0) ;
    
    if ($#decimalMzPart+1 == 1) 	{	$decimalMzPart = 0 ; }
    else 							{ 	$decimalMzPart = $decimalMzPart[1] ; }
    
    if ($#decimalDeltaPart+1 == 1) 	{	$decimalDeltaPart = 0 ; }
    else 							{ 	$decimalDeltaPart = $decimalDeltaPart[1] ; }
    
    if ( ($decimalMzPart == 0 ) and ($decimalDeltaPart == 0 ) ) {
    	$decimalLength = 1 ;
    }
    else {
    	$nbDecimalMz = length ($decimalMzPart)+1 ;
   		$nbDecimalDelta = length ($decimalDeltaPart)+1 ;
    
    	if ( $nbDecimalMz >= $nbDecimalDelta ) { $decimalLength = $nbDecimalMz ; }
    	if ( $nbDecimalDelta >= $nbDecimalMz ) { $decimalLength = $nbDecimalDelta ; }
    }
    
    my $deltaAdjustment = sprintf ("0."."%.$decimalLength"."d", 1 ) ;
    
#    print "$$mass: $decimalMzPart -> $nbDecimalMz, $$mz_delta: $decimalDeltaPart -> $nbDecimalDelta ==> $deltaAdjustment \n " ;
    
	$min = $$mass - $computedDeltaMz ;
	$max = $$mass + $computedDeltaMz + $deltaAdjustment ; ## it's to included the maximum value in the search
	
    return(\$min, \$max) ;
}
## END of SUB


=head2 METHOD _computeMzDeltaInMmu

	## Description : compute a delta (Da) between exp. mz and calc. mz
	## based on http://www.waters.com/waters/en_GB/Mass-Accuracy-and-Resolution/nav.htm?cid=10091028&locale=en_GB
	## Other ref : https://www.sciencedirect.com/science/article/pii/S1044030510004022
	## Input : $expMz, $calcMz
	## Output : $mzDeltaDa
	## Usage : my ( $mzDeltaDa ) = _computeMzDeltaInMmu ( $expMz, $calcMz ) ;
	
=cut
## START of SUB
sub _computeMzDeltaInMmu {
    ## Retrieve Values
    my ( $expMz, $calcMz ) = @_;
    my ( $mzDeltaMmu ) = ( 0 ) ;
    
    if ( ($expMz > 0 ) and ($calcMz > 0) ) {
    	
    	my $oUtils = Metabolomics::Utils->new() ;
    	my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($expMz, $calcMz) ;
    	
    	my $delta = abs($expMz - $calcMz) ;
    	$mzDeltaMmu = sprintf("%.$decimalLength"."f", $delta );
    }
    else {
    	carp "[ERROR Given masses are null\n" ;
    }
    
    return ($mzDeltaMmu) ;
}
### END of SUB

=head2 METHOD computeMzDeltaInPpm

	## Description : compute a delta (PPM) between exp. mz and calc. mz - Δm/Monoisotopic calculated exact mass ×106 
	## Input : $expMz, $calcMz
	## Output : $mzDeltaPpm
	## Usage : my ( $mzDeltaPpm ) = computeMzDeltaInPpm ( $expMz, $calcMz ) ;
	
=cut
## START of SUB
sub _computeMzDeltaInPpm {
    ## Retrieve Values
    my ( $calcMz, $mzDeltaMmu ) = @_;
    my ( $mzDeltaPpm, $mzDeltaPpmRounded ) = ( undef, undef ) ;
    
#    print "$calcMz -> $mzDeltaMmu\n" ;
    
    if ( ($calcMz > 0 ) and ($mzDeltaMmu >= 0) ) {
    	$mzDeltaPpm = ($mzDeltaMmu/$calcMz) * (10**6 ) ;
    	#Perform a round at int level
#    	print "\t$mzDeltaPpm\n";
    	
    	my $oUtils = Metabolomics::Utils->new() ;
    	$mzDeltaPpmRounded = $oUtils->roundFloat($mzDeltaPpm, 0) ;
    	
    }
    else {
    	carp "[ERROR Given masses are null\n" ;
    }
    
    return ($mzDeltaPpmRounded) ;
}
### END of SUB


__END__

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inra.fr> >>

=head1 SEE ALSO

All information about FragNot should be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/fragnot

=head1 BUGS

Please report any bugs or feature requests to C<bug-metabolomics-fragnot at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Metabolomics-FragNot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Fragment::Annotation

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Metabolomics-FragNot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Metabolomics-FragNot>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Metabolomics-FragNot>

=item * Search CPAN

L<https://metacpan.org/release/Metabolomics-FragNot>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

CeCILL Copyright (C) 2019 by Franck Giacomoni

Initiated by Franck Giacomoni

followed by INRA PFEM team

Web Site = INRA PFEM


=cut

1; # End of Metabolomics::Fragment::Annotation
