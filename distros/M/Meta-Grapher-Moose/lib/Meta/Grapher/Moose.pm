package Meta::Grapher::Moose;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.03';

use Class::MOP;
use Meta::Grapher::Moose::Constants qw( CLASS ROLE P_ROLE ANON_ROLE );
use Try::Tiny;
use Scalar::Util qw( blessed );

use Moose;

has package => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has show_meta => (
    is  => 'ro',
    isa => 'Bool',
);

has show_new => (
    is  => 'ro',
    isa => 'Bool',
);

has show_destroy => (
    is  => 'ro',
    isa => 'Bool',
);

has show_moose_object => (
    is  => 'ro',
    isa => 'Bool',
);

has _renderer => (
    is       => 'ro',
    init_arg => 'renderer',
    does     => 'Meta::Grapher::Moose::Role::Renderer',
    required => 1,
);

# these are an internal record of what we asked our renderer to render.  It's
# used for de-duplication purposes (to avoid asking the renderer to render
# the same thing twice), but is inaccessible to the renderer that is responsible
# for keeping it's own state.

has _nodes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Bool]',
    default => sub { {} },
    handles => {
        _set_node          => 'set',
        _already_seen_node => 'get',
    },
);

sub _seen_node {
    my $self = shift;
    my $node = shift;
    $self->_set_node( $node => 1 );
}

has _edges => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Bool]',
    default => sub { {} },
    handles => {
        _set_edge          => 'set',
        _already_seen_edge => 'get',
    },
);

sub _seen_edge {
    my $self = shift;
    my $edge = shift;
    $self->_set_edge( $edge => 1 );
}

with 'MooseX::Getopt::Dashes';

sub run {
    my $self = shift;

    my $package = $self->package;

    # This just produces a better error message than Module::Runtime or any
    # other runtime loader.
    #
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "require $package; 1;"
        or die $@;
    ## use critic

    $self->_process_package( $package, 2048 );
    $self->_renderer->render;

    return 0;
}

sub _get_methods_and_attributes {
    my $self = shift;
    my $meta = shift;

    # HERE YOU ARE ETHAN
    # - turn into a for loop, add filtering for meta
    my @methods;
    for my $method_name ( $meta->get_method_list ) {
        next if $method_name eq 'meta'    && !$self->show_meta;
        next if $method_name eq 'new'     && !$self->show_new;
        next if $method_name eq 'DESTROY' && !$self->show_destroy;

        my $method = $meta->get_method($method_name);

        # ignore methods that weren't created in this class (i.e. they
        # came from a role)
        next if $method->original_package_name ne $meta->name;

        # ignore things that are just readers and writers since they're
        # already listed as attributes (we probably want to add some
        # configuration on this later)
        next
            if $method->isa('Class::MOP::Method::Accessor')
            && $method->accessor_type =~ /^[rw]/;

        push @methods, $method_name;
    }

    my @attributes;
ATTRIBUTE: for my $attr_name ( $meta->get_attribute_list ) {
        my $attribute = $meta->get_attribute($attr_name);

        # roles know where they get their attributes from
        if ( $attribute->can('original_role') ) {
            if ( $attribute->original_role->name eq $meta->name ) {
                push @attributes, $attr_name;
            }
            next ATTRIBUTE;
        }

        # otherwise we need to check each of our roles to see if they
        # have the accessor of the same neme
        for my $role ( $self->_roles_from($meta) ) {
            if ( $role->get_attribute($attr_name) ) {
                next ATTRIBUTE;
            }
        }
        push @attributes, $attr_name;
    }

    return (
        methods    => \@methods,
        attributes => \@attributes,
    );
}

sub _process_package {
    my $self    = shift;
    my $package = shift;
    my $weight  = shift;

    my $meta = try { $package->meta }
        or die "$package does not have a ->meta method\n";

    die
        "$package->meta is not a Moose::Meta::Class or a Moose::Meta::Role, it's a "
        . ref($meta) . "\n"
        unless blessed $meta
        && ( $meta->isa('Moose::Meta::Class')
        || $meta->isa('Moose::Meta::Role') );

    my $name = $self->_node_label_for($meta);
    $self->_maybe_add_node_to_graph(
        id    => $name,
        label => $name,
        type  => CLASS,
        $self->_get_methods_and_attributes($meta),
    );

    # We halve the weight each time we go up the tree. This makes the graph
    # cleaner (straighter lines) nearest the node we start from.
    $self->_follow_parents( $meta, $weight )
        if $meta->isa('Moose::Meta::Class');
    $self->_follow_roles( $meta, $meta, $weight );

    return 0;
}

sub _follow_parents {
    my $self   = shift;
    my $meta   = shift;
    my $weight = shift;

    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    my @parents = map { Class::MOP::class_of($_) } $meta->superclasses;
    ## use critic

    for my $parent (@parents) {

        my $name = $self->_node_label_for($parent);
        $self->_maybe_add_node_to_graph(
            id    => $name,
            label => $name,
            type  => CLASS,
            $self->_get_methods_and_attributes($parent),
        );

        $self->_maybe_add_edge_to_graph(
            from   => $parent,
            to     => $meta,
            type   => CLASS,
            weight => $weight,
        );

        $self->_follow_roles( $parent, $parent, $weight );
        $self->_follow_parents( $parent, $weight / 2 );
    }

    return;
}

sub _follow_roles {
    my $self       = shift;
    my $to_meta    = shift;
    my $roles_from = shift;
    my $weight     = shift;

    for my $role ( $self->_roles_from($roles_from) ) {
        $self->_record_role(
            $to_meta,
            $role,
            $weight / 2
        );
    }

}

sub _roles_from {
    my $self       = shift;
    my $roles_from = shift;

    if ( $roles_from->isa('Moose::Meta::Class') ) {
        return map { $_->role } $roles_from->role_applications;
    }

    return @{ $roles_from->get_roles };
}

sub _record_role {
    my $self    = shift;
    my $to_meta = shift;
    my $role    = shift;
    my $weight  = shift;

    # For the purposes of this graph, Composite roles are essentially an
    # implementation detail of Moose. We just want to see that Class A
    # consumes Roles X, Y, & Z. The fact that this was done in a single "with"
    # (or not) is not going to be included on the graph. We skip composite
    # roles and simply graph the roles that they are composed of.
    unless ( $role->isa('Moose::Meta::Role::Composite') ) {
        my ( $label, $type );
        if (
            $role->isa(
                'MooseX::Role::Parameterized::Meta::Role::Parameterized')
            ) {
            $label = $self->_node_label_for( $role->genitor );
            $type  = ANON_ROLE;
        }
        else {
            $label = $self->_node_label_for($role);
            $type  = (
                $role->meta->can('does_role') && $role->meta->does_role(
                    'MooseX::Role::Parameterized::Meta::Trait::Parameterizable'
                )
            ) ? P_ROLE : ROLE;
        }

        $self->_maybe_add_node_to_graph(
            id    => $self->_node_label_for($role),
            label => $label,
            type  => $type,
            $self->_get_methods_and_attributes($role),
        );

        $self->_maybe_add_edge_to_graph(
            from   => $role,
            to     => $to_meta,
            weight => $weight,
        );

        $to_meta = $role;
    }

    $self->_follow_roles( $to_meta, $role, $weight );

    return;
}

# We need to dedeuplicate nodes - obviously more than one thing can point
# to any given node!
sub _maybe_add_node_to_graph {
    my $self = shift;
    my %p    = @_;

    return if $p{id} eq 'Moose::Object' && !$self->show_moose_object;
    return if $self->_already_seen_node( $p{id} );

    $self->_renderer->add_package( map { $_ => $p{$_} }
            qw( id methods attributes type label ) );

    $self->_seen_node( $p{id} );

    return;
}

# We also need to deduplicate edges - it's possible for an edge to appear twice
# if something earlier in the graph consumes a role directly that it also
# consumes via another role indirectly. For example, if class A consumes roles B
# & C, but role B _also_ consumes role C. In that case, we end up visiting role
# C twice. That means that if C consumes some roles we'd end up seeing that
# relationship twice as well.
#
# The same could happen with a weird inheritance tree where a class and its
# parent both inherit from the same (other) parent class.
sub _maybe_add_edge_to_graph {
    my $self = shift;
    my %p    = @_;

    @p{qw( from to )}
        = map { $self->_node_label_for($_) } @p{qw( from to )};

    unless ( $self->show_moose_object ) {
        return if $p{from} eq 'Moose::Object';
        return if $p{to} eq 'Moose::Object';
    }

    # When a parameterized role consumes role inside its role{} block, we may
    # end up trying to add an edge from the parameterized role to itself,
    # which we can just ignore.
    return if $p{from} eq $p{to};

    my $key = join ' - ', @p{qw( from to )};
    return if $self->_already_seen_edge($key);

    $self->_renderer->add_edge(
        from   => $p{from},
        to     => $p{to},
        weight => $p{weight},
        type   => $p{type},
    );

    $self->_seen_edge($key);

    return;
}

sub _node_label_for {
    my $self = shift;
    my $meta = shift;

    return $meta unless blessed $meta && $meta->can('name');
    return $meta->name;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Produce graphs showing meta-information about classes and roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose - Produce graphs showing meta-information about classes and roles

=head1 VERSION

version 1.03

=head1 SYNOPSIS

From the shell:

   foo@bar:~/package$ graph-meta.pl --package='My::Package::Name' --output='diagram.png'

Or from code:

    my $grapher = Meta::Grapher::Moose->new(
        package  => 'My::Package::Name',
        renderer => Meta::Grapher::Moose::Renderer::Plantuml->new(
            output => 'diagram.png',
        ),
    );
    $grapher->run;

=head1 DESCRIPTION

STOP: The most common usage for this module is to use the command line
F<graph-meta.pl> program. You should read the documentation for
F<graph-meta.pl> to see how that works.

This module allows you to create graphs of your Moose classes showing a
directed graph of the parent classes and roles that your class consumes
recursively. In short, it can visually answer the questions like "Why did I
end up consuming that role" and, with the right renderer backend, "Where did
that method come from?"

=head2 Example Output

With the GraphViz renderer (no methods/attributes):
L<http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/graphviz/example.png>

=for html <img src="http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/graphviz/example.png" width="100%">

And with the PlantUML renderer:
L<http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/plantuml/example.png>

=for html <img src="http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/plantuml/example.png" width="100%">

=head1 ATTRIBUTES

This class accepts the following attributes:

=head2 package

The name of package that we should render a graph for.

String. Required.

=head2 show_meta

Since every Moose class and role normally has a C<meta()> method it is
omitted from every class for brevity;  Enabling this option causes it to be
rendered.

=head2 show_new

The standard C<new()> constructor is omitted from every class for brevity;
Enabling this option causes it to be rendered.

=head2 show_destroy

The C<DESTROY()> method that Moose installs is omitted from every class for
brevity; Enabling this option causes it to be rendered.

=head2 show_moose_object

The L<Moose::Object> base class is normally omitted from the diagram for
brevity. Enabling this option causes it be rendered.

=head2 _renderer

The renderer instance you want to use to create the graph.

Something that consumes L<Meta::Grapher::Moose::Role::Renderer>. Required,
should be passed as the C<renderer> argument (without the leading underscore.)

=head1 METHODS

This class provides the following methods:

=head2 run

Builds the graph from the source code and tells the renderer to render it.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose>
(or L<bug-meta-grapher-moose@rt.cpan.org|mailto:bug-meta-grapher-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTOR

=for stopwords Mark Fowler

Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
