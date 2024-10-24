package Metabolomics::Banks::AbInitioFragments ;

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

# This allows declaration	use Metabolomics::Banks::AbInitioFragments ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	getFragmentsFromSource buildTheoPeakBankFromFragments buildTheoDimerFromMz isotopicAdvancedCalculation
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	getFragmentsFromSource buildTheoPeakBankFromFragments buildTheoDimerFromMz isotopicAdvancedCalculation
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Banks::AbInitioFragments - Perl extension for Ab Initio Fragments generator 

=head1 VERSION

Version 0.3 - Adding POD
Version 0.4 - Updating Fragments/Adducts/isotopes listing
Version 0.5 - Completing object properties

=cut

our $VERSION = '0.5';


=head1 SYNOPSIS

use Metabolomics::Banks::AbInitioFragments;

=head1 DESCRIPTION

Metabolomics::Banks::AbInitioFragments is a full package for Perl allowing to build a generic Perl bank object from Ab Initio fragments resource.

=head1 EXPORT

use Metabolomics::Banks::AbInitioFragments qw( :all ) ;

=head1 PUBLIC METHODS 


=head2 Metabolomics::Banks::AbInitioFragments


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
    
    $self->{_DATABASE_NAME_} = 'Ab Initio Fragments' ;
    $self->{_DATABASE_TYPE_} = 'FRAGMENT' ;
    $self->{_POLARITY_} =  $args->{POLARITY} ;
    $self->{_DATABASE_VERSION_} = '1.0' ;
    $self->{_DATABASE_ENTRIES_NB_} = 'database_entries_nb' ;
    $self->{_DATABASE_URL_} = 'database_url' ;
    $self->{_DATABASE_DOI_} = 'database_doi' ;
    $self->{_FRAGMENTS_} = [] ;
    ## _DATABASE_ENTRIES_
    bless($self) ;
    
    return $self ;
}
### END of SUB


=item METHOD getFragmentsFromSource

	## Description : get the list of theorical fragments from $source file
	## Input : $source
	## Output : $theoFragments
	## Usage : my ( $theoFragments ) = getFragmentsFromSource ( $source ) ;

=cut

## START of SUB
sub getFragmentsFromSource {
    ## Retrieve Values
    my $self = shift ;
    my ( $source ) = @_;
    
    my $entriesNb = 0 ;
    
    if (!defined $source) {
    	
    	
    	if ($VERSION == 0.3) {
    		## v1.0 file
    		$source = dist_file('Metabolomics-Fragment-Annotation', 'MS_fragments-adducts-isotopes.txt');
	    	if (-e $source) {
	    		print "loading v1.0 $source...\n" ;
	    	}
	    	else {
	    		croak "The v1.0 source file ('MS_fragments-adducts-isotopes.txt') does not exist at this path\n" ;
	    	}
    		
    	}
    	elsif ($VERSION >= 0.4) {
    		## v1.0 file
    		$source = dist_file('Metabolomics-Fragment-Annotation', 'MS_fragments-adducts-isotopes__V1.1.txt');
    		
	    	if (-e $source) {
	    		print "loading v1.1 $source...\n" ;
	    	}
	    	else {
	    		croak "The v1.1 source file ('MS_fragments-adducts-isotopes__V1.1.txt') does not exist at this path\n" ;
	    	}
    	}
    }
    
    
    
    if ( (defined $source) and (-e $source) ) {
    	
    	my $oFragment = $self->__refAbInitioFragment__() ;
    	
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
    		my $currentFrag = $self->__refAbInitioFragment__() ;
    		## TODO getter/setter...
    		$currentFrag->{_TYPE_} = $row->{'type'} ;
    		$currentFrag->{_DELTA_MASS_} = $row->{'delta_mass'} ;
    		$currentFrag->{_LOSSES_OR_GAINS_} = $row->{'losses_or_gains'} ;
    		$currentFrag->{_ANNOTATION_IN_POS_MODE_} = $row->{'annotation_in_pos_mode'} ;
    		$currentFrag->{_ANNOTATION_IN_NEG_MODE_} = $row->{'annotation_in_neg_mode'} ;
    		
    		$self->_addFragment($currentFrag);
    		$entriesNb ++ ;
    	}
    }
    else {
    	 croak "The source file does not exist ($source) or is not defined\n" ;
    }
    return ($entriesNb) ;
}
### END of SUB


=item METHOD buildTheoPeakBankFromFragments

	## Description : building a bank integrating each potential fragments from a parent ion
	## Input : $refBank, $mzParent, $mode (POSITIVE, NEGATIVE, NEUTRAL), $stateMolecule (POS, NEG, NEU)
	## Output : $ionBank
	## Usage : my ( $ionBank ) = buildTheoPeakBankFromFragments ( $refBank, $mzParent ) ;

=cut

## START of SUB
sub buildTheoPeakBankFromFragments {
    ## Retrieve Values
    my $self = shift ;
    my ( $mzParent, $mode, $stateMolecule, $isotopicAddingStatus ) = @_;

    my $fragments = $self->_getFragments();

    foreach my $fragment (@{$fragments}) {
    	## Addition ion mz and theo fragment and filter negative obtained mz
    	
    	## Avoid to generate isotopic massif
    	if ( (defined $isotopicAddingStatus) and ($isotopicAddingStatus eq 'FALSE') and ( $fragment->_getFragment_TYPE() eq 'isotope'  ) ) {
    		next ;
    	}
    	
    	my $fragMass = $fragment->_getFragment_DELTA_MASS() ;
    	
    	my $mzToAdjust = $mzParent ;
    	
    	# arround the result with min decimal part of the two floats. 
    	my $oUtils = Metabolomics::Utils->new() ;
    	my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($fragMass, $mzParent) ;
    	
    	## Manage natural charged molecules
    	if ( (defined $mode ) and ( $mode eq 'POSITIVE') and (defined $stateMolecule ) and ($stateMolecule eq 'POSITIVE') ) {
    		
    		if ( $fragment->_getFragment_TYPE() eq 'pseudomolecular ion'  ) {
    			# remove a H
    			$mzToAdjust += sprintf("%.$decimalLength"."f", -1.0072764 ) ;	
    		}

    	}
    	elsif ( (defined $mode ) and ( $mode eq 'NEGATIVE') and (defined $stateMolecule ) and ($stateMolecule eq 'NEGATIVE') ) {
    		
    		if ( $fragment->_getFragment_TYPE() eq 'pseudomolecular ion'  ) {
    			
    			$mzToAdjust += sprintf("%.$decimalLength"."f", 1.0072764 ) ;	
    		}
    	}
    	elsif ( (defined $stateMolecule ) and ($stateMolecule eq 'NEUTRAL') ) {
    		## Manage ionisation mode specie
	    	# if mode == POS -> adding H+ to mzParent
	    	# elsif mode == NEG -> remove H to mzParent
	    	
	    	## for every theo fragment which are not "pseudomolecular ion"
	    	if ( $fragment->_getFragment_TYPE() ne 'pseudomolecular ion'  ) {
	    		
	    		if ( (defined $mode ) and ( $mode eq 'POSITIVE') ) {
	    			$mzToAdjust += sprintf("%.$decimalLength"."f", 1.0072764 ) ;
		    	}
		    	elsif ( (defined $mode ) and ( $mode eq 'NEGATIVE') ) {
		    		$mzToAdjust += sprintf("%.$decimalLength"."f", -1.0072764 ) ;
		    	}
	    	}
    	}
    	
    	my $computedMass = ($mzToAdjust + $fragMass)  ;
    	$computedMass = sprintf("%.$decimalLength"."f", $computedMass );
    	
    	if ($computedMass > 0) {
    		my $oPeak = Metabolomics::Banks->__refPeak__() ;
	    	$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMass );
	    	$oPeak->_setPeak_ANNOTATION_TYPE ( $fragment->_getFragment_TYPE() ) ;
	    	$oPeak->_setPeak_ANNOTATION_NAME ( $fragment->_getFragment_LOSSES_OR_GAINS() );
	    	
	    	# remove wrong mode annotation
	    	if ( (defined $mode ) and ( $mode eq 'POSITIVE') ) {
	    		$oPeak->_setPeak_ANNOTATION_IN_POS_MODE ( $fragment->_getFragment_ANNOTATION_IN_POS_MODE() ) if ($fragment->_getFragment_ANNOTATION_IN_POS_MODE ) ;
	    	}
	    	elsif ( (defined $mode ) and ( $mode eq 'NEGATIVE') ) {
	    		$oPeak->_setPeak_ANNOTATION_IN_NEG_MODE ( $fragment->_getFragment_ANNOTATION_IN_NEG_MODE() ) if ($fragment->_getFragment_ANNOTATION_IN_NEG_MODE ) ;
	    	}
	    	
	    	$self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
    	}
    } ## END FOREACH
#    print Dumper $self ;
}
### END of SUB

=item METHOD buildTheoDimerFromMz

	## Description : build potential dimers/trimers in NEG/POS mode
	## Input : $Mz, $mode
	## Output : $oBank
	## Usage : my ( $oBank ) = buildTheoDimerFromMz ( $Mz, $mode ) ;

=cut

## START of SUB
sub buildTheoDimerFromMz {
    ## Retrieve Values
    my $self = shift ;
    my ( $Mz, $mode ) = @_;
    
    if ($mode eq 'POSITIVE') {

		## Dimers...
    	my %posAdducts = (
    		'2M+H' => 1.007276 ,
			'2M+NH4' => 18.033823,
			'2M+Na' => 22.989218,
			'2M+3H2O+2H' => 28.02312,
			'2M+K' => 38.963158 ,
			'2M+ACN+H' => 42.033823 ,
			'2M+ACN+Na'  => 64.015765 ,
    	) ;
    	
    	foreach my $adduct ( sort {lc $a cmp lc $b} keys %posAdducts) {
    		
    		my $adductMass = $posAdducts{$adduct} ;
    		## Only for Dimers !!!!
    		my $DimerMass = ($Mz * 2) ;
    		
    		# arround the result with min decimal part of the two floats. 
			my $oUtils = Metabolomics::Utils->new() ;
			my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($DimerMass, $adductMass) ;
			
			## Only for Dimers !!!!
			my $computedMass = ($adductMass + $DimerMass)  ;
    		$computedMass = sprintf("%.$decimalLength"."f", $computedMass );
    		
    		my $oPeak = Metabolomics::Banks->__refPeak__() ;
	    	$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMass );
	    	$oPeak->_setPeak_ANNOTATION_TYPE ( 'dimeric adduct' ) ;
	    	$oPeak->_setPeak_ANNOTATION_NAME ( $adduct );
			$oPeak->_setPeak_ANNOTATION_IN_POS_MODE (  $adduct ) ;
			
#			print Dumper $oPeak ;
			
			$self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
    	}

    }
    elsif ($mode eq 'NEGATIVE') {
    	
    	## Dimers...
    	my %negAdducts = (
    		'2M-H' => -1.007276,
			'2M+FA-H' => 44.998201,
			'2M+Hac-H' => 59.013851 ,
    	) ;
    	
    	foreach my $adduct (sort {lc $a cmp lc $b} keys %negAdducts) {
    		
    		my $adductMass = $negAdducts{$adduct} ;
    		## Only for Dimers !!!!
    		my $DimerMass = $Mz * 2 ;
    		
    		# arround the result with min decimal part of the two floats. 
			my $oUtils = Metabolomics::Utils->new() ;
			my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($DimerMass, $adductMass) ;
			
			## Only for Dimers !!!!
			my $computedMass = ($adductMass + $DimerMass)  ;
    		$computedMass = sprintf("%.$decimalLength"."f", $computedMass );
    		
    		my $oPeak = Metabolomics::Banks->__refPeak__() ;
	    	$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMass );
	    	$oPeak->_setPeak_ANNOTATION_TYPE ( 'dimeric adduct' ) ;
	    	$oPeak->_setPeak_ANNOTATION_NAME ( $adduct );
			$oPeak->_setPeak_ANNOTATION_IN_NEG_MODE (  $adduct ) ;
			
#			print Dumper $oPeak ;
			
			$self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
    	}

    }
    else {
    		croak "The mode does not exist ($mode) or is not defined\n" ;
    	}
    
}
### END of SUB

=item METHOD isotopicAdvancedCalculation

	## Description : if a fragment is present in theorical bank, compute its isotopic couple.
	## Input : $refBank
	## Output : $ionBank
	## Usage : my ( $ionBank ) = isotopicAdvancedCalculation ( $refBank ) ;

=cut

## START of SUB
sub isotopicAdvancedCalculation {
    ## Retrieve Values
    my $self = shift ;
    my ( $mode ) = @_;
    
    my %isotopes = () ;
    
    # get fragments
    my $fragments = $self->_getFragments();
    my $theoPeaks = $self->_getTheoricalPeaks() ;
    
   	# foreach theo peak
   	
   	foreach my $fragment  (@{$fragments}) {
   		if ($fragment->_getFragment_TYPE() eq 'isotope' ) {
   			if ( ($fragment->_getFragment_LOSSES_OR_GAINS()) !~ /Ca|K|S|Cl/ ) {
   				$isotopes{ $fragment->_getFragment_LOSSES_OR_GAINS() } = $fragment->_getFragment_DELTA_MASS() ;	
   			}
   			
   		}
   	}
#   	print Dumper %isotopes ;
   	
   	foreach my $peak  (@{$theoPeaks}) {
   	
   		# find if it is a fragment
   		if ( defined $peak->_getPeak_ANNOTATION_TYPE() ) {
   			
   			if ( ($peak->_getPeak_ANNOTATION_TYPE() eq 'fragment' ) or ($peak->_getPeak_ANNOTATION_TYPE() eq 'adduct' ) or ($peak->_getPeak_ANNOTATION_TYPE() eq 'dimeric adduct' ) ) {
   				
   				my $peakMass = $peak->_getPeak_COMPUTED_MONOISOTOPIC_MASS() ;
   				my $peakAnnotationName = $peak->_getPeak_ANNOTATION_NAME() ;
   				
   				my $peakAnnotationInPosMode = 'x' ;
   				my $peakAnnotationInNegMode = 'x' ;
   				
   				$peakAnnotationInPosMode = $peak->_getPeak_ANNOTATION_IN_POS_MODE() if ( $peak->_getPeak_ANNOTATION_IN_POS_MODE() ) ;
   				$peakAnnotationInNegMode = $peak->_getPeak_ANNOTATION_IN_NEG_MODE() if ( $peak->_getPeak_ANNOTATION_IN_NEG_MODE() ) ;
   				
   				foreach my $isotope ( sort {lc $a cmp lc $b} keys %isotopes) {
   					
   					my $isotopeMass = $isotopes{$isotope} ;
   					
   					# arround the result with min decimal part of the two floats. 
			    	my $oUtils = Metabolomics::Utils->new() ;
			    	my $decimalLength = $oUtils->getSmallestDecimalPartOf2Numbers($isotopeMass, $peakMass) ;
			    	
			    	my $computedMass = ($peakMass + $isotopeMass)  ;
    				$computedMass = sprintf("%.$decimalLength"."f", $computedMass );
   					
   					my $oPeak = Metabolomics::Banks->__refPeak__() ;
			    	$oPeak->_setPeak_COMPUTED_MONOISOTOPIC_MASS ( $computedMass );
			    	$oPeak->_setPeak_ANNOTATION_TYPE ( 'isotopic massif' ) ;
			    	$oPeak->_setPeak_ANNOTATION_NAME ( $peakAnnotationName.'_'.$isotope );
			    	
			    	# remove wrong mode annotation
			    	if ( (defined $mode ) and ( $mode eq 'POSITIVE') ) {
			    		$oPeak->_setPeak_ANNOTATION_IN_POS_MODE (  $peakAnnotationInPosMode.'_'.$isotope ) ;
			    	}
			    	elsif ( (defined $mode ) and ( $mode eq 'NEGATIVE') ) {
			    		$oPeak->_setPeak_ANNOTATION_IN_NEG_MODE ( $peakAnnotationInNegMode.'_'.$isotope ) ;
			    	}
			    	
			    	$self->_addPeakList('_THEO_PEAK_LIST_', $oPeak) ;
   				} # End foreach isotope
   			}
   		}		
   	}
}
### END of SUB

=back

=head1 PRIVATE METHODS

=head2 Metabolomics::Banks::AbInitioFragments

=over 4

=item PRIVATE_ONLY __refBloodExposomeEntry__

	## Description : init a new ab initio fragment entry
	## Input : void	
	## Output : refEntry
	## Usage : $self->__refAbInitioFragment__() ;

=cut

## START of SUB
sub __refAbInitioFragment__ {
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

=item PRIVATE_ONLY _getANNOTATION_IN_NEG_MODE

	## Description : _getANNOTATION_IN_NEG_MODE
	## Input : void
	## Output : $ANNOTATION_IN_NEG_MODE
	## Usage : my ( $ANNOTATION_IN_NEG_MODE ) = _getANNOTATION_IN_NEG_MODE () ;

=cut

## START of SUB
sub _getFragment_ANNOTATION_IN_NEG_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_IN_NEG_MODE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IN_NEG_MODE_}) and ( $self->{_ANNOTATION_IN_NEG_MODE_} ne '' ) ) {	$ANNOTATION_IN_NEG_MODE = $self->{_ANNOTATION_IN_NEG_MODE_} ; }
    #else {	 $ANNOTATION_IN_NEG_MODE = undef ; warn "[WARN] the method _getFragment_ANNOTATION_IN_NEG_MODE get a undef or null string value\n" ; }
    
    return ( $ANNOTATION_IN_NEG_MODE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getANNOTATION_IN_POS_MODE

	## Description : _getANNOTATION_IN_POS_MODE
	## Input : void
	## Output : $ANNOTATION_IN_POS_MODE
	## Usage : my ( $ANNOTATION_IN_POS_MODE ) = _getANNOTATION_IN_POS_MODE () ;

=cut

## START of SUB
sub _getFragment_ANNOTATION_IN_POS_MODE {
    ## Retrieve Values
    my $self = shift ;
    
    my $ANNOTATION_IN_POS_MODE = undef ;
    
    if ( (defined $self->{_ANNOTATION_IN_POS_MODE_}) and ( $self->{_ANNOTATION_IN_POS_MODE_} ne '' ) ) {	$ANNOTATION_IN_POS_MODE = $self->{_ANNOTATION_IN_POS_MODE_} ; }
    #else {	 $ANNOTATION_IN_POS_MODE = undef ; warn "[WARN] the method _getFragment_ANNOTATION_IN_POS_MODE get a undef or null string value\n" ; }
    
    return ( $ANNOTATION_IN_POS_MODE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getDELTA_MASS

	## Description : _getDELTA_MASS
	## Input : void
	## Output : $DELTA_MASS
	## Usage : my ( $DELTA_MASS ) = _getDELTA_MASS () ;

=cut

## START of SUB
sub _getFragment_DELTA_MASS {
    ## Retrieve Values
    my $self = shift ;
    
    my $DELTA_MASS = undef ;
    
    if ( (defined $self->{_DELTA_MASS_}) and ( $self->{_DELTA_MASS_} > 0 ) or $self->{_DELTA_MASS_} < 0  ) {	$DELTA_MASS = $self->{_DELTA_MASS_} ; }
    else {	 $DELTA_MASS = 0 ; warn "[WARN] the method _getFragment_DELTA_MASS can't _get a undef or non numerical value\n" ; }
    
    return ( $DELTA_MASS ) ;
}
### END of SUB

=item PRIVATE_ONLY _getFragment_TYPE

	## Description : _getFragment_TYPE
	## Input : void
	## Output : $TYPE
	## Usage : my ( $TYPE ) = _getFragment_TYPE () ;

=cut

## START of SUB
sub _getFragment_TYPE {
    ## Retrieve Values
    my $self = shift ;
    
    my $TYPE = undef ;
    
    if ( (defined $self->{_TYPE_}) and ( $self->{_TYPE_} ne '' ) ) {	$TYPE = $self->{_TYPE_} ; }
    else {	 $TYPE = undef ; warn "[WARN] the method _getFragment_TYPE can't _get a undef or non numerical value\n" ; }
    
    return ( $TYPE ) ;
}
### END of SUB

=item PRIVATE_ONLY _getLOSSES_OR_GAINS

	## Description : _getLOSSES_OR_GAINS
	## Input : void
	## Output : $LOSSES_OR_GAINS
	## Usage : my ( $LOSSES_OR_GAINS ) = _getLOSSES_OR_GAINS () ;

=cut

## START of SUB
sub _getFragment_LOSSES_OR_GAINS {
    ## Retrieve Values
    my $self = shift ;
    
    my $LOSSES_OR_GAINS = undef ;
    
    if ( (defined $self->{_LOSSES_OR_GAINS_}) and ( $self->{_LOSSES_OR_GAINS_} ne '' ) ) {	$LOSSES_OR_GAINS = $self->{_LOSSES_OR_GAINS_} ; }
    else {	 $LOSSES_OR_GAINS = undef ; warn "[WARN] the method _getFragment_LOSSES_OR_GAINS can't _get a undef or non numerical value\n" ; }
    
    return ( $LOSSES_OR_GAINS ) ;
}
### END of SUB


__END__

=back

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inrae.fr> >>

=head1 SEE ALSO

All information about Metabolomics::Fragment::Annotation would be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragnot

=head1 BUGS

Please report any bugs or feature requests to C<bug-Metabolomics-Fragment-Annotation at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Metabolomics-Fragment-Annotation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Banks::AbInitioFragments

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

1; # End of Metabolomics::Banks::AbInitioFragments
