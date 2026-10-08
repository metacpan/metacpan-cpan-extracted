use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Number;

class Getopt::Pad::Type::Int :isa(Getopt::Pad::Type::Number) :strict(params) {
	use constant NAMES     => ['i', 'int', 'integer'];
	use constant SPEC_KEYS => ['min', 'max', 'bigint'];

	our $VERSION = '0.06';

	field $bigint :param :reader = 0;

	# Math::BigInt is loaded only for the options that ask for it.
	ADJUST {
		require Math::BigInt if $bigint;
	}

	# The bounds of a bigint option are compared exactly, so they must be
	# integers themselves.
	method checkSpecKeys :common (%args) {
		my $problem = $class->SUPER::checkSpecKeys(%args);
		return $problem if defined $problem || !$args{bigint};

		foreach my $bound (grep { defined $args{$_} } qw(min max)) {
			return sprintf("%s must be an integer with bigint, not '%s'", $bound, $args{$bound}) if $args{$bound} !~ /\A[+-]?[0-9]+\z/;
		}
		return undef;
	}

	method checkFormat($value) {
		return sprintf("'%s' is not an integer", $value) if $value !~ /\A[+-]?[0-9]+\z/;
		return undef if $bigint;

		# Beyond Perl's integer range the value would become a rounded
		# float, or Inf: it reads back as other digits than the given ones.
		my $digits = $value =~ s/\A\+//r =~ s/\A(-?)0+(?=[0-9])/$1/r =~ s/\A-0\z/0/r;
		return sprintf("'%s' is too large for an integer", $value) if ($value + 0) . '' ne $digits;
		return undef;
	}

	method coerce($value) {
		return $bigint ? Math::BigInt->new($value) : $value + 0;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Int - The int option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        workers => { type => 'int', min => 1, max => 64, default => 4 },
        id      => { type => 'int', bigint => 1 },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'int' >>,
C<'integer'> or C<'i'>.

It accepts an optional C<+> or C<->, followed by one or more decimal
digits: C<42>, C<-7>, C<+3>, C<007>. The reader returns the value as a
number, so C<007> reads as 7. Anything else is rejected with
C<'VALUE' is not an integer>, and a value outside the range of Perl's
integers (from -2**63 to 2**64-1 on a 64-bit perl), which Perl could
only hold as a rounded float, with C<'VALUE' is too large for an
integer>.

With the spec key C<bigint>, values of any size are accepted and the
reader returns a L<Math::BigInt> object, loaded only for such options.
The bounds C<min> and C<max> must then be integers (C<min must be an
integer with bigint, not 'VALUE'>) and are compared exactly.

The spec keys C<min> and C<max> set inclusive bounds; they come from
L<Getopt::Pad::Type::Number>. See L<Getopt::Pad/int> for the user-level
description.

=head1 SEE ALSO

L<Getopt::Pad/TYPES>, L<Getopt::Pad::Type::Float>,
L<Getopt::Pad::Type::Number>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
