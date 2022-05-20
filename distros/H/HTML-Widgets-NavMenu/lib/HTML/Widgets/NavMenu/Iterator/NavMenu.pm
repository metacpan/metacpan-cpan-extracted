package HTML::Widgets::NavMenu::Iterator::NavMenu;
$HTML::Widgets::NavMenu::Iterator::NavMenu::VERSION = '1.0902';
use strict;
use warnings;

use parent qw(HTML::Widgets::NavMenu::Iterator::Html);

use HTML::Widgets::NavMenu::EscapeHtml qw/ escape_html /;

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _ul_classes
        )
    ]
);


sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    # Make a fresh copy just to be on the safe side.
    $self->_ul_classes( [ @{ $args->{'ul_classes'} } ] );

    return 0;
}

sub _calc_li_id_attr
{
    my $self = shift;

    my $li_id = $self->top()->_li_id;

    return (
        defined($li_id)
        ? qq/ id="/ . escape_html($li_id) . qq/"/
        : q//
    );
}


# Depth is 1 for the uppermost depth.
sub gen_ul_tag
{
    my ( $self, $args ) = @_;

    my $depth = $args->{'depth'};

    my $class = $self->_get_ul_class( { 'depth' => $depth } );

    return "<ul"
        . (
        defined($class)
        ? ( " class=\"" . escape_html($class) . "\"" )
        : ""
        ) . ">";
}

sub _get_ul_class
{
    my ( $self, $args ) = @_;

    my $depth = $args->{'depth'};

    return $self->_ul_classes->[ $depth - 1 ];
}


sub get_currently_active_text
{
    my $self = shift;
    my $node = shift;
    return "<b>" . $node->text() . "</b>";
}


sub get_link_tag
{
    my $self = shift;
    my $node = $self->top->_node();
    if ( $node->CurrentlyActive() )
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


sub get_open_sub_menu_tags
{
    my $self = shift;
    return ( "<br />",
        $self->gen_ul_tag( { 'depth' => $self->stack->len() } ) );
}

sub _start_handle_non_role
{
    my $self     = shift;
    my $top_item = $self->top;
    my @tags_to_add =
        ( ( "<li" . $self->_calc_li_id_attr() . ">" ), $self->get_link_tag() );
    if ( $top_item->_num_subs_to_go() && $self->_is_expanded() )
    {
        push @tags_to_add, ( $self->get_open_sub_menu_tags() );
    }
    $self->_add_tags(@tags_to_add);
}

sub _start_regular
{
    my $self = shift;

    my $top_item = $self->top;
    my $node     = $self->top->_node();

    if ( $self->_is_hidden() )
    {
        # Do nothing
    }
    else
    {
        if ( $self->_is_role_specified() )
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
                'depth' => $self->stack->len() - 1
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
    if ( $self->_is_hidden() )
    {
        # Do nothing
    }
    elsif ( $self->_is_role_specified() )
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
    return ( $node->expanded() || $self->top->_accum_state->{'show_always'} );
}


sub get_role
{
    my $self = shift;
    return $self->top->_node->role();
}

sub _is_role_specified
{
    my $self = shift;
    return defined( $self->get_role() );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Iterator::NavMenu - navmenu iterator.

=head1 VERSION

version 1.0902

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 $self->gen_ul_tag({depth => $depth});

Generate a UL tag of depth $depth.

=head2 get_currently_active_text ( $node )

Calculates the highlighted text for the node C<$node>. Normally surrounds it
with C<<< <b> ... </b> >>> tags.

=head2 $self->get_link_tag()

Gets the tag for the link - an item in the menu.

=head2 my @tags = $self->get_open_sub_menu_tags()

Gets the tags to open a new sub menu.

=head2 $self->get_role()

Retrieves the current role.

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
