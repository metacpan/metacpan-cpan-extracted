package Metabolomics::Fragment::Annotation;

use 5.006;
use strict;
use warnings;

use Data::Dumper ;
use Text::CSV ;
use XML::Twig ;
use File::Share ':all'; 
use Carp qw (cluck croak carp) ;

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
	parsingMsFragments
	getFragmentsFromSource 
	getContaminantsFromSource 
	getContaminantsExtensiveFromSource 
	extractContaminantTypes 
	extractContaminantInstruments 
	extractContaminantInstrumentTypes 
	filterContaminantIonMode 
	filterContaminantInstruments 
	filterContaminantInstrumentTypes 
	buildTheoPeakBankFromFragments 
	buildTheoPeakBankFromContaminants 
	compareExpMzToTheoMzList
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	writeFullTabularWithPeakBankObject 
	writeTabularWithPeakBankObject 
	parsingMsFragments 
	getFragmentsFromSource 
	getContaminantsFromSource 
	getContaminantsExtensiveFromSource 
	extractContaminantTypes 
	extractContaminantInstruments 
	extractContaminantInstrumentTypes 
	filterContaminantIonMode 
	filterContaminantInstruments 
	filterContaminantInstrumentTypes 
	buildTheoPeakBankFromFragments 
	buildTheoPeakBankFromContaminants 
	compareExpMzToTheoMzList
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Fragment::Annotation - Perl extension for fragment annotation in metabolomics 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Metabolomics::Fragment::Annotation;

=head1 DESCRIPTION

	Metabolomics::Fragment::Annotation is a full package for Perl dev allowing full annotation of fragments.
	

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 METHOD refFragment

	## Description : set a new fragment
	## Input : NA	
	## Output : $refFragment
	## Usage : my ( $refFragment ) = refFragment() ;
	
=cut
## START of SUB
sub refFragment {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_TYPE_} = 'type' ; # STRING as adducts, fragment or isotope
    $self->{_LOSSES_OR_GAINS_} = 'losses_or_gains' ;
    $self->{_DELTA_MASS_} = 'delta_mass' ;
    $self->{_ANNOTATION_IN_POS_MODE_} = 'annotation_in_pos_mode' ;
    $self->{_ANNOTATION_IN_NEG_MODE_} = 'annotation_in_neg_mode' ;

    return $self ;
}
### END of SUB

# * * * * * * * * * *get/setter  * * * * * * * * * *#

=head2 METHOD _getANNOTATION_IN_NEG_MODE

	## Description : _getANNOTATION_IN_NEG_MODE
	## Input : void
	## Output : $ANNOTATION_IN_NEG_MODE
	## Usage : my ( $ANNOTATION_IN_NEG_MODE ) = _getANNOTATION_IN_NEG_MODE () ;
	
=cut
## START of SUB
sub _getANNOTATION_IN_NEG_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_IN_NEG_MODE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IN_NEG_MODE_}) and ( $self->{_ANNOTATION_IN_NEG_MODE_} ne '' ) ) {	$ANNOTATION_IN_NEG_MODE = $self->{_ANNOTATION_IN_NEG_MODE_} ; }
    else {	 $ANNOTATION_IN_NEG_MODE = undef ; warn "[WARN] the method _getANNOTATION_IN_NEG_MODE can't _get a undef or non numerical value\n" ; }
    
    return ( $ANNOTATION_IN_NEG_MODE ) ;
}
### END of SUB



=head2 METHOD _getANNOTATION_IN_POS_MODE

	## Description : _getANNOTATION_IN_POS_MODE
	## Input : void
	## Output : $ANNOTATION_IN_POS_MODE
	## Usage : my ( $ANNOTATION_IN_POS_MODE ) = _getANNOTATION_IN_POS_MODE () ;
	
=cut
## START of SUB
sub _getANNOTATION_IN_POS_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_IN_POS_MODE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IN_POS_MODE_}) and ( $self->{_ANNOTATION_IN_POS_MODE_} ne '' ) ) {	$ANNOTATION_IN_POS_MODE = $self->{_ANNOTATION_IN_POS_MODE_} ; }
    else {	 $ANNOTATION_IN_POS_MODE = undef ; warn "[WARN] the method _getANNOTATION_IN_POS_MODE can't _get a undef or non numerical value\n" ; }
    
    return ( $ANNOTATION_IN_POS_MODE ) ;
}
### END of SUB


=head2 METHOD _getDELTA_MASS

	## Description : _getDELTA_MASS
	## Input : void
	## Output : $DELTA_MASS
	## Usage : my ( $DELTA_MASS ) = _getDELTA_MASS () ;
	
=cut
## START of SUB
sub _getDELTA_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $DELTA_MASS = undef ;
    
    if ( (defined $self->{_DELTA_MASS_}) and ( $self->{_DELTA_MASS_} > 0 ) or $self->{_DELTA_MASS_} < 0  ) {	$DELTA_MASS = $self->{_DELTA_MASS_} ; }
    else {	 $DELTA_MASS = 0 ; warn "[WARN] the method _getDELTA_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $DELTA_MASS ) ;
}
### END of SUB

=head2 METHOD _getTYPE

	## Description : _getTYPE
	## Input : void
	## Output : $TYPE
	## Usage : my ( $TYPE ) = _getTYPE () ;
	
=cut
## START of SUB
sub _getTYPE {
    ## Retrieve Values
    my $self = shift ;
    
    my $TYPE = undef ;
    
    if ( (defined $self->{_TYPE_}) and ( $self->{_TYPE_} ne '' ) ) {	$TYPE = $self->{_TYPE_} ; }
    else {	 $TYPE = undef ; warn "[WARN] the method _getTYPE can't _get a undef or non numerical value\n" ; }
    
    return ( $TYPE ) ;
}
### END of SUB

=head2 METHOD _getLOSSES_OR_GAINS

	## Description : _getLOSSES_OR_GAINS
	## Input : void
	## Output : $LOSSES_OR_GAINS
	## Usage : my ( $LOSSES_OR_GAINS ) = _getLOSSES_OR_GAINS () ;
	
=cut
## START of SUB
sub _getLOSSES_OR_GAINS {
    ## Retrieve Values
    my $self = shift ;
    
    my $LOSSES_OR_GAINS = undef ;
    
    if ( (defined $self->{_LOSSES_OR_GAINS_}) and ( $self->{_LOSSES_OR_GAINS_} ne '' ) ) {	$LOSSES_OR_GAINS = $self->{_LOSSES_OR_GAINS_} ; }
    else {	 $LOSSES_OR_GAINS = undef ; warn "[WARN] the method _getLOSSES_OR_GAINS can't _get a undef or non numerical value\n" ; }
    
    return ( $LOSSES_OR_GAINS ) ;
}
### END of SUB




=head2 METHOD refPeak

	## Description : set a new theorical peak
	## Input : NA	
	## Output : refPeak
	## Usage : my ( refPeak ) = refPeak() ;
	
=cut
## START of SUB
sub refPeak {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    $self->{_ID_} = undef ; # identifiant (for theo peak)
    $self->{_MESURED_MONOISOTOPIC_MASS_} = 0 ; # mesured accurate mass (for exp peak)
    $self->{_COMPUTED_MONOISOTOPIC_MASS_} = 0 ; # computed accurate mass (for theo peak)
    $self->{_PPM_ERROR_} = 0 ; # STRING
    $self->{_MMU_ERROR_} = 0 ; # STRING
    $self->{_ANNOTATION_IN_NEG_MODE_} = undef ; # STRING
    $self->{_ANNOTATION_IN_POS_MODE_} = undef ; # STRING
    $self->{_ANNOTATION_TYPE_} = undef ; # STRING as adducts, fragment or isotope
    $self->{_ANNOTATION_NAME_} = undef ; # STRING

    return $self ;
}
### END of SUB

# * * * * * * * * * *get/setter  * * * * * * * * * *#

=head2 METHOD _setCOMPUTED_MONOISOTOPIC_MASS

	## Description : _setCOMPUTED_MONOISOTOPIC_MASS
	## Input : $COMPUTED_MONOISOTOPIC_MASS
	## Output : TRUE
	## Usage : _setCOMPUTED_MONOISOTOPIC_MASS ( $COMPUTED_MONOISOTOPIC_MASS ) ;
	
=cut
## START of SUB
sub _setCOMPUTED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    my ( $COMPUTED_MONOISOTOPIC_MASS ) = @_;
    
    if ( (defined $COMPUTED_MONOISOTOPIC_MASS) and ( ($COMPUTED_MONOISOTOPIC_MASS >= 0) or ($COMPUTED_MONOISOTOPIC_MASS <= 0) )  ) {	$self->{_COMPUTED_MONOISOTOPIC_MASS_} = $COMPUTED_MONOISOTOPIC_MASS ; }
    else {	carp "[ERROR] the method _setCOMPUTED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getCOMPUTED_MONOISOTOPIC_MASS

	## Description : _getCOMPUTED_MONOISOTOPIC_MASS
	## Input : void
	## Output : $COMPUTED_MONOISOTOPIC_MASS
	## Usage : my ( $COMPUTED_MONOISOTOPIC_MASS ) = _getCOMPUTED_MONOISOTOPIC_MASS () ;
	
=cut
## START of SUB
sub _getCOMPUTED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $COMPUTED_MONOISOTOPIC_MASS = undef ;
    
    if ( (defined $self->{_COMPUTED_MONOISOTOPIC_MASS_}) and ( $self->{_COMPUTED_MONOISOTOPIC_MASS_} > 0 ) or $self->{_COMPUTED_MONOISOTOPIC_MASS_} < 0  ) {	$COMPUTED_MONOISOTOPIC_MASS = $self->{_COMPUTED_MONOISOTOPIC_MASS_} ; }
    else {	 $COMPUTED_MONOISOTOPIC_MASS = 0 ; warn "[WARN] the method _getCOMPUTED_MONOISOTOPIC_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $COMPUTED_MONOISOTOPIC_MASS ) ;
}
### END of SUB



=head2 METHOD _setMESURED_MONOISOTOPIC_MASS

	## Description : _setMESURED_MONOISOTOPIC_MASS
	## Input : $MESURED_MONOISOTOPIC_MASS
	## Output : TRUE
	## Usage : _setMESURED_MONOISOTOPIC_MASS ( $MESURED_MONOISOTOPIC_MASS ) ;
	
=cut
## START of SUB
sub _setMESURED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    my ( $MESURED_MONOISOTOPIC_MASS ) = @_;
    
    if ( (defined $MESURED_MONOISOTOPIC_MASS) and ( ($MESURED_MONOISOTOPIC_MASS > 0) or ($MESURED_MONOISOTOPIC_MASS < 0) )  ) {	$self->{_MESURED_MONOISOTOPIC_MASS_} = $MESURED_MONOISOTOPIC_MASS ; }
    else {	carp "[ERROR] the method _setMESURED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getMESURED_MONOISOTOPIC_MASS

	## Description : _getMESURED_MONOISOTOPIC_MASS
	## Input : void
	## Output : $MESURED_MONOISOTOPIC_MASS
	## Usage : my ( $MESURED_MONOISOTOPIC_MASS ) = _getMESURED_MONOISOTOPIC_MASS () ;
	
=cut
## START of SUB
sub _getMESURED_MONOISOTOPIC_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $MESURED_MONOISOTOPIC_MASS = undef ;
    
    if ( (defined $self->{_MESURED_MONOISOTOPIC_MASS_}) and ( $self->{_MESURED_MONOISOTOPIC_MASS_} > 0 ) or $self->{_MESURED_MONOISOTOPIC_MASS_} < 0  ) {	$MESURED_MONOISOTOPIC_MASS = $self->{_MESURED_MONOISOTOPIC_MASS_} ; }
    else {	 $MESURED_MONOISOTOPIC_MASS = 0 ; warn "[WARN] the method _getMESURED_MONOISOTOPIC_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $MESURED_MONOISOTOPIC_MASS ) ;
}
### END of SUB


=head2 METHOD _setANNOTATION_IN_NEG_MODE

	## Description : _setANNOTATION_IN_NEG_MODE
	## Input : $ANNOTATION_IN_NEG_MODE
	## Output : TRUE
	## Usage : _setANNOTATION_IN_NEG_MODE ( $ANNOTATION_IN_NEG_MODE ) ;
	
=cut
## START of SUB
sub _setANNOTATION_IN_NEG_MODE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_IN_NEG_MODE ) = @_;
    
    if ( (defined $ANNOTATION_IN_NEG_MODE) and ($ANNOTATION_IN_NEG_MODE ne '')  ) {	$self->{_ANNOTATION_IN_NEG_MODE_} = $ANNOTATION_IN_NEG_MODE ; }
    else {	carp "[ERROR] the method _setCOMPUTED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB


=head2 METHOD _setANNOTATION_DA_ERROR

	## Description : _setANNOTATION_DA_ERROR
	## Input : $MMU_ERROR
	## Output : TRUE
	## Usage : _setANNOTATION_DA_ERROR ( $MMU_ERROR ) ;
	
=cut
## START of SUB
sub _setANNOTATION_DA_ERROR {
    ## Retrieve Values
    my $self = shift ;
    my ( $MMU_ERROR ) = @_;
    
    if ( (defined $MMU_ERROR) and ($MMU_ERROR ne '')  ) {	$self->{_MMU_ERROR_} = $MMU_ERROR ; }
    else {	carp "[ERROR] the method _setANNOTATION_DA_ERROR can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _setANNOTATION_PPM_ERROR

	## Description : _setANNOTATION_PPM_ERROR
	## Input : $PPM_ERROR
	## Output : TRUE
	## Usage : _setANNOTATION_PPM_ERROR ( $PPM_ERROR ) ;
	
=cut
## START of SUB
sub _setANNOTATION_PPM_ERROR {
    ## Retrieve Values
    my $self = shift ;
    my ( $PPM_ERROR ) = @_;
    
    if ( (defined $PPM_ERROR) and ($PPM_ERROR ne '')  ) {	$self->{_PPM_ERROR_} = $PPM_ERROR ; }
    else {	carp "[ERROR] the method _setANNOTATION_PPM_ERROR can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _setANNOTATION_IN_NEG_MODE

	## Description : _setANNOTATION_IN_NEG_MODE
	## Input : $ANNOTATION_IN_POS_MODE
	## Output : TRUE
	## Usage : _setANNOTATION_IN_POS_MODE ( $ANNOTATION_IN_POS_MODE ) ;
	
=cut
## START of SUB
sub _setANNOTATION_IN_POS_MODE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_IN_POS_MODE ) = @_;
    
    if ( (defined $ANNOTATION_IN_POS_MODE) and ($ANNOTATION_IN_POS_MODE ne '')  ) {	$self->{_ANNOTATION_IN_POS_MODE_} = $ANNOTATION_IN_POS_MODE ; }
    else {	carp "[ERROR] the method _setANNOTATION_IN_POS_MODE can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _setANNOTATION_TYPE

	## Description : _setANNOTATION_TYPE
	## Input : $ANNOTATION_TYPE
	## Output : TRUE
	## Usage : _setANNOTATION_TYPE ( $ANNOTATION_TYPE ) ;
	
=cut
## START of SUB
sub _setANNOTATION_TYPE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_TYPE ) = @_;
    
    if ( (defined $ANNOTATION_TYPE) and ($ANNOTATION_TYPE ne '')  ) {	$self->{_ANNOTATION_TYPE_} = $ANNOTATION_TYPE ; }
    else {	carp "[ERROR] the method _setANNOTATION_TYPE can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getANNOTATION_TYPE

	## Description : _getANNOTATION_TYPE
	## Input : void
	## Output : $ANNOTATION_TYPE
	## Usage : my ( $TYPE ) = _getANNOTATION_TYPE () ;
	
=cut
## START of SUB
sub _getANNOTATION_TYPE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_TYPE = undef ;
    
    if ( (defined $self->{_ANNOTATION_TYPE_}) and ( $self->{_ANNOTATION_TYPE_} ne '' ) ) {	$ANNOTATION_TYPE = $self->{_ANNOTATION_TYPE_} ; }
    else {	 $ANNOTATION_TYPE = undef ; warn "[WARN] the method _getANNOTATION_TYPE can't _get a undef or non numerical value\n" ; }
    
    return ( $ANNOTATION_TYPE ) ;
}
### END of SUB

=head2 METHOD _setANNOTATION_NAME

	## Description : _setANNOTATION_NAME
	## Input : $ANNOTATION_NAME
	## Output : TRUE
	## Usage : _setANNOTATION_NAME ( $ANNOTATION_NAME ) ;
	
=cut
## START of SUB
sub _setANNOTATION_NAME {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_NAME ) = @_;
    
    if ( (defined $ANNOTATION_NAME) and ($ANNOTATION_NAME ne '')  ) {	$self->{_ANNOTATION_NAME_} = $ANNOTATION_NAME ; }
    else {	carp "[ERROR] the method _setANNOTATION_NAME can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB


=head2 METHOD _getANNOTATION_NAME

	## Description : _getANNOTATION_NAME
	## Input : void
	## Output : $ANNOTATION_NAME
	## Usage : my ( $ANNOTATION_NAME ) = _getANNOTATION_NAME () ;
	
=cut
## START of SUB
sub _getANNOTATION_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_NAME = undef ;
    
    if ( (defined $self->{_ANNOTATION_NAME_}) and ( $self->{_ANNOTATION_NAME_} ne '' ) ) {	$ANNOTATION_NAME = $self->{_ANNOTATION_NAME_} ; }
    else {	 $ANNOTATION_NAME = undef ; warn "[WARN] the method _getANNOTATION_NAME can't _get a undef or non numerical value\n" ; }
    
    return ( $ANNOTATION_NAME ) ;
}
### END of SUB

=head2 METHOD _getANNOTATION_ID

	## Description : _getANNOTATION_ID
	## Input : void
	## Output : $ANNOTATION_ID
	## Usage : my ( $ANNOTATION_ID ) = _getANNOTATION_ID () ;
	
=cut
## START of SUB
sub _getANNOTATION_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_ID = undef ;
    
    if ( (defined $self->{_ID_}) and ( $self->{_ID_} ne '' ) ) {	$ANNOTATION_ID = $self->{_ID_} ; }
    else {	 $ANNOTATION_ID = undef ; warn "[WARN] the method _getANNOTATION_NAME can't _get a undef or non numerical value\n" ; }
    
    return ( $ANNOTATION_ID ) ;
}
### END of SUB

=head2 METHOD _setANNOTATION_ID

	## Description : _setANNOTATION_ID
	## Input : $ANNOTATION_ID
	## Output : TRUE
	## Usage : _setANNOTATION_ID ( $ANNOTATION_ID ) ;
	
=cut
## START of SUB
sub _setANNOTATION_ID {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_ID ) = @_;
    
    if ( (defined $ANNOTATION_ID) and ($ANNOTATION_ID ne '')  ) {	$self->{_ID_} = $ANNOTATION_ID ; }
    else {	carp "[ERROR] the method _setANNOTATION_ID can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB



=head2 METHOD refBank

	## Description : set a new list of fragments as a bank
	## Input : NA
	## Output : $Fragments
	## Usage : my ( $Fragments ) = refBank ( ) ;
	
=cut
## START of SUB
sub refBank {
	## Variables
	my ($class,$args) = @_;
	my $self={};

	bless($self) ;
    
    $self->{_FRAGMENTS_} = [] ;
    $self->{_THEO_PEAK_LIST_} = [] ;
    $self->{_EXP_PEAK_LIST_} = [] ;
    
    return ($self) ;
}
### END of SUB

=head2 METHOD refContaminants

	## Description : set a new list of contaminants as a bank
	## Input : NA
	## Output : $Contaminants
	## Usage : my ( $Contaminants ) = refContaminants ( ) ;
	
=cut
## START of SUB
sub refContaminants {
	## Variables
	my ($class,$args) = @_;
	my $self={};

	bless($self) ;
    
    $self->{_CONTAMINANTS_} = [] ;
    
    return ($self) ;
}
### END of SUB

=head2 METHOD refContaminant

	## Description : set a new contaminant
	## Input : NA	
	## Output : $refContaminant
	## Usage : my ( $refContaminant ) = refContaminant() ;
	
=cut
## START of SUB
sub refContaminant {
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

=head2 METHOD refContaminantExtensive

	## Description : set a new contaminant extensive version
	## Input : NA	
	## Output : $refContaminantExtensive
	## Usage : my ( $refContaminantExtensive ) = refContaminantExtensive() ;
	
=cut
## START of SUB
sub refContaminantExtensive {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    ## TODO... surcharge de l'objet
    $self->{_ID_} = 'id' ;
    $self->{_NAME_} = 'name' ;
    $self->{_FORMULA_} = 'formula' ;
    $self->{_EXACT_MASS_} = 'exact_mass' ;
    $self->{_STD_INCHI_} = 'std_inchi' ;
    $self->{_STD_INCHI_KEY_} = 'std_inchi_key' ;
    $self->{_PUBCHEM_CID_} = 'pubchem_cid' ;
    $self->{_TYPE_OF_CONTAMINANT_} = 'type_of_contaminant' ;
    
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


=head2 METHOD _setContaminantExtREFERENCE

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

=head2 METHOD _getContaminantExtION_MODE

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

=head2 METHOD _setContaminantExtION_MODE

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

=head2 METHOD _setContaminantExtEXACT_ADDUCT_MASS

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

=head2 METHOD _getContaminantExtEXACT_ADDUCT_MASS

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

=head2 METHOD _getContaminantExtION_FORM

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


=head2 METHOD _setContaminantExtION_FORM

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

=head2 METHOD _getContaminantExtMZ

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

=head2 METHOD _setContaminantExtMZ

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


=head2 METHOD _getContaminantExtINSTRUMENT_TYPES

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

=head2 METHOD _setContaminantExtINSTRUMENT_TYPE

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

=head2 METHOD _getContaminantExtINSTRUMENTS

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

=head2 METHOD _setContaminantExtINSTRUMENT

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

=head2 METHOD _setContaminantExtCHROMATOGRAPHY

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

=head2 METHOD _setContaminantExtION_SOURCE_TYPE

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

=head2 METHOD _getContaminantExtTYPE_OF_CONTAMINANT

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


=head2 METHOD _setContaminantTYPE_OF_CONTAMINANT

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

=head2 METHOD _setContaminantPUBCHEM_CID

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

=head2 METHOD _setContaminantSTD_INCHI_KEY

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


=head2 METHOD _setContaminantSTD_INCHI

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

=head2 METHOD _getContaminantEXACT_MASS

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

=head2 METHOD _setContaminantEXACT_MASS

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

=head2 METHOD _setContaminantFORMULA

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

=head2 METHOD _getContaminantNAME

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

=head2 METHOD _setContaminantNAME

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

=head2 METHOD _getContaminantID

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

=head2 METHOD _setContaminantID

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



=head2 METHOD _addContaminant

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




=head2 METHOD _addFragment

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

=head2 METHOD _addPeakList

	## Description : _addPeakList
	## Input : $self, $type, $peakList ;
	## Ouput : NA;
	## Usage : _addPeakList($type, $peakList);

=cut

### START of SUB

sub _addPeakList {
    my ($self, $type, $peakList) = @_;
    
    ## type should be _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_
	if ( (defined $type) and (defined $peakList) ) {
		push (@{$self->{$type}}, $peakList);
	}
	else{
		croak "type peaklist should be _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ \n" ;
	}
}

### END of SUB

=head2 METHOD _getFragments

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

=head2 METHOD _getContaminants

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


=head2 METHOD _getPeakList

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
    else {
    	croak "[ERROR] No type is undefined or does not correspond to _THEO_PEAK_LIST_ or _EXP_PEAK_LIST_ \n" ;
    }
    
    
    return ($peakList) ;
}
### END of SUB



=head2 METHOD getFragmentsFromSource

	## Description : get the list of theorical fragmets from $source file
	## Input : $source
	## Output : $theoFragments
	## Usage : my ( $theoFragments ) = getFragmentsFromSource ( $conf ) ;
	
=cut
## START of SUB
sub getFragmentsFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $source ) = @_;
    my ( $oBank ) = ( Metabolomics::Fragment::Annotation->refBank() ) ;
    
    if ( (defined $source) and (-e $source) ) {
    	
    	my $oFragment = Metabolomics::Fragment::Annotation->refFragment() ;
    	
		## format of ref file is in version 1.0 :
		## type	losses_or_gains	delta_mass	example_valine	annotation_in_pos_mode	annotation_in_neg_mode
		my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    		or die "Cannot use CSV: ".Text::CSV->error_diag ();
    	
    	open my $fh, "<", $source or die "$source: $!";
    	
		## Checking header of the source file   	
    	$csv->header ($fh, { munge_column_names => sub {
		    s/\s+$//;
		    s/^\s+//;
		    my $uc_col = '_'.uc$_.'_' ;
		    if ($_ ne 'example_valine' ) {
		    	$oFragment->{$uc_col} or die "Unknown column '$uc_col' in $source";
		    }
		 }});
		
    	while (my $row = $csv->getline_hr ($fh)) {
    		my $currentFrag = Metabolomics::Fragment::Annotation->refFragment() ;
    		## TODO getter/setter...
    		$currentFrag->{_TYPE_} = $row->{'type'} ;
    		$currentFrag->{_DELTA_MASS_} = $row->{'delta_mass'} ;
    		$currentFrag->{_LOSSES_OR_GAINS_} = $row->{'losses_or_gains'} ;
    		$currentFrag->{_ANNOTATION_IN_POS_MODE_} = $row->{'annotation_in_pos_mode'} ;
    		$currentFrag->{_ANNOTATION_IN_NEG_MODE_} = $row->{'annotation_in_neg_mode'} ;
    		
    		$oBank->_addFragment($currentFrag)
    	}
    }
    else {
    	 croak "The source file does not exist ($source) or is not defined\n" ;
    }
#    print Dumper $oBank ;
    return ($oBank) ;
}
### END of SUB



=head2 METHOD getContaminantsFromSource

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
    my ( $oBank ) = ( Metabolomics::Fragment::Annotation->refContaminants() ) ;
    my $twig = undef ;
    my ($currentId, $currentName, $currentInchi, $currentInchiKey, $currentFormula, $currentExactMass, $currentPubchemCid, $currentContaminType) = ( undef, undef, undef, undef, undef, undef, undef, undef ) ;
    
    if (!defined $source) {

    	$source = dist_file('Metabolomics-FragNot', 'MaConDa__v1_0.xml');
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
									my $oContaminant = Metabolomics::Fragment::Annotation->refContaminant() ;
									$oContaminant->_setContaminantID($currentId) ;
									$oContaminant->_setContaminantNAME($currentName) ;
									$oContaminant->_setContaminantEXACT_MASS($currentExactMass) ;
									$oContaminant->_setContaminantFORMULA($currentFormula) ;
									$oContaminant->_setContaminantSTD_INCHI($currentInchi) ;
									$oContaminant->_setContaminantSTD_INCHI_KEY($currentInchiKey) ;
									$oContaminant->_setContaminantPUBCHEM_CID($currentPubchemCid) ;
									$oContaminant->_setContaminantTYPE_OF_CONTAMINANT($currentContaminType) ;
									
									$oBank->_addContaminant($oContaminant) ;
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
    return ($oBank) ;
}
### END of SUB


=head2 METHOD getContaminantsFromSource

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
    my ( $oBank ) = ( Metabolomics::Fragment::Annotation->refContaminants() ) ;
    my $twig = undef ;
    my ($currentId, $currentName, $currentInchi, $currentInchiKey, $currentFormula, $currentExactMass, $currentPubchemCid, $currentContaminType) = ( undef, undef, undef, undef, undef, undef, undef, undef ) ;
    
    my ($currentChromatography, $currentExactAdductMass, $currentInstrument, $currentInstrumentType, $currentIonForm, $currentIonMode, $currentIonSourceType, $currentReference, $currentMz) = ( undef, undef, undef, undef, undef, undef, undef, undef, undef ) ;    
    
    if (!defined $source) {

    	$source = dist_file('Metabolomics-FragNot', 'MaConDa__v1_0__extensive.xml');
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
									my $oContaminant = Metabolomics::Fragment::Annotation->refContaminant() ;
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
									
									$oBank->_addContaminant($oContaminant) ;
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
    return ($oBank) ;
}
### END of SUB


=head2 METHOD extractContaminantTypes

	## Description : extract contaminant types listing from contaminants object
	## Input : $oContaminants
	## Output : $contaminantTypes
	## Usage : my ( $contaminantTypes ) = extractContaminantTypes ( $oContaminants ) ;
	
=cut
## START of SUB
sub extractContaminantTypes {
    ## Retrieve Values
#    my $self = shift ;
    my ( $oContaminants ) = @_;
    my ( %contaminantTypes ) = ( () ) ;
    
#    print Dumper $oContaminants ;
	my $contaminants = $oContaminants->_getContaminants();
    
    if ( (defined $oContaminants )  ) {
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

=head2 METHOD extractContaminantInstruments

	## Description : extract instruments listing from contaminants object
	## Input : $oContaminants
	## Output : $contaminantInstruments
	## Usage : my ( $contaminantInstruments ) = extractContaminantInstruments ( $oContaminants ) ;
	
=cut
## START of SUB
sub extractContaminantInstruments {
    ## Retrieve Values
#    my $self = shift ;
    my ( $oContaminants ) = @_;
    my ( %contaminantInstruments ) = ( () ) ;
    
#    print Dumper $oContaminants ;
	my $contaminants = $oContaminants->_getContaminants();
    
    if ( (defined $oContaminants )  ) {
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

=head2 METHOD extractContaminantInstrumentTypes

	## Description : extract instrument types listing from contaminants object
	## Input : $oContaminants
	## Output : $contaminantInstrumentTypes
	## Usage : my ( $contaminantInstrumentTypes ) = extractContaminantInstrumentTypes ( $oContaminants ) ;
	
=cut
## START of SUB
sub extractContaminantInstrumentTypes {
    ## Retrieve Values
#    my $self = shift ;
    my ( $oContaminants ) = @_;
    my ( %contaminantInstrumentTypes ) = ( () ) ;
    
#    print Dumper $oContaminants ;
	my $contaminants = $oContaminants->_getContaminants();
    
    if ( (defined $oContaminants )  ) {
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

=head2 METHOD filterContaminantIonMode

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
    		$oFilteredBank = Metabolomics::Fragment::Annotation->refContaminants() ;
    		
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

=head2 METHOD filterContaminantInstruments

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
    		
    		$oFilteredBank = Metabolomics::Fragment::Annotation->refContaminants() ;
    		
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

=head2 METHOD filterContaminantInstrumentTypes

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
    		
    		$oFilteredBank = Metabolomics::Fragment::Annotation->refContaminants() ;
    		
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


=head2 METHOD buildTheoPeakBankFromFragments

	## Description : building a bank integrating each potential fragments from a parent ion
	## Input : $refBank, $mzParent
	## Output : $ionBank
	## Usage : my ( $ionBank ) = buildTheoPeakBankFromFragments ( $refBank, $mzParent ) ;
	
=cut
## START of SUB
sub buildTheoPeakBankFromFragments {
    ## Retrieve Values
    my ( $oBank, $mzParent ) = @_;

    my $fragments = $oBank->_getFragments();
    
    my @fragmentsList = () ; 

    foreach my $fragment (@{$fragments}) {
    	## Addition ion mz and theo fragment and filter negative obtained mz
    	
    	my $fragMass = $fragment->_getDELTA_MASS() ;
    	
    	# arround the result with min decimal part of the two floats. 
    	my $decimalLength = _getSmallestDecimalPartOf2Numbers($fragMass, $mzParent) ;
    	my $computedMass = ($mzParent + $fragMass)  ;
    	$computedMass = sprintf("%.$decimalLength"."f", $computedMass );
    	
    	if ($computedMass > 0) {
    		my $oPeak = Metabolomics::Fragment::Annotation->refPeak() ;
	    	$oPeak->_setCOMPUTED_MONOISOTOPIC_MASS ( $computedMass );
	    	$oPeak->_setANNOTATION_TYPE ( $fragment->_getTYPE() );
	    	$oPeak->_setANNOTATION_NAME ( $fragment->_getLOSSES_OR_GAINS() );
#	    	$oPeak->_setANNOTATION_IN_NEG_MODE ( $fragment->_getANNOTATION_IN_NEG_MODE() );
#	    	$oPeak->_setANNOTATION_IN_POS_MODE ( $fragment->_getANNOTATION_IN_POS_MODE() );
	    	
#	    	push(@fragmentsList, $oPeak) ;
	    	$oBank->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
    	}
    } ## END FOREACH
#    print Dumper $oBank ;
}
### END of SUB

=head2 METHOD buildTheoPeakBankFromContaminants

	## Description : building a bank integrating each potential ion from contaminants
	## Input : $refBank, $oContaminants, $queryMode
	## Output : $ionBank
	## Usage : my ( $ionBank ) = buildTheoPeakBankFromContaminants ( $refBank, $oContaminants, $queryMode ) ;
	
=cut
## START of SUB
sub buildTheoPeakBankFromContaminants {
    ## Retrieve Values
    my ( $oBank, $oContaminants, $queryMode ) = @_;
    
    my $contaminants = $oContaminants->_getContaminants() ;
    
    
    foreach my $oContaminant (@{$contaminants}) {
    	## map contaminant object with peak object
    	
#    	print Dumper $oContaminant ;
    	
    	my $oPeak = Metabolomics::Fragment::Annotation->refPeak() ;
    	my $mass = undef ;
    	
    	## should be ION | NEUTRAL -> getting different source of data in mapping
    	if ( (defined $queryMode) and ($queryMode eq "NEUTRAL") ) {
    		$mass = $oContaminant->_getContaminantEXACT_MASS() ;
    		$oPeak->_setCOMPUTED_MONOISOTOPIC_MASS ($mass) if ( defined $mass ) ;
    	}
    	elsif ( (defined $queryMode) and ($queryMode eq "ION") ) {
    		$mass = $oContaminant->_getContaminantExtEXACT_ADDUCT_MASS() ;
    		
    		## in case found no value for the adduct mass -> get the MZ value...
    		if ( !defined $mass ) {
    			$mass = $oContaminant->_getContaminantExtMZ() ;
    			$oPeak->_setCOMPUTED_MONOISOTOPIC_MASS ($mass) if ( defined $mass ) ;
    		}
    		else {
    			$oPeak->_setCOMPUTED_MONOISOTOPIC_MASS ($mass) if ( defined $mass ) ;
    		}	
    	}
    	else {
    		croak "This mode does not exist ($queryMode)\n" ;
    	}
    	# _ION_MODE_ shoulbe NEG | POS and is linked to _ION_FORM_ and mapping ANNOTATION
    	my $ionMode = $oContaminant->_getContaminantExtION_MODE() ;
    	my $ionForm = $oContaminant->_getContaminantExtION_FORM() ;
    	
    	if ( (defined $ionMode ) and ( $ionMode eq 'NEG')   ){	$oPeak->_setANNOTATION_IN_NEG_MODE($ionForm) ; }
    	elsif ( (defined $ionMode ) and ( $ionMode eq 'POS') ){ $oPeak->_setANNOTATION_IN_POS_MODE($ionForm) ; }
    	
    	# _TYPE_OF_CONTAMINANT_
    	my $type = $oContaminant->_getContaminantExtTYPE_OF_CONTAMINANT() ;
    	$oPeak->_setANNOTATION_TYPE ( $type )  if ( defined $type ) ; 
    	
    	# _NAME_
    	my $name = $oContaminant->_getContaminantNAME() ;
	    $oPeak->_setANNOTATION_NAME ( $name )  if ( defined $name ) ;
	    
	    # _ID_
    	my $id = $oContaminant->_getContaminantID() ;
	    $oPeak->_setANNOTATION_ID ( $id )  if ( defined $id ) ;
    	
    	## If every run -> push the well completed object !
    	if ( (defined $mass) and ( $mass > 0 ) ) { $oBank->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ; }
    }
}
### END of SUB

=head2 METHOD parsingMsFragments

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
    
    my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
    
    ## Adapte the number of the colunm : (nb of column to position in array)
	$column = $column - 1 ;
    
    open (CSV, "<", $Xfile) or die $! ;
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
    	
    	my $oPeak = Metabolomics::Fragment::Annotation->refPeak() ;
	    $oPeak->_setMESURED_MONOISOTOPIC_MASS ( $mz );
#	    $oPeak->_setANNOTATION_TYPE (  );
#	    $oPeak->_setANNOTATION_NAME (  );
#	    $oPeak->_setANNOTATION_IN_NEG_MODE (  );
#	    $oPeak->_setANNOTATION_IN_POS_MODE (  );
    	
    	$oBank->_addPeakList('_EXP_PEAK_LIST_', $oPeak) ;
    }
    
}
### END of SUB

=head2 METHOD _parsingW4mTabularFile

	## Description : parsing a full W4M variable metadata tabular file and create a array of arrats object
	## Input : $inputTabularFile
	## Output : $oVariableMetadataTable
	## Usage : my ( $oVariableMetadataTable ) = parsingW4mTabularFile ( $inputTabularFile ) ;
	
=cut
## START of SUB
sub _parsingW4mTabularFile {
    ## Retrieve Values
    my ( $inputTabularFile, $keepHeader ) = @_;
    my ( @oVariableMetadataTable ) = ( () ) ;
    
    my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
    
    my @csv_matrix = () ;
    my $line = 0 ;
    
	open my $fh, "<:encoding(utf8)", $inputTabularFile or die "Can't open csv file $inputTabularFile: $!";
	
	while ( my $row = $csv->getline( $fh ) ) {
		$line++ ;
		if ( (defined $keepHeader) and ($keepHeader eq 'FALSE') and ($line == 1 )  ) {
			next ;
		}
		else {
			push @oVariableMetadataTable, $row;
		}
	}
	$csv->eof or $csv->error_diag();
	close $fh;
    
    return (\@oVariableMetadataTable) ;
}
### END of SUB


=head2 METHOD compareExpMzToTheoMzList

	## Description : comparing two lists of mzs (theo and experimental) with a delta
	## Input : $oBank, $deltaValue, $deltaType
	## Output : NA
	## Usage : my ( $var4 ) = compareExpMzToTheoMzList ( $var3 ) ;
	
=cut
## START of SUB
sub compareExpMzToTheoMzList {
    ## Retrieve Values
    my $self = shift ;
    my ($deltaType, $deltaValue ) = @_ ;
    
    my $expFragments = $self->_getPeakList('_EXP_PEAK_LIST_') ;
    my $theoFragments = $self->_getPeakList('_THEO_PEAK_LIST_') ;
    
#    print Dumper $expFragments ;
#    print Dumper $theoFragments ;
    
    if (  ( scalar (@{$expFragments}) > 0 ) and  ( scalar (@{$theoFragments}) > 0 ) ) {
    	
    	foreach my $expFrag (@{$expFragments}) {
    		
    		my $fragMz = $expFrag->_getMESURED_MONOISOTOPIC_MASS();
    		my ($min, $max) = _mz_delta_conversion (\$fragMz, \$deltaType, \$deltaValue) ; 
    		
#    		print "FOR frag $fragMz - MIN is: $$min and MAX is: $$max\n" ;
    		
    		foreach my $theoFrag (@{$theoFragments}) {
    			
    			my $motifMz = $theoFrag-> _getCOMPUTED_MONOISOTOPIC_MASS();
    			
    			if (  ($motifMz > $$min ) and ($motifMz < $$max)  ) {
    				
#    				print "OK -> $motifMz MATCHING WITH $fragMz\n" ;
    				my $annotName = $theoFrag-> _getANNOTATION_NAME();
    				my $computedMz = $theoFrag->_getCOMPUTED_MONOISOTOPIC_MASS();
    				my $annotType = $theoFrag->_getANNOTATION_TYPE() ;
    				my $annotID = $theoFrag->_getANNOTATION_ID() ;
    				## TODO...
    				
    				my $deltaError = 0 ;
    				# compute error 
    				$deltaError = _computeMzDeltaInMmu($fragMz, $motifMz) ;
    				$expFrag-> _setANNOTATION_DA_ERROR( $deltaError );
    				
    				my $deltaErrorMmu = _computeMzDeltaInMmu($fragMz, $motifMz) ;
    				$deltaError = _computeMzDeltaInPpm($fragMz, $deltaErrorMmu) ;
    				$expFrag-> _setANNOTATION_PPM_ERROR( $deltaError );
    				
    				$expFrag-> _setANNOTATION_NAME( $annotName );
    				$expFrag-> _setCOMPUTED_MONOISOTOPIC_MASS( $computedMz );
    				$expFrag-> _setANNOTATION_TYPE( $annotType );
    				$expFrag-> _setANNOTATION_ID( $annotID ) if (defined $annotID);
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
    
    my $peakList = $self->_getPeakList('_EXP_PEAK_LIST_') ;
    
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

    my $peakList = $self->_getPeakList('_EXP_PEAK_LIST_') ;
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
    		if ($peak->{$field}) 	{	$tmp{$field} = $peak->{$field}  ; }
    		else 					{	$tmp{$field} = 'NA'  ; }
    	}

    	push (@rows, \%tmp) ;
    }
    return (\@rows) ;
}
### END of SUB



=head2 METHOD utilsAsConf

	## Description : build a conf from a conf file with KEY=VALUE structure
	## Input : $file
	## Ouput : $oConf (a hash)
	## Usage : my ( $oConf ) = utilsAsConf( $file ) ;
	
=cut
## START of SUB
sub utilsAsConf {
	## Retrieve Values
    my $self = shift ;
    my ( $file, $separator ) = @_ ;
    
#    if (!defined $separator) { $separator = ';' } ## set separator to ;
    
    if ( !defined $file )  {  croak "Can't create object with an none defined file\n" ; }
    
    my %Conf = () ; ## Hash devant contenir l'ensemble des parametres locaux
	
	if (-e $file) {
		open (CFG, "<$file") or die "Can't open $file\n" ;
		while (<CFG>) {
			chomp $_ ;
			if ( $_ =~ /^#(.*)/)  {	next ; }
			elsif ($_ =~/^(\w+?)=(.*)/) { ## ALPHANUMERIC OR UNDERSCORE ONLY FOR THE KEY AND ANYTHING ELSE FOR VALUE
				
				my ($key, $value) = ($1, $2) ;
				
				if (defined $separator) {
					if ( $value=~/$separator/ ) { ## is a list to split
						my @tmp = split(/$separator/ , $value) ;
						$Conf{$key} = \@tmp ;
					}
				}
				else {
					$Conf{$key} = $value ;
				}
			}
		}
		close(CFG) ;
	}
	else { 
		croak "Can't create object with an none existing file\n" ;
	}
	
    return ( \%Conf ) ;
}
## END of SUB


=head2 METHOD _getSmallestDecimalPartOf2Numbers

	## Description : get the smallest decimal part of two numbers
	## Input : $float01, $float02
	## Output : $commonLenghtDecimalPart
	## Usage : my ( $commonLenghtDecimalPart ) = _getSmallestDecimalPartOf2Numbers ( $float01, $float02 ) ;
	
=cut
## START of SUB
sub _getSmallestDecimalPartOf2Numbers {
    ## Retrieve Values
    my ( $float01, $float02 ) = @_;

    my ($smallestDecimalPart, $nbDecimalFloat01, $nbDecimalFloat02) = (0, 0, 0) ;
    
    my @decimalPart01 = split (/\./, $float01) ;
    my @decimalPart02 = split (/\./, $float02) ;
    
    if ($#decimalPart01+1 == 1) 	{	$nbDecimalFloat01 = 0 ; }
    else 							{ 	$nbDecimalFloat01 = length ($decimalPart01[1]) ; }
    
    if ($#decimalPart02+1 == 1) 	{	$nbDecimalFloat02 = 0 ; }
    else 							{ 	$nbDecimalFloat02 = length ($decimalPart02[1]) ; }
    	
    	## get the smallest number
    if ( $nbDecimalFloat01 >= $nbDecimalFloat02 ) { $smallestDecimalPart = $nbDecimalFloat02 ; }
    if ( $nbDecimalFloat02 >= $nbDecimalFloat01 ) { $smallestDecimalPart = $nbDecimalFloat01 ; }

    return ($smallestDecimalPart) ;
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
    	my $decimalLength = _getSmallestDecimalPartOf2Numbers($expMz, $calcMz) ;
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
    my ( $mzDeltaPpm ) = ( 0 ) ;
    
#    print "$calcMz -> $mzDeltaMmu\n" ;
    
    if ( ($calcMz > 0 ) and ($mzDeltaMmu >= 0) ) {
    	$mzDeltaPpm = ($mzDeltaMmu/$calcMz) * (10**6 ) ;
    	#Perform a round at int level
#    	print "\t$mzDeltaPpm\n";
    	$mzDeltaPpm = _roundFloat($mzDeltaPpm, 0) ;
    	
    }
    else {
    	carp "[ERROR Given masses are null\n" ;
    }
    
    return ($mzDeltaPpm) ;
}
### END of SUB

=head2 METHOD _roundFloat

	## Description : round a float by the sended decimal
	## Input : $number, $decimal
	## Output : $round_num
	## Usage : my ( $round_num ) = round_num( $number, $decimal ) ;
	
=cut
## START of SUB 
sub _roundFloat {
    ## Retrieve Values
    my ( $number, $decimal ) = @_ ;
    my $round_num = 0 ;
    
	if ( ( defined $decimal ) and ( $decimal > -1 ) and ( defined $number ) and ( $number > 0 ) ) {
        $round_num = sprintf("%.".$decimal."f", $number);	## on utilise un arrondit : 5.3 -> 5 et 5.5 -> 6
	}
	elsif ( ( defined $decimal ) and ( $decimal > -1 ) and ( defined $number ) and ( $number == 0 ) ) {
		$round_num = 0 ;
	}
	else {
		croak "Can't round any number : missing value or decimal\n" ;
	}
    
    return($round_num) ;
}
## END of SUB


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
