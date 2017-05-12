package Mac::EyeTV;
use strict;
use warnings;
use Mac::Glue;
use Mac::EyeTV::Channel;
use Mac::EyeTV::Programme;
use Mac::EyeTV::Recording;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(eyetv));
our $VERSION = "0.30";

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;

  my $eyetv = Mac::Glue->new('EyeTV');
  $self->eyetv($eyetv);

  return $self;
}

sub channels {
  my $self  = shift;
  my $eyetv = $self->eyetv;
  my @channels;

  my @eyetv_channels = $eyetv->obj('channels')->get;
  foreach my $eyetv_channel (@eyetv_channels) {
    my $channel = Mac::EyeTV::Channel->new;
    $channel->channel($eyetv_channel);
    $channel->number($eyetv_channel->prop('channel number')->get);
    $channel->name($eyetv_channel->prop('name')->get);
    push @channels, $channel;
  }
  return @channels;
}

sub programmes {
  my $self  = shift;
  my $eyetv = $self->eyetv;
  my @programmes;

  my @eyetv_programmes = $eyetv->obj('programs')->get;
  foreach my $eyetv_programme (@eyetv_programmes) {
    my $programme = Mac::EyeTV::Programme->new;
    $programme->programme($eyetv_programme);

    my $start =
      DateTime->from_epoch(epoch => $eyetv_programme->prop("start time")->get);
    my $duration =
      DateTime::Duration->new(
      seconds => $eyetv_programme->prop("duration")->get);
    my $stop = $start + $duration;

    $programme->start($start);
    $programme->stop($stop);

    my %map = (
      'channel_number' => 'channel number',
      'station_name '  => 'station name',
      'input_source'   => 'input source',
      'id'             => 'unique ID',
    );

    foreach my $prop (
      qw(title description channel_number station_name input_source repeats quality enabled id)
      )
    {
      my $eyetv_prop = $map{$prop} || $prop;
      my $value = $eyetv_programme->prop($eyetv_prop)->get;
      $programme->$prop($value);
    }

    push @programmes, $programme;
  }
  return @programmes;
}

sub recordings {
  my $self  = shift;
  my $eyetv = $self->eyetv;
  my @programmes;

  my @eyetv_programmes = $eyetv->obj('recordings')->get;
  foreach my $eyetv_programme (@eyetv_programmes) {
    my $programme = Mac::EyeTV::Recording->new;
    $programme->recording($eyetv_programme);

    my $start =
      DateTime->from_epoch(epoch => $eyetv_programme->prop("start time")->get);
    my $duration =
      DateTime::Duration->new(
      seconds => $eyetv_programme->prop("duration")->get);
    my $stop = $start + $duration;

    $programme->start($start);
    $programme->stop($stop);

    my %map = (
      'channel_number' => 'channel number',
      'station_name '  => 'station name',
      'input_source'   => 'input source',
      'id'             => 'unique ID',
    );

    foreach my $prop (
      qw(title description channel_number station_name input_source repeats quality enabled busy id)
      )
    {
      my $eyetv_prop = $map{$prop} || $prop;
      my $value = $eyetv_programme->prop($eyetv_prop)->get;
      $programme->$prop($value);
    }

    push @programmes, $programme;
  }
  return @programmes;
}

1;

__END__

=head1 NAME

Mac::EyeTV - Interface to the Elgato EyeTV Digital Video Recorder

=head1 SYNOPSIS

  use Mac::EyeTV;
  my $eyetv = Mac::EyeTV->new();

  # See Mac::EyeTV::Channel
  foreach my $channel ($eyetv->channels) {
    my $name   = $channel->name;
    my $number = $channel->number;
    print "$number $name\n";
  }

  # See Mac::EyeTV::Programme
  foreach my $programme ($eyetv->programmes) {
    my $start = $programme->start;
    my $stop  = $programme->stop;
    my $title = $programme->title;
    print "$title $start - $stop\n";
  }

=head1 DESCRIPTION

This module allows you to interface to the Elgato EyeTV Digital Video
Recorder. EyeTV is a piece of software and hardware for Mac OS X which
can record and play back television much like a Tivo. This module
allows you to interface to the EyeTV software, view the channel list
and the recorded programmes and schedule recordings.

See Mac::EyeTV::Programme for information on scheduling a recording.

You should create Mac::Glue bindings to EyeTV before using this
(along the lines of 'sudo gluemac EyeTV').

The EyeTV software itself is available from Elgato Systems at
http://www.elgato.com/index.php?file=support_updates_eyetv

=head1 METHODS

=head2 new

This is the constructor, which takes no arguments:

  my $eyetv = Mac::EyeTV->new();

=head2 channels

This returns the channels known by EyeTV:

  # See Mac::EyeTV::Channel
  foreach my $channel ($eyetv->channels) {
    my $name   = $channel->name;
    my $number = $channel->number;
    print "$number $name\n";
  }

=head2 programmes

This returns the programmes known by EyeTV:

  # See Mac::EyeTV::Programme
  foreach my $program ($eyetv->programmes) {
    my $start = $programme->start;
    my $stop  = $programme->stop;
    my $title = $programme->title;
    print "$title $start - $stop\n";
  }

=head2 recordings

This returns the recordings known by EyeTV:

  # See Mac::EyeTV::Programme
  foreach my $program ($eyetv->programmes) {
    my $start = $programme->start;
    my $stop  = $programme->stop;
    my $title = $programme->title;
    print "$title $start - $stop\n";
  }

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2004-5, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.


