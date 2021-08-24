package Metabolomics::Banks::MaConDa ;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

use Data::Dumper ;
use Text::CSV ;
use XML::Twig ;
use File::Share ':all'; 
use Carp qw (cluck croak carp) ;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../..";  # use the parent directory
use base qw( Metabolomics::Banks ) ;
use Metabolomics::Utils qw( :all ) ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Banks::MaConDa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	getContaminantsExtensiveFromSource getContaminantsFromSource buildTheoPeakBankFromContaminants extractContaminantTypes extractContaminantInstruments filterContaminantIonMode filterContaminantInstruments filterContaminantInstrumentTypes
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	getContaminantsExtensiveFromSource getContaminantsFromSource buildTheoPeakBankFromContaminants extractContaminantTypes extractContaminantInstruments filterContaminantIonMode filterContaminantInstruments filterContaminantInstrumentTypes
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks::MaConDa - Perl extension for contaminants bank building

=head1 VERSION

Version 0.2 - Adding POD
Version 0.3 - Completing object properties

=cut

our $VERSION = '0.3';



=head1 SYNOPSIS

    use Metabolomics::Banks::MaConDa;

=head1 DESCRIPTION

	Metabolomics::Banks::MaConDa is a full package for Perl allowing to build a generic Perl bank object from MaConDa resource.

=head1 EXPORT

	use Metabolomics::Banks::MaConDa qw( :all ) ;

=head1 PUBLIC METHODS 

=head2 Metabolomics::Banks::MaConDa

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
    
    $self->{_DATABASE_NAME_} = 'MaConDa' ;
    $self->{_DATABASE_VERSION_} = '1.0' ;
    $self->{_DATABASE_TYPE_} = 'METABOLITE' ;
    $self->{_POLARITY_} =  $args->{POLARITY} ;
    $self->{_DATABASE_ENTRIES_NB_} = 'database_entries_nb' ;
    $self->{_DATABASE_URL_} = 'https://maconda.bham.ac.uk/' ;
    $self->{_DATABASE_URL_CARD_} = 'https://www.maconda.bham.ac.uk/contaminant.php?id=' ;
    $self->{_DATABASE_DOI_} = 'database_doi' ;
    $self->{_CONTAMINANTS_} = [] ;
    ## _DATABASE_ENTRIES_
    bless($self) ;
    return $self ;
}
### END of SUB

=item __refContaminant__

	## Description : set a new contaminant object
	## Input : NA	
	## Output : $refContaminant
	## Usage : my ( $refContaminant ) = __refContaminant__() ;

=cut

## START of SUB
sub __refContaminant__ {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_ID_} = 'id' ;
    $self->{_NAME_} = 'name' ;
    $self->{_FORMULA_} = 'formula' ;
    $self->{_EXACT_MASS_} = 'exact_mass' ;
    $self->{_STD_INCHI_} = 'std_inchi' ;
    $self->{_STD_INCHI_KEY_} = 'std_inchi_key' ;
    $self->{_PUBCHEM_CID_} = 'pubchem_cid' ;
    $self->{_TYPE_OF_CONTAMINANT_} = 'type_of_contaminant' ;

    return $self ;
}
### END of SUB

=item __refContaminantExtensive__

	## Description : set a new contaminant object in extensive version
	## Input : NA	
	## Output : $refContaminantExtensive
	## Usage : my ( $refContaminantExtensive ) = __refContaminantExtensive__() ;

=cut

## START of SUB
sub __refContaminantExtensive__ {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    ## TODO... surcharge de l'objet
    
    $self->{_REFERENCE_} = 'reference' ;
    $self->{_ION_MODE_} = 'ion_mode' ;
    $self->{_MZ_} = 'mz' ;
    $self->{_EXACT_ADDUCT_MASS_} = 'exact_adduct_mass' ;
    $self->{_ION_FORM_} = 'ion_form' ;
    $self->{_INSTRUMENT_TYPE_} = 'instrument_type' ;
    $self->{_INSTRUMENT_} = 'instrument' ;
    $self->{_CHROMATOGRAPHY_} = 'chromatography' ;
    $self->{_ION_SOURCE_TYPE_} = 'ion_source_type' ;

    return $self ;
}
### END of SUB

=item getContaminantsFromSource

	## Description : get all contaminants information from the MaConDa resources v01
	## Input : $source
	## Output : $oBank
	## Usage : my ( $oBank ) = getContaminantsFromSource ( $source ) ;

=cut

## START of SUB
sub getContaminantsFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $source ) = @_;

    my $twig = undef ;
    my ($currentId, $currentName, $currentInchi, $currentInchiKey, $currentFormula, $currentExactMass, $currentPubchemCid, $currentContaminType) = ( undef, undef, undef, undef, undef, undef, undef, undef ) ;
    
    if (!defined $source) {

    	$source = dist_file('Metabolomics-Fragment-Annotation', 'MaConDa__v1_0.xml');
    	if (-e $source) {
    		print "loading $source...\n" ;
    	}
    	else {
    		croak "The source file ($source) does not exist at this path\n" ;
    	}
    }


    if ( (defined $source) and (-e $source) ) {
    	
    	$twig = XML::Twig->nparse_ppe(
						twig_handlers => { 
							# contaminant_id
							'contaminant' => sub {
								
								if ( (defined $currentId) ) {
									my $oContaminant = $self->__refContaminant__() ;
									$oContaminant->_setContaminantID($currentId) ;
									$oContaminant->_setContaminantNAME($currentName) ;
									$oContaminant->_setContaminantEXACT_MASS($currentExactMass) ;
									$oContaminant->_setContaminantFORMULA($currentFormula) ;
									$oContaminant->_setContaminantSTD_INCHI($currentInchi) ;
									$oContaminant->_setContaminantSTD_INCHI_KEY($currentInchiKey) ;
									$oContaminant->_setContaminantPUBCHEM_CID($currentPubchemCid) ;
									$oContaminant->_setContaminantTYPE_OF_CONTAMINANT($currentContaminType) ;
									
									$self->_addContaminant($oContaminant) ;
									$currentId = undef ;
								}

							} , ## END SUB contaminant_id
							'contaminant/id' => sub {
								$currentId = $_ -> text_only ;
							},
							'contaminant/name' => sub {
								$currentName = $_ -> text_only ;
							},
							'contaminant/formula' => sub {
								$currentFormula = $_ -> text_only ;
							},
							'contaminant/exact_mass' => sub {
								$currentExactMass = $_ -> text_only ;
							},
							'contaminant/std_inchi' => sub {
								$currentInchi = $_ -> text_only ;
							},
							'contaminant/std_inchi_key' => sub {
								$currentInchiKey = $_ -> text_only ;
							},
							'contaminant/pubchem_cid' => sub {
								$currentPubchemCid = $_ -> text_only ;
							},
							'contaminant/type_of_contaminant' => sub {
								$currentContaminType = $_ -> text_only ;
							},
						}, 
						pretty_print => 'indented', 
						error_context => 1, $source
		);
						
#		$twig->print;
		$twig->purge ;
    }
    else{
    	croak "The source file does not exist ($source) or is not defined\n" ;
    }
    return ($self) ;
}
### END of SUB


=item getContaminantsExtensiveFromSource

	## Description : get all contaminants information from the MaConDa extensive resources v01
	## Input : $source
	## Output : $oBank
	## Usage : my ( $oBank ) = getContaminantsFromSource ( $source ) ;

=cut

## START of SUB
sub getContaminantsExtensiveFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $source ) = @_;

    my $twig = undef ;
    my ($currentId, $currentName, $currentInchi, $currentInchiKey, $currentFormula, $currentExactMass, $currentPubchemCid, $currentContaminType) = ( undef, undef, undef, undef, undef, undef, undef, undef ) ;
    
    my ($currentChromatography, $currentExactAdductMass, $currentInstrument, $currentInstrumentType, $currentIonForm, $currentIonMode, $currentIonSourceType, $currentReference, $currentMz) = ( undef, undef, undef, undef, undef, undef, undef, undef, undef ) ;    
    
    if (!defined $source) {

    	$source = dist_file('Metabolomics-Fragment-Annotation', 'MaConDa__v1_0__extensive.xml');
    	if (-e $source) {
    		print "loading $source...\n" ;
    	}
    	else {
    		croak "The source file ($source) does not exist at this path\n" ;
    	}
    }
    
    if ( (defined $source) and (-e $source) ) {
    	
    	$twig = XML::Twig->nparse_ppe(
						twig_handlers => { 
							# contaminant_id
							'contaminant' => sub {
								
								if ( (defined $currentId) ) {
									my $oContaminant = $self->__refContaminant__() ;
									$self->__refContaminantExtensive__() ; ## object overloading
									$oContaminant->_setContaminantID($currentId) ;
									$oContaminant->_setContaminantNAME($currentName) ;
									$oContaminant->_setContaminantEXACT_MASS($currentExactMass) ;
									$oContaminant->_setContaminantFORMULA($currentFormula) ;
									$oContaminant->_setContaminantSTD_INCHI($currentInchi) ;
									$oContaminant->_setContaminantSTD_INCHI_KEY($currentInchiKey) ;
									$oContaminant->_setContaminantPUBCHEM_CID($currentPubchemCid) ;
									$oContaminant->_setContaminantTYPE_OF_CONTAMINANT($currentContaminType) ;
									
									$oContaminant->_setContaminantExtCHROMATOGRAPHY($currentChromatography) ;
									$oContaminant->_setContaminantExtEXACT_ADDUCT_MASS($currentExactAdductMass) ;
									$oContaminant->_setContaminantExtINSTRUMENT($currentInstrument) ;
									$oContaminant->_setContaminantExtINSTRUMENT_TYPE($currentInstrumentType) ;
									$oContaminant->_setContaminantExtION_FORM($currentIonForm) ;
									$oContaminant->_setContaminantExtION_MODE($currentIonMode) ;
									$oContaminant->_setContaminantExtION_SOURCE_TYPE($currentIonSourceType) ;
									$oContaminant->_setContaminantExtMZ($currentMz) ;
									$oContaminant->_setContaminantExtREFERENCE($currentReference) ;
									
									$self->_addContaminant($oContaminant) ;
									$currentId = undef ;
								}

							} , ## END SUB contaminant_id
							'contaminant/id' => sub { $currentId = $_ -> text_only ; },
							'contaminant/name' => sub { $currentName = $_ -> text_only ; },
							'contaminant/formula' => sub { $currentFormula = $_ -> text_only ; },
							'contaminant/exact_mass' => sub { $currentExactMass = $_ -> text_only ; },
							'contaminant/std_inchi' => sub { $currentInchi = $_ -> text_only ; },
							'contaminant/std_inchi_key' => sub { $currentInchiKey = $_ -> text_only ; },
							'contaminant/pubchem_cid' => sub { $currentPubchemCid = $_ -> text_only ; },
							'contaminant/type_of_contaminant' => sub { $currentContaminType = $_ -> text_only ; },
							
							## extensive part:
							'contaminant/reference' => sub { $currentReference = $_ -> text_only ; },
							'contaminant/ion_mode' => sub { $currentIonMode = $_ -> text_only ; },
							'contaminant/mz' => sub { $currentMz = $_ -> text_only ; },
							'contaminant/exact_adduct_mass' => sub { $currentExactAdductMass = $_ -> text_only ; },
							'contaminant/ion_form' => sub { $currentIonForm = $_ -> text_only ; },
							'contaminant/instrument_type' => sub { $currentInstrumentType = $_ -> text_only ; },
							'contaminant/instrument' => sub { $currentInstrument = $_ -> text_only ; },
							'contaminant/chromatography' => sub { $currentChromatography = $_ -> text_only ; },
							'contaminant/ion_source_type' => sub { $currentIonSourceType = $_ -> text_only ; },
							
							
						}, 
						pretty_print => 'indented', 
						error_context => 1, $source
		);
						
#		$twig->print;
		$twig->purge ;
    }
    else{
    	croak "The source file does not exist ($source) or is not defined\n" ;
    }
    return ($self) ;
}
### END of SUB

=item buildTheoPeakBankFromContaminants

	## Description : building a bank integrating each potential ion from contaminants
	## Input : $refBank, $oContaminants, $queryMode
	## Output : $ionBank
	## Usage : my ( $ionBank ) = buildTheoPeakBankFromContaminants ( $refBank, $oContaminants, $queryMode ) ;

=cut

## START of SUB
sub buildTheoPeakBankFromContaminants {
    ## Retrieve Values
    my $self = shift ;
    
    my ( $queryMode ) = @_;
    
    my $contaminants = $self->_getContaminants() ;
    
    
    foreach my $oContaminant (@{$contaminants}) {
    	## map contaminant object with peak object
    	
#    	print Dumper $oContaminant ;
    	
    	my $oPeak = Metabolomics::Banks->__refPeak__() ;
    	my $mass = undef ;
    	
    	## should be ION | NEUTRAL -> getting different source of data in mapping
    	if ( (defined $queryMode) and ($queryMode eq "NEUTRAL") ) {
    		$mass = $oContaminant->_getContaminantEXACT_MASS() ;
    		$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ($mass) if ( defined $mass ) ;
    	}
    	elsif ( (defined $queryMode) and ($queryMode eq "ION") ) {
    		$mass = $oContaminant->_getContaminantExtEXACT_ADDUCT_MASS() ;
    		
    		## in case found no value for the adduct mass -> get the MZ value...
    		if ( !defined $mass ) {
    			$mass = $oContaminant->_getContaminantExtMZ() ;
    			$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ($mass) if ( defined $mass ) ;
    		}
    		else {
    			$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ($mass) if ( defined $mass ) ;
    		}	
    	}
    	else {
    		croak "This mode does not exist ($queryMode)\n" ;
    	}
    	# _ION_MODE_ shoulbe NEG | POS and is linked to _ION_FORM_ and mapping ANNOTATION
    	my $ionMode = $oContaminant->_getContaminantExtION_MODE() ;
    	my $ionForm = $oContaminant->_getContaminantExtION_FORM() ;
    	
    	if ( (defined $ionMode ) and ( $ionMode eq 'NEG')   ){	$oPeak->_setPeak_ANNOTATION_IN_NEG_MODE($ionForm) ; }
    	elsif ( (defined $ionMode ) and ( $ionMode eq 'POS') ){ $oPeak->_setPeak_ANNOTATION_IN_POS_MODE($ionForm) ; }
    	
    	# _TYPE_OF_CONTAMINANT_
    	my $type = $oContaminant->_getContaminantExtTYPE_OF_CONTAMINANT() ;
    	$oPeak->_setPeak_ANNOTATION_TYPE ( $type )  if ( defined $type ) ; 
    	
    	# _NAME_
    	my $name = $oContaminant->_getContaminantNAME() ;
	    $oPeak->_setPeak_ANNOTATION_NAME ( $name )  if ( defined $name ) ;
	    
	    # _ID_
    	my $id = $oContaminant->_getContaminantID() ;
	    $oPeak->_setPeak_ANNOTATION_ID ( $id )  if ( defined $id ) ;
    	
    	## If every run -> push the well completed object !
    	if ( (defined $mass) and ( $mass > 0 ) ) { $self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ; }
    }
}
### END of SUB


=item extractContaminantTypes

	## Description : extract contaminant types listing from contaminants object
	## Input : $oContaminants
	## Output : $contaminantTypes
	## Usage : my ( $contaminantTypes ) = extractContaminantTypes ( $oContaminants ) ;

=cut

## START of SUB
sub extractContaminantTypes {
    ## Retrieve Values
    my $self = shift ;

    my ( %contaminantTypes ) = ( () ) ;
    
	my $contaminants = $self->_getContaminants();
#    print Dumper $contaminants ;
    
    if ( (defined $contaminants )  ) {
    	foreach my $contaminant ( @{$contaminants} ) {
    		my $type = $contaminant->_getContaminantExtTYPE_OF_CONTAMINANT() ;
    		
    		if (defined $type) {
    			$contaminantTypes{$type} += 1 ; 
    		}
    	}
    }
    else{
    	croak "The contaminants object is not defined or is empty\n" ;
    }
    
    return (\%contaminantTypes) ;
}
### END of SUB

=item extractContaminantInstruments

	## Description : extract instruments listing from contaminants object
	## Input : $oContaminants
	## Output : $contaminantInstruments
	## Usage : my ( $contaminantInstruments ) = extractContaminantInstruments ( $oContaminants ) ;

=cut

## START of SUB
sub extractContaminantInstruments {
    ## Retrieve Values
    my $self = shift ;
    my ( %contaminantInstruments ) = ( () ) ;
    
#    print Dumper $oContaminants ;
	my $contaminants = $self->_getContaminants();
    
    if ( (defined $contaminants )  ) {
    	foreach my $contaminant ( @{$contaminants} ) {
    		my $instrument = $contaminant->_getContaminantExtINSTRUMENTS() ;
    		
    		if (defined $instrument) {
    			$contaminantInstruments{$instrument} += 1 ; 
    		}
    	}
    }
    else{
    	croak "The contaminants object is not defined or is empty\n" ;
    }
    
    return (\%contaminantInstruments) ;
}
### END of SUB

=item extractContaminantInstrumentTypes

	## Description : extract instrument types listing from contaminants object
	## Input : $oContaminants
	## Output : $contaminantInstrumentTypes
	## Usage : my ( $contaminantInstrumentTypes ) = extractContaminantInstrumentTypes ( $oContaminants ) ;

=cut

## START of SUB
sub extractContaminantInstrumentTypes {
    ## Retrieve Values
    my $self = shift ;
    my ( %contaminantInstrumentTypes ) = ( () ) ;
    
#    print Dumper $oContaminants ;
	my $contaminants = $self->_getContaminants();
    
    if ( (defined $contaminants )  ) {
    	foreach my $contaminant ( @{$contaminants} ) {
    		my $instrument = $contaminant->_getContaminantExtINSTRUMENT_TYPES() ;
    		
    		if (defined $instrument) {
    			$contaminantInstrumentTypes{$instrument} += 1 ; 
    		}
    	}
    }
    else{
    	croak "The contaminants object is not defined or is empty\n" ;
    }
    
    return (\%contaminantInstrumentTypes) ;
}
### END of SUB

=item filterContaminantIonMode

	## Description : filtering contaminants by their ion mode (POS|NEG|BOTH)
	## Input : $oBank, $ionMode
	## Output : $oFilteredBank
	## Usage : my ( $oFilteredBank ) = filterContaminantIonMode ( $oBank, $ionMode ) ;

=cut

## START of SUB
sub filterContaminantIonMode {
    ## Retrieve Values
    my $self = shift ;
    my ( $ionMode ) = @_;
    my ( $oFilteredBank ) = ( undef ) ;
    
    if ( (defined $ionMode )  ) {
    	
    	my $contaminants = $self->_getContaminants();
    	
    	$ionMode = uc ($ionMode) ; ## UPPERCASE
    	
    	if  ( ( $ionMode eq 'BOTH' )  ) {
    		$oFilteredBank = $self ; ## - - none filter - -
    	}
    	else {
    		my $filter = undef ;
    		$oFilteredBank = Metabolomics::Banks::MaConDa->new( {POLARITY => $ionMode} ) ;
    		
    		if   	( ( $ionMode eq 'POSITIVE' )  ) { $filter = 'POS' ; }
	    	elsif   ( ( $ionMode eq 'NEGATIVE' )  ) { $filter = 'NEG' ; }
	    	elsif   	( ( $ionMode eq 'POS' )  ) { $filter = 'POS' ; }
	    	elsif   	( ( $ionMode eq 'NEG' )  ) { $filter = 'NEG' ; }
	    	elsif   	( ( $ionMode eq 'POSITIF' )  ) { $filter = 'POS' ; }
	    	elsif   	( ( $ionMode eq 'NEGATIF' )  ) { $filter = 'NEG' ; }
	    	
	    	else { croak "This ion mode is unknown: $ionMode\n" ; }
    		
    		foreach my $oContaminant ( @{$contaminants} ) {
    			
    			my $contaminantIonMode = $oContaminant->_getContaminantExtION_MODE() ;
#    			print "mode is... $contaminantIonMode\n" ;
    			if ( (defined $contaminantIonMode ) and ( $contaminantIonMode eq $filter ) ) {
    				
    				my $selectedContaminant = $oContaminant ;
    				
    				$oFilteredBank->_addContaminant($selectedContaminant) ;
    			}
    			else {
    				next ;
    			}
    		} ## END FOREACH
    	}
    }
    else{
    	croak "The ion mode object is not defined\n" ;
    }
    return ($oFilteredBank) ;
}
### END of SUB

=item filterContaminantInstruments

	## Description : filtering contaminants by their instrument (array)
	## Input : $oBank, $instruments
	## Output : $oFilteredBank, $totalEntryNum, $fiteredEntryNum
	## Usage : my ( $oFilteredBank ) = filterContaminantInstruments ( $oBank, $instruments ) ;

=cut

## START of SUB
sub filterContaminantInstruments {
    ## Retrieve Values
    my $self = shift ;
    my ( $instruments ) = @_;
    my ( $oFilteredBank ) = ( undef ) ;
    my ($totalEntryNum, $fiteredEntryNum) = (0, 0) ;
    
#    print Dumper $instruments ;
    
    if ( (defined $instruments )  ) {
    	
    	my $contaminants = $self->_getContaminants();
    	
    	if (( scalar (@{$instruments}) == 1 ) and $instruments->[0] eq 'ALL'  ) {
    		$oFilteredBank = $self ; ## - - none filter - -
    		$totalEntryNum = $fiteredEntryNum = scalar ( @{$contaminants} ) ;
    	}
    	elsif (( scalar (@{$instruments}) >= 1 ) ) {
    		
    		$oFilteredBank = Metabolomics::Banks::MaConDa->new() ;
    		
    		foreach my $oContaminant ( @{$contaminants} ) {
    			
    			$totalEntryNum ++ ;
    			
    			my $contaminantInstrument = $oContaminant->_getContaminantExtINSTRUMENTS() ;
    			
    			foreach my $instrument (@{$instruments}) {
    				if ( (defined $contaminantInstrument ) and ( $contaminantInstrument eq $instrument ) ) {
    					my $selectedContaminant = $oContaminant ;
    					$oFilteredBank->_addContaminant($selectedContaminant) ;
    					$fiteredEntryNum++ ;
    					last ;
    				}
    				else {
		    			next ;
		    		}
    			}
    		}
    	}
    }
    else{
    	croak "The instrument array ref is not defined\n" ;
    }
    return ($oFilteredBank, $totalEntryNum, $fiteredEntryNum) ;
}
### END of SUB

=item filterContaminantInstrumentTypes

	## Description : filtering contaminants by their instrument types (array)
	## Input : $oBank, $instrumentTypes
	## Output : $oFilteredBank
	## Usage : my ( $oFilteredBank ) = filterContaminantInstrumentTypes ( $oBank, $instrumentTypes ) ;

=cut

## START of SUB
sub filterContaminantInstrumentTypes {
    ## Retrieve Values
    my $self = shift ;
    my ( $instrumentTypes ) = @_;
    my ( $oFilteredBank ) = ( undef ) ;
    my ($totalEntryNum, $fiteredEntryNum) = (0, 0) ;
    
    if ( (defined $instrumentTypes )  ) {
    	
    	my $contaminants = $self->_getContaminants();
    	
    	if (( scalar (@{$instrumentTypes}) == 1 ) and $instrumentTypes->[0] eq 'ALL'  ) {
    		$oFilteredBank = $self ; ## - - none filter - -
    		$totalEntryNum = $fiteredEntryNum = scalar ( @{$contaminants} ) ;
    	}
    	elsif (( scalar (@{$instrumentTypes}) >= 1 ) ) {
    		
    		$oFilteredBank = Metabolomics::Banks::MaConDa->new() ;
    		
    		foreach my $oContaminant ( @{$contaminants} ) {
    			
    			$totalEntryNum ++ ;
    			
    			my $contaminantInstrument = $oContaminant->_getContaminantExtINSTRUMENT_TYPES() ;
    			
    			foreach my $instrumentType (@{$instrumentTypes}) {
    				if ( (defined $contaminantInstrument ) and ( $contaminantInstrument eq $instrumentType ) ) {
    					my $selectedContaminant = $oContaminant ;
    					$oFilteredBank->_addContaminant($selectedContaminant) ;
    					$fiteredEntryNum++ ;
    					last ;
    				}
    				else {
		    			next ;
		    		}
    			}
    		}
    	}
    }
    else{
    	croak "The instrument types array ref is not defined\n" ;
    }
    return ($oFilteredBank, $totalEntryNum, $fiteredEntryNum) ;
}
### END of SUB



## * * * * * * * * * *  * * * * * * * * * *  * * * * * * * * * * getter/setter  * * * * * * * * * *  * * * * * * * * * *  * * * * * * * * * * ##


=item _setContaminantExtREFERENCE

	## Description : _setContaminantExtREFERENCE
	## Input : $REFERENCE
	## Output : TRUE
	## Usage : _setContaminantExtREFERENCE ( $ION_FORM ) ;

=cut

## START of SUB
sub _setContaminantExtREFERENCE {
    ## Retrieve Values
    my $self = shift ;
    my ( $REFERENCE ) = @_;
    
    if ( (defined $REFERENCE) and ( $REFERENCE ne '' )  ) {	
    	$REFERENCE =~ s/\n//g ; # cleaning \n
    	$REFERENCE =~ s/^\s+// ; # trim left
    	$REFERENCE =~ s/\s+$// ; # trim right
    	$self->{_REFERENCE_} = $REFERENCE ; }
    else {	$self->{_REFERENCE_} = undef }
    
    return (0) ;
}
### END of SUB

=item _getContaminantExtION_MODE

	## Description : _getContaminantExtION_MODE
	## Input : void
	## Output : $ION_MODE
	## Usage : my ( $ION_MODE ) = _getContaminantExtION_MODE () ;

=cut

## START of SUB
sub _getContaminantExtION_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ION_MODE = undef ;
    
    if ( (defined $self->{_ION_MODE_}) and ( $self->{_ION_MODE_} ne '' ) ) {	$ION_MODE = $self->{_ION_MODE_} ; }
    else {	 $ION_MODE = 'unknown' ; warn "[WARN] the method _getContaminantExtION_MODE return unknown if getting a undef value\n" ; }
    
    return ( $ION_MODE ) ;
}
### END of SUB

=item _setContaminantExtION_MODE

	## Description : _setContaminantExtION_MODE
	## Input : $ION_MODE
	## Output : TRUE
	## Usage : _setContaminantExtION_MODE ( $ION_FORM ) ;

=cut

## START of SUB
sub _setContaminantExtION_MODE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ION_MODE ) = @_;
    
    if ( (defined $ION_MODE) and ( $ION_MODE ne '' )  ) {	
    	$ION_MODE =~ s/\n//g ; # cleaning \n
    	$ION_MODE =~ s/^\s+// ; # trim left
    	$ION_MODE =~ s/\s+$// ; # trim right
    	$self->{_ION_MODE_} = $ION_MODE ; }
    else {	$self->{_ION_MODE_} = undef }
    
    return (0) ;
}
### END of SUB

=item _setContaminantExtEXACT_ADDUCT_MASS

	## Description : _setContaminantExtEXACT_ADDUCT_MASS
	## Input : $EXACT_ADDUCT_MASS
	## Output : TRUE
	## Usage : _setContaminantExtEXACT_ADDUCT_MASS ( $ION_FORM ) ;

=cut

## START of SUB
sub _setContaminantExtEXACT_ADDUCT_MASS {
    ## Retrieve Values
    my $self = shift ;
    my ( $EXACT_ADDUCT_MASS ) = @_;
    
    if ( (defined $EXACT_ADDUCT_MASS) and ( $EXACT_ADDUCT_MASS > 0 )  ) {	
    	$EXACT_ADDUCT_MASS =~ s/\n//g ; # cleaning \n
    	$EXACT_ADDUCT_MASS =~ s/^\s+// ; # trim left
    	$EXACT_ADDUCT_MASS =~ s/\s+$// ; # trim right
    	$self->{_EXACT_ADDUCT_MASS_} = $EXACT_ADDUCT_MASS ; }
    else {	$self->{_EXACT_ADDUCT_MASS_} = undef }
    
    return (0) ;
}
### END of SUB

=item _getContaminantExtEXACT_ADDUCT_MASS

	## Description : _getContaminantExtEXACT_ADDUCT_MASS
	## Input : void
	## Output : $EXACT_ADDUCT_MASS
	## Usage : my ( $EXACT_ADDUCT_MASS ) = _getContaminantExtEXACT_ADDUCT_MASS () ;

=cut

## START of SUB
sub _getContaminantExtEXACT_ADDUCT_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $EXACT_ADDUCT_MASS = undef ;
    
    if ( (defined $self->{_EXACT_ADDUCT_MASS_}) and ( $self->{_EXACT_ADDUCT_MASS_} ne '' ) ) {	$EXACT_ADDUCT_MASS = $self->{_EXACT_ADDUCT_MASS_} ; }
    else {	 $EXACT_ADDUCT_MASS = undef ; warn "[WARN] the method _getContaminantExtEXACT_ADDUCT_MASS return undef when no value is available\n" ; }
    
    return ( $EXACT_ADDUCT_MASS ) ;
}
### END of SUB

=item _getContaminantExtION_FORM

	## Description : _getContaminantExtION_FORM
	## Input : void
	## Output : $ION_FORM
	## Usage : my ( $ION_FORM ) = _getContaminantExtION_FORM () ;

=cut

## START of SUB
sub _getContaminantExtION_FORM {
    ## Retrieve Values
    my $self = shift ;
    
    my $ION_FORM = undef ;
    
    if ( (defined $self->{_ION_FORM_}) and ( $self->{_ION_FORM_} ne '' ) ) {	$ION_FORM = $self->{_ION_FORM_} ; }
    else {	 $ION_FORM = 'unknown' ; warn "[WARN] the method _getContaminantExtION_FORM return unknown if getting a undef value\n" ; }
    
    return ( $ION_FORM ) ;
}
### END of SUB


=item _setContaminantExtION_FORM

	## Description : _setContaminantExtION_FORM
	## Input : $ION_FORM
	## Output : TRUE
	## Usage : _setContaminantExtION_FORM ( $ION_FORM ) ;

=cut

## START of SUB
sub _setContaminantExtION_FORM {
    ## Retrieve Values
    my $self = shift ;
    my ( $ION_FORM ) = @_;
    
    if ( (defined $ION_FORM) and ( $ION_FORM ne '' )  ) {	
    	$ION_FORM =~ s/\n| //g ; # cleaning \n and spaces before and after...
    	$self->{_ION_FORM_} = $ION_FORM ; }
    else {	$self->{_ION_FORM_} = undef }
    
    return (0) ;
}
### END of SUB

=item _getContaminantExtMZ

	## Description : _getContaminantExtMZ
	## Input : void
	## Output : $MZ
	## Usage : my ( $EXACT_ADDUCT_MASS ) = _getContaminantExtMZ () ;

=cut

## START of SUB
sub _getContaminantExtMZ {
    ## Retrieve Values
    my $self = shift ;
    
    my $MZ = undef ;
    
    if ( (defined $self->{_MZ_}) and ( $self->{_MZ_} ne '' ) ) {	$MZ = $self->{_MZ_} ; }
    else {	 $MZ = undef ; warn "[WARN] the method _getContaminantExtMZ can't _get a undef or non numerical value\n" ; }
    
    return ( $MZ ) ;
}
### END of SUB

=item _setContaminantExtMZ

	## Description : _setContaminantExtMZ
	## Input : $MZ
	## Output : TRUE
	## Usage : _setContaminantExtMZ ( $MZ ) ;

=cut

## START of SUB
sub _setContaminantExtMZ {
    ## Retrieve Values
    my $self = shift ;
    my ( $MZ ) = @_;
    
    if ( (defined $MZ) and ( $MZ > 0 )  ) {	
    	$MZ =~ s/\n| //g ; # cleaning \n and spaces before and after...
    	$self->{_MZ_} = $MZ ; }
    else {	$self->{_MZ_} = undef }
    
    return (0) ;
}
### END of SUB

=item _getContaminantExtINSTRUMENT_TYPES

	## Description : _getContaminantExtINSTRUMENT_TYPES
	## Input : void
	## Output : $INSTRUMENT_TYPE
	## Usage : my ( $INSTRUMENT_TYPE ) = _getContaminantExtINSTRUMENT_TYPES () ;

=cut

## START of SUB
sub _getContaminantExtINSTRUMENT_TYPES {
    ## Retrieve Values
    my $self = shift ;
    
    my $INSTRUMENT_TYPE = undef ;
    
    if ( (defined $self->{_INSTRUMENT_TYPE_}) and ( $self->{_INSTRUMENT_TYPE_} ne '' ) ) {	$INSTRUMENT_TYPE = $self->{_INSTRUMENT_TYPE_} ; }
    else {	 $INSTRUMENT_TYPE = undef ; warn "[WARN] the method _getContaminantExtINSTRUMENT_TYPES can't _get a undef or non numerical value\n" ; }
    
    return ( $INSTRUMENT_TYPE ) ;
}
### END of SUB

=item _setContaminantExtINSTRUMENT_TYPE

	## Description : _setContaminantExtINSTRUMENT_TYPE
	## Input : $INSTRUMENT_TYPE
	## Output : TRUE
	## Usage : _setContaminantExtINSTRUMENT_TYPE ( $INSTRUMENT_TYPE ) ;

=cut

## START of SUB
sub _setContaminantExtINSTRUMENT_TYPE {
    ## Retrieve Values
    my $self = shift ;
    my ( $INSTRUMENT_TYPE ) = @_;
    
    if ( (defined $INSTRUMENT_TYPE) and ( $INSTRUMENT_TYPE ne '' )  ) {	
    	$INSTRUMENT_TYPE =~ s/\n//g ; # cleaning \n
    	$INSTRUMENT_TYPE =~ s/^\s+// ; # trim left
    	$INSTRUMENT_TYPE =~ s/\s+$// ; # trim right
    	$self->{_INSTRUMENT_TYPE_} = $INSTRUMENT_TYPE ; }
    else {	$self->{_INSTRUMENT_TYPE_} = 'unknown' }
    
    return (0) ;
}
### END of SUB

=item _getContaminantExtINSTRUMENTS

	## Description : _getContaminantExtINSTRUMENTS
	## Input : void
	## Output : $INSTRUMENT
	## Usage : my ( $INSTRUMENT ) = _getContaminantExtINSTRUMENTS () ;

=cut

## START of SUB
sub _getContaminantExtINSTRUMENTS {
    ## Retrieve Values
    my $self = shift ;
    
    my $INSTRUMENT = undef ;
    
    if ( (defined $self->{_INSTRUMENT_}) and ( $self->{_INSTRUMENT_} ne '' ) ) {	$INSTRUMENT = $self->{_INSTRUMENT_} ; }
    else {	 $INSTRUMENT = undef ; warn "[WARN] the method _getContaminantExtINSTRUMENTS can't _get a undef or non numerical value\n" ; }
    
    return ( $INSTRUMENT ) ;
}
### END of SUB

=item _setContaminantExtINSTRUMENT

	## Description : _setContaminantExtINSTRUMENT
	## Input : $INSTRUMENT
	## Output : TRUE
	## Usage : _setContaminantExtINSTRUMENT ( $INSTRUMENT ) ;

=cut

## START of SUB
sub _setContaminantExtINSTRUMENT {
    ## Retrieve Values
    my $self = shift ;
    my ( $INSTRUMENT ) = @_;
    
    if ( (defined $INSTRUMENT) and ( $INSTRUMENT ne '' )  ) {	
    	$INSTRUMENT =~ s/\n//g ; # cleaning \n
    	$INSTRUMENT =~ s/^\s+// ; # trim left
    	$INSTRUMENT =~ s/\s+$// ; # trim right
    	$self->{_INSTRUMENT_} = $INSTRUMENT ; }
    else {	$self->{_INSTRUMENT_} = 'unknown' }
    
    return (0) ;
}
### END of SUB

=item _setContaminantExtCHROMATOGRAPHY

	## Description : _setContaminantExtCHROMATOGRAPHY
	## Input : $CHROMATOGRAPHY
	## Output : TRUE
	## Usage : _setContaminantExtCHROMATOGRAPHY ( $CHROMATOGRAPHY ) ;

=cut

## START of SUB
sub _setContaminantExtCHROMATOGRAPHY {
    ## Retrieve Values
    my $self = shift ;
    my ( $CHROMATOGRAPHY ) = @_;
    
    if ( (defined $CHROMATOGRAPHY) and ( $CHROMATOGRAPHY ne '' )  ) {	
    	$CHROMATOGRAPHY =~ s/\n//g ; # cleaning \n
    	$CHROMATOGRAPHY =~ s/^\s+// ; # trim left
    	$CHROMATOGRAPHY =~ s/\s+$// ; # trim right
    	$self->{_CHROMATOGRAPHY_} = $CHROMATOGRAPHY ; }
    else {	$self->{_CHROMATOGRAPHY_} = undef }
    
    return (0) ;
}
### END of SUB

=item _setContaminantExtION_SOURCE_TYPE

	## Description : _setContaminantExtION_SOURCE_TYPE
	## Input : $ION_SOURCE_TYPE
	## Output : TRUE
	## Usage : _setContaminantExtION_SOURCE_TYPE ( $ION_SOURCE_TYPE ) ;

=cut

## START of SUB
sub _setContaminantExtION_SOURCE_TYPE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ION_SOURCE_TYPE ) = @_;
    
    if ( (defined $ION_SOURCE_TYPE) and ( $ION_SOURCE_TYPE ne '' )  ) {	
    	$ION_SOURCE_TYPE =~ s/\n//g ; # cleaning \n
    	$ION_SOURCE_TYPE =~ s/^\s+// ; # trim left
    	$ION_SOURCE_TYPE =~ s/\s+$// ; # trim right
    	$self->{_ION_SOURCE_TYPE_} = $ION_SOURCE_TYPE ; }
    else {	$self->{_ION_SOURCE_TYPE_} = undef }
    
    return (0) ;
}
### END of SUB

=item _getContaminantExtTYPE_OF_CONTAMINANT

	## Description : _getContaminantExtTYPE_OF_CONTAMINANT
	## Input : void
	## Output : $TYPE_OF_CONTAMINANT
	## Usage : my ( $TYPE_OF_CONTAMINANT ) = _getContaminantExtTYPE_OF_CONTAMINANT () ;

=cut

## START of SUB
sub _getContaminantExtTYPE_OF_CONTAMINANT {
    ## Retrieve Values
    my $self = shift ;
    
    my $TYPE_OF_CONTAMINANT = undef ;
    
    if ( (defined $self->{_TYPE_OF_CONTAMINANT_}) and ( $self->{_TYPE_OF_CONTAMINANT_} ne '' ) ) {	$TYPE_OF_CONTAMINANT = $self->{_TYPE_OF_CONTAMINANT_} ; }
    else {	 $TYPE_OF_CONTAMINANT = undef ; warn "[WARN] the method _getContaminantExtTYPE_OF_CONTAMINANT can't _get a undef or non numerical value\n" ; }
    
    return ( $TYPE_OF_CONTAMINANT ) ;
}
### END of SUB


=item _setContaminantTYPE_OF_CONTAMINANT

	## Description : _setContaminantTYPE_OF_CONTAMINANT
	## Input : $TYPE_OF_CONTAMINANT
	## Output : TRUE
	## Usage : _setContaminantTYPE_OF_CONTAMINANT ( $TYPE_OF_CONTAMINANT ) ;

=cut

## START of SUB
sub _setContaminantTYPE_OF_CONTAMINANT {
    ## Retrieve Values
    my $self = shift ;
    my ( $TYPE_OF_CONTAMINANT ) = @_;
    
    if ( (defined $TYPE_OF_CONTAMINANT) and ( $TYPE_OF_CONTAMINANT ne '' )  ) {	
    	$TYPE_OF_CONTAMINANT =~ s/\n//g ; # cleaning \n
    	$TYPE_OF_CONTAMINANT =~ s/^\s+// ; # trim left
    	$TYPE_OF_CONTAMINANT =~ s/\s+$// ; # trim right
    	
    	$self->{_TYPE_OF_CONTAMINANT_} = $TYPE_OF_CONTAMINANT ; }
    else {	$self->{_TYPE_OF_CONTAMINANT_} = 'unknown' }
    
    return (0) ;
}
### END of SUB

=item _setContaminantPUBCHEM_CID

	## Description : _setContaminantPUBCHEM_CID
	## Input : $PUBCHEM_CID
	## Output : TRUE
	## Usage : _setContaminantPUBCHEM_CID ( $PUBCHEM_CID ) ;

=cut

## START of SUB
sub _setContaminantPUBCHEM_CID {
    ## Retrieve Values
    my $self = shift ;
    my ( $PUBCHEM_CID ) = @_;
    
    if ( (defined $PUBCHEM_CID) and ( $PUBCHEM_CID ne '' )  ) {	
    	$PUBCHEM_CID =~ s/\n//g ; # cleaning \n
    	$PUBCHEM_CID =~ s/^\s+// ; # trim left
    	$PUBCHEM_CID =~ s/\s+$// ; # trim right
    	$self->{_PUBCHEM_CID_} = $PUBCHEM_CID ; }
    else {	
    	$self->{_PUBCHEM_CID_} = undef ; }
    
    return (0) ;
}
### END of SUB

=item _setContaminantSTD_INCHI_KEY

	## Description : _setContaminantSTD_INCHI_KEY
	## Input : $STD_INCHI_KEY
	## Output : TRUE
	## Usage : _setContaminantSTD_INCHI_KEY ( $STD_INCHI_KEY ) ;

=cut

## START of SUB
sub _setContaminantSTD_INCHI_KEY {
    ## Retrieve Values
    my $self = shift ;
    my ( $STD_INCHI_KEY ) = @_;
    
    if ( (defined $STD_INCHI_KEY) and ( $STD_INCHI_KEY ne '' )  ) {	
    	$STD_INCHI_KEY =~ s/\n//g ; # cleaning \n
    	$STD_INCHI_KEY =~ s/^\s+// ; # trim left
    	$STD_INCHI_KEY =~ s/\s+$// ; # trim right
    	$self->{_STD_INCHI_KEY_} = $STD_INCHI_KEY ; }
    else {	
    	$self->{_STD_INCHI_KEY_} = undef ; }
    
    return (0) ;
}
### END of SUB

=item _setContaminantSTD_INCHI

	## Description : _setContaminantSTD_INCHI
	## Input : $STD_INCHI
	## Output : TRUE
	## Usage : _setContaminantSTD_INCHI ( $STD_INCHI ) ;

=cut

## START of SUB
sub _setContaminantSTD_INCHI {
    ## Retrieve Values
    my $self = shift ;
    my ( $STD_INCHI ) = @_;
    
    if ( (defined $STD_INCHI) and ( $STD_INCHI ne '' )  ) {	
    	$STD_INCHI =~ s/\n//g ; # cleaning \n
    	$STD_INCHI =~ s/^\s+// ; # trim left
    	$STD_INCHI =~ s/\s+$// ; # trim right
    	$self->{_STD_INCHI_} = $STD_INCHI ; }
    else {	$self->{_STD_INCHI_} = undef ; }
    
    return (0) ;
}
### END of SUB

=item _getContaminantEXACT_MASS

	## Description : _getContaminantEXACT_MASS
	## Input : void
	## Output : $EXACT_MASS
	## Usage : my ( $EXACT_MASS ) = _getContaminantEXACT_MASS () ;

=cut

## START of SUB
sub _getContaminantEXACT_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $EXACT_MASS = undef ;
    
    if ( (defined $self->{_EXACT_MASS_}) and ( $self->{_EXACT_MASS_} ne '' ) ) {	$EXACT_MASS = $self->{_EXACT_MASS_} ; }
    else {	 $EXACT_MASS = undef ; warn "[WARN] the method _getContaminantEXACT_MASS return undef when no value is available\n" ; }
    
    return ( $EXACT_MASS ) ;
}
### END of SUB

=item _setContaminantEXACT_MASS

	## Description : _setContaminantEXACT_MASS
	## Input : $EXACT_MASS
	## Output : TRUE
	## Usage : _setContaminantEXACT_MASS ( $EXACT_MASS ) ;

=cut

## START of SUB
sub _setContaminantEXACT_MASS {
    ## Retrieve Values
    my $self = shift ;
    my ( $EXACT_MASS ) = @_;
    
    if ( (defined $EXACT_MASS) and ( $EXACT_MASS > 0 )  ) {	
    	$EXACT_MASS =~ s/\n//g ; # cleaning \n
    	$EXACT_MASS =~ s/^\s+// ; # trim left
    	$EXACT_MASS =~ s/\s+$// ; # trim right
    	$self->{_EXACT_MASS_} = $EXACT_MASS ; }
    else {	$self->{_EXACT_MASS_} = undef ; }
    
    return (0) ;
}
### END of SUB

=item _setContaminantFORMULA

	## Description : _setContaminantFORMULA
	## Input : $FORMULA
	## Output : TRUE
	## Usage : _setContaminantFORMULA ( $FORMULA ) ;

=cut

## START of SUB
sub _setContaminantFORMULA {
    ## Retrieve Values
    my $self = shift ;
    my ( $FORMULA ) = @_;
    
    if ( (defined $FORMULA) and ( $FORMULA ne '' )  ) {	
    	$FORMULA =~ s/\n//g ; # cleaning \n
    	$FORMULA =~ s/^\s+// ; # trim left
    	$FORMULA =~ s/\s+$// ; # trim right
    	$self->{_FORMULA_} = $FORMULA ; }
    else {	carp "[ERROR] the method _setContaminantFORMULA can't set any undef or void value\n" ; }
    
    return (0) ;
}
### END of SUB

=item _getContaminantNAME

	## Description : _getContaminantNAME
	## Input : void
	## Output : $NAME
	## Usage : my ( $NAME ) = _getContaminantNAME () ;

=cut

## START of SUB
sub _getContaminantNAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $NAME = undef ;
    
    if ( (defined $self->{_NAME_}) and ( $self->{_NAME_} ne '' ) ) {	$NAME = $self->{_NAME_} ; }
    else {	 $NAME = undef ; warn "[WARN] the method _getContaminantNAME can't _get a undef or non numerical value\n" ; }
    
    return ( $NAME ) ;
}
### END of SUB

=item _setContaminantNAME

	## Description : _setContaminantNAME
	## Input : $NAME
	## Output : TRUE
	## Usage : _setContaminantNAME ( $NAME ) ;

=cut

## START of SUB
sub _setContaminantNAME {
    ## Retrieve Values
    my $self = shift ;
    my ( $NAME ) = @_;
    
    if ( (defined $NAME) and ( $NAME ne '' )  ) {	
    	$NAME =~ s/\n//g ; # cleaning \n
    	$NAME =~ s/^\s+// ; # trim left
    	$NAME =~ s/\s+$// ; # trim right
    	$self->{_NAME_} = $NAME ; }
    else {	carp "[ERROR] the method _setContaminantNAME can't set any undef or void value\n" ; }
    
    return (0) ;
}
### END of SUB

=item _getContaminantID

	## Description : _getContaminantID
	## Input : void
	## Output : $ID
	## Usage : my ( $ID ) = _getContaminantID () ;

=cut

## START of SUB
sub _getContaminantID {
    ## Retrieve Values
    my $self = shift ;
    
    my $ID = undef ;
    
    if ( (defined $self->{_ID_}) and ( $self->{_ID_} ne '' ) ) {	$ID = $self->{_ID_} ; }
    else {	 $ID = undef ; warn "[WARN] the method _getContaminantID can't _get a undef or non numerical value\n" ; }
    
    return ( $ID ) ;
}
### END of SUB

=item _setContaminantID

	## Description : _setContaminantID
	## Input : $ID
	## Output : TRUE
	## Usage : _setContaminantID ( $ID ) ;

=cut

## START of SUB
sub _setContaminantID {
    ## Retrieve Values
    my $self = shift ;
    my ( $ID ) = @_;
    
    if ( (defined $ID) and ( $ID ne '' )  ) {
    	$ID =~ s/\n//g ; # cleaning \n
    	$ID =~ s/^\s+// ; # trim left
    	$ID =~ s/\s+$// ; # trim right
    	$self->{_ID_} = $ID ; }
    else {	carp "[ERROR] the method _setContaminantID can't set any undef or void value\n" ; }
    
    return (0) ;
}
### END of SUB

__END__

=back

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inra.fr> >>

=head1 SEE ALSO

All information about Metabolomics::Fragment would be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragnot

=head1 BUGS

Please report any bugs or feature requests to C<bug-Metabolomics-Fragment-Annotation at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Metabolomics-Fragment-Annotation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Banks::MaConDa

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

1; # End of Metabolomics::Banks::MaConDa
