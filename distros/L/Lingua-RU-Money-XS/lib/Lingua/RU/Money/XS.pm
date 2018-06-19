package Lingua::RU::Money::XS;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw();
our %EXPORT_TAGS = (
	all => [ qw(rur2words all2words) ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Lingua::RU::Money::XS', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Lingua::RU::Money::XS - Perl extension for digit conversion to corresponding
money sum in Russian.

=begin HTML

<div id="images">
	<img src="https://img.shields.io/cpan/v/Lingua-RU-Money-XS.svg" alt="Cpan version"/>
	<img src="https://img.shields.io/cpan/l/Lingua-RU-Money-XS.svg" alt="Cpan licence"/>
</div>

=end HTML

=head1 SYNOPSIS

  use Lingua::RU::Money::XS qw(rur2words);
  print rur2words(123456789012345.00)
  # outputs "сто двадцать три триллиона четыреста пятьдесят шесть миллиардов семьсот восемьдесят девять миллионов двенадцать тысяч триста сорок пять рублей 00 копеек"

=head1 DESCRIPTION

=head2 SUBROUTINES

=over 4

=item B<Lingua::RU::Money::XS::rur2words>

C<rur2words> returns a given as number money sum in words, i.e. I<5.10> converts
to I<пять рублей 10 копеек>. The target charset is B<UTF-8>.

=item B<Lingua::RU::Money::XS::all2words>

C<all2words> returns a given as number money sum in words, i.e. I<5.10> converts
to I<пять рублей десять копеек>. The target charset is B<UTF-8>.

=back

B<Caution>: Current implementation of C<rur2words> and C<all2words> follows the
Perl philosophy - anyway the given argument will be casted to C<double>.

B<Caution>: Due to previous caution there are several constraints, making
conversion impossible. These constraints divide input values into 4 groups
listed below

=over 8

=item I<amount less than 0>

Conversion for specified values make no sense. Thus, conversion croaks for all
these values.

=item I<amount between 0 and 1e12>

Any value in this range converts correctly with the specified accuracy.

=item I<amount between 1e12 and 1e15>

Due to the lack for significant digits after the radix point for some values in
this range, kopeck value is calculated inaccurate. It simply is replaced with
the 0 with the corresponding warning.

=item I<amount greater or equal than 1e15>

Conversion for these values is impossible due to the type overflow. Conversion
also croaks for all these values.

=back

=cut

=head2 EXPORT

Nothing is exported by default.

=cut

=head2 SUPPORTED VERSIONS OF PERL

Please note that this module works only on Perl 5.10.0 and newer.

B<Caution>: Though the version 0.06 of current module works with Perl 5.10.0,
I<it cannot be used in Perl older 5.16.0> due to typo within this package.
Please use version 0.07 instead.

=cut

=head1 AUTHOR

Igor Munkin, E<lt>imun@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Mons Anderson - The original idea, rationale and motivation

=head1 BUGS

Feel free to report your bugs by mailing to E<lt>imun@cpan.orgE<gt> or via
L<https://rt.cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2018 by Igor Munkin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
