package HTML::Widgets::NavMenu::Iterator::SiteMap;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Iterator::Html);

=head1 NAME

HTML::Widgets::NavMenu::Iterator::SiteMap - a site-map iterator.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=cut

sub _start_root
{
    my $self = shift;

    $self->_add_tags("<ul>");
}

sub _start_sep
{
}

sub _start_regular
{
    my $self = shift;

    my $top_item = $self->top;
    my $node = $self->top->_node();

    $self->_add_tags("<li>");
    my $tag = $self->get_a_tag();
    my $title = $node->title();
    if (defined($title))
    {
        $tag .= " - $title";
    }
    $self->_add_tags($tag);

    if ($top_item->_num_subs_to_go())
    {
        $self->_add_tags("<br />");
        $self->_add_tags("<ul>");
    }
}

sub _end_sep
{
}

sub _is_expanded
{
    return 1;
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;
