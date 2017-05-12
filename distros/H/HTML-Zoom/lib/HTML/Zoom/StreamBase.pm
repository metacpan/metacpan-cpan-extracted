package HTML::Zoom::StreamBase;

use strictures 1;
use HTML::Zoom::TransformBuilder;

sub _zconfig { shift->{_zconfig} }

sub peek {
  my ($self) = @_;
  if (exists $self->{_peeked}) {
    return ($self->{_peeked});
  }
  if (my ($peeked) = $self->_next(1)) {
    return ($self->{_peeked} = $peeked);
  }
  return;
}

sub next {
  my ($self) = @_;

  # peeked entry so return that

  if (exists $self->{_peeked}) {
    if (my $peeked_from = delete $self->{_peeked_from}) {
      $peeked_from->next;
    }
    return (delete $self->{_peeked});
  }

  $self->_next;
}


sub flatten {
  my $self = shift;
  require HTML::Zoom::FlattenedStream;
  HTML::Zoom::FlattenedStream->new({
    source => $self,
    zconfig => $self->_zconfig
  });
}

sub map {
  my ($self, $mapper) = @_;
  require HTML::Zoom::MappedStream;
  HTML::Zoom::MappedStream->new({
    source => $self, mapper => $mapper, zconfig => $self->_zconfig
  });
}

sub with_filter {
  my ($self, $selector, $filter) = @_;
  my $match = $self->_parse_selector($selector);
  $self->_zconfig->stream_utils->wrap_with_filter($self, $match, $filter);
}

sub with_transform {
  my ($self, $transform) = @_;
  $transform->apply_to_stream($self);
}

sub select {
  my ($self, $selector) = @_;
  return HTML::Zoom::TransformBuilder->new({
    zconfig => $self->_zconfig,
    selector => $selector,
    filters => [],
    proto => $self,
  });
}

sub then {
  my ($self) = @_;
  # see notes in HTML/Zoom.pm for why this needs to be fixed
  $self->select($self->transform->selector);
}

sub apply {
  my ($self, $code) = @_;
  local $_ = $self;
  $self->$code;
}

sub apply_if {
  my ($self, $predicate, $code) = @_;
  if($predicate) {
    local $_ = $self;
    $self->$code;
  }
  else {
    $self;
  }
}

sub to_html {
  my ($self) = @_;
  $self->_zconfig->producer->html_from_stream($self);
}

sub AUTOLOAD {
  my ($self, $selector, @args) = @_;
  my $sel = $self->select($selector);
  my $meth = our $AUTOLOAD;
  $meth =~ s/.*:://;
  if (ref($selector) eq 'HASH') {
    my $ret = $self;
    $ret = $ret->_do($_, $meth, @{$selector->{$_}}) for keys %$selector;
    $ret;
  } else {
    $self->_do($selector, $meth, @args);
  }
}

sub _do {
  my ($self, $selector, $meth, @args) = @_;
  return $self->select($selector)->$meth(@args);
}

sub DESTROY {}

1;
