package GFX::Enhancer::SingleLineEnhancer;

### project a single line from e.g. a scanned in line (with a RL scanner)

sub new {
	my ($class) = @_;

	my $self = { lines_points => (), adjacent_lines_points => (), }; ### lines_points are enhanced, adjacent_lines_points are all neighbourhood points

	$class = ref($class) || $class;

	bless $self, $class;
}

sub filter {
	my ($self, $imgrepr) = @_; 

	### points are PNGRGBAs

	for (my $i = 0; $i < length($imgrepr->{points}); $i++) {
		if (my @rgbasl = $self->investigate_neighbourhood_of_points($i, $imgrepr, GFX::Enhancer::PointsInvestigator->new)) {
			push(@{ $self->{adjacent_lines_points}}, @rgbasl);
			$i += length(@rgbasl); ### extraneous points added to
		}
	}
	### the result is in $self->{lines_points}
	$self->antialias(GFX::Enhancer::SingleLineAntialias->new($imgrepr));	
}

### private methods

sub investigate_neighbourhood_of_points {
	my ($self, $rgba_point_index, $imgrepr, $investigator) = @_;

	return ($investigator->calculate_neighbourhood($rgba_point_index, $self->{adjacent_lines_points}, $imgrepr));
}

sub antialias {
	my ($antialiaser) = @_;

	$self->{lines_points} = $antialiaser->filter($self->{adjacent_lines_points});
}

1;
