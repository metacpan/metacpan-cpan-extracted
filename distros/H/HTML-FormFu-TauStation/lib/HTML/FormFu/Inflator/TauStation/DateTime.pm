use strict;
package HTML::FormFu::Inflator::TauStation::DateTime;
$HTML::FormFu::Inflator::TauStation::DateTime::VERSION = '1.182322';
use Moose;
extends 'HTML::FormFu::Inflator';

use HTML::FormFu::Constants qw( $EMPTY_STR );
use DateTime::Format::TauStation 1.182290;


sub inflator {
    my ( $self, $value ) = @_;

    return if !defined $value || $value eq $EMPTY_STR;

    return DateTime::Format::TauStation->parse_datetime( $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Inflator::TauStation::DateTime

=head1 SYNOPSIS

    ---
    elements:
        - type: Text
          contraint:
              - 'TauStation::DateTime'
          inflator:
              - 'TauStation::DateTime'
          deflator:
              - 'TauStation::DateTime'

=head1 DESCRIPTION

Inflate TauStation GCT dates into L<DateTime::Calendar::TauStation> objects.

For a corresponding deflator, see L<HTML::FormFu::Deflator::TauStation::DateTime>.

=head1 SEE ALSO

L<DateTime::Calendar::TauStation>.

L<DateTime::Format::TauStation>.

L<HTML::FormFu::TauStation>.

Is a sub-class of, and inherits methods from L<HTML::FormFu::Constraint>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks, C<github@tauhead.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
