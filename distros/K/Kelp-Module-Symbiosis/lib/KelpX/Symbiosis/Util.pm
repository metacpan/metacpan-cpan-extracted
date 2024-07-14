package KelpX::Symbiosis::Util;
$KelpX::Symbiosis::Util::VERSION = '2.11';
use Kelp::Base -strict;
use Plack::Util;
use Kelp::Util;

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
	goto \&Kelp::Util::adapt_psgi;
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

Moved to core Kelp in version I<2.10>. This function will not be removed for
backward compatilibity, but is now just an alias for L<Kelp::Util/adapt_psgi>.

