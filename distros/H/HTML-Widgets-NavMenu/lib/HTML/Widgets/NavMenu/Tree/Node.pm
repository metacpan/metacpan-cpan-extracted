package HTML::Widgets::NavMenu::Tree::Node;

use strict;
use warnings;

use base 'HTML::Widgets::NavMenu::Object';

__PACKAGE__->mk_acc_ref([
    qw(
    CurrentlyActive expanded hide host li_id role rec_url_type
    separator show_always skip subs text title url url_is_abs url_type
    )]
    );

use HTML::Widgets::NavMenu::ExpandVal;

=head1 NAME

HTML::Widgets::NavMenu::Tree::Node - an iterator for HTML.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 CurrentlyActive

Internal use.

=head2 expanded

Internal use.

=head2 CurrentlyActive

Internal use.

=head2 hide

Internal use.

=head2 host

Internal use.

=head2 li_id

Internal use.

=head2 role

Internal use.

=head2 rec_url_type

Internal use.

=head2 separator

Internal use.

=head2 show_always

Internal use.

=head2 skip

Internal use.

=head2 subs

Internal use.

=head2 text

Internal use.

=head2 title

Internal use.

=head2 url

Internal use.

=head2 url_is_abs

Internal use.

=head2 url_type

Internal use.

=cut

sub _init
{
    my $self = shift;

    $self->subs([]);

    return $self;
}

=head2 $self->expand()

Expands the node.

=cut

sub expand
{
    my $self = shift;
    my $v = @_ ? (shift(@_)) :
        HTML::Widgets::NavMenu::ExpandVal->new({capture => 1})
        ;
    # Don't set it to something if it's already capture_expanded(),
    # otherwise it can set as a non-capturing expansion.
    if (! $self->capture_expanded())
    {
        $self->expanded($v);
    }
    return 0;
}

=head2 $self->mark_as_current()

Marks the node as the current node.

=cut

sub mark_as_current
{
    my $self = shift;
    $self->expand();
    $self->CurrentlyActive(1);
    return 0;
}

sub _process_new_sub
{
    my $self = shift;
    my $sub = shift;
    $self->update_based_on_sub($sub);
}

=head2 $self->update_based_on_sub

Propagate changes.

=cut

sub update_based_on_sub
{
    my $self = shift;
    my $sub = shift;
    if (my $expand_val = $sub->expanded())
    {
        $self->expand($expand_val);
    }
}

=head2 $self->add_sub()

Adds a new subroutine.

=cut

sub add_sub
{
    my $self = shift;
    my $sub = shift;
    push (@{$self->subs}, $sub);
    $self->_process_new_sub($sub);
    return 0;
}

=head2 $self->get_nth_sub($idx)

Get the $idx sub.

=cut

sub get_nth_sub
{
    my $self = shift;
    my $idx = shift;
    return $self->subs()->[$idx];
}

sub _num_subs
{
    my $self = shift;
    return scalar(@{$self->subs()});
}

=head2 $self->list_regular_keys()

Customisation to list the regular keys.

=cut

sub list_regular_keys
{
    my $self = shift;

    return (qw(host li_id rec_url_type role show_always text title url url_type));
}

=head2 $self->list_boolean_keys()

Customisation to list the boolean keys.

=cut

sub list_boolean_keys
{
    my $self = shift;

    return (qw(hide separator skip url_is_abs));
}

=head2 $self->set_values_from_hash_ref($hash)

Set the values from the hash ref.

=cut

sub set_values_from_hash_ref
{
    my $self = shift;
    my $sub_contents = shift;

    foreach my $key ($self->list_regular_keys())
    {
        if (exists($sub_contents->{$key}))
        {
            $self->$key($sub_contents->{$key});
        }
    }

    foreach my $key ($self->list_boolean_keys())
    {
        if ($sub_contents->{$key})
        {
            $self->$key(1);
        }
    }
}

=head2 my $bool = $self->capture_expanded()

Tests whether the node is expanded and in a capturing way.

=cut

sub capture_expanded
{
    my $self = shift;

    if (my $e = $self->expanded())
    {
        return $e->is_capturing();
    }
    else
    {
        return;
    }
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;
