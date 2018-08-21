package HTML::FormFu::TauStation
# ABSTRACT: HTML::FormFu modules for working with GCT (Galactic Time Coordinated) datetimes and durations from the online game Tau Station
$HTML::FormFu::TauStation::VERSION = '1.182322';
1;

=head1 NAME

HTML::FormFu::TauStation

=head1 SYNOPSIS

    ---
    elements:
        - type: Text
          name: gct_datetime
          contraint:
              - 'TauStation::DateTime'
          inflator:
              - 'TauStation::DateTime'
          deflator:
              - 'TauStation::DateTime'

        - type: Text
          name: gct_duration
          contraint:
              - 'TauStation::Duration'
          inflator:
              - 'TauStation::Duration'
          deflator:
              - 'TauStation::Duration'

=head1 DESCRIPTION

L<HTML::FormFu> modules for working with GCT (Galactic Time Coordinated)
datetimes and durations from the online game
L<Tau Station|https://taustation.space>.

=head1 SEE ALSO

L<DateTime::Calendar::TauStation>.

L<DateTime::Duration::TauStation>.

L<DateTime::Format::TauStation>.

L<HTML::FormFu::Constraint::TauStation::DateTime>.

L<HTML::FormFu::Constraint::TauStation::Duration>.

L<HTML::FormFu::Inflator::TauStation::DateTime>.

L<HTML::FormFu::Inflator::TauStation::Duration>.

L<HTML::FormFu::Deflator::TauStation::DateTime>.

L<HTML::FormFu::Deflator::TauStation::Duration>.

Is a sub-class of, and inherits methods from L<HTML::FormFu::Constraint>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks, C<github@tauhead.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
