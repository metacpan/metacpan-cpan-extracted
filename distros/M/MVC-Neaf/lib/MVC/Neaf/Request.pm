package MVC::Neaf::Request;

use strict;
use warnings;

our $VERSION = 0.2501;

=head1 NAME

MVC::Neaf::Request - Request class for Not Even A Framework

=head1 DESCRIPTION

This is what your L<MVC::Neaf> application is going to get as its ONLY input.

Here's a brief overview of what a Neaf request returns:

    # How the application was configured:
    MVC::Neaf->route( "/matching/route" => sub { my $req = shift; ... },
        path_info_regex => '.*' );

    # What was requested:
    http(s)://server.name:1337/mathing/route/some/more/slashes?foo=1&bar=2

    # What is being returned:
    $req->http_version = HTTP/1.0 or HTTP/1.1
    $req->scheme       = http or https
    $req->method       = GET
    $req->hostname     = server.name
    $req->port         = 1337
    $req->path         = /mathing/route/some/more/slashes
    $req->prefix       = /mathing/route
    $req->postfix      = some/more/slashes

    # params and cookies require a regex
    $req->param( foo => '\d+' ) = 1

=head1 REQUEST METHODS

The actual Request object the application gets is going to be
a subclass of this.
Thus it is expected to have the following methods.

=cut

use Carp;
use URI::Escape;
use Encode;
use HTTP::Headers::Fast;
use Time::HiRes ();
use Sys::Hostname ();
use Digest::MD5 qw(md5);

use MVC::Neaf::Util qw( http_date run_all_nodie canonize_path encode_b64 );
use MVC::Neaf::Upload;
use MVC::Neaf::Exception;
use MVC::Neaf::Route::Null;

our %allow_helper;

=head2 new()

    MVC::Neaf::Request->new( %arguments )

The application is not supposed to make its own requests,
so this constructor is really for testing purposes only.

For now, just swallows whatever is given to it.
Restrictions MAY BE added in the future though.

=cut

sub new {
    my ($class, %args) = @_;

    # TODO 0.30 restrict params
    return bless \%args, $class;
};

# TODO 0.90 A lot of copypasted methods down here.
# Should we join them all? Maybe...

=head2 client_ip()

Returns the IP of the client.
If C<X-Forwarded-For> header is set, returns that instead.

=cut

sub client_ip {
    my $self = shift;

    return $self->{client_ip} ||= do {
        my @fwd = $self->header_in( "X-Forwarded-For" );
        @fwd == 1 && $fwd[0] || $self->do_get_client_ip || "127.0.0.1";
    };
};

=head2 http_version()

Returns version number of C<http> protocol.

=cut

sub http_version {
    my $self = shift;

    if (!exists $self->{http_version}) {
        $self->{http_version} = $self->do_get_http_version;
    };

    return $self->{http_version};
};

=head2 scheme()

Returns C<http> or C<https>, depending on how the request was done.

=cut

sub scheme {
    my $self = shift;

    if (!exists $self->{scheme}) {
        $self->{scheme} = $self->do_get_scheme || 'http';
    };

    return $self->{scheme};
};

=head2 secure()

Returns true if C<https> is used, false otherwise.

=cut

# TODO 0.90 secure should be a flag, scheme should depend on it
sub secure {
    my $self = shift;
    return $self->scheme eq 'https';
};

=head2 method()

Return the C<HTTP> method being used.
C<GET> is the default value if cannot determine
(useful for command-line debugging).

=cut

sub method {
    my $self = shift;
    return $self->{method} ||= $self->do_get_method || "GET";
};

=head2 is_post()

Alias for C<$self-E<gt>method eq 'POST'>.
May be useful in form submission, as in

    $form = $request->form( $validator );
    if ($request->is_post and $form->is_valid) {
        # save & redirect
    };
    # show form again

=cut

sub is_post {
    my $self = shift;
    return $self->method eq 'POST';
};

=head2 hostname()

Returns the hostname that was requested, or C<localhost> if cannot detect.

=cut

sub hostname {
    my $self = shift;

    return $self->{hostname} ||= $self->do_get_hostname || "localhost";
    # TODO 0.90 what if http://0/?
};

=head2 port()

Returns the port number.

=cut

sub port {
    my $self = shift;

    return $self->{port} ||= $self->do_get_port;
};

=head2 path()

Returns the path part of the URI. Path is guaranteed to start with a slash.

=cut

sub path {
    my $self = shift;

    return $self->{path} ||= $self->do_get_path;
};

=head2 route()

A L<MVC::Neaf::Route> object that this request is being dispatched to.

If request is not inside an application, returns a L<MVC::Neaf::Route::Null>
instead.

=cut

sub route {
    my $self = shift;
    return $self->{route} || MVC::Neaf::Route::Null->new;
};

=head2 set_path()

    $req->set_path( $new_path )

Set path() to new value. This may be useful in C<pre_route> hook.

Path will be canonized.

If no argument given, or it is C<undef>, resets path() value to
underlying driver's C<do_get_path>.

Returns self.

=cut

sub set_path {
    my ($self, $new_path) = @_;

    $self->{path} = defined $new_path
        ? canonize_path( $new_path, 1 )
        : $self->do_get_path;

    $self;
};

=head2 prefix()

The part of the request that matched the route to the
application being executed.

Guaranteed to start with slash.
Unless C<set_path> was called, it is a prefix of C<path()>.

Not available before routing was applied to request.

=cut

sub prefix {
    my $self = shift;

    # TODO kill in 0.30
    carp "NEAF: prefix() call before routing was applied is DEPRECATED: "
        unless $self->{route} && $self->{route}->path =~ m,^(?:/|$),;

    return $self->{prefix} ||= $self->path;
};

=head2 get_url_base()

Get scheme, server, and port of the application.

B<[EXPERIMENTAL]> Name and meaning subject to change.

=head2 get_url_rel( ... )

=over

=item * C<$req-E<gt>get_url_rel( %override )>

=back

Produce a relative link to the page being served,
possibly overriding some parameters.

Parameter order is NOT preserved. If parameter is empty or C<undef>,
it is skipped.

B<[CAUTION]> Multiple values are ignored, this MAY change in the future.

B<[CAUTION]> For a POST request, normal parameters are used instead of URL
parameters (see C<url_param>). This MAY change in the future.

B<[EXPERIMENTAL]> Name and meaning subject to change.

=head2 get_url_full( ... )

=over

=item * C<$req-E<gt>get_url_full( %override )>

=back

Same as above, but prefixed with schema, server name, and port.

B<[EXPERIMENTAL]> Name and meaning subject to change.

=cut

sub get_url_rel {
    my ($self, %override) = @_;

    my %h = (%{ $self->_all_params }, %override );

    return $self->path . '?' . join '&'
        , map { uri_escape_utf8($_) . "=" .uri_escape_utf8($h{$_}) }
        grep { defined $h{$_} && length $h{$_} }
        sort keys %h;
};

my %port_scheme = (
    http => 80,
    https => 443,
);

sub get_url_base {
    my $self = shift;

    # skip well-known ports
    my $port = ($self->port == ($port_scheme{ $self->scheme } || 0))
        ? ''
        : ':'.$self->port;

    return join "", $self->scheme, "://", $self->hostname, $port;
};

sub get_url_full {
    my $self = shift;
    return $self->get_url_base . $self->get_url_rel(@_);
};

=head2 postfix()

Returns the part of URI path beyond what matched the application's path.

Contrary to the
L<CGI specification|https://tools.ietf.org/html/rfc3875#section-4.1.5>,
the leading slash is REMOVED.

The validation regex for this value MUST be specified during application
setup as C<path_info_regex>. See C<route> in L<MVC::Neaf>.

B<[EXPERIMENTAL]> This part of API is undergoing changes.

=cut

sub postfix {
    my ($self) = @_;

    return $self->{postfix};
};

=head2 splat()

Return a list of matched capture groups found in path_info_regex, if any.

=cut

sub splat {
    my $self = shift;

    return @{ $self->{path_info_split} || [] };
};

# This is somewhat ugly.
# When a route is matched, we'll store it
#    and _also_ the leftovers of regex splitting that happens around that moment
sub _import_route {
    my ($self, $route, $path, $path_info, $tail) = @_;

    $self->{route}        = $route;
    if (defined $path) {
        $self->{prefix}  = $path;
        $self->{postfix}    = $path_info;
        $self->{path_info_split}   = $tail;
    };

    return $self;
};

=head2 set_path_info( ... )

=over

=item * C<$req-E<gt>set_path_info( $path_info )>

=back

Sets path_info to new value.

Also updates path() value so that path = script_name + path_info
still holds.

Returns self.

=cut

sub set_path_info {
    my ($self, $path_info) = @_;

    $path_info = '' unless defined $path_info;
    # CANONIZE
    $path_info =~ s#^/+##;

    $self->{postfix} = $path_info;
    $self->{path} = $self->script_name
        .(length $self->{postfix} ? "/$self->{postfix}" : '');

    return $self;
};

=head2 param( ... )

=over

=item * $req->param( $name, $regex )

=item * $req->param( $name, $regex, $default )

=back

Return parameter, if it passes regex check, default value or C<undef> otherwise.

The regular expression is applied to the WHOLE string,
from beginning to end, not just the middle.
Use '.*' if you really trust the data.

Dies if regular expression didn't match and the route has the C<strict> flag.

B<[EXPERIMENTAL]> If C<param_regex> hash was given during route definition,
C<$regex> MAY be omitted for params that were listed there.
This feature is not stable yet, though. Use with care.

If method other than GET/HEAD is being used, whatever is in the
address line after ? is IGNORED.
Use L<url_param> (see below) if you intend to mix GET/POST parameters.

B<[NOTE]> C<param()> ALWAYS returns a single value, even in list context.
Use C<multi_param()> (see below) if you really want a list.

B<[NOTE]> C<param()> has I<nothing to do> with getting parameter list from request.
Instead, use form with wildcards:

    neaf form => "my_form" => [ [ 'guest\d+' => '.*'], [ 'arrival\d+' => '.*' ] ],
        engine => 'Wildcard';

    # later in controller
    my $guests = $req->form("my_form");
    $guests->fields; # has guest1 & arrival1, guest2 & arrival2 etc
    $guests->error;  # hash with values that didn't match regex

See L<MVC::Neaf::X::Form::Wildcard>.

=cut

sub param {
    my ($self, $name, $regex, $default) = @_;

    $regex ||= $self->{route}{param_regex}{$name};

    $self->_croak( "NEAF: param(): a validation regex is REQUIRED" )
        unless defined $regex;

    # Some write-through caching
    my $value = $self->_all_params->{ $name };

    return $default if !defined $value;
    return $value   if  $value =~ /^(?:$regex)$/s;

    if ($self->route->strict) {
        die 422; # TODO 0.30 configurable die message
    };
    return $default;
};

=head2 url_param( ... )

=over

=item * C<$req-E<gt>url_param( name =E<gt> qr/regex/ )>

=back

If method is GET or HEAD, identical to C<param>.

Otherwise would return the parameter from query string,
AS IF it was a GET request.

Dies if regular expression didn't match and the route has the C<strict> flag.

Multiple values are deliberately ignored.

See L<CGI>.

=cut

our %query_allowed = ( GET => 1, HEAD => 1);
sub url_param {
    my ($self, $name, $regex, $default) = @_;

    if ($query_allowed{ $self->method }) {
        return $self->param( $name, $regex, $default );
    };

    # HACK here - some lazy caching + parsing string by hand
    $self->{url_param_hash} ||= do {
        my %hash;

        foreach (split /[&;]/, $self->{query_string} || '' ) {
            /^(.*?)(?:=(.*))?$/ or next;
            $hash{$1} = $2;
        };

        # causes error w/o + (context issues?)
        # do decoding AFTER uniq'ing params (plus it was simpler to write)
        +{ map { decode_utf8(uri_unescape($_)) } %hash };
    };
    my $value = $self->{url_param_hash}{$name};

    # this is copypaste from param(), do something (or don't)
    return $default if !defined $value;
    return $value   if  $value =~ /^(?:$regex)$/s;

    if ($self->route->strict) {
        die 422; # TODO 0.30 configurable die message
    };
    return $default;
};

=head2 multi_param( ... )

=over

=item * C<$req-E<gt>multi_param( name =E<gt> qr/regex/ )>

=back

Get a multiple value GET/POST parameter as a C<@list>.
The name generally follows that of newer L<CGI> (4.08+).

ALL values must match the regex, or an empty list is returned.
Dies if strict mode if enabled for route and there is a mismatch.

B<[EXPERIMENTAL]> If C<param_regex> hash was given during route definition,
C<$regex> MAY be omitted for params that were listed there.
This feature is not stable yet, though. Use with care.

B<[EXPERIMENTAL]> This method's behavior MAY change in the future.
Please be careful when upgrading.

=cut

# TODO 0.90 merge multi_param, param, and _all_params
# backend mechanism.

sub multi_param {
    my ($self, $name, $regex) = @_;

    $regex ||= $self->{route}{param_regex}{$name};
    $self->_croak( "validation regex is REQUIRED" )
        unless defined $regex;

    my $ret = $self->{multi_param}{$name} ||= [
        map { decode_utf8($_) } $self->do_get_param_as_array( $name ),
    ];

    # ANY mismatch = no go. Replace with simple grep if want filter EVER.
    if (grep { !/^(?:$regex)$/s } @$ret) {
        die 422 if $self->route->strict;
        return ();
    } else {
        return @$ret;
    };
};

=head2 set_param( ... )

=over

=item * C<$req-E<gt>set_param( name =E<gt> $value )>

=back

Override form parameter. Returns self.

=cut

sub set_param {
    my ($self, $name, $value) = @_;

    $self->{cached_params}{$name} = $value;
    return $self;
};

=head2 form( ... )

=over

=item * C<$req-E<gt>form( $validator )>

=back

Apply validator to raw params and return whatever it returns.

A validator MUST be an object with C<validate> method, or a coderef,
or a symbolic name registered earlier via C<neaf form ...>.

Neaf's own validators, C<MVC::Neaf::X::Form> and C<MVC::Neaf::X::Form::LIVR>,
will return a C<MVC::Neaf::X::Form::Data> object with the following methods:

=over

=item * is_valid - tells whether data passed validation

=item * error - hash of errors, can also be modified if needed:

    $result->error( myfield => "Correct, but not found in database" );

=item * data - hash of valid, cleaned data

=item * raw - hash of data entered initially, may be useful to display
input form again.

=back

You are encouraged to use this return format from your own validation class
or propose improvements.

=cut

sub form {
    my ($self, $validator) = @_;

    if (!ref $validator) {
        $validator = $self->{route}->get_form( $validator )
            || $self->_croak("Unknown form name $validator");
    };

    my $result = (ref $validator eq 'CODE')
        ? $validator->( $self->_all_params )
        : $validator->validate( $self->_all_params );

    return $result;
};

=head2 get_form_as_list( ... )

=over

=item * C<$req-E<gt>get_form_as_list( qr/.../, qw(name1 name2 ...)  )>

=back

=head2 get_form_as_list( ... )

=over

=item * C<$req-E<gt>get_form_as_list( [ qr/.../, "default" ], qw(name1 name2 ...)  )>

=back

Return a group of uniform parameters as a list, in that order.
Values that fail validation are returned as C<undef>, unless default given.

B<[EXPERIMENTAL]> The name MAY be changed in the future.

=cut

sub get_form_as_list {
    my ($self, $spec, @list) = @_;

    $self->_croak( "Meaningless call in scalar context" )
        unless wantarray;

    $spec = [ $spec, undef ]
        unless ref $spec eq 'ARRAY';

    # Call the same validation over for each parameter
    return map { $self->param( $_, @$spec ); } @list;
};

sub _all_params {
    my $self = shift;

    return $self->{cached_params} ||= do {
        my $raw = $self->do_get_params;

        $_ = decode_utf8($_)
            for (values %$raw);

        $raw;
    };
};

=head2 body()

Returns request body for PUT/POST requests.
This is not regex-checked - the check is left for the user.

Also the data is NOT converted to C<utf8>.

=cut

sub body {
    my $self = shift;

    $self->{body} = $self->do_get_body
        unless exists $self->{body};
    return $self->{body};
};

=head2 upload_utf8( ... )

=head2 upload_raw( ... )

=over

=item * C<$req-E<gt>upload_utf8( "name" )>

Returns an L<MVC::Neaf::Upload> object corresponding to an uploaded file,
if such uploaded file is present.

All data read from such upload will be converted to unicode,
raising an exception if decoding ever fails.

An upload object has at least C<handle> and C<content> methods to work with
data:

    my $upload = $req->upload("user_file");
    if ($upload) {
        my $untrusted_filename = $upload->filename;
        my $fd = $upload->handle;
        while (<$fd>) {
            ...
        };
    }

or just

    if ($upload) {
        while ($upload->content =~ /(...)/g) {
            do_something($1);
        };
    };

=item * C<$req-E<gt>upload_raw( "name" )>

Like above, but no decoding whatsoever is performed.

=back

=cut

sub upload_utf8 {
    my ($self, $name) = @_;
    return $self->_upload( id => $name, utf8 => 1 );
};

sub upload_raw {
    my ($self, $name) = @_;
    return $self->_upload( id => $name, utf8 => 0 );
};

# TODO 0.30 do something about upload's content type
# TODO 0.30 and btw, restrict content types!
sub _upload {
    my ($self, %args) = @_;

    my $id = $args{id}
        or $self->_croak( "upload name is required for upload" );
    # caching undef as well, so exists()
    if (!exists $self->{uploads}{$id}) {
        my $raw = $self->do_get_upload( $id );
        $self->{uploads}{$id} = (ref $raw eq 'HASH')
            ? MVC::Neaf::Upload->new( %$raw, %args )
            : undef;
    };

    return $self->{uploads}{$id};
};

=head2 get_cookie( ... )

=over

=item * C<$req-E<gt>get_cookie( "name" =E<gt> qr/regex/ [, "default" ] )>

=back

Fetch client cookie.
The cookie MUST be sanitized by regular expression.

The regular expression is applied to the WHOLE string,
from beginning to end, not just the middle.
Use '.*' if you really need none.

Dies if regular expression didn't match and the route has the C<strict> flag.

=cut

sub get_cookie {
    my ($self, $name, $regex, $default) = @_;

    $default = '' unless defined $default;
    $self->_croak( "validation regex is REQUIRED")
        unless defined $regex;

    $self->{neaf_cookie_in} ||= do {
        my %hash;
        foreach ($self->header_in("cookie")) {
            while (/(\S+?)=([^\s;]*);?/g) {
                $hash{$1} = decode_utf8(uri_unescape($2));
            };
        };
        \%hash;
    };
    my $value = $self->{neaf_cookie_in}{ $name };
    return $default unless defined $value;

    return $value if $value =~ /^$regex$/;

    if ($self->route->strict) {
        die 422; # TODO 0.30 configurable die message
    };
    return $default;
};

=head2 set_cookie( ... )

=over

=item * C<$req-E<gt>set_cookie( name =E<gt> "value", %options )>

=back

Set HTTP cookie. C<%options> may include:

=over

=item * C<regex> - regular expression to check outgoing value

=item * C<ttl> - time to live in seconds.
0 means no C<ttl>.
Use negative C<ttl> and empty value to delete cookie.

=item * C<expire> - UNIX time stamp when the cookie expires
(overridden by C<ttl>).

=item * C<expires> - B<[DEPRECATED]> - use 'expire' instead (without trailing "s")

=item * C<domain>

=item * C<path>

=item * C<httponly> - flag

=item * C<secure> - flag

=back

Returns self.

=cut

sub set_cookie {
    my ($self, $name, $cook, %opt) = @_;

    defined $opt{regex} and $cook !~ /^$opt{regex}$/
        and $self->_croak( "output value doesn't match regex" );
    if (exists $opt{expires}) {
        # TODO 0.30 kill it and croak
        carp( "NEAF set_cookie(): 'expires' parameter DEPRECATED, use 'expire' instead" );
        $opt{expire} = delete $opt{expires};
    };

    # Zero ttl is ok and means "no ttl at all".
    if ($opt{ttl}) {
        $opt{expire} = time + $opt{ttl};
    };

    $self->{response}{cookie}{ $name } = [
        $cook, $opt{regex},
        $opt{domain}, $opt{path}, $opt{expire}, $opt{secure}, $opt{httponly}
    ];

    # TODO 0.90 also set cookie_in for great consistency, but don't
    # break reading cookies from backend by cache vivification!!!
    return $self;
};

=head2 delete_cookie( ... )

=over

=item * C<$req-E<gt>delete_cookie( "name" )>

=back

Remove cookie by setting value to an empty string,
and expiration in the past.
B<[NOTE]> It is up to the user agent to actually remove cookie.

Returns self.

=cut

sub delete_cookie {
    my ($self, $name) = @_;
    return $self->set_cookie( $name => '', ttl => -100000 );
};

# Set-Cookie: SSID=Ap4P….GTEq; Domain=foo.com; Path=/;
# Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly

=head2 format_cookies

Converts stored cookies into an arrayref of scalars
ready to be put into Set-Cookie header.

=cut

sub format_cookies {
    my $self = shift;

    my $cookies = $self->{response}{cookie} || {};

    my @out;
    foreach my $name (keys %$cookies) {
        my ($cook, $regex, $domain, $path, $expire, $secure, $httponly)
            = @{ $cookies->{$name} };
        next unless defined $cook; # TODO 0.90 erase cookie if undef?

        $path = "/" unless defined $path;
        defined $expire and $expire = http_date( $expire );
        my $bake = join "; ", ("$name=".uri_escape_utf8($cook))
            , defined $domain  ? "Domain=$domain" : ()
            , "Path=$path"
            , defined $expire ? "Expires=$expire" : ()
            , $secure ? "Secure" : ()
            , $httponly ? "HttpOnly" : ();
        push @out, $bake;
    };
    return \@out;
};

=head2 error( ... )

=over

=item * C<$req-E<gt>error( status )>

=back

Report error to the CORE.

This throws an C<MVC::Neaf::Exception> object.

If you're planning calling C<$req-E<gt>error> within C<eval> block,
consider using C<neaf_err> function to let it propagate:

    use MVC::Neaf::Exception qw(neaf_err);

    eval {
        $req->error(422)
            if ($foo);
        $req->redirect( "http://google.com" )
            if ($bar);
    };
    if ($@) {
        neaf_err($@);
        # The rest of the catch block
    };

=cut

sub error {
    my $self = shift;
    die MVC::Neaf::Exception->new(@_);
};

=head2 redirect( ... )

=over

=item * C<$req-E<gt>redirect( $location )>

=back

Redirect to a new location.

This throws an MVC::Neaf::Exception object.
See C<error()> discussion above.

=cut

sub redirect {
    my ($self, $location) = @_;

    die MVC::Neaf::Exception->new(
        -status   => 302,
        -location => $location,
        -content  => 'See '.$location,
        -type     => 'text/plain',
    );
};

=head2 header_in( ... )

=over

=item * C<header_in()> - return headers as-is

=item * C<$req-E<gt>header_in( "header_name" )>

=back

Fetch HTTP header sent by client.
Header names are canonized,
so C<Http-Header>, C<HTTP_HEADER> and C<http_header> are all the same.

Without argument, returns a L<HTTP::Headers::Fast> object.

With a name, returns all values for that header in list context,
or ", " - joined value as one scalar in scalar context -
this is actually a frontend to HTTP::Headers::Fast C<header()> method.

B<[NOTE]> No regex checks are made (yet) on headers, these may be added
in the future.

=cut

sub header_in {
    my ($self, $name) = @_;

    $self->{header_in} ||= $self->do_get_header_in;
    return $self->{header_in} unless defined $name;

    $name = lc $name;
    $name =~ s/-/_/g;
    return $self->{header_in}->header( $name );
};

=head2 referer

Get/set HTTP referrer - i.e. where the request pretends to come from.

B<[NOTE]> Avoid using this for anything serious/secure - too easy to forge.

=cut

sub referer {
    my $self = shift;
    if (@_) {
        $self->{referer} = shift
    } else {
        return $self->{referer} ||= $self->header_in( "referer" );
    };
};

=head2 user_agent

Get/set user_agent.

B<[NOTE]> Avoid using user_agent for anything serious - too easy to forge.

=cut

sub user_agent {
    my $self = shift;
    if (@_) {
        $self->{user_agent} = shift
    } else {
        $self->{user_agent} = $self->header_in("user_agent")
            unless exists $self->{user_agent};
        return $self->{user_agent};
    };
};

=head2 dump ()

Dump whatever came in the request. Useful for debugging.

=cut

sub dump {
    my $self = shift;

    my %raw;
    foreach my $method (qw( http_version scheme secure method hostname port
        path script_name
        referer user_agent )) {
            $raw{$method} = eval { $self->$method }; # deliberately skip errors
    };
    $raw{param} = $self->_all_params;
    $raw{header_in} = $self->header_in->as_string;
    $self->get_cookie( noexist => '' ); # warm up cookie cache
    $raw{cookie_in} = $self->{neaf_cookie_in};
    $raw{path_info} = $self->{postfix}
        if defined $self->{postfix};

    return \%raw;
};

=head1 SESSION MANAGEMENT

=head2 session()

Get reference to session data.
This reference is guaranteed to be the same throughout the request lifetime.

If MVC::Neaf->set_session_handler() was called during application setup,
this data will be initialized by that handler;
otherwise initializes with an empty hash (or whatever session engine generates).

If session engine was not provided, dies instead.

See L<MVC::Neaf::X::Session> for details about session engine internal API.

=cut

sub session {
    my $self = shift;

    if (my $sess = $self->load_session) {
        return $sess;
    };

    return $self->{session} = $self->{session_engine}->create_session;
};

=head2 load_session

Like above, but don't create session - just fetch from cookies & storage.

Never tries to load anything if session already loaded or created.

=cut

sub load_session {
    my $self = shift;

    # aggressive caching FTW
    return $self->{session} if exists $self->{session};

    $self->_croak("No session engine found, use Request->stash() for per-request data")
        unless $self->{session_engine};

    # Try loading session...
    my $id = $self->get_cookie( $self->{session_cookie}, $self->{session_regex} );
    my $hash = ($id && $self->{session_engine}->load_session( $id ));

    if ($hash && ref $hash eq 'HASH' && $hash->{data}) {
        # Loaded, cache it & refresh if needed
        $self->{session} = $hash->{data};

        $self->set_cookie(
            $self->{session_cookie} => $hash->{id}, expire => $hash->{expire} )
                if $hash->{id};
    };

    return $self->{session};
};

=head2 save_session( ... )

=over

=item * C<$req-E<gt>save_session( [$replace] )>

=back

Save whatever is in session data reference.

If argument is given, replace session (if any) altogether with that one
before saving.

=cut

sub save_session {
    my $self = shift;

    if (@_) {
        $self->{session} = shift;
    };

    return $self
        unless exists $self->{session_engine};

    # TODO 0.90 set "save session" flag, save later
    my $id = $self->get_cookie( $self->{session_cookie}, $self->{session_regex} );
    $id ||= $self->{session_engine}->get_session_id();

    my $hash = $self->{session_engine}->save_session( $id, $self->session );

    if ( $hash && ref $hash eq 'HASH' ) {
        # save successful - send cookie to user
        my $expire = $hash->{expire};

        $self->set_cookie(
            $self->{session_cookie} => $hash->{id} || $id,
            expire => $hash->{expire},
        );
    };

    return $self;
};

=head2 delete_session()

Remove session.

=cut

sub delete_session {
    my $self = shift;
    return unless $self->{session_engine};

    my $id = $self->get_cookie( $self->{session_cookie}, $self->{session_regex} );
    $self->{session_engine}->delete_session( $id )
        if $id;
    $self->delete_cookie( $self->{session_cookie} );
    return $self;
};

# TODO 0.90 This is awkward, but... Maybe optimize later
# TODO 0.90 Replace with callback generator (managed by cb anyway)
sub _set_session_handler {
    my ($self, $data) = @_;
    $self->{session_engine} = $data->[0];
    $self->{session_cookie} = $data->[1];
    $self->{session_regex}  = $data->[2];
    $self->{session_ttl}    = $data->[3];
};

=head1 REPLY METHODS

Typically, a Neaf user only needs to return a hashref with the whole reply
to client.

However, sometimes more fine-grained control is required.

In this case, a number of methods help stashing your data
(headers, cookies etc) in the request object until the response is sent.

Also some lengthly actions (e.g. writing request statistics or
sending confirmation e-mail) may be postponed until the request is served.

=head2 header_out( ... )

=over

=item * C<$req-E<gt>header_out( [$header_name] )>

=back

Without parameters returns a L<HTTP::Headers::Fast>-compatible object
containing all headers to be returned to client.

With one parameter returns this header.

Returned values are just proxied L<HTTP::Headers::Fast> returns.
It is generally advised to use them in list context as multiple
headers may return trash in scalar context.

E.g.

    my @old_value = $req->header_out( foobar => set => [ "XX", "XY" ] );

or

    my $old_value = [ $req->header_out( foobar => delete => 1 ) ];

B<[NOTE]> This format may change in the future.

=cut

sub header_out {
    my $self = shift;

    my $head = $self->{response}{header} ||= HTTP::Headers::Fast->new;
    return $head unless @_;

    my $name = shift;
    return $head->header( $name );
};

=head2 set_header( ... )

=head2 push_header( ... )

=head2 remove_header( ... )

=over

=item * C<$req-E<gt>set_header( $name, $value || [] )>

=item * C<$req-E<gt>push_header( $name, $value || [] )>

=item * C<$req-E<gt>remove_header( $name )>

=back

Set, append, and delete values in the header_out object.
See L<HTTP::Headers::Fast>.

Arrayrefs are fine and will set multiple values for a given header.

=cut

sub set_header {
    my ($self, $name, $value) = @_;
    return $self->header_out->header( $name, $value );
};

sub push_header {
    my ($self, $name, $value) = @_;
    return $self->header_out->push_header( $name, $value );
};

sub remove_header {
    my ($self, $name) = @_;
    return $self->header_out->remove_header( $name );
};

=head2 reply

Returns reply hashref that was returned by controller, if any.
Returns C<undef> unless the controller was actually called.
This may be useful in postponed actions or hooks.

This is killed by a C<clear()> call.

=cut

sub reply {
    my $self = shift;

    return $self->{response}{ret};
}

sub _set_reply {
    my ($self, $data) = @_;

    croak "Bareword forbidden in reply"
        unless ref $data and UNIVERSAL::isa($data, 'HASH');

    $self->{response}{ret} = $data;
    return $self;
}

=head2 stash( ... )

Stash (ah, the naming...) is a temporary set of data that only lives
throughtout request's lifetime and never gets to the client.

This may be useful to maintain shared data across hooks and callbacks.
Usage is as follows:

=over

=item * C<$req-E<gt>stash()> - get the whole stash as hash.

=item * C<$req-E<gt>stash( "name" )> - get a single value

=item * C<$req-E<gt>stash( %save_data )> - set multiple values, old data
is overridden rather than replaced.

=back

As a rule of thumb,

=over

=item * use C<session> if you intend to share data between requests;

=item * use C<reply> if you intend to render the data for the user;

=item * use C<stash> as a last resort for temporary, private data.

=back

Stash is not killed by C<clear()> function so that cleanup hooks aren't
botched accidentally.

=cut

sub stash {
    my $self = shift;
    my $st = $self->{stash} ||= {};
    return $st unless @_;

    return $st->{ $_[0] } unless @_>1;

    $self->_croak("Odd number of elements in hash assignment") if @_ % 2;
    my %new = @_;
    $st->{$_} = $new{$_} for keys %new;
    return $self;
};

=head2 postpone( ... )

=over

=item * C<$req-E<gt>postpone( CODEREF-E<gt>($request) )>

=item * C<$req-E<gt>postpone( [ CODEREF-E<gt>($request), ... ] )>

=back

Execute a function (or several) right after the request is served.

Can be called multiple times.

B<[CAVEAT]> If CODEREF contains reference to the request,
the request will never be destroyed due to circular reference.
Thus CODEREF may not be executed.

Don't pass request to CODEREF, use C<my $req = shift> instead.

Returns self.

=cut

sub postpone {
    my ($self, $code, $prepend_flag) = @_;

    $code = [ $code ]
        unless ref $code eq 'ARRAY';
    grep { ref $_ ne 'CODE' } @$code
        and $self->_croak( "argument must be a function or a list of functions" );

    $prepend_flag
        ? unshift @{ $self->{response}{postponed} }, reverse @$code
        : push    @{ $self->{response}{postponed} }, @$code;

    return $self;
};

=head2 write( ... )

=over

=item * C<$req-E<gt>write( $data )>

=back

Write data to client inside C<-continue> callback, unless C<close> was called.

Returns self.

=cut

sub write {
    my ($self, $data) = @_;

    $self->{continue}
        or $self->_croak( "called outside -continue callback scope" );

    $self->do_write( $data )
        if defined $data;
    return $self;
};

=head2 close()

Stop writing to client in C<-continue> callback.

By default, does nothing, as the socket will probably
be closed anyway when the request finishes.

=cut

sub close {
    my ($self) = @_;

    $self->{continue}
        or $self->_croak( "called outside -continue callback scope" );

    return $self->do_close();
}

=head2 clear()

Remove all data that belongs to reply.
This is called when a handler bails out to avoid e.g. setting cookies
in a failed request.

=cut

sub clear {
    my $self = shift;

    $self->_croak( "called after responding" )
        if $self->{continue};

    delete $self->{response};
    return $self;
}

=head1 DEVELOPER METHODS

=head2 id()

Fetch unique request id. If none has been set yet (see L</set_id>),
use L</make_id> method to create one.

The request id is present in both log messages from Neaf
and default error pages, making it easier to establish link
between the two.

Custom ids can be provided, see L</make_id> below.

=cut

sub id {
    my $self = shift;

    # We don't really need to protect anything here
    # Just avoid accidental matches for which md5 seems good enough
    return $self->{id} ||= $self->make_id;
};

=head2 set_id( ... )

=over

=item * C<$req-E<gt>set_id( $new_value )>

=back

Set the id above to a user-supplied value.

If a false value given, just generate a new one next time id is requested.

Symbols outside C<ascii>, as well as whitespace and C<"> and C"\",
are prohibited.

Returns the request object.

=cut

sub set_id {
    my ($self, $id) = @_;

    !$id or $id =~ /^[\x21-\x7E]+$/ && $id !~ /[\s\"\\]/
        or $self->_croak( "Bad id format, should only contain printable" );

    $self->{id} = $id;
    return $self;
};

=head2 log_error( ... )

=over

=item * C<$req-E<gt>log_error( $message )>

=back

Log an error message, annotated with request id and the route being processed.

Currently works via warn, but this may change in the future.

B<[EXPERIMENTAL]> This feature is still under development.

One can count on C<log_error> to be available in the future and do
some king of logging.

=cut

sub log_error {
    my ($self, $msg) = @_;
    $self->do_log_error( $self->_log_mark($msg) );
};

sub _where {
    my $self = shift;

    return $self->{prefix} || "pre_route";
};

sub _log_mark {
    my ($self, $msg) = @_;

    $msg ||= Carp::shortmess( "Something bad happened" );
    $msg =~ s/\s*$//s;

    return "req_id=".$self->id." in ".$self->_where.": $msg";
};

# See do_log_error below

# If called outside user's code, carp() will point at http server
#     which is misleading.
# So make a warn/die message that actually blames user's code
sub _message {
    my ($self, $message) = @_;

    return "NEAF: $message in handler ".$self->method." '".$self->script_name
        ."' at ".$self->endpoint_origin."\n";
};

=head2 execute_postponed()

NOT TO BE CALLED BY USER.

Execute postponed functions. This is called in DESTROY by default,
but request driver may decide it knows better.

Flushes postponed queue. Ignores exceptions in functions being executed.

Returns self.

=cut

sub execute_postponed {
    my $self = shift;

    $self->{continue}++;
    run_all_nodie( delete $self->{response}{postponed}, sub {
            # TODO 0.30 prettier error handling
            carp "NEAF WARN ".(ref $self).": postponed action failed: $@";
        }, $self );

    return $self;
};

sub DESTROY {
    my $self = shift;

    # TODO 0.90 Check that request isn't destroyed because of an exception
    # during sending headers
    # In this case we're gonna fail silently with cryptic warnings. :(
    $self->execute_postponed
        if (exists $self->{response}{postponed});
};

=head1 METHODS THAT CAN BE OVERRIDDEN

Generally Neaf allows to define custom Request methods restricted to certain
path & method combinations.

The following methods are available by default, but can be overridden
via the helper mechanism.

For instance,

    use MVC::Neaf;

    my $id;
    neaf helper => make_id => sub { $$ . "_" . ++$id };
    neaf helper => make_id => \&unique_secure_base64, path => '/admin';

=cut

sub _helper_fallback {
    my ($name, $impl) = @_;

    my $code = sub {
        my $self = shift;
        my $todo = $self->route && $self->route->helpers->{$name} || $impl;
        $todo->( $self, @_ );
    };

    $allow_helper{$name}++;

    no strict 'refs'; ## no critic
    use warnings FATAL => qw(all);
    *$name = $code;
};

=head2 make_id

Create unique request id, e.g. for logging context.
This is called by L</id> if the id has not yet been set.

By default, generates MD5 checksum based on time, hostname, process id, and a
sequential number and encodes as URL-friendly base64.

B<[CAUTION]> This should be unique, but may not be secure.
Use L<MVC::Neaf::X::Session> if you need something to rely upon.

=cut

my $host = Sys::Hostname::hostname();
my $lastid = 0;
_helper_fallback( make_id => sub {
    $lastid = 0 if $lastid > 4_000_000_000;
    encode_b64( md5( join "#", $host, $$, Time::HiRes::time, ++$lastid ) );
} );

=head2 log_message

    $req->log_message( $level => $message );

By default would print uppercased level, $request->id, route,
and the message itself.

Levels are not restricted whatsoever.
Suggested values are "fatal", "error", "warn", "debug".

=cut

_helper_fallback( log_message => sub {
    my ($req, $level, @mess) = @_;

    warn sprintf "%s req_id=%s [%s]: %s"
        , uc $level, $req->id, $req->_where, join " ", @mess;
});

=head1 DRIVER METHODS

The following methods MUST be implemented in every Request subclass
to create a working Neaf backend.

They SHOULD NOT be called directly inside the application.

=over

=item * do_get_client_ip()

=item * do_get_http_version()

=item * do_get_method()

=item * do_get_scheme()

=item * do_get_hostname()

=item * do_get_port()

=item * do_get_path()

=item * do_get_params()

=item * do_get_param_as_array() - get single GET/POST parameter in list context

=item * do_get_upload()

=item * do_get_body()

=item * do_get_header_in() - returns a L<HTTP::Headers>-compatible object.

=item * do_reply( $status, $content ) - write reply to client

=item * do_reply( $status ) - only send headers to client

=item * do_write( $data )

=item * do_close()

=item * do_log_error()

=back

=cut

foreach (qw(
    do_get_method do_get_scheme do_get_hostname do_get_port do_get_path
    do_get_client_ip do_get_http_version
    do_get_params do_get_param_as_array do_get_upload do_get_header_in
    do_get_body
    do_reply do_write)) {
    my $method = $_;
    my $code = sub {
        my $self = shift;
        croak ((ref $self || $self)."->$method() unimplemented!");
    };
    no strict 'refs'; ## no critic
    *$method = $code;
};

# by default, just skip - the handle will auto-close anyway at some point
sub do_close { return 1 };

# by default, write to STDERR - ugly but at least it will get noticed
sub do_log_error {
    my ($self, $msg) = @_;

    warn "NEAF: ERROR: $msg\n";
};

sub _croak {
    my ($self, $msg) = @_;

    my $where = [caller(1)]->[3];
    $where =~ s/.*:://;
    croak( (ref $self || $self)."->$where: $msg" );
};

=head1 DEPRECATED METHODS

Some methods become obsolete during Neaf development.
Anything that is considered deprecated will continue to be supported
I<for at least three minor versions> after official deprecation
and a corresponding warning being added.

Please keep an eye on C<Changes> though.

Here are these methods, for the sake of completeness.

=cut

=head2 script_name

See L</prefix>

=head2 path_info

See L</postfix>.

=head2 path_info_split

See L</prefix>

These three will start warning in 0.30 and will be removed in 0.40

=cut

# TODO 0.30 start warning "deprecated"
{
    no warnings 'once'; ## no critic
    use warnings FATAL => 'redefine';
    *script_name = \&prefix;
    *path_info = \&postfix;
    *path_info_split = \&splat;
}

=head2 header_in_keys ()

Return all keys in header_in object as a list.

B<[DEPRECATED]> Use C<$req-E<gt>header_in-E<gt>header_field_names> instead.

=cut

sub header_in_keys {
    my $self = shift;

    carp( (ref $self)."->header_in_keys: DEPRECATED, use header_in()->header_field_names instead" );
    my $head = $self->header_in;
    $head->header_field_names;
};

=head2 endpoint_origin

Returns file:line where controller was defined.

B<[DEPRECATED]> This function was added prematurely and shall not be used.

=cut

sub endpoint_origin {
    my $self = shift;

    return '(unspecified file):0' unless $self->{route}{caller};
    return join " line ", @{ $self->{route}{caller} }[1,2];
};

=head2 get_form_as_hash( ... )

=over

=item * C<$req-E<gt>get_form_as_hash( name =E<gt> qr/.../, name2 =E<gt> qr/..../, ... )>

=back

B<[DEPRECATED]> and dies. Use L<MVC::Neaf::X::Form> instead.

=cut

sub get_form_as_hash {
    my ($self, %spec) = @_;

    $self->_croak( "DEPRECATED. use neaf->add_form( name, ...) + \$req->form( name )" );
};

=head2 set_default( ... )

=over

=item * C<$req-E<gt>set_default( key =E<gt> $value, ... )>

=back

As of v.0.20 this dies.

Use path-based defaults, or stash().

=cut

sub set_default {
    my ($self, %args) = @_;

    # TODO 0.30 remove completely
    $self->_croak( "DEPRECATED. Use path-based defaults or stash()" );
};

=head2 get_default()

As of v.0.20 this dies.

Use path-based defaults, or stash().

=cut

sub get_default {
    my $self = shift;

    # TODO 0.30 remove completely
    $self->_croak( "DEPRECATED. Use path-based defaults or stash()" );
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
