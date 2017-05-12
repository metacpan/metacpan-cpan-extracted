package Filter::ExtractSource::CodeObj;

sub new {
  my $invocant = shift;
  my $class    = ref($invocant) || $invocant;
  my $self     = {};
  bless $self,$class;
  return $self;
}

sub merge {
  my $self  = shift;
  push @{$self->{lines}},shift;
  $self->{end} = shift;
}

sub DESTROY {
  my $self = shift;
  print join "",@{$self->{lines}},$self->{end};
}

1;
