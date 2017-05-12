package HTML::Widgets::NavMenu::Tree::Iterator::Stack;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Object);

__PACKAGE__->mk_acc_ref([qw(_items)]);

sub _init
{
    my $self = shift;

    $self->reset();

    return 0;
}

=head1 NAME

HTML::Widgets::NavMenu::Tree::Iterator::Stack - a simple stack class.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS
=cut

sub push
{
    my $self = shift;
    my $item = shift;

    push @{$self->_items()}, $item;

    return 0;
}

=head2 $s->push($myitem)

Pushes an item.

=cut

sub len
{
    my $self = shift;

    return scalar(@{$self->_items()});
}

=head2 $s->len($myitem)

Returns the number of elements.

=cut

sub top
{
    my $self = shift;
    return $self->_items->[-1];
}

=head2 $s->top()

Returns the highest item.

=cut


sub item
{
    my $self = shift;
    my $index = shift;
    return $self->_items->[$index];
}

=head2 my $item = $s->item($index)

Returns the item of index C<$index>.

=cut

sub pop
{
    my $self = shift;
    return pop(@{$self->_items()});
}

=head2 my $item = $s->pop()

Pops the item and returns it.

=cut

sub is_empty
{
    my $self = shift;
    return ($self->len() == 0);
}

=head2 my $bool = $s->is_empty()

Returns true if the stack is empty.

=cut

sub reset
{
    my $self = shift;

    $self->_items([]);

    return 0;
}

=head2 $s->reset();

Empties the stack

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

