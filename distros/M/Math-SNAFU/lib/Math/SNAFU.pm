use 5.012;
use strict;
use warnings;

package Math::SNAFU;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Carp qw(
	croak
);

use Exporter::Shiny 1.006000 qw(
	decimal_to_snafu
	snafu_to_decimal
);

sub decimal_to_snafu ($) {
	my ( $n ) = @_;
	return '0' if $n == 0;

	my @chars;
	while ( $n > 0 ) {
		my $mod = $n % 5;
		$n = int( $n / 5 );
		if ( $mod == 3 ) {
			push @chars, '=';
			++$n;
		}
		elsif ( $mod == 4 ) {
			push @chars, '-';
			++$n;
		}
		else {
			push @chars, $mod;
		}
	}

	return join '', reverse @chars;
}

sub snafu_to_decimal ($) {
	my ( $snafu ) = @_;

	state $digits = {
		'='  => -2,
		'-'  => -1,
		'0'  => +0,
		'1'  => +1,
		'2'  => +2,
	};

	my @input = reverse split //, $snafu;
	my ( $sum, $slot ) = ( 0, 0 );
	$sum += ( 5 ** $slot++ ) * ( $digits->{$_} // croak "Bad SNAFU digit: $_" )
		for @input;

	return $sum;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::SNAFU - decimal to SNAFU converter

=head1 SYNOPSIS

Converts between decimal integers and SNAFU.

=head1 DESCRIPTION

SNAFU is defined in L<https://adventofcode.com/2022/day/25>.

=head1 FUNCTIONS

=head2 C<< decimal_to_snafu( $decimal ) >>

Returns the number in SNAFU format.

Only supports non-negative integers.

=head2 C<< snafu_to_decimal( $snafu ) >>

Returns the number in decimal format.

Only supports non-negative integers.

=head1 EXPORTS

Nothing is exported by default. Exports must be requested:

  use Math::SNAFU -all;

Exports can be lexical:

  use Math::SNAFU -all, -lexical;

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/advent-of-code/issues>

=head1 SEE ALSO

L<https://adventofcode.com/2022/day/25>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

