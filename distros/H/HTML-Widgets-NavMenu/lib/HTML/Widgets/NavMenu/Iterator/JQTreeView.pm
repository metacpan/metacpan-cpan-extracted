package HTML::Widgets::NavMenu::Iterator::JQTreeView;
$HTML::Widgets::NavMenu::Iterator::JQTreeView::VERSION = '1.0900';
use strict;
use warnings;

use HTML::Widgets::NavMenu::EscapeHtml qw/ escape_html /;

use parent qw(HTML::Widgets::NavMenu::Iterator::NavMenu);

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    # Make a fresh copy just to be on the safe side.
    $self->_ul_classes( [ @{ $args->{'ul_classes'} } ] );

    return 0;
}


sub _calc_open_li_tag
{
    my $self = shift;

    my $id_attr = $self->_calc_li_id_attr();

    return (
        $self->_is_expanded_for_treeview()
        ? (qq{<li class="open"$id_attr>})
        : ("<li$id_attr>")
    );

    return;
}


sub _start_handle_non_role
{
    my $self        = shift;
    my $top_item    = $self->top;
    my @tags_to_add = ( $self->_calc_open_li_tag(), $self->get_link_tag() );
    if ( $top_item->_num_subs_to_go() && $self->_is_expanded() )
    {
        push @tags_to_add, ( $self->get_open_sub_menu_tags() );
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

    return ( $node->expanded() || $self->top->_accum_state->{'show_always'} );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Iterator::JQTreeView - an iterator for JQuery
TreeView's navigation menus.

=head1 VERSION

version 1.0900

=head1 SYNOPSIS

See L<http://bassistance.de/jquery-plugins/jquery-plugin-treeview/> .

For internal use only.

=head1 METHODS

=head2 get_currently_active_text ( $node )

Calculates the highlighted text for the node C<$node>. Normally surrounds it
with C<<< <b> ... </b> >>> tags.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Widgets-NavMenu>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Widgets-NavMenu>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Widgets-NavMenu>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Widgets-NavMenu>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Widgets-NavMenu>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Widgets::NavMenu>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-widgets-navmenu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Widgets-NavMenu>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu>

  git clone git://github.com/shlomif/perl-HTML-Widgets-NavMenu.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
