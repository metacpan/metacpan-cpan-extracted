package HTML::Zoom::FilterStream;

use strictures 1;
use base qw(HTML::Zoom::StreamBase);

sub new {
  my ($class, $args) = @_;
  if ($args->{filters}) {
    die "Single filter please (XXX FIXME)"
      unless @{$args->{filters}} == 1;
    $args->{filter} = $args->{filters}[0];
  }
  bless(
    {
      _stream => $args->{stream},
      _match => $args->{match},
      _filter => $args->{filter},
      _zconfig => $args->{zconfig},
    },
    $class
  );
}

sub _next {
  my ($self, $am_peek) = @_;

  # if our main stream is already gone then we can short-circuit
  # straight out - there's no way for an alternate stream to be there

  return unless $self->{_stream};

  # if we have an alternate stream (provided by a filter call resulting
  # from a match on the main stream) then we want to read from that until
  # it's gone - we're still effectively "in the match" but this is the
  # point at which that fact is abstracted away from downstream consumers

  my $_next = $am_peek ? 'peek' : 'next';

  if (my $alt = $self->{_alt_stream}) {

    if (my ($evt) = $alt->$_next) {
      $self->{_peeked_from} = $alt if $am_peek;
      return $evt;
    }

    # once the alternate stream is exhausted we can throw it away so future
    # requests fall straight through to the main stream

    delete $self->{_alt_stream};
  }

  # if there's no alternate stream currently, process the main stream

  while (my ($evt) = $self->{_stream}->$_next) {

    $self->{_peeked_from} = $self->{_stream} if $am_peek;

    # don't match this event? return it immediately

    return $evt unless $evt->{type} eq 'OPEN' and $self->{_match}->($evt);

    # run our filter routine against the current event

    my ($res) = $self->{_filter}->($evt, $self->{_stream});

    # if the result is just an event, we can return that now

    return $res if ref($res) eq 'HASH';

    # if no result at all, jump back to the top of the loop to get the
    # next event and try again - the filter has eaten this one

    next unless defined $res;

    # ARRAY means a pair of [ $evt, $new_stream ]

    if (ref($res) eq 'ARRAY') {
      $self->{_alt_stream} = $res->[1];
      return $res->[0];
    }

    # the filter returned a stream - if it contains something return the
    # first entry and stash it as the new alternate stream

    if (my ($new_evt) = $res->$_next) {
      $self->{_alt_stream} = $res;
      $self->{_peeked_from} = $res if $am_peek;
      return $new_evt;
    }

    # we got a new alternate stream but it turned out to be empty
    # - this will happens for e.g. with an in place close (<foo />) that's
    # being removed. In that case, we fall off to loop back round and try
    # the next event from our main stream
  } continue {

    # if we fell off the bottom (empty new alternate stream or filter ate
    # the event) then we need to advance our internal stream one so that the
    # top of the while loop gets the right thing; also, we need to clear the
    # _peeked_from in case our source stream is exhausted (it'll be
    # re-assigned if the while condition gets a new event)

    if ($am_peek) {
      $self->{_stream}->next;
      delete $self->{_peeked_from};
    }
  }

  # main stream exhausted so throw it away so we hit the short circuit
  # at the top and return nothing to indicate to our caller we're done

  delete $self->{_stream};
  return;
}

1;
