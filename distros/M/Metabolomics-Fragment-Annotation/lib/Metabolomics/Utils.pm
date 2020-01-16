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
	roundFloat getSmallestDecimalPartOf2Numbers utilsAsConf
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	roundFloat getSmallestDecimalPartOf2Numbers utilsAsConf
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Utils - Perl Utils extension metabolomics::fragment::annotation module 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

    use Metabolomics::Utils;

=head1 DESCRIPTION

	Metabolomics::Utils is a module containing little helper as formatters, parsers, conf called during annotation steps 
	

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 METHOD new

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

=head2 METHOD _roundFloat

	## Description : round a float by the sended decimal
	## Input : $number, $decimal
	## Output : $round_num
	## Usage : my ( $round_num ) = round_num( $number, $decimal ) ;
	
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

=head2 METHOD getSmallestDecimalPartOf2Numbers

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


=head1 LICENSE AND COPYRIGHT

CeCILL Copyright (C) 2019 by Franck Giacomoni

Initiated by Franck Giacomoni

followed by INRA PFEM team

Web Site = INRA PFEM


=cut

1; # End of Metabolomics::Utils
