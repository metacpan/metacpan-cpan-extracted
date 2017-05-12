package Leyland::Context;

# ABSTRACT: The working environment of an HTTP request and Leyland response

use Moo;
use namespace::clean;

use Carp;
use Data::Dumper;
use JSON;
use Leyland::Exception;
use Leyland::Logger;
use Module::Load;
use Text::SpanningTable;
use Try::Tiny;
use XML::TreePP;

extends 'Plack::Request';

=head1 NAME

Leyland::Context - The working environment of an HTTP request and Leyland response

=head1 SYNOPSIS

	# every request automatically gets a Leyland::Context object, which
	# is available in your routes and your views:
	post '^/blog$' {
		my $post = Blog->new(
			subject => $c->params->{subject},
			user => $c->user,
			date => DateTime->now,
			text => $c->params->{text}
		);
		return $c->template('blog.html', { post => $post });
	}

	# by the way, since Leyland is RESTful, your application can accept
	# requests of any content type, making the above something like
	# this:
	post '^/blog$' accepts 'text/plain' {
		my $post = Blog->new(
			subject => $c->params->{subject},
			user => $c->user,
			date => DateTime->now,
			text => $c->data
		);
		return $c->template('blog.html', { post => $post });
	}

=head1 DESCRIPTION

The Leyland context object is the heart and soul of your application. Or
something. Anyway, it's an object that escorts an HTTP request to somewhere
in your application through its entire lifetime, up to the point where an
HTTP response is sent back to the client. This is quite similar to the
L<Catalyst> context object.

The context object holds a lot of information about the request, such as
its content type, its method, the parameters/content provided with it,
the routes it matched in your application, etc. Your controllers and views
will mostly interact with this object, which apart from the information
mentioned just now, provides you with useful methods to generate the final
response, and perform other necessary operations such as logging.

The Leyland context object inherits from L<Plack::Request>, so you can
use all of its attributes and methods. But keep in mind that this class
performs some modifications on these methods, all documented in the
L</"PLACK MODIFICATIONS"> section.

This document is for reference purposes only, please refer to L<Leyland::Manual>
for more information on using the context object.

=head1 EXTENDS

L<Plack::Request>

=head1 ATTRIBUTES

=head2 app

Holds the <Leyland> object of the application.

=head2 cwe

Holds the L<Plack> environment in which the application is running. This
is the C<PLACK_ENV> environment variable. See the C<-E> or C<--env> switch
in L<plackup> for more information. Defaults to 'development'.

=head2 res

The L<Plack::Response> object used to respond to the client.

=head2 routes

An array reference of all routes matched by the request (there can be
more than one).

=head2 current_route

The index of the route to be invoked in the "routes" attribute above. By
default this would be the first route (i.e. index 0), unless C<pass>es are
performed.

=head2 froutes

An array reference of all routes matched by an internal forward.

=head2 current_froute

The index of the route to be forwarded to in the "froutes" attribute above.
By default this would be the first route (i.e. index 0), unless C<pass>es
are performed.

=head2 controller

The controller class of the current route.

=head2 wanted_mimes

An array reference of all media types the client accepts, ordered by
the client's preference, as defined by the "Accept" HTTP header.

=head2 want

The media type the L<Leyland::Negotiator> has decided to return to the
client.

=head2 lang

The language to use when localizing responses, probably according to the
client's wishes. Defaults to 'en' for English.

=head2 stash

A hash-ref of data meant to be available for the views/templates when
rendering resources.

=head2 user

Something (anything really) that describes the user that initiated the
request. This attribute will only be defined by the application, you are
free to choose whatever scheme of authentication as you wish, this attribute
is provided for your convenience. You will use the C<set_user()> method
to set the value of this attribute.

=head2 json

A L<JSON::Any> object for usage by routes as they see fit.

=head2 xml

An L<XML::TreePP> object for usage by routes as they see fit.

=head2 _pass_next

Holds a boolean value indicating whether the route has decided to pass
the request to the next matching route. Not to be used directly.

=head2 _data

Holds the content of the HTTP request for POST and PUT requests after
parsing. Not to be used directly.

=cut

has 'app' => (
	is => 'ro',
	isa => sub { die "app must be a Leyland object" unless ref $_[0] && $_[0]->isa('Leyland') },
	required => 1,
	handles => ['cwe', 'views', 'config']
);

has 'res' => (
	is => 'lazy',
	isa => sub { die "res must be a Plack::Response object" unless ref $_[0] && $_[0]->isa('Plack::Response') }
);

has 'routes' => (
	is => 'ro',
	isa => sub { die "routes must be an array-ref" unless ref $_[0] && ref $_[0] eq 'ARRAY' },
	predicate => 'has_routes',
	writer => '_set_routes'
);

has 'current_route' => (
	is => 'ro',
	isa => sub { die "current_route must be an integer" unless $_[0] =~ m/^\d+$/ },
	default => sub { 0 },
	writer => '_set_current_route'
);

has 'froutes' => (
	is => 'ro',
	isa => sub { die "froutes must be an array-ref" unless ref $_[0] && ref $_[0] eq 'ARRAY' },
	predicate => 'has_froutes',
	writer => '_set_froutes',
	clearer => '_clear_froutes'
);

has 'current_froute' => (
	is => 'ro',
	isa => sub { die "current_froute must be an integer" unless $_[0] =~ m/^\d+$/ },
	default => sub { 0 },
	writer => '_set_current_froute'
);

has 'controller' => (
	is => 'ro',
	isa => sub { die "controller must be a scalar" if ref $_[0] },
	writer => '_set_controller'
);

has 'wanted_mimes' => (
	is => 'ro',
	isa => sub { die "wanted_mimes must be an array-ref" unless ref $_[0] && ref $_[0] eq 'ARRAY' },
	builder => '_build_mimes'
);

has 'want' => (
	is => 'ro',
	isa => sub { die "want must be a scalar" if ref $_[0] },
	writer => '_set_want'
);

has 'lang' => (
	is => 'ro',
	isa => sub { die "lang must be a scalar" if ref $_[0] },
	writer => 'set_lang',
	default => sub { 'en' }
);

has 'stash' => (
	is => 'ro',
	isa => sub { die "stash must be an hash-ref" unless ref $_[0] && ref $_[0] eq 'HASH' },
	default => sub { {} }
);

has 'user' => (
	is => 'ro',
	predicate => 'has_user',
	writer => 'set_user',
	clearer => 'clear_user'
);

has 'log' => (
	is => 'lazy',
	isa => sub { die "log must be a Leyland::Logger object" unless ref $_[0] && ref $_[0] eq 'Leyland::Logger' }
);

has 'json' => (
	is => 'ro',
	isa => sub { die "json must be a JSON object" unless ref $_[0] && ref $_[0] eq 'JSON' },
	default => sub { JSON->new->utf8(0)->convert_blessed }
);

has 'xml' => (
	is => 'ro',
	isa => sub { die "xml must be an XML::TreePP object" unless ref $_[0] && ref $_[0] eq 'XML::TreePP' },
	default => sub { my $xml = XML::TreePP->new(); $xml->set(utf8_flag => 1); return $xml; }
);

has '_pass_next' => (
	is => 'ro',
	default => sub { 0 },
	writer => '_set_pass_next'
);

has '_data' => (
	is => 'ro',
	predicate => '_has_data',
	writer => '_set_data'
);

=head1 OBJECT METHODS

Since this class extends L<Plack::Request>, it inherits all its methods,
so refer to Plack::Request for a full list. However, this module performs
some modifications on certain Plack::Request methods, all of which are
documented in the L</"PLACK MODIFICATIONS"> section.

=head2 leyland

An alias for the "app" attribute.

=cut

sub leyland { shift->app }

=head2 has_routes()

Returns a true value if the request matched any routes.

=head2 has_froutes()

Returns a true value if the request has routes matched in an internal forward.

=head2 set_lang( $lang )

Sets the language to be used for localization.

=head2 has_user()

Returns a true value if the "user" argument has a value.

=head2 set_user( $user )

Sets the "user" argument with a new value. This value could be anything,
a simple string/number, a hash-ref, an object, whatever your app uses.

=head2 clear_user()

Clears the value of the "user" argument, if any. Useful for logout actions.

=head2 params()

A shortcut for C<< $c->parameters->as_hashref_mixed >>. Note that this
is read-only, so changes you make to the hash-ref returned by this method
are not stored. For example, if you run C<< $c->params->{something} = 'whoa' >>,
subsequent calls to C<< $c->params >> will not have the "something"
key.

=cut

sub params { shift->parameters->as_hashref_mixed }

=head2 data( [ $dont_parse ] )

Returns the data of the request for POST and PUT requests. If the data
is JSON or XML, this module will attempt to automatically convert it to a Perl
data structure, which will be returned by this method (if conversion will
fail, this method will return an empty hash-ref). Otherwise, the data will be returned
as is. You can force this method to return the data as is even if it's
JSON or XML by passing a true value to this method.

If the request had no content, an empty hash-ref will be returned. This is different
than version 0.003 and down where it would have returned C<undef>.

=cut

sub data {
	my ($self, $dont_parse) = @_;

	return {} unless $self->content_type && $self->content;

	return $self->_data if $self->_has_data;

	if ($self->content_type =~ m!^application/json! && !$dont_parse) {
		my $data = try { $self->json->decode($self->content) } catch { {} };
		return unless $data;
		$self->_set_data($data);
		return $self->_data;
	} elsif ($self->content_type =~ m!^application/(atom+)?xml! && !$dont_parse) {
		my $data = try { $self->xml->parse($self->content) } catch { {} };
		return unless $data;
		$self->_set_data($data);
		return $self->_data;
	} else {
		my $data = $self->content;
		$self->_set_data($data);
		return $self->_data;
	}

	return;
}

=head2 pass()

Causes Leyland to invoke the next matching route, if any, after this
request has finished (meaning it does not pass immediately). Since you
will most likely want to pass routes immediately, use C<< return $self->pass >>
in your routes to do so.

=cut

sub pass {
	my $self = shift;

	# are we passing inside an internal forward or externally?
	# in any case, do not allow passing if we don't have routes to pass to
	if ($self->has_froutes && $self->current_froute + 1 < scalar @{$self->froutes}) {
		$self->_set_current_froute($self->current_froute + 1);
		$self->_set_pass_next(1);
		return 1;
	} elsif (!$self->has_froutes && $self->current_route + 1 < scalar @{$self->routes}) {
		$self->_set_current_route($self->current_route + 1);
		$self->_set_pass_next(1);
		return 1;
	}

	return 0;
}

=head2 render( $tmpl_name, [ \%context, $use_layout ] )

=head2 template( $tmpl_name, [ \%context, $use_layout ] )

Renders the view/template named C<$tmpl_name> using the first view class
defined by the application. Anything in the C<$context> hash-ref will be
automatically available inside the template, which will be rendered inside
whatever layout template is defined, unless C<$use_layout> is provided
and holds a false value (well, 0 really). The context object (i.e. C<$c>)
will automatically be embedded in the C<$context> hash-ref under the name
"c", as well as the application object (i.e. C<< $c->app >>) under the
name "l". Anything in the stash (i.e. C<< $c->stash >>) will also be
embedded in the context hash-ref, but keys in C<$context> take precedence
to the stash, so if the stash has the key 'name' and C<$context> also has
the key 'name', then the one from C<$context> will be used.

Returns the rendered output. You will mostly use this at the end of your
routes as the return value.

The two methods are the same, C<template> is provided as an alias for
C<render>.

=cut

sub render {
	my ($self, $tmpl_name, $context, $use_layout) = @_;

	# first, run the pre_template sub
	$self->controller->pre_template($self, $tmpl_name, $context, $use_layout);

	# allow passing $use_layout but not passing $context
	if (defined $context && ref $context ne 'HASH') {
		$use_layout = $context;
		$context = {};
	}

	# default $use_layout to 1
	$use_layout = 1 unless defined $use_layout;

	$context->{c} = $self;
	$context->{l} = $self->leyland;
	foreach (keys %{$self->stash}) {
		$context->{$_} = $self->stash->{$_} unless exists $context->{$_};
	}

	return unless scalar @{$self->views};

	return $self->views->[0]->render($tmpl_name, $context, $use_layout);
}

sub template { shift->render(@_) }

=head2 forward( $path, [ @args ] )

Immediately forwards the request (internally) to a different location defined
by C<$path>. Leyland will attempt to find routes that match the provided
path (without performing HTTP negotiations for the request's method,
content type, accepted media types, etc. like L<Leyland::Negotiator> does).
The first matching route will be invoked, with C<@args> passed to it (if
provided). The returned output (before serializing, if would have been
performed had the route been invoked directly) is returned and the route
from which the C<forward> has been called continues. If you don't want
it to continue, simple use C<< return $c->forward('/somewhere') >>.

The path should include the HTTP method of the route to forward to, by
prefixing C<$path> with the method name and a colon, like so: C<< $c->forward('POST:/somewhere') >>.
If a method is not provided (i.e. C<< $c->forward('/somewhere') >>), C<Leyland>
will assume a C<GET> method. Note that this differs from version C<0.003> and
down, where it would forward to the first matching route, regardless of the method.
This is a safety measure so you do not accidentally forward to C<DELETE> routes.

Note that if no routes are found, a 500 Internal Server Error will be
thrown, not a 404 Not Found error, as this really is an internal server
error.

=cut

sub forward {
	my ($self, $path) = (shift, shift);

	$self->exception({ code => 500, error => "You must provide a path to forward to" }) unless $path;

	my $method;

	if ($path =~ m/^(GET|POST|PUT|DELETE|HEAD|OPTIONS):/) {
		$method = $1;
		$path = $';
	} else {
		$method = 'GET';
	}

	$self->log->debug("Attempting to forward request to $path with a $method method.");

	my $routes = Leyland::Negotiator->_negotiate_path($self, {
		app_routes => $self->app->routes,
		path => $path,
		method => $method,
		internal => 1
	});

	$self->_set_froutes($routes);

	$self->exception({ code => 500, error => "Can't forward as no matching routes were found" }) unless scalar @$routes;

	my @pass = ($routes->[0]->{class}, $self);
	push(@pass, @{$routes->[0]->{captures}}) if scalar @{$routes->[0]->{captures}};
	push(@pass, @_) if scalar @_;

	# invoke the first matching route
	my $ret = $routes->[0]->{code}->(@pass);

	# are we passing to the next matching route?
	# to prevent infinite loops, limit passing to no more than 100 times
	while ($self->_pass_next && $self->current_froute < 100) {
		$self->log->debug("Passing request to the next matching route.");

		# we need to pass to the next matching route.
		# first, let's erase the pass flag from the context
		# so we don't try to do this infinitely
		$self->_set_pass_next(0);
		# no let's invoke the route
		$ret = $routes->[$self->current_froute]->{code}->(@pass);
	}

	$self->_clear_froutes;
	$self->_set_current_froute(0);

	return $ret;
}

=head2 loc( $msg, [ @args ] )

Uses L<Leyland::Localizer> to localize the provided string to the language
defined in the "lang" attribute, possibly performing some replacements
with the values provided in C<@args>. See L<Leyland::Manual::Localization>
for more info.

=cut

sub loc {
	my ($self, $msg, @args) = @_;

	return $self->app->localizer->loc($msg, $self->lang, @args);
}

=head2 exception( \%err )

Throws a L<Leyland::Exception>. C<$err> must have a "code" key with the
error's HTTP status code, and most likely an "error" key with a description
of the error. See L<Leyland::Manual::Exceptions> for more information.

=cut

sub exception {
	my ($self, $err) = @_;

	$err->{location} = $err->{location}->as_string
		if $err->{location} && ref $err->{location} =~ m/^URI/;

	Leyland::Exception->throw($err);
}

=head2 uri_for( $path, [ \%query ] )

Returns a L<URI> object with the full URI to the provided path. If a
C<$query> hash-ref is provided, it will be converted to a query string
and used in the URI object.

=cut

sub uri_for {
	my ($self, $path, $args) = @_;

	my $uri = $self->base;
	my $full_path = $uri->path . $path;
	$full_path =~ s!^/!!; # remove starting slash
	$uri->path($full_path);
	$uri->query_form($args) if $args;

	return $uri;
}

=head2 finalize( \$ret )

This method is meant to be overridden by classes that extend this class,
if used in your application. It is automatically called after the route
has been invoked and it gets a reference to the output returned from the
route (after serialization, if performed), even if this output is a scalar
(like HTML text), in which case C<$ret> will be a reference to a scalar.

You can use it to modify and manipulate the returned output if you wish.

The default C<finalize()> method provided by this class does not do anything.

=cut

sub finalize { 1 } # meant to be overridden

=head2 accepts( $mime )

Returns a true value if the client accepts the provided MIME type.

=cut

sub accepts {
	my ($self, $mime) = @_;

	foreach (@{$self->wanted_mimes}) {
		return 1 if $_->{mime} eq $mime;
	}

	return;
}

=head1 INTERNAL METHODS

The following methods are only to be used internally:

=cut

sub _build_res { shift->new_response(200) }

sub _build_mimes {
	my $self = shift;

	my @wanted_mimes;

	my $accept = $self->header('Accept');
	if ($accept) {
		my @mimes = split(/, ?/, $accept);
		foreach (@mimes) {
			my ($mime, $q) = split(/;q=/, $_);
			$q = 1 unless defined $q;
			push(@wanted_mimes, { mime => $mime, q => $q });
		}
		@wanted_mimes = reverse sort {
			if ($a->{q} > $b->{q}) {
				return 1;
			} elsif ($b->{q} > $a->{q}) {
				return -1;
			} elsif ($a->{mime} eq 'text/html' && $b->{mime} ne 'text/html') {
				return 1;
			} elsif ($b->{mime} eq 'text/html' && $a->{mime} ne 'text/html') {
				return -1;
			} elsif ($a->{mime} eq 'application/xhtml+xml' && $b->{mime} ne 'application/xhtml+xml') {
				return 1;
			} elsif ($b->{mime} eq 'application/xhtml+xml' && $a->{mime} ne 'application/xhtml+xml') {
				return -1;
			} else {
				return 0;
			}
		} @wanted_mimes;
		return \@wanted_mimes;
	} else {
		return [];
	}
}

sub _respond {
	my ($self, $status, $headers, $content) = @_;

	$self->res->status($status) if $status && $status =~ m/^\d+$/;
	$self->res->headers($headers) if $headers && ref $headers eq 'HASH';
	$self->res->header('X-Framework' => 'Leyland '.$Leyland::DISPLAY_VERSION);
	if ($content) {
		my $body = Encode::encode('UTF-8', $content);
		$self->res->body($body);
		$self->res->content_length(length($body));
	}

	$self->_log_response;

	return $self->res->finalize;
}

sub _log_request {
	my $self = shift;

	print STDOUT "\n", '='x80, "\n",
			 '| New request: ', $self->method, ' ', $self->path, ' from ', $self->address, "\n",
			 '-'x80, "\n";
}

sub _log_response {
	my $self = shift;

	print STDOUT '-'x80, "\n",
			 '| Response code: ', $self->res->status, ' ', $Leyland::CODES->{$self->res->status}, "\n",
			 '| Response type: ', $self->res->content_type, "\n",
			 '='x80, "\n";
}

sub _invoke_route {
	my $self = shift;

	my $i = $self->current_route;

	$self->_set_controller($self->routes->[$i]->{class});
	
	# but first invoke all 'auto' subs up to the matching route's controller
	foreach ($self->_route_parents($self->routes->[$i])) {
		$_->auto($self, @{$self->routes->[$i]->{captures}});
	}

	# then invoke the pre_route subroutine
	$self->controller->pre_route($self, @{$self->routes->[$i]->{captures}});

	# invoke the route itself
	$self->_set_want($self->routes->[$i]->{media});
	my $ret = $self->_serialize(
		$self->routes->[$i]->{code}->($self->controller, $self, @{$self->routes->[$i]->{captures}}),
		$self->routes->[$i]->{media}
	);

	# invoke the post_route subroutine
	$self->controller->post_route($self, \$ret);

	return $ret;
}

sub _serialize {
	my ($self, $obj, $want) = @_;

	my $ct = $self->res->content_type;
	unless ($ct) {
		$ct = $want.'; charset=UTF-8' if $want && $want =~ m/text|json|xml|html|atom/;
		$ct ||= 'text/plain; charset=UTF-8';
		$self->log->debug($ct .' will be returned');
		$self->res->content_type($ct);
	}

	if (ref $obj && ref $obj eq 'ARRAY' && (scalar @$obj == 2 || scalar @$obj == 3) && ref $obj->[0] eq 'HASH') {
		# render specified template
		if ((exists $obj->[0]->{$want} && $obj->[0]->{$want} eq '') || !exists $obj->[0]->{$want}) {
			# empty string for template name means deserialize
			# same goes if the route returns the wanted type
			# but has no template rule for it
			return $self->_structure($obj->[1], $want);
		} else {
			my $use_layout = scalar @$obj == 3 && defined $obj->[2] ? $obj->[2] : 1;
			return $self->template($obj->[0]->{$want}, $obj->[1], $use_layout);
		}
	} elsif (ref $obj && (ref $obj eq 'ARRAY' || ref $obj eq 'HASH')) {
		# serialize according to wanted type
		return $self->_structure($obj, $want);
	} elsif (ref $obj) {
		# $obj is some kind of reference, use Data::Dumper;
		Dumper($obj);
	} else {
		# $obj is a scalar, return as is
		return $obj;
	}
}

sub _route_parents {
	my ($self, $route) = @_;

	my @parents;

	my $class = $route->{class};
	while ($class =~ m/Controller::(.+)$/) {
		# attempt to find a controller for this class
		foreach ($self->app->controllers) {
			if ($_ eq $class) {
				push(@parents, $_);
				last;
			}
		}
		# now strip the class once
		$class =~ s/::[^:]+$//;
	}
	$class .= '::Root';
	push(@parents, $class);

	return @parents;
}

sub _structure {
	my ($self, $obj, $want) = @_;
	
	if ($want eq 'application/json') {
		return $self->json->encode($obj);
	} elsif ($want eq 'application/atom+xml' || $want eq 'application/xml') {
		return $self->xml->write($obj);
	} else {
		# return json anyway (temporary)
		return $self->json->encode($obj);
	}
}

sub _build_log {
	my $self = shift;

	my %opts;
	$opts{logger} = $self->env->{'psgix.logger'}
		if $self->env->{'psgix.logger'};

	Leyland::Logger->new(%opts);
}

=head2 FOREIGNBUILDARGS( \%args )

=cut

sub FOREIGNBUILDARGS {
	my ($class, %args) = @_;

	return ($args{env});
}

=head2 BUILD()

=cut

sub BUILD { shift->_log_request }

=head1 PLACK MODIFICATIONS

The following modifications are performed on methods provided by L<Plack::Request>,
from which this class inherits.

=head2 content()

Returns the request content after UTF-8 decoding it (Plack::Request doesn't
decode the content, this class does since Leyland is purely UTF-8).

=cut

around content => sub {
	my ($orig, $self) = @_;

	return $self->env->{'leyland.request.content'} ||= Encode::decode('UTF-8', $self->$orig);
};

=head2 session()

Returns the C<psgix.session> hash-ref, or, if it doesn't exist, an empty
hash-ref. This is different from Plack::Request, which won't return anything
if there is no session hash-ref. If C<psgix.session> really doesn't exist,
however, then the returned hash-ref won't be very useful and data entered
to it will only be alive for the lifetime of the request.

=cut

around session => sub {
	my ($orig, $self) = @_;

	return $self->$orig || {};
};

=head2 query_parameters()

Returns a L<Hash::MuliValue> object of query string (GET) parameters,
after UTF-8 decoding them (Plack::Request doesn't
decode the query, this class does since Leyland is purely UTF-8).

=cut

around query_parameters => sub {
	my ($orig, $self) = @_;

	if ($self->env->{'leyland.request.query'}) {
		return $self->env->{'leyland.request.query'};
	} else {
		my $params = $self->$orig->as_hashref_mixed;
		foreach (keys %$params) {
			if (ref $params->{$_}) { # implied: ref $params->{$_} eq 'ARRAY'
				my $arr = [];
				foreach my $val (@{$params->{$_}}) {
					push(@$arr, Encode::decode('UTF-8', $val));
				}
				$params->{$_} = $arr;
			} else {
				$params->{$_} = Encode::decode('UTF-8', $params->{$_});
			}
		}
		return $self->env->{'leyland.request.query'} = Hash::MultiValue->from_mixed($params);
	}
};

=head2 body_parameters()

Returns a L<Hash::MultiValue> object of posted parameters in the request
body (POST/PUT), after UTF-8 decoding them (Plack::Request doesn't
decode the body, this class does since Leyland is purely UTF-8).

=cut

around body_parameters => sub {
	my ($orig, $self) = @_;

	$self->_parse_request_body
		unless $self->env->{'leyland.request.body'};

	return $self->env->{'leyland.request.body'};
};

after _parse_request_body => sub {
	my $self = shift;

	# decode the body parameters
	if ($self->env->{'plack.request.body'} && !$self->env->{'leyland.request.body'}) {
		my $body = $self->env->{'plack.request.body'}->as_hashref_mixed;
		foreach (keys %$body) {
			if (ref $body->{$_}) { # implied: ref $body->{$_} eq 'ARRAY'
				my $arr = [];
				foreach my $val (@{$body->{$_}}) {
					push(@$arr, Encode::decode('UTF-8', $val));
				}
				$body->{$_} = $arr;
			} else {
				$body->{$_} = Encode::decode('UTF-8', $body->{$_});
			}
		}
		$self->env->{'leyland.request.body'} = Hash::MultiValue->from_mixed($body);
	}
};

around _uri_base => sub {
	my ($orig, $self) = @_;

	my $base = $self->$orig;
	$base .= '/' unless $base =~ m!/$!;
	return $base;
};

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Context

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
