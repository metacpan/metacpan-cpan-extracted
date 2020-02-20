package Metabolomics::Formats::W4M ;

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

# This allows declaration	use Metabolomics::Formats::W4M ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	
	
);


# Preloaded methods go here.
my $modulePath = File::Basename::dirname( __FILE__ );

=head1 NAME

Metabolomics::Formats::W4M - Perl W4M extension of the metabolomics::fragment::annotation module 

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

    use Metabolomics::Formats::W4M ;

=head1 DESCRIPTION

	Metabolomics::Formats::W4M is a module allowing to access at uptodate W4M formatters, parsers and writters during annotation steps 
	

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 METHOD new

	## Description : set a new utils object
	## Input : NA
	## Output : $oUtils
	## Usage : my ( $oFormat ) = Metabolomics::Formats::W4M->new ( ) ;
	
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

=head2 METHOD _parsingW4mTabularFile

	## Description : parsing a full W4M variable metadata tabular file and create a array of arrats object
	## Input : $inputTabularFile
	## Output : $oVariableMetadataTable
	## Usage : my ( $oVariableMetadataTable ) = parsingW4mTabularFile ( $inputTabularFile ) ;
	
=cut
## START of SUB
sub parserTabularFile {
    ## Retrieve Values
    my $self = shift ;
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



__END__

=head1 AUTHOR

Franck Giacomoni, C<< <franck.giacomoni at inra.fr> >>

=head1 SEE ALSO

All information about Metabolomics::Formats::W4M would be find here: https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragnot

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

1; # End of Metabolomics::Formats::W4M
