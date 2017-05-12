package HTML::Zoom::Producer::BuiltIn;

use strictures 1;
use base qw(HTML::Zoom::SubObject);

sub html_from_stream {
  my ($self, $stream) = @_;
  return
    join '',
      map $self->event_to_html($_),
        $self->_zconfig->stream_utils->stream_to_array($stream)
}

sub html_from_events {
  my ($self, $events) = @_;
  join '', map $self->event_to_html($_), @$events;
}

sub event_to_html {
  my ($self, $evt) = @_;
  # big expression
  if (defined $evt->{raw}) {
    $evt->{raw}
  } elsif ($evt->{type} eq 'OPEN') {
    '<'
    .$evt->{name}
    .(defined $evt->{raw_attrs}
        ? $evt->{raw_attrs}
        : do {
            my @names = @{$evt->{attr_names}};
            @names
              ? join(' ', '', map qq{${_}="${\$evt->{attrs}{$_}}"}, @names)
              : ''
          }
     )
    .($evt->{is_in_place_close} ? ' /' : '')
    .'>'
  } elsif ($evt->{type} eq 'CLOSE') {
    '</'.$evt->{name}.'>'
  } elsif ($evt->{type} eq 'EMPTY') {
    ''
  } else {
    die "No raw value in event and no special handling for type ".$evt->{type};
  }
}

1;
