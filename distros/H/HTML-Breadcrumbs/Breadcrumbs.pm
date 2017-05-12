package HTML::Breadcrumbs;

use 5.000;
use File::Basename;
use Carp;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = '0.7';
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(breadcrumbs);

my @ARG = qw(path roots indexes omit omit_regex map labels sep format format_last extra);

#
# Initialise
#
sub _init
{
    my $self = shift;
    # Argument defaults
    my %arg = (
        path => $ENV{SCRIPT_NAME},
        roots => [ '/' ],
        indexes => [ 'index.html' ],
        sep => '&nbsp;&gt;&nbsp;',
        format => '<a href="%s">%s</a>',
        format_last => '%s',
        @_,
    );

    # Check for invalid args
    my %ARG = map { $_ => 1 } @ARG;
    my @bad = grep { ! exists $ARG{$_} } keys %arg;
    croak "[Breadcrumbs::_init] invalid argument(s): " . join(',',@bad) if @bad;
    croak "[Breadcrumbs::_init] 'path' argument must be absolute" 
        if $self->{path} && substr($self->{path},0,1) ne '/';

    # Add arguments to $self
    @$self{ @ARG } = @arg{ @ARG };

    return $self;
}

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self->_init(@_);
}

# Identify the root element
sub _setup_root
{
    my $self = shift;

    $self->{roots} = [ $self->{roots} ] if $self->{roots} && ! ref $self->{roots};
    my $root = '/';
    for my $r (sort { length($b) <=> length($a) } @{$self->{roots}}) {
        if ($self->{path} =~ m/^$r\b/) {
            $root = $r;
            $root .= '/' if substr($root,-1) ne '/';
            last;
        }
    }
    push @{$self->{elt}}, $root;
    $self->{root} = $root;
}

# Setup omit stuff (omit hash, omit_regex arrayrefs)
sub _setup_omit
{
    my $self = shift;

    $self->{omit_elt} = {};
    $self->{omit_regex_elt} = [];
    $self->{omit_regex_path} = [];

    $self->{omit} = [ $self->{omit} ] 
        if $self->{omit} && ! ref $self->{omit};
    # Create a hash from omit elements
    if ($self->{omit} && ref $self->{omit} eq 'ARRAY') {
        for (@{$self->{omit}}) {
            # Omit elements should be either absolute paths or element basenames
            if (substr($_,0,1) eq '/') {
                # Remove any trailing '/'
                $_ = substr($_, 0, -1)  if substr($_,-1) eq '/';
            } elsif (m!/!) {
                warn "omit arguments must be either absolute paths or simple path basenames - skipping $_";
                next;
            }
            $self->{omit_elt}->{$_} = 1;
        }
    }
    my $omit_regex = $self->{omit_regex} || [];
    $omit_regex = [ $omit_regex ] unless ref $omit_regex eq 'ARRAY';
    # Create seperate full-path and element omit_regex arrays
    for my $o (@$omit_regex) {
        if ($o =~ m!/!) {
            $o =~ s!^\^!!;
            $o =~ s!/*(\$)?$!!;  #!
            push @{$self->{omit_regex_path}}, qq(^$o\$);
        }
        else {
            push @{$self->{omit_regex_elt}}, $o;
        }
    }
}

# Add path elements to elt array
sub _add_elements
{
    my $self = shift;
    my $current = $self->{root};
    while ($self->{path} =~ m|^\Q$current\E/*(([^/]+)/?)|) {
        my $final = $2;
        $current .= $1;
        # Remove any trailing '/' from current for testing
        my $current_test = $current;
        $current_test = substr($current_test, 0, -1) if substr($current_test, -1) eq '/';
        # Ignore elements explicitly omitted
        next if $self->{omit_elt}->{$current_test} || $self->{omit_elt}->{$final};
        # Ignore elements matching omit_regex_elt patterns
        next if grep { $final =~ m/$_/ } @{$self->{omit_regex_elt}};
        # Ignore paths matching omit_regex_path patterns
        next if grep { $current_test =~ m/$_/ } @{$self->{omit_regex_path}};
        # Otherwise add to elt array
        push @{$self->{elt}}, $current;
    }
}

# Apply element mappings
sub _map_elements
{
    my $self = shift;
    die "invalid map argument" if ref $self->{map} ne 'HASH';

    $self->{elt_map} = {};
    ELT: 
    for my $elt (@{$self->{elt}}) {
        for my $key (sort keys %{$self->{map}}) {
            # Map elements must be either absolute paths or element basenames
            my $key2 = $key;
            if (substr($key2,0,1) eq '/') {
                # Absolute paths must end in '/'
                $key2 .= '/' unless substr($key2,-1) eq '/';
            } elsif ($key2 =~ m!/!) {
                warn "map arguments must be either absolute paths or simple path basenames - skipping $key2";
                next;
            }

            # If the map key matches this element, record map value in elt_map
            my $match = ($key2 =~ m!/!) ? $elt eq $key2 : $elt =~ m,/\Q$key2\E/$,;
            if ($match) {
                $self->{elt_map}->{$elt} = $self->{map}->{$key};
                next ELT;
            }
        }
    }
}

# Check the final element for indexes
sub _check_final_index_element
{
    my $self = shift;

    $self->{indexes} = [ $self->{indexes} ] 
        if $self->{indexes} && ! ref $self->{indexes};
    if (ref $self->{indexes} eq 'ARRAY') {
        # Convert indexes to hash
        my %indexes = map { $_ => 1 } @{$self->{indexes}};
        # Check final element
        my $final = basename($self->{elt}->[ $#{$self->{elt}} ]);
        if ($indexes{$final}) {
            pop @{$self->{elt}};
        }
    }
}

#
# Split the path into elements (stored in $self->{elt} arrayref)
#
sub _split
{
    my $self = shift;
    $self->{elt} = [];

    # Identify the root
    $self->_setup_root;

    # Setup omit stuff
    $self->_setup_omit;

    # Add path elements to elt array
    $self->_add_elements;

    # Apply element mappings
    $self->_map_elements if $self->{'map'};

    # Check for final index elements
    $self->_check_final_index_element;

}

#
# Generate a default label for $elt
#
sub _label_default
{
    my $self = shift;
    my ($elt, $last, $extra) = @_;
    my $label = '';

    if ($elt eq '/' || $elt eq '') {
        $label = 'Home';
    }
    else {
        $elt = substr($elt,0,-1) if substr($elt,-1) eq '/';
        $label = basename($elt);
        $label =~ s/\.[^.]*$// if $last;
        $label = ucfirst($label) if lc($label) eq $label && $label =~ m/^\w+$/;
    }

    return $label;
}

#
# Return a label for the given element
#
sub _label
{
    my $self = shift;
    my ($elt, $last, $extra) = @_;
    my $label = '';

    # Check $self->{labels}
    if (ref $self->{labels} eq 'CODE') {
        $elt = substr($elt,0,-1) if substr($elt,-1) eq '/' && $elt ne '/';
        $label = $self->{labels}->($elt, basename($elt), $last, $extra);
    }
    elsif (ref $self->{labels} eq 'HASH') {
        $elt = substr($elt,0,-1) if substr($elt,-1) eq '/' && $elt ne '/';
        $label ||= $self->{labels}->{$elt};
        $label ||= $self->{labels}->{$elt . '/'} unless $elt eq '/' || $last;
        $label ||= $self->{labels}->{basename($elt)};
    }

    # Else use defaults
    $label ||= $self->_label_default($elt, $last, $extra);

    return $label;
}

#
# Render the elt path for URI use, and lookup in elt_map if applicable
#
sub _uri_elt
{
    my $self = shift;
    local $_ = shift;
    $_ = $self->{elt_map}->{$_} if exists $self->{elt_map}->{$_};
    # URI escape - should maybe use URI::Escape here instead
    s/ /%20/g;
    return $_;
}

# 
# HTML-format the breadcrumbs
#
sub _format 
{
    my $self = shift;

    my $out;
    for (my $i = 0; $i <= $#{$self->{elt}}; $i++) {

        # Format breadcrumb links
        if ($i != $#{$self->{elt}}) {
            # Generate label
            my $label = $self->_label($self->{elt}->[$i], undef, $self->{extra});

            # $self->{format} coderef
            if (ref $self->{format} eq 'CODE') {
                $out .= $self->{format}->($self->_uri_elt($self->{elt}->[$i]), 
                    $label, $self->{extra});
            }
            # $self->{format} sprintf pattern
            elsif ($self->{format} && ! ref $self->{format}) {
                $out .= sprintf $self->{format}, $self->_uri_elt($self->{elt}->[$i]), 
                    $label;
            }
            # Else croak
            else {
                croak "[Breadcrumbs::format] invalid format $self->{format}";
            }

            # Separator
            $out .= $self->{sep};
        }

        # Format final element breadcrumb label
        else {
            # Generate label
            my $label = $self->_label($self->{elt}->[$i], 'last', $self->{extra});

            # $self->{format_last} coderef
            if (ref $self->{format_last} eq 'CODE') {
                $out .= $self->{format_last}->($label, $self->{extra});
            }
            # $self->{format_last} sprintf pattern
            elsif ($self->{format_last} && ! ref $self->{format_last}) {
                $out .= sprintf $self->{format_last}, $label;
            }
            # Else croak
            else {
                croak "[Breadcrumbs::format] invalid format_last $self->{format_last}";
            }
        }
    }

    return $out;
}

#
# The real work - process and render the given path
#
sub render
{
    my $self = shift;
    my %arg = @_;

    # Check for invalid args
    my %ARG = map { $_ => 1 } @ARG;
    my @bad = grep { ! exists $ARG{$_} } keys %arg;
    croak "[Breadcrumbs::render] invalid argument(s): " . join(',',@bad) if @bad;

    # Add args to $self
    for (@ARG) {
        $self->{$_} = $arg{$_} if defined $arg{$_};
    }

    # Croak if no path
    croak "[Breadcrumbs::render] no valid 'path' found" if ! $self->{path};
    croak "[Breadcrumbs::render] 'path' argument must be absolute" 
        if substr($self->{path},0,1) ne '/';

    # Split the path into elements
    $self->_split();

    # Format
    return $self->_format();
}

# 
# Alias for render
#
sub to_string
{
    my $self = shift;
    $self->render(@_);
}

#
# Procedural interface
#
sub breadcrumbs
{
    my $bc = HTML::Breadcrumbs->new(@_);
    croak "[breadcrumbs] object creation failed!" if ! ref $bc;
    return $bc->render();
}

1;

__END__

=head1 NAME

HTML::Breadcrumbs - module to produce HTML 'breadcrumb trails'.


=head1 SYNOPSIS

    # Procedural interace
    use HTML::Breadcrumbs qw(breadcrumbs);
    print breadcrumbs(path => '/foo/bar/bog.html');
    # prints: Home > Foo > Bar > Bog (the first three as links)

    # More complex version - some explicit element labels + extras
    print breadcrumbs(
        path => '/foo/bar/biff/bog.html', 
        labels => {
            'bog.html' => 'Various Magical Stuff',
            '/foo' => 'Foo Foo',
            bar => 'Bar Bar',
            '/' => 'Start', 
        },
        sep => ' :: ',
        format => '<a target="_blank" href="%s">%s</a>',
    );
    # prints: Start :: Foo Foo :: Bar Bar :: Biff :: Various Magical Stuff

    # Object interface
    use HTML::Breadcrumbs;

    # Create
    $bc = HTML::Breadcrumbs->new(
        path => $path, 
        labels => {
            'download.html' => 'Download',
            foo => 'Bar',
            'x.html' => 'The X Files',
        },
    );

    # Render
    print $bc->render(sep => '&nbsp;::&nbsp;');


=head1 DESCRIPTION

HTML::Breadcrumbs is a module used to create HTML 'breadcrumb trails'
i.e. an ordered set of html links locating the current page within
a hierarchy. 

HTML::Breadcrumbs splits the given path up into a list of elements, 
derives labels to use for each of these elements, and then renders this 
list as N-1 links using the derived label, with the final element
being just a label.

Both procedural and object-oriented interfaces are provided. The OO 
interface is useful if you want to separate object creation and
initialisation from rendering or display, or for subclassing.

Both interfaces allow you to munge the path in various ways (see the 
I<roots> and I<indexes> arguments); set labels either explicitly
via a hashref or via a callback subroutine (see I<labels>); and
control the formatting of elements via sprintf patterns or a callback
subroutine (see I<format> and I<format_last>).

=head2 PROCEDURAL INTERFACE

The procedural interface is the breadcrumbs() subroutine (not
exported by default), which uses a named parameter style. Example 
usage:

    # Procedural interace
    use HTML::Breadcrumbs qw(breadcrumbs);
    print breadcrumbs(
        path => $path, 
        labels => {
            'download.html' => 'Download',
            foo => 'Bar',
            'x.html' => 'The X Files',
        },
        sep => '&nbsp;::&nbsp;',
        format => '<a class="breadcrumbs" href="%s">%s</a>',
        format_last => '<span class="bclast">%s</span>,
    );

=head2 OBJECT INTERFACE

The object interface consists of two public methods: the traditional new() for
object creation, and render() to return the formatted breadcrumb trail as a
string (to_string() is an alias for render).  Arguments are passed in the same
named parameter style used in the procedural interface. All arguments can be
passed to either method (using new() is preferred, although using render() for
formatting arguments can be a useful convention). 

Example usage:

    # OO interface
    use HTML::Breadcrumbs;
    $bc = HTML::Breadcrumbs->new(path => $path);
    
    # Later
    print $bc->render(sep => '&nbsp;::&nbsp;');

    # OR
    $bc = HTML::Breadcrumbs->new(
        path => $path,
        labels => {
            'download.html' => 'Download',
            foo => 'Bar',
            'x.html' => 'The X Files',
        },
        sep => '&nbsp;::&nbsp;',
        format => '<a class="breadcrumbs" href="%s">%s</a>',
        format_last => '<span class="bclast">%s</span>,
    );
    print $bc->render();    # Same as bc->to_string()


=head2 ARGUMENTS

breadcrumbs() takes the following parameters:

PATH PROCESSING

=over 4

=item *

L<path|path> - the uri-relative path of the item this breadcrumb trail 
is for, as found, for example, in $ENV{SCRIPT_NAME}. This should 
probably be the I<real> uri-based path to the object, so that the 
elements derived from it produce valid links - if you want to munge 
the path and the elements from it see the L<roots>, L<omit>, and L<map> 
parameters. Default: $ENV{SCRIPT_NAME}.

=item *

L<roots|roots> - an arrayref of uri-relative paths used to identify
the root (the first element) of the breadcrumb trail as something other 
than '/'. For example, if the roots arrayref contains '/foo', a path of 
/foo/test.html will be split into two elements: /foo and /foo/test.html,
and rendered as "Foo > Test". The default behaviour would be to split 
/foo/test.html into three elements: /, /foo, and /foo/test.html, rendered
as "Home > Foo > Test". Default: [ '/' ].

=item *

L<indexes|indexes> - an arrayref of filenames (basenames) to treat 
as index pages. Index pages are omitted where they occur as the 
last element in the element list, essentially identifying the index 
page with its directory e.g. /foo/bar/index.html is treated as 
/foo/bar, rendered as "Home > Foo > Bar" with the first two links. 
Anything you would add to an apache DirectoryIndex directive should 
probably also be included here. Default: [ 'index.html' ].

=item *

L<omit|omit> - a scalar or arrayref of elements to be omitted or 
skipped when producing breadcrumbs. Omit arguments should be either
bare element names (i.e. contain no '/' characters, e.g. 'forms') or 
full absolute paths (i.e. begin with a '/', e.g. '/cgi-bin/forms') . 
For example, if omit includes 'cgi-bin', then a path of 
'/cgi-bin/forms/help.html' would be rendered as "Home > Forms > Help" 
instead of the default "Home > cgi-bin > Forms > Help". Default: none.

=item *

L<omit_regex|omit_regex> - a scalar or arrayref of regular expressions
used to match elements to be omitted when producing breadcrumbs.
Like 'omit', regexes should match either bare element names (no '/'
characters, e.g. 'forms') or full absolute paths (beginning with '/',
e.g. '/cgi-bin/forms'). WARNING: absolute paths are always explicitly
anchored at both ends (i.e. '/cgi-bin/forms' is used as 
m!^/cgi-bin/forms/$!), since otherwise the pattern matches every path 
after an initial match.

For example, a path like "/product/12/sample" will be rendered as
"Home > Product > Sample" instead of the default 
"Home > Product > 12 > Sample" using any of the following omit_regex 
patterns: '\d+', '/product/\d+', '/product/[^/]+', etc. Note that
partial full-path matches like '/product/1' will NOT cause the '12'
element to be omitted, however.

Default: none.

=item *

L<map|map> - a hashref of path mappings used to transform individual
element paths. Map key paths may be either full absolute paths, or 
simple path basenames. Elements that match a map key path have their
paths replaced by the map value e.g. a path of /foo/bar/bog.html
with the following map:

  map => {
    '/' => '/home.html',
    '/foo' => '/foo/foo.html',
    'bar' => '/foo/bar.html',
  },

will render with paths of (non-final labels omitted for clarity):

  /home.html > /foo/foo.html > /foo/bar.html > Bog

=back

LABELS

=over 4

=item *

L<labels|labels> - a hashref or a subroutine reference used to derive 
the labels of the breadcrumb trail elements. Default: none.

If a hashref, first the fully-qualified element name (e.g. /foo/bar or 
/foo/bar/, or /foo/bar/bog.html) and then the element basename 
(e.g. 'bar' or 'bog.html') are looked up in the hashref. If found, 
the corresponding value is used for the element label.

If this parameter is a subroutine reference, the subroutine is invoked 
for each element as:

  C<$sub->($elt, $base, $last)>

where $elt is the fully-qualified element (e.g. /foo/bar or 
/foo/bar/bog.html), $base is the element basename (e.g. 'bar' or 
'bog.html'), and $last is a boolean true iff this is the last element.
The subroutine should return the label to use (return undef or '' to
accept the default).

If no label is found for an element, the default behaviour is to use
the element basename as its label (without any suffix, if the final 
element). If the label is lowercase and only \w characters, it will be
ucfirst()-ed.

=back

RENDERING

=over 4

=item *

L<sep|sep> - the separator (scalar) used between breadcrumb elements. 
Default: '&nbsp;&gt;&nbsp;'.

=item *

L<format|format> - a subroutine reference or a (scalar) sprintf pattern
used to format each breadcrumb element except the last (for which, see 
L<format_last>). 

If a subroutine reference, the subroutine is invoked for each element as:

  C<$sub->($elt, $label)>.

where $elt is fully-qualified element (e.g. /foo/bar or /foo/bar/bog.html) 
and $label is the label for the element.

If a scalar, it is used as a sprintf format with the fully-qualified 
element and the label as arguments i.e. C<sprintf $format, $element, 
$label>.

Default: '<a href="%s">%s</a>' i.e. a vanilla HTML link.

=item *

L<format_last|format_last> - a subroutine reference or a (scalar) 
sprintf pattern used to format the last breadcrumb element (not a 
link).

If a subroutine reference, the subroutine is invoked for the element
the label as only parameter i.e. C<$sub->($label)>.

If a scalar, it is used as a sprintf format with the label as 
argument i.e. C<sprintf $format_last, $label>.

Default: '%s' i.e. the label itself.

=back


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>


=head1 COPYRIGHT

Copyright 2002-2005, Gavin Carr. All Rights Reserved.

This program is free software. You may copy or redistribute it under the 
same terms as perl itself.

=cut

# arch-tag: 0e040afb-30be-467f-9693-f9e16bbfe20f

