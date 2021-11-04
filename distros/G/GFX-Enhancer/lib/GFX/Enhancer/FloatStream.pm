package GFX::Enhancer::Stream;

### uses a list of float numbers

sub new {
	my ($class, $length, @listoffloats) = @_;

	### listoffloats is a list of float bytes
        my $self = { length => $length, listoffloats => @listoffloats, index => 0, }; 

	$class = ref($class) || $class;

	bless $self, $class;
}

### public methods

sub next {
	my ($self) = @_;

	$self->{index} <= $length or (print "float stream ended" and $self->{index} = 0);

	return $self->{listoffloats}[$self->{index}++];
}

1;
