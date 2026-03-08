package Google::RestApi::CalendarApi3::Event;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      calendar => HasApi,
      id       => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'events' }
sub _parent_accessor { 'calendar' }

sub create {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      summary     => Str,
      start       => HashRef,
      end         => HashRef,
      description => Str, { optional => 1 },
      location    => Str, { optional => 1 },
      attendees   => ArrayRef[HashRef], { optional => 1 },
      _extra_     => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %content = (
    summary => delete $p->{summary},
    start   => delete $p->{start},
    end     => delete $p->{end},
  );
  $content{description} = delete $p->{description} if defined $p->{description};
  $content{location} = delete $p->{location} if defined $p->{location};
  $content{attendees} = delete $p->{attendees} if defined $p->{attendees};

  DEBUG(sprintf("Creating event '%s' on calendar '%s'", $content{summary}, $self->calendar()->calendar_id()));
  my $result = $self->calendar()->api(
    uri     => 'events',
    method  => 'post',
    content => \%content,
  );
  return ref($self)->new(calendar => $self->calendar(), id => $result->{id});
}

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

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      summary     => Str, { optional => 1 },
      description => Str, { optional => 1 },
      location    => Str, { optional => 1 },
      start       => HashRef, { optional => 1 },
      end         => HashRef, { optional => 1 },
      attendees   => ArrayRef[HashRef], { optional => 1 },
      _extra_     => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content;
  $content{summary} = delete $p->{summary} if defined $p->{summary};
  $content{description} = delete $p->{description} if defined $p->{description};
  $content{location} = delete $p->{location} if defined $p->{location};
  $content{start} = delete $p->{start} if defined $p->{start};
  $content{end} = delete $p->{end} if defined $p->{end};
  $content{attendees} = delete $p->{attendees} if defined $p->{attendees};

  DEBUG(sprintf("Updating event '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting event '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub quick_add {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      text => Str,
    ],
  );
  my $p = $check->(@_);

  DEBUG(sprintf("Quick adding event on calendar '%s': %s", $self->calendar()->calendar_id(), $p->{text}));
  my $result = $self->calendar()->api(
    uri    => 'events/quickAdd',
    method => 'post',
    params => { text => $p->{text} },
  );
  return ref($self)->new(calendar => $self->calendar(), id => $result->{id});
}

sub instances {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields        => Str, { optional => 1 },
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('instances');

  return paginated_list(
    api            => $self,
    uri            => 'instances',
    result_key     => 'items',
    default_fields => 'items(id, summary, start, end)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub move {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      destination => Str,
    ],
  );
  my $p = $check->(@_);

  $self->require_id('move');

  DEBUG(sprintf("Moving event '%s' to calendar '%s'", $self->{id}, $p->{destination}));
  my $result = $self->api(
    uri    => 'move',
    method => 'post',
    params => { destination => $p->{destination} },
  );
  return $result;
}

sub event_id { shift->{id}; }
sub calendar { shift->{calendar}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Event - Event object for Google Calendar.

=head1 SYNOPSIS

 # Create an event
 my $event = $calendar->event()->create(
   summary => 'Team Meeting',
   start   => { dateTime => '2026-03-01T10:00:00Z' },
   end     => { dateTime => '2026-03-01T11:00:00Z' },
 );

 # Quick add using natural language
 my $event = $calendar->event()->quick_add(text => 'Lunch tomorrow at noon');

 # Get event details
 my $details = $event->get();

 # Update event
 $event->update(summary => 'Updated Meeting');

 # Move event to another calendar
 $event->move(destination => 'other_calendar_id');

 # Delete event
 $event->delete();

=head1 DESCRIPTION

Represents an event on a Google Calendar. Supports creating, reading,
updating, deleting, and moving events.

=head1 METHODS

=head2 create(summary => $text, start => \%start, end => \%end, ...)

Creates a new event. Required parameters: summary, start, end.
Start and end are hashrefs with either C<dateTime> (for timed events)
or C<date> (for all-day events).

Optional parameters: description, location, attendees.

=head2 get(fields => $fields)

Gets event details. Requires event ID.

=head2 update(summary => $text, ...)

Updates event properties. Requires event ID.

=head2 delete()

Deletes the event. Requires event ID.

=head2 quick_add(text => $text)

Creates an event using natural language text parsing.

=head2 instances(params => \%params, max_pages => $n, page_callback => $coderef)

Lists instances of a recurring event. Requires event ID. C<max_pages> limits
the number of pages fetched (default 0 = unlimited). Supports C<page_callback>,
see L<Google::RestApi/PAGE CALLBACKS>.

=head2 move(destination => $calendar_id)

Moves the event to another calendar. Requires event ID.

=head2 event_id()

Returns the event ID.

=head2 calendar()

Returns the parent Calendar object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
