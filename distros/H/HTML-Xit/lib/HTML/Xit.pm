package HTML::Xit;

use strict;
use warnings;

use Data::Dumper;
use HTML::Selector::XPath qw(
    selector_to_xpath
);
use Scalar::Util qw(
    blessed
    reftype
    weaken
);
use XML::LibXML;

our $VERSION = '0.05';

# default arguments for XML::LibXML
my $default_libxml_args = {
    recover  => 1,
    suppress_errors => 1,
    suppress_warnings => 1,
};

###################
#                 #
# PRIVATE METHODS #
#                 #
###################

# empty_x
#
# because methods are chained we need an HTML::Xit object to return
# even if a previous selection in the chain failed.
my $empty_x = sub { };
bless($empty_x, __PACKAGE__);

# new_explicit_args
#
# create new XML::LibXML instance with args that are passed
my $new_explicit_args = sub {
    my %args = @_;

    for my $arg (keys %$default_libxml_args) {
        # set default args values unless the arg is
        # explicitly set
        $args{$arg} = $default_libxml_args->{$arg}
            unless exists $args{$arg};
    }

    return {
        _xml => XML::LibXML->load_html( %args )
    };
};

# new_guess_args
#
# guess source as one of IO, location, or string based
# on the type of scalar that is passed.
#
# call new_explicit_args once type is guessed.
my $new_guess_args = sub {
    my $arg = shift or die;

    if (ref $arg) {
        # file handle
        if (reftype $arg eq 'GLOB') {
            return $new_explicit_args->(IO => $arg);
        }
        # scalar ref
        elsif (reftype $arg eq 'SCALAR') {
            return $new_explicit_args->(string => $arg);
        }
    }
    # url or valid file path
    elsif ( $arg =~ m{^http} || ($arg !~ m{\n} && -e $arg) ) {
        return $new_explicit_args->(location => $arg);
    }
    # text
    else {
        return $new_explicit_args->(string => $arg);
    }
};

# declare this first since we need to call in from closure
my $new_X;
# new_X
#
# create a new X instance which is a function reference that
# can return a hidden hash ref instance where data is stored
$new_X = sub {
    my($self) = @_;
    # self must be a hash ref that includes a XML::LibXML object
    return $empty_x unless eval { $self->{_xml} };

    # need to jump through some hoops here to avoid creating
    # a circular ref.  We can't have $X getting captured in its
    # own closure, but we need to know the scalar value of $X, so
    # create $Y, then assign the scalar value of $X to $Y after creating
    # $X
    my $Y;
    # HTML::Xit instance
    my $X = sub {
        my($select) = @_;
        # if we are passed a self-reference then
        # return our hidden instance variable
        return $self
            if ref $select
            and $select eq $Y;

        my $xml = $self->{_xml};
        # else create a new instance
        my $self = {};
        # create new node
        if ($select =~ m{^<([^>]+)>$}) {
            my $node_name = $1;
            # try to get XML::LibXML::Document
            my $doc = $xml
                # if the current node supports createElement then use it
                ? $xml->can('createElement')
                    ? $xml
                    # if the current belongs to a Document then use that
                    : $xml->can('ownerDocument')
                        ? $xml->ownerDocument
                        : XML::LibXML::Document->new
                # create a new Document to create node from
                : XML::LibXML::Document->new;
            # create element under document
            $xml = $self->{_xml} = $doc->createElement($node_name);
        }
        # value is selector
        else {
            # generate xpath from CSS selector using HTML::Selector::XPath
            my $xpath = selector_to_xpath($select)
                or return $empty_x;
            # set the current xml context as the result of the xpath selection
            $self->{_xml} = $xml->find('.'.$xpath);
        }
        # return a new HTML::Xit instace with either the selected or created elements
        return $new_X->($self);
    };

    bless($X, __PACKAGE__);
    # store scalar value of $X without creating another ref
    $Y = "$X";
    # return blessed sub ref
    return $X;
};

# each
#
# call callback function for each argument
#
# unlike the public version of this method the private version does
# not create HTML::Xit instances around the returned object.
my $each = sub {
    my($elm, $func) = @_;

    if (ref $elm && reftype $elm eq 'ARRAY') {
        $func->($_) for @$elm;
    }
    else {
        $func->($elm);
    }
};

# first
#
# return the first element from array or return arg if not an array.
#
# unlike the public version of this method the private version does
# not create HTML::Xit instances around the returned object.
my $first = sub {
    my($elm) = @_;

    return ref $elm && reftype $elm eq 'ARRAY'
        ? $elm->[0]
        : $elm;
};

# arg_to_nodes
#
# take one or more arguments that may be strings of xml/html
# Xit objects referencing XML, or XML objects and return an
# XML fragment
my $arg_to_nodes = sub
{
    my $parser = XML::LibXML->new(%$default_libxml_args)
        or return;

    my $nodes = [];

    for my $arg (@_) {
        if (ref $arg) {
            if ($arg->isa('HTML::Xit')) {
                push(@$nodes, @{$arg->get});
            }
        }
        else {
            my $xml = $parser->parse_balanced_chunk($arg);
            push(@$nodes, $xml);
        }
    }

    return $nodes;
};

# mod_class
#
# perform addClass, removeClass, and toggleClass methods
my $mod_class = sub {
    my($action, $X, $value) = @_;

    return $X unless $value;

    my $self = $X->($X);
    my $xml  = $self->{_xml} or return $X;
    # class list may be one or more space seperated class names
    my @mod_classes = grep {$_ =~ /\w+/} split(/\s+/, $value);

    return $X unless @mod_classes;

    $each->($xml, sub {
        my($sel) = @_;

        my $class = $sel->getAttribute('class');

        my $classes = {
            map {$_ => 1} grep {$_ =~ /\w+/} split(/\s+/, $class)
        };

        if ($action eq 'add') {
            $classes->{$_} = 1 for @mod_classes;
        }
        elsif ($action eq 'remove') {
            delete $classes->{$_} for @mod_classes;
        }
        elsif ($action eq 'toggle') {
            for my $mod_class (@mod_classes) {
                if ($classes->{$mod_class}) {
                    delete $classes->{$mod_class};
                }
                else {
                    $classes->{$mod_class} = 1;
                }
            }
        }

        $class = join(' ', sort keys %$classes);

        $sel->setAttribute('class', $class);
    });

    return $X;
};

##################
#                #
# PUBLIC METHODS #
#                #
##################

# new
#
# create new HTML::Xit instance which is a function ref
sub new
{
    my $class = shift;
    # process args which may be in the form of:
    # new("<html>...")
    # new("http://www...")
    # new(FH)
    # new("/my/file.html")
    # new(a => 1, b => 2, ...)
    # new({a => 1, b => 2})
    my $self = @_ == 1
        ? ref $_[0] && ref $_[0] eq 'HASH'
            # first arg is hash ref, use as args
            ? $new_explicit_args->( %{$_[0]} )
            # first arg is not hash ref, guess what it is
            : $new_guess_args->(@_)
        # treat multiple args as explicit, which are passed
        # directly to XML::LibXML
        : $new_explicit_args->(@_);
    # need XML::LibXML instance to continue
    return unless $self and $self->{_xml};

    return $new_X->($self);
}

# addClass
#
# add class using $mod_class
sub addClass    { $mod_class->('add', @_) }

# append
#
# add nodes after last child
sub append
{
    my($X) = shift;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;

    my $child_nodes = $arg_to_nodes->(@_)
        or return $X;

    $each->($xml, sub {
        my $sel = shift or return;
        # must be able to have children
        return unless $sel->can('appendChild');
        # append one or more child nodes
        $each->($child_nodes, sub {
            my $node = shift or return;
            # deep clone child
            $sel->appendChild( $node->cloneNode(1) );
        });
    });

    return $X;
}

# attr
#
# get or set an attribute on selected XML nodes
sub attr
{
    my($X, $name, $value) = @_;
    my $self = $X->($X);
    my $xml  = $self->{_xml};

    if (defined $value)
    {
        return $X unless $xml;

        $each->($xml, sub {
            my $sel = shift or return;

            $sel->setAttribute($name, $value)
                if $sel->can('setAttribute');
        });

        return $X;
    }
    else
    {
        return undef unless $xml;

        my $sel = $first->($xml);

        return $sel->can('getAttribute')
            ? $sel->getAttribute($name)
            : undef;
    }
}

# children
#
# return child nodes.  *does not* process optional selector
# at this time.
sub children
{
    my($X) = @_;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;

    # if we are working on a list of elements then return
    # the children of all of the elements
    if (reftype $xml eq 'ARRAY') {
        my @child_nodes;
        # add child nodes of each element to list
        push(@child_nodes, $_->childNodes) for grep {
            $_->can('childNodes')
        } @$xml;
        # return empty HTML::Xit unless child nodes were found
        return $empty_x unless @child_nodes;
        # return new HTML::Xit with child nodes
        return $new_X->( {_xml => \@child_nodes} );
    }
    else {
        # get child nodes or return empty HTML::Xit object
        return $empty_x unless $xml->can('childNodes')
            and (my @child_nodes = $xml->childNodes);
        # create new HTML::Xit object from child nodes
        return $new_X->( {_xml => \@child_nodes} );
    }
}

# classes
#
# return a list of the classes assigned to elements
sub classes
{
    my($X) = @_;
    my $self = $X->($X);

    my $xml  = $self->{_xml} or return;

    my $classes;

    # for multiple elements add each element's class attribute
    # to the list of classes
    if (reftype $xml eq 'ARRAY') {
        $classes .= " " . $_->getAttribute('class') for @$xml;
    }
    # get class attribute for single element
    else {
        $classes = $xml->getAttribute('class');
    }
    # build table of unique class names
    $classes = {
        map {$_ => 1} grep {defined $_ && $_ =~ /\w+/} split(/\s+/, $classes)
    };

    return wantarray
        # return sorted list of classes
        ? sort keys %$classes
        # return hashref of classes
        : $classes;
}

# each
#
# call callback function for each argument
#
# unlike the private version, this method creates a new
# HTML::Xit instance for each XML element being iterated on
sub each
{
    my($X, $func) = @_;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;

    if (ref $xml && reftype $xml eq 'ARRAY') {
        # call callback for each element in array, creating a
        # new HTML::Xit instance for each XML element
        $func->( $new_X->({_xml => $_}) ) for @$xml;
    }
    else {
        # call callback, creating a new HTML::Xit instance
        $func->( $new_X->({_xml => $xml}) );
    }

    return $X;
}

# find
#
# get all matching child elements
sub find
{
    my($X, $query) = @_;

    my $nodes = [];

    $X->each(sub {
        my($X) = @_;
        my $node = $X->($query)->get
            or return;
        $node = [$node]
            unless reftype $node eq 'ARRAY';
        push(@$nodes, @$node);
    });

    return $new_X->({_xml => $nodes})
}

# first
#
# return the first element from array or return arg if not an array.
#
# unlike the private version, this method creates a new
# HTML::Xit instance for node being returned
sub first {
    my($X) = @_;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;

    return ref $xml && reftype $xml eq 'ARRAY'
        ? $new_X->( {_xml => $xml->[0]} )
        : $new_X->( {_xml => $xml} );
};

# get
#
# return the XML::LibXML nodes or node identified by index
sub get
{
    my($X, $index) = @_;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;
    # make sure we have nodes in array
    my $nodes = ref $xml && reftype $xml eq 'ARRAY'
        ? $xml : [ $xml ];
    # return either all nodes or specified index
    return defined $index && int $index
        ? $nodes->[ $index ]
        : $nodes;
}

# hasClass
#
# return true (1) / false (0) if any of the elements have
# the class.  return undef on errors.
sub hasClass
{
    my($X, $class) = @_;
    # require class name to test
    return unless defined $class;
    # get hashref of class names
    my $classes = $X->classes()
        or return;

    return $classes->{$class} ? 1 : 0;
}

# html
#
# return html content or if that is not possible return text
# content
sub html
{
    my($X) = shift;
    my $self = $X->($X);

    my $xml = $self->{_xml};
    # if there are args we modify the current elements
    # and return the current HTML::Xit instance
    if (@_) {
        # require current element
        return $X unless $xml;
        # build nodes to be appended from args which can
        # be either HTML strings or HTML::Xit objects
        my $child_nodes = $arg_to_nodes->(@_)
            or return $X;
        # go through each of the current elements and set
        # the child nodes from args to be their HTML content
        $each->($xml, sub {
            my $sel = shift or return;
            # must be able to have children
            return unless $sel->can('appendChild');
            # html replaces any existing child nodes
            $sel->removeChildNodes()
                if $sel->can('removeChildNodes');
            # append one or more child nodes
            $each->($child_nodes, sub {
                my $node = shift or return;
                # deep clone child
                $sel->appendChild( $node->cloneNode(1) );
            });
        });
        # return HTML::Xit instance
        return $X;
    }
    # if there are no args then we return the HTML text of the
    # current elements or an empty string
    else {
        # require current element
        return undef unless $xml;
        # get the first element
        my $sel = $first->($xml);
        # if the current node has children then create html
        # by concatenating html values of child nodes
        if ( $sel->can('childNodes') && (my @child_nodes = $sel->childNodes) ) {
            return join('', map {
                $_->can('toStringHTML')
                    ? $_->toStringHTML
                    : $_->can('toString')
                        ? $_->toString
                        : ''
            } @child_nodes);
        }
        # if the node has no children then it can only have
        # text content (?) maybe not possible
        else {
            return $sel->can('toString')
                ? $sel->toString
                : '';
        }
    }
}

# last
#
# return the last matching element
sub last {
    my($X) = @_;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;

    return ref $xml && reftype $xml eq 'ARRAY'
        ? $new_X->( {_xml => $xml->[-1]} )
        : $new_X->( {_xml => $xml} );
};

# prepend
#
# add nodes before first child
sub prepend
{
    my($X) = shift;
    my $self = $X->($X);

    my $xml = $self->{_xml} or return $X;

    my $child_nodes = $arg_to_nodes->(@_)
        or return $X;

    my $first_child = shift @$child_nodes;

    $each->($xml, sub {
        my $sel = shift or return;

        if ($sel->can('firstChild')) {
            # insert first node before first child
            my $insert_after = $sel->insertBefore(
                $first_child->cloneNode(1),
                $sel->firstChild,
            ) or return;

            $each->($child_nodes, sub {
                my $node = shift or return;

                return unless $insert_after
                    and $insert_after->can('insertAfter');

                $insert_after = $sel->insertAfter(
                    $node->cloneNode(1),
                    $insert_after
                );
            });
        }
        elsif ($self->can('addChild')) {
            $sel->addChild( $first_child->cloneNode(1) );
            $each->($child_nodes, sub {
                my $node = shift or return;
            });
        }
        else {
            return;
        }
    });

    return $X;
}

# removeClass
#
# remove class using $mod_class
sub removeClass { $mod_class->('remove', @_) }

# text
#
# return text content
sub text
{
    my($X, $value) = @_;
    my $self = $X->($X);

    my $xml = $self->{_xml};

    if (defined $value) {
        return $X unless $xml;

        $each->($xml, sub {
            my $sel = shift or return;
            # text replaces everything else so remove child nodes
            # if they exist
            $sel->removeChildNodes() if $sel->can('removeChildNodes');
            # attempt different methods of adding text
            # XML::LibXML::Element
            if ($sel->can('appendText')) {
                $sel->appendText($value);
            }
            # XML::LibXML::Text
            elsif ($sel->can('setData')) {
                $sel->setData($value);
            }
            # XML::LibXML::Node
            elsif ($sel->can('appendChild')) {
                $sel->appendChild( $sel->createTextNode($value) );
            }
        });
    }
    else {
        return undef unless $xml;

        my $sel = $first->($xml);
        return $sel && $sel->can('textContent')
            ? $sel->textContent
            : undef;
    }

    return $X;
}

# trimText
sub trimText
{
    my($X) = @_;

    my $text = $X->text;
    return unless defined $text;

    $text =~ s{^\s*|\s*$}{}g;

    return $text;
}

# toggleClass
#
# toggle class using $mod_class
sub toggleClass { $mod_class->('toggle', @_) }

1;

__END__

=head1 NAME

HTML::Xit - XML/HTML DOM Manipulation with CSS Selectors

=head1 SYNOPSIS

    my $X = HTML::Xit->new("http://mysite.com/mydoc.html");

    $X->("a")->each( sub {
        my($X) = @_;

        print $X->attr("href");
        print $X->text;
    } );

    $X->(".a")->addClass("b c d")->removeClass("c e")->toggleClass("b a");

    print $X->("<a>")->attr("href", "http://mysite.com")->text("My Site")->html;

=head1 DESCRIPTION

DOM manipulation in the style of jQuery using L<XML::LibXML> and L<HTML::Selector::XPath>.

=head1 METHODS

=over 4

=item new

Create a new HTML::Xit instance.  The source can be a URL (which will be fetched), a filename,
a file handle, or a string.

    HTML::Xit->new("http://www.some.com");
    HTML::Xit->new("somefile.html");
    HTML::Xit->new($html);

The source will be parsed using L<XML::LibXML>.  By default the following args are used:

    recover  => 1,
    suppress_errors => 1,
    suppress_warnings => 1,

You can pass arguments for use when instantiating L<XML::LibXML>.

    HTML::Xit->new({
        recover => 0,
        location => "http://www.some.com",
    });

These arguments will be passed to XML::LibXML->load_html which is documented in L<XML::LibXML::Parser>.

=item addClass

    $X->addClass("a b");

Add one or more classes to the matching elements.  Class names must be space separated.

=item append

    $X->append("<span>Hello</span>");
    $X->append( $X->("<span>")->text("Hello") );

Insert the content passed after the last child node for each matching element.

=item attr

    $X->attr("href");
    $X->attr("href", "http://www.some.com");

Either get or set an attribute.

=item children

    $X->children();

Get child nodes for each matching element.

=item classes

    my $hash_ref = $X->classes();
    $hash_ref->{someClass} ? 1 : 0;

Get hashref containing the names of all of the classes for the matching element.

!! NOT STANDARD JQUERY !!

=item each

    $X->each(sub {
        my($X) = @_;
    });

Interate over each matching element, calling the callback function for each.

=item find

    $X->(".foo")->find(".bar");

Search matching elements for additional elements that match the given selector.

=item first

    my $h1 = $X->("h1")->first;

Get the first matching element.

=item get

    my $nodes = $X->("p")->get

Get the list of XML nodes that are currently selected.

=item hasClass

    $X->addClass("a");
    $X->hasClass("a"); # true

Will return true if the selected element has the given class.  If multiple elements
are selected this will return true if any of the selected elements has the class.

=item html

    $X->html("<span>Hello</span>");
    $X->append( $X->("<span>")->text("Hello") );
    $X->html(); # "<span>Hello</span>"

If an HTML string or HTML objects are passed this will set the inner HTML for each selected
element.

If no HTML is passed this will return the inner HTML of the first selected element as a string.

=item last

    $X->("a")->last();

Return the last selected element.

=item prepend

    $X->prepend("<span>Hello</span>");
    $X->prepend( $X->("<span>")->text("Hello") );

Insert the content passed before the first child node for each matching element.

=item removeClass

    $X->removeClass("a b");

Remove one or more classes from the matching elements.  Class names must be space separated.

=item text

    $X->text("Hello");
    $X->text(); # Hello

If a string is passed this will be set as the text content for all selected elements.

If no text is passed then the text content of the first selected element will be returned.

=item trimText

    $X->trimText();

Return $X->text() with leading and trailing whitespace removed.

!! NOT STANDARD JQUERY !!

=item toggleClass

    $X->toggleClass("a b");

Toggle one or more classes from the matching elements.  If the class exists it will be removed.
If the class does not exist it will be added.  Class names must be space separated.

=back

=head1 SEE ALSO

L<XML::LibXML>, L<HTML::Selector::XPath>

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
