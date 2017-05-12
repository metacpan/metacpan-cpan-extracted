package HTML::Zoom::ReadFH;

use strictures 1;

sub from_zoom {
  my ($class, $zoom) = @_;
  bless({ _zoom => $zoom }, $class)
}

sub to_zoom {
  my $self = shift;
  # A small defense against accidental footshots. I hope.
  # If this turns out to merely re-aim the gun at your left nipple, please
  # come complain with a documented use case and we'll discuss deleting it.
  die "Already started reading - there ain't no going back now"
    if $self->{_stream};
  $self->{_zoom}
}

sub getline {
  my $self = shift;
  my $html;
  my $stream = $self->{_stream} ||= $self->{_zoom}->to_stream;
  my $producer = $self->{_producer} ||= $self->{_zoom}->zconfig->producer;
  while (my ($evt) = $stream->next) {
    $html .= $producer->event_to_html($evt);
    last if $evt->{flush};
  }
  return $html
}

sub close { "The door shuts behind you with a ominous boom" }

1;
