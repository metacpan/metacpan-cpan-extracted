use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Number :isa(Getopt::Pad::Type) :abstract {
	use Scalar::Util qw(looks_like_number);

	our $VERSION = '0.05';

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

Getopt::Pad::Type::Number - Base class of the numeric option types

=head1 SYNOPSIS

=for highlighter language=perl

    use Object::Pad;
    use Getopt::Pad::Type;
    use Getopt::Pad::Type::Number;

    # A numeric type that accepts only multiples of 5, with min and max.
    class My::Type::Five :isa(Getopt::Pad::Type::Number) {
        use constant NAMES => ['five'];

        method checkFormat($value) {
            return undef if $value =~ /\A-?[0-9]+\z/ && $value % 5 == 0;
            return sprintf("'%s' is not a multiple of 5", $value);
        }
    }

    Getopt::Pad::Type::registerType('My::Type::Five');

=head1 DESCRIPTION

The common base class of L<Getopt::Pad::Type::Int> and
L<Getopt::Pad::Type::Float>. It is abstract: specs cannot use it
directly, but you can subclass it for numeric types of your own.

It provides:

=over 4

=item * the spec keys C<min> and C<max> (inclusive bounds). When the spec
is built, both must be numbers and C<min> must not be larger than C<max>;
otherwise the spec is invalid (C<min must be a number, not 'VALUE'>,
C<min MIN is larger than max MAX>);

=item * the value check: first the subclass's C<checkFormat>, then the
bounds (C<VALUE is smaller than the minimum of MIN>, C<VALUE is larger
than the maximum of MAX>);

=item * the conversion of the value to a number;

=item * C<glSuffix> C<'=s'>: every numeric type takes a value.

=back

A subclass provides C<NAMES> and one method:

=over 4

=item checkFormat($value)

Returns C<undef> when C<$value> has the right format, otherwise a short
description of the problem without the option name. It runs before the
bounds are checked, so the bounds only ever see numbers.

=back

See L<Getopt::Pad::Type> for the rest of the type contract.

=head1 SEE ALSO

L<Getopt::Pad::Type>, L<Getopt::Pad::Type::Int>, L<Getopt::Pad::Type::Float>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
