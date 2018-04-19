package Graphics::Grid;

# ABSTRACT: An incomplete port of the R "grid" library to Perl

use 5.014;

use Graphics::Grid::Class;

our $VERSION = '0.0001'; # VERSION

use List::AllUtils qw(reduce);
use Math::Trig qw(:pi :radial deg2rad);
use Module::Load;
use Types::Standard qw(InstanceOf ConsumerOf ArrayRef HashRef Str);
use namespace::autoclean;

use Graphics::Grid::Viewport;
use Graphics::Grid::ViewportTree;
use Graphics::Grid::Util;

has _vptree => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build__vptree',
    init_arg => undef,
);

has _current_vptree => (
    is       => 'rw',
    lazy     => 1,
    builder  => '_build__current_vptree',
    init_arg => undef,
);


has driver => (
    is      => 'rw',
    lazy    => 1,
    isa     => ConsumerOf ["Graphics::Grid::Driver"],
    builder => '_build_driver',

);

has _gp_stack => (
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        _push_gp  => 'push',
        _pop_gp   => 'pop',
        _clear_gp => 'clear',
    }
);

sub _build_driver {
    my $driver_cls = 'Graphics::Grid::Driver::Cairo';
    load $driver_cls;
    return $driver_cls->new();
}

sub _build__vptree {
    my ($self) = @_;
    return Graphics::Grid::ViewportTree->new(
        node => Graphics::Grid::Viewport->new(
            name => 'ROOT',
            gp   => $self->driver->default_gpar()
        )
    );
}

sub _build__current_vptree { $_[0]->_vptree }


method current_vptree( $all = true ) {
    return ( $all ? $self->_vptree : $self->_current_vptree );
}


method current_viewport() {
    return $self->_current_vptree->node;
}

method _push_vp($vp) {

    # Viewports in a stack are pushed in series.
    # Viewports in a list are pushed in parallel.
    # For a tree of viewports, the parent is pushed then the children are
    #  pushed in parallel.

    # Push a list of viewpoints in parallel, and move current to last node.
    my $push_node = sub {
        my (@vps) = @_;
        return unless @vps;

        my @trees =
          map { Graphics::Grid::ViewportTree->new( node => $_ ) } @vps;
        $self->_current_vptree->add_children(@trees);
        $self->_current_vptree( $trees[-1] );
    };

    if ( $vp->$_isa('Graphics::Grid::Viewport') ) {
        &$push_node($vp);
    }
    elsif ( Ref::Util::is_arrayref($vp) ) {
        &$push_node(@$vp);
    }
    elsif ( $vp->$_isa('Graphics::Grid::ViewportTree') ) {
        my $t = $vp;
        $self->_current_vptree->add_child($t);

        # go right-then-down in the sub-tree
        while ( my $child_count = $t->child_count ) {
            $t = $t->get_child_at( $child_count - 1 );
        }
        $self->_current_vptree($t);
    }
}


method push_viewport(@vps) {
    for my $vp (@vps) {
        $self->_push_vp($vp);
    }
    $self->_set_vptree( $self->_current_vptree );
}

sub _up_viewport {
    my ( $self, $n, $is_pop ) = @_;

    return if ( $n == 0 );
    return unless ( $self->_current_vptree->has_parent );

    $self->_current_vptree( $self->_current_vptree->parent );
    if ($is_pop) {
        $self->_current_vptree->children( [] );
    }
    $self->_up_viewport( $n - 1, $is_pop );
}


method pop_viewport( $n = 1 ) {
    if ( $n < 0 ) {
        die "must pop at least one viewport";
    }
    if ( $n == 0 ) {

        # retain only the root node
        $self->_current_vptree( $self->_vptree );
        $self->_current_vptree->children( [] );
    }
    else {    # $n > 0
        $self->_up_viewport( $n, true );
    }
    $self->_set_vptree( $self->_current_vptree );
}


method up_viewport( $n = 1 ) {
    if ( $n < 0 ) {
        die "must navigate at least one viewport";
    }
    if ( $n == 0 ) {
        $self->_current_vptree( $self->_vptree );
    }
    else {    # $n > 0
        $self->_up_viewport($n);
    }
    $self->_set_vptree( $self->_current_vptree );
}

# return arrayref of tree nodes.
method _find_viewport( $from_tree, $name ) {
    my @nodes;
    $from_tree->visit(
        sub {
            my ($tree) = @_;
            if ( $tree->node->name eq $name ) {
                push @nodes, $tree;
            }
        }
    );
    return \@nodes;
}

method _check_vppath( $tree, $path = [] ) {
    if ( @$path == 0 ) {
        return 1;
    }
    if ( $tree->has_parent ) {
        my $parent = $tree->parent;
        if ( $parent->node->name ne $path->[-1] ) {
            return 0;
        }
        else {
            return $self->_check_vppath( $parent,
                [ @$path[ 0 .. $#$path - 1 ] ] );
        }
    }
    return 0;
}

method _seek_viewport( $from_tree, $name_or_path ) {
    my $path = ref($name_or_path) eq 'ARRAY' ? $name_or_path : [$name_or_path];
    my $target = pop @$path;
    my $trees = $self->_find_viewport( $from_tree, $target );

    for my $tree (@$trees) {
        if ( $self->_check_vppath( $tree, [@$path] ) ) {
            $self->_current_vptree($tree);

            my $depth         = 0;
            my $from_tree_uid = $from_tree->node->_uid;
            while ( $tree->node->_uid ne $from_tree_uid ) {
                $depth++;
                last unless ( $tree->has_parent );
                $tree = $tree->parent;
            }
            return $depth;
        }
    }
    die "Viewport '$target' was not found";
}


method down_viewport($name_or_path) {
    my $n = $self->_seek_viewport( $self->_current_vptree, $name_or_path );
    $self->_set_vptree();
    return $n;
}


method seek_viewport($name_or_path) {
    my $n = $self->_seek_viewport( $self->_vptree, $name_or_path );
    $self->_set_vptree();
    return $n;
}


method draw($grob) {
    $grob->validate();

    # set root vptree to driver if it does not yet have one.
    unless ( $self->driver->current_vptree ) {
        $self->_set_vptree( $self->_vptree );
    }

    if ( $grob->vp ) {
        $self->push_viewport( $grob->vp );
    }

    if ( $grob->gp ) {
        $self->_push_gp( $grob->gp );
    }
    my @gp = reverse @{ $self->_gp_stack };
    my $merged_gp = reduce { $a->merge($b) } $gp[0], @gp[ 1 .. $#gp ];
    $self->driver->current_gp($merged_gp);

    $grob->draw( $self->driver );

    if ( $grob->gp ) {
        $self->_pop_gp();
    }

    if ( $grob->vp ) {
        $self->pop_viewport( $grob->vp );
    }
}

my @grob_types = qw(
  circle lines null points polygon polyline rect segments text zero
);

classmethod _grob_types() {
    return @grob_types;
}


for my $grob_type ( __PACKAGE__->_grob_types ) {
    my $class = 'Graphics::Grid::Grob::' . ucfirst($grob_type);
    load $class;

    my $func = sub {
        my $self = shift;
        my $grob = $class->new(@_);
        $self->draw($grob);
    };

    no strict 'refs';    ## no critic
    *{$grob_type} = $func;
}

# set current viewport to state
method _set_vptree( $vptree = $self->_current_vptree ) {
    $self->driver->current_vptree($vptree);

    my $path = $self->_current_vptree->path_from_root;
    $self->_clear_gp;
    $self->_push_gp( grep { defined $_ } map { $_->gp } @$path );
}


method write($filename) {
    $self->driver->write($filename);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid - An incomplete port of the R "grid" library to Perl

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid;
    use Graphics::Grid::GPar;
    use Graphics::Grid::Viewport;

    my $grid = Graphics::Grid->new();
    $grid->push_viewport(
            Graphics::Grid::Viewport->new(width => 0.5, height => 0.5));

    $grid->rect(gp => Graphics::Grid::GPar->new(col => 'blue'));
    $grid->write("foo.png");

=head1 DESCRIPTION

This is alpha code. Before version 1.0 of this library, its API would change
without any notice.

This library is an incomplete port of Paul Murrell's R "grid" library. The R
"grid" library is a low level graphics system that provides full access to
the graphics facilities in R. It's used by some other R plotting libraries
including the famous "ggplot2". 

With my (immature maybe) understanding the fundamental designs and features
of the R "grid" library can be summarized as following:

=over 4

=item *

It supports a few graphical primitives (called "grob") like lines,
rectangles, circles, text, etc. And they can be configured via a set
of graphical parameters (called "gpar"), like colors, line weights and
types, fonts, etc. And, it also has a tree structure called "gTree"
which allows arranging the grobs in a hierachical way.

=item *

It designs something called "viewport" which is basically an arbitrary
rectangular region which defines the transform (position, coordinate scale,
rotation) on the graphics device. There is a global viewport stack 
(actually it's a tree). Viewports can be pushed onto, or popped from the
stack, and drawing always takes place on the "top" or "current" viewport.
Thus for drawing each graphical primitive it's possible to have a specific
transform for the graphics device context. Combined with its ability to
define graphical primitives as mention above, the "grid" library enables
the full possibilities of customization which cannot be done with R's
standard "plot" system.

=item *

It has a "unit" system. a "unit" is basically a numerical value plus a
unit. The default unit is "npc" (Normalised Parent Coordinates), which
describes an object's position or dimension either in relative to those
of the parent viewport or be absolute. So when defining a grob, for
example for a rectangle you can specify its (x, y) position or width or
heightha relative to a viewport, although absolute values are also
possible and you can combine relative and absolute values. Beause of
this design, it's easy to adapt a plot to various types and sizes of
graphics devices. 

=item *

Similar to many stuffs in the R world, parameters to the R "grid" library
are vectorized. This means a single rectangular "grob" object can actually
contain information for multiple rectangles. 

=item *

It has a grid-based layout system. That's probably why the library got the
name "grid".

=back

The target of this Perl Graphics::Grid library, as of today, is to have
most of the R "grid"'s fundamental features mentioned above except for
the grid-layout system. 

This Graphics::Grid module is the object interface of this libray. There is
also a function interface L<Graphics::Grid::Functions>, which is more like
the interface of the R "grid" library.

=head1 ATTRIBUTES

=head2 driver

Set the device driver. The value needs to be a consumer of the L<Graphics::Grid::Driver>
role. Default is a L<Graphics::Grid::Driver::Cairo> object.

=head1 METHODS

=head2 current_vptree($all=true)

If C<$all> is a true value, it returns the whole viewport tree, whose root
node contains the "ROOT" viewport. If C<$all> is a false value, it returns
the current viewport tree, whose root node contains the current viewport.

=head2 current_viewport()

Get the current viewport. It's same as,

    $grid->current_vptree(0)->node;

=head2 push_viewport(@viewports)

Push viewports onto the global viewport tree, and update the
current viewport.

=head2 pop_viewport($n=1)

Remove C<$n> levels of viewports from the global viewport tree,
and update to current viewport to the remaining parent node of the
removed part of tree nodes.

if C<$n> is 0 then only the "ROOT" node of the global viewport
tree would be retained and set to current. 

=head2 up_viewport($n=1)

This is similar to the C<pop_viewport> method except that it does
not remove the tree nodes, but only updates the current viewport. 

=head2 down_viewport($from_tree_node, $name)

Start from a tree node, and try to find the first child node whose
name is C<$name>. If found it sets the node to current, and returns
the number of tree leves it went down. So it's possible to do
something like,

    my $depth = downViewport(...);
    upViewport($depth).

C<$name> can also be an array ref of names which defines a "path".
In this case the top-most node in the "path" is set to current.

=head2 seek_viewport($from_tree, $name)

This is similar to the C<down_viewport> method except that this always
starts from the "ROOT" node.

=head2 draw($grob)

Draw a grob (or gtree) on the graphics device.

=head2 ${grob_type}(%params)

This creates a grob and draws it. For example, C<rect(%params)> would create
and draw a rectangular grob.

C<$grob_type> can be one of following,

=over 4

=item *

circle

=item *

lines

=item *

points

=item *

polygon

=item *

polyline

=item *

rect

=item *

segments

=item *

text

=item *

null

=item *

zero

=back

=head2 write($filename)

Write to file.

=head1 TODOS

Including but not limited to,

=over 4

=item * 

Support canvas resize.

=item *

Support R pch symbols for points grob. 

=item *

Cache things to speed up the drawing.

=back

=head1 ACKNOWLEDGEMENT

Thanks to Paul Murrell and his great R "grid" library, from which this Perl
library is ported.

=head1 SEE ALSO

The R grid package L<https://stat.ethz.ch/R-manual/R-devel/library/grid/html/grid-package.html>

L<Graphics::Grid::Functions>

Examples in the C<examples> directory of the package release.

An article that explains a few concepts in the R "grid" package L<http://ww2.amstat.org/publications/jse/v18n3/zhou.pdf>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
