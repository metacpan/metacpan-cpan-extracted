package DotICD9;
# DotICD9.pm - add the dots to ICD9 codes
# DTM -- Sun May 16 18:27:39 DST 1999

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( );
$VERSION = '0.04';

sub new
{
my $self = shift;
return ( bless { }, $self );
}

sub dot
{
# parameters: icd9code without any dots, D or 3 || O or 2
# returns: properly formatted ICD9 code or 0 for error
	my $self = shift;
	my $icdcode = shift;
	$icdcode =~ s/\.//g; # shed decimal point if present
	$icdcode =~ y/ //d;  # remove space characters
	my $MAJOR   = shift;
	# MAJOR is 3 for diagnostic, 2 for procedure codes
	if    ( $MAJOR eq 'D' ){ $MAJOR = 3; }      # D or DIAG for diagnosis codes
	elsif ( $MAJOR =~ m/DIAG/i ){ $MAJOR = 3; }
	elsif ( $MAJOR eq 'O' ){ $MAJOR = 2; }      # O,SURG, or PROC for procedures
	elsif ( $MAJOR =~ m/SURG/i ){ $MAJOR = 2; }
	elsif ( $MAJOR =~ m/PROC/i ){ $MAJOR = 2; }
    my ( $codelen, $minor, $major );
    $codelen = length($icdcode);    # should be 2, 3, 4, or 5
    if( $icdcode =~ /^E/ ){ $major = $MAJOR + 1; }
	else{ $major = $MAJOR; }
    $minor = $codelen - $major;    # number of decimal places
    if( $minor < 0 ) {
		return 0; # strings goofed up error
    }
    elsif( $minor > 0 ) {
		$icdcode = substr($icdcode, 0, $major) . "." . substr( $icdcode, $major, $minor );
    }
    else {
		$icdcode = substr( $icdcode, 0, $major );
    }
	return $icdcode;
}

1;
__END__

=head1 NAME

DotICD9 - Perl extension for placing decimal points in ICD-9 Codes

=head1 SYNOPSIS

  use DotICD9; 
  $i = new DotICD9;

  $dottedcode = $i->dot( 78830, 3 );

  $dottedcode = $i->dot( 78830, D );

  $dottedcode = $i->dot( 7830, O );

=head1 DESCRIPTION

Adds the dots to ICD9 codes. Diagnostic codes are assumed to have an
integer width of 3, Procedure codes have integer width of 2. A 'D' or 
'O' character can be used to distinguish between the two types of
codes, or a case insensitive match with 'surg' or 'diag' can be used.

=head1 AUTHOR

David Martin, pengy@icx.net

=head1 SEE ALSO

perl(1).

=cut
