package Google::RestApi::CalendarApi3::Settings;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      calendar_api => HasApi,
      id           => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'users/me/settings' }
sub _parent_accessor { 'calendar_api' }

sub get {
  my $self = shift;

  $self->require_id('get');

  return $self->api();
}

sub value {
  my $self = shift;
  return $self->get()->{value};
}

sub setting_id { shift->{id}; }
sub calendar_api { shift->{calendar_api}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Settings - Settings object for Google Calendar.

=head1 SYNOPSIS

 # Get a specific setting
 my $setting = $cal_api->settings(id => 'timezone');
 my $details = $setting->get();

 # Get just the value
 my $tz = $setting->value();

=head1 DESCRIPTION

Provides access to user calendar settings (read-only).

=head1 METHODS

=head2 get()

Gets the setting details. Requires setting ID.

=head2 value()

Returns just the setting value. Requires setting ID.

=head2 setting_id()

Returns the setting ID.

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
