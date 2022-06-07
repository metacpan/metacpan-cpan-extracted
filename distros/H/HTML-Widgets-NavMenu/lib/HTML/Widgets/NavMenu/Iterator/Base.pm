package HTML::Widgets::NavMenu::Iterator::Base;
$HTML::Widgets::NavMenu::Iterator::Base::VERSION = '1.1000';
use strict;
use warnings;

use parent qw(HTML::Widgets::NavMenu::Tree::Iterator);

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _html
            nav_menu
        )
    ]
);


sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    $self->nav_menu( $args->{'nav_menu'} )
        or die "nav_menu not specified!";

    $self->_html( [] );

    return 0;
}

sub _add_tags
{
    my $self = shift;
    push( @{ $self->_html() }, @_ );
}

sub _is_root
{
    my $self = shift;

    return ( $self->stack->len() == 1 );
}


sub get_initial_node
{
    my $self = shift;
    return $self->nav_menu->_get_traversed_tree();
}


sub get_node_subs
{
    my ( $self, $args ) = @_;

    my $node = $args->{'node'};

    return [ @{ $node->subs() } ];
}


# TODO : This method is too long - refactor.
sub get_new_accum_state
{
    my ( $self, $args ) = @_;

    my $parent_item = $args->{'item'};
    my $node        = $args->{'node'};

    my $prev_state;
    if ( defined($parent_item) )
    {
        $prev_state = $parent_item->_accum_state();
    }
    else
    {
        $prev_state = +{};
    }

    my $show_always = 0;
    if ( exists( $prev_state->{'show_always'} ) )
    {
        $show_always = $prev_state->{'show_always'};
    }
    if ( defined( $node->show_always() ) )
    {
        $show_always = $node->show_always();
    }

    my $rec_url_type;
    if ( exists( $prev_state->{'rec_url_type'} ) )
    {
        $rec_url_type = $prev_state->{'rec_url_type'};
    }
    if ( defined( $node->rec_url_type() ) )
    {
        $rec_url_type = $node->rec_url_type();
    }
    return {
        'host' => ( $node->host() ? $node->host() : $prev_state->{'host'} ),
        'show_always'  => $show_always,
        'rec_url_type' => $rec_url_type,
    };
}


sub get_results
{
    my $self = shift;

    return [ @{ $self->_html() } ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Iterator::Base - base class for the iterator.

=head1 VERSION

version 1.1000

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 nav_menu

Internal use.

=head2 $self->get_initial_node()

Gets the initial node.

=head2 $self->get_node_subs({ node => $node})

Gets the subs of the node.

=head2 $self->get_new_accum_state( { item => $item, node => $node } )

Gets the new accumulated state.

=head2 my $array_ref = $self->get_results()

Returns an array reference with the resultant HTML.

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
