use parent 'Action';

### An Action on which you take a hit based on functors in Action.pm

sub new {
	my $class = shift;

	$self = $class->SUPER::new(@_);

	bless $self, $class;
};

sub takeHit {
	$self = shift;

	$self->{tohitmethod}->do(@_);
};	

1;

