package HTML::Widgets::NavMenu::Iterator::GetCurrentlyActive;
$HTML::Widgets::NavMenu::Iterator::GetCurrentlyActive::VERSION = '1.1000';
use strict;
use warnings;

use parent 'HTML::Widgets::NavMenu::Iterator::Base';

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _item_found
            _leading_path_coords
            _ret_coords
            _temp_coords
            _tree
        )
    ]
);

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    $self->_tree( $args->{'tree'} );

    $self->_item_found(0);

    return 0;
}

sub get_initial_node
{
    my $self = shift;

    return $self->_tree;
}

sub item_matches
{
    my $self     = shift;
    my $item     = $self->top();
    my $url      = $item->_node()->url();
    my $nav_menu = $self->nav_menu();
    return (   ( $item->_accum_state()->{'host'} eq $nav_menu->current_host() )
            && ( defined($url) && ( $url eq $nav_menu->path_info() ) ) );
}

sub does_item_expand
{
    my $self = shift;
    my $item = $self->top();
    return $item->_node()->capture_expanded();
}

sub node_start
{
    my $self = shift;

    if ( $self->item_matches() )
    {
        my @coords = @{ $self->get_coords() };
        $self->_ret_coords( [@coords] );
        $self->_temp_coords( [ @coords, (-1) ] );
        $self->top()->_node()->mark_as_current();
        $self->_item_found(1);
    }
    elsif ( $self->does_item_expand() )
    {
        my @coords = @{ $self->get_coords() };
        $self->_leading_path_coords( [@coords] );
    }
}

sub node_end
{
    my $self = shift;
    if ( $self->_item_found() )
    {
        # Skip the first node, because the coords refer
        # to the nodes below it.
        my $idx = pop( @{ $self->_temp_coords() } );
        if ( $idx >= 0 )
        {
            my $node = $self->top()->_node();
            $node->update_based_on_sub( $node->get_nth_sub($idx) );
        }
    }
}

sub node_should_recurse
{
    my $self = shift;
    return ( !$self->_item_found() );
}

sub get_final_coords
{
    my $self = shift;

    return $self->_ret_coords();
}

sub _get_leading_path_coords
{
    my $self = shift;

    return ( $self->_ret_coords() || $self->_leading_path_coords() );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

=head1 VERSION

version 1.1000

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 does_item_expand()

B<internal use>

=head2 get_final_coords()

B<internal use>

=head2 get_initial_node()

B<internal use>

=head2 item_matches()

B<internal use>

=head2 node_end()

B<internal use>

=head2 node_should_recurse()

B<internal use>

=head2 node_start()

B<internal use>

=head2

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
