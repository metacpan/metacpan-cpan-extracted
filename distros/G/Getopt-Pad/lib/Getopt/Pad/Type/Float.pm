use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Number;

class Getopt::Pad::Type::Float :isa(Getopt::Pad::Type::Number) :strict(params) {
	use Scalar::Util qw(looks_like_number);

	our $VERSION = '0.02';

	use constant NAMES => ['f', 'float', 'num', 'number'];

	method checkFormat($value) {
		return sprintf("'%s' is not a number", $value) if !looks_like_number($value);
		return sprintf("'%s' is not a finite number", $value) if $value =~ /\A\s*[+-]?(?:inf(?:inity)?|nan)\s*\z/i;
		return undef;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Float - float type

=head1 DESCRIPTION

Finite numeric value with optional C<min> / C<max> bounds, spec type C<f>; infinities and NaN are rejected.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
