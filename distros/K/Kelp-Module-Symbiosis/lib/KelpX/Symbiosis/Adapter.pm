package KelpX::Symbiosis::Adapter;
$KelpX::Symbiosis::Adapter::VERSION = '2.00';
use Kelp::Base;
use Carp;
use Plack::Middleware::Conditional;
use Plack::Util;
use KelpX::Symbiosis::Util;

attr engine => sub { croak 'no engine was choosen' };
attr -app => sub { croak 'app is required' };
attr -mounted => sub { {} };
attr -loaded => sub { {} };
attr -middleware => sub { [] };
attr reverse_proxy => 0;

sub mount
{
	my ($self, $path, $app) = @_;

	if (!ref $app && $app) {
		my $loaded = $self->loaded;
		croak "Symbiosis: cannot mount $app because no such name was loaded"
			unless $loaded->{$app};
		$app = $loaded->{$app};
	}

	# mount first, not to pollute mounted hash if the exception is caught and
	# the program continues
	my $mounted = $self->engine->mount($path, $app);
	$self->mounted->{$path} = $app;
	return $mounted;
}

sub _link
{
	my ($self, $name, $app, $mount) = @_;
	my $loaded = $self->loaded;

	carp "Symbiosis: overriding module name $name"
		if exists $loaded->{$name};
	$loaded->{$name} = $app;

	if ($mount) {
		$self->mount($mount, $app);
	}
	return scalar keys %{$loaded};
}

sub run
{
	my $self = shift;

	my $app = $self->engine->run(@_);

	my $wrapped = KelpX::Symbiosis::Util::wrap($self, $app);
	return $self->_reverse_proxy_wrap($wrapped);
}

sub _reverse_proxy_wrap
{
	my ($self, $app) = @_;
	return $app unless $self->reverse_proxy;

	my $mw_class = Plack::Util::load_class('ReverseProxy', 'Plack::Middleware');
	return Plack::Middleware::Conditional->wrap(
		$app,
		condition => sub { !$_[0]{REMOTE_ADDR} || $_[0]{REMOTE_ADDR} =~ m{127\.0\.0\.1} },
		builder => sub { $mw_class->wrap($_[0]) },
	);
}

sub build
{
	my ($self, %args) = @_;

	if ($args{reverse_proxy}) {
		$self->reverse_proxy(1);
	}

	$self->engine->build(%args);
	KelpX::Symbiosis::Util::load_middleware($self, %args);
}

sub new
{
	my ($class, %args) = @_;

	my $self = $class->SUPER::new(%args);

	# turn engine into an object
	my $engine_class = Plack::Util::load_class($self->engine, 'KelpX::Symbiosis::Engine');
	$self->engine($engine_class->new(adapter => $self));

	return $self;
}

1;

# This is not internal, but currently no specific documentation is provided.
# All of the interface is documented in Kelp::Module::Symbiosis.

