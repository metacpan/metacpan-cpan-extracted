package Lingua::RU::Numeric::Declension;

use vars qw ($VERSION);
$VERSION = '1.1';

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(numdecl);


sub numdecl {
   my ($number, $nominative, $genitive, $plural) = @_;

   return $plural if $number =~ /1.$/;

   my ($last_digit) = $number =~ /(.)$/;

   return $nominative if $last_digit == 1;
   return $genitive if $last_digit > 0 && $last_digit < 5;
   return $plural;
}

1;

__END__

=head1 NAME

Lingua::RU::Numeric::Declension - Chooses variant of declension dependent on the number

=head1 SYNOPSIS

	use Lingua::RU::Numeric::Declension "numdecl";
	printf "%i %s", 38, numdecl(38, 'parrot', 'parrota', 'parrotov');


=head1 ABSTRACT

Lingua::RU::Numeric::Declension chooses which version of a word form to use this a particular number.

=head1 DESCRIPTION

Module exports the only subroutine C<numdecl> which accepts the number and three forms 
of a word related to that number. Return value is always a string with one of the 
given forms, result does not contain the number itself. These forms must appear 
in subroutine call in the following order: nominative case, genitive case and plural form. 
Use simple mnemonic rule to remember the order: instead of thinking of grammar cases, 
just substitute word forms which should be used with numbers 1, 2 and 5.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE

Lingua::RU::Numeric::Declension module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl, which ever version you mean.

=cut
