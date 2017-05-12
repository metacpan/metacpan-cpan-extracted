package Forest::Tree;
use Moose;

use Scalar::Util 'reftype', 'refaddr';
use List::Util   'sum', 'max';

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

extends qw(Forest::Tree::Pure);

#has '+node' => ( is => 'rw' );
has 'node' => (
    traits => [qw(StorableClone)],
    is  => 'rw',
    isa => 'Item',
);

sub set_node {
    my ( $self, $new ) = @_;
    $self->node($new);
    $self;
}

has 'parent' => (
    traits    => [qw(NoClone)],
    reader      => 'parent',
    writer      => '_set_parent',
    predicate   => 'has_parent',
    clearer     => 'clear_parent',
    isa         => 'Maybe[Forest::Tree]',
    weak_ref => 1,
    handles     => {
        'add_sibling'       => 'add_child',
        'get_sibling_at'    => 'get_child_at',
        'insert_sibling_at' => 'insert_child_at',
    },
);

#has '+children' => (
#    is        => 'rw',
has 'children' => (
    traits    => [qw(Array Clone)],
    is        => 'rw',
    isa       => 'ArrayRef[Forest::Tree]',
    lazy      => 1,
    default   => sub { [] },
    handles   => {
        get_child_at => 'get',
        child_count  => 'count',
    },
    trigger   => sub {
        my ($self, $children) = @_;
        foreach my $child (@$children) {
            $child->_set_parent($self);
            $self->clear_height if $self->has_height;
            $self->clear_size   if $self->has_size;
        }
    }
);

after 'clear_size' => sub {
    my $self = shift;
    $self->parent->clear_size
        if $self->has_parent && $self->parent->has_size;
};

after 'clear_height' => sub {
    my $self = shift;
    $self->parent->clear_height
        if $self->has_parent && $self->parent->has_height;
};

## informational
sub is_root { !(shift)->has_parent }

## depth
sub depth { ((shift)->parent || return -1)->depth + 1 }

## child management

sub add_child {
    my ($self, $child) = @_;
    (blessed($child) && $child->isa(ref $self))
        || confess "Child parameter must be a " . ref($self) . " not (" . (defined $child ? $child : 'undef') . ")";
    $child->_set_parent($self);
    $self->clear_height if $self->has_height;
    $self->clear_size   if $self->has_size;
    push @{ $self->children } => $child;
    $self;
}

sub replace {
    my ( $self, $replacement ) = @_;

    confess "Can't replace root" if $self->is_root;

    $self->parent->set_child_at( $self->get_index_in_siblings, $replacement );

    return $replacement;
}

sub add_children {
    my ($self, @children) = @_;
    $self->add_child($_) for @children;
    return $self;
}

sub set_child_at {
    my ( $self, $index, $child ) = @_;

    (blessed($child) && $child->isa(ref $self))
        || confess "Child parameter must be a " . ref($self) . " not (" . (defined $child ? $child : 'undef') . ")";

    $self->clear_height if $self->has_height;
    $self->clear_size   if $self->has_size;

    my $children = $self->children;

    $children->[$index]->clear_parent;

    $children->[$index] = $child;
    $child->_set_parent($self);

    $self;
}

sub insert_child_at {
    my ($self, $index, $child) = @_;
    (blessed($child) && $child->isa(ref $self))
        || confess "Child parameter must be a " . ref($self) . " not (" . (defined $child ? $child : 'undef') . ")";
    $child->_set_parent($self);
    $self->clear_height if $self->has_height;
    $self->clear_size   if $self->has_size;
    splice @{ $self->children }, $index, 0, $child;
    $self;
}

sub remove_child_at {
    my ($self, $index) = @_;
    $self->clear_height if $self->has_height;
    $self->clear_size   if $self->has_size;
    my $child = splice @{ $self->children }, $index, 1;
    $child->clear_parent;
    $child;
}

##siblings

sub siblings {
    my $self = shift;
    return [] unless $self->has_parent;
    [ grep { $self->uid ne $_->uid } @{ $self->parent->children } ];
}

sub get_index_in_siblings {
    my ($self) = @_;
    return -1 if $self->is_root;

    $self->parent->get_child_index($self);
}

## cloning

sub clone_and_detach { shift->clone(@_) }

sub to_pure_tree {
    my $self = shift;

    $self->reconstruct_with_class("Forest::Tree::Pure");
}

sub to_mutable_tree {
    my $self = shift;

    return $self;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Forest::Tree - An n-ary tree

=head1 SYNOPSIS

  use Forest::Tree;

  my $t = Forest::Tree->new(
      node     => 1,
      children => [
          Forest::Tree->new(
              node     => 1.1,
              children => [
                  Forest::Tree->new(node => 1.1.1),
                  Forest::Tree->new(node => 1.1.2),
                  Forest::Tree->new(node => 1.1.3),
              ]
          ),
          Forest::Tree->new(node => 1.2),
          Forest::Tree->new(
              node     => 1.3,
              children => [
                  Forest::Tree->new(node => 1.3.1),
                  Forest::Tree->new(node => 1.3.2),
              ]
          ),
      ]
  );

  $t->traverse(sub {
      my $t = shift;
      print(('    ' x $t->depth) . ($t->node || '\undef') . "\n");
  });

=head1 DESCRIPTION

This module is a basic n-ary tree, it provides most of the functionality
of Tree::Simple, whatever is missing will be added eventually.

This class inherits from L<Forest::Tree::Pure>>, but all shared methods and
attributes are documented in both classes.

=head1 ATTRIBUTES

=over 4

=item I<node>

=item I<uid>

=item I<parent>

=over 4

=item B<parent>

=item B<_set_parent>

=item B<has_parent>

=item B<clear_parent>

=back

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

=item B<clear_size>

=back

=item I<height>

=over 4

=item B<height>

=item B<has_height>

=item B<clear_height>

=back

=back

=head1 METHODS

=over 4

=item B<is_root>

True if the current tree has no parent

=item B<is_leaf>

True if the current tree has no children

=item B<depth>

Return the depth of this tree. Root has a depth of -1

=item B<add_child ($child)>

=item B<add_children (@children)>

Add a new child. The $child must be a C<Forest::Tree>

=item B<insert_child_at ($index, $child)>

Insert a child at this position. (zero-base index)

=item B<remove_child_at ($index)>

Remove the child at this position. (zero-base index)

=item B<traverse (\&func)>

Takes a reference to a subroutine and traverses the tree applying this subroutine to
every descendant.

=item B<siblings>

Returns an array reference of all siblings (not including us)

=item B<to_pure_tree>

Invokes C<reconstruct_with_class> with L<Forest::Tree::Pure>.

=item B<to_mutable_tree>

Returns the invocant (without cloning).

=item B<clone>

See L<Forest::Tree::Pure/clone>.

This variant will B<not> clone the parent, but return a clone of the subtree
that is detached.

=item B<get_index_in_siblings>

Returns the index of the tree in the list of children.

Equivalent to calling C<$tree->parent->get_child_index($tree)>.

Returns -1 if the node has no parent (the root node).

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
