package KelpX::Symbiosis::Util;
$KelpX::Symbiosis::Util::VERSION = '2.00';
use Kelp::Base -strict;
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

sub plack_to_kelp
{
	my ($app) = @_;

	return sub {
		my $kelp = shift;
		my $path = pop() // '';
		my $env = $kelp->req->env;

		# remember script and path
		my $orig_script = $env->{SCRIPT_NAME};
		my $orig_path = $env->{PATH_INFO};

		# adjust slashes in paths
		my $trailing_slash = $orig_path =~ m{/$} ? '/' : '';
		$path =~ s{^/?}{/};
		$path =~ s{/?$}{$trailing_slash};

		# adjust script and path
		$env->{SCRIPT_NAME} = $orig_path;
		$env->{SCRIPT_NAME} =~ s{\Q$path\E$}{};
		$env->{PATH_INFO} = $path;

		# run the callback
		my $result = $app->($env, @_);

		# restore old script and path
		$env->{SCRIPT_NAME} = $orig_script;
		$env->{PATH_INFO} = $orig_path;

		# produce a response
		if (ref $result eq 'ARRAY') {
			my ($status, $headers, $body) = @{$result};

			my $res = $kelp->res;
			$res->status($status) if $status;
			$res->headers($headers) if $headers;
			$res->body($body) if $body;
			$res->rendered(1);
		}
		elsif (ref $result eq 'CODE') {
			return $result;
		}

		# this should be an error unless already rendered
		return;
	};
}

1;

__END__

=head1 NAME

KelpX::Symbiosis::Util - Reusable tools for Symbiosis

=head1 SYNOPSIS

	use KelpX::Symbiosis::Util;

	my $app = SomePlackApp->new;
	$kelp->routes->add(
		'/newapp/>',
		KelpX::Symbiosis::Util::plack_to_kelp($app->to_app),
	);

=head1 DESCRIPTION

These are some utilities helpful when Plack and Kelp are wrestling each other.

=head1 USAGE

=head2 Functions

None of the functions are exported, use them together with package name.

=head3 wrap

	my $wrapped = KelpX::Symbiosis::Util::wrap($obj, $app);

Wraps C<$app> inside all the middleware declared in C<$obj>, which should
contain attribute C<middleware> with contents loaded using L</load_middleware>.

=head3 load_middleware

	KelpX::Symbiosis::Util::load_middleware($obj, %config);

Loads standard Kelp middleware definitions into C<middleware> attribute of
C<$obj> (adds to it, does not clear it). Can be used later with L</wrap>.

=head3 plack_to_kelp

	my $kelp_destination = KelpX::Symbiosis::Util::plack_to_kelp($plack_app);

Turns a Plack app into a Kelp destination (a sub). Useful to mount Plack stuff
under a specific Kelp route.

