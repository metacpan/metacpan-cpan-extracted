package Gears::Controller;
$Gears::Controller::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

extends 'Gears::Component';

__END__

=head1 NAME

Gears::Controller - Base class for controllers

=head1 SYNOPSIS

	package My::App::Controller::User;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Controller';

	sub configure ($self)
	{
		my $r = $self->app->router;

		$r->add('/user/:id');
	}

	# Later in your application
	$app->load_controller('User');

=head1 DESCRIPTION

Gears::Controller is a base class for application controllers. Controllers are
specialized L<Gears::Component>s that typically define routes and handle
requests. They extend the component class without adding additional
functionality, serving primarily as a semantic distinction for organizing
request handlers.

Controllers are loaded using L<Gears::App/load_controller>, which automatically
resolves the controller class name relative to the application's namespace and
instantiates it with a reference to the application.

=head2 Usage patterns

=head3 Route Definition

Controllers typically define their routes in the C<build> method using
L<Gears::App/router>. Build method is not called automatically in subclasses,
preventing routing from being accidentally repeated in a subclass which omitted
the C<build> method.

=head3 Accessing Configuration

Controllers can access application configuration through L<Gears::App/config> object.

=head3 Persistent controllers

Controllers are generally supposed to be persistent - built only once at the
start of the application and reused for every request. Implementations can
chose to clone built controllers if necessary.

=head1 EXTENDING

You will want to create a base controller for your framework, for example:

	package My::Framework::Controller;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Controller';

	sub configure ($self)
	{
		# do something before build method is called
	}

=head1 INTERFACE

Controllers inherit all attributes and methods from L<Gears::Component>

