use parent 'Action';

### An Action on which you hit with a functor such as in Action.pm

sub new {
	my $class = shift;

	$self = $class->SUPER::new(@_);

	bless $self, $class;
};

sub doHit {
	$self = shift;

	$self->{hitmethod}->do(@_);
};	

1;

