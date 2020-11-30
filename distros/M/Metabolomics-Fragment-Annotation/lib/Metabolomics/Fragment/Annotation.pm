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

Version 0.6.3 - Adding POD and PhytoHUB module


=cut

our $VERSION = '0.6.3';


=head1 SYNOPSIS

Note that this documentation is intended as a reference to the module.

	Metabolomics::Banks::MaConDa is allowing to build a contaminant database usefull to clean your LC-MS filtered peak list:
	
		my $oBank = Metabolomics::Banks::MaConDa->new() ;			# init the bank object
		$oBank->getContaminantsExtensiveFromSource() ;			# get theorical contaminants from the extensive version of MaConDa database
		$oNewBank->buildTheoPeakBankFromContaminants($queryMode) ;			# build theorical bank (ION | NEUTRAL)
    
	Metabolomics::Banks::BloodExposome is giving access to a local Blood Exposome database (Cf publication here L<https://doi.org/10.1289/EHP4713>):
	
		my $oBank = Metabolomics::Banks::BloodExposome->new() ;			# init the bank object
		$oBank->getMetabolitesFromSource($source) ;			# get theorical metabolites from local database version
		$oBank->buildTheoPeakBankFromEntries($IonMode) ;			# produce the new theorical bank depending of chosen acquisition mode
    
	Metabolomics::Banks::Knapsack is giving access to a local Knapsack database (Cf publication here L<https://doi.org/10.1093/pcp/pcr165>):
	
		my $oBank = Metabolomics::Banks::Knapsack->new() ;
		$oBank->getKSMetabolitesFromSource($source) ;
		$oBank->buildTheoPeakBankFromKnapsack($IonMode) ;
    
	Metabolomics::Banks::AbInitioFragments is used abinitio fragment, adduct and isotope annotation:
    
		my $oBank = Metabolomics::Banks::AbInitioFragments->new() ;			# init the bank object
		$oBank->getFragmentsFromSource() ;			# get theorical fragment/adduct/isotopes loses or adds
		$oBank->buildTheoPeakBankFromFragments($mzMolecule, $mode, $stateMolecule) ;			# produce the new theorical bank from neutral (or not) molecule mass
		
	When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:
		$oBank->parsingMsFragments($inputFile, $asHeader, $mzCol) ;			# get exprimental mz listing to annotate
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;			# init analysis object
		$oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ;			# compare theorical bank vs experimental bank

=encoding utf8

=head1 DESCRIPTION

Metabolomics::Fragment::Annotation is a full package for Perl dev allowing MS fragments annotation with ab initio database, contaminant and public metabolites ressources.

All resources used are described and available here:

=head1 Metabolomics::Fragment::Annotation 0.6.x

Metabolomics::Fragment::Annotation Perl package proposes several databases and algorithms to help metabolomics identification step:


=head2 Using BloodExposome database

The exposome represents the sum of all exposures during the life-span of an organism (from chemicals to microbes, viruses, radiation and other sources). Exposome chemicals are a major component of the exposome and are known to alter activities of cellular pathways and structures. In humans, exposome chemicals are transported throughout the body, linking chemical exposures to phenotypes such as such as cancer, ageing or diabetes. 
The Blood Exposome Database (L<https://bloodexposome.org>) is a collection of chemical compounds and associated information that were automatically extracted by text mining the content of PubMed and PubChem databases.
The database also unifies chemical lists from metabolomics, systems biology, environmental epidemiology, occupational expossure, toxiology and nutrition fields.
This db is developped and supported by Dinesh Kumar Barupal and Oliver Fiehn.
The database can be used in following applications - 1) to rank chemicals for building target libraries and expand metabolomics assays 2) to associate blood compounds with phenotypes 3) to get detailed descriptions about chemicals 4) to prepare lists of blood chemical lists by chemical classes and associated properties. 5) to interpret of metabolomics datasets from plasma or serum analyses 6) to prioritize chemicals for hazard assessments.

Metabolomics::Banks::BloodExposome is giving access to a up to date Blood Exposome database stored in metabolomics::references package

	# init the bank object
	
	my $oBank = Metabolomics::Banks::BloodExposome->new() ;
	
	# Get theorical metabolites from local database version
	
	$oBank->getMetabolitesFromSource($source) ;			
	
	# produce the new theorical bank depending of chosen acquisition mode
	
	$oBank->buildTheoPeakBankFromEntries($IonMode) ;

When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

	# Get experimental mz listing to annotate
	
	$oBank->parsingMsFragments($inputFile, $asHeader, $mzCol) ;			
		
	# init analysis object based on a Knapsack bank object
	
	my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;			
	
	# Compare theorical bank vs experimental bank with a delta on mz (Da or PPM are both supported)
	
	$oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ;

Intensity and retention time variables are not used in this annotation because the reference bank does not store such features.


=head2 Using KnapSack database

KnapSack database is a comprehensive Species-Metabolite Relationship Database with more than 53,000 metabolites and 128,000 metabolite-species pair entities.
This db is developped and supported by Yukiko Nakamura, Hiroko Asahi, Md. Altaf-Ul-Amin, Ken Kurokawa and Shigehiko Kanaya.
This resource is very useful for plant or natural product community trying to identify metabolites in samples analysed by LC-MS

 	# init the bank object
	
	my $oBank = Metabolomics::Banks::Knapsack->new()
	
	# get theorical metabolites from last database version (crawled by metabolomics::references package)			
	
	$oBank->getKSMetabolitesFromSource($source) ;
	
	# build potential candidates depending of your acquisition mode used on LC-MS instrument and produce the new theorical bank
	# Only POSITIVE or NEGATIVE is today supported - - "BOTH" does not work
	
	$oBank->buildTheoPeakBankFromKnapsack($IonMode) ;

When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

	# Get experimental mz listing to annotate
	
	$oBank->parsingMsFragments($inputFile, $asHeader, $mzCol) ;			
		
	# init analysis object based on a Knapsack bank object
	
	my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;			
	
	# Compare theorical bank vs experimental bank with a delta on mz (Da or PPM are both supported)
	
	$oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ;

Intensity and retention time variables are not used in this annotation because the reference bank does not store such features.


=head1 PUBLIC METHODS 

=head2 Metabolomics::Fragment::Annotation

=over 4

=item new 

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

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

=item compareExpMzToTheoMzList

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
    		
#    		print "\nFOR frag $fragMz - MIN is: $$min and MAX is: $$max\n" ;
    		
    		my ( $deltaErrorMmu, $deltaErrorPpm) = ( undef, 0 ) ;
    		
    		my ( $currentPpmError, $currentDeltaErrorMmu) = ( undef, undef ) ;
    		my ( $currentAnnotName, $currentComputedMz, $currentAnnotType, $currentAnnotID) =  ( undef, undef, undef, undef ) ;
    		my ( $currentAnnotInNegMode, $currentAnnotInPosMode, $currentAnnotFormula, $currentAnnotSmiles) = ( undef, undef, undef, undef ) ;
    		my ( $currentAnnotInchikey, $currentAnnotIsAMetabolite, $currentAnnotIsAPrecursor) = ( undef, undef, undef ) ;
    		
    		my ( $annotName, $computedMz, $annotType, $annotID) = ( undef, undef, undef, undef ) ;
    		my ( $annotInNegMode, $annotInPosMode, $annotFormula, $annotSmiles) = ( undef, undef, undef, undef ) ;
    		my ( $annotInchikey, $annotIsAMetabolite, $annotIsAPrecursor) = ( undef, undef, undef ) ;
    		
    		foreach my $theoFrag (@{$theoFragments}) {
    			
    			my $motifMz = $theoFrag-> _getPeak_COMPUTED_MONOISOTOPIC_MASS();
    			
    			if (  ($motifMz > $$min ) and ($motifMz < $$max)  ) {
    				
    				$annotName = $theoFrag-> _getPeak_ANNOTATION_NAME();
    				$computedMz = $theoFrag->_getPeak_COMPUTED_MONOISOTOPIC_MASS();
    				$annotType = $theoFrag->_getPeak_ANNOTATION_TYPE() ;
    				$annotID = $theoFrag->_getPeak_ANNOTATION_ID() if $theoFrag->_getPeak_ANNOTATION_ID ;
    				
    				$annotInNegMode =  $theoFrag->_getPeak_ANNOTATION_IN_NEG_MODE() if $theoFrag->_getPeak_ANNOTATION_IN_NEG_MODE() ;
    				$annotInPosMode =  $theoFrag->_getPeak_ANNOTATION_IN_POS_MODE() if $theoFrag->_getPeak_ANNOTATION_IN_POS_MODE() ;
    				
    				$annotFormula = $theoFrag->_getPeak_ANNOTATION_FORMULA() if $theoFrag->_getPeak_ANNOTATION_FORMULA() ;
    				$annotSmiles = $theoFrag->_getPeak_ANNOTATION_SMILES() if $theoFrag->_getPeak_ANNOTATION_SMILES() ;
    				$annotInchikey = $theoFrag->_getPeak_ANNOTATION_INCHIKEY() if $theoFrag->_getPeak_ANNOTATION_INCHIKEY() ;
    				$annotIsAMetabolite = $theoFrag->_getPeak_ANNOTATION_IS_A_METABOLITE() if ($theoFrag->_getPeak_ANNOTATION_IS_A_METABOLITE() and $theoFrag->_getPeak_ANNOTATION_IS_A_METABOLITE() != 0) ;
    				$annotIsAPrecursor = $theoFrag->_getPeak_ANNOTATION_IS_A_PRECURSOR() if ($theoFrag->_getPeak_ANNOTATION_IS_A_PRECURSOR() and $theoFrag->_getPeak_ANNOTATION_IS_A_PRECURSOR() != 0) ;
    				    				
#    				print $annotInNegMode if $annotInNegMode ;
#    				print $annotInPosMode if $annotInPosMode ;
    				
    				# compute error 
    				$deltaErrorMmu = _computeMzDeltaInMmu($fragMz, $motifMz) ;
    				$deltaErrorPpm = _computeMzDeltaInPpm($fragMz, $deltaErrorMmu) ;
    				
    				
    				if (!defined $currentPpmError) {
    					
    					$currentDeltaErrorMmu = $deltaErrorMmu ;
    					$currentPpmError = $deltaErrorPpm ;
						$currentAnnotName =  $annotName ;
						$currentComputedMz = $computedMz ;
						$currentAnnotType = $annotType ;
						$currentAnnotID = $annotID ;
						$currentAnnotInNegMode = $annotInNegMode ;
						$currentAnnotInPosMode = $annotInPosMode ;
						$currentAnnotFormula = $annotFormula ;
						$currentAnnotSmiles = $annotSmiles ;
						$currentAnnotInchikey = $annotInchikey ;
						$currentAnnotIsAMetabolite = $annotIsAMetabolite ;
						$currentAnnotIsAPrecursor = $annotIsAPrecursor ;
	    				
    				}
    				else {
    					
    					if ($currentPpmError < $deltaErrorPpm ) {
    						next ;
    					}
    					elsif ($currentPpmError > $deltaErrorPpm ) {
    						$currentDeltaErrorMmu = $deltaErrorMmu ;
    						$currentPpmError = $deltaErrorPpm ;
							$currentAnnotName =  $annotName ;
							$currentComputedMz = $computedMz ;
							$currentAnnotType = $annotType ;
							$currentAnnotID = $annotID ;
							$currentAnnotInNegMode = $annotInNegMode ;
							$currentAnnotInPosMode = $annotInPosMode ;
							$currentAnnotFormula = $annotFormula ;
							$currentAnnotSmiles = $annotSmiles ;
							$currentAnnotInchikey = $annotInchikey ;
							$currentAnnotIsAMetabolite = $annotIsAMetabolite ;
							$currentAnnotIsAPrecursor = $annotIsAPrecursor ;
    					}
    					elsif ($currentPpmError == $deltaErrorPpm ) {
    						next ;
    					}
    				}
    				
				## Keep the best hit (lower ppm error) and set annotation 
    			$expFrag-> _setPeak_ANNOTATION_DA_ERROR( $currentDeltaErrorMmu );
    			$expFrag-> _setPeak_ANNOTATION_PPM_ERROR( $currentPpmError );
    				
    			$expFrag-> _setPeak_ANNOTATION_NAME( $currentAnnotName );
    			$expFrag-> _setPeak_COMPUTED_MONOISOTOPIC_MASS( $currentComputedMz );
    			$expFrag-> _setPeak_ANNOTATION_TYPE( $currentAnnotType ) if (defined $currentAnnotType);
    			$expFrag-> _setPeak_ANNOTATION_ID( $currentAnnotID ) if (defined $currentAnnotID);
    				
    			$expFrag->_setPeak_ANNOTATION_IN_NEG_MODE($currentAnnotInNegMode) if (defined $currentAnnotInNegMode);
    			$expFrag->_setPeak_ANNOTATION_IN_POS_MODE($currentAnnotInPosMode) if (defined $currentAnnotInPosMode);
    			
    			$expFrag->_setPeak_ANNOTATION_FORMULA($currentAnnotFormula) if (defined $currentAnnotFormula);
    			$expFrag->_setPeak_ANNOTATION_SMILES($currentAnnotSmiles) if (defined $currentAnnotSmiles);
    			$expFrag->_setPeak_ANNOTATION_INCHIKEY($currentAnnotInchikey) if (defined $currentAnnotInchikey);
    			$expFrag->_setPeak_ANNOTATION_IS_A_METABOLITE($currentAnnotIsAMetabolite) if (defined $currentAnnotIsAMetabolite);
    			$expFrag->_setPeak_ANNOTATION_IS_A_PRECURSOR($currentAnnotIsAPrecursor) if (defined $currentAnnotIsAPrecursor);
    			
#    			print "\tOK -> $motifMz MATCHING WITH $fragMz and ppm error of $currentPpmError ($currentAnnotInPosMode)\n" ;

    			} ## Matching !!
    			else {
#    				print "KO -> $motifMz DON'T MATCHING WITH $fragMz\n" ;
    				next ;
    			} ## No Matching
    		}
    	} ## END foreach
    }
    else {
    	croak "[ERROR]: One of peak list is empty or object is undef...\n" ;
    }
}
### END of SUB


=item writeTabularWithPeakBankObject

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


=item writeFullTabularWithPeakBankObject

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

=back

=head1 PRIVATE METHODS

=head2 Metabolomics::Fragment::Annotation

=over 4

=item PRIVATE_ONLY _getPeaksToAnnotated

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

=item PRIVATE_ONLY _getTEMPLATE_TABULAR_FIELDS

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

=item PRIVATE_ONLY _mapPeakListWithTemplateFields

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

=item PRIVATE_ONLY _mz_delta_conversion

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


=item PRIVATE_ONLY _computeMzDeltaInMmu

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

=item PRIVATE_ONLY computeMzDeltaInPpm

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
    	$mzDeltaPpmRounded = $oUtils->roundFloat($mzDeltaPpm, 1) ;
    	
    }
    else {
    	carp "[ERROR Given masses are null\n" ;
    }
    
    return ($mzDeltaPpmRounded) ;
}
### END of SUB

__END__

=back

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inrae.fr> >>
Biological computing & Metabolomics
INRAE - UMR 1019 Human Nutrition Unit – Metabolism Exploration Platform MetaboHUB – Clermont


=head1 SEE ALSO

All information about FragNot should be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/fragnot

=head1 BUGS

Please report any bugs or feature requests to C<bug-metabolomics-fragment-annotation at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Metabolomics-Fragment-Annotation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Fragment::Annotation

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Metabolomics-Fragment-Annotation>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Metabolomics-Fragment-Annotation>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Metabolomics-Fragment-Annotation>

=item * Search CPAN

L<https://metacpan.org/release/Metabolomics-Fragment-Annotation>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to INRAE and All metabolomics colleagues.

=head1 LICENSE AND COPYRIGHT

CeCILL Copyright (C) 2019 by Franck Giacomoni

Initiated by Franck Giacomoni

followed by INRAE PFEM team

Web Site = INRAE PFEM

=cut

1; # End of Metabolomics::Fragment::Annotation
