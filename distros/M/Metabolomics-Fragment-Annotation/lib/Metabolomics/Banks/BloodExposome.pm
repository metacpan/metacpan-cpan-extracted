package Metabolomics::Banks::BloodExposome ;

use 5.006;
use strict;
use warnings;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../..";  # use the parent directory

use Exporter qw(import);

use Data::Dumper ;
use Text::CSV ;
use XML::Twig ;
use File::Share ':all'; 
use Carp qw (cluck croak carp) ;

use base qw( Metabolomics::Banks ) ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Banks::BloodExposome ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	getMetabolitesFromSource buildTheoPeakBankFromEntries
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	getMetabolitesFromSource buildTheoPeakBankFromEntries
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks::BloodExposome - Perl extension for BloodExposome bank 

=head1 VERSION

Version 0.2 - Adding POD
Version 0.3 - Completing object properties

=cut

our $VERSION = '0.3';


=head1 SYNOPSIS

    use Metabolomics::Banks::BloodExposome;

=head1 DESCRIPTION

	Metabolomics::Banks::BloodExposome is a full package for Perl allowing to build a generic Perl bank object from Blood exposome bank resource.
	

=head1 EXPORT

use Metabolomics::Banks::BloodExposome qw( :all ) ;

=head1 PUBLIC METHODS 

=head2 Metabolomics::Fragment::Annotation

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
    
    $self->{_DATABASE_NAME_} = 'Blood Exposome' ;
    $self->{_DATABASE_VERSION_} = '1.0' ;
    $self->{_DATABASE_ENTRIES_NB_} = 'database_entries_nb' ;
    $self->{_DATABASE_URL_} = 'http://bloodexposome.org/' ;
    $self->{_DATABASE_URL_CARD_} = 'https://pubchem.ncbi.nlm.nih.gov/#query=' ; # BloodExposome is linked with pubchem CID
    $self->{_DATABASE_TYPE_} = 'METABOLITE' ;
    $self->{_POLARITY_} =  $args->{POLARITY} ;
    $self->{_DATABASE_DOI_} = 'database_doi' ;
    ## _DATABASE_ENTRIES_
    bless($self) ;
    return $self ;
}
### END of SUB

=item getMetabolitesFromSource

	## Description : get the list of metabolite entries from $source file and set the Metabolomics::Banks::BloodExposome object
	## Input : $source (file from the metabolomics-references project)
	## Output : an int as $entriesNb
	## Usage : my ( $entriesNb ) = $self->getMetabolitesFromSource ( $source ) ;

=cut

## START of SUB
sub getMetabolitesFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $source ) = @_;
    
    my $entriesNb = 0 ;
    
    if (!defined $source) {

    	$source = dist_file('Metabolomics-Fragment-Annotation', 'BloodExposome_v1_0.txt');
    	if (-e $source) {
    		print "loading $source...\n" ;
    	}
    	else {
    		croak "The source file ($source) does not exist at this path\n" ;
    	}
    }
    
    if ( (defined $source) and (-e $source) ) {
    	
    	my $oEntry = $self->__refBloodExposomeEntry__() ;
    	
		## format of ref file is in version 1.0 :
		my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    		or die "Cannot use CSV: ".Text::CSV->error_diag ();
    	
    	open my $fh, "<", $source or die "$source: $!";
    	
		## Checking header of the source file   	
    	$csv->header ($fh, { munge_column_names => sub {
		    s/\s+$//;
		    s/^\s+//;
		    my $uc_col = '_'.uc$_.'_' ;
		    if ($_ ne 'example_valine' ) {
		    	$oEntry->{$uc_col} or die "Unknown column '$uc_col' in $source";
		    }
		 }});
		
    	while (my $row = $csv->getline_hr ($fh)) {
    		my $currentEntry = $self->__refBloodExposomeEntry__() ;
    		## TODO getter/setter...
    		$currentEntry->{_PUBCHEM_CID_} = $row->{'pubchem_cid'} ;
    		$currentEntry->{_COMPOUND_NAME_} = $row->{'compound_name'} ;
    		$currentEntry->{_KEGG_ID_} = $row->{'kegg_id'} ;
    		$currentEntry->{_HMDB_ID_} = $row->{'hmdb_id'} ;
    		$currentEntry->{_MOLECULAR_FORMULA_} = $row->{'molecular_formula'} ;
    		$currentEntry->{_CANONICAL_SMILES_} = $row->{'canonical_smiles'} ;
    		$currentEntry->{_INCHIKEY_} = $row->{'inchikey'} ;
    		$currentEntry->{_MULTI_COMPONENT_} = $row->{'multi_component'} ;
    		$currentEntry->{_XLOGP_} = $row->{'xlogp'} ;
    		$currentEntry->{_EXACT_MASS_} = $row->{'exact_mass'} ;
    		$currentEntry->{_CHARGE_} = $row->{'charge'} ;
    		
    		$self->_addEntry($currentEntry) ;
    		$entriesNb ++ ;
    	}
    }
    else {
    	 croak "The source file does not exist ($source) or is not defined\n" ;
    }
#    print Dumper $oBank ;
    return ($entriesNb) ;
}
### END of SUB

=item METHOD buildTheoPeakBankFromEntries

	## Description : building from a Metabolomics::Banks::BloodExposome object, a bank integrating each potential entry in a metabolomics format (POSITIVE or NEGATIVE forms)
	## Input : $queryMode [POS|NEG]
	## Output : int as $entryNb
	## Usage : my $nb = $oBank->buildTheoPeakBankFromEntries() ;

=cut

## START of SUB
sub buildTheoPeakBankFromEntries {
    ## Retrieve Values
    my $self = shift ;
    
    my ( $queryMode ) = @_;
    my $mode = undef ;

    my $entries = $self->_getEntries();
        
    my $entryNb = 0 ; 

    foreach my $entry (@{$entries}) {
    	
#    	print Dumper $entry ;
    	
    	## get mz and compute the mz depending of charge and ionisation mode
    	my $entryMass = $entry->_getEntry_EXACT_MASS() ;
    	my $entryCharge = $entry->_getEntry_CHARGE() ;
    	
    	my $oPeak = Metabolomics::Banks->__refPeak__() ;
    	
    	# Charge manager
    	## Manage and compute mz depending NEG/POS mode used
    	if   	( ( $queryMode eq 'POSITIVE' )  ) 		{ $mode = 'POS' ; }
    	elsif   ( ( $queryMode eq 'NEGATIVE' )  ) 		{ $mode = 'NEG' ; }
    	elsif   	( ( $queryMode eq 'POS' )  ) 		{ $mode = 'POS' ; }
    	elsif   	( ( $queryMode eq 'NEG' )  ) 		{ $mode = 'NEG' ; }
    	elsif   	( ( $queryMode eq 'POSITIF' )  ) 	{ $mode = 'POS' ; }
    	elsif   	( ( $queryMode eq 'NEGATIF' )  ) 	{ $mode = 'NEG' ; }
    	else 											{ croak "This ion mode is unknown: $queryMode\n" ; }
    	
    	if ( (!defined $mode) or ( ( $mode ne 'NEG' ) and ( $mode ne 'POS' ) ) ) {
    		croak "[ERROR] The ion mode ($queryMode) is not recognize by buildTheoPeakBankFromEntries method and internal mode can not be set\n" ;
    	}
    	
    	## Compound has a positive charge - it will be only seen in POS mode
    	if ($entryCharge > 0) {
    		
    		if ( (defined $mode) and ( $mode eq 'POS' ) ) {
    			$oPeak->_setPeak_ANNOTATION_ONLY_IN ( 'POS' ); 
    			$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $entryMass );
    		}
    		else {
    			next ;
    		}
    	} 
    	## Compound has a negative charge - it will be only seen in NEG mode
    	elsif ($entryCharge < 0) {
    		
    		if ( (defined $mode) and ( $mode eq 'NEG' ) ) {
    			$oPeak->_setPeak_ANNOTATION_ONLY_IN ( 'NEG' );
    			$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $entryMass );
    		}
    		else {
    			next ;
    		}
    	}
    	## Compound has no charge - its mz will be computed depending the acquisition mode
    	elsif  ($entryCharge == 0) {
	    	
	    	my $computedMz = undef ;
	    	
	    	if ( (defined $mode) and ( $mode eq 'POS' ) ) {
	    		$computedMz = Metabolomics::Banks->computeNeutralCpdMz_To_PositiveIonMz($entryMass) ;
	    	}
	    	
	    	elsif ( (defined $mode) and ( $mode eq 'NEG' ) ) {
	    		$computedMz = Metabolomics::Banks->computeNeutralCpdMz_To_NegativeIonMz($entryMass) ;
	    	}
    		
    		$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMz );
    	}
    	
    	## set all others properties
	    $oPeak->_setPeak_ANNOTATION_NAME ( $entry->_getEntry_COMPOUND_NAME() );
	    $oPeak->_setPeak_ANNOTATION_FORMULA ( $entry->_getEntry_MOLECULAR_FORMULA() );
	    $oPeak->_setPeak_ANNOTATION_SMILES ( $entry->_getEntry_CANONICAL_SMILES() );
	    $oPeak->_setPeak_ANNOTATION_INCHIKEY ( $entry->_getEntry_INCHIKEY() );
	    $oPeak->_setPeak_ANNOTATION_ID ( 'CID'.$entry->_getEntry_PUBCHEM_CID() );
	    
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

=head2 Metabolomics::Banks::BloodExposome

=over 4

=item PRIVATE_ONLY __refBloodExposomeEntry__

	## Description : init a new blood exposome entry
	## Input : void	
	## Output : refEntry
	## Usage : $self->__refBloodExposomeEntry__() ;

=cut

## START of SUB
sub __refBloodExposomeEntry__ {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_PUBCHEM_CID_} = 'pubchem_cid' ; # 
    $self->{_COMPOUND_NAME_} = 'compound_name' ; # 
	$self->{_KEGG_ID_} = 'kegg_id' ;
	$self->{_HMDB_ID_} = 'hmdb_id' ;
	$self->{_MOLECULAR_FORMULA_} = 'molecular_formula' ;
	$self->{_CANONICAL_SMILES_} = 'canonical_smiles' ;
	$self->{_INCHIKEY_} = 'inchikey' ;
	$self->{_MULTI_COMPONENT_} = 'multi_component' ;
	$self->{_XLOGP_} = 'xlogp' ;
    $self->{_EXACT_MASS_} = 'exact_mass' ;
    $self->{_CHARGE_} = 'charge' ;

    return $self ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_EXACT_MASS

	## Description : PRIVATE method _getEntry_EXACT_MASS on a refBloodExposomeEntry object
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
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_EXACT_MASS get a undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_CHARGE

	## Description : PRIVATE method _getEntry_CHARGE on a refBloodExposomeEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_CHARGE () ;

=cut

## START of SUB
sub _getEntry_CHARGE {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_CHARGE_}) and ( $self->{_CHARGE_} > 0  or $self->{_CHARGE_} < 0 or $self->{_CHARGE_} == 0 )   ) {	$VALUE = $self->{_CHARGE_} ; }
    else {	 $VALUE = 0 ; warn "[WARN] the method _getEntry_CHARGE get an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_COMPOUND_NAME

	## Description : PRIVATE method _getEntry_COMPOUND_NAME on a refBloodExposomeEntry object
	## Input : void
	## Output : $COMPOUND_NAME
	## Usage : my ( $COMPOUND_NAME ) = $entry->_getEntry_COMPOUND_NAME () ;

=cut

## START of SUB
sub _getEntry_COMPOUND_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_COMPOUND_NAME_}) and ( $self->{_COMPOUND_NAME_} ne '' ) ) {	$VALUE = $self->{_COMPOUND_NAME_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_COMPOUND_NAME get an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_MOLECULAR_FORMULA

	## Description : PRIVATE method _getEntry_MOLECULAR_FORMULA on a refBloodExposomeEntry object
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
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_MOLECULAR_FORMULA get an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_CANONICAL_SMILES

	## Description : PRIVATE method _getEntry_CANONICAL_SMILES on a refBloodExposomeEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_CANONICAL_SMILES () ;

=cut

## START of SUB
sub _getEntry_CANONICAL_SMILES {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_CANONICAL_SMILES_}) and ( $self->{_CANONICAL_SMILES_} ne '' ) ) {	$VALUE = $self->{_CANONICAL_SMILES_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_CANONICAL_SMILES get an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_INCHIKEY

	## Description : PRIVATE method _getEntry_INCHIKEY on a refBloodExposomeEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_INCHIKEY () ;

=cut

## START of SUB
sub _getEntry_INCHIKEY {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_INCHIKEY_}) and ( $self->{_INCHIKEY_} ne '' ) ) {	$VALUE = $self->{_INCHIKEY_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_INCHIKEY get an undef value\n" ; }
    
    return ( $VALUE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_PUBCHEM_CID

	## Description : PRIVATE method _getEntry_PUBCHEM_CID on a refBloodExposomeEntry object
	## Input : void
	## Output : $VALUE
	## Usage : my ( $VALUE ) = $entry->_getEntry_PUBCHEM_CID () ;

=cut

## START of SUB
sub _getEntry_PUBCHEM_CID {
    ## Retrieve Values
    my $self = shift ;
    
    my $VALUE = undef ;
    
    if ( (defined $self->{_PUBCHEM_CID_}) and ( $self->{_PUBCHEM_CID_} ne '' ) ) {	$VALUE = $self->{_PUBCHEM_CID_} ; }
    else {	 $VALUE = undef ; warn "[WARN] the method _getEntry_PUBCHEM_CID get an undef value\n" ; }
    
    return ( $VALUE ) ;
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

1; # End of Metabolomics::Banks::BloodExposome
