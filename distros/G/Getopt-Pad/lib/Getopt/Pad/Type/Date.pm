use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Temporal;

class Getopt::Pad::Type::Date :isa(Getopt::Pad::Type::Temporal) :strict(params) {
	use constant NAMES => ['date'];

	our $VERSION = '0.06';

	field $parser;

	ADJUST {
		$parser = $self->newParser;
	}

	method label() { return 'Date' }

	method check($value) {
		$parser->parse_datetime($value);
		return $parser->success ? undef : sprintf("'%s' is not a date", $value);
	}

	method coerce($value) {
		return $parser->parse_datetime($value);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Date - The date option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        since => { type => 'date', default => 'yesterday', timezone => 'UTC' },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'date' >>. It
parses a date and time in natural language, such as C<tomorrow 3pm>,
C<last monday>, C<3 days ago> or C<2026-10-06 14:00>, with
L<DateTime::Format::Natural>. That module is not installed together with
Getopt::Pad (see L<Getopt::Pad::Type::Temporal>). A value it cannot
parse is rejected with C<'VALUE' is not a date>.

The reader returns a L<DateTime> object in the time zone of the
C<timezone> key. Relative values are resolved against the current time
when the value is checked; for a default, that is when C<GetOptions>
builds the spec. The help output labels the option C<[Date]>.

The behavior for users is described in L<Getopt::Pad/date>.

=head1 SEE ALSO

L<Getopt::Pad/TYPES>, L<Getopt::Pad::Type::Temporal>,
L<Getopt::Pad::Type::Duration>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
