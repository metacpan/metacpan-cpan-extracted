use strict;
package HTML::FormFu::Constraint::TauStation::Duration;
$HTML::FormFu::Constraint::TauStation::Duration::VERSION = '1.182322';
use Moose;
extends 'HTML::FormFu::Constraint';

use DateTime::Format::TauStation 1.182290;

sub constrain_value {
    my ( $self, $value ) = @_;

    return 1 if DateTime::Format::TauStation->parse_duration( $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Constraint::TauStation::Duration

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

DateTime constraint for TauStation GCT duration string.

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
