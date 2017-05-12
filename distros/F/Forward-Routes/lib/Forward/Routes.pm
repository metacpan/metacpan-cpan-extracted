package Forward::Routes;
use strict;
use warnings;

use 5.010001;

use Forward::Routes::Match;
use Forward::Routes::Pattern;
use Forward::Routes::Resources;
use Scalar::Util qw/weaken/;
use Carp 'croak';

our $VERSION = '0.56';


## ---------------------------------------------------------------------------
##  Constructor
## ---------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self->initialize(@_);
}


sub initialize {
    my $self = shift;

    # block
    my $code_ref = pop @_ if @_ && ref $_[-1] eq 'CODE';

    # inherit
    $self->{_inherit_format} = 1;
    $self->{_inherit_via} = 1;
    $self->{_inherit_namespace} = 1;
    $self->{_inherit_app_namespace} = 1;

    # Pattern
    my $pattern = @_ % 2 ? shift : undef;
    $self->pattern->pattern($pattern) if defined $pattern;

    # Shortcut in case of chained API
    return $self unless @_ || $code_ref;

    # Remaining params
    my $params = ref $_[0] eq 'HASH' ? {%{$_[0]}} : {@_};

    $self->format(delete $params->{format}) if exists $params->{format};
    $self->via(delete $params->{via}) if exists $params->{via};
    $self->namespace(delete $params->{namespace}) if exists $params->{namespace};
    $self->app_namespace(delete $params->{app_namespace}) if exists $params->{app_namespace};
    $self->defaults(delete $params->{defaults});
    $self->name(delete $params->{name});
    $self->to(delete $params->{to});
    $self->constraints(delete $params->{constraints});
    $self->resource_name(delete $params->{resource_name});

    # after inheritance
    $code_ref->($self) if $code_ref;

    return $self;
}


## ---------------------------------------------------------------------------
##  Routes tree
## ---------------------------------------------------------------------------

sub add_route {
    my $self = shift;
    my (@params) = @_;

    my $child = Forward::Routes->new(@params);

    return $self->add_child($child);
}


sub add_resources {
    my $self = shift;
    my $params = [@_];

    $params = Forward::Routes::Resources->_prepare_resource_options(@$params);

    my $last_resource;

    while (my $name = shift @$params) {

        my $options;
        if (@$params && ref $params->[0] eq 'HASH') {
            $options = shift @$params;
        }

        $last_resource = $self->_add_plural_resource($name, $options);
    }

    return $last_resource;
}


sub _add_plural_resource {
    my $self = shift;
    my ($resource_name, $options) = @_;

    my $resource = Forward::Routes::Resources::Plural->new($resource_name,
        resource_name => $options->{as} // $resource_name,
        %$options
    );
    $resource->init_options($options);

    $resource->_adjust_nested_resources($self);

    $self->add_child($resource);

    # after _adjust_nested_resources because parent name is needed for route name
    # after add_child because of namespace inheritance for route name
    $resource->preprocess;
   
    $resource->inflate;
    
    return $resource;
}


sub add_singular_resources {
    my $self = shift;
    my $params = [@_];

    $params = Forward::Routes::Resources->_prepare_resource_options(@$params);

    my $last_resource;

    while (my $name = shift @$params) {

        my $options;
        if (@$params && ref $params->[0] eq 'HASH') {
            $options = shift @$params;
        }

        $last_resource = $self->_add_singular_resource($name, $options);
    }

    return $last_resource;
}


sub _add_singular_resource {
    my $self = shift;
    my ($resource_name, $options) = @_;

    my $resource = Forward::Routes::Resources::Singular->new($resource_name,
        resource_name => $options->{as} // $resource_name,
        %$options
    );
    $resource->init_options($options);

    $resource->_adjust_nested_resources($self);

    $self->add_child($resource);

    # after _adjust_nested_resources because parent name is needed for route name
    # after add_child because of namespace inheritance for route name
    $resource->preprocess;
   
    $resource->inflate;
    
    return $resource;
}


sub bridge {
    my $self = shift;
    return $self->add_route(@_)->_is_bridge(1);
}


sub children {
    my $self = shift;
    return $self->{children} ||= [];
}


sub parent {
    my $self = shift;
    my ($value) = @_;
    return $self->{parent} unless $value;
    
    $self->{parent} = $value;
    weaken $self->{parent};
    return $self;
}


sub add_child {
    my $self = shift;
    my ($child) = @_;

    # child
    push @{$self->children}, $child;

    # parent
    $child->parent($self);

    # inheritance
    $child->format(        [@{$self->{format}}]   ) if $self->{format}        && $child->_inherit_format;
    $child->via(           [@{$self->{via}}]      ) if $self->{via}           && $child->_inherit_via;
    $child->namespace(     $self->{namespace}     ) if $self->{namespace}     && $child->_inherit_namespace;
    $child->app_namespace( $self->{app_namespace} ) if $self->{app_namespace} && $child->_inherit_app_namespace;

    return $child;
}


## ---------------------------------------------------------------------------
##  Route attributes
## ---------------------------------------------------------------------------

sub app_namespace {
    my $self = shift;
    my (@params) = @_;

    return $self->{app_namespace} unless @params;

    $self->{_inherit_app_namespace} = 0;

    $self->{app_namespace} = $params[0];

    return $self;
}


sub constraints {
    my $self = shift;

    return $self->pattern->constraints unless defined $_[0];

    $self->pattern->constraints(@_);

    return $self;
}


sub defaults {
    my $self = shift;
    my (@params) = @_;

    # Initialize
    my $d = $self->{defaults} ||= {};

    # Getter
    return $d unless defined $params[0];

    # Hash ref or array?
    my $passed_defaults = ref $params[0] eq 'HASH' ? $params[0] : {@params};

    # Merge defaults
    %$d = (%$d, %$passed_defaults);

    return $self;
}


sub format {
    my $self = shift;
    my (@params) = @_;

    return $self->{format} unless @params;

    $self->{_inherit_format} = 0;

    # no format constraint, no format matching performed
    if (!defined($params[0])) {
        $self->{format} = undef;
        return $self;
    }

    my $formats = ref $params[0] eq 'ARRAY' ? $params[0] : [@params];

    @$formats = map {lc $_} @$formats;

    $self->{format} = $formats;

    return $self;
}


sub name {
    my $self = shift;
    my ($name) = @_;

    return $self->{name} unless defined $name;

    $self->{name} = $name;

    return $self;
}


sub resource_name {
    my $self = shift;
    my ($name) = @_;

    return $self->{resource_name} unless defined $name;

    $self->{resource_name} = $name;
    return $self;
}


sub namespace {
    my $self = shift;
    my (@params) = @_;

    return $self->{namespace} unless @params;

    $self->{_inherit_namespace} = 0;

    $self->{namespace} = $params[0];

    return $self;
}


sub pattern {
    my $self = shift;
    my (@params) = @_;

    $self->{pattern} ||= Forward::Routes::Pattern->new;

    return $self->{pattern} unless @params;

    $self->{pattern}->pattern(@params);

    return $self;
}


sub via {
    my $self = shift;
    my (@params) = @_;

    return $self->{via} unless @params;

    $self->{_inherit_via} = 0;

    if (!defined $params[0]) {
        $self->{via} = undef;
        return $self;
    }

    my $methods = ref $params[0] eq 'ARRAY' ? $params[0] : [@params];

    @$methods = map {lc $_} @$methods;

    $self->{via} = $methods;

    return $self;
}


sub to {
    my $self = shift;
    my ($to) = @_;

    return unless $to;

    my $params;
    @$params{qw/controller action/} = split '#' => $to;

    $params->{controller} ||= undef;

    return $self->defaults($params);
}


sub _is_bridge {
    my $self = shift;

    return $self->{_is_bridge} unless defined $_[0];

    $self->{_is_bridge} = $_[0];

    return $self;
}


sub _inherit_format {
    my $self = shift;
    $self->{_inherit_format};
}


sub _inherit_via {
    my $self = shift;
    $self->{_inherit_via};
}


sub _inherit_namespace {
    my $self = shift;
    $self->{_inherit_namespace};
}


sub _inherit_app_namespace {
    my $self = shift;
    $self->{_inherit_app_namespace};
}


sub _is_plural_resource {
    my $self = shift;
    return ref $self eq 'Forward::Routes::Resources::Plural' ? 1 : 0;
}


sub _is_singular_resource {
    my $self = shift;
    return ref $self eq 'Forward::Routes::Resources::Singular' ? 1 : 0;
}


## ---------------------------------------------------------------------------
##  Path matching and search
## ---------------------------------------------------------------------------

sub find_route {
    my $self = shift;
    my ($name) = @_;

    $self->{routes_by_name} ||= {};
    return $self->{routes_by_name}->{$name} if $self->{routes_by_name}->{$name};

    return $self if $self->name && $self->name eq $name;

    foreach my $child (@{$self->children}) {
        my $match = $child->find_route($name, @_);
        $self->{routes_by_name}->{$name} = $match if $match;
        return $match if $match;
    }

    return undef;
}


sub routes_by_name {
    my $self = shift;
    return $self->{routes_by_name};
}


sub match {
    my $self = shift;
    my ($method, $path) = @_;

    length $method || croak 'Forward::Routes->match: missing request method';
    defined $path || croak 'Forward::Routes->match: missing path';

    # Leading slash
    $path = "/$path" unless $path =~ m{ \A / }x;

    # Search for match
    my $matches = $self->_match(lc($method) => $path);
    return unless $matches;

    my $m = $matches->[-1];
    for (my $i=0; $i<(@$matches-1); $i++) {
        $matches->[$i]->_set_params({%{$m->params}, %{$matches->[$i]->params}}); # all params except controller and action
        $matches->[$i]->_set_captures($m->captures);
        $matches->[$i]->_set_name($m->name);
    }

    return $matches;
}


sub _match {
    my $self = shift;
    my ($method, $path, $format_extracted_from_path, $last_path_part, $last_pattern) = @_;

    # re-evaluate last path part if format changes from undef to def or vice versa
    # and last path part has already been checked (empty path)
    my $re_eval_pattern;
    if (!(length $path) && defined($self->format) ne defined($self->parent->format)) {
        $path = $last_path_part;
        $re_eval_pattern = 1;
    }


    # change from def to undef format -> add format extension back to path
    # (reverse format extraction)
    if (!(defined $self->format) && $self->parent && defined $self->parent->format) {
        $path .= '.' . $format_extracted_from_path if $format_extracted_from_path ne '';
        $format_extracted_from_path = undef;
    }


    # use pattern of current route, or if it does not exist and path has to be
    # re-evaluated because of format change, use last pattern
    my $pattern;
    if (defined $self->pattern->pattern) {
        $pattern = $self->pattern;
    }
    elsif ($re_eval_pattern) {
        $pattern = $last_pattern;
    }
    else {
        $pattern = undef;
    }


    # extract format from path if not already done and format option is activated
    if ($self->format && !(defined $format_extracted_from_path)) {
        $path =~m/\.([\a-zA-Z0-9]{1,4})$/;
        $format_extracted_from_path = defined $1 ? $1 : '';

        $path =~s/\.[\a-zA-Z0-9]{1,4}$// if $format_extracted_from_path ne '';
    }


    # match current pattern or return
    my $captures = [];
    if ($pattern) {
        ($captures, $last_path_part, $last_pattern) = $self->_match_current_pattern(\$path, $pattern);
        $captures || return;
    }

    # no match, as path not empty and no further children exist
    return if length $path && !@{$self->children};

    # Children match
    my $matches = [];

    # Children
    if (@{$self->children}) {
        foreach my $child (@{$self->children}) {

            # Match?
            $matches = $child->_match($method => $path, $format_extracted_from_path, $last_path_part, $last_pattern);
            last if $matches;

        }
        return unless $matches;
    }


    # Format and Method
    unless (@{$self->children}) {
        $self->_match_method($method) || return;
        $self->_match_format($format_extracted_from_path) || return;
    }

    # Match object
    if (!@$matches){
        my $m = Forward::Routes::Match->new;
        $m->_set_name($self->name);
        $m->_set_app_namespace($self->app_namespace);
        $m->_set_namespace($self->namespace);

        if ($self->{format}) {
            $m->_add_params({format => $format_extracted_from_path});
        }

        push @$matches, $m;
    }

    if ($self->_is_bridge) {
        my $m = Forward::Routes::Match->new;
        $m->_set_app_namespace($self->app_namespace);
        $m->_set_namespace($self->namespace);

        $m->is_bridge(1);

        $m->_add_params({
            controller => $self->defaults->{controller},
            action     => $self->defaults->{action}
        });

        unshift @$matches, $m;
    }

    my $match = $matches->[-1];

    my $captures_hash = {};
    if ($pattern) {
        $captures_hash = $self->_captures_to_hash($pattern, @$captures);
    }

    # Merge defaults and captures, Copy! of $self->defaults
    $match->_add_params({%{$self->defaults}, %$captures_hash});

    # Captures
    $match->_add_captures($captures_hash);

    return $matches;
}


sub _match_current_pattern {
    my $self = shift;
    my ($path_ref, $pattern) = @_;

    my $last_path_part = $$path_ref;

    # Pattern
    my $regex = $pattern->compile->pattern;

    my @captures = ($$path_ref =~ m/$regex/);
    return unless @captures;

    # Remove 1 at the end of array if no real captures present
    splice @captures, @{$pattern->captures};

    # Replace matching part
    $$path_ref =~ s/$regex//;

    if (length($last_path_part) && !(length $$path_ref)) {
        return (\@captures, $last_path_part, $pattern);
    }

    return \@captures;
}


sub _match_format {
    my $self = shift;
    my ($format) = @_;

    # just relevant for path building, not path matching, as $format
    # is only extraced if format constraint exists ($self->format)
    return if !defined($self->format) && defined($format);

    return 1 if !defined($self->format);

    my @success = grep { $_ eq $format } @{$self->format};

    return unless @success;

    return 1;
}


sub _match_method {
    my $self = shift;
    my ($value) = @_;

    return 1 unless defined $self->via;

    return unless defined $value;

    return !!grep { $_ eq $value } @{$self->via};
}


sub _captures_to_hash {
    my $self = shift;
    my ($pattern, @captures) = @_;

    my $captures = {};

    my $defaults = $self->{defaults};

    foreach my $name (@{$pattern->captures}) {
        my $capture = shift @captures;

        if (defined $capture) {
            $captures->{$name} = $capture;
        }
        else {
            $captures->{$name} = $defaults->{$name} if defined $defaults->{$name};
        }
    }

    return $captures;
}


## ---------------------------------------------------------------------------
##  Path building
## ---------------------------------------------------------------------------

sub build_path {
    my $self = shift;
    my ($name, %params) = @_;

    my $route = $self->find_route($name);
    croak qq/Unknown name '$name' used to build a path/ unless $route;

    my $path_string = $route->_build_path(\%params);
    my $path = {};
    $path->{path} = $path_string;

    # format extension
    my $format;
    if ($format = $params{format}) {
        $route->_match_format($format) || die qq/Invalid format '$format' used to build a path/;
    }
    $format ||= $route->format ? $route->format->[0] : undef;
    $path->{path} .= '.' . $format if $format;


    # Method
    $path->{method} = $route->via->[0] if $route->via;

    $path->{path} =~s/^\///;

    return $path;
}


sub _build_path {
    my $self = shift;
    my ($params) = @_;

    my $path = '';

    if ($self->{parent}) {
        $path = $self->{parent}->_build_path($params);
    }

    # Return path if current route has no pattern
    return $path unless $self->{pattern} && defined $self->{pattern}->pattern;

    $self->{pattern}->compile;

    # Use pre-generated pattern->path in case no captures exist for current route
    if (my $new_path = $self->{pattern}->path) {
        $path .= $new_path;
        return $path;
    }

    # Path parts by optional level
    my $parts = {};

    # Capture is required if other captures have already been defined in same optional group
    my $existing_capture = {};

    # No captures allowed if other captures empty in same optional group
    my $empty_capture = {};

    # Optional depth
    my $depth = 0;

    foreach my $part (@{$self->{pattern}->parts}) {
        my $type = $part->{type};
        my $name = $part->{name} || '';

        # Open group
        if ($type eq 'open_group') {
            $depth++ if ${$part->{optional}};
            next;
        }

        if ($type eq 'close_group') {

            # Close optional group          
            if (${$part->{optional}}) {

                # Only pass group content to lower levels if captures have values
                if ($existing_capture->{$depth}) {
    
                    # push data to optional level
                    push @{$parts->{$depth-1}}, @{$parts->{$depth}};
    
                    # error, if lower level optional group has emtpy captures, but current
                    # optional group has filled captures
                    $self->capture_error($empty_capture->{$depth-1})
                      if $empty_capture->{$depth-1};
    
                    # all other captures in lower level must have values now
                    $existing_capture->{$depth-1} += $existing_capture->{$depth};
                }
    
                $existing_capture->{$depth} = 0;
                $empty_capture->{$depth} = undef;
                $parts->{$depth} = [];
    
                $depth--;
    
                next;
            }
            # Close non optional group
            else {
                next;
            }

        }

        my $path_part;

        # Capture
        if ($type eq 'capture') {

            # Param
            $path_part = $params->{$name};
            $path_part = defined $path_part && length $path_part ? $path_part : $self->{defaults}->{$name};

            if (!$depth && !defined $path_part) {
                $self->capture_error($name);
            }
            elsif ($depth && !defined $path_part) {

                # Capture value has to be passed if other captures in same
                # group have already been passed

                $self->capture_error($name) if $existing_capture->{$depth};

                # Save capture as empty as following captures in same group
                # have to be empty as well
                $empty_capture->{$depth} = $name;

                next;

            }
            elsif ($depth && defined $path_part) {

                # Earlier captures in same group can not be empty
                $self->capture_error($empty_capture->{$depth})
                  if $empty_capture->{$depth};

                $existing_capture->{$depth} = 1;
            }

            # Constraint
            my $constraint = $part->{constraint};
            if (defined $constraint) {
                croak qq/Param '$name' fails a constraint/
                  unless $path_part =~ m/^$constraint$/;
            }

        }
        # Globbing
        elsif ($type eq 'glob') {
            my $name = $part->{name};

            croak qq/Required glob param '$name' was not passed when building a path/
              unless exists $params->{$name};

            $path_part = $params->{$name};
        }
        # Text
        elsif ($type eq 'text') {
            $path_part = $part->{text};
        }
        # Slash
        elsif ($type eq 'slash') {
            $path_part = '/';
        }

        # Push param in optional group array
        push @{$parts->{$depth}}, $path_part;

    }

    my $new_path = join('' => @{$parts->{0}});

    if ($self->{parent}) {
        $path .= $new_path;
    }
    else {
        $path = $new_path;
    }

    return $path;

}


sub capture_error {
    my $self = shift;
    my ($capture_name) = @_;

    croak qq/Required param '$capture_name' was not passed when building a path/;
}


## ---------------------------------------------------------------------------
##  Helpers
## ---------------------------------------------------------------------------

# overwrite code ref for more advanced approach:
# sub {
#     require Lingua::EN::Inflect::Number;
#     return &Lingua::EN::Inflect::Number::to_S($value);
# }
sub singularize {
    my $self = shift;
    my ($code_ref) = @_;

    # Initialize very basic singularize code ref
    $Forward::Routes::singularize ||= sub {
        my $value = shift;

        if ($value =~ s/ies$//) {
            $value .= 'y';
        }
        else {
            $value =~ s/s$//;
        }

        return $value;
    };

    return $Forward::Routes::singularize unless $code_ref;

    $Forward::Routes::singularize = $code_ref;

    return $self;

}


sub format_resource_controller {
    my $self = shift;
    my ($code_ref) = @_;

    $Forward::Routes::format_controller ||= sub {
        my $value = shift;

        my @parts = split /-/, $value;
        for my $part (@parts) {
            $part = join '', map {ucfirst} split /_/, $part;
        }
        return join '::', @parts;
    };

    return $Forward::Routes::format_controller unless $code_ref;

    $Forward::Routes::format_controller = $code_ref;

    return $self;
}



1;
__END__
=head1 NAME

Forward::Routes - restful routes for web framework developers

=head1 DESCRIPTION

Instead of letting a web server like Apache decide which files to serve based
on the provided URL, the whole work can be done by your framework using the
L<Forward::Routes> module.

Ruby on Rails and Perl's Mojolicious make use of routes. Forward::Routes, in
contrast to that, tries to provide the same or even better functionality
without the tight couplings with a full featured framework.

Think of routes as kind of simplified regular expressions! First of all, a
bunch of routes is defined. Each route contains information on

=over 2

=item *

what kind of URLs to match

=item *

what to do in case of a match

=back

Finally, the request method and path of a users HTTP request are passed to
search for a matching route.


=head2 1. Routes setup

Each route represents a specific URL or a bunch of URLs (if placeholders are
used). The URL path pattern is defined via the C<add_route> command. A route
also contains information on what to do in case of a match. A common use
case is to provide controller and action defaults, so the framework knows
which controller method to execute in case of a match:

    # create a routes root object
    my $routes = Forward::Routes->new;

    # add a new route with a :city placeholder and controller and action defaults
    $routes->add_route('/towns/:city')->defaults(controller => 'World', action => 'cities');

=head2 2. Search for a matching route

After the setup has been done, the method and path of a current HTTP request
can be passed to the routes root object to search for a matching route.

The match method returns an array ref of L<Forward::Routes::Match> objects in
case of a match, or undef if there is no match. Unless advanced techniques
such as bridges are used, the array ref contains no more than one match object
($matches->[0]).

    # get request path and method (e.g. from a Plack::Request object)
    my $path   = $req->path_info;
    my $method = $req->method;

    # search routes
    my $matches = $routes->match($method => $path);

The search ends as soon as a matching route has been found. As a result, if
there are multiple routes that might match, the route that has been defined
first wins.

    # $matches is an array ref of Forward::Routes::Match objects
    my $matches = $routes->match(GET => '/towns/paris');

    # exactly one match object is returned:
    # $match is a Forward::Routes::Match object
    my $match = $matches->[0];

    # $match->params->{controller} is "World"
    # $match->params->{action}     is "cities"
    # $match->params->{city}       is "paris"

Controller and action parameters can be used by your framework to execute the
desired controller method, while making default and placeholder values of the
matching route available to that method for further use.

If the passed path and method do not match against a defined route, an
undefined value is returned. Frameworks might render a 404 not found page in
such cases.

    # $matches is undef
    my $matches = $routes->match(get => '/hello_world');

The match object holds two types of parameters:

=over 2

=item *

default values of the matching route as defined earlier via the "defaults"
method

=item *

placeholder values extracted from the passed URL path

=back


=head1 FEATURES AND METHODS

=head2 Add new routes

The C<add_route> method adds a new route to the parent route object (in simple
use cases, to the routes root object) and returns the new route object.

The passed parameter is the URL path pattern of the new route object. The URL
path pattern is kind of a simplified reqular expression for the path part of a
URL and is transformed to a real regular expression internally. It is used
later on to check whether the passed request path matches the route.

    $root = Forward::Routes->new;
    my $new_route = $root->add_route('foo/bar');

    my $m = $root->match(get => 'foo/bar');
    # $m->[0]->params is {}

    my $m = $r->match(get => 'foo/hello');
    # $m is undef;


=head2 Placeholders

Placeholders start with a colon and match everything except slashes. If the
route matches against the passed request method and path, placeholder values
can be retrieved from the returned match object.

    $r = Forward::Routes->new;
    $r->add_route(':foo/:bar');

    $m = $r->match(get => 'hello/there');
    # $m->[0]->params is {foo => 'hello', bar => 'there'};

    $m = $r->match(get => 'hello/there/you');
    # $m is undef


=head2 Optional Placeholders

Placeholders can be marked as optional by surrounding them with brackets and
a trailing question mark.

    $r = Forward::Routes->new;
    $r->add_route(':year(/:month/:day)?');

    $m = $r->match(get => '2009');
    # $m->[0]->params is {year => 2009}

    $m = $r->match(get => '2009/12');
    # $m is undef

    $m = $r->match(get => '2009/12/10');
    # $m->[0]->params is {year => 2009, month => 12, day => 10}


    $r = Forward::Routes->new;
    $r->add_route('/hello/world(-:city)?');

    $m = $r->match(get => 'hello/world');
    # $m->[0]->params is {}

    $m = $r->match(get => 'hello/world-paris');
    # $m->[0]->params is {city => 'paris'}


=head2 Grouping

Placeholders have to be surrounded with brackets if more than one placeholder
is put between slashes (grouping).

    $r = Forward::Routes->new;
    $r->add_route('world/(:country)-(:cities)');

    $m = $r->match(get => 'world/us-new_york');
    # $m->[0]->params is {country => 'us', cities => 'new_york'}


=head2 Constraints

By default, placeholders match everything except slashes. The C<constraints>
method allows to make placeholders more restrictive. The first passed
parameter is the name of the placeholder, the second parameter is a
Perl regular expression.

    $r = Forward::Routes->new;

    # placeholder only matches integers
    $r->add_route('articles/:id')->constraints(id => qr/\d+/);

    $m = $r->match(get => 'articles/abc');
    # $m is undef

    $m = $r->match(get => 'articles/123');
    # $m->[0]->params is {id => 123}


=head2 Defaults

The C<defaults> method allows to add default values to a route. If the route
matches against the passed request method and path, default values can be
retrieved from the returned match object.

    $r = Forward::Routes->new;
    $r->add_route('articles')
      ->defaults(first_name => 'Kevin', last_name => 'Smith');

    $m = $r->match(get => 'articles');
    # $m->[0]->params is {first_name => 'Kevin', last_name => 'Smith'}


=head2 Optional Placeholders and Defaults

Placeholders are automatically filled with default values if the route
would not match otherwise.

    $r = Forward::Routes->new;
    $r->add_route(':year(/:month)?/:day')->defaults(month => 1);

    $m = $r->match(get => '2009');
    # $m is undef

    $m = $r->match(get => '2009/12');
    # $m->[0]->params is {year => 2009, month => 1, day => 12}

    $m = $r->match(get => '2009/2/3');
    # $m->[0]->params is {year => 2009, month => 2, day => 3};


=head2 Shortcut for Action and Controller Defaults

The C<to> method provides a shortcut for action and controller defaults.

    $r = Forward::Routes->new;

    $r->add_route('articles')
      ->to('Foo#bar');

    # is a shortcut for
    $r->add_route('articles')
      ->defaults(controller => 'Foo', action => 'bar');

    $m = $r->match(get => 'articles');
    # $m->[0]->params is {controller => 'Foo', action => 'bar'}


=head2 Request Method Constraints

The C<via> method sets the HTTP request method required for a route to match.
If no method is set, the request method has no influence on the search for a
matching route.

    $r = Forward::Routes->new;
    $r->add_route('logout')->via('post');

    my $m = $r->match(get => 'logout');
    # $m is undef

    my $m = $r->match(post => 'logout');
    # $m->[0] is {}

All child routes inherit the method constraint of their parent, unless the
method constraint of the child is overwritten.


=head2 Format Constraints

The C<format> method restricts the allowed formats of a URL path. If the route
matches against the passed request method and path, the format value can be
retrieved from the returned match object.

    $r = Forward::Routes->new;
    $r->add_route(':foo/:bar')->format('html','xml');

    $m = $r->match(get => 'hello/there.html');
    # $m->[0]->params is {foo => 'hello', bar => 'there', format => 'html'}

    $m = $r->match(get => 'hello/there.xml');
    # $m->[0]->params is {foo => 'hello', bar => 'there', format => 'xml'}

    $m = $r->match(get => 'hello/there.jpeg');
    # $m is undef


All child routes inherit the format constraint of their parent, unless the
format constraint of the child is overwritten. For example, adding a format
constraint to the route root object affects all child routes added
via add_route.

    my $root = Forward::Routes->new->format('html');
    $root->add_route('foo')->format('xml');
    $root->add_route('baz');

    $m = $root->match(get => 'foo.html');
    # $m is undef;

    $m = $root->match(get => 'foo.xml');
    # $m->[0]->params is {format => 'xml'};

    $m = $root->match(get => 'baz.html');
    # $m->[0]->params is {format => 'html'};

    $m = $root->match(get => 'baz.xml');
    # $m is undef;

If no format constraint is added to a route and the route's parents also have
no format constraints, there is also no format validation taking place. This
might cause kind of unexpected behaviour when dealing with placeholders:

    $r = Forward::Routes->new;
    $r->add_route(':foo/:bar');

    $m = $r->match(get => 'hello/there.html');
    # $m->[0]->params is {foo => 'hello', bar => 'there.html'}

If this is not what you want, an empty format constraint can be passed explicitly:

    $r = Forward::Routes->new->format('');
    $r->add_route(':foo/:bar');

    $m = $r->match(get => 'hello/there.html');
    # $m->[0] is undef

    $m = $r->match(get => 'hello/there');
    # $m->[0]->params is {foo => 'hello', bar => 'there'}


=head2 Naming

Each route can get a name through the C<name> method. Names are required to
make routes reversible (see C<build_path>).

    $r = Forward::Routes->new;
    $r->add_route('logout')->name('foo');


=head2 Namespaces

The C<app_namespace> method can be used to define the base namespace of your
application. All nested routes inherit the app_namespace, unless it is
overwritten. The app_namespace value is used to determine the full
controller class name.

    my $root = Forward::Routes->new->app_namespace('My::Project');
    $root->add_route('hello')->to('Foo#bar');

    my $matches = $root->match(get => '/hello');
    # $matches->[0]->class is My::Project::Foo
    # $matches->[0]->action is bar

The C<namespace> method can be used to define sub namespaces on top of the app
namespace. All nested routes inherit the (sub) namespace, unless it is
overwritten. The namespace value is used to determine the full controller
class name.

    my $root = Forward::Routes->new->app_namespace('My::Project');
    $root->add_route('hi')->namespace('Greetings')->to('Foo#hi');
    my $matches = $root->match(get => '/hello');
    # $matches->[0]->class is My::Project::Greetings::Foo
    # $matches->[0]->action is "hi"


=head2 Path Building

Routes are reversible, i.e. paths can be generated through the C<build_path>
method. The first parameter is the name of the route. If the route consists of
placeholders which are not optional, placeholder values have to be passed as
well to generate the path, otherwise an exception is thrown.
The C<build_path> method returns a hash ref with the keys "method" and "path".

    $r = Forward::Routes->new;
    $r->add_route('world/(:country)-(:cities)')->name('hello')->via('post');

    my $path = $r->build_path('hello', country => 'us', cities => 'new_york')
    # $path->{path}   is 'world/us-new_york';
    # $path->{method} is 'post';

Path building is useful to build tag helpers that can be used in templates.
For example, a link_to helper might generate a link with the help of a route
name: link_to('route_name', placeholder => 'value'). In contrast to hard
coding the URL in templates, routes could be changed and all links in your
templates would get adjusted automatically.


=head2 Chaining

All methods can be chained.

    $r = Forward::Routes->new;
    my $articles = $r->add_route('articles/:id')
      ->defaults(first_name => 'foo', last_name => 'bar')
      ->format('html')
      ->constraints(id => qr/\d+/)
      ->name('hot')
      ->to('Hello#world')
      ->via('get','post');


=head2 Nested Routes

New routes cannot only be added to the routes root object, but to any route.
Building deep routes trees might result in performance gains in larger
projects with many routes, as the amount of regular expression searches can
be reduced this way.

    # nested routes
    $root = Forward::Routes->new;
    $nested1 = $root->add_route('foo1');
    $nested1->add_route('bar1');
    $nested1->add_route('bar2');
    $nested1->add_route('bar3');
    $nested1->add_route('bar4');
    $nested1->add_route('bar5');

    $nested2 = $root->add_route('foo2');
    $nested2->add_route('bar5');

    $m = $r->match(get => 'foo2/bar5');
    # 3 regular expression searches performed

    # alternative:
    $root = Forward::Routes->new;
    $root->add_route('foo1/bar1');
    $root->add_route('foo1/bar2');
    $root->add_route('foo1/bar3');
    $root->add_route('foo1/bar4');
    $root->add_route('foo1/bar5');
    $root->add_route('foo2/bar5');
    # 6 regular expression searches performed


=head2 Resource Routing

The C<add_resources> method enables Rails like resource routing.

Please look at L<Forward::Guides::Routes::Resources> for more in depth
documentation on resourceful routes.

    $r = Forward::Routes->new;
    $r->add_resources('users', 'photos', 'tags');

    $m = $r->match(get => 'photos');
    # $m->[0]->params is {controller => 'Photos', action => 'index'}

    $m = $r->match(get => 'photos/1');
    # $m->[0]->params is {controller => 'Photos', action => 'show', id => 1}

    $m = $r->match(put => 'photos/1');
    # $m->[0]->params is {controller => 'Photos', action => 'update', id => 1}

    my $path = $r->build_path('photos_update', id => 987)
    # $path->{path} is 'photos/987'
    # $path->{method} is 'put'

Resource routing is quite flexible and offers many options for customization:
L<Forward::Guides::Routes::ResourceCustomization>

Please look at L<Forward::Guides::Routes::NestedResources> for more in depth
documentation on nested resources.

=head2 Bridges

    $r = Forward::Routes->new;
    my $bridge = $r->bridge('admin')->to('Check#authentication');
    $bridge->add_route('foo')->to('My#stuff');

    $m = $r->match(get => 'admin/foo');
    # $m->[0]->params is {controller => 'Check', action => 'authentication'}
    # $m->[1]->params is {controller => 'My', action => 'stuff'}


=head1 AUTHOR

ForwardEver

=head1 DEVELOPMENT

=head2 Repository

L<https://github.com/forwardever/Forward-Routes>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, ForwardEver

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 CREDITS

Path matching and path building inspired by Viacheslav Tykhanovskyi's Router module
L<https://github.com/vti/router>

Concept of nested routes and bridges inspired by Sebastian Riedel's Mojolicious::Routes module
L<https://github.com/kraih/mojo/tree/master/lib/Mojolicious/Routes>

Concept of restful resources inspired by Ruby on Rails

=cut
