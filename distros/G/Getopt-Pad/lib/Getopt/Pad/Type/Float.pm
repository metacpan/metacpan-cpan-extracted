use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Number;

class Getopt::Pad::Type::Float :isa(Getopt::Pad::Type::Number) :strict(params) {
	use Scalar::Util qw(looks_like_number);

	our $VERSION = '0.06';

	use constant NAMES => ['f', 'float', 'num', 'number'];

	method checkFormat($value) {
		return sprintf("'%s' is not a number", $value) if !looks_like_number($value);

		# Catches inf and nan however they are spelled, and values too large
		# for a Perl number (1e999): times 0, an infinity becomes nan, and
		# nan equals nothing.
		my $number = $value + 0;
		return sprintf("'%s' is not a finite number", $value) if $number * 0 != 0;
		return undef;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Float - The float option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        ratio => { type => 'float', min => 0, max => 1, default => 0.5 },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'float' >>,
C<'num'>, C<'number'> or C<'f'>.

It accepts any value that Perl recognizes as a decimal number
(L<Scalar::Util/looks_like_number>): C<1.5>, C<-2>, C<.5>, C<1e3>.
Values that are not finite are rejected with C<'VALUE' is not a finite
number>: C<inf>, C<infinity> and C<nan> in any spelling, and values too
large for a Perl number, such as C<1e999>. Everything else that is not a
number, including hexadecimal values such as C<0x10>, is rejected with
C<'VALUE' is not a number>. The reader returns the value as a number.

The spec keys C<min> and C<max> set inclusive bounds; they come from
L<Getopt::Pad::Type::Number>. See L<Getopt::Pad/float> for the user-level
description.

=head1 SEE ALSO

L<Getopt::Pad/TYPES>, L<Getopt::Pad::Type::Int>,
L<Getopt::Pad::Type::Number>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
