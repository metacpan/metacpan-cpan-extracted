package Metabolomics::Utils ;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

use Data::Dumper ;
use Text::CSV ;
use XML::Twig ;
use File::Share ':all'; 
use Carp qw (cluck croak carp) ;

require Exporter;

our @ISA = qw(Exporter );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Metabolomics::Utils ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	roundFloat getSmallestDecimalPartOf2Numbers utilsAsConf computeScoreMatchedLibrarySpectrumPeaksPercent computeScoreMatchedQueryPeaksPercent computeScorePairedPeaksIntensitiesPearsonCorrelation
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	roundFloat getSmallestDecimalPartOf2Numbers utilsAsConf computeScoreMatchedLibrarySpectrumPeaksPercent computeScoreMatchedQueryPeaksPercent computeScorePairedPeaksIntensitiesPearsonCorrelation
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Utils - Perl Utils extension metabolomics::fragment::annotation module 

=head1 VERSION

Version 0.2 - Adding POD
Version 0.3 - Adding Scoring methods for gcms annotation analysis
Version 0.4 - Adding RI computing

=cut

our $VERSION = '0.4';


=head1 SYNOPSIS

    use Metabolomics::Utils;

=head1 DESCRIPTION

	Metabolomics::Utils is a module containing little helper as formatters, parsers, conf called during annotation steps 

=head1 EXPORT

	use Metabolomics::Utils;

=head1 PUBLIC METHODS 

=head2 Metabolomics::Utils ;

=over 4

=item new

	## Description : set a new utils object
	## Input : NA
	## Output : $oUtils
	## Usage : my ( $oBank ) = Metabolomics::Utils->new ( ) ;

=cut

## START of SUB
sub new {
	## Variables
	my ($class,$args) = @_;
	my $self={};

	bless($self) ;
    
    return ($self) ;
}
### END of SUB

=item roundFloat

	## Description : round a float by the sended decimal
	## Input : $number, $decimal
	## Output : $round_num
	## Usage : my ( $round_num ) = roundFloat( $number, $decimal ) ;

=cut

## START of SUB 
sub roundFloat {
    ## Retrieve Values
    my $self = shift ;
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
#    print Dumper "----> $number, $decimal ==> $round_num\n" ;
    return($round_num) ;
}
## END of SUB

=item METHOD getSmallestDecimalPartOf2Numbers

	## Description : get the smallest decimal part of two numbers
	## Input : $float01, $float02
	## Output : $commonLenghtDecimalPart
	## Usage : my ( $commonLenghtDecimalPart ) = getSmallestDecimalPartOf2Numbers ( $float01, $float02 ) ;

=cut

## START of SUB
sub getSmallestDecimalPartOf2Numbers {
    ## Retrieve Values
    my $self = shift ;
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

=item METHOD validFloat

	## Description : valid float as float with dot as decimal separator
	## Input : $refFloats
	## Output : \@floats 
	## Usage : my ( \@floats ) = validFloat( $refFloats ) ;
=cut
## START of SUB
sub validFloat {
	## Retrieve Values
    my $self = shift ;
    my ( $refFloats ) = @_ ;
    my @floats = () ;
    
    foreach my $float ( @{$refFloats} ) {
    	$float =~ s/,/\./ ;
    	push ( @floats, $float ) ;
    }
return (\@floats) ;
}
## END of SUB

=item METHOD trackZeroIntensity

	## Description : track zero value in raw intensity
	## Input : $refFloats
	## Output : \@floats 
	## Usage : my ( \@floats ) = trackZeroIntensity( $refFloats ) ;
=cut
## START of SUB
sub trackZeroIntensity {
	## Retrieve Values
    my $self = shift ;
    my ( $refFloats ) = @_ ;
    my @floats = () ;
    
    foreach my $float ( @{$refFloats} ) {
    	if ( ( !defined $float ) ) {
    		push ( @floats, 13 ) ; ## by default
    	}
    	elsif ( (defined $float) and ( $float == 0) ) {
    		push ( @floats, 13 ) ; ## by default
    	}
    	else {
    		push ( @floats, $float ) ;
    	}
    	
    }
return (\@floats) ;
}
## END of SUB

=item METHOD computeScorePairedPeaksIntensitiesPearsonCorrelation

	## Description : Pearson correlation between intensities of paired peaks, where unmatched peaks are paired with zero-intensity "pseudo-peaks"
	## Input : $x
	## Output : $correlation (<=1)
	## Usage : my ( $correlation ) = computeScorePairedPeaksIntensitiesPearsonCorrelation ( $x ) ;

=cut

## START of SUB
sub computeScorePairedPeaksIntensitiesPearsonCorrelation {
    ## Retrieve Values
    my $self = shift ;
    my ( $x ) = @_;
    
#    print Dumper $x ;
    
    my $correlation = undef ;
    
    $correlation = __correlation($x);
    
    
    sub __mean {
	   my ($x)=@_;
#	   my $num = scalar(@{$x}) - 1;
	   my $num = scalar(@{$x}) ;
	   my $sum_x = 0;
	   my $sum_y = 0;
#	   for (my $i = 1; $i < scalar(@{$x}); ++$i){
	   foreach my $pair (@{$x}) {
	      $sum_x += $pair->[0];
	      $sum_y += $pair->[1];
	   }
	   my $mu_x = $sum_x / $num;
	   my $mu_y = $sum_y / $num;
	   return($mu_x,$mu_y);
	}
	 
	### ss = sum of squared deviations to the mean
	sub __ss {
	   my ($x,$mean_x,$mean_y,$one,$two)=@_;
	   my $sum = 0;
#	   for (my $i=1;$i<scalar(@{$x});++$i){
	   foreach my $pair (@{$x}) {
	     $sum += ($pair->[$one]- $mean_x )*($pair->[$two] - $mean_y );
	   }
	   return $sum;
	}
	 
	sub __correlation {
	   my ($x) = @_;
	   my ($mean_x,$mean_y) = __mean($x);
#	   print "$mean_x,$mean_y\n" ;
	   my $ssxx=__ss($x,$mean_x,$mean_y,0,0);
	   my $ssyy=__ss($x,$mean_x,$mean_y,1,1);
	   my $ssxy=__ss($x,$mean_x,$mean_y,0,1);
#	   print "$ssxx,$ssyy,$ssxy\n" ;
	   my $correl=__correl($ssxx,$ssyy,$ssxy);
	   my $xcorrel=sprintf("%.3f",$correl);
	   return($xcorrel);
	 
	}
	 
	sub __correl {
	   my ($ssxx,$ssyy,$ssxy) = @_;
	   my $sign = $ssxy / abs($ssxy);
	   my $correl = $sign *sqrt($ssxy*$ssxy/($ssxx*$ssyy));
	   return $correl;
	}

    
    return ($correlation) ;
}
### END of SUB

=item METHOD _computeScoreMatchedQueryPeaksPercent

	## Description : Proportion of query peaks with matches. 
	## Input : $nbMatches, $nbQueryPeaks
	## Output : $scoreQ
	## Usage : my ( $scoreQ ) = _computeScoreMatchedQueryPeaksPercent ( $nbMatches, $nbQueryPeaks ) ;

=cut

## START of SUB
sub computeScoreMatchedQueryPeaksPercent {
    ## Retrieve Values
    my $self = shift ;
    my ( $nbMatches, $nbQueryPeaks ) = @_;
    my $scoreQ = undef ;
    
    if ( (defined $nbMatches)  and (defined $nbQueryPeaks)  ) {
    	
    	if ( ($nbMatches >= 0 ) and  ($nbQueryPeaks > 0) ) {
    		my $proportion = $nbMatches / $nbQueryPeaks ;
#    		print "scoreQ ($nbMatches / $nbQueryPeaks) = $proportion\n" ;
    		$scoreQ = sprintf("%.2f", $proportion );	## arroun : 0.6666666 -> 0.67
    	}
    	else {
    		croak "[ERROR] Values for score factors ar not none null integer\n" ;
    	}
    }
    else {
    	croak "[ERROR] One of your two factors mandatory for score computing (Proportion of query peaks with matches) is not defined\n" ;
    }
    return ($scoreQ) ;
}
### END of SUB  

=item METHOD _computeScoreMatchedLibrarySpectrumPeaksPercent

	## Description : Proportion of library spectrum's peaks with matches. 
	## Input : $nbMatches, $nbLibPeaks
	## Output : $scoreL
	## Usage : my ( $scoreL ) = computeScoreMatchedLibrarySpectrumPeaksPercent ( $nbMatches, $nbLibPeaks ) ;

=cut

## START of SUB
sub computeScoreMatchedLibrarySpectrumPeaksPercent {
    ## Retrieve Values
    my $self = shift ;
    my ( $nbMatches, $nbLibPeaks ) = @_;
    my $scoreL = undef ;
    
    if ( (defined $nbMatches)  and (defined $nbLibPeaks)  ) {
    	
    	if ( ($nbMatches >= 0 ) and  ($nbLibPeaks > 0) ) {
    		my $proportion = $nbMatches / $nbLibPeaks ;
#    		print "scoreL ($nbMatches / $nbLibPeaks) = $proportion\n" ;
    		$scoreL = sprintf("%.2f", $proportion );	## arroun : 0.6666666 -> 0.67
    	}
    	else {
    		croak "[ERROR] Values for score factors ar not none null integer\n" ;
    	}
    }
    else {
    	croak "[ERROR] One of your two factors mandatory for score computing (Proportion of library spectrum's peaks with matches) is not defined\n" ;
    }
    
    return ($scoreL) ;
}
### END of SUB    

=item METHOD computeAbsoluteIntensitiesInRelativeIntensity100

	## Description : compute a whole liste of relative Intensity (100-based) 
	## Input : $mz_res, $ints_res
	## Output : $relative_ints
	## Usage : my ( $relative_ints ) = computeAbsoluteIntensitiesInRelativeIntensity100 ( $mz_res, $ints_res ) ;

=cut

## START of SUB
sub computeAbsoluteIntensitiesInRelativeIntensity100 {
	## Retrieve Values
    my $self = shift ;
    my ( $mz_res, $ints_res ) = @_ ;
    
    my @ints_res = @{$ints_res} ;
    my @mzs_res = @{$mz_res} ;
    	
    # Sort by value (max -> min)
    for (my $i=0 ; $i<@ints_res ; $i++) {
		my @sorted_indices = sort { $ints_res[$b] <=> $ints_res[$a] } 0..$#ints_res;
		@$_ = @{$_}[@sorted_indices] for \(@mzs_res, @ints_res);
	}
		
    my @relative_ints = map { ($_ * 100)/$ints_res[0] } @ints_res ;

    return (\@relative_ints) ;
}
## END of SUB


=item utilsAsConf

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

__END__

=back

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

    perldoc Metabolomics::Utils

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

1; # End of Metabolomics::Utils
