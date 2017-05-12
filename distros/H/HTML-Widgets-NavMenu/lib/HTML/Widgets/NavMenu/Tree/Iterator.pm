package HTML::Widgets::NavMenu::Tree::Iterator;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Object);

use HTML::Widgets::NavMenu::Tree::Iterator::Stack;
use HTML::Widgets::NavMenu::Tree::Iterator::Item;

__PACKAGE__->mk_acc_ref([qw(
    coords
    stack
    )]);

=head1 NAME

HTML::Widgets::NavMenu::Tree::Iterator - an iterator for HTML.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 coords

Internal use.

=head2 stack

Internal use.

=cut



sub _init
{
    my $self = shift;

    $self->stack(HTML::Widgets::NavMenu::Tree::Iterator::Stack->new());

    return 0;
}

=head2 $self->top()

Retrieves the stack top item.

=cut
sub top
{
    my $self = shift;
    return $self->stack()->top();
}

sub _construct_new_item
{
    my ($self, $args) = @_;

    return HTML::Widgets::NavMenu::Tree::Iterator::Item->new(
        $args
    );
}

=head2 $self->get_new_item({'node' => $node, 'parent_item' => $parent})

Gets the new item.

=cut

sub get_new_item
{
    my ($self, $args) = @_;

    my $node = $args->{'node'};
    my $parent_item = $args->{'parent_item'};

    return
        $self->_construct_new_item(
            {
                'node' => $node,
                'subs' => $self->get_node_subs( { 'node' => $node } ),
                'accum_state' =>
                    $self->get_new_accum_state(
                        {
                            'item' => $parent_item,
                            'node' => $node,
                        }
                    ),
            }
        );
}

sub _push_into_stack
{
    my $self = shift;

    my $node = shift;

    $self->stack()->push(
        $self->get_new_item(
            {
                'node' => $node,
                'parent_item' => $self->top(),
            }
        ),
    );
}

=head2 $self->traverse()

Traverses the tree.

=cut

sub traverse
{
    my $self = shift;

    $self->_push_into_stack($self->get_initial_node());

    $self->coords([]);

    my $top_item;

    MAIN_LOOP: while ($top_item = $self->top())
    {
        my $visited = $top_item->_is_visited();

        if (!$visited)
        {
            $self->node_start();
        }

        my $sub_item =
            ($self->node_should_recurse() ?
                $top_item->_visit() :
                undef);

        if (defined($sub_item))
        {
            push @{$self->coords()}, $top_item->_visited_index();
            $self->_push_into_stack(
                $self->get_node_from_sub(
                    {
                        'item' => $top_item,
                        'sub' => $sub_item,
                    }
                ),
            );
            next MAIN_LOOP;
        }
        else
        {
            $self->node_end();
            $self->stack->pop();
            pop(@{$self->coords()})
        }
    }

    return 0;
}

=head2 $self->get_node_from_sub()

This function can be overridden to generate a node from the sub-nodes
returned by get_node_subs() in a different way than the default.

=cut

sub get_node_from_sub
{
    my $self = shift;
    my $args = shift;

    return $args->{'sub'};
}

=head2 $self->find_node_by_coords($coords, $callback)

Finds a node by its coordinations.

=cut

sub find_node_by_coords
{
    my $self = shift;
    my $coords = shift;
    my $callback = shift || (sub { });

    my $idx = 0;
    my $item =
        $self->get_new_item(
            {
                'node' => $self->get_initial_node(),
            }
        );

    my $internal_callback =
        sub {
            $callback->(
                'idx' => $idx,
                'item' => $item,
                'self' => $self,
            );
        };

    $internal_callback->();
    foreach my $c (@$coords)
    {
        $item =
            $self->get_new_item(
                {
                    'node' =>
                    $self->get_node_from_sub(
                        {
                            'item' => $item,
                            'sub' => $item->_get_sub($c),
                        }
                    ),
                    'parent_item' => $item,
                }
            );
        $idx++;
        $internal_callback->();
    }
    return +{ 'item' => $item, };
}

=head2 $self->get_coords()

Returns the current coordinates of the object.

=cut

sub get_coords
{
    my $self = shift;

    return $self->coords();
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

