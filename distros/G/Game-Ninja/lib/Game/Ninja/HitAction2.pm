use parent 'Action2';

### An Action on which you/first entity hits based on Action2 subclasses

sub new {
	my $class = shift;

	$self = $class->SUPER::new(@_);

	bless $self, $class;
};

sub doHit {
	$self = shift;

	$self->{hitaction}->doHit(@_);
};	

1;

