package Kelp::Module::Symbiosis::_Util;

our $VERSION = '1.12';

use v5.10;
use warnings;
use Plack::Util;

sub wrap
{
	my ($self, $app) = @_;

	for (@{$self->middleware}) {
		my ($class, $args) = @$_;

		# Same middleware loading procedure as Kelp
		next if $self->{_loaded_middleware}{$class}++ && !$ENV{KELP_TESTING};

		my $mw = Plack::Util::load_class($class, "Plack::Middleware");
		$app = $mw->wrap($app, %{$args // {}});
	}

	return $app;
}

sub load_middleware
{
	my ($self, %args) = @_;

	my $middleware = $self->middleware;
	foreach my $mw (@{$args{middleware}}) {
		my $config = $args{middleware_init}{$mw};
		push @$middleware, [$mw, $config];
	}

	return;
}

1;
