package Mac::EyeTV::Recording;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use Mac::AppleScript qw(RunAppleScript);
use URI::file;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
  qw(recording start stop title
    description channel_number station_name input_source repeats quality
    enabled busy id)
);

sub delete {
  my $self = shift;
  $self->recording->delete;
}

sub duration {
  my $self = shift;
  return $self->stop - $self->start;
}

sub export {
  my($self, $path) = @_;
  
  my $id = $self->id;
  my $applescript = qq{
tell application "EyeTV"
  export from recording id $id to file "$path" as MPEGPS
end tell
  };
  warn $applescript;
  RunAppleScript($applescript);
}

1;

__END__

=head1 NAME

Mac::EyeTV::Programme - An EyeTV programme

=head1 SYNOPSIS

  use Mac::EyeTV;
  my $eyetv = Mac::EyeTV->new();

  # Examine existing programmes
  foreach my $programme ($eyetv->programmes) {
    my $start       = $programme->start;
    my $stop        = $programme->stop;
    my $title       = $programme->title;
    my $description = $programme->description;

    print "$title $start - $stop ($description)\n";
  }

  # Record a new programme
  my $programme = Mac::EyeTV::Programme->new;
  $programme->start($start_dt);
  $programme->stop($stop_dt);
  $programme->title($title);
  $programme->description($description);
  $programme->channel_number($channel_number);
  $programme->record;

  # Export an existing recording
  $programme->export("new.mpg");

  # Delete an existing programme
  $programme->delete;

=head1 DESCRIPTION

This module represents an EyeTV program. The programmes() method in
Mac::EyeTV returns a list of Mac::EyeTV::Programme objects which
represent the existing and future programs.

=head1 METHODS

=head2 new

This is the constructor, which takes no arguments:

  my $eyetv = Mac::EyeTV->new();

=head2 export

Exports the programme as an MPEGPS file:

  $programme->export("new.mpg");

=head2 delete

The delete() method deletes the programme:

  $programme->delete;

=head2 description

The description() method returns the description of the programme:

  my $description = $programme->description;

=head2 duration

The duration() method returns the duration of the programme (as a
DateTime::Duration object):

  my $duration = $programme->duration;

=head2 record

The record method schedules a new recording:

  # Record a new program
  my $programme = Mac::EyeTV::Programme->new;
  $programme->start($start_dt);
  $programme->stop($stop_dt);
  $programme->title($title);
  $programme->description($description);
  $programme->channel_number($channel_number);
  $programme->record;

=head2 start

The start method returns when the programme starts (as a DateTime
object):

  my $start = $programme->start;

=head2 stop

The stop method returns when the programme stops (as a DateTime
object):

  my $stop = $programme->stop;

=head2 title

The title() method returns the title of the programme:

  my $title = $programme->title;

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2004-5, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
