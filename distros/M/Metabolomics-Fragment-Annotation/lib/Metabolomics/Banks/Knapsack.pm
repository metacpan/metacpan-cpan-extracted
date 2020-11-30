package Metabolomics::Banks::Knapsack ;

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

require Exporter;
 
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Banks::Knapsack ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	getKSMetabolitesFromSource buildTheoPeakBankFromKnapsack
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	getKSMetabolitesFromSource buildTheoPeakBankFromKnapsack
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks::Knapsack - Perl extension for Knapsack bank 

=head1 VERSION

Version 0.2 - Adding POD

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

    use Metabolomics::Banks::Knapsack;

=head1 DESCRIPTION

	Metabolomics::Banks::Knapsack is a full package for Perl allowing to build a generic Perl bank object from Knapsack bank resource.

=head1 EXPORT

	use Metabolomics::Banks::Knapsack qw( :all ) ;

=head1 PUBLIC METHODS 

=head2 Metabolomics::Banks::Knapsack

=over 4

=item new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my $self={};
    
    $self = Metabolomics::Banks->new() ;
    
    $self->{_DATABASE_NAME_} = 'Knapsack' ;
    $self->{_DATABASE_VERSION_} = '1.1' ;
    $self->{_DATABASE_ENTRIES_NB_} = 51187 ;
    $self->{_DATABASE_URL_} = 'http://www.knapsackfamily.com/KNApSAcK_Family/' ;
    $self->{_DATABASE_DOI_} = '10.1093/pcp/pct176' ;
    ## _DATABASE_ENTRIES_
    bless($self) ;
    return $self ;
}
### END of SUB

=item getMetabolitesFromSource

	## Description : get the list of metabolite entries from $source file and set the Metabolomics::Banks::Knapsack object
	## Input : $source (file from the metabolomics-references project)
	## Output : an int as $entriesNb
	## Usage : my ( $entriesNb ) = $self->getMetabolitesFromSource ( $source ) ;

=cut

## START of SUB
sub getKSMetabolitesFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $source ) = @_;
    
    my $entriesNb = 0 ;
    
    if (!defined $source) {

    	$source = dist_file('Metabolomics-Fragment-Annotation', 'Knapsack__V1_1.csv');
    	if (-e $source) {
    		print "loading $source...\n" ;
    	}
    	else {
    		croak "The source file ($source) does not exist at this path\n" ;
    	}
    }
    
    if ( (defined $source) and (-e $source) ) {
    	
    	my $oEntry = $self->__refKnapsackEntry__() ;
    	
		## format of ref file is in version 1.0 :
		my $csv = Text::CSV->new ( { 'sep_char' => ',', binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
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
		# knapsackid,name,formula,mw,cas,inchikey
    	while (my $row = $csv->getline_hr ($fh)) {
    		
#    		print Dumper $row ;
    		
    		my $currentEntry = $self->__refKnapsackEntry__() ;
    		## TODO getter/setter...
    		$currentEntry->{_KNAPSACK_ID_} = $row->{'knapsack_id'} ;
    		$currentEntry->{_COMPOUND_NAME_} = $row->{'compound_name'} ;
    		$currentEntry->{_MOLECULAR_FORMULA_} = $row->{'molecular_formula'} ;
    		$currentEntry->{_INCHIKEY_} = $row->{'inchikey'} ;
    		$currentEntry->{_CAS_} = $row->{'cas'} ;
    		$currentEntry->{_EXACT_MASS_} = $row->{'exact_mass'} ;
    		
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

	## Description : building from a Metabolomics::Banks::Knapsack object, a bank integrating each potential entry in a metabolomics format (POSITIVE or NEGATIVE forms)
	## Input : $queryMode [POS|NEG]
	## Output : int as $entryNb
	## Usage : my $nb = $oBank->buildTheoPeakBankFromEntries() ;

=cut

## START of SUB
sub buildTheoPeakBankFromKnapsack {
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
    	
    	## KnapSack compound information do not integrate charge information
    	    	
	    my $computedMz = undef ;
	    	
	    if ( (defined $mode) and ( $mode eq 'POS' ) ) {
	    	$computedMz = Metabolomics::Banks->computeNeutralCpdMz_To_PositiveIonMz($entryMass) ;
	    	$oPeak->_setPeak_ANNOTATION_TYPE('[M+H]+')
	    }
	    
	    elsif ( (defined $mode) and ( $mode eq 'NEG' ) ) {
	    	$computedMz = Metabolomics::Banks->computeNeutralCpdMz_To_NegativeIonMz($entryMass) ;
	    	$oPeak->_setPeak_ANNOTATION_TYPE('[M-H]-')
	    }
    	#_MZ_
    	$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMz );
    	#_COMPOUND_NAME_
	    $oPeak->_setPeak_ANNOTATION_NAME ( $entry->_getEntry_COMPOUND_NAME() );
	    #_BANK_ID_
	    $oPeak->_setPeak_ANNOTATION_ID ( $entry->_getEntry_KNAPSACK_ID() );
	    #_MOLECULAR_FORMULA_
	    $oPeak->_setPeak_ANNOTATION_FORMULA ( $entry->_getEntry_MOLECULAR_FORMULA() );
	    
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

=head2 Metabolomics::Banks::Knapsack

=over 4

=item PRIVATE_ONLY __refKnapsackEntry__

	## Description : init a new blood exposome entry
	## Input : void	
	## Output : refEntry
	## Usage : $self->__refKnapsackEntry__() ;

=cut

## START of SUB
sub __refKnapsackEntry__ {
    ## Variables
    my ($class,$args) = @_;
    my $self={};

    bless($self) ;
    
    $self->{_KNAPSACK_ID_} = 'knapsack_id' ; # 
    $self->{_COMPOUND_NAME_} = 'compound_name' ; # 
	$self->{_MOLECULAR_FORMULA_} = 'molecular_formula' ;
	$self->{_INCHIKEY_} = 'inchikey' ;
	$self->{_CAS_} = 'cas' ;
    $self->{_EXACT_MASS_} = 'exact_mass' ;

    return $self ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_INCHIKEY

	## Description : PRIVATE method _getEntry_INCHIKEY on a refKnapsackEntry object
	## Input : void
	## Output : $INCHIKEY
	## Usage : my ( $INCHIKEY ) = $entry->_getEntry_INCHIKEY () ;

=cut

## START of SUB
sub _getEntry_INCHIKEY {
    ## Retrieve Values
    my $self = shift ;
    
    my $INCHIKEY = undef ;
    
    if ( (defined $self->{_INCHIKEY_}) and ( $self->{_INCHIKEY_} > 0 ) or $self->{_INCHIKEY_} < 0  ) {	$INCHIKEY = $self->{_INCHIKEY_} ; }
    else {	 $INCHIKEY = 0 ; warn "[WARN] the method _getEntry_INCHIKEY can't _get a undef or non numerical value\n" ; }
    
    return ( $INCHIKEY ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_EXACT_MASS

	## Description : PRIVATE method _getEntry_EXACT_MASS on a refKnapsackEntry object
	## Input : void
	## Output : $EXACT_MASS
	## Usage : my ( $EXACT_MASS ) = $entry->_getEntry_EXACT_MASS () ;

=cut

## START of SUB
sub _getEntry_EXACT_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $EXACT_MASS = undef ;
    
    if ( (defined $self->{_EXACT_MASS_}) and ( $self->{_EXACT_MASS_} > 0 ) or $self->{_EXACT_MASS_} < 0  ) {	$EXACT_MASS = $self->{_EXACT_MASS_} ; }
    else {	 $EXACT_MASS = 0 ; warn "[WARN] the method _getEntry_EXACT_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $EXACT_MASS ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_KNAPSACK_ID

	## Description : PRIVATE method _getEntry_CAS on a refKnapsackEntry object
	## Input : void
	## Output : $KNAPSACK_ID
	## Usage : my ( $KNAPSACK_ID ) = $entry->_getEntry_KNAPSACK_ID () ;

=cut

## START of SUB
sub _getEntry_KNAPSACK_ID {
    ## Retrieve Values
    my $self = shift ;
    
    my $KNAPSACK_ID = undef ;
    
    if ( ( defined $self->{_KNAPSACK_ID_} ) and ( $self->{_KNAPSACK_ID_} ne '' )   ) {	$KNAPSACK_ID = $self->{_KNAPSACK_ID_} ; }
    else {	 $KNAPSACK_ID = 0 ; warn "[WARN] the method _getEntry_KNAPSACK_ID can't _get a undef or non numerical value\n" ; }
    
    return ( $KNAPSACK_ID ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_CAS

	## Description : PRIVATE method _getEntry_CAS on a refKnapsackEntry object
	## Input : void
	## Output : $CAS
	## Usage : my ( $CAS ) = $entry->_getEntry_CAS () ;

=cut

## START of SUB
sub _getEntry_CAS {
    ## Retrieve Values
    my $self = shift ;
    
    my $CAS = undef ;
    
    if ( (defined $self->{_CAS_}) and ( $self->{_CAS_} > 0  or $self->{_CAS_} < 0 or $self->{_CAS_} == 0 )   ) {	$CAS = $self->{_CAS_} ; }
    else {	 $CAS = 0 ; warn "[WARN] the method _getEntry_CAS can't _get a undef or non numerical value\n" ; }
    
    return ( $CAS ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_MOLECULAR_FORMULA

	## Description : PRIVATE method _getEntry_MOLECULAR_FORMULA on a refKnapsackEntry object
	## Input : void
	## Output : $COMPOUND_FORMULA
	## Usage : my ( $COMPOUND_FORMULA ) = $entry->_getEntry_MOLECULAR_FORMULA () ;

=cut

## START of SUB
sub _getEntry_MOLECULAR_FORMULA {
    ## Retrieve Values
    my $self = shift ;
    
    my $COMPOUND_FORMULA = undef ;
    
    if ( (defined $self->{_MOLECULAR_FORMULA_}) and ( $self->{_MOLECULAR_FORMULA_} ne '' ) ) {	$COMPOUND_FORMULA = $self->{_MOLECULAR_FORMULA_} ; }
    else {	 $COMPOUND_FORMULA = undef ; warn "[WARN] the method _getEntry_COMPOUND_NAME can't _get a undef or non numerical value\n" ; }
    
    return ( $COMPOUND_FORMULA ) ;
}
### END of SUB

=item PRIVATE_ONLY _getEntry_COMPOUND_NAME

	## Description : PRIVATE method _getEntry_COMPOUND_NAME on a refKnapsackEntry object
	## Input : void
	## Output : $COMPOUND_NAME
	## Usage : my ( $COMPOUND_NAME ) = $entry->_getEntry_COMPOUND_NAME () ;

=cut

## START of SUB
sub _getEntry_COMPOUND_NAME {
    ## Retrieve Values
    my $self = shift ;
    
    my $COMPOUND_NAME = undef ;
    
    if ( (defined $self->{_COMPOUND_NAME_}) and ( $self->{_COMPOUND_NAME_} ne '' ) ) {	$COMPOUND_NAME = $self->{_COMPOUND_NAME_} ; }
    else {	 $COMPOUND_NAME = undef ; warn "[WARN] the method _getEntry_COMPOUND_NAME can't _get a undef or non numerical value\n" ; }
    
    return ( $COMPOUND_NAME ) ;
}
### END of SUB

__END__

=back

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inrae.fr> >>

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

1; # End of Metabolomics::Banks::Knapsack
