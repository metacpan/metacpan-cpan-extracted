package KelpX::Symbiosis::Engine;
$KelpX::Symbiosis::Engine::VERSION = '2.11';
use Kelp::Base;
use Carp;
use Scalar::Util qw(blessed refaddr);

attr adapter => sub { croak 'adapter is required' };
attr app_runners => sub { {} };

sub run_app
{
	my ($self, $app) = @_;

	if (blessed $app) {
		my $addr = refaddr $app;

		croak 'Symbiosis: class ' . ref($app) . ' cannot run()'
			unless $app->can("run");

		# cache the ran application so that it won't be ran twice. Also run the
		# application lazily to maintain backwards compatibility
		my $app_obj = $app;
		$app = $self->app_runners->{$addr} //= sub {
			state $real_app = $app_obj->run;
			goto $real_app;
		};
	}
	elsif (ref $app ne 'CODE') {
		croak "Symbiosis: mount point is neither an object nor a coderef: $app";
	}

	return $app;
}

sub build
{
	my ($self, %args) = @_;

	# mount through adapter so that it will be seen in mounted hash
	$self->adapter->mount($args{mount}, $self->adapter->app)
		if $args{mount};
}

sub mount
{
	my ($self, $path, $app) = @_;
	croak 'mount needs to be overridden';
}

sub run
{
	my ($self) = @_;
	croak 'run needs to be overridden';
}

1;
__END__

=head1 NAME

KelpX::Symbiosis::Engine - Base class for engine implementation

=head1 SYNOPSIS

See the code of L<KelpX::Symbiosis::Engine::URLMap> as an example.

=head1 DESCRIPTION

This is a base to be reimplemented for a specific way to run an ecosystem. An
engine should be able to mount plack apps under itself and route traffic to
them.

=head1 USAGE

=head2 Attributes

=head3 adapter

An instance of C<KelpX::Symbiosis::Adapter>.

=head3 app_runners

A cache for L</run_app>.

=head2 Methods

=head3 run_app

Finds, runs and caches an app to be mounted. Returns a coderef with the
plackified app. No need to override this, but can be useful when mounting an
app

=head3 build

Builds this engine. Run once after instantiating, passing all the Symbiosis
configuration. Can be overriden, by default mounts the app to where it was
configured to mount (but does not mount under C</> by default).

=head3 mount

Mount a plack app under the given path. Must be overridden.

=head3 run

Run the ecosystem, but without the top-level middleware. Must be overridden.

