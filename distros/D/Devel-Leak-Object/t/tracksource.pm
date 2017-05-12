package Devel::Leak::Object::Tests::tracksource;

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	$self->{foo} = $self;
}
1;
