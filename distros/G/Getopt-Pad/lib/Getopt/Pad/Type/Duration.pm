use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Temporal;

class Getopt::Pad::Type::Duration :isa(Getopt::Pad::Type::Temporal) :strict(params) {
	use constant NAMES => ['duration'];

	our $VERSION = '0.06';

	method label() { return 'Duration' }

	method check($value) {
		return defined $self->span($value) ? undef : sprintf("'%s' is not a duration", $value);
	}

	method coerce($value) {
		my ($start, $end) = $self->span($value)->@*;
		return $end->subtract_datetime($start);
	}

	# The start and end of $value counted from now, or undef. A bare length
	# gets the 'for' DateTime::Format::Natural expects. Both ends count from
	# one pinned now, so the length carries no stray fraction of a second.
	method span($value) {
		my $parser = $self->newParser(datetime => DateTime->now(time_zone => $self->zone));
		my @ends   = $parser->parse_datetime_duration($value =~ /\A\s*for\b/i ? $value : "for $value");
		return undef if !$parser->success || @ends != 2;
		return \@ends;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Duration - The duration option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        timeout => { type => 'duration', default => '90 minutes' },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'duration' >>. It
parses a length of time, one number and one unit with an optional
leading C<for>, such as C<90 minutes>, C<2 weeks>, C<1 month> or
C<for 3 hours>, with L<DateTime::Format::Natural>. That module is not
installed together with Getopt::Pad (see L<Getopt::Pad::Type::Temporal>).
Abbreviations (C<1h>) and combinations (C<1 hour 30 minutes>) are
rejected with C<'VALUE' is not a duration>.

The reader returns a L<DateTime::Duration> object. It is measured from
the current time in the time zone of the C<timezone> key, which makes a
difference only when the length spans a daylight saving change. The help
output labels the option C<[Duration]>.

The behavior for users is described in L<Getopt::Pad/duration>.

=head1 SEE ALSO

L<Getopt::Pad/TYPES>, L<Getopt::Pad::Type::Temporal>,
L<Getopt::Pad::Type::Date>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
