#============================================================= -*-perl-*-
#
# Kite::XML::Node
#
# DESCRIPTION
#   Base class for XML node modules which are constructed automatically
#   by the Kite::XML::Parser.  These represent the XML elements.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION 
#   $Id: Node.pm,v 1.1 2000/10/17 11:58:16 abw Exp $
#
#========================================================================
 
package Kite::XML::Node;

require 5.004;

use strict;
use Kite::Base;
use base qw( Kite::Base );
use vars qw( $VERSION $AUTOLOAD );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

# create some aliases for method names
*attribute = \&attr;
*element   = \&elem;
*content   = \&char;


#------------------------------------------------------------------------
# init(\%config)
#
# Initialisation method called by the base class constructor, new().
# Copies attributes pass in the $config hash reference into the $self
# object, checking that all mandatory attributes are specified.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my $class = ref $self;
    my ($attribs, $elems, $default, $key, $val, $mult);

    {
	no strict qw( refs );
	$attribs =  ${"$class\::ATTRIBUTES"} || { };
	$elems   =  ${"$class\::ELEMENTS"}   || { };
    }

    # ugy hack: we must call keys() to reset the iterators on the hashes
    my @dud = (keys(%$attribs), keys(%$elems));

    # set attributes from the $config hash, where specified in $ATTRIBUTES 
    while (($key, $val) = each %$attribs) {
	if ($key =~ /^_/) {
	    # just set default for private keys with leading _UNDERSCORE
	    $self->{ $key } = ref $val eq 'CODE' ? &$val : $val;
	}
	else {
	    if (defined $config->{ $key }) {
		$self->{ $key } = $config->{ $key };
	    }
	    elsif (defined $val) {
		$self->{ $key } = $val;
	    }
	    else {
		return $self->error("$key not defined");
	    }
	}
	delete $config->{ $key };
    }

    # set elements from the $config hash, or initialise
    while (($key, $val) = each %$elems) {
	# value can be an array ref containing [ $pkg, $module ]
	$val = $val->[0]
	    if ref $val eq 'ARRAY';

	# look for, and strip trailing '+' on package name, then create
	# array reference for elements with multiplicity
	$mult = ($val =~ s/\+$//);
	$self->{ $key } = [] 
	    if $mult;

	# copy any config value(s) into the elements
	if (defined ($val = $config->{ $key })) {
	    if ($mult) {
		push(@{ $self->{ $key } }, ref $val eq 'ARRAY' ? @$val : $val);
	    }
	    else {
		$self->{ $key } = $val;
	    }
	}
	delete $config->{ $key };
    }

    # any items remaining in $config are invalid
    foreach $key (keys %$config) {
	return $self->error("invalid attribute '$key'");
    }

    return $self;
}


#------------------------------------------------------------------------
# attr($name)
# attr($name, $value)
#
# Accessor method to retrieve or update element attributes.
#------------------------------------------------------------------------

sub attr {
    my $self = shift;
    my $attr = shift;
    my $class = ref $self;

    no strict qw( refs );
    my $attribs = ${"$class\::ATTRIBUTES"} || { };

    # set new or return existing value for valid PARAMS
    if (exists $attribs->{ $attr }) {
	if (@_) {
	    return ($self->{ $attr } = shift);
	}
	else {
	    return $self->{ $attr };
	}
    }
    else {
	return $self->error("no such attribute '$attr'");
    }
}


#------------------------------------------------------------------------
# char()
# char($text)
#
# Returns the internal CDATA member when called without any arguments, 
# which contains the current character content for the node.  When called
# with an argument, the passed value will be appended to the CDATA member.
# The CDATA item must be defined in the $ELEMENTS hash reference in the 
# subclass's package for character content to be accepted.  A call to 
# char() for a node that don't accept CDATA will be considered an error
# and will set the internal ERROR variable and return undef.  There is 
# one caveat to this rule: any node that *doesn't* define CDATA will 
# accept and silently ignore any $text that contains only whitespace.
# This is required to prevent XML nodes that shouldn't define content, 
# but do contain whitespace, from raising errors.
#------------------------------------------------------------------------

sub char {
    my ($self, $text) = @_;
    my $class = ref $self;

    no strict qw( refs );
    my $elems = ${"$class\::ELEMENTS"} || { };

    if ($elems->{ CDATA }) {
	$self->{ CDATA }  = '' unless defined $self->{ CDATA };
	$self->{ CDATA } .= $text if defined $text;
	return $self->{ CDATA };
    }
    elsif(defined $text) {
	# complain about character data unless it's just white noise
	return $self->error("invalid character data")
	    unless $text =~ /^\s*$/;
	return 1;
    }
    else {
	return $self->error("no character data");
    }
}


#------------------------------------------------------------------------
# elem($name)
# elem($name, @args)
#
# Accessor method to retrieve the element specified by parameter.  If 
# additional arguments are provided then the call is assumed to be a 
# construction request and is delegated to child($name, @args).
#------------------------------------------------------------------------

sub elem {
    my $self = shift;
    my $elem = shift;
    my $class = ref $self;

    # delegate to child() if additional arguments specified!
    return $self->child($elem, @_) 
	if @_;

    no strict qw( refs );
    my $elems = ${"$class\::ELEMENTS"} || { };

    # set new or return existing value for valid PARAMS
    if  (exists $elems->{ $elem }) {
        return $self->{ $elem };
    }
    else {
	return $self->error("no such element '$elem'");
    }
}
    

#------------------------------------------------------------------------
# child($element, @args)
#
# Creates a new child element of type denoted by the first parameter.
# Examines the $ELEMENTS hash reference in the object's package for 
# a key matching $element and uses the relevant value as a package 
# name against which the new() constructor can be called, passing 
# any additional arguments specified.  The package name may be suffixed
# by a '+' to indicate that multiple child elements are permitted.
#------------------------------------------------------------------------

sub child {
    my $self = shift;
    my $class = ref $self;
    my $elem = shift;
    my ($pkg, $mod, $mult) = (0) x 3;

    no strict qw( refs );
    my $elems = ${"$class\::ELEMENTS"} || { };

    if (defined($pkg = $elems->{ $elem })) {
	# value can be an array ref containing [ $pkg, $module ]
	($pkg, $mod) = @$pkg
	    if ref $pkg eq 'ARRAY';

	# look for, and strip trailing '+' on package name
	$mult = ($pkg =~ s/\+$//);

	# use package name to define module name if $mod set to 1
	if ($mod eq '1') {
	    $mod = $pkg;
	    $mod =~ s/::/\//g;
	    $mod .= '.pm';
	}

	require $mod if $mod;

	my $node = $pkg->new(@_)
	    || return $self->error($pkg->error());

	if ($mult) {
	    push(@{ $self->{ $elem } }, $node);
	}
	else {
	    return $self->error("$elem already defined")
		if defined $self->{ $elem };
	    $self->{ $elem } = $node;
	}
	return $node;
    }
    else {
	return $self->error("invalid element '$elem'");
    }
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Autoload method.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $class = ref $self;
    my $method = $AUTOLOAD;
    
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    no strict qw( refs );
    my $attribs = ${"$class\::ATTRIBUTES"} || { };
    my $elems   = ${"$class\::ELEMENTS"}   || { };
    
    if ($method =~ /^_/) {
	my ($pkg, $file, $line) = caller();
	die "attempt to access private member $method at $file line $line\n";
    }

    if (exists $attribs->{ $method }) {
	return $self->attr($method, @_);
    }
    elsif (exists $elems->{ $method }) {
	return $self->elem($method, @_);
    }
    else {
        return $self->error("no such attribute '$method'");
    }
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method to return a formatted string containing the object data.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $text = "$self:\n";
    local $" = ', ';
    while (my ($key, $value) = each %$self) {
	my $v;
	$value = '<undef>' unless defined $value;
	$value = [ map { $v = $value->{ $_ }; 
			 $v = '<undef>' unless defined $v;
			 "$_ => $v" } keys %$value ]
	    if ref $value eq 'HASH';
	$value = "[ @$value ]"
	    if ref $value eq 'ARRAY';
	$text .= sprintf("    %-12s => $value\n", $key);
    }
    return $text;
}


1;

__END__
	

=head1 NAME

Kite::XML::Node - base class for XML parser nodes

=head1 SYNOPSIS

    package Kite::XML::Node::Foo;

    use base qw( Kite::XML::Node );
    use vars qw( $ATTRIBUTES $ELEMENTS $ERROR );

    # define some attributes for the element node
    $ATTRIBUTES = {
	id    => undef,		# mandatory
	lang  => 'en',		# default value
	title => '',		# optional attribute
    };

    # define permitted child elements
    $ELEMENTS = {
	# single 'bar' child element
        bar => 'Kite::XML::Node::Bar',
	# multiple 'baz' child elements
        baz => 'Kite::XML::Node::Baz+',
        # require "Kite/XML/Node/Baz.pm"
        wiz => [ 'Kite::XML::Node::Wiz' => 1 ]
	# require some other module, accept multiple children
        waz => [ 'Kite::XML::Node::Waz+' => 'some/other/module.pm' ],
	# accept character content
	CDATA => 1,
    };

    package main;

    my $foo = Kite::XML::Node::Foo->new(id => 12345)
        || die Kite::XML::Node::Foo->error(), "\n";

    # set/get attributes via AUTOLOAD accessor methods...
    $foo->title('New Title');
    print $foo->id();		# 12345
    print $foo->lang();		# 'en'
    print $foo->title();	# 'New Title'

    # ...or using explicit attr() (or attribute()) method
    $foo->attr('title', 'New Title');
    $foo->attribute('title', 'New Title');
    print $foo->attr('title');	# 'New Title'

    # create new 'bar' child element
    $foo->child('bar', @some_bar_args)
        || die $foo->error(), "\n";

    # same, using AUTOLOAD method (_must_ pass additional args)
    $foo->bar(@some_bar_args)
        || die $foo->error(), "\n";
    
    # retrieve elements via AUTOLOAD methods (_don't_ pass any args)
    my $bar = $foo->bar();

    # ...or using explicit elem() (or element()) method
    $bar = $foo->elem('bar');
    $bar = $foo->element('bar');

    # create multiple 'baz' children
    $foo->child('baz', @some_baz_args)
        || die $foo->error(), "\n";
    $foo->child('baz', @more_baz_args)
        || die $foo->error(), "\n";

    # multiple elements returned as (possibly empty) list reference
    foreach my $baz (@{ $foo->baz() }) {
	print $baz->some_attribute();
    }

    # append/retrieve character content
    $foo->char('Character Content');
    print $foo->char();

=head1 DESCRIPTION

This module implements a base class for objects that are constructed 
automatically by the Kite::XML::Parser to represented parsed XML nodes
(i.e. elements).

Other modules may be derived from base class to represent specific
XML element nodes.

    package Kite::XML::Node::Foo;
    use base qw( Kite::XML::Node );

The base class methods examine variables in the package of the subclass
to determine the permitted attributes and elements of the node.  The 
$ERROR variable is also used for reporting class errors.

    use vars qw( $ATTRIBUTES $ELEMENTS $ERROR );

The $ATTRIBUTES package variable may be defined as hash reference
containing valid attributes for the node.  Default values may be
provided.  Any values left undefined are mandatory and must be
provided to the new() constructor.

    # define some attributes for the element node
    $ATTRIBUTES = {
	id    => undef,		# mandatory
	lang  => 'en',		# default value
	title => '',		# optional attribute
    };

The $ELEMENTS package variable may also be defined as a hash reference
detailing valid child elements of the node.  The keys represent the
element names and the relevant values should be the package names of
other Kite::XML::Node subclasses.  The package name may be suffixed by
a '+' to indicate that multiple child elements of this type are
permitted.  It may also be defined as a reference to an array
containing the package name as before, followed by the name of a
specific module to load (via require()) before instantiating objects
of that type.  This value may also be specified as '1' to indicate
that the relevant module for the package should be required
(i.e. change '::' to '/' and append '.pm').  The CDATA key can also
be specified to contain any true to indicate that the element should 
also accept character content.

    # define permitted child elements
    $ELEMENTS = {
	# single 'bar' child element
        bar => 'Kite::XML::Node::Bar',

	# multiple 'baz' child elements
        baz => 'Kite::XML::Node::Baz+',

        # require "Kite/XML/Node/Baz.pm"
        wiz => [ 'Kite::XML::Node::Wiz' => 1 ]

	# require some other module, accept multiple children
        waz => [ 'Kite::XML::Node::Waz+' => 'some/other/module.pm' ],

	# accept character content
	CDATA => 1,
    };

The derived class can then be used to instantiate XML node objects to 
represent XML elements.  Any mandatory attributes (i.e. $ATTRIBUTES set
to undef) must be provided to the constructor.

    package main;

    my $foo = Kite::XML::Node::Foo->new(id => 12345)
        || die Kite::XML::Node::Foo->error(), "\n";

Any optional attributes may also be provided.  Any default values
specified in $ATTRIBUTES will be set if otherwise undefined.

    my $foo = Kite::XML::Node::Foo->new(id => 12345, title => 'test')
        || die Kite::XML::Node::Foo->error(), "\n";

Attribute arguments may also be specified as a hash reference for 
convenience.

    my $foo = Kite::XML::Node::Foo->new({
	id => 12345, 
	title => 'test',
    }) || die Kite::XML::Node::Foo->error(), "\n";

The new() constructor returns undef on failure and sets the $ERROR 
package variable in the subclass.  This can then be inspected directly
or by calling error() as a class method.

    my $foo = Kite::XML::Node::Foo->new(...)
        || die $Kite::XML::Node::Foo::ERROR;

    my $foo = Kite::XML::Node::Foo->new(...)
        || die Kite::XML::Node::Foo->error();

An AUTOLOAD method is provided to allow attributes to be accessed as 
methods.  Arguments passed to these methods will be used to set the 
attribute, otherwise the attribute value will be returned.

    $foo->title('New Title');
    print $foo->id();		# 12345
    print $foo->lang();		# 'en'
    print $foo->title();	# 'New Title'

The attr() method can also be used explicitly.  This is also aliased
to attribute().

    $foo->attr('title', 'New Title');
    $foo->attribute('title', 'New Title');
    print $foo->attr('title');	# 'New Title'

The child() method is used to create a new child element.  The first argument
specifies the element type and should be defined in $ELEMENTS.  Any 
additional arguments are passed to the new() constructor method for that
element.  The instantiated child node is stored internally by the element
name.  Single elements (i.e. those that aren't suffixed by '+' in $ELEMENTS)
may only be defined once and will generate an error (returning undef) if
an attempt is made to redefine an existing element.  


    # create new 'bar' child element
    $foo->child('bar', @some_bar_args)
        || die $foo->error(), "\n";


Multiple elements (i.e. those suffixed '+' in $ELEMENTS) may be added any
number of times.

    $foo->child('baz', @some_baz_args)
        || die $foo->error(), "\n";
    $foo->child('baz', @more_baz_args)
        || die $foo->error(), "\n";

The AUTOLOAD method can be used to return element values.  Single elements
return a single object (or undef), multiple elements return a reference
to a list which may be empty (no children defined).

    my $bar = $foo->bar();
    print $bar->some_attribute();

    foreach my $baz (@{ $foo->baz() }) {
	print $baz->some_attribute();
    }

The elem() method can also be used explicitly.  This is also aliased
to element().

    my $bar = $foo->elem('bar');
    my $baz = $foo->element('bar');

Additional arguments may be passed to the elem() method to create a new 
child element.  This is then delegated to the child() method.

    $foo->elem('bar', @some_bar_args)
	|| die $foo->error(), "\n";

    # same as
    $foo->child('bar', @some_bar_args)
	|| die $foo->error(), "\n";

The AUTOLOAD method can be used in the same way.  Note that both these 
uses require additional arguments to be passed to distinguish them from
simple retrieval calls.

    $foo->bar(@some_bar_args)
        || die $foo->error(), "\n";

The char() method is provided to retrieve and update character content for
the element.  The CDATA item should be defined to any true value in $ELEMENTS
for character data to be accepted.  Note however, that any node which doesn't
defined CDATA true will accept and ignore any character data consisting of
nothing but whitespace.  Any text data passed as the first argument is 
appended to the current character content buffer.  The buffer is then 
returned.

    # append/retrieve character content
    $foo->char('Character Content');
    print $foo->char();

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision: 1.1 $

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also <Kite::XML::Parser>.

=cut


