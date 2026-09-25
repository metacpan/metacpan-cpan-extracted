use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Number :isa(Getopt::Pad::Type) :abstract {
	use Scalar::Util qw(looks_like_number);

	our $VERSION = '0.03';

	use constant SPEC_KEYS => ['min', 'max'];

	field $min :param :reader = undef;
	field $max :param :reader = undef;

	# A bound that is not a number, or an empty range, is a spec mistake.
	method checkSpecKeys :common (%args) {
		foreach my $bound (grep { defined $args{$_} } qw(min max)) {
			return sprintf("%s must be a number, not '%s'", $bound, $args{$bound}) if !looks_like_number($args{$bound});
		}
		return sprintf("min %s is larger than max %s", $args{min}, $args{max}) if defined $args{min} && defined $args{max} && $args{min} > $args{max};
		return undef;
	}

	method glSuffix() { return '=s' }

	method checkFormat($value);

	method coerce($value) {
		return $value + 0;
	}

	method check($value) {
		my $problem = $self->checkFormat($value);
		return $problem if defined $problem;
		return sprintf('%s is smaller than the minimum of %s', $value, $min) if defined $min && $value < $min;
		return sprintf('%s is larger than the maximum of %s', $value, $max)  if defined $max && $value > $max;
		return undef;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Number - numeric type base class

=head1 DESCRIPTION

Abstract base for numeric types: owns the C<min> / C<max> bounds and the range check, and coerces valid values to numbers. The bounds are checked when the spec is built (checkSpecKeys): each must be a number and min may not exceed max. Subclasses provide checkFormat, the format test that runs before the range check (see Int and Float).

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
