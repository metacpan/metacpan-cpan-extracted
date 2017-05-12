=head1 NAME

MKDoc::Core::Plugin - Class for atomic MKDoc application functionality


=head1 SUMMARY

The L<MKDoc::Core> plugin system is a fundamental foundation for any application
which uses the L<MKDoc::Core> framework. Plugins are classes which are executed
one after the other in a predefined order.

The plugin processor (MKDoc::process) executes a list of plugins until one
(usually the one which handles the request) returns 'TERMINATE'.

=cut
package MKDoc::Core::Plugin;
use MKDoc::Core::Request;
use MKDoc::Core::Response;
use MKDoc::Core::Language;
use MKDoc::Core::Error;
use Petal;
use URI;
use strict;
use warnings;


sub _used_once { $::MKD_Current_Plugin };



=head1 Petal modifiers

=head2 plugin:

Instanciates a plugin of class plugin_type and returns it. This is handy if
you need to access the attributes methods of another plugin from the plugin
you're on, e.g:

    petal:define="details flo::plugin::Account::Details"

=cut
$Petal::Hash::MODIFIERS->{'plugin:'} = sub {
    my $hash  = shift;
    my $class = shift;
    my $file  = $class;
    $file =~ s/::/\//g;
    $file .= '.pm';

    for (@INC)
    {
        (-e "$_/$file") and do {
            require $file;
            last;
        };
    }

    return unless defined $INC{$file};
    return eval "$class->new()";
};



=head2 global:

Gives you access to any scalar variable stored in $::.
For example:

    petal:define="site_dir global: MKD__SITE_DIR"

=cut
$Petal::Hash::MODIFIERS->{'global:'} = sub {
    my $hash = shift;
    my $sym  = shift;
    return $ {$::{$sym}};
};



=head1 Methods

=head2 $self->equals ($otherplugin);

Returns TRUE if the class of $self is the same as the class of $otherplugin.

Since by default plugin objects do not have any data a class equivalence makes
sense, however this behavior can be subclassed as necessary.

=cut
sub equals
{
    my $self  = shift;
    my $thing = shift;
    return ref $self eq ref $thing;
}



=head2 $self->would_activate();

Returns TRUE if this plugin would activate if it was requested.
Returns FALSE otherwise.

For example:

    <span
        petal:define="details flo::plugin::Account::Details"
        petal:condition="details/would_activate"
    > ./.account.details can be accessed from here!</span>

For convenience, would_activate always returns FALSE if invoked on the same
class of plugin that is currently being activated. This is because usually,
hyperlinking to yourself is rather useless.

i.e. if you were using the piece of code above in the account details plugin
itself, details/would_activate would always return false.

=cut
sub would_activate
{
    my $self  = shift;
    return if ($self->is_current_plugin());

    my $class = ref $self || $self;

    # let's lie about what the path_info is...
    my $path_info = $self->location();

    local *MKDoc::Core::Request::path_info;
    *MKDoc::Core::Request::path_info = sub { $path_info };

    # go through plugin list and see if $self activates
    for (MKDoc::Core->plugin_list()) { return 1 if ($_ eq $class and $self->activate()) }

    return;
}



=head2 $thing->current_plugin();

Returns the current plugin which is being executed.

=cut
sub current_plugin
{
    return $::MKD_Current_Plugin;
}



=head2 $self->is_current_plugin();

Returns TRUE if $self is the plugin being currently executed, FALSE otherwise.

=cut
sub is_current_plugin
{   
    my $self = shift;
    return $self->equals ($self->current_plugin());
}



=head2 $self->main();

This class method is called by the MKDoc module.
Unless overriden it instantiates the current plugin and
checks to see if it should be activated.  If so it processes
the request by calling run(), otherwise it does nothing.

Returns 'TERMINATE' if the request was handled by this plugin,
false if not, or undef on error.

=cut
sub main
{
    my $class = shift || return;
    my $self  = $class->new (@_);
    return ($self->activate) ? do {   
        local $MKDoc::Core::Error::CALLBACK;
        $::MKDoc::Core::Error::CALLBACK = sub { $self->add_error (@_) };
        $self->run();
    } : undef;
}



=head2 $class->new();

Very basic constructor which instantiates a new object.
Calls the _initialize method.

=cut
sub new
{
    my $class = shift;
    $class    = ref $class || $class;
    my $self  = bless { @_ }, $class;
    $self->_initialize;
    return $self;
}



=head2 $self->_initialize();

Initializes this object, called by new().  This is empty, and
here to be overrided if necessary. Returns $self, or undef on
failure.

=cut
sub _initialize
{
    my $self = shift;
    return $self;
}



=head2 $self->run();

Runs the current plugin. If the request is a POST, runs
$self->http_post(). If it's a GET, runs $self->http_get().

=cut
sub run
{
    my $self = shift;
    my $meth = $self->request()->method();
    if ($meth =~ /^POST$/) { $self->http_post (@_) }
    else                   { $self->http_get  (@_) }
}


=head2 $self->http_get();

Processes an HTTP GET request.

=cut
sub http_get
{
    my $self = shift;
    $self->render_http (
        self       => $self,
        __input__  => 'XML',
        __output__ => 'XHTML',
       );
    return 'TERMINATE';
}


=head2 $self->http_post();

Processes an HTTP POST request.
Defaults http_get() by default.

=cut
sub http_post
{
    my $self = shift;
    return $self->http_get (@_);
}



=head2 $self->activate();

Returns TRUE if this plugin wants to be activated, FALSE otherwise.

By default it returns true if $self->location() equals the current
PATH_INFO.

=cut
sub activate
{
    my $self = shift;
    my $location  = $self->location()             || '';
    my $path_info = $self->request()->path_info() || '';
    return $location eq $path_info;
}



=head2 $self->uri();

By default, returns the L<URI> of the current plugin without any parameters.
However, this behavior can be overriden as follows:

  # http://example.com/.plugin
  $plugin->uri();
  
  # http://example.com/.plugin?foo=bar
  $plugin->uri (foo => 'bar');
  
  # http://example.com/.plugin?keep-original=parameters
  $plugin->uri ('parameters');
  
  # http://example.com/.plugin?keep-original=parameters;foo=bar
  $plugin->uri ( 'parameters', foo => 'bar');

=cut
sub uri
{
    my $self = shift;
    my $req  = $self->request->clone();

    if (defined $_[0] and $_[0] eq 'parameters')
    {
        shift (@_);
    }
    else
    {
        for ($req->param()) { $req->delete ($_) }
    }

    while (@_)
    {
        my $key = shift;
        my $val = shift;
        $req->param ($key, "$val");
    }

    $req->path_info ($self->location());
    return URI->new ( $req->url ( -full => 1, -path => 1, -query => 1 ) );
}



=head2 $self->uri_relative ($other);

Same this object's URI relative to $other. $other can be a L<URI> object,
a SCALAR representing a URI, or an object which MUST have a uri() method.

=cut
sub uri_relative
{
    my $self = shift;
    my $other_uri = shift;

    # if we already have a URI object, everything's good.
    ref $other_uri and $other_uri->isa ('URI') and do {
        return $self->uri()->rel ($other_uri);
    };

    # if we have some kind of object that's not a URI, use
    # $object->uri()
    ref $other_uri and return $self->uri_relative ($other_uri->uri());

    # finally, we must have a scalar representing the URI...
    return $self->uri_relative (URI->new ($other_uri));
}



=head2 $self->language();

Returns a L<MKDoc::Language> object which represents the preferred language
to be used for this plugin. By order of preference:

=over

=item looks into $ENV{HTTP_ACCEPT_LANGUAGE}

=item looks at $ENV{MKD__DEFAULT_LANGUAGE}

=item new MKDoc::Language ('en')

=back

=cut
sub language
{
    my $self = shift;
    $self->{'.language'} ||= do {
        my $default = $ENV{MKD__DEFAULT_LANGUAGE} || 'en';
        my $lang    = $ENV{HTTP_ACCEPT_LANGUAGE} || '';

        $lang =~ s/^\s*//;
        $lang =~ s/,.*$//;
        
        new MKDoc::Core::Language ( $lang ) || new MKDoc::Core::Language ( $default );
    };
    
    return $self->{'.language'};
}



=head2 $self->HTTP_Content_Type();

Returns the content-type associated with this plugin.
By default, returns "text/html; charset=UTF-8"

=cut
sub HTTP_Content_Type { "text/html; charset=UTF-8" }



=head2 $self->has_errors();

Returns TRUE if the current plugin object holds error that needs
to be displayed, false otherwise.

=cut
sub has_errors
{
    my $self = shift;
    my $errors = $self->errors;
    return scalar @{$errors};
}



=head2 $self->errors();

Returns a list of errors, or an array ref in scalar context.

=cut
sub errors
{
    my $self = shift;
    return (defined $self->{'.errors'}) ?
        $self->{'.errors'} :
        [];
}



=head2 $self->add_error (@_);

Adds all the errors in @_ to the current plugin object.

=cut
sub add_error
{
    my $self = shift;
    $self->{'.errors'} ||= [];
    push @{$self->{'.errors'}}, @_;
}



=head2 $self->render_http

Renders the current object with render().
Sets the response object.

Explores all the inherited HTTP_ methods and sets
HTTP headers accordingly.

=cut
sub render_http
{
    my $self = shift || return;
    my $data = $self->render (@_) || return;
    my $resp = $self->response();

    use bytes;
    $resp->Body ($data);

    foreach my $method ( $self->_render_http_headers )
    {
        my $set_method = $method;
        $set_method =~ s/^HTTP_//;

        my $del_method = "delete_$set_method";

        my $value = $self->$method();
        if (defined $value) { $resp->$set_method ($value) }
        else                { $resp->$del_method()        }
    }
    
    $resp->out();
}



=head2 $this->_render_http_headers()

Recursively introspects $this and its base classes and find
all methods which starts with HTTP_. Returns a list of methods
found.

This little hack is written so that you can simply add HTTP
headers by defining methods, e.g.

  sub HTTP_X_Bender { "Bite my shiny, metal ass!" }

Will set the following header:

  X-Bender: Bite my shiny, metal ass!

=cut
sub _render_http_headers
{
    my $class = shift;
    $class = ref $class || $class;

    my %refs  = do {
        no strict 'refs';
        map { $_ => 1 }
          grep /^HTTP_/,
            keys %{*{$class . "::"}}
    };

    my %more_refs = do {
        no strict 'refs';
        map { $_ => 1 }
          map { $_->_render_http_headers }
            @{*{$class . "::ISA"}}
    };

    my %result = (%refs, %more_refs);
    return keys %result;
}



=head2 $self->render (%args);

Renders the current object, passing %args to the template being used.
Intercepts '__input__' and '__output__' to set Petal processing vars.

Returns the rendered document on success, or undef on error.
See template_path().

=cut
sub render
{
    my $self = shift;
    my $hash = (ref $_[0]) ? shift : { @_ };
    $Petal::DISK_CACHE   = 1;
    $Petal::MEMORY_CACHE = 1;
    $Petal::INPUT        = $hash->{__input__}  || 'XML';
    $Petal::OUTPUT       = $hash->{__output__} || 'XML';

    my $template = new Petal
        language => $self->language()->code(),
        file     => $self->template_path();

    my $data = $template->process ( @_ );
    return $data;
}



=head2 $self->env()

Returns the environment variables as a hash reference.

=cut
sub env
{
    my $self = shift;
    return \%ENV;
}



=head2 $self->env_keys();

Returns the environment variables keys as an array or an array ref
depending on the context.

=cut
sub env_keys
{
    my $self = shift;
    my @res  = sort keys %ENV;
    return wantarray ? @res : \@res;
}



=head2 $self->env_value ($key);

Returns the environment variable value for $key, i.e.

    my $path_info = $self->env_value ('PATH_INFO');

=cut
sub env_value
{
    my $self = shift;
    my $key  = shift;
    return $ENV{$key};
}


=head2 $self->template_path();

Returns the template path relative to Petal @BASE_DIR directories.

By default if your plugin is called something like:

  Foo::Bar::Plugin::Hello::World

It will return:

  /hello/world/

This method is subclassable.

=cut
sub template_path
{
    my $self  = shift;
    my $class = ref $self || $self;
    $class =~ s/MKDoc:://;
    $class =~ s/Plugin:://;
    $class = lc ($class);
    $class =~ s/::/\//g;
    return "/$class/";
}



=head2 $self->location();

Returns the location of the current plugin. By default, returns
the current PATH_INFO.

=cut
sub location
{
    my $self = shift;
    return $self->request()->path_info();
}



=head2 $self->request();

Returns the MKDoc::Core::Request object singleton.

=cut
sub request
{
    return MKDoc::Core::Request->instance();
}



=head2 $self->response();

Returns the MKDoc::Core::Response object singleton.

=cut
sub response
{
    return MKDoc::Core::Response->instance();
}



=head2 $self->return_uri();

Some plugins have a need to redirect to a return uri once they have finished
processing. This is usually the case with POST request. This method tries to
provide a sensible default:

=over 4

=item it looks for a return_uri parameter

=item otherwise it looks in $ENV{HTTP_REFERER}

=item otherwise it returns the root of the website by setting path_info to '/'.

=back

=cut
sub return_uri
{
    my $self = shift;
    my $req  = $self->request()->clone();
    return $req->param ('return_uri') || $ENV{HTTP_REFERER} || do {
        $req->path_info ('/');
        $req->delete ($_) for ($req->param());
        $req->self_uri();
    };
}


1;


__END__


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal> TAL for perl
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk
