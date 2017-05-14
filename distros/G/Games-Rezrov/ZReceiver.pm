package Games::Rezrov::ZReceiver;
# stub ZIO used for redirecting output.

sub new {
  my ($type) = @_;
  my $self = {};
  bless $self, $type;
  $self->reset();
  return $self;
}

sub write_zchar {
#  print STDERR "received: " . chr($_[1]);
  $_[0]->{"buffer"} .= chr($_[1]);
}

sub buffer {
  return $_[0]->{"buffer"};
}

sub reset {
  $_[0]->{"buffer"} = "";
}

sub misc {
  # misc info for this object; hack used in stream3 redirection
  $_[0]->{"misc"} = $_[1] if defined $_[1];
  return $_[0]->{"misc"};
}

sub buffer_zchar {
  $_[0]->{"buffer"} .= chr($_[1]);
#  printf STDERR "redirect: %s\n", chr($_[1]);
}

sub buffer_zchunk {
  $_[0]->{"buffer"} .= ${$_[1]};
}

sub flush {
#  $_[0]->{"buffer"} .= $_;
}

sub newline {
  # z-char for newline
  $_[0]->{"buffer"} .= chr(Games::Rezrov::ZConst::Z_NEWLINE());
}

1;

