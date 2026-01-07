package Gears::Component;
$Gears::Component::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

has param 'app' => (
	isa => InstanceOf ['Gears::App'],
	weak_ref => 1,
);

sub BUILD ($self, $)
{
	$self->configure;
	my $class = ref $self;

	# make sure superclass build method won't be called (avoid building the
	# same elements twice)
	if (exists &{"${class}::build"}) {
		$self->build;
	}
}

sub configure ($self)
{
}

sub build ($self)
{
}

