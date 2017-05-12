package HTML::Zoom::Transform;

use strictures 1;
use base qw(HTML::Zoom::SubObject);
use HTML::Zoom::TransformedStream;

sub new {
  my ($class, $args) = @_;
  my $new = $class->SUPER::new($args);
  $new->{selector} = $args->{selector};
  $new->{match} = $args->{match} if $args->{match};
  $new->{filters} = $args->{filters}||[];
  $new;
}

sub selector { shift->{selector} }

sub filters { shift->{filters} }

sub with_filter {
  my ($self, $filter) = @_;
  (ref $self)->new({
    selector => $self->selector,
    ($self->{match} ? (match => $self->{match}) : ()),
    filters => [ @{$self->filters}, $filter ]
  });
}

sub match {
  my ($self) = @_;
  $self->{match} ||=
    $self->_zconfig
         ->selector_parser
         ->parse_selector($self->{selector});
}

sub apply_to_stream {
  my ($self, $stream) = @_;
  HTML::Zoom::TransformedStream->new({
    stream => $stream,
    transform => $self,
    zconfig => $self->_zconfig,
  });
}
    

1;
