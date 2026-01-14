package Gears::Context;
$Gears::Context::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Devel::StrictMode;

has param 'app' => (
	(STRICT ? (isa => InstanceOf ['Gears::App']) : ()),
);

__END__

=head1 NAME

Gears::Context - Request context container

=head1 SYNOPSIS

	package My::App::Context;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Context';

	...

=head1 DESCRIPTION

Gears::Context is a minimal base class for request context objects. It provides
a reference to the application and serves as a container for request-specific
data such as HTTP request and response objects, session data, or any other
state necessary to handle a single request/response cycle.

When running in strict mode (via L<Devel::StrictMode>), the C<app> attribute is
type-checked. In non-strict mode, the type check is disabled for performance.

=head1 EXTENDING

Context classes should extend Gears::Context to add request-specific attributes:

	package My::App::Context;

	use v5.40;
	use Mooish::Base;

	extends 'Gears::Context';

	has field 'request' => (
		isa => InstanceOf['Plack::Request'],
	);

	has field 'response' => (
		isa => InstanceOf['Plack::Response'],
		builder => 1,
	);

	has field 'session' => (
		isa => HashRef,
		default => sub { {} },
	);

	has field 'stash' => (
		isa => HashRef,
		default => sub { {} },
	);

	sub _build_response ($self)
	{
		return Plack::Response->new(200);
	}

The context can then be created for each request:

	sub handle_request ($app, $env)
	{
		my $ctx = My::App::Context->new(
			app => $app,
			request => Plack::Request->new($env),
		);

		# Process the request using $ctx
		# ...

		return $ctx->response->finalize;
	}

=head1 INTERFACE

=head2 Attributes

=head3 app

	$app = $context->app()

A reference to the L<Gears::App> instance. Unlike L<Gears::Component>, this is
not a weak reference, as contexts are short-lived request objects that don't
create circular reference issues.

In strict mode, this attribute is type-checked to ensure it's a Gears::App
instance. In non-strict mode, no type checking is performed.

I<Mandatory constructor argument>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

