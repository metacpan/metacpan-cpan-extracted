package GFX::Enhancer::PointsInvestigator;

### neighbourhood etc

sub new {
	my ($class) = @_;

	my $self = {};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub calculate_neighbourhood {
	my ($self, $rgba_index, @previous_lines_points, $imgrepr) = @_;

	my @return_rgbasl = ();

	### search for neighbourhood of $rgba_index'd points
	### each loop consists of a width in the png rect

	### previous line fetch NOTE reverse
	my @prevs = ();
	for (my $j = 0; $j < reverse (@previous_lines_points); $j++) { 
		### < further $i
		if (@previous_lines_points[$j]->{index} < $imgrepr->{points}[$rgba_index]->{index} / 4) {
			push(@prevs, @previous_lines_points[$j]);
		} else {
			last;
		}
	}
		
	@prevs = reverse (@prevs);

	if (length (@prevs) != 0) { 

		for (my $i = $imgrepr->{points}[$rgba_index]->{index} / 4; $i < $imgrepr->{width}; $i++) {
			for (my $j = 0; $j < length(@prevs); $j++) {
				if (@prevs[$j]->{index} / 4 <= $i - $imgrepr->{width}) {
					for (my $k = 0; $k < length(@prevs); $k++) {
						### match if there are adjacent points width -1, width + 1 and intermediate width itself
						if (@prevs[$k]->{index} / 4 == @prevs[$j] - $imgrepr->{width} or @prevs[$k]->{index} / 4 == @prevs[$j] - $imgrepr->{width} - 1 or @prevs[$k]->{index} / 4 == @prevs[$j] - $imgrepr->{width} + 1) {
	push (@return_rgbasl, $imgrepr->{points}[$rgba_index]) unless ($imgrepr->{points}[$rgba_index] ~~ @return_rgbasl); ### unless element in already list
}
}
}
}				
}
} else {
	### FIXME
}
	return @return_rgbasl;	
}
1;
