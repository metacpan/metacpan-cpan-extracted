package Metabolomics::Banks ;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

use Data::Dumper ;
use Text::CSV ;
use Math::BigFloat;
use List::Util qw( min max );
use XML::Twig ;
use File::Share ':all'; 
use Carp qw (cluck croak carp) ;

#require Exporter;

#our @ISA = qw(Exporter Metabolomics::Banks::Knapsack Metabolomics::Banks::BloodExposome Metabolomics::Banks::AbInitioFragments Metabolomics::Banks::MaConDa);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Banks::BloodExposome ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	__refPeak__ getMinAndMaxMass
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	__refPeak__ getMinAndMaxMass parsingMsFragmentsByCluster
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks - Perl extension to build metabolite banks for metabolomics 

=head1 VERSION

Version 0.3 - Object integration for multi-annotation
Version 0.4 - Completing object properties and add cluster support
Version 0.5 - parsingFeaturesFragments method to manage complexe fragments (multiple features)
Version 0.6 - Fix intensity parsing reference issue in Banks::parsingFeaturesFragments method + computing relative_100+relative_900/absolute intensities

=cut

our $VERSION = '0.6';


=head1 SYNOPSIS

    use Metabolomics::Banks

=head1 DESCRIPTION

	Metabolomics::Banks is a meta class for bank objects.

=head1 EXPORT

use Metabolomics::Banks qw( :all ) ;

=head1 PUBLIC METHODS 

=head2 Metabolomics::Fragment::Annotation

=over 4

=item new 

	## Description : set a new bank object
	## Input : NA
	## Output : $oBank
	## Usage : my ( $oBank ) = Metabolomics::Banks->new ( ) ;

=cut

## START of SUB
sub new {
	## Variables
	my ($class,$args) = @_;
	my $self={};

	bless($self) ;
    
    $self->{_DATABASE_NAME_} = undef ; ## STRING, name of the current db
    $self->{_DATABASE_TYPE_} = undef ; ## STRING, name of the current db
    $self->{_DATABASE_VERSION_} = '1.0' ; ## FLOAT, version number e.g. 1.0
    $self->{_DATABASE_ENTRIES_NB_} = 'database_entries_nb' ; ## INT, number of DB entries - - 
    $self->{_DATABASE_URL_} = 'database_url' ; ## STRING, url to the resource - - mandatory
    $self->{_DATABASE_URL_CARD_} = 'database_url_card' ; ## STRING, url to the resource card part - - optionnal
    $self->{_DATABASE_DOI_} = 'database_doi' ; ## STRING, DOI to the scientific publication
    $self->{_DATABASE_ENTRIES_} = [] ; ## ARRAYS, All entries with metadata
    $self->{_DATABASE_SPECTRA_} = {} ; ## HASH, All spectra entries with metadata { SPECTRA_ID => oSpectrum }
    $self->{_THEO_PEAK_LIST_} = [] ; ## ARRAYS, All theo peaks metadata
    $self->{_EXP_PEAK_LIST_} = [] ; ## ARRAYS, All exp peaks metadata
    $self->{_EXP_PEAK_LIST_ALL_ANNOTATIONS_} = [] ; ## ARRAYS, All exp annotated (or not) peaks + metadata
    $self->{_EXP_PSEUDOSPECTRA_LIST_} = {} ;  ## HASH of ARRAYs { PseudoSp_ID => [sorted Exp. oPeaks] }
    $self->{_PSEUDOSPECTRA_SPECTRA_INDEX_} = {} ; ## HASH of ARRAY {PseudoSp_ID => [SPECTRA_ID, ...] }
        
    return ($self) ;
}
### END of SUB

=item computeNeutralCpdMz_To_PositiveIonMz

	## Description : compute the mz of a neutral cpd into the positive ion form mz
	## Input : $initMz, $charge
	## Output : $positiveMz
	## Usage : my ( $positiveMz ) = computeNeutralCpdMz_To_PositiveIonMz ( $initMz, $charge ) ;

=cut

## START of SUB
sub computeNeutralCpdMz_To_PositiveIonMz {
    ## Retrieve Values
    my $self = shift ;
    my ( $initMz, $charge ) = @_;
    my ( $positiveMz ) = ( undef ) ;
    
    my $protonMass = 1.007825 ;
    my $electronMass = 0.0005486 ; 
    
    if (!defined $charge) { 	$charge = 1 ; }
    
    $positiveMz = ( $initMz + $protonMass - $electronMass ) * $charge ;
    
    my $oUtils = Metabolomics::Utils->new() ;
    my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($initMz, $electronMass) ;
    $positiveMz = sprintf("%.$decimalLength"."f", $positiveMz );
    
    return ($positiveMz) ;
}
### END of SUB

=item computeNeutralCpdMz_To_NegativeIonMz

	## Description : compute the mz of a neutral cpd into the positive ion form mz
	## Input : $initMz, $chargeNumber
	## Output : $negativeMz
	## Usage : my ( $negativeMz ) = computeNeutralCpdMz_To_NegativeIonMz ( $initMz, $chargeNumber ) ;

=cut

## START of SUB
sub computeNeutralCpdMz_To_NegativeIonMz {
    ## Retrieve Values
    my $self = shift ;
    my ( $initMz, $charge ) = @_;
    my ( $negativeMz ) = ( undef ) ;
    
    my $protonMass = 1.007825 ;
    my $electronMass = 0.0005486 ; 
    
    if (!defined $charge) { 	$charge = 1 ; }
    
    $negativeMz = ( $initMz - $protonMass + $electronMass ) * $charge ;
    
    my $oUtils = Metabolomics::Utils->new() ;
    my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($initMz, $electronMass) ;
    $negativeMz = sprintf("%.$decimalLength"."f", $negativeMz );
    
    return ($negativeMz) ;
}
### END of SUB

=item computeRelativeIntensity
	## Description : relative intensity computed based on 100 or 999...
	## Input : $mzs_intensities, $intensityHeader, $base, 
	## Output : $mzs_intensities_relIntensities
	## Usage : my ( $mzs_intensities_relIntensities ) = computeRelativeIntensity ( $mzs_intensities, intensityHeader, base ) ;
	
=cut
## START of SUB
sub computeRelativeIntensity {
    ## Retrieve Values
#    my $self = shift ;
    my ( $absIntensity, $maxIntensity, $baseIntensity ) = @_;
    
    my $relIntensity = undef ;
    my $oUtils = Metabolomics::Utils->new() ;
    	
    $relIntensity = $oUtils->roundFloat( ($absIntensity / $maxIntensity ), 4) ;
    	
   	if ($relIntensity == 0) {
   		$relIntensity = 1 ;
   	}
   	else {
   		## based on 100 (hmdb)
   		if ($baseIntensity == 100 ) {
   			$relIntensity = $oUtils->roundFloat( ( ( $relIntensity * $baseIntensity ) ), 4) ;
   		}
   		## based on 999 (massbank format)
   		elsif ($baseIntensity == 1000 ) {
   			$relIntensity = $oUtils->roundFloat( ( ( $relIntensity * $baseIntensity - 1 ) ), 4) ;
   		}
   		else {
   			croak ("[ERROR] The given base intensity is not supported (100 or 1000") ;
   		}
    }
    return($relIntensity) ;
}
### END of SUB

=item getMinAndMaxMass

	## Description : retrieve the min/max mz of a __PEAK_LIST_
	## Input : N/A
	## Output : $minMs, $maxMs
	## Usage : my ( $minMs, $maxMs ) = getMinAndMaxMass() ;

=cut

## START of SUB
sub getMinAndMaxMass {
    ## Retrieve Values
    my $self = shift ;
#    my (  ) = @_;
    my ( $minMs, $maxMs ) = ( 0, 0 ) ;
    
    my @mzs = () ;
    
    my $peakList = $self->_getPeakList('_EXP_PEAK_LIST_') ;
    
    foreach my $peak ( @{$peakList} ) {
    	if ( $peak->_getPeak_MESURED_MONOISOTOPIC_MASS() ) {
    		push ( @mzs, $peak->_getPeak_MESURED_MONOISOTOPIC_MASS() ) ;	
    	}
    }
    
    $minMs = min @mzs ;
	$maxMs = max @mzs ;
#
#	my ( $min_delta, undef ) = $opfws->mz_delta_conversion(\$min, \$mz_delta_type, \$mz_delta) ;
#	my ( undef, $max_delta ) = $opfws->mz_delta_conversion(\$max, \$mz_delta_type, \$mz_delta) ;
    
    return ($minMs, $maxMs) ;
}
### END of SUB

=item parsingMsFragments

	## Description : get a list of Ms fragment from a experimental mesureament.
	## Input : $oBank, $Xfile, $is_header, $column
	## Output : $msFragBank
	## Usage : $oBank->parsingMsFragments ( $Xfile, $is_header, $column ) ;

=cut

## START of SUB
sub parsingMsFragments {
    ## Retrieve Values
    my ( $oBank, $Xfile, $is_header, $column ) = @_;
    my @fragmentsList = () ;

    #### FOR TEST ONLY :
    if ((!defined $Xfile) or (!defined $column) or (!defined $is_header)) {
    	@fragmentsList = (178.9942, 156.0351, 118.9587, 118.9756, 108.0666) ;
    }
    
    ## Check file extension (tsv, csv, tabular...) and adapt csv object constructor
    my $csv = undef ;
    
    if ($Xfile =~/\.(csv|CSV)$/) {
    	print "Parsing a CSV file...\n" ;
    	$csv = Text::CSV->new ( { 'sep_char' => ",", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use CSV: ".Text::CSV->error_diag ();	
    }
    elsif ($Xfile =~/\.(tsv|TSV|TABULAR|tabular)$/) {
    	print "Parsing a tabular file...\n" ;
    	$csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use CSV: ".Text::CSV->error_diag ();	
    }
    else { # By default considering tabular as default format
    	$csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use TSV: ".Text::CSV->error_diag ();	
    }
    
    ## Adapte the number of the colunm : (nb of column to position in array)
	$column = $column - 1 ;
    
    open (CSV, '<:crlf', $Xfile) or die $! ;
	my $line = 0 ;
	
	while (<CSV>) {
		$line++ ;
	    chomp $_ ;
		# file has a header
		if ( defined $is_header ) { if ($line == 1) { next ; } }
		# parsing the targeted column
	    if ( $csv->parse($_) ) {
	        my @columns = $csv->fields();
	        push ( @fragmentsList, $columns[$column] ) ;
	    }
	    else {
	        my $err = $csv->error_input;
	        die "Failed to parse line: $err";
	    }
	}
	close CSV;
    
    ## Create a PeakList
    foreach my $mz (@fragmentsList) {
    	
    	my $oPeak = Metabolomics::Banks->__refPeak__() ;
	    $oPeak->_setPeak_MESURED_MONOISOTOPIC_MASS ( $mz );
#	    $oPeak->_setANNOTATION_TYPE (  );
#	    $oPeak->_setANNOTATION_NAME (  );
#	    $oPeak->_setANNOTATION_IN_NEG_MODE (  );
#	    $oPeak->_setANNOTATION_IN_POS_MODE (  );
    	
    	$oBank->_addPeakList('_EXP_PEAK_LIST_', $oPeak) ;
    }
    
}
### END of SUB

=item parsingMsFragmentsByCluster

	## Description : get a list of Ms fragment from a experimental mesureament.
	## Input : $oBank, $Xfile, $is_header, $column
	## Output : $msFragBank
	## Usage : $oBank->parsingMsFragments ( $Xfile, $is_header, $column ) ;

=cut

## START of SUB
sub parsingMsFragmentsByCluster {
    ## Retrieve Values
    my ( $oBank, $Xfile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds ) = @_;
    
    my $mzs = undef ;
    my $into = undef ;
    my $clusters = undef ;
    
    ## Check file extension (tsv, csv, tabular...) and adapt csv object constructor
    my $csv = undef ;
    
    if ($Xfile =~/\.(csv|CSV)$/) {
    	print "Parsing a CSV file...\n" ;
    	$csv = Text::CSV->new ( { 'sep_char' => ",", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use CSV: ".Text::CSV->error_diag ();	
    }
    elsif ($Xfile =~/\.(tsv|TSV|TABULAR|tabular)$/) {
    	print "Parsing a tabular file...\n" ;
    	$csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use TSV: ".Text::CSV->error_diag ();	
    }
    else { # By default considering tabular as default format
    	$csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use TSV: ".Text::CSV->error_diag ();	
    }
    
    open (CSV, '<:crlf', $Xfile) or die $! ;
	my $line = 0 ;
	
	while (<CSV>) {
		$line++ ;
	    chomp $_ ;
		# file has a header
		if ( defined $is_header ) { if ($line == 1) { next ; } }
		# parsing the targeted column
	    if ( $csv->parse($_) ) {
	        my @columns = $csv->fields();
	        push ( @{$mzs}, $columns[$col_Mzs - 1] ) 				if (defined $col_Mzs);
	        push ( @{$into}, $columns[$col_Ints - 1] ) 				if (defined $col_Ints);
	        push ( @{$clusters}, sprintf( "%04s", $columns[$col_ClusterIds - 1] )  ) 	if (defined $col_ClusterIds); # Make Clusters sortable by id
	    }
	    else {
	        my $err = $csv->error_input;
	        die "Failed to parse line: $err";
	    }
	}
	close CSV;
	
	## manage input file with no into colunm / init into with a default value of 10
	if ( !defined $col_Ints ) {
		my $nb_mzs = scalar(@{$mzs}) ;
		my @intos = map {10} (0..$nb_mzs-1) ;
		my $nb_intos = scalar(@intos) ;
		if ($nb_intos == $nb_mzs) { $into = \@intos ;	}
		else { carp "A difference exists between intensity and mz values\n" }
	}
	
	## Transform int in relative intensity
	if (defined $into) {
		my $oUtils = Metabolomics::Utils->new() ;
		$into = $oUtils->validFloat($into) ;
		$into = $oUtils->trackZeroIntensity($into) ;
		$mzs = $oUtils->validFloat($mzs) ;
	}
	
	my $num_pcs = scalar(@{$clusters}) ;
    my $num_mzs = scalar(@{$mzs}) ;
    my $num_ints = scalar(@{$into}) ;
    my $num_peaks = 0 ;
    
    ## Create a PeakList
    foreach my $mz (@{$mzs}) {
    	
    	my $oPeak = Metabolomics::Banks->__refPeak__() ;
	    $oPeak->_setPeak_MESURED_MONOISOTOPIC_MASS ( $mz );
	    $oPeak->_setPeak_INTENSITY ( $into->[$num_peaks] );
	    $oPeak->_setPeak_CLUSTER_ID ( $clusters->[$num_peaks]  );
	    
    	$oBank->_addPeakList('_EXP_PEAK_LIST_', $oPeak) ;
    	$oBank->_addPeakList('_EXP_PSEUDOSPECTRA_LIST_', $oPeak, $clusters->[$num_peaks] ) ;
    	$num_peaks++ ;
    }
    
#    print Dumper $mzs ;
#    print Dumper $into ;
#    print Dumper $clusters ;

    return ($num_mzs, $num_ints, $num_pcs) ;
    
}
### END of SUB

=item parsingFeaturesFragments

	## Description : get a list of fragments from a experimental mesureament with all their features.
	## Input : $oBank, $Xfile, $is_header, $columns
	## Output : $msFragBank
	## Usage : $oBank->parsingFeaturesFragments ( $Xfile, $is_header, $columns ) ;

=cut

## START of SUB
sub parsingFeaturesFragments {
    ## Retrieve Values
    my ( $oBank, $Xfile, $is_header, $columns ) = @_;
    ## $columns = [$MZ, $AB_INTENSITY, $REL100_INTENSITY, $REL999_INTENSITY] # 4 values
    my @fragmentsList = () ;
    my @headers = () ;

    #### FOR TEST ONLY :
    if ((!defined $Xfile) or (!defined $columns) or (!defined $is_header)) {
    	@fragmentsList = ( { 'mz' => '173.09274', 'ri' => '100.0'}, { 'mz' => '174.09584', 'ri' => '4.975'}, { 'mz' => '175.09841', 'ri' => '0.273'}  ) ;
    	@headers =( 'mz', 'ri' ) ;
    }
    
    ## Check file extension (tsv, csv, tabular...) and adapt csv object constructor
    my $csv = undef ;
    
    if ($Xfile =~/\.(csv|CSV)$/) {
    	print "Parsing a CSV file...\n" ;
    	$csv = Text::CSV->new ( { 'sep_char' => ",", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use CSV: ".Text::CSV->error_diag ();	
    }
    elsif ($Xfile =~/\.(tsv|TSV|TABULAR|tabular)$/) {
    	print "Parsing a tabular file...\n" ;
    	$csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use CSV: ".Text::CSV->error_diag ();	
    }
    else { # By default considering tabular as default format
    	$csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    	or die "Cannot use TSV: ".Text::CSV->error_diag ();	
    }
    
    ## Adapte the number of the colunm : (nb of column to position in array)
    
    open my $fh, '<:crlf', $Xfile or die $! ;
	
	@headers =	$csv->header( $fh ) ;
	
	## Clean headers: (can contains space before or after value/key)
	my @cleanHeaders = () ;
	
	foreach my $header (@headers) {
		
		my $headerToclean = $header ;
		$headerToclean =~ s/^\s+//;
		$headerToclean =~ s/\s+$//;
		push (@cleanHeaders, $headerToclean) ;
	}
	
	## Get data
	while (my $row = $csv->getline_hr ($fh)) {
		my $fragment = undef ;
		
		foreach my $col ( @{$columns} ) {
			
			if (defined $col) {
				
				my $fieldName = $cleanHeaders[$col -1] ;
				$fieldName =~ s/^\s+//;
				$fieldName =~ s/\s+$//;
				
				my $fieldValue = $row->{$headers[$col -1]} ;
				$fieldValue =~ s/^\s+//;
				$fieldValue =~ s/\s+$//;
				
	        	$fragment->{ $fieldName } = $fieldValue ;
				
			}
			else {
				next ;
			}
        }
        my $tmp = $fragment ;
        push ( @fragmentsList, $tmp ) ;
	}
    
    #print Dumper @fragmentsList ;
    
    my $currentMzHeader = $cleanHeaders[ $columns->[0] - 1 ] if ( $columns->[0] ) ;
    my $currentAbIntHeader = $cleanHeaders[ $columns->[1] - 1 ] if ( $columns->[1] ) ;
    my $currentRel100IntHeader = $cleanHeaders[ $columns->[2] - 1 ] if ( $columns->[2] ) ;
    my $currentRel999IntHeader = undef ; ## corresponding to $columns->[3]
    
    my @sortedRelInt =  sort { $a->{$currentAbIntHeader} <=> $b->{$currentAbIntHeader} } @fragmentsList ;
    
    #print Dumper @sortedRelInt ;
    my $maxAbsoluteIntensity = $sortedRelInt[-1]->{$currentAbIntHeader} ;
    
    #print "MAX IS : $maxAbsoluteIntensity\n" ;
    
    ## Create a PeakList (Mapping on )
    foreach my $features (@fragmentsList) {
    
    	my $oPeak = Metabolomics::Banks->__refPeak__() ;
    	## TODO... make it generic ! (NOT ONLY FOR BRUKER output format)
    	## Issue '_INTENSITY_' => '195.07577', (this is MZ and NOT intensity)
    	#my $currentMzHeader = $cleanHeaders[ $columns->[0] - 1 ] if ( $columns->[0] ) ;
    	#my $currentAbIntHeader = $cleanHeaders[ $columns->[1] - 1 ] if ( $columns->[1] ) ;
    	#my $currentRel100IntHeader = $cleanHeaders[ $columns->[2] - 1 ] if ( $columns->[2] ) ;
    	#my $currentRel999IntHeader = undef ; ## corresponding to $columns->[3]
    	
    	$oPeak->_setPeak_MESURED_MONOISOTOPIC_MASS (  $features->{$currentMzHeader} ) ;
	    $oPeak->_setPeak_INTENSITY ( $features->{$currentAbIntHeader} ) ;
	    
    	if ( ( defined $currentAbIntHeader ) and ( ( !defined $currentRel100IntHeader ) or ( !defined $currentRel999IntHeader ) ) ) {
    		## compute Rel100 + Rel999
    		my $currentRelIntValue100 = computeRelativeIntensity($features->{$currentAbIntHeader}, $maxAbsoluteIntensity, 100) ;
    		my $currentRelIntValue999 = computeRelativeIntensity($features->{$currentAbIntHeader}, $maxAbsoluteIntensity, 1000) ;
    		$oPeak->_setPeak_RELATIVE_INTENSITY_100 ( $currentRelIntValue100 ) ;
	   		$oPeak->_setPeak_RELATIVE_INTENSITY_999 ( $currentRelIntValue999 ) ;
    	}
	    
    	$oBank->_addPeakList('_EXP_PEAK_LIST_', $oPeak) ;
    	
    }
}
### END of SUB



=back

=head1 PRIVATE METHODS

=head2 Metabolomics::Banks

=over 4

=item PRIVATE_ONLY _set_DATABASE_ENTRIES_NB

	## Description : _set_DATABASE_ENTRIES_NB
	## Input : $DATABASE_ENTRIES_NB
	## Output : TRUE
	## Usage : $self->_set_DATABASE_ENTRIES_NB ( $DATABASE_ENTRIES_NB ) ;

=cut

## START of SUB
sub _set_DATABASE_ENTRIES_NB {
    ## Retrieve Values
    my $self = shift ;
    my ( $DATABASE_ENTRIES_NB ) = @_;
    
    if ( (defined $DATABASE_ENTRIES_NB) and ( ($DATABASE_ENTRIES_NB > 0) )  ) {	$self->{_DATABASE_ENTRIES_NB_} = $DATABASE_ENTRIES_NB ; }
    else {	carp "[ERROR] the method set_DATABASE_ENTRIES_NB can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _addEntry

	## Description : _addEntry
	## Input : $self, $Entry ;
	## Ouput :  NA
	## Usage : _addEntry($Entry);

=cut

### START of SUB

sub _addEntry {
    my ($self, $Entry) = @_;
    
    if (defined $Entry) {
    	push (@{$self->{_DATABASE_ENTRIES_}}, $Entry);
    }
}

### END of SUB

=item PRIVATE_ONLY _addSpectra

	## Description : _addSpectra
	## Input : $self, $Entry, $Index ;
	## Ouput :  NA
	## Usage : _addSpectra($Entry, $Index);

=cut

### START of SUB

sub _addSpectra {
    my ($self, $Entry, $Index) = @_;
    
    if ( (defined $Entry) and (!defined $Index) ) {
    	my $Index = time ;
    	$self->{_DATABASE_SPECTRA_}{$Index} = $Entry ;
    }
    elsif ( (defined $Entry) and (defined $Index) ) {
    	$self->{_DATABASE_SPECTRA_}{$Index} = $Entry ;
    }
}

=item PRIVATE_ONLY _indexSpectraByCluster

	## Description : _indexSpectraByCluster
	## Input : $self, $clusterID, $spectralID ;
	## Ouput :  NA
	## Usage : $self->_indexSpectraByCluster($clusterID, $spectralID);

=cut

### START of SUB

sub _indexSpectraByCluster {
    my ($self, $clusterID, $spectralID) = @_;
    
    if ( (defined $clusterID) and (defined $spectralID) ) {
    	    	
    	push (@{$self->{_PSEUDOSPECTRA_SPECTRA_INDEX_}{$clusterID}}, $spectralID) ;
    	
#    	if ($self->{_PSEUDOSPECTRA_SPECTRA_INDEX_}{$clusterID}) {
#    		
#    	}
#    	else {
#    		$self->{_PSEUDOSPECTRA_SPECTRA_INDEX_}{$clusterID} = [] ;
#    		push (@{$self->{_PSEUDOSPECTRA_SPECTRA_INDEX_}{$clusterID}}, $spectralID) ;
#		}
    	
    }
    else {
    	croak "[ERROR] Impossible to index any spectra by its cluster (pseudospectra id)\n" ;
    }
}

=item PRIVATE_ONLY _detectSpectraDuplicate

	## Description : _detectSpectraDuplicate
	## Input : $self, $spectralID ;
	## Ouput :  TRUE/FALSE
	## Usage : $self->_detectSpectraDuplicate($spectralID);

=cut

### START of SUB

sub _detectSpectraDuplicate {
    my ($self, $spectralID) = @_;
    
    my $SpectraStatus = undef ;
    
    if ( (defined $spectralID) ) {
    	
    	if ($self->{_DATABASE_SPECTRA_}{$spectralID}) {
    		$SpectraStatus = 'TRUE' ;
    	}
    	else {
    		$SpectraStatus = 'FALSE' ;
    	}
    }
    else {
    	croak "[ERROR] Impossible to search in the index without spectra id\n" ;
    }
}



### END of SUB

=item PRIVATE_ONLY _addFragment

	## Description : _addFragment
	## Input : $self, $fragment ;
	## Ouput :  NA
	## Usage : _addFragment($fragment);

=cut

### START of SUB

sub _addFragment {
    my ($self, $fragment) = @_;
    
    if (defined $fragment) {
    	push (@{$self->{_FRAGMENTS_}}, $fragment);
    }
}

### END of SUB

=item PRIVATE_ONLY _addContaminant

	## Description : _addContaminant
	## Input : $self, $contaminant ;
	## Ouput :  NA
	## Usage : _addContaminant($contaminant);

=cut

### START of SUB

sub _addContaminant {
    my ($self, $contaminant) = @_;
    
    if (defined $contaminant) {
    	push (@{$self->{_CONTAMINANTS_}}, $contaminant);
    }
    else {
    	croak "[ERROR] No contaminant is defined\n" ;
    }
}

### END of SUB

=item PRIVATE_ONLY _getContaminants

	## Description : get the list of contaminants from the bank object
	## Input : $self
	## Output : $contaminants
	## Usage : my ( $contaminants ) = $obank->_getContaminants () ;

=cut

## START of SUB
sub _getContaminants {
    ## Retrieve Values
    my $self = shift ;
    my ( $contaminants ) = ( () ) ;
    
    $contaminants = $self->{_CONTAMINANTS_} ;
    
    return ($contaminants) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntries

	## Description : get the list of entries from the bank object
	## Input : $self
	## Output : $Entries
	## Usage : my ( $Entries ) = $obank->_getEntries () ;

=cut

## START of SUB
sub _getEntries {
    ## Retrieve Values
    my $self = shift ;
    my ( $Entries ) = ( () ) ;
    
    $Entries = $self->{_DATABASE_ENTRIES_} ;
    
    return ($Entries) ;
}
### END of SUB

=item PRIVATE_ONLY _getSpectra

	## Description : get the list of entries from the bank object
	## Input : $self
	## Output : $Entries
	## Usage : my ( $Entries ) = $obank->_getSpectra () ;

=cut

## START of SUB
sub _getSpectra {
    ## Retrieve Values
    my $self = shift ;
    my ( $Entries ) = ( () ) ;
    
    $Entries = $self->{_DATABASE_SPECTRA_} ;
    
    return ($Entries) ;
}
### END of SUB

=item PRIVATE_ONLY _getFragments

	## Description : get the list of fragments from the bank object
	## Input : $self
	## Output : $fragments
	## Usage : my ( $fragments ) = $obank->_getFragments () ;

=cut

## START of SUB
sub _getFragments {
    ## Retrieve Values
    my $self = shift ;
    my ( $fragments ) = ( () ) ;
    
    $fragments = $self->{_FRAGMENTS_} ;
    
    return ($fragments) ;
}
### END of SUB

=item PRIVATE_ONLY _getTheoricalPeaks

	## Description : get the list of theorical peaks from the bank object
	## Input : $self
	## Output : $theoPeaks
	## Usage : my ( $theoPeaks ) = $obank->_getTheoricalPeaks () ;

=cut

## START of SUB
sub _getTheoricalPeaks {
    ## Retrieve Values
    my $self = shift ;
    my ( $theoPeaks ) = ( () ) ;
    
    $theoPeaks = $self->{_THEO_PEAK_LIST_} ;
    
    return ($theoPeaks) ;
}
### END of SUB

=item PRIVATE_ONLY __refPeak__

	## Description : set a new theorical peak
	## Input : NA	
	## Output : refPeak
	## Usage : my ( refPeak ) = __refPeak__() ;

=cut

## START of SUB
sub __refPeak__ {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    $self->{_ID_} = undef ; # identifiant (for theo peak)
    $self->{_SPECTRA_ID_} = undef ; # spectra identifiant (for theo peak) - best hit
    $self->{_MESURED_MONOISOTOPIC_MASS_} = 0 ; # mesured accurate mass (for exp peak)
    $self->{_CLUSTER_ID_} = undef ; 	# PC_GROUP or PSEUDOSPECTRA / CLUSTER ID of the peak
    $self->{_INTENSITY_} = undef ; 	# Absolute intensity
    $self->{_RELATIVE_INTENSITY_100_} = undef ; 	# Relative intensity in base 100
    $self->{_RELATIVE_INTENSITY_999_} = undef ; 	# Relative intensity in base 999
    $self->{_COMPUTED_MONOISOTOPIC_MASS_} = 0 ; # computed accurate mass (for theo peak) - best hit
    $self->{_PPM_ERROR_} = 0 ; # FLOAT - best hit
    $self->{_MMU_ERROR_} = 0 ; # FLOAT - best hit
    $self->{_ANNOTATION_IN_NEG_MODE_} = undef ; # STRING as [M-H]- - best hit
    $self->{_ANNOTATION_IN_POS_MODE_} = undef ; # STRING as [M+H]+ - best hit
    $self->{_ANNOTATION_ONLY_IN_} = undef ; # STRING as [undef|NEG|POS], undef is default - best hit
    $self->{_ANNOTATION_TYPE_} = undef ; # STRING as adducts, fragment or isotope - best hit
    $self->{_ANNOTATION_NAME_} = undef ; # STRING for metabolite common name - best hit
    $self->{_ANNOTATION_FORMULA_} = undef ; # STRING for metabolite molecular formula - best hit
    $self->{_ANNOTATION_INCHIKEY_} = undef ; # STRING for metabolite inchikey representation - best hit
    $self->{_ANNOTATION_SMILES_} = undef ; # STRING for metabolite smiles representation - best hit
    $self->{_ANNOTATION_IS_A_METABOLITE_} = undef ; # STRING for metabolite status - best hit
    $self->{_ANNOTATION_IS_A_PRECURSOR_} = undef ; # STRING for metabolite status - best hit
    $self->{_ANNOTATIONS_} = [] ; # ARRAY for metabolite annotations
    $self->{_ANNOTATION_SPECTRAL_IDS_} = [] ; # ARRAY of ids from matched spectra

    return $self ;
}
### END of SUB

=item PRIVATE_ONLY _addPeakList

	## Description : _addPeakList
	## Input : $self, $type, $peakList ;
	## Ouput : NA;
	## Usage : _addPeakList($type, $peakList);

=cut

### START of SUB

sub _addPeakList {
    my ($self, $type, $peakList, $index) = @_;
    
    ## type should be _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ or _EXP_PSEUDOSPECTRA_LIST_
	if ( (defined $type) and (defined $peakList) and (!defined $index) ) {
		push (@{$self->{$type}}, $peakList);
	}
	# Manage indew in case of pseudo spectra
	elsif ( (defined $type) and (defined $peakList) and (defined $index) ) {
		push (@{$self->{$type}{$index}}, $peakList);
	}
	else{
		croak "type peaklist should be _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ or _EXP_PSEUDOSPECTRA_LIST_ \n" ;
	}
}
### END of SUB


=item PRIVATE_ONLY _getPeakList

	## Description : get the list of fragments from the bank object
	## Input : $self, $type
	## Output : $peakList
	## Usage : my ( $peakList ) = $obank->_getPeakList ($type) ;

=cut

## START of SUB
sub _getPeakList {
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
    elsif ( (defined $type) and ($type eq '_EXP_PSEUDOSPECTRA_LIST_') ) {
    	$peakList = $self->{_EXP_PSEUDOSPECTRA_LIST_} ;
    }
    else {
    	croak "[ERROR] No type is undefined or does not correspond to _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ \n" ;
    }
    
    
    return ($peakList) ;
}
### END of SUB

#
## * * * * * * * * * * * * * * get/setter * * * * * * * * * * * * * #
#

=item PRIVATE_ONLY _setPeak_COMPUTED_MONOISOTOPIC_MASS

	## Description : _setPeak_COMPUTED_MONOISOTOPIC_MASS
	## Input : $COMPUTED_MONOISOTOPIC_MASS
	## Output : TRUE
	## Usage : _setPeak_COMPUTED_MONOISOTOPIC_MASS ( $COMPUTED_MONOISOTOPIC_MASS ) ;

=cut

## START of SUB
sub _setPeak_COMPUTED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    my ( $COMPUTED_MONOISOTOPIC_MASS ) = @_;
    
    if ( (defined $COMPUTED_MONOISOTOPIC_MASS) and ( ($COMPUTED_MONOISOTOPIC_MASS >= 0) or ($COMPUTED_MONOISOTOPIC_MASS <= 0) )  ) {	$self->{_COMPUTED_MONOISOTOPIC_MASS_} = $COMPUTED_MONOISOTOPIC_MASS ; }
    else {	carp "[ERROR] the method _setCOMPUTED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeakCOMPUTED_MONOISOTOPIC_MASS

	## Description : _getPeakCOMPUTED_MONOISOTOPIC_MASS
	## Input : void
	## Output : $COMPUTED_MONOISOTOPIC_MASS
	## Usage : my ( $COMPUTED_MONOISOTOPIC_MASS ) = _getPeakCOMPUTED_MONOISOTOPIC_MASS () ;

=cut

## START of SUB
sub _getPeak_COMPUTED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $COMPUTED_MONOISOTOPIC_MASS = undef ;
    
    if ( (defined $self->{_COMPUTED_MONOISOTOPIC_MASS_}) and ( $self->{_COMPUTED_MONOISOTOPIC_MASS_} > 0 ) or $self->{_COMPUTED_MONOISOTOPIC_MASS_} < 0  ) {	$COMPUTED_MONOISOTOPIC_MASS = $self->{_COMPUTED_MONOISOTOPIC_MASS_} ; }
    else {	 $COMPUTED_MONOISOTOPIC_MASS = 0 ; warn "[WARN] the method _getPeakCOMPUTED_MONOISOTOPIC_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $COMPUTED_MONOISOTOPIC_MASS ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeakMESURED_MONOISOTOPIC_MASS

	## Description : _setPeakMESURED_MONOISOTOPIC_MASS
	## Input : $MESURED_MONOISOTOPIC_MASS
	## Output : TRUE
	## Usage : _setPeakMESURED_MONOISOTOPIC_MASS ( $MESURED_MONOISOTOPIC_MASS ) ;

=cut

## START of SUB
sub _setPeak_MESURED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    my ( $MESURED_MONOISOTOPIC_MASS ) = @_;
    
    if ( (defined $MESURED_MONOISOTOPIC_MASS) and ( ($MESURED_MONOISOTOPIC_MASS > 0) or ($MESURED_MONOISOTOPIC_MASS < 0) )  ) {
    	$MESURED_MONOISOTOPIC_MASS =~ s/\s//g ;
    	$self->{_MESURED_MONOISOTOPIC_MASS_} = $MESURED_MONOISOTOPIC_MASS ; 
    }
    else {	carp "[ERROR] the method _setPeakMESURED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeakMESURED_MONOISOTOPIC_MASS

	## Description : _getPeakMESURED_MONOISOTOPIC_MASS
	## Input : void
	## Output : $MESURED_MONOISOTOPIC_MASS
	## Usage : my ( $MESURED_MONOISOTOPIC_MASS ) = _getPeakMESURED_MONOISOTOPIC_MASS () ;

=cut

## START of SUB
sub _getPeak_MESURED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $MESURED_MONOISOTOPIC_MASS = undef ;
    
    if ( (defined $self->{_MESURED_MONOISOTOPIC_MASS_}) and ( $self->{_MESURED_MONOISOTOPIC_MASS_} > 0 ) or $self->{_MESURED_MONOISOTOPIC_MASS_} < 0  ) {	$MESURED_MONOISOTOPIC_MASS = $self->{_MESURED_MONOISOTOPIC_MASS_} ; }
    else {	 $MESURED_MONOISOTOPIC_MASS = 0 ; warn "[WARN] the method _getPeakMESURED_MONOISOTOPIC_MASS can't _getPeak a undef or non numerical value\n" ; }
    
    return ( $MESURED_MONOISOTOPIC_MASS ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_CLUSTER_ID

	## Description : _setPeak_CLUSTER_ID
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_CLUSTER_ID ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_CLUSTER_ID {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE)  ) {
    	$VALUE =~ s/\s//g ;
    	$self->{_CLUSTER_ID_} = $VALUE ; 
    }
    else {	
#    	warn "[WARN] the method _setPeak_CLUSTER_ID set an undef or non numerical value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_CLUSTER_ID

	## Description : _getPeak_CLUSTER_ID
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_CLUSTER_ID () ;

=cut

## START of SUB
sub _getPeak_CLUSTER_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_CLUSTER_ID_}) ) {
    	$VALUE = $self->{_CLUSTER_ID_} ; 
    }
    else {	 
    	$VALUE = undef ; 
#    	warn "[WARN] the method _getPeak_CLUSTER_ID get an undef value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeakFilterPass

	## Description : _setPeakFilterPass
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeakFilterPass ( $VALUE ) ;

=cut

## START of SUB
sub _setPeakFilterPass {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE)  ) {
    	$VALUE =~ s/\s//g ;
    	$self->{_FILTER_PASSED_} = $VALUE ; 
    }
    else {	
#    	warn "[WARN] the method _setPeakFilterPass set an undef or non numerical value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeakFilterPass

	## Description : _getPeakFilterPass
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeakFilterPass () ;

=cut

## START of SUB
sub _getPeakFilterPass {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_FILTER_PASSED_}) ) {
    	$VALUE = $self->{_FILTER_PASSED_} ; 
    }
    else {	 
    	$VALUE = undef ; 
#    	warn "[WARN] the method _getPeakFilterPass get an undef value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB



=item PRIVATE_ONLY _setPeak_RELATIVE_INTENSITY_100

	## Description : _setPeak_RELATIVE_INTENSITY_100
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_RELATIVE_INTENSITY_100 ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_RELATIVE_INTENSITY_100 {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ( ($VALUE > 0) )  ) {
    	$VALUE =~ s/\s//g ;
    	$self->{_RELATIVE_INTENSITY_100_} = $VALUE ; 
    }
    else {	
#    	warn "[WARN] the method _setPeak_RELATIVE_INTENSITY_100 set an undef value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_RELATIVE_INTENSITY_100

	## Description : _getPeak_RELATIVE_INTENSITY_100
	## Input : void
	## Output : $MESURED_MONOISOTOPIC_MASS
	## Usage : my ( $MESURED_MONOISOTOPIC_MASS ) = _getPeak_RELATIVE_INTENSITY_100 () ;

=cut

## START of SUB
sub _getPeak_RELATIVE_INTENSITY_100 {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( $self->{_RELATIVE_INTENSITY_100_} ) {
    	 $VALUE = $self->{_RELATIVE_INTENSITY_100_} if ( (defined $self->{_RELATIVE_INTENSITY_100_}) and ( $self->{_RELATIVE_INTENSITY_100_} > 0 ) ) ;
    }
    else {	 
    	$VALUE = undef ; 
#    	warn "[WARN] the method _getPeak_RELATIVE_INTENSITY_100 get an undef value\n" ; 
    }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_RELATIVE_INTENSITY_999

	## Description : _setPeak_RELATIVE_INTENSITY_999
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_RELATIVE_INTENSITY_999 ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_RELATIVE_INTENSITY_999 {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ( ($VALUE > 0) )  ) {
    	$VALUE =~ s/\s//g ;
    	$self->{_RELATIVE_INTENSITY_999_} = $VALUE ; 
    }
    else {	
#    	warn "[WARN] the method _setPeak_RELATIVE_INTENSITY_999 set an undef value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_RELATIVE_INTENSITY_999

	## Description : _getPeak_RELATIVE_INTENSITY_999
	## Input : void
	## Output : $MESURED_MONOISOTOPIC_MASS
	## Usage : my ( $MESURED_MONOISOTOPIC_MASS ) = _getPeak_RELATIVE_INTENSITY_999 () ;

=cut

## START of SUB
sub _getPeak_RELATIVE_INTENSITY_999 {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( $self->{_RELATIVE_INTENSITY_999_} ) {
    	 $VALUE = $self->{_RELATIVE_INTENSITY_999_} if ( (defined $self->{_RELATIVE_INTENSITY_999_}) and ( $self->{_RELATIVE_INTENSITY_999_} > 0 ) ) ;
    }
    else {	 
    	$VALUE = undef ; 
#    	warn "[WARN] the method _getPeak_RELATIVE_INTENSITY_999 get an undef value\n" ; 
    }
    
    return ( $VALUE ) ;
}
### END of SUB


=item PRIVATE_ONLY _setPeak_INTENSITY

	## Description : _setPeak_INTENSITY
	## Input : $INTENSITY
	## Output : TRUE
	## Usage : _setPeak_INTENSITY ( $INTENSITY ) ;

=cut

## START of SUB
sub _setPeak_INTENSITY {
    ## Retrieve Values
    my $self = shift ;
    my ( $INTENSITY ) = @_;
    
    if ( (defined $INTENSITY) and ( ($INTENSITY > 0) )  ) {
    	$INTENSITY =~ s/\s//g ;
    	$self->{_INTENSITY_} = $INTENSITY ; 
    }
    else {	
#    	warn "[WARN] the method _setPeak_INTENSITY set an undef value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_INTENSITY

	## Description : _getPeak_INTENSITY
	## Input : void
	## Output : $MESURED_MONOISOTOPIC_MASS
	## Usage : my ( $MESURED_MONOISOTOPIC_MASS ) = _getPeak_INTENSITY () ;

=cut

## START of SUB
sub _getPeak_INTENSITY {
    ## Retrieve Values
    my $self = shift ;
    
    my $INTENSITY = undef ;
    
    if ( $self->{_INTENSITY_} ) {
    	 $INTENSITY = $self->{_INTENSITY_} if ( (defined $self->{_INTENSITY_}) and ( $self->{_INTENSITY_} > 0 ) ) ;
    }
    else {	 
    	$INTENSITY = undef ; 
#    	warn "[WARN] the method _getPeak_INTENSITY get an undef value\n" ; 
    }
    return ( $INTENSITY ) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_IN_NEG_MODE

	## Description : _setANNOTATION_IN_NEG_MODE
	## Input : $ANNOTATION_IN_NEG_MODE
	## Output : TRUE
	## Usage : _setANNOTATION_IN_NEG_MODE ( $ANNOTATION_IN_NEG_MODE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_IN_NEG_MODE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_IN_NEG_MODE ) = @_;
    
    if ( (defined $ANNOTATION_IN_NEG_MODE) and ($ANNOTATION_IN_NEG_MODE ne '')  ) {	$self->{_ANNOTATION_IN_NEG_MODE_} = $ANNOTATION_IN_NEG_MODE ; }
    else {
    	$self->{_ANNOTATION_IN_NEG_MODE_} = undef ;
#    	warn "[WARN] the method _setCOMPUTED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_IN_NEG_MODE

	## Description : _getPeak_ANNOTATION_IN_NEG_MODE
	## Input : void
	## Output : $ANNOTATION_IN_NEG_MODE
	## Usage : my ( $ANNOTATION_IN_NEG_MODE ) = _getPeak_ANNOTATION_IN_NEG_MODE () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_IN_NEG_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_IN_NEG_MODE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IN_NEG_MODE_}) and ( $self->{_ANNOTATION_IN_NEG_MODE_} ne '' ) ) {	$ANNOTATION_IN_NEG_MODE = $self->{_ANNOTATION_IN_NEG_MODE_} ; }
#    else {	 $ANNOTATION_IN_NEG_MODE = 0 ; warn "[WARN] the method _getPeak_ANNOTATION_IN_NEG_MODE can't _getPeak a undef or null string value\n" ; }
    
    return ( $ANNOTATION_IN_NEG_MODE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_DA_ERROR

	## Description : _setANNOTATION_DA_ERROR
	## Input : $MMU_ERROR
	## Output : TRUE
	## Usage : _setANNOTATION_DA_ERROR ( $MMU_ERROR ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_DA_ERROR {
    ## Retrieve Values
    my $self = shift ;
    my ( $MMU_ERROR ) = @_;
    
    if ( (defined $MMU_ERROR) and ($MMU_ERROR ne '')  ) {	$self->{_MMU_ERROR_} = $MMU_ERROR ; }
    else {
    	$self->{_MMU_ERROR_} = 0 ;
#    	warn "[WARN] the method _setANNOTATION_DA_ERROR can't set any undef or non numerical value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_PPM_ERROR

	## Description : _setANNOTATION_PPM_ERROR
	## Input : $PPM_ERROR
	## Output : TRUE
	## Usage : _setANNOTATION_PPM_ERROR ( $PPM_ERROR ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_PPM_ERROR {
    ## Retrieve Values
    my $self = shift ;
    my ( $PPM_ERROR ) = @_;
    
    if ( (defined $PPM_ERROR) and ($PPM_ERROR ne '')  ) {	$self->{_PPM_ERROR_} = $PPM_ERROR ; }
    else {	
    	$self->{_PPM_ERROR_} = undef ;
#    	warn "[WARN] the method _setANNOTATION_PPM_ERROR is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_IN_NEG_MODE

	## Description : _setANNOTATION_IN_NEG_MODE
	## Input : $ANNOTATION_IN_POS_MODE
	## Output : TRUE
	## Usage : _setANNOTATION_IN_POS_MODE ( $ANNOTATION_IN_POS_MODE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_IN_POS_MODE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_IN_POS_MODE ) = @_;
    
    if ( (defined $ANNOTATION_IN_POS_MODE) and ($ANNOTATION_IN_POS_MODE ne '')  ) {	$self->{_ANNOTATION_IN_POS_MODE_} = $ANNOTATION_IN_POS_MODE ; }
    else {	
    	$self->{_ANNOTATION_IN_POS_MODE_} = undef ;
#    	warn "[WARN] the method _setANNOTATION_IN_POS_MODE can't set any undef or non numerical value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_IN_POS_MODE

	## Description : _getPeak_ANNOTATION_IN_POS_MODE
	## Input : void
	## Output : $ANNOTATION_IN_POS_MODE
	## Usage : my ( $ANNOTATION_IN_POS_MODE ) = _getPeak_ANNOTATION_IN_POS_MODE () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_IN_POS_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_IN_POS_MODE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IN_POS_MODE_}) and ( $self->{_ANNOTATION_IN_POS_MODE_} ne '' )  ) {	$ANNOTATION_IN_POS_MODE = $self->{_ANNOTATION_IN_POS_MODE_} ; }
#    else {	 $ANNOTATION_IN_POS_MODE = 0 ; warn "[WARN] the method _getPeak_ANNOTATION_IN_POS_MODE can't _getPeak a undef or null string value\n" ; }
    
    return ( $ANNOTATION_IN_POS_MODE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_TYPE

	## Description : _setPeak_ANNOTATION_TYPE
	## Input : $ANNOTATION_TYPE
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_TYPE ( $ANNOTATION_TYPE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_TYPE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_TYPE ) = @_;
    
    if ( (defined $ANNOTATION_TYPE) and ($ANNOTATION_TYPE ne '')  ) {	$self->{_ANNOTATION_TYPE_} = $ANNOTATION_TYPE ; }
    else {	
    	$self->{_ANNOTATION_TYPE_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_TYPE is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATIONS

	## Description : _setPeak_ANNOTATIONS
	## Input : $ANNOTATIONS
	## Output : TRUE
	## Usage : _setPeak_ANNOTATIONS ( $ANNOTATIONS ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATIONS {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATIONS ) = @_;
    
    if ( ( $ANNOTATIONS ) and ( scalar ( @{$ANNOTATIONS} ) > 0 )  ) {	$self->{_ANNOTATIONS_} = $ANNOTATIONS ; }
    else {	
#    	warn "[WARN] the method _setPeak_ANNOTATIONS can't set any undef or empty list value\n" ; 
    	$self->{_ANNOTATIONS_} = [] ;
    }
    
    return (0) ;
}
### END of SUB


=item PRIVATE_ONLY _getPeak_ANNOTATION_TYPE

	## Description : _getPeak_ANNOTATION_TYPE
	## Input : void
	## Output : $ANNOTATION_TYPE
	## Usage : my ( $TYPE ) = _getPeak_ANNOTATION_TYPE () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_TYPE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_TYPE = undef ;
    
    if ( (defined $self->{_ANNOTATION_TYPE_}) and ( $self->{_ANNOTATION_TYPE_} ne '' ) ) {	$ANNOTATION_TYPE = $self->{_ANNOTATION_TYPE_} ; }
    else {	 $ANNOTATION_TYPE = undef ; warn "[WARN] the method _getPeak_ANNOTATION_TYPE can't _getPeak a undef or void string value\n" ; }
    
    return ( $ANNOTATION_TYPE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setANNOTATION_NAME

	## Description : _setANNOTATION_NAME
	## Input : $ANNOTATION_NAME
	## Output : TRUE
	## Usage : _setANNOTATION_NAME ( $ANNOTATION_NAME ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_NAME {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_NAME_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_NAME_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_NAME is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_NAME

	## Description : _getPeak_ANNOTATION_NAME
	## Input : void
	## Output : $ANNOTATION_NAME
	## Usage : my ( $ANNOTATION_NAME ) = _getPeak_ANNOTATION_NAME () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_NAME = undef ;
    
    if ( (defined $self->{_ANNOTATION_NAME_}) and ( $self->{_ANNOTATION_NAME_} ne '' ) ) {	$ANNOTATION_NAME = $self->{_ANNOTATION_NAME_} ; }
    else {	 $ANNOTATION_NAME = undef ; warn "[WARN] the method _getPeak_ANNOTATION_NAME can't _getPeak a undef or void string value\n" ; }
    
    return ( $ANNOTATION_NAME ) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_ID

	## Description : _getPeak_ANNOTATION_ID
	## Input : void
	## Output : $ANNOTATION_ID
	## Usage : my ( $ANNOTATION_ID ) = _getPeak_ANNOTATION_ID () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_ID = undef ;
    
    if ( (defined $self->{_ID_}) and ( $self->{_ID_} ne '' ) ) {	$ANNOTATION_ID = $self->{_ID_} ; }
    else {	 $ANNOTATION_ID = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_ID can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $ANNOTATION_ID ) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_DA_ERROR

	## Description : _getPeak_ANNOTATION_DA_ERROR
	## Input : void
	## Output : $ANNOTATION_DA_ERROR
	## Usage : my ( $ANNOTATION_DA_ERROR ) = _getPeak_ANNOTATION_DA_ERROR () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_DA_ERROR {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_DA_ERROR = undef ;
    
    if ( (defined $self->{_DA_ERROR_}) and ( $self->{_DA_ERROR_} ne '' ) ) {	$ANNOTATION_DA_ERROR = $self->{_DA_ERROR_} ; }
    else {	 $ANNOTATION_DA_ERROR = 0 ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_DA_ERROR can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $ANNOTATION_DA_ERROR ) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_PPM_ERROR

	## Description : _getPeak_ANNOTATION_PPM_ERROR
	## Input : void
	## Output : $ANNOTATION_ID
	## Usage : my ( $ANNOTATION_ID ) = _getPeak_ANNOTATION_PPM_ERROR () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_PPM_ERROR {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_PPM_ERROR = undef ;
    
    if ( (defined $self->{_PPM_ERROR_}) and ( $self->{_PPM_ERROR_} ne '' ) ) {	$ANNOTATION_PPM_ERROR = $self->{_PPM_ERROR_} ; }
    else {	 $ANNOTATION_PPM_ERROR = 0 ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_PPM_ERROR can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $ANNOTATION_PPM_ERROR ) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_SPECTRA_ID

	## Description : _getPeak_ANNOTATION_SPECTRA_ID
	## Input : void
	## Output : $ANNOTATION_ID
	## Usage : my ( $ANNOTATION_ID ) = _getPeak_ANNOTATION_SPECTRA_ID () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_SPECTRA_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_ID = undef ;
    
    if ( (defined $self->{_SPECTRA_ID_}) and ( $self->{_SPECTRA_ID_} ne '' ) ) {	$ANNOTATION_ID = $self->{_SPECTRA_ID_} ; }
    else {	 $ANNOTATION_ID = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_SPECTRA_ID can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $ANNOTATION_ID ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_ID

	## Description : _setPeak_ANNOTATION_ID
	## Input : $ANNOTATION_ID
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_ID ( $ANNOTATION_ID ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_ID {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_ID ) = @_;
    
    if ( (defined $ANNOTATION_ID) and ($ANNOTATION_ID ne '')  ) {	$self->{_ID_} = $ANNOTATION_ID ; }
    else {
    	$self->{_ID_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_ID is set with undef value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_SPECTRA_ID

	## Description : _setPeak_ANNOTATION_SPECTRA_ID
	## Input : $ANNOTATION_ID
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_SPECTRA_ID ( $ANNOTATION_ID ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_SPECTRA_ID {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_ID ) = @_;
    
    if ( (defined $ANNOTATION_ID) and ($ANNOTATION_ID ne '')  ) {	$self->{_SPECTRA_ID_} = $ANNOTATION_ID ; }
    else {	
    	$self->{_SPECTRA_ID_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_SPECTRA_ID is set with undef value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_FORMULA

	## Description : _getPeak_ANNOTATION_FORMULA
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATION_FORMULA () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_FORMULA {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_FORMULA_}) and ( $self->{_ANNOTATION_FORMULA_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_FORMULA_} ; }
    else {	 $VALUE = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_FORMULA can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_FORMULA

	## Description : _setPeak_ANNOTATION_FORMULA
	## Input : $ANNOTATION_FORMULA
	## Output : TRUE
	## Usage : $self->_setPeak_ANNOTATION_FORMULA ( $ANNOTATION_ID ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_FORMULA {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_FORMULA_} = $VALUE ; }
    else {	
    	$self->{_ANNOTATION_FORMULA_} = undef ;
#    	warn "[WARN] the method _setANNOTATION_FORMULA is set with undef value\n" ; 
    }
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_ONLY_IN

	## Description : _setPeak_ANNOTATION_ONLY_IN
	## Input : $ANNOTATION_ONLY_IN
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_ONLY_IN ( $ANNOTATION_ONLY_IN ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_ONLY_IN {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_ONLY_IN ) = @_;
    
    if ( (defined $ANNOTATION_ONLY_IN) and ( ($ANNOTATION_ONLY_IN eq 'POS' ) or ($ANNOTATION_ONLY_IN eq 'NEG') )  ) {	$self->{_ANNOTATION_ONLY_IN_} = $ANNOTATION_ONLY_IN ; }
    else {	
    	$self->{_ANNOTATION_ONLY_IN_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_ONLY_IN is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_SMILES

	## Description : _getPeak_ANNOTATION_SMILES
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATION_SMILES () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_SMILES {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_SMILES_}) and ( $self->{_ANNOTATION_SMILES_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_SMILES_} ; }
    else {	 $VALUE = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_SMILES can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_SMILES

	## Description : _setPeak_ANNOTATION_SMILES
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_SMILES ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_SMILES {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_SMILES_} = $VALUE ; }
    else {	
    	$self->{_ANNOTATION_SMILES_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_SMILES is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_INCHIKEY

	## Description : _getPeak_ANNOTATION_INCHIKEY
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATION_INCHIKEY () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_INCHIKEY {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_INCHIKEY_}) and ( $self->{_ANNOTATION_INCHIKEY_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_INCHIKEY_} ; }
    else {	 $VALUE = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_INCHIKEY can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATIONS

	## Description : _getPeak_ANNOTATIONS
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATIONS () ;

=cut

## START of SUB
sub _getPeak_ANNOTATIONS {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUES = undef ;
    
    if ( ( $self->{_ANNOTATIONS_} ) and ( scalar ($self->{_ANNOTATIONS_}) > 0 ) ) {	$VALUES = $self->{_ANNOTATIONS_} ; }
    else {	 $VALUES = [] ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_SMILES can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUES ) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_SPECTRAL_IDS

	## Description : _getPeak_ANNOTATION_SPECTRAL_IDS
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATION_SPECTRAL_IDS () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_SPECTRAL_IDS {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUES = undef ;
    
    if ( ( $self->{_ANNOTATION_SPECTRAL_IDS_} ) ) {	
    	if ( ( scalar ($self->{_ANNOTATION_SPECTRAL_IDS_}) > 0 ) ) {
    		$VALUES = $self->{_ANNOTATION_SPECTRAL_IDS_} ;
    	}
    	else {
    		warn "[WARN]  _ANNOTATION_SPECTRAL_IDS_ returns a void list\n";
    	}
    }
    else {	 $VALUES = [] ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_SPECTRAL_IDS can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUES ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_SPECTRAL_IDS

	## Description : _setPeak_ANNOTATION_SPECTRAL_IDS
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_SPECTRAL_IDS ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_SPECTRAL_IDS {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {
    	push (@{$self->{_ANNOTATION_SPECTRAL_IDS_}}, $VALUE) ;	
    } 
    else {
    	$self->{_ANNOTATION_SPECTRAL_IDS_} = [] ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_SPECTRAL_IDS is set with empty array\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_INCHIKEY

	## Description : _setPeak_ANNOTATION_INCHIKEY
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_INCHIKEY ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_INCHIKEY {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_INCHIKEY_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_INCHIKEY_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_INCHIKEY is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_IS_A_PRECURSOR

	## Description : _getPeak_ANNOTATION_IS_A_PRECURSOR
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATION_IS_A_PRECURSOR () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_IS_A_PRECURSOR {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IS_A_PRECURSOR_}) and ( $self->{_ANNOTATION_IS_A_PRECURSOR_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_IS_A_PRECURSOR_} ; }
    else {	 $VALUE = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_IS_A_PRECURSOR can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_IS_A_PRECURSOR

	## Description : _setPeak_ANNOTATION_IS_A_PRECURSOR
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_IS_A_PRECURSOR ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_IS_A_PRECURSOR {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_IS_A_PRECURSOR_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_IS_A_PRECURSOR_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_IS_A_PRECURSOR is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB

=item PRIVATE_ONLY _getPeak_ANNOTATION_IS_A_PRECURSOR

	## Description : _getPeak_ANNOTATION_IS_A_PRECURSOR
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = _getPeak_ANNOTATION_IS_A_PRECURSOR () ;

=cut

## START of SUB
sub _getPeak_ANNOTATION_IS_A_METABOLITE {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IS_A_METABOLITE_}) and ( $self->{_ANNOTATION_IS_A_METABOLITE_} ne '' ) ) {	$VALUE = $self->{_ANNOTATION_IS_A_METABOLITE_} ; }
    else {	 $VALUE = undef ; 
    	#warn "[WARN] the method _getPeak_ANNOTATION_IS_A_METABOLITE can't _getPeak a undef or non numerical value\n" ; 
	}
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _setPeak_ANNOTATION_IS_A_METABOLITE

	## Description : _setPeak_ANNOTATION_IS_A_METABOLITE
	## Input : $VALUE
	## Output : TRUE
	## Usage : _setPeak_ANNOTATION_IS_A_METABOLITE ( $VALUE ) ;

=cut

## START of SUB
sub _setPeak_ANNOTATION_IS_A_METABOLITE {
    ## Retrieve Values
    my $self = shift ;
    my ( $VALUE ) = @_;
    
    if ( (defined $VALUE) and ($VALUE ne '')  ) {	$self->{_ANNOTATION_IS_A_METABOLITE_} = $VALUE ; }
    else {
    	$self->{_ANNOTATION_IS_A_METABOLITE_} = undef ;
#    	warn "[WARN] the method _setPeak_ANNOTATION_IS_A_METABOLITE  is set with undef value\n" ; 
	}
    
    return (0) ;
}
### END of SUB



__END__

=back

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inrae.fr> >>

=head1 SEE ALSO

All information about Metabolomics::Banks would be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragnot

=head1 BUGS

Please report any bugs or feature requests to C<bug-Metabolomics-Fragment-Annotation at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Metabolomics-Fragment-Annotation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Banks

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

followed by INRAE PFEM team

Web Site = INRAE PFEM


=cut

1; # End of Metabolomics::Banks
