use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Number;

class Getopt::Pad::Type::Int :isa(Getopt::Pad::Type::Number) :strict(params) {
	use constant NAMES => ['i', 'int', 'integer'];

	our $VERSION = '0.05';

	method checkFormat($value) {
		return $value =~ /\A[+-]?[0-9]+\z/ ? undef : sprintf("'%s' is not an integer", $value);
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
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'int' >>,
C<'integer'> or C<'i'>.

It accepts an optional C<+> or C<->, followed by one or more decimal
digits: C<42>, C<-7>, C<+3>, C<007>. The reader returns the value as a
number, so C<007> reads as 7. Anything else is rejected with
C<'VALUE' is not an integer>.

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
