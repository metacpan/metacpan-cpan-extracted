package MVC::Neaf;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.2901';

=head1 NAME

MVC::Neaf - Not Even A (Web Application) Framework

=head1 OVERVIEW

Neaf C<[ni:f]> stands for Not Even A Framework.

The B<Model> is assumed to be just a regular Perl module,
no restrictions are imposed on it.

The B<View> is an object with one method, C<render>, receiving a hashref
and returning rendered content as string plus optional content-type header.

The B<Controller> is a prefix tree of subroutines called I<handlers>.
Each such handler receives a L<MVC::Neaf::Request> object
containing I<all> it needs to know about the outside world,
and returns a simple C<\%hashref> which is forwarded to View.

Alternatively, it can die. C<die 404> is a valid way to return
a customizable "404 Not Found" page.

Please see the C<example> directory in this distribution
that demonstrates the features of Neaf.

=head1 SYNOPSIS

The following application, outputting a greeting, is ready to run
as a L<CGI> script, L<PSGI> application, or Apache handler.

    use strict;
    use warnings;
    use MVC::Neaf;

    get+post '/hello' => sub {
        my $req = shift;

        my $name = $req->param( name => qr/[-'\w\s]+/ ) || "Mystical stranger";
        return {
            name  => $name,
        };
    }, default => {
        -view     => 'TT',
        -type     => "text/plain",
        -template => \"Hello, [% name %]",
    };

    neaf->run;

A neaf application has some command-line interface built in:

    perl myapp.pl --list

Will give a summary of available routes.

    perl myapp.pl --listen :31415

Will start a default C<plackup> server (C<plackup myapp.pl> works as well)

    perl myapp.pl --post --upload foo=/path/to/file /bar?life=42 --view Dumper

Will run just one request and stop right before template processing,
dumping stash instead.

=head1 CREATING AN APPLICATION

=head2 THE CONTROLLER

The handler sub receives one and only argument, the B<request> object,
and outputs a C<\%hashref>.

It may also die, which will be interpreted as an error 500,
UNLESS error message starts with 3 digits and a whitespace,
in which case this is considered the return status.
E.g. C<die 404;> is a valid method to return
a configurable "Not Found" page right away.

Handlers are set up using the L</add_route> method discussed below.

=head2 THE REQUEST

L<MVC::Neaf::Request> interface is
similar to that of L<CGI> or L<Plack::Request> with some minor differences:

    # What was requested:
    http(s)://server.name:1337/mathing/route/some/more/slashes?foo=1&bar=2

    # What is being returned:
    $req->http_version; # = HTTP/1.0 or HTTP/1.1
    $req->scheme      ; # = http or https
    $req->method      ; # = GET
    $req->hostname    ; # = server.name
    $req->port        ; # = 1337
    $req->path        ; # = /mathing/route/some/more/slashes
    $req->prefix      ; # = /mathing/route
    $req->postfix     ; # = /some/more/slashes

    $req->param( foo => '\d+' ); # = 1
    $req->get_cookie( session => '.+' ); # = whatever it was set to before

One I<major> difference is that there's no (easy) way to fetch
query parameters or cookies without validation.
Just use pattern C<qr/.*/> if you know better.
But see also L</add_form>, forms are quite powerful.

Also there are some methods that affect the reply,
mainly the headers, like C<set_cookie> or C<redirect>.
This is a step towards a know-it-all God object,
however, mapping those properties into a hashref turned out to be
too cumbersome.

=head2 THE RESPONSE

B<The response> may contain regular keys, typically alphanumeric,
as well as a predefined set of dash-prefixed keys to control
Neaf itself.

    return {
        -view     => 'TT',
        -template => 'users.html',
        users     => \@list,
        extras    => \%hash,
    };

And that's it.

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
It will be executed AFTER the headers and the first content chunk
are served to the client, and may use C<$req-E<gt>write( $data );>
and C<$req-E<gt>close;> to output more data.

=item * -headers - Pass a hash or array of values for header generation.
This is an alternative to L<MVC::Neaf::Request>'s C<push_header> method.

=item * -jsonp - Used by C<JS> view module as a callback name to produce a
L<jsonp|https://en.wikipedia.org/wiki/JSONP> response.
Callback MUST be a set of identifiers separated by dots.
Otherwise it's ignored for security reasons.

=item * -location - HTTP Location: header for 3xx statuses.
This is set by C<$request-E<gt>redirect(...)>.

B<[DEPRECATED]> This will be phased out at some point,
use C<-header =E<gt> [ location =E<gt> ... ]> instead.

=item * -payload - if present, the C<JS> view will render this instead of
the whole response hash.
This can be used, for instance, to return non-hash data in a REST API.

Also used to be C<-serial> which is now deprecated.

B<[EXPERIMENTAL]> Name and meaning may change in the future.

=item * -status - HTTP status (200, 404, 500 etc).
Default is 200 if the handler managed to live through, and 500 if it died.

=item * -template - Set template name for a text processing view
(currently L<MVC::Neaf::View::TT> based on L<Template>).

=item * -type - Content-type HTTP header.
View module may set this parameter if unset.
Default is generated by the renderer - see L<MVC::Neaf::View>.

=item * -view - select B<View> module.
Views are initialized lazily and cached by the framework.
C<TT>, C<JS>, C<Full::Module::Name>, and C<$view_predefined_object>
are currently supported.
New short aliases may be created by
C<MVC::Neaf-E<gt>load_view( "name" =E<gt> $your_view );> (see below).

The default is C<JS> denoting the the L<MVC::Neaf::View::JS> engine.
Adding C<-template> key will cause switching to C<MVC::Neaf::View::TT>,
but it is deprecated and will go away in v.0.25.

=back

Though more dash-prefixed parameters may be returned
and will be passed to the View module as of current,
they are not guaranteed to work in the future.
Please either avoid them, or send patches.

=head1 FUNCTIONAL AND OBJECT-ORIENTED API

By default, NEAF exports a pretty standard route declaration interface:
C<get> + C<head> + C<post> + C<put> + C<patch> + C<del> for delete,
C<any> for setting up custom method combinations,
and a single L</neaf> function (see below) for configuring the application.

A C<:sugar> export keyword was used for it previously,
but it is no longer needed.

All prototyped declarative functions described below
are really frontends to a single L<MVC::Neaf> instance
which is also returned by a C<neaf> call without parameters.

More than one neaf application object can be created as simply
as C<MVC::Neaf-E<gt>new> if anybody needs that.

Given the above, functional and object-oriented ways
to declare the same thing will now follow in pairs.
See L<MVC::Neaf::Route::Main> for implementation details.

Returned value, unless specified otherwise,
is always the Neaf application itself (but who cares).

=cut

use Carp;
use Scalar::Util qw( blessed reftype );
use parent qw(Exporter);

our @EXPORT;
our @EXPORT_OK = qw( neaf_err );
my  @EXPORT_SUGAR = qw( neaf ); # Will populate later - see @ALL_METHODS below
our %EXPORT_TAGS = (
    sugar => \@EXPORT_SUGAR,
);

# NOTE We want MVC::Neaf->new() to create an application object.
#      We also want to profoundly document all the methods of said.
#      We also want `perdoc MVC::Neaf` to introduce the framework
#          and its DSL and features.
#      And thus we outsource our numerous helper methods to a separate class
#          and only leave exported stuff in this file.
use parent qw(MVC::Neaf::Route::Main);

our $Inst;

=head2 add_route()

The add_route() function and its numerous aliases define a handler
for given by URI path and HTTP method(s).

    $neaf->add_route( '/path' => CODEREF, %options )

is equivalent to

    get+post '/path' => sub { CODE; }, %options;

=over

=item * post '/path' => sub { CODE; }, %options;

Ditto, but sets method => 'POST'

=item * head ... - autogenerated by C<get>,
but can be specified explicitly if needed

=item * put ...

=item * patch ...

=item * del ... is for C<DELETE> (because C<delete> is a Perl's own keyword).

=item * any [ 'get', 'post', 'CUSTOM_METHOD' ] => '/path' => \&handler

=back

HTTP method declarations can be combined using the C<+> sign, as in

    get + post '/submit' => sub {
        my $req = shift;
        # do a lot of common stuff here
        if ($req->is_post) {
            # a few lines unique to POST method
            $req->redirect('/done');
        };
        return { ... }
    };

    post + put + patch '/some/item' => sub {
        my $req = shift;
        # generate item from $req->body
    };

Any incoming request to uri matching C</path>
(C</path/something/else> too, but NOT C</pathology>)
will now be directed to CODEREF.

Longer paths are GUARANTEED to be checked first.

Dies if the same method and path combination is given twice
(but see C<tentative> and C<override> below).
Multiple methods may be given for the same path.

Exactly one leading slash will be prepended no matter what you do.
(C<path>, C</path> and C</////path> are all the same).

The C<CODEREF> MUST accept exactly one argument,
referred to as C<$request> or C<$req> hereafter,
and return an unblessed hashref with response data.

%options may include:

=over

=item * C<method> - list of allowed HTTP methods.
Default is [GET, POST].
Multiple handles can be defined for the same path, provided that
methods do not intersect.
HEAD method is automatically handled if GET is present, however,
one MAY define a separate HEAD handler explicitly.

=item * C<path_info_regex> => C<qr/.../> - allow URI subpaths
to be handled by this handler.

A 404 error will be generated unless C<path_info_regex> is present
and PATH_INFO matches the regex (without the leading slashes).

If path_info_regex matches, it will be available in the controller
as C<$req-E<gt>postfix>.

If capture groups are present in said regular expression,
their content will also be available as C<$req-E<gt>path_info_split>.

B<[EXPERIMENTAL]> Name and semantics MAY change in the future.

=item * C<param_regex> => { name => C<qr/.../>, name2 => C<'\d+'> }

Add predefined regular expression validation to certain request parameters,
so that they can be queried by name only.
See L<MVC::Neaf::Request/param>.

B<[EXPERIMENTAL]> Name and semantics MAY change in the future.

=item * strict => 1|0

If true, request's C<param()> and C<get_cookie()>
will emit HTTP error 422
whenever mandatory validation fails.

If parameter or cookie is missing, just return default.
This MAY change in the future.

B<[EXPERIMENTAL]> Name and meaning MAY change in the future.

=item * C<view> - default View object for this Controller.
Must be a name of preloaded view,
an object with a C<render> method, or a CODEREF
receiving hashref and returning a list of two scalars
(content and content-type).

B<[DEPRECATED]> Use C<-view> instead, meaning is exactly the same.

=item * C<cache_ttl> - if set, set Expires: HTTP header accordingly.

B<[EXPERIMENTAL]> Name and semantics MAY change in the future.

=item * C<default> - a C<\%hash> of fallback values to be added to hash
returned by the handler.
Consider using C<neaf default ...> below if you need to append
the same values to multiple handlers.

=item * C<override> => 1 - replace old route even if it exists.
If not set, route collisions causes exception.
Use this if you know better.

This still issues a warning.

B<[EXPERIMENTAL]> Name and meaning may change in the future.

=item * C<tentative> => 1 - if route is already defined, do nothing.
If not, allow to redefine it later.

B<[EXPERIMENTAL]> Name and meaning may change in the future.

=item * C<description> - just for information, has no action on execution.
This will be displayed if application called with --list (see L<MVC::Neaf::CLI>).

=item * C<public> => 0|1 - a flag just for information.
In theory, public endpoints should be searchable from the outside
while non-public ones should only be reachable from other parts of application.
This is not enforced whatsoever.

=back

Also, any number of dash-prefixed keys MAY be present.
This is the same as putting them into C<default> hash.

See L<MVC::Neaf::Route::Main/add_route> for implementation.

=cut

=head2 static()

    neaf static => '/path' => $local_path, %options;

    neaf static => '/other/path' => [ $content, $content_type ];

    $neaf->static( $req_path => $file_path, %options )

Serve static content located under C<$file_path>.
Both directories and single files may be added.

Note that non-absolute local paths will be calculated relative to
the file where static() was called, not current working directory.
For files ending in C<.pm> and having a matching package name,
the file name without C<.pm> suffix will be used:

    # in /www/lib/perl5/My/App.pm
    package My::App;
    use MVC::Neaf;
    neaf static => '/css' => './resources/css';
        # points to /www/lib/perl5/My/App/resources/css/

If an arrayref of C<[ $content, $content_type ]> is given as second argument,
serve that content from memory instead.

%options may include:

=over

=item * C<buffer> => C<nnn> - buffer size for reading/writing files.
Default is 4096. Smaller values may be set, but are NOT recommended.

=item * C<cache_ttl> => C<nnn> - if given, files below the buffer size
will be stored in memory for C<cache_ttl> seconds.

B<[EXPERIMENTAL]> Cache API is not yet established.

=item * allow_dots => 1|0 - if true, serve files/directories
starting with a dot (.git etc), otherwise give a 404.

B<[EXPERIMENTAL]>

=item * dir_index => 1|0 - if true, generate index for a directory;
otherwise a 404 is returned, and deliberately so, for security reasons.

B<[EXPERIMENTAL]>

=item * dir_template - specify template for directory listing
(with images etc). A sane default is provided.

B<[EXPERIMENTAL]>

=item * view - specify view object for rendering directory template.
By default a localized C<TT> instance is used.

B<[EXPERIMENTAL]> Name MAY be changed (dir_view etc).

=item * override - override the route that was here before.
See C<route> above.

=item * tentative - don't complain if replaced later.

=item * description - comment. The default is "Static content at $directory"

=item * public => 0|1 - a flag just for information.
In theory, public endpoints should be searchable from the outside
while non-public ones should only be reachable from other parts of application.
This is not enforced whatsoever.

=back

See L<MVC::Neaf::X::Files> for implementation.

File type detection is based on extentions so far, and the list is quite short.
This MAY change in the future.
Known file types are listed in C<%MVC::Neaf::X::Files::ExtType> hash.
Patches welcome.

I<It is probably a bad idea to serve files in production
using a web application framework.
Use a real web server instead.
Not need to set up one for merely testing icons/js/css, though.>

=cut

=head2 set_path_defaults()

    neaf default => \%values, path => '/prefix', method => [ 'GET', 'POST' ];

    $neaf->set_path_defaults ( \%values, path => [ '/other', '/prefixes' ] );

Append these values to ANY controller return under given path(s),
unless overridden by return from handler.

Longer paths override shorter ones;
route-specific defaults override path-based defaults;
explicit values returned from handler override all or the above.

For example,

    neaf default '/api' => { -view => 'JS', version => My::Model->VERSION };

=cut

=head2 add_hook()

    neaf "phase" => sub { ... }, path => [ ... ], exclude => [ ... ];

    $neaf->add_hook ( phase => CODEREF, %options );

Set hook that will be executed on a given request processing phase.

Valid phases include:

=over

=item * pre_route [die]

=item * pre_logic [die]

=item * pre_content

=item * pre_render [die]

=item * pre_reply [reverse]

=item * pre_cleanup [reverse]

=back

See L</REQUEST PROCESSING PHASES AND HOOKS> below for detailed
discussion of each phase.

The CODEREF receives one and only argument - the C<$request> object.
Return value is B<ignored>, see explanation below.

Use C<$request>'s C<session>, C<reply>, and C<stash> methods
for communication between hooks.

Dying in a hook MAY cause interruption of request processing
or merely a warning, depending on the phase.

%options may include:

=over

=item * path => '/path' - where the hook applies. Default is '/'.
Multiple locations may be supplied via C<[ /foo, /bar ...]>

=item * exclude => '/path/skip' - don't apply to these locations,
even if under '/path'.
Multiple locations may be supplied via C<[ /foo, /bar ...]>

=item * method => 'METHOD' || [ list ]
List of request HTTP methods to which given hook applies.

=item * prepend => 0|1 - all other parameters being equal,
hooks will be executed in order of adding.
This option allows to override this and run given hook first.
Note that this does NOT override path bubbling order.

=back

=cut

=head2 alias()

    neaf alias $newpath => $oldpath

    $neaf->alias( $newpath => $oldpath )

Create a new name for already registered route.
The handler will be executed as is,
but the hooks and defaults will be re-calculated.
So be careful.

B<[CAUTION]> As of 0.21, C<alias> does NOT follow tentative/override switches.
This needs to be fixed in the future.

=cut

=head2 load_view()

    neaf view => 'name' => 'Driver::Class' => %options;

    $neaf->load_view( $name, $object || coderef || ($module_name, %options) )

Setup view under name C<$name>.
Subsequent requests with C<-view = $name> would be processed by that view
object.

Use C<get_view> to fetch the object itself.

=over

=item * if object is given, just save it.

=item * if module name + parameters are given, try to load module
and create a new() instance.

Short aliases C<JS>, C<TT>, and C<Dumper> may be used
for corresponding C<MVC::Neaf::View::*> modules.

The templates that allow for paths
(i.e. currently just L<MVC::Neaf::View::TT>)
will have non-absolute paths calculated relative to the file where
static() was called, not to the current directory.

=item * if coderef is given, use it as a C<render> method.
The coderef must take 1 argument - the hash returned from application -
and return a string + optional content-type.

=back

Returns the view object, NOT the calling Neaf object.

=cut

=head2 set_session_handler()

    neaf session => $engine => %options

    $neaf->set_session_handler( %options )

Set a handler for managing sessions.

If such handler is set, the request object will provide C<session()>,
C<save_session()>, and C<delete_session()> methods to manage
cross-request user data.

% options may include:

=over

=item * C<engine> (required in method form, first argument in DSL form)
- an object providing the storage primitives;

=item * C<ttl> - time to live for session (default is 0, which means until
browser is closed);

=item * C<cookie> - name of cookie storing session id.
The default is "session".

=item * C<view_as> - if set, add the whole session into data hash
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

=head2 add_form()

    neaf form => name => \%spec, engine => ...

    $neaf->add_form( name => $validator )

Create a named form for future query data validation
via C<$request-E<gt>form("name")>.
See L<MVC::Neaf::Request/form>.

The C<$validator> is one of:

=over

=item * An object with C<validate> method accepting one C<\%hashref>
argument (the raw form data).

=item * A CODEREF accepting the same argument.

=back

Whatever is returned by validator is forwarded into the controller.

Neaf comes with a set of predefined validator classes that return
a convenient object that contains collected valid data, errors (if any),
and an is_valid flag.

The C<engine> parameter of the functional form has predefined values
C<Neaf> (the default), C<LIVR>, and C<Wildcard> (all case-insensitive)
pointing towards L<MVC::Neaf::X::Form>, L<MVC::Neaf::X::Form::LIVR>,
and L<MVC::Neaf::X::Form::Wildcard>, respectively.

You are encouraged to use C<LIVR>
(See L<Validator::LIVR> and L<LIVR grammar|https://github.com/koorchik/LIVR>)
for anything except super-basic regex checks.

If an arbitrary class name is given instead, C<new()> will be called
on that class with \%spec ref as first parameter.

Consider the following script:

    use MVC::Neaf;
    neaf form => my => { foo => '\d+', bar => '[yn]' };
    get '/check' => sub {
        my $req = shift;
        my $in = $req->form("my");
        return $in->is_valid ? { ok => $in->data } : { error => $in->error };
    };
    neaf->run

And by running this one gets

    bash$ curl http://localhost:5000/check?bar=xxx
    {"error":{"bar":"BAD_FORMAT"}}
    bash$ curl http://localhost:5000/check?bar=y
    {"ok":{"bar":"y"}}
    bash$ curl http://localhost:5000/check?bar=yy
    {"error":{"bar":"BAD_FORMAT"}}
    bash$ curl http://localhost:5000/check?foo=137\&bar=n
    {"ok":{"bar":"n","foo":"137"}}
    bash$ curl http://localhost:5000/check?foo=leet
    {"error":{"foo":"BAD_FORMAT"}}

=cut

=head2 set_error_handler()

    $neaf->set_error_handler ( $status => CODEREF( $request, %options ), %where )

Set custom error handler.

Status MUST be a 3-digit number (as in HTTP).

%where may include C<path>, C<method>, and C<exclude> keys.
If omitted, just install error handler globally.

Other allowed keys MAY appear in the future.

The following options will be passed to coderef:

=over

=item * status - status being returned;

=item * caller - file:line where the route was set up;
This is DEPRECATED and will silently disappear around version 0.25

=item * error - exception, an L<MVC::Neaf::Exception> object.

=back

The coderef MUST return an unblessed hash just like a normal controller does.

In case of exception or unexpected return format
default HTML error page will be returned.

Also available in static form, as C<set_error_handler( status =E<gt> \%hash )>.

This is a synonym to C<sub { +{ status =E<gt> $status,  ... } }>.

=cut

=head2 load_resources()

    $neaf->load_resources( $file_name || \*FH )

Load pseudo-files from a file, like templates or static files.
This is automatically called upon C<run> if C<__DATA__> is present,
unless C<neaf-E<gt>magic(0)> was called.

The format is as follows:

    @@ [TT] main.html

    [% some_tt_template %]

    @@ /favicon.ico format=base64 type=png

    iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAAL
    GPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hS<....more encoded lines>

I<This is obviously stolen from L<Mojolicious>,
in a slightly incompatible way.>

If view is specified in brackets, preload template.
A missing view is skipped, no error.

Otherwise file is considered a static resource.

Extra options may follow file name:

=over

=item * C<type=ext | mime/type>

=item * C<format=base64>

=back

Unknown options are skipped.
Unknown format value will cause exception though.

B<[EXPERIMENTAL]> This method and exact format of data is being worked on.

=cut

=head2 magic

    neaf->magic( 0 || 1)
    my $get = neaf->magic

Get/set whether automatic actions should occur.
Currently only affects calling L</load_resources> upon L</run>.

=head2 set_helper

    neaf helper "name" => sub { ... }, %options;

    neaf->set_helper( "name" => \&coderef, ... );

Create a method in L<MVC::Neaf::Request> package that is only visible
in the current application.

Options may include:

=over

=item * path => C<[ '/foo', '/bar' ]> - restrict the helper
to given prefix(es) only.
Helpers with the same name may be created for different paths.
In such case, longer paths take over as usual.

Colliding prefixes will cause an error, but see below.

=item * method => C<[ 'GET', 'POST' ]> - restrict the helper to given methods only.

=item * exclude => C<[ '/foo/bar' ]> - do NOT provide this helper for
given prefixes.

=item * tentative - allow to override this helper later.

=item * override - override the existing helper, no matter what.

=back

B<[EXPERIMENTAL]>. Name and meaning may change in the future.

=head2 run()

    neaf->run();

Start the application.
This SHOULD be the last statement in your application's main file.

If called in void context, assumes execution as C<CGI>
and prints results to C<STDOUT>.
If command line options are present at the moment,
enters debug mode via L<MVC::Neaf::CLI>.
Call C<perl yourapp.pl --help> for more.

Otherwise returns a C<PSGI>-compliant coderef.
This will also happen if you application is C<require>'d,
meaning that it returns a true value and actually serves nothing until
C<run()> is called again.

Running under mod_perl requires setting a handler with
L<MVC::Neaf::Request::Apache2>.

=cut

=head1 EXPORTED HELPER FUNCTIONS

Neaf tries hard to keep user's namespace clean, however,
some helper functions are needed.

=head2 neaf_err $error

Rethrow Neaf's internal exceptions immediately, do nothing otherwise.

If no argument if given, acts on current C<$@> value.

Currently Neaf uses exception mechanism for internal signalling,
so this function may be of use if there's a lot of C<eval> blocks
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

Or alternatively with L<Try::Tiny>:

    try {
        ...
    } catch {
        neaf_err $_;
        # proceed with normal error handling
    }

See also L<MVC::Neaf::Exception>.

=cut

sub neaf_err(;$) { ## no critic # prototype it for less typing on user's part
    my $err = shift || $@;
    die $err if blessed $err and $err->isa("MVC::Neaf::Exception");
    die $err if !ref $err and $err =~ /^(\d\d\d)\s/s; # die 403
    return;
};

=head2 neaf()

If called without arguments, returns the default C<MVC::Neaf> instance.

If arguments are given, works as described above:

    neaf $action => @options;

Possible actions include:

=over

=item * view - L<load_view>

=item * session - L<set_session_handler>

=item * default - L<set_path_defaults>

=item * helper - L<set_helper>

=item * alias   - L<alias>

=item * static  - L<static>

=item * route - L<add_route>

Don't do this, use C<any> or C<get + post + ...> instead.

=item * hook - L<add_hook>

Don't do this, use phase name instead.

=item * error - L<set_error_handler>

Don't do this, use 3-digit error code instead.

=back

=cut

my %method_shortcut = (
    route    => 'route',
    error    => 'set_error_handler',
    view     => 'load_view',
    hook     => 'add_hook',
    helper   => 'set_helper',
    session  => 'set_session_handler',
    default  => 'set_path_defaults',
    alias    => 'alias',
    static   => 'static',
    form     => 'add_form',
);

sub neaf(@) { ## no critic # DSL
    return $MVC::Neaf::Inst unless @_;

    # If something dies here, it's probably the calling code to blame
    #    and not us
    local $Carp::Internal{+__PACKAGE__} = 1;

    my ($action, @args) = @_;

    if ($action =~ /^\d\d\d$/) {
        unshift @args, $action;
        $action = 'error';
    };
    if ($MVC::Neaf::Route::Main::hook_phases{$action}) {
        unshift @args, $action;
        $action = 'hook';
    };

    if ($action eq 'session') {
        unshift @args, 'engine';
    };

    if ($action eq 'route' ) {
        carp "neaf route is DEPRECATED, use get+post+put instead";
    };

    my $method = $method_shortcut{$action};
    croak "neaf: don't know how to handle '$action'"
        unless $method and MVC::Neaf->can($method);

    return $MVC::Neaf::Inst->$method( @args );
};

# Generate alias subs
my @ALL_METHODS = qw( get head post put patch delete );
my %ALIAS;
$ALIAS{$_} = uc $_ for @ALL_METHODS;
$ALIAS{del} = delete $ALIAS{delete}; # ouch, no delete '/foo' => bar
$ALIAS{any} = \@ALL_METHODS;

foreach (keys %ALIAS) {
    my $method = $ALIAS{$_};
    my $is_any = $_ eq 'any';

    my $code = sub(@) { ## no critic
        # any
        if ($is_any and ref $_[0] eq 'ARRAY') {
            $method = shift;
        } elsif (@_ == 1 and UNIVERSAL::isa( $_[0], __PACKAGE__ )) {
            # get + post sugar
            return $_[0]->_dup_route( $method );
        };

        # normal operation
        my $path = shift;
        my $handler = ref $_[0] && reftype $_[0] eq 'CODE' ? shift : pop;

        return neaf()->add_route(
            $path, $handler, @_, method => $method, caller => [caller(0)] );
    };

    push @EXPORT_SUGAR, $_;
    no strict 'refs'; ## no critic
    *{$_} = $code;
};
push @EXPORT, @EXPORT_SUGAR;

=pod

=head1 DEVELOPMENT AND DEBUGGING METHODS

No more prototyped/exported functions below here.

=head2 run_test()

    neaf->run_test( \%PSGI_ENV, %options )

    neaf->run_test( "/path?parameter=value", %options )

Run a L<PSGI> request and return a list of
C<($status, HTTP::Headers::Fast, $whole_content )>.

Returns just the content in scalar context.

Just as the name suggests, useful for testing only (it reduces boilerplate).

Continuation responses are supported, but will be returned in one chunk.

%options may include:

=over

=item * method - set method (default is GET)

=item * cookie = \%hash - force HTTP_COOKIE header

=item * header = \%hash - override some headers
This gets overridden by type, cookie etc. in case of conflict

=item * body = 'DATA' - force body in request

=item * type - content-type of body

=item * uploads - a hash of L<MVC::Neaf::Upload> objects.

=item * secure = 0|1 - C<http> vs C<https>

=item * override = \%hash - force certain data in C<ENV>
Gets overridden by all of the above.

=back

See also L<Plack::Test> which author of this writing has overlooked.

=cut

=head2 get_routes()

    neaf->get_routes( $callback->(\%route_spec, $path, $method) )

Returns a 2-level hashref with ALL routes for inspection.

So C<$hash{'/path'}{'GET'} = { handler, expected params, description etc }>

If callback is present, run it against route definition
and append to hash its return value, but ONLY if it's true.

As of 0.20, route definitions are only protected by shallow copy,
so be careful with them.

B<[EXPERIMENTAL]>. Name and meaning MAY change in the future.

=cut

# Setup default instance, no more code after this
# aside from deprecated methods
$Inst = __PACKAGE__->new;

=head1 REQUEST PROCESSING PHASES AND HOOKS

Hooks are subroutines executed during various phases of request processing.
Each hook is characterized by phase, code to be executed, path, and method.
Multiple hooks MAY be added for the same phase/path/method combination.
ALL hooks matching a given route will be executed, either short to long or
long to short (aka "event bubbling"), depending on the phase.

B<[CAUTION]> Don't overuse hooks.
This may lead to a convoluted, hard to follow application.
Use hooks for repeated auxiliary tasks such as checking permissions or writing
down statistics, NOT for primary application logic.

Hook return values are discarded, and deliberately so.
I<In absence of an explicit return,
Perl will interpret the last statement in the code as such.
Therefore writers of hooks would have to be extremely careful to avoid
breaking the execution chain.
On the other hand, proper exception handling is required anyway for
implementing any kind of callbacks.>

As a rule of thumb, the following primitives should be used to maintain
state across hooks and the main controller:

=over

=item * Use C<session> if you intend to share data between requests.

=item * Use C<reply> if you intend to render the data for the user.

=item * Use C<stash> as a last resort for temporary, private data.

=back

The following list of phases MAY change in the future.
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

=head2 pre_route

Executed AFTER the request has been received, but BEFORE the path has been
resolved and handler found.

Dying in this phase stops both further hook processing and controller execution.
Instead, the corresponding error handler is executed right away.

Options C<path> and C<exclude> are not available on this stage.

May be useful for mangling path.
Use C<$request-E<gt>set_path($new_path)> if you need to.

=head2 pre_logic

Executed AFTER finding the correct route, but BEFORE processing the main
handler code (one that returns C<\%hash>, see C<route> above).

Hooks are executed in order, shorted paths to longer.
C<reply> is not available at this stage,
as the controller has not been executed yet.

Dying in this phase stops both further hook processing and controller execution.
Instead, the corresponding error handler is executed right away.

B<[EXAMPLE]> use this hook to produce a 403 error if the user is not logged in
and looking for a restricted area of the site:

    neaf pre_logic => sub {
        my $request = shift;
        $request->session->{user_id} or die 403;
    }, path => '/admin', exclude => '/admin/static';

=head2 pre_content

This hook is run AFTER the main handler has returned or died, but BEFORE
content rendering/serialization is performed.

C<reply()> hash is available at this stage.

Dying is ignored, only producing a warning.

=head2 pre_render

This hook is run BEFORE content rendering is performed, and ONLY IF
the content is going to be rendered,
i.e. no C<-content> key set in response hash on previous stages.

Dying will stop rendering, resulting in a template error instead.

=head2 pre_reply

This hook is run AFTER the headers have been generated, but BEFORE the reply is
actually sent to client. This is the last chance to amend something.

Hooks are executed in REVERSE order, from longer to shorter paths.

C<reply()> hash is available at this stage.

Dying is ignored, only producing a warning.

=head2 pre_cleanup

This hook is run AFTER all postponed actions set up in controller
(via C<-continue> etc), but BEFORE the request object is actually destroyed.
This can be useful to free some resource or write statistics.

The client connection MAY be closed at this point and SHOULD NOT be relied upon.

Hooks are executed in REVERSE order, from longer to shorter paths.

Dying is ignored, only producing a warning.

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

    neaf->run;

=head2 Static content

    neaf->static( '/images' => "/local/images" );
    neaf->static( '/favicon.ico' => "/local/images/icon_32x32.png" );
    neaf->static( '/robots.txt' => [ "Disallow: *\n", "text/plain "] );

=head2 Form submission

    # You're still encouraged to use LIVR for more detailed validation
    my %profile = (
        name => [ required => '\w+' ],
        age  => '\d+',
    );
    neaf form my_form => \%profile;

    get+post '/submit' => sub {
        my $req = shift;

        my $form = $req->form( "my_form" );
        if ($req->is_post and $form->is_valid) {
            my $id = do_something( $form->data );
            $req->redirect( "/result/$id" );
        };

        return {
            -template   => 'form.tt',
            errors      => $form->error,
            fill_values => $form->raw,
        };
    };

=head2 Adding JSONP callbacks

    neaf pre_render => sub {
        my $req = shift;
        $req->reply->{-jsonp} = $req->param("callback" => '.*');
        # Even if you put no restriction here, no XSS comes through
        #    as JS View has its own default filter
    }, path => '/js/api';

More examples to follow as usage (hopefully) accumulates.

=head1 FOUNDATIONS OF NEAF

=over

=item * Data in, data out.

A I<function> should receive an I<argument> and return a I<value> or I<die>.
Everything else should be confined within the function.
This applies to both Neaf's own methods and the user code.

A notable exception is the session mechanism which is naturally stateful
and thus hard to implement in functional style.

=item * Sane defaults.

Everything can be configured, nothing needs to be.
C<TT> view needs work in this respect.

=item * It's not software unless you can run it.

Don't rely on a specific server environment.
Be ready to run as a standalone program or inside a test script.

=item * Trust nobody.

Validate incoming data.
This is not yet enforced for HTTP headers and body.

=item * Unicode inside the perimeter.

This is not yet implemented (but planned) for body and file uploads
because these may well be binary data.

=back

=head1 BUGS

This software is still in BETA stage.

Test coverage is maintained at >80% currently,
but who knows what lurks in the other 20%.

See the C<TODO> file in this distribution for a vague roadmap.

Please report any bugs or feature requests to
L<https://github.com/dallaylaen/perl-mvc-neaf/issues>.

Alternatively, email them to C<bug-mvc-neaf at rt.cpan.org>, or report through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MVC-Neaf>.

Feedback and/or critique are welcome.

=head1 SUPPORT

Feel free to email the author to get instant help!

You can find documentation for this module with the C<perldoc> command:

    perldoc MVC::Neaf
    perldoc MVC::Neaf::Request

You can also look for information at:

=over

=item * Github: L<https://github.com/dallaylaen/perl-mvc-neaf>

=item * MetaCPAN: L<https://metacpan.org/pod/MVC::Neaf>

=item * C<RT>: CPAN's request tracker (report bugs here)

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

Neaf has a lot of similarities to L<Mojolicious::Lite>,
initially unintentional.

=head1 ACKNOWLEDGEMENTS

Ideas were shamelessly stolen from L<Catalyst>, L<Dancer>, L<PSGI>,
and L<sinatra.rb|http://sinatrarb.com/>.

L<CGI> was used heavily in the beginning of development,
though Neaf was C<PSGI>-ready from the start.

Thanks to L<Eugene Ponizovsky|https://metacpan.org/author/IPH>
for introducing me to the MVC concept.

Thanks to L<Alexander Kuklev|https://github.com/akuklev>
for early feedback and great insights about pure functions and side effects.

Thanks to L<Akzhan Abdullin|https://github.com/akzhan>
for driving me towards proper hooks model.

Thanks to L<Cono|https://github.com/cono>
for early feedback and feature proposals.

Thanks to Alexey Kuznetsov
for requesting REST support and thus
adding of multiple methods for the same path.

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2023 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of MVC::Neaf
