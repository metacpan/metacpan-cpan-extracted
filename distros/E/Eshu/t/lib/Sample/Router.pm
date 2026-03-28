package Sample::Router;

use strict;
use warnings;

our $VERSION = '0.03';

my %ROUTES;
my %MIDDLEWARE;

sub new {
	my ($class, %opts) = @_;
	return bless {
		prefix     => $opts{prefix} || '',
		routes     => [],
		middleware => [],
		not_found  => $opts{not_found} || sub { [404, [], ['Not Found']] },
	}, $class;
}

sub use_middleware {
	my ($self, $mw, %opts) = @_;
	push @{$self->{middleware}}, {
		handler => $mw,
		path    => $opts{path} || '/',
		order   => $opts{order} || 0,
	};
	return $self;
}

sub get    { shift->_add_route('GET',    @_) }
sub post   { shift->_add_route('POST',   @_) }
sub put    { shift->_add_route('PUT',    @_) }
sub delete { shift->_add_route('DELETE', @_) }

sub _add_route {
	my ($self, $method, $path, $handler, %opts) = @_;
	my $full_path = $self->{prefix} . $path;

	# Convert :param style to regex captures
	my $pattern = $full_path;
	my @param_names;
	$pattern =~ s{:(\w+)}{
		push @param_names, $1;
		'([^/]+)'
	}ge;

	push @{$self->{routes}}, {
		method      => $method,
		path        => $full_path,
		pattern     => qr{^$pattern$},
		param_names => \@param_names,
		handler     => $handler,
		name        => $opts{name},
	};
	return $self;
}

sub dispatch {
	my ($self, $env) = @_;
	my $method = $env->{REQUEST_METHOD};
	my $path   = $env->{PATH_INFO} || '/';

	# Run middleware chain
	for my $mw (sort { $a->{order} <=> $b->{order} } @{$self->{middleware}}) {
		if (index($path, $mw->{path}) == 0) {
			my $result = $mw->{handler}->($env);
			return $result if $result;
		}
	}

	# Match routes
	for my $route (@{$self->{routes}}) {
		next unless $route->{method} eq $method;
		if (my @captures = ($path =~ $route->{pattern})) {
			my %params;
			for my $i (0 .. $#captures) {
				$params{$route->{param_names}[$i]} = $captures[$i]
					if $i < scalar @{$route->{param_names}};
			}
			$env->{route_params} = \%params;
			return $route->{handler}->($env);
		}
	}

	return $self->{not_found}->($env);
}

sub url_for {
	my ($self, $name, %params) = @_;
	for my $route (@{$self->{routes}}) {
		next unless defined $route->{name} && $route->{name} eq $name;
		my $url = $route->{path};
		$url =~ s{:(\w+)}{
			$params{$1} // ":$1"
		}ge;
		return $url;
	}
	return undef;
}

# Heredoc for default error page
my $ERROR_TEMPLATE = <<'HTML';
<!DOCTYPE html>
<html>
<head><title>Error</title></head>
<body>
<h1>%s</h1>
<p>%s</p>
</body>
</html>
HTML

sub _render_error {
	my ($self, $code, $message) = @_;
	my $body = sprintf($ERROR_TEMPLATE, $code, $message);
	return [$code, ['Content-Type' => 'text/html'], [$body]];
}

=head1 NAME

Sample::Router - A toy HTTP router for testing

=head1 SYNOPSIS

    my $r = Sample::Router->new(prefix => '/api');
    $r->get('/users/:id', sub { ... });
    $r->post('/users', sub { ... });

    my $response = $r->dispatch($env);

=head1 METHODS

=head2 new

    my $router = Sample::Router->new(%opts);

=head2 dispatch

    my $res = $router->dispatch(\%env);

=cut

1;
