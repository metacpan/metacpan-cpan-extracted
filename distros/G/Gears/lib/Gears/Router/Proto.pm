package Gears::Router::Proto;
$Gears::Router::Proto::VERSION = '0.104';
use v5.40;
use Mooish::Base -standard, -role;

requires qw(
	pattern
);

has param 'router' => (
	isa => InstanceOf ['Gears::Router'],
	weak_ref => 1,
);

has field 'locations' => (
	isa => ArrayRef [InstanceOf ['Gears::Router::Location']],
	default => sub { [] },
);

sub add ($self, $pattern, $data = {})
{
	my $sep = $self->router->pattern_separator;
	my $full_pattern = ($self->pattern =~ s{\Q$sep\E$}{}r) . $sep . ($pattern =~ s{^\Q$sep\E}{}r);
	$full_pattern =~ s{\Q$sep\E$}{}
		unless $full_pattern eq $sep;

	my $location = $self->router->_build_location(
		$data->%*,
		router => $self->router,
		pattern => $full_pattern,
	);

	push $self->locations->@*, $location;
	return $location;
}

