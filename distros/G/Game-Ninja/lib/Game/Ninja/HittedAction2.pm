use parent 'Action2';

### An Action on which you/first entity hits based on Action2 subclasses

sub new {
	my $class = shift;

	$self = $class->SUPER::new(@_);

	bless $self, $class;
};

sub takeHit {
	$self = shift;

	$self->{hitaction}->takeHit(@_);
};	

1;

