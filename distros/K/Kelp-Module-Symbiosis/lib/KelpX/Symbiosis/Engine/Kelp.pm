package KelpX::Symbiosis::Engine::Kelp;
$KelpX::Symbiosis::Engine::Kelp::VERSION = '2.11';
use Kelp::Base 'KelpX::Symbiosis::Engine';
use Carp;

attr router => sub { shift->adapter->app->routes };

sub mount
{
	my ($self, $path, $app) = @_;
	my $adapter = $self->adapter;

	croak "Symbiosis: application tries to mount itself under $path in kelp mode"
		if ref $app && $app == $adapter->app;

	# Add slurpy suffix
	if (!ref $path) {
		$path =~ s{/?$}{/>subpath};
	}
	elsif (ref $path eq 'ARRAY' && !ref $path->[1]) {
		$path->[1] =~ s{/?$}{/>subpath};
	}

	$self->router->add(
		$path, {
			to => $self->run_app($app),
			psgi => 1,
		}
	);
}

sub run
{
	my $self = shift;
	return $self->adapter->app->run;
}

1;
__END__

=head1 NAME

KelpX::Symbiosis::Engine::Kelp - Use Kelp routes as an engine

=head1 DESCRIPTION

This is a reimplementation of L<KelpX::Symbiosis::Engine> using Kelp itself as
a runner. All other apps will have to go through Kelp first, which will be the
center of the application.

=head1 CAVEATS

=head2 All system routing goes through the Kelp router

You can mix apps and Kelp actions, set bridges and build urls to all application components.

=head2 Slurpy parameter will be added to the non-regex path

C<'/static'> will be turned into C<< '/static/>subpath' >> in order to be able
to match any subpath and pass it into the app. Same with C<< [GET => '/static']
>>. This way it will allow the same mount points as other engines without extra
work. Regex patterns will not be altered in any way.

=head2 C<mount> cannot be configured for the main Kelp app

Kelp will always be mounted at the very root. The module will throw an
exception if you try to configure a different C<mount>.

=head2 Does not allow to assign specific middleware for the Kelp app

Middleware from the top-level C<middleware> will be wrapping the app the same
as Symbiosis middleware, and all other apps will have to go through it. It's
impossible to have middleware just for the Kelp app.

=head2 Middleware redundancy

Wrapping some apps in the same middleware as your main app may be redundant at
times. For example, wrapping a static app in session middleware is probably
only going to reduce its performance. If it bothers you, you may want to switch
to URLMap engine and only mount specific apps under kelp using C<< psgi => 1 >>.

