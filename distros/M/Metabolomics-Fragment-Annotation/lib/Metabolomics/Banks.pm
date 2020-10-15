package Metabolomics::Banks ;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

use Data::Dumper ;
use Text::CSV ;
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
	__refPeak__
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	__refPeak__
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks - Perl extension to build metabolite banks for metabolomics 

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

    use Metabolomics::Fragment::Annotation;

=head1 DESCRIPTION

	Metabolomics::Fragment::Annotation is a full package for Perl dev allowing full annotation of fragments.
	

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 METHOD new

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
    $self->{_DATABASE_VERSION_} = '1.0' ; ## FLOAT, version number e.g. 1.0
    $self->{_DATABASE_ENTRIES_NB_} = 'database_entries_nb' ; ## INT, number of DB entries - - 
    $self->{_DATABASE_URL_} = 'database_url' ; ## STRING, url to the resource - - mandatory
    $self->{_DATABASE_DOI_} = 'database_doi' ; ## STRING, DOI to the scientific publication
    $self->{_DATABASE_ENTRIES_} = [] ; ## ARRAYS, All entries with metadata
    $self->{_THEO_PEAK_LIST_} = [] ; ## ARRAYS, All theo peaks metadata
    $self->{_EXP_PEAK_LIST_} = [] ; ## ARRAYS, All exp peaks metadata
    
    return ($self) ;
}
### END of SUB


=head2 METHOD set_DATABASE_ENTRIES_NB

	## Description : set_DATABASE_ENTRIES_NB
	## Input : $DATABASE_ENTRIES_NB
	## Output : TRUE
	## Usage : $self->set_DATABASE_ENTRIES_NB ( $DATABASE_ENTRIES_NB ) ;
	
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




=head2 METHOD _addEntry

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

=head2 METHOD _getEntries

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

=head2 METHOD _getTheoricalPeaks

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


=head2 METHOD __refPeak__

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
    $self->{_MESURED_MONOISOTOPIC_MASS_} = 0 ; # mesured accurate mass (for exp peak)
    $self->{_COMPUTED_MONOISOTOPIC_MASS_} = 0 ; # computed accurate mass (for theo peak)
    $self->{_PPM_ERROR_} = 0 ; # FLOAT
    $self->{_MMU_ERROR_} = 0 ; # FLOAT
    $self->{_ANNOTATION_IN_NEG_MODE_} = undef ; # STRING as [M-H]-
    $self->{_ANNOTATION_IN_POS_MODE_} = undef ; # STRING as [M+H]+
    $self->{_ANNOTATION_ONLY_IN_} = undef ; # STRING as [undef|NEG|POS], undef is default
    $self->{_ANNOTATION_TYPE_} = undef ; # STRING as adducts, fragment or isotope
    $self->{_ANNOTATION_NAME_} = undef ; # STRING for metabolite common name
    $self->{_ANNOTATION_FORMULA_} = undef ; # STRING for metabolite molecular formula

    return $self ;
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

#
## * * * * * * * * * * * * * * get/setter * * * * * * * * * * * * * #
#

=head2 METHOD _setPeak_COMPUTED_MONOISOTOPIC_MASS

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

=head2 METHOD _getPeakCOMPUTED_MONOISOTOPIC_MASS

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



=head2 METHOD _setPeakMESURED_MONOISOTOPIC_MASS

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
    
    if ( (defined $MESURED_MONOISOTOPIC_MASS) and ( ($MESURED_MONOISOTOPIC_MASS > 0) or ($MESURED_MONOISOTOPIC_MASS < 0) )  ) {	$self->{_MESURED_MONOISOTOPIC_MASS_} = $MESURED_MONOISOTOPIC_MASS ; }
    else {	carp "[ERROR] the method _setPeakMESURED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getPeakMESURED_MONOISOTOPIC_MASS

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


=head2 METHOD _setANNOTATION_IN_NEG_MODE

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
    else {	carp "[ERROR] the method _setCOMPUTED_MONOISOTOPIC_MASS can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getPeak_ANNOTATION_IN_NEG_MODE

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


=head2 METHOD _setANNOTATION_DA_ERROR

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
sub _setPeak_ANNOTATION_PPM_ERROR {
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
sub _setPeak_ANNOTATION_IN_POS_MODE {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_IN_POS_MODE ) = @_;
    
    if ( (defined $ANNOTATION_IN_POS_MODE) and ($ANNOTATION_IN_POS_MODE ne '')  ) {	$self->{_ANNOTATION_IN_POS_MODE_} = $ANNOTATION_IN_POS_MODE ; }
    else {	carp "[ERROR] the method _setANNOTATION_IN_POS_MODE can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getPeak_ANNOTATION_IN_POS_MODE

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


=head2 METHOD _setPeak_ANNOTATION_TYPE

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
    else {	carp "[ERROR] the method _setPeak_ANNOTATION_TYPE can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _getPeak_ANNOTATION_TYPE

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

=head2 METHOD _setANNOTATION_NAME

	## Description : _setANNOTATION_NAME
	## Input : $ANNOTATION_NAME
	## Output : TRUE
	## Usage : _setANNOTATION_NAME ( $ANNOTATION_NAME ) ;
	
=cut
## START of SUB
sub _setPeak_ANNOTATION_NAME {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_NAME ) = @_;
    
    if ( (defined $ANNOTATION_NAME) and ($ANNOTATION_NAME ne '')  ) {	$self->{_ANNOTATION_NAME_} = $ANNOTATION_NAME ; }
    else {	carp "[ERROR] the method _setPeak_ANNOTATION_NAME can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB


=head2 METHOD _getPeak_ANNOTATION_NAME

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

=head2 METHOD _getPeak_ANNOTATION_ID

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

=head2 METHOD _setANNOTATION_ID

	## Description : _setANNOTATION_ID
	## Input : $ANNOTATION_ID
	## Output : TRUE
	## Usage : _setANNOTATION_ID ( $ANNOTATION_ID ) ;
	
=cut
## START of SUB
sub _setPeak_ANNOTATION_ID {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_ID ) = @_;
    
    if ( (defined $ANNOTATION_ID) and ($ANNOTATION_ID ne '')  ) {	$self->{_ID_} = $ANNOTATION_ID ; }
    else {	carp "[ERROR] the method _setPeak_ANNOTATION_ID can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB

=head2 METHOD _setPeak_ANNOTATION_FORMULA

	## Description : _setPeak_ANNOTATION_FORMULA
	## Input : $ANNOTATION_FORMULA
	## Output : TRUE
	## Usage : $self->_setPeak_ANNOTATION_FORMULA ( $ANNOTATION_ID ) ;
	
=cut
## START of SUB
sub _setPeak_ANNOTATION_FORMULA {
    ## Retrieve Values
    my $self = shift ;
    my ( $ANNOTATION_FORMULA ) = @_;
    
    if ( (defined $ANNOTATION_FORMULA) and ($ANNOTATION_FORMULA ne '')  ) {	$self->{_ANNOTATION_FORMULA_} = $ANNOTATION_FORMULA ; }
    else {	carp "[ERROR] the method _setANNOTATION_FORMULA can't set any undef or non numerical value\n" ; }
    
    return (0) ;
}
### END of SUB





=head2 METHOD _setPeak_ANNOTATION_ONLY_IN

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
    else {	carp "[ERROR] the method _setPeak_ANNOTATION_ONLY_IN can't set any undef or value diff from POS or NEG\n" ; }
    
    return (0) ;
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

=head2 METHOD computeNeutralCpdMz_To_PositiveIonMz

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

=head2 METHOD computeNeutralCpdMz_To_NegativeIonMz

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



__END__

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inra.fr> >>

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


=head1 LICENSE AND COPYRIGHT

CeCILL Copyright (C) 2019 by Franck Giacomoni

Initiated by Franck Giacomoni

followed by INRA PFEM team

Web Site = INRA PFEM


=cut

1; # End of Metabolomics::Banks
