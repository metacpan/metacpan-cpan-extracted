package Metabolomics::Fragment::Annotation;

use 5.006;
use strict;
use warnings;

use Data::Dumper ;
use POSIX ;
use HTML::Template ;
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
	writeHtmlWithPeakBankObject
	writeHtmlWithSpectralBankObject
	compareExpMzToTheoMzList
	compareExpMzToTheoMzListAllMatches
	computeHrGcmsMatchingScores
	filterAnalysisSpectralAnnotationByScores
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	writeFullTabularWithPeakBankObject 
	writeTabularWithPeakBankObject
	writeHtmlWithPeakBankObject
	writeHtmlWithSpectralBankObject 
	compareExpMzToTheoMzList
	compareExpMzToTheoMzListAllMatches
	computeHrGcmsMatchingScores
	filterAnalysisSpectralAnnotationByScores
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Fragment::Annotation - Perl extension for fragment annotation in metabolomics 

=head1 VERSION

	Version 0.6.4 - POD Update, multiAnnotation support in matching algo and writers, PeakForest REST API integration, supporting CSV and TSV as inputs (sniffer), HTML outputs
	Version 0.6.5 - Package architecture modification (PeakForest Part), POD improvement, Annotation results filtering based on scores
	Version 0.6.6 - Fix cpan bugs (#24) and fix several templates and properties issues (rel int, peakforest compliance, ...)
	Version 0.6.7 - Fix tests issues + pod alignment
	Version 0.6.8 - Buggy version 
	Version 0.6.9 - Fix GCMS tests issue, fix intensity value missing in banks module + PeakForest REST API Client Update

=cut

our $VERSION = '0.6.9';


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
		
	Metabolomics::Banks::PeakForest is giving access to any PeakForest database by its REST API
		
		my $oBank = Metabolomics::Banks::PeakForest->new(%PARAMS) ; # init the bank object with %PARAMS as DATABASE_URL, TOKEN, POLARITY, RESOLUTION
		$oBank->parsingMsFragmentsByCluster($expFile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds) ; # get fragments by cluster or pcgroup
		$oBank->buildSpectralBankFromPeakForest($column_code, $delta) ; # produce the new theorical bank querying REST API (GCMS part for this version)
		
		
	When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;			# init analysis object
		$oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ;			# compare theorical bank vs experimental bank (Best hit only)
		$oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ; 	# compare theorical bank vs experimental bank (supporting multi annotation)
		
		$oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ; # Write TSV enriched output with integrated input data
		$oAnalysis->writeTabularWithPeakBankObject($template, $tabular) ; 				# Write TSV enriched output
		$oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile, $bestHitOnly ) ; # Write Html enriched output
		
	For spectral Annotation, Package allows to compute scores (ONLY GCMS scores for current package version) and filter results by threshold based on these scores
	
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;			# init analysis object
		$oAnalysis->compareExpMzToTheoMzListAllMatches('MMU', $delta) ; 	# compare theorical bank vs experimental bank (supporting multi annotation)
		
		my $scores = $oAnalysis->computeHrGcmsMatchingScores() ; # Compute _SCORE_PEARSON_CORR_ , _SCORE_Q_ and _SCORE_LIB_
		
		$oAnalysis->filterAnalysisSpectralAnnotationByScores($scores, '_SCORE_PEARSON_CORR_', 0.5) ;	
		
		$oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ; # Write TSV enriched output with integrated input data
		$oAnalysis->writeTabularWithPeakBankObject($template, $tabular) ; 				# Write TSV enriched output
		$oAnalysis->writeHtmlWithSpectralBankObject($templateHTML, $htmlFile, $scores ) ; # Write Html enriched output
		
	Possible scores are:
		# For GC/MS Spectral annotation
		_SCORE_LIB_: Proportion of library spectrum's peaks with matches.
		_SCORE_Q_: Proposition of query peaks with matches.
		_SCORE_PEARSON_CORR_: Pearson correlation between intensities of paired peaks, where unmatched peaks are paired with zero-intensity "pseudo-peaks"

		# For LC/MS spectral annotation
		Work is in progress for version 0.6.6 of Metabolomics::Fragment::Annotation
		
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
	
	$oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ; # Keep best hit only

Intensity and retention time variables are not used in this annotation because the reference bank does not store such features.

=head2 Using PhytoHUB database

PhytoHub is a freely available electronic database containing detailed information about dietary phytochemicals and their human and animal metabolites. 
Around 1,200 polyphenols, terpenoids, alkaloids and other plant secondary metabolites present in commonly consumed foods (>350) are included, with >560 of their human or animal metabolites. 
For every phytochemical, the following is or will be soon available: 
	1) the chemical structure and identifyers 
	2) physico-chemical data such as solubility and physiological charge 
	3) the main dietary sources (extracted from the literature by a team of invited experts and from online databases such as FooDB and Phenol-Explorer) 
	4) known human metabolites (also manually extracted from the literature and from online databases by the curators), 
	5) in silico predicted metabolites, generated by Biotransformer (developed by Univ of Alberta) based on machine learning and expert knowledge of host and microbial metabolism, 
	6) monoisotopic mass and spectral data (collated from libraries of spectra such as MassBank and ReSpect (RIKEN MSn spectral database for phytochemicals), as well as from the literature and from our mass spectrometry/metabolomics laboratory and collaborating groups) 
	7) hyperlinks to other online databases.
	
PhytoHUB is a key resource in European JPI Projects FOODBALL (https://foodmetabolome.org/) and FOODPHYT (2019-2022).

This resource is very useful for foodmetabolome studies, trying to identify metabolites in samples analysed by LC-MS

# init the bank object
	
	my $oBank = Metabolomics::Banks::PhytoHub->new( { POLARITY => $IonMode, } ) ;
	
	# get theorical metabolites from last database version (crawled by metabolomics::references package)			
	
	$oBank->getMetabolitesFromSource($source) ;
	
	# build potential candidates depending of your acquisition mode used on LC-MS instrument and produce the new theorical bank
	# Only POSITIVE or NEGATIVE is today supported - - "BOTH" does not work
	
	$oBank->buildTheoPeakBankFromPhytoHub($IonMode) ;

When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

	# Don't forget to parse your tabular or CSV input peak list
	
	$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm $col

	# init analysis object based on a PhytoHUB bank object
	
	my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

	# Compare theorical bank vs experimental bank with a delta on mz (Da or PPM are both supported)
	
	my $Annot = $oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ; ## multi annotation method

	# Write different outputs adapted for different view of results
	
	my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ; ## add result columns at the end of your inputfile 
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ; ## foreach mz from your peak list, give annotation results (can be several lines by mz)
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ; A html results view + hyperlinks to database


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
    $self->{_ANNOTATION_ION_MODE_} = $args->{_POLARITY_} || 'annotation_ion_mode' ; ## would be POSITIVE|NEGATIVE|NEUTRAL
    $self->{_ANNOTATION_DB_SOURCE_} = $args->{_DATABASE_NAME_} ;
    $self->{_ANNOTATION_DB_SOURCE_TYPE_} = $args->{_DATABASE_TYPE_} ;
    $self->{_ANNOTATION_DB_SOURCE_VERSION_} = $args->{_DATABASE_VERSION_} ;
    $self->{_ANNOTATION_DB_SOURCE_URL_} = $args->{_DATABASE_URL_} ;
    $self->{_ANNOTATION_DB_SOURCE_URL_CARD_} = $args->{_DATABASE_URL_CARD_} ;
    $self->{_ANNOTATION_DB_SPECTRA_INDEX_} = $args->{_DATABASE_SPECTRA_} ;
#    $self->{_ANNOTATION_SCORES_} = undef ; # A hash
    $self->{_ANNOTATION_PARAMS_DELTA_} = undef ;
    $self->{_ANNOTATION_PARAMS_DELTA_TYPE_} = undef ; ## should be PPM | MMU
    $self->{_ANNOTATION_PARAMS_INSTRUMENTS_} = [] ;
    $self->{_ANNOTATION_PARAMS_FILTERS_} = [] ;
    
    $self->{_THEO_PEAK_LIST_} = $args->{_THEO_PEAK_LIST_} ;
    $self->{_EXP_PEAK_LIST_} = $args->{_EXP_PEAK_LIST_} ;
    $self->{_EXP_PSEUDOSPECTRA_LIST_} = $args->{_EXP_PSEUDOSPECTRA_LIST_} ;
    $self->{_EXP_PEAK_LIST_ALL_ANNOTATIONS_} = $args->{_EXP_PEAK_LIST_ALL_ANNOTATIONS_} ;
    $self->{_PSEUDOSPECTRA_SPECTRA_INDEX_} = $args->{_PSEUDOSPECTRA_SPECTRA_INDEX_} ;

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
    
    ## Set Annotation object with search parameters
    $self->_setANNOTATION_PARAMS_DELTA_TYPE($deltaType) ;
    $self->_setANNOTATION_PARAMS_DELTA($deltaValue) ;
    
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


=item compareExpMzToTheoMzListAllMatches

	## Description : comparing two lists of mzs (theo and experimental) with a mz delta and keep all matches
	## Input : $deltaValue, $deltaType
	## Output : $oAnalysis with annotation results
	## Usage : $oAnalysis->compareExpMzToTheoMzListAllMatches ( $deltaValue, $deltaType ) ;

=cut

## START of SUB
sub compareExpMzToTheoMzListAllMatches {
    ## Retrieve Values
    my $self = shift ;
    my ($deltaType, $deltaValue ) = @_ ;
    
    ## Set Annotation object with search parameters
    $self->_setANNOTATION_PARAMS_DELTA_TYPE($deltaType) ;
    $self->_setANNOTATION_PARAMS_DELTA($deltaValue) ;
    
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
    		
    		my ( $annotName, $mesuredMz, $computedMz, $annotType, $annotID) = ( undef, undef, undef, undef, undef ) ;
    		my ( $annotInNegMode, $annotInPosMode, $annotFormula, $annotSmiles) = ( undef, undef, undef, undef ) ;
    		my ( $annotInchikey, $annotIsAMetabolite, $annotIsAPrecursor) = ( undef, undef, undef ) ;
    		my ( $annotInt, $annotInt100, $annotInt999) = ( undef, undef, undef ) ;
    		my ( $annotSpectralId, $annotClusterId ) = ( undef, undef ) ;
    		
    		my $Matches = 'FALSE' ;
    		my @matches = () ;
    		
    		foreach my $theoFrag (@{$theoFragments}) {
    			
    			my $motifMz = $theoFrag-> _getPeak_COMPUTED_MONOISOTOPIC_MASS();
    			
    			if (  ($motifMz > $$min ) and ($motifMz < $$max)  ) {
    				
    				$Matches = 'TRUE' ;
    				
    				$computedMz =  $theoFrag->_getPeak_COMPUTED_MONOISOTOPIC_MASS() ;
    				$annotName = $theoFrag-> _getPeak_ANNOTATION_NAME() ;
    				$annotType = $theoFrag->_getPeak_ANNOTATION_TYPE() if $theoFrag->_getPeak_ANNOTATION_TYPE ;
    				$annotID = $theoFrag->_getPeak_ANNOTATION_ID() if $theoFrag->_getPeak_ANNOTATION_ID ;
    				$annotInNegMode = $theoFrag->_getPeak_ANNOTATION_IN_NEG_MODE()  if $theoFrag->_getPeak_ANNOTATION_IN_NEG_MODE() ;
    				$annotInPosMode = $theoFrag->_getPeak_ANNOTATION_IN_POS_MODE() if $theoFrag->_getPeak_ANNOTATION_IN_POS_MODE() ;
    				$annotFormula = $theoFrag->_getPeak_ANNOTATION_FORMULA() if $theoFrag->_getPeak_ANNOTATION_FORMULA() ;
    				$annotSmiles = $theoFrag->_getPeak_ANNOTATION_SMILES() if $theoFrag->_getPeak_ANNOTATION_SMILES() ;
    				$annotInchikey = $theoFrag->_getPeak_ANNOTATION_INCHIKEY() if $theoFrag->_getPeak_ANNOTATION_INCHIKEY()  ;
    				$annotIsAMetabolite = $theoFrag->_getPeak_ANNOTATION_IS_A_METABOLITE()  if ($theoFrag->_getPeak_ANNOTATION_IS_A_METABOLITE() and $theoFrag->_getPeak_ANNOTATION_IS_A_METABOLITE() != 0) ;
    				$annotIsAPrecursor = $theoFrag->_getPeak_ANNOTATION_IS_A_PRECURSOR()  if ($theoFrag->_getPeak_ANNOTATION_IS_A_PRECURSOR() and $theoFrag->_getPeak_ANNOTATION_IS_A_PRECURSOR() != 0) ;
    				$annotInt = $expFrag->_getPeak_INTENSITY() if $expFrag->_getPeak_INTENSITY() ;
    				$annotInt100 = $expFrag->_getPeak_RELATIVE_INTENSITY_100() if $expFrag->_getPeak_RELATIVE_INTENSITY_100()  ;
    				$annotInt999 = $expFrag->_getPeak_RELATIVE_INTENSITY_999() if $expFrag->_getPeak_RELATIVE_INTENSITY_999()  ;
    				$annotSpectralId = $theoFrag->_getPeak_ANNOTATION_SPECTRA_ID() if $theoFrag->_getPeak_ANNOTATION_SPECTRA_ID()  ;
    				# Get Cluster if exists in exp peak
    				$annotClusterId = $expFrag->_getPeak_CLUSTER_ID() if $expFrag->_getPeak_CLUSTER_ID()  ;
#    				warn "\tMATCH! -> with $annotID and $annotInchikey\n " ;
    				# compute error 
    				$deltaErrorMmu = _computeMzDeltaInMmu($fragMz, $motifMz) ;
    				$deltaErrorPpm = _computeMzDeltaInPpm($fragMz, $deltaErrorMmu) ;
    				
    				my $oPeak = Metabolomics::Banks->__refPeak__() ;
					$oPeak->_setPeak_MESURED_MONOISOTOPIC_MASS ( $fragMz );
	    			$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMz );
	    			$oPeak->_setPeak_ANNOTATION_NAME( $annotName ) ;
	    			$oPeak->_setPeak_ANNOTATION_TYPE( $annotType ) ;
	    			$oPeak->_setPeak_ANNOTATION_ID( $annotID ) ;
	    			$oPeak->_setPeak_ANNOTATION_IN_NEG_MODE( $annotInNegMode )   ;
	    			$oPeak->_setPeak_ANNOTATION_IN_POS_MODE( $annotInPosMode )  ;
	    			$oPeak->_setPeak_ANNOTATION_FORMULA( $annotFormula )  ;
	    			$oPeak->_setPeak_ANNOTATION_SMILES( $annotSmiles )  ;
	    			$oPeak->_setPeak_ANNOTATION_INCHIKEY( $annotInchikey )   ;
	    			$oPeak->_setPeak_ANNOTATION_IS_A_METABOLITE( $annotIsAMetabolite ) ;
	    			$oPeak->_setPeak_ANNOTATION_IS_A_PRECURSOR( $annotIsAPrecursor ) ;
					$oPeak->_setPeak_ANNOTATION_DA_ERROR($deltaErrorMmu) ;
	    			$oPeak->_setPeak_ANNOTATION_PPM_ERROR($deltaErrorPpm) ;
	    			$oPeak->_setPeak_RELATIVE_INTENSITY_100($annotInt100) ;
	    			$oPeak->_setPeak_RELATIVE_INTENSITY_999($annotInt999) ;
	    			$oPeak->_setPeak_INTENSITY($annotInt) ;    			
	    			$oPeak->_setPeak_ANNOTATION_SPECTRAL_IDS($annotSpectralId) ;
	    			$oPeak->_setPeak_CLUSTER_ID($annotClusterId) if (defined $annotClusterId) ;

					$self->_addAnnotatedPeakList('_EXP_PEAK_LIST_ALL_ANNOTATIONS_', $oPeak) ;
					
					push(@matches, $oPeak) ;
    			
#    				print "\tOK -> $motifMz MATCHING WITH $fragMz and ppm error of $deltaErrorMmu\n" ;
    			} ## End of Matching !!
    			else {
    				next ;
    			} ## End of No Matching
    		} ## END foreach theo peak
    		
    		if ($Matches eq 'FALSE') {
    			my $oNoMatchedPeak = Metabolomics::Banks->__refPeak__() ;
    			$oNoMatchedPeak->_setPeak_MESURED_MONOISOTOPIC_MASS ( $fragMz );
    			$oNoMatchedPeak->_setPeak_ANNOTATION_DA_ERROR(0) ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_PPM_ERROR(0) ;
	    		$oNoMatchedPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( 0 );
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_NAME( undef ) ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_TYPE( undef ) ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_ID( undef ) ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_IN_NEG_MODE( undef )   ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_IN_POS_MODE( undef )  ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_FORMULA( undef )  ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_SMILES( undef )  ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_INCHIKEY( undef )   ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_IS_A_METABOLITE( undef ) ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATION_IS_A_PRECURSOR( undef ) ;
	    		$oNoMatchedPeak->_setPeak_ANNOTATIONS(undef) ;
	    		$oNoMatchedPeak->_setPeak_INTENSITY( $expFrag->_getPeak_INTENSITY() ) if $expFrag->_getPeak_INTENSITY() ;
	    		$oNoMatchedPeak->_setPeak_RELATIVE_INTENSITY_100($expFrag->_getPeak_RELATIVE_INTENSITY_100() ) if $expFrag->_getPeak_RELATIVE_INTENSITY_100() ;
	    		$oNoMatchedPeak->_setPeak_RELATIVE_INTENSITY_999($expFrag->_getPeak_RELATIVE_INTENSITY_999() ) if $expFrag->_getPeak_RELATIVE_INTENSITY_999() ;
	    		$oNoMatchedPeak->_setPeak_CLUSTER_ID( $expFrag->_getPeak_CLUSTER_ID() ) if $expFrag->_getPeak_CLUSTER_ID()  ;
	    		
	    		## TODO - No match intensities    
	    		
#    			print "KO -> $motifMz DON'T MATCHING WITH $fragMz\n" ;
				$self->_addAnnotatedPeakList('_EXP_PEAK_LIST_ALL_ANNOTATIONS_', $oNoMatchedPeak) ;
    		}
    		else {
    			## Set best hit as exp peak annotation
    			my @sortedMatches = () ;
    			@sortedMatches = sort {$$a{"_PPM_ERROR_"} <=> $$b{"_PPM_ERROR_"} } @matches;
    			@matches = () ; ## flush Array
#    			print Dumper @sortedMatches ;
    			my $bestAnnotedPeak = $sortedMatches[0] ;
    			
    			$expFrag-> _setPeak_ANNOTATION_DA_ERROR( $bestAnnotedPeak->_getPeak_ANNOTATION_DA_ERROR() );
    			$expFrag-> _setPeak_ANNOTATION_PPM_ERROR( $bestAnnotedPeak->_getPeak_ANNOTATION_PPM_ERROR() );
    				
    			$expFrag-> _setPeak_ANNOTATION_NAME( $bestAnnotedPeak->_getPeak_ANNOTATION_NAME() );
    			$expFrag-> _setPeak_COMPUTED_MONOISOTOPIC_MASS( $bestAnnotedPeak->_getPeak_COMPUTED_MONOISOTOPIC_MASS() );
    			$expFrag-> _setPeak_ANNOTATION_TYPE( $bestAnnotedPeak->_getPeak_ANNOTATION_TYPE() ) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_TYPE());
    			$expFrag-> _setPeak_ANNOTATION_ID( $bestAnnotedPeak->_getPeak_ANNOTATION_ID() ) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_ID());
    				
    			$expFrag->_setPeak_ANNOTATION_IN_NEG_MODE($bestAnnotedPeak->_getPeak_ANNOTATION_IN_NEG_MODE()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_IN_NEG_MODE());
    			$expFrag->_setPeak_ANNOTATION_IN_POS_MODE($bestAnnotedPeak->_getPeak_ANNOTATION_IN_POS_MODE()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_IN_POS_MODE());
    			
    			$expFrag->_setPeak_ANNOTATION_FORMULA($bestAnnotedPeak->_getPeak_ANNOTATION_FORMULA()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_FORMULA());
    			$expFrag->_setPeak_ANNOTATION_SMILES($bestAnnotedPeak->_getPeak_ANNOTATION_SMILES()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_SMILES());
    			$expFrag->_setPeak_ANNOTATION_INCHIKEY($bestAnnotedPeak->_getPeak_ANNOTATION_INCHIKEY()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_INCHIKEY());
    			$expFrag->_setPeak_ANNOTATION_IS_A_METABOLITE($bestAnnotedPeak->_getPeak_ANNOTATION_IS_A_METABOLITE()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_IS_A_METABOLITE());
    			$expFrag->_setPeak_ANNOTATION_IS_A_PRECURSOR($bestAnnotedPeak->_getPeak_ANNOTATION_IS_A_PRECURSOR()) if (defined $bestAnnotedPeak->_getPeak_ANNOTATION_IS_A_PRECURSOR());
    			
    			## TODO - Best Hit intensities    			
    			
    			$expFrag->_setPeak_ANNOTATIONS(\@sortedMatches) ;
    		}
    		
    	} ## END foreach exp peak
    }
    else {
    	 if (  ( scalar (@{$expFragments}) == 0 ) and  ( scalar (@{$theoFragments}) == 0 ) ) {
    	 	croak "[ERROR]: Both peak lists (EXP / THEO) are empty or object is undef...\n" ;
    	 }
    	 elsif (  ( scalar (@{$expFragments}) == 0 ) ) {
    	 	croak "[ERROR]: Experimental peak lists is empty ...\n" ;
    	 }
    	 elsif (  ( scalar (@{$theoFragments}) > 0 ) ) {
    	 	warn "[WARN]: Theorical peak lists is empty (No results?)...\n" ;
    	 }
    	
    }
#    print Dumper @AnnotatedPeaks ;
#    return (\@AnnotatedPeaks) ;
}
### END of SUB

=item computeHrGcmsMatchingScores

	## Description : compute by fullscan High resolution GCMS pseudospectra, all needed scores
	## Input : $oAnalysis
	## Output : $scores
	## Usage : my ( $scores ) = $oAnalysis->computeHrGcmsMatchingScores ( ) ;

=cut

## START of SUB
sub computeHrGcmsMatchingScores {
	## Retrieve Values
    my $self = shift ;
    
    my $expPseudoSpectra = $self->_getPeaksToAnnotated('_EXP_PSEUDOSPECTRA_LIST_') ;
    my $spectraPeakList = $self->_getPeaksToAnnotated('_ANNOTATION_DB_SPECTRA_INDEX_') ;
    
    my %MatchingSyntesis = () ;
    my %spectraScores = () ;
    
    foreach my $pcId (keys %{$expPseudoSpectra}) {
    	
#    	print "Cluster -- $pcId\n" ;
    	
    	# structure [ [intE_x, intT_y], ... ]
#    	my $i = 0 ;
#    	my $annot = 0 ;
    	foreach my $oPeak (@{$expPseudoSpectra->{$pcId}}) {
#    		$i++ ;
    		my $RIexp = $oPeak->_getPeak_RELATIVE_INTENSITY_100() ;
    		my $RIsp = undef ;
    		my $spectralIDs = undef ;
#    		
    		my $matchedPeaksRelatedToSpectra = $oPeak->_getPeak_ANNOTATIONS() ;
    		
    		## Some matched exists
    		if ($matchedPeaksRelatedToSpectra > 0 ) {
#    			my $j = 0 ;
    			foreach my $oMatchedPeak (@{$matchedPeaksRelatedToSpectra}) {
#    				$j ++ ;
#    				$annot ++ ;
#	    			print Dumper $oMatchedPeak ;
	    			$spectralIDs = $oMatchedPeak->_getPeak_ANNOTATION_SPECTRAL_IDS() ;
#	    			print Dumper $spectralIDs ;
	    			$RIsp = $oMatchedPeak->_getPeak_RELATIVE_INTENSITY_100() ;
	    			
	    			my $scoreIndex = $spectralIDs->[0].'-'.$pcId ;
	    			
	    			push (@{ $MatchingSyntesis{$scoreIndex}{'INT_MATCHING'} }, [$RIexp, $RIsp ] ) ;
#	    			print "$scoreIndex -- expPeak $i / annot $j (total $annot) -> [ $RIexp, $RIsp ]\n" ;
	    			
    			## add cluster id information
	    			$MatchingSyntesis{$scoreIndex}{'CLUSTER_ID'} = $pcId if (! $MatchingSyntesis{$scoreIndex}{'CLUSTER_ID'} ) ;
	    			$MatchingSyntesis{$scoreIndex}{'SPECTRAL_ID'} = $spectralIDs->[0] ;
	    		}
    		}   		
#    		
    	} ## END FOREACH $oPeak
    } ## END FOREACH $pcId
    
#    print Dumper %MatchingSyntesis ;
    
    foreach my $spectralId_pcId (keys %MatchingSyntesis) {
    	# get cluster_id
    	my $pcId = $MatchingSyntesis{$spectralId_pcId}{'CLUSTER_ID'} ;
    	my $spectralId = $MatchingSyntesis{$spectralId_pcId}{'SPECTRAL_ID'} ;
    	
    	## Get indicators as Total peak matched in query or in lib...
    	my $nbLibPeaks = scalar (@{$spectraPeakList->{$spectralId}{'_PEAKS_'}}) ;
    	my $nbQueryPeaks = scalar (@{$expPseudoSpectra->{$pcId}} ) ;
    	my $nbMatches = scalar (@{$MatchingSyntesis{$spectralId_pcId}{'INT_MATCHING'}}) ;
    	
    	$MatchingSyntesis{$spectralId_pcId}{'TOTAL_LIB_PEAKS'} = $nbLibPeaks ;
    	$MatchingSyntesis{$spectralId_pcId}{'TOTAL_QUERY_PEAKS'} = $nbQueryPeaks ; ## Total peaks from pseudospectra used as query
    	$MatchingSyntesis{$spectralId_pcId}{'TOTAL_MATCHES'} = $nbMatches ;
    	
    	## Complete Intensity arrays with unmatched query peaks on matched spectral peaks
    	foreach my $libPeak ( @{ $spectraPeakList->{$spectralId}{'_PEAKS_'} } ) {
    		
    		my $libPeakRelInt = $libPeak->{'ri'} ;
    		my $machingStatus = 'FALSE' ;
    		
    		foreach my $matchedPeaksPair ( @{ $MatchingSyntesis{$spectralId_pcId}{'INT_MATCHING'} } ) {
    			my $matchedSpRelInt = $matchedPeaksPair->[1] ;
    			
    			if ( $libPeakRelInt == $matchedSpRelInt ) {
    				$machingStatus = 'TRUE' ;
    				last ;
    			}
    			else {
    				next ;
    			}
    		}
    		## No match between spectra and query
    		if ( $machingStatus eq 'FALSE' ) {
    			push ( @{ $MatchingSyntesis{$spectralId_pcId}{'INT_MATCHING'} }, [ 0, $libPeakRelInt] )
    		}
    	}
    	
#    	print Dumper %MatchingSyntesis ;
    	
    	# Score computing
    	my ($ScoreQuery, $ScoreLib, $ScorePearsonCorr ) = (undef, undef, undef) ;
    	
    	my $oUtils = Metabolomics::Utils->new() ;
    	$ScoreQuery = $oUtils->computeScoreMatchedQueryPeaksPercent($nbMatches, $nbQueryPeaks) ;
    	$ScoreLib = $oUtils->computeScoreMatchedLibrarySpectrumPeaksPercent($nbMatches, $nbLibPeaks) ;
    	
    	## To avoid illegal division with spectra == 1 peak
    	my $nbIntensityPairs = scalar @{$MatchingSyntesis{$spectralId_pcId}{'INT_MATCHING'}} ;
    	if ($nbIntensityPairs > 0 ) {
    		$ScorePearsonCorr = $oUtils->computeScorePairedPeaksIntensitiesPearsonCorrelation( $MatchingSyntesis{$spectralId_pcId}{'INT_MATCHING'} ) ;
    	}
    	else {
    		$ScorePearsonCorr = 0 ;
    	}
    	
    	$spectraScores{$pcId}{$spectralId}{'_SCORE_Q_'} = $ScoreQuery ;
    	$spectraScores{$pcId}{$spectralId}{'_SCORE_LIB_'} = $ScoreLib ;
    	$spectraScores{$pcId}{$spectralId}{'_SCORE_PEARSON_CORR_'} = $ScorePearsonCorr ;
    	
#    	print "SCORES ARE: Q:$ScoreQuery / L:$ScoreLib / P:$ScorePearsonCorr\n" ;
    
    }
        
#    print Dumper %spectraScores ;

    return (\%spectraScores) ;
}
### END of SUB

=item filterAnalysisSpectralAnnotationByScores

	## Description : filter a analysis object (after spectral annotation) by score
	## Input : $oAnalysis, $scoreType, $scoreFilterValue
	## Output : $oAnalysis
	## Usage : my ( $oAnalysis ) = $oAnalysis->filterAnalysisSpectralAnnotationByScores ( $oAnalysis, $scoreType, $scoreFilterValue ) ;

=cut

## START of SUB
sub filterAnalysisSpectralAnnotationByScores {
    ## Retrieve Values
    my $self = shift ;
    
    my ( $SCORES, $scoreType, $scoreFilterValue ) = @_;
    
    if ( scalar ( keys %{$SCORES} ) > 0  ) {
    	
    	## Demo with cluster 1505
    	my $PSEUDOSPECTRALIST = $self->_getPeaksToAnnotated('_EXP_PSEUDOSPECTRA_LIST_') ; # HASH
    	my $EXPPEAKLISTALLANNOTATIONS = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_ALL_ANNOTATIONS_') ; # ARRAY
    	my $EXPPEAKLIST = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ; # ARRAY
    	
    	foreach my $groupId ( keys %{ $SCORES } ) {
    		
    		foreach my $spectralId ( keys %{ $SCORES->{$groupId} } ) {
    			
    			if ( $SCORES->{$groupId}{$spectralId}{$scoreType} ) {
    				
    				my $currentScore = $SCORES->{$groupId}{$spectralId}{$scoreType} ;
    				
    				if ( $currentScore < $scoreFilterValue) {
    					
    					foreach my $expPeakAllAnnot (@{$EXPPEAKLISTALLANNOTATIONS}) {
    						
    						if ( (defined $expPeakAllAnnot->_getPeak_CLUSTER_ID() ) and ($expPeakAllAnnot->_getPeak_CLUSTER_ID() eq $groupId ) ) {
    							
    							if ( scalar ($expPeakAllAnnot->_getPeak_ANNOTATION_SPECTRAL_IDS()) > 0 ) {
    								
    								foreach my $AnnotSpectralId (@{ $expPeakAllAnnot->_getPeak_ANNOTATION_SPECTRAL_IDS() }) {
    									
    									if ($spectralId eq $AnnotSpectralId) {
    										$expPeakAllAnnot->_setPeakFilterPass('FALSE') ;
    									}
    								}
    							}
    						}
    					}
    				}
    			}
    		}
    	}
    	
		## For test only    	
#    	foreach my $expPeak (@{$EXPPEAKLIST}) {
#    		if ( (defined $expPeak->_getPeak_CLUSTER_ID() ) and ($expPeak->_getPeak_CLUSTER_ID() eq '1505' || '0666' ) ) {
#    			print "----------------------> ExpPEAK:\n" ;
#    			print Dumper $expPeak ;
#    		}
#    	}
#    	
#    	foreach my $expPeakAllAnnot (@{$EXPPEAKLISTALLANNOTATIONS}) {
#    		if ( (defined $expPeakAllAnnot->_getPeak_CLUSTER_ID() ) and ($expPeakAllAnnot->_getPeak_CLUSTER_ID() eq '1505' || '0666' ) ) {
#    			print "----------------------> ExpPEAKALLANNOT:\n" ;
#    			print Dumper $expPeakAllAnnot ;
#    		}
#    	}
    } ## END IF SCORES keys > 0
    else {
    	warn "[WARN] No computed scores detected - - No filter applied on analysis object\n" ;
    }
    
    return () ;
}
### END of SUB



=item writeHtmlWithPeakBankObject

	## Description : write a full html file from a template and mapping peak bank objects features
	## Input : $oBank, $templateHTML, $htmlfile
	## Output : $tabular
	## Usage : my ( $htmlfile ) = $oBank->writeHtmlWithPeakBankObject ( $templateHTML, $htmlfile ) ;

=cut

## START of SUB
sub writeHtmlWithPeakBankObject {
    ## Retrieve Values
    my $self = shift ;
    
    my ( $templateHTML, $htmlfile, $bestHitOnly ) = @_;
    
#    my ( $html_file_name,  $html_object, $pages , $search_condition, $html_template, $js_path, $css_path ) = @_ ;
    
    ## Manage best hit only or all annotations
	my $peakList = undef ;
	
	if ( (!defined $bestHitOnly) or ( $bestHitOnly eq 'TRUE') ) {
		$peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
	}
	else {
		$peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_ALL_ANNOTATIONS_') ;
	}
	
	## Create and set oTbody
    my ($PAGES_NB, $oHtmlTbody) = $self->_setPeakHtmlTbody( $peakList ) ;
    
    ## Write HTML from oTbody
    if ( defined $htmlfile ) {
		open ( HTML, ">$htmlfile" ) or die "Can't create the output file $htmlfile " ;
		
		if (-e $templateHTML) {
			my $ohtml = HTML::Template->new(filename => $templateHTML);
			$ohtml->param(  DATABASE => $self->{_ANNOTATION_DB_SOURCE_}  ) ;
			$ohtml->param(  CONDITIONS => 'search_condition'  ) ;
			$ohtml->param(  PAGES_NB => $PAGES_NB  ) ;
			$ohtml->param(  PAGES => $oHtmlTbody  ) ;
			print HTML $ohtml->output ;
		}
		else {
			croak "Can't fill any html output : No template available ($templateHTML)\n" ;
		}
		
		close (HTML) ;
    }
    else {
    	croak "No output file name available to write HTML file\n" ;
    }
    
    
    return ( $templateHTML ) ;
}
### END of SUB


=item writeHtmlWithSpectralBankObject

	## Description : write a output file in HTML format from a template and mapping spectral bank objects features
	## Input : $oBank, $templateHTML, $htmlfile
	## Output : $htmlfile
	## Usage : my ( $htmlfile ) = $oBank->writeTabularWithPeakBankObject ( $templateHTML, $htmlfile ) ;

=cut

## START of SUB
sub writeHtmlWithSpectralBankObject {
    ## Retrieve Values
    my $self = shift ;
    my ( $templateHTML, $htmlFile, $SCORES ) = @_;
    
    ## Prepare Data for PCGROUPs and SPECTRA
    my $PSEUDOSPECTRALIST = $self->_getPeaksToAnnotated('_EXP_PSEUDOSPECTRA_LIST_') ;
    
    my $pseudoSpNb = 0 ;
    $pseudoSpNb = scalar (keys %{$PSEUDOSPECTRALIST}) ;
    
    my $SearchParameters = '*Delta* ('.$self->_getANNOTATION_PARAMS_DELTA().''.$self->_getANNOTATION_PARAMS_DELTA_TYPE().')' if ($self->_getANNOTATION_PARAMS_DELTA() and $self->_getANNOTATION_PARAMS_DELTA_TYPE()  )  ;
    $SearchParameters = '_search_parameters_' if (!defined $SearchParameters) ;
    
    
    my ($PCGROUPS, $SPECTRA) = $self->_setSpectraHtmlTboby($PSEUDOSPECTRALIST, $SCORES) ;
    
    if ( defined $htmlFile ) {
		open ( HTML, ">$htmlFile" ) or die "Can't create the output file $htmlFile " ;
		
		if (-e $templateHTML) {
			my $ohtml = HTML::Template->new(filename => $templateHTML, utf8 => 1,) ;
			
			$ohtml->param(  PSEUDOSPECTRA_NB => $pseudoSpNb ) ;
			$ohtml->param(  DATABASE => $self->_getANNOTATION_DB_SOURCE() ) ;
			$ohtml->param(  PARAMS => $SearchParameters  ) ;
			$ohtml->param(  PCGROUP_COLUMNS => $PCGROUPS  ) ;
			$ohtml->param(  PCGROUP_N_SERIES => $SPECTRA  ) ;
						
			print HTML $ohtml->output ;
		}
		else {
			croak "Can't fill any html output : No template available ($templateHTML)\n" ;
		}
		
		close (HTML) ;
    }
    else {
    	croak "No output file name available to write HTML file\n" ;
    }
    
    return ($htmlFile) ;
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
    my ( $templateTabular, $tabular, $bestHitOnly ) = @_;
    
    ## Manage best hit only or all annotations
	my $peakList = undef ;
	
	if ( (!defined $bestHitOnly) or ( $bestHitOnly eq 'TRUE') ) {
		$peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
	}
	else {
		$peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_ALL_ANNOTATIONS_') ;
	}
    
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
    my ( $inputTabular, $templateTabular, $tabular, $bestHitOnly ) = @_;
    
    my $inputFields = undef ;
    my @inputData = () ; # an array of hash correxponding to the input tabular file
    
    ## input source needs a header...
    if (-e $inputTabular) {
    	$inputFields = _getTEMPLATE_TABULAR_FIELDS($inputTabular) ;
    }
    else {
    	croak "[ERROR] Your input file does not exist ($inputTabular...)\n" ;
    }
	
	## Manage best hit only or all annotations
	my $peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
	
    my $templateFields = _getTEMPLATE_TABULAR_FIELDS($templateTabular) ;
    my $peakListRows = _mapPeakListWithTemplateFields($templateFields, $peakList) ;
    
    # merge $inputFields and $templateFields
    my @tabularFields = (@{$inputFields}, @{$templateFields} ) ;
    
    if ( ( defined $bestHitOnly) and ($bestHitOnly eq 'FALSE') ) {
    	
    	# Add a new column to merge multi annotation if activate
    	@tabularFields = (@tabularFields, '_ANNOTATIONS_') ;
    	# merge All annotations in one string
    	$peakListRows = _mergeAnnotationsAsString($peakListRows, $peakList)  ;
    }
    
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

=item writePForestTabularWithPeakBankObject

	## Description : write PForest compatible Tabular output file From a Peak Bank Object
	## Input : $templateTabular, $tabular, $bestHitOnly
	## Output : $PForestSpectraPeakListInTabular
	## Usage : my ( $PForestSpectraPeakListInTabular ) = writePForestTabularWithPeakBankObject ( $inputTabularFile ) ;

=cut

## START of SUB
sub writePForestTabularWithPeakBankObject {
    ## Retrieve Values
    my $self = shift ;
    my ( $templateTabular, $tabular, $bestHitOnly ) = @_;
    
    ## Manage best hit only or all annotations
	my $peakList = undef ;
	
	if ( (!defined $bestHitOnly) or ( $bestHitOnly eq 'TRUE') ) {
		$peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_') ;
	}
	else {
		$peakList = $self->_getPeaksToAnnotated('_EXP_PEAK_LIST_ALL_ANNOTATIONS_') ;
	}
    
    ## Get template header
    my ( @fields, $templateFields ) = ( (), undef ) ;
    if (-e $templateTabular) {
    	
    	my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    		or die "Cannot use CSV: ".Text::CSV->error_diag ();
    	
    	open my $fh, "<", $templateTabular or die "$templateTabular: $!";
    	
		## Checking header of the source file   	
    	@fields = $csv->header ($fh) ;
    	$templateFields = \@fields ;
    }
    else {
		croak "Tabular template file is not defined or is not existing.\n" ;
	}
    
    ## Map PeakList feature names with internal output headers
    my ( $peakListRows ) = ( undef ) ;

    foreach my $peak (@{$peakList}) {
    	my %tmp = () ;
    	
    	foreach my $field (@fields ) {
    		
    		if ($field eq 'm/z') {
    			if (defined $peak->{_MESURED_MONOISOTOPIC_MASS_}) 	{	$tmp{'m/z'} = $peak->{_MESURED_MONOISOTOPIC_MASS_}  ; }
    		}
    		elsif  ($field eq 'theo_mass') {
    			if (defined $peak->{_COMPUTED_MONOISOTOPIC_MASS_}) 	{	$tmp{'theo_mass'} = $peak->{_COMPUTED_MONOISOTOPIC_MASS_}  ; }
    		}
    		elsif  ($field eq 'delta_ppm') {
    			if (defined $peak->{_PPM_ERROR_}) 	{	$tmp{'delta_ppm'} = $peak->{_PPM_ERROR_}  ; }
    		}
    		elsif  ($field eq 'absolute_intensity') {
    			if (defined $peak->{_INTENSITY_}) 	{	$tmp{'absolute_intensity'} = $peak->{_INTENSITY_}  ; }
    		}
    		elsif  ($field eq 'relative_intensity') {
    			if (defined $peak->{_RELATIVE_INTENSITY_100_}) 	{	$tmp{'relative_intensity'} = $peak->{_RELATIVE_INTENSITY_100_}  ; }
    		}
    		elsif  ($field eq 'attribution') {
    			if (defined $peak->{_ANNOTATION_IN_NEG_MODE_}) 	{	$tmp{'attribution'} = $peak->{_ANNOTATION_IN_NEG_MODE_}  ; }
    			elsif (defined $peak->{_ANNOTATION_IN_POS_MODE_}) 	{	$tmp{'attribution'} = $peak->{_ANNOTATION_IN_POS_MODE_}  ; }
    		}
    		
    		else 							{	$tmp{$field} = 'NA'  ; }
    	}
    	push (@{$peakListRows}, \%tmp) ;
    }
    
#    print Dumper $peakListRows ;
	
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
		croak "[ERROR] the tabular output file $tabular is not defined\n" ;
	}
}
### END of SUB



=back

=head1 PRIVATE METHODS

=head2 Metabolomics::Fragment::Annotation

=over 4

=item PRIVATE_ONLY _addAnnotatedPeakList

	## Description : _addAnnotatedPeakList
	## Input : $self, $type, $peakList ;
	## Ouput : NA;
	## Usage : _addAnnotatedPeakList($type, $peakList);

=cut

### START of SUB

sub _addAnnotatedPeakList {
    my ($self, $type, $peakList) = @_;
    
    ## type should be _EXP_PEAK_LIST_ALL_ANNOTATIONS_
	if ( (defined $type) and (defined $peakList) ) {
		push (@{$self->{$type}}, $peakList);
	}
	else{
		croak "type peaklist should be _EXP_PEAK_LIST_ALL_ANNOTATIONS_ \n" ;
	}
}
### END of SUB

=item PRIVATE_ONLY _getANNOTATION_PARAMS_DELTA

	## Description : _getANNOTATION_PARAMS_DELTA
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getANNOTATION_PARAMS_DELTA () ;

=cut

## START of SUB
sub _getANNOTATION_PARAMS_DELTA {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_PARAMS_DELTA_}) and ( $self->{_ANNOTATION_PARAMS_DELTA_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_PARAMS_DELTA_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getANNOTATION_PARAMS_DELTA getPeak an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_PARAMS_DELTA

	## Description : _setANNOTATION_PARAMS_DELTA
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setANNOTATION_PARAMS_DELTA ( $VALUE ) ;

=cut

## START of SUB
sub _setANNOTATION_PARAMS_DELTA {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_PARAMS_DELTA_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_PARAMS_DELTA_} = undef ;
    	warn "[WARN] the method _setANNOTATION_PARAMS_DELTA is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getANNOTATION_PARAMS_DELTA_TYPE

	## Description : _getANNOTATION_PARAMS_DELTA_TYPE
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getANNOTATION_PARAMS_DELTA_TYPE () ;

=cut

## START of SUB
sub _getANNOTATION_PARAMS_DELTA_TYPE {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_PARAMS_DELTA_TYPE_}) and ( $self->{_ANNOTATION_PARAMS_DELTA_TYPE_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_PARAMS_DELTA_TYPE_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getANNOTATION_PARAMS_DELTA_TYPE getPeak an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_PARAMS_DELTA_TYPE

	## Description : _setANNOTATION_PARAMS_DELTA_TYPE
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setANNOTATION_PARAMS_DELTA_TYPE ( $VALUE ) ;

=cut

## START of SUB
sub _setANNOTATION_PARAMS_DELTA_TYPE {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_PARAMS_DELTA_TYPE_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_PARAMS_DELTA_TYPE_} = undef ;
    	warn "[WARN] the method _setANNOTATION_PARAMS_DELTA_TYPE is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getANNOTATION_DB_SOURCE

	## Description : _getANNOTATION_DB_SOURCE
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getANNOTATION_DB_SOURCE () ;

=cut

## START of SUB
sub _getANNOTATION_DB_SOURCE {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_DB_SOURCE_}) and ( $self->{_ANNOTATION_DB_SOURCE_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_DB_SOURCE_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getANNOTATION_DB_SOURCE getPeak an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_DB_SOURCE

	## Description : _setANNOTATION_DB_SOURCE
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setANNOTATION_DB_SOURCE ( $VALUE ) ;

=cut

## START of SUB
sub _setANNOTATION_DB_SOURCE {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_DB_SOURCE_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_DB_SOURCE_} = undef ;
    	warn "[WARN] the method _setANNOTATION_DB_SOURCE is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

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
    elsif ( (defined $type) and ($type eq '_EXP_PEAK_LIST_ALL_ANNOTATIONS_') ) {
    	$peakList = $self->{_EXP_PEAK_LIST_ALL_ANNOTATIONS_} ;
    }
    elsif ( (defined $type) and ($type eq '_THEO_PEAK_LIST_') ) {
    	$peakList = $self->{_THEO_PEAK_LIST_} ;
    }
    elsif ( (defined $type) and ($type eq '_EXP_PSEUDOSPECTRA_LIST_') ) {
    	$peakList = $self->{_EXP_PSEUDOSPECTRA_LIST_} ;
    }
    elsif ( (defined $type) and ($type eq '_ANNOTATION_DB_SPECTRA_INDEX_') ) {
    	$peakList = $self->{_ANNOTATION_DB_SPECTRA_INDEX_} ;
    }
    else {
    	croak "[ERROR] No type is undefined or does not correspond to _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ or _EXP_PEAK_LIST_ALL_ANNOTATIONS_ or _EXP_PSEUDOSPECTRA_LIST_ \n" ;
    }
    
    return ($peakList) ;
}
### END of SUB

=item PRIVATE_ONLY _setSpectraHtmlTboby

	## Description : set Html body object (spectra) for output creation from the Annotation analysis object
	## Input : 
	## Output : oHtmlTbody
	## Usage : my ( oHtmlTbody ) = _setSpectraHtmlTboby () ;

=cut
sub _setSpectraHtmlTboby {
	## Retrieve Values
	my $self = shift ;
	my ($PSEUDOSPECTRALIST, $SCORES) = @_ ;
	
	my $SPECTRA = undef ;
	my $CLUSTERS = undef ;
	
	foreach my $pcId (sort keys %{$PSEUDOSPECTRALIST}) {
		
		##  - - - - - TABLE PART - - - - - - 
    	
    	my %Synthesis = () ;
    	    	
    	$Synthesis{'PCGROUP_ID'} = $pcId ;
    	$Synthesis{'ANNOT_COLUMNS'} = []  if ( ! $Synthesis{'ANNOT_COLUMNS'} );
    	
    	if  ( ( scalar (@{$PSEUDOSPECTRALIST->{$pcId}}) == 0 ) ) {
    		my %tmp = ( BTID1 => 'N/A', SPECTRA_ID => 'N/A', INSTRUMENT => 'N/A', CPD_ID => 'N/A', CPD_NAME => 'N/A', DERIVATIVE_TYPE => 'N/A', SCORES => '0 / 0 / 0'  ) ;
			push (@{$Synthesis{'ANNOT_COLUMNS'} }, \%tmp ) ;
#			PCGROUP_N_SPECTRA => 'N/A'
			my %tmp2 = (BTID2 => 'N/A', PSEUDOSPECTRA_N_SPECTRA => undef, THEO_N_SPECTRA => undef, PSEUDOSPECTRA_CHART_TITLE => undef, ) ;
			push ( @{$SPECTRA}, \%tmp2 ) ;
			
    	}
    	elsif ( ( scalar (@{$PSEUDOSPECTRALIST->{$pcId}}) > 0 ) ) {
    		
    		## Get matched Spectra Ids
    		my %uniqSpIds = () ;
    		
    		foreach my $expPeak (@{$PSEUDOSPECTRALIST->{$pcId}}) {
    			
    			## Get All matched Peaks (to keep their Id)
    			my $matchedPeaks = $expPeak->_getPeak_ANNOTATIONS() ;
#    			print Dumper $matchedPeaks ;
    			
    			foreach my $annotedPeak (@{ $matchedPeaks }) {
    				
    				if ( ( $annotedPeak->_getPeakFilterPass() ) and ( $annotedPeak->_getPeakFilterPass() eq 'FALSE' ) ) {
#    					print "Remove peaks badly annotated where score does not reach given threshold\n" ;
    					next ;
    				}
    				else {
    					my $ids = $annotedPeak->_getPeak_ANNOTATION_SPECTRAL_IDS() ;
	#    				print Dumper $ids ;
	    				foreach (@{$ids}) {
	    					$uniqSpIds{$_} = 1 ;
	    				}
    				}
    			}
    		} ## END FOREACH
    		
    		## Foreach matched spectra - Get their properties into 
    		my @spectraIDs = keys %uniqSpIds ;
#    		print Dumper @spectraIDs ;
#    		exit(0) ;

			if (scalar @spectraIDs == 0 ) {
				my %tmp = ( BTID1 => 'N/A', SPECTRA_ID => 'N/A', INSTRUMENT => 'N/A', CPD_ID => 'N/A', CPD_NAME => 'N/A', DERIVATIVE_TYPE => 'N/A', SCORES => '0 / 0 / 0'  ) ;
				push (@{$Synthesis{'ANNOT_COLUMNS'} }, \%tmp ) ;
				my %tmp2 = (BTID2 => 'N/A', PSEUDOSPECTRA_N_SPECTRA => undef, THEO_N_SPECTRA => undef, PSEUDOSPECTRA_CHART_TITLE => undef, ) ;
				push ( @{$SPECTRA}, \%tmp2 ) ;
			}
			elsif (scalar @spectraIDs > 0 ) {

	    		foreach my $spectraID (@spectraIDs) {
	    			## 'Urea; GC-EI-QTOF; MS; 2 TMS; '
	    			
	#    			print Dumper $self->{_ANNOTATION_DB_SPECTRA_INDEX_}{$spectraID} ;
	    			
	    			# Cpd part
	    			my ($cpdName, $instr, $derivType, $cpdId, $score) = (undef, undef, undef, undef) ;
	    			
	    			if ($self->{_ANNOTATION_DB_SPECTRA_INDEX_}{$spectraID}{_SPECTRUM_NAME_} =~/(.*)\;\s(.*)\;\s(.*)\;\s(.*)\;/) {
	    				$cpdName = $1 ;
	    				$instr = $2 ;
	    				$derivType = $4 ;
	    			}
	    			
	#    			my $score = join (' / ', @{ $pcResults->{$pcId}{'COMPOUNDS'}{$cpdId}{SCORES} } );
	#				print Dumper $SCORES ;
#					print "$pcId -- $spectraID\n" ;
					$score = $SCORES->{$pcId}{$spectraID}{_SCORE_Q_}.' / '.$SCORES->{$pcId}{$spectraID}{_SCORE_LIB_}.' / '.$SCORES->{$pcId}{$spectraID}{_SCORE_PEARSON_CORR_} ;
#					print Dumper $SCORES ;
					
					if ( $self->{_ANNOTATION_DB_SPECTRA_INDEX_}{$spectraID}{_SYNONYMS_} eq 'single compound') {
						$cpdId = $self->{_ANNOTATION_DB_SPECTRA_INDEX_}{$spectraID}{_COMPOUNDS_}[0] ;
					}
	    			
	    			# Spectra part
	    			my %tmp = ( BTID1 => $pcId.'_'.$spectraID, SPECTRA_ID => $spectraID, INSTRUMENT => $instr, CPD_ID => $cpdId, CPD_NAME => $cpdName, DERIVATIVE_TYPE => $derivType, SCORES => $score  ) ;
					push (@{$Synthesis{'ANNOT_COLUMNS'} }, \%tmp ) ;
					
					
					## - - - - - - SPECTRA PART - - - - - - -
					my %spectraSynth = () ;
					
					$spectraSynth{'BTID2'} = $pcId.'_'.$spectraID ;
	    			$spectraSynth{'PSEUDOSPECTRA_N_SPECTRA'} = undef ;
	    			
	    			$spectraSynth{'PSEUDOSPECTRA_CHART_TITLE'} = 'Spectrum '.$spectraID ;
					
					my $fragNum = 1 ;
					my $THEO_SPECTRUM = undef ;
					
					foreach my $record (@{ $self->{_ANNOTATION_DB_SPECTRA_INDEX_}{$spectraID}{_PEAKS_} }) {
						
						my $X = $record->{'mz'} ;
						my $Y = $record->{'ri'} ;
						
	#					print "$record->[0] / $X - - $record->[1] / $Y " ;
						
						$THEO_SPECTRUM .= "{ yAxis: 0, name: '**frag_".$fragNum."**', color: '#FF0000', data: [[".$X.", 0], [".$X.", ".-$Y."]]}, " ;
						$fragNum ++ ; 
					}
					$spectraSynth{'THEO_N_SPECTRA'} = $THEO_SPECTRUM ;
					
					## Exp part
					my $pcFragNum = 1 ;
					my $pcRelIntNum = 0 ;
					my $EXP_SPECTRUM = undef ;
					
					foreach my $oPeak ( @{$PSEUDOSPECTRALIST->{$pcId}} ) {
						
						my $X = $oPeak->_getPeak_MESURED_MONOISOTOPIC_MASS() ;
						my $Y = $oPeak->_getPeak_RELATIVE_INTENSITY_100() ;
						
	#					print "$record->[0] / $X - - $record->[1] / $Y " ;
						
						$EXP_SPECTRUM .= "{ yAxis: 0, name: '**frag_".$pcFragNum."**', color: '#0000FF', data: [[".$X.", 0], [".$X.", ".$Y."]]}, " ;
						$pcFragNum ++ ;
						$pcRelIntNum ++ ;
					}
					$spectraSynth{'PSEUDOSPECTRA_N_SPECTRA'} = $EXP_SPECTRUM ;
					
					push ( @{$SPECTRA}, \%spectraSynth ) ;
	    			
	    		} ## END FOREACH $spectraID
			} ## END ELSIF ANNOTATIONS > 0
    	} ## END ELSIF A MATCHING EXISTS
    	push (@{$CLUSTERS}, \%Synthesis) ;
	}## END FOREACH pseudoSp.
	
	return ($CLUSTERS, $SPECTRA) ;
}

=item PRIVATE_ONLY _setPeakHtmlTbody

	## Description : set Html body object for ouput creation from the Annotation analysis object
	## Input : 
	## Output : oHtmlTbody
	## Usage : my ( oHtmlTbody ) = _setPeakHtmlTbody () ;

=cut
sub _setPeakHtmlTbody {
	## Retrieve Values
	my $self = shift ;
	my ( $PEAKSLIST ) = @_ ;
	
	## Determine tbody to use at the entry level (FRAGMENT VS METABOLITE)
	my $TBODY_TYPE = $self->{_ANNOTATION_DB_SOURCE_TYPE_} ;
	
	my $HTML_ENTRIES_PER_PAGE = 10 ; ## DEFAULT 
	$HTML_ENTRIES_PER_PAGE = 50 if $TBODY_TYPE eq 'FRAGMENT' ; ## Change depending of annotation type (fragment vs metabolite)
	
	## initializes and build the tbody object (perl array) needed to html template
	my ( @tbody_object ) = ( ) ;
	
	my $PAGES_NB = undef ;
	$PAGES_NB = ceil( scalar(@{$PEAKSLIST} ) / $HTML_ENTRIES_PER_PAGE )  ; #NB total masses / HTML_ENTRIES_PER_PAGE
	
	
	my $POLARITY = $self->{_ANNOTATION_ION_MODE_} ;
	
	my $FRAG_NAME_TAG = undef ;
	if ($POLARITY eq 'POSITIVE') {
		$FRAG_NAME_TAG = '_ANNOTATION_IN_POS_MODE_' ;
	}
	elsif ($POLARITY eq 'NEGATIVE') {
		$FRAG_NAME_TAG = '_ANNOTATION_IN_NEG_MODE_' ;
	}
	else {
		warn "\t[WARN] Polarity is not defined or type is not recognize ($POLARITY)\n" ;
	}
	
	
	for ( my $i = 1 ; $i <= $PAGES_NB ; $i++ ) {
	    
	    my %pages = ( 
	    	# tbody feature
	    	PAGE_NB => $i,
	    	MASSES => [], ## end MASSES
	    ) ; ## end TBODY N
	    push (@tbody_object, \%pages) ;
	}
	
	## initializes and build the MZ object part (perl array) needed to html template
	my ( $current_page, $mz_index ) = ( 0, 0 ) ;
	
	foreach my $page ( @tbody_object ) {
		
		my @colors = ('white', 'green') ;
		my ( $current_index, , $icolor ) = ( 0, 0 ) ;
		
		for ( my $i = 1 ; $i <= $HTML_ENTRIES_PER_PAGE ; $i++ ) {
			# 
			if ( $current_index > $HTML_ENTRIES_PER_PAGE ) { ## manage exact mz per html page 
				$current_index = 0 ; 
				last ; ##
			}
			else {
				$current_index++ ;
				if ( $icolor > 1 ) { $icolor = 0 ; }
				
				if ( exists $PEAKSLIST->[$mz_index]  ) {
					
					my %mz = (
						# mass feature
						MASSES_ID_QUERY => $PEAKSLIST->[$mz_index]{'_ID_'},
						MASSES_MZ_QUERY => $PEAKSLIST->[$mz_index]{'_MESURED_MONOISOTOPIC_MASS_'},
						MZ_COLOR => $colors[$icolor],
						MASSES_NB => $mz_index+1,
						ENTRIES => [] ,
					) ;
					push ( @{ $tbody_object[$current_page]{MASSES} }, \%mz ) ;
					# Html attr for mass
					$icolor++ ;
				}
			}
			$mz_index++ ;
		} ## foreach mz

		$current_page++ ;
	}
	
	## initializes and build the entries object (perl array) needed to html template
    my $index_page = 0 ;
    my $index_mz_continous = 0 ;
    
    foreach my $page (@tbody_object) {
    	
    	my $index_mz = 0 ;
    	
    	foreach my $mz (@{ $tbody_object[$index_page]{MASSES} }) {
    		
    		my $index_entry = 0 ;
    		
    		my @anti_redondant = ('N/A') ;
    		my $check_rebond = 0 ;
    		my $check_noentry = 0 ;
    		
    		my $ANNOTATIONS = $PEAKSLIST->[$index_mz_continous]{_ANNOTATIONS_} ;
    		 
    		
    		foreach my $annotation (@{ $ANNOTATIONS }) {
    			$check_noentry ++ ;
    			## dispo anti doublons des entries
#    			foreach my $rebond (@anti_redondant) {
#    				if ( $rebond eq $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID} ) {	$check_rebond = 1 ; last ; }
#    			}
    			
    			if ( $check_rebond == 0 ) {
    				
#    				 push ( @anti_redondant, $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID} ) ;
					my %entry = () ;

					if ( (defined $TBODY_TYPE) and ($TBODY_TYPE eq 'FRAGMENT') ) {
						%entry = (
			    			ENTRY_COLOR => $tbody_object[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
			    			ENTRY_FRAG_NAME => $annotation->{$FRAG_NAME_TAG},
			    			ENTRY_FRAG_MZ => $annotation->{_MESURED_MONOISOTOPIC_MASS_},
			    			ENTRY_DELTA_PPM => $annotation->{_PPM_ERROR_},
			    			ENTRY_DELTA_MMU => $annotation->{_MMU_ERROR_},
			    			ENTRY_FRAG_DELTA_MZ => undef,
			    			ENTRY_FRAG_TYPE => $annotation->{_ANNOTATION_TYPE_},
			    			ENTRY_FRAG_ID_URL => $annotation->{_ID_}, 
			   				ENTRY_FRAG_ID => $annotation->{_ID_},
			    		) ;
					}
					
					elsif ( (defined $TBODY_TYPE) and ($TBODY_TYPE eq 'METABOLITE') ) {
						%entry = (
			    			ENTRY_COLOR => $tbody_object[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
			    			ENTRY_MET_NAME => $annotation->{_ANNOTATION_NAME_},
			    			ENTRY_MET_MZ => $annotation->{_COMPUTED_MONOISOTOPIC_MASS_},
			    			ENTRY_DELTA_PPM => $annotation->{_PPM_ERROR_},
			    			ENTRY_DELTA_MMU => $annotation->{_MMU_ERROR_},
			    			ENTRY_FRAG_NAME => $annotation->{$FRAG_NAME_TAG},
			    			ENTRY_FRAG_TYPE => $annotation->{_ANNOTATION_TYPE_},
			    			ENTRY_MET_FORMULA => $annotation->{_ANNOTATION_FORMULA_},
			    			ENTRY_MET_INCHIKEY => $annotation->{_ANNOTATION_INCHIKEY_}, 		
							ENTRY_MET_ID_URL => $self->{_ANNOTATION_DB_SOURCE_URL_CARD_}.$annotation->{_ID_}, 
			   				ENTRY_MET_ID => $annotation->{_ID_},
		    		) ;
						
					}
					else {
						croak "[ERROR] Your source is not a METABOLITE OR FRAGMENT type. Please check object feature _ANNOTATION_DB_SOURCE_TYPE_\n ;"
					}

	    			push ( @{ $tbody_object[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
    			}
#    			$check_rebond = 0 ; ## reinit double control
    			$index_entry++ ;	
    		} ## end foreach
    		if ($check_noentry == 0 ) {
    			
    			my %entry = () ;

				if ( (defined $TBODY_TYPE) and ($TBODY_TYPE eq 'FRAGMENT') ) {
					%entry = (
		    			ENTRY_COLOR => $tbody_object[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
		    			ENTRY_FRAG_NAME  => 'UNKNOWN',
						ENTRY_FRAG_MZ => 'n/a',
						ENTRY_DELTA_PPM => 0,
						ENTRY_DELTA_MMU => 0,
						ENTRY_FRAG_DELTA_MZ => 'n/a',
						ENTRY_FRAG_TYPE => 'n/a',
						ENTRY_FRAG_ID => 'NONE',
		   				ENTRY_FRAG_ID_URL => '',
		    		) ;
				}
				
				elsif ( (defined $TBODY_TYPE) and ($TBODY_TYPE eq 'METABOLITE') ) {
					%entry = (
		    			ENTRY_COLOR => $tbody_object[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
		    			ENTRY_MET_NAME => 'UNKNOWN',
		    			ENTRY_MET_MZ => 'n/a',
		    			ENTRY_DELTA_PPM => 0,
		    			ENTRY_DELTA_MMU => 0,
		    			ENTRY_FRAG_NAME => 'n/a',
		    			ENTRY_FRAG_TYPE => 'n/a',
		    			ENTRY_MET_FORMULA => 'n/a',
		    			ENTRY_MET_INCHIKEY => 'n/a', 		
						ENTRY_MET_ID_URL => '',
		   				ENTRY_MET_ID => 'NONE',
	    		) ;
					
				}
				else {
					croak "[ERROR] Your source is not a METABOLITE OR FRAGMENT type. Please check object feature _ANNOTATION_DB_SOURCE_TYPE_\n ;"
				}
   
	    		push ( @{ $tbody_object[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
    		}
    		$index_mz ++ ;
    		$index_mz_continous ++ ;
    	}
    	$index_page++ ;
    }
	
	
	return ($PAGES_NB, \@tbody_object) ;
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

=item PRIVATE_ONLY _mergeAnnotationsAsString

	## Description : Merge all annotations in a single string (annotation separated by '|') by annotated peak.
	## Input : $rows, $peakList
	## Output : $newRows
	## Usage : my ( $newRows ) = _mergeAnnotationsAsString ( $rows, $peakList ) ;

=cut

## START of SUB
sub _mergeAnnotationsAsString {
    ## Retrieve Values
    my ( $rows, $peakList ) = @_;
    
    my ( @newRows ) = ( () ) ;
    my $i = 0 ;
#    print Dumper $rows ;
#    print Dumper $peakList ;
    
    foreach my $row (@{$rows}) {
    	
    	if ($peakList->[$i]) {
    		
    		my $peakListSize = scalar ( @{$peakList->[$i]{'_ANNOTATIONS_'}} ) ;
    		
    		if ( $peakListSize > 0 ) {
    			my $annotationString = undef ;
    			
    			my $j = 1 ;

    			foreach my $annotation (@{ $peakList->[$i]{'_ANNOTATIONS_'} }) {
    				
    				if ($peakListSize > $j ) {
    					$annotationString .= $annotation->{_MMU_ERROR_}." ".$annotation->{_COMPUTED_MONOISOTOPIC_MASS_}." ".$annotation->{_ANNOTATION_NAME_}." | " ;
    				}
    				elsif ($peakListSize == $j) {
    					$annotationString .= $annotation->{_MMU_ERROR_}." ".$annotation->{_COMPUTED_MONOISOTOPIC_MASS_}." ".$annotation->{_ANNOTATION_NAME_} ;
    				}
    				$j ++ ;
    			}
    			$row->{'_ANNOTATIONS_'} = $annotationString ;
    		}
    		else {
    			$row->{'_ANNOTATIONS_'} = 'NA' ;
    		}
    		
    	}
    	else {
    		warn "[WARN] row array size seems different than the peaklist array one\n" ;
    		$row->{'_ANNOTATIONS_'} = 'NA' ;
    	}
    	
    	
    	push (@newRows, $row) ;
    	$i ++ ;
    }
#	print Dumper @newRows ;
	return (\@newRows) ;
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
	elsif 	($$delta_type eq 'MMU')		{	$computedDeltaMz = $$mz_delta ; }
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

	## Description : compute a delta (PPM) between exp. mz and calc. mz - Delta m/Monoisotopic calculated exact mass * 100 
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

All information about FragNot should be find here: https://services.pfem.clermont.inrae.fr/gitlab/fgiacomoni/metabolomics-fragment-annotation

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
