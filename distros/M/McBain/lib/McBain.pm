package McBain;

# ABSTRACT: Framework for building portable, auto-validating and self-documenting APIs

use warnings;
use strict;

use Brannigan;
use Carp;
use File::Spec;
use Scalar::Util qw/blessed/;
use Try::Tiny;

our $VERSION = "2.001000";
$VERSION = eval $VERSION;

=head1 NAME
 
McBain - Framework for building portable, auto-validating and self-documenting APIs

=head1 SYNOPSIS

	package MyAPI;

	use McBain; # imports strict and warnings for you

	get '/multiply' => (
		description => 'Multiplies two integers',
		params => {
			one => { required => 1, integer => 1 },
			two => { required => 1, integer => 1 }
		},
		cb => sub {
			my ($api, $params) = @_;

			return $params->{one} * $params->{two};
		}
	);

	post '/factorial' => (
		description => 'Calculates the factorial of an integer',
		params => {
			num => { required => 1, integer => 1, min_value => 0 }
		},
		cb => sub {
			my ($api, $params) = @_;

			# note how this route both uses another
			# route and calls itself recursively

			if ($params->{num} <= 1) {
				return 1;
			} else {
				return $api->forward('GET:/multiply', {
					one => $params->{num},
					two => $api->forward('POST:/factorial', { num => $params->{num} - 1 })
				});
			}
		}
	);

	1;

=head1 DESCRIPTION

C<McBain> is a framework for building powerful APIs and applications. Writing an API with C<McBain> provides the following benefits:

=over

=item * B<Lightweight-ness>

C<McBain> is extremely lightweight, with minimal dependencies on non-core modules; only two packages; and a succinct, minimal syntax that is easy to remember. Your APIs and applications will require less resources and perform better. Maybe.

=item * B<Portability>

C<McBain> APIs can be run/used in a variety of ways with absolutely no changes of code. For example, they can be used B<directly from Perl code> (see L<McBain::Directly>), as fully fledged B<RESTful PSGI web services> (see L<McBain::WithPSGI>), as B<Gearman workers> (see L<McBain::WithGearmanXS>), or as B<ZeroMQ workers> (see L<McBain::WithZeroMQ>). Seriously, no change of code required. More L<McBain runners|"MCBAIN RUNNERS"> are yet to come (plus search CPAN to see if more are available), and you can
easily create your own, god knows I don't have the time or motivation or talent. Why should I do it
for you anyway?

=item * B<Auto-Validation>

No more tedious input tests. C<McBain> will handle input validation for you. All you need to do is define the parameters you expect to get with the simple and easy to remember syntax provided by L<Brannigan>. When your API is used, C<McBain> will automatically validate input. If validation fails, C<McBain> will return appropriate errors and tell the users of your API that they suck.

=item * B<Self-Documentation>

C<McBain> also eases the burden of having to document your APIs, so that other people can actually use it (and you, two weeks later when you're drunk and can't remember why you wrote the thing in the first place). Using simple descriptions you give to your API's methods, and the parameter definitions, C<McBain> can automatically create a manual document describing your API (see the L<mcbain2pod> command line utility).

=item * B<Modularity and Flexibility>

APIs written with C<McBain> are modular and flexible. You can make them object oriented if you want, or not, C<McBain> won't care, it's unobtrusive like that. APIs are hierarchical, and every module in the API can be used as a complete API all by itself, detached from its siblings, so you can actually load only the parts of the API you need. Why is this useful? I don't know, maybe it isn't, what do I care? It happened by accident anyway.

=item * B<No More World Hunger>

It'll do that too, just give it a chance.

=back

=head1 FUNCTIONS

The following functions are exported:

=head2 provide( $method, $route, %opts )

Define a method and a route. C<$method> is one of C<GET>, C<POST>, C<PUT>
or C<DELETE>. C<$route> is a string that starts with a forward slash,
like a path in a URI. C<%opts> can hold the following keys (only C<cb>
is required):

=over

=item * description

A short description of the method and what it does.

=item * params

A hash-ref of parameters in the syntax of L<Brannigan> (see L<Brannigan::Validations>
for a complete references).

=item * cb

An anonymous subroutine (or a subroutine reference) to run when the route is
called. The method will receive the root topic class (or object, if the
topics are written in object oriented style), and a hash-ref of parameters.

=back

=head2 get( $route, %opts )

Shortcut for C<provide( 'GET', $route, %opts )>

=head2 post( $route, %opts )

Shortcut for C<provide( 'POST', $route, %opts )>

=head2 put( $route, %opts )

Shortcut for C<provide( 'PUT', $route, %opts )>

=head2 del( $route, %opts )

Shortcut for C<provide( 'DELETE', $route, %opts )>

=head2 pre_route( $cb->( $self, $meth_and_route, \%params ) )

=head2 post_route( $cb->( $self, $meth_and_route, \$ret ) )

Define a post_route method to run before/after every request to a route in the
defining topic. See L</"PRE-ROUTES AND POST-ROUTES"> for details.

=head1 METHODS

The following methods will be available on importing classes/objects:

=head2 call( @args )

Calls the API, requesting the execution of a certain route. This is the
main way your API is used. The arguments it expects to receive and its
behavior are dependent on the L<McBain runner|"MCBAIN RUNNERS"> used. Refer to the docs
of the runner you wish to use for more information.

=head2 forward( $namespace, [ \%params ] )

For usage from within API methods; this simply calls a method of the
the API with the provided parameters (if any) and returns the result.
With C<forward()>, an API method can call other API methods or even
itself (for recursive operations).

C<$namespace> is the method and route to execute, in the format C<< <METHOD>:<ROUTE> >>,
where C<METHOD> is one of C<GET>, C<POST>, C<PUT>, C<DELETE>, and C<ROUTE>
starts with a forward slash.

=head2 is_root( )

Returns a true value if the module is the root topic of the API.
Mostly used internally and in L<McBain runner|"MCBAIN RUNNERS"> modules.

=cut

our %INFO;

sub import {
	my $target = caller;
	return if $target eq 'main';
	my $me = shift;
	strict->import;
	warnings->import(FATAL => 'all');
	return if $INFO{$target};

	# find the root of this API (if it's not this class)
	my $root = _find_root($target);

	# create the routes hash for $root
	$INFO{$root} ||= {};

	# were there any options passed?
	if (scalar @_) {
		my %opts = map { s/^-//; $_ => 1 } @_;
		# apply the options to the root package
		$INFO{$root}->{_opts} = \%opts;
	}

	# figure out the topic name from this class
	my $topic = '/';
	unless ($target eq $root) {
		my $rel_name = ($target =~ m/^${root}::(.+)$/)[0];
		$topic = '/'.lc($rel_name);
		$topic =~ s!::!/!g;
	}

	no strict 'refs';

	# export the is_root() subroutine to the target topic,
	# so that it knows whether it is the root of the API
	# or not
	*{"${target}::is_root"} = sub {
		exists $INFO{$target};
	};

	if ($target eq $root) {
		*{"${target}::import"} = sub {
			my $t = caller;
			shift;
			my $runner = scalar @_ ? 'McBain::'.ucfirst(substr($_[0], 1)) : 'McBain::Directly';

			eval "require $runner";
			croak "Can't load runner module $runner: $@"
				if $@;

			$INFO{$root}->{_runner} = $runner;

			# let the runner module do needed initializations,
			# as the init method usually needs the is_root subroutine,
			# this statement must come after exporting is_root()
			$runner->init($target);
		};
	}

	# export the provide subroutine to the target topic,
	# so that it can define routes and methods.
	*{"${target}::provide"} = sub {
		my ($method, $name) = (shift, shift);
		my %opts = @_;

		# make sure the route starts and ends
		# with a slash, and prefix it with the topic
		$name = '/'.$name
			unless $name =~ m{^/};
		$name .= '/'
			unless $name =~ m{/$};
		$name = $topic.$name
			unless $topic eq '/';

		$INFO{$root}->{$name} ||= {};
		$INFO{$root}->{$name}->{$method} = \%opts;
	};

	# export shortcuts to the provide() subroutine
	# per http methods
	foreach my $meth (
		[qw/get GET/],
		[qw/put PUT/],
		[qw/post POST/],
		[qw/del DELETE/]
	) {
		*{$target.'::'.$meth->[0]} = sub {
			&{"${target}::provide"}($meth->[1], @_);
		};
	}

	my $forward_target = $target;

	if ($target eq $root && $INFO{$root}->{_opts} && $INFO{$root}->{_opts}->{contextual}) {
		# we're running in contextual mode, which means the API
		# should have a Context class called $root::Context, and this
		# is the class to which we should export the forward() method
		# (the call() method is still exported to the API class).
		# when call() is, umm, called, we need to create a new instance
		# of the context class and use forward() on it to handle the
		# request.
		# we expect this class to be called $root::Context, but if it
		# does not exist, we will try going up the hierarchy until we
		# find one.
		my $check = $root.'::Context';
		my $ft;
		while ($check) {
			eval "require $check";
			if ($@) {
				# go up one level and try again
				$check =~ s/[^:]+::Context$/Context/;
			} else {
				$ft = $check;
				last;
			}
		}

		croak "No context class found"
			unless $ft;
		croak "Context class doesn't have create_from_env() method"
			unless $ft->can('create_from_env');

		$forward_target = $ft;
	}

	# export the pre_route and post_route "constructors"
	foreach my $mod (qw/pre_route post_route/) {
		*{$target.'::'.$mod} = sub (&) {
			$INFO{$root}->{"_$mod"} ||= {};
			$INFO{$root}->{"_$mod"}->{$topic} = shift;
		};
	}

	# export the call method, the one that actually
	# executes API methods
	*{"${target}::call"} = sub {
		my ($self, @args) = @_;

		my $runner = $INFO{$root}->{_runner};

		return try {
			# ask the runner module to generate a standard
			# env hash-ref
			my $env = $runner->generate_env(@args);

			my $ctx = $INFO{$root}->{_opts} && $INFO{$root}->{_opts}->{contextual} ?
				$forward_target->create_from_env($runner, $env, @args) :
					$self;

			# handle the request
			my $res = $ctx->forward($env->{METHOD}.':'.$env->{ROUTE}, $env->{PAYLOAD});

			# ask the runner module to generate an appropriate
			# response with the result
			return $runner->generate_res($env, $res);
		} catch {
			# an exception was caught, ask the runner module
			# to format it as it needs
			my $exp;
			if (ref $_ && ref $_ eq 'HASH' && exists $_->{code} && exists $_->{error}) {
				$exp = $_;
			} else {
				$exp = { code => 500, error => $_ };
			}

			return $runner->handle_exception($exp, @args);
		};
	};

	# export the forward method, which is both used internally
	# in call(), and can be used by API authors within API
	# methods
	*{"${forward_target}::forward"} = sub {
		my ($ctx, $meth_and_route, $payload) = @_;

		my ($meth, $route) = split(/:/, $meth_and_route);

		# make sure route ends with a slash
		$route .= '/'
			unless $route =~ m{/$};

		my @captures;

		# is there a direct route that equals the request?
		my $r = $INFO{$root}->{$route};

		# if not, is there a regex route that does?
		unless ($r) {
			foreach (keys %{$INFO{$root}}) {
				next unless @captures = ($route =~ m/^$_$/);
				$r = $INFO{$root}->{$_};
				last;
			}
		}

		confess { code => 404, error => "Route $route not found" }
			unless $r;

		# is this an OPTIONS request?
		if ($meth eq 'OPTIONS') {
			my %options;
			foreach my $m (keys %$r) {
				%{$options{$m}} = map { $_ => $r->{$m}->{$_} } grep($_ ne 'cb', keys(%{$r->{$m}}));
			}
			return \%options;
		}

		# does this route have the HTTP method?
		confess { code => 405, error => "Method $meth not available for route $route" }
			unless exists $r->{$meth};

		# process parameters
		my $params_ret = Brannigan::process({ params => $r->{$meth}->{params} }, $payload);

		confess { code => 400, error => "Parameters failed validation", rejects => $params_ret->{_rejects} }
			if $params_ret->{_rejects};

		# break the path into "directories", run pre_route methods
		# for each directory (if any)
		my @parts = _break_path($route);

		# are there pre_routes?
		foreach my $part (@parts) {
			$INFO{$root}->{_pre_route}->{$part}->($ctx, $meth_and_route, $params_ret)
				if $INFO{$root}->{_pre_route} && $INFO{$root}->{_pre_route}->{$part};
		}

		my $res = $r->{$meth}->{cb}->($ctx, $params_ret, @captures);

		# are there post_routes?
		foreach my $part (@parts) {
			$INFO{$root}->{_post_route}->{$part}->($ctx, $meth_and_route, \$res)
				if $INFO{$root}->{_post_route} && $INFO{$root}->{_post_route}->{$part};
		}

		return $res;
	};

	# we're done with exporting, now lets try to load all
	# child topics (if any), and collect their method definitions
	_load_topics($target, $INFO{$root}->{_opts});
}

# _find_root( $current_class )
# -- finds the root topic of the API, which might
#    very well be the module we're currently importing into

sub _find_root {
	my $class = shift;

	my $copy = $class;
	while ($copy =~ m/::[^:]+$/) {
		return $`
			if $INFO{$`};
		$copy = $`;
	}

	return $class;
}

# _load_topics( $base, [ \%opts ] )
# -- finds and loads the child topics of the class we're
#    currently importing into, automatically requiring
#    them and thus importing McBain into them as well

sub _load_topics {
	my ($base, $opts) = @_;

	# this code is based on code from Module::Find

	my $pkg_dir = File::Spec->catdir(split(/::/, $base));

	my @inc_dirs = map { File::Spec->catdir($_, $pkg_dir) } @INC;

	foreach my $inc_dir (@inc_dirs) {
		next unless -d $inc_dir;

		opendir DIR, $inc_dir;
		my @pms = grep { !-d && m/\.pm$/ } readdir DIR;
		closedir DIR;

		foreach my $file (@pms) {
			my $pkg = $file;
			$pkg =~ s/\.pm$//;
			$pkg = join('::', File::Spec->splitdir($pkg));

			my $req = File::Spec->catdir($inc_dir, $file);

			next if $req =~ m!/Context.pm$!
				&& $opts && $opts->{contextual};

			require $req;
		}
	}
}

# _break_path( $path )
# -- breaks a route/path into a list of "directories",
#    starting from the root and up to the full path

sub _break_path {
	my $path = shift;

	my $copy = $path;

	my @path;

	unless ($copy eq '/') {
		chop($copy);

		while (length($copy)) {
			unshift(@path, $copy);
			$copy =~ s!/[^/]+$!!;
		}
	}

	unshift(@path, '/');

	return @path;
}

=head1 MANUAL

=head2 ANATOMY OF AN API

Writing an API with C<McBain> is easy. The syntax is short and easy to remember,
and the feature list is just what it needs to be - short and sweet.

The main idea of a C<McBain> API is this: a client requests the execution of a
method provided by the API, sending a hash of parameters. The API then executes the
method with the client's parameters, and produces a response. Every L<runner module|"MCBAIN RUNNERS">
will enforce a different response format (and even request format). When the API is
L<used directly|McBain::Directly>, for example, whatever the API produces is returned as
is. The L<PSGI|McBain::WithPSGI> and L<Gearman::XS|McBain::WithGearmanXS> runners,
however, are both JSON-in JSON-out interfaces.

A C<McBain> API is built of one or more B<topics>, in a hierarchical structure.
A topic is a class that provides methods that are categorically similar. For
example, an API might have a topic called "math" that provides math-related
methods such as add, multiply, divide, etc.

Since topics are hierarchical, every API will have a root topic, which may have
zero or more child topics. The root topic is where your API begins, and it's your
decision how to utilize it. If your API is short and simple, with methods that
cannot be categorized into different topics, then the entire API can live within the
root topic itself, with no child topics at all. If, however, you're building a
larger API, then the root topic might be empty, or it can provide general-purpose
methods that do not particularly fit in a specific topic, for example maybe a status
method that returns the status of the service, or an authentication method.

The name of a topic is calculated from the name of the package itself. The root
topic is always called C</> (forward slash), and its child topics are named
like their package names, in lowercase, relative to the root topic, with C</>
as a separator instead of Perl's C<::>, and starting with a slash.
For example, lets look at the following API packages:

	+------------------------+-------------------+------------------+
	| Package Name           | Topic Name        | Description      |
	+========================+===================+==================+
	| MyAPI                  | "/"               | the root topic   |
	| MyAPI::Math            | "/math"           | a child topic    |
	| MyAPI::Math::Constants | "/math/constants" | a child-of-child |
	| MyAPI::Strings         | "/strings"        | a child topic    |
	+------------------------+--------------------------------------+

You will notice that the naming of the topics is similar to paths in HTTP URIs.
This is by design, since I wrote C<McBain> mostly for writing web applications
(with the L<PSGI|McBain::WithPSGI> runner), and the RESTful architecture fits
well with APIs whether they are HTTP-based or not.

=head2 CREATING TOPICS

To create a topic package, all you need to do is:

	use McBain;

This will import C<McBain> functions into the package, register the package
as a topic (possibly the root topic), and attempt to load all child topics, if there
are any. For convenience, C<McBain> will also import L<strict> and L<warnings> for
you.

Notice that using C<McBain> doesn't make your package an OO class. If you want your
API to be object oriented, you are free to form your classes however you want, for
example with L<Moo> or L<Moose>:

	package MyAPI;

	use McBain;
	use Moo;

	has 'some_attr' => ( is => 'ro' );

	1;

=head2 CREATING ROUTES AND METHODS

The resemblance with HTTP continues as we delve further into methods themselves. An API
topic defines B<routes>, and one or more B<methods> that can be executed on every
route. Just like HTTP, these methods are C<GET>, C<POST>, C<PUT> and C<DELETE>.

Route names are like topic names. They begin with a slash, and every topic I<can>
have a root route which is just called C</>. Every method defined on a route
will have a complete name (or path, if you will), in the format
C<< <METHOD_NAME>:<TOPIC_NAME><ROUTE_NAME> >>. For example, let's say we have a
topic called C</math>, and this topic has a route called C</divide>, with one
C<GET> method defined on this route. The complete name (or path) of this method
will be C<GET:/math/divide>.

By using this structure and semantics, it is easy to create CRUD interfaces. Lets
say your API has a topic called C</articles>, that deals with articles in your
blog. Every article has an integer ID. The C</articles> topic can have the following
routes and methods:

	+------------------------+--------------------------------------+
	| Namespace              | Description                          |
	+========================+======================================+
	| POST:/articles/        | Create a new article (root route /)  |
	| GET:/articles/(\d+)    | Read an article                      |
	| PUT:/articles/(\d+)    | Update an article                    |
	| DELETE:/articles/(\d+) | Delete an article                    |
	+------------------------+--------------------------------------+

Methods are defined using the L<get()|"get( $route, %opts )">, L<post()|"post( $route, %opts )">,
L<put()|"put( $route, %opts )"> and L<del()|"del( $route, %opts )"> subroutines.
The syntax is similar to L<Moose>'s antlers:

	get '/multiply' => (
		description => 'Multiplies two integers',
		params => {
			a => { required => 1, integer => 1 },
			b => { required => 1, integer => 1 }
		},
		cb => sub {
			my ($api, $params) = @_;

			return $params->{a} * $params->{b};
		}
	);

Of the three keys above (C<description>, C<params> and C<cb>), only C<cb>
is required. It takes the actual subroutine to execute when the method is
called. The subroutine will get two arguments: first, the root topic (either
its package name, or its object, if you're creating an object oriented API),
and a hash-ref of parameters provided to the method (if any).

You can provide C<McBain> with a short C<description> of the method, so that
C<McBain> can use it when documenting the API with L<mcbain2pod>.

You can also tell C<McBain> which parameters your method takes. The C<params>
key will take a hash-ref of parameters, in the format defined by L<Brannigan>
(see L<Brannigan::Validations> for a complete references). These will be both
enforced and documented.

As you may have noticed in the C</articles> example, routes can be defined using
regular expressions. This is useful for creating proper RESTful URLs:

	# in topic /articles

	get '/(\d+)' => (
		description => 'Returns an article by its integer ID',
		cb => sub {
			my ($api, $params, $id) = @_;

			return $api->db->get_article($id);
		}
	);

If the regular expression contains L<captures|perlpod/"Capture groups">, and
a call to the API matches the regular expressions, the values captured will
be passed to the method, after the parameters hash-ref (even if the method
does not define parameters, in which case the parameters hash-ref will be
empty - this may change in the future).

It is worth understanding how C<McBain> builds the regular expression. In the
above example, the topic is C</articles>, and the route is C</(\d+)>. Internally,
the generated regular expression will be C<^/articles/(\d+)$>. Notice how the topic
and route are concatenated, and how the C<^> and C<$> metacharacters are added to
the beginning and end of the regex, respectively. This means it is impossible to
create partial regexes, which only pose problems in my experience.

=head2 OPTIONS REQUESTS

Every route defined by the API also automatically gets an C<OPTIONS> method,
again just like HTTP. This method returns a list of HTTP-style methods allowed
on the route. The return format depends on the runner module used. The direct
runner will return a hash-ref with keys being the HTTP methods, and values being
hash-refs holding the C<description> and C<params> definitions (if any).

For example, let's look at the following route:

	get '/something' => (
		description => 'Gets something',
		cb => sub { }
	);

	put '/something' => (
		description => 'Updates something',
		params => { new_content => { required => 1 } },
		cb => sub { }
	);

Calling C<OPTIONS:/something> will return:

	{
		GET => {
			description => "Gets something"
		},
		PUT => {
			description => "Updates something",
			params => {
				new_content => { required => 1 }
			}
		}
	}

=head2 CALLING METHODS FROM WITHIN METHODS

Methods are allowed to call other methods (whether in the same route or not),
and even call themselves recursively. This can be accomplished easily with
the L<forward()|"forward( $namespace, [ \%params ] )"> method. For example:

	get '/factorial => (
		description => 'Calculates the factorial of a number',
		params => {
			num => { required => 1, integer => 1 }
		},
		cb => sub {
			my ($api, $params) = @_;

			if ($params->{num} <= 1) {
				return 1;
			} else {
				return $api->forward('GET:/multiply', {
					one => $params->{num},
					two => $api->forward('GET:/factorial', { num => $params->{num} - 1 })
				});
			}
		}
	);

In the above example, notice how the C<GET:/factorial> method calls both
C<GET:/multiply> and itself.

=head2 EXCEPTIONS

C<McBain> APIs handle errors in a graceful way, returning proper error
responses to callers. As always, the way errors are returned depends on
the L<runner module|"MCBAIN RUNNERS"> used. When used directly from Perl
code, McBain will L<confess|Carp> (i.e. die) with a hash-ref consisting
of two keys:

=over

=item * C<code> - An HTTP status code indicating the type of the error (for
example 404 if the route doesn't exist, 405 if the route exists but the method
is not allowed, 400 if parameters failed validation, etc.).

=item * C<error> - The text/description of the error.

=back

Depending on the type of the error, more keys might be added to the exception.
For example, the parameters failed validation error will also include a C<rejects>
key holding L<Brannigan>'s standard rejects hash, describing which parameters failed
validation.

When writing APIs, you are encouraged to return exceptions in this format to
ensure proper handling by C<McBain>. If C<McBain> encounters an exception
that does not conform to this format, it will generate an exception with
C<code> 500 (indicating "Internal Server Error"), and the C<error> key will
hold the exception as is.

=head2 PRE-ROUTES AND POST-ROUTES

I<New in v1.3.0>

Every topic in your API can define pre and post routes. The pre route is called
right before a route is executed, while the post route is called immediately after.

You should note that the pre and post routes are called on every route execution
(when applicable), even when forwarding from one route to another.

Pre and post routes are hierarchical. When a route is executed, C<McBain> will analyze
the entire chain of topics leading up to that route, and execute all pre and post routes
on the way (if any, of course). So, for example, if the route C</math/factorial> is to be
executed, C<McBain> will look for pre and post routes and the root topic (C</>), the C</math>
topic, and the C</math/factorial> topic (if it exists). Whichever ones it finds will be
executed, in order.

The C<pre_route> subroutine gets as parameters the API package (or object, if writing
object-oriented APIs, or the context object, if writing in L<contextual mode|/"CONTEXTUAL MODE">),
the full route name (the method and the path, e.g. C<POST:/math/factorial>), and the
parameters hash-ref, after validation has occurred.

	package MyApi::Math;

	post '/factorial' => (
		...
	);

	pre_route {
		my ($self, $meth_and_route, $params) = @_;

		# do something here
	}

The C<post_route> subroutine gets the same parameters, except the parameters hash-ref, in which
place a reference to the result returned by the actual route is passed. So, for example, if
the C<POST:/math/factorial> method returned C<13>, then C<post_route> will get a reference
to a scalar variable whose value is 13.

	post_route {
		my ($self, $meth_and_route, $ret) = @_;

		if ($$ret == 13) {
			# change the result to 14, because
			# 13 is an unlucky number
			$$ret = 14;
		}
	}

=head2 CONTEXTUAL MODE

I<< B<Note:> contextual mode is an experimental feature introduced in v1.2.0 and
may change in the future. >>

Contextual mode is an optional way of writing C<McBain> APIs, reminiscent of
web application frameworks such as L<Catalyst> and L<Leyland>. The main idea
is that a context object is created for every request, and follows it during
its entire life.

In regular mode, the API methods receive the class of the root package (or its
object, if writing object oriented APIs), and a hash-ref of parameters. This is
okay for simple APIs, but many APIs need more, like information about the
user who sent the request.

In contextual mode, the context object can contain user information, methods for
checking authorization (think role-based and ability-based authorization systems),
database connections, and anything else your API might need in order to fulfill the
request.

Writing APIs in contextual mode is basically the same as in regular mode, only you
need to build a context class. Since C<McBain> doesn't intrude on your OO system of
choice, constructing the class is your responsibility, and you can use whatever you
want (like L<Moo>, L<Moose>, L<Class::Accessor>). C<McBain> only requires your
context class to implement a subroutine named C<create_from_env( $runner, \%env,  @args_to_call )>.
This method will receive the name of the runner module used, the standard environment
hash-ref of C<McBain> (which includes the keys C<METHOD>, C<ROUTE> and C<PAYLOAD>),
plus all of the arguments that were sent to the L<call( @args )> method. These are
useful for certain runner modules, such as the L<PSGI runner|McBain::WithPSGI>,
which gets the L<PSGI> hash-ref, from which you can extract session data, user
information, HTTP headers, etc. Note that this means that if you plan to use your API
with different runner modules, your C<create_from_env()> method should be able to parse
differently formatted arguments.

Note that currently, the context class has to be named C<__ROOT__::Context>, where
C<__ROOT__> is the name of your API's root package. So, for example, if your API's
root package is named C<MyAPI>, then C<McBain> will expect C<MyAPI::Context>.

I<< B<Note:> since v2.1.0, if C<McBain> doesn't find a package named C<__ROOT__::Context>,
it will go up the package hierarchy until it finds one. For example, if the root package
of your API is C<Some::API>, then McBain will try C<Some::API::Context>, then C<Some::Context>,
then finally C<Context>. This was added to allow the sharing of the same context class
in a project comprised of several APIs. >>

When writing in contextual mode, your API methods will receive the context object
instead of the root package/object, and the parameters hash-ref.

Let's look at a simple example for writing APIs in contextual mode. Say our API
is called C<MyAPI>. Let's begin with the context class, C<MyAPI::Context>:

	package MyAPI::Context;

	use Moo;
	use Plack::Request;

	has 'user_agent' => (
		is => 'ro',
		default => sub { 'none' }
	);

	sub create_from_env {
		my ($class, $runner, $mcbain_env, @call_args) = @_;

		my $user_agent;

		if ($runner eq 'McBain::WithPSGI') {
			# extract user agent from the PSGI env,
			# which will be the first item in @call_args
			$user_agent = Plack::Request->new($call_args[0])->user_agent;
		}

		return $class->new(user_agent => $user_agent);
	}

	1;

Now let's look at the API itself:

	package MyAPI;

	use McBain -contextual;

	get '/' => (
		cb => sub {
			my ($c, $params) = @_;

			if ($c->user_agent =~ m/Android/) {
				# do it this way
			} else {
				# do it that way
			}

			# you can still forward to other methods
			$c->forward('GET:/something_else', \%other_params);
		}
	);

	1;

So as you can see, the only real change for API packages is the need
to write C<use McBain -contextual> instead of C<use McBain>. The only
"challenge" is writing the context class.

=head1 MCBAIN RUNNERS

I<< B<NOTE:> since v2.0.0 the way runner modules are used has changed. The
C<MCBAIN_WITH> environment variable is no longer used. Read on for more
information. >>

A runner module is in charge of loading C<McBain> APIs in a specific way.
The default runner, L<McBain::Directly>, is the simplest runner there is,
and is meant for using APIs directly from Perl code.

The runner module is in charge of whatever heavy lifting is required in order
to turn your API into a "service", or an "app", or whatever it is you think your
API needs to be.

The following runners are currently available:

=over

=item * L<McBain::Directly> - Directly use an API from Perl code.

=item * L<McBain::WithPSGI> - Turn an API into a Plack based, JSON-to-JSON
RESTful web application.

=item * L<McBain::WithGearmanXS> - Turn an API into a JSON-to-JSON
Gearman worker.

=item * L<McBain::WithWebSocket> - Turn an API into a WebSocket server.

=item * L<McBain::WithZeroMQ> - Turn an API into a JSON-to-JSON ZeroMQ REP worker.

=back

The latter four completely change the way your API is used, and yet you can
see their code is very short.

To tell C<McBain> which runner module to use, you must provide the name of the
runner when loading your API:

	use MyAPI -withPSGI; # can also write -WithPSGI

In the above example, C<McBain::WithPSGI> will be the runner module used.

The default runner module is C<McBain::Directly>. If you C<use> an API with no
parameter, it will be the loaded runner module:

	use MyAPI;

	use MyAPI -directly; # the same as above

You can easily create your own runner modules, so that your APIs can be used
in different ways. A runner module needs to implement the following interface:

=head2 init( $runner_class, $target_class )

This method is called when C<McBain> is first imported into an API topic.
C<$target_class> will hold the name of the class currently being imported to.

You can do whatever initializations you need to do here, possibly manipulating
the target class directly. You will probably only want to do this on the root
topic, which is why L</"is_root( )"> is available on C<$target_class>.

You can look at C<WithPSGI> and C<WithGearmanXS> to see how they're using the
C<init()> method. For example, in C<WithPSGI>, L<Plack::Component> is added
to the C<@ISA> array of the root topic, so that it turns into a Plack app. In
C<WithGearmanXS>, the C<init()> method is used to define a C<work()> method
on the root topic, so that your API can run as any standard Gearman worker.

=head2 generate_env( $runner_class, @call_args )

This method receives whatever arguments were passed to the L</"call( @args )">
method. It is in charge of returning a standard hash-ref that C<McBain> can use
in order to determine which route the caller wants to execute, and with what
parameters. Remember that the way C<call()> is invoked depends on the runner used.

The hash-ref returned I<must> have the following key-value pairs:

=over

=item * ROUTE - The route to execute (string).

=item * METHOD - The method to call on the route (string).

=item * PAYLOAD - A hash-ref of parameters to provide for the method. If no parameters
are provided, an empty hash-ref should be given.

=back

The returned hash-ref is called C<$env>, inspired by L<PSGI>.

=head2 generate_res( $runner_class, \%env, $result )

This method formats the result from a route before returning it to the caller.
It receives the C<$env> hash-ref (if needed), and the result from the route. In the
C<WithPSGI> runner, for example, this method encodes the result into JSON and 
returns a proper PSGI response array-ref.

=head2 handle_exception( $runner_class, $error, @args )

This method will be called whenever a route raises an exception, or otherwise your code
fails. The C<$error> variable will always be a standard L<exception hash-ref|"EXCEPTIONS">,
with C<code> and C<error> keys, and possibly more. Read the discussion above.

The method should format the error before returning it to the user, similar to what
C<generate_res()> above performs, but it allows you to handle exceptions gracefully.

Whatever arguments were provided to C<call()> will be provided to this method as-is,
so that you can inspect or use them if need be. C<WithGearmanXS>, for example,
will get the L<Gearman::XS::Job> object and call the C<send_fail()> method on it,
to properly indicate the job failed.

=head1 CONFIGURATION AND ENVIRONMENT
   
No configuration files or environment variables required.
 
=head1 DEPENDENCIES
 
C<McBain> depends on the following CPAN modules:
 
=over
 
=item * L<Brannigan>
 
=item * L<Carp>

=item * L<File::Spec>

=item * L<Scalar::Util>
 
=item * L<Try::Tiny>
 
=back
 
The command line utility, L<mcbain2pod>, depends on the following CPAN modules:
 
=over

=item * L<IO::Handle>

=item * L<Getopt::Compact>

=item * L<Module::Load>

=back

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-McBain@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=McBain>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc McBain

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=McBain>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/McBain>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/McBain>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/McBain/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2013-2014, Ido Perlmuter C<< ido@ido50.net >>.
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.
 
The full text of the license can be found in the
LICENSE file included with this module.
 
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
 
=cut

1;
__END__
