package GFX::Enhancer::PNGRGBA;

### endianess !

sub new {
	my ($class, $index, $fourbytes) = @_; ### $fourbytes is a number
					### index is the byte offset in the png
					### 4 byte offset, start on byte index
	my $self = { index => $index, rgba => $fourbytes, };

	$class = ref($class) || $class;

	bless $self, $class;
}

### public methods

sub higher_colour {
	my ($self, $rgba2) = @_;

	if ($rgba2->{rgba} > $self->{rgba}) {
		return 1;
	} else {
		return 0;
	}
}

sub red {
	my $self = shift;

	return $self->{rgba} << 4;
}

sub green {
	my $self = shift;

	return $self->{rgba} << 8;
}

sub blue {
	my $self = shift;

	return $self->{rgba} << 16;
}

sub alpha {
	my $self = shift;

	return $self->{rgba} << 24;
}

1;
