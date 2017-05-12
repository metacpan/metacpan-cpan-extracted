package Forest::Tree::Pure;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util 'reftype', 'refaddr';
use List::Util   'sum', 'max';

with qw(MooseX::Clone);

has 'node' => (
    is        => 'ro',
    isa       => 'Item',
    predicate => 'has_node',
);

has 'uid'  => (
    is      => 'rw',
    isa     => 'Value',
    lazy    => 1,
    default => sub { (overload::StrVal($_[0]) =~ /\((.*?)\)$/)[0] },
);

has 'children' => (
    traits    => ['Array'],
    is        => 'ro',
    isa       => 'ArrayRef[Forest::Tree::Pure]',
    lazy      => 1,
    default   => sub { [] },
    handles   => {
        get_child_at => 'get',
        child_count  => 'count',
    },
);

has 'size' => (
    traits => [qw(NoClone)],
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_size {
    my $self = shift;

    if ( $self->is_leaf ) {
        return 1;
    } else {
        return 1 + sum map { $_->size } @{ $self->children };
    }
}

has 'height' => (
    traits => [qw(NoClone)],
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_height {
    my $self = shift;

    if ( $self->is_leaf ) {
        return 0;
    } else {
        return 1 + max map { $_->height } @{ $self->children };
    }
}

## informational
sub is_leaf { (shift)->child_count == 0 }

## traversal
sub traverse {
    my ($self, @args) = @_;

    $_->visit(@args) for @{ $self->children };
}

sub visit {
    my ( $self, $f, @args ) = @_;

    $self->fmap_cont(sub {
        my ( $tree, $cont, @args ) = @_;
        $tree->$f(@args);
        $cont->();
    });
}

sub fmap_cont {
    my ( $self, @args ) = @_;

    unshift @args, "callback" if @args % 2 == 1;

    my %args = ( depth => 0, path => [], index_path => [], @args );

    my $f = $args{callback};

    (defined($f))
        || confess "Cannot traverse without traversal function";
    (!ref($f) or reftype($f) eq "CODE")
        || confess "Traversal function must be a CODE reference or method name, not: $f";

    $self->$f(
        sub {
            my ( @inner_args ) = @_;
            unshift @inner_args, "callback" if @inner_args % 2 == 1;
            my $children = $args{children} || $self->children;

            my %child_args = ( %args, depth => $args{depth} + 1, path => [ @{ $args{path} }, $self ], parent => $self, @inner_args );

            my @index_path  = @{ $args{index_path} };

            my $i = 0;
            map {
                my $index = $i++;
                $_->fmap_cont(
                    %child_args,
                    index => $index,
                    index_path => [ @index_path, $index ],
                )
            } @$children;
        },
        %args,
    );
}

sub locate {
    my ( $self, @path ) = @_;

    my @nodes = $self->descend(@path);

    return $nodes[-1];
}

sub descend {
    my ( $self, @path ) = @_;

    if ( @path ) {
        my ( $head, @tail ) = @path;

        if ( my $child = $self->get_child_at($head) ) {
            return ( $self, $child->descend(@tail) );
        } else {
            confess "No such child $head";
        }
    } else {
        return $self;
    }
}

sub transform {
    my ( $self, $path, $method, @args ) = @_;

    if ( @$path ) {
        my ( $i, @path ) = @$path;

        my $targ = $self->get_child_at($i);

        my $transformed = $targ->transform(\@path, $method, @args);

        if ( refaddr($transformed) == refaddr($targ) ) {
            return $self;
        } else {
            return $self->set_child_at( $i => $transformed );
        }
    } else {
        return $self->$method(@args);
    }
}

sub set_node {
    my ( $self, $node ) = @_;

    $self->clone( node => $node );
}

sub replace {
    my ( $self, $replacement ) = @_;

    return $replacement;
}

sub add_children {
    my ( $self, @additional_children ) = @_;

    foreach my $child ( @additional_children ) {
        (blessed($child) && $child->isa(ref $self))
            || confess "Child parameter must be a " . ref($self) . " not (" . (defined $child ? $child : 'undef') . ")";
    }

    my @children = @{ $self->children };

    push @children, @additional_children;

    return $self->clone( children => \@children );
}

sub add_child {
    my ( $self, $child ) = @_;

    $self->add_children($child);
}

sub set_child_at {
    my ( $self, $index, $child ) = @_;

    (blessed($child) && $child->isa(ref $self))
        || confess "Child parameter must be a " . ref($self) . " not (" . (defined $child ? $child : 'undef') . ")";

    my @children = @{ $self->children };

    $children[$index] = $child;

    $self->clone( children => \@children );
}

sub remove_child_at {
    my ( $self, $index ) = @_;

    my @children = @{ $self->children };

    confess "No child at index '$index'" if @children <= $index;

    splice @children, $index, 1;

    $self->clone( children => \@children );

}

sub insert_child_at {
    my ( $self, $index, $child ) = @_;

    (blessed($child) && $child->isa('Forest::Tree::Pure'))
        || confess "Child parameter must be a Forest::Tree::Pure not (" . (defined $child ? $child : 'undef') . ")";

    my @children = @{ $self->children };

    confess "'$index' is out of bounds" if @children < $index;

    splice @children, $index, 0, $child;

    $self->clone( children => \@children );
}

sub get_child_index {
    my ( $self, $child ) = @_;

    my $index = 0;
    foreach my $sibling (@{ $self->children }) {
        (refaddr($sibling) eq refaddr($child)) && return $index;
        $index++;
    }

    return;
}

sub reconstruct_with_class {
    my ( $self, $class ) = @_;

    confess "No class provided" unless defined($class);

    return $class->new(
        node => $self->node,
        children => [
            map { $_->reconstruct_with_class($class) } @{ $self->children },
        ],
    );
}

sub to_pure_tree {
    my $self = shift;

    return $self;
}

sub to_mutable_tree {
    my $self = shift;

    $self->reconstruct_with_class("Forest::Tree");
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Pure - An n-ary tree

=head1 SYNOPSIS

  use Forest::Tree;

  my $t = Forest::Tree::Pure->new(
      node     => 1,
      children => [
          Forest::Tree::Pure->new(
              node     => 1.1,
              children => [
                  Forest::Tree::Pure->new(node => 1.1.1),
                  Forest::Tree::Pure->new(node => 1.1.2),
                  Forest::Tree::Pure->new(node => 1.1.3),
              ]
          ),
          Forest::Tree::Pure->new(node => 1.2),
          Forest::Tree::Pure->new(
              node     => 1.3,
              children => [
                  Forest::Tree::Pure->new(node => 1.3.1),
                  Forest::Tree::Pure->new(node => 1.3.2),
              ]
          ),
      ]
  );

  $t->traverse(sub {
      my $t = shift;
      print(('    ' x $t->depth) . ($t->node || '\undef') . "\n");
  });

=head1 DESCRIPTION

This module is a base class for L<Forest::Tree> providing functionality for
immutable trees.

It can be used independently for trees that require sharing of children between
parents.

There is no single authoritative parent (no upward links at all), and changing
of data is not supported.

This class is appropriate when many tree roots share the same children (e.g. in
a versioned tree).

This class is strictly a DAG, wheras L<Forest::Tree> produces a graph with back references

=head1 ATTRIBUTES

=over 4

=item I<node>

=item I<children>

=over 4

=item B<get_child_at ($index)>

Return the child at this position. (zero-base index)

=item B<child_count>

Returns the number of children this tree has

=back

=item I<size>

=over 4

=item B<size>

=item B<has_size>

=back

=item I<height>

=over 4

=item B<height>

=item B<has_height>

=back

=back

=head1 METHODS

=over 4

=item B<is_leaf>

True if the current tree has no children

=item B<traverse (\&func)>

Takes a reference to a subroutine and traverses the tree applying this subroutine to
every descendant. (But not the root)

=item B<visit (&func)>

Traverse the entire tree, including the root.

=item B<fmap_cont (&func)>

A CPS form of C<visit> that lets you control when and how data flows from the children.

It takes a callback in the form:

    sub {
        my ( $tree, $cont, @args ) = @_;

        ...
    }

and C<$cont> is a code ref that when invoked will apply that same function to the children of C<$tree>.

This allows you to do things like computing the sum of all the node values in a tree, for instance:

    use List::Util qw(sum);

    my $sum = $tree->fmap_cont(sub {
        my ( $tree, $cont ) = @_;

        return sum( $tree->node, $cont->() );
    });

And also allows to stop traversal at a given point.

=item B<add_children (@children)>

=item B<add_child ($child)>

Create a new tree node with the children appended.

The children must inherit C<Forest::Tree::Pure>

Note that this method does B<not> mutate the tree, instead it clones and
returns a tree with the augmented list of children.

=item B<insert_child_at ($index, $child)>

Insert a child at this position. (zero-base index)

Returns a derived tree with overridden children.

=item B<set_child_at ($index, $child)>

Replaces the child at C<$index> with C<$child>.

=item B<remove_child_at ($index)>

Remove the child at this position. (zero-base index)

Returns a derived tree with overridden children.

=item B<locate (@path)>

Find a child using a path of child indexes. These two examples return the same object:

    $tree->get_child_at(0)->get_child_at(1)->get_child_at(0);

    $tree->locate(0, 1, 0);

=item B<descend (@path)>

Like C<lookup> except that it returns every object in the path, not just the leaf.

=item C<transform (\@path, $method, @args)>

Performs a lookup on C<@path>, applies the method C<$method> with C<@args> to
the located node, and clones the path to the parent returning a derived tree.

This method is also implemented in L<Forest::Tree> by mutating the tree in
place and returning the original tree, so the same transformations should work
on both pure trees and mutable ones.

This code:

    my $new = $root->transform([ 1, 3 ], insert_child_at => 3, $new_child);

will locate the child at the path C<[ 1, 3 ]>, call C<insert_child_at> on it,
creating a new version of C<[ 1, 3 ]>, and then return a cloned version of
C<[ 1 ]> and the root node recursively, such that C<$new> appears to be a
mutated C<$root>.

=item set_node $new

Returns a clone of the tree node with the node value changed.

=item C<replace $arg>

Returns the argument. This is useful when used with C<transform>.

=item B<clone>

Provided by L<MooseX::Clone>.

Deeply clones the entire tree.

Subclasses should use L<MooseX::Clone> traits to specify the correct cloning
behavior for additional attributes if cloning is used.

=item B<reconstruct_with_class $class>

Recursively recreates the tree by passing constructor arguments to C<$class>.

Does not use C<clone>.

=item B<to_mutable_tree>

Invokes C<reconstruct_with_class> with L<Forest::Tree> as the argument.

=item B<to_pure_tree>

Returns the invocant.

=item B<get_child_index ($child)>

Returns the index of C<$child> in C<children> or undef if it isn't a child of
the current tree.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
