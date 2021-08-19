package GFX::Enhancer::Stream;

### for a PNG file (attribute bytes is a number which gets shifted,
### it is not an array (see the FloatStream class for that)

sub new {
	my ($class, $length, $bytes) = @_;

	### bytes is a number which represents all bytes
        my $self = { length => $length, bytes => $bytes, index => 0, }; 

	$class = ref($class) || $class;

	bless $self, $class;
}

### public methods

sub next {
	my ($self) = @_;

	$index <= $length or (print "stream ended" and $index = 0);

	return $self->{bytes} << $index++ * 4;
}

1;
