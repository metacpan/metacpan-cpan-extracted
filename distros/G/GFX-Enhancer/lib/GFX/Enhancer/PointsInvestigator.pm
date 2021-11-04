package GFX::Enhancer::PointsInvestigator;

### neighbourhood etc

sub new {
	my ($class) = @_;

	my $self = {};

	$class = ref($class) || $class;
	bless $self, $class;
}

sub calculate_neighbourhood_of_point {
  my ($self, $rgba_index, $imgrepr, $threshold) = @_;
  
  my @return_rgbasl = ();
  
  ### search for neighbourhood of $rgba_index'd points
  ### each loop consists of a width in the png rect (width x height)

  ### match if there are adjacent points width -1, width + 1 and intermediate width itself
  my @neighbourhood_points = ();
  if ($rgba_index > $imgrepr->{width} + 1) {
    push(@neighbourhood_points, $imgrepr->{points}[$rgba_index - $imgrepr->{width}]);
    push(@neighbourhood_points, $imgrepr->{points}[$rgba_index - $imgrepr->{width} - 1]);
    push(@neighbourhood_points, $imgrepr->{points}[$rgba_index - $imgrepr->{width} + 1]);
  }

  if ($rgba_index < $imgrepr->{width} * $imgrepr->{height} + 1) {
    push(@neighbourhood_points, $imgrepr->{points}[$rgba_index + $imgrepr->{width}]);
    push(@neighbourhood_points, $imgrepr->{points}[$rgba_index + $imgrepr->{width} - 1]);
    push(@neighbourhood_points, $imgrepr->{points}[$rgba_index + $imgrepr->{width} + 1]);
  }
  
  for (my $i = 0; $i < length (@neighbourhood_points); $i++) {
    if (@neighbourhood_points[$i]->threshold_colour($imgrepr->{points}[$rgba_index], $threshold)) {
      push (@return_rgbasl, @neighbourhood_points[$i]);
    }
  } 
  return @return_rgbasl;	
}

1;
  
