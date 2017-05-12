package HTML::Widgets::NavMenu::Iterator::NavMenu;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Iterator::Html);

use HTML::Widgets::NavMenu::EscapeHtml;

__PACKAGE__->mk_acc_ref([qw(
    _ul_classes
    )]);

=head1 NAME

HTML::Widgets::NavMenu::Iterator::NavMenu - navmenu iterator.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS
=cut

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    # Make a fresh copy just to be on the safe side.
    $self->_ul_classes([ @{$args->{'ul_classes'}} ]);

    return 0;
}

sub _calc_li_id_attr
{
    my $self = shift;

    my $li_id = $self->top()->_li_id;

    return
    (defined ($li_id)
        ? qq/ id="/ . escape_html($li_id) . qq/"/
        : q//
    );
}

=head2 $self->gen_ul_tag({depth => $depth});

Generate a UL tag of depth $depth.

=cut

# Depth is 1 for the uppermost depth.
sub gen_ul_tag
{
    my ($self, $args) = @_;

    my $depth = $args->{'depth'};

    my $class = $self->_get_ul_class({'depth' => $depth});

    return "<ul" .
        (defined($class) ?
            (" class=\"" . escape_html($class) . "\"") :
            ""
        ) . ">";
}

sub _get_ul_class
{
    my ($self, $args) = @_;

    my $depth = $args->{'depth'};

    return $self->_ul_classes->[$depth-1];
}

=head2 get_currently_active_text ( $node )

Calculates the highlighted text for the node C<$node>. Normally surrounds it
with C<<< <b> ... </b> >>> tags.

=cut

sub get_currently_active_text
{
    my $self = shift;
    my $node = shift;
    return "<b>" . $node->text() . "</b>";
}

=head2 $self->get_link_tag()

Gets the tag for the link - an item in the menu.

=cut

sub get_link_tag
{
    my $self = shift;
    my $node = $self->top->_node();
    if ($node->CurrentlyActive())
    {
        return $self->get_currently_active_text($node);
    }
    else
    {
        return $self->get_a_tag();
    }
}

sub _start_root
{
    my $self = shift;

    $self->_add_tags(
        $self->gen_ul_tag(
            {
                'depth' => $self->stack->len()
            }
        )
    );
}

sub _start_sep
{
    my $self = shift;

    $self->_add_tags("</ul>");
}

sub _start_handle_role
{
    my $self = shift;
    return $self->_start_handle_non_role();
}

=head2 my @tags = $self->get_open_sub_menu_tags()

Gets the tags to open a new sub menu.

=cut

sub get_open_sub_menu_tags
{
    my $self = shift;
    return ("<br />",
        $self->gen_ul_tag(
            {'depth' => $self->stack->len()}
        )
    );
}

sub _start_handle_non_role
{
    my $self = shift;
    my $top_item = $self->top;
    my @tags_to_add = (("<li" . $self->_calc_li_id_attr() . ">"),
        $self->get_link_tag());
    if ($top_item->_num_subs_to_go() && $self->_is_expanded())
    {
        push @tags_to_add, ($self->get_open_sub_menu_tags());
    }
    $self->_add_tags(@tags_to_add);
}

sub _start_regular
{
    my $self = shift;

    my $top_item = $self->top;
    my $node = $self->top->_node();

    if ($self->_is_hidden())
    {
        # Do nothing
    }
    else
    {
        if ($self->_is_role_specified())
        {
            $self->_start_handle_role();
        }
        else
        {
            $self->_start_handle_non_role();
        }
    }
}

sub _end_sep
{
    my $self = shift;

    $self->_add_tags(
        $self->gen_ul_tag(
            {
                'depth' => $self->stack->len()-1
            }
        )
    );
}

sub _end_handle_role
{
    my $self = shift;
    return $self->_end_handle_non_role();
}

sub _end_handle_non_role
{
    my $self = shift;
    return $self->SUPER::_end_regular();
}

sub _end_regular
{
    my $self = shift;
    if ($self->_is_hidden())
    {
        # Do nothing
    }
    elsif ($self->_is_role_specified())
    {
        $self->_end_handle_role();
    }
    else
    {
        $self->_end_handle_non_role();
    }
}

sub _is_hidden
{
    my $self = shift;
    return $self->top->_node()->hide();
}

sub _is_expanded
{
    my $self = shift;
    my $node = $self->top->_node();
    return ($node->expanded() || $self->top->_accum_state->{'show_always'});
}

=head2 $self->get_role()

Retrieves the current role.

=cut

sub get_role
{
    my $self = shift;
    return $self->top->_node->role();
}

sub _is_role_specified
{
    my $self = shift;
    return defined($self->get_role());
}

1;

