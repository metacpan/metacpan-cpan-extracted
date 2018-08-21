use strict;
package HTML::FormFu::Inflator::TauStation::Duration;
$HTML::FormFu::Inflator::TauStation::Duration::VERSION = '1.182322';
use Moose;
extends 'HTML::FormFu::Inflator';

use HTML::FormFu::Constants qw( $EMPTY_STR );
use DateTime::Format::TauStation 1.182290;


sub inflator {
    my ( $self, $value ) = @_;

    return if !defined $value || $value eq $EMPTY_STR;

    return DateTime::Format::TauStation->parse_duration( $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Inflator::TauStation::Duration

=head1 SYNOPSIS

    ---
    elements:
        - type: Text
          contraint:
              - 'TauStation::Duration'
          inflator:
              - 'TauStation::Duration'
          deflator:
              - 'TauStation::Duration'

=head1 DESCRIPTION

Inflate TauStation GCT durations into L<DateTime::Duration::TauStation> objects.

For a corresponding deflator, see L<HTML::FormFu::Deflator::TauStation::Duration>.

=head1 SEE ALSO

L<DateTime::Duration::TauStation>.

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
