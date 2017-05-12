package Leyland;

# ABSTRACT: RESTful web application framework based on Plack

use Moo;
use parent 'Plack::Component';
use namespace::clean;
use version 0.77;

our $VERSION = "1.000002";
$VERSION = eval $VERSION;
our $DISPLAY_VERSION = version->parse($VERSION)->normal;

use Carp;
use Encode;
use Leyland::Localizer;
use Leyland::Negotiator;
use Module::Load;
use Scalar::Util qw/blessed/;
use Text::SpanningTable;
use Tie::IxHash;
use Try::Tiny;

our %INFO;

=head1 NAME

Leyland - RESTful web application framework based on Plack

=head1 SYNOPSIS

	# in app.psgi:

	#!/usr/bin/perl -w

	use strict;
	use warnings;
	use MyApp;

	my $app = MyApp->new->to_app;

=head1 DESCRIPTION

Leyland is a L<Plack>-based application framework for building truely
RESTful, MVC-style web applications. It is feature rich and highly
extensible.

B<STOP! BACKWORDS COMPATIBILITY BREAKING CHANGES>

	Leyland v1.0.0 brings small changes that break backwords compatibility.
	Read the L<upgrading manual|Leyland::Manual::Upgrading> for more information.

=head2 FEATURES

=over

=item * B<Build truely RESTful web applications:> Leyland was designed from
the ground up according to the Representational State Transfer style of
software architecture. Leyland applications perform real HTTP negotiations,
(can) provide different representations of the same resource easily, respond
with proper HTTP status codes, throw real HTTP exceptions, etc.

=item * B<Automatic data (de)serialization> - Leyland automatically
serializes resources to representations in the format your client
wants to receive, like JSON and XML. It will also automatically deserialize
JSON/XML requests coming from the client to Perl data-structures.

=item * B<Pure UTF-8> - Leyland applications are pure UTF-8. Anything your
application receives is automatically UTF-8 decoded, and anything your
application sends is automatically UTF-8 encoded. Leyland apps will not
accept, nor provide, content in a different character set. If you want to
use different/multiple encodings, then Leyland is not for you.

=item * B<Localize for the client, not the server> - Pretty much every other
application framework only concerns itself with localizing the application
to the locale of the machine on which it is running. I find that this is
rarely useful nor interesting to the application developer. Leyland localizes for
the client, not the server. If the client wants to view your application
(which may be a simple website) in Hebrew, and your application supports
Hebrew, then you can easily provide him with Hebrew representations.
Leyland uses L<Locale::Wolowitz> for this purpose.

=item * B<< Easy deployment and middleware support via L<Plack> >> - Leyland doesn't
support Plack, it is dependant on it. Leyland's entire session support,
for example, depends on Plack's L<Session|Plack::Middleware::Session>
middleware. Use the full power of Plack in your Leyland application.

=item * B<Lightweight> - Leyland is much smaller than L<Catalyst> or other
major frameworks, while still providing lots of features. While it is not
a "micro-framework", it is pretty small. If you're looking for an extremely
lightweight solution, my other framework - L<McBain> - might fit your need.

=item * B<Flexible, extensible> - Leyland was designed to be as flexible and
as extensible as possible - where flexibility matters, and strict - where
constistency and convention are appropriate. Leyland goes to great lengths
to give you the ability to do things the way you want to, and more
importantly - the way your end-users want to. Your applications listen to
your users' preferences and automatically decide on a suitable course of action.
Leyland is also L<Moo> based, making it easy to extend and tweak its behavior
(and making it L<Moose> compatible).

=item * B<Doesn't have a pony> - You don't really need a pony, do you?

=back

=head2 MANUAL / TUTORIAL / GUIDE / GIBBERISH

To learn about using Leyland, please refer to the L<Leyland::Manual>. The
documentation of this distribution's classes is for reference only, the
manual is where you're most likely to find your answers. Or not.

=head2 UPGRADING FROM VERSION 0.1.7 OR SMALLER

Major changes have been made in Leyland version 1.0.0. While most should be
backwords compatible, some are not. Please take a look at the L<upgrading manual|Leyland::Manual::Upgrading>
for a complete list of changes and a simple guide for upgrading existing applications.

=head2 WHAT'S WITH THE NAME?

Leyland is named after Mr. Bean's clunker of a car - the British Leyland
Mini 1000. I don't know why.

=head1 EXTENDS

L<Plack::Component>

=head1 ATTRIBUTES

=head2 name

The package name of the application, for example C<MyApp> or C<My::App>.
Automatically created.

=head2 config

A hash-ref of configuration options supplied to the app by the PSGI file.
These options are purely for the writer of the application and have nothing
to do with Leyland itself.

=head2 context_class

The name of the class to be used as the context class for every request.
Defaults to L<Leyland::Context>. If provided, the class must extend
Leyland::Context.

=head2 localizer

If application config defines a path for localization files, this will hold
a L<Leyland::Localizer> object, which is based on L<Locale::Wolowitz>.

=head2 views

An array refernce of all L<Leyland::View> classes enabled in the app's
configuration. If none defined, L<Tenjin> is used by default.

=head2 routes

A L<Tie::IxHash> object holding all routes defined in the application's
controllers. Automatically created, not to be used directly by applications.

=head2 cwe

The plack environment in which the application is running. This is the
C<PLACK_ENV> environment variable. Defaults to "development" unless you've
provided a specific value to C<plackup> (via the C<-E> switch or by
changing C<PLACK_ENV> directly).

=cut

has 'name' => (
	is => 'ro',
	isa => sub { die "name must be a scalar" if ref $_[0] },
	writer => '_set_name'
);

has 'config' => (
	is => 'ro',
	isa => sub { die "config must be a hash-ref" unless ref $_[0] && ref $_[0] eq 'HASH' },
	default => sub { {} }
);

has 'context_class' => (
	is => 'ro',
	isa => sub { die "context_class must be a scalar" if ref $_[0] },
	writer => '_set_context_class',
	default => sub { 'Leyland::Context' }
);

has 'localizer' => (
	is => 'ro',
	predicate => 'has_localizer',
	writer => '_set_localizer'
);

has 'views' => (
	is => 'ro',
	isa => sub { die "views must be an array-ref" unless ref $_[0] && ref $_[0] eq 'ARRAY' },
	predicate => 'has_views',
	writer => '_set_views'
);

has 'routes' => (
	is => 'ro',
	isa => sub { die "routes must be a Tie::IxHash object" unless ref $_[0] && ref $_[0] eq 'Tie::IxHash' },
	predicate => 'has_routes',
	writer => '_set_routes'
);

has 'cwe' => (
	is => 'ro',
	isa => sub { die "cwe must be a scalar" if ref $_[0] },
	default => sub { $ENV{PLACK_ENV} }
);

=head1 CLASS METHODS

=head2 new( [ %attrs ] )

Creates a new instance of this class. None of the attributes are required
(in fact, you shouldn't pass most of them), though you can pass the
C<config> and C<context_class> attributes if you need.

=head1 OBJECT METHODS

=head2 setup()

This method is not available by default, but is expected to be provided by
application classes (though it is not required). If present, it will be
called upon creation of the application object. The method is expected to
return a hash-ref of Leyland-specific options. The following options are
supported:

=over

=item * views

A list of view classes to load. Defaults to C<["Tenjin"]>.

=item * view_dir

The path to the directory in which views/templates reside (defaults to C<views>).

=item * locales

The path to the directory in which localization files (in L<Locale::Wolowitz>'s format)
reside (if localization is used).

=item * default_mime

The default return MIME type for routes that lack a specific declaration (defaults to C<text/html>).

=back

=head2 call( \%env )

The request handler. Receives a standard PSGI env hash-ref, creates a new instance of the
application's context class  (most probably L<Leyland::Context>), performs HTTP negotiations
and finds routes matching the request. If any are found, the first one is invoked and
an HTTP response is generated and returned.

You should note that requests to paths that end with a slash will automatically
be redirected without the trailing slash.

=cut

sub call {
	my ($self, $env) = @_;

	# create the context object
	my $c = $self->context_class->new(
		app => $self,
		env => $env
	);

	# does the request path have an "unnecessary" trailing slash?
	# if so, remove it and redirect to the resulting URI
	if ($c->path ne '/' && $c->path =~ m!/$!) {
		my $newpath = $`;
		my $uri = $c->uri;
		$uri->path($newpath);
		
		$c->res->redirect($uri, 301);
		return $c->_respond;
	}

	# is this an OPTIONS request?
	if ($c->method eq 'OPTIONS') {
		# get all available methods by using Leyland::Negotiator
		# and return a 204 No Content response
		$c->log->debug('Finding supported methods for requested path.');
		return $c->_respond(204, { 'Allow' => join(', ', Leyland::Negotiator->find_options($c, $self->routes)) });
	} else {
		# negotiate for routes and invoke the first matching route (if any).
		# handle route passes and return the final output after UTF-8 encoding.
		# if at any point an expception is raised, handle it.
		return try {
			# get routes
			$c->log->debug('Searching matching routes.');
			$c->_set_routes(Leyland::Negotiator->negotiate($c, $self->routes));

			# invoke first route
			$c->log->debug('Invoking first matching route.');
			my $ret = $c->_invoke_route;

			# are we passing to the next matching route?
			# to prevent infinite loops, limit passing to no more than 100 times
			while ($c->_pass_next && $c->current_route < 100) {
				# we need to pass to the next matching route.
				# first, let's erase the pass flag from the context
				# so we don't try to do this infinitely
				$c->_set_pass_next(0);
				# no let's invoke the route
				$ret = $c->_invoke_route;
			}

			$c->finalize(\$ret);
			
			$c->_respond(undef, undef, $ret);
		} catch {
			$self->_handle_exception($c, $_);
		};
	}
}

=head2 has_localizer()

Returns a true value if the application has a localizer.

=head2 has_views()

Returns a true value if the application has any view classes.

=head2 has_routes()

Returns a true value if the application has any routes defined in its
controllers.

=head1 INTERNAL METHODS

The following methods are only to be used internally.

=head2 BUILD()

Automatically called by L<Moo> after instance creation, this method
runs the applicaiton's C<setup()> method (if any), loads the context class,
localizer, controllers and views. It then find all routes in the controllers
and prints a nice info table to the log.

=cut

sub BUILD {
	my $self = shift;

	# invoke setup method and get application settings
	my $settings = $self->can('setup') ? $self->setup : {};
	$settings->{views} ||= ['Tenjin'];
	$settings->{view_dir} ||= 'views';

	$self->_set_name(blessed $self);

	$INFO{default_mime} = $settings->{default_mime} || 'text/html';

	$self->_set_context_class($settings->{context_class})
		if $settings->{context_class};

	# load the context class
	load $self->context_class;

	# init localizer, if localization path given
	$self->_set_localizer(Leyland::Localizer->new(path => $self->config->{locales}))
		if exists $self->config->{locales};

	# require Module::Pluggable and load all views and controllers
	# with it
	load Module::Pluggable;
	Module::Pluggable->import(
		search_path => [$self->name.'::View'],
		sub_name => '_views',
		instantiate => 'new'
	);
	Module::Pluggable->import(
		search_path => [$self->name.'::Controller'],
		sub_name => 'controllers',
		require => 1
	);

	# init views, if any, start with view modules in the app
	my @views = $self->_views;
	# now load views defined in the config file
	VIEW: foreach (@{$settings->{views}}) {
		# have we already loaded this view in the first step?
		foreach my $v ($self->_views) {
			next VIEW if blessed($v) eq $_;
		}

		# attempt to load this view
		my $class = "Leyland::View::$_";
		load $class;
		push(@views, $class->new(view_dir => $settings->{view_dir}));
	}
	$self->_set_views(\@views) if scalar @views;

	# if we haven't loaded any views, load Tenjin
	unless (scalar @views) {
		load Leyland::View::Tenjin;
		$self->_set_views([ Leyland::View::Tenjin->new(view_dir => $settings->{view_dir}) ]);
	}

	# get all routes
	my $routes = Tie::IxHash->new;
	foreach ($self->controllers) {
		my $prefix = $_->prefix || '_root_';
		
		# in order to allow multiple controllers having the same
		# prefix, let's see if we've already encountered this prefix,
		# and if so, merge the routes
		if ($routes->EXISTS($prefix)) {
			foreach my $r ($_->routes->Keys) {
				foreach my $m (keys %{$_->routes->FETCH($r)}) {
					if ($routes->FETCH($prefix)->EXISTS($r)) {
						$routes->FETCH($prefix)->FETCH($r)->{$m} = $_->routes->FETCH($r)->{$m};
					} else {
						$routes->FETCH($prefix)->Push($r => { $m => $_->routes->FETCH($r)->{$m} });
					}
				}
			}
		} elsif ($_->routes && $_->routes->Length) {
			$routes->Push($prefix => $_->routes);
		}
	}
	$self->_set_routes($routes);

	# print debug information
	$self->_initial_debug_info;
}

# _handle_exception( $c, $exp )
# -----------------------------
# Receives exceptions thrown by the application (including run-time errors)
# and generates an HTTP response with the error information, in a format
# recognizable by the client.

sub _handle_exception {
	my ($self, $c, $exp) = @_;

	# have we caught a Leyland::Exception object? if not, turn it into
	# a Leyland::Exception
	$exp = Leyland::Exception->new(code => 500, error => $exp)
		unless blessed($exp) && $exp->isa('Leyland::Exception');

	# log the error thrown
	$c->log->info('Exception thrown: '.$exp->code.", message: ".$exp->error);

	# is this a redirecting exception?
	if ($exp->code =~ m/^3\d\d$/ && $exp->has_location) {
		$c->res->redirect($exp->location);
		return $c->_respond($exp->code);
	}

	# are we on the development environment? if so, and the client
	# accepts HTML (and the exception has no HTML MIME), we croak
	# with a simple error message so that Plack displays a nice stack trace
	croak $self->name.' croaked with HTTP status code '.$exp->code.' and error message "'.$exp->error.'"'
		if $self->cwe eq 'development' && $c->accepts('text/html') && (!$exp->has_mimes || !$exp->has_mime('text/html'));

	# do we have templates for any of the client's requested MIME types?
	# if so, render the first one you find.
	if ($exp->has_mimes) {
		foreach (@{$c->wanted_mimes}) {
			return $c->_respond(
				$exp->code,
				{ 'Content-Type' => $_->{mime}.'; charset=UTF-8' },
				$c->template($exp->mime($_->{mime}), $exp->hash, $exp->use_layout)
			) if $exp->has_mime($_->{mime});
		}
	}

	# we haven't found any templates for the request mime types, let's
	# attempt to serialize the error ourselves if the client accepts
	# JSON or XML
	foreach (@{$c->wanted_mimes}) {
		return $c->_respond(
			$exp->code,
			{ 'Content-Type' => $_->{mime}.'; charset=UTF-8' },
			$c->_serialize($exp->hash, $_->{mime})
		) if	$_->{mime} eq 'text/html' ||
			$_->{mime} eq 'application/xhtml+xml' ||
			$_->{mime} eq 'application/json' ||
			$_->{mime} eq 'application/atom+xml' ||
			$_->{mime} eq 'application/xml';
	}

	# We do not support none of the MIME types the client wants,
	# let's return plain text
	return $c->_respond(
		$exp->code,
		{ 'Content-Type' => 'text/plain; charset=UTF-8' },
		$exp->error
	);
}

# _autolog( $msg )
# ----------------
# Used by C<Text::SpanningTable> when printing the application's info
# table.

sub _autolog { print STDOUT $_[0], "\n" }

# _initial_debug_info()
# ---------------------
# Prints an info table of the application after initialization.

sub _initial_debug_info {
	my $self = shift;

	my @views;
	foreach (sort @{$self->views || []}) {
		my $view = ref $_;
		$view =~ s/^Leyland::View:://;
		push(@views, $view);
	}

	my $t1 = Text::SpanningTable->new(96);
	$t1->exec(\&_autolog);

	$t1->hr('top');
	$t1->row($self->name.' (powered by Leyland '.$DISPLAY_VERSION.')');
	$t1->dhr;
	$t1->row('Current working environment: '.$self->cwe);
	$t1->row('Avilable views: '.join(', ', @views));
	
	$t1->hr('bottom');
	
	my $t2 = Text::SpanningTable->new(16, 24, 13, 18, 18, 12);
	$t2->exec(\&_autolog);
	$t2->hr('top');
	$t2->row([6, 'Available routes:']);
	$t2->dhr;

	if ($self->has_routes && $self->routes->Length) {
		$t2->row('Prefix', 'Regex', 'Method', 'Accepts', 'Returns', 'Is');
		$t2->dhr;

		foreach (sort { ($b eq '_root_') <=> ($a eq '_root_') || $a cmp $b } $self->routes->Keys) {
			my $c = $_;
			$c =~ s!_root_!(root)!;
			my $pre = $self->routes->FETCH($_);
			if ($pre) {
				foreach my $r (sort $pre->Keys) {
					my $reg = $pre->FETCH($r);
					foreach my $m (sort keys %$reg) {
						my $returns = ref $reg->{$m}->{rules}->{returns} eq 'ARRAY' ? join(', ', @{$reg->{$m}->{rules}->{returns}}) : $reg->{$m}->{rules}->{returns};
						my $accepts = ref $reg->{$m}->{rules}->{accepts} eq 'ARRAY' ? join(', ', @{$reg->{$m}->{rules}->{accepts}}) : $reg->{$m}->{rules}->{accepts};
						my $is = ref $reg->{$m}->{rules}->{is} eq 'ARRAY' ? join(', ', @{$reg->{$m}->{rules}->{is}}) : $reg->{$m}->{rules}->{is};
						
						$t2->row($c, $r, uc($m), $accepts, $returns, $is);
					}
				}
			}
		}
	} else {
		$t2->row([6, '-- No routes available!']);
	}

	$t2->hr('bottom');
}

$Leyland::CODES = {
	# success codes
	200 => 'OK',
	201 => 'Created',
	202 => 'Accepted',
	204 => 'No Content',

	# redirect codes
	300 => 'Multiple Choices',
	301 => 'Moved Permanently',
	302 => 'Found',
	303 => 'See Other',
	304 => 'Not Modified',
	307 => 'Temporary Redirect',

	# client error codes
	400 => 'Bad Request',
	401 => 'Unauthorized',
	403 => 'Forbidden',
	404 => 'Not Found',
	405 => 'Method Not Allowed',
	406 => 'Not Acceptable',
	408 => 'Request Timeout',
	409 => 'Conflict',
	410 => 'Gone',
	411 => 'Length Required',
	412 => 'Precondition Failed',
	413 => 'Request Entity Too Large',
	414 => 'Request-URI Too Long',
	415 => 'Unsupported Media Type',
	417 => 'Expectation Failed',

	# server error codes
	500 => 'Internal Server Error',
	501 => 'Not Implemented',
	502 => 'Bad Gateway',
	503 => 'Service Unavailable',
	504 => 'Gateway Timeout',
	522 => 'Connection timed out',
};

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 ACKNOWLEDGMENTS

I wish to thank the following people:

=over

=item * L<Sebastian Knapp|http://search.cpan.org/~sknpp/> for submitting bug fixes

=item * L<Michael Alan Dorman|http://search.cpan.org/~mdorman/> for some helpful ideas

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Leyland>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Leyland>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Leyland>

=item * Search CPAN

L<http://search.cpan.org/dist/Leyland/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
