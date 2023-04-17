package Metabolomics::Banks::PeakForest ;

use 5.006;
use strict;
use warnings;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../..";  # use the parent directory

use Exporter qw(import);

use LWP::Simple ;
use LWP::UserAgent ;
use Encode ;
use JSON ;
use Data::Dumper ;
use Carp qw (cluck croak carp) ;

use base qw( Metabolomics::Banks ) ;

## To load the API packages:
use PeakForest::REST_Client::ChromatographyApi;
use PeakForest::REST_Client::CompoundsApi;
use PeakForest::REST_Client::InformationsApi;
use PeakForest::REST_Client::SpectraApi;

## load the models
use PeakForest::REST_Client::Object::Chromatography;
use PeakForest::REST_Client::Object::Compound;
use PeakForest::REST_Client::Object::FragmentationLcmsSpectrum;
use PeakForest::REST_Client::Object::FullscanGcmsSpectrum;
use PeakForest::REST_Client::Object::FullscanGcmsSpectrumAllOf;
use PeakForest::REST_Client::Object::FullscanLcmsSpectrum;
use PeakForest::REST_Client::Object::GasChromatography;
use PeakForest::REST_Client::Object::GasChromatographyAllOf;
use PeakForest::REST_Client::Object::Informations;
use PeakForest::REST_Client::Object::LiquidChromatography;
use PeakForest::REST_Client::Object::LiquidChromatographyAllOf;
use PeakForest::REST_Client::Object::MassPeak;
use PeakForest::REST_Client::Object::MassSpectrum;
use PeakForest::REST_Client::Object::MassSpectrumAllOf;
use PeakForest::REST_Client::Object::Nmr1dPeak;
use PeakForest::REST_Client::Object::Nmr1dPeakpattern;
use PeakForest::REST_Client::Object::Nmr1dSpectrum;
use PeakForest::REST_Client::Object::Nmr1dSpectrumAllOf;
use PeakForest::REST_Client::Object::Nmr2dPeak;
use PeakForest::REST_Client::Object::Nmr2dSpectrum;
use PeakForest::REST_Client::Object::Nmr2dSpectrumAllOf;
use PeakForest::REST_Client::Object::NmrSpectrum;
use PeakForest::REST_Client::Object::NmrSpectrumAllOf;
use PeakForest::REST_Client::Object::Spectrum;

require Exporter;
 
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Banks::PeakForest ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	initPeakForestQuery getCleanRangeSpectraFromSource buildTheoPeakBankFromPeakForest buildSpectralBankFromPeakForest
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	initPeakForestQuery getCleanRangeSpectraFromSource buildTheoPeakBankFromPeakForest buildSpectralBankFromPeakForest
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks::PeakForest - Perl extension for PeakForest bank 

=head1 VERSION

Version 0.2 - supporting/integrating REST API V2 methods
Version 0.3 - Completing object properties + GCMS bank generation
Version 0.4 - Integration of deltaType

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

    use Metabolomics::Banks::PeakForest;

=head1 DESCRIPTION

	Metabolomics::Banks::PeakForest is a full package for Perl allowing to build a generic Perl bank object from PeakForest bank resource.

=head1 EXPORT

	use Metabolomics::Banks::PeakForest qw( :all ) ;

=head1 PUBLIC METHODS 

=head2 Metabolomics::Banks::PeakForest

=over 4

=item new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my ($class,$args) = @_;
    my $self={};
    
    $self = Metabolomics::Banks->new() ;
    
    $self->{_DATABASE_NAME_} = 'PeakForest' ;
    $self->{_DATABASE_VERSION_} = '2.3.2' ;
    $self->{_DATABASE_ENTRIES_NB_} = undef ;
    $self->{_DATABASE_URL_} = 		$args->{DATABASE_URL} ; # REST API
    $self->{_DATABASE_TOKEN_} = 	$args->{TOKEN} ; # REST API TOKEN
    $self->{_RESOLUTION_} = 		$args->{RESOLUTION} ;
    $self->{_POLARITY_} = 			$args->{POLARITY} ;
    
    $self->{_DATABASE_DOI_} = 'NA' ;
    $self->{_DATABASE_TYPE_} = 'METABOLITE' ;
    
    $self->{_DATABASE_SPECTRA_} = undef ;
    
    if (!defined $args->{DATABASE_URL}) {
    	$self->{_DATABASE_URL_} = 'https://metabohub.peakforest.org/rest/v2' ;
    	
    }
    if (!defined $args->{DATABASE_URL_CARD}) {
    	$self->{_DATABASE_URL_CARD_} = 'https://metabohub.peakforest.org/webapp/home?PFc=' ;	
    }
    
    
    ## _DATABASE_ENTRIES_
    bless($self) ;
    return $self ;
}
### END of SUB

=item PRIVATE_ONLY __refpeakforestcompound__

	## Description : PRIVATE method __refpeakforestcompound__ object
	## Input : void
	## Output : __refpeakforestcompound__
	## Usage : $self->__refpeakforestcompound__ ;

=cut

## START of SUB
sub __refpeakforestcompound__ {
	## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_NAME_} = $args->{'name'} ; # 
    $self->{_SYNONYMS_} = $args->{'synonyms'} ; #ARRAY 
	$self->{_ID_} = $args->{'id'} ;
	$self->{_INCHIKEY_} = $args->{'inchikey'} ;
	$self->{_IUPAC_} = $args->{'iupac'} ;
    $self->{_EXACT_MASS_} = $args->{'exact_mass'} ;
    $self->{_BIOACTIVE_} = $args->{'bioactive'} ; # 
    $self->{_AVERAGE_MASS_} = $args->{'average_mass'} ; # 
	$self->{_LOG_P_} = $args->{'log_p'} ;
	$self->{_INCHI_} = $args->{'inchi'} ;
	$self->{_CAN_SMILES_} = $args->{'can_smiles'} ;
    $self->{_FORMULA_} = $args->{'formula'} ;
    $self->{_SPECTRA_} = $args->{'spectra'} ; #ARRAY
    
	return $self ;
}
### END of SUB

=item PRIVATE_ONLY __refpeakforestspectra__

	## Description : PRIVATE method __refpeakforestspectra__ object
	## Input : void
	## Output : __refpeakforestspectra__
	## Usage : $self->__refpeakforestspectra__ ;

=cut

## START of SUB
sub __refpeakforestspectra__ {
	## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_SPECTRUM_TYPE_} = $args->{'spectrumType'} ; # 
    $self->{_ID_} = $args->{'id'} ; # 
    $self->{_SPECTRUM_NAME_} = $args->{'name'} ; # 
    $self->{_SYNONYMS_} = $args->{'sampleType'} ; # 
    $self->{_COMPOUNDS_} = $args->{'compounds'} ; # ARRAY ["PFc000341"],
    $self->{_ANALYSER_TYPE_} = $args->{'analyzerType'} ; # 
    $self->{_POLARITY_} = $args->{'polarity'} ; # 
    $self->{_RESOLUTION_} = $args->{'resolution'} ; # 
    $self->{_MANUFACTURER_BRAND_} = $args->{'manufacturerBrand'} ; # 
    $self->{_IONISATION_METHOD_} = $args->{'ionisationMethod'} ; # 
    $self->{_PEAKS_} = $args->{'peaks'} ; #ARRAY [{"mz":52.0063,"ri":1.39},...]
    $self->{_CREATED_} = $args->{'created'} ; # "2021-08-10T12:41:36Z"
    
	return $self ;
}
### END of SUB


##### * * * *  REST API V02 - available since 2020 * * * * 



=item buildSpectralBankFromPeakForest

	## Description : build a spectra bank from PeakForest matching REST API
	## Input : 
	## Output : $oBank
	## Usage : $oBank->buildSpectralBankFromPeakForest ( ) ;

=cut

## START of SUB
sub buildSpectralBankFromPeakForest {
    ## Retrieve Values
    my $self = shift ;
    my ( $COLUMN_CODE, $DELTATYPE, $DELTA, $MIN_FRAGMENTS ) = @_;
    
    my $nbMatchedSpectra = 0 ;
    my %MatchedCpds = () ;
    my %MatchedSpectralIds = () ;
    
    ## get pseudospectra list
    my $pseudospectra = $self->_getPeakList('_EXP_PSEUDOSPECTRA_LIST_') ;
    
#    print Dumper $pseudospectra ;
    
    foreach my $group_id (sort keys %{$pseudospectra}) {
    	
    	print "\tMatching PCGROUP $group_id and PeakForest Spectra (by REST API)\n " ;
    	
    	my @mzs_res = () ;
    	my @ints_res = () ;
    	
    	foreach (@{ $pseudospectra->{$group_id} } ) {
    		push( @mzs_res, $_->_getPeak_MESURED_MONOISOTOPIC_MASS ) ;
    		push( @ints_res, $_->_getPeak_INTENSITY ) ;
    	}
    	
    	# Compute relative int
    	# Sort by value (max -> min)
    	for (my $i=0 ; $i<@ints_res ; $i++) {
			my @sorted_indices = sort { $ints_res[$b] <=> $ints_res[$a] } 0..$#ints_res;
			@$_ = @{$_}[@sorted_indices] for \(@mzs_res, @ints_res);
		}
		
#    	my @relative_ints = map { ($_ * 100)/$ints_res[0] } @ints_res ;
    	my @relative_ints = map { sprintf("%.2f",( ( $_ * 100) / $ints_res[0] ) ) } @ints_res ;
    	
    	## Add Rel. Intensity property into each oExpPeak
    	my $expPeaks = $self->_getPeakList('_EXP_PEAK_LIST_') ;
    	
		foreach my $entry (@{ $pseudospectra->{$group_id} } ) {
			
			## browse entire exp peak list to annotate it with spectra ids and rel. int.
			foreach my $expPeak (@{$expPeaks}) {
				
	    		if ( $expPeak->_getPeak_MESURED_MONOISOTOPIC_MASS() == $entry->_getPeak_MESURED_MONOISOTOPIC_MASS()  ) {
			    	my $i = 0 ;
			    	foreach my $mz (@mzs_res) {
			    		if ($expPeak->_getPeak_MESURED_MONOISOTOPIC_MASS() == $mz ) {
			    			if ($expPeak->_getPeak_INTENSITY() == $ints_res[$i] ) {
			    				if ($relative_ints[$i]) {
			    					$expPeak->_setPeak_RELATIVE_INTENSITY_100($relative_ints[$i]) ;
			    					last ;
			    				}
			    				else {
			    					warn "Relative intensity is not defined, please refer to your input file\n";
			    				}
			    			}
			    		}
			    		$i++ ;
			    	} ## END FOREACH mz
	    		}
	    	} ## End foreach $expPeak From EXP_PEAK_LIST 
		} # END foreach exp peak by Cluster
		
		## MIN_FRAG parameters - Runn a query ONLY if Cluster size is > MIN_FRAG
		my $list_ids = [] ;
		my $nbIds = 0 ;
		my @uniqueIds = () ;
		
		## Default
		if (!defined $MIN_FRAGMENTS) {
			$MIN_FRAGMENTS = 10 ;
		}
		
		## Block query with PPM value...
		if ( (defined $DELTATYPE)  and ($DELTATYPE ne 'MMU') ) {
			croak "Method buildSpectralBankFromPeakForest supports only mz delta in MMU" ;
		}
		
		my $clusterSize = scalar @mzs_res ;
		
		if ($clusterSize >= $MIN_FRAGMENTS ) {
			$list_ids = $self->_getGcmsSpectraByMatchingPeaks( $COLUMN_CODE, \@mzs_res, $DELTA) ; #colonne_code, mzs, delta in MMU
			$nbIds = scalar @{$list_ids} ;
			$nbMatchedSpectra += $nbIds ;
			
			## Index Spectra to avoid unusefull REST query and
			foreach (@{$list_ids}) {
	    		## Create INDEX between pseudo-spectra (cluster or pcgroup) (ID) and matched spectra (ID)
			    $self->_indexSpectraByCluster($group_id, $_ ) ;
	    		if (!$MatchedSpectralIds{$_}) {
	    			$MatchedSpectralIds{$_} = 1 ;
	    			push (@uniqueIds, $_) ;
	    		}
	    	}
		}
		else {
			print "\t[WARN] Cluster $group_id (size: $clusterSize) does not raise minimum cluster size set (10)\n" ;
		}
    	
    	## Query returns Spectra results!
    	if ( $nbIds > 0 ) {
    		
    		## Get Spectra from PeakForest REST API
	    	my ($oSpectra, $nbSpectra) = $self->_getGcmsSpectraFromIds(\@uniqueIds) ;
	    	
	    	foreach my $spectrum ( @{$oSpectra} ) {
	    		
	    		my $spectrumId = $spectrum->_getSpectra_ID() ;
	    		
	    		## Detect if the current spectrum is already indexed and present in theo peak list
	    		if ( $self->_detectSpectraDuplicate($spectrumId) eq 'FALSE' ) {
	    			
	    			## Create _ANNOTATION_DB_SPECTRA_INDEX_ - Add spectra ids as annotation
		    		$self->_addSpectra($spectrum, $spectrumId );
		    		
		    		## Create theo-Peak-list from spectra
		    		my $spectralPeaks = $spectrum->_getSpectra_PEAKS() ;
		    		
		    		foreach my $peak (@{$spectralPeaks}) {
		    			
		    			my $oPeak = $self->__refPeak__ ;
		    			
		    			my @cpds = @{ $spectrum->_getSpectra_COMPOUNDS() } ;
		    			$oPeak->_setPeak_ANNOTATION_ID( $cpds[0] ) ;
		    			$oPeak->_setPeak_ANNOTATION_SPECTRA_ID( $spectrumId ) ;
		    			$oPeak->_setPeak_MESURED_MONOISOTOPIC_MASS( $peak->{'mz'} ) if $peak->{'mz'} ;
		    			$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS( $peak->{'mz'} ) if $peak->{'mz'} ; ## NOT great but that the best for GCMS (No computed mz)
		    			$oPeak->_setPeak_RELATIVE_INTENSITY_100($peak->{'ri'}) if $peak->{'ri'} ;
		    			$oPeak->_setPeak_INTENSITY($peak->{'int'}) if $peak->{'int'} ; ## TO IMPROVE with GCMS data...
		    			
		    			## Fill Compound informations from PeakForest API - support only single compound in v1.0
		    			my $oCompound = undef ;
		    			
		    			if ( $MatchedCpds{ $cpds[0] } ) {
		    				$oCompound = $MatchedCpds{ $cpds[0] } ;
		    			}
		    			else {
		    				$oCompound = $self->_getCompoundFromId($cpds[0]) ;
		    				$MatchedCpds{ $cpds[0] } = $oCompound ;
		    			}
						
						$oPeak->_setPeak_ANNOTATION_TYPE('fragment') ;
						$oPeak->_setPeak_ANNOTATION_NAME($oCompound->_getCpd_NAME() ) ;
						$oPeak->_setPeak_ANNOTATION_FORMULA($oCompound->_getCpd_FORMULA() ) ;
						$oPeak->_setPeak_ANNOTATION_INCHIKEY($oCompound->_getCpd_INCHIKEY() ) ;
						$oPeak->_setPeak_ANNOTATION_SMILES($oCompound->_getCpd_CAN_SMILES() ) ;
						
		    			$self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
		    		}
	    		} ## END IF Duplicate IS FALSE
	    		else {
	    			warn "\t[WARN] Spectrum $spectrumId is already indexed (and peaks too) in banks object\n" ;
	    		}
	    	} ## END FOREACH spectrum 
		} ## END for IF get results from PeakForest
    } # END foreach group
    
#    print Dumper %MatchedSpectralIds ;
    
    return ($nbMatchedSpectra) ;
    
}
### END of SUB


=item _getCompoundFromId

	## Description : get a peakforest compound by Id, based on REST API V2
	## Input : $cpdId
	## Output : $oCpd
	## Usage : my ( $oCpd ) = $self->_getCompoundFromId ($cpdId) ;

=cut

## START of SUB
sub _getCompoundFromId {
    ## Retrieve Values
    my $self = shift ;
    my ( $cpdId ) = @_;
    
    
    my $compound = undef ;
    
    my $api_client = PeakForest::REST_Client::CompoundsApi->new( api_key => {'token' => $self->{_DATABASE_TOKEN_} }, 'base_url' => $self->{_DATABASE_URL_} ) ;
    
    if ( ( defined $cpdId ) and $cpdId !~ /PFc/ ) {
    	print "\tPeakForest compound id is reformatted ($cpdId) for query...\n" ;
    	$cpdId = 'PFc'.sprintf("%06d",$cpdId) ;
    	
#    	print Dumper $compound ;
    }
    elsif ( ( defined $cpdId ) and $cpdId =~ /PFc(\d+)/ ) {
    	print "\tPeakForest compound id is well formatted ($cpdId) for query...\n" ;
    }
    else {
    	croak "[PeakForest-REST-Client] Object is not well formatted - Please check that the query argt value matching with \'PFc000001\' format for example\n" ;
    }
    
    eval {
    	## REST query and REST object -- peakforest::__refpeakforestcompound__ object mapping
      	my $oCpd = $api_client->get_compound( id => $cpdId  ) ;
      	$compound = $self->__refpeakforestcompound__($oCpd) ;
      	
    } ;
    
    if ($@) {
	    warn "Exception when calling CompoundsApi->get_compounds: $@\n";
	}
	
    return ($compound) ;
}
### END of SUB

=item _getGcmsSpectraFromIds

	## Description : match a GC-MS spectra from a list of peaks, based on REST API V2
	## Input : $cpdId
	## Output : $oSpectra
	## Usage : my ( $oSpectra ) = $self->_getGcmsSpectraFromIds () ;

=cut

## START of SUB
sub _getGcmsSpectraFromIds {
    ## Retrieve Values
    my $self = shift ;
    my ( $list_ids ) = @_;
    
    my $spectra_type = 'fullscan-gcms' ; ## always fixed as part of the method specificity
    
    my $oSpectra = undef ;
    
    my $api_client = PeakForest::REST_Client::SpectraApi->new(api_key => {'token' => $self->{_DATABASE_TOKEN_}}, 'base_url' => $self->{_DATABASE_URL_}) ;
    
    if ( ( defined $list_ids ) and $list_ids > 0  ) {
    	print "\tImported peak list is not null \n" ;
    }
    elsif ( ( defined $list_ids ) and $list_ids == 0  ) {
    	print "\tImported peak list is null - (already found) No more result found\n" ;
    }
    else {
    	croak "[ERROR] The Given Ids are undef\n" ;
    }
    
    # based on curl "https://metabohub.peakforest.org/rest/v2/spectrum/PFs008655?token=xxx"
    my $nbSpectra = 0 ;
    
    foreach my $id (@{$list_ids}) {
    	print "\tQuery API with id $id\n" ;
    	my $spectrum = undef ;
    	
    	eval {
    		my $query = '/spectrum/'.$id ;
#	    	$oSpectrum = $api_client->get_spectrum(id => $id);
			$spectrum = $self->_launchGenericRestQuery($query);
#			print Dumper $spectrum ;
			my $oSpectrum = $self->__refpeakforestspectra__($spectrum) ;
			$nbSpectra ++ ;
			push (@{$oSpectra}, $oSpectrum ) ;
	    	
	    } ;
	    
	    if ($@) {
		    warn "Exception when calling SpectraApi->get_spectrum: $@\n";
		}
    }
	
    return ($oSpectra, $nbSpectra) ;
}
### END of SUB

=item _getGcmsSpectraByMatchingPeaks

	## Description : match a GC-MS spectra from a list of peaks, based on REST API V2
	## Input : $cpdId
	## Output : $oSpectra
	## Usage : my ( $oSpectra ) = $self->_getGcmsSpectraByMatchingPeaks () ;

=cut

## START of SUB
sub _getGcmsSpectraByMatchingPeaks {
    ## Retrieve Values
    my $self = shift ;
    my ( $column_code, $list_mzs, $delta ) = @_;
    
#    print "$self->{_DATABASE_TOKEN_}\n" ;
#    print "$self->{_DATABASE_URL_}\n" ;
    
    my $spectra_type = 'fullscan-gcms' ; ## always fixed as part of the method specificity
    
    my $oSpectra = [] ;
    my @spectraIds = () ; ## aggregate all matched spectra ids
    
    my $api_client = PeakForest::REST_Client::SpectraApi->new(api_key => {'token' => $self->{_DATABASE_TOKEN_}}, 'base_url' => $self->{_DATABASE_URL_}) ;
#    my $mzs_string = join(',', @{$list_mzs}) ;
    if ( ( defined $list_mzs ) and $list_mzs > 0  ) {
    	print "\tImported peak list is not null \n" ;
#    	print "Mzs list is: $mzs_string\n" ;
    }
    
    ## based on curl -v "https://metabohub.peakforest.org/rest/v2//spectra-peakmatching/fullscan-gcms
    ## ?list_mz=147.0658,171.0768&token=XX"
    eval {
    	$oSpectra = $api_client->get_spectra_matching_peaks(
    		spectra_type => $spectra_type,  
    		column_code => $column_code, 
    		polarity => $self->{_POLARITY_}, 
    		resolution => $self->{_RESOLUTION_}, 
    		list_mz => $list_mzs, 
    		delta =>  $delta ) ;
    } ;
    
    if ($@) {
	    warn "Exception when calling ChromatographyApi->get_spectra_matching_peaks: $@\n";
	}
	
#	print Dumper $oSpectra ;
	
	## Get All spectra information by REST API
	if ( ($oSpectra ne '[]') and ( scalar @{$oSpectra} > 0 ) ) {
		
		foreach my $spectrum (@{$oSpectra}) {
			# get id
			
			if ( (defined $spectrum->{'id'} ) and ( $spectrum->{'id'} =~ /PFs(\d+)/   ) ) {
				push(@spectraIds, $spectrum->{'id'})	
			}
		}
		# warn if results
		if (scalar @spectraIds > 0) {
			my $nbSpectra = scalar @spectraIds ;
			print "\tPeakForest returns $nbSpectra matched spectra\n" ;
#			print Dumper @spectraIds ;
		}
		else {
			print "\t[WARN] PeakForest returns 0 matched spectra\n" ;
		}
	}
	else {
		print "\t[WARN] PeakForest returns NONE matched spectra\n" ;
	}
	
    return (\@spectraIds) ;
}
### END of SUB



##### * * * *  REST API V01 - Deprecated since 2021 * * * * 

=item initPeakForestQuery

	## Description : Deprecated - initiate a peakforest query based on REST API V1
	## Input : $peakforestInstance
	## Output : $query
	## Usage : my ( $entriesNb ) = $self->initPeakForestQuery () ;

=cut

## START of SUB
sub initPeakForestQuery {
    ## Retrieve Values
    my $self = shift ;
    my ( $args ) = @_;
    
    $self->{_QUERY_AQUISITION_MODE_} = $args->{MODE} ;
    $self->{_QUERY_INSTRUMENT_} = $args->{INSTRUMENTS} ;

    return () ;
}
### END of SUB



=item getCleanRangeSpectraFromSource

	## Description : get the list of spectra entries from a peakforest instance and a mz range (min/max) based on REST API V1
	## Input : $oPeakForestQuery, $minMass, $maxMass
	## Output : $Spectra
	## Usage : my ( $Spectra ) = $oPeakForestQuery->getCleanRangeSpectraFromSource ( $minMass, $maxMass ) ;

=cut

## START of SUB
sub getCleanRangeSpectraFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $minMass, $maxMass ) = @_;
    
    my $jsonSPECTRA = undef ;
    my $entriesNb = 0 ;
    
    my $MIN = 0 ;
    my $MAX = 0 ;
    my $QUERY = undef ;
    my $DATABASE_URL = $self->{_DATABASE_URL_} ; 
    my $DATABASE_TOKEN = $self->{_DATABASE_TOKEN_} ;
    my $QUERY_URL = 'spectra/lcms/peaks/get-range-clean/' ; 
    my $MODE = $self->{_QUERY_AQUISITION_MODE_} ;
    
    
    # test $mz range
    if ( (defined $minMass) and $minMass > 0 ) { 	$MIN = $minMass ; 	}
    else {	carp "[ERROR][PEAKFOREST] Can't get a clean range with undef or null min mass\n" ; }
    
    if ( (defined $maxMass) and $maxMass > 0 ) { 	$MAX = $maxMass ; 	}
    else {	croak "[ERROR][PEAKFOREST] Can't get a clean range with undef or null max mass\n" ; }
    
    ## query building
    # Example of query "https://metabohub.peakforest.org/rest/spectra/lcms/peaks/get-range-clean/100.07/115.09?mode=pos&token=XXX";
    #					https://metabohub.peakforest.org/rest/spectra/lcms/peaks/get-range-clean/100.07/115.09?mode=pos&token=9131jq9l8gsjn1j14t351h716u
    $QUERY = $DATABASE_URL.$QUERY_URL.$MIN.'/'.$MAX ;
    
    if (defined $MODE) 				{	$QUERY = $QUERY.'?mode='.$MODE ; }
	if (defined $DATABASE_TOKEN)	{	$QUERY = $QUERY.'&token='.$DATABASE_TOKEN ; }
	
	print "GET $QUERY\n" ;
	
	my $ua = LWP::UserAgent->new;
#	$ua->ssl_opts(SSL_ca_file => Mozilla::CA::SSL_ca_file(), timeout => 100, verify_hostname => 1);
#	$ua->ssl_opts(SSL_ca_file     => 'metabohubpeakforestorg.crt', timeout => 100, verify_hostname => 1);
	$ua->ssl_opts(timeout => 100, verify_hostname => 0);
	my $req = HTTP::Request->new(GET => $QUERY);
	#$req->authorization_basic('[hide]','[hide]');
	my $response = $ua->request($req);
	
	if ($response->is_success) {
	    $jsonSPECTRA = decode_json $response->decoded_content;
	 }
	else {
	    croak "[ERROR][PEAKFOREST] Clean range query return a ",$response->status_line;
	}
#	print Dumper $jsonSPECTRA ;
	
	# map with a __RefEntry__
	foreach my $entry (@{$jsonSPECTRA}) {
		
		my $currentEntry = $self->__refPeakForestSpectralEntry__() ;
		
		$currentEntry->{_SPECTRAL_ID_} = $entry->{sp} ;

		$currentEntry->{_MOLECULAR_COMPOSITION_} = $entry->{composition} ;
		
		$currentEntry->{_THEO_EXACT_MASS_} = $entry->{thMass} ;
	    $currentEntry->{_EXACT_MASS_} = $entry->{mz} ;
	    $currentEntry->{_DELTA_PPM_} = $entry->{deltaPPM} ;
	    
	    $currentEntry->{_PEAK_ATTRIBUTION_} = $entry->{attribution} ;
	    $currentEntry->{_RELATIVE_INTENSITY_} = $entry->{ri} ;
	    
		if ( ( $entry->{cpds} ) and ( scalar @{ $entry->{cpds} } == 1 ) ) {
			$currentEntry->{_COMPOUND_ID_} = $entry->{cpds}[0] ;
			$self->_addSpectra($currentEntry) ;
		}
		elsif ( ( $entry->{cpds} ) and ( scalar @{ $entry->{cpds} } > 0 ) ) {
			next ;
			## TODO...
		}
				
    	$entriesNb ++ ;
	}
    return ($entriesNb) ;
}
### END of SUB

=item METHOD buildTheoPeakBankFromEntries

	## Description : Deprecated - building from a Metabolomics::Banks::PhytoHub object, a bank integrating each potential entry in a metabolomics format (POSITIVE or NEGATIVE forms)
	## Input : $queryMode [POS|NEG]
	## Output : int as $entryNb
	## Usage : my $nb = $oBank->buildTheoPeakBankFromEntries() ;

=cut

## START of SUB
sub buildTheoPeakBankFromPeakForest {
    ## Retrieve Values
    my $self = shift ;
    
    my ( $queryMode ) = @_;

    my $spectra = $self->_getSpectra();
    
    my $entryNb = 0 ; 

    foreach my $entry (@{$spectra}) {
    	
#    	print Dumper $entry ;
    	    	
    	my $oPeak = Metabolomics::Banks->__refPeak__() ;
	    
    	#_MZ_
    	if ( $entry->_getEntry_THEO_EXACT_MASS() ) {
    		$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $entry->_getEntry_THEO_EXACT_MASS() );
    	}
    	else {
    		$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $entry->_getEntry_EXACT_MASS() );
    	}
    	
    	#_COMPOUND_NAME_
	    $oPeak->_setPeak_ANNOTATION_NAME ( $entry->_getEntry_COMPOUND_NAME() );
	    #_BANK_ID_
	    $oPeak->_setPeak_ANNOTATION_ID ( $entry->_getEntry_COMPOUND_ID() );
	    #_SPECTRA_ID_
	    $oPeak->_setPeak_ANNOTATION_SPECTRA_ID ( $entry->_getEntry_SPECTRAL_ID() );
	    #_MOLECULAR_FORMULA_
	    $oPeak->_setPeak_ANNOTATION_FORMULA ( $entry->_getEntry_MOLECULAR_FORMULA() );
	    # _SMILES_
	    $oPeak->_setPeak_ANNOTATION_SMILES ( $entry->_getEntry_SMILES() );
	    # _INCHIKEY_
	    $oPeak->_setPeak_ANNOTATION_INCHIKEY ( $entry->_getEntry_INCHIKEY() );
	    
	    if ( $queryMode eq 'POSITIVE' ) {
	    	$oPeak->_setPeak_ANNOTATION_IN_POS_MODE($entry->_getEntry_PEAK_ATTRIBUTION() ) ;
	    }
	    elsif  ( $queryMode eq 'NEGATIVE' ) {
	    	$oPeak->_setPeak_ANNOTATION_IN_NEG_MODE($entry->_getEntry_PEAK_ATTRIBUTION() ) ;
	    }
	    
	    $self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
	    
	    $entryNb++ ;
    } ## END FOREACH
    
    # Set Entries number of the built database.
    $self->_set_DATABASE_ENTRIES_NB($entryNb) ;
    
    return($entryNb) ;
}
### END of SUB


=back

=head1 PRIVATE METHODS

=head2 Metabolomics::Banks::peakForest

=over 4

=item PRIVATE_ONLY __refPeakForestSpectralEntry__

	## Description : init a new peakforest spectral entry
	## Input : void	
	## Output : refEntry
	## Usage : $self->__refPeakForestSpectralEntry__() ;

=cut

## START of SUB
sub __refPeakForestSpectralEntry__ {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_SPECTRAL_ID_} = '_PEAKFOREST_SPECTRAL_ID_' ; 	#
    $self->{_SPECTRA_METADATA} = [] ; 	# spectra object from peakforest
    $self->{_COMPOUND_NAME_} = undef ; # 
    $self->{_COMPOUND_ID_} = '_COMPOUND_ID_' ; # 
	$self->{_MOLECULAR_COMPOSITION_} = '_MOLECULAR_COMPOSITION_' ;
	
	$self->{_THEO_EXACT_MASS_} = '_THEO_EXACT_MASS_' ;
    $self->{_EXACT_MASS_} = '_EXACT_MASS_' ;
    $self->{_DELTA_PPM_} = '_DELTA_PPM_' ;
    
    $self->{_PEAK_ATTRIBUTION_} = undef ;
    $self->{_RELATIVE_INTENSITY_} = undef ;

    return $self ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_INCHIKEY

	## Description : PRIVATE method _getEntry_INCHIKEY on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_INCHIKEY () ;

=cut

## START of SUB
sub _getEntry_INCHIKEY {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_INCHIKEY_}) and ( $self->{_INCHIKEY_} ne '' )  ) {	$VALUE = $self->{_INCHIKEY_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_INCHIKEY can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_SMILES

	## Description : PRIVATE method _getEntry_SMILES on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_SMILES () ;

=cut

## START of SUB
sub _getEntry_SMILES {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_SMILES_}) and ( $self->{_SMILES_} ne '' )   ) {	$VALUE = $self->{_SMILES_} ; }
    else {	 $VALUE = 'NA' ; warn "[WARN] the method _getEntry_SMILES can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_MOLECULAR_FORMULA

	## Description : PRIVATE method _getEntry_MOLECULAR_FORMULA on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_MOLECULAR_FORMULA () ;

=cut

## START of SUB
sub _getEntry_MOLECULAR_FORMULA {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_MOLECULAR_FORMULA_}) and ( $self->{_MOLECULAR_FORMULA_} ne '' ) ) {	$VALUE = $self->{_MOLECULAR_FORMULA_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_COMPOUND_NAME can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_THEO_EXACT_MASS

	## Description : PRIVATE method _getEntry_EXACT_MASS on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_THEO_EXACT_MASS () ;

=cut

## START of SUB
sub _getEntry_THEO_EXACT_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_THEO_EXACT_MASS_}) and ( $self->{_THEO_EXACT_MASS_} > 0 ) or $self->{_THEO_EXACT_MASS_} < 0  ) {	$VALUE = $self->{_THEO_EXACT_MASS_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_THEO_EXACT_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_EXACT_MASS

	## Description : PRIVATE method _getEntry_EXACT_MASS on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_EXACT_MASS () ;

=cut

## START of SUB
sub _getEntry_EXACT_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_EXACT_MASS_}) and ( $self->{_EXACT_MASS_} > 0 ) or $self->{_EXACT_MASS_} < 0  ) {	$VALUE = $self->{_EXACT_MASS_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_EXACT_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_DELTA_PPM

	## Description : PRIVATE method _getEntry_DELTA_PPM on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_DELTA_PPM () ;

=cut

## START of SUB
sub _getEntry_DELTA_PPM {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_DELTA_PPM_}) and ( $self->{_DELTA_PPM_} > 0 ) or $self->{_DELTA_PPM_} < 0  ) {	$VALUE = $self->{_DELTA_PPM_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_DELTA_PPM can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_RELATIVE_INTENSITY

	## Description : PRIVATE method _getEntry_RELATIVE_INTENSITY on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_RELATIVE_INTENSITY () ;

=cut

## START of SUB
sub _getEntry_RELATIVE_INTENSITY {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_RELATIVE_INTENSITY_}) and ( $self->{_RELATIVE_INTENSITY_} > 0 ) or $self->{_RELATIVE_INTENSITY_} < 0  ) {	$VALUE = $self->{_RELATIVE_INTENSITY_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_RELATIVE_INTENSITY can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_COMPOUND_ID

	## Description : PRIVATE method _getEntry_COMPOUND_ID on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $PhytoHub_ID ) = $entry->_getEntry_COMPOUND_ID () ;

=cut

## START of SUB
sub _getEntry_COMPOUND_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_COMPOUND_ID_} ) and ( $self->{_COMPOUND_ID_} ne '' )   ) {	$VALUE = $self->{_COMPOUND_ID_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_COMPOUND_ID can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_SPECTRAL_ID

	## Description : PRIVATE method _getEntry_SPECTRAL_ID on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $PhytoHub_ID ) = $entry->_getEntry_SPECTRAL_ID () ;

=cut

## START of SUB
sub _getEntry_SPECTRAL_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_SPECTRAL_ID_} ) and ( $self->{_SPECTRAL_ID_} ne '' )   ) {	$VALUE = $self->{_SPECTRAL_ID_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_SPECTRAL_ID can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_COMPOUND_NAME

	## Description : PRIVATE method _getEntry_COMPOUND_NAME on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_COMPOUND_NAME () ;

=cut

## START of SUB
sub _getEntry_COMPOUND_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_COMPOUND_NAME_}) and ( $self->{_COMPOUND_NAME_} ne '' ) ) {	$VALUE = $self->{_COMPOUND_NAME_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_COMPOUND_NAME can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_MOLECULAR_COMPOSITION

	## Description : PRIVATE method _getEntry_MOLECULAR_COMPOSITION on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_MOLECULAR_COMPOSITION () ;

=cut

## START of SUB
sub _getEntry_MOLECULAR_COMPOSITION {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_MOLECULAR_COMPOSITION_}) and ( $self->{_MOLECULAR_COMPOSITION_} ne '' ) ) {	$VALUE = $self->{_MOLECULAR_COMPOSITION_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_MOLECULAR_COMPOSITION can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_PEAK_ATTRIBUTION

	## Description : PRIVATE method _getEntry_PEAK_ATTRIBUTION on a refPeakForestSpectraEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_PEAK_ATTRIBUTION () ;

=cut

## START of SUB
sub _getEntry_PEAK_ATTRIBUTION {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_PEAK_ATTRIBUTION_}) and ( $self->{_PEAK_ATTRIBUTION_} ne '' ) ) {	$VALUE = $self->{_PEAK_ATTRIBUTION_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_PEAK_ATTRIBUTION can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getSpectra_ID

	## Description : PRIVATE method _getSpectra_ID on a __refpeakforestspectra__ object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $ID ) = $spectrum->_getSpectra_ID () ;

=cut

## START of SUB
sub _getSpectra_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_ID_} ) and ( $self->{_ID_} ne '' )   ) {	$VALUE = $self->{_ID_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getSpectra_ID can't _get a undef or non numerical value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getSpectra_PEAKS

	## Description : PRIVATE method _getSpectra_PEAKS on a refPeakForestSpectra object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getSpectra_PEAKS () ;

=cut

## START of SUB
sub _getSpectra_PEAKS {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUES = undef ;
    
    if ( ( defined $self->{_PEAKS_} ) and ( $self->{_PEAKS_} ne '' )   ) {	$VALUES = $self->{_PEAKS_} ; }
    else {	 $VALUES = () ; warn "[WARN] the method _getSpectra_PEAKS invoked on a __refPeakForestSpectra__ get empty ARRAY\n" ; }
    
    return ( $VALUES ) ;
}
### END of SUB

=item PRIVATE_ONLY _getSpectra_COMPOUNDS

	## Description : PRIVATE method _getSpectra_COMPOUNDS on a refPeakForestSpectra object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getSpectra_COMPOUNDS () ;

=cut

## START of SUB
sub _getSpectra_COMPOUNDS {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUES = undef ;
    
    if ( ( defined $self->{_COMPOUNDS_} ) and ( $self->{_COMPOUNDS_} ne '' )   ) {	$VALUES = $self->{_COMPOUNDS_} ; }
    else {	 $VALUES = () ; warn "[WARN] the method _getSpectra_COMPOUNDS invoked on a __refPeakForestSpectra__ get empty ARRAY\n" ; }
    
    return ( $VALUES ) ;
}
### END of SUB

=item PRIVATE_ONLY _getSpectra_SPECTRUM_NAME

	## Description : PRIVATE method _getSpectra_SPECTRUM_NAME on a refPeakForestSpectra object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getSpectra_SPECTRUM_NAME () ;

=cut

## START of SUB
sub _getSpectra_SPECTRUM_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_SPECTRUM_NAME_} ) and ( $self->{_SPECTRUM_NAME_} ne '' )   ) {	$VALUE = $self->{_SPECTRUM_NAME_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getSpectra_SPECTRUM_NAME invoked on a __refPeakForestSpectra__ get empty string\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getCpd_NAME

	## Description : PRIVATE method _getCpd_NAME on a refPeakForestCompound object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getCpd_NAME () ;

=cut

## START of SUB
sub _getCpd_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_NAME_} ) and ( $self->{_NAME_} ne '' )   ) {	$VALUE = $self->{_NAME_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getCpd_NAME invoked on a __refPeakForestCompound__ get empty string\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getCpd_INCHIKEY

	## Description : PRIVATE method _getCpd_INCHIKEY on a refPeakForestCompound object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getCpd_INCHIKEY () ;

=cut

## START of SUB
sub _getCpd_INCHIKEY {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_INCHIKEY_} ) and ( $self->{_INCHIKEY_} ne '' )   ) {	$VALUE = $self->{_INCHIKEY_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getCpd_INCHIKEY invoked on a __refPeakForestCompound__ get empty string\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getCpd_CAN_SMILES

	## Description : PRIVATE method _getCpd_CAN_SMILES on a refPeakForestCompound object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getCpd_CAN_SMILES () ;

=cut

## START of SUB
sub _getCpd_CAN_SMILES {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_CAN_SMILES_} ) and ( $self->{_CAN_SMILES_} ne '' )   ) {	$VALUE = $self->{_CAN_SMILES_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getCpd_CAN_SMILES invoked on a __refPeakForestCompound__ get empty string\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getCpd_FORMULA

	## Description : PRIVATE method _getCpd_FORMULA on a refPeakForestCompound object
	## Input : void
	## Output : $VALUES
	## Usage : my ( $VALUES ) = $spectrum->_getCpd_FORMULA () ;

=cut

## START of SUB
sub _getCpd_FORMULA {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( ( defined $self->{_FORMULA_} ) and ( $self->{_FORMULA_} ne '' )   ) {	$VALUE = $self->{_FORMULA_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getCpd_FORMULA invoked on a __refPeakForestCompound__ get empty string\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB



=item PRIVATE_ONLY _launchGenericRestQuery

	## Description : PRIVATE method _launchGenericRestQuery launch Rest queries and return json object
	## Input : $QUERY
	## Output : $JSON
	## Usage : my ( $JSON ) = $self->_launchGenericRestQuery ($QUERY) ;

=cut

## START of SUB
sub _launchGenericRestQuery {
	## Retrieve Values
    my $self = shift;
    
    my ($QUERY) = @_;
    
    my $json = undef ;
    my $httpStatus = undef ;
 
	my $complete_query = $self->{_DATABASE_URL_}.'/'.$QUERY ;
	
	if ( $complete_query =~/\?/ ) {
		if (defined $self->{_DATABASE_TOKEN_}) {  $complete_query = $complete_query.'&token='.$self->{_DATABASE_TOKEN_} ; }
	}
	else {
		if (defined $self->{_DATABASE_TOKEN_}) {  $complete_query = $complete_query.'?token='.$self->{_DATABASE_TOKEN_} ; }
	}

	my $URL = $complete_query ;
	
	print "\t===>$URL\n\n" ;
	
	my $ua = LWP::UserAgent->new;

#	$ua->ssl_opts(SSL_ca_file     => 'informatique-miainrafr.crt', timeout => 100, verify_hostname => 1);
	$ua->ssl_opts(timeout => 100, verify_hostname => 0);
	my $req = HTTP::Request->new(GET => $URL);
	my $response = $ua->request($req);
	
	$httpStatus = $response->status_line ;
	
	if ($response->is_success) {
		
		my $json_text = $response->decoded_content;
		$json = JSON->new->utf8->decode( $json_text ) ;
		
		if ( ($json eq '{"success":false,"error":"token_required"}') || ($json eq '{"success":false,"error":null}' ) )  {
			$httpStatus = '403 KO' ;
		}
	}
	else {
		## Failed...
	}
#	print Dumper $json ;

	return ($httpStatus, $json) ;   
}
## END of SUB




__END__

=back

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inrae.fr> >>

=head1 SEE ALSO

All information about Metabolomics::Banks::PeakForest would be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragnot

=head1 BUGS

Please report any bugs or feature requests to C<bug-Metabolomics-Fragment-Annotation at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Metabolomics-Fragment-Annotation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Fragment::Annotation

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Metabolomics-Fragment-Annotation>

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

followed by INRA PFEM team

Web Site = INRA PFEM


=cut

1; # End of Metabolomics::Banks::PeakForest
