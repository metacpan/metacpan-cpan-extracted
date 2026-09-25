use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Number;

class Getopt::Pad::Type::Int :isa(Getopt::Pad::Type::Number) :strict(params) {
	use constant NAMES => ['i', 'int', 'integer'];

	our $VERSION = '0.03';

	method checkFormat($value) {
		return $value =~ /\A[+-]?[0-9]+\z/ ? undef : sprintf("'%s' is not an integer", $value);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Int - integer type

=head1 DESCRIPTION

Integer value with optional C<min> / C<max> bounds, spec type C<i>.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
