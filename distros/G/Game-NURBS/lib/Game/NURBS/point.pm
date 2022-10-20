### point in 3 dimensions (x,y,z)

sub new {
	my ($class, $x, $y, $z) = @_;

	$self = { x => $x, y => $y, z => $z, };

	bless $self, $class;
}

sub xyz {
	my $self = shift;

	my @array = ();

	push(@array, $self->{x});
	push(@array, $self->{y});
	push(@array, $self->{z});

	return @array;
} 

sub getx {
	my $self = shift;

	return $self->x;
}

sub gety {
	my $self = shift;

	return $self->y;
}

sub getz {
	my $self = shift;

	return $self->z;
}

sub setx {
	my ($self, $x) = @_;

	$self->{x} = $x;
}

sub sety {
	my ($self, $y) = @_;

	$self->{y} = $y;
}

sub setz {
	my ($self, $z) = @_;

	$self->{z} = $z;
}

1;
