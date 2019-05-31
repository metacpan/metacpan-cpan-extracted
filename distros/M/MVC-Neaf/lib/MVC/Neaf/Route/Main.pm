package MVC::Neaf::Route::Main;

use strict;
use warnings;
our $VERSION = '0.2701';

=head1 NAME

MVC::Neaf::Route::Main - main application class for Not Even A Framework.

=head1 DESCRIPTION

This class contains a L<MVC::Neaf> application structure
and implements the core of Neaf logic.

It is a L<MVC::Neaf::Route> object itself,
containing a hash of other routes designated by their path prefixes.

=head1 APPLICATION SETUP METHODS

=cut

use Carp;
use Encode;
use Module::Load;
use Scalar::Util qw( blessed looks_like_number reftype );
use URI::Escape;

use parent qw(MVC::Neaf::Route);
use MVC::Neaf::Util qw( run_all run_all_nodie http_date canonize_path check_path
     maybe_list supported_methods extra_missing encode_b64 decode_b64 data_fh );
use MVC::Neaf::Util::Container;
use MVC::Neaf::Request::PSGI;
use MVC::Neaf::Route::PreRoute;

sub _one_and_true {
    my $self = shift;

    my $method = [caller 1]->[3];
    $method =~ s/.*:://;

    if ($self eq 'MVC::Neaf') {
        require MVC::Neaf;
        carp "MVC::Neaf->$method() call is DEPRECATED, use neaf->$method or MVC::Neaf->new()";
        return MVC::Neaf::neaf();
    };

    croak "Method $method called on unblessed '$self'";
};

=head2 new()

    new( %options )

This is also called by C<MVC::Neaf-E<gt>new>,
in case one wants to instantiate a Neaf application object
instead of using the default L<MVC::Neaf/neaf>.

Options may include:

=over

=item force_view - use that view instead of anything specified by controller.
See L</load_view> for details about how view is declared.
Useful for debugging.

=back

=cut

sub new {
    my ($class, %opt) = @_;

    my $force = delete $opt{force_view};

    my $self = bless \%opt, $class;

    $self->set_forced_view( $force )
        if $force;

    $self->set_path_defaults( { -status => 200, -view => 'JS' } );

    # This is required for $self->hooks to produce something.
    # See also todo_hooks where the real hooks sit.
    $self->{hooks} = {};

    # magical by default
    $self->{magic} = 1;

    return $self;
};

=head2 add_route()

Define a handler for given by URI path and HTTP method(s).
This is the backend behind NEAF's C<get + post> route specifications.

    route( '/path' => CODEREF, %options )

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

=cut

my $year = 365 * 24 * 60 * 60;
my %known_route_args;
$known_route_args{$_}++ for qw(
    default method view cache_ttl
    path_info_regex param_regex strict
    description caller tentative override public
);

sub add_route {
    my $self = shift;

    $self->my_croak( "Odd number of elements in hash assignment" )
        if @_ % 2;
    my ($path, $sub, %args) = @_;
    $self = _one_and_true($self) unless ref $self;

    $self->my_croak( "handler must be a coderef, not ".ref $sub )
        unless UNIVERSAL::isa( $sub, "CODE" );

    # check defaults to be a hash before accessing them
    $self->my_croak( "default must be unblessed hash" )
        if $args{default} and ref $args{default} ne 'HASH';

    # minus-prefixed keys are typically defaults
    $_ =~ /^-/ and $args{default}{$_} = delete $args{$_}
        for keys %args;

    # kill extra args
    my @extra = grep { !$known_route_args{$_} } keys %args;
    $self->my_croak( "Unexpected keys in route setup: @extra" )
        if @extra;

    $args{path} = $path = check_path canonize_path( $path );

    $args{method} = maybe_list( $args{method}, qw( GET POST ) );
    $_ = uc $_ for @{ $args{method} };

    $self->my_croak("Public endpoint must have nonempty description")
        if $args{public} and not $args{description};

    $self->_detect_duplicate( \%args );

    # Do the work
    my %profile;
    $profile{parent}    = $self;
    $profile{code}      = $sub;
    $profile{tentative} = $args{tentative};
    $profile{override}  = $args{override};
    $profile{strict}    = $args{strict};

    # Always have regex defined to simplify routing
    $profile{path_info_regex} = (defined $args{path_info_regex})
        ? qr#^$args{path_info_regex}$#
        : qr#^$#;

    # Just for information
    $profile{path}        = $path;
    $profile{description} = $args{description};
    $profile{public}      = $args{public} ? 1 : 0;
    $profile{caller}      = $args{caller} || [caller(0)]; # save file,line

    if (my $view = $args{view}) {
        # TODO 0.30
        carp "NEAF: route(): view argument is deprecated, use -view instead";
        $args{default}{-view} = $view;
    };

    # preload view so that we can fail early
    $args{default}{-view} = $self->get_view( $args{default}{-view} )
        if $args{default}{-view};

    # todo_default because some path-based defs will be mixed in later
    $profile{default} = $args{default};

    # preprocess regular expression for params
    if ( my $reg = $args{param_regex} ) {
        my %real_reg;
        $self->my_croak("param_regex must be a hash of regular expressions")
            if ref $reg ne 'HASH' or grep { !defined $reg->{$_} } keys %$reg;
        $real_reg{$_} = qr(^$reg->{$_}$)s
            for keys %$reg;
        $profile{param_regex} = \%real_reg;
    };

    if ( $args{cache_ttl} ) {
        $self->my_croak("cache_ttl must be a number")
            unless looks_like_number($args{cache_ttl});
        # as required by RFC
        $args{cache_ttl} = -100000 if $args{cache_ttl} < 0;
        $args{cache_ttl} = $year if $args{cache_ttl} > $year;
        $profile{cache_ttl} = $args{cache_ttl};
    };

    # ready, shallow copy handler & burn cache
    delete $self->{route_re};

    $self->{route}{ $path }{$_} = MVC::Neaf::Route->new( %profile, method => $_ )
        for @{ $args{method} };

    # This is for get+post sugar
    $self->{last_added} = \%profile;

    return $self;
}; # end sub route

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

# This is for get+post sugar
# TODO 0.90 merge with alias, GET => implicit HEAD
# TODO 0.30 public method
sub _dup_route {
    my ($self, $method, $profile) = @_;

    $profile ||= $self->{last_added};
    my $path = $profile->{path};

    $self->_detect_duplicate($profile);

    delete $self->{route_re};
    $self->{route}{ $path }{$method} = MVC::Neaf::Route->new(
        %$profile, method => $method );
};

=head2 static()

    $neaf->static( '/path' => $local_path, %options );

    $neaf->static( '/other/path' => [ "content", "content-type" ] );

Serve static content located under C<$file_path>.
Both directories and single files may be added.

If an arrayref of C<[ $content, $content_type ]> is given as second argument,
serve content from memory instead.

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
    $self = _one_and_true($self) unless ref $self;

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

# Instantiate a global static handler to preload in-memory
#    static files into.
# TODO 0.30 lame name, find better
sub _static_global {
    my $self = shift;

    return $self->{global_static} ||= do {
        require MVC::Neaf::X::Files;
        MVC::Neaf::X::Files->new( root => '/dev/null' );
    };
};


=head2 alias()

    $neaf->alias( $newpath => $oldpath )

Create a new name for already registered route.
The handler will be executed as is,
but the hooks and defaults will be re-calculated.
So be careful.

B<[CAUTION]> As of 0.21, C<alias> does NOT adhere tentative/override switches.
This needs to be fixed in the future.

=cut

# TODO 0.30 add_alias or something
sub alias {
    my ($self, $new, $old) = @_;
    $self = _one_and_true($self) unless ref $self;

    $new = canonize_path( $new );
    $old = canonize_path( $old );

    check_path( $old, $new );

    $self->{route}{$old}
        or $self->my_croak( "Cannot create alias for unknown route $old" );

    # TODO 0.30 restrict methods, handle tentative/override, detect dupes
    $self->my_croak( "Attempting to set duplicate handler for path "
        .( length $new ? $new : "/" ) )
            if $self->{route}{ $new };

    # reset cache
    delete $self->{route_re};

    # FIXME clone()
    $self->{route}{$new} = $self->{route}{$old};
    return $self;
};

=head2 set_path_defaults

    set_path_defaults( { version => 0.99 }, path => '/api', %options );

%options may include:

=over

=item * path - restrict this set of defaults to given prefix(es);

=item * method - restrict this set of defaults to given method(s);

=item * exclude - exclude some prefixes;

=back

Append the given values to the hash returned by I<any> route
under the given path(s) and method(s).

Longer paths take over the shorter ones.
Route's own default values take over any path-based defaults.
Whatever the controller returns overrides all of these.

=cut

# TODO 0.30 rename defaults => [something]
sub set_path_defaults {
    my $self = shift;
    $self = _one_and_true($self) unless ref $self;

    # Old form - path => \%hash
    # TODO 0.30 kill
    if (@_ == 2) {
        carp "set_path_defaults(): '/prefix' => \%values form is DEPRECATED, use \%values, path => '/prefix' instead";
        push @_, path => shift;
    };

    my ($values, %opt) = @_;

    $self->my_croak( "values must be a \%hash" )
        unless ref $values eq 'HASH';

    extra_missing( \%opt, { path => 1, method => 1 } );

    $self->{defaults} ||= MVC::Neaf::Util::Container->new;
    $self->{defaults}->store( $values, %opt );

    return $self;
};

=head2 get_path_defaults

    get_path_defaults ( $methods, $path, [ \%override ... ] )

Fetch default values for given (path, method) combo as a single hash.

=cut

sub get_path_defaults {
    my ($self, $method, $path, @override) = @_;

    my @source = $self->{defaults}->fetch( method => $method, path => $path );
    my %hash = map { %$_ } @source, grep defined, @override;
    defined $hash{$_} or delete $hash{$_}
        for keys %hash;

    \%hash;
};


=head2 add_hook()

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

See L<MVC::Neaf/REQUEST PROCESSING PHASES AND HOOKS> below for detailed
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

our %hook_phases;
$hook_phases{$_}++ for qw(pre_route
    pre_logic pre_content pre_render pre_reply pre_cleanup);

sub add_hook {
    my ($self, $phase, $code, %opt) = @_;
    $self = _one_and_true($self) unless ref $self;

    extra_missing( \%opt, \%add_hook_args );
    $self->my_croak( "illegal phase: $phase" )
        unless $hook_phases{$phase};

    $opt{method} = maybe_list( $opt{method}, supported_methods() );
    if ($phase eq 'pre_route') {
        # handle pre_route separately
        $self->my_croak("cannot specify paths/excludes for $phase")
            if defined $opt{path} || defined $opt{exclude};
    };

    $opt{path}      = maybe_list( $opt{path}, '' );
    $opt{caller}  ||= [ caller(0) ]; # where the hook was set

    $self->{todo_hooks}{$phase} ||= MVC::Neaf::Util::Container->new;
    $self->{todo_hooks}{$phase}->store( $code, %opt );

    return $self;
};

=head2 get_hooks

    get_hooks( $method, $path )

Fetch all hooks previously set for given path as a { phase => [ list ] } hash.

=cut

sub get_hooks {
    my ($self, $method, $path) = @_;

    my %ret;

    foreach my $phase ( keys %{ $self->{todo_hooks} } ) {
        $ret{$phase} = [ $self->{todo_hooks}{$phase}->fetch( method => $method, path => $path ) ];
    };

    # Some hooks to be executed in reverse order
    $ret{$_} and @{ $ret{$_} } = reverse @{ $ret{$_} }
        for qw( pre_reply pre_cleanup );

    # Prepend session handler unconditionally, if present
    if (my $key = $self->{session_view_as}) {
        unshift @{ $ret{pre_render} }, sub {
            $_[0]->reply->{$key} = $_[0]->load_session;
        };
    };

    if (my $force_view = $self->{force_view}) {
        # TODO 0.40 also push pre-rendered -content through force_view
        push @{ $ret{pre_render} }, sub { $_[0]->reply->{-view} = $force_view };
    };

    return \%ret;
};

=head2 set_helper

    set_helper( name => \&code, %options )

=cut

sub set_helper {
    my ($self, $name, $code, %opt) = @_;

    $self->my_croak( "helper must be a CODEREF, not ".ref $code )
        unless ref $code and UNIVERSAL::isa( $code, 'CODE' );
    _install_helper( $name );

    $self->{todo_helpers}{$name} ||= MVC::Neaf::Util::Container->new( exclusive => 1 );
    $self->{todo_helpers}{$name}->store( $code, %opt );
};

sub _install_helper {
    my $name = shift;

    return if $MVC::Neaf::Request::allow_helper{$name};

    croak( "NEAF: helper: inappropriate helper name '$name'" )
        if $name !~ /^[a-z][a-z_0-9]*/ or $name =~ /^(?:do|neaf)/;

    croak "NEAF: helper: Cannot override existing method '$name' in Request"
        if MVC::Neaf::Request->can( $name );

    my $sub = sub {
        my $req = shift;

        my $code = $req->route->helpers->{$name};
        croak ("Helper '$name' is not defined for ".$req->method." ".$req->route->path)
            unless $code;

        $code->( $req, @_ );
    };

    # HACK magic here - plant method into request
    {
        no strict 'refs'; ## no critic
        use warnings FATAL => qw(all);
        *{"MVC::Neaf::Request::$name"} = $sub;
    };

    $MVC::Neaf::Request::allow_helper{$name}++;
};

=head2 get_helpers

=cut

sub get_helpers {
    my ($self, $method, $path) = @_;

    my $todo = $self->{todo_helpers};

    my %ret;
    foreach my $name( keys %$todo ) {
        my ($last) = reverse $todo->{$name}->fetch( method => $method, path => $path );
        $ret{$name} = $last if $last;
    };

    return \%ret;
};

=head2 load_view()

    load_view( "name", $view_object );  # stores object
                                        # assuming it's an L<MVC::Neaf::View>
    load_view( "name", $module_name, %params ); # calls new()
    load_view( "name", $module_alias ); # ditto, see list of aliases below
    load_view( "name", \&CODE );        # use that sub to generate
                                        # content from hash

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

Returns the view object, NOT the object this method was called on.

=cut

my %view_alias = (
    TT     => 'MVC::Neaf::View::TT',
    JS     => 'MVC::Neaf::View::JS',
    Dumper => 'MVC::Neaf::View::Dumper',
);
sub load_view {
    my ($self, $name, $obj, @param) = @_;
    $self = _one_and_true($self) unless ref $self;

    $self->my_croak("At least two arguments required")
        unless defined $name and defined $obj;

    # Instantiate if needed
    if (!ref $obj) {
        # in case an alias is used, apply alias
        $obj = $view_alias{ $obj } || $obj;

        # Try loading...
        if (!$obj->can("new")) {
            eval { load $obj; 1 }
                or $self->my_croak( "Failed to load view $name=>$obj: $@" );
        };
        $obj = $obj->new( @param );
    };

    $self->my_croak( "view must be a coderef or a MVC::Neaf::View object" )
        unless blessed $obj and $obj->can("render")
            or ref $obj eq 'CODE';

    $self->{seen_view}{$name} = $obj;

    return $obj;
};

=head2 set_forced_view()

    $neaf->set_forced_view( $view )

If set, this view object will be user instead of ANY other view.

See L</get_view>.

Returns self.

=cut

sub set_forced_view {
    my ($self, $view) = @_;
    $self = _one_and_true($self) unless ref $self;

    delete $self->{force_view};
    return $self unless $view;

    $self->{force_view} = $self->get_view( $view );

    return $self;
};

=head2 magic( bool )

Get/set "magic" bit that triggers stuff like loading resources from __DATA__
on run() and such.

Neaf is magical by default.

=cut

# Dumb accessor(boolean)
sub magic {
    my $self = shift;
    if (@_) {
        $self->{magic} = !! shift;
        return $self;
    } else {
        return $self->{magic};
    };
};

=head2 load_resources()

    $neaf->load_resources( $file_name || \*FH )

Load pseudo-files from a file (typically C<__DATA__>),
say templates or static files.

As of 0.27, load_resources happens automatically upon L<run>,
but only once for each calling file.
Use C<neaf-E<gt>magic(0)> if you know better
(e.g. you want to use __DATA__ for something else).

The format is as follows:

    @@ /main.html view=TT

    [% some_tt_template %]

    @@ /favicon.ico format=base64 type=png

    iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAAL
    GPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hS<....more encoded lines>

I<This is obviously stolen from L<Mojolicious>,
in a slightly incompatible way.>

An entry starts with a literal C<@@>, followed by 1 or more spaces,
followed by a slash and a file name, optionally followed by a list
of options, and finally by a newline.

Everything following the newline and until next such entry
is considered file content.

Options may include:

=over

=item * C<type=ext | mime/type>

=item * C<format=base64>

=item * C<view=view_name,view_name...> - specify a template for given view(s)
Leading slash will be stripped in this case.

=back

Entries with unknown options will be skipped with a warning.

B<[EXPERIMENTAL]> This method and exact format of data is being worked on.

=cut

# TODO split this sub & move to a separate file
my $INLINE_SPEC = qr/^(?:\[(\w+)\]\s+)?(\S+)((?:\s+\w+=\S+)*)$/;
my %load_resources_opt;
$load_resources_opt{$_}++ for qw( view format type );
sub load_resources {
    my ($self, $file, $name) = @_;

    if (!ref $file and defined $file) {
        open my $fd, "<", $file
            or $self->my_croak( "Failed to open(r) $file: $!" );
        $name = $file;
        $file = $fd;
    };

    # Don't load the same filename twice
    return $self
        if defined $name and $self->{load_resources}{$name}++;

    my $content;

    if (ref $file eq 'GLOB') {
        local $/;
        $content = <$file>;
        defined $content
            or $self->my_croak( "Failed to read from $file: $!" );
        close $file;
        # Die later
    } elsif (ref $file eq 'SCALAR') {
        $content = $$file;
    } else {
        $self->my_croak( "Argument must be a scalar, a scalar ref, or a file descriptor" );
    };

    defined $content
        or $self->my_croak( "Failed load content" );

    # TODO 0.40 The regex should be: ^@@\s+(/\S+(?:\s+\w+=\S+)*)\s*$
    #     but we must deprecate '[TT] foo.html' first
    my @parts = split m{^@@\s+(\S.*?)\s*$}m, $content, -1;
    shift @parts;
    confess "NEAF load_resources failed unexpectedly, file a bug in MVC::Neaf"
        if @parts % 2;

    my %templates;
    my %static;
    while (@parts) {
        # parse pseudo-file
        my $spec = shift @parts;
        my $content = shift @parts;

        # process header
        my ($dest, $name, $extra) = ($spec =~ $INLINE_SPEC);
        $self->my_croak("Bad resource spec format @@ $spec")
            unless defined $name;
        my %opt = $extra =~ /(\w+)=(\S+)/g;
        if ($dest) {
            $opt{view} = $dest;
            carp "DEPRECATED '@@ [$dest]' resource format,"
                ." use '@@ $name view=$dest' instead";
        };

        if ( my @unknown = grep { !$load_resources_opt{$_} } keys %opt ) {
            carp "Unknown options (@unknown) in '@@ name' in $file, skipping";
            next;
        };

        # process content
        if (!$opt{format}) {
            $content =~ s/^\n+//s;
            $content =~ s/\s+$//s;
            $content = Encode::decode_utf8( $content, 1 );
        } elsif ($opt{format} eq 'base64') {
            $content = decode_b64( $content );
        } else {
            # TODO 0.50 calculate line
            $self->my_croak("Unknown format $opt{format} in '@@ $spec' in $file");
        };

        # store for loading
        if (defined( my $view = $opt{view} )) {
            # template
            $self->my_croak("Duplicate template '@@ $spec' in $file")
                if defined $templates{$view}{$name};
            $templates{$view}{$name} = $content;
        } else {
            # static file
            $self->my_croak("Duplicate static file '@@ $spec' in $file")
                if $static{$name};
            $static{$name} = [ $content, $opt{type} ];
        };
    }; # end while @parts

    # now do the loading
    foreach my $name( keys %templates ) {
        my $view = $self->get_view( $name, 1 );
        if (!$view) {
            carp "NEAF: Unknown view $name mentioned in $file";
        } elsif ($view->can("preload")) {
            $view->preload( %{ $templates{$name} } );
        } else  {
            carp "NEAF: View $name mentioned in $file doesn't support template preloading";
        };
    };
    if( %static ) {
        my $st = $self->_static_global;
        $st->preload( %static );
        foreach( keys %static ) {
            $self->add_route( $_ => $st->one_file_handler, method => 'GET'
                , description => "Static resource from $file" );
        };
    };

    return $self;
};

=head2 set_session_handler()

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

sub set_session_handler {
    my ($self, %opt) = @_; # TODO 0.30 use helpers when ready
    $self = _one_and_true($self) unless ref $self;

    my $sess = delete $opt{engine};
    my $cook = $opt{cookie} || 'neaf.session';

    $self->my_croak("engine parameter is required")
        unless $sess;

    if (!ref $sess) {
        $opt{session_ttl} = delete $opt{ttl} || $opt{session_ttl};

        my $obj = eval { load $sess; $sess->new( %opt ); }
            or $self->my_croak("Failed to load session '$sess': $@");

        $sess = $obj;
    };

    my @missing = grep { !$sess->can($_) }
        qw(get_session_id session_id_regex session_ttl
            create_session load_session save_session delete_session );
    $self->my_croak("engine object does not have methods: @missing")
        if @missing;

    my $regex = $sess->session_id_regex;
    my $ttl   = $opt{ttl} || $sess->session_ttl || 0;

    my $setup = {
        engine => $sess,
        cookie => $cook,
        regex  => $regex,
        ttl    => $ttl,
    };

    $self->set_helper( _session_setup => sub { $setup }, override => 1 );
    $self->{session_view_as} = $opt{view_as};
    return $self;
};

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

sub set_error_handler {
    my ($self, $status, $code, %where) = @_;
    $self = _one_and_true($self) unless ref $self;

    $status =~ /^(?:\d\d\d)$/
        or $self->my_croak( "1st argument must be an http status");
    extra_missing( \%where, { path => 1, exclude => 1, method => 1 } );

    if (ref $code eq 'HASH') {
        my $hash = $code;
        $code = sub {
            my ($req, %opt) = @_;

            return { -status => $opt{status}, %opt, %$hash };
        };
    };
    reftype $code eq 'CODE'
        or $self->my_croak( "2nd argument must be a callback or hash");

    my $store = $self->{error_template}{$status}
        ||= MVC::Neaf::Util::Container->new();

    $store->store( $code, %where );

    return $self;
};

=head2 on_error()

    on_error( sub { my ($request, $error) = @_ } )

Install custom error handler for a dying controller.
Neaf's own exceptions, redirects, and C<die \d\d\d> status returns will NOT
trigger it.

E.g. write to log, or something.

Return value from this callback is ignored.
If it dies, only a warning is emitted.

=cut

sub on_error {
    my ($self, $code) = @_;
    $self = _one_and_true($self) unless ref $self;

    if (defined $code) {
        ref $code eq 'CODE'
            or $self->my_croak( "Argument MUST be a callback" );
        $self->{on_error} = $code;
    } else {
        delete $self->{on_error};
    };

    return $self;
};

=head2 post_setup

This function is run after configuration has been completed,
but before first request is served.

It goes as follows:

=over

=item * compile all the routes into a giant regexp;

=item * Add HEAD handling to where only GET exists;

=item * finish set_session_handler works

=item * set the lock on route;

=back

Despite the locking, further modifications are not prohibited.
This MAY change in the future.

=cut

sub post_setup {
    my $self = shift;

    # TODO 0.30 disallow calling this method twice
    # confess "Attempt to call post_setup twice"
    #     if $self->{lock};

    $self->{route_re} ||= $self->_make_route_re;

    # Add implicit HEAD for all GETs via shallow copy
    foreach my $node (values %{ $self->{route} }) {
        $node->{GET} or next;
        $node->{HEAD} ||= $node->{GET}->clone( method => 'HEAD' );
    };

    $self->{lock}++;
};

# Create a giant regexp from a hash of paths
# PURE
# The regex can be matched against an URI path,
# in which case it returns either nothing,
# or mathed route in $1 (prefix) and the rest of the string in $2 (postfix)
sub _make_route_re {
    my ($self, $hash) = @_;

    $hash ||= $self->{route};

    # Make longest paths come first
    my @path_list = reverse sort keys %$hash;

    # escape all metacharacters except /
    # which is converted to '/+' so that foo///bar is also matched
    my $re = join "|", map {
        join '/+', map {
            quotemeta
        } split /\/+/, $_
    } @path_list;

    # split path into (/foo/bar)/(baz)?param=value
    # return prefix as $1 and postfix as $2, if present
    return qr{^($re)(?:/+([^?]*))?(?:\?|$)};
};

=head2 run()

    $neaf->run();

Run the application.
This SHOULD be the last statement in your application's main file.

When run() is called, the routes are compiled into one giant regex,
and the post-setup is run, if needed.

Additionally if neaf is in magical mode,
L</load_resources> is called on the enclosing file's DATA descriptor.
Magic mode is on by default. See L</magic-bool>.

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
    $self = _one_and_true($self) unless ref $self;

    # "Magically" load __DATA__ section from calling file
    if ($self->{magic}) {
        my ($file, $data) = data_fh(1);
        $self->load_resources( $data, $file )
            if $data;
    };

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

    # Do postsetup after CGI/CLI execution
    # because it's unneeded there - only one route may be needed so why bother
    $self->post_setup;

    return sub {
        $self->handle_request(
            MVC::Neaf::Request::PSGI->new( env => $_[0] ));
    };
};

=head1 INTROSPECTION AND TESTING METHODS

=head2 run_test()

    $neaf->run_test( \%PSGI_ENV, %options )

    $neaf->run_test( "/path?parameter=value", %options )

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
    $self = _one_and_true($self) unless ref $self;

    my @extra = grep { !$run_test_allow{$_} } keys %opt;
    $self->my_croak( "Extra keys @extra" )
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

    my $req = MVC::Neaf::Request::PSGI->new( %fake, env => $env );

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

    $neaf->get_routes( $callback->(\%route_spec, $path, $method) )

Returns a 2-level hashref with ALL routes for inspection.

So C<$hash{'/path'}{'GET'} = { handler, expected params, description etc }>

If callback is present, run it against route definition
and append to hash its return value, but ONLY if it's true.

As of 0.20, route definitions are only protected by shallow copy,
so be careful with them.

This SHOULD NOT be used by application itself.

=cut

# TODO 0.30 Route->inspect, Route::Main->inspect
sub get_routes {
    my ($self, $code) = @_;
    $self = _one_and_true($self) unless ref $self;

    $code ||= sub { $_[0] };
    scalar $self->run; # burn caches

    # TODO 0.30 must do deeper copying
    my $all = $self->{route};
    my %ret;
    foreach my $path ( keys %$all ) {
        my $batch = $all->{$path};
        foreach my $method ( keys %$batch ) {
            my $route = $batch->{$method};
            $route->post_setup
                unless $route->is_locked;

            my $filtered = $code->( $route->clone, $path, $method );
            $ret{$path}{$method} = $filtered if $filtered;
        };
    };

    return \%ret;
};

=head1 RUN TIME METHODS

=head2 handle_request

    handle_request( $req )

This is the CORE of Not Even A Framework.
Should not be called directly - use C<run()> instead.

C<handle_request> really boils down to

    my ($self, $req) = @_;

    my $req->path =~ /($self->{GIANT_ROUTING_RE})/
        or die 404;

    my $endpoint = $self->{ROUTES}{$1}{ $req->method }
        or die 405;

    my $reply_hash = $endpoint->{CODE}->($req);

    my $content = $reply_hash->{-view}->render( $reply_hash );

    return [ $reply_hash->{-status}, [...], [ $content ] ];

The rest 200+ lines of it, spread across this module and L<MVC::Neaf::Route>,
are for running callbacks, handling corner cases, and substituting sane defaults.

=cut

sub handle_request {
    my ($self, $req) = @_;
    $self = _one_and_true($self) unless ref $self;

    my $data = eval {
        my $hash = $self->dispatch_logic( $req, '', $req->path );
        $hash = $req->_set_reply( $hash );

        if (my $hooks = $req->route->hooks->{pre_content}) {
            run_all_nodie( $hooks, sub {
                    $req->log_error( "NEAF: pre_content hook failed: $@" )
            }, $req );
        };

        $hash->{-content} = $self->dispatch_view( $req )
            unless defined $hash->{-content};
        $hash;
    };

    if (!$data) {
        # TODO 0.30 Error handler should be route-dependent.
        $req->_unset_reply;
        $data = $self->_error_to_reply( $req, $@ );
    };

    # Encode content, fix headers - do it before hooks
    $req->_mangle_headers;
    $req->_apply_late_hooks;
    $req->_respond;
};

=head2 get_view()

    $route->get_view( "name", $lazy )

Fetch view object by name.

This is used to fetch/instantiate whatever is in C<-view> of the
controller return hash.

Uses C<load_view> ( name => name ) if needed, unless $lazy flag is on.

If L</set_forced_view> was called, return its argument instead.

=cut

sub get_view {
    my ($self, $view, $lazy) = @_;
    $self = _one_and_true($self) unless ref $self;

    # An object/code means controller knows better
    return $view
        if ref $view;

    # Try loading & caching if not present.
    $self->load_view( $view, $view )
        unless $lazy || $self->{seen_view}{$view};

    # Finally, return the thing.
    return $self->{seen_view}{$view};
};

=head2 INTERNAL LOGIC METHODS

The following methods are part of NEAF's core and should not be called
unless you want something I<very> special.

The following terminology is used hereafter:

=over

=item * prefix - part of URI that matched given NEAF route;

=item * suffix - anything after the matching part
but before query parameters (the infamous C<path_info>).

=back

When recursive routing is applied, C<prefix> is left untouched,
C<stem> becomes prefix, and C<suffix> is split into new C<stem> + C<suffix>.

When a leaf route is found, it matches $suffix to its own regex
and either dies 404 or proceeds with application logic.

=head2 find_route( $method, $suffix )

Find subtree that matches given ($method, $suffix) pair.

May die 404 or 405 if no suitable route is found.

Otherwise returns (route, new_stem, new_suffix).

=cut

sub find_route {
    my ($self, $method, $path) = @_;

    # Lookup the rules for the given path
    $path =~ $self->{route_re}
        or die "404\n";

    my ($prefix, $postfix) = ($1, $2);
    $prefix =~ s#//+#/#g; # CANONIZE

    my $node = $self->{route}{$prefix}
        or die "404\n";

    my $route = $node->{ $method };
    unless ($route) {
        die MVC::Neaf::Exception->new(
            -status => 405,
            -headers => [Allow => join ", ", keys %$node]
        );
    };

    $postfix = '' unless defined $postfix;
    return ($route, $prefix, $postfix);
};

=head2 dispatch_logic

    dispatch_logic( $req, $prefix, $suffix )

Find a matching route and apply it to the request.

This is recursive, may die, and may spoil C<$req>.

Upon successful termination, a reply hash is returned.
See also L<MVC::Neaf::Route/dispatch_logic>.

=cut

sub dispatch_logic {
    my ($self, $req, $stem, $suffix) = @_;

    $self->post_setup
        unless $self->{lock};

    my $method = $req->method;

    # We MUST now ensure that $req->route is avail at any time
    # so add self to route
    # but maybe this whould be in dispatch_logic
    my $stub = $self->{pre_route_stub}{ $method }
        ||= MVC::Neaf::Route::PreRoute->new(
             method => $method, parent => $self );
    $req->_import_route( $stub );

    # run pre_route hooks if any
    my $pre_route_hooks = $stub->hooks->{pre_route};
    run_all( $pre_route_hooks, $req )
        if $pre_route_hooks;

    my ($route, $new_stem, $new_suffix) = $self->find_route( $method, $suffix );

    $route->dispatch_logic( $req, $new_stem, $new_suffix );
};

=head2 dispatch_view

Apply view to a request.

=cut

sub dispatch_view {
    my ($self, $req) = @_;

    my $data  = $req->reply;
    my $route = $req->route;

    my $content;

    eval {
        run_all( $route->hooks->{pre_render}, $req )
            if $route->hooks->{pre_render};

        my $view = $self->get_view( $data->{-view} );

        ($content, my $type) = blessed $view
            ? $view->render( $data ) : $view->( $data );

        $data->{-type} ||= $type;
    };

    if (!defined $content) {
        $req->log_error( "NEAF: Request processed, but rendering failed: ". ($@ || "unknown error") );
        die MVC::Neaf::Exception->new(
            -status => 500,
            -reason => "Rendering error: $@"
        );
    };

    return $content;
};

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
            or $req->log_error( "NEAF: on_error callback failed: ".($@ || "unknown reason") );
    };

    # Try fancy error template
    if (my $tpl = $self->_get_error_handler( $err->status, $req )) {
        my $ret = eval {
            my $data = $tpl->( $req,
                status => $err->status,
                error => $err,
            );
            $data->{-status}  ||= $err->status;
            $data = $req->_set_reply( $data );
            $data->{-content} ||= $self->dispatch_view( $req );
            $data;
        };
        return $ret if $ret;
        $req->log_error( "NEAF: error_template for ".$err->status." failed:"
            .( $@ || "unknown reason") );
    };

    # Options exhausted - return plain error message,
    #    keep track of reason on the inside
    $req->log_error( $err->reason )
        if $err->is_sudden;
    $req->_set_reply( $err->make_reply( $req ) );
};

sub _get_error_handler {
    my ($self, $status, $req) = @_;

    my $store = $self->{error_template}{$status};
    return unless $store;

    return $store->fetch_last( method => $req->method, path => $req->path );
};

=head1 DEPRECATED METHODS

Some methods become obsolete during Neaf development.
Anything that is considered deprecated will continue to be supported
I<for at least three minor versions> after official deprecation
and a corresponding warning being added.

Please keep an eye on C<Changes> though.

B<Here is the list of such methods, for the sake of completeness.>

=over

=item * route

Old alias for L</add_route>.

=cut

sub route {
    my $self = shift;

    # TODO 0.30 deprecate

    $self->add_route(@_);
};

=back

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2019 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
