package KelpX::Symbiosis::Engine::URLMap;
$KelpX::Symbiosis::Engine::URLMap::VERSION = '2.10';
use Kelp::Base 'KelpX::Symbiosis::Engine';
use Plack::App::URLMap;
use Carp;

attr handler => sub { Plack::App::URLMap->new };

sub build
{
	my ($self, %args) = @_;

	# even if not mounted, try to mount under /
	$args{mount} //= '/'
		unless exists $args{mount};

	$self->SUPER::build(%args);
}

sub mount
{
	my ($self, $path, $app) = @_;

	$self->handler->map($path, $self->run_app($app));
	return;
}

sub run
{
	my $self = shift;

	return $self->handler->to_app;
}

1;
__END__

=head1 NAME

KelpX::Symbiosis::Engine::URLMap - Default engine implementation

=head1 DESCRIPTION

This is a reimplementation of L<KelpX::Symbiosis::Engine> using
L<Plack::App::URLMap> as a runner. It's pretty straightforward and mounts Kelp
as just one of the apps in the ecosystem (not giving it any special treatment).

=head1 CAVEATS

=head2 Symbiosis paths will always have priority over Kelp routes

