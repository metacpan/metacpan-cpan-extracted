package MVC::Neaf;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.2203;

=head1 NAME

MVC::Neaf - Not Even A (Web Application) Framework

=head1 OVERVIEW

Neaf C<[ni:f]> stands for Not Even A Framework.

The B<Model> is assumed to be just a regular Perl module,
no restrictions are imposed on it.

The B<View> is an object with one method, C<render>, receiving a hashref
and returning rendered content as string plus optional content-type header.

The B<Controller> is broken down into handlers associated with URI paths.
Each such handler receives a L<MVC::Neaf::Request> object
containing I<all> it needs to know about the outside world,
and returns a simple C<\%hashref> which is forwarded to View.

Please see the C<example> directory in this distribution
that demonstrates the features of Neaf.

=head1 SYNOPSIS

The following application, outputting a greeting, is ready to run
as a L<CGI> script, L<PSGI> application, or Apache handler.

    use strict;
    use warnings;
    use MVC::Neaf qw(:sugar);

    get+post '/app' => sub {
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

Handlers are set using the L</route> method discussed below.

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
    $req->script_name ; # = /mathing/route
    $req->path_info   ; # = /some/more/slashes

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

=item * -serial - if present, the C<JS> view will render this instead of
the whole response hash.
This can be used, for instance, to return non-hash data in a REST API.

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

A C<:sugar> keyword must be added to the C<use> statement
to get access to the prototyped declarative API.
The need to do so MAY be removed in the future.

All prototyped declarative functions described below
are really frontends to a single L<MVC::Neaf> object
that accumulates the knowledge about your application.

Though more than one such objects can be created,
there is little use in doing that so far.

Given the above, functional and object-oriented ways
to declare the same thing will now follow in pairs.

Returned value, if unspecified, is always the Neaf object
(but who cares).

=head2 neaf()

Without arguments, returns the default Neaf instance
that is also used to handle all the prototyped calls.
As in

    neaf->oo_method_without_shortcut(...);

Just in case you're curious, the default instance is C<$MVC::Neaf::Inst>.
This name MAY change in the future.

See complete description below.

=cut

use Carp;
use Encode;
use HTTP::Headers::Fast;
use MIME::Base64;
use Module::Load;
use Scalar::Util qw(blessed looks_like_number);
use URI::Escape;
use parent qw(Exporter);

our @EXPORT_OK = qw( neaf_err );
my  @EXPORT_SUGAR = qw( neaf ); # Will populate later - see @ALL_METHODS below
our %EXPORT_TAGS = (
    sugar => \@EXPORT_SUGAR,
);

use MVC::Neaf::Util qw(http_date canonize_path path_prefixes run_all run_all_nodie);
use MVC::Neaf::Request::PSGI;
use MVC::Neaf::Exception;

our $Inst;

my %FORM_ENGINE = (
    neaf     => 'MVC::Neaf::X::Form',
    livr     => 'MVC::Neaf::X::Form::LIRV',
    wildcard => 'MVC::Neaf::X::Form::Wildcard',
);

=head2 route()

The route() function and its numerous aliases define a handler
for given by URI path and HTTP method(s).

=over

=item * $neaf->route( '/path' => CODEREF, %options )

=item * get '/path' => sub { CODE; }, %options;

I<Equivalent> to

    neaf->route( '/path' => sub { CODE; }, method => 'GET', %options );

=item * post '/path' => sub { CODE; }, %options;

Ditto, but sets method => 'POST'

=item * head ... - autogenerated by C<get>,
but can be specified explicitly if needed

=item * put ...

=item * patch ...

=item * del ... is for C<DELETE> (because C<delete> is a Perl's own keyword).

=item * any [ 'get', 'post', 'CUSTOM_METHOD' ] => '/path' => \&handler

=back

Short aliases can be combined using the C<+> sign, as in

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
as C<$req-E<gt>path_info>.

If capture groups are present in said regular expression,
their content will also be available as C<$req-E<gt>path_info_split>.

B<[EXPERIMENTAL]> Name and semantics MAY change in the future.

=item * C<param_regex> => { name => C<qr/.../>, name2 => C<'\d+'> }

Add predefined regular expression validation to certain request parameters,
so that they can be queried by name only.
See C<param()> in L<MVC::Neaf::Request>.

B<[EXPERIMENTAL]> Name and semantics MAY change in the future.

=item * C<view> - default View object for this Controller.
Must be a name of preloaded view,
an object with a C<render> method, or a CODEREF
receiving hashref and returning a list of two scalars
(content and content-type).

B<[DEPRECATED]> Use C<-view> instead, meaning is exactly the same.

=item * C<cache_ttl> - if set, set Expires: HTTP header accordingly.

B<[EXPERIMENTAL]> Name and semantics MAY change in the future.

=item * C<default> - a C<\%hash> of values that will be added to results
EVERY time the handler returns.
Consider using C<neaf default ...> below if you need to append
the same values to multiple paths.

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

B<[NOTE]> For some reason ability to add multicomponent paths
like C<(foo =E<gt> bar =E<gt> \&code)> was added in the past,
resulting in C<"/foo/bar" =E<gt> \&code>.

It was never documented, will issue a warning, and will be removed for good
it v.0.25.

=cut

my $year = 365 * 24 * 60 * 60;
my %known_route_args;
$known_route_args{$_}++ for qw(
    default method view cache_ttl
    path_info_regex param_regex
    description caller tentative override public
);

sub route {
    my $self = shift;

    # TODO 0.25 kill this for good, just
    #     my ($path, $sub, %args) = @_;
    # HACK!! pack path components together, i.e.
    # foo => bar => \&handle eq "/foo/bar" => \&handle
    carp "NEAF: using multi-component path in route() is DEPRECATED and is to be removed in v.0.25"
        unless ref $_[1];
    my ( $path, $sub );
    while ($sub = shift) {
        last if ref $sub;
        $path .= "/$sub";
    };
    $self->_croak( "Odd number of elements in hash assignment" )
        if @_ % 2;
    my (%args) = @_;
    $self = $Inst unless ref $self;

    $self->_croak( "handler must be a coderef, not ".ref $sub )
        unless UNIVERSAL::isa( $sub, "CODE" );

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

    $args{path} = $path = canonize_path( $path );

    _listify( \$args{method}, qw( GET POST ) );
    $_ = uc $_ for @{ $args{method} };

    $self->_croak("Public endpoint must have nonempty description")
        if $args{public} and not $args{description};

    $self->_detect_duplicate( \%args );

    # Do the work
    my %profile;
    $profile{code}      = $sub;
    $profile{tentative} = $args{tentative};
    $profile{override}  = $args{override};

    # Always have regex defined to simplify routing
    $profile{path_info_regex} = (defined $args{path_info_regex})
        ? qr#^$args{path_info_regex}$#
        : qr#^$#;

    # Just for information
    $profile{path}        = $path;
    $profile{description} = $args{description};
    $profile{public}      = $args{public} ? 1 : 0;
    $profile{caller}      = $args{caller} || [caller(0)]; # save file,line
    $profile{where}       = "at $profile{caller}[1] line $profile{caller}[2]";

    if (my $view = $args{view}) {
        carp "NEAF: route(): view argument is deprecated, use -view instead";
        $args{default}{-view} = $view;
    };

    # preload view so that we can fail early
    $args{default}{-view} = $self->get_view( $args{default}{-view} )
        if $args{default}{-view};

    # todo_default because some path-based defs will be mixed in later
    $profile{todo_default} = $args{default}
        if $args{default};

    # preprocess regular expression for params
    if ( my $reg = $args{param_regex} ) {
        my %real_reg;
        $self->_croak("param_regex must be a hash of regular expressions")
            if ref $reg ne 'HASH' or grep { !defined $reg->{$_} } keys %$reg;
        $real_reg{$_} = qr(^$reg->{$_}$)s
            for keys %$reg;
        $profile{param_regex} = \%real_reg;
    };

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
# TODO 0.90 merge with alias, GET => implicit HEAD
sub _dup_route {
    my ($self, $method, $profile) = @_;

    $profile ||= $self->{last_added};
    my $path = $profile->{path};

    $self->_detect_duplicate($profile);

    delete $self->{route_re};
    $self->{route}{ $path }{$method} = { %$profile, my_method => $method };
};

# in: { method => [...], path => '/...', tentative => 0|1, override=> 0|1 }
# out: none
# spoils $method if tentative
# dies/warns if violations found
sub _detect_duplicate {
    my ($self, $profile) = @_;

    my $path = $profile->{path};
    # Handle duplicate route definitions
    my @dupe = grep {
        exists $self->{route}{$path}{$_}
        and !$self->{route}{$path}{$_}{tentative};
    } @{ $profile->{method} };

    if (@dupe) {
        my %olddef;
        foreach (@dupe) {
            my $where = $self->{route}{$path}{$_}{where};
            push @{ $olddef{$where} }, $_;
        };

        # flatten olddef hash, format list
        my $oldwhere = join ", ", map { "$_ [@{ $olddef{$_} }]" } keys %olddef;
        my $oldpath = $path || '/';

        # Alas, must do error message by hand
        my $caller = [caller 1]->[3];
        $caller =~ s/.*:://;
        if ($profile->{override}) {
            carp( (ref $self)."->$caller: Overriding old handler for"
                ." $oldpath defined $oldwhere");
        } elsif( $profile->{tentative} ) {
            # just skip duplicate methods
            my %filter;
            $filter{$_}++ for @{ $profile->{method} };
            delete $filter{$_} for @dupe;
            $profile->{method} = [keys %filter];
        } else {
            croak( (ref $self)."->$caller: Attempting to set duplicate handler for"
                ." $oldpath defined $oldwhere");
        };
    };
};

=head2 static()

=over

=item * neaf static => '/path' => $local_path, %options;

=item * neaf static => '/other/path' => [ "content", "content-type" ];

=item * $neaf->static( $req_path => $file_path, %options )

=back

Serve static content located under C<$file_path>.
Both directories and single files may be added.

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

See L<MVC::Meaf::X::Files> for implementation.

File type detection is based on extentions so far, and the list is quite short.
This MAY change in the future.
Known file types are listed in C<%MVC::Neaf::X::Files::ExtType> hash.
Patches welcome.

I<It is probably a bad idea to serve files in production
using a web application framework.
Use a real web server instead.
Not need to set up one for merely testing icons/js/css, though.>

=cut

sub static {
    my ($self, $path, $dir, %options) = @_;
    $self = $Inst unless ref $self;

    $options{caller} ||= [caller 0];

    my %fwd_opt;
    defined $options{$_} and $fwd_opt{$_} = delete $options{$_}
        for qw( tentative override caller public );

    if (ref $dir eq 'ARRAY') {
        my $sub = $self->_static_global->preload( $path => $dir )->one_file_handler;
        return $self->route( $path => $sub, method => 'GET', %fwd_opt,
            , description => Carp::shortmess( "Static content from memory" ));
    };

    require MVC::Neaf::X::Files;
    my $xfiles = MVC::Neaf::X::Files->new(
        %options, root => $dir, base_url => $path );
    return $self->route( $xfiles->make_route, %fwd_opt );
};

=head2 set_path_defaults()

=over

=item * neaf default => '/path' => \%values;

=item * $neaf->set_path_defaults ( '/path' => \%values );

=back

Use given values as defaults for ANY handler below given path.
A value of '/' means global.

Longer paths override shorter ones;
route-specific defaults override path-base defaults;
explicit values returned from handler override all or the above.

For example,

    neaf default '/api' => { view => 'JS', version => My::Model->VERSION };

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

=head2 add_hook()

=over

=item * neaf "phase" => sub { ... }, path => [ ... ], exclude => [ ... ];

=item * $neaf->add_hook ( phase => CODEREF, %options );

=back

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

my %add_hook_args;
$add_hook_args{$_}++ for qw(method path exclude prepend);

my %hook_phases;
$hook_phases{$_}++ for qw(pre_route
    pre_logic pre_content pre_render pre_reply pre_cleanup);

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

# TODO 0.90 util?
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

=head2 alias()

=over

=item * neaf alias $newpath => $oldpath

=item * $neaf->alias( $newpath => $oldpath )

=back

Create a new name for already registered route.
The handler will be executed as is,
but the hooks and defaults will be re-calculated.
So be careful.

B<[CAUTION]> As of 0.21, C<alias> does NOT follow tentative/override switches.
This needs to be fixed in the future.

=cut

sub alias {
    my ($self, $new, $old) = @_;
    $self = $Inst unless ref $self;

    $new = canonize_path( $new );
    $old = canonize_path( $old );

    $self->{route}{$old}
        or $self->_croak( "Cannot create alias for unknown route $old" );

    # TODO 0.30 restrict methods, handle tentative/override, detect dupes
    $self->_croak( "Attempting to set duplicate handler for path "
        .( length $new ? $new : "/" ) )
            if $self->{route}{ $new };

    # reset cache
    $self->{route_re} = undef;

    $self->{route}{$new} = $self->{route}{$old};
    return $self;
};

=head2 load_view()

=over

=item * neaf view => 'name' => 'Driver::Class' => %options;

=item * $neaf->load_view( $name, $object || coderef || ($module_name, %options) )

=back

Setup view under name C<$name>.
Subsequent requests with C<-view = $name> would be processed by that view
object.

Use C<get_view> to fetch the object itself.

=over

=item * if object is given, just save it.

=item * if module name + parameters is given, try to load module
and create new() instance.

Short aliases C<JS>, C<TT>, and C<Dumper> may be used
for corresponding C<MVC::Neaf::View::*> modules.

=item * if coderef is given, use it as a C<render> method.

=back

Returns the view object, NOT the calling Neaf object.

=cut

my %view_alias = (
    TT     => 'MVC::Neaf::View::TT',
    JS     => 'MVC::Neaf::View::JS',
    Dumper => 'MVC::Neaf::View::Dumper',
);
sub load_view {
    my ($self, $name, $obj, @param) = @_;
    $self = $Inst unless ref $self;

    $self->_croak("At least two arguments required")
        unless defined $name and defined $obj;

    # Instantiate if needed
    if (!ref $obj) {
        # in case an alias is used, apply alias
        $obj = $view_alias{ $obj } || $obj;

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

    $self->{seen_view}{$name} = $obj;

    return $obj;
};

=head2 set_session_handler()

=over

=item * neaf session => $engine => %options

=item * $neaf->set_session_handler( %options )

=back

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

=head2 add_form()

=over

=item * neaf form => name => \%spec, engine => ...

=item * add_form( name => $validator )

=back

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

    use MVC::Neaf qw(:sugar);
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

sub add_form {
    my ($self, $name, $spec, %opt) = @_;

    $name and $spec
        or $self->_croak( "Form name and spec must be nonempty" );
    exists $self->{forms}{$name}
        and $self->_croak( "Form $name redefined" );

    if (!blessed $spec) {
        my $eng = delete $opt{engine} || 'MVC::Neaf::X::Form';
        $eng = $FORM_ENGINE{ lc $eng } || $eng;

        if (!$eng->can("new")) {
            eval { load $eng; 1 }
                or $self->_croak( "Failed to load form engine $eng: $@" );
        };

        $spec = $eng->new( $spec, %opt );
    };

    $self->{forms}{$name} = $spec;
    return $self;
};

=head2 set_error_handler()

=over

=item * neaf 403 => sub { ... }

=item * $neaf->set_error_handler ( $status => CODEREF( $request, %options ) )

=back

Set custom error handler.

Status must be a 3-digit number (as in HTTP).
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
default JSON-based error will be returned.

Also available as C<set_error_handler( status =E<gt> \%hash )>.

This is a synonym to C<sub { +{ status =E<gt> $status,  ... } }>.

=cut

sub set_error_handler {
    my ($self, $status, $code) = @_;
    $self = $Inst unless ref $self;

    $status =~ /^(?:\d\d\d)$/
        or $self->_croak( "1st arg must be http status");
    if (ref $code eq 'HASH') {
        my $hash = $code;
        $code = sub {
            my ($req, %opt) = @_;

            return { -status => $opt{status}, %opt, %$hash };
        };
    };
    UNIVERSAL::isa($code, 'CODE')
        or $self->_croak( "2nd arg must be callback or hash");

    $self->{error_template}{$status} = $code;

    return $self;
};

=head2 on_error()

=over

=item * $neaf->on_error( sub { my ($request, $error) = @_ } )

=back

Install custom error handler for a dying controller.
Neaf's own exceptions, redirects, and C<die \d\d\d> status returns will NOT
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

=head2 load_resources()

=over

=item * $neaf->load_resources( $file_name || \*FH )

=back

Load pseudo-files from a file, like templates or static files.

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

my $INLINE_SPEC = qr/^(?:\[(\w+)\]\s+)?(\S+)((?:\s+\w+=\S+)*)$/;
sub load_resources {
    my ($self, $file) = @_;

    my $fd;
    if (ref $file) {
        $fd = $file;
    } else {
        open $fd, "<", $file
            or $self->_croak( "Failed to open(r) $file: $!" );
    };

    local $/;
    my $content = <$fd>;
    defined $content
        or $self->_croak( "Failed to read from $file: $!" );

    my @parts = split /^@@\s+(.*\S)\s*$/m, $content, -1;
    shift @parts;
    die "Something went wrong" if @parts % 2;

    my %templates;
    my %static;
    while (@parts) {
        # parse file
        my $spec = shift @parts;
        my ($dest, $name, $extra) = ($spec =~ $INLINE_SPEC);
        my %opt = $extra =~ /(\w+)=(\S+)/g;
        $name or $self->_croak("Bad resource spec format @@ $spec");

        my $content = shift @parts;
        if (!$opt{format}) {
            $content =~ s/^\n+//s;
            $content =~ s/\s+$//s;
            $content = Encode::decode_utf8( $content, 1 );
        } elsif ($opt{format} eq 'base64') {
            $content = decode_base64( $content );
        } else {
            $self->_croak("Unknown format $opt{format} in '@@ $spec' in $file");
        };

        if ($dest) {
            # template
            $self->_croak("Duplicate template '@@ $spec' in $file")
                if defined $templates{lc $dest}{$name};
            $templates{$dest}{$name} = $content;
        } else {
            # static file
            $self->_croak("Duplicate static file '@@ $spec' in $file")
                if $static{$name};
            $static{$name} = [ $content, $opt{type} ];
        };
    };

    # now do the loading
    foreach my $name( keys %templates ) {
        my $view = $self->get_view( $name, 1 ) or next;
        $view->can("preload") or next; # TODO 0.30 warn here?
        $view->preload( %{ $templates{$name} } );
    };
    if( %static ) {
        require MVC::Neaf::X::Files;
        my $st = $self->_static_global;
        $st->preload( %static );
        foreach( keys %static ) {
            $self->route( $_ => $st->one_file_handler, method => 'GET'
                , description => "Static resource from $file" );
        };
    };

    return $self;
};

# TODO 0.30 lame name, find better
sub _static_global {
    my $self = shift;

    return $self->{global_static} ||= do {
        require MVC::Neaf::X::Files;
        MVC::Neaf::X::Files->new( root => '/dev/null' );
    };
};

=head2 run()

=over

=item * neaf->run;

=item * $neaf->run();

=back

Run the application.
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

sub run {
    my $self = shift;
    $self = $Inst unless ref $self;

    if (!defined wantarray) {
        # void context - we're being called as CGI
        if (@ARGV) {
            require MVC::Neaf::CLI;
            MVC::Neaf::CLI->run($self);
        } else {
            require Plack::Handler::CGI;
            # Somehow this caused uninitialized warning in Plack::Handler::CGI
            $ENV{SCRIPT_NAME} = ''
                unless defined $ENV{SCRIPT_NAME};
            Plack::Handler::CGI->new->run( $self->run );
        };
    };

    $self->{route_re} ||= $self->_make_route_re;

    # Add implicit HEAD for all GETs via shallow copy
    foreach my $node (values %{ $self->{route} }) {
        $node->{GET} or next;
        $node->{HEAD} ||= { %{ $node->{GET} }, my_method => 'HEAD' };
    };

    # initialize stuff if first run
    # TODO 0.30 don't allow modification after lock
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
            # TODO 0.25 remove for good
            $self->add_hook( pre_route => sub {
                $engine->record_start;
            }, prepend => 1);
            $self->add_hook( pre_content => sub {
                $engine->record_controller( $_[0]->script_name );
            }, prepend => 1);
            # Should've switched to pre_cleanup, but we cannot
            # guarrantee another request doesn't get mixed in
            # in the meantime, as X::ServerStat is sequential.
            $self->add_hook( pre_reply => sub {
                $engine->record_finish($_[0]->reply->{-status}, $_[0]);
            }, prepend => 1);
        };
    };

    return sub {
        $self->handle_request(
            MVC::Neaf::Request::PSGI->new( env => $_[0], _neaf => $self ));
    };
};

sub _make_route_re {
    my ($self, $hash) = @_;

    $hash ||= $self->{route};

    my $re = join "|", map { quotemeta } reverse sort keys %$hash;

    # make $1, $2 always defined
    # split into (/foo/bar)/(baz)?param=value
    return qr{^($re)(?:/*([^?]*)?)(?:\?|$)};
};


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

=head2 neaf action => @options;

Forward C<@options> to the underlying method of the default instance.
Possible actions include:

=over

=item * view - C<load_view>

=item * session - C<set_session_handler>

=item * default - C<set_path_defaults>

=item * alias   - C<alias>

=item * static  - C<static>

=item * route - C<route>

Don't do this, use C<any> or C<get + post + ...> instead.

=item * hook - C<add_hook>

Don't do this, use phase name instead.

=item * error - C<set_error_handler>

Don't do this, use 3-digit error code instead.

=back

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
    if ($hook_phases{$action}) {
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
        my ($path, $handler, @args) = @_;

        return $Inst->route(
            $path, $handler, @args, method => $method, caller => [caller(0)] );
    };

    push @EXPORT_SUGAR, $_;
    no strict 'refs'; ## no critic
    *{$_} = $code;
};
push @EXPORT_OK, @EXPORT_SUGAR;

=pod

=head1 DEVELOPMENT AND DEBUGGING METHODS

No more prototyped/exported functions below here.

=head2 run_test()

=over

=item * $neaf->run_test( \%PSGI_ENV, %options )

=item * $neaf->run_test( "/path?parameter=value", %options )

=back

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

=cut

my %run_test_allow;
$run_test_allow{$_}++
    for qw( type method cookie body override secure uploads header );
sub run_test {
    my ($self, $env, %opt) = @_;

    my @extra = grep { !$run_test_allow{$_} } keys %opt;
    $self->_croak( "Extra keys @extra" )
        if @extra;

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
            'psgi.version' => [1,1],
            'psgi.errors' => \*STDERR,
        }
    };
    # TODO 0.30 complete emulation of everything a sane person needs
    $env->{REQUEST_METHOD} = $opt{method} if $opt{method};
    $env->{$_} = $opt{override}{$_} for keys %{ $opt{override} };

    if (my $head = $opt{header} ) {
        foreach (keys %$head) {
            my $name = uc $_;
            $name =~ tr/-/_/;
            $env->{"HTTP_$name"} = $head->{$_};
        };
    };
    if (exists $opt{secure}) {
        $env->{'psgi.url_scheme'} = $opt{secure} ? 'https' : 'http';
    };
    if (my $cook = $opt{cookie}) {
        if (ref $cook eq 'HASH') {
            $cook = join '; ', map {
                uri_escape_utf8($_).'='.uri_escape_utf8($cook->{$_})
            } keys %$cook;
        };
        $env->{HTTP_COOKIE} = $env->{HTTP_COOKIE}
            ? "$env->{HTTP_COOKIE}; $cook"
            : $cook;
    };
    if (my $body = $opt{body} ) {
        open my $dummy, "<", \$body
            or die ("NEAF: FATAL: Redirect failed in run_test");
        $env->{'psgi.input'} = $dummy;
        $env->{CONTENT_LENGTH} = length $body;
    };
    if (my $type = $opt{type}) {
        $type = 'application/x-www-form-urlencoded' if $type eq '?';
        $env->{CONTENT_TYPE} = $opt{type} eq '?' ? '' : $opt{type}
    };

    my %fake;
    $fake{uploads} = delete $opt{uploads};

    scalar $self->run; # warm up caches

    my $req = MVC::Neaf::Request::PSGI->new( %fake, env => $env, _neaf => $self );

    my $ret = $self->handle_request( $req );
    if (ref $ret eq 'CODE') {
        # PSGI functional interface used.
        require MVC::Neaf::Request::FakeWriter;
        $ret = MVC::Neaf::Request::FakeWriter->new->respond( $ret );
    };

    return (
        $ret->[0],
        HTTP::Headers::Fast->new( @{ $ret->[1] } ),
        join '', @{ $ret->[2] },
    );
};

=head2 get_routes()

=over

=item * $neaf->get_routes( $callback->(\%route_spec, $path, $method) )

=back

Returns a 2-level hashref with ALL routes for inspection.

So C<$hash{'/path'}{'GET'} = { handler, expected params, description etc }>

If callback is present, run it against route definition
and append to hash its return value, but ONLY if it's true.

As of 0.20, route definitions are only protected by shallow copy,
so be careful with them.

This SHOULD NOT be used by application itself.

=cut

sub get_routes {
    my ($self, $code) = @_;
    $self = $Inst unless ref $self;

    $code ||= sub { $_[0] };
    scalar $self->run; # burn caches

    # TODO 0.30 must do deeper copying
    my $all = $self->{route};
    my %ret;
    foreach my $path ( keys %$all ) {
        my $batch = $all->{$path};
        foreach my $method ( keys %$batch ) {
            my $route = $batch->{$method};
            $self->_post_setup( $route )
                unless $route->{lock};

            my $filtered = $code->( { %$route }, $path, $method );
            $ret{$path}{$method} = $filtered if $filtered;
        };
    };

    return \%ret;
};

=head2 set_forced_view()

=over

=item * $neaf->set_forced_view( $view )

=back

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

=head1 INTERNAL METHODS

B<CAVEAT EMPTOR.>

The following methods are generally not to be used,
unless you want something very strange.

=head2 new()

=over

=item * MVC::Neaf->new(%options)

=back

Constructor. Usually, instantiating Neaf is not required.
But it's possible.

Options are not checked whatsoever.

=cut

sub new {
    my ($class, %opt) = @_;

    my $force = delete $opt{force_view};

    my $self = bless \%opt, $class;

    $self->set_forced_view( $force )
        if $force;

    # TODO 0.20 set default (-view => JS)
    $self->set_path_defaults( '/' => { -status => 200 } );

    return $self;
};

=head2 handle_request()

=over

=item * $neaf->handle_request( MVC::Neaf::Request->new )

=back

This is the CORE of this module.
Should not be called directly - use C<run()> instead.

C<handle_request> really boils down to

    my ($self, $req) = @_;

    my $req->path =~ /($self->{GIANT_ROUTING_RE})/
        or die 404;

    my $route = $self->{ROUTES}{$1}{ $req->method }
        or die 405;

    my $reply_hash = $route->{CODE}->($req);

    my $content = $reply_hash->{-view}->render( $reply_hash );

    return [ $reply_hash->{-status}, [...], [ $content ] ];

The rest 200+ lines of it, split into 4 separate private functions,
are running callbacks, handling corner cases, and substituting sane defaults.

=cut

# sub handle_request is now split into four separate "procedures",
# but it is still a 200-line method by nature.

# In:   request
# Out:  $route + $data
# Side: request modified - {reply} added
sub _route_request {
    my ($self, $req) = @_;

    my $route;
    my $data = eval {
        my $method = $req->method;
        # Try running the pre-routing callback.
        run_all( $self->{pre_route}{$method}, $req )
            if (exists $self->{pre_route}{$method});

        # Lookup the rules for the given path
        $req->path =~ $self->{route_re} and my $node = $self->{route}{$1}
            or die "404\n";
        my ($path, $path_info) = ($1, $2);
        unless ($route = $node->{ $method }) {
            $req->set_header( Allow => join ", ", keys %$node );
            die "405\n";
        };
        $self->_post_setup( $route )
            unless exists $route->{lock};

        # TODO 0.90 optimize this or do smth. Still MUST keep route_re a prefix tree
        if ($path_info =~ /%/) {
            $path_info = decode_utf8( uri_unescape( $path_info ) );
        };
        my @split = $path_info =~ $route->{path_info_regex}
            or die "404\n";
        $req->_import_route( $route, $path, $path_info, \@split );

        # execute hooks
        run_all( $route->{hooks}{pre_logic}, $req)
            if exists $route->{hooks}{pre_logic};
        # Run the controller!
        return $route->{code}->($req);
    };

    if ($data and UNIVERSAL::isa($data, 'HASH')) {
        # post-process data - fill in request(RD) & global(GD) defaults.
        my $GD = $route->{default};
        exists $data->{$_} or $data->{$_} = $GD->{$_} for keys %$GD;
    } elsif( $@ ) {
        # Fall back to error page
        # TODO 0.90 $req->clear; - but don't kill cleanup hooks
        $data = $self->_error_to_reply( $req, $@ );
    } else {
        # controller returned garbage
        # so prevent dying with criptic error message
        $data = $self->_error_to_reply(
            $req, "Returned value is a ".(ref $data || 'SCALAR').
            ", not a HASH at ". $req->endpoint_origin
        );
    };

    if (my $append = $data->{-headers}) {
        if (ref $append eq 'ARRAY') {
            my $head = $req->header_out;
            for (my $i = 0; $i < @$append; $i+=2) {
                $head->push_header($append->[$i], $append->[$i+1]);
            };
        }
        else {
            # Would love to die, but it's impossible here
            $req->log_error("-headers must be ARRAY, not ".(ref $append)
                ." at ".$req->endpoint_origin);
        };
    };

    $req->_set_reply( $data );
    if (exists $route->{hooks}{pre_content}) {
        run_all_nodie( $route->{hooks}{pre_content}, sub {
                $req->log_error( "pre_content hook failed: $@" )
        }, $req );
    };

    return ($route, $data);
}; # end _route_request

# In: $route, $req
# Out: $content
# side: $req->reply modified
sub _render_content {
    my ($self, $route, $req) = @_;

    my $data = $req->reply;
    my $content;
        # TODO 0.20 remove, set default( -view => JS ) instead
        if (!$data->{-view}) {
            if ($data->{-template}) {
                $data->{-view} = 'TT';
                warn $req->_message( "default -view=TT is DEPRECATED, will switch to JS in 0.20" );
            } else {
                $data->{-view} = 'JS';
            };
        };

        my $view = $self->get_view( $data->{-view} );
        eval {
            run_all( $route->{hooks}{pre_render}, $req )
                if exists $route->{hooks}{pre_render};

            ($content, my $type) = blessed $view
                ? $view->render( $data ) : $view->( $data );
            $data->{-type} ||= $type;
        };
        if (!defined $content) {
            # TODO 0.90 $req->clear; - but don't kill cleanup hooks
            # FIXME bug here - resetting data does NOT affect the inside of req
            $req->log_error( "Request processed, but rendering failed: ". ($@ || "unknown error") );
            %$data = (
                -status => 500,
                -type   => "application/json",
            );
            # TODO 0.30 configurable
            $content = '{"error":"500","reason":"rendering error","req_id":"'
                . $req->id .'"}';
        };

    return $content;
}; # end _render_content

# in: $req->reply
# out: nothing
# side: $reply->{-content}, $reply->{-type} modified
sub _fix_encoding {
    my (undef, $data) = @_;

    my $content = \$data->{-content};

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
}; # end _fix_encoding

sub handle_request {
    my ($self, $req) = @_;
    $self = $Inst unless ref $self;

    # Route request, process logic, generate reply
    my ($route, $data) = $self->_route_request( $req );
    # $data == $req->reply at this point

    # Render content if needed.
    my $content = \$data->{-content};
    $$content = $self->_render_content( $route, $req )
        unless defined $$content;

    # encode_utf8 if needed, define -type if none
    $self->_fix_encoding( $data );

    # MANGLE HEADERS
    # NOTE these modifications remain stored in req
    my $head = $req->header_out;

    # The most standard ones...
    $head->init_header( content_type => $data->{-type} );
    $head->init_header( location => $data->{-location} )
        if $data->{-location};
    $head->push_header( set_cookie => $req->format_cookies );
    $head->init_header( content_length => length $$content )
        unless $data->{-continue};
    $head->init_header( expires => http_date( time + $route->{cache_ttl} ) )
        if exists $route->{cache_ttl} and $data->{-status} == 200;

    # END MANGLE HEADERS

    if (exists $route->{hooks}{pre_cleanup}) {
        $req->postpone( $route->{hooks}{pre_cleanup} );
    };
    if (exists $route->{hooks}{pre_reply}) {
        run_all_nodie( $route->{hooks}{pre_reply}, sub {
                $req->log_error( "pre_reply hook failed: $@" )
        }, $req );
    };

    # DISPATCH CONTENT

    $$content = '' if $req->method eq 'HEAD';
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

    # LOCK PROFILE
    $route->{lock}++
        and die "MVC::Neaf broken, please file a bug";

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
                # TODO 0.90 filter out repetition
                push @{ $phases{$phase} }, $hook->{code};
                # TODO 0.30 also store hook info somewhere for better error logging
            };
        };
    };

    # the pre-reply, pre-cleanup should go in backward direction
    # those are for cleaning up stuff
    $phases{$_} and @{ $phases{$_} } = reverse @{ $phases{$_} }
        for qw(pre_cleanup pre_reply);

    $route->{hooks} = \%phases;

    return;
};

# In: $req, raw exception
# Out: reply hash
sub _error_to_reply {
    my ($self, $req, $err) = @_;

    # Convert all errors to Neaf expt.
    if (!blessed $err) {
        $err = MVC::Neaf::Exception->new(
            -status   => $err,
            -nocaller => 1,
        );
    }
    elsif ( !$err->isa("MVC::Neaf::Exception")) {
        $err = MVC::Neaf::Exception->new(
            -status   => 500,
            -sudden   => 1,
            -reason   => $err,
            -nocaller => 1,
        );
    };

    # Now $err is guaranteed to be a Neaf error

    # Use on_error callback to fixup error or gather stats
    if( $err->is_sudden and exists $self->{on_error}) {
        eval {
            $self->{on_error}->($req, $err, $req->endpoint_origin);
            1;
        }
            or $req->log_error( "on_error callback failed: ".($@ || "unknown reason") );
    };

    # Try fancy error template
    if (my $tpl = $self->{error_template}{$err->status}) {
        my $ret = eval {
            $tpl->( $req,
                status => $err->status,
                caller => $req->endpoint_origin, # TODO 0.25 kill this
                error => $err,
            );
        };
        if (ref $ret eq 'HASH') {
            # success
            $ret->{-status} ||= $err->status;
            return $ret;
        };
        $req->log_error( "error_template for ".$err->status." failed:"
            .( $@ || "unknown reason") );
    };

    # Options exhausted - return plain error message,
    #    keep track of reason on the inside
    $req->log_error( $err->reason )
        if $err->is_sudden;
    return $err->make_reply( $req );
};

# See my_croak in MVC::Neaf::X
# dies with "MVC::Neaf->current_method: $error_message at <calling code>"
sub _croak {
    my ($self, $msg) = @_;

    my $where = [caller(1)]->[3];
    $where =~ s/.*:://;
    croak( (ref $self || $self)."->$where: $msg" );
};

=head2 get_view()

=over

=item * $neaf->get_view( "name", $lazy )

=back

Fetch view object by name.

Uses C<load_view> ( name => name ) if needed, unless $lazy flag is on.

This is for internal usage, mostly.

If C<set_forced_view> was called, return its argument instead.

=cut

sub get_view {
    my ($self, $view, $lazy) = @_;
    $self = $Inst unless ref $self;

    # We've been overridden!
    return $self->{force_view}
        if exists $self->{force_view};

    # An object/code means controller knows better
    return $view
        if ref $view;

    # Try loading & caching if not present.
    $self->load_view( $view, $view )
        unless $lazy || $self->{seen_view}{$view};

    # Finally, return the thing.
    return $self->{seen_view}{$view};
};

=head2 get_form()

    $neaf->get_form( "name" )

Fetch form named "name". No magic here. See L</add_form>.

=cut

sub get_form {
    my ($self, $name) = @_;
    return $self->{forms}{$name};
};

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
    use MVC::Neaf qw(:sugar);

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

=head1 DEPRECATED METHODS

Some methods become obsolete during Neaf development.
Anything that is considered deprecated will continue to be supported
I<for at least three minor versions> after official deprecation
and a corresponding warning being added.

Please keep an eye on C<Changes> though.

B<Here is the list of such methods, for the sake of completeness.>

=over

=item * C<$neaf-E<gt>pre_route( sub { my $req = shift; ... } )>

Use C<$neaf-E<gt>add_hook( pre_route =E<gt> \&hook )> instead.
Hook signature & meaning is exactly the same.

=cut

sub pre_route {
    my ($self, $code) = @_;
    $self = $Inst unless ref $self;

    # TODO 0.20 remove
    carp ("NEAF: pre_route(): DEPRECATED until 0.20, use add_hook( pre_route => CODE )");
    $self->add_hook( pre_route => $code );
    return $self;
};

=item * C<$neaf-E<gt>error_template( { param =E<gt> value } )>

Use L</set_error_handler> aka C<neaf \d\d\d =E<gt> sub { ... }>
instead.

=cut

# TODO 0.25 remove
sub error_template {
    my $self = shift;

    carp "error_template() is deprecated, use set_error_handler() instead";
    return $self->set_error_handler(@_);
};

=item * C<$neaf-E<gt>set_default ( key =E<gt> value, ... )>

Use C<MVC::Neaf-E<gt>set_path_defaults( '/', { key =E<gt> value, ... } );>
as a drop-in replacement.

=cut

sub set_default {
    my ($self, %data) = @_;
    $self = $Inst unless ref $self;

    # TODO 0.25 remove
    carp "DEPRECATED use set_path_defaults( '/', \%data ) instead of set_default()";

    return $self->set_path_defaults( '/', \%data );
};

=item * C<$neaf-E<gt>server_stat ( MVC::Neaf::X::ServerStat-E<gt>new( ... ) )>

Record server performance statistics during run.

The interface of C<MVC::Neaf::X::ServerStat> is as follows:

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

B<[DEPRECATED]> Just use pre_route/pre_reply/pre_cleanup hooks if you need
to gather performance statistics.

=cut

sub server_stat {
    my ($self, $obj) = @_;
    $self = $Inst unless ref $self;

    carp( (ref $self)."->server_stat: DEPRECATED, use hooks & custom stat toolinstead" );

    if ($obj) {
        $self->{stat} = $obj;
    } else {
        delete $self->{stat};
    };

    return $self;
};

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

Copyright 2016-2017 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of MVC::Neaf
