package HTML::Widgets::NavMenu::Tree::Node;
$HTML::Widgets::NavMenu::Tree::Node::VERSION = '1.0902';
use strict;
use warnings;

use parent 'HTML::Widgets::NavMenu::Object';

__PACKAGE__->mk_acc_ref(
    [
        qw(
            CurrentlyActive expanded hide host li_id role rec_url_type
            separator show_always skip subs text title url url_is_abs url_type
        )
    ]
);

use HTML::Widgets::NavMenu::ExpandVal ();


sub _init
{
    my $self = shift;

    $self->subs( [] );

    return $self;
}


sub expand
{
    my $self = shift;
    my $v =
        @_
        ? ( shift(@_) )
        : HTML::Widgets::NavMenu::ExpandVal->new( { capture => 1 } );

    # Don't set it to something if it's already capture_expanded(),
    # otherwise it can set as a non-capturing expansion.
    if ( !$self->capture_expanded() )
    {
        $self->expanded($v);
    }
    return 0;
}


sub mark_as_current
{
    my $self = shift;
    $self->expand();
    $self->CurrentlyActive(1);
    return 0;
}

sub _process_new_sub
{
    my $self = shift;
    my $sub  = shift;
    $self->update_based_on_sub($sub);
}


sub update_based_on_sub
{
    my $self = shift;
    my $sub  = shift;
    if ( my $expand_val = $sub->expanded() )
    {
        $self->expand($expand_val);
    }
}


sub add_sub
{
    my $self = shift;
    my $sub  = shift;
    push( @{ $self->subs }, $sub );
    $self->_process_new_sub($sub);
    return 0;
}


sub get_nth_sub
{
    my $self = shift;
    my $idx  = shift;
    return $self->subs()->[$idx];
}

sub _num_subs
{
    my $self = shift;
    return scalar( @{ $self->subs() } );
}


sub list_regular_keys
{
    my $self = shift;

    return (
        qw(host li_id rec_url_type role show_always text title url url_type));
}


sub list_boolean_keys
{
    my $self = shift;

    return (qw(hide separator skip url_is_abs));
}


sub set_values_from_hash_ref
{
    my $self         = shift;
    my $sub_contents = shift;

    foreach my $key ( $self->list_regular_keys() )
    {
        if ( exists( $sub_contents->{$key} ) )
        {
            $self->$key( $sub_contents->{$key} );
        }
    }

    foreach my $key ( $self->list_boolean_keys() )
    {
        if ( $sub_contents->{$key} )
        {
            $self->$key(1);
        }
    }
}


sub capture_expanded
{
    my $self = shift;

    if ( my $e = $self->expanded() )
    {
        return $e->is_capturing();
    }
    else
    {
        return;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Tree::Node - an iterator for HTML.

=head1 VERSION

version 1.0902

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 CurrentlyActive

Internal use.

=head2 expanded

Internal use.

=head2 CurrentlyActive

Internal use.

=head2 hide

Internal use.

=head2 host

Internal use.

=head2 li_id

Internal use.

=head2 role

Internal use.

=head2 rec_url_type

Internal use.

=head2 separator

Internal use.

=head2 show_always

Internal use.

=head2 skip

Internal use.

=head2 subs

Internal use.

=head2 text

Internal use.

=head2 title

Internal use.

=head2 url

Internal use.

=head2 url_is_abs

Internal use.

=head2 url_type

Internal use.

=head2 $self->expand()

Expands the node.

=head2 $self->mark_as_current()

Marks the node as the current node.

=head2 $self->update_based_on_sub

Propagate changes.

=head2 $self->add_sub()

Adds a new subroutine.

=head2 $self->get_nth_sub($idx)

Get the $idx sub.

=head2 $self->list_regular_keys()

Customisation to list the regular keys.

=head2 $self->list_boolean_keys()

Customisation to list the boolean keys.

=head2 $self->set_values_from_hash_ref($hash)

Set the values from the hash ref.

=head2 my $bool = $self->capture_expanded()

Tests whether the node is expanded and in a capturing way.

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
