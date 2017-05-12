package HTML::Widgets::NavMenu::Iterator::Base;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Tree::Iterator);

__PACKAGE__->mk_acc_ref([qw(
    _html
    nav_menu
    )]);

=head1 NAME

HTML::Widgets::NavMenu::Iterator::Base - base class for the iterator.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 nav_menu

Internal use.

=cut

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    $self->nav_menu($args->{'nav_menu'}) or
        die "nav_menu not specified!";

    $self->_html([]);

    return 0;
}

sub _add_tags
{
    my $self = shift;
    push (@{$self->_html()}, @_);
}

sub _is_root
{
    my $self = shift;

    return ($self->stack->len() == 1);
}

sub _is_top_separator
{
    my $self = shift;

    return $self->top->_node->separator;
}

=head2 $self->get_initial_node()

Gets the initial node.

=cut

sub get_initial_node
{
    my $self = shift;
    return $self->nav_menu->_get_traversed_tree();
}

=head2 $self->get_node_subs({ node => $node})

Gets the subs of the node.

=cut


sub get_node_subs
{
    my ($self, $args) = @_;

    my $node = $args->{'node'};

    return [ @{$node->subs()} ];
}

=head2 $self->get_new_accum_state( { item => $item, node => $node } )

Gets the new accumulated state.

=cut

# TODO : This method is too long - refactor.
sub get_new_accum_state
{
    my ($self, $args) = @_;

    my $parent_item = $args->{'item'};
    my $node = $args->{'node'};

    my $prev_state;
    if (defined($parent_item))
    {
        $prev_state = $parent_item->_accum_state();
    }
    else
    {
        $prev_state = +{};
    }

    my $show_always = 0;
    if (exists($prev_state->{'show_always'}))
    {
        $show_always = $prev_state->{'show_always'};
    }
    if (defined($node->show_always()))
    {
        $show_always = $node->show_always();
    }

    my $rec_url_type;
    if (exists($prev_state->{'rec_url_type'}))
    {
        $rec_url_type = $prev_state->{'rec_url_type'};
    }
    if (defined($node->rec_url_type()))
    {
        $rec_url_type = $node->rec_url_type();
    }
    return
        {
            'host' => ($node->host() ? $node->host() : $prev_state->{'host'}),
            'show_always' => $show_always,
            'rec_url_type' => $rec_url_type,
        };
}

=head2 my $array_ref = $self->get_results()

Returns an array reference with the resultant HTML.

=cut

sub get_results
{
    my $self = shift;

    return [ @{$self->_html()} ];
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

