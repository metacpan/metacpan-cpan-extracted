package MVC::Neaf;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.17;

=head1 NAME

MVC::Neaf - Not Even A (Web Application) Framework

=head1 OVERVIEW

Neaf [ni:f] stands for Not Even A Framework.

The B<Model> is assumed to be just a regular Perl module,
no restrictions are imposed on it.

The B<View> is an object with one method, C<render>, receiving a hashref
and returning rendered content as string plus optional content-type header.

The B<Controller> is broken down into handlers associated with URI paths.
Each such handler receives a L<MVC::Neaf::Request> object
containing all it needs to know about the outside world,
and returns a simple C<\%hashref> which is forwarded to View.

Please see the C<example> directory in this distribution
that demonstrates the features of Neaf.

=head1 SYNOPSIS

The following application, outputting a greeting, is ready to run
as a CGI script, PSGI application, or Apache handler.

    use MVC::Neaf;

    MVC::Neaf->route( "/app" => sub {
        my $req = shift;

        my $name = $req->param( name => qr/[\w\s]+/, "Yet another perl hacker" );

        return {
            -template => \"Hello, [% name %]",
            -type     => "text/plain",
            name      => $name,
        };
    });
    MVC::Neaf->run;

=head1 CREATING AN APPLICATION

=head2 THE CONTROLLER

The handler sub receives an L<MVC::Neaf::Request> object
and outputs a C<\%hashref>.

It may also die, which will be interpreted as an error 500,
UNLESS error message starts with 3 digits and a whitespace,
in which case this is considered the return status.
E.g. C<die 404;> is a valid method to return "Not Found" right away.

Handlers are set using the C<route( path =E<gt> CODEREF );>
method discussed below.

=head2 THE REQUEST

B<The Request> object is similar to the OO interface of L<CGI>
or L<Plack::Request> with some minor differences:

    # What was requested:
    http(s)://server.name:1337/mathing/route/some/more/slashes?foo=1&bar=2

    # What is being returned:
    $req->http_version; # = HTTP/1.0 or HTTP/1.1
    $req->scheme      ; # = http or https
    $req->method      ; # = GET
    $req->hostname    ; # = server.name
    $req->port        ; # = 1337
    $req->path        ; # = /mathing/route/some/more/slashes
    $req->script_name ; # = /mathing/route
    $req->path_info   ; # = /some/more/slashes

    $req->param( foo => '\d+' ); # = 1
    $req->get_cookie( session => '.+' ); # = whatever it was set to before

One I<major> difference is that there's no (easy) way to fetch
query parameters or cookies without validation.
Just use qr/.*/ if you know better.

Also there are some methods that affect the reply,
mainly the headers, like C<set_cookie> or C<redirect>.
This is a step towards a know-it-all God object,
however, mapping those properties into a hashref turned out to be
too cumbersome.

=head2 THE RESPONSE

B<The response> may contain regular keys, typically alphanumeric,
as well as a predefined set of dash-prefixed keys to control
Neaf itself.

I<-Note -that -dash-prefixed -options -look -antique
even to the author of this writing.
However, it is a concise and B<visible> way to separate
auxiliary parameters from users's data,
without requiring a more complex return structure
(two hashes, array of arrays etc).>

The small but growing list of these -options is as follows:

=over

=item * -content - Return raw data and skip view processing.
E.g. display generated image.

=item * -continue - A callback that receives the Request object.
It will be executed AFTER the headers and pre-generated content
are served to the client, and may use C<$req-E<gt>write( $data );>
and C<$req-E<gt>close;> to output more data.

=item * -headers - Pass a hash or array of values for header generation.
This is an alternative to L<MVC::Neaf::Request>'s C<push_header> method.

=item * -jsonp - Used by JS view module as a callback name to produce a
L<jsonp|https://en.wikipedia.org/wiki/JSONP> response.
Callback MUST be a set of identifiers separated by dots.
Otherwise it's ignored for security reasons.

=item * -location - HTTP Location: header.

=item * -status - HTTP status (200, 404, 500 etc).
Default is 200 if the app managed to live through, and 500 if it died.

=item * -template - Set template name for TT (L<Template>-based view).

=item * -type - Content-type HTTP header.
View module may set this parameter if unset.
Default: C<"text/html">.

=item * -view - select B<View> module.
Views are initialized lazily and cached by the framework.
C<TT>, C<JS>, C<Full::Module::Name>, and C<$view_predefined_object>
are currently supported.
New short aliases may be created by
C<MVC::Neaf-E<gt>load_view( "name" =E<gt> $your_view );> (see below).

=back

Though more dash-prefixed parameters may be returned
and will be passed to the View module as of current,
they are not guaranteed to work in the future.
Please either avoid them, or send patches.

=head1 APPLICATION API

These methods are generally called during the setup phase of the application.
They have nothing to do with serving the request.

=cut

use Carp;
use Scalar::Util qw(blessed looks_like_number);
use Encode;
use URI::Escape;
use Module::Load;
use parent qw(Exporter);

our @EXPORT_OK = qw( neaf_err neaf get post head put );
our %EXPORT_TAGS = (
    sugar => [qw[ neaf get post head put ]],
);

use MVC::Neaf::Util qw(http_date canonize_path path_prefixes run_all run_all_nodie);
use MVC::Neaf::Request;

our $Inst = __PACKAGE__->new;

=head2 route( path => CODEREF, %options )

Set up an URI handler in the application.
Any incoming request to uri matching C</path>
(C</path/something/else> too, but NOT C</pathology>)
will now be directed to CODEREF.

Longer paths are GUARANTEED to be checked first.

Dies if the same method and path combo is given again.
Multiple methods may be given for the same path,
e.g. when handling REST.

Exactly one leading slash will be prepended no matter what you do.
(C<path>, C</path> and C</////path> are all the same).

%options may include:

=over

=item * method - list of allowed HTTP methods.
Default is [GET, POST].
Multiple handles can be defined for the same path, provided that
methods do not intersect.
HEAD method is automatically handled if GET is present, however,
one MAY define a separate HEAD handler explicitly.

=item * path_info_regex => qr/.../ - allow URI subpaths
to be handled by this handler.

A 404 error will be generated unless C<path_info_regex> is present
and PATH_INFO matches the regex (without the leading slash).

B<EXPERIMENTAL>. Name and semantics MAY change in the future.

=item * view - default View object for this Controller.
Must be an object with a C<render> method, or a CODEREF
receiving hashref and returning a list of two scalars
(content and content-type).

=item * cache_ttl - if set, set Expires: HTTP header accordingly.

B<EXPERIMENTAL>. Name and semantics MAY change in the future.

=item * default - a C<\%hash> with default values for handler's return value.

B<EXPERIMENTAL>. Name and semantics MAY change in the future.

=item * description - just for information, has no action on execution.
This will be displayed if application called with --list (see L<MVC::Neaf::CLI>).

=back

Also, any number of dash-prefixed keys MAY be present.
This is totally the same as putting them into C<default> hash.

=cut

my $year = 365 * 24 * 60 * 60;
my %known_route_args;
$known_route_args{$_}++ for qw(default method view cache_ttl path_info_regex description);

sub route {
    my $self = shift;

    # HACK!! pack path components together, i.e.
    # foo => bar => \&handle eq "/foo/bar" => \&handle
    my ( $path, $sub );
    while ($sub = shift) {
        last if ref $sub;
        $path .= "/$sub";
    };
    $self->_croak( "Odd number of elements in hash assignment" )
        if @_ % 2;
    my (%args) = @_;
    $self = $Inst unless ref $self;

    # check defaults to be a hash before accessing them
    $self->_croak( "default must be unblessed hash" )
        if $args{default} and ref $args{default} ne 'HASH';

    # minus-prefixed keys are typically defaults
    $_ =~ /^-/ and $args{default}{$_} = delete $args{$_}
        for keys %args;

    # kill extra args
    my @extra = grep { !$known_route_args{$_} } keys %args;
    $self->_croak( "Unexpected keys in route setup: @extra" )
        if @extra;

    $path = canonize_path( $path );

    _listify( \$args{method}, qw( GET POST ) );

    my @dupe = grep { exists $self->{route}{$path}{$_} } @{ $args{method} };
    $self->_croak( "Attempting to set duplicate handler for [@dupe] "
        .( length $path ? $path : "/" ) )
            if @dupe;

    # Do the work
    my %profile;
    $profile{code}     = $sub;
    $profile{caller}   = [caller(0)]; # file,line
    if ( !defined $args{path_info_regex} ) {
        # TODO replace def path_info_regex with '' in v.0.16 aka '404 if unspecified'
        $args{path_info_regex}      = '';
        $profile{no_path_info_regex} = 1;
    };
    $profile{path_info_regex}  = qr#^/*($args{path_info_regex})$#;

    # Just for information
    $profile{path}        = $path;
    $profile{description} = $args{description};

    if (my $view = $args{view}) {
        # preload view so we can fail early
        $view = $self->get_view( $view );

        $args{default}{-view} = ref $args{view} ? $view : $args{view};
    };

    # todo_default because some path-based defs will be mixed in later
    $profile{todo_default} = $args{default}
        if $args{default};

    if ( $args{cache_ttl} ) {
        $self->_croak("cache_ttl must be a number")
            unless looks_like_number($args{cache_ttl});
        # as required by RFC
        $args{cache_ttl} = -100000 if $args{cache_ttl} < 0;
        $args{cache_ttl} = $year if $args{cache_ttl} > $year;
        $profile{cache_ttl} = $args{cache_ttl};
    };

    # ready, shallow copy handler & burn cache
    delete $self->{route_re};
    $self->{route}{ $path }{$_} = { %profile, my_method => $_ }
        for @{ $args{method} };

    # This is for get+post sugar
    $self->{last_added} = \%profile;

    return $self;
}; # end sub route

# This is for get+post sugar
# TODO merge with alias, GET => implicit HEAD
sub _dup_route {
    my ($self, $method, $profile) = @_;

    $profile ||= $self->{last_added};
    my $path = $profile->{path};

    $self->_croak( "Attempting to set duplicate handler for [$method] "
        .($path || '/'))
            if $self->{route}{ $path }{$method};

    $self->{route}{ $path }{$method}
        and $self->_croak("Attempting to set duplicate ");

    delete $self->{route_re};
    $self->{route}{ $path }{$method} = { %$profile, my_method => $method };
};

=head2 alias( $newpath => $oldpath )

Create a new name for already registered route.
The handler will be executed as is,
but new name will be reflected in Request->path.

Returns self.

=cut

sub alias {
    my ($self, $new, $old) = @_;
    $self = $Inst unless ref $self;

    $new = canonize_path( $new );
    $old = canonize_path( $old );

    $self->{route}{$old}
        or $self->_croak( "Cannot create alias for unknown route $old" );

    $self->_croak( "Attempting to set duplicate handler for path "
        .( length $new ? $new : "/" ) )
            if $self->{route}{ $new };

    # reset cache
    $self->{route_re} = undef;

    $self->{route}{$new} = $self->{route}{$old};
    return $self;
};

=head2 static( $req_path => $file_path, %options )

Serve static content located under C<$file_path>.

%options may include:

=over

=item * buffer => nnn - buffer size for reading/writing files.
Default is 4096. Smaller values may be set, but are NOT recommended.

=item * cache_ttl => nnn - if given, files below the buffer size will be stored
in memory for cache_ttl seconds.

B<EXPERIMENTAL>. Cache API is not yet established.

=item * allow_dots => 1|0 - if true, serve files/directories
starting with a dot (.git etc), otherwise give a 404.

B<EXPERIMENTAL>

=item * dir_index => 1|0 - if true, generate index for a directory;
otherwise a 404 is returned, and deliberately so, for security reasons.

B<EXPERIMENTAL>

=item * dir_template - specify template for directory listing
(with images etc). A sane default is provided.

B<EXPERIMENTAL>

=item * view - specify view object for rendering dir template.
By default a localized TT instance is used.

B<EXPERIMENTAL> Name MAY be changed (dir_view etc).

=item * description - comment. The default is "Static content at $dir"

=back

The content is really handled by L<MVC::Neaf::X::Files>.

File type detection is based on extention.
This MAY change in the future.
Known file types are listed in C<%MVC::Neaf::X::Files::ExtType> hash.
Patches welcome.

Generally it is probably a bad idea to serve files in production
using a web application framework.
Use a real web server instead.

However, this method may come in handy when testing the application
in standalone mode, e.g. under plack web server.
This is the intended usage.

=cut

sub static {
    my ($self, $path, $dir, %options) = @_;
    $self = $Inst unless ref $self;

    require MVC::Neaf::X::Files;
    my $xfiles = MVC::Neaf::X::Files->new(
        %options, root => $dir, base_url => $path );
    return $self->route( $xfiles->make_route );
};

=head2 pre_route( sub { ... } )

Mangle request before serving it.
E.g. canonize uri or read session cookie.

Return value from callback is ignored.

Dying in callback is treated the same way as in normal controller sub.

B<DEPRECATED>. Use C<Neaf-E<gt>add_hook( pre_route =E<gt> ... )> instead.

=cut

sub pre_route {
    my ($self, $code) = @_;
    $self = $Inst unless ref $self;

    carp ("DEPRECATED: pre_route(): use add_hook( pre_route => CODE ) instead");
    $self->add_hook( pre_route => $code );
    return $self;
};

=head2 load_view( $name, $object || coderef || ($module_name, %options) )

Load a view object and cache it under name $name, if $name is true.
The loaded view is returned.
All subsequent calls to get_view( $name ) would return that object, too.

=over

=item * if object is given, just save it.

=item * if module name + parameters is given, try to load module
and create new() instance.

=item * as a last resort, load stock view: C<TT>, C<JS>, or C<Dumper>.
Those are prefixed with C<MVC::Neaf::View::>.

=back

If C<set_forced_view> was called, return its argument instead.

=cut

my %known_view = (
    TT     => 'MVC::Neaf::View::TT',
    JS     => 'MVC::Neaf::View::JS',
    Dumper => 'MVC::Neaf::View::Dumper',
);
sub load_view {
    my ($self, $name, $obj, @param) = @_;
    $self = $Inst unless ref $self;

    $self->_croak("At least two arguments required")
        unless defined $name and defined $obj;

    # We've been overridden!
    return $self->{force_view}
        if exists $self->{force_view};

    # Instantiate if needed
    if (!ref $obj) {
        # in case an alias is used, apply alias
        $obj = $known_view{ $obj } || $obj;

        # Try loading...
        if (!$obj->can("new")) {
            eval { load $obj; 1 }
                or $self->_croak( "Failed to load view $name=>$obj: $@" );
        };
        $obj = $obj->new( @param );
    };

    $self->_croak( "view must be a coderef or a MVC::Neaf::View object" )
        unless blessed $obj and $obj->can("render")
            or ref $obj eq 'CODE';

    $self->{seen_view}{$name} = $obj
        if $name;

    return $obj;
};

=head2 set_default ( key => value, ... )

Set some default values that would be appended to data hash returned
from any controller on successful operation.
Controller return always overrides these values.

Returns self.

B<DEPRECATED>. Use C<MVC::Neaf-E<gt>set_path_defaults( '/', { ... } );> instead.

=cut

sub set_default {
    my ($self, %data) = @_;
    $self = $Inst unless ref $self;

    carp "DEPRECATED use set_path_defaults( '/', \%data ) instead of MVC::Neaf->set_default()";

    return $self->set_path_defaults( '/', \%data );
};

=head2 set_path_defaults ( '/path' => \%values )

Use given values as defaults for ANY handler below given path.
A value of '/' means global.

Longer paths override shorter ones; route-specific defaults override these;
and anything defined inside handler takes over once again.

B<EXPERIMENTAL> Name and meaning MAY change in the future.

=cut

sub set_path_defaults {
    my ($self, $path, $src) = @_;
    $self = $Inst unless ref $self;

    $self->_croak("arguments must be a scalar and a hashref")
        unless defined $path and !ref $path and ref $src eq 'HASH';

    # canonize path
    # CANONIZE
    $path =~ s#/+#/#;
    $path =~ s#^/*#/#;
    $path =~ s#/$##;
    my $dst = $self->{path_defaults}{$path} ||= {};
    $dst->{$_} = $src->{$_}
        for keys %$src;

    return $self;
};

=head2 set_session_handler( %options )

Set a handler for managing sessions.

If such handler is set, the request object will provide C<session()>,
C<save_session()>, and C<delete_session()> methods to manage
cross-request user data.

% options may include:

=over

=item * engine (required) - an object providing the storage primitives;

=item * ttl - time to live for session (default is 0, which means until
browser is closed);

=item * cookie - name of cookie storing session id.
The default is "session".

=item * view_as - if set, add the whole session into data hash
under this name before view processing.

=back

The engine MUST provide the following methods
(see L<MVC::Neaf::X::Session> for details):

=over

=item * session_ttl (implemented in MVC::Neaf::X::Session);

=item * session_id_regex (implemented in MVC::Neaf::X::Session);

=item * get_session_id (implemented in MVC::Neaf::X::Session);

=item * create_session (implemented in MVC::Neaf::X::Session);

=item * save_session (required);

=item * load_session (required);

=item * delete_session (implemented in MVC::Neaf::X::Session);

=back

=cut

sub set_session_handler {
    my ($self, %opt) = @_;
    $self = $Inst unless ref $self;

    my $sess = delete $opt{engine};
    my $cook = $opt{cookie} || 'neaf.session';

    $self->_croak("engine parameter is required")
        unless $sess;

    if (!ref $sess) {
        $opt{session_ttl} = delete $opt{ttl} || $opt{session_ttl};

        my $obj = eval { load $sess; $sess->new( %opt ); }
            or $self->_croak("Failed to load session '$sess': $@");

        $sess = $obj;
    };

    my @missing = grep { !$sess->can($_) }
        qw(get_session_id session_id_regex session_ttl
            create_session load_session save_session delete_session );
    $self->_croak("engine object does not have methods: @missing")
        if @missing;

    my $regex = $sess->session_id_regex;
    my $ttl   = $opt{ttl} || $sess->session_ttl || 0;

    $self->{session_handler} = [ $sess, $cook, $regex, $ttl ];
    $self->{session_view_as} = $opt{view_as};
    return $self;
};

=head2 set_error_handler ( status => CODEREF( $req, %options ) )

Set custom error handler.

Status must be either a 3-digit number (as in HTTP), or "view".
Other allowed keys MAY appear in the future.

The following options will be passed to coderef:

=over

=item * status - status being returned (500 in case of 'view');

=item * caller - array with the point where C<MVC::Neaf-E<gt>route> was set up;

=item * error - exception, if there was one.

=back

The coderef MUST return an unblessed hash just like controller does.

In case of exception or unexpected return format text message "Error NNN"
will be returned instead.

=head2 set_error_handler ( status => \%hash )

Return a static template as C<{ %options, %hash }>.

=cut

sub set_error_handler {
    my ($self, $status, $code) = @_;
    $self = $Inst unless ref $self;

    $status =~ /^(\d\d\d|view)$/
        or $self->_croak( "1st arg must be http status or a const(see docs)");
    if (ref $code eq 'HASH') {
        my $hash = $code;
        $code = sub {
            my ($req, %opt) = @_;

            return { -status => $opt{status}, %opt, %$hash };
        };
    };
    ref $code eq 'CODE'
        or $self->_croak( "2nd arg must be callback or hash");

    $self->{error_template}{$status} = $code;

    return $self;
};

=head2 error_template( ... )

B<DEPRECATED>. Same as above, but issues a warning.

=cut

# TODO kill in v.0.20
sub error_template {
    my $self = shift;

    carp "error_template() is deprecated, use set_error_handler() instead";
    return $self->set_error_handler(@_);
};

=head2 on_error( sub { my ($req, $err) = @_ } )

Install custom error handler for dying controller.
Neaf's own exceptions and C<die \d\d\d> status returns will NOT
trigger it.

E.g. write to log, or something.

Return value from this callback is ignored.
If it dies, only a warning is emitted.

=cut

sub on_error {
    my ($self, $code) = @_;
    $self = $Inst unless ref $self;

    if (defined $code) {
        ref $code eq 'CODE'
            or $self->_croak( "Argument MUST be a callback" );
        $self->{on_error} = $code;
    } else {
        delete $self->{on_error};
    };

    return $self;
};

=head2 run()

Run the applicaton.
This should be the last statement in your appication main file.

If called in void context, assumes CGI is being used and instantiates
L<MVC::Neaf::Request::CGI>.
If command line options are present at the time,
enters debug mode via L<MVC::Neaf::CLI>.

Otherwise returns a PSGI-compliant coderef.
This will also happen if you application is C<require>'d,
meaning that it returns a true value and actually serves nothing until
C<run()> is called again.

Running under mod_perl requires setting a handler with
L<MVC::Neaf::Request::Apache2>.

=cut

sub run {
    my $self = shift;
    $self = $Inst unless ref $self;

    $self->{route_re} ||= $self->_make_route_re;

    # Add implicit HEAD for all GETs via shallow copy
    foreach my $node (values %{ $self->{route} }) {
        $node->{GET} or next;
        $node->{HEAD} ||= { %{ $node->{GET} }, my_method => 'HEAD' };
    };

    # initialize stuff if first run
    # TODO don't allow modification after lock
    # Please bear in mind that $_[0] in callbacks is ALWAYS the Request object
    if (!$self->{lock}) {
        if (my $engine = $self->{session_handler}) {
            $self->add_hook( pre_route => sub {
                $_[0]->_set_session_handler( $engine );
            }, prepend => 1 );
            if (my $key = $self->{session_view_as}) {
                $self->add_hook( pre_render => sub {
                    $_[0]->reply->{$key} = $_[0]->load_session;
                }, prepend => 1 );
            };
        };
        if (my $engine = $self->{stat}) {
            $self->add_hook( pre_route => sub {
                $engine->record_start;
            }, prepend => 1);
            $self->add_hook( pre_content => sub {
                $engine->record_controller( $_[0]->script_name );
            }, prepend => 1);
            $self->add_hook( pre_reply => sub {
                $engine->record_finish($_[0]->reply->{-status}, $_[0]);
            }, prepend => 1);
        };
    };

    if (defined wantarray) {
        # The run method is being called in non-void context
        # This is the case for PSGI, but not CGI (where it's just
        # the last statement in the script).

        # PSGI
        require MVC::Neaf::Request::PSGI;
        return sub {
            my $env = shift;
            my $req = MVC::Neaf::Request::PSGI->new( env => $env );
            return $self->handle_request( $req );
        };
    } else {
        # void context - CGI called.
        if (@ARGV) {
            require MVC::Neaf::CLI;
            MVC::Neaf::CLI->run($self);
        } else {;
            require MVC::Neaf::Request::CGI;
            my $req = MVC::Neaf::Request::CGI->new;
            $self->handle_request( $req );
        };
    };
};

sub _make_route_re {
    my ($self, $hash) = @_;

    $hash ||= $self->{route};

    my $re = join "|", map { quotemeta } reverse sort keys %$hash;

    # make $1, $2 always defined
    return qr{^($re)((?:/[^?]*)?)(?:\?|$)};
};

=head1 EXPORTED FUNCTIONS

Currently only one function is exportable:

=head2 neaf_err $error

Rethrow Neaf's internal exceptions immediately, do nothing otherwise.

If no argument if given, acts on current C<$@> value.

Currently Neaf uses exception mechanism for internal signalling,
so this function may be of use if there's a lot of eval blocks
in the controller. E.g.

    use MVC::Neaf qw(neaf_err);

    # somewhere in controller
    eval {
        check_permissions()
            or $req->error(403);
        do_something()
            and $req->redirect("/success");
    };

    if (my $err = $@) {
        neaf_err;
        # do the rest of error handling
    };

=cut

sub neaf_err(;$) { ## no critic # prototype it for less typing on user's part
    my $err = shift || $@;
    return unless blessed $err and $err->isa("MVC::Neaf::Exception");
    die $err;
};

=head1 EXPERIMENTAL FUNCTIONAL SUGAR

In order to minimize typing, a less cumbersome prototyped interface is provided:

    use MVC::Neaf qw(:sugar);

    get '/foo/bar' => sub { ... }, view => 'TT';
    neaf error => 404 => \&my_error_template;

    neaf->run;

It is not stable yet, so be careful when upgrading Neaf.

=head2 get '/path' => CODE, %options;

Create a route with C<GET/HEAD> methods enabled.
The %options are the same as those of C<route()> method.

=head2 head '/path' => CODE, %options;

Create a route with C<HEAD> method enabled.
The %options are the same as those of C<route()> method.

=head2 post '/path' => CODE, %options;

Create a route with C<POST> method enabled.
The %options are the same as those of C<route()> method.

=head2 put '/path' => CODE, %options;

Create a route with C<PUT> method enabled.
The %options are the same as those of C<route()> method.

=head2 get + post '/path' => CODE, %options;

B<EXPERIMENTAL>. Set multiple methods in one go.

=cut

foreach (qw(get head post put)) {
    my $method = uc $_;

    my $code = sub(@) { ## no critic
        # get + post sugar
        if (@_ == 1 and UNIVERSAL::isa( $_[0], __PACKAGE__ )) {
            return $_[0]->_dup_route( $method );
        };

        # normal operation
        my ($path, $handler, @args) = @_;

        return $Inst->route( $path, $handler, @args, method => $method );
    };

    no strict 'refs'; ## no critic
    *{$_} = $code;
};

=head2 neaf->...

Returns default Neaf instance (C<$MVC::Neaf::Inst>), so that
C<neaf-E<gt>method_name> is the equivalent of C<MVC::Neaf-E<gt>method_name>.

=head2 neaf shortcut => @options;

Shorter alias to methods described above. Currently supported:

=over

=item * route - C<route>

=item * error - C<set_error_handler>

=item * view - C<load_view>

=item * hook - C<add_hook>

=item * session - C<set_session_handler>

=item * default - C<set_path_defaults>

=item * alias   - C<alias>

=item * static  - C<static>

=back

Also, passing a 3-digit number will trigger C<set_error_handler>,
and passing a hook phase (see below) will result in setting a hook.

=cut

my %method_shortcut = (
    route    => 'route',
    error    => 'set_error_handler',
    view     => 'load_view',
    hook     => 'add_hook',
    session  => 'set_session_handler',
    default  => 'set_path_defaults',
    alias    => 'alias',
    static   => 'static',
);
my %hook_phases;
$hook_phases{$_}++ for qw(pre_route pre_logic pre_content pre_render pre_reply pre_cleanup);

sub neaf(@) { ## no critic # DSL
    return $MVC::Neaf::Inst unless @_;

    my ($action, @args) = @_;

    if ($action =~ /^\d\d\d$/) {
        unshift @args, $action;
        $action = 'error';
    };
    if ($hook_phases{$action}) {
        unshift @args, $action;
        $action = 'hook';
    };

    if ($action eq 'session') {
        unshift @args, 'engine';
    };

    my $method = $method_shortcut{$action};
    croak "neaf: don't know how to handle '$action'"
        unless $method and MVC::Neaf->can($method);

    return MVC::Neaf->$method( @args );
};

=head1 HOOKS

Hooks are subroutines executed during various phases of request processing.
Each hook is characterized by phase, code to be executed, path, and method.
Multiple hooks MAY be added for the same phase/path/method combination.
ALL hooks matching a given route will be executed, either short to long or
long to short (aka "event bubbling"), depending on the phase.

B<CAUTION> Don't overuse hooks.
This may lead to a convoluted, hard to follow application.
Use hooks for repeated auxiliary tasks such as checking permissions or writing
down statistics, NOT for primary application logic.

=head2 add_hook ( phase => CODEREF, %options )

Set execution hook for given phase. See list of phases below.

The CODEREF receives one and only argument - the C<$request> object.
Return value is ignored.

Use the following primitives to maintain state accross hooks and the main
controller:

=over

=item * Use C<session> if you intend to share data between requests.

=item * Use C<reply> if you intend to render the data for the user.

=item * Use C<stash> as a last resort for temporary, private data.

=back

%options may include:

=over

=item * path => '/path' - where the hook applies. Default is '/'.
Multiple locations may be supplied via C<[ /foo, /bar ...]>

=item * exclude => '/path/dont' - don't apply to these locations,
even if under '/path'.
Multiple locations may be supplied via C<[ /foo, /bar ...]>

=item * method => 'METHOD' || [ list ]
List of request HTTP methods to which given hook applies.

=item * prepend => 0|1 - all other parameters being equal,
hooks will be executed in order of adding.
This option allows to override this and run given hook first.
Note that this does NOT override path bubbling order.

=back

=head2 HOOK PHASES

This list of phases MAY change in the future.
Current request processing diagram looks as follows:

   [*] request created
    . <- pre_route [no path] [can die]
    |
    * route - select handler
    |
    . <- pre_logic [can die]
   [*] execute main handler
    * apply path-based defaults - reply() is populated now
    |
    . <- pre_content
    ? checking whether content already generated
    |\
    | . <- pre_render [can die - template error produced]
    | [*] render - -content is present now
    |/
    * generate default headers (content type & length, cookies, etc)
    . <- pre_reply [path traversal long to short]
    |
   [*] headers sent out, no way back!
    * output the rest of reply (if -continue specified)
    * execute postponed actions (if any)
    |
    . <- pre_cleanup [path traversal long to short] [no effect on headers]
   [*] request destroyed

=head3 pre_route

Executed AFTER the event has been received, but BEFORE the path has been
resolved and handler found.

Dying in this phase stops both further hook processing and controller execution.
Instead, the corresponding error handler is executed right away.

Options C<path> and C<exclude> are not available on this stage.

May be useful for mangling path.
Use C<$request-E<gt>set_full_path($new_path)> if you need to.

=head3 pre_logic

Executed AFTER finding the correct route, but BEFORE processing the main
handler code (one that returns C<\%hash>, see C<route> above).

Hooks are executed in order, shorted paths to longer.
C<reply> is not available at this stage,
as the controller has not been executed yet.

Dying in this phase stops both further hook processing and controller execution.
Instead, the corresponding error handler is executed right away.

B<EXAMPLE>: use this hook to produce a 403 error if the user is not logged in
and looking for a restricted area of the site:

    MVC::Neaf->set_hook( pre_logic => sub {
        my $request = shift;
        $request->session->{user_id} or die 403;
    }, path => '/admin', exclude => '/admin/static' );

=head3 pre_content

This hook is run AFTER the main handler has returned or died, but BEFORE
content rendering/serialization is performed.

C<reply()> hash is available at this stage.

Dying is ignored, only producing a warning.

=head3 pre_render

This hook is run BEFORE content rendering is performed, and ONLY IF
the content is going to be rendered,
i.e. no C<-content> key set in response hash on previous stages.

Dying will stop rendering, resulting in a template error instead.

=head3 pre_reply

This hook is run AFTER the headers have been generated, but BEFORE the reply is
actually sent to client. This is the last chance to amend something.

Hooks are executed in REVERSE order, from longer to shorter paths.

C<reply()> hash is available at this stage.

Dying is ignored, only producing a warning.

=head3 pre_cleanup

This hook is run AFTER all postponed actions set up in controller
(via C<-continue> etc), but BEFORE the request object is actually destroyed.
This can be useful to deinitialize something or write statistics.

The client conection MAY be closed at this point and SHOULD NOT be relied upon.

Hooks are executed in REVERSE order, from longer to shorter paths.

Dying is ignored, only producing a warning.

=cut

my %add_hook_args;
$add_hook_args{$_}++ for qw(method path exclude prepend);

sub add_hook {
    my ($self, $phase, $code, %opt) = @_;
    $self = $Inst unless ref $self;

    my @extra = grep { !$add_hook_args{$_} } keys %opt;
    $self->_croak( "unknown options: @extra" )
        if @extra;
    $self->_croak( "illegal phase: $phase" )
        unless $hook_phases{$phase};

    _listify( \$opt{method}, qw( GET HEAD POST PUT PATCH DELETE ) );
    if ($phase eq 'pre_route') {
        # handle pre_route separately
        $self->_croak("cannot specify paths/excludes for $phase")
            if defined $opt{path} || defined $opt{exclude};
        foreach( @{ $opt{method} } ) {
            my $where = $self->{pre_route}{$_} ||= [];
            $opt{prepend} ? unshift @$where, $code : push @$where, $code;
        };
        return $self;
    };

    _listify( \$opt{path}, '/' );
    _listify( \$opt{exclude} );
    @{ $opt{path} } = map { canonize_path($_) } @{ $opt{path} };
    @{ $opt{exclude} } = map { canonize_path($_) } @{ $opt{exclude} };

    $opt{caller} = [ caller(0) ]; # where the hook was set
    $opt{phase}  = $phase; # just for information
    $opt{code}   = $code;

    # hooks == {method}{path}{phase}[nnn] => { code => CODE, ... }

    foreach my $method ( @{$opt{method}} ) {
        foreach my $path ( @{$opt{path}} ) {
            my $where = $self->{hooks}{$method}{$path}{$phase} ||= [];
            $opt{prepend} ? unshift @$where, \%opt : push @$where, \%opt;
        };
    };

    return $self;
};

# TODO util?
# usage: listify ( \$var, default1, default2... )
# converts scalar in-place to arrayref if needed
sub _listify {
    my ($scalref, @default) = @_;

    if (ref $$scalref ne 'ARRAY') {
        my $array = defined $$scalref ? [ my $tmp = $$scalref ] : \@default;
        $$scalref = $array;
    };

    return $$scalref;
};

=head1 DEVELOPMENT AND DEBUGGING METHODS

=head2 get_routes

Returns a hash with ALL routes for inspection.
This should NOT be used by application itself.

=cut

sub get_routes {
    my $self = shift;
    $self = $Inst unless ref $self;

    # shallow copy TODO need 2 layers!
    return { %{ $self->{route} } };
};

=head2 set_forced_view( $view )

If set, this view object will be user instead of ANY other view.

See C<load_view>.

Returns self.

=cut

sub set_forced_view {
    my ($self, $view) = @_;
    $self = $Inst unless ref $self;

    delete $self->{force_view};
    return $self unless $view;

    $self->{force_view} = $self->get_view( $view );

    return $self;
};

=head2 server_stat ( MVC::Neaf::X::ServerStat->new( ... ) )

Record server performance statistics during run.

The interface of ServerStat is as follows:

    my $stat = MVC::Neaf::X::ServerStat->new (
        write_threshold_count => 100,
        write_threshold_time  => 1,
        on_write => sub {
            my $array_of_arrays = shift;

            foreach (@$array_of_arrays) {
                # @$_ = (script_name, http_status,
                #       controller_duration, total_duration, start_time)
                # do something with this data
                warn "$_->[0] returned $_->[1] in $_->[3] sec\n";
            };
        },
    );

on_write will be executed as soon as either count data points are accumulated,
or time is exceeded by difference between first and last request in batch.

Returns self.

=cut

sub server_stat {
    my ($self, $obj) = @_;
    $self = $Inst unless ref $self;

    if ($obj) {
        $self->{stat} = $obj;
    } else {
        delete $self->{stat};
    };

    return $self;
};

=head1 INTERNAL API

B<CAVEAT EMPTOR.>

The following methods are generally not to be used,
unless you want something very strange.

=cut


=head2 new(%options)

Constructor. Usually, instantiating Neaf is not required.
But it's possible.

Options are not checked whatsoever.

Just in case you're curious, C<$MVC::Neaf::Inst> is the default instance
that handles MVC::Neaf->... requests.

=cut

sub new {
    my ($class, %opt) = @_;

    $opt{-type}     ||= "text/html";
    $opt{-view}     ||= "TT";
    my $force = delete $opt{force_view};

    my $self = bless \%opt, $class;

    $self->{on_error} ||= sub {
        my ($req, $err, $where) = @_;
        $self->_log_error( $req->script_name, $err );
    };

    $self->set_forced_view( $force )
        if $force;
    # avoid an extra ||= in handle requ
    $self->set_path_defaults( '/' => { -status => 200 } );

    return $self;
};

=head2 handle_request( MVC::Neaf::Request->new )

This is the CORE of this module.
Should not be called directly - use C<run()> instead.

=cut

sub handle_request {
    my ($self, $req) = @_;
    $self = $Inst unless ref $self;

    # ROUTE REQUEST
    my $route;
    my $data = eval {
        my $method = $req->method;
        # Try running the pre-routing callback.
        run_all( $self->{pre_route}{$method}, $req )
            if (exists $self->{pre_route}{$method});

        # Lookup the rules for the given path
        $req->path =~ $self->{route_re} and my $node = $self->{route}{$1}
            or die "404\n";
        unless ($route = $node->{ $method }) {
            $req->set_header( Allow => join ", ", keys %$node );
            die "405\n";
        };

        # TODO optimize this or do smth. Still MUST keep route_re a prefix tree
        my ($path, $path_info) = ($1, $2);
        if ($path_info =~ /%/) {
            $path_info = decode_utf8( uri_unescape( $path_info ) );
        };
        $path_info =~ $route->{path_info_regex}
            or die "404\n";
        $req->set_full_path( $path, $path_info, $route->{no_path_info_regex} );
        $self->_post_setup( $route )
            unless exists $route->{lock};

        # execute hooks
        run_all( $route->{hooks}{pre_logic}, $req)
            if exists $route->{hooks}{pre_logic};
        # Run the controller!
        return $route->{code}->($req);
    };

    if ($data) {
        # post-process data - fill in request(RD) & global(GD) defaults.
        # TODO kill request defaults in v.0.20
        my $RD = $req->get_default;
        my $GD = $route->{default};
        exists $data->{$_} or $data->{$_} = $RD->{$_} for keys %$RD;
        exists $data->{$_} or $data->{$_} = $GD->{$_} for keys %$GD;
    } else {
        # Fall back to error page
        # TODO $req->clear; - but don't kill cleanup hooks
        $data = $self->_error_to_reply( $req, $@, $route->{caller} );
    };

    # END ROUTE REQUEST

    $req->_set_reply( $data );
    if (exists $route->{hooks}{pre_content}) {
        run_all_nodie( $route->{hooks}{pre_content}, sub {
                $self->_log_error( "pre_content hook", $@ )
        }, $req );
    };

    # PROCESS REPLY

    # Render content if needed. This may alter type, so
    # produce headers later.
    my $content = \$data->{-content};
    if( !defined $$content) {
        my $view = $self->get_view( $data->{-view} || $route->{view} );
        eval {
            run_all( $route->{hooks}{pre_render}, $req )
                if exists $route->{hooks}{pre_render};
            ($$content, my $type) = blessed $view
                ? $view->render( $data ) : $view->( $data );
            $data->{-type} ||= $type;
        };
        if (!defined $$content) {
            # TODO $req->clear; - but don't kill cleanup hooks
            # FIXME bug here - resetting data does NOT affect the inside of req
            $self->_log_error( view => $@ );
            $data = {
                -status => 500,
                -type   => "text/plain",
            };
            $$content = "Template error."; # TODO configurable
        };
    };

    # TODO should this be a sub?
    # Encode unicode content NOW so that we don't lie about its length
    # Then detect ascii/binary
    if (Encode::is_utf8( $$content )) {
        # UTF8 means text, period
        $$content = encode_utf8( $$content );
        $data->{-type} ||= 'text/plain';
        $data->{-type} .= "; charset=utf-8"
            unless $data->{-type} =~ /; charset=/;
    } elsif (!$data->{-type}) {
        # Autodetect binary. Plain text is believed to be in utf8 still
        $data->{-type} = $$content =~ /^.{0,512}?[^\s\x20-\x7F]/s
            ? 'application/octet-stream'
            : 'text/plain; charset=utf-8';
    } elsif ($data->{-type} =~ m#^text/#) {
        # Some other text, mark as utf-8 just in case
        $data->{-type} .= "; charset=utf-8"
            unless $data->{-type} =~ /; charset=/;
    };

    # Mangle headers - NOTE these modifications remain stored in req
    my $head = $req->header_out;
    if (my $append = $data->{-headers}) {
        if (ref $append eq 'ARRAY') {
            for (my $i = 0; $i < @$append; $i+=2) {
                $head->push_header($append->[$i], $append->[$i+1]);
            };
        }
        else {
            carp("Neaf: -headers must be ARRAY, not ".(ref $append));
            # Would love to die, but it's impossible here
        };
    };
    $head->init_header( content_type => $data->{-type} || $self->{-type} );
    $head->init_header( location => $data->{-location} )
        if $data->{-location};
    $head->push_header( set_cookie => $req->format_cookies );
    $head->init_header( content_length => length $$content )
        unless $data->{-continue};
    $head->init_header( expires => http_date( time + $route->{cache_ttl} ) )
        if exists $route->{cache_ttl} and $data->{-status} == 200;
    $$content = '' if $req->method eq 'HEAD';

    # END PROCESS REPLY

    if (exists $route->{hooks}{pre_cleanup}) {
        $req->postpone( $route->{hooks}{pre_cleanup} );
    };
    if (exists $route->{hooks}{pre_reply}) {
        run_all_nodie( $route->{hooks}{pre_reply}, sub {
                $self->_log_error( "pre_reply hook", $@ )
        }, $req );
    };

    # DISPATCH CONTENT

    if ($data->{-continue} and $req->method ne 'HEAD') {
        $req->postpone( $data->{'-continue'}, 1 );
        $req->postpone( sub { $_[0]->write( $$content ); }, 1 );
        return $req->do_reply( $data->{-status} );
    } else {
        return $req->do_reply( $data->{-status}, $$content );
    };

    # END DISPATCH CONTENT
}; # End handle_request()

# _post_setup( $route )
# 1) calc defaults
# 2) calc hooks
# 3) lock
sub _post_setup {
    my ($self, $route) = @_;

    # CALCULATE DEFAULTS
    my %def;
    # merge data sources, longer paths first
    my @sources = (
          $route->{todo_default}
        , map { $self->{path_defaults}{$_} }
            reverse path_prefixes( $route->{path} )
    );

    foreach my $src( @sources ) {
        $src or next;
        exists $def{$_} or $def{$_} = $src->{$_}
            for keys %$src;
    };

    # kill undef values
    defined $def{$_} or delete $def{$_}
        for keys %def;
    $route->{default} = \%def;

    # CALCULATE HOOKS
    # select ALL hooks prepared for upper paths
    my $hook_tree = $self->{hooks}{ $route->{my_method} };
    my @hook_by_path =
        map { $hook_tree->{$_} || () } path_prefixes( $route->{path} );

    # Merge callback stacks into one hash, in order
    # hook = {method}{path}{phase}[nnn] => { code => sub{}, ... }
    # We need to extract that sub {}
    # We do so in a rather clumsy way that would short cirtuit
    #     at all possibilities
    # Premature optimization FTW!
    my %phases;
    foreach my $hook_by_phase (@hook_by_path) {
        foreach my $phase ( keys %$hook_by_phase ) {
            my $hook_list = $hook_by_phase->{$phase};
            foreach my $hook (@$hook_list) {
                # process excludes - if path starts with any, no go!
                grep { $route->{path} =~ m#^\Q$_\E(?:/|$)# }
                    @{ $hook->{exclude} }
                        and next;
                # TODO filter out repetition
                push @{ $phases{$phase} }, $hook->{code};
                # TODO also store hook info somewhere for better error logging
            };
        };
    };

    # the pre-reply, pre-cleanup should go in backward direction
    # those are for cleaning up stuff
    $phases{$_} and @{ $phases{$_} } = reverse @{ $phases{$_} }
        for qw(pre_cleanup pre_reply);

    $route->{hooks} = \%phases;

    # LOCK PROFILE
    $route->{lock}++
        and die "MVC::Neaf broken, please file a bug";
    return;
};

sub _error_to_reply {
    my ($self, $req, $err, $where) = @_;

    if (blessed $err and $err->isa("MVC::Neaf::Exception")) {
        $err->{-status} ||= 500;
        return $err;
    };

    my $status = (!ref $err && $err =~ /^(\d\d\d)/) ? $1 : 500;

    # Try exception handler
    if( !$1 and exists $self->{on_error}) {
        eval { $self->{on_error}->($req, $err, $where); 1 }
            or $self->_log_error( "error handler", $@ );
    };

    # Try fancy error template
    if (exists $self->{error_template}{$status}) {
        my $ret = eval {
            $self->{error_template}{$status}->( $req,
                status => $status,
                caller => $where,
                error => $err,
            );
        };
        return $ret
            if (ref $ret eq 'HASH');
        $self->_log_error( "status $status handler:", $@ );
    };

    # Options exhausted - return plain error message
    return {
        -status     => $status,
        -type       => 'text/plain',
        -content    => "Error $status\n",
    };
};

sub _croak {
    my ($self, $msg) = @_;

    my $where = [caller(1)]->[3];
    $where =~ s/.*:://;
    croak( (ref $self || $self)."->$where: $msg" );
};

sub _log_error {
    my ($self, $where, $err) = @_;

    my $msg = "ERROR: in $where: $err";
    $msg =~ s/\n\s*/ /gs;
    $msg =~ s/\s*$/\n/;
    warn $msg;
};

=head2 get_view( "name" )

Fetch view object by name.
Uses C<load_view> w/o additional params if needed.
This is for internal usage.

=cut

sub get_view {
    my ($self, $view) = @_;
    $self = $Inst unless ref $self;

    if (ref $view) {
        return $self->load_view( '' => $view );
    }
    else {
        $view = $self->{-view} unless defined $view;
        return $self->{seen_view}{$view} || $self->load_view( $view, $view );
    };
};

=head2 run_test( \%PSGI_ENV, %options )

=head2 run_test( "/path?param=value", %options )

Run a PSGI request and return a list of
C<($status, HTTP::Headers, $whole_content )>.

Returns just the content in scalar context.

Just as the name suggests, useful for testing only (it reduces boilerplate).

Continuation responses are supported.

%options may include:

=over

=item * method - set method (default is GET)

=item * override = \%hash - force certain data in ENV

=item * cookie = \%hash - force HTTP_COOKIE header

=back

=cut

sub run_test {
    my ($self, $env, %opt) = @_;

    if (!ref $env) {
        $env =~ /^(.*?)(?:\?(.*))?$/;
        $env = {
            REQUEST_URI => $env,
            REQUEST_METHOD => 'GET',
            QUERY_STRING => defined $2 ? $2 : '',
            SERVER_NAME => 'localhost',
            SERVER_PORT => 80,
            SCRIPT_NAME => '',
            PATH_INFO => $1,
        }
    };
    # TODO more civilized stuff like cookies, headers...
    $env->{REQUEST_METHOD} = $opt{method} if $opt{method};
    $env->{$_} = $opt{override}{$_} for keys %{ $opt{override} };

    if (my $cook = $opt{cookie}) {
        # TODO hash processing
        $env->{HTTP_COOKIE} = $env->{HTTP_COOKIE}
            ? "$env->{HTTP_COOKIE}, $cook"
            : $cook;
    };

    my $ret = $self->run->( $env );
    if (ref $ret eq 'CODE') {
        # PSGI functional interface used.
        require MVC::Neaf::Request::FakeWriter;
        $ret = MVC::Neaf::Request::FakeWriter->new->respond( $ret );
    };

    return (
        $ret->[0],
        HTTP::Headers->new( @{ $ret->[1] } ),
        join '', @{ $ret->[2] },
    );
};

=head1 MORE EXAMPLES

See the examples directory in this distro or at
L<https://github.com/dallaylaen/perl-mvc-neaf/tree/master/example>
for complete working examples.
These below are just code snippets.

All of them are supposed to start and end with:

    use strict;
    use warnings;
    use MVC::Neaf;

    # ... snippet here

    MVC::Neaf->run;

=head2 Static content

    MVC::Neaf->static( '/images' => "/local/images" );
    MVC::Neaf->static( '/favicon.ico' => "/local/images/icon_32x32.png" );

=head2 RESTful web-service returning JSON

    MVC::Neaf->route( '/restful' => sub {
        # ...
    }, method => 'GET', view => 'JS' );

    MVC::Neaf->route( '/restful' => sub {
        # ...
    }, method => 'POST', view => 'JS' );

    MVC::Neaf->route( '/restful' => sub {
        # ...
    }, method => 'PUT', view => 'JS' );

=head2 Form submission

    use MVC::Neaf::X::Form;

    my %profile = (
        name => [ required => '\w+' ],
        age  => '\d+',
    );
    my $validator = MVC::Neaf::X::Form->new( \%profile );

    MVC::Neaf->route( '/submit' => sub {
        my $req = shift;

        my $form = $req->form( $validator );
        if ($req->is_post and $form->is_valid) {
            do_somethong( $form->data );
            $req->redirect( "/result" );
        };

        return {
            -template   => 'form.tt',
            errors      => $form->error,
            fill_values => $form->raw,
        };
    } );

More examples to follow as usage (hopefuly) accumulates.

=head1 BUGS

Lots of them, this software is still under heavy development.

* Apache2 handler is a joke and requires work.
It can still serve requests though.

Please report any bugs or feature requests to
L<https://github.com/dallaylaen/perl-mvc-neaf/issues>.

Alternatively, email them to C<bug-mvc-neaf at rt.cpan.org>, or report through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MVC-Neaf>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This is BETA software.
Feel free to email the author to get instant help!
Or you can comment the L<announce|http://perlmonks.org/?node_id=1174241>
at the Perlmonks forum.

You can find documentation for this module with the perldoc command.

    perldoc MVC::Neaf
    perldoc MVC::Neaf::Request

You can also look for information at:

=over 4

=item * Github: https://github.com/dallaylaen/perl-mvc-neaf

=item * MetaCPAN: https://metacpan.org/pod/MVC::Neaf

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MVC-Neaf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MVC-Neaf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MVC-Neaf>

=item * Search CPAN

L<http://search.cpan.org/dist/MVC-Neaf/>

=back

=head1 SEE ALSO

The L<Kelp> framework has very similar concept.

=head1 ACKNOWLEDGEMENTS

Ideas were shamelessly stolen from L<Catalyst>, L<Dancer>, and L<PSGI>.

Thanks to Eugene Ponizovsky aka L<IPH|https://metacpan.org/author/IPH>
for introducing me to the MVC concept.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MVC::Neaf
