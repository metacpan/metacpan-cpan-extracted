package GFX::Enhancer::SingleLineAntialias;

sub new {
	my ($class, $imgrepr) = @_;

	my $self = { imgrepr => $imgrepr, };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub filter {
	my ($self, $imgrepr, @rgba_points) = @_;

	my @non_return_rgba_points = @rgba_points;
	my @return_rgba_points = ();

	my @indexl = ();
	for (my $i = 0; $i < length(@rgba_points); $i++) {
		push (@indexl, @rgba_points[$i]->{index});
	}

	for (my $i = 0; $i < length(@rgba_points); $i++) {
		for (my $j = 0; $j < length(@rgba_points); $j++) {
			### grep points to be deleted  
			my @non_return_rgba_points = grep { $_ != $self->grep(@indexl, @rgba_points) } @non_return_rgba_points;
		}
	}

	### delete grepped points from resulting list
	for (my $i = 0; $i < length(@rgba_points); $i++) {
		if (not (@rgba_points[$i] ~~ @non_rgba_rgba_points)) {
			push (@return_rgba_points, @rgba_points[$i]);
		}
	}
	
	return (@return_rgba_points);
}

sub grep {
	my ($self, @indexl, @rgbasl) = @_;

	my @grepped_points = (); ### these are scheduled for deletion

	for (my $i = 0; $i < length(@rgbasl); $i++) {
		if ((@rgbasl[$i]->{@rgbasl[$i]->{index} - $self->{imgrepr}->{width}}) % $self->{imgrepr}->{width} ~~ @indexl
			and (@rgbasl[$i]->{@rgbasl[$i]->{index} - $self->{imgrepr}->{width} - 1}) % $self->{imgrepr}->{width} ~~ @indexl
			and (@rgbasl[$i]->{@rgbasl[$i]->{index} - $self->{imgrepr}->{width} + 1}) % $self->{imgrepr}->{width} ~~ @indexl) {
		push (@grepped_points, @rgbasl[$i]);
		}
	}
	return (@grepped_points);	
}

1;
