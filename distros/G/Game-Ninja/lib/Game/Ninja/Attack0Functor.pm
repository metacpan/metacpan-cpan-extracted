### override this class as an Attacking functor

### $subroutine is a function reference

sub new {
	my ($class, $subroutine) = @_;

	$self = { fref => $subroutine, }; 

	bless $self, $class;
};

sub setMethod {
	my ($self, $f) = @_;

	$self->{fref} = $f;
};

sub do {
	my ($self, @args) = @_;

	$self->{ref}(@args);
}

1;
