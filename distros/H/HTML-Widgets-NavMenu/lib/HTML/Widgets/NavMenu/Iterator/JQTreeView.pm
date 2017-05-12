package HTML::Widgets::NavMenu::Iterator::JQTreeView;

use strict;
use warnings;

# For escape_html().
use HTML::Widgets::NavMenu::EscapeHtml;

use base qw(HTML::Widgets::NavMenu::Iterator::NavMenu);

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    # Make a fresh copy just to be on the safe side.
    $self->_ul_classes([ @{$args->{'ul_classes'}} ]);

    return 0;
}

=head1 NAME

HTML::Widgets::NavMenu::Iterator::JQTreeView - an iterator for JQuery
TreeView's navigation menus.

=head1 SYNOPSIS

See L<http://bassistance.de/jquery-plugins/jquery-plugin-treeview/> .

For internal use only.

=head1 METHODS

=cut
sub _calc_open_li_tag
{
    my $self = shift;

    my $id_attr = $self->_calc_li_id_attr();

    return
    (
        $self->_is_expanded_for_treeview()
        ? (qq{<li class="open"$id_attr>})
        : ("<li$id_attr>")
    );

    return;
}

=head2 get_currently_active_text ( $node )

Calculates the highlighted text for the node C<$node>. Normally surrounds it
with C<<< <b> ... </b> >>> tags.

=cut

sub _start_handle_non_role
{
    my $self = shift;
    my $top_item = $self->top;
    my @tags_to_add = ($self->_calc_open_li_tag(), $self->get_link_tag());
    if ($top_item->_num_subs_to_go() && $self->_is_expanded())
    {
        push @tags_to_add, ($self->get_open_sub_menu_tags());
    }
    $self->_add_tags(@tags_to_add);

    return;
}

sub _start_handle_role
{
    my $self = shift;

    return $self->_start_handle_non_role();
}

sub _is_expanded
{
    return 1;
}

sub _is_expanded_for_treeview
{
    my $self = shift;

    my $node = $self->top->_node();

    return ($node->expanded() || $self->top->_accum_state->{'show_always'});
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;
