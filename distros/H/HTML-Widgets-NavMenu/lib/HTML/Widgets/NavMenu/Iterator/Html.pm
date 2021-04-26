package HTML::Widgets::NavMenu::Iterator::Html;
$HTML::Widgets::NavMenu::Iterator::Html::VERSION = '1.0900';
use strict;
use warnings;

use HTML::Widgets::NavMenu::Iterator::Html::Item ();


use parent qw(HTML::Widgets::NavMenu::Iterator::Base);

use HTML::Widgets::NavMenu::EscapeHtml qw/ escape_html /;

sub _construct_new_item
{
    my $self = shift;
    my $args = shift;

    return HTML::Widgets::NavMenu::Iterator::Html::Item->new( $args, );
}


sub _is_top_separator
{
    return $_[0]->top->{_node}->{separator};
}

sub node_start
{
    my $self = shift;

    if ( $self->{_is_root} )
    {
        return $self->_start_root();
    }
    elsif ( $self->_is_top_separator() )
    {
        # _start_sep() is short for start_separator().
        return $self->_start_sep();
    }
    else
    {
        return $self->_start_regular();
    }
}


sub node_end
{
    my $self = shift;

    if ( $self->{_is_root} )
    {
        return $self->end_root();
    }
    elsif ( $self->_is_top_separator() )
    {
        return $self->_end_sep();
    }
    else
    {
        return $self->_end_regular();
    }
}


sub end_root
{
    my $self = shift;

    $self->_add_tags("</ul>");
}

sub _end_regular
{
    my $self = shift;
    if ( $self->top()->_num_subs() && $self->_is_expanded() )
    {
        $self->_add_tags("</ul>");
    }
    $self->_add_tags("</li>");
}


sub node_should_recurse
{
    my $self = shift;
    return $self->_is_expanded();
}


# Get the HTML <a href=""> tag.
#
sub get_a_tag
{
    my $self = shift;
    my $item = $self->top();
    my $node = $item->_node;

    my $tag   = "<a";
    my $title = $node->title;

    $tag .= " href=\""
        . escape_html( $self->nav_menu()->_get_url_to_item($item) ) . "\"";
    if ( defined($title) )
    {
        $tag .= " title=\"$title\"";
    }
    $tag .= ">" . $node->text() . "</a>";
    return $tag;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Iterator::Html - an iterator for HTML.

=head1 VERSION

version 1.0900

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 $self->node_start()

Gets called upon node start.

=head2 $self->node_end()

Gets called upon node end.

=head2 $self->end_root()

End-root event.

=head2 $self->node_should_recurse()

Override to determine when one should recurse to the node.

=head2 $self->get_a_tag()

Renders the HTML for the opening a-tag.

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
