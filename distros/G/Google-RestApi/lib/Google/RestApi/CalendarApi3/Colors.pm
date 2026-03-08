package Google::RestApi::CalendarApi3::Colors;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      calendar_api => HasApi,
    ],
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  return $self->calendar_api()->api(uri => 'colors', @_);
}

sub get {
  my $self = shift;
  return $self->api();
}

sub calendar_colors {
  my $self = shift;
  return $self->get()->{calendar};
}

sub event_colors {
  my $self = shift;
  return $self->get()->{event};
}

sub calendar_api { shift->{calendar_api}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Colors - Colors information for Google Calendar.

=head1 SYNOPSIS

 my $colors = $cal_api->colors();

 # Get all color definitions
 my $all = $colors->get();

 # Get just calendar colors
 my $cal_colors = $colors->calendar_colors();

 # Get just event colors
 my $evt_colors = $colors->event_colors();

=head1 DESCRIPTION

Provides access to the available color definitions for calendars and events.

=head1 METHODS

=head2 get()

Gets all color definitions.

=head2 calendar_colors()

Returns calendar color definitions.

=head2 event_colors()

Returns event color definitions.

=head2 calendar_api()

Returns the parent CalendarApi3 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
