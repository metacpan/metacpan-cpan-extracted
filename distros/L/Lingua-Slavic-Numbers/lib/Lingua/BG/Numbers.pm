package Lingua::BG::Numbers;
use strict;

use Lingua::Slavic::Numbers;
use Exporter;
use vars qw( $VERSION @EXPORT_OK @EXPORT @ISA);
@EXPORT_OK                = qw( &number_to_bg &ordinate_to_bg );
@EXPORT = @EXPORT_OK;
$VERSION = 0.02;
@ISA                      = qw(Exporter);

sub ordinate_to_bg { return Lingua::Slavic::Numbers::ordinate_to_slavic(LANG_BG, @_); }
sub number_to_bg { return Lingua::Slavic::Numbers::number_to_slavic(LANG_BG, @_); }

1;

__END__

=pod

=head1 NAME

Lingua::BG::Numbers - Converts numeric values into their Bulgarian
string equivalents, using Lingua::Slavic::Numbers.

=head1 SYNOPSIS

 See Lingua::Slavic::Numbers.  ordinate_to_bg and number_to_bg are
 simply calls to ordinate_to_slavic and number_to_slavic.

 use Lingua::BG::Numbers qw(number_to_bg ordinate_to_bg);
 print number_to_bg( 345 );

 my $twenty  = ordinate_to_bg( 20 );
 print "Ordinate of 20 is $twenty";

=head1 FUNCTION-ORIENTED INTERFACE

=head2 number_to_bg( $number )

 use Lingua::BG::Numbers qw(number_to_bg);
 my $depth = number_to_bg( 20_000 );
 my $year  = number_to_bg( 1870 );

 # in honor of Lingua::FR::Numbers, which I copied to start this
 # module, I'm using a French example
 print "Жул Верн написа ,,$depth левги под морето'' в $year.";

This function can be exported by the module.

=head2 ordinate_to_bg( $number )
 
 use Lingua::BG::Numbers qw(ordinate_to_bg);
 my $twenty  = ordinate_to_bg( 20 );
 print "Номер $twenty";

This function can be exported by the module.

=head1 DESCRIPTION

 See Lingua::Slavic::Numbers

=head1 BUGS

 See Lingua::Slavic::Numbers

=head1 COPYRIGHT

Copyright 2008, Ted Zlatanov (Теодор Златанов). All Rights
Reserved. This module can be redistributed under the same terms as
Perl itself.

=head1 AUTHOR

Ted Zlatanov <tzz@lifelogs.com>

=head1 SEE ALSO

Lingua::Slavic::Numbers, Lingua::EN::Numbers, Lingua::Word2Num

