package Google::RestApi::CalendarApi3::CalendarList;

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

sub _uri_base { 'users/me/calendarList' }
sub _parent_accessor { 'calendar_api' }

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub insert {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id      => Str,
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %content = (
    id => delete $p->{id},
  );

  DEBUG(sprintf("Inserting calendar '%s' into calendar list", $content{id}));
  my $result = $self->calendar_api()->api(
    uri     => 'users/me/calendarList',
    method  => 'post',
    content => \%content,
  );
  return ref($self)->new(calendar_api => $self->calendar_api(), id => $result->{id});
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      summary_override => Str, { optional => 1 },
      color_id         => Str, { optional => 1 },
      hidden           => Bool, { optional => 1 },
      selected         => Bool, { optional => 1 },
      _extra_          => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content;
  $content{summaryOverride} = delete $p->{summary_override} if defined $p->{summary_override};
  $content{colorId} = delete $p->{color_id} if defined $p->{color_id};
  $content{hidden} = delete $p->{hidden} ? JSON::MaybeXS::true() : JSON::MaybeXS::false() if defined $p->{hidden};
  $content{selected} = delete $p->{selected} ? JSON::MaybeXS::true() : JSON::MaybeXS::false() if defined $p->{selected};

  DEBUG(sprintf("Updating calendar list entry '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting calendar list entry '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub calendar_list_id { shift->{id}; }
sub calendar_api { shift->{calendar_api}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::CalendarList - CalendarList object for Google Calendar.

=head1 SYNOPSIS

 # Get a calendar list entry
 my $cl = $cal_api->calendar_list(id => 'primary');
 my $info = $cl->get();

 # Insert a calendar into the user's list
 my $cl = $cal_api->calendar_list()->insert(id => 'calendar_id@group.calendar.google.com');

 # Update display settings
 $cl->update(summary_override => 'My Custom Name', color_id => '7');

 # Remove from the user's list
 $cl->delete();

=head1 DESCRIPTION

Represents an entry in the user's calendar list. This manages the user's
view and display settings for calendars, not the calendars themselves.

=head1 METHODS

=head2 get(fields => $fields)

Gets calendar list entry details. Requires calendar list ID.

=head2 insert(id => $calendar_id)

Inserts a calendar into the user's calendar list.

=head2 update(summary_override => $name, color_id => $id, ...)

Updates display settings. Requires calendar list ID.

=head2 delete()

Removes the calendar from the user's list. Requires calendar list ID.

=head2 calendar_list_id()

Returns the calendar list entry ID.

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
