package Embedix::ECD;

use strict;
use vars qw($AUTOLOAD $VERSION);

$VERSION = '0.09';

# different classes of nodes
use Embedix::ECD::Autovar;
use Embedix::ECD::Component;
use Embedix::ECD::Group;
use Embedix::ECD::Option;

# misc info
use Embedix::ECD::Util qw(
    indent 
    unindent_and_aggregate
    %default 
    @attribute_order
);

# damian conway is the man
use Parse::RecDescent;

# for debugging
use Data::Dumper;

# for preserving insertion order
use Tie::IxHash;

# for when the grammar is giving me trouble
# $::RD_HINT = 1;

# the grammar
$Embedix::ECD::__grammar = q(

    {
        *Parse::RecDescent::unindent_and_aggregate = 
        \&Embedix::ECD::Util::unindent_and_aggregate;
    }

    ecd_arrayref:
        statement(s?)
        {
            # return syntax tree as nested arrayrefs
            $return = $item[1];
        }

    statement:
        comment
        | node
        | attribute
        | <error>

    comment_line:
        /^#(.*)\n/
        {
            $return = $1;
        }

    comment: 
        comment_line(s)
        {
            $return = [ 'Comment', $item[1] ];
        }

    rawtext:
        #m{[^<]+}
        #m{(?:[^<]|<(?!(?:/[a-zA-Z_]+|[a-zA-Z_]+/?)>))+}
        m{(?:[^<]|<(?!(/)?[a-zA-Z_]+(?(1)|/?)>))+}
        {
            $return = $item[1];
        }

    attribute:
        # one line w/o tags
        m{(\w+)[ \t]*=(.*)\n}
        {
            my $attr  = $1;
            my $value = $2;
            $value    =~ s/^\s*//;
            $value    =~ s/\s*$//;
            $return   = [ $attr, $value ];
        }
        | tag_open rawtext(s?) tag_close
        {
            if ($item[1] ne $item[3]) {
                die "$thisline: was expecting $item[1], " .
                    "but found $item[3] instead\n";
            }
            my $value = ref($item[2]) && $item[2][0] || '';
            $value    = unindent_and_aggregate($value);
            $return   = [ $item[1], $value ];
        }

    tag_open:
        m{<([a-zA-Z_]+)>}
        {
            $return = $1;
        }

    tag_close:
        m{</([a-zA-Z_]+)>}
        {
            $return = $1;
        }

    node:
        node_start node_item(s?) node_end
        {
            if ($item[1][0] ne $item[3]) {
                die "$thisline: was expecting $item[1][0], " .
                    "but found $item[3] instead\n";
            }
            $return = [ $item[1], $item[2] ];
        }

    node_item:
        statement
        | attribute

    node_start:
        m{<(\w+)\s+(.*?)>}
        {
            #print STDERR "node $1 $2\n";
            my $nodetype = ucfirst lc $1;
            my $name     = $2;
            $return      = [ $nodetype, $name ];
        }

    node_end:
        m{</(\w+)>}
        {
            $return = ucfirst lc $1;
        }
);

$Embedix::ECD::__parser = undef;

# the parser as a singleton
#_______________________________________
sub parser {
    if (defined $Embedix::ECD::__parser) {
        return  $Embedix::ECD::__parser;
    } else {
        # construct a new parser
        my $g = \$Embedix::ECD::__grammar;
        my $p = Parse::RecDescent->new($$g);
        return $Embedix::ECD::__parser = $p;
    }
}

# constructor, basic
#_______________________________________
sub new {
    my $class = shift; (@_ & 1) && die "Odd number of parameters.\n";
    my %opt   = @_;
    my %child;
    tie %child, "Tie::IxHash";
    my $self  = { 
        name   => $opt{name} || die("name attribute is mandatory\n"),
        parent => undef,
        child  => \%child,

        # FIXME : these are the attributes that have occurred in nodes
        # so far.  I need to find out if certain attributes are not
        # allowed in certain node types.
        attribute => { 
            # scalar values
            type                => undef,
            value               => undef,
            default_value       => undef,
            range               => undef,
            help                => undef,
            prompt              => undef,
            license             => undef,
            srpm                => undef,
            specpatch           => undef,

            static_size         => undef,   # XXX < not a good indicator of
            min_dynamic_size    => undef,   # XXX < true memory consumption
            storage_size        => undef,   # XXX platform dependent
            startup_time        => undef,   # XXX platform dependent

            # These options have been observed to contain aggregate values.
            build_vars          => undef,
            conflicts           => undef,
            provides            => undef,
            requires            => undef,
            keeplist            => undef,
            choicelist          => undef,
            trideps             => undef,

            # a syntax of its own
            requiresexpr        => undef,
            'if'                => undef,
        },
    };
    delete($opt{name});
    @{$self->{attribute}}{keys %opt} = values %opt;
    return bless($self => $class);
}

# constructor, object
#_______________________________________
sub newFromCons {
    my $proto = shift;
    my $cons  = shift;
    my $self  = undef;
    my $i;

    # self
    $self = $proto if (ref($proto));

    # root node
    $self = Embedix::ECD->new(name => 'ecd') unless ($self);

    # add kids recursively
    while ($i = shift(@$cons)) {
        if (ref($i->[0])) {
            # node
            my $node_class =  "Embedix::ECD::" . $i->[0][0];
            my $child = $node_class->new(name => $i->[0][1]);
            $self->addChild($child);
            $child->newFromCons($i->[1]);
        } else {
            # attribute
            if ($i->[0] eq "Comment") {
                # comment
                # throw them away for now
            } else {
                # attribute
                $self->setAttribute(lc $i->[0], $i->[1]);
            }
        }
    }
    return $self;
}

# constructor, object
#_______________________________________
sub newFromString {
    my $class = shift;
    my $s     = shift;
    my $p     = Embedix::ECD->parser();
    my $cons  = $p->ecd_arrayref($s);
    my $self  = $class->newFromCons($cons);
    return $self;
}

# constructor, object
#_______________________________________
sub newFromFile {
    my $class    = shift;
    my $filename = shift;
    open(ECD, $filename) || die "$!";
    my $s    = join('', <ECD>);
    my $self = $class->newFromString($s);
    close(ECD);
    return $self;
}

# constructor, arrayref
#_______________________________________
sub consFromString {
    my $class = shift;
    my $s     = shift;
    my $p     = Embedix::ECD->parser();
    my $cons  = $p->ecd_arrayref($s);
    return $cons;
}

# constructor, arrayref
#_______________________________________
sub consFromFile {
    my $class    = shift;
    my $filename = shift;
    open(ECD, $filename) || die "$!";
    my $s    = join('', <ECD>);
    my $cons = $class->consFromString($s);
    close(ECD);
    return $cons;
}

# destructor 
#_______________________________________
sub DESTROY {

}

# accessor for name
#_______________________________________
sub name {
    my $self = shift;
    if (@_) {
        $self->{name} = +shift;
    } else {
        return $self->{name};
    }
}

# general attribute getter
#_______________________________________
sub getAttribute {
    my $self = shift;
    my $attr = shift;
    return $self->{attribute}{$attr};
}

# general attribute setter
#_______________________________________
sub setAttribute {
    my $self = shift;
    my $attr = shift;
    my $val  = shift;
    $self->{attribute}{$attr} = $val;
}

# maybe do some glob + closure magic for attribute getters and setters
#_______________________________________
sub make_accessor_method {
    my $package = caller;
    my $method;
    foreach $method (@_) {
        no strict 'refs';
        *{$package . "::$method"} = sub {
            my $self = shift;
            if (@_) {
                $self->{attribute}{$method} = +shift;
            } else {
                return $self->{attribute}{$method};
            }
        }
    }
}

# *_size attributes can be mathematical expressions.
#_______________________________________
sub make_evaluating_getter_method {
    my $package = caller;
    my $method;
    foreach $method (@_) {
        no strict 'refs';
        *{$package . "::eval_$method"} = sub {
            my $self = shift;
            my @x = split (
                /(?<=\d)\s+(?=\d)/,
                $self->{attribute}{$method}
            );
            push @x, 0 if (@x == 1);
            return map { eval } @x;
        }
    }
}

# in the future, subclasses will be more specific.
Embedix::ECD::make_accessor_method(qw(
    type
    value
    default_value
    range
    help
    prompt
    license
    srpm
    specpatch

    static_size
    min_dynamic_size
    storage_size
    startup_time

    build_vars
    conflicts
    provides
    requires
    keeplist
    choicelist
    trideps

    requiresexpr
    if
));

Embedix::ECD::make_evaluating_getter_method(qw(
    static_size
    min_dynamic_size
    storage_size
    startup_time
));

# get child node objects
#_______________________________________
sub getChild {
    my $self = shift;
    my $name = shift;

    if (defined $self->{child}{$name}) {
        return  $self->{child}{$name};
    } else {
        return undef;
    }
}

# an alias for getChild()
#_______________________________________
*Embedix::ECD::n = \&getChild;  # node

# set child node objects
#_______________________________________
sub addChild {
    my $self = shift;
    my $obj  = shift;
    die "$obj is not an instance of Embedix::ECD.\n"
        unless (ref($obj) && $obj->isa('Embedix::ECD'));
    my $name = $obj->{name};
    $obj->{parent} = $self;
    $self->{child}{$name} = $obj;
    return $obj;
}

# delete a child from a node
#_______________________________________
sub delChild {
    my $self = shift;
    my $obj  = shift;
    my $name;
    if (ref($obj)) {
        $name = $obj->name;
    } else {
        $name = $obj;
    }
    if (defined $self->{child}{$name}) {
        return delete($self->{child}{$name});
    } else {
        carp("Child $name does not exist");
        return undef;
    }
}

# return list of children of node
#_______________________________________
sub getChildren {
    my $self = shift;
    return values %{$self->{child}};
}

# true if node has children
#_______________________________________
sub hasChildren {
    my $self = shift;
    return scalar values %{$self->{child}};
}

# get child node objects automagically
#_______________________________________
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;

    $name =~ s/.*://;

    if (defined $self->{child}{$name}) {
        return  $self->{child}{$name};
    } else {
        # my (undef, $f, $l) = caller();
        # die "$f\[$l\] => ", ref($self), "::$name() is not a valid method.\n";
        return undef;
    }
}

# merge another Embedix::ECD object together with $self
#_______________________________________
sub mergeWith {
    my $self = shift;
    my $ecd  = shift;

    # restrict
    unless (   ($self->name eq $ecd->name) 
           &&  (ref($self)  eq  ref($ecd)) ) 
    {
        die "ecd needs to have the same name and class to be merged\n";
    }

    # copy attributes
    foreach (keys %{$ecd->{attribute}}) {
        $self->{attribute}{$_} = $ecd->{attribute}{$_}
            if defined ($ecd->{attribute}{$_});
    }

    # merge children
    my $sibling;
    foreach $sibling ($ecd->getChildren) {
        my $name  = $sibling->name;
        my $child = $self->getChild($name);

        unless ($child) {
            $self->addChild($sibling);
        } else {
            my $evil_twin = $sibling;
            $child->mergeWith($evil_twin);  # bad poetry?
        }
    }
}

# get depth in tree
#_______________________________________
sub getDepth {
    my $self = shift;
    my $parent = $self->{parent};
    unless (ref($parent)) {
        return 0;
    } else {
        return ($parent->getDepth() + 1);
    }
}

# return the class of the node as a string
#_______________________________________
sub getNodeClass {
    my $self = shift;
    my $type = ref($self);
    return substr($type, rindex($type, ':') + 1);
}

# calculate spaces
#_______________________________________
sub getFormatOptions {
    my $self = shift; (@_ & 1) && die "Odd number of parameters.\n";
    my %opt  = @_;

    $opt{indent} = 0 unless(defined($opt{indent}));
    $opt{sw}     = $opt{shiftwidth} || $default{shiftwidth};
    $opt{space}  = " " x $opt{indent} . indent($self->getDepth, $opt{sw});
    $opt{space2} = $opt{space} . " " x $opt{sw};
    $opt{order}  = \@attribute_order;

    return \%opt;
}

# render the attributes of a node
# It's rare for me to nest this much.
#_______________________________________
sub attributeToString {
    my $self = shift;
    my $opt  = shift;
    my ($sw, $space, $space2) = map { $opt->{$_} } qw(sw space space2);
    my $a;
    return join '', map {
        $a = $self->getAttribute($_);
        if (defined($a)) {
            if (ref($a)) {
                if (scalar(@$a)) {
                    # an aggregate attribute
                    $space2 . "<" . uc($_) . ">\n" .
                    join('', map { $space2 . " " x $sw . "$_\n" } @$a) .
                    $space2 . "</" . uc($_) . ">\n";
                } else {
                    # an empty aggregate attribute
                    "";
                }
            } else {
                # a scalar attribute
                $space2 . uc($_) . "=" . "$a\n";
            }
        }
    } @{$opt->{order}};
}

# render $self in ECD format
# Embedix::ECD itself doesn't have a textual representation 
# but its subclasses should.
#_______________________________________
sub toString {
    my $self = shift;
    return join('', map { $_->toString(@_) } $self->getChildren());
}

1;

__END__

=head1 NAME

Embedix::ECD - Embedix Component Descriptions as objects

=head1 SYNOPSIS

instantiate from a file

    my $ecd       = Embedix::ECD->newFromFile('busybox.ecd');
    my $other_ecd = Embedix::ECD->newFromFile('tinylogin.ecd');

access nodes

    my $busybox = $ecd->System->Utilities->busybox;

build from scratch

    my $server = Embedix::ECD::Group->new(name => 'Server');
    my $www    = Embedix::ECD::Group->new(name => 'WWW');
    my $apache = Embedix::ECD::Component->new (
        name   => 'apache',
        srpm   => 'apache',
        prompt => 'Include apache web server?',
        help   => 'The most popular http server on the internet',
    );
    $ecd->addChild($server);
    $ecd->Server->addChild($www);
    $ecd->Server->WWW->addChild($apache);

get/set attributes

    my $srpm = $busybox->srpm();

    $busybox->help('i am busybox of borg -- unix will be assimilated.');

    $busybox->requires([
        'libc.so.6',
        'ld-linux.so.2',
        'skellinux',
    ]);

combine Embedix::ECD objects together

    $ecd->mergeWith($other_ecd);

print as text

    print $ecd->toString;

print as XML

    use Embedix::ECD::XMLv1 qw(xml_from_cons);

    print $ecd->toXML(shiftwidth => 4, dtd => 'yes');

    my $cons = Embedix::ECD->consFromFile('minicom.ecd');
    print xml_from_cons($cons);

=head1 REQUIRES

=over 4

=item Parse::RecDescent

for the ECD parser

=item Data::Dumper

for debugging

=item Tie::IxHash

for preserving the insertion order of children while retaining
C<O(1)> named access (at the expense of memory).

=item Pod::Usage

C<bin/ecd2xml> uses this to generate its help message.

=back

=head1 DESCRIPTION

Embedix::ECD allows one to represent ECD files as a tree of perl
objects.  One can construct objects by parsing an ECD file, or one can
build an ECD object from scratch by combining instances of Embedix::ECD
and its subclasses.  These objects can then be turned back into ECD
files via the C<toString()> method.

ECD stands for Embedix Component Description, and its purpose is to
contain meta-data regarding packages (aka components) in the Embedix
distribution.  ECD files contain much of the same data a .spec file does
for an RPM.  A major difference however is that ECD files do not contain
building instructions whereas .spec files do.  Another major difference
between .spec files and ECD files is the structure.  ECD files are
hierarchically structured whereas .spec files are comparatively flat.

The ECD format reminds me of the syntax for Apache configuration files.
Items are tag-delimited (like in XML) and attributes are found between
these tags.  Comments are written by prefixing them with /^\s*#/.
Unlike apache configurations, attribute names and values are separated
by an "=" sign, whereas in apache the first token is the attribute name
and everything after that (sans leading whitespace) and up to the end of
the line is the attribute's value.  Also, unlike apache configurations,
attributes may also be enclosed in tags, whereas in apache tags are used
only to describe nodes.  

ECD files look like pseudo-XML with shell-styled comments.

=head1 METHODS

=head2 Constructors

There are two types of constructors provided by this class.  The first
kind of constructor begins with "new" and returns an Embedix::ECD
object.  There is another kind of constructor that begins with "cons"
and returns the syntax tree as nested arrayrefs.

I realized that creating an object of the syntax tree takes a long time
(especially for long ECD files).  I also realized that sometimes, the
simple nested arrayref is useful enough on its own.  It also has the
nice property of retaining comments whereas the object constructor
disposes of comments.  I thought if ECD files were ever to be translated
into XML, it'd be nice to be able to keep the comments.  These factors
convinced me that it would be useful to have these 2 kinds of
constructors.

=over 4

=item new(key => $value, ...)

This returns an Embedix::ECD object.  It can be initialized with named
parameters which represent the attributes the object should have.  The
set of valid attributes is described under L</Attributes>.

    $system     = Embedix::ECD::Group->new(name => 'System');
    $utilities  = Embedix::ECD::Group->new(name => 'Utilities');
    $busybox    = Embedix::ECD::Component->new(

        name    => 'busybox',
        type    => 'bool',
        value   => 0,
        srpm    => 'busybox',

        static_size     => 3006,
        min_dynamic_size=> 0,
        storage_size    => 4408,
        startup_time    => 0,

        keeplist        => [ '/bin/busybox' ],
        requires_expr   => [
            '(libc.so.6 == "y") &&',
            '(ld-linux.so.2 == "y") &&',
            '(skellinux == "y") &&',
            '(  (Misc-utilities == "y")',
            '|| (File-compression-utilities == "y")',
            '|| (Network-utilities == "y")',
            '|| (Process-utilities == "y")',
            '|| (Directory-utilities == "y")',
            '|| (User-info-utilities == "y")',
            '|| (Disk-info-utilities == "y")',
            '|| (Screen-utilities == "y")',
            '|| (System-utilities == "y")',
            '|| (File-manipulation-utilities == "y") )',
        ],
                            
    );

=back

The following 5 constructors rely on a Parse::RecDescent parser.  When
they encounter a syntax error they will C<die>, so be sure to wrap them
around an C<eval> block.

=over 4

=item newFromCons($cons)

This returns an Embedix::ECD object from a nested arrayref.

    $ecd = Embedix::ECD->newFromCons($cons)

=item newFromString($string)

This returns an Embedix::ECD object from a string in ECD format.

    $ecd = Embedix::ECD->newFromString($string)

=item newFromFile($filename)

This returns an Embedix::ECD object from an ECD file.

    $ecd = Embedix::ECD->newFromFile($filename)

=item consFromString($string)

This returns a nested arrayref from a string in ECD format.

    $cons = Embedix::ECD->consFromString($string)

=item consFromFile($filename)

This returns a nested arrayref from an ECD file.

    $cons = Embedix::ECD->consFromFile($filename)

=back

(This next constructor is an anomaly.)

=over 4

=item Embedix::ECD->parser

This returns an instance of Parse::RecDescent configured to understand
the ECD grammar.  This instance is a singleton, so you will receive the
same instance every time.

    $ecd_parser = Embedix::ECD->parser()

=back

=head2 Nodes

Nodes are the fundamental building block of the tree structure in an ECD
file.   Nodes are containers of attributes and other nodes.  No matter
what, all nodes will have a "name" attribute.  This is the key feature
that makes nodes distiguishable from attributes.

This is a node

    <AUTOVAR embedix_ui-VGAOPT>
        TYPE=string
        DEFAULT_VALUE=785
    </AUTOVAR>

This is an attribute

    <IF>
        ( ( EBXDUP_CONFIG_USB_BANDWIDTH == "y" )
        LET ( $VALUE = "y" ) )
        ||
        ( ( ( CONFIG_USB != "n" )
        && ( CONFIG_EXPERIMENTAL != "y" ) )
        LET ( $VALUE = "n" ) )
    </IF>

The distinction is in the opening tag.  The autovar has a second string
in it which represents the node's name whereas the if has nothing which
means that it is an attribute of the node it is contained in.

There are 5 (not 4) types of nodes.

=over 4

=item the root node | Embedix::ECD

This node is implicit but very real.  When invoking any of the
constructors that begin with "newFrom", one will get back an
Embedix::ECD object within which the rest of the ECD data will be
contained.

=item Group | Embedix::ECD::Group

Their purpose is to establish a hierarchy of components under meaningful
subheadings such as "Server/WWW" or "System/Utilities".  Their main use
is as containers of other nodes.

=item Component | Embedix::ECD::Component

A component node represents a package in the Embedix distribution.

=item Option | Embedix::ECD::Option

An option node is almost always contained under a component node.  The
purpose of an option is to provide a point of configurability for a
package.

=item Autovar | Embedix::ECD::Autovar

What exactly is this?

=back

=head2 Accessing Child Nodes

The following are accessor methods for child nodes.

=over 4

=item getChild($name)

This returns a child node with the given $name or undef if no
such child exists.

    $child_ecd = $ecd->getChild($name)

=item n($name)

C<n()> is an alias for C<getChild()>.  "n" stands for "node" and is a
lot easier to type than "getChild".

    $ecd->n('System')
        ->n('Utilities')
        ->n('busybox')
        ->n('long-ass-option-name-with-redundant-information');

=item addChild($obj)

This adds a child to the current node.

    $ecd->addChild($obj)

=item delChild($obj) or delChild($name)

This deletes a child from the current node.
The child may either be specified by an object or by its name.

    $ecd->delChild($obj) or $ecd->delChild($name)

=item getChildren

This returns a list of all child nodes.

    @child_ecd = $ecd->getChildren()

=item hasChildren

This returns true if the current node has child nodes.

    $ecd->hasChildren()

=back

=head2 Accessing Child Nodes via AUTOLOAD

The name of a node can be used as a method.  This is what makes it
possible to say something like:

    my $busybox = $ecd->System->Utilities->busybox;

and get back the Embedix::ECD::Component object that contains the
information for the busybox package.  "System", "Utilities", and
"busybox" are not predefined methods in Embedix::ECD or any of its
subclasses, so they are delegated to the AUTOLOAD method.  The AUTOLOAD
method will try to find a child with the same name as the undefined
method and it will return it if found.

I have not yet decided whether the AUTOLOAD should die when a child is
not found.  Currently undef is returned in this situation.

One annoyance is that many nodes have names with "-" in them.  These
cannot be AUTOLOADed, because method names may not have a "-" in perl.
When accessing such nodes, use the C<getChild()> method.

=head2 Attributes

If nodes are objects, then attributes are a node's instance variables.
All attributes may be single-valued or aggregate-valued.  Single-valued
attributes are non-reference scalar values, and aggregate attributes are
non-reference scalar values enclosed within an arrayref.

A single valued attribute:

    my $bbsed = $busybox->n('Misc-utilities')->n('keep-bb-sed');
    $bbsed->provides('sed');

The same attribute as an aggregate:

    $bbsed->provides([ 'sed' ]);

Semantically, these are equivalent.  The main difference one will notice
is cosmetic.  When the C<toString()> method is called, the single-valued
one will look like:

    PROVIDES=sed

and the aggregate valued provides will look like:

    <PROVIDES>
        sed
    </PROVIDES>

Again, these two expressions mean the same thing.  An aggregate of one
is interpreted just as if it were a single value.

Aggregates become useful when attributes needs to have a list of values.

    $busybox->n('compile-time-features')->n('enable-bb-feature-use-inittab')->requires ([
        'keep-bb-init',
        'inittab',
        '/bin/sh',
    ]);

This will be rendered by C<toString()> as

    <REQUIRES>
        keep-bb-init
        inittab
        /bin/sh
    </REQUIRES>

There are accessors for attributes that work like your typical perl
getters and setters.  That is, when called without a parameter, the
method behaves as a getter.  When called I<with> a parameter, the method
behaves as a setter and the value of the parameter is assigned to the
attribute.

getter:

    my $name = $busybox->name();

setter:

    $busybox->name('busybox');

=head2 Accessors For Single-Valued Attributes

These are accessors for attributes that are typically single-valued.

=over 4

=item name

This is the name of the node.

    $ecd->name()

=item type

This is the type of the node.  This is usually (always?) seen in the
context of an option and it can contain values such as "bool", "int",
"int.hex", "string", and "tridep".

    $ecd->type()

=item value

This is the value of a node which must be something appropriate for its
type.

    $ecd->value()

=item default_value

This is the value taken by the node if value is not defined.

    $ecd->default_value()

=item range

For the numerical types, it may be desirable to limit the range of
values that may be assigned such that C<value()> will always be
meaningful.  The use of this attribute has only been observed in
linux.ecd.

    $ecd->range()

=item help

This often contains prose regarding the current node.  I think it would
be nice if it were possible to use an alternative form of mark-up
language inside these sections.  (HTML, for instance).

    $ecd->help()

=item prompt

The value in prompt is used in TargetWizard to pose a question to the
user regarding whether he/she wants to enable an option or not.

    $ecd->prompt()

=item license

This is the license that the software falls under.  Usually, there is
only one license, but once in a while you may get a dual-licensed
package.  In that case, it's OK to give it an arrayref with multiple
licenses in it.

    $ecd->license()

=item srpm

This contains the name of the source RPM sans version information and
the file extension.  This attribute almost always has the same value as
C<name()>.

    $ecd->srpm()

=item specpatch

This attribute is only meaningful within the context of a component.
Specpatches are applied to .spec files just prior to the building of a
component.  They are often used to configure the compilation of a
component.  The busybox package provides a good example of this in
action.

    $ecd->specpatch()

=item static_size

This is the sum of .text, .data, and .bss for an option and/or component.

    $ecd->static_size()

=item eval_static_size

If static_size contains a mathematical expression, this method
evaluates it.

    ($size, $give_or_take) = $ecd->eval_static_size;

=item min_dynamic_size

The very least a program will C<malloc()> during its execution.

    $ecd->min_dynamic_size()

=item eval_min_dynamic_size

If min_dynamic_size contains a mathematical expression, this method
evaluates it.

    ($size, $give_or_take) = $ecd->eval_min_dynamic_size;

=item storage_size

This is the amount of space this component and/or option would consume on
a filesystem.

    $ecd->storage_size()

=item eval_storage_size

If storage_size contains a mathematical expression, this method
evaluates it.

    ($size, $give_or_take) = $ecd->eval_storage_size;

=item startup_time

The amount of time (in what metric?) from the time a program is executed
up to the point in time when the program becomes useful.

    $ecd->startup_time()

=item eval_startup_time

If startup_time contains a mathematical expression, this method
evaluates it.

    ($size, $give_or_take) = $ecd->eval_startup_time;

=back

=head2 Accessing Aggregate Attributes

The following are attributes that frequently contain aggregate values.
When setting attributes with aggregate values, enclose the values within
an arrayref.

=over 4

=item requiresexpr

This contains a C-like expression describing node dependencies.

    $ecd->requiresexpr()

=item if

I didn't know if using a keyword as a method name would be legal, but
apparently it is.  I also wonder if more than on 'if' statement is
allowed per node.

    $ecd->if()

=item conflicts

This is used to explicitly specify a node that conflicts with the
current node.  My first thought is that this is just another way
to say C<provides>.

    $ecd->conflicts()

=item build_vars

This specifies a list of transformations that can be applied to a .spec
file prior to building.

    $ecd->build_vars()

=item provides

This is a list of symbolic names that a node is said to be able to
provide.  For example, grep in busybox provides grep.  GNU/grep also
provides grep.  According to TargetWizard, these two cannot coexist on
the same instance of an Embedix distribution, because they both provide
grep.

    $ecd->provides()

=item requires

This is a list of libraries, files, provides, and other nodes required
by the current node.

    $ecd->requires()

=item keeplist

This is a list of files and directories provided by a component or
option.

    $ecd->keeplist()

=item choicelist

This is used for options in the kernel.

    $ecd->choicelist()

=item trideps

This is used for options in the kernel.  

    $ecd->trideps()

=back

=head2 Accessors That Take Named Attributes

The most general kind of accessor takes the name of an attribute as a
parameter and gets or sets it.

=over 4

=item getAttribute($name)

This gets the attribute called $name.

    $val = $ecd->getAttribute($name)

=item setAttribute($name, $value)

This sets the attribute called $name to $value.

    $ecd->setAttribute($name, $value)

=back

=head2 Utility Methods

=over 4

=item toString(indent => 0, shiftwidth => 4)

This will render an $ecd object as ASCII in ECD format.  JavaScript
programmers may find this familiar.  An interesting deviation from the
JavaScript version of C<toString()> is that this one will accept
optional parameters that allow one to control the rendering options.

    $string = $ecd->toString(indent => 0, shiftwidth => 4)

=over 4

=item indent

This is the number of spaces the first level nodes should be indented.
The default value is 0.

=item shiftwidth

This is the number of spaces a nested item should be indented.  The
default value is 4.

=back

=item mergeWith($the_other_ecd)

This combines the information contained in $the_other_ecd with $ecd.  In
the event that there is conflicting information, the information in
$the_other_ecd takes precedence over what already existed in $ecd.

    $ecd->mergeWith($the_other_ecd)

=item getDepth

This method returns how many levels deep one is in the object tree.  The
root level is considered 0.

    $depth = $ecd->getDepth()

=item getNodeClass

This returns the node class (ie. Group, Component, Option, or Autovar) of
an Embedix::ECD object.  It differs from the B<ref()> operator in that 
the string "Embedix::ECD::" is omitted from the returned value.

    $name = $ecd->getNodeClass()

=item getFormatOptions(@opt);

This is used internally by implementations of C<toString()> to compute
and return spacing information based on the formatting parameters passed
to it.

    $opt_hash_ref = $ecd->getFormatOptions(@opt);

=item attributeToString($opt_hash_ref);

This is used internally by implementations of C<toString()> to render a
node's attributes.

    $string = $ecd->attributeToString($opt_hash_ref);

=back

=head1 CLASS VARIABLES

You shouldn't be touching these.  This is just here for your
information.

=over 4

=item Embedix::ECD::__grammar

This scalar contains the grammar for ECD files.

=item Embedix::ECD::__parser

This contains an instance of Parse::RecDescent.

=back

=head1 DIAGNOSTICS

=over 4

=item $line: was expecting $TAGNAME, but found $CRAP instead.

This error occurs whenever an imbalanced tag is found.

=item $line: $ATTRIBUTE not allowed in $NODE_TYPE

not implemented

=back

=head1 BUGS

This parser becomes exponentially slower as the size of ECD data
increases.  busybox.ecd takes 30 seconds to parse.
Don't even try to parse linux.ecd -- it will sit there for hours
just sucking CPU before it ultimately fails and gives you back
nothing.  I don't know if there's anything I can do about it.

I have noticed that XML::Parser (which wraps around the C library,
expat) is 60 times faster than my Parse::RecDescent-based parser
when reading busybox.ecd.  I really want to take advantage of this.

=head1 COPYRIGHT

Copyright (c) 2000,2001 John BEPPU.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

=over 4

=item related libraries and programs

C<ecdlib.py(3)>, C<config2ecd(1)>, C<tw(1)>

=item related perl modules

Embedix::ECD::XMLv1(3pm)

=item CML2

The Configuration Menu Language is a constraint-based language
developed by Eric Raymond in an attempt to simplify the process of
configuring the Linux kernel.

    http://www.tuxedo.org/~esr/kbuild/

=item CDL

The Component Description Language was developed by Cygnus to support
configurable compilation for the eCos operating system.

    http://sourceware.cygnus.com/ecos/

=item the lastest version

    http://opensource.lineo.com/cgi-bin/cvsweb/pm/Embedix/ECD/

=back

=cut

# $Id: ECD.pm,v 1.9 2001/02/21 21:04:58 beppu Exp $
