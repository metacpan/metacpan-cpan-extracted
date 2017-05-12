package Games::Go::Referee::Node;

sub new {
  my $class = shift;
  my $self  = {};
  $self->{movecount}  = shift;
  $self->{passcount}  = shift;
  $self->{colour}     = shift;
  $self->{point}      = shift; # co-ordinates of the move
  $self->{board}      = undef; # reference to '....xo...' (for a 3x3 board)
  $self->{captures}   = undef; # reference to [0][12], [1][12]
  bless $self, $class;
  return $self;
}

sub movecount {
  my $self = shift;
  return $self->{movecount}
}

sub passcount {
  my $self = shift;
  $self->{passcount} = shift if @_;
  return $self->{passcount}
}

sub colour {
  my $self = shift;
  $self->{colour} = shift if @_;
  return $self->{colour}
}

sub point {
  my $self = shift;
  return $self->{point}
}

sub board {
  my $self = shift;
  $self->{board} = shift if @_;
  return $self->{board}
}

sub captures {
  my $self = shift;
  $self->{captures} = shift if @_;
  return $self->{captures}
}

1;
