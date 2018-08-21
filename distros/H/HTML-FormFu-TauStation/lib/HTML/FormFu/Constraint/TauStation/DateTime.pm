use strict;
package HTML::FormFu::Constraint::TauStation::DateTime;
$HTML::FormFu::Constraint::TauStation::DateTime::VERSION = '1.182322';
use Moose;
extends 'HTML::FormFu::Constraint';

use DateTime::Format::TauStation 1.182290;

sub constrain_value {
    my ( $self, $value ) = @_;

    return 1 if DateTime::Format::TauStation->parse_datetime( $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Constraint::TauStation::DateTime

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

DateTime constraint for TauStation GCT time string.

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
