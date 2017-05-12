package HTML::Widgets::NavMenu::Iterator::Html::Item;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Tree::Iterator::Item);

sub get_url_type
{
    my $item = shift;
    return
        ($item->_node()->url_type() ||
            $item->_accum_state()->{'rec_url_type'} ||
            "rel");
}

package HTML::Widgets::NavMenu::Iterator::Html;

=head1 NAME

HTML::Widgets::NavMenu::Iterator::Html - an iterator for HTML.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS
=cut

use base qw(HTML::Widgets::NavMenu::Iterator::Base);

use HTML::Widgets::NavMenu::EscapeHtml;

sub _construct_new_item
{
    my $self = shift;
    my $args = shift;

    return HTML::Widgets::NavMenu::Iterator::Html::Item->new(
        $args,
    );
}

=head2 $self->node_start()

Gets called upon node start.

=cut

sub node_start
{
    my $self = shift;

    if ($self->_is_root())
    {
        return $self->_start_root();
    }
    elsif ($self->_is_top_separator())
    {
        # _start_sep() is short for start_separator().
        return $self->_start_sep();
    }
    else
    {
        return $self->_start_regular();
    }
}

=head2 $self->node_end()

Gets called upon node end.

=cut

sub node_end
{
    my $self = shift;

    if ($self->_is_root())
    {
        return $self->end_root();
    }
    elsif ($self->_is_top_separator())
    {
        return $self->_end_sep();
    }
    else
    {
        return $self->_end_regular();
    }
}

=head2 $self->end_root()

End-root event.

=cut

sub end_root
{
    my $self = shift;

    $self->_add_tags("</ul>");
}

sub _end_regular
{
    my $self = shift;
    if ($self->top()->_num_subs() && $self->_is_expanded())
    {
        $self->_add_tags("</ul>");
    }
    $self->_add_tags("</li>");
}

=head2 $self->node_should_recurse()

Override to determine when one should recurse to the node.

=cut

sub node_should_recurse
{
    my $self = shift;
    return $self->_is_expanded();
}

=head2 $self->get_a_tag()

Renders the HTML for the opening a-tag.

=cut

# Get the HTML <a href=""> tag.
#
sub get_a_tag
{
    my $self = shift;
    my $item = $self->top();
    my $node = $item->_node;

    my $tag ="<a";
    my $title = $node->title;

    $tag .= " href=\"" .
        escape_html(
            $self->nav_menu()->_get_url_to_item($item)
        ). "\"";
    if (defined($title))
    {
        $tag .= " title=\"$title\"";
    }
    $tag .= ">" . $node->text() . "</a>";
    return $tag;
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

