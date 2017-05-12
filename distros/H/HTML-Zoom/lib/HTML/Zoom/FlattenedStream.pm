package HTML::Zoom::FlattenedStream;

use strictures 1;
use base qw(HTML::Zoom::StreamBase);

sub new {
  my ($class, $args) = @_;
  bless({ _source => $args->{source}, _zconfig => $args->{zconfig} }, $class);
}

sub _next {

  return unless (my $self = shift)->{_source};
  my ($next, $s);
  until (($next) = ($s = $self->{_cur}) ? $s->next : ()) {
    unless (($self->{_cur}) = $self->{_source}->next) {
      delete $self->{_source}; return;
    }
  }
  return $next;
}

1;
